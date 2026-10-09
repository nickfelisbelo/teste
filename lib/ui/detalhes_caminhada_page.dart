import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/caminhada.dart';
import '../services/foto_service.dart';
import 'widgets.dart';

class DetalhesCaminhadaPage extends StatefulWidget {
  final Caminhada caminhada;
  final Future<void> Function(Caminhada caminhada) onAtualizar;

  const DetalhesCaminhadaPage({
    super.key,
    required this.caminhada,
    required this.onAtualizar,
  });

  @override
  State<DetalhesCaminhadaPage> createState() => _DetalhesCaminhadaPageState();
}

class _DetalhesCaminhadaPageState extends State<DetalhesCaminhadaPage> {
  final FotoService _fotoService = FotoService();

  late Caminhada caminhada;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    caminhada = widget.caminhada;
  }

  Future<void> _tirarFoto() async {
    final caminho = await _fotoService.tirarFoto();

    if (caminho == null || !mounted) return;

    final atualizada = caminhada.copyWith(
      fotos: [...caminhada.fotos, caminho],
    );

    setState(() {
      caminhada = atualizada;
    });

    await widget.onAtualizar(atualizada);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto salva na caminhada.'),
      ),
    );
  }

  Set<Marker> get _marcadores {
    if (caminhada.pontos.isEmpty) return {};

    return {
      Marker(
        markerId: const MarkerId('inicio'),
        position: caminhada.pontos.first,
        infoWindow: const InfoWindow(
          title: 'Início',
        ),
      ),
      if (caminhada.pontos.length > 1)
        Marker(
          markerId: const MarkerId('destino'),
          position: caminhada.pontos.last,
          infoWindow: const InfoWindow(
            title: 'Destino',
          ),
        ),
    };
  }

  Set<Polyline> get _polylines {
    if (caminhada.pontos.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('rota'),
        points: caminhada.pontos,
        width: 6,
        color: Theme.of(context).colorScheme.primary,
      ),
    };
  }

  Future<void> _centralizarRota() async {
    if (_mapController == null || caminhada.pontos.isEmpty) return;

    var minLat = caminhada.pontos.first.latitude;
    var maxLat = caminhada.pontos.first.latitude;
    var minLng = caminhada.pontos.first.longitude;
    var maxLng = caminhada.pontos.first.longitude;

    for (final ponto in caminhada.pontos) {
      if (ponto.latitude < minLat) minLat = ponto.latitude;
      if (ponto.latitude > maxLat) maxLat = ponto.latitude;
      if (ponto.longitude < minLng) minLng = ponto.longitude;
      if (ponto.longitude > maxLng) maxLng = ponto.longitude;
    }

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          70,
        ),
      );
    } catch (_) {}
  }

  String _dataFormatada(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final centro = caminhada.pontos.isNotEmpty
        ? caminhada.pontos.first
        : const LatLng(-23.5505, -46.6333);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da caminhada'),
        actions: [
          IconButton(
            onPressed: _centralizarRota,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: centro,
                zoom: 15,
              ),
              markers: _marcadores,
              polylines: _polylines,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _centralizarRota();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              caminhada.titulo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _dataFormatada(caminhada.data),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InfoCaminhada(
                      titulo: 'Distância',
                      valor:
                          '${caminhada.distanciaKm.toStringAsFixed(2)} km',
                    ),
                    InfoCaminhada(
                      titulo: 'Calorias',
                      valor:
                          '${caminhada.calorias.toStringAsFixed(0)} kcal',
                    ),
                    InfoCaminhada(
                      titulo: 'Tempo',
                      valor: '${caminhada.tempoMinutos} min',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Foto da caminhada',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          if (caminhada.fotos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: InkWell(
                  onTap: _tirarFoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 52,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Adicionar foto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toque aqui para abrir a câmera.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: caminhada.fotos.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final caminho = caminhada.fotos[index];

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(caminho),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(Icons.broken_image),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          if (caminhada.fotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: OutlinedButton.icon(
                onPressed: _tirarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar outra foto'),
              ),
            ),
        ],
      ),
    );
  }
}
