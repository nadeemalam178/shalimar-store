import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user_model.dart';

class OrderAnalyticsSummary {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final List<LoggedOrder> recentOrders;

  const OrderAnalyticsSummary({
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    this.averageOrderValue = 0.0,
    this.recentOrders = const [],
  });
}

class LoggedOrder {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double totalAmount;
  final int itemCount;
  final DateTime timestamp;
  final List<String> itemNames;

  const LoggedOrder({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.totalAmount,
    required this.itemCount,
    required this.timestamp,
    required this.itemNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'totalAmount': totalAmount,
      'itemCount': itemCount,
      'timestamp': timestamp.toIso8601String(),
      'itemNames': itemNames,
    };
  }

  factory LoggedOrder.fromJson(Map<String, dynamic> json) {
    return LoggedOrder(
      orderId: json['orderId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Customer',
      customerPhone: json['customerPhone'] as String? ?? '',
      customerAddress: json['customerAddress'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      itemNames: (json['itemNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _localOrdersKey = 'shalimar_tracked_orders';

  /// Records a WhatsApp order initiation event in Firestore and local storage
  static Future<void> recordWhatsAppOrder({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double totalAmount,
    required List<CartItem> items,
  }) async {
    final now = DateTime.now();
    final orderId = 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final itemNames = items.map((i) => '${i.product.name} (x${i.quantity})').toList();

    final order = LoggedOrder(
      orderId: orderId,
      customerName: customerName.isNotEmpty ? customerName : 'Shalimar Customer',
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      totalAmount: totalAmount,
      itemCount: items.fold(0, (total, i) => total + i.quantity),
      timestamp: now,
      itemNames: itemNames,
    );

    // 1. Cache locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(_localOrdersKey) ?? [];
      currentList.insert(0, jsonEncode(order.toJson()));
      // Keep last 100 orders locally
      if (currentList.length > 100) {
        currentList.removeRange(100, currentList.length);
      }
      await prefs.setStringList(_localOrdersKey, currentList);
    } catch (e) {
      debugPrint('⚠️ [AnalyticsService] Local order cache error: $e');
    }

    // 2. Sync to Firestore orders collection (best effort, non-blocking)
    try {
      await _firestore.collection('orders').doc(orderId).set({
        ...order.toJson(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('📊 [AnalyticsService] Recorded WhatsApp order $orderId in Firestore');
    } catch (e) {
      debugPrint('ℹ️ [AnalyticsService] Firestore order sync error: $e');
    }
  }

  /// Fetches registered customers from Firestore
  static Future<List<UserModel>> fetchRegisteredCustomers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [AnalyticsService] Failed to fetch customers from Firestore: $e');
      return [];
    }
  }

  /// Fetches aggregated WhatsApp order analytics
  static Future<OrderAnalyticsSummary> fetchOrderAnalytics() async {
    List<LoggedOrder> orders = [];

    // 1. Try Firestore first
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 6));

      if (snapshot.docs.isNotEmpty) {
        orders = snapshot.docs.map((d) => LoggedOrder.fromJson(d.data())).toList();
      }
    } catch (_) {}

    // 2. Fallback to local cache if Firestore is empty or offline
    if (orders.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawList = prefs.getStringList(_localOrdersKey) ?? [];
        orders = rawList
            .map((r) => LoggedOrder.fromJson(jsonDecode(r) as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(0.0, (total, o) => total + o.totalAmount);
    final aov = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return OrderAnalyticsSummary(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      averageOrderValue: aov,
      recentOrders: orders,
    );
  }

  /// Computes catalogue inventory metrics
  static Map<String, dynamic> calculateInventoryMetrics(List<Product> products) {
    final totalItems = products.length;
    final inStock = products.where((p) => p.inStock).length;
    final outOfStock = totalItems - inStock;
    final totalValuation = products.fold<double>(0.0, (total, p) => total + (p.price * (p.inStock ? 10 : 0)));

    final Map<String, int> categoryCounts = {};
    for (final p in products) {
      categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
    }

    return {
      'totalProducts': totalItems,
      'inStock': inStock,
      'outOfStock': outOfStock,
      'totalValuation': totalValuation,
      'categoryCounts': categoryCounts,
    };
  }
}

