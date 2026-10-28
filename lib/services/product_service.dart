import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../utils/logger.dart';

// Flutter Service: full CRUD on the products collection
class ProductService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  // READ (the "R" in CRUD)
  // snapshots() is a live stream: whenever the data in Firebase changes,
  // the UI that listens to it rebuilds automatically (real-time sync).
  Stream<List<Product>> getProducts() {
    return _products.snapshots().map((snapshot) {
      logInfo('ProductService',
          'Snapshot received: ${snapshot.docs.length} products (fromCache: ${snapshot.metadata.isFromCache})');
      final list = <Product>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(Product.fromFirestore(doc));
        } catch (e, s) {
          // One bad document must not break the whole product list
          logError('ProductService', 'Skipped bad product ${doc.id}: $e', s);
        }
      }
      return list;
    });
  }

  // HOA05 Step 3: Validate Product Data (empty fields, negative price, invalid stock)
  void _validate({
    required String productName,
    required String description,
    required double price,
    required Map<String, int> sizes,
    required String imageUrl,
  }) {
    Product.validateProduct(
      productName: productName,
      description: description,
      price: price,
      sizes: sizes,
      imageUrl: imageUrl,
    );
  }

  // CREATE
  Future<void> addProduct({
    required String productName,
    required String description,
    required double price,
    required Map<String, int> sizes,
    required String imageUrl,
    required String category,
  }) async {
    _validate(
      productName: productName,
      description: description,
      price: price,
      sizes: sizes,
      imageUrl: imageUrl,
    );
    final totalStock = sizes.values.fold(0, (a, b) => a + b);
    final ref = await _products.add({
      'productName': productName,
      'description': description,
      'price': price,
      'sizes': sizes,
      'stock': totalStock,
      'imageUrl': imageUrl,
      'category': category,
    });
    logInfo('ProductService', 'Added product ${ref.id} ($productName)');
  }

  // UPDATE
  Future<void> updateProduct(
    String id, {
    required String productName,
    required String description,
    required double price,
    required Map<String, int> sizes,
    required String imageUrl,
    required String category,
  }) async {
    _validate(
      productName: productName,
      description: description,
      price: price,
      sizes: sizes,
      imageUrl: imageUrl,
    );
    final totalStock = sizes.values.fold(0, (a, b) => a + b);
    await _products.doc(id).update({
      'productName': productName,
      'description': description,
      'price': price,
      'sizes': sizes,
      'stock': totalStock,
      'imageUrl': imageUrl,
      'category': category,
    });
    logInfo('ProductService', 'Updated product $id ($productName)');
  }

  // DELETE
  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
    logInfo('ProductService', 'Deleted product $id');
  }
}