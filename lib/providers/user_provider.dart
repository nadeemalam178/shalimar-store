import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  UserProfile _profile = const UserProfile(username: '');
  UserModel? _currentUserModel;
  bool _hasSeenOnboarding = false;
  List<OrderModel> _pastOrders = [];

  UserProfile get profile => _profile;
  UserModel? get currentUserModel => _currentUserModel;
  String get username => _currentUserModel?.name ?? _profile.username;
  String get email => _currentUserModel?.email ?? '';
  bool get isAuthenticated => AuthService.isAuthenticated;
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
    final firebaseUser = AuthService.currentUser;
    if (firebaseUser != null) {
      _currentUserModel = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName?.isNotEmpty == true
            ? firebaseUser.displayName!
            : (_profile.username.isNotEmpty ? _profile.username : 'Customer'),
        email: firebaseUser.email ?? '',
        phone: _profile.phone,
        address: _profile.address,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  void setCurrentUser(UserModel userModel) {
    _currentUserModel = userModel;
    _profile = _profile.copyWith(
      username: userModel.name,
      phone: userModel.phone.isNotEmpty ? userModel.phone : _profile.phone,
      address: userModel.address.isNotEmpty ? userModel.address : _profile.address,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.signOut();
    _currentUserModel = null;
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

