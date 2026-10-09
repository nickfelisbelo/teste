import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/caminhada.dart';
import '../services/rota_service.dart';
import 'widgets.dart';

class NovaCaminhadaPage extends StatefulWidget {
  const NovaCaminhadaPage({super.key});

  @override
  State<NovaCaminhadaPage> createState() => _NovaCaminhadaPageState();
}

class _NovaCaminhadaPageState extends State<NovaCaminhadaPage> {
  final RotaService _rotaService = RotaService();

  GoogleMapController? _mapController;

  static const LatLng _padrao = LatLng(
    -23.5505,
    -46.6333,
  );

  LatLng? _origem;
  LatLng? _destino;
  List<LatLng> _rota = [];

  double _distanciaKm = 0;
  double _calorias = 0;
  int _tempoMinutos = 0;

  bool _carregandoLocalizacao = true;
  bool _calculandoRota = false;

  @override
  void initState() {
    super.initState();
    _localizarUsuario();
  }

  Future<void> _localizarUsuario() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() {
            _carregandoLocalizacao = false;
          });
        }
        return;
      }

      var permissao = await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _carregandoLocalizacao = false;
            _origem = _padrao;
          });
        }
        return;
      }

      final posicao = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      final ponto = LatLng(
        posicao.latitude,
        posicao.longitude,
      );

      setState(() {
        _origem = ponto;
        _carregandoLocalizacao = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(ponto, 16),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregandoLocalizacao = false;
        _origem = _padrao;
      });
    }
  }

  Future<void> _selecionarDestino(LatLng destino) async {
    final origem = _origem;

    if (origem == null || _calculandoRota) return;

    setState(() {
      _destino = destino;
      _calculandoRota = true;
    });

    try {
      final rota = await _rotaService.calcularRota(
        origem: origem,
        destino: destino,
      );

      if (!mounted) return;

      final distancia = _rotaService.calcularDistancia(rota);
      final tempo = _calcularTempo(distancia);
      final calorias = _calcularCalorias(distancia);

      setState(() {
        _rota = rota;
        _distanciaKm = distancia;
        _tempoMinutos = tempo;
        _calorias = calorias;
        _calculandoRota = false;
      });

      await _mostrarRotaCompleta(rota);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _calculandoRota = false;
        _rota = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível calcular a rota: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  int _calcularTempo(double distanciaKm) {
    const velocidadeMedia = 5.0;
    return ((distanciaKm / velocidadeMedia) * 60).ceil();
  }

  double _calcularCalorias(double distanciaKm) {
    const pesoEstimadoKg = 70.0;
    const fatorCaminhada = 0.75;
    return distanciaKm * pesoEstimadoKg * fatorCaminhada;
  }

  Future<void> _mostrarRotaCompleta(List<LatLng> pontos) async {
    if (pontos.isEmpty || _mapController == null) return;

    var minLat = pontos.first.latitude;
    var maxLat = pontos.first.latitude;
    var minLng = pontos.first.longitude;
    var maxLng = pontos.first.longitude;

    for (final ponto in pontos) {
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

  Future<void> _salvar() async {
    if (_rota.length < 2) return;

    final controller = TextEditingController();

    final titulo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar caminhada'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Ex.: Caminhada no parque',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              final texto = controller.text.trim();

              if (texto.isNotEmpty) {
                Navigator.pop(context, texto);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final texto = controller.text.trim();

                if (texto.isEmpty) return;

                Navigator.pop(context, texto);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (titulo == null || titulo.trim().isEmpty) return;

    final caminhada = Caminhada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo.trim(),
      data: DateTime.now(),
      distanciaKm: _distanciaKm,
      calorias: _calorias,
      tempoMinutos: _tempoMinutos,
      pontos: List<LatLng>.from(_rota),
      fotos: [],
    );

    if (!mounted) return;

    Navigator.pop(context, caminhada);
  }

  Set<Marker> get _marcadores {
    final marcadores = <Marker>{};

    if (_origem != null) {
      marcadores.add(
        Marker(
          markerId: const MarkerId('origem'),
          position: _origem!,
          infoWindow: const InfoWindow(
            title: 'Início',
          ),
        ),
      );
    }

    if (_destino != null) {
      marcadores.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: _destino!,
          infoWindow: const InfoWindow(
            title: 'Destino',
          ),
        ),
      );
    }

    return marcadores;
  }

  Set<Polyline> get _polylines {
    if (_rota.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('rota'),
        points: _rota,
        width: 6,
        color: Theme.of(context).colorScheme.primary,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final centro = _origem ?? _padrao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova caminhada'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: centro,
                    zoom: 15,
                  ),
                  myLocationEnabled: _origem != null,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: _marcadores,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _selecionarDestino,
                ),
                if (_carregandoLocalizacao)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                if (_calculandoRota)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Calculando rota...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Toque no mapa para escolher o destino.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_rota.length >= 2)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoCaminhada(
                        titulo: 'Distância',
                        valor: '${_distanciaKm.toStringAsFixed(2)} km',
                      ),
                      InfoCaminhada(
                        titulo: 'Calorias',
                        valor: '${_calorias.toStringAsFixed(0)} kcal',
                      ),
                      InfoCaminhada(
                        titulo: 'Tempo',
                        valor: '$_tempoMinutos min',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Escolha um destino no mapa para calcular a caminhada.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
