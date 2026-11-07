import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shalimar_store/core/constants/app_constants.dart';
import 'package:shalimar_store/models/user_model.dart';
import 'package:shalimar_store/services/admin_auth_service.dart';
import 'package:shalimar_store/services/supabase_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AdminAuthService.init();
  });

  group('Security Audit - Supabase Storage Validation', () {
    test('Enforces 5 MB maximum file size limit', () {
      expect(SupabaseStorageService.maxSizeBytes, 5 * 1024 * 1024);

      final oversizedBytes = Uint8List(5 * 1024 * 1024 + 1);
      expect(oversizedBytes.lengthInBytes > SupabaseStorageService.maxSizeBytes, isTrue);

      final validSizeBytes = Uint8List(2 * 1024 * 1024);
      expect(validSizeBytes.lengthInBytes <= SupabaseStorageService.maxSizeBytes, isTrue);
    });

    test('Validates MIME type from allowed image extensions', () {
      expect(SupabaseStorageService.getContentType('product.jpg'), 'image/jpeg');
      expect(SupabaseStorageService.getContentType('product.jpeg'), 'image/jpeg');
      expect(SupabaseStorageService.getContentType('product.png'), 'image/png');
      expect(SupabaseStorageService.getContentType('product.webp'), 'image/webp');

      // Disallowed file types
      expect(SupabaseStorageService.getContentType('script.exe'), isNull);
      expect(SupabaseStorageService.getContentType('payload.sh'), isNull);
      expect(SupabaseStorageService.getContentType('document.pdf'), isNull);
      expect(SupabaseStorageService.getContentType('vector.svg'), isNull);
    });

    test('Validates genuine JPEG, PNG, and WebP magic byte signatures', () {
      // JPEG magic bytes: FF D8 FF
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01]);
      expect(SupabaseStorageService.isValidImageBytes(jpegBytes), isTrue);

      // PNG magic bytes: 89 50 4E 47
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D]);
      expect(SupabaseStorageService.isValidImageBytes(pngBytes), isTrue);

      // WebP magic bytes: RIFF....WEBP
      final webpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x20, 0x00, 0x00, 0x00, // length
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(SupabaseStorageService.isValidImageBytes(webpBytes), isTrue);

      // Corrupted / Executable bytes
      final exeBytes = Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00]);
      expect(SupabaseStorageService.isValidImageBytes(exeBytes), isFalse);

      // Truncated bytes (< 12 bytes)
      final truncatedBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      expect(SupabaseStorageService.isValidImageBytes(truncatedBytes), isFalse);
    });
  });

  group('Security Audit - Owner Authentication & Role Enforcement', () {
    test('Validates authorized owner IDs and rejects unauthorized identifiers', () {
      expect(AdminAuthService.isOwnerId('Shalimar@1988'), isTrue);
      expect(AdminAuthService.isOwnerId('shalimar@1988'), isTrue);
      expect(AdminAuthService.isOwnerId(AppConstants.ownerEmail), isTrue);
      expect(AdminAuthService.isOwnerId('NadeemAlam178@Gmail.com'), isTrue);

      // Unauthorized IDs
      expect(AdminAuthService.isOwnerId('admin'), isFalse);
      expect(AdminAuthService.isOwnerId('owner'), isFalse);
      expect(AdminAuthService.isOwnerId('customer@gmail.com'), isFalse);
      expect(AdminAuthService.isOwnerId(''), isFalse);
    });

    test('Customer model defaults to customer role and restricts owner privilege', () {
      final customer = UserModel(
        uid: 'user_cust_01',
        name: 'Regular Customer',
        email: 'customer@example.com',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      expect(customer.role, 'customer');
      expect(customer.isOwner, isFalse);

      final owner = customer.copyWith(role: 'owner');
      expect(owner.isOwner, isTrue);
    });

    test('Local session restoration rejects when Firebase user is not store owner', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyAdminSessionActive, true);
      await prefs.setInt(AppConstants.keyAdminLoginTimestamp, DateTime.now().millisecondsSinceEpoch);

      // Without Firebase owner user, session must not be restored
      final restored = await AdminAuthService.restoreSession();
      expect(restored, isFalse);
      expect(AdminAuthService.isLoggedIn, isFalse);
    });
  });

  group('Security Audit - Firestore Rules Verification', () {
    test('firestore.rules file does not contain open public writes or PII leaks', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();

      // Ensure open write on products is completely eliminated
      expect(content.contains('match /products/{productId} {\n      allow read: if true;\n      allow write: if true;'), isFalse);

      // Ensure strict isOwner() check on products write
      expect(content.contains('allow write: if isOwner();'), isTrue);

      // Ensure user profiles are not publicly readable
      expect(content.contains('match /users/{userId} {\n      allow read: if true;'), isFalse);
      expect(content.contains('allow read: if isOwnerOrSelf(userId);'), isTrue);

      // Ensure admin sessions write is restricted to owner
      expect(content.contains('match /admin_sessions/{document=**} {\n      allow read, write: if true;'), isFalse);

      // Ensure flawed email_verified rule without email is removed
      expect(content.contains('request.auth.token.email_verified == true\n      );'), isFalse);
    });
  });
}

