import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/logger.dart';
import '../widgets/async_state_view.dart';
import '../widgets/admin_common.dart';

// HOA04 Activity 3: Order Management (display orders + update status)
class OrdersSection extends StatefulWidget {
  const OrdersSection({super.key});

  @override
  State<OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<OrdersSection> {
  static const _statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

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
  Future<void> _updateStatusWithConfirmation(String orderId, String currentStatus, String newStatus) async {
    if (newStatus == 'cancelled' || newStatus == 'delivered') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Update Order Status to ${_label(newStatus)}?'),
          content: Text('Are you sure you want to mark order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)} as $newStatus?${newStatus == 'cancelled' ? ' This will restore product stock.' : ''}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: newStatus == 'cancelled' ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white) : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(newStatus == 'cancelled' ? 'Confirm Cancel' : 'Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _updateStatus(orderId, newStatus);
  }

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

        // Step 6: Orders table / responsive view
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            if (isMobile) {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final total = ((data['total'] as num?) ?? 0).toDouble();
                  final raw = (data['status'] ?? 'pending').toString().toLowerCase();
                  final status = _statuses.contains(raw) ? raw : 'pending';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Text('Customer: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                                    Expanded(child: _CustomerName(key: ValueKey(doc.id), order: data)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                initialValue: status,
                                onSelected: (v) {
                                  if (v != status) {
                                    _updateStatusWithConfirmation(doc.id, status, v);
                                  }
                                },
                                itemBuilder: (context) => _statuses
                                    .map((s) => PopupMenuItem(
                                          value: s,
                                          child: Text(_label(s)),
                                        ))
                                    .toList(),
                                child: StatusChip(status: status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Items: ${_itemsText(data['items'])}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total: ₱${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade800, fontSize: 15)),
                              Text('ID: #${doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return Card(
              child: SingleChildScrollView(
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
                               PopupMenuButton<String>(
                                 initialValue: status,
                                  onSelected: (v) {
                                    if (v != status) {
                                      _updateStatusWithConfirmation(doc.id, status, v);
                                    }
                                  },
                                 itemBuilder: (context) => _statuses
                                     .map((s) => PopupMenuItem(
                                           value: s,
                                           child: Text(_label(s)),
                                         ))
                                     .toList(),
                                 child: StatusChip(status: status),
                               ),
                             ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Shows the customer's name from order document (denormalized customerName or userId).
class _CustomerName extends StatelessWidget {
  final Map<String, dynamic> order;
  const _CustomerName({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final saved = order['customerName'];
    if (saved is String && saved.isNotEmpty) {
      return Text(saved);
    }
    final uid = order['userId'];
    if (uid is String && uid.isNotEmpty) {
      return Text(uid);
    }
    return const Text('Unknown');
  }
}