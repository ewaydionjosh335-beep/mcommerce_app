import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

// State Management for the cart.
// notifyListeners() makes every screen that watches the cart rebuild.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  // Compute Total Amount
  double get totalAmount => _items.fold<double>(
        0,
        (sum, item) => sum + item.product.price * item.quantity,
      );

  // Step 6: Add to Cart logic
  void addToCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // Increase Quantity
  void increaseQuantity(CartItem item) {
    item.quantity++;
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
    final i = _items.indexWhere((e) => e.product.id == fresh.id);
    if (i < 0) return;
    _items[i] = CartItem(product: fresh, quantity: _items[i].quantity);
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
}