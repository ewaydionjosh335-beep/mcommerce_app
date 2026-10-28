import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/app_theme.dart';
import '../utils/logger.dart';
import '../widgets/admin_common.dart';
import '../widgets/async_state_view.dart';

class InventorySection extends StatefulWidget {
  const InventorySection({super.key});

  @override
  State<InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<InventorySection> {
  final _service = ProductService();
  bool _lowStockOnly = false;

  Future<void> _quickRestock(Product product, int addQty) async {
    try {
      final updatedSizes = Map<String, int>.from(product.sizes);
      if (updatedSizes.isNotEmpty) {
        final firstKey = updatedSizes.keys.first;
        updatedSizes[firstKey] = (updatedSizes[firstKey] ?? 0) + addQty;
      } else {
        updatedSizes['Standard'] = addQty;
      }
      await _service.updateProduct(
        product.id,
        productName: product.productName,
        description: product.description,
        price: product.price,
        sizes: updatedSizes,
        imageUrl: product.imageUrl,
        category: product.category,
      );
      if (!mounted) return;
      final newTotal = product.stock + addQty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restocked ${product.productName} by +$addQty (New stock: $newTotal)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, s) {
      logError('Inventory', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update stock'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _showCustomRestockDialog(Product product) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Quick Restock: ${product.productName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Add Stock Quantity', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text.trim()) ?? 0;
              if (qty > 0) {
                Navigator.pop(dialogContext);
                _quickRestock(product, qty);
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Inventory Management',
          subtitle: 'Monitor stock levels and perform quick restocks.',
          actions: [
            FilterChip(
              label: Text(_lowStockOnly ? 'Low Stock Only' : 'All Products'),
              selected: _lowStockOnly,
              onSelected: (val) => setState(() => _lowStockOnly = val),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _service.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return AsyncStateView(error: snapshot.error);
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final products = snapshot.data!;
              final filtered = _lowStockOnly ? products.where((p) => p.stock < 5).toList() : products;

              if (filtered.isEmpty) {
                return const Center(child: Text('No inventory items match the criteria.'));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  if (isMobile) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final isLow = p.stock < 5;
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
                                          if (isLow) const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                                          if (isLow) const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              p.productName,
                                              style: TextStyle(fontWeight: isLow ? FontWeight.bold : FontWeight.w600, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusChip(status: '${p.stock} units'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Category: ${p.category}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    Text('Price: ₱${p.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo.shade800)),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(onPressed: () => _quickRestock(p, 10), child: const Text('+10')),
                                    const SizedBox(width: 8),
                                    ElevatedButton(onPressed: () => _quickRestock(p, 50), child: const Text('+50')),
                                    const SizedBox(width: 8),
                                    IconButton(icon: const Icon(Icons.edit_note), onPressed: () => _showCustomRestockDialog(p)),
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
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            columns: const [
                              DataColumn(label: Text('Product')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Stock')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Restock')),
                            ],
                            rows: filtered.map((p) {
                              final isLow = p.stock < 5;
                              return DataRow(
                                key: ValueKey(p.id),
                                cells: [
                                  DataCell(Row(
                                    children: [
                                      if (isLow) const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                                      if (isLow) const SizedBox(width: AppSpacing.s8),
                                      Text(p.productName, style: TextStyle(fontWeight: isLow ? FontWeight.bold : FontWeight.w500)),
                                    ],
                                  )),
                                  DataCell(Text(p.category)),
                                  DataCell(StatusChip(status: '${p.stock} units')),
                                  DataCell(Text('₱${p.price.toStringAsFixed(2)}')),
                                  DataCell(Row(
                                    children: [
                                      ElevatedButton(onPressed: () => _quickRestock(p, 10), child: const Text('+10')),
                                      const SizedBox(width: AppSpacing.s8),
                                      ElevatedButton(onPressed: () => _quickRestock(p, 50), child: const Text('+50')),
                                      const SizedBox(width: AppSpacing.s8),
                                      IconButton(icon: const Icon(Icons.edit_note), onPressed: () => _showCustomRestockDialog(p)),
                                    ],
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
              );
            },
          ),
        ),
      ],
    );
  }
}
