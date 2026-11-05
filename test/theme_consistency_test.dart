import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalimar_store/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Light and Dark themes provide valid contrast and palettes', () {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);

    // Dark theme scaffold background should be AMOLED dark #121212
    expect(dark.scaffoldBackgroundColor, const Color(0xFF121212));
    expect(dark.cardColor, const Color(0xFF1E1E1E));

    // Light theme scaffold background should be light
    expect(light.scaffoldBackgroundColor.computeLuminance() > 0.8, true);
    // Dark theme scaffold background should have ultra low luminance
    expect(dark.scaffoldBackgroundColor.computeLuminance() < 0.05, true);
  });
}
