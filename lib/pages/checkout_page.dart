import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/order_email_service.dart';
import '../widgets/flash_overlay.dart';
import '../main.dart' show AppColors;

class CheckoutPage extends StatefulWidget {
  final String? userId;
  final String? email;

  const CheckoutPage({super.key, this.userId, this.email});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _addressCommentController = TextEditingController();
  bool _payOnDelivery = false;
  bool _isLoading = false;
  bool _isLoadingUser = true;
  bool _showOverlay = false;
  bool? _showResult;
  String? _name;
  String? _phone;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? uid = widget.userId;
    String? email = widget.email;
    
    if (uid == null) {
      final user = FirebaseAuth.instance.currentUser;
      uid = user?.uid;
      email = user?.email;
    }
    
    if (uid != null) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _name = data['name'] ?? '';
            _phone = data['phone'] ?? '';
            _email = email ?? data['email'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      } finally {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } else {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_payOnDelivery) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm pay on delivery')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? uid = widget.userId;
      uid ??= FirebaseAuth.instance.currentUser?.uid;
      
      final cart = context.read<CartService>();

      if (uid != null) {
        final orderRef = FirebaseDatabase.instance.ref('orders').push();
        final orderId = orderRef.key;
        
        final itemsData = cart.items.map((item) => {
          'name': item.name,
          'price': item.price,
          'addons': item.selectedAddons,
          'addonPrice': item.addonPrice,
          'totalPrice': item.totalPrice,
        }).toList();
        
        await orderRef.set({
          'userId': uid,
          'name': _name,
          'phone': _phone,
          'email': _email,
          'address': _addressController.text.trim(),
          'addressComment': _addressCommentController.text.trim(),
          'items': itemsData,
          'totalAmount': cart.totalPrice,
          'payOnDelivery': true,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });
        
        try {
          await OrderEmailService().sendOrderConfirmation(
            email: _email ?? '',
            name: _name ?? '',
            phone: _phone ?? '',
            address: _addressController.text.trim(),
            items: cart.items.map((item) => {
              'name': item.name,
              'price': item.price,
              'addons': item.selectedAddons,
              'addonPrice': item.addonPrice,
              'totalPrice': item.totalPrice,
            }).toList(),
            totalAmount: cart.totalPrice,
            orderId: orderId ?? '',
          );
        } catch (e) {
          debugPrint('Error sending email: $e');
        }
      }

      cart.clearCart();
      
      setState(() {
        _isLoading = false;
        _showOverlay = true;
        _showResult = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showOverlay = true;
        _showResult = false;
      });
    }
  }
  
  void _onOverlayComplete() {
    setState(() {
      _showOverlay = false;
      _showResult = null;
    });
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    if (_isLoadingUser) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: AppColors.burntOrange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.burntOrange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _name,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _phone,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _email,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCommentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address Comment (optional)',
                      prefixIcon: const Icon(Icons.comment),
                      hintText: 'e.g., Near the church, yellow gate',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...cart.items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (item.selectedAddons.isNotEmpty)
                                Text(
                                  item.selectedAddons.join(', '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '₵${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.burntOrange,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₵${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.burntOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    value: _payOnDelivery,
                    onChanged: (value) {
                      setState(() {
                        _payOnDelivery = value ?? false;
                      });
                    },
                    title: const Text('Pay on delivery'),
                    activeColor: AppColors.burntOrange,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_payOnDelivery && !_isLoading) ? _submitOrder : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burntOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Order - ₵${cart.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showOverlay)
            FlashOverlay(
              isLoading: _isLoading,
              isSuccess: _showResult,
              onComplete: _onOverlayComplete,
            ),
        ],
      ),
    );
  }
}