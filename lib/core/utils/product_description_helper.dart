import '../../models/product.dart';

/// Generates smart, culturally authentic grocery descriptions for Shalimar Store (Est. 1988)
/// based on product category, brand, and name when manual description is not provided.
class ProductDescriptionHelper {
  /// Comprehensive 1-2 sentence description for ProductDetailScreen
  static String getSmartDescription(Product product) {
    if (product.description.trim().isNotEmpty) {
      return product.description.trim();
    }

    final cat = product.category.toLowerCase();
    final name = product.name.toLowerCase();

    if (cat.contains('atta') || name.contains('atta') || name.contains('flour') || name.contains('maida') || name.contains('suji')) {
      return '100% Shudh Chakki Fresh ${product.name} — high in natural dietary fiber for soft, nutritious rotis every day.';
    } else if (cat.contains('rice') || cat.contains('dal') || name.contains('chawal') || name.contains('dal') || name.contains('rice') || name.contains('rajma') || name.contains('chana')) {
      return 'Premium unpolished grain, naturally rich in protein and authentic aroma from Shalimar Store.';
    } else if (cat.contains('oil') || cat.contains('ghee') || name.contains('tel') || name.contains('oil') || name.contains('ghee') || name.contains('mustard')) {
      return 'Pure, wholesome cooking essential preserving natural nutrients and authentic traditional aroma.';
    } else if (cat.contains('masala') || cat.contains('spices') || name.contains('mirch') || name.contains('haldi') || name.contains('dhaniya') || name.contains('namak') || name.contains('spice')) {
      return 'Aromatic, handpicked whole spices retaining natural essential oils for rich flavor and taste.';
    } else if (cat.contains('snack') || cat.contains('biscuit') || name.contains('biscuit') || name.contains('chips') || name.contains('namkeen') || name.contains('toast')) {
      return 'Crispy, crunchy snack crafted for perfect morning and evening chai time cravings.';
    } else if (cat.contains('tea') || cat.contains('coffee') || name.contains('chai') || name.contains('tea') || name.contains('coffee')) {
      return 'Rich aromatic blend providing strong kadak aroma, revitalizing taste, and authentic warmth.';
    } else if (cat.contains('dairy') || cat.contains('egg') || name.contains('milk') || name.contains('dahi') || name.contains('paneer') || name.contains('butter')) {
      return 'Fresh, wholesome dairy staple packed with natural calcium and essential nutrition for the family.';
    } else if (cat.contains('dry fruit') || name.contains('kaju') || name.contains('badam') || name.contains('kismis') || name.contains('pista') || name.contains('walnut')) {
      return 'Hand-sorted premium dry fruits packed with natural energy, vitamins, and daily vitality.';
    } else if (cat.contains('clean') || cat.contains('household') || name.contains('surf') || name.contains('soap') || name.contains('detergent') || name.contains('harpic') || name.contains('vim')) {
      return 'Tough on stains and grease, keeping your kitchen and home sparkling clean and hygienic.';
    } else if (cat.contains('personal') || name.contains('shampoo') || name.contains('paste') || name.contains('cream') || name.contains('lotion')) {
      return 'Gentle daily personal care essential formulated for refreshed, clean, and healthy everyday living.';
    } else if (cat.contains('drink') || cat.contains('juice') || name.contains('cold drink') || name.contains('frooti') || name.contains('coke')) {
      return 'Refreshing, chilled beverage to beat the heat and uplift your energy instantly.';
    } else if (cat.contains('pooja') || name.contains('agarbatti') || name.contains('dhoop') || name.contains('diya') || name.contains('camphor')) {
      return 'Pure and divine pooja samagri for peaceful, fragrant, and auspicious daily prayers.';
    }

    return 'Genuine, quality-checked daily grocery staple from Shalimar Store (Est. 1988), Alamganj, Patna.';
  }

  /// Short 4-6 word tagline for ProductCard
  static String getShortTagline(Product product) {
    if (product.description.trim().isNotEmpty) {
      final desc = product.description.trim();
      return desc.length > 40 ? '${desc.substring(0, 37)}...' : desc;
    }

    final cat = product.category.toLowerCase();
    final name = product.name.toLowerCase();

    if (cat.contains('atta') || name.contains('atta')) {
      return 'Chakki Fresh Daily Staple';
    } else if (cat.contains('rice') || cat.contains('dal')) {
      return 'Pure & Unpolished Grain';
    } else if (cat.contains('oil') || cat.contains('ghee')) {
      return '100% Pure Cooking Essential';
    } else if (cat.contains('masala') || cat.contains('spice')) {
      return 'Authentic Aromatic Spices';
    } else if (cat.contains('snack') || cat.contains('biscuit')) {
      return 'Crispy Tea-Time Snack';
    } else if (cat.contains('tea') || cat.contains('coffee')) {
      return 'Rich & Kadak Blend';
    } else if (cat.contains('dairy')) {
      return 'Fresh Daily Nutrition';
    } else if (cat.contains('dry fruit')) {
      return 'Premium Energy Booster';
    } else if (cat.contains('clean') || cat.contains('household')) {
      return 'Deep Stain Cleaning';
    } else if (cat.contains('personal')) {
      return 'Gentle Daily Care';
    } else if (cat.contains('drink')) {
      return 'Refreshing & Chilled';
    } else if (cat.contains('pooja')) {
      return 'Pure & Auspicious';
    }

    return 'Trusted Quality Since 1988';
  }
}

