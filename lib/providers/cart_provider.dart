import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  final String selectedSize;
  int quantity;

  CartItem({required this.product, required this.selectedSize, this.quantity = 1});
}

// State Management for the cart.
// notifyListeners() makes every screen that watches the cart rebuild.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSub;

  CartProvider({FirebaseAuth? auth}) : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null) {
    final authInstance = _auth;
    if (authInstance != null) {
      _authSub = authInstance.authStateChanges().listen((user) {
        if (user == null) {
          clear();
        }
      });
    }
  }

  List<CartItem> get items => List.unmodifiable(_items);

  // Compute Total Amount
  double get totalAmount => _items.fold<double>(
        0,
        (sum, item) => sum + item.product.price * item.quantity,
      );

  // Step 6: Add to Cart logic with size
  void addToCart(Product product, [String? selectedSize]) {
    final sizeToUse = selectedSize ?? (product.sizes.isNotEmpty ? product.sizes.keys.first : 'Standard');
    final sizeStock = product.sizes[sizeToUse] ?? 0;
    if (sizeStock <= 0) return;

    final index = _items.indexWhere(
      (item) => item.product.id == product.id && item.selectedSize == sizeToUse,
    );
    if (index >= 0) {
      if (_items[index].quantity < sizeStock) {
        _items[index].quantity++;
      }
    } else {
      _items.add(CartItem(product: product, selectedSize: sizeToUse, quantity: 1));
    }
    notifyListeners();
  }

  // Increase Quantity
  void increaseQuantity(CartItem item) {
    final sizeStock = item.product.sizes[item.selectedSize] ?? item.product.stock;
    if (item.quantity < sizeStock) {
      item.quantity++;
      notifyListeners();
    }
  }

  // Decrease Quantity (remove at 0 or when quantity becomes 0)
  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  // Remove Item
  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // HOA05: replace a cart item's product with fresh data from Firestore
  // (e.g. the admin changed the price after the item was added)
  void syncProduct(Product fresh) {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].product.id == fresh.id) {
        _items[i] = CartItem(
          product: fresh,
          selectedSize: _items[i].selectedSize,
          quantity: _items[i].quantity,
        );
      }
    }
    notifyListeners();
  }

  // HOA05: remove an item whose product no longer exists
  void removeById(String productId) {
    _items.removeWhere((e) => e.product.id == productId);
    notifyListeners();
  }

  // Used after checkout
  void clear() {
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
