import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/product.dart';
import 'firebase_config.dart';
import 'storage_service.dart';

/// Push & Local Notification Service for Shalimar Store.
/// Handles:
/// 1. Out-of-Stock restock alert topic subscriptions (`restock_<productId>`).
/// 2. General store broadcast announcements (`store_broadcast`).
/// 3. Offline-safe local heads-up notifications with zero crashing.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _localNotificationsInitialized = false;

  static const String _channelId = 'shalimar_store_alerts';
  static const String _channelName = 'Shalimar Store Notifications';
  static const String _channelDescription = 'Stock alerts, offers, and order confirmations';

  /// Initialize local notification channels and FCM background handlers
  static Future<void> init() async {
    // 1. Initialize local notifications
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('🔔 [NotificationService] Tapped notification payload: ${response.payload}');
        },
      );
      _localNotificationsInitialized = true;
      debugPrint('🔔 [NotificationService] Local notification channels registered.');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Local notifications init warning: $e');
    }

    // 2. Initialize Firebase Messaging if Firebase is available
    if (FirebaseConfig.isInitialized) {
      try {
        final messaging = FirebaseMessaging.instance;

        // Request permission on Android 13+ and iOS
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('🔔 [NotificationService] User granted notification permissions.');
          // Auto-subscribe customer to store-wide broadcasts (deals, timings)
          await messaging.subscribeToTopic('store_broadcast');
        }

        // Foreground push message listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showNotification(
              id: notification.hashCode,
              title: notification.title ?? 'Shalimar Store (Est. 1988)',
              body: notification.body ?? '',
            );
          }
        });
      } catch (e) {
        debugPrint('ℹ️ [NotificationService] FCM setup skipped or offline: $e');
      }
    }
  }

  /// Display a high-priority heads-up local notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_localNotificationsInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to present notification: $e');
    }
  }

  /// Subscribe customer to restock alerts for a specific out-of-stock product
  static Future<bool> subscribeToRestock(String productId) async {
    try {
      // Clean topic name conforming to FCM regex [a-zA-Z0-9-_.~%]+
      final cleanTopic = 'restock_${productId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      if (FirebaseConfig.isInitialized) {
        await FirebaseMessaging.instance.subscribeToTopic(cleanTopic);
      }

      await StorageService.addRestockSubscription(productId);
      debugPrint('🔔 [NotificationService] Subscribed to restock alerts for product: $productId');
      return true;
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Subscribe error: $e');
      // Still persist locally so UI reflects customer intention
      await StorageService.addRestockSubscription(productId);
      return true;
    }
  }

  /// Unsubscribe customer from restock alerts
  static Future<bool> unsubscribeFromRestock(String productId) async {
    try {
      final cleanTopic = 'restock_${productId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      if (FirebaseConfig.isInitialized) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(cleanTopic);
      }

      await StorageService.removeRestockSubscription(productId);
      debugPrint('🔔 [NotificationService] Unsubscribed from restock alerts for product: $productId');
      return true;
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Unsubscribe error: $e');
      await StorageService.removeRestockSubscription(productId);
      return true;
    }
  }

  /// Check whether current customer is subscribed to a product's restock alerts
  static bool isSubscribed(String productId) {
    return StorageService.isSubscribedToRestock(productId);
  }

  /// Notify customer that an item is back in stock
  static Future<void> showRestockNotification(Product product) async {
    await showNotification(
      id: product.id.hashCode,
      title: '🎉 Back in Stock!',
      body: '${product.name} is now available at Shalimar Store (Est. 1988)!',
      payload: 'product_${product.id}',
    );
  }

  /// Notify customer that their WhatsApp order has been dispatched
  static Future<void> showOrderPlacedNotification(String orderId, double amount) async {
    await showNotification(
      id: orderId.hashCode,
      title: '📦 Order Shared via WhatsApp',
      body: 'Order #$orderId (₹${amount.toStringAsFixed(0)}) sent to Shalimar Store owner.',
      payload: 'order_$orderId',
    );
  }
}

