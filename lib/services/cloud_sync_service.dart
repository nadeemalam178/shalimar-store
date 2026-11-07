import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'firebase_config.dart';
import 'image_upload_service.dart';

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

  static void startLiveCatalogueListener({required Function(List<Product> products) onCatalogueUpdated}) {
    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('ℹ️ [CloudSync] Firestore not initialized, offline local catalogue in use.');
      return;
    }

    bool hasSeenNonEmpty = false;

    try {
      _streamSub?.cancel();
      _streamSub = firestore.collection(_collectionPath).snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) hasSeenNonEmpty = true;
        if (snapshot.docs.isEmpty && !hasSeenNonEmpty) {
          debugPrint('ℹ️ [CloudSync] Firestore products collection is empty; preserving local catalog.');
          return;
        }

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
        debugPrint('⚡ [CloudSync] Mirrored ${cloudProducts.length} live products from Firestore');
        onCatalogueUpdated(cloudProducts);
      }, onError: (error) {
        debugPrint('⚠️ [CloudSync] Firestore live stream error: $error');
      });
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Failed to start live catalogue stream: $e');
    }
  }

  static void stopLiveCatalogueListener() {
    _streamSub?.cancel();
    _streamSub = null;
  }

  static Future<bool> deleteProductFromCloud(String productId) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      _isSyncing = true;
      await firestore.collection(_collectionPath).doc(productId).delete();
      unawaited(ImageUploadService.deleteProductImages(productId));
      debugPrint('🗑️ [CloudSync] Deleted $productId from Firestore');
      return true;
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Error deleting product $productId: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single product to Firestore. Returns true on success.
  static Future<bool> syncProductToCloud(Product product) async {
    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('⚠️ [CloudSync] Firestore not ready, cannot sync ${product.id}');
      return false;
    }
    try {
      final data = product.toJson();
      await firestore.collection(_collectionPath).doc(product.id).set(data);
      debugPrint('☁️ [CloudSync] Synced ${product.id} (${product.name}) to Firestore');
      return true;
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Failed to sync ${product.id}: $e');
      return false;
    }
  }

  /// Push the entire local catalogue to Firestore. Returns count of successfully synced items.
  static Future<int> pushFullCatalogueToCloud(List<Product> products) async {
    final firestore = _firestore;
    if (firestore == null) return 0;
    int synced = 0;
    try {
      _isSyncing = true;
      for (final product in products) {
        final success = await syncProductToCloud(product);
        if (success) synced++;
      }
      debugPrint('☁️ [CloudSync] Batch push complete: $synced / ${products.length} pushed to cloud');
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Batch push error: $e');
    } finally {
      _isSyncing = false;
    }
    return synced;
  }
}
