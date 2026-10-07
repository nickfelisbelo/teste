import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/caminhada.dart';
import '../services/caminhada_storage.dart';
import '../services/foto_service.dart';
import 'historico_page.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CaminhadaStorage _storage = CaminhadaStorage();
  final FotoService _fotoService = FotoService();
  GoogleMapController? mapaController;
  Position? posicaoAtual;
  StreamSubscription<Position>? posicaoSubscription;
  Timer? cronometro;
  DateTime? inicio;
  int segundos = 0;
  double distanciaKm = 0;
  final List<LatLng> pontos = [];
  final List<String> fotos = [];
  List<Caminhada> historico = [];
  bool caminhando = false;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    posicaoSubscription?.cancel();
    cronometro?.cancel();
    super.dispose();
  }

  Future<void> carregarDados() async {
    historico = await _storage.carregar();
    await inicializarGps();
  }

  Future<void> inicializarGps() async {
    final habilitado = await Geolocator.isLocationServiceEnabled();

    if (!habilitado) {
      setState(() => carregando = false);
      return;
    }

    var permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      setState(() => carregando = false);
      return;
    }

    final posicao = await Geolocator.getCurrentPosition();

    setState(() {
      posicaoAtual = posicao;
      carregando = false;
    });
  }

  Future<void> iniciarCaminhada() async {
    if (posicaoAtual == null) {
      await inicializarGps();
    }

    if (posicaoAtual == null) return;

    posicaoSubscription?.cancel();
    cronometro?.cancel();

    final pontoInicial = LatLng(
      posicaoAtual!.latitude,
      posicaoAtual!.longitude,
    );

    setState(() {
      caminhando = true;
      inicio = DateTime.now();
      segundos = 0;
      distanciaKm = 0;
      pontos.clear();
      fotos.clear();
      pontos.add(pontoInicial);
    });

    cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => segundos++);
      }
    });

    posicaoSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((posicao) {
      if (!caminhando) return;

      final novoPonto = LatLng(posicao.latitude, posicao.longitude);

      if (pontos.isNotEmpty) {
        final anterior = pontos.last;
        final metros = Geolocator.distanceBetween(
          anterior.latitude,
          anterior.longitude,
          novoPonto.latitude,
          novoPonto.longitude,
        );

        if (metros > 1) {
          setState(() {
            distanciaKm += metros / 1000;
            pontos.add(novoPonto);
            posicaoAtual = posicao;
          });
        }
      } else {
        setState(() {
          pontos.add(novoPonto);
          posicaoAtual = posicao;
        });
      }

      mapaController?.animateCamera(CameraUpdate.newLatLng(novoPonto));
    });
  }

  Future<void> tirarFoto() async {
    if (!caminhando) return;

    final caminho = await _fotoService.tirarFoto();

    if (caminho == null) return;

    setState(() => fotos.add(caminho));
  }

  Future<void> finalizarCaminhada() async {
    if (!caminhando || inicio == null) return;

    await posicaoSubscription?.cancel();
    cronometro?.cancel();

    final caminhada = Caminhada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      inicio: inicio!,
      fim: DateTime.now(),
      distanciaKm: distanciaKm,
      duracaoSegundos: segundos,
      pontos: List.from(pontos),
      fotos: List.from(fotos),
    );

    historico.insert(0, caminhada);
    await _storage.salvar(historico);

    setState(() {
      caminhando = false;
      inicio = null;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caminhada salva no histórico.')),
    );
  }

  String formatarDuracao(int totalSegundos) {
    final horas = totalSegundos ~/ 3600;
    final minutos = (totalSegundos % 3600) ~/ 60;
    final segundosRestantes = totalSegundos % 60;

    if (horas > 0) {
      return '${horas.toString().padLeft(2, '0')}:'
          '${minutos.toString().padLeft(2, '0')}:'
          '${segundosRestantes.toString().padLeft(2, '0')}';
    }

    return '${minutos.toString().padLeft(2, '0')}:'
        '${segundosRestantes.toString().padLeft(2, '0')}';
  }

  Set<Polyline> get linhas {
    if (pontos.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('trajeto'),
        points: pontos,
        width: 6,
        color: Colors.green,
      ),
    };
  }

  Set<Marker> get marcadores {
    final resultado = <Marker>{};

    if (pontos.isNotEmpty) {
      resultado.add(
        Marker(
          markerId: const MarkerId('inicio'),
          position: pontos.first,
          infoWindow: const InfoWindow(title: 'Início'),
        ),
      );
    }

    if (pontos.length > 1) {
      resultado.add(
        Marker(
          markerId: const MarkerId('atual'),
          position: pontos.last,
          infoWindow: const InfoWindow(title: 'Posição atual'),
        ),
      );
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final pontoInicial = posicaoAtual == null
        ? const LatLng(-23.5505, -46.6333)
        : LatLng(posicaoAtual!.latitude, posicaoAtual!.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Caminhadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoricoPage(
                    historico: historico,
                    formatarDuracao: formatarDuracao,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: pontoInicial,
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    markers: marcadores,
                    polylines: linhas,
                    onMapCreated: (controller) {
                      mapaController = controller;
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InfoCaminhada(
                            titulo: 'Distância',
                            valor: '${distanciaKm.toStringAsFixed(2)} km',
                          ),
                          InfoCaminhada(
                            titulo: 'Tempo',
                            valor: formatarDuracao(segundos),
                          ),
                          InfoCaminhada(
                            titulo: 'Fotos',
                            valor: fotos.length.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: caminhando
                                  ? finalizarCaminhada
                                  : iniciarCaminhada,
                              icon: Icon(
                                caminhando ? Icons.stop : Icons.play_arrow,
                              ),
                              label: Text(
                                caminhando
                                    ? 'Finalizar caminhada'
                                    : 'Iniciar caminhada',
                              ),
                            ),
                          ),
                          if (caminhando) ...[
                            const SizedBox(width: 10),
                            IconButton.filled(
                              onPressed: tirarFoto,
                              icon: const Icon(Icons.camera_alt),
                              tooltip: 'Tirar foto',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
