import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green, brightness: Brightness.dark),
        useMaterial3: true,
      );
}
