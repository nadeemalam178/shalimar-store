import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../customer/customer_main_screen.dart';
import 'add_edit_product_dialog.dart';
import 'store_settings_dialog.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: context.surfaceColor,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(AppConstants.logoPath),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    'Shalimar Store Control Panel',
                    style: TextStyle(fontSize: 10, color: context.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Store Settings & Password',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const StoreSettingsDialog(),
                );
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
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              tooltip: 'Sign Out Admin',
              onPressed: () async {
                await admin.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton.extended(
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

                  // Category Filter Chips with "+ Add Category" button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories Filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showAddCategoryDialog(context, catalogue),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '+ Add Category',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
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
                          // "+ Add Category" Chip
                          return ActionChip(
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.inStock
                                ? context.borderSubtle
                                : Colors.red.shade400,
                            width: item.inStock ? 1 : 1.5,
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
                        child: Row(
                          children: [
                            // Image or placeholder with local file support
                            Container(
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

                            // Edit Button
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
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
