import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/async_state_view.dart';

// HOA04: User Monitoring (list of registered users + customer profile inspector)
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
        if (snapshot.hasError) {
          return AsyncStateView(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs.toList()
          ..sort((a, b) => (a.data()['name'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b.data()['name'] ?? '').toString().toLowerCase()));

        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();
        }

        if (docs.isEmpty && _searchQuery.isEmpty) {
          return const Center(child: Text('No users yet.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            Text('Total users: ${docs.length} (Click Inspect to view customer order history & lifetime spend)'),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
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
                                DataCell(Text('${data['name'] ?? '—'}')),
                                DataCell(Text('${data['email'] ?? '—'}')),
                                DataCell(Text(
                                  role,
                                  style: TextStyle(
                                    fontWeight: role == 'admin'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                )),
                                DataCell(
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.visibility_outlined, size: 14),
                                    label: const Text('Inspect'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      minimumSize: const Size(70, 30),
                                    ),
                                    onPressed: () => _inspectUser(doc.id, data),
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
    final name = (userData['name'] as String?) ?? '—';
    final email = (userData['email'] as String?) ?? '—';
    final phone = (userData['phone'] as String?) ?? (userData['phoneNumber'] as String?) ?? '—';
    final address = (userData['address'] as String?) ?? (userData['shippingAddress'] as String?) ?? '—';
    final role = (userData['role'] ?? 'user').toString();

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.shade100,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(email, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact & Address Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact & Address Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Phone: $phone', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Address: $address', style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Role: $role', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Order History & Lifetime Spend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading orders');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orderDocs = snapshot.data?.docs ?? [];
                  double lifetimeSpend = 0;
                  for (final doc in orderDocs) {
                    final data = doc.data();
                    final status = (data['status'] ?? 'pending').toString().toLowerCase();
                    if (status != 'cancelled') {
                      lifetimeSpend += ((data['total'] as num?) ?? 0).toDouble();
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Lifetime Spend:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                            Text('₱${lifetimeSpend.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 18)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (orderDocs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('No orders placed by this customer yet.')),
                        )
                      else
                        ...orderDocs.map((doc) {
                          final data = doc.data();
                          final total = ((data['total'] as num?) ?? 0).toDouble();
                          final status = (data['status'] ?? 'pending').toString().toLowerCase();
                          final payment = (data['paymentMethod'] as String?) ?? 'COD';
                          final items = (data['items'] as List?) ?? [];
                          final itemsText = items.map((i) {
                            final m = Map<String, dynamic>.from(i as Map);
                            return '${m['productName']} x${m['quantity']}';
                          }).join(', ');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Order #${doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(itemsText, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Payment: $payment', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    Text('₱${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
