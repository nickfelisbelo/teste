import 'package:flutter/material.dart';

class InfoCaminhada extends StatelessWidget {
  final String titulo;
  final String valor;

  const InfoCaminhada({
    super.key,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(titulo),
      ],
    );
  }
}
