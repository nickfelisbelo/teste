import 'dart:io';
import 'package:flutter/material.dart';
import '../models/caminhada.dart';

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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          titulo,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class CaminhadaCard extends StatelessWidget {
  final Caminhada caminhada;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const CaminhadaCard({
    super.key,
    required this.caminhada,
    required this.onTap,
    required this.onExcluir,
  });

  String _dataFormatada(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onExcluir,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: caminhada.fotos.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_walk,
                          size: 40,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(caminhada.fotos.first),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(Icons.broken_image);
                          },
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caminhada.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(_dataFormatada(caminhada.data)),
                    const SizedBox(height: 8),
                    Text(
                      '${caminhada.distanciaKm.toStringAsFixed(2)} km'
                      ' • ${caminhada.calorias.toStringAsFixed(0)} kcal'
                      ' • ${caminhada.tempoMinutos} min',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
