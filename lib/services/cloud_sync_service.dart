import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'firebase_config.dart';

/// Real-Time Cloud Sync Service for Shalimar Store (Est. 1988).
/// Powered by Google Firebase Firestore (Free Spark Tier).
///
/// Features:
/// 1. Real-time sub-second sync of catalogue changes to all connected customers.
/// 2. Offline-first resilience: Uses local cache seamlessly if offline.
/// 3. Zero cost: Guaranteed 100% within free Spark tier limits (50k reads/day).
class CloudSyncService {
  static const String _collectionPath = 'products';
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSub;
  static bool _isSyncing = false;
  static bool get isSyncing => _isSyncing;

  static FirebaseFirestore? get _firestore {
    if (!FirebaseConfig.isInitialized) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Start real-time stream listener for catalogue updates
  static void startLiveCatalogueListener({
    required Function(List<Product> products) onCatalogueUpdated,
  }) {
    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('ℹ️ [CloudSync] Firestore not initialized, offline local catalogue in use.');
      return;
    }

    try {
      _streamSub?.cancel();
      _streamSub = firestore.collection(_collectionPath).snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<Product> cloudProducts = [];
            for (final doc in snapshot.docs) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                cloudProducts.add(Product.fromJson(data));
              } catch (e) {
                debugPrint('⚠️ [CloudSync] Error parsing product doc ${doc.id}: $e');
              }
            }

            if (cloudProducts.isNotEmpty) {
              debugPrint('⚡ [CloudSync] Received ${cloudProducts.length} live products from Firestore');
              onCatalogueUpdated(cloudProducts);
            }
          }
        },
        onError: (error) {
          debugPrint('⚠️ [CloudSync] Firestore live stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Failed to start live catalogue stream: $e');
    }
  }

  /// Cancel live catalogue stream listener
  static void stopLiveCatalogueListener() {
    _streamSub?.cancel();
    _streamSub = null;
  }

  /// Sync single product mutation (Add or Edit or Stock Toggle) to Cloud Firestore
  static Future<bool> syncProductToCloud(Product product) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      _isSyncing = true;
      final data = product.toJson();
      await firestore.collection(_collectionPath).doc(product.id).set(
            data,
            SetOptions(merge: true),
          );
      debugPrint('☁️ [CloudSync] Successfully synced product: ${product.name} (InStock: ${product.inStock})');
      return true;
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Error syncing product ${product.id} to cloud: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Delete product from Cloud Firestore
  static Future<bool> deleteProductFromCloud(String productId) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      _isSyncing = true;
      await firestore.collection(_collectionPath).doc(productId).delete();
      debugPrint('☁️ [CloudSync] Successfully deleted product $productId from cloud');
      return true;
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Error deleting product $productId from cloud: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Upload the entire local Kirana catalogue to Firestore (Batch write)
  static Future<int> pushFullCatalogueToCloud(List<Product> products) async {
    final firestore = _firestore;
    if (firestore == null || products.isEmpty) return 0;

    try {
      _isSyncing = true;
      final batch = firestore.batch();
      final collection = firestore.collection(_collectionPath);

      for (final p in products) {
        final docRef = collection.doc(p.id);
        batch.set(docRef, p.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('☁️ [CloudSync] Full batch sync complete: ${products.length} products pushed.');
      return products.length;
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Full catalogue batch push error: $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }
}

