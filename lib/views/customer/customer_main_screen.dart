import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 0,
        backgroundColor: Colors.white,
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
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
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
                        const Text(
                          'Welcome,',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          user.username.isNotEmpty ? user.username : 'Customer',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
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

            // Center: App Logo
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                AppConstants.logoPath,
                height: 38,
                fit: BoxFit.contain,
              ),
            ),

            // Right: Admin Portal Switch with Lock Icon
            InkWell(
              onTap: _handleAdminSwitchTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: admin.isLoggedIn
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: admin.isLoggedIn ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      admin.isLoggedIn ? Icons.admin_panel_settings : Icons.lock_outline_rounded,
                      size: 16,
                      color: admin.isLoggedIn ? AppColors.primary : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      admin.isLoggedIn ? 'Admin' : 'Owner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: admin.isLoggedIn ? AppColors.primary : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main Body Tabs
          IndexedStack(
            index: _currentTabIndex,
            children: [
              FavoritesTab(onBrowseHome: () => _onTabSelected(1)),
              const HomeCatalogTab(),
              CartTab(onBrowseHome: () => _onTabSelected(1)),
            ],
          ),

          // Floating Cart Bar (Appears when cart has items and not on cart tab)
          if (_currentTabIndex != 2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 84, // Sits right above the Bottom Deck Dock
              child: FloatingCartBar(
                onViewCart: () => _onTabSelected(2),
              ),
            ),

          // Bottom Deck Dock (Left=Favorites, Center=Elevated Home, Right=Cart)
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
