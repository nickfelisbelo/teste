import 'package:flutter/material.dart';

class AppStyle {
  static ThemeData get claro {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8F6),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData get escuro {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF101410),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
      ),
    );
  }
}
