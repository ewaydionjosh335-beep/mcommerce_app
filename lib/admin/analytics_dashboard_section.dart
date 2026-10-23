import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyticsDashboardSection extends StatelessWidget {
  const AnalyticsDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('orders').snapshots(),
      builder: (context, ordersSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('products').snapshots(),
          builder: (context, productsSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('users').snapshots(),
              builder: (context, usersSnap) {
                if (ordersSnap.hasError || productsSnap.hasError || usersSnap.hasError) {
                  return const Center(child: Text('Error loading analytics metrics'));
                }
                if (!ordersSnap.hasData || !productsSnap.hasData || !usersSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orderDocs = ordersSnap.data!.docs;
                final productDocs = productsSnap.data!.docs;
                final userDocs = usersSnap.data!.docs;

                double totalRevenue = 0;
                int pendingCount = 0;
                int processingCount = 0;
                int shippedCount = 0;
                int deliveredCount = 0;
                int cancelledCount = 0;

                for (final doc in orderDocs) {
                  final data = doc.data();
                  final total = ((data['total'] as num?) ?? 0).toDouble();
                  final status = (data['status'] ?? 'pending').toString().toLowerCase();

                  // Count revenue from non-cancelled orders (or all orders)
                  if (status != 'cancelled') {
                    totalRevenue += total;
                  }

                  switch (status) {
                    case 'pending':
                      pendingCount++;
                      break;
                    case 'processing':
                      processingCount++;
                      break;
                    case 'shipped':
                      shippedCount++;
                      break;
                    case 'delivered':
                      deliveredCount++;
                      break;
                    case 'cancelled':
                      cancelledCount++;
                      break;
                    default:
                      pendingCount++;
                  }
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Overview',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Key performance indicators and sales metrics in real-time.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      // KPI Grid Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          return GridView.count(
                            crossAxisCount: isWide ? 4 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isWide ? 1.3 : 1.2,
                            children: [
                              _KpiCard(
                                title: 'Total Revenue',
                                value: '₱${totalRevenue.toStringAsFixed(2)}',
                                icon: Icons.payments_outlined,
                                color: Colors.green,
                              ),
                              _KpiCard(
                                title: 'Total Orders',
                                value: '${orderDocs.length}',
                                icon: Icons.receipt_long_outlined,
                                color: Colors.blue,
                              ),
                              _KpiCard(
                                title: 'Products in Catalog',
                                value: '${productDocs.length}',
                                icon: Icons.inventory_2_outlined,
                                color: Colors.orange,
                              ),
                              _KpiCard(
                                title: 'Registered Users',
                                value: '${userDocs.length}',
                                icon: Icons.people_outline,
                                color: Colors.purple,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Order Status Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _StatusRow(label: 'Pending', count: pendingCount, color: Colors.indigo),
                              const Divider(height: 24),
                              _StatusRow(label: 'Processing', count: processingCount, color: Colors.orange),
                              const Divider(height: 24),
                              _StatusRow(label: 'Shipped', count: shippedCount, color: Colors.blue),
                              const Divider(height: 24),
                              _StatusRow(label: 'Delivered', count: deliveredCount, color: Colors.green),
                              const Divider(height: 24),
                              _StatusRow(label: 'Cancelled', count: cancelledCount, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color.shade700, size: 20),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final MaterialColor color;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.shade600,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.shade200),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
