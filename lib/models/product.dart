import 'package:cloud_firestore/cloud_firestore.dart';

// Product Model: turns a Firestore document into a Dart object
class Product {
  final String id;
  final String productName;
  final double price;
  final String description;
  final String imageUrl;
  final int stock;
  final String category;

  Product({
    required this.id,
    required this.productName,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.stock,
    required this.category,
  });

  // HOA05 (null values): accept numbers stored as num or String, and never
  // crash on a missing / wrong-typed field.
  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product(
      id: doc.id,
      productName: (data['productName'] ?? '').toString(),
      price: _toDouble(data['price']),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      stock: _toInt(data['stock']),
      category: (data['category'] ?? 'General').toString(),
    );
  }
}