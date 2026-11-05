import 'package:flutter/material.dart';

extension ThemeContextExtension on BuildContext {
  /// Whether the current theme is in dark mode
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Scaffold background color: pure AMOLED dark #121212 in dark, clean slate #F8FAFC in light
  Color get scaffoldBg => isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);

  /// Primary card and surface color: #1E1E1E in dark, pure white in light
  Color get surfaceColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  /// Elevated surface: #262626 in dark, light grey in light
  Color get surfaceElevated => isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9);

  /// Highlighted chip or pill background
  Color get surfaceHighlight => isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE2E8F0);

  /// Primary high-contrast typography color: #F8FAFC in dark, #0F172A in light
  Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  /// Secondary typography color: #94A3B8 in dark, #64748B in light
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  /// Subtle muted placeholder/hint text color
  Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  /// Subtle card and chip border color
  Color get borderSubtle => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0);

  /// Strong border or divider color
  Color get borderStrong => isDark ? const Color(0xFF383838) : const Color(0xFFCBD5E1);

  /// Form input background fill
  Color get inputFill => isDark ? const Color(0xFF242424) : Colors.white;
}

