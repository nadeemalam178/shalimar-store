import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';

/// Centralized Authentication Service for Shalimar Store.
/// Handles Email/Password registration & login, Google Sign-In,
/// session persistence, and Firestore customer profile synchronization.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static bool get isAuthenticated => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register customer with Name, Email and Password
  static Future<UserModel> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String address = '',
  }) async {
    final cleanEmail = email.trim();
    final cleanName = name.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Registration failed. Please try again.',
      );
    }

    // Set display name in Firebase Auth
    await user.updateDisplayName(cleanName);

    final now = DateTime.now();
    final userModel = UserModel(
      uid: user.uid,
      name: cleanName,
      email: cleanEmail,
      phone: phone.trim(),
      address: address.trim(),
      role: 'customer',
      provider: 'password',
      createdAt: now,
      lastLoginAt: now,
    );

    // Save to Firestore users collection
    await _syncUserToFirestore(userModel);

    // Save locally for instant offline cache
    await StorageService.saveUserProfile(UserProfile(
      username: cleanName,
      phone: phone.trim(),
      address: address.trim(),
    ));

    debugPrint('✅ [AuthService] Customer registered: $cleanName ($cleanEmail)');
    return userModel;
  }

  /// Sign In customer with Email and Password
  static Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Sign in failed. Please try again.',
      );
    }

    // Retrieve or construct user model
    final profile = await _fetchOrUpdateProfile(user);
    debugPrint('✅ [AuthService] Customer signed in: ${profile.name} ($cleanEmail)');
    return profile;
  }

  /// Sign In / Register with Google
  static Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'canceled',
          message: 'Google Sign-In was cancelled by user.',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Google sign-in failed. Please try again.',
        );
      }

      final profile = await _fetchOrUpdateProfile(user, defaultProvider: 'google.com');
      debugPrint('✅ [AuthService] Google sign-in successful: ${profile.name}');
      return profile;
    } catch (e) {
      debugPrint('⚠️ [AuthService] Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Send official Firebase Password Reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    await _auth.sendPasswordResetEmail(email: cleanEmail);
    debugPrint('📧 [AuthService] Password reset sent to: $cleanEmail');
  }

  /// Sign Out customer
  static Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
    debugPrint('🚪 [AuthService] User signed out successfully.');
  }

  /// Helper to fetch existing profile from Firestore or initialize new one
  static Future<UserModel> _fetchOrUpdateProfile(User user, {String defaultProvider = 'password'}) async {
    final now = DateTime.now();
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['uid'] = user.uid;
        final existing = UserModel.fromJson(data);
        final updated = existing.copyWith(lastLoginAt: now);
        await docRef.update({'lastLoginAt': now.toIso8601String()});

        // Cache locally
        await StorageService.saveUserProfile(UserProfile(
          username: updated.name,
          phone: updated.phone,
          address: updated.address,
        ));
        return updated;
      }
    } catch (e) {
      debugPrint('ℹ️ [AuthService] Firestore read error, creating or using cached profile: $e');
    }

    // New profile or offline fallback
    final newModel = UserModel(
      uid: user.uid,
      name: user.displayName?.isNotEmpty == true ? user.displayName! : 'Customer',
      email: user.email ?? '',
      provider: defaultProvider,
      createdAt: now,
      lastLoginAt: now,
    );

    await _syncUserToFirestore(newModel);
    await StorageService.saveUserProfile(UserProfile(
      username: newModel.name,
      phone: newModel.phone,
      address: newModel.address,
    ));

    return newModel;
  }

  static Future<void> _syncUserToFirestore(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(
            user.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('⚠️ [AuthService] Firestore user profile sync error: $e');
    }
  }
}

