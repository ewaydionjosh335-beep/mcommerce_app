import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/admin_common.dart';
import '../widgets/async_state_view.dart';

class AnalyticsDashboardSection extends StatelessWidget {
  const AnalyticsDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      future: Future.wait([
        db.collection('orders').limit(200).get(),
        db.collection('products').limit(200).get(),
        db.collection('users').limit(200).get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AsyncStateView(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ordersSnap = snapshot.data![0];
        final productsSnap = snapshot.data![1];
        final usersSnap = snapshot.data![2];

        final orderDocs = ordersSnap.docs;
        final productDocs = productsSnap.docs;
        final userDocs = usersSnap.docs;

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
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageHeader(
                        title: 'Dashboard Overview',
                        subtitle: 'Real-time key performance indicators and sales metrics.',
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          return GridView.count(
                            crossAxisCount: isWide ? 4 : 2,
                            crossAxisSpacing: AppSpacing.s16,
                            mainAxisSpacing: AppSpacing.s16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isWide ? 1.3 : 1.2,
                            children: [
                              StatCard(
                                title: 'Total Revenue',
                                value: '₱${totalRevenue.toStringAsFixed(2)}',
                                icon: Icons.payments_outlined,
                                color: AppColors.success,
                                trend: '+12.5%',
                                isPositiveTrend: true,
                              ),
                              StatCard(
                                title: 'Total Orders',
                                value: '${orderDocs.length}',
                                icon: Icons.receipt_long_outlined,
                                color: AppColors.info,
                                trend: '+8.2%',
                                isPositiveTrend: true,
                              ),
                              StatCard(
                                title: 'Products in Catalog',
                                value: '${productDocs.length}',
                                icon: Icons.inventory_2_outlined,
                                color: AppColors.secondaryLight,
                              ),
                              StatCard(
                                title: 'Registered Users',
                                value: '${userDocs.length}',
                                icon: Icons.people_outline,
                                color: AppColors.purple,
                                trend: '+4.1%',
                                isPositiveTrend: true,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.s32),
                      Text(
                        'Order Status Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s24),
                          child: Column(
                            children: [
                              _StatusRow(label: 'Pending', count: pendingCount, color: AppColors.warning),
                              const Divider(height: AppSpacing.s24),
                              _StatusRow(label: 'Processing', count: processingCount, color: AppColors.info),
                              const Divider(height: AppSpacing.s24),
                              _StatusRow(label: 'Shipped', count: shippedCount, color: AppColors.purple),
                              const Divider(height: AppSpacing.s24),
                              _StatusRow(label: 'Delivered', count: deliveredCount, color: AppColors.success),
                              const Divider(height: AppSpacing.s24),
                              _StatusRow(label: 'Cancelled', count: cancelledCount, color: AppColors.danger),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
