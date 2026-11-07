import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reusable Full-Screen Pinch-to-Zoom Image Viewer for Shalimar Store.
/// Supports network URLs, local files, and assets with:
/// - 1x to 5x InteractiveViewer pinch zoom
/// - Double-tap toggle zoom (1.0x <-> 2.5x)
/// - Drag-down or close-button dismiss
/// - Optional bottom caption card showing product title, category, and price
class FullScreenImageViewer extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? assetPath;
  final String? title;
  final String? subtitle;
  final double? price;
  final String? heroTag;

  const FullScreenImageViewer({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.assetPath,
    this.title,
    this.subtitle,
    this.price,
    this.heroTag,
  }) : assert(
          imageUrl != null || imageFile != null || assetPath != null,
          'At least one image source must be provided',
        );

  /// Convenient helper to open the viewer with smooth page transition
  static Future<void> open(
    BuildContext context, {
    String? imageUrl,
    File? imageFile,
    String? assetPath,
    String? title,
    String? subtitle,
    double? price,
    String? heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, _, _) => FullScreenImageViewer(
          imageUrl: imageUrl,
          imageFile: imageFile,
          assetPath: assetPath,
          title: title,
          subtitle: subtitle,
          price: price,
          heroTag: heroTag,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;
  bool _showOverlays = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    if (currentScale > 1.2) {
      // Zoom out to normal
      _zoomAnimation = Matrix4Tween(
        begin: _transformController.value,
        end: Matrix4.identity(),
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
    } else {
      // Zoom into tapped point
      final position = details.localPosition;
      final Matrix4 target = Matrix4.identity()
        ..storage[0] = 2.5
        ..storage[5] = 2.5
        ..storage[12] = -position.dx * 1.5
        ..storage[13] = -position.dy * 1.5;

      _zoomAnimation = Matrix4Tween(
        begin: _transformController.value,
        end: target,
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
    }

    _animController.reset();
    _zoomAnimation!.addListener(() {
      _transformController.value = _zoomAnimation!.value;
    });
    _animController.forward();
  }

  Widget _buildImageWidget() {
    Widget imageContent;

    if (widget.imageFile != null) {
      imageContent = Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
      );
    } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      if (widget.imageUrl!.startsWith('http')) {
        imageContent = Image.network(
          widget.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          },
        );
      } else {
        // Local file path string
        final file = File(widget.imageUrl!);
        if (file.existsSync()) {
          imageContent = Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
          );
        } else {
          imageContent = _buildErrorPlaceholder();
        }
      }
    } else if (widget.assetPath != null) {
      imageContent = Image.asset(
        widget.assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
      );
    } else {
      imageContent = _buildErrorPlaceholder();
    }

    if (widget.heroTag != null && widget.heroTag!.isNotEmpty) {
      return Hero(
        tag: widget.heroTag!,
        child: imageContent,
      );
    }
    return imageContent;
  }

  Widget _buildErrorPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.broken_image_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Image unavailable',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails = (widget.title != null && widget.title!.isNotEmpty) ||
        (widget.subtitle != null && widget.subtitle!.isNotEmpty) ||
        (widget.price != null && widget.price! > 0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Pinch-to-zoom interactive viewer
          GestureDetector(
            onTap: () {
              setState(() {
                _showOverlays = !_showOverlays;
              });
            },
            onDoubleTapDown: _handleDoubleTap,
            child: SizedBox.expand(
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.8,
                  maxScale: 5.0,
                  clipBehavior: Clip.none,
                  child: _buildImageWidget(),
                ),
              ),
            ),
          ),

          // 2. Top bar (AppBar with dismiss button and store branding)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showOverlays ? MediaQuery.of(context).padding.top + 8 : -80,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Store badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Pinch to Zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom caption card (if details available)
          if (hasDetails)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showOverlays
                  ? MediaQuery.of(context).padding.bottom + 16
                  : -120,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null &&
                              widget.title!.isNotEmpty) ...[
                            Text(
                              widget.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (widget.subtitle != null &&
                              widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.price != null && widget.price! > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${widget.price!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
