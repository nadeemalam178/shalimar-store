import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'supabase_storage_service.dart';

class ImageUploadService {
  static Future<String?> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    String fileName = 'image.jpg',
  }) async {
    return SupabaseStorageService.uploadProductImage(productId: productId, bytes: bytes, fileName: fileName);
  }

  static Future<void> deleteProductImages(String productId) async {
    return SupabaseStorageService.deleteProductImages(productId);
  }
}