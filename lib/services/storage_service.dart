import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import 'analytics_service.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    // ── Version Migration: Force Sign Out All Sessions Once on v4.2.0 Update ──
    final hasResetSession = _prefs?.getBool('v4_2_force_signout_fresh') ?? false;
    if (!hasResetSession) {
      await _prefs?.setBool(AppConstants.keyAdminSessionActive, false);
      await _prefs?.remove(AppConstants.keyAdminLoginTimestamp);
      await _prefs?.remove(AppConstants.keyAdminDeviceId);
      await _prefs?.remove(AppConstants.keyUsername);
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      await _prefs?.setBool('v4_2_force_signout_fresh', true);
      debugPrint('🧹 [StorageService] v4.2 Force sign-out applied: Signed out all users for clean update.');
    }

    // ── Clear all previous customer records from Firestore once ──
    final hasClearedCustomers = _prefs?.getBool('v4_2_customers_cleared') ?? false;
    if (!hasClearedCustomers) {
      unawaited(AnalyticsService.clearAllRegisteredCustomers());
      await _prefs?.setBool('v4_2_customers_cleared', true);
    }

    await _prefs?.setString('app_version', AppConstants.appVersion);
  }

  /// Clears only the cached product catalogue and custom categories,
  /// preserving all user data, cart, favorites, and authentication sessions.
  static Future<void> clearCatalogueCache() async {
    await _prefs?.remove(AppConstants.keyProducts);
    await _prefs?.remove(AppConstants.keyCustomCategories);
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
  static UserProfile getUserProfile() {
    final raw = _prefs?.getString(AppConstants.keyUsername);
    if (raw == null) return const UserProfile(username: '');
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs?.setString(AppConstants.keyUsername, jsonEncode(profile.toJson()));
  }

  // ── Favorites ──
  static List<String> loadFavorites() {
    return _prefs?.getStringList(AppConstants.keyFavorites) ?? [];
  }

  static Future<void> saveFavorites(List<String> favorites) async {
    await _prefs?.setStringList(AppConstants.keyFavorites, favorites);
  }

  // ── Past Orders ──
  static List<OrderModel> loadOrders() {
    return _prefs?.getStringList(AppConstants.keyPastOrders)
        ?.map((e) => OrderModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList() ?? [];
  }

  static Future<void> saveOrders(List<OrderModel> orders) async {
    await _prefs?.setStringList(
      AppConstants.keyPastOrders,
      orders.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // ── Products ──
  static Future<List<Product>> loadProducts() async {
    final raw = _prefs?.getString(AppConstants.keyProducts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        if (list.isNotEmpty) {
          return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        // Corrupted cache — fallback to standard
      }
    }
    // Only load standard catalogue if it's the very first time AND no cloud sync has happened yet
    // Otherwise return empty list and let live CloudSync populate actual inventory
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

  // ── Gemini Pro AI Preferences & Settings ──
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyBroadcastFrequency = 'gemini_broadcast_frequency';
  static const String keyLastBroadcastTimestamp = 'gemini_last_broadcast_ts';
  static const String keyLastSeenBroadcastTimestamp = 'customer_last_seen_broadcast_ts';

  static String getGeminiApiKey() {
    return _prefs?.getString(keyGeminiApiKey)?.trim() ?? '';
  }

  static Future<void> setGeminiApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await _prefs?.remove(keyGeminiApiKey);
    } else {
      await _prefs?.setString(keyGeminiApiKey, trimmed);
    }
  }

  static bool isGeminiConfigured() {
    return getGeminiApiKey().isNotEmpty;
  }

  static bool isGeminiFeatureEnabled(String featureKey, {bool defaultValue = true}) {
    return _prefs?.getBool('gemini_feat_$featureKey') ?? defaultValue;
  }

  static Future<void> setGeminiFeatureEnabled(String featureKey, bool enabled) async {
    await _prefs?.setBool('gemini_feat_$featureKey', enabled);
  }

  static String getBroadcastFrequency() {
    return _prefs?.getString(keyBroadcastFrequency) ?? 'Daily Morning (10 AM)';
  }

  static Future<void> setBroadcastFrequency(String freq) async {
    await _prefs?.setString(keyBroadcastFrequency, freq);
  }

  static int getLastBroadcastTimestamp() {
    return _prefs?.getInt(keyLastBroadcastTimestamp) ?? 0;
  }

  static Future<void> setLastBroadcastTimestamp(int ts) async {
    await _prefs?.setInt(keyLastBroadcastTimestamp, ts);
  }

  static int getLastSeenBroadcastTimestamp() {
    return _prefs?.getInt(keyLastSeenBroadcastTimestamp) ?? 0;
  }

  static Future<void> setLastSeenBroadcastTimestamp(int ts) async {
    await _prefs?.setInt(keyLastSeenBroadcastTimestamp, ts);
  }

  // ── Standard catalogue ──
  static Future<List<Product>> loadStandardKiranaCatalogue() async {
    try {
      final jsonString = await rootBundle.loadString(AppConstants.catalogueAssetPath);
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('⚠️ [StorageService] Error loading standard catalogue from assets: $e');
      return [];
    }
  }
}