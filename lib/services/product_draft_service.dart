import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDraft {
  final String? productId; // null for new product, ID for edit product
  final String name;
  final String category;
  final String price;
  final String mrp;
  final String unit;
  final bool isCustomUnit;
  final String description;
  final bool inStock;
  final String? localImagePath;
  final String? imageUrl;
  final int lastModified;

  const ProductDraft({
    this.productId,
    this.name = '',
    this.category = 'General',
    this.price = '',
    this.mrp = '',
    this.unit = '1 kg',
    this.isCustomUnit = false,
    this.description = '',
    this.inStock = true,
    this.localImagePath,
    this.imageUrl,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'category': category,
        'price': price,
        'mrp': mrp,
        'unit': unit,
        'isCustomUnit': isCustomUnit,
        'description': description,
        'inStock': inStock,
        'localImagePath': localImagePath,
        'imageUrl': imageUrl,
        'lastModified': lastModified,
      };

  factory ProductDraft.fromJson(Map<String, dynamic> json) {
    return ProductDraft(
      productId: json['productId'] as String?,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      price: json['price'] as String? ?? '',
      mrp: json['mrp'] as String? ?? '',
      unit: json['unit'] as String? ?? '1 kg',
      isCustomUnit: json['isCustomUnit'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      inStock: json['inStock'] as bool? ?? true,
      localImagePath: json['localImagePath'] as String?,
      imageUrl: json['imageUrl'] as String?,
      lastModified: json['lastModified'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool get isEmpty {
    return name.trim().isEmpty &&
        price.trim().isEmpty &&
        mrp.trim().isEmpty &&
        description.trim().isEmpty &&
        (localImagePath == null || localImagePath!.isEmpty) &&
        (imageUrl == null || imageUrl!.isEmpty);
  }
}

class ProductDraftService {
  static const String keyNewDraft = 'draft_product_new';
  static String keyEditDraft(String id) => 'draft_product_edit_$id';

  static String getDraftKey({String? productId}) {
    if (productId == null || productId.trim().isEmpty) {
      return keyNewDraft;
    }
    return keyEditDraft(productId.trim());
  }

  static Future<void> saveDraft(ProductDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = getDraftKey(productId: draft.productId);
      await prefs.setString(key, jsonEncode(draft.toJson()));
      debugPrint('💾 [ProductDraftService] Saved draft for key: $key');
    } catch (e) {
      debugPrint('⚠️ [ProductDraftService] Error saving draft: $e');
    }
  }

  static Future<ProductDraft?> loadDraft({String? productId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = getDraftKey(productId: productId);
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ProductDraft.fromJson(map);
    } catch (e) {
      debugPrint('⚠️ [ProductDraftService] Error loading draft: $e');
      return null;
    }
  }

  static Future<void> clearDraft({String? productId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = getDraftKey(productId: productId);
      await prefs.remove(key);
      debugPrint('🧹 [ProductDraftService] Cleared draft for key: $key');
    } catch (e) {
      debugPrint('⚠️ [ProductDraftService] Error clearing draft: $e');
    }
  }

  static Future<bool> hasDraft({String? productId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = getDraftKey(productId: productId);
      final raw = prefs.getString(key);
      return raw != null && raw.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

