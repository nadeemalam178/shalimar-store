import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Firebase Configuration & Safe Initialization for Shalimar Store.
/// Provides offline-first tolerance so the app runs smoothly with zero crashes
/// regardless of whether network is offline or Firebase is unreachable.
class FirebaseConfig {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Safe initialization wrapper with zero UI thread blocking.
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // 1. Initialize with current platform options (from DefaultFirebaseOptions)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('🚀 [FirebaseConfig] Successfully initialized for project: ${DefaultFirebaseOptions.android.projectId}');
      return true;
    } catch (e) {
      // 2. If options init encounters an issue, attempt default native initialization
      try {
        await Firebase.initializeApp();
        _initialized = true;
        debugPrint('🚀 [FirebaseConfig] Initialized via native google-services');
        return true;
      } catch (nativeErr) {
        debugPrint('ℹ️ [FirebaseConfig] Offline-first fallback: $nativeErr');
        _initialized = false;
        return false;
      }
    }
  }
}

