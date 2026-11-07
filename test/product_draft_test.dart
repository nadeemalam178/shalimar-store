import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shalimar_store/services/product_draft_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProductDraftService - Form Draft Persistence', () {
    test('Saves and loads a new product draft accurately', () async {
      expect(await ProductDraftService.hasDraft(), isFalse);
      expect(await ProductDraftService.loadDraft(), isNull);

      final draft = ProductDraft(
        productId: null,
        name: 'Fortune Sunlite Sunflower Oil',
        category: 'Oils & Ghee',
        price: '185',
        mrp: '210',
        unit: '1 Liter',
        isCustomUnit: false,
        description: 'Refined sunflower oil for cooking',
        inStock: true,
        localImagePath: '/data/user/0/com.shalimar.store/cache/oil.jpg',
        imageUrl: '',
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );

      await ProductDraftService.saveDraft(draft);

      expect(await ProductDraftService.hasDraft(), isTrue);
      final loaded = await ProductDraftService.loadDraft();
      expect(loaded, isNotNull);
      expect(loaded!.productId, isNull);
      expect(loaded.name, 'Fortune Sunlite Sunflower Oil');
      expect(loaded.category, 'Oils & Ghee');
      expect(loaded.price, '185');
      expect(loaded.mrp, '210');
      expect(loaded.unit, '1 Liter');
      expect(loaded.isCustomUnit, isFalse);
      expect(loaded.description, 'Refined sunflower oil for cooking');
      expect(loaded.inStock, isTrue);
      expect(loaded.localImagePath, '/data/user/0/com.shalimar.store/cache/oil.jpg');
    });

    test('Saves and loads an edit product draft accurately', () async {
      const prodId = 'prod-aashirvaad-atta-10kg';
      expect(await ProductDraftService.hasDraft(productId: prodId), isFalse);

      final draft = ProductDraft(
        productId: prodId,
        name: 'Aashirvaad Shudh Chakki Atta',
        category: 'Atta & Flours',
        price: '440',
        mrp: '490',
        unit: '10 kg',
        isCustomUnit: false,
        description: '100% whole wheat flour',
        inStock: false,
        localImagePath: null,
        imageUrl: 'https://example.com/atta.png',
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );

      await ProductDraftService.saveDraft(draft);

      expect(await ProductDraftService.hasDraft(productId: prodId), isTrue);
      final loaded = await ProductDraftService.loadDraft(productId: prodId);
      expect(loaded, isNotNull);
      expect(loaded!.productId, prodId);
      expect(loaded.name, 'Aashirvaad Shudh Chakki Atta');
      expect(loaded.price, '440');
      expect(loaded.inStock, isFalse);
      expect(loaded.imageUrl, 'https://example.com/atta.png');
    });

    test('Keeps New Product and Edit Product drafts strictly separated', () async {
      const editId1 = 'item_edit_001';
      const editId2 = 'item_edit_002';

      // 1. Save new product draft
      await ProductDraftService.saveDraft(ProductDraft(
        productId: null,
        name: 'New Basmati Rice',
        price: '120',
        lastModified: 1000,
      ));

      // 2. Save edit draft 1
      await ProductDraftService.saveDraft(ProductDraft(
        productId: editId1,
        name: 'Editing Existing Sugar 5kg',
        price: '210',
        lastModified: 2000,
      ));

      // 3. Save edit draft 2
      await ProductDraftService.saveDraft(ProductDraft(
        productId: editId2,
        name: 'Editing Existing Tea 250gm',
        price: '95',
        lastModified: 3000,
      ));

      // Verify all 3 exist concurrently with separate keys and contents
      final newDraft = await ProductDraftService.loadDraft();
      final editDraft1 = await ProductDraftService.loadDraft(productId: editId1);
      final editDraft2 = await ProductDraftService.loadDraft(productId: editId2);

      expect(newDraft?.name, 'New Basmati Rice');
      expect(editDraft1?.name, 'Editing Existing Sugar 5kg');
      expect(editDraft2?.name, 'Editing Existing Tea 250gm');

      // 4. Clear editDraft1 only
      await ProductDraftService.clearDraft(productId: editId1);
      expect(await ProductDraftService.hasDraft(productId: editId1), isFalse);

      // Verify newDraft and editDraft2 remain intact
      expect(await ProductDraftService.hasDraft(), isTrue);
      expect((await ProductDraftService.loadDraft())?.name, 'New Basmati Rice');
      expect(await ProductDraftService.hasDraft(productId: editId2), isTrue);
      expect((await ProductDraftService.loadDraft(productId: editId2))?.name, 'Editing Existing Tea 250gm');
    });

    test('Handles custom units and custom pack-sizes properly', () async {
      final draft = ProductDraft(
        productId: null,
        name: 'Special Herbal Soap',
        unit: '3 Bars Pack',
        isCustomUnit: true,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );

      await ProductDraftService.saveDraft(draft);

      final loaded = await ProductDraftService.loadDraft();
      expect(loaded?.unit, '3 Bars Pack');
      expect(loaded?.isCustomUnit, isTrue);
    });

    test('ProductDraft isEmpty property correctly flags empty drafts', () {
      final emptyDraft = ProductDraft(
        lastModified: 100,
      );
      expect(emptyDraft.isEmpty, isTrue);

      final populatedDraft = ProductDraft(
        name: 'Colgate Strong Teeth',
        lastModified: 100,
      );
      expect(populatedDraft.isEmpty, isFalse);

      final imageOnlyDraft = ProductDraft(
        localImagePath: '/tmp/photo.jpg',
        lastModified: 100,
      );
      expect(imageOnlyDraft.isEmpty, isFalse);
    });
  });
}

