import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/catalogue_provider.dart';

class ManageCategoriesDialog extends StatelessWidget {
  const ManageCategoriesDialog({super.key});

  void _confirmDeleteCategory(
    BuildContext context,
    CatalogueProvider catalogue,
    String categoryName,
    int productCount,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Delete "$categoryName"?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          productCount > 0
              ? 'This category has $productCount product(s). Deleting it will safely move those products to the "General" category.\n\nAre you sure?'
              : 'Are you sure you want to delete the category "$categoryName"?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await catalogue.removeCategory(categoryName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$categoryName" deleted.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: const Text('Delete Category'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryPrompt(BuildContext context, CatalogueProvider catalogue) {
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
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Organic Pulses, Frozen Foods',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                await catalogue.addCategory(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "$name" added!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueProvider>();
    final allCats = catalogue.categories.where((c) => c != 'All').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.surfaceColor,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Manage Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 16, color: context.borderSubtle),
            const SizedBox(height: 6),
            Text(
              'Add, review, or delete product departments. Deleting a category with items will reassign those items to "General".',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 14),

            // Add Category Quick Button
            InkWell(
              onTap: () => _showAddCategoryPrompt(context, catalogue),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Create New Category',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category List
            Expanded(
              child: allCats.isEmpty
                  ? Center(
                      child: Text(
                        'No custom categories found.',
                        style: TextStyle(color: context.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: allCats.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: context.borderSubtle),
                      itemBuilder: (context, index) {
                        final cat = allCats[index];
                        final productCount =
                            catalogue.products.where((p) => p.category == cat).length;
                        final isProtected = cat == 'General';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withAlpha(30),
                            child: const Icon(Icons.folder_outlined, size: 16, color: AppColors.primary),
                          ),
                          title: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '$productCount product(s)',
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                          trailing: isProtected
                              ? Tooltip(
                                  message: 'Default system category',
                                  child: Icon(Icons.lock_outline, size: 18, color: context.textSecondary),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  tooltip: 'Delete category',
                                  onPressed: () => _confirmDeleteCategory(
                                    context,
                                    catalogue,
                                    cat,
                                    productCount,
                                  ),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

