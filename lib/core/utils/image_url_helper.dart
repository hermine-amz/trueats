import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/http_services.dart';

// Note: Cet helper permet de gérer de manière transparente la résolution des chemins d'images, 
// qu'il s'agisse d'URLs absolues, de chemins relatifs stockés en BDD via Laravel public disk, 
// ou de fichiers locaux temporaires (très utile lors des phases de tests avec les services mockés).
class ImageUrlHelper {
  static bool isNetworkPath(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }
    final trimmed = url.trim().toLowerCase();
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('/storage') ||
        trimmed.startsWith('storage/') ||
        trimmed.startsWith('/api/storage') ||
        trimmed.startsWith('api/storage');
  }

  static String resolve(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }

    String trimmed = url.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (!kIsWeb && Platform.isAndroid && trimmed.contains('localhost')) {
        trimmed = trimmed.replaceFirst('localhost', '10.0.2.2');
      } else if (!kIsWeb && Platform.isAndroid && trimmed.contains('127.0.0.1')) {
        trimmed = trimmed.replaceFirst('127.0.0.1', '10.0.2.2');
      }
      if (trimmed.contains('/storage/')) {
        trimmed = trimmed.replaceFirst('/storage/', '/api/storage/');
      }
      return trimmed;
    }

    final apiBase = ApiClient.baseUrl;
    final origin = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    if (trimmed.startsWith('/storage/')) {
      trimmed = '/api/storage/${trimmed.substring(9)}';
    } else if (trimmed.startsWith('storage/')) {
      trimmed = '/api/storage/${trimmed.substring(8)}';
    }

    if (trimmed.startsWith('/')) {
      return '$origin$trimmed';
    }

    return '$origin/$trimmed';
  }

  static Widget buildImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (url == null || url.trim().isEmpty) {
      return placeholder ?? const Icon(Icons.image);
    }

    final trimmed = url.trim();

    if (isNetworkPath(trimmed) || (kIsWeb && trimmed.startsWith('blob:'))) {
      final resolved = trimmed.startsWith('blob:') ? trimmed : resolve(trimmed);
      return Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        // Mise en cache dimensionnelle pour réduire la mémoire sur mobile
        cacheWidth: width != null ? (width * 2).toInt() : null,
        cacheHeight: height != null ? (height * 2).toInt() : null,
        filterQuality: FilterQuality.medium,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        // Affiche le placeholder pendant le téléchargement (évite l'écran blanc)
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: const Color(0xFFEDE8E3),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFC4704A),
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (_, __, ___) => placeholder ?? const Icon(Icons.broken_image),
      );
    } else {
      if (kIsWeb) {
        return placeholder ?? const Icon(Icons.broken_image);
      }
      return Image.file(
        File(trimmed),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width != null ? (width * 2).toInt() : null,
        cacheHeight: height != null ? (height * 2).toInt() : null,
        errorBuilder: (_, __, ___) => placeholder ?? const Icon(Icons.broken_image),
      );
    }
  }
}

