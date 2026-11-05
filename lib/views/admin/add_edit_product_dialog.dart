import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../providers/catalogue_provider.dart';

class AddEditProductDialog extends StatefulWidget {
  final Product? productToEdit;

  const AddEditProductDialog({super.key, this.productToEdit});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _descCtrl;
  late String _category;
  late bool _inStock;

  final List<String> _commonCategories = [
    'Atta, Rice & Grains',
    'Oils & Ghee',
    'Dals & Pulses',
    'Spices & Masale',
    'Dairy & Breakfast',
    'Snacks & Biscuits',
    'Beverages & Tea',
    'Cleaning & Household',
    'Personal Care',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toString() : '');
    _mrpCtrl = TextEditingController(text: p != null ? p.mrp.toString() : '');
    _unitCtrl = TextEditingController(text: p?.unit ?? '1 kg');
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? 'Atta, Rice & Grains';
    if (!_commonCategories.contains(_category)) {
      _commonCategories.insert(0, _category);
    }
    _inStock = p?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _unitCtrl.dispose();
    _imageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final mrp = double.tryParse(_mrpCtrl.text) ?? price;
    final catalogue = context.read<CatalogueProvider>();

    if (widget.productToEdit == null) {
      // Add new
      catalogue.addProduct(
        name: _nameCtrl.text.trim(),
        category: _category,
        price: price,
        mrp: mrp,
        unit: _unitCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        inStock: _inStock,
        description: _descCtrl.text.trim(),
      );
    } else {
      // Edit existing
      catalogue.updateProduct(
        widget.productToEdit!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _category,
          price: price,
          mrp: mrp,
          unit: _unitCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          inStock: _inStock,
          description: _descCtrl.text.trim(),
        ),
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.productToEdit == null ? 'Product added!' : 'Product updated!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 480,
        ),
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Product' : 'Add New Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'e.g. Aashirvaad Shudh Chakki Atta',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _commonCategories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Price & MRP
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (₹) *',
                                hintText: '245',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _mrpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Original MRP (₹)',
                                hintText: '270',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pack Unit
                      TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Pack Size / Unit *',
                          hintText: 'e.g. 5 kg, 1 Liter, 500 gm, 1 pc',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Image URL
                      TextFormField(
                        controller: _imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Image Web URL (Optional)',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Stock Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Available In Stock',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _inStock ? 'Customers can add this item' : 'Marked as Out of Stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: _inStock ? AppColors.success : Colors.red,
                          ),
                        ),
                        activeColor: AppColors.success,
                        value: _inStock,
                        onChanged: (val) => setState(() => _inStock = val),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        context.read<CatalogueProvider>().deleteProduct(widget.productToEdit!.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product deleted'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(isEditing ? 'Save Changes' : 'Add to Catalogue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
