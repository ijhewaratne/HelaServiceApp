import 'package:flutter/material.dart';

/// App colors, typography, and theme constants
class ThemeConstants {
  // Primary Colors
  static const Color primaryColor = Color(0xFF0F7A7A);
  static const Color primaryLight = Color(0xFF4DA8A8);
  static const Color primaryDark = Color(0xFF004F4F);
  
  // Secondary Colors
  static const Color secondaryColor = Color(0xFF1E293B);
  static const Color secondaryLight = Color(0xFF334155);
  static const Color secondaryDark = Color(0xFF0F172A);
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Typography
  static const String fontFamily = 'NotoSansSinhala';
  static const String fontFamilyFallback = 'Outfit';
  
  // Font Sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;
  static const double fontSize4xl = 36.0;
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;
  
  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;
  
  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 15,
      offset: Offset(0, 10),
    ),
  ];
}
