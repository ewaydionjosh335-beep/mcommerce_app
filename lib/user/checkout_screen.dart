import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../utils/logger.dart';
import 'my_orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'Cash on Delivery (COD)';
  bool _isLoading = false;
  bool _submitting = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery (COD)',
    'GCash',
    'Credit / Debit Card',
    'Maya',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          if (_addressController.text.isEmpty) {
            _addressController.text = data['address']?.toString() ?? data['shippingAddress']?.toString() ?? '';
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? '';
          }
        });
      }
    } catch (e, s) {
      logError('Checkout', e, s);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<String?> _validateCart(CartProvider cart) async {
    if (cart.items.isEmpty) return 'Your cart is empty';

    final db = FirebaseFirestore.instance;
    final items = List<CartItem>.from(cart.items);
    final snaps = await Future.wait(
      items.map((i) => db.collection('products').doc(i.product.id).get()),
    );

    final problems = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final snap = snaps[i];

      if (!snap.exists) {
        cart.removeById(item.product.id);
        problems.add('${item.product.productName} is no longer available and was removed.');
        continue;
      }

      final fresh = Product.fromFirestore(snap);

      if (fresh.stock < item.quantity) {
        problems.add('${fresh.productName}: only ${fresh.stock} left in stock.');
      }

      if (fresh.price != item.product.price) {
        cart.syncProduct(fresh);
        problems.add('${fresh.productName} price changed to ₱${fresh.price.toStringAsFixed(2)}. Please review your total.');
      }
    }
    return problems.isEmpty ? null : problems.join('\n');
  }

  Future<void> _submitOrder(CartProvider cart) async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _show('Please log in again.');
      return;
    }
    if (cart.items.isEmpty) {
      _show('Your cart is empty');
      return;
    }

    _submitting = true;
    setState(() => _isLoading = true);
    try {
      final problem = await _validateCart(cart);
      if (problem != null) {
        logInfo('Checkout', 'Validation failed: $problem');
        _show(problem);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final customerName =
          (userDoc.data()?['name'] as String?) ?? user.email ?? 'Customer';

      final items = cart.items
          .map((item) => {
                'productId': item.product.id,
                'productName': item.product.productName,
                'price': item.product.price,
                'quantity': item.quantity,
              })
          .toList();

      final total = double.parse(cart.items
          .fold<double>(
              0, (runningTotal, i) => runningTotal + i.product.price * i.quantity)
          .toStringAsFixed(2));

      final ref = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'customerName': customerName,
        'customerEmail': user.email,
        'shippingAddress': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'notes': _notesController.text.trim(),
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'Cash on Delivery (COD)' ? 'Unpaid' : 'Paid (Simulated)',
        'items': items,
        'total': total,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Deduct stock and check for Out of Stock (0) automatic alerts for Admin
      for (final item in cart.items) {
        final productRef = FirebaseFirestore.instance.collection('products').doc(item.product.id);
        final productSnap = await productRef.get();
        if (productSnap.exists) {
          final currentStock = (productSnap.data()?['stock'] as num?)?.toInt() ?? item.product.stock;
          final newStock = currentStock - item.quantity < 0 ? 0 : currentStock - item.quantity;

          await productRef.update({'stock': newStock});

          if (newStock == 0) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': 'admin',
              'title': '⚠️ Out of Stock Alert!',
              'body': 'Product "${item.product.productName}" is now out of stock (0 remaining) after a customer purchase.',
              'type': 'out_of_stock',
              'productId': item.product.id,
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      final shortId = ref.id.substring(0, ref.id.length > 8 ? 8 : ref.id.length);
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'title': 'Order Placed Successfully',
        'body': 'Your order #$shortId has been placed and is currently pending.',
        'type': 'order',
        'orderId': ref.id,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      logInfo('Checkout', 'Order ${ref.id} saved (${items.length} items, total ₱$total)');

      cart.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully! Order #$shortId'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.indigo.shade700,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('My Orders')),
            body: const MyOrdersScreen(),
          ),
        ),
      );
    } on FirebaseException catch (e, s) {
      logError('Checkout', e, s);
      _show(e.code == 'unavailable'
          ? 'No connection. Please check your internet and try again.'
          : (e.message ?? 'Checkout failed'));
    } catch (e, s) {
      logError('Checkout', e, s);
      _show('Something went wrong. Please try again.');
    } finally {
      _submitting = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter your complete street address, city, province',
                ),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter delivery address'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g., 09123456789',
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter phone number'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Order Notes (Optional)',
                  hintText: 'e.g., Leave package at front door',
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                   children: _paymentMethods.map((method) {
                     final selected = _selectedPaymentMethod == method;
                     return InkWell(
                       onTap: () => setState(() => _selectedPaymentMethod = method),
                       borderRadius: BorderRadius.circular(14),
                       child: Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                         child: Row(
                           children: [
                             Icon(
                               selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                               color: selected ? Colors.indigo.shade600 : Colors.grey,
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Text(
                                 method,
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                    color: selected ? Colors.indigo.shade800 : Theme.of(context).colorScheme.onSurface,
                                  ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     );
                   }).toList(),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Items:'),
                        Text('${cart.items.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₱${cart.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : () => _submitOrder(cart),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
