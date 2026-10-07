import 'package:flutter/material.dart';

class AppStyle {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
      ),
    );
  }
}
