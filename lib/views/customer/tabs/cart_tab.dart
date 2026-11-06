import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/order_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/notification_service.dart';

class CartTab extends StatefulWidget {
  final VoidCallback onBrowseHome;

  const CartTab({super.key, required this.onBrowseHome});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = context.read<UserProvider>();
      _nameController.text = user.profile.username;
      _phoneController.text = user.profile.phone;
      _addressController.text = user.profile.address;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _copyUpi() {
    Clipboard.setData(const ClipboardData(text: AppConstants.ownerUpiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied: ${AppConstants.ownerUpiId}'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final user = context.read<UserProvider>();

    // Update user profile with latest contact info
    await user.updateProfile(username: name, phone: phone, address: address);
    if (!mounted) return;

    final orderItems = List.from(cart.itemList);
    final totalAmount = cart.totalAmount;

    // Send order via WhatsApp
    final sent = await WhatsAppHelper.sendOrder(
      context: context,
      items: orderItems.cast(),
      totalAmount: totalAmount,
      customerName: name,
      customerAddress: address,
      customerPhone: phone.isNotEmpty ? phone : 'Not specified',
      note: _noteController.text,
    );

    if (sent) {
      // Save to local order history
      final newOrder = OrderModel(
        id: 'SHL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        items: orderItems.cast(),
        totalAmount: totalAmount,
        date: DateTime.now(),
        customerName: name,
        deliveryAddress: address,
      );
      await user.addOrder(newOrder);
      await NotificationService.showOrderPlacedNotification(
        newOrder.id,
        totalAmount,
      );

      // Clear cart
      cart.clearCart();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 28,
                ),
                SizedBox(width: 8),
                Text('Order Sent!'),
              ],
            ),
            content: Text(
              'Your order of ${CurrencyFormatter.format(totalAmount)} was dispatched directly to Shalimar Store WhatsApp (${AppConstants.ownerPhone}).\n\nThe store owner will confirm delivery time!',
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onBrowseHome();
                },
                child: const Text(
                  'Back to Store',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.totalItemCount == 0) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove_shopping_cart_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Cart is Empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore our daily grocery essentials and add items to your basket.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: widget.onBrowseHome,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Start Shopping'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Shopping Cart',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => cart.clearCart(),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cart Items List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cart.itemList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = cart.itemList[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDark ? 0.25 : 0.03,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Image or placeholder
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? const Color(0xFF262626)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildProductThumbnail(
                              item.product.imageUrl,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.product.unit} • ${CurrencyFormatter.format(item.product.price)} each',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(item.totalPrice),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity selector
                        Container(
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => cart.decrementItem(item.product),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => cart.addItem(item.product),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.add,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Delivery Details Form
              Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Your Name *',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Contact Phone / WhatsApp *',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                maxLines: 2,
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Delivery Address & Landmark *',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                style: TextStyle(color: context.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Special Note / Timing (Optional)',
                  prefixIcon: Icon(
                    Icons.note_alt_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bill Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDark ? 0.25 : 0.03,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items Total (MRP)',
                          style: TextStyle(color: context.textSecondary),
                        ),
                        Text(
                          CurrencyFormatter.format(cart.totalMrp),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (cart.totalSavings > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Store Discount',
                            style: TextStyle(color: AppColors.success),
                          ),
                          Text(
                            '- ${CurrencyFormatter.format(cart.totalSavings)}',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Store Delivery',
                          style: TextStyle(color: context.textSecondary),
                        ),
                        const Text(
                          'FREE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20, color: context.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'To Pay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(cart.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Place Order via WhatsApp Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handlePlaceOrder,
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text(
                    'Order on WhatsApp (Direct to Owner)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsappGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 1-Tap Pay UPI Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    WhatsAppHelper.launchUpiPayment(
                      amount: cart.totalAmount,
                      customerName: name.isNotEmpty
                          ? name
                          : 'Shalimar Customer',
                    );
                  },
                  icon: const Icon(
                    Icons.qr_code_rounded,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Pay Now with UPI App (GPay / PhonePe / Paytm)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Official Shalimar UPI ID Box placed directly below UPI payment button
              _buildOfficialUpiCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficialUpiCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF241E12) : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark
              ? const Color(0xFFC68400)
              : Colors.amber.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFC68400),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Shalimar Store Official UPI ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF7F4E00),
                  ),
                ),
              ),
              InkWell(
                onTap: _copyUpi,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF1B150A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.copy,
                        size: 12,
                        color: context.isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF7F4E00),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.isDark
                              ? const Color(0xFFFFD54F)
                              : const Color(0xFF7F4E00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF1B150A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.isDark
                    ? const Color(0xFF4A3B18)
                    : Colors.amber.shade200,
              ),
            ),
            child: const SelectableText(
              AppConstants.ownerUpiId,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Accepted on all UPI apps: PhonePe, Google Pay, Paytm, BHIM, Cred. Zero gateway charges.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.shopping_basket_outlined,
        color: AppColors.primary,
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.shopping_basket_outlined,
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
          color: AppColors.primary,
        ),
      );
    }
    return const Icon(Icons.shopping_basket_outlined, color: AppColors.primary);
  }
}
