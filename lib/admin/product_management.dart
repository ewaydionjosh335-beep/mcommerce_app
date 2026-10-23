import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/logger.dart';
import '../utils/validation_exception.dart';
import '../widgets/async_state_view.dart';

InputDecoration _dec(String label, {String? prefix}) => InputDecoration(
      labelText: label,
      prefixText: prefix,
      border: const OutlineInputBorder(),
    );

// HOA04 Activity 2: Product CRUD (form, table, update, delete)
class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final _service = ProductService();
  late final Stream<List<Product>> _products = _service.getProducts();

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // Step 2 + 3 (Add) and Step 5 (Update): one form used for both
  Future<void> _showProductForm({Product? product}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: product?.productName ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final price =
        TextEditingController(text: product == null ? '' : '${product.price}');
    final stock =
        TextEditingController(text: product == null ? '' : '${product.stock}');
    final imageUrl = TextEditingController(text: product?.imageUrl ?? '');
    final category = TextEditingController(text: product?.category ?? 'Electronics');
    const availableCategories = ['Electronics', 'Clothing', 'Home', 'Beauty', 'Food', 'General'];
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => saving = true);
            try {
              final priceValue = double.parse(price.text.trim());
              final stockValue = int.parse(stock.text.trim());
              final categoryValue = category.text.trim();
              if (product == null) {
                await _service.addProduct(
                  productName: name.text.trim(),
                  description: description.text.trim(),
                  price: priceValue,
                  stock: stockValue,
                  imageUrl: imageUrl.text.trim(),
                  category: categoryValue,
                );
              } else {
                await _service.updateProduct(
                  product.id,
                  productName: name.text.trim(),
                  description: description.text.trim(),
                  price: priceValue,
                  stock: stockValue,
                  imageUrl: imageUrl.text.trim(),
                  category: categoryValue,
                );
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                _snack(product == null ? 'Product added' : 'Product updated');
              }
            } on ValidationException catch (e) {
              setDialogState(() => saving = false);
              if (mounted) _snack(e.message);
            } on FirebaseException catch (e, s) {
              logError('ProductForm', e, s);
              setDialogState(() => saving = false);
              if (mounted) _snack(e.message ?? 'Failed to save product');
            } catch (e, s) {
              logError('ProductForm', e, s);
              setDialogState(() => saving = false);
              if (mounted) _snack('Something went wrong. Please try again.');
            }
          }

          return AlertDialog(
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: _dec('Product Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: availableCategories.contains(category.text) ? category.text : 'Electronics',
                        decoration: _dec('Category'),
                        items: availableCategories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) category.text = v;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        decoration: _dec('Description'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _dec('Price', prefix: '₱ '),
                        validator: (v) {
                          // note: double.tryParse accepts "NaN" and "Infinity"
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n.isNaN || n.isInfinite || n <= 0) {
                            return 'Price must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: stock,
                        keyboardType: TextInputType.number,
                        decoration: _dec('Stock'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0) return 'Enter a whole number (0 or more)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: imageUrl,
                        keyboardType: TextInputType.url,
                        decoration: _dec('Image URL'),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return 'Required';
                          if (!t.startsWith('http')) return 'Must start with http';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(product == null ? 'Save' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Step 5: Delete (asks for confirmation first)
  Future<void> _confirmDelete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.productName}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteProduct(product.id);
      if (mounted) _snack('Product deleted');
    } on FirebaseException catch (e) {
      if (mounted) _snack(e.message ?? 'Failed to delete product');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showProductForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _products,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AsyncStateView(error: snapshot.error);
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = snapshot.data!;
              if (products.isEmpty) {
                return const Center(
                  child: Text('No products yet. Tap "Add Product".'),
                );
              }

              // Step 4: Product table
              return Card(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Product Name')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Edit')),
                            DataColumn(label: Text('Delete')),
                          ],
                          rows: products
                              .map(
                                (p) => DataRow(
                                  key: ValueKey(p.id),
                                  cells: [
                                    DataCell(Text(p.productName)),
                                    DataCell(Text(p.category)),
                                    DataCell(
                                        Text('₱${p.price.toStringAsFixed(2)}')),
                                    DataCell(Text('${p.stock}')),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Edit',
                                        onPressed: () =>
                                            _showProductForm(product: p),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () => _confirmDelete(p),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
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