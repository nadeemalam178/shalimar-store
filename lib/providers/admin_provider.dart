import 'package:flutter/foundation.dart';
import '../services/admin_auth_service.dart';

class AdminProvider with ChangeNotifier {
  bool _isAdminMode = false;
  bool _isLoggedIn = false;

  bool get isAdminMode => _isAdminMode;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> init() async {
    await AdminAuthService.init();
    _isLoggedIn = AdminAuthService.isLoggedIn;
    notifyListeners();
  }

  bool login(String id, String password) {
    final success = AdminAuthService.authenticate(id, password);
    if (success) {
      _isLoggedIn = true;
      _isAdminMode = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    AdminAuthService.logout();
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
}
