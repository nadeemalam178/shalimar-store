import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../models/product.dart';
import '../../providers/catalogue_provider.dart';
import '../../services/image_upload_service.dart';
import '../../services/product_draft_service.dart';

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
  bool _isSaving = false;
  bool _hasRestoredDraft = false;
  bool _isInitializing = false;
  Timer? _draftDebounce;

  final List<String> _standardUnits = [
    '1 kg',
    '500 gm',
    '250 gm',
    '100 gm',
    '50 gm',
    '2 kg',
    '5 kg',
    '10 kg',
    '1 Liter',
    '500 ml',
    '200 ml',
    '100 ml',
    '2 Liter',
    '5 Liter',
    '1 pc',
    '1 Packet',
    'Pack of 2',
    'Pack of 4',
    'Pack of 6',
    '1 Box',
    '1 Strip',
    '1 Bottle',
    '1 Can',
  ];

  late String _selectedUnit;
  bool _isCustomUnit = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toString() : '');
    _mrpCtrl = TextEditingController(text: p != null ? p.mrp.toString() : '');
    final initialUnit = p?.unit ?? '1 kg';
    _unitCtrl = TextEditingController(text: initialUnit);
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? 'General';
    _inStock = p?.inStock ?? true;

    if (_standardUnits.contains(initialUnit)) {
      _selectedUnit = initialUnit;
      _isCustomUnit = false;
    } else {
      _selectedUnit = 'Custom';
      _isCustomUnit = true;
    }

    if (p != null && p.imageUrl.isNotEmpty) {
      if (File(p.imageUrl).existsSync()) {
        _localImagePath = p.imageUrl;
      }
    }

    _nameCtrl.addListener(_onFieldChanged);
    _priceCtrl.addListener(_onFieldChanged);
    _mrpCtrl.addListener(_onFieldChanged);
    _unitCtrl.addListener(_onFieldChanged);
    _imageCtrl.addListener(_onFieldChanged);
    _descCtrl.addListener(_onFieldChanged);

    // Load any persisted draft (separate for New vs Edit) and recover lost camera image
    _initDraftAndLostData();
  }

  void _onFieldChanged() {
    if (_isInitializing) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 350), () {
      _saveCurrentDraft();
    });
  }

  Future<void> _initDraftAndLostData() async {
    _isInitializing = true;
    try {
      // 1. Check for saved draft (separate for New vs Edit product)
      final draft = await ProductDraftService.loadDraft(
        productId: widget.productToEdit?.id,
      );
      if (draft != null && !draft.isEmpty && mounted) {
        setState(() {
          if (draft.name.isNotEmpty) _nameCtrl.text = draft.name;
          if (draft.price.isNotEmpty) _priceCtrl.text = draft.price;
          if (draft.mrp.isNotEmpty) _mrpCtrl.text = draft.mrp;
          if (draft.unit.isNotEmpty) {
            _unitCtrl.text = draft.unit;
            if (_standardUnits.contains(draft.unit)) {
              _selectedUnit = draft.unit;
              _isCustomUnit = false;
            } else {
              _selectedUnit = 'Custom';
              _isCustomUnit = true;
            }
          }
          if (draft.category.isNotEmpty) _category = draft.category;
          _descCtrl.text = draft.description;
          _inStock = draft.inStock;
          if (draft.localImagePath != null && File(draft.localImagePath!).existsSync()) {
            _localImagePath = draft.localImagePath;
            _imageCtrl.text = draft.localImagePath!;
          } else if (draft.imageUrl != null && draft.imageUrl!.isNotEmpty) {
            _imageCtrl.text = draft.imageUrl!;
            if (draft.imageUrl!.startsWith('http')) {
              _showUrlField = true;
            }
          }
          _hasRestoredDraft = true;
        });
      }

      // 2. Check for lost camera image on Android activity recreation
      await _retrieveLostImage();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _retrieveLostImage() async {
    try {
      final picker = ImagePicker();
      final response = await picker.retrieveLostData();
      if (response.isEmpty) return;
      final file = response.file;
      if (file != null && mounted) {
        setState(() {
          _localImagePath = file.path;
          _imageCtrl.text = file.path;
        });
        await _saveCurrentDraft();
      }
    } catch (e) {
      debugPrint('ℹ️ [AddEditProduct] retrieveLostData check: $e');
    }
  }

  Future<void> _saveCurrentDraft() async {
    if (!mounted) return;

    // Avoid saving if completely empty new product form
    if (widget.productToEdit == null &&
        _nameCtrl.text.trim().isEmpty &&
        _priceCtrl.text.trim().isEmpty &&
        _mrpCtrl.text.trim().isEmpty &&
        _descCtrl.text.trim().isEmpty &&
        _localImagePath == null &&
        _imageCtrl.text.trim().isEmpty) {
      return;
    }

    final draft = ProductDraft(
      productId: widget.productToEdit?.id,
      name: _nameCtrl.text,
      category: _category,
      price: _priceCtrl.text,
      mrp: _mrpCtrl.text,
      unit: _unitCtrl.text,
      isCustomUnit: _isCustomUnit,
      description: _descCtrl.text,
      inStock: _inStock,
      localImagePath: _localImagePath,
      imageUrl: _imageCtrl.text,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    await ProductDraftService.saveDraft(draft);
  }

  Future<void> _discardDraftAndReset() async {
    await ProductDraftService.clearDraft(productId: widget.productToEdit?.id);
    final p = widget.productToEdit;
    setState(() {
      _nameCtrl.text = p?.name ?? '';
      _priceCtrl.text = p != null ? p.price.toString() : '';
      _mrpCtrl.text = p != null ? p.mrp.toString() : '';
      final initialUnit = p?.unit ?? '1 kg';
      _unitCtrl.text = initialUnit;
      if (_standardUnits.contains(initialUnit)) {
        _selectedUnit = initialUnit;
        _isCustomUnit = false;
      } else {
        _selectedUnit = 'Custom';
        _isCustomUnit = true;
      }
      _imageCtrl.text = p?.imageUrl ?? '';
      _descCtrl.text = p?.description ?? '';
      _category = p?.category ?? 'General';
      _inStock = p?.inStock ?? true;
      if (p != null && p.imageUrl.isNotEmpty && File(p.imageUrl).existsSync()) {
        _localImagePath = p.imageUrl;
      } else {
        _localImagePath = null;
      }
      _hasRestoredDraft = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft discarded. Form reset to original.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _hasUnsavedChanges() {
    final p = widget.productToEdit;
    if (p == null) {
      return _nameCtrl.text.trim().isNotEmpty ||
          _priceCtrl.text.trim().isNotEmpty ||
          _mrpCtrl.text.trim().isNotEmpty ||
          _descCtrl.text.trim().isNotEmpty ||
          _localImagePath != null ||
          (_imageCtrl.text.trim().isNotEmpty && !_imageCtrl.text.startsWith('http'));
    } else {
      return _nameCtrl.text.trim() != p.name ||
          _priceCtrl.text.trim() != (p.price == 0 ? '' : p.price.toString()) ||
          _mrpCtrl.text.trim() != (p.mrp == 0 ? '' : p.mrp.toString()) ||
          _unitCtrl.text.trim() != p.unit ||
          _category != p.category ||
          _inStock != p.inStock ||
          _descCtrl.text.trim() != p.description ||
          (_localImagePath != null && _localImagePath != p.imageUrl) ||
          _imageCtrl.text.trim() != p.imageUrl;
    }
  }

  Future<bool> _showDiscardConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'You have unsaved changes in this form. Would you like to keep this draft for later or discard it?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          OutlinedButton(
            onPressed: () async {
              await _saveCurrentDraft();
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Keep Draft'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ProductDraftService.clearDraft(productId: widget.productToEdit?.id);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _nameCtrl.removeListener(_onFieldChanged);
    _priceCtrl.removeListener(_onFieldChanged);
    _mrpCtrl.removeListener(_onFieldChanged);
    _unitCtrl.removeListener(_onFieldChanged);
    _imageCtrl.removeListener(_onFieldChanged);
    _descCtrl.removeListener(_onFieldChanged);

    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _unitCtrl.dispose();
    _imageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // Immediately persist current draft before launching external camera/gallery activity
    await _saveCurrentDraft();

    try {
      final picker = ImagePicker();
      // On Samsung devices, requesting raw full 50MP/108MP camera capture exhausts RAM.
      // Setting maxWidth: 1024, maxHeight: 1024, imageQuality: 80 keeps memory low and fast.
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null && mounted) {
        setState(() {
          _localImagePath = picked.path;
          _imageCtrl.text = picked.path;
        });
        await _saveCurrentDraft();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final price = double.tryParse(_priceCtrl.text) ?? 0.0;
      final mrp = double.tryParse(_mrpCtrl.text) ?? price;
      final catalogue = context.read<CatalogueProvider>();
      final imagePath = _imageCtrl.text.trim();
      String finalImageUrl = imagePath;

      final uploadId = widget.productToEdit?.id ?? const Uuid().v4();

      // ── Upload image to Supabase Storage if local image is selected ──
      if (_localImagePath != null && File(_localImagePath!).existsSync() && !imagePath.startsWith('http')) {
        try {
          final file = File(_localImagePath!);
          final bytes = await file.readAsBytes();
          final fileName = _localImagePath!.split(RegExp(r'[/\\]')).last;

          final publicUrl = await ImageUploadService.uploadProductImage(
            productId: uploadId,
            bytes: bytes,
            fileName: fileName,
          );

          if (publicUrl != null && publicUrl.isNotEmpty) {
            finalImageUrl = publicUrl;
          } else {
            // Upload returned null or failed -> alert admin and do not save with unusable local path
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Image upload failed. Please check internet connection or storage permissions.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() => _isSaving = false);
            return;
          }
        } catch (uploadErr) {
          debugPrint('⚠️ [AddEditProduct] Image upload to Supabase failed: $uploadErr');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Image upload failed: $uploadErr'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      if (widget.productToEdit == null) {
        // Add new product & sync to Firestore
        await catalogue.addProduct(
          id: uploadId,
          name: _nameCtrl.text.trim(),
          category: _category,
          price: price,
          mrp: mrp,
          unit: _unitCtrl.text.trim(),
          imageUrl: finalImageUrl,
          inStock: _inStock,
          description: _descCtrl.text.trim(),
        );
      } else {
        // Edit existing product & sync to Firestore
        await catalogue.updateProduct(
          widget.productToEdit!.copyWith(
            name: _nameCtrl.text.trim(),
            category: _category,
            price: price,
            mrp: mrp,
            unit: _unitCtrl.text.trim(),
            imageUrl: finalImageUrl,
            inStock: _inStock,
            description: _descCtrl.text.trim(),
          ),
        );
      }

      // Clear draft after successful add or update
      await ProductDraftService.clearDraft(productId: widget.productToEdit?.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productToEdit == null ? '✅ Product added & synced to cloud!' : '✅ Product updated & synced!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ [AddEditProduct] Error saving product: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  Widget _buildRestoredDraftBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Restored unsaved draft',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: _discardDraftAndReset,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Discard Draft',
              style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardConfirmationDialog();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Dialog(
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
                      onPressed: () async {
                        if (_hasUnsavedChanges()) {
                          final shouldPop = await _showDiscardConfirmationDialog();
                          if (shouldPop && context.mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
                Divider(height: 16, color: context.borderSubtle),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restored Draft Banner if recovered
                        if (_hasRestoredDraft) _buildRestoredDraftBanner(),

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

                      // Category Dropdown (Dynamic from CatalogueProvider)
                      Builder(
                        builder: (context) {
                          final catalogue = context.watch<CatalogueProvider>();
                          final availableCats = catalogue.categories.where((c) => c != 'All').toList();
                          if (!availableCats.contains('General')) availableCats.add('General');
                          if (!availableCats.contains(_category) && _category.isNotEmpty) {
                            availableCats.insert(0, _category);
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: availableCats.contains(_category) ? _category : availableCats.first,
                                  decoration: const InputDecoration(labelText: 'Category *'),
                                  items: availableCats.map((c) {
                                    return DropdownMenuItem(value: c, child: Text(c));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _category = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                tooltip: 'Create New Category',
                                onPressed: () {
                                  final textCtrl = TextEditingController();
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      content: TextField(
                                        controller: textCtrl,
                                        autofocus: true,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: const InputDecoration(labelText: 'Category Name'),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final name = textCtrl.text.trim();
                                            if (name.isNotEmpty) {
                                              await catalogue.addCategory(name);
                                              setState(() => _category = name);
                                              if (ctx.mounted) Navigator.pop(ctx);
                                            }
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
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

                      // Standardized Pack Size / Unit Dropdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _isCustomUnit ? 'Custom' : _selectedUnit,
                              decoration: const InputDecoration(labelText: 'Pack Size / Unit *'),
                              items: [
                                ..._standardUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))),
                                const DropdownMenuItem(value: 'Custom', child: Text('✍️ Custom Unit...')),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                if (val == 'Custom') {
                                  setState(() {
                                    _selectedUnit = 'Custom';
                                    _isCustomUnit = true;
                                  });
                                } else {
                                  setState(() {
                                    _selectedUnit = val;
                                    _isCustomUnit = false;
                                    _unitCtrl.text = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_isCustomUnit) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _unitCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Specify Custom Unit *',
                            hintText: 'e.g. 750 ml, 1 Bundle, 1 Dozen',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please specify unit' : null,
                        ),
                      ],
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
                      onPressed: () async {
                        await ProductDraftService.clearDraft(productId: widget.productToEdit!.id);
                        if (context.mounted) {
                          context.read<CatalogueProvider>().deleteProduct(widget.productToEdit!.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product deleted'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Add to Catalogue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
