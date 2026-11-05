import 'package:flutter/material.dart';

/// App color palette matching the official Shalimar Store logo:
/// Rich Crimson Red (#B71C1C), Warm Gold / Sun Yellow (#FFB300), 
/// Deep Charcoal (#1A1A1A), and Warm Off-White (#FFFDF9).
class AppColors {
  // Primary Brand Colors (From Logo Monogram)
  static const Color primary = Color(0xFFB71C1C);       // Deep Crimson Red
  static const Color primaryDark = Color(0xFF7F0000);   // Dark Burgundy
  static const Color primaryLight = Color(0xFFFF5252);  // Bright Red Accent

  // Secondary / Accent Colors (From Logo Ring & Heritage)
  static const Color accent = Color(0xFFFFB300);        // Rich Gold / Amber
  static const Color accentLight = Color(0xFFFFE082);   // Soft Gold
  static const Color accentDark = Color(0xFFC68400);    // Deep Amber

  // Neutrals & Backgrounds
  static const Color background = Color(0xFFF9F7F4);    // Warm off-white
  static const Color surface = Color(0xFFFFFFFF);       // Pure White
  static const Color surfaceVariant = Color(0xFFF0ECE6);// Soft warm grey
  static const Color darkText = Color(0xFF1E1E1E);      // Deep Charcoal
  static const Color lightText = Color(0xFF757575);     // Muted grey

  // Status & Badges
  static const Color success = Color(0xFF2E7D32);       // Green for In Stock / Discounts
  static const Color error = Color(0xFFD32F2F);         // Red for Out of Stock
  static const Color warning = Color(0xFFF57C00);       // Orange
  static const Color whatsappGreen = Color(0xFF25D366); // Official WhatsApp Green

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFC62828), Color(0xFF8E0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

