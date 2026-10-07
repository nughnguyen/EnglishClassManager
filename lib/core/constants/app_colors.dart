import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryDark = Color(0xFF0D1B6E);
  static const Color primaryLight = Color(0xFF3D5AFE);
  static const Color accent = Color(0xFF00BCD4);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color navyDark = Color(0xFF0A1628);
  static const Color cardShadow = Color(0x1A000000);

  static const List<Color> sessionColors = [
    Color(0xFF3D5AFE), // Indigo Accent
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFF009688), // Teal
    Color(0xFFF44336), // Red
    Color(0xFF2196F3), // Blue
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFFC107), // Amber
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF03A9F4), // Light Blue
    Color(0xFFCDDC39), // Lime
    Color(0xFF3F51B5), // Indigo
    Color(0xFF00E676), // Green Accent
    Color(0xFFFF4081), // Pink Accent
  ];

  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color generateUniqueColor(List<String> existingHexColors) {
    final existingColors = existingHexColors.map((e) => fromHex(e).value).toSet();
    
    // First try from predefined
    for (final c in sessionColors) {
      if (!existingColors.contains(c.value)) {
        return c;
      }
    }

    // If all predefined are used, generate a random pleasant color
    int attempts = 0;
    while (attempts < 50) {
      final double hue = (DateTime.now().millisecondsSinceEpoch + attempts * 137.5) % 360.0;
      final color = HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor();
      if (!existingColors.contains(color.value)) {
        return color;
      }
      attempts++;
    }
    
    // Fallback if somehow still colliding
    return HSVColor.fromAHSV(1.0, (DateTime.now().millisecondsSinceEpoch % 360).toDouble(), 0.8, 0.8).toColor();
  }
}
