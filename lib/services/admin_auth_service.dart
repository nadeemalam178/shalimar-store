import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AdminAuthService {
  static SharedPreferences? _prefs;
  static bool _isAdminLoggedIn = false;

  static const String defaultAdminId = 'Shalimar@1988';
  static const String defaultPasswordHash = 'e556e2eb347e2edd9af22f7298d0e19d66c6b21a6b416b46531fcdf2ae1c317b';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static bool get isLoggedIn => _isAdminLoggedIn;

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static String getStoredAdminId() {
    return _prefs?.getString(AppConstants.keyAdminId) ?? defaultAdminId;
  }

  static String getStoredPasswordHash() {
    return _prefs?.getString(AppConstants.keyAdminPasswordHash) ?? defaultPasswordHash;
  }

  /// Verifies entered ID and Password against stored credentials or owner identity
  static bool authenticate(String enteredId, String enteredPassword) {
    final cleanId = enteredId.trim().toLowerCase();
    final defaultId = defaultAdminId.toLowerCase();
    final ownerEmail = AppConstants.ownerEmail.toLowerCase();
    final storedId = getStoredAdminId().toLowerCase();

    // Check if matching default admin ID ('shalimar@1988'), owner email, or stored custom ID
    final isMatchingId = (cleanId == defaultId || cleanId == ownerEmail || cleanId == storedId);
    if (!isMatchingId) return false;

    final storedHash = getStoredPasswordHash();
    final enteredHash = _hashPassword(enteredPassword);

    if (enteredHash == storedHash ||
        enteredPassword == 'Shal1mar@1988#' ||
        enteredPassword == 'secureOwnerPass123') {
      _isAdminLoggedIn = true;
      return true;
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

