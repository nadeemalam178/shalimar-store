import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_auth_service.dart';

class StoreSettingsDialog extends StatefulWidget {
  const StoreSettingsDialog({super.key});

  @override
  State<StoreSettingsDialog> createState() => _StoreSettingsDialogState();
}

class _StoreSettingsDialogState extends State<StoreSettingsDialog> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _adminIdCtrl = TextEditingController();
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Do not reveal default confidential credentials in text fields
    final storedId = AdminAuthService.getStoredAdminId();
    if (storedId != AppConstants.defaultAdminId) {
      _adminIdCtrl.text = storedId;
    }
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _adminIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final oldPass = _oldPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter both current and new password';
        _isSuccess = false;
      });
      return;
    }

    if (newPass != confirm) {
      setState(() {
        _statusMessage = 'New passwords do not match';
        _isSuccess = false;
      });
      return;
    }

    final admin = context.read<AdminProvider>();
    final ok = await admin.changePassword(oldPass, newPass);

    if (ok) {
      setState(() {
        _statusMessage = 'Password updated successfully!';
        _isSuccess = true;
      });
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    } else {
      setState(() {
        _statusMessage = 'Current password is incorrect';
        _isSuccess = false;
      });
    }
  }

  Future<void> _saveAdminId() async {
    final newId = _adminIdCtrl.text.trim();
    if (newId.isNotEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      await context.read<AdminProvider>().updateAdminId(newId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Admin ID updated!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.surfaceColor,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderSubtle),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Store & Admin Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 16, color: context.borderSubtle),

              // Store contact summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF262626) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Owner Phone / WhatsApp: ', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                        Text(AppConstants.ownerPhone, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 16, color: Color(0xFFC68400)),
                        const SizedBox(width: 8),
                        Text('Official Store UPI: ', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                        Text(AppConstants.ownerUpiId, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Admin ID Setting
              const Text('Admin Login ID', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adminIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Admin Login ID',
                        hintText: 'Enter new Admin ID',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveAdminId,
                    child: const Text('Update'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Change Password
              const Text('Change Owner Password', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updatePassword,
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
