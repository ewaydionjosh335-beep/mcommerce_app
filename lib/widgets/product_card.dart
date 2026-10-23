import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../screens/login_screen.dart';
import '../utils/logger.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: product.id,
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade50,
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                      ),
                    ),
                  ),
                  if (product.stock == 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Out of stock',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlist, child) {
                        final user = FirebaseAuth.instance.currentUser;
                        final isFavorite = user != null && wishlist.isInWishlist(product);
                        return GestureDetector(
                          onTap: () {
                            if (user == null) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Sign up / Login first'),
                                  content: const Text('You need to log in or register to add items to your wishlist.'),
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
                              return;
                            }
                            wishlist.toggleWishlist(product);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('productId', isEqualTo: product.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError && snapshot.error != null) {
                        logError('ProductCard review error', snapshot.error!);
                      }
                      final docs = snapshot.data?.docs ?? [];
                      double avgRating = 0;
                      if (docs.isNotEmpty) {
                        final total = docs.fold<int>(
                            0,
                            (acc, doc) =>
                                acc +
                                ((doc.data()['rating'] as num?)?.toInt() ?? 0));
                        avgRating = total / docs.length;
                      }

                      return Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: docs.isEmpty ? Colors.grey.shade400 : Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            docs.isEmpty ? '0.0' : avgRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: docs.isEmpty ? Colors.grey.shade600 : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '(${docs.length})',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      GestureDetector(
                        onTap: product.stock == 0
                            ? null
                            : () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Sign up / Login first'),
                                      content: const Text('You need to log in or register to add items to your cart.'),
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
                                  return;
                                }
                                context.read<CartProvider>().addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.productName} added to cart'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: product.stock == 0 ? Colors.grey.shade200 : Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: product.stock == 0 ? Colors.grey : Colors.indigo.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
