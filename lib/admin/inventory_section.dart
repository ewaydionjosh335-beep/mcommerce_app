import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/logger.dart';

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
      final newStock = product.stock + addQty;
      await _service.updateProduct(
        product.id,
        productName: product.productName,
        description: product.description,
        price: product.price,
        stock: newStock,
        imageUrl: product.imageUrl,
        category: product.category,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restocked ${product.productName} by +$addQty (New stock: $newStock)'),
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
          decoration: const InputDecoration(
            labelText: 'Add Stock Quantity',
            hintText: 'e.g., 20',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Inventory Management & Low-Stock Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FilterChip(
              label: Text(_lowStockOnly ? 'Showing Low Stock (<5)' : 'Showing All Products'),
              selected: _lowStockOnly,
              selectedColor: Colors.orange.shade100,
              onSelected: (val) => setState(() => _lowStockOnly = val),
              avatar: Icon(
                Icons.warning_amber_rounded,
                color: _lowStockOnly ? Colors.orange.shade800 : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _service.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data!;
              final filtered = _lowStockOnly
                  ? products.where((p) => p.stock < 5).toList()
                  : products;

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _lowStockOnly ? 'No low stock products found (All stocks >= 5)' : 'No products in inventory.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Product Name')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Current Stock')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Quick Restock Actions')),
                          ],
                          rows: filtered.map((p) {
                            final isLow = p.stock < 5;
                            return DataRow(
                              key: ValueKey(p.id),
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      if (isLow)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(Icons.warning, color: Colors.orange, size: 18),
                                        ),
                                      Text(
                                        p.productName,
                                        style: TextStyle(
                                          fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(p.category)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isLow ? Colors.red.shade200 : Colors.green.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      '${p.stock} units',
                                      style: TextStyle(
                                        color: isLow ? Colors.red.shade800 : Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text('₱${p.price.toStringAsFixed(2)}')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.add, size: 14),
                                        label: const Text('+10'),
                                        onPressed: () => _quickRestock(p, 10),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: const Size(60, 32),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.add, size: 14),
                                        label: const Text('+50'),
                                        onPressed: () => _quickRestock(p, 50),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: const Size(60, 32),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_note, color: Colors.indigo),
                                        tooltip: 'Custom Restock',
                                        onPressed: () => _showCustomRestockDialog(p),
                                      ),
                                    ],
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
          ),
        ),
      ],
    );
  }
}
