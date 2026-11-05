import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  UserProfile _profile = const UserProfile(username: '');
  bool _hasSeenOnboarding = false;
  List<OrderModel> _pastOrders = [];

  UserProfile get profile => _profile;
  String get username => _profile.username;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  List<OrderModel> get pastOrders => _pastOrders;
  List<String> get favoriteProductIds => _profile.favoriteProductIds;

  Future<void> init() async {
    _hasSeenOnboarding = StorageService.hasSeenOnboarding();
    _profile = StorageService.getUserProfile();
    final savedFavs = StorageService.loadFavorites();
    if (savedFavs.isNotEmpty && _profile.favoriteProductIds.isEmpty) {
      _profile = _profile.copyWith(favoriteProductIds: savedFavs);
    }
    _pastOrders = StorageService.loadOrders();
    notifyListeners();
  }

  Future<void> completeOnboarding(String username, {String phone = '', String address = ''}) async {
    _hasSeenOnboarding = true;
    _profile = _profile.copyWith(
      username: username.trim().isEmpty ? 'Valued Customer' : username.trim(),
      phone: phone.trim(),
      address: address.trim(),
    );
    await StorageService.setHasSeenOnboarding(true);
    await StorageService.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> updateProfile({String? username, String? phone, String? address}) async {
    _profile = _profile.copyWith(
      username: username,
      phone: phone,
      address: address,
    );
    await StorageService.saveUserProfile(_profile);
    notifyListeners();
  }

  bool isFavorite(String productId) {
    return _profile.favoriteProductIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    final updated = List<String>.from(_profile.favoriteProductIds);
    if (updated.contains(productId)) {
      updated.remove(productId);
    } else {
      updated.add(productId);
    }
    _profile = _profile.copyWith(favoriteProductIds: updated);
    await StorageService.saveFavorites(updated);
    await StorageService.saveUserProfile(_profile);
    notifyListeners();
  }

  Future<void> addOrder(OrderModel order) async {
    _pastOrders.insert(0, order);
    await StorageService.saveOrders(_pastOrders);
    notifyListeners();
  }
}
