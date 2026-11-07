import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/catalogue_provider.dart';
import '../../services/analytics_service.dart';

class AdminAnalyticsDrawer extends StatefulWidget {
  const AdminAnalyticsDrawer({super.key});

  @override
  State<AdminAnalyticsDrawer> createState() => _AdminAnalyticsDrawerState();
}

class _AdminAnalyticsDrawerState extends State<AdminAnalyticsDrawer> {
  bool _isLoading = true;
  List<UserModel> _customers = [];
  OrderAnalyticsSummary _orderSummary = const OrderAnalyticsSummary();
  String _customerSearch = '';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final customers = await AnalyticsService.fetchRegisteredCustomers();
      final orderSummary = await AnalyticsService.fetchOrderAnalytics();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _orderSummary = orderSummary;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _launchWhatsAppChat(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = clean.length == 10 ? '91$clean' : clean;
    final uri = Uri.parse('https://wa.me/$fullPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueProvider>();
    final inventory = AnalyticsService.calculateInventoryMetrics(catalogue.products);
    final isDark = context.isDark;

    final filteredCustomers = _customers.where((c) {
      if (_customerSearch.isEmpty) return true;
      final q = _customerSearch.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();

    return Drawer(
      width: MediaQuery.of(context).size.width > 450 ? 400 : MediaQuery.of(context).size.width * 0.88,
      backgroundColor: context.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(bottom: BorderSide(color: context.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(AppConstants.logoPath, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store Analytics & CRM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Real-Time Shalimar Insights',
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: context.textSecondary),
                    tooltip: 'Refresh Data',
                    onPressed: _isLoading ? null : _loadAnalyticsData,
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── KPI Summary Cards ──
                          Row(
                            children: [
                              _buildKpiCard(
                                title: 'Registered Customers',
                                value: '${_customers.length}',
                                subtitle: 'From Firestore Users',
                                icon: Icons.people_alt_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              _buildKpiCard(
                                title: 'WhatsApp Orders',
                                value: '${_orderSummary.totalOrders}',
                                subtitle: 'Messages Initiated',
                                icon: Icons.chat_rounded,
                                color: AppColors.whatsappGreen,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildKpiCard(
                                title: 'Order Revenue (Est.)',
                                value: CurrencyFormatter.format(_orderSummary.totalRevenue),
                                subtitle: 'Sum of WhatsApp orders',
                                icon: Icons.payments_rounded,
                                color: const Color(0xFFC68400),
                              ),
                              const SizedBox(width: 10),
                              _buildKpiCard(
                                title: 'Catalogue Worth',
                                value: CurrencyFormatter.format(inventory['totalValuation'] as double),
                                subtitle: '${inventory['inStock']} In-Stock Items',
                                icon: Icons.inventory_2_rounded,
                                color: const Color(0xFF2E7D32),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Section 1: Customer Directory ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Customer Directory',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_customers.length} users',
                                style: TextStyle(fontSize: 11, color: context.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Search customer
                          TextField(
                            onChanged: (val) => setState(() => _customerSearch = val),
                            style: TextStyle(fontSize: 12, color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search by customer name, phone, address...',
                              prefixIcon: const Icon(Icons.search, size: 16),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (filteredCustomers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: Text(
                                _customers.isEmpty
                                    ? 'No registered customers yet in Firestore.'
                                    : 'No customer matches your search.',
                                style: TextStyle(fontSize: 12, color: context.textSecondary),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredCustomers.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF222222) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderSubtle),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              customer.name.isNotEmpty ? customer.name : 'Customer',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: context.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              customer.provider,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (customer.phone.isNotEmpty) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_outlined, size: 13, color: AppColors.whatsappGreen),
                                            const SizedBox(width: 4),
                                            Text(
                                              '+91 ${customer.phone}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            const Spacer(),
                                            InkWell(
                                              onTap: () => _launchWhatsAppChat(customer.phone),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.whatsappGreen),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _callCustomer(customer.phone),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Icon(Icons.call_outlined, size: 16, color: AppColors.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if (customer.address.isNotEmpty)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                customer.address,
                                                style: TextStyle(fontSize: 10, color: context.textSecondary),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 20),

                          // ── Section 2: Recent WhatsApp Orders ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.whatsappGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Recent WhatsApp Orders',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_orderSummary.recentOrders.length} orders',
                                style: TextStyle(fontSize: 11, color: context.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_orderSummary.recentOrders.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: Text(
                                'No WhatsApp orders recorded yet.',
                                style: TextStyle(fontSize: 12, color: context.textSecondary),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _orderSummary.recentOrders.take(15).length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final order = _orderSummary.recentOrders[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF222222) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderSubtle),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            order.orderId,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(order.totalAmount),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.whatsappGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Customer: ${order.customerName} (${order.itemCount} items)',
                                        style: TextStyle(fontSize: 11, color: context.textPrimary, fontWeight: FontWeight.w600),
                                      ),
                                      if (order.itemNames.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          order.itemNames.join(', '),
                                          style: TextStyle(fontSize: 10, color: context.textSecondary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 20),

                          // ── Section 3: Category Inventory Distribution ──
                          Row(
                            children: [
                              const Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Category Distribution',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (inventory['categoryCounts'] as Map<String, int>).entries.map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: context.borderSubtle),
                                ),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: color),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: context.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

