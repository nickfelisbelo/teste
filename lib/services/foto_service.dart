import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> tirarFoto() async {
    final foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (foto == null) {
      return null;
    }

    final diretorio = await getApplicationDocumentsDirectory();
    final pasta = Directory('${diretorio.path}/caminhadas_fotos');

    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }

    final nome = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destino = File('${pasta.path}/$nome');

    await File(foto.path).copy(destino.path);

    return destino.path;
  }
}
