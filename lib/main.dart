import 'package:flutter/material.dart';
import 'style/app_style.dart';
import 'ui/splash_page.dart';

void main() {
  runApp(const CaminhadasApp());
}

class CaminhadasApp extends StatefulWidget {
  const CaminhadasApp({super.key});

  @override
  State<CaminhadasApp> createState() => _CaminhadasAppState();
}

class _CaminhadasAppState extends State<CaminhadasApp> {
  bool modoEscuro = false;

  void alterarTema(bool valor) {
    setState(() {
      modoEscuro = valor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minhas Caminhadas',
      theme: AppStyle.claro,
      darkTheme: AppStyle.escuro,
      themeMode: modoEscuro ? ThemeMode.dark : ThemeMode.light,
      home: SplashPage(
        modoEscuro: modoEscuro,
        onTemaChanged: alterarTema,
      ),
    );
  }
}
