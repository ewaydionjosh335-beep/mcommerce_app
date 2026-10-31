import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../screens/login_screen.dart';
import 'checkout_screen.dart';
import 'product_reviews_section.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class SizeSelector extends StatefulWidget {
  final Product product;
  final ValueChanged<String?> onSelected;

  const SizeSelector({super.key, required this.product, required this.onSelected});

  @override
  State<SizeSelector> createState() => _SizeSelectorState();
}

class _SizeSelectorState extends State<SizeSelector> {
  String? _selectedSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.product.sizes.entries.map((entry) {
        final sizeName = entry.key;
        final sizeStock = entry.value;
        final isSelected = _selectedSize == sizeName;
        final isOutOfStock = sizeStock <= 0;

        return ChoiceChip(
          label: Text('$sizeName ($sizeStock left)'),
          selected: isSelected,
          selectedColor: Colors.indigo.shade100,
          backgroundColor: Colors.grey.shade100,
          labelStyle: TextStyle(
            color: isOutOfStock 
                ? Colors.grey 
                : (isSelected ? Colors.indigo.shade900 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: isOutOfStock 
              ? (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Size $sizeName is out of stock'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              : (selected) {
                  setState(() {
                    _selectedSize = selected ? sizeName : null;
                  });
                  widget.onSelected(_selectedSize);
                },
        );
      }).toList(),
    );
  }
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign up / Login first'),
        content: const Text('You need to log in or register to add items to your cart and place orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LoginScreen.showAsModal(context);
            },
            child: const Text('Log In / Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.productName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: product.id,
              child: SizedBox(
                height: 360,
                width: double.infinity,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  cacheHeight: 800,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Expanded(
                        child: Text(
                          product.productName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Size',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizeSelector(
                    product: product,
                    onSelected: (size) {
                      _selectedSize = size;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Product Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                   Text(
                     product.description,
                     style: TextStyle(
                       fontSize: 15,
                       color: Colors.grey.shade700,
                       height: 1.6,
                     ),
                   ),
                   ProductReviewsSection(product: product),
                   const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        ),
        child: SafeArea(
            child: product.stock == 0
                ? SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.block),
                      label: const Text('Out of Stock'),
                      onPressed: null,
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Add to Cart'),
                            onPressed: () {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                _showLoginDialog(context);
                                return;
                              }
                              if (_selectedSize == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a size first')),
                                );
                                return;
                              }

                              context.read<CartProvider>().addToCart(product, _selectedSize!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.productName} ($_selectedSize) added to cart'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.indigo.shade700,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                _showLoginDialog(context);
                                return;
                              }
                              if (_selectedSize == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a size first')),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    directItems: [CartItem(product: product, selectedSize: _selectedSize!)],
                                  ),
                                ),
                              );
                            },
                            child: const Text('Buy Now'),
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
