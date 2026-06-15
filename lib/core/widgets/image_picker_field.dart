import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';
import '../utils/image_url_helper.dart';

class ImagePickerField extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final XFile? localFile;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const ImagePickerField({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.localFile,
    required this.isUploading,
    required this.onPick,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget preview;
    if (localFile != null) {
      if (kIsWeb) {
        preview = Image.network(
          localFile!.path,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
        );
      } else {
        preview = Image.file(
          File(localFile!.path),
          width: 88,
          height: 88,
          fit: BoxFit.cover,
        );
      }
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      preview = ImageUrlHelper.buildImage(
        imageUrl,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        placeholder: _placeholder(textTheme),
      );
    } else {
      preview = _placeholder(textTheme);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 88, height: 88, child: preview),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleLarge?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isUploading ? null : onPick,
                      icon: isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(isUploading ? 'Envoi...' : 'Choisir'),
                    ),
                    if (((imageUrl != null && imageUrl!.trim().isNotEmpty) || localFile != null) &&
                        onRemove != null)
                      TextButton(
                        onPressed: isUploading ? null : onRemove,
                        child: const Text('Retirer'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(TextTheme textTheme) {
    return Container(
      width: 88,
      height: 88,
      color: AppColors.cremeFonce,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.grisTexte.withValues(alpha: 0.6),
        size: 28,
      ),
    );
  }
}

Future<XFile?> pickImageFromGallery() async {
  final picker = ImagePicker();
  return picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
}
