import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../screens/login_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.indigo.shade600),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to start shopping',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: isNarrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: Image.network(
                                              item.product.imageUrl,
                                              fit: BoxFit.cover,
                                              cacheWidth: 200,
                                              cacheHeight: 200,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.productName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Size: ${item.selectedSize}',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '₱${item.product.price.toStringAsFixed(2)}',
                                                style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 14),
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
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 16),
                                                onPressed: () => cart.decreaseQuantity(item),
                                                color: Colors.indigo,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                              Text(
                                                '${item.quantity}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add, size: 16),
                                                onPressed: item.quantity < (item.product.sizes[item.selectedSize] ?? item.product.stock)
                                                    ? () => cart.increaseQuantity(item)
                                                    : null,
                                                color: item.quantity < (item.product.sizes[item.selectedSize] ?? item.product.stock) ? Colors.indigo : Colors.grey,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 16),
                                                onPressed: () => cart.removeItem(item),
                                                color: Colors.red.shade400,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 72,
                                        height: 72,
                                        child: Image.network(
                                          item.product.imageUrl,
                                          fit: BoxFit.cover,
                                          cacheWidth: 200,
                                          cacheHeight: 200,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.productName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Size: ${item.selectedSize}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${item.product.price.toStringAsFixed(2)}',
                                            style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 18),
                                            onPressed: () => cart.decreaseQuantity(item),
                                            color: Colors.indigo,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 18),
                                            onPressed: item.quantity < (item.product.sizes[item.selectedSize] ?? item.product.stock)
                                                ? () => cart.increaseQuantity(item)
                                                : null,
                                            color: item.quantity < (item.product.sizes[item.selectedSize] ?? item.product.stock) ? Colors.indigo : Colors.grey,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18),
                                            onPressed: () => cart.removeItem(item),
                                            color: Colors.red.shade400,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      Text(
                        '₱${cart.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: cart.items.isEmpty
                          ? null
                          : () {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Authentication Required'),
                                    content: const Text('You need to log in or register to checkout and place an order.'),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen(),
                                ),
                              );
                            },
                      child: const Text('Proceed to Checkout'),
                    ),
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