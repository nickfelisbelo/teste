import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RotaCalculada {
  final List<LatLng> pontos;
  final double distanciaKm;
  final int tempoMinutos;

  const RotaCalculada({
    required this.pontos,
    required this.distanciaKm,
    required this.tempoMinutos,
  });
}

class RotaService {
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static const String _endpoint =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  Future<RotaCalculada> calcularRota({
    required LatLng origem,
    required LatLng destino,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'A chave da Routes API não foi configurada. Execute o app com '
        '--dart-define=GOOGLE_MAPS_API_KEY=SUA_CHAVE.',
      );
    }

    final resposta = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,'
            'routes.polyline.encodedPolyline',
      },
      body: jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': origem.latitude,
              'longitude': origem.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destino.latitude,
              'longitude': destino.longitude,
            },
          },
        },
        'travelMode': 'WALK',
        'languageCode': 'pt-BR',
        'units': 'METRIC',
        'computeAlternativeRoutes': false,
      }),
    );

    final dynamic corpo;

    try {
      corpo = jsonDecode(resposta.body);
    } catch (_) {
      throw Exception('O Google retornou uma resposta inválida.');
    }

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final mensagem = corpo is Map
          ? (corpo['error'] is Map
              ? corpo['error']['message']?.toString()
              : null)
          : null;

      throw Exception(
        mensagem ?? 'Erro HTTP ${resposta.statusCode} ao calcular a rota.',
      );
    }

    if (corpo is! Map || corpo['routes'] is! List) {
      throw Exception(
        'A resposta do Google não contém rotas.',
      );
    }

    final rotas = corpo['routes'] as List;

    if (rotas.isEmpty) {
      throw Exception(
        'Nenhuma rota a pé foi encontrada entre esses pontos.',
      );
    }

    final rota = rotas.first as Map;

    final encoded = rota['polyline']?['encodedPolyline'] as String?;

    final distanciaMetros = rota['distanceMeters'] as num?;

    final duracao = rota['duration']?.toString();

    if (encoded == null || encoded.isEmpty || distanciaMetros == null) {
      throw Exception(
        'O Google não retornou os dados completos da rota.',
      );
    }

    final pontos = _decodificarPolyline(encoded);

    if (pontos.length < 2) {
      throw Exception(
        'A rota retornada não possui pontos suficientes.',
      );
    }

    final segundos = _lerDuracaoSegundos(duracao);

    return RotaCalculada(
      pontos: pontos,
      distanciaKm: distanciaMetros / 1000,
      tempoMinutos: (segundos / 60).ceil(),
    );
  }

  int _lerDuracaoSegundos(String? duracao) {
    if (duracao == null) {
      throw Exception(
        'O Google não retornou a duração estimada da rota.',
      );
    }

    final valor = RegExp(
      r'^(\d+(?:\.\d+)?)s$',
    ).firstMatch(duracao);

    if (valor == null) {
      throw Exception(
        'Formato de duração da rota não reconhecido.',
      );
    }

    return double.parse(valor.group(1)!).ceil();
  }

  List<LatLng> _decodificarPolyline(String encoded) {
    final pontos = <LatLng>[];

    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var shift = 0;
      var resultado = 0;
      int byte;

      do {
        if (index >= encoded.length) {
          throw Exception(
            'Polyline da rota está incompleta.',
          );
        }

        byte = encoded.codeUnitAt(index++) - 63;
        resultado |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      latitude += (resultado & 1) != 0 ? ~(resultado >> 1) : (resultado >> 1);

      shift = 0;
      resultado = 0;

      do {
        if (index >= encoded.length) {
          throw Exception(
            'Polyline da rota está incompleta.',
          );
        }

        byte = encoded.codeUnitAt(index++) - 63;
        resultado |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      longitude += (resultado & 1) != 0 ? ~(resultado >> 1) : (resultado >> 1);

      pontos.add(
        LatLng(
          latitude / 1e5,
          longitude / 1e5,
        ),
      );
    }

    return pontos;
  }
}
