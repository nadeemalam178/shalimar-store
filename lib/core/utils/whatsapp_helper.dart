import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cart_item.dart';
import '../constants/app_constants.dart';
import 'currency_formatter.dart';

class WhatsAppHelper {
  /// Generates neatly formatted order message and launches WhatsApp directly.
  static Future<bool> sendOrder({
    required BuildContext context,
    required List<CartItem> items,
    required double totalAmount,
    required String customerName,
    required String customerAddress,
    required String customerPhone,
    String? note,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *NEW ORDER — SHALIMAR STORE*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 *Customer:* $customerName');
    buffer.writeln('📱 *Phone:* $customerPhone');
    buffer.writeln('📍 *Delivery Address:* $customerAddress');
    if (note != null && note.trim().isNotEmpty) {
      buffer.writeln('📝 *Special Note:* $note');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📦 *ORDER ITEMS:*');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemTotal = item.product.price * item.quantity;
      buffer.writeln(
        '${i + 1}. *${item.product.name}* (${item.product.unit})\n'
        '   Qty: ${item.quantity} × ${CurrencyFormatter.format(item.product.price)} = *${CurrencyFormatter.format(itemTotal)}*',
      );
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💵 *TOTAL BILL: ${CurrencyFormatter.format(totalAmount)}*');
    buffer.writeln('🏷️ *Payment Mode:* Cash on Delivery / UPI (${AppConstants.ownerUpiId})');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('⚡ _Sent via Shalimar Store App_');

    final message = Uri.encodeComponent(buffer.toString());
    final phone = AppConstants.ownerWhatsApp;

    // Try direct WhatsApp URL scheme first, then web link fallback
    final whatsappUri = Uri.parse('whatsapp://send?phone=$phone&text=$message');
    final webUri = Uri.parse('https://wa.me/$phone?text=$message');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return true;
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Please check if WhatsApp is installed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  /// Launch phone call to store owner
  static Future<void> callStore() async {
    final uri = Uri.parse('tel:${AppConstants.ownerPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Launch UPI Intent directly for seamless zero-fee payment
  static Future<bool> launchUpiPayment({
    required double amount,
    required String customerName,
  }) async {
    final upiUrl = 'upi://pay?'
        'pa=${AppConstants.ownerUpiId}'
        '&pn=Shalimar%20Store'
        '&am=${amount.toStringAsFixed(2)}'
        '&cu=INR'
        '&tn=Order%20by%20${Uri.encodeComponent(customerName)}';

    final uri = Uri.parse(upiUrl);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('UPI launch error: $e');
    }
    return false;
  }
}

