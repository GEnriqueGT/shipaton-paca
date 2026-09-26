import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';

class AdGenerationException implements Exception {
  AdGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

String studioAdPrompt(String brandHex) {
  final hex = brandHex.trim().startsWith('#') ? brandHex.trim() : '#${brandHex.trim()}';
  return 'Create a NEW photorealistic 3D apparel mockup from the reference photo. '
      'Do not return the original flat, front-facing catalog photo. '
      'Re-render the same shirt twice, floating in mid-air on a solid $hex background: '
      'left is the back view turned about 20 degrees, '
      'right is the front view in a three-quarter 3D angle so the sleeve and side are visible. '
      'Both pieces need volume, collar depth, fabric folds and a soft floor shadow, '
      'like a premium clothing render. '
      'No person, no mannequin, no hanger, no text, no logo, no watermark. '
      'Square composition.';
}

/// Pulls the first generated image out of an OpenRouter chat response.
Uint8List? imageBytesFromOpenRouter(Map<String, dynamic> json) {
  final choices = json['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final first = choices.first;
  if (first is! Map) return null;
  final message = first['message'];
  if (message is! Map) return null;

  final images = message['images'];
  if (images is List) {
    for (final image in images) {
      final bytes = _bytesFromNode(image);
      if (bytes != null) return bytes;
    }
  }

  final content = message['content'];
  if (content is String) return _bytesFromDataUrl(content);
  if (content is List) {
    for (final part in content) {
      final bytes = _bytesFromNode(part);
      if (bytes != null) return bytes;
    }
  }
  return null;
}

Future<Uint8List> fetchImageBytes(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw AdGenerationException('No se pudo descargar la foto de la paca.');
    }
    return await consolidateHttpClientResponseBytes(response);
  } finally {
    client.close();
  }
}

Future<Uint8List> generateStudioAd({
  required Uint8List photo,
  required String brandHex,
  String? apiKey,
  String? model,
}) async {
  final key = (apiKey ?? AppConfig.openRouterApiKey).trim();
  if (key.isEmpty) {
    throw AdGenerationException(
      'Agrega OPENROUTER_API_KEY en el .env para generar la publicidad.',
    );
  }

  final mime = _mimeFor(photo);
  final dataUrl = 'data:$mime;base64,${base64Encode(photo)}';
  final body = jsonEncode({
    'model': (model ?? AppConfig.openRouterImageModel).trim(),
    'modalities': ['image', 'text'],
    'image_config': {'aspect_ratio': '1:1'},
    'messages': [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': studioAdPrompt(brandHex)},
          {
            'type': 'image_url',
            'image_url': {'url': dataUrl},
          },
        ],
      },
    ],
  });

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    );
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $key')
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.acceptHeader, 'application/json');
    request.write(body);
    final response = await request.close().timeout(const Duration(seconds: 90));
    final raw = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw AdGenerationException(_errorMessage(raw, response.statusCode));
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw AdGenerationException('OpenRouter no devolvió una imagen.');
    }
    final bytes = imageBytesFromOpenRouter(Map<String, dynamic>.from(decoded));
    if (bytes == null) {
      throw AdGenerationException('OpenRouter no devolvió una imagen.');
    }
    return bytes;
  } on AdGenerationException {
    rethrow;
  } catch (_) {
    throw AdGenerationException('No se pudo generar la publicidad. Intenta de nuevo.');
  } finally {
    client.close();
  }
}

String _errorMessage(String raw, int status) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final error = decoded['error'];
      if (error is Map && error['message'] is String) {
        return 'OpenRouter: ${error['message']}';
      }
    }
  } catch (_) {
    // Fall through to the status line.
  }
  return 'OpenRouter respondió $status.';
}

Uint8List? _bytesFromNode(Object? node) {
  if (node is! Map) return null;
  final imageUrl = node['image_url'];
  if (imageUrl is Map && imageUrl['url'] is String) {
    return _bytesFromDataUrl(imageUrl['url'] as String);
  }
  if (node['url'] is String) {
    return _bytesFromDataUrl(node['url'] as String);
  }
  return null;
}

Uint8List? _bytesFromDataUrl(String value) {
  final match = RegExp(
    r'data:image/[a-zA-Z0-9.+-]+;base64,([A-Za-z0-9+/=\s]+)',
  ).firstMatch(value);
  if (match == null) return null;
  try {
    return base64Decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
  } catch (_) {
    return null;
  }
}

String _mimeFor(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return 'image/jpeg';
  }
  return 'image/jpeg';
}
