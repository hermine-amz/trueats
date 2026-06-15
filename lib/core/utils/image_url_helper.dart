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
        trimmed.startsWith('storage/');
  }

  static String resolve(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }

    final trimmed = url.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (!kIsWeb && Platform.isAndroid && trimmed.contains('localhost')) {
        return trimmed.replaceFirst('localhost', '10.0.2.2');
      }
      if (!kIsWeb && Platform.isAndroid && trimmed.contains('127.0.0.1')) {
        return trimmed.replaceFirst('127.0.0.1', '10.0.2.2');
      }
      return trimmed;
    }

    final apiBase = ApiClient.baseUrl;
    final origin = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

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

    if (isNetworkPath(trimmed)) {
      final resolved = resolve(trimmed);
      return Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? const Icon(Icons.broken_image),
      );
    } else {
      return Image.file(
        File(trimmed),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? const Icon(Icons.broken_image),
      );
    }
  }
}

