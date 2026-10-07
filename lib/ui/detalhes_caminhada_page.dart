import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/caminhada.dart';
import 'widgets.dart';

class DetalhesCaminhadaPage extends StatelessWidget {
  final Caminhada caminhada;
  final String Function(int) formatarDuracao;

  const DetalhesCaminhadaPage({
    super.key,
    required this.caminhada,
    required this.formatarDuracao,
  });

  @override
  Widget build(BuildContext context) {
    final centro = caminhada.pontos.isNotEmpty
        ? caminhada.pontos.first
        : const LatLng(-23.5505, -46.6333);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da caminhada')),
      body: ListView(
        children: [
          SizedBox(
            height: 280,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: centro,
                zoom: 15,
              ),
              markers: caminhada.pontos.isEmpty
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('inicio'),
                        position: caminhada.pontos.first,
                      ),
                      if (caminhada.pontos.length > 1)
                        Marker(
                          markerId: const MarkerId('fim'),
                          position: caminhada.pontos.last,
                        ),
                    },
              polylines: caminhada.pontos.length < 2
                  ? {}
                  : {
                      Polyline(
                        polylineId: const PolylineId('historico'),
                        points: caminhada.pontos,
                        width: 6,
                        color: Colors.green,
                      ),
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InfoCaminhada(
                  titulo: 'Distância',
                  valor: '${caminhada.distanciaKm.toStringAsFixed(2)} km',
                ),
                InfoCaminhada(
                  titulo: 'Tempo',
                  valor: formatarDuracao(caminhada.duracaoSegundos),
                ),
                InfoCaminhada(
                  titulo: 'Fotos',
                  valor: caminhada.fotos.length.toString(),
                ),
              ],
            ),
          ),
          if (caminhada.fotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: caminhada.fotos.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(caminhada.fotos[index]),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
