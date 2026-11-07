import 'package:flutter/foundation.dart';
import '../services/admin_session_service.dart';
import '../services/admin_auth_service.dart';

class AdminProvider with ChangeNotifier {
  bool _isAdminMode = false;
  bool _isLoggedIn = false;
  String? _sessionConflictMessage;

  bool get isAdminMode => _isAdminMode;
  bool get isLoggedIn => _isLoggedIn;
  String? get sessionConflictMessage => _sessionConflictMessage;

  Future<void> init() async {
    await AdminAuthService.init();
    if (await AdminAuthService.restoreSession()) {
      _isLoggedIn = true;
      _isAdminMode = true;
      _startSessionMonitoring();
    }
  }

  Future<bool> login(String id, String password) async {
    // 1. Authoritative verification through Firebase Auth using entered credentials
    final authResult = await AdminAuthService.loginWithFirebaseCredentials(id, password);
    if (!authResult.isSuccess) {
      _sessionConflictMessage = authResult.errorMessage;
      notifyListeners();
      return false;
    }

    // 2. Single-Admin Enforcement (Online only)
    if (!authResult.isOffline) {
      final conflict = await AdminSessionService.checkExistingActiveSession();
      if (conflict != null) {
        _sessionConflictMessage = conflict;
        notifyListeners();
        return false;
      }
    }

    _isLoggedIn = true;
    _isAdminMode = true;
    _sessionConflictMessage = null;

    final deviceId = await AdminSessionService.getOrCreateDeviceId();
    await AdminSessionService.saveLocalSession(deviceId);

    if (!authResult.isOffline) {
      await AdminSessionService.claimSession();
      _startSessionMonitoring();
    }

    notifyListeners();
    return true;
  }

  void _startSessionMonitoring() {
    AdminSessionService.startHeartbeat();
    AdminSessionService.listenForTakeover(onTakeover: _handleSessionTakenOver);
  }

  void _handleSessionTakenOver() {
    _sessionConflictMessage = 'Your admin session was claimed on another device.';
    _isLoggedIn = false;
    _isAdminMode = false;
    notifyListeners();
  }

  void clearSessionConflictMessage() {
    _sessionConflictMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await AdminSessionService.signOut();
    await AdminAuthService.logout();
    _isLoggedIn = false;
    _isAdminMode = false;
    notifyListeners();
  }

  void exitAdminMode() {
    _isAdminMode = false;
    notifyListeners();
  }

  void enterAdminModeIfAuthorized() {
    if (_isLoggedIn) {
      _isAdminMode = true;
      _startSessionMonitoring();
      notifyListeners();
    }
  }

  Future<bool> changePassword(String currentPass, String newPass) async {
    final success = await AdminAuthService.changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
    );
    notifyListeners();
    return success;
  }

  Future<void> updateAdminId(String newId) async {
    await AdminAuthService.updateAdminId(newId);
    notifyListeners();
  }

  @override
  void dispose() {
    AdminSessionService.stopHeartbeat();
    AdminSessionService.stopTakeoverListener();
    super.dispose();
  }
}