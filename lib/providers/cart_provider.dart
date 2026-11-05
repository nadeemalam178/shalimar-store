import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;
  List<CartItem> get itemList => _items.values.toList();

  int get totalItemCount {
    int total = 0;
    for (final item in _items.values) {
      total += item.quantity;
    }
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    for (final item in _items.values) {
      total += item.totalPrice;
    }
    return total;
  }

  double get totalMrp {
    double total = 0.0;
    for (final item in _items.values) {
      total += item.totalMrp;
    }
    return total;
  }

  double get totalSavings => totalMrp - totalAmount;

  int getItemQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += 1;
    } else {
      _items[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void decrementItem(Product product) {
    if (!_items.containsKey(product.id)) return;
    if (_items[product.id]!.quantity > 1) {
      _items[product.id]!.quantity -= 1;
    } else {
      _items.remove(product.id);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
