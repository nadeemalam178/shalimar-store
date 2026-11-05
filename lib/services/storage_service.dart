import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_profile.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Onboarding & Username ---
  static bool hasSeenOnboarding() {
    return _prefs?.getBool(AppConstants.keyHasSeenOnboarding) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs?.setBool(AppConstants.keyHasSeenOnboarding, value);
  }

  static UserProfile getUserProfile() {
    final raw = _prefs?.getString(AppConstants.keyUsername);
    if (raw == null || raw.isEmpty) {
      return const UserProfile(username: '');
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return UserProfile(username: raw);
    }
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    await _prefs?.setString(AppConstants.keyUsername, raw);
  }

  // --- Products Catalogue ---
  static Future<List<Product>> loadProducts() async {
    final raw = _prefs?.getString(AppConstants.keyProducts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        // Fallback to asset catalogue if corrupted
      }
    }
    // First run: Load from bundled standard Kirana store catalogue
    return await loadStandardKiranaCatalogue();
  }

  static Future<List<Product>> loadStandardKiranaCatalogue() async {
    try {
      final jsonString = await rootBundle.loadString(AppConstants.catalogueAssetPath);
      final list = jsonDecode(jsonString) as List<dynamic>;
      final products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      await saveProducts(products);
      return products;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveProducts(List<Product> products) async {
    final raw = jsonEncode(products.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.keyProducts, raw);
  }

  // --- Favorites ---
  static List<String> loadFavorites() {
    return _prefs?.getStringList(AppConstants.keyFavorites) ?? [];
  }

  static Future<void> saveFavorites(List<String> ids) async {
    await _prefs?.setStringList(AppConstants.keyFavorites, ids);
  }

  // --- Past Orders ---
  static List<OrderModel> loadOrders() {
    final raw = _prefs?.getString(AppConstants.keyPastOrders);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveOrders(List<OrderModel> orders) async {
    final raw = jsonEncode(orders.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.keyPastOrders, raw);
  }
}
