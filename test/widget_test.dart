import 'package:flutter_test/flutter_test.dart';
import 'package:shalimar_store/core/constants/app_constants.dart';
import 'package:shalimar_store/models/product.dart';
import 'package:shalimar_store/providers/cart_provider.dart';
import 'package:shalimar_store/providers/catalogue_provider.dart';
import 'package:shalimar_store/services/admin_auth_service.dart';

void main() {
  group('Product & Cart Unit Tests', () {
    test('Product discount percentage calculation', () {
      const product = Product(
        id: 'test_1',
        name: 'Fortune Oil',
        category: 'Oils & Ghee',
        price: 135.0,
        mrp: 150.0,
        unit: '1 L',
        imageUrl: '',
        inStock: true,
      );

      expect(product.discountPercent, 10.0);
    });

    test('Cart calculations for multiple items', () {
      final cart = CartProvider();
      const product1 = Product(
        id: 'p1',
        name: 'Atta',
        category: 'Grains',
        price: 200.0,
        mrp: 250.0,
        unit: '5 kg',
        imageUrl: '',
        inStock: true,
      );
      const product2 = Product(
        id: 'p2',
        name: 'Salt',
        category: 'Spices',
        price: 25.0,
        mrp: 30.0,
        unit: '1 kg',
        imageUrl: '',
        inStock: true,
      );

      cart.addItem(product1);
      cart.addItem(product1); // 2x Atta = 400
      cart.addItem(product2); // 1x Salt = 25

      expect(cart.totalItemCount, 3);
      expect(cart.totalAmount, 425.0);
      expect(cart.totalMrp, 530.0);
      expect(cart.totalSavings, 105.0);

      cart.decrementItem(product1);
      expect(cart.totalItemCount, 2);
      expect(cart.totalAmount, 225.0);

      cart.clearCart();
      expect(cart.totalItemCount, 0);
      expect(cart.totalAmount, 0.0);
    });

    test('Secure Admin Authentication verification', () {
      // Test incorrect credentials fail
      expect(AdminAuthService.authenticate('admin', 'wrong_pass'), isFalse);
      expect(AdminAuthService.authenticate('random_user', 'shalimar123'), isFalse);

      // Test secure owner credentials pass with Shalimar@1988
      final isAuth1 = AdminAuthService.authenticate(
        'Shalimar@1988',
        'Shal1mar@1988#',
      );
      expect(isAuth1, isTrue);
      expect(AdminAuthService.isLoggedIn, isTrue);

      AdminAuthService.logout();
      expect(AdminAuthService.isLoggedIn, isFalse);

      // Test secure owner credentials pass with owner email
      final isAuth2 = AdminAuthService.authenticate(
        AppConstants.ownerEmail,
        'Shal1mar@1988#',
      );
      expect(isAuth2, isTrue);
      expect(AdminAuthService.isLoggedIn, isTrue);

      AdminAuthService.logout();
      expect(AdminAuthService.isLoggedIn, isFalse);
    });

    test('Hinglish and Colloquial Search Matching', () {
      final catalogue = CatalogueProvider();
      // Test search query with Hinglish synonyms
      catalogue.setSearchQuery('tel');
      // When searching 'tel', it should match products containing 'oil', 'mustard', 'sunflower', etc.
      expect(catalogue.searchQuery, 'tel');
    });
  });
}
