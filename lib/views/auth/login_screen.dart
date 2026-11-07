import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/admin_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/admin_auth_service.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_login_overlay.dart';
import '../customer/customer_main_screen.dart';
import '../onboarding/welcome_onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showAdminOverlay = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();

    try {
      if (_isSignUp) {
        // Ensure clean customer session
        await context.read<AdminProvider>().logout();
        final userModel = await AuthService.registerWithEmailPassword(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text,
        );
        userProvider.setCurrentUser(userModel);
      } else {
        // Owner credentials direct login support (Shalimar@1988 or owner email)
        final enteredId = _emailController.text.trim();
        final enteredPass = _passwordController.text;
        if (AdminAuthService.authenticate(enteredId, enteredPass)) {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.login(enteredId, enteredPass);
          // Owner goes directly to Admin Dashboard
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          }
          return;
        }

        // Standard Customer Sign-In (ensure any leftover admin session is cleared)
        await context.read<AdminProvider>().logout();
        final userModel = await AuthService.signInWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        userProvider.setCurrentUser(userModel);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication error. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email. Please create an account.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect password. Please verify and try again.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email. Please sign in.';
      } else if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('Sign in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();

    try {
      // Ensure clean customer session
      await context.read<AdminProvider>().logout();
      final userModel = await AuthService.signInWithGoogle();
      userProvider.setCurrentUser(userModel);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'canceled') {
        _showErrorSnackBar(e.message ?? 'Google Sign-In failed.');
      }
    } on PlatformException catch (e) {
      final errStr = '${e.code} ${e.message} ${e.details}'.toLowerCase();
      if (errStr.contains('10') || errStr.contains('sign_in_failed') || errStr.contains('apiexception')) {
        _showGoogleConfigNoticeDialog();
      } else if (e.code != 'sign_in_canceled') {
        _showErrorSnackBar('Google Sign-In failed: ${e.message ?? e.code}');
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('10') || errStr.contains('sign_in_failed') || errStr.contains('apiexception')) {
        _showGoogleConfigNoticeDialog();
      } else {
        _showErrorSnackBar('Google Sign-In error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGoogleConfigNoticeDialog() {
    const sha1 = '9B:2E:6B:EC:AB:AA:AD:2F:02:8B:81:41:76:EC:D2:C2:BA:EB:5E:F4';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Google Sign-In Setup',
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Sign-In requires registering this app\'s SHA-1 fingerprint in your Firebase Console project settings:',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      sha1,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AppColors.primary,
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: sha1));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SHA-1 fingerprint copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '💡 Instant Alternative: You can create an account or sign in with Email & Password right now without waiting!',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email and we will send you a password reset link.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email Address',
                filled: true,
                fillColor: context.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                _showErrorSnackBar('Please enter a valid email.');
                return;
              }
              Navigator.pop(ctx);
              try {
                await AuthService.sendPasswordResetEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset link sent to $email'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                _showErrorSnackBar('Failed to send reset email: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  // App Logo & Store Branding
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(AppConstants.logoPath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'SHALIMAR STORE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Since 1988 • Trust & Quality',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Card Container (AMOLED Adaptive)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Segment
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.inputFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isSignUp = false),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isSignUp ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: !_isSignUp ? Colors.white : context.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isSignUp = true),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isSignUp ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _isSignUp ? Colors.white : context.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Inputs
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: context.textPrimary),
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'e.g. Md. Nadeem',
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                              filled: true,
                              fillColor: context.inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            validator: (val) {
                              if (_isSignUp && (val == null || val.trim().isEmpty)) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            hintText: 'e.g. yourname@gmail.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                            filled: true,
                            fillColor: context.inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            final clean = val.trim().toLowerCase();
                            if (!_isSignUp && (clean == 'shalimar@1988' || clean == 'shalimar')) {
                              return null;
                            }
                            if (!clean.contains('@') || !clean.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            hintText: 'At least 6 characters',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: context.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: context.inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        if (_isSignUp) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Phone / WhatsApp (Optional)',
                              hintText: 'For WhatsApp delivery updates',
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                              filled: true,
                              fillColor: context.inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],

                        if (!_isSignUp) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 20),

                        // Action Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitEmailAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isSignUp ? 'Create Account & Continue' : 'Sign In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: context.borderSubtle)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider(color: context.borderSubtle)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Continue with Google Button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            height: 18,
                            width: 18,
                            errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                          ),
                          label: Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: context.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: context.surfaceColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Access Links for Owner & App Tour
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _showAdminOverlay = true);
                        },
                        icon: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Store Owner Login',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text('•', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WelcomeOnboardingScreen()),
                          );
                        },
                        icon: Icon(Icons.slideshow_rounded, size: 16, color: context.textSecondary),
                        label: Text(
                          'App Tour (Intro)',
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Alamganj, Ashok Rajpath, Patna - 800007\nZero Gateway Fees • Direct WhatsApp Delivery',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: context.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (_showAdminOverlay)
        AdminLoginOverlay(
          onDismiss: () => setState(() => _showAdminOverlay = false),
          onLoginSuccess: () {
            setState(() => _showAdminOverlay = false);
            // Owner goes directly to Admin Dashboard, not customer screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          },
        ),
    ],
  ),
);
  }
}

