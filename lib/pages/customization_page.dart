import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';

class CustomizationPage extends StatefulWidget {
  final String name;
  final String price;
  final String imageAsset;
  final List<Map<String, dynamic>> addons;

  const CustomizationPage({
    super.key,
    required this.name,
    required this.price,
    required this.imageAsset,
    required this.addons,
  });

  @override
  State<CustomizationPage> createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> {
  final Set<String> _selectedAddons = {};
  double _addonPrice = 0;

  void _toggleAddon(String addonName, double price) {
    setState(() {
      if (_selectedAddons.contains(addonName)) {
        _selectedAddons.remove(addonName);
        _addonPrice -= price;
      } else {
        _selectedAddons.add(addonName);
        _addonPrice += price;
      }
    });
  }

  void _addToCart() {
    final cart = context.read<CartService>();
    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.name,
      price: widget.price,
      imageAsset: widget.imageAsset,
      selectedAddons: _selectedAddons.toList(),
      addonPrice: _addonPrice,
    );

    cart.addItem(cartItem);

    Navigator.pop(context);
    _showAddedConfirmation();
  }

  void _showAddedConfirmation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Added to cart!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue Shopping'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = double.tryParse(widget.price.replaceAll('₵', '')) ?? 0;
    final totalPrice = basePrice + _addonPrice;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              widget.imageAsset,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.restaurant, size: 64),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₵${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (widget.addons.isNotEmpty) ...[
                    const Text(
                      'Add-ons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.addons.map((addon) => CheckboxListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(addon['name'] as String),
                          Text(
                            '₵${(addon['price'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      value: _selectedAddons.contains(addon['name']),
                      onChanged: (_) => _toggleAddon(
                        addon['name'] as String,
                        addon['price'] as double,
                      ),
                      activeColor: Colors.deepPurple,
                    )),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Add to Cart - ₵${totalPrice.toStringAsFixed(2)}',
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
          ],
        ),
      ),
    );
  }
}