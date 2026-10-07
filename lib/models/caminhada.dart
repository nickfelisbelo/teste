import 'package:google_maps_flutter/google_maps_flutter.dart';

class Caminhada {
  final String id;
  final DateTime inicio;
  final DateTime fim;
  final double distanciaKm;
  final int duracaoSegundos;
  final List<LatLng> pontos;
  final List<String> fotos;

  Caminhada({
    required this.id,
    required this.inicio,
    required this.fim,
    required this.distanciaKm,
    required this.duracaoSegundos,
    required this.pontos,
    required this.fotos,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
      'distanciaKm': distanciaKm,
      'duracaoSegundos': duracaoSegundos,
      'pontos': pontos
          .map((ponto) => {
                'latitude': ponto.latitude,
                'longitude': ponto.longitude,
              })
          .toList(),
      'fotos': fotos,
    };
  }

  factory Caminhada.fromJson(Map<String, dynamic> json) {
    return Caminhada(
      id: json['id'],
      inicio: DateTime.parse(json['inicio']),
      fim: DateTime.parse(json['fim']),
      distanciaKm: (json['distanciaKm'] as num).toDouble(),
      duracaoSegundos: json['duracaoSegundos'],
      pontos: (json['pontos'] as List)
          .map(
            (ponto) => LatLng(
              (ponto['latitude'] as num).toDouble(),
              (ponto['longitude'] as num).toDouble(),
            ),
          )
          .toList(),
      fotos: List<String>.from(json['fotos'] ?? []),
    );
  }
}
