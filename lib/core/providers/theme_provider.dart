import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

/// Phase 5: UI/UX Polish - Theme Provider
/// 
/// Manages dark mode state and persists user preference.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  
  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeProvider(this._prefs) : _themeMode = _loadThemeMode(_prefs);

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Whether dark mode is currently active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Current theme data based on mode
  ThemeData get currentTheme {
    switch (_themeMode) {
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.system:
        // Return light theme as default, actual mode determined by system
        return AppTheme.lightTheme;
    }
  }

  /// Load theme mode from preferences
  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final isDark = prefs.getBool(_themeKey);
    if (isDark == null) return ThemeMode.system;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.system:
        // Default to light when toggling from system
        _themeMode = ThemeMode.light;
        break;
    }
    await _prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    if (mode != ThemeMode.system) {
      await _prefs.setBool(_themeKey, mode == ThemeMode.dark);
    } else {
      await _prefs.remove(_themeKey);
    }
    notifyListeners();
  }

  /// Enable dark mode
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// Enable light mode
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);

  /// Use system theme
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);
}
