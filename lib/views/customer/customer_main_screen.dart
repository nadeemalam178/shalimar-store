import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/admin_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/bottom_deck_dock.dart';
import '../../widgets/floating_cart_bar.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_login_overlay.dart';
import 'profile_dialog.dart';
import 'tabs/cart_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/home_catalog_tab.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentTabIndex = 1; // Default to Middle: Home Catalog
  bool _showAdminLogin = false;

  void _onTabSelected(int index) {
    setState(() => _currentTabIndex = index);
  }

  void _handleAdminSwitchTap() {
    final admin = context.read<AdminProvider>();
    if (admin.isLoggedIn) {
      // Direct jump to admin portal
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      // Show background blur + Owner Sign In overlay
      setState(() => _showAdminLogin = true);
    }
  }

  Widget _buildActiveTab(int index) {
    switch (index) {
      case 0:
        return FavoritesTab(onBrowseHome: () => _onTabSelected(1));
      case 2:
        return CartTab(onBrowseHome: () => _onTabSelected(1));
      case 1:
      default:
        return const HomeCatalogTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final admin = context.watch<AdminProvider>();
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 0,
        backgroundColor: context.surfaceColor,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: User Greeting & Profile Shortcut
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const ProfileDialog(),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF262626) : AppColors.surfaceVariant.withAlpha(120),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: admin.isLoggedIn ? AppColors.accent.withAlpha(120) : context.borderSubtle),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: admin.isLoggedIn ? AppColors.accent : AppColors.primary,
                      child: Text(
                        admin.isLoggedIn ? '👑' : (user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(fontSize: 10, color: context.textSecondary),
                        ),
                        Text(
                          admin.isLoggedIn ? 'Owner' : (user.username.isNotEmpty ? user.username : 'Customer'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: admin.isLoggedIn ? AppColors.accent : context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Center: Perfectly Circular Logo with Golden Border (Never squares when scrolled)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  AppConstants.logoPath,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Right: Admin Portal Switch (ONLY visible when Store Owner is logged in)
            if (admin.isLoggedIn)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(width: 42),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main Body with Screen-Covering Animation into Cart
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final isCart = (child.key as ValueKey<int>?)?.value == 2;
              if (isCart) {
                // Expanding slide-up & scale effect covering the screen
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              }
              return FadeTransition(opacity: animation, child: child);
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentTabIndex),
              child: _buildActiveTab(_currentTabIndex),
            ),
          ),

          // Floating Cart Bar (Appears when cart has items, not on cart tab, and keyboard closed)
          if (_currentTabIndex != 2 && !keyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 84, // Sits right above the Bottom Deck Dock
              child: FloatingCartBar(
                onViewCart: () => _onTabSelected(2),
              ),
            ),

          // Bottom Deck Dock (Left=Favorites, Center=Elevated Home, Right=Cart) - Hidden during typing
          if (!keyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomDeckDock(
                currentIndex: _currentTabIndex,
                onTabSelected: _onTabSelected,
              ),
            ),

          // Blur + Admin Login Modal
          if (_showAdminLogin)
            AdminLoginOverlay(
              onDismiss: () => setState(() => _showAdminLogin = false),
              onLoginSuccess: () {
                setState(() => _showAdminLogin = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
        ],
      ),
    );
  }
}
