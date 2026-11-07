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
      await AdminAuthService.ensureOwnerFirebaseSession();
      _startSessionMonitoring();
    }
  }

  Future<bool> login(String id, String password) async {
    if (!AdminAuthService.authenticate(id, password)) {
      return false;
    }

    // Single-Admin Enforcement: Prevent simultaneous logins
    final conflict = await AdminSessionService.checkExistingActiveSession();
    if (conflict != null) {
      _sessionConflictMessage = conflict;
      notifyListeners();
      return false;
    }

    _isLoggedIn = true;
    _isAdminMode = true;
    _sessionConflictMessage = null;
    await AdminAuthService.ensureOwnerFirebaseSession();
    final deviceId = await AdminSessionService.getOrCreateDeviceId();
    await AdminSessionService.saveLocalSession(deviceId);
    await AdminSessionService.claimSession();
    _startSessionMonitoring();
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