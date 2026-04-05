import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final String price;
  final String imageAsset;
  final List<String> selectedAddons;
  final double addonPrice;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageAsset,
    this.selectedAddons = const [],
    this.addonPrice = 0,
  });

  double get totalPrice {
    final basePrice = double.tryParse(price.replaceAll('₵', '')) ?? 0;
    return basePrice + addonPrice;
  }
}

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}