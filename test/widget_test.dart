import 'package:flutter_test/flutter_test.dart';
import 'package:shalimar_store/models/product.dart';
import 'package:shalimar_store/providers/cart_provider.dart';

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
  });
}
