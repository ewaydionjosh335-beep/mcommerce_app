import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/app_theme.dart';
import '../utils/logger.dart';
import '../utils/validation_exception.dart';
import '../widgets/admin_common.dart';
import '../widgets/async_state_view.dart';

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

  Future<void> _showProductForm({Product? product}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: product?.productName ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final price =
        TextEditingController(text: product == null ? '' : '${product.price}');
    final imageUrl = TextEditingController(text: product?.imageUrl ?? '');
    final category = TextEditingController(text: product?.category ?? 'Electronics');
    const availableCategories = ['Electronics', 'Clothing', 'Home', 'Beauty', 'Food', 'General'];

    final Map<String, TextEditingController> sizeControllers = {};
    if (product != null && product.sizes.isNotEmpty) {
      product.sizes.forEach((s, stockVal) {
        sizeControllers[s] = TextEditingController(text: '$stockVal');
      });
    } else {
      for (final s in ['S', 'M', 'L', 'XL']) {
        sizeControllers[s] = TextEditingController(text: '10');
      }
    }

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            if (sizeControllers.isEmpty) {
              _snack('Please add at least one size with stock.');
              return;
            }

            setDialogState(() => saving = true);
            try {
              final priceValue = double.parse(price.text.trim());
              final categoryValue = category.text.trim();
              
              final Map<String, int> sizesMap = {};
              sizeControllers.forEach((sizeName, controller) {
                final stockInt = int.tryParse(controller.text.trim()) ?? 0;
                sizesMap[sizeName.trim()] = stockInt;
              });

              if (product == null) {
                await _service.addProduct(
                  productName: name.text.trim(),
                  description: description.text.trim(),
                  price: priceValue,
                  sizes: sizesMap,
                  imageUrl: imageUrl.text.trim(),
                  category: categoryValue,
                );
              } else {
                await _service.updateProduct(
                  product.id,
                  productName: name.text.trim(),
                  description: description.text.trim(),
                  price: priceValue,
                  sizes: sizesMap,
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

          void addSizeRow() {
            showDialog(
              context: dialogContext,
              builder: (ctx) => _AddSizeDialog(
                onAdd: (sName, sStock) {
                  setDialogState(() {
                    sizeControllers[sName] = TextEditingController(text: '$sStock');
                  });
                },
              ),
            );
          }

          return AlertDialog(
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Product Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      DropdownButtonFormField<String>(
                        initialValue: availableCategories.contains(category.text) ? category.text : 'Electronics',
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) {
                          if (v != null) category.text = v;
                        },
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      TextFormField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Price', prefixText: '₱ '),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Price must be > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sizes & Stock', style: Theme.of(context).textTheme.titleSmall),
                          OutlinedButton.icon(
                            onPressed: addSizeRow,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Size'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      ...sizeControllers.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                              const SizedBox(width: AppSpacing.s8),
                              Expanded(flex: 3, child: TextFormField(
                                controller: entry.value,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Stock'),
                                validator: (v) => (int.tryParse((v ?? '').trim()) == null || int.parse(v!) < 0) ? 'Invalid' : null,
                              )),
                              const SizedBox(width: AppSpacing.s8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                onPressed: () => setDialogState(() => sizeControllers.remove(entry.key)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.s12),
                      TextFormField(
                        controller: imageUrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(labelText: 'Image URL'),
                        validator: (v) => ((v ?? '').trim().isEmpty || !(v ?? '').startsWith('http')) ? 'Valid URL required' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: saving ? null : save,
                child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(product == null ? 'Save' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.productName}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
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
      logError('ProductDelete', e);
      if (mounted) _snack(e.message ?? 'Failed to delete product');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Product Management',
          subtitle: 'Manage your product catalog, prices, and stock.',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _products,
            builder: (context, snapshot) {
              if (snapshot.hasError) return AsyncStateView(error: snapshot.error);
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final products = snapshot.data!;
              if (products.isEmpty) return const Center(child: Text('No products yet.'));

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  if (isMobile) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
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
                                        p.productName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(p.category, style: TextStyle(fontSize: 12, color: Colors.indigo.shade700, fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Price: ₱${p.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo.shade800)),
                                    Text('Stock: ${p.stock}', style: TextStyle(color: p.stock == 0 ? Colors.red : Colors.grey.shade700)),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showProductForm(product: p),
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                                      onPressed: () => _confirmDelete(p),
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      label: const Text('Delete'),
                                    ),
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
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Stock')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: products.map((p) => DataRow(
                              cells: [
                                DataCell(Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(p.category)),
                                DataCell(Text('₱${p.price.toStringAsFixed(2)}')),
                                DataCell(Text('${p.stock}')),
                                DataCell(Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showProductForm(product: p)),
                                    IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _confirmDelete(p)),
                                  ],
                                )),
                              ],
                            )).toList(),
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

class _AddSizeDialog extends StatefulWidget {
  final Function(String, int) onAdd;
  const _AddSizeDialog({required this.onAdd});

  @override
  State<_AddSizeDialog> createState() => _AddSizeDialogState();
}

class _AddSizeDialogState extends State<_AddSizeDialog> {
  final _sizeController = TextEditingController();
  final _stockController = TextEditingController(text: '10');

  @override
  void dispose() {
    _sizeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Size & Stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sizeController,
            decoration: const InputDecoration(labelText: 'Size Name'),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock Quantity'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final sName = _sizeController.text.trim();
            final sStock = int.tryParse(_stockController.text.trim()) ?? 0;
            if (sName.isNotEmpty) {
              widget.onAdd(sName, sStock);
            }
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
