import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/validation_exception.dart';

// Product Model: turns a Firestore document into a Dart object
class Product {
  final String id;
  final String productName;
  final double price;
  final String description;
  final String imageUrl;
  final Map<String, int> sizes;
  final String category;

  Product({
    required this.id,
    required this.productName,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.sizes,
    required this.category,
  });

  int get stock {
    if (sizes.isEmpty) return 0;
    return sizes.values.fold(0, (a, b) => a + b);
  }

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

  static Map<String, int> _parseSizes(dynamic v, int fallbackStock) {
    final map = <String, int>{};
    if (v is Map) {
      v.forEach((key, val) {
        map[key.toString()] = _toInt(val);
      });
    }
    if (map.isEmpty) {
      map['Standard'] = fallbackStock > 0 ? fallbackStock : 10;
    }
    return map;
  }

  factory Product.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? {};
    final fallbackStock = _toInt(d['stock']);
    return Product(
      id: id,
      productName: (d['productName'] ?? '').toString(),
      price: _toDouble(d['price']),
      description: (d['description'] ?? '').toString(),
      imageUrl: (d['imageUrl'] ?? '').toString(),
      sizes: _parseSizes(d['sizes'], fallbackStock),
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
    required Map<String, int> sizes,
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
    if (sizes.isEmpty) {
      throw ValidationException('At least one size with stock is required');
    }
    for (final entry in sizes.entries) {
      if (entry.key.trim().isEmpty) {
        throw ValidationException('Size name cannot be empty');
      }
      if (entry.value < 0) {
        throw ValidationException('Stock for size ${entry.key} cannot be negative');
      }
    }
    if (!imageUrl.trim().startsWith('http')) {
      throw ValidationException('Image URL must start with http');
    }
  }
}