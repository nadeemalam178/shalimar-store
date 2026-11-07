import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../views/customer/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = context.watch<UserProvider>();
    final isFav = user.isFavorite(product.id);
    final quantity = cart.getItemQuantity(product.id);
    final isOutOfStock = !product.inStock;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: isDark
            ? (isOutOfStock ? const Color(0xFF1A1A1A) : const Color(0xFF1E1E1E))
            : (isOutOfStock ? const Color(0xFFF2F2F2) : Colors.white),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOutOfStock
              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
              : (quantity > 0
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200)),
          width: quantity > 0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? (isOutOfStock ? 0.05 : 0.2) : (isOutOfStock ? 0.03 : 0.07)),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Hero animation & constrained cache
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : AppColors.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Hero(
                      tag: 'product_image_${product.id}',
                      child: _buildProductImage(),
                    ),
                  ),
                ),
              ),

              // Product Info & Price
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Unit badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : (isOutOfStock ? Colors.grey.shade200 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.unit,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : (isOutOfStock ? Colors.grey.shade500 : Colors.grey.shade700),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Name
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : (isOutOfStock ? Colors.grey.shade500 : AppColors.darkText),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Price and Add / Quantity Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price & MRP
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.format(product.price),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isOutOfStock ? Colors.grey.shade500 : AppColors.primary,
                                  ),
                                ),
                                if (product.mrp > product.price)
                                  Text(
                                    CurrencyFormatter.format(product.mrp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Action Button
                          if (isOutOfStock)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Unavailable',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            )
                          else if (quantity == 0)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => cart.addItem(product),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '+ ADD',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => cart.decrementItem(product),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.remove, size: 16, color: Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => cart.addItem(product),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.add, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tappable InkWell overlay for opening Detail View
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              ),
            ),
          ),

          // Top Left Discount Badge (Only if in stock)
          if (!isOutOfStock && product.discountPercent > 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${product.discountPercent.toInt()}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

          // Out Of Stock Centered Ribbon
          if (isOutOfStock)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF424242).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top Right Wishlist Heart Button
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFav ? AppColors.primary : Colors.grey.shade400,
                ),
                splashRadius: 18,
                onPressed: () => user.toggleFavorite(product.id),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap with RepaintBoundary for fast scrolling GPU isolation
    return RepaintBoundary(child: cardContent);
  }

  Widget _buildProductImage() {
    if (product.imageUrl.isEmpty) {
      return _buildPlaceholderIcon();
    }

    // Check if it's a local file picked from camera/device with constrained decode size
    final file = File(product.imageUrl);
    if (file.existsSync()) {
      return Image(
        image: ResizeImage(FileImage(file), width: 350, height: 350),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderIcon(),
      );
    }

    // Network image with memory-constrained cacheWidth/Height
    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: 350,
      cacheHeight: 350,
      errorBuilder: (_, _, _) => _buildPlaceholderIcon(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 38,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            'Shalimar Store',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
