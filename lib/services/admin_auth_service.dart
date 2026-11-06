import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AdminAuthService {
  static SharedPreferences? _prefs;
  static bool _isAdminLoggedIn = false;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static bool get isLoggedIn => _isAdminLoggedIn;

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static String getStoredAdminId() {
    return _prefs?.getString(AppConstants.keyAdminId) ?? AppConstants.ownerEmail;
  }

  static String? getStoredPasswordHash() {
    return _prefs?.getString(AppConstants.keyAdminPasswordHash);
  }

  /// Verifies entered ID and Password against stored credentials or owner identity
  static bool authenticate(String enteredId, String enteredPassword) {
    final cleanId = enteredId.trim().toLowerCase();
    final ownerEmail = AppConstants.ownerEmail.toLowerCase();
    final storedId = getStoredAdminId().toLowerCase();

    // Check if matching owner email
    if (cleanId == ownerEmail || cleanId == storedId) {
      final storedHash = getStoredPasswordHash();
      final enteredHash = _hashPassword(enteredPassword);

      if (storedHash != null) {
        if (enteredHash == storedHash) {
          _isAdminLoggedIn = true;
          return true;
        }
      } else {
        // First setup or matched owner default
        _isAdminLoggedIn = true;
        return true;
      }
    }
    return false;
  }

  /// Changes the admin password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final expectedHash = getStoredPasswordHash();
    if (expectedHash != null && _hashPassword(currentPassword) != expectedHash) {
      return false;
    }
    final newHash = _hashPassword(newPassword);
    await _prefs?.setString(AppConstants.keyAdminPasswordHash, newHash);
    return true;
  }

  /// Updates admin login ID
  static Future<void> updateAdminId(String newId) async {
    if (newId.trim().isNotEmpty) {
      await _prefs?.setString(AppConstants.keyAdminId, newId.trim());
    }
  }

  static void logout() {
    _isAdminLoggedIn = false;
  }
}

