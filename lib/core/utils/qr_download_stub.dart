import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

Future<void> downloadFileWeb(Uint8List bytes, String filename) async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: filename.replaceAll('.png', ''),
        quality: 100,
      );
      
      // result est un dictionnaire dynamique (Map)
      if (result is Map && result['isSuccess'] == true) {
        return; // Succès
      } else if (result != null && result.toString().contains('true')) {
        return; // Succès (fallback selon les versions du package)
      }
    }
    
    // Fallback pour Desktop ou en cas d'échec
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
    throw Exception('Erreur lors de la sauvegarde du QR code: $e');
  }
}
