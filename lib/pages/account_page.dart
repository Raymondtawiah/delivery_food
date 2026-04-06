import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart' show AppColors;

class AccountPage extends StatelessWidget {
  final VoidCallback? onSignOut;
  final VoidCallback? onDeleteAccount;
  final String? userId;
  final String? email;

  const AccountPage({super.key, this.onSignOut, this.onDeleteAccount, this.userId, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: AppColors.burntOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: 'Account Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountSettingsPage(
                  userId: userId,
                  email: email,
                  onSignOut: onSignOut,
                  onDeleteAccount: onDeleteAccount,
                ),
              ),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: 'Past Orders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PastOrdersPage(userId: userId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.burntOrange),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class AccountSettingsPage extends StatefulWidget {
  final VoidCallback? onSignOut;
  final VoidCallback? onDeleteAccount;
  final String? userId;
  final String? email;

  const AccountSettingsPage({super.key, this.onSignOut, this.onDeleteAccount, this.userId, this.email});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _receiveDeals = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? uid = widget.userId;
    if (uid == null) {
      final user = FirebaseAuth.instance.currentUser;
      uid = user?.uid;
    }
    
    if (uid != null) {
      _userId = uid;
      try {
        final snapshot = await FirebaseDatabase.instance.ref('users/$_userId').get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _receiveDeals = data['receiveDeals'] ?? false;
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseDatabase.instance.ref('users/$_userId').update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'receiveDeals': _receiveDeals,
        });
        
        setState(() {
          _hasChanges = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved successfully')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (e) {
        // Ignore errors when deleting anonymous user
      }
      widget.onSignOut?.call();
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (_userId != null) {
          await FirebaseDatabase.instance.ref('users/$_userId').remove();
        }
        await FirebaseAuth.instance.currentUser?.delete();
        widget.onDeleteAccount?.call();
      } catch (e) {
        widget.onDeleteAccount?.call();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userId != null ? null : FirebaseAuth.instance.currentUser;
    final email = widget.email ?? user?.email ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: AppColors.burntOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                onChanged: (_) => _onFieldChanged(),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length > 20) {
                    return 'Name too long';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
                    return 'Only letters & numbers allowed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                onChanged: (_) => _onFieldChanged(),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length > 15) {
                    return 'Phone too long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Communication Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Keep me up to date with the latest deals'),
                value: _receiveDeals,
                onChanged: (value) {
                  setState(() {
                    _receiveDeals = value;
                    _hasChanges = true;
                  });
                },
                activeThumbColor: AppColors.burntOrange,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_hasChanges && !_isLoading) ? _saveChanges : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burntOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ) : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _deleteAccount,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PastOrdersPage extends StatefulWidget {
  final String? userId;

  const PastOrdersPage({super.key, this.userId});

  @override
  State<PastOrdersPage> createState() => _PastOrdersPageState();
}

class _PastOrdersPageState extends State<PastOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    String? uid = widget.userId;
    
    debugPrint('Loading orders for userId: $uid');
    
    if (uid == null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        uid = user?.uid;
        debugPrint('Got uid from FirebaseAuth: $uid');
      } catch (e) {
        debugPrint('Error getting user: $e');
      }
    }

    if (uid != null) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('orders').get();
        
        debugPrint('Orders snapshot exists: ${snapshot.exists}');
        
        if (snapshot.exists) {
          final List<Map<String, dynamic>> loadedOrders = [];
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          
          data.forEach((key, value) {
            final orderMap = Map<String, dynamic>.from(value as Map);
            final orderUserId = orderMap['userId']?.toString() ?? '';
            
            debugPrint('Order userId: $orderUserId, looking for: $uid');
            
            if (orderUserId == uid) {
              orderMap['orderId'] = key;
              loadedOrders.add(orderMap);
            }
          });
          
          loadedOrders.sort((a, b) {
            final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
            final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });
          
          debugPrint('Found ${loadedOrders.length} orders');
          
          setState(() {
            _orders = loadedOrders;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading orders: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      debugPrint('No uid found');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Orders'),
        backgroundColor: AppColors.burntOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No past orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final itemsData = order['items'];
                    final List<dynamic> items = itemsData is List ? itemsData : [];
                    final totalAmount = (order['totalAmount'] ?? 0.0).toDouble();
                    final status = order['status'] ?? 'pending';
                    final createdAt = order['createdAt'] ?? '';
                    
                    DateTime? orderDate;
                    try {
                      orderDate = DateTime.parse(createdAt);
                    } catch (e) {
                      orderDate = null;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        childrenPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt, color: AppColors.burntOrange),
                        ),
                        title: Text(
                          'Order #${order['orderId']?.substring(0, 8) ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₵${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.burntOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (orderDate != null)
                              Text(
                                '${orderDate.day}/${orderDate.month}/${orderDate.year}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'pending' 
                                ? Colors.orange.shade100 
                                : (status == 'completed' ? Colors.green.shade100 : Colors.red.shade100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == 'pending' 
                                  ? Colors.orange 
                                  : (status == 'completed' ? Colors.green : Colors.red),
                            ),
                          ),
                        ),
                        children: [
                          const Divider(),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Order Details',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...items.map<Widget>((item) {
                            final itemMap = item is Map ? Map<String, dynamic>.from(item) : {};
                            final itemName = itemMap['name'] ?? '';
                            final itemTotal = (itemMap['totalPrice'] ?? 0.0).toDouble();
                            final List<String> itemAddons = [];
                            if (itemMap['addons'] is List) {
                              itemAddons.addAll((itemMap['addons'] as List).map((e) => e.toString()));
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemName,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        if (itemAddons.isNotEmpty)
                                          Text(
                                            itemAddons.join(', '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₵${itemTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '₵${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: AppColors.burntOrange,
                                ),
                              ),
                            ],
                          ),
                          if (order['address'] != null && order['address'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order['address'],
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}