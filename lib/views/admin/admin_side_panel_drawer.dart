import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../models/user_model.dart';
import '../../providers/catalogue_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import '../../services/update_service.dart';

/// Unified, sleek Admin Side Panel Drawer.
/// Consolidates all admin operations without cluttering the main dashboard:
/// - Tab 0: 📊 Insights & CRM (Registered customers, WhatsApp metrics, inventory)
/// - Tab 1: ✨ Gemini Pro AI Hub (Step-by-step key setup, ping verification, unlocked features & broadcast push)
/// - Tab 2: 📲 App Sharing & QR Code (Instant QR code for latest arm64-v8a APK)
/// - Tab 3: ⚙️ Store Settings (Delivery banner, timings, OTA update check)
class AdminSidePanelDrawer extends StatefulWidget {
  final int initialTabIndex;

  const AdminSidePanelDrawer({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminSidePanelDrawer> createState() => _AdminSidePanelDrawerState();
}

class _AdminSidePanelDrawerState extends State<AdminSidePanelDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Tab 0: Insights state ──
  int _customerCount = 0;
  int _whatsAppOrderCount = 0;
  double _whatsAppTotalRevenue = 0.0;
  List<UserModel> _customers = [];
  List<LoggedOrder> _recentOrders = [];
  bool _isLoadingInsights = true;
  String _customerSearch = '';

  // ── Tab 1: Gemini AI state ──
  late TextEditingController _apiKeyCtrl;
  bool _isObscureKey = true;
  bool _isTestingKey = false;
  String? _keyVerificationMessage;
  bool? _isKeyValid;
  bool _isGeneratingBroadcast = false;
  List<GeminiBroadcastDraft> _generatedBroadcasts = [];
  String _selectedBroadcastTheme = 'Weekend Deals';
  final TextEditingController _customBroadcastTitleCtrl = TextEditingController();
  final TextEditingController _customBroadcastBodyCtrl = TextEditingController();
  bool _isBroadcasting = false;

  // ── Tab 2: QR & App Sharing ──
  static const String _arm64ApkUrl =
      'https://github.com/nadeemalam178/Shalimar-Store/releases/latest/download/app-arm64-v8a-release.apk';
  static const String _releasesUrl =
      'https://github.com/nadeemalam178/Shalimar-Store/releases/latest';

  // ── Tab 3: Settings state ──
  late TextEditingController _bannerCtrl;
  late TextEditingController _timingsCtrl;
  bool _isCheckingUpdate = false;
  String? _updateStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    _apiKeyCtrl = TextEditingController(text: StorageService.getGeminiApiKey());
    if (StorageService.isGeminiConfigured()) {
      _isKeyValid = true;
      _keyVerificationMessage = 'Gemini 1.5 Pro: Active & Connected';
    }

    _bannerCtrl = TextEditingController(
      text: '⚡ Free Home Delivery in Alam Ganj Area • Minimum Order ₹200',
    );
    _timingsCtrl = TextEditingController(
      text: AppConstants.storeHours,
    );

    _fetchInsightsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyCtrl.dispose();
    _customBroadcastTitleCtrl.dispose();
    _customBroadcastBodyCtrl.dispose();
    _bannerCtrl.dispose();
    _timingsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInsightsData() async {
    setState(() => _isLoadingInsights = true);
    try {
      final customers = await AnalyticsService.fetchRegisteredCustomers();
      final stats = await AnalyticsService.fetchOrderAnalytics();

      if (mounted) {
        setState(() {
          _customers = customers;
          _customerCount = customers.length;
          _whatsAppOrderCount = stats.totalOrders;
          _whatsAppTotalRevenue = stats.totalRevenue;
          _recentOrders = stats.recentOrders;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [SidePanel] Insights load error: $e');
      if (mounted) {
        setState(() => _isLoadingInsights = false);
      }
    }
  }

  // ── Gemini Handlers ──
  Future<void> _testAndSaveGeminiKey() async {
    final key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() {
        _isKeyValid = false;
        _keyVerificationMessage = 'Please enter or paste an API Key.';
      });
      return;
    }

    setState(() {
      _isTestingKey = true;
      _keyVerificationMessage = 'Verifying with Google Gemini API...';
      _isKeyValid = null;
    });

    final res = await GeminiService.verifyApiKey(key);

    if (mounted) {
      setState(() {
        _isTestingKey = false;
        _isKeyValid = res.success;
        _keyVerificationMessage = res.message;
      });

      if (res.success) {
        await StorageService.setGeminiApiKey(key);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Gemini Pro Connected & Saved Successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  Future<void> _disconnectGeminiKey() async {
    await StorageService.setGeminiApiKey('');
    setState(() {
      _apiKeyCtrl.clear();
      _isKeyValid = false;
      _keyVerificationMessage = null;
      _generatedBroadcasts.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API Key removed. AI features locked.'),
        ),
      );
    }
  }

  Future<void> _generateAiBroadcastCopies() async {
    final catalogue = context.read<CatalogueProvider>();
    setState(() => _isGeneratingBroadcast = true);

    final drafts = await GeminiService.generatePromotionalBroadcast(
      inStockProducts: catalogue.products.where((p) => p.inStock).toList(),
      theme: _selectedBroadcastTheme,
    );

    if (mounted) {
      setState(() {
        _generatedBroadcasts = drafts;
        _isGeneratingBroadcast = false;
      });
    }
  }

  Future<void> _sendBroadcast(String title, String body, String category) async {
    setState(() => _isBroadcasting = true);

    final ok = await GeminiService.broadcastNotificationToCustomers(
      title: title,
      body: body,
      targetCategory: category,
    );

    if (mounted) {
      setState(() => _isBroadcasting = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📢 Broadcast Sent to All Customers: "$title"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  // ── QR & Sharing Handlers ──
  Future<void> _shareOnWhatsApp() async {
    const msg =
        'Namaste! Download the official Shalimar Store (Est. 1988) grocery app for Android:\n$_arm64ApkUrl';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyDownloadLink() async {
    await Clipboard.setData(const ClipboardData(text: _arm64ApkUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Direct arm64-v8a APK download link copied!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // ── Update Check ──
  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatus = 'Checking GitHub releases...';
    });

    try {
      final info = await UpdateService.checkForUpdate();
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
          _updateStatus = info.hasUpdate
              ? '✨ New Version Available: v${info.latestVersion}'
              : '✅ Shalimar Store is Up to Date (v${AppConstants.appVersion})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
          _updateStatus = 'Unable to check update: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueProvider>();
    final isDark = context.isDark;

    return Drawer(
      width: MediaQuery.of(context).size.width > 500
          ? 440
          : MediaQuery.of(context).size.width * 0.90,
      backgroundColor: context.scaffoldBg,
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(bottom: BorderSide(color: context.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFC68400)],
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppConstants.logoPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shalimar Control Hub',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const Text(
                          'Owner Management & AI Tools',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Tab Bar Navigation ──
            Container(
              color: context.surfaceColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Insights'),
                  Tab(icon: Icon(Icons.auto_awesome_rounded, size: 20), text: 'Gemini AI'),
                  Tab(icon: Icon(Icons.qr_code_rounded, size: 20), text: 'Share App'),
                  Tab(icon: Icon(Icons.settings_rounded, size: 20), text: 'Settings'),
                ],
              ),
            ),

            // ── Tab Bar Views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInsightsTab(catalogue, isDark),
                  _buildGeminiAiTab(catalogue, isDark),
                  _buildShareAppTab(isDark),
                  _buildSettingsTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 0: Insights & CRM
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInsightsTab(CatalogueProvider catalogue, bool isDark) {
    if (_isLoadingInsights) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final filteredCustomers = _customers.where((c) {
      if (_customerSearch.isEmpty) return true;
      final q = _customerSearch.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchInsightsData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Customers',
                    value: '$_customerCount',
                    subtitle: 'Registered users',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'WhatsApp Orders',
                    value: '$_whatsAppOrderCount',
                    subtitle: CurrencyFormatter.format(_whatsAppTotalRevenue),
                    icon: Icons.chat_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Inventory Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInventoryStat('Total Items', '${catalogue.products.length}', Colors.blue),
                  _buildInventoryStat('In Stock', '${catalogue.products.where((p) => p.inStock).length}', AppColors.success),
                  _buildInventoryStat('Out of Stock', '${catalogue.products.where((p) => !p.inStock).length}', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Registered Customer Directory
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Directory (${_customers.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.redAccent),
                      tooltip: 'Clear All Customers (Reset to 0)',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: context.surfaceColor,
                            title: const Text('Reset Customer Directory?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            content: const Text('Are you sure you want to delete all registered customer accounts? This will set the customer count to 0.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Reset to 0', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await AnalyticsService.clearAllRegisteredCustomers();
                          await _fetchInsightsData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ All previous customers deleted. Count reset to 0.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Refresh',
                      onPressed: _fetchInsightsData,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search customer by name, phone, address...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderSubtle),
                ),
              ),
              onChanged: (val) => setState(() => _customerSearch = val),
            ),
            const SizedBox(height: 10),

            if (filteredCustomers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    _customers.isEmpty
                        ? 'No registered customers yet.'
                        : 'No customers match "$_customerSearch"',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCustomers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final cust = filteredCustomers[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cust.name.isNotEmpty ? cust.name : 'Guest Customer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              if (cust.phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  cust.phone,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                              if (cust.address.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  cust.address,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (cust.phone.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.accent),
                            tooltip: 'Chat on WhatsApp',
                            onPressed: () => WhatsAppHelper.launchWhatsAppChat(
                              phoneNumber: cust.phone,
                              message: 'Namaste ${cust.name}! Shalimar Store (Est. 1988) se sampark kar rahe hain.',
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // Recent Orders section
            if (_recentOrders.isNotEmpty) ...[
              Text(
                'Recent WhatsApp Orders (${_recentOrders.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentOrders.take(6).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final ord = _recentOrders[idx];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ord.customerName.isNotEmpty ? ord.customerName : 'Customer Order',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${ord.itemCount} items • ${ord.timestamp.day}/${ord.timestamp.month}/${ord.timestamp.year}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(ord.totalAmount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: Gemini Pro AI Hub
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGeminiAiTab(CatalogueProvider catalogue, bool isDark) {
    final isConfigured = StorageService.isGeminiConfigured() && _isKeyValid == true;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Banner ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isConfigured
                  ? AppColors.success.withValues(alpha: 0.12)
                  : Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConfigured ? AppColors.success : Colors.amber.shade700,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConfigured ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: isConfigured ? AppColors.success : Colors.amber.shade800,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConfigured
                            ? 'Google Gemini 1.5 Pro: Active'
                            : 'Gemini Pro API Key Required',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isConfigured ? AppColors.success : Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        isConfigured
                            ? 'AI Vision, copywriter & automated push notifications unlocked.'
                            : 'Follow the 4 steps below to connect your Gemini Pro plan.',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isConfigured) ...[
                  TextButton(
                    onPressed: _disconnectGeminiKey,
                    child: const Text('Change', style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Step-by-Step API Key Setup Card ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step-by-Step API Key Setup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Open AI Studio'),
                      onPressed: () async {
                        final uri = Uri.parse('https://aistudio.google.com/app/apikey');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildGuideStep('1', 'Tap "Open AI Studio" to visit aistudio.google.com/app/apikey.'),
                _buildGuideStep('2', 'Sign in with your Google Account having Gemini Pro plan.'),
                _buildGuideStep('3', 'Click "+ Create API key" and copy the key (AIzaSy...).'),
                _buildGuideStep('4', 'Paste the key below and tap "Verify & Connect".'),
                const Divider(height: 20),

                // API Key Input
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: _isObscureKey,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'Paste AIzaSy... here',
                    prefixIcon: const Icon(Icons.key_rounded, size: 20),
                    isDense: true,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isObscureKey ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _isObscureKey = !_isObscureKey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.content_paste_rounded, size: 18),
                          tooltip: 'Paste',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _apiKeyCtrl.text = data!.text!.trim();
                            }
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                if (_keyVerificationMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isKeyValid ?? false)
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (_isKeyValid ?? false) ? Icons.check_circle : Icons.error_outline,
                          size: 16,
                          color: (_isKeyValid ?? false) ? AppColors.success : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _keyVerificationMessage!,
                            style: TextStyle(
                              fontSize: 11,
                              color: (_isKeyValid ?? false) ? AppColors.success : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isTestingKey ? null : _testAndSaveGeminiKey,
                    child: _isTestingKey
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Verify & Connect Gemini Pro', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Conditional Gemini Features Section ──
          Text(
            'Gemini Pro AI Features Suite',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          if (!isConfigured) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Column(
                children: [
                  Icon(Icons.lock_rounded, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text(
                    'AI Features Locked',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter and verify your Gemini Pro API key above to unlock Vision Photo-to-Product, AI Customer Broadcasts, and Parchi Decoders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Feature 1: Vision Photo-to-Product
            _buildFeatureSwitchCard(
              title: '📸 Photo-to-Product Vision Auto-Fill',
              description: 'Snap any product package; auto-fills Name, Category, MRP, and Unit.',
              featureKey: 'vision_autofill',
              icon: Icons.camera_alt_rounded,
            ),
            const SizedBox(height: 10),

            // Feature 2: Automated Time-to-Time Push Notifications
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.campaign_rounded, color: AppColors.accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📢 AI Customer Push Notifications',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            const Text(
                              'Broadcast deals & festive alerts to registered customers',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Theme Selection Chip
                  Wrap(
                    spacing: 6,
                    children: ['Weekend Deals', 'Festival Special', 'Daily Staples Discount', 'Fresh Stock Alert']
                        .map((theme) {
                      final isSel = _selectedBroadcastTheme == theme;
                      return ChoiceChip(
                        label: Text(theme, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        onSelected: (val) {
                          if (val) setState(() => _selectedBroadcastTheme = theme);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Button to Generate AI Drafts
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isGeneratingBroadcast
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(_isGeneratingBroadcast ? 'Writing with Gemini 1.5 Pro...' : '✨ Generate AI Broadcast Options'),
                      onPressed: _isGeneratingBroadcast ? null : _generateAiBroadcastCopies,
                    ),
                  ),

                  // Display AI Generated Drafts
                  if (_generatedBroadcasts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'AI Generated Drafts (Tap to Send):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    ..._generatedBroadcasts.map((draft) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.scaffoldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              draft.body,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 12),
                                label: const Text('Push to Customers'),
                                onPressed: _isBroadcasting ? null : () => _sendBroadcast(draft.title, draft.body, draft.category),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Feature 3: Parchi Decoder
            _buildFeatureSwitchCard(
              title: '🧾 Parchi & WhatsApp List Decoder',
              description: 'Convert handwritten chits or WhatsApp grocery lists into digital bills.',
              featureKey: 'parchi_decoder',
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(height: 10),

            // Feature 4: Smart Inventory Advisory
            _buildFeatureSwitchCard(
              title: '📊 Smart Reorder & Demand Advisory',
              description: 'AI forecasts fast-depleting staples and advises wholesale reorders.',
              featureKey: 'inventory_advisory',
              icon: Icons.trending_up_rounded,
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: Share App & Instant QR Code
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildShareAppTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SHALIMAR STORE (EST. 1988)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Offline High-Contrast QR Code
                QrImageView(
                  data: _arm64ApkUrl,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1E3A8A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Scan to Download APK',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Latest stable release: arm64-v8a Android APK',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action 1: Share on WhatsApp
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat_rounded, size: 20),
              label: const Text('Share via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _shareOnWhatsApp,
            ),
          ),
          const SizedBox(height: 10),

          // Action 2: Copy Download Link
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textPrimary,
                side: BorderSide(color: context.borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Direct Download Link'),
              onPressed: _copyDownloadLink,
            ),
          ),
          const SizedBox(height: 10),

          // Action 3: Open GitHub Releases
          TextButton.icon(
            icon: const Icon(Icons.launch_rounded, size: 16),
            label: const Text('View All Releases on GitHub'),
            onPressed: () async {
              final uri = Uri.parse(_releasesUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: Store & App Settings
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSettingsTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Timings Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Timings & Notice',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _timingsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Opening & Closing Hours',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bannerCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Customer Delivery Notice Banner',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // OTA Update Check Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Updates',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Current Version: v${AppConstants.appVersion}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isCheckingUpdate ? null : _checkForUpdate,
                      child: _isCheckingUpdate
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Check Update', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                if (_updateStatus != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _updateStatus!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──
  Widget _buildGuideStep(String stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFeatureSwitchCard({
    required String title,
    required String description,
    required String featureKey,
    required IconData icon,
  }) {
    final enabled = StorageService.isGeminiFeatureEnabled(featureKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: AppColors.primary,
            onChanged: (val) async {
              await StorageService.setGeminiFeatureEnabled(featureKey, val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
