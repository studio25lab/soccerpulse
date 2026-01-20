import 'package:flutter/material.dart';
import '../services/user_preferences_service.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('it', 'IT');

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  Future<void> _loadLocale() async {
    final prefs = UserPreferencesService.getInstance();
    final languageCode = await prefs.getLanguage();
    _locale = Locale(languageCode, languageCode == 'it' ? 'IT' : 'US');
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    final prefs = UserPreferencesService.getInstance();
    await prefs.setLanguage(locale.languageCode);
    notifyListeners();
  }
}
