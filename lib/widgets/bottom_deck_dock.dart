import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/theme_extensions.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';

class BottomDeckDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const BottomDeckDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = context.watch<UserProvider>();
    final favCount = user.favoriteProductIds.length;
    final cartCount = cart.totalItemCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left: Favorites / Wishlist
          _buildDeckItem(
            context,
            index: 0,
            icon: currentIndex == 0 ? Icons.favorite : Icons.favorite_border,
            label: 'Favorites',
            badgeCount: favCount,
            isSelected: currentIndex == 0,
            onTap: () => onTabSelected(0),
          ),

          // Middle: Home (Slightly Larger Elevated Icon Button)
          _buildCenterHomeButton(
            isSelected: currentIndex == 1,
            onTap: () => onTabSelected(1),
          ),

          // Right: Cart
          _buildDeckItem(
            context,
            index: 2,
            icon: currentIndex == 2
                ? Icons.shopping_bag
                : Icons.shopping_bag_outlined,
            label: 'My Cart',
            badgeCount: cartCount,
            isSelected: currentIndex == 2,
            onTap: () => onTabSelected(2),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterHomeButton({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, isSelected ? -8 : 0, 0),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppColors.brandGradient
                : const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: isSelected ? 0.45 : 0.25,
                ),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
              if (isSelected)
                const BoxShadow(
                  color: Color(0xFFFFD54F),
                  blurRadius: 2,
                  spreadRadius: 1.5,
                ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.storefront_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeckItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required int badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(
                  alpha: context.isDark ? 0.22 : 0.08,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : context.textSecondary,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
