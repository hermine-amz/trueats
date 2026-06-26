import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_url_helper.dart';

class DocumentPreviewDialog extends StatelessWidget {
  final String title;
  final String? url;
  final XFile? localFile;
  final bool isPdf;

  const DocumentPreviewDialog({
    super.key,
    required this.title,
    this.url,
    this.localFile,
    required this.isPdf,
  }) : assert(url != null || localFile != null);

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = url != null ? ImageUrlHelper.resolve(url) : null;

    return Dialog(
      backgroundColor: AppColors.creme,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.replaceAll(RegExp(r'\s*\(PDF ou [iI]mage\)', caseSensitive: false), ''),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.marronFonce,
                    ),
                  ),
                ),
                if (resolvedUrl != null)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppColors.terracotta),
                    tooltip: 'Télécharger / Ouvrir dans le navigateur',
                    onPressed: () async {
                      final uri = Uri.parse(resolvedUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.marronFonce),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: FutureBuilder<Uint8List>(
                future: _getFileBytes(),
                builder: (context, snapshot) {
                  if (localFile != null && snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur : ${snapshot.error}", textAlign: TextAlign.center));
                  }

                  final bytes = snapshot.data;

                  if (isPdf) {
                    if (localFile != null && !kIsWeb) {
                      return SfPdfViewer.file(File(localFile!.path));
                    } else if (resolvedUrl != null && !resolvedUrl.startsWith('blob:')) {
                      return SfPdfViewer.network(
                        resolvedUrl,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                      );
                    } else if (bytes != null && bytes.isNotEmpty) {
                      return SfPdfViewer.memory(bytes);
                    }
                  } else {
                    if (localFile != null && !kIsWeb) {
                      return Image.file(File(localFile!.path), fit: BoxFit.contain);
                    } else if (resolvedUrl != null && !resolvedUrl.startsWith('blob:')) {
                      return Image.network(
                        resolvedUrl,
                        fit: BoxFit.contain,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                      );
                    } else if (bytes != null && bytes.isNotEmpty) {
                      return Image.memory(bytes, fit: BoxFit.contain);
                    }
                  }
                  return const Center(child: Text("Aucun document à afficher."));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _getFileBytes() async {
    if (localFile != null) {
      return await localFile!.readAsBytes();
    }
    return Uint8List(0);
  }
}
