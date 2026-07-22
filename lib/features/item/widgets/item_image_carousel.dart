import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/common/utils/product_side_images.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 NEW DESIGN: centered 194×194 product image.
/// With a single image it shows just the image; with multiple images it becomes
/// a swipeable carousel with dot indicators below — the active dot is larger.
class ItemImageCarousel extends StatefulWidget {
  final Item item;
  final VoidCallback? onTap;
  const ItemImageCarousel({super.key, required this.item, this.onTap});

  @override
  State<ItemImageCarousel> createState() => _ItemImageCarouselState();
}

class _ItemImageCarouselState extends State<ItemImageCarousel> {
  static const double _size = 194;
  final PageController _controller = PageController();
  int _index = 0;

  /// Extra CDN photos (side1.jpg, …) recovered client-side — the sync stores
  /// only one image. Appended after the API image(s). See [ProductSideImages].
  List<String> _sideImages = const [];

  List<String> get _images {
    final List<String> list = [];
    final raw = widget.item.imagesFullUrl;
    if (raw != null) {
      list.addAll(raw.where((e) => e.isNotEmpty));
    }
    if (list.isEmpty) {
      final String? single =
          widget.item.imageFullUrl ?? widget.item.displayImage;
      if (single != null && single.isNotEmpty) {
        list.add(single);
      }
    }
    return [...list.map(_hiResImage), ..._sideImages];
  }

  @override
  void initState() {
    super.initState();
    _loadSideImages();
  }

  Future<void> _loadSideImages() async {
    final String? main = widget.item.imageFullUrl ?? widget.item.displayImage;
    if (main == null || main.isEmpty) return;
    final sides = await ProductSideImages.fetch(_hiResImage(main));
    if (mounted && sides.isNotEmpty) setState(() => _sideImages = sides);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Upgrade a todoorstep thumbnail to full resolution: the sync stores
  /// "..._small.jpg" (150×150); dropping "_small" fetches the original
  /// (750–1000px). Client-side, sync-proof; non-matching URLs pass through.
  static String _hiResImage(String url) =>
      url.contains('_small.jpg') ? url.replaceFirst('_small.jpg', '.jpg') : url;

  Widget _image(String url) {
    final String hi = _hiResImage(url);
    return SizedBox(
      width: _size,
      height: _size,
      // CachedNetworkImage with ONLY memCacheWidth (no height) so the decode
      // preserves the real aspect ratio — CustomImage derives BOTH cache
      // dimensions from the square box and squashes the picture. contain keeps
      // the whole product visible, letterboxed, never stretched.
      child: hi.isEmpty
          ? Image.asset(Images.placeholder, fit: BoxFit.contain)
          : CachedNetworkImage(
              imageUrl: hi,
              fit: BoxFit.contain,
              memCacheWidth: 600, // width only → real aspect ratio preserved
              placeholder: (_, __) =>
                  Image.asset(Images.placeholder, fit: BoxFit.contain),
              errorWidget: (_, __, ___) =>
                  Image.asset(Images.placeholder, fit: BoxFit.contain),
            ),
    );
  }

  /// Whole-number discount percentage (original vs current price).
  int get _discountPercent {
    final double original = (widget.item.originalPrice ?? 0).toDouble();
    final double current = (widget.item.price ?? 0).toDouble();
    if (original <= 0 || current >= original) return 0;
    return ((original - current) / original * 100).round();
  }

  Widget _discountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFFFDCDC), // light pink bg
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Text(
        '-$_discountPercent%',
        textAlign: TextAlign.center,
        // Force LTR so the minus stays attached to the number (e.g. "-6%").
        textDirection: TextDirection.ltr,
        style: tajawalBold.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.0,
          letterSpacing: 0,
          color: const Color(0xFFDB2525), // red text
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = _images;
    final bool multiple = images.length > 1;

    final Widget gallery = multiple
        ? SizedBox(
            width: double.infinity,
            height: _size,
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Center(child: _image(images[i])),
            ),
          )
        : Center(child: _image(images.isNotEmpty ? images.first : ''));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            GestureDetector(onTap: widget.onTap, child: gallery),
            // Discount badge at the top-right of the image (when discounted).
            if (_discountPercent > 0)
              Positioned(top: 0, right: 0, child: _discountBadge()),
          ],
        ),
        if (multiple) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (i) {
              final bool active = i == _index;
              // Active: an elongated green pill. Inactive: small muted grey dot.
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active
                      ? Theme.of(context).primaryColor
                      : const Color(0xFFD9D9D9),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
