import 'dart:io';
import 'package:flutter/material.dart';
import '../models/caminhada.dart';
import 'detalhes_caminhada_page.dart';

class HistoricoPage extends StatelessWidget {
  final List<Caminhada> historico;
  final String Function(int) formatarDuracao;

  const HistoricoPage({
    super.key,
    required this.historico,
    required this.formatarDuracao,
  });

  String dataFormatada(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de caminhadas')),
      body: historico.isEmpty
          ? const Center(
              child: Text('Nenhuma caminhada registrada ainda.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: historico.length,
              itemBuilder: (context, index) {
                final caminhada = historico[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalhesCaminhadaPage(
                            caminhada: caminhada,
                            formatarDuracao: formatarDuracao,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: caminhada.fotos.isEmpty
                                ? const Icon(
                                    Icons.directions_walk,
                                    size: 42,
                                  )
                                : Image.file(
                                    File(caminhada.fotos.first),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dataFormatada(caminhada.inicio),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${caminhada.distanciaKm.toStringAsFixed(2)} km'
                                  ' • ${formatarDuracao(caminhada.duracaoSegundos)}',
                                ),
                                const SizedBox(height: 4),
                                Text('${caminhada.fotos.length} foto(s)'),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
