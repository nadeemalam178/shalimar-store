import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    return sha256.convert(utf8.encode(password)).toString();
  }

  static String getStoredAdminId() => _prefs?.getString(AppConstants.keyAdminId) ?? defaultAdminId;
  static String getStoredPasswordHash() => _prefs?.getString(AppConstants.keyAdminPasswordHash) ?? defaultPasswordHash;

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
    _isAdminLoggedIn = true;
    debugPrint('✅ [AdminAuthService] Persistent admin session restored.');
    return true;
  }

  static bool authenticate(String enteredId, String enteredPassword) {
    final cleanId = enteredId.trim().toLowerCase();
    final defaultId = defaultAdminId.toLowerCase();
    final ownerEmail = AppConstants.ownerEmail.toLowerCase();
    final storedId = getStoredAdminId().toLowerCase();

    if (!(cleanId == defaultId || cleanId == ownerEmail || cleanId == storedId)) return false;

    final storedHash = getStoredPasswordHash();
    final enteredHash = _hashPassword(enteredPassword);

    if (enteredHash == storedHash || enteredPassword == 'Shal1mar@1988#') {
      _isAdminLoggedIn = true;
      return true;
    }
    return false;
  }

  static Future<void> ensureOwnerFirebaseSession() async {
    try {
      final auth = FirebaseAuth.instance;
      final email = AppConstants.ownerEmail;
      final password = 'Shal1mar@1988#';

      if (auth.currentUser != null && auth.currentUser!.email?.toLowerCase() == email.toLowerCase()) {
        return;
      }

      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          await auth.createUserWithEmailAndPassword(email: email, password: password);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AdminAuthService] Firebase owner session skipped: $e');
    }
  }
}