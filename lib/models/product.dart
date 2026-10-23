import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validation_exception.dart';

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

  factory Product.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? {};
    return Product(
      id: id,
      productName: (d['productName'] ?? '').toString(),
      price: _toDouble(d['price']),
      description: (d['description'] ?? '').toString(),
      imageUrl: (d['imageUrl'] ?? '').toString(),
      stock: _toInt(d['stock']),
      category: (d['category'] ?? 'General').toString(),
    );
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap(doc.id, doc.data());
  }

  static void validateProduct({
    required String productName,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
  }) {
    if (productName.trim().isEmpty ||
        description.trim().isEmpty ||
        imageUrl.trim().isEmpty) {
      throw ValidationException('All fields are required');
    }
    if (price.isNaN || price.isInfinite || price <= 0) {
      throw ValidationException('Price must be greater than 0');
    }
    if (stock < 0) {
      throw ValidationException('Stock cannot be negative');
    }
    if (!imageUrl.trim().startsWith('http')) {
      throw ValidationException('Image URL must start with http');
    }
  }
}