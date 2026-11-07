import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Supabase Storage Service for Shalimar Store product images.
class SupabaseStorageService {
  static const String _bucket = 'product-images';
  static const int _maxSizeBytes = 5 * 1024 * 1024;
  static bool _initialized = false;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
    debugPrint('✅ [SupabaseStorage] Initialized');
  }

  static Future<String?> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    String fileName = 'main.jpg',
  }) async {
    if (!_initialized) return null;
    try {
      final path = '$productId/${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      final lower = fileName.toLowerCase();
      final contentType = lower.endsWith('.png')
          ? 'image/png'
          : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      await Supabase.instance.client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      final publicUrl = Supabase.instance.client.storage.from(_bucket).getPublicUrl(path);
      debugPrint('📸 [SupabaseStorage] Successfully uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('⚠️ [SupabaseStorage] Upload failed: $e');
      return null;
    }
  }

  static Future<void> deleteProductImages(String productId) async {
    if (!_initialized) return;
    try {
      final files = await Supabase.instance.client.storage.from(_bucket).list(path: productId);
      if (files.isNotEmpty) {
        await Supabase.instance.client.storage.from(_bucket).remove(files.map((f) => '$productId/${f.name}').toList());
      }
    } catch (e) {
      debugPrint('⚠️ [SupabaseStorage] Delete failed: $e');
    }
  }
}