import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryContainer = Color(0xFFD6E4FF);
  static const Color secondary = Color(0xFF00C853);
  static const Color secondaryContainer = Color(0xFFB9F6CA);
  static const Color tertiary = Color(0xFFFF6D00);
  static const Color tertiaryContainer = Color(0xFFFFE0B2);
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFE0E0E0);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF00A8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF64DD17)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
