import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFileWeb(Uint8List bytes, String filename) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$filename');
    await tempFile.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        text: 'Voici le QR Code de mon restaurant sur TrueAts.',
      ),
    );
  } catch (e) {
    throw Exception('Erreur lors du partage du QR code: $e');
  }
}
