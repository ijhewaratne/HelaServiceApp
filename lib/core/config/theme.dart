import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Theme Configuration
/// 
/// Phase 5: UI/UX Polish - Dark Mode Implementation
class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF0F7A7A);
  static const Color primaryLight = Color(0xFF14B8B8);
  static const Color primaryDark = Color(0xFF0A5252);
  
  // Semantic Colors
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  /// Light Theme
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      backgroundColor: lightBackground,
      surfaceColor: lightSurface,
      cardColor: lightCard,
      textPrimary: lightTextPrimary,
      textSecondary: lightTextSecondary,
      borderColor: lightBorder,
      statusBarStyle: SystemUiOverlayStyle.dark,
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      backgroundColor: darkBackground,
      surfaceColor: darkSurface,
      cardColor: darkCard,
      textPrimary: darkTextPrimary,
      textSecondary: darkTextSecondary,
      borderColor: darkBorder,
      statusBarStyle: SystemUiOverlayStyle.light,
    );
  }

  /// Build theme with given colors
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required SystemUiOverlayStyle statusBarStyle,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme = GoogleFonts.outfitTextTheme(
      brightness == Brightness.dark 
          ? ThemeData.dark().textTheme 
          : ThemeData.light().textTheme,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: isDark ? primaryDark : primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: textSecondary,
        onSecondary: Colors.white,
        secondaryContainer: surfaceColor,
        onSecondaryContainer: textPrimary,
        surface: surfaceColor,
        onSurface: textPrimary,
        surfaceContainerHighest: cardColor,
        onSurfaceVariant: textSecondary,
        background: backgroundColor,
        onBackground: textPrimary,
        error: errorColor,
        onError: Colors.white,
        errorContainer: errorColor.withOpacity(0.1),
        onErrorContainer: errorColor,
        outline: borderColor,
        shadow: Colors.black.withOpacity(0.1),
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundColor,

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? surfaceColor : Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: statusBarStyle,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Text Theme
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: isDark ? 0 : 2,
          shadowColor: isDark ? Colors.transparent : primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: isDark ? primaryLight : primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.outfit(color: textSecondary),
        hintStyle: GoogleFonts.outfit(color: textSecondary.withOpacity(0.6)),
        helperStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 12),
        errorStyle: GoogleFonts.outfit(color: errorColor, fontSize: 12),
      ),

      // Card
      cardTheme: CardTheme(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : Colors.black.withOpacity(0.1),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? darkBorder : lightBorder,
            width: 1,
          ),
        ),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: surfaceColor,
        selectedTileColor: primaryColor.withOpacity(0.1),
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: isDark ? 0 : 8,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: isDark ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: isDark ? 0 : 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkCard : lightTextPrimary,
        contentTextStyle: GoogleFonts.outfit(color: isDark ? lightTextPrimary : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: GoogleFonts.outfit(color: textPrimary),
        secondaryLabelStyle: GoogleFonts.outfit(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
