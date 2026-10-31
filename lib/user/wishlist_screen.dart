import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();

    if (wishlist.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: wishlist.items.length,
          itemBuilder: (context, index) {
            final product = wishlist.items[index];
            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              cacheWidth: 200,
                                              cacheHeight: 200,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.grey.shade100,
                                                child: const Icon(Icons.image_not_supported),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (product.stock == 0)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: Colors.red.shade600,
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: const Text(
                                                'Out of stock',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.indigo.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                                      color: product.stock == 0 ? Colors.grey : Colors.indigo,
                                      tooltip: product.stock == 0 ? 'Out of stock' : 'Add to Cart',
                                      onPressed: product.stock == 0
                                          ? null
                                          : () {
                                              cart.addToCart(product);
                                              wishlist.removeProduct(product.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${product.productName} added to cart'),
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      color: Colors.red.shade400,
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        wishlist.removeProduct(product.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 72,
                                        height: 72,
                                        child: Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (product.stock == 0)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.red.shade600,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: const Text(
                                            'Out of stock',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₱${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.indigo.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                                      color: product.stock == 0 ? Colors.grey : Colors.indigo,
                                      tooltip: product.stock == 0 ? 'Out of stock' : 'Add to Cart',
                                      onPressed: product.stock == 0
                                          ? null
                                          : () {
                                              cart.addToCart(product);
                                              wishlist.removeProduct(product.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${product.productName} added to cart'),
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      color: Colors.red.shade400,
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        wishlist.removeProduct(product.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
