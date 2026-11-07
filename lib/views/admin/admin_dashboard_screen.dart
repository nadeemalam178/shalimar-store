import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../auth/login_screen.dart';
import '../customer/customer_main_screen.dart';
import 'add_edit_product_dialog.dart';
import 'admin_side_panel_drawer.dart';
import 'manage_categories_dialog.dart';
import 'store_settings_dialog.dart';
import '../../widgets/full_screen_image_viewer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchFilter = '';
  String _selectedCategory = 'All';
  String _selectedStockFilter = 'All'; // 'All', 'In Stock', 'Out of Stock'
  bool _isBreakdownExpanded = true;
  final _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Multi-Select Mode
  bool _isSelectionMode = false;
  final Set<String> _selectedProductIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String initialProductId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedProductIds.add(initialProductId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProductIds.clear();
    });
  }

  void _toggleProductSelection(String productId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
        if (_selectedProductIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _selectAllProducts(List<Product> products) {
    setState(() {
      if (_selectedProductIds.length == products.length) {
        _selectedProductIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedProductIds.addAll(products.map((p) => p.id));
      }
    });
  }

  Future<void> _handleBatchDelete(CatalogueProvider catalogue) async {
    final count = _selectedProductIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Delete $count Products?', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete $count selected products? This will remove them from the store catalogue and cloud database.',
          style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete $count Items'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final idsToDelete = List<String>.from(_selectedProductIds);
      _exitSelectionMode();

      for (final id in idsToDelete) {
        await catalogue.deleteProduct(id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $count products.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleBatchMoveCategory(CatalogueProvider catalogue) async {
    final count = _selectedProductIds.length;
    if (count == 0) return;

    final targetCategory = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.drive_file_move_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Move $count Products to Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Select destination category for the $count selected products:',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: catalogue.categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final cat = catalogue.categories[index];
                    if (cat == 'All') return const SizedBox.shrink();
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_outlined, color: AppColors.primary, size: 20),
                      title: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      onTap: () => Navigator.pop(ctx, cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (targetCategory != null && targetCategory.isNotEmpty && mounted) {
      final idsToMove = List<String>.from(_selectedProductIds);
      _exitSelectionMode();

      for (final id in idsToMove) {
        final existing = catalogue.products.firstWhere((p) => p.id == id, orElse: () => catalogue.products.first);
        if (existing.id == id) {
          final updated = existing.copyWith(category: targetCategory);
          await catalogue.updateProduct(updated);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved $count products to "$targetCategory".'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddCategoryDialog(
    BuildContext context,
    CatalogueProvider catalogue,
  ) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.category_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Add New Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a new department/category for Shalimar Store. It will instantly appear for both admin and customers.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Organic Pulses, Frozen Foods, Cold Drinks',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                catalogue.addCategory(name);
                setState(() => _selectedCategory = name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$name" added & live immediately!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueProvider>();
    final admin = context.read<AdminProvider>();

    final allItems = catalogue.products;
    final outOfStockCount = allItems.where((p) => !p.inStock).length;
    final inStockCount = allItems.length - outOfStockCount;

    // Group out-of-stock items by category
    final Map<String, List<Product>> outOfStockByCategory = {};
    for (final item in allItems) {
      if (!item.inStock) {
        outOfStockByCategory.putIfAbsent(item.category, () => []).add(item);
      }
    }

    final displayedItems = allItems.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesStock =
          _selectedStockFilter == 'All' ||
          (_selectedStockFilter == 'In Stock' && p.inStock) ||
          (_selectedStockFilter == 'Out of Stock' && !p.inStock);
      final matchesSearch =
          _searchFilter.isEmpty ||
          p.name.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          p.unit.toLowerCase().contains(_searchFilter.toLowerCase());
      return matchesCategory && matchesStock && matchesSearch;
    }).toList();

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.scaffoldBg,
        endDrawer: const AdminSidePanelDrawer(),
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: context.surfaceColor,
                elevation: 2,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cancel Selection',
                  onPressed: _exitSelectionMode,
                ),
                title: Text(
                  '${_selectedProductIds.length} Selected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _selectAllProducts(displayedItems),
                    child: Text(
                      _selectedProductIds.length == displayedItems.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_rounded, color: AppColors.primary),
                    tooltip: 'Move to Category',
                    onPressed: () => _handleBatchMoveCategory(catalogue),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                    tooltip: 'Delete Selected',
                    onPressed: () => _handleBatchDelete(catalogue),
                  ),
                ],
              )
            : AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: context.surfaceColor,
                elevation: 0,
                titleSpacing: 16,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(AppConstants.logoPath),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.dashboard_customize_rounded, color: AppColors.primary),
                    tooltip: 'Control Hub (Insights, AI, QR, Settings)',
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Switch to Customer View',
                    onPressed: () {
                      admin.exitAdminMode();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: context.textPrimary),
                    tooltip: 'More Options',
                    onSelected: (val) async {
                      if (val == 'categories') {
                        showDialog(
                          context: context,
                          builder: (_) => const ManageCategoriesDialog(),
                        );
                      } else if (val == 'settings') {
                        showDialog(
                          context: context,
                          builder: (_) => const StoreSettingsDialog(),
                        );
                      } else if (val == 'logout') {
                        await admin.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'categories',
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Manage Categories', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Store Settings & Password', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Sign Out Admin', style: TextStyle(fontSize: 13, color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddEditProductDialog(),
                  );
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Add Product',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // KPI Stat Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Items',
                          value: '${allItems.length}',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'In Stock',
                          value: '$inStockCount',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Out of Stock',
                          value: '$outOfStockCount',
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Out of Stock Inventory Breakdown Dashboard
                  _buildOutOfStockDashboard(
                    outOfStockByCategory: outOfStockByCategory,
                    outOfStockCount: outOfStockCount,
                    catalogue: catalogue,
                  ),

                  const SizedBox(height: 12),

                  // Rounded Search Bar (48dp Pill)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchFilter = val),
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText:
                              'Search 1,000+ items by name, unit, category...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          suffixIcon: _searchFilter.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: context.textSecondary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchFilter = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Stock Filter Segmented Control (All / In Stock / Out of Stock)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildStockFilterChip(
                          'All',
                          'All (${allItems.length})',
                        ),
                        const SizedBox(width: 8),
                        _buildStockFilterChip(
                          'In Stock',
                          'In Stock ($inStockCount)',
                        ),
                        const SizedBox(width: 8),
                        _buildStockFilterChip(
                          'Out of Stock',
                          'Out of Stock ($outOfStockCount)',
                          isDanger: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Category Filter Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories Filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.textSecondary,
                        ),
                      ),
                      Text(
                        '${catalogue.categories.length - 1} categories',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: catalogue.categories.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        if (index == catalogue.categories.length) {
                          // "+ Add Category" & "Manage" Chips
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  'New Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onPressed: () =>
                                    _showAddCategoryDialog(context, catalogue),
                              ),
                              const SizedBox(width: 6),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                label: const Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: context.surfaceColor,
                                side: BorderSide(
                                  color: context.borderSubtle,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => const ManageCategoriesDialog(),
                                ),
                              ),
                            ],
                          );
                        }

                        final cat = catalogue.categories[index];
                        final isSelected = _selectedCategory == cat;
                        final count = cat == 'All'
                            ? allItems.length
                            : allItems.where((p) => p.category == cat).length;
                        final outCount = cat == 'All'
                            ? outOfStockCount
                            : (outOfStockByCategory[cat]?.length ?? 0);

                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$cat ($count)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textPrimary,
                                ),
                              ),
                              if (outCount > 0 && cat != 'All') ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$outCount',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: context.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.borderSubtle,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${displayedItems.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      if (_selectedCategory != 'All' ||
                          _selectedStockFilter != 'All' ||
                          _searchFilter.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedCategory = 'All';
                              _selectedStockFilter = 'All';
                              _searchFilter = '';
                            });
                          },
                          child: const Text(
                            'Reset Filters',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Inventory Table / List (Virtualized for 1,000+ items performance)
          displayedItems.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No products match your filter',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = displayedItems[index];
                      final isSelected = _selectedProductIds.contains(item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (item.inStock
                                    ? context.borderSubtle
                                    : Colors.red.shade400),
                            width: isSelected ? 2 : (item.inStock ? 1 : 1.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: context.isDark ? 0.25 : 0.02,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _enterSelectionMode(item.id);
                              }
                            },
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleProductSelection(item.id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Selection checkbox indicator in selection mode
                                  if (_isSelectionMode) ...[
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      color: isSelected ? AppColors.primary : Colors.grey,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                  ],

                                  // Image or placeholder with local file support & Full-Screen Pinch Zoom
                                  GestureDetector(
                                    onTap: () {
                                      if (item.imageUrl.isNotEmpty) {
                                        FullScreenImageViewer.open(
                                          context,
                                          imageUrl: item.imageUrl,
                                          title: item.name,
                                          subtitle: '${item.category} • ${item.unit}',
                                          price: item.price,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: context.isDark
                                            ? const Color(0xFF262626)
                                            : AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _buildItemImage(item.imageUrl),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: item.inStock
                                                ? context.textPrimary
                                                : context.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.category} • ${item.unit}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          CurrencyFormatter.format(item.price),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: item.inStock
                                                ? AppColors.primary
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Stock Switch (1-tap toggle)
                                  if (!_isSelectionMode)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: item.inStock,
                                          activeThumbColor: AppColors.success,
                                          inactiveThumbColor: Colors.red,
                                          onChanged: (_) =>
                                              catalogue.toggleStock(item.id),
                                        ),
                                        Text(
                                          item.inStock ? 'In Stock' : 'Out of Stock',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: item.inStock
                                                ? AppColors.success
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Edit & Share Action Buttons (Hidden during Selection Mode)
                                  if (!_isSelectionMode)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.share_outlined,
                                            size: 19,
                                            color: Color(0xFF25D366),
                                          ),
                                          tooltip: 'Share on WhatsApp',
                                          onPressed: () {
                                            WhatsAppHelper.shareProduct(
                                              context: context,
                                              name: item.name,
                                              category: item.category,
                                              price: item.price,
                                              mrp: item.mrp,
                                              unit: item.unit,
                                              imageUrl: item.imageUrl,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          tooltip: 'Edit Product Details',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  AddEditProductDialog(productToEdit: item),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: displayedItems.length),
                  ),
                ),
        ],
      ),
    ),
  );
}

  Widget _buildStockFilterChip(
    String key,
    String label, {
    bool isDanger = false,
  }) {
    final isSelected = _selectedStockFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDanger ? Colors.red : context.textPrimary),
        ),
      ),
      selected: isSelected,
      selectedColor: isDanger ? Colors.red : AppColors.primary,
      backgroundColor: isDanger
          ? (context.isDark ? const Color(0xFF2B1212) : Colors.red.shade50)
          : context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? (isDanger ? Colors.red : AppColors.primary)
              : (isDanger ? Colors.red.shade400 : context.borderSubtle),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStockFilter = key);
        }
      },
    );
  }

  Widget _buildOutOfStockDashboard({
    required Map<String, List<Product>> outOfStockByCategory,
    required int outOfStockCount,
    required CatalogueProvider catalogue,
  }) {
    if (outOfStockCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF142918)
              : AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '100% Stock Availability',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'All products across all categories are currently in stock.',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF261212) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark ? const Color(0xFF5E1B1B) : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          // Collapsible Header
          InkWell(
            onTap: () =>
                setState(() => _isBreakdownExpanded = !_isBreakdownExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Out-of-Stock Inventory Dashboard',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '$outOfStockCount items out of stock across ${outOfStockByCategory.length} categories',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isBreakdownExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Breakdown List
          if (_isBreakdownExpanded) ...[
            const Divider(height: 1, color: Color(0xFFFFCDD2)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: outOfStockByCategory.keys.length,
              itemBuilder: (context, catIdx) {
                final categoryName = outOfStockByCategory.keys.elementAt(
                  catIdx,
                );
                final items = outOfStockByCategory[categoryName]!;

                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    border: catIdx < outOfStockByCategory.keys.length - 1
                        ? Border(bottom: BorderSide(color: Colors.red.shade100))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header with quick filter button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.folder_open_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${items.length} missing',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = categoryName;
                                _selectedStockFilter = 'Out of Stock';
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Filter list below →',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // List of out-of-stock items under this category with instant 1-tap Restock
                      ...items.map((prod) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${prod.name} (${prod.unit})',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(prod.price),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  catalogue.toggleStock(prod.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${prod.name} marked IN STOCK!',
                                      ),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Restock',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.shopping_basket_outlined,
        size: 20,
        color: AppColors.primary,
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.shopping_basket_outlined,
          size: 20,
          color: AppColors.primary,
        ),
      );
    }
    final file = File(imageUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.shopping_basket_outlined,
          size: 20,
          color: AppColors.primary,
        ),
      );
    }
    return const Icon(
      Icons.shopping_basket_outlined,
      size: 20,
      color: AppColors.primary,
    );
  }
}
