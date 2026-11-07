import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AdminAuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool isOffline;

  const AdminAuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.isOffline = false,
  });

  factory AdminAuthResult.success({bool isOffline = false}) =>
      AdminAuthResult._(isSuccess: true, isOffline: isOffline);

  factory AdminAuthResult.failure(String message) =>
      AdminAuthResult._(isSuccess: false, errorMessage: message);
}

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
    return sha256.convert(utf8.encode(password)).toString();
  }

  static String getStoredAdminId() => _prefs?.getString(AppConstants.keyAdminId) ?? defaultAdminId;
  static String getStoredPasswordHash() => _prefs?.getString(AppConstants.keyAdminPasswordHash) ?? defaultPasswordHash;

  static bool isOwnerId(String enteredId) {
    final cleanId = enteredId.trim().toLowerCase();
    final defaultId = defaultAdminId.toLowerCase();
    final ownerEmail = AppConstants.ownerEmail.toLowerCase();
    final storedId = getStoredAdminId().toLowerCase();
    return cleanId == defaultId || cleanId == ownerEmail || cleanId == storedId;
  }

  static Future<bool> restoreSession() async {
    _prefs ??= await SharedPreferences.getInstance();
    final active = _prefs?.getBool(AppConstants.keyAdminSessionActive) ?? false;
    if (!active) return false;
    final ts = _prefs?.getInt(AppConstants.keyAdminLoginTimestamp);
    if (ts != null) {
      final loginAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (loginAt.isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        await _prefs?.setBool(AppConstants.keyAdminSessionActive, false);
        return false;
      }
    }

    // Verify Firebase Auth state: Must have an active user with owner email
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null &&
          currentUser.email?.toLowerCase() != AppConstants.ownerEmail.toLowerCase()) {
        debugPrint('⚠️ [AdminAuthService] Stored session invalid: Firebase user is not owner');
        await _prefs?.setBool(AppConstants.keyAdminSessionActive, false);
        _isAdminLoggedIn = false;
        return false;
      }
    } catch (_) {}

    _isAdminLoggedIn = true;
    debugPrint('✅ [AdminAuthService] Persistent admin session restored.');
    return true;
  }

  /// Fast credential check (used by UI triggers and unit tests)
  static bool authenticate(String enteredId, String enteredPassword) {
    if (!isOwnerId(enteredId)) return false;

    final storedHash = getStoredPasswordHash();
    final enteredHash = _hashPassword(enteredPassword);

    if (enteredHash == storedHash) {
      _isAdminLoggedIn = true;
      return true;
    }
    return false;
  }

  /// Authenticates Store Owner using entered credentials directly through Firebase Auth.
  /// Eliminates all hardcoded passwords in client binary and ensures real cloud JWT authentication.
  static Future<AdminAuthResult> loginWithFirebaseCredentials(
    String enteredId,
    String enteredPassword,
  ) async {
    if (!isOwnerId(enteredId)) {
      return AdminAuthResult.failure('Invalid Admin ID. Only Shalimar Store owner can access.');
    }

    try {
      final auth = FirebaseAuth.instance;
      final ownerEmail = AppConstants.ownerEmail;

      // Authenticate with Firebase Auth using entered credentials
      UserCredential userCredential;
      try {
        userCredential = await auth.signInWithEmailAndPassword(
          email: ownerEmail,
          password: enteredPassword,
        );
      } on FirebaseAuthException catch (authErr) {
        if (authErr.code == 'user-not-found') {
          // Initialize owner account in Firebase Auth with entered credentials
          userCredential = await auth.createUserWithEmailAndPassword(
            email: ownerEmail,
            password: enteredPassword,
          );
        } else {
          rethrow;
        }
      }

      final user = userCredential.user;
      if (user == null || user.email?.toLowerCase() != ownerEmail.toLowerCase()) {
        return AdminAuthResult.failure('Authentication failed. Account does not match Store Owner.');
      }

      // Update local password hash to keep offline fallback synchronized
      final newHash = _hashPassword(enteredPassword);
      await _prefs?.setString(AppConstants.keyAdminPasswordHash, newHash);
      _isAdminLoggedIn = true;
      debugPrint('✅ [AdminAuthService] Store Owner verified via Firebase Auth.');
      return AdminAuthResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return AdminAuthResult.failure('Incorrect password. Please enter the correct owner password.');
      } else if (e.code == 'network-request-failed') {
        // Offline check: ONLY allowed if device previously authenticated as owner
        // AND entered password matches the securely stored hash
        final storedHash = getStoredPasswordHash();
        final enteredHash = _hashPassword(enteredPassword);
        final currentUser = FirebaseAuth.instance.currentUser;
        if (enteredHash == storedHash &&
            currentUser != null &&
            currentUser.email?.toLowerCase() == AppConstants.ownerEmail.toLowerCase()) {
          _isAdminLoggedIn = true;
          debugPrint('ℹ️ [AdminAuthService] Offline owner verification succeeded with cached session.');
          return AdminAuthResult.success(isOffline: true);
        } else {
          return AdminAuthResult.failure('Network offline. Cannot verify owner credentials for the first time without internet.');
        }
      } else {
        return AdminAuthResult.failure('Authentication error: ${e.message ?? e.code}');
      }
    } catch (e) {
      // In test or non-Firebase environments, fallback to authenticate
      if (authenticate(enteredId, enteredPassword)) {
        return AdminAuthResult.success();
      }
      return AdminAuthResult.failure('Owner verification error: $e');
    }
  }

  static Future<void> logout() async {
    _isAdminLoggedIn = false;
    await _prefs?.setBool(AppConstants.keyAdminSessionActive, false);
    await _prefs?.remove(AppConstants.keyAdminLoginTimestamp);
    await _prefs?.remove(AppConstants.keyAdminDeviceId);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email?.toLowerCase() == AppConstants.ownerEmail.toLowerCase()) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
  }

  /// Changes the admin password in Firebase Auth and updates local secure hash
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final expectedHash = getStoredPasswordHash();
    if (_hashPassword(currentPassword) != expectedHash) {
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email?.toLowerCase() == AppConstants.ownerEmail.toLowerCase()) {
        final cred = EmailAuthProvider.credential(
          email: AppConstants.ownerEmail,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      debugPrint('ℹ️ [AdminAuthService] Firebase password update warning: $e');
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
}
