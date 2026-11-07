import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Storage Service for Shalimar Store product images.
/// Includes strict file-size enforcement (5 MB max), allowed extension checks,
/// and magic-byte signature validation.
class SupabaseStorageService {
  static const String _bucket = 'product-images';
  static const int _maxSizeBytes = 5 * 1024 * 1024; // 5 MB
  static bool _initialized = false;

  static int get maxSizeBytes => _maxSizeBytes;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );
    _initialized = true;
    debugPrint('✅ [SupabaseStorage] Initialized with 5MB validation');
  }

  /// Determines MIME Content-Type from file name
  static String? getContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  /// Validates magic bytes to ensure file is actually a valid JPEG, PNG, or WebP image
  static bool isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    // WebP: RIFF (bytes 0-3) and WEBP (bytes 8-11)
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return true;
    }
    return false;
  }

  static Future<String?> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    String fileName = 'main.jpg',
  }) async {
    if (!_initialized) return null;

    // 1. Strict File Size Validation (Max 5 MB)
    if (bytes.lengthInBytes > _maxSizeBytes) {
      debugPrint('⚠️ [SupabaseStorage] Image rejected: Size (${bytes.lengthInBytes} bytes) exceeds 5MB limit.');
      return null;
    }

    // 2. MIME Type Validation
    final contentType = getContentType(fileName);
    if (contentType == null) {
      debugPrint('⚠️ [SupabaseStorage] Image rejected: Invalid file extension for "$fileName". Allowed: .jpg, .jpeg, .png, .webp.');
      return null;
    }

    // 3. Magic-Byte Image Header Signature Validation
    if (!isValidImageBytes(bytes)) {
      debugPrint('⚠️ [SupabaseStorage] Image rejected: File contents do not match genuine JPEG/PNG/WebP magic bytes.');
      return null;
    }

    try {
      final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = '$productId/$sanitizedName';

      // Attempt standard upload (works with standard INSERT policy)
      try {
        await Supabase.instance.client.storage.from(_bucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: false),
            );
      } catch (insertErr) {
        // If file already exists, retry with upsert
        debugPrint('ℹ️ [SupabaseStorage] Standard insert fallback to upsert: $insertErr');
        await Supabase.instance.client.storage.from(_bucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );
      }

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
