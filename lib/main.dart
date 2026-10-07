import 'package:flutter/material.dart';
import 'style/app_style.dart';
import 'ui/home_page.dart';

void main() {
  runApp(const CaminhadasApp());
}

class CaminhadasApp extends StatelessWidget {
  const CaminhadasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minhas Caminhadas',
      theme: AppStyle.theme,
      home: const HomePage(),
    );
  }
}
