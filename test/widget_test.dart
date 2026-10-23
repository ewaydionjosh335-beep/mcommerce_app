import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/models/product.dart';
import 'package:mcommerce_app/providers/cart_provider.dart';
import 'package:mcommerce_app/utils/validation_exception.dart';

void main() {
  group('Product.fromMap Tests', () {
    test('parses normal valid data correctly', () {
      final product = Product.fromMap('p1', {
        'productName': 'Test Product',
        'price': 29.99,
        'description': 'A description',
        'imageUrl': 'https://example.com/img.jpg',
        'stock': 10,
        'category': 'Electronics',
      });

      expect(product.id, 'p1');
      expect(product.productName, 'Test Product');
      expect(product.price, 29.99);
      expect(product.description, 'A description');
      expect(product.imageUrl, 'https://example.com/img.jpg');
      expect(product.stock, 10);
      expect(product.category, 'Electronics');
    });

    test('handles missing or null fields gracefully', () {
      final product = Product.fromMap('p2', null);
      expect(product.id, 'p2');
      expect(product.productName, '');
      expect(product.price, 0.0);
      expect(product.description, '');
      expect(product.imageUrl, '');
      expect(product.stock, 0);
      expect(product.category, 'General');
    });

    test('handles wrong-typed fields (numeric strings, int/double conversions)', () {
      final product = Product.fromMap('p3', {
        'productName': 'Typed Product',
        'price': '49.50',
        'description': 'Desc',
        'imageUrl': 'http://example.com/img.png',
        'stock': '5',
        'category': 123,
      });

      expect(product.price, 49.50);
      expect(product.stock, 5);
      expect(product.category, '123');
    });
  });

  group('CartProvider Tests', () {
    test('add, increase, decrease, remove, total, and clear work correctly', () {
      final cart = CartProvider();
      final p1 = Product(
        id: '1',
        productName: 'Item 1',
        price: 10.0,
        description: 'Desc',
        imageUrl: 'http://',
        stock: 5,
        category: 'Cat',
      );
      final p2 = Product(
        id: '2',
        productName: 'Item 2',
        price: 25.0,
        description: 'Desc',
        imageUrl: 'http://',
        stock: 5,
        category: 'Cat',
      );

      expect(cart.items.isEmpty, true);
      expect(cart.totalAmount, 0.0);

      // Add item 1
      cart.addToCart(p1);
      expect(cart.items.length, 1);
      expect(cart.items[0].quantity, 1);
      expect(cart.totalAmount, 10.0);

      // Add item 1 again (increases quantity)
      cart.addToCart(p1);
      expect(cart.items.length, 1);
      expect(cart.items[0].quantity, 2);
      expect(cart.totalAmount, 20.0);

      // Increase quantity explicitly
      cart.increaseQuantity(cart.items[0]);
      expect(cart.items[0].quantity, 3);
      expect(cart.totalAmount, 30.0);

      // Add item 2
      cart.addToCart(p2);
      expect(cart.items.length, 2);
      expect(cart.totalAmount, 55.0);

      // Decrease quantity of item 1
      cart.decreaseQuantity(cart.items[0]);
      expect(cart.items[0].quantity, 2);
      expect(cart.totalAmount, 45.0);

      // Decrease item 1 until removal
      cart.decreaseQuantity(cart.items[0]); // qty 1
      cart.decreaseQuantity(cart.items[0]); // removed
      expect(cart.items.length, 1);
      expect(cart.items[0].product.id, '2');
      expect(cart.totalAmount, 25.0);

      // Remove item 2 explicitly
      cart.removeItem(cart.items[0]);
      expect(cart.items.isEmpty, true);
      expect(cart.totalAmount, 0.0);

      // Add back and clear
      cart.addToCart(p1);
      expect(cart.items.length, 1);
      cart.clear();
      expect(cart.items.isEmpty, true);
      expect(cart.totalAmount, 0.0);
    });
  });

  group('Product Validation Tests', () {
    test('validates valid product successfully', () {
      expect(() {
        Product.validateProduct(
          productName: 'Valid Product',
          description: 'Good description',
          price: 10.0,
          stock: 5,
          imageUrl: 'https://example.com/img.png',
        );
      }, returnsNormally);
    });

    test('throws ValidationException on empty fields', () {
      expect(() {
        Product.validateProduct(
          productName: '',
          description: 'Desc',
          price: 10.0,
          stock: 5,
          imageUrl: 'https://example.com/img.png',
        );
      }, throwsA(isA<ValidationException>()));
    });

    test('throws ValidationException on invalid price', () {
      expect(() {
        Product.validateProduct(
          productName: 'Product',
          description: 'Desc',
          price: 0.0,
          stock: 5,
          imageUrl: 'https://example.com/img.png',
        );
      }, throwsA(isA<ValidationException>()));

      expect(() {
        Product.validateProduct(
          productName: 'Product',
          description: 'Desc',
          price: -5.0,
          stock: 5,
          imageUrl: 'https://example.com/img.png',
        );
      }, throwsA(isA<ValidationException>()));
    });

    test('throws ValidationException on negative stock', () {
      expect(() {
        Product.validateProduct(
          productName: 'Product',
          description: 'Desc',
          price: 10.0,
          stock: -1,
          imageUrl: 'https://example.com/img.png',
        );
      }, throwsA(isA<ValidationException>()));
    });

    test('throws ValidationException on invalid image URL', () {
      expect(() {
        Product.validateProduct(
          productName: 'Product',
          description: 'Desc',
          price: 10.0,
          stock: 5,
          imageUrl: 'ftp://example.com/img.png',
        );
      }, throwsA(isA<ValidationException>()));
    });
  });
}
