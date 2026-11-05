import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
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
      if (c.trim().isNotEmpty) {
        set.add(c.trim());
      }
    }
    for (final p in _products) {
      if (p.category.trim().isNotEmpty) {
        set.add(p.category.trim());
      }
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
      id: const Uuid().v4(),
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
  }

  Future<void> updateProduct(Product updated) async {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      await StorageService.saveProducts(_products);
      notifyListeners();
    }
  }

  Future<void> toggleStock(String productId) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      _products[index] = current.copyWith(inStock: !current.inStock);
      await StorageService.saveProducts(_products);
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    await StorageService.saveProducts(_products);
    notifyListeners();
  }

  Future<void> restoreStandardCatalogue() async {
    _isLoading = true;
    notifyListeners();
    _products = await StorageService.loadStandardKiranaCatalogue();
    _isLoading = false;
    notifyListeners();
  }
}

