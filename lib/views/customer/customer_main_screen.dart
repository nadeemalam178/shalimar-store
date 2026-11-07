import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/admin_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_config.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/bottom_deck_dock.dart';
import '../../widgets/floating_cart_bar.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_login_overlay.dart';
import 'customer_settings_dialog.dart';
import 'dialogs/store_heritage_dialog.dart';
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _broadcastSub;

  @override
  void initState() {
    super.initState();
    _listenToBroadcastNotifications();
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    super.dispose();
  }

  void _listenToBroadcastNotifications() {
    if (!FirebaseConfig.isInitialized) return;
    try {
      final firestore = FirebaseFirestore.instance;
      _broadcastSub = firestore
          .collection('broadcast_notifications')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first.data();
          final createdAt = (doc['createdAt'] as num?)?.toInt() ?? 0;
          final lastSeen = StorageService.getLastSeenBroadcastTimestamp();

          if (createdAt > lastSeen && lastSeen != 0) {
            final title = doc['title']?.toString() ?? 'Shalimar Store (Est. 1988)';
            final body = doc['body']?.toString() ?? '';
            NotificationService.showNotification(
              id: createdAt.hashCode,
              title: title,
              body: body,
            );
            StorageService.setLastSeenBroadcastTimestamp(createdAt);
          } else if (lastSeen == 0) {
            StorageService.setLastSeenBroadcastTimestamp(createdAt);
          }
        }
      }, onError: (err) {
        debugPrint('ℹ️ [CustomerMainScreen] Broadcast listener offline or skipped: $err');
      });
    } catch (e) {
      debugPrint('ℹ️ [CustomerMainScreen] Broadcast setup skipped: $e');
    }
  }

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
            // Left: User Greeting & Profile Shortcut (Only clickable in Customer mode)
            Flexible(
              child: InkWell(
                onTap: admin.isLoggedIn
                    ? null
                    : () {
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
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Center: Interactive Logo with Premium Golden Glow (Tap opens Store Heritage & Photos)
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const StoreHeritageDialog(),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFC68400), Color(0xFFFFE082)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC68400).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppConstants.logoPath,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Right: Settings Button (+ Admin Switch when Owner is logged in)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (admin.isLoggedIn) ...[
                  InkWell(
                    onTap: _handleAdminSwitchTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings, size: 14, color: AppColors.primary),
                          SizedBox(width: 3),
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
                  ),
                  const SizedBox(width: 6),
                ],
                // Settings Icon Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CustomerSettingsDialog(),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.isDark ? const Color(0xFF262626) : AppColors.surfaceVariant.withAlpha(120),
                        shape: BoxShape.circle,
                        border: Border.all(color: context.borderSubtle),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
