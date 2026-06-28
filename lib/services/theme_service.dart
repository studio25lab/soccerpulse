// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('it', 'IT');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  // Colori del tema
  Color get primaryColor {
    return _themeMode == ThemeMode.dark
        ? const Color(0xFF66BB6A) // Verde chiaro per dark mode
        : const Color(0xFF2E7D32); // Verde scuro per light mode
  }

  Color get secondaryColor {
    return _themeMode == ThemeMode.dark
        ? const Color(0xFF81C784)
        : const Color(0xFF66BB6A);
  }

  // Carica preferenze salvate
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carica tema
      final themeModeString = prefs.getString(_themeModeKey);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }

      // Carica locale
      final localeString = prefs.getString(_localeKey);
      if (localeString != null) {
        final localeParts = localeString.split('_');
        if (localeParts.length == 2) {
          _locale = Locale(localeParts[0], localeParts[1]);
        } else if (localeParts.isNotEmpty) {
          _locale = Locale(localeParts[0]);
        }
      }

      notifyListeners();
    } catch (e) {
      print('Errore caricamento preferenze tema: $e');
    }
  }

  // Salva tema
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      print('Errore salvataggio tema: $e');
    }
  }

  // Salva locale
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await prefs.setString(_localeKey, localeString);
    } catch (e) {
      print('Errore salvataggio locale: $e');
    }
  }

  // Toggle tema
  void toggleTheme(BuildContext context) {
    // Decide in base al tema EFFETTIVAMENTE visibile: isDarkMode risolve
    // anche 'system' guardando la brightness di sistema. Cosi un solo tap
    // inverte sempre cio' che l'utente vede, da qualunque stato di partenza.
    final currentlyDark = isDarkMode(context);
    setThemeMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  // Helper per verificare se è dark mode
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Ottieni il tema corrente
  String getThemeModeString() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Chiaro';
      case ThemeMode.dark:
        return 'Scuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  // Ottieni la lingua corrente
  String getLocaleString() {
    switch (_locale.languageCode) {
      case 'it':
        return 'Italiano';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return _locale.languageCode.toUpperCase();
    }
  }

  // Reset alle impostazioni predefinite
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _locale = const Locale('it', 'IT');
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeModeKey);
      await prefs.remove(_localeKey);
    } catch (e) {
      print('Errore reset preferenze: $e');
    }
  }
}

// Extension per accesso rapido al theme service
extension ThemeServiceExtension on BuildContext {
  ThemeService get themeService => ThemeService();

  bool get isDarkMode {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark;
  }

  Color get primaryColor => Theme.of(this).primaryColor;
  Color get scaffoldColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor =>
      Theme.of(this).cardTheme.color ?? Theme.of(this).cardColor;
}
