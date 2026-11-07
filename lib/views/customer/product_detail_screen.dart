import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/product_description_helper.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/full_screen_image_viewer.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _activeImageIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final user = context.watch<UserProvider>();
    final catalogue = context.watch<CatalogueProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFav = user.isFavorite(product.id);
    final quantity = cart.getItemQuantity(product.id);
    final allImages = product.allImages;

    // Recommendation 1: "More Like This" (Same Category)
    final sameCategoryProducts = catalogue.products
        .where((p) => p.category == product.category && p.id != product.id)
        .toList();

    // Recommendation 2: "More For You" (Cross-Category Essentials)
    final moreForYouProducts = catalogue.products
        .where((p) => p.category != product.category && p.id != product.id)
        .take(10)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          product.category,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border_rounded,
              color: isFav ? Colors.red : (isDark ? Colors.white : AppColors.darkText),
            ),
            tooltip: isFav ? 'Remove from Wishlist' : 'Add to Wishlist',
            onPressed: () => user.toggleFavorite(product.id),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomBar(
        context: context,
        product: product,
        quantity: quantity,
        cart: cart,
        isDark: isDark,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Swipeable Multi-Image Gallery with Hero Animation
            _buildImageGallery(allImages, isDark),

            // 2. Main Product Info Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row (Category & Stock)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.inStock
                              ? AppColors.success.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 13,
                              color: product.inStock ? AppColors.success : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.inStock ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: product.inStock ? AppColors.success : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Pack Unit Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.unit,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Product Title
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.darkText,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Pricing & Savings Banner
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (product.mrp > product.price) ...[
                        Text(
                          CurrencyFormatter.format(product.mrp),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Save ₹${(product.mrp - product.price).toStringAsFixed(0)} (${product.discountPercent.toInt()}% OFF)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const Divider(height: 28),

                  // Trust Badges
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.amber.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF333333) : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFFC68400), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shalimar Store Trust Guarantee',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF7F4E00),
                                ),
                              ),
                              Text(
                                'Fresh daily stock • Direct WhatsApp ordering • Since 1988',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product Description (Smart contextual description based on category and name)
                  const SizedBox(height: 18),
                  const Text(
                    'Product Details',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ProductDescriptionHelper.getSmartDescription(product),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Recommendation Carousel 1: "More Like This" (Same Category)
            if (sameCategoryProducts.isNotEmpty)
              _buildHorizontalRecommendationSection(
                title: 'More Like This',
                subtitle: 'Related items in ${product.category}',
                products: sameCategoryProducts,
                isDark: isDark,
              ),

            // 4. Recommendation Carousel 2: "More For You" (Cross-Category Staples)
            if (moreForYouProducts.isNotEmpty)
              _buildHorizontalRecommendationSection(
                title: 'More For You',
                subtitle: 'Popular grocery essentials from other departments',
                products: moreForYouProducts,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images, bool isDark) {
    if (images.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceVariant.withValues(alpha: 0.6),
        child: const Center(
          child: Icon(Icons.shopping_basket_outlined, size: 72, color: AppColors.primary),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
            itemBuilder: (context, idx) {
              final imgUrl = images[idx];
              final heroTag = idx == 0 ? 'product_image_${widget.product.id}' : 'gallery_image_${widget.product.id}_$idx';
              return InkWell(
                onTap: () {
                  FullScreenImageViewer.open(
                    context,
                    imageUrl: imgUrl,
                    title: widget.product.name,
                    subtitle: '${widget.product.category} • ${widget.product.unit}',
                    price: widget.product.price,
                    heroTag: heroTag,
                  );
                },
                child: Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: Center(
                    child: Hero(
                      tag: heroTag,
                      child: _buildConstrainedImage(imgUrl),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (i) {
              final isSelected = i == _activeImageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildConstrainedImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        cacheWidth: 600,
        cacheHeight: 600,
        errorBuilder: (_, _, _) => const Icon(
          Icons.shopping_basket_outlined,
          size: 64,
          color: AppColors.primary,
        ),
      );
    }
    final file = File(url);
    if (file.existsSync()) {
      return Image(
        image: ResizeImage(FileImage(file), width: 600, height: 600),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.shopping_basket_outlined,
          size: 64,
          color: AppColors.primary,
        ),
      );
    }
    return const Icon(
      Icons.shopping_basket_outlined,
      size: 64,
      color: AppColors.primary,
    );
  }

  Widget _buildHorizontalRecommendationSection({
    required String title,
    required String subtitle,
    required List<Product> products,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final prod = products[idx];
              return _buildMiniProductCard(prod, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniProductCard(Product prod, bool isDark) {
    final cart = context.watch<CartProvider>();
    final qty = cart.getItemQuantity(prod.id);

    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: prod),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : AppColors.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildConstrainedImage(prod.imageUrl),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              prod.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              prod.unit,
              style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(prod.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                if (prod.inStock)
                  InkWell(
                    onTap: () => cart.addItem(prod),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        qty > 0 ? '$qty' : '+',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar({
    required BuildContext context,
    required Product product,
    required int quantity,
    required CartProvider cart,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price Summary
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                Text(
                  CurrencyFormatter.format(product.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Cart Action or Restock Alert
            Expanded(
              child: !product.inStock
                  ? NotificationService.isSubscribed(product.id)
                      ? InkWell(
                          onTap: () async {
                            await NotificationService.unsubscribeFromRestock(product.id);
                            if (context.mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unsubscribed from restock alert.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  '✓ Alert Active (Tap to Cancel)',
                                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      : InkWell(
                          onTap: () async {
                            await NotificationService.subscribeToRestock(product.id);
                            if (context.mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🔔 We\'ll notify you when ${product.name} is back in stock!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_active_outlined, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Notify Me When in Stock',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                  : quantity == 0
                      ? ElevatedButton.icon(
                          onPressed: () => cart.addItem(product),
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                          label: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white),
                                onPressed: () => cart.decrementItem(product),
                              ),
                              Text(
                                '$quantity in Cart (${CurrencyFormatter.format(product.price * quantity)})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: () => cart.addItem(product),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
