import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/caminhada.dart';

class CaminhadaStorage {
  Future<File> _arquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/caminhadas.json');
  }

  Future<List<Caminhada>> carregar() async {
    final arquivo = await _arquivo();

    if (!await arquivo.exists()) {
      return [];
    }

    try {
      final texto = await arquivo.readAsString();
      final lista = jsonDecode(texto) as List;

      return lista
          .map((item) => Caminhada.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> salvar(List<Caminhada> caminhadas) async {
    final arquivo = await _arquivo();
    final texto = jsonEncode(
      caminhadas.map((caminhada) => caminhada.toJson()).toList(),
    );
    await arquivo.writeAsString(texto);
  }
}
