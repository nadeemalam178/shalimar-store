import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Cart ──
  static List<CartItem> loadCart() {
    return _prefs?.getStringList(AppConstants.keyCart)
        ?.map((e) => CartItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList() ?? [];
  }

  static Future<void> saveCart(List<CartItem> items) async {
    await _prefs?.setStringList(
      AppConstants.keyCart,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // ── Onboarding ──
  static bool hasSeenOnboarding() {
    return _prefs?.getBool(AppConstants.keyHasSeenOnboarding) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs?.setBool(AppConstants.keyHasSeenOnboarding, value);
  }

  // ── User Profile ──
  static Map<String, dynamic> getUserProfile() {
    return _prefs?.getString(AppConstants.keyUsername) == null
        ? {}
        : {
            'username': _prefs?.getString(AppConstants.keyUsername) ?? '',
            'phone': _prefs?.getString(AppConstants.keyStorePhone) ?? '',
            'email': _prefs?.getString(AppConstants.keyStoreUpi) ?? '',
          };
  }

  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _prefs?.setString(AppConstants.keyUsername, profile['username'] ?? '');
    await _prefs?.setString(AppConstants.keyStorePhone, profile['phone'] ?? '');
    await _prefs?.setString(AppConstants.keyStoreUpi, profile['email'] ?? '');
  }

  // ── Favorites ──
  static List<String> loadFavorites() {
    return _prefs?.getStringList(AppConstants.keyFavorites) ?? [];
  }

  static Future<void> saveFavorites(List<String> favorites) async {
    await _prefs?.setStringList(AppConstants.keyFavorites, favorites);
  }

  // ── Past Orders ──
  static List<Map<String, dynamic>> loadOrders() {
    return _prefs?.getStringList(AppConstants.keyPastOrders)
        ?.map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList() ?? [];
  }

  static Future<void> saveOrders(List<Map<String, dynamic>> orders) async {
    await _prefs?.setStringList(
      AppConstants.keyPastOrders,
      orders.map((e) => jsonEncode(e)).toList(),
    );
  }

  // ── Products ──
  static Future<List<Product>> loadProducts() async {
    final raw = _prefs?.getString(AppConstants.keyProducts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        // Corrupted cache — start clean
      }
    }
    return [];
  }

  static Future<void> saveProducts(List<Product> products) async {
    final jsonList = products.map((p) => p.toJson()).toList();
    await _prefs?.setString(AppConstants.keyProducts, jsonEncode(jsonList));
  }

  // ── Custom Categories ──
  static List<String> loadCustomCategories() {
    return _prefs?.getStringList(AppConstants.keyCustomCategories) ?? [];
  }

  static Future<void> saveCustomCategories(List<String> categories) async {
    await _prefs?.setStringList(AppConstants.keyCustomCategories, categories);
  }

  // ── Restock subscriptions ──
  static bool isSubscribedToRestock(String productId) {
    final subscribed = _prefs?.getStringList('restock_subscribed') ?? [];
    return subscribed.contains(productId);
  }

  static Future<void> addRestockSubscription(String productId) async {
    final subscribed = <String>{..._prefs?.getStringList('restock_subscribed') ?? []};
    subscribed.add(productId);
    await _prefs?.setStringList('restock_subscribed', subscribed.toList());
  }

  static Future<void> removeRestockSubscription(String productId) async {
    final subscribed = <String>{..._prefs?.getStringList('restock_subscribed') ?? []};
    subscribed.remove(productId);
    await _prefs?.setStringList('restock_subscribed', subscribed.toList());
  }

  // ── OTA Update version tracking ──
  static String getLastPromptedUpdateVersion() {
    return _prefs?.getString('last_prompted_update_version') ?? '';
  }

  static Future<void> setLastPromptedUpdateVersion(String version) async {
    await _prefs?.setString('last_prompted_update_version', version);
  }

  // ── Standard catalogue ──
  static Future<List<Product>> loadStandardKiranaCatalogue() async {
    return [];
  }
}