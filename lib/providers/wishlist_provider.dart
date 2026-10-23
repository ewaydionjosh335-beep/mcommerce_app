import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../utils/logger.dart';

class WishlistProvider with ChangeNotifier {
  final List<Product> _items = [];
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _wishlistSub;
  String? _uid;

  WishlistProvider() {
    logInfo('Wishlist', 'Provider created');
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid != null) {
      _listenWishlist(_uid!);
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      logInfo('Wishlist', 'Auth changed, user = ${user?.uid}');
      if (user == null) {
        _uid = null;
        _wishlistSub?.cancel();
        _items.clear();
        notifyListeners();
      } else if (user.uid != _uid) {
        _uid = user.uid;
        _wishlistSub?.cancel();
        _items.clear();
        notifyListeners();
        _listenWishlist(user.uid);
      }
    });
  }

  List<Product> get items => _items;

  CollectionReference<Map<String, dynamic>> _wishlistRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wishlist');

  void _listenWishlist(String uid) {
    _wishlistSub?.cancel();
    _wishlistSub = _wishlistRef(uid).snapshots().listen((snap) async {
      logInfo('Wishlist', 'Snapshot received: ${snap.docs.length} wishlist docs');
      try {
        final docs = await Future.wait(
          snap.docs.map((d) =>
              FirebaseFirestore.instance.collection('products').doc(d.id).get()),
        );

        if (_uid != uid) return;

        _items
          ..clear()
          ..addAll(docs.where((d) => d.exists).map(Product.fromFirestore));
        notifyListeners();
        logInfo('Wishlist', 'Loaded ${_items.length} items');
      } catch (e, s) {
        logError('Wishlist stream', e, s);
      }
    }, onError: (e, s) {
      logError('Wishlist stream error', e, s);
    });
  }

  Future<void> _saveAdd(String productId) async {
    final uid = _uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      logInfo('Wishlist', 'SKIPPED save: _uid is null');
      return;
    }
    try {
      await _wishlistRef(uid).doc(productId).set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      logInfo('Wishlist', 'Saved $productId for $uid');
    } catch (e, s) {
      logError('Wishlist save', e, s);
    }
  }

  Future<void> _saveRemove(String productId) async {
    final uid = _uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      logInfo('Wishlist', 'SKIPPED remove: _uid is null');
      return;
    }
    try {
      await _wishlistRef(uid).doc(productId).delete();
      logInfo('Wishlist', 'Removed $productId for $uid');
    } catch (e, s) {
      logError('Wishlist remove', e, s);
    }
  }

  bool isInWishlist(Product product) {
    return _items.any((item) => item.id == product.id);
  }

  void toggleWishlist(Product product) {
    if (isInWishlist(product)) {
      _items.removeWhere((item) => item.id == product.id);
      notifyListeners();
      _saveRemove(product.id);
    } else {
      _items.add(product);
      notifyListeners();
      _saveAdd(product.id);
    }
  }

  void removeProduct(String productId) {
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
    _saveRemove(productId);
  }

  /// Clears only the local list (used on logout). Does NOT delete from Firestore.
  void clear() {
    _wishlistSub?.cancel();
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _wishlistSub?.cancel();
    super.dispose();
  }
}
