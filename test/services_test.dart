import 'dart:ffi';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shalimar_store/models/product.dart';
import 'package:shalimar_store/models/user_model.dart';
import 'package:shalimar_store/services/storage_service.dart';
import 'package:shalimar_store/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('StorageService Restock Subscriptions', () {
    test('Can subscribe, check status, and unsubscribe from product restock alerts', () async {
      const testProductId = 'prod-basmati-rice-5kg';

      expect(StorageService.isSubscribedToRestock(testProductId), isFalse);

      await StorageService.addRestockSubscription(testProductId);
      expect(StorageService.isSubscribedToRestock(testProductId), isTrue);

      await StorageService.removeRestockSubscription(testProductId);
      expect(StorageService.isSubscribedToRestock(testProductId), isFalse);
    });
  });

  group('UpdateService Version Comparison', () {
    test('Correctly identifies higher version numbers as updates', () {
      expect(UpdateService.isVersionGreater('v3.1.0', 'v3.0.0'), isTrue);
      expect(UpdateService.isVersionGreater('v4.0.0', 'v3.0.0'), isTrue);
      expect(UpdateService.isVersionGreater('v3.0.0', 'v3.0.0'), isFalse);
      expect(UpdateService.isVersionGreater('v2.9.0', 'v3.0.0'), isFalse);
    });

    test('Selects exact architecture-matching APK and avoids wrong architecture', () {
      final mockAssets = [
        {
          'name': 'app-arm64-v8a-release.apk',
          'browser_download_url': 'https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.2.1/app-arm64-v8a-release.apk',
        },
        {
          'name': 'app-armeabi-v7a-release.apk',
          'browser_download_url': 'https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.2.1/app-armeabi-v7a-release.apk',
        },
        {
          'name': 'app-x86_64-release.apk',
          'browser_download_url': 'https://github.com/nadeemalam178/Shalimar-Store/releases/download/v3.2.1/app-x86_64-release.apk',
        },
      ];
      const fallbackUrl = 'https://github.com/nadeemalam178/Shalimar-Store/releases';

      // 1. Android ARM64 must always get arm64-v8a APK, never x86_64
      final arm64Choice = UpdateService.selectBestApkUrl(
        mockAssets,
        fallbackUrl,
        targetAbi: Abi.androidArm64,
      );
      expect(arm64Choice, contains('app-arm64-v8a-release.apk'));

      // 2. Android 32-bit ARM must get armeabi-v7a APK
      final armV7Choice = UpdateService.selectBestApkUrl(
        mockAssets,
        fallbackUrl,
        targetAbi: Abi.androidArm,
      );
      expect(armV7Choice, contains('app-armeabi-v7a-release.apk'));

      // 3. Android x86_64 emulator must get x86_64 APK
      final x86Choice = UpdateService.selectBestApkUrl(
        mockAssets,
        fallbackUrl,
        targetAbi: Abi.androidX64,
      );
      expect(x86Choice, contains('app-x86_64-release.apk'));

      // 4. Default fallback on phone must prioritize ARM64 over x86
      final defaultChoice = UpdateService.selectBestApkUrl(
        mockAssets,
        fallbackUrl,
      );
      expect(defaultChoice, contains('app-arm64-v8a-release.apk'));
      expect(defaultChoice, isNot(contains('x86_64')));
    });

    test('Tracks last prompted update version in StorageService', () async {
      expect(StorageService.getLastPromptedUpdateVersion(), isEmpty);
      await StorageService.setLastPromptedUpdateVersion('v3.2.1');
      expect(StorageService.getLastPromptedUpdateVersion(), equals('v3.2.1'));
    });
  });

  group('Product Serialization', () {
    test('Product serializes to JSON and deserializes identically', () {
      const original = Product(
        id: 'test-1',
        name: 'Tata Tea Gold',
        category: 'Tea & Coffee',
        price: 140.0,
        mrp: 160.0,
        unit: '250g',
        imageUrl: '',
        inStock: false,
        description: 'Rich aroma tea leaves',
      );

      final json = original.toJson();
      final reconstructed = Product.fromJson(json);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.name, equals(original.name));
      expect(reconstructed.price, equals(original.price));
      expect(reconstructed.inStock, equals(original.inStock));
      expect(reconstructed.discountPercent, equals(13.0));
    });
  });

  group('UserModel Serialization', () {
    test('UserModel serializes and deserializes accurately', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'usr_test_123',
        name: 'Md. Nadeem',
        email: 'nadeem@gmail.com',
        phone: '9876543210',
        address: 'Alamganj, Patna',
        role: 'customer',
        provider: 'password',
        createdAt: now,
        lastLoginAt: now,
        appVersion: 'v3.2.0',
      );

      final json = user.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.uid, equals('usr_test_123'));
      expect(restored.name, equals('Md. Nadeem'));
      expect(restored.email, equals('nadeem@gmail.com'));
      expect(restored.isOwner, isFalse);
    });
  });
}
