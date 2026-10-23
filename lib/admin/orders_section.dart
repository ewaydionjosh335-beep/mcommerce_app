import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../widgets/async_state_view.dart';

// HOA04 Activity 3: Order Management (display orders + update status)
class OrdersSection extends StatefulWidget {
  const OrdersSection({super.key});

  @override
  State<OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<OrdersSection> {
  static const _statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

  MaterialColor _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.indigo;
    }
  }

  final Stream<QuerySnapshot<Map<String, dynamic>>> _orders = FirebaseFirestore
      .instance
      .collection('orders')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    logInfo('Orders',
        'Snapshot received: ${snapshot.docs.length} orders (fromCache: ${snapshot.metadata.isFromCache})');
    return snapshot;
  });

  String _label(String s) => s[0].toUpperCase() + s.substring(1);

  // Step 7: Update Order Status
  Future<void> _updateStatus(String orderId, String status) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final data = orderDoc.data();
      final previousStatus = (data?['status'] ?? 'pending').toString().toLowerCase();
      final userId = data?['userId'];

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': status});

      if (status == 'cancelled' && previousStatus != 'cancelled') {
        final items = data?['items'];
        if (items is List) {
          for (final item in items) {
            final itemMap = Map<String, dynamic>.from(item as Map);
            final productId = itemMap['productId'] as String?;
            final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
            if (productId != null && productId.isNotEmpty && quantity > 0) {
              final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
              final productSnap = await productRef.get();
              if (productSnap.exists) {
                final currentStock = (productSnap.data()?['stock'] as num?)?.toInt() ?? 0;
                final newStock = currentStock + quantity;
                await productRef.update({'stock': newStock});
                logInfo('Orders', 'Restocked product $productId by +$quantity (New stock: $newStock)');
              }
            }
          }
        }
      }

      if (userId is String && userId.isNotEmpty) {
        final shortId = orderId.substring(0, orderId.length > 8 ? 8 : orderId.length);
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': 'Order Status Updated',
          'body': 'Your order #$shortId status has been updated to ${_label(status)}.',
          'type': 'order',
          'orderId': orderId,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      logInfo('Orders', 'Order $orderId status -> $status');
    } on FirebaseException catch (e, s) {
      logError('Orders', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to update status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // "Name x2, Name x1"
  String _itemsText(dynamic items) {
    if (items is! List || items.isEmpty) return '—';
    return items.map((i) {
      final m = Map<String, dynamic>.from(i as Map);
      return '${m['productName']} x${m['quantity']}';
    }).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _orders,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AsyncStateView(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }

        // Step 6: Orders table
        return Card(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Customer Name')),
                      DataColumn(label: Text('Products Ordered')),
                      DataColumn(label: Text('Total Amount')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data();
                      final total = ((data['total'] as num?) ?? 0).toDouble();
                      final raw =
                          (data['status'] ?? 'pending').toString().toLowerCase();
                      final status = _statuses.contains(raw) ? raw : 'pending';

                      return DataRow(
                        key: ValueKey(doc.id),
                        cells: [
                          DataCell(_CustomerName(key: ValueKey(doc.id), order: data)),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(
                                _itemsText(data['items']),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(Text('₱${total.toStringAsFixed(2)}')),
                           DataCell(
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                               decoration: BoxDecoration(
                                 color: _statusColor(status).shade50,
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(
                                   color: _statusColor(status).shade200,
                                 ),
                               ),
                               child: DropdownButton<String>(
                                 value: status,
                                 underline: const SizedBox.shrink(),
                                 dropdownColor: Colors.white,
                                 style: TextStyle(
                                   color: _statusColor(status).shade800,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 13,
                                 ),
                                 items: _statuses
                                     .map((s) => DropdownMenuItem(
                                           value: s,
                                           child: Text(_label(s)),
                                         ))
                                     .toList(),
                                 onChanged: (v) {
                                   if (v != null && v != status) {
                                     _updateStatus(doc.id, v);
                                   }
                                 },
                               ),
                             ),
                           ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Shows the customer's name. New orders store it directly (customerName);
// older orders only have userId, so the name is looked up from users.
class _CustomerName extends StatefulWidget {
  final Map<String, dynamic> order;
  const _CustomerName({super.key, required this.order});

  @override
  State<_CustomerName> createState() => _CustomerNameState();
}

class _CustomerNameState extends State<_CustomerName> {
  late final Future<String> _name = _resolve();

  Future<String> _resolve() async {
    final saved = widget.order['customerName'];
    if (saved is String && saved.isNotEmpty) return saved;

    final uid = widget.order['userId'];
    if (uid is! String) return 'Unknown';
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (doc.data()?['name'] as String?) ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _name,
      builder: (context, snapshot) => Text(snapshot.data ?? '...'),
    );
  }
}