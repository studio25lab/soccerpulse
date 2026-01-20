import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('it');

  Locale get locale => _locale;
  String get currentLanguageCode => _locale.languageCode;
  String get currentLanguageName =>
      _locale.languageCode == 'it' ? 'Italiano' : 'English';

  LocaleService() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'it';
    _locale = Locale(localeCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    final newLocale =
        _locale.languageCode == 'it' ? const Locale('en') : const Locale('it');
    setLocale(newLocale);
  }
}
