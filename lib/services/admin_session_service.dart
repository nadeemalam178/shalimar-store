import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import 'firebase_config.dart';

class AdminSessionService {
  static const String _sessionDocPath = 'admin_sessions/active';
  static const Duration sessionTtl = Duration(days: 7);
  static const Duration heartbeatInterval = Duration(seconds: 25);
  static const Duration heartbeatStaleAfter = Duration(seconds: 90);

  static SharedPreferences? _prefs;
  static Timer? _heartbeatTimer;
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _takeoverSub;
  static bool _heartbeatRunning = false;
  static bool _takeoverListening = false;

  static bool get _firestoreReady => FirebaseConfig.isInitialized;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<String> getOrCreateDeviceId() async {
    await _ensurePrefs();
    final existing = _prefs?.getString(AppConstants.keyAdminDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final deviceId = const Uuid().v4();
    await _prefs?.setString(AppConstants.keyAdminDeviceId, deviceId);
    return deviceId;
  }

  static bool hasValidLocalSession() {
    final active = _prefs?.getBool(AppConstants.keyAdminSessionActive) ?? false;
    if (!active) return false;
    final ts = _prefs?.getInt(AppConstants.keyAdminLoginTimestamp);
    if (ts == null) return false;
    final loginAt = DateTime.fromMillisecondsSinceEpoch(ts);
    if (loginAt.isBefore(DateTime.now().subtract(sessionTtl))) {
      return false;
    }
    return true;
  }

  static Future<void> saveLocalSession(String deviceId) async {
    await _ensurePrefs();
    await _prefs?.setBool(AppConstants.keyAdminSessionActive, true);
    await _prefs?.setInt(AppConstants.keyAdminLoginTimestamp, DateTime.now().millisecondsSinceEpoch);
    await _prefs?.setString(AppConstants.keyAdminDeviceId, deviceId);
    debugPrint('✅ [AdminSession] Local session saved');
  }

  static Future<void> clearLocalSession() async {
    await _ensurePrefs();
    await _prefs?.setBool(AppConstants.keyAdminSessionActive, false);
    await _prefs?.remove(AppConstants.keyAdminLoginTimestamp);
  }

  static Future<void> _releaseRemote() async {
    if (!_firestoreReady) return;
    final deviceId = await getOrCreateDeviceId();
    try {
      final doc = await FirebaseFirestore.instance.collection('admin_sessions').doc('active').get();
      if (doc.exists && doc.data()?['deviceId'] == deviceId) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('⚠️ [AdminSession] Release skipped: $e');
    }
  }

  /// Checks if another device currently holds an active admin session.
  /// Returns an error message if an active session exists on another device, or null if clear.
  static Future<String?> checkExistingActiveSession() async {
    if (!_firestoreReady) return null;
    try {
      final myDeviceId = await getOrCreateDeviceId();
      final doc = await FirebaseFirestore.instance.collection('admin_sessions').doc('active').get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      final remoteDeviceId = data['deviceId'] as String?;
      if (remoteDeviceId == null || remoteDeviceId == myDeviceId) {
        return null; // Same device or unoccupied
      }

      final heartbeatTs = data['heartbeat'] as Timestamp?;
      if (heartbeatTs != null) {
        final lastBeat = heartbeatTs.toDate();
        if (DateTime.now().difference(lastBeat) < heartbeatStaleAfter) {
          return 'Another device is currently logged in as Store Owner. Simultaneous admin logins are blocked. Please log out from the other device first.';
        }
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [AdminSession] Session check error: $e');
      return null;
    }
  }

  static Future<bool> claimSession() async {
    final deviceId = await getOrCreateDeviceId();
    if (!_firestoreReady) return true;
    try {
      await FirebaseFirestore.instance.collection('admin_sessions').doc('active').set({
        'deviceId': deviceId,
        'claimedAt': FieldValue.serverTimestamp(),
        'heartbeat': FieldValue.serverTimestamp(),
        'appVersion': AppConstants.appVersion,
      });
      return true;
    } catch (e) {
      debugPrint('⚠️ [AdminSession] Claim failed: $e');
      return true;
    }
  }

  static Future<void> startHeartbeat() async {
    if (_heartbeatRunning || !_firestoreReady) return;
    _heartbeatRunning = true;
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      try {
        final deviceId = await getOrCreateDeviceId();
        final doc = await FirebaseFirestore.instance.collection('admin_sessions').doc('active').get();
        if (doc.exists && doc.data()?['deviceId'] == deviceId) {
          await doc.reference.update({'heartbeat': FieldValue.serverTimestamp()});
        }
      } catch (e) {
        debugPrint('⚠️ [AdminSession] Heartbeat skipped: $e');
      }
    });
  }

  static void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _heartbeatRunning = false;
  }

  static void listenForTakeover({required VoidCallback onTakeover}) {
    if (_takeoverListening || !_firestoreReady) return;
    _takeoverListening = true;
    _takeoverSub = FirebaseFirestore.instance.collection('admin_sessions').doc('active').snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      final remoteDeviceId = snapshot.data()?['deviceId'] as String?;
      if (remoteDeviceId == null) return;
      getOrCreateDeviceId().then((myId) {
        if (remoteDeviceId != myId) {
          stopHeartbeat();
          onTakeover();
        }
      });
    });
  }

  static void stopTakeoverListener() {
    _takeoverSub?.cancel();
    _takeoverSub = null;
    _takeoverListening = false;
  }

  static Future<void> signOut({bool releaseRemote = true}) async {
    stopHeartbeat();
    stopTakeoverListener();
    if (releaseRemote) await _releaseRemote();
    await clearLocalSession();
  }
}