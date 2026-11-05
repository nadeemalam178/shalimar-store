import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
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
  String? _localImagePath;
  bool _showUrlField = false;

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

    if (p != null && p.imageUrl.isNotEmpty) {
      if (File(p.imageUrl).existsSync()) {
        _localImagePath = p.imageUrl;
      }
    }
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked != null) {
        setState(() {
          _localImagePath = picked.path;
          _imageCtrl.text = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera/gallery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final mrp = double.tryParse(_mrpCtrl.text) ?? price;
    final catalogue = context.read<CatalogueProvider>();

    final imagePath = _imageCtrl.text.trim();

    if (widget.productToEdit == null) {
      // Add new
      catalogue.addProduct(
        name: _nameCtrl.text.trim(),
        category: _category,
        price: price,
        mrp: mrp,
        unit: _unitCtrl.text.trim(),
        imageUrl: imagePath,
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
          imageUrl: imagePath,
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

  Widget _buildImagePreview() {
    final hasLocal = _localImagePath != null && File(_localImagePath!).existsSync();
    final hasUrl = _imageCtrl.text.startsWith('http');

    if (hasLocal || hasUrl) {
      return Stack(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasLocal
                  ? Image.file(
                      File(_localImagePath!),
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _imageCtrl.text,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black.withAlpha(160),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.red.withAlpha(200),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _localImagePath = null;
                        _imageCtrl.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
          const SizedBox(height: 8),
          const Text(
            'Product Photo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Capture Photo', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16, color: AppColors.primary),
                  label: const Text('Upload File', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _showUrlField = !_showUrlField),
            child: Text(
              _showUrlField ? 'Hide Web URL Option' : 'Or paste Web Image URL',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 480,
        ),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderSubtle),
        ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 16, color: context.borderSubtle),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Capture & Upload Box
                      _buildImagePreview(),
                      if (_showUrlField) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _imageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Image Web URL',
                            hintText: 'https://...',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      const SizedBox(height: 14),

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
                        initialValue: _category,
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
                          _inStock ? 'In Stock (Visible to Customers)' : 'Out of Stock (Greyed Out)',
                          style: TextStyle(
                            fontSize: 12,
                            color: _inStock ? AppColors.success : Colors.red,
                          ),
                        ),
                        activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.success,
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
