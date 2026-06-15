import 'dart:typed_data';
import 'qr_download_stub.dart'
    if (dart.library.html) 'qr_download_web.dart' as loader;

Future<void> saveFile(Uint8List bytes, String filename) async {
  await loader.downloadFileWeb(bytes, filename);
}
