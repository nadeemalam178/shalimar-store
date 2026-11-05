import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shalimar_store/models/product.dart';
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
}
