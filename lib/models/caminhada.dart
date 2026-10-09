import 'package:google_maps_flutter/google_maps_flutter.dart';

class Caminhada {
  final String id;
  final String titulo;
  final DateTime data;
  final double distanciaKm;
  final double calorias;
  final int tempoMinutos;
  final List<LatLng> pontos;
  final List<String> fotos;

  Caminhada({
    required this.id,
    required this.titulo,
    required this.data,
    required this.distanciaKm,
    required this.calorias,
    required this.tempoMinutos,
    required this.pontos,
    required this.fotos,
  });

  Caminhada copyWith({
    String? titulo,
    DateTime? data,
    double? distanciaKm,
    double? calorias,
    int? tempoMinutos,
    List<LatLng>? pontos,
    List<String>? fotos,
  }) {
    return Caminhada(
      id: id,
      titulo: titulo ?? this.titulo,
      data: data ?? this.data,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      calorias: calorias ?? this.calorias,
      tempoMinutos: tempoMinutos ?? this.tempoMinutos,
      pontos: pontos ?? this.pontos,
      fotos: fotos ?? this.fotos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'data': data.toIso8601String(),
      'distanciaKm': distanciaKm,
      'calorias': calorias,
      'tempoMinutos': tempoMinutos,
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
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: json['titulo']?.toString() ?? 'Caminhada',
      data: DateTime.tryParse(json['data']?.toString() ?? '') ?? DateTime.now(),
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble() ?? 0,
      calorias: (json['calorias'] as num?)?.toDouble() ?? 0,
      tempoMinutos: (json['tempoMinutos'] as num?)?.toInt() ?? 0,
      pontos: ((json['pontos'] as List?) ?? [])
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
