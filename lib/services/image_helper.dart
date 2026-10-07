import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Image Helper — File to Base64 (compressed)
class ImageHelper {
  static Future<String> fileToBase64(
    File file, {
    int maxWidth = 600,
    int quality = 70,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Invalid image format');
      if (image.width > maxWidth) {
        image = img.copyResize(image,
            width: maxWidth,
            interpolation: img.Interpolation.linear);
      }
      final compressed = img.encodeJpg(image, quality: quality);
      return 'data:image/jpeg;base64,${base64Encode(compressed)}';
    } catch (e) {
      debugPrint('ImageHelper.fileToBase64 error: $e');
      rethrow;
    }
  }

  static Uint8List base64ToBytes(String base64String) {
    try {
      final pureBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(pureBase64);
    } catch (e) {
      debugPrint('ImageHelper.base64ToBytes error: $e');
      return Uint8List(0);
    }
  }

  static double base64SizeKB(String base64String) {
    return base64String.length / 1024;
  }

  static bool isSafeForFirestore(String base64String) {
    return base64SizeKB(base64String) < 800;
  }
}