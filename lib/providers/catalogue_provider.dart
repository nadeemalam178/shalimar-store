import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../services/admin_auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class CatalogueProvider with ChangeNotifier {
  List<Product> _products = [];
  List<String> _customCategories = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<String> get categories {
    final set = <String>{'All'};
    for (final c in _customCategories) {
      if (c.trim().isNotEmpty) set.add(c.trim());
    }
    for (final p in _products) {
      if (p.category.trim().isNotEmpty) set.add(p.category.trim());
    }
    return set.toList();
  }

  List<Product> get filteredProducts {
    return _products.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.unit.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _products = await StorageService.loadProducts();
    _customCategories = StorageService.loadCustomCategories();
    _isLoading = false;
    notifyListeners();

    CloudSyncService.startLiveCatalogueListener(
      onCatalogueUpdated: (cloudProducts) {
        _syncFromCloud(cloudProducts);
      },
    );
  }

  void _syncFromCloud(List<Product> cloudProducts) {
    if (cloudProducts.isEmpty) return;

    if (_products.isNotEmpty) {
      _checkAndNotifyStockChanges(oldList: _products, newList: cloudProducts);
    }

    // Safely merge: update products by ID without dropping existing catalogue items
    final Map<String, Product> productMap = {
      for (final p in _products) p.id: p,
    };
    for (final cp in cloudProducts) {
      productMap[cp.id] = cp;
    }

    _products = productMap.values.toList();
    unawaited(StorageService.saveProducts(_products));
    notifyListeners();
  }

  void _checkAndNotifyStockChanges({required List<Product> oldList, required List<Product> newList}) {
    // If Admin is active on this device, do not trigger customer push notifications
    if (AdminAuthService.isLoggedIn) return;

    final favoriteIds = StorageService.loadFavorites();
    final cartProductIds = StorageService.loadCart().map((i) => i.product.id).toSet();

    for (final newP in newList) {
      final oldIndex = oldList.indexWhere((p) => p.id == newP.id);
      if (oldIndex == -1) continue;
      final oldP = oldList[oldIndex];

      final isFavorite = favoriteIds.contains(newP.id);
      final isInCart = cartProductIds.contains(newP.id);
      final isSubscribed = NotificationService.isSubscribed(newP.id);

      // Notify strictly if customer has this product in Favorites, Cart, or subscribed to restock
      if (!isFavorite && !isInCart && !isSubscribed) continue;

      if (!oldP.inStock && newP.inStock) {
        // Back in stock notification
        NotificationService.showRestockNotification(newP);
      } else if (oldP.inStock && !newP.inStock) {
        // Out of stock notification
        NotificationService.showOutOfStockNotification(newP);
      }
    }
  }

  Future<void> addCategory(String categoryName) async {
    final clean = categoryName.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'all') return;
    if (!_customCategories.contains(clean)) {
      _customCategories.add(clean);
      await StorageService.saveCustomCategories(_customCategories);
      notifyListeners();
    }
  }

  Future<void> removeCategory(String categoryName) async {
    _customCategories.remove(categoryName.trim());
    await StorageService.saveCustomCategories(_customCategories);
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- Admin Catalogue Mutations ---
  Future<void> addProduct({
    String? id,
    required String name,
    required String category,
    required double price,
    required double mrp,
    required String unit,
    String imageUrl = '',
    bool inStock = true,
    String description = '',
  }) async {
    final newProduct = Product(
      id: id ?? const Uuid().v4(),
      name: name.trim(),
      category: category.trim().isEmpty ? 'General' : category.trim(),
      price: price,
      mrp: mrp > 0 ? mrp : price,
      unit: unit.trim().isEmpty ? '1 pc' : unit.trim(),
      imageUrl: imageUrl.trim(),
      inStock: inStock,
      description: description.trim(),
    );

    _products.insert(0, newProduct);
    await StorageService.saveProducts(_products);
    notifyListeners();
    await CloudSyncService.syncProductToCloud(newProduct);
  }

  Future<int> syncAllToCloud() async {
    return await CloudSyncService.pushFullCatalogueToCloud(_products);
  }

  Future<void> updateProduct(Product updated) async {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      await StorageService.saveProducts(_products);
      notifyListeners();
      await CloudSyncService.syncProductToCloud(updated);
    }
  }

  Future<void> toggleStock(String productId) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      final willBeInStock = !current.inStock;
      final updated = current.copyWith(inStock: willBeInStock);
      _products[index] = updated;
      await StorageService.saveProducts(_products);
      notifyListeners();

      await CloudSyncService.syncProductToCloud(updated);
    }
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    await StorageService.saveProducts(_products);
    notifyListeners();
    await CloudSyncService.deleteProductFromCloud(productId);
  }

  Future<void> restoreStandardCatalogue() async {
    _isLoading = true;
    notifyListeners();
    _products = await StorageService.loadStandardKiranaCatalogue();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    CloudSyncService.stopLiveCatalogueListener();
    super.dispose();
  }
}