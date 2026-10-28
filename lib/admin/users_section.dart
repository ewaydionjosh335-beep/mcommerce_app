import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/admin_common.dart';
import '../widgets/async_state_view.dart';

class UsersSection extends StatefulWidget {
  const UsersSection({super.key});

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _users =
      FirebaseFirestore.instance.collection('users').snapshots();

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _inspectUser(String userId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => CustomerDetailsDialog(userId: userId, userData: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _users,
      builder: (context, snapshot) {
        if (snapshot.hasError) return AsyncStateView(error: snapshot.error);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.toList();
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();
        }

        return Column(
          children: [
            PageHeader(
              title: 'User Management',
              subtitle: 'Monitor user base and inspect customer profiles.',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s16),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      : null,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  if (isMobile) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final role = (data['role'] ?? 'user').toString();
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
                                      child: Text(
                                        data['name'] ?? '—',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: role == 'admin' ? Colors.purple.shade50 : Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(role, style: TextStyle(fontSize: 12, color: role == 'admin' ? Colors.purple.shade700 : Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Email: ${data['email'] ?? '—'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                const Divider(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton(
                                    onPressed: () => _inspectUser(doc.id, data),
                                    child: const Text('Inspect'),
                                  ),
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
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data();
                              final role = (data['role'] ?? 'user').toString();
                              return DataRow(
                                key: ValueKey(doc.id),
                                cells: [
                                  DataCell(Text(data['name'] ?? '—')),
                                  DataCell(Text(data['email'] ?? '—')),
                                  DataCell(Text(role, style: TextStyle(fontWeight: role == 'admin' ? FontWeight.bold : FontWeight.normal))),
                                  DataCell(OutlinedButton(
                                    onPressed: () => _inspectUser(doc.id, data),
                                    child: const Text('Inspect'),
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class CustomerDetailsDialog extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const CustomerDetailsDialog({super.key, required this.userId, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (userData['name'] as String?) ?? '—';
    final email = (userData['email'] as String?) ?? '—';

    return AlertDialog(
      title: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U')),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(email),
        ),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    children: [
                      _infoRow(Icons.phone, 'Phone', userData['phone']?.toString() ?? '—'),
                      const Divider(),
                      _infoRow(Icons.location_on, 'Address', userData['address']?.toString() ?? '—'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text('Order History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.s8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return AsyncStateView(error: snapshot.error);
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: LinearProgressIndicator());
                  }
                  final orderDocs = snapshot.data!.docs;
                  if (orderDocs.isEmpty) {
                    return const AsyncStateView(
                      isEmpty: true,
                      emptyMessage: 'No orders found for this customer.',
                    );
                  }
                  
                  return Column(
                    children: orderDocs.map((doc) {
                      final data = doc.data();
                      final total = ((data['total'] as num?) ?? 0).toDouble();
                      final status = (data['status'] ?? 'pending').toString().toLowerCase();

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text('Order #${doc.id.substring(0, 8)}'),
                          subtitle: Text('Total: ₱${total.toStringAsFixed(2)}'),
                          trailing: StatusChip(status: status),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [Icon(icon, size: 16), const SizedBox(width: AppSpacing.s8), Text('$label: $value')],
  );
}
