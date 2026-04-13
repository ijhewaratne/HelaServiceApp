import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app localization
/// 
/// Phase 3: Essential Features - Sinhala Language Support
class LocalizationService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  
  final SharedPreferences _prefs;
  Locale _currentLocale;
  
  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('si'), // Sinhala
  ];
  
  /// Default locale
  static const Locale defaultLocale = Locale('en');
  
  LocalizationService(this._prefs) 
      : _currentLocale = _loadLocale(_prefs);
  
  /// Current app locale
  Locale get currentLocale => _currentLocale;
  
  /// Current language code
  String get currentLanguageCode => _currentLocale.languageCode;
  
  /// Check if current locale is Sinhala
  bool get isSinhala => _currentLocale.languageCode == 'si';
  
  /// Check if current locale is English
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
  /// Set locale
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      throw ArgumentError('Locale ${locale.languageCode} is not supported');
    }
    
    _currentLocale = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
  
  /// Toggle between English and Sinhala
  Future<void> toggleLanguage() async {
    final newLocale = isEnglish ? const Locale('si') : const Locale('en');
    await setLocale(newLocale);
  }
  
  /// Set English locale
  Future<void> setEnglish() async {
    await setLocale(const Locale('en'));
  }
  
  /// Set Sinhala locale
  Future<void> setSinhala() async {
    await setLocale(const Locale('si'));
  }
  
  /// Get locale name for display
  String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'si':
        return 'සිංහල';
      default:
        return locale.languageCode;
    }
  }
  
  /// Load locale from preferences
  static Locale _loadLocale(SharedPreferences prefs) {
    final languageCode = prefs.getString(_localeKey);
    if (languageCode == null) return defaultLocale;
    
    final locale = Locale(languageCode);
    return supportedLocales.contains(locale) ? locale : defaultLocale;
  }
}

/// Extension for easy access to localization
extension LocalizationContext on BuildContext {
  /// Get current locale
  Locale get currentLocale => Localizations.localeOf(this);
  
  /// Check if current locale is Sinhala
  bool get isSinhala => currentLocale.languageCode == 'si';
  
  /// Check if current locale is English
  bool get isEnglish => currentLocale.languageCode == 'en';
}
