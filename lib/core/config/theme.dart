import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    // Premium Slate/Teal base colors
    const Color primaryColor = Color(0xFF0F7A7A); 
    const Color secondaryColor = Color(0xFF1E293B);
    const Color backgroundColor = Color(0xFFF8FAFC);
    const Color surfaceColor = Colors.white;

    final baseTextTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: secondaryColor),
        titleTextStyle: GoogleFonts.outfit(
          color: secondaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(color: secondaryColor, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: secondaryColor, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: Colors.black87),
        bodyMedium: GoogleFonts.outfit(color: Colors.black54),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.outfit(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Dark theme placeholder - for future implementation
    return lightTheme;
  }
}
