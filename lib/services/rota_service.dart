import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RotaService {
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  Future<List<LatLng>> calcularRota({
    required LatLng origem,
    required LatLng destino,
  }) async {
    if (_apiKey.isEmpty) {
      return [origem, destino];
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origem.latitude},${origem.longitude}'
      '&destination=${destino.latitude},${destino.longitude}'
      '&mode=walking'
      '&key=$_apiKey',
    );

    final resposta = await http.get(url);

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível calcular a rota.');
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (dados['status'] != 'OK') {
      throw Exception(
        dados['error_message']?.toString() ??
            'Não foi possível encontrar uma rota.',
      );
    }

    final rotas = dados['routes'] as List;

    if (rotas.isEmpty) {
      throw Exception('Nenhuma rota encontrada.');
    }

    final pontos = rotas.first['overview_polyline']['points'] as String;
    return _decodificarPolyline(pontos);
  }

  List<LatLng> _decodificarPolyline(String encoded) {
    final resultado = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;

        if (byte < 0x20) {
          break;
        }
      }

      final deltaLatitude = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      latitude += deltaLatitude;
      shift = 0;
      result = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;

        if (byte < 0x20) {
          break;
        }
      }

      final deltaLongitude = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      longitude += deltaLongitude;

      resultado.add(
        LatLng(
          latitude / 100000.0,
          longitude / 100000.0,
        ),
      );
    }

    return resultado;
  }

  double calcularDistancia(List<LatLng> pontos) {
    if (pontos.length < 2) return 0;

    double metros = 0;

    for (var i = 1; i < pontos.length; i++) {
      metros += _distanciaEntre(
        pontos[i - 1],
        pontos[i],
      );
    }

    return metros / 1000;
  }

  double _distanciaEntre(LatLng a, LatLng b) {
    const raioTerra = 6371000.0;
    final latitude1 = a.latitude * 3.141592653589793 / 180;
    final latitude2 = b.latitude * 3.141592653589793 / 180;
    final deltaLatitude = (b.latitude - a.latitude) * 3.141592653589793 / 180;
    final deltaLongitude =
        (b.longitude - a.longitude) * 3.141592653589793 / 180;

    final senoLatitude = _sin(deltaLatitude / 2);
    final senoLongitude = _sin(deltaLongitude / 2);

    final h = senoLatitude * senoLatitude +
        _cos(latitude1) * _cos(latitude2) * senoLongitude * senoLongitude;

    final c = 2 * _atan2(_sqrt(h), _sqrt(1 - h));

    return raioTerra * c;
  }

  double _sin(double value) => math.sin(value);

  double _cos(double value) => math.cos(value);

  double _sqrt(double value) => math.sqrt(value);

  double _atan2(double y, double x) => math.atan2(y, x);
}
