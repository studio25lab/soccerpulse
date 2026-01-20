import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _updateSystemUI();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    _updateSystemUI();
    notifyListeners();
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            _isDarkMode ? const Color(0xFF121212) : Colors.white,
        systemNavigationBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  // LIGHT THEME - Colori vivaci e moderni
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2E7D32), // Verde calcio
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),
          secondary: Color(0xFF1976D2),
          tertiary: Color(0xFFFF6F00),
          surface: Colors.white,
          error: Color(0xFFD32F2F),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1A1A1A),
          onError: Colors.white,
        ),

        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
        ),

        dividerTheme: DividerThemeData(
          color: Colors.grey[300],
          thickness: 1,
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF424242),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF616161),
          ),
        ),
      );

  // DARK THEME - Design premium con contrasti perfetti
  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4CAF50), // Verde più chiaro per dark mode
        scaffoldBackgroundColor: const Color(0xFF121212),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF42A5F5),
          tertiary: Color(0xFFFF9800),
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFEF5350),
          onPrimary: Color(0xFF121212),
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E0E0),
          onError: Colors.white,
          surfaceContainerHighest: Color(0xFF2C2C2C),
        ),

        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E1E1E),
        ),

        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: const Color(0xFF121212),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Color(0xFF121212),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),

        dividerTheme: const DividerThemeData(
          color: Color(0xFF2C2C2C),
          thickness: 1,
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0E0E0),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0E0E0),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0E0E0),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFFBDBDBD),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF9E9E9E),
          ),
        ),
      );

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;
}
