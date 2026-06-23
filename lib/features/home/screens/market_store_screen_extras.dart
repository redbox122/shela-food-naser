// ignore_for_file: unused_element_parameter, unused_element
part of 'market_store_screen.dart';

// ─── Shared bits ─────────────────────────────────────────────────────────────

/// White pill overlaid on the cover (delivery / time).
class _CoverPill extends StatelessWidget {
  final String image;
  final String label;
  const _CoverPill({required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // Translucent near-white — hsba(260, 1%, 97%, 0.8).
        color: const Color.fromRGBO(246, 245, 247, 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            image,
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Color(0xFF121C19),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green rating badge with diagonal corners (top-right + bottom-left rounded).
class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF9DFCA3),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.black),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final String image;
  final VoidCallback onTap;
  const _CircleIconButton({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(image, width: 20, height: 20),
        ),
      ),
    );
  }
}

/// Loading placeholder for the store body.
///
/// We deliberately do NOT use Skeletonizer here: the category tiles carry a
/// `back_N.png` background that Skeletonizer can't bone away (the green artwork
/// shows through under the grey bones). Instead we hand-draw a shimmer skeleton
/// from plain grey boxes that mirror the real layout — category grid, filter
/// chips and a product grid — so nothing bleeds through.
class _BodySkeleton extends StatelessWidget {
  const _BodySkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeDefault,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories grid (4 per row, two rows).
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (_, __) => const _SkelCategoryTile(),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            // Filter chips row.
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, __) => const _SkelBox(
                  width: 72,
                  height: 32,
                  radius: 16,
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            // Section title.
            const _SkelBox(width: 140, height: 18, radius: 6),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            // Product grid (3 per row, two rows).
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 104 / 150,
              ),
              itemBuilder: (_, __) => const _SkelProductCard(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single grey rounded box used by the skeleton.
class _SkelBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkelBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Category-tile placeholder: rounded artwork box + label bar.
class _SkelCategoryTile extends StatelessWidget {
  const _SkelCategoryTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const _SkelBox(width: 48, height: 10, radius: 4),
      ],
    );
  }
}

/// Product-card placeholder: image box + two text lines. Kept on a transparent
/// background with gaps so the shimmering boxes read as separate shapes.
class _SkelProductCard extends StatelessWidget {
  const _SkelProductCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _SkelBox(width: double.infinity, height: 10, radius: 4),
        const SizedBox(height: 6),
        const _SkelBox(width: 40, height: 10, radius: 4),
      ],
    );
  }
}

// ─── See-all products grid ────────────────────────────────────────────────────

/// Full grid of a section's products, opened from a rail's "view more" tile.
class _SeeAllProductsScreen extends StatelessWidget {
  final String title;
  final List<_Product> products;
  final int? storeId;
  const _SeeAllProductsScreen(
      {required this.title, required this.products, this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Green header band: back chevron (RTL right) + centered title.
            Container(
              color: const Color(0xFF1F7A35),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Get.back<void>(),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 20, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  // 104×130 design card.
                  childAspectRatio: 104 / 130,
                ),
                itemBuilder: (_, i) =>
                    _GridProductCard(product: products[i], storeId: storeId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact product card (≈104×130) for the see-all grid: image with a red
/// discount badge + add button, then name and price.
class _GridProductCard extends StatelessWidget {
  final _Product product;
  final int? storeId;
  const _GridProductCard({required this.product, this.storeId});

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFEFEFF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image + discount badge (top-right) + add button (bottom-left).
          Stack(
            children: [
              CustomImage(
                image: product.image ?? '',
                width: double.infinity,
                height: 64,
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
              if (product.discountPercent > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: Text(
                      '-${product.discountPercent}%',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 4,
                bottom: 4,
                child: _AddButton(
                  onTap: () => _addProductToCart(product, storeId),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                      height: 1.2,
                      color: Color(0xFF121C19),
                    ),
                  ),
                  const Spacer(),
                  _price(product.shownPrice, bold: true),
                  if (product.hasDiscount)
                    _price(product.originalPrice, struck: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _price(double value, {bool bold = false, bool struck = false}) {
    final color = struck ? const Color(0xFF9AA0A6) : const Color(0xFF121C19);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.sar,
            width: struck ? 9 : 11,
            height: struck ? 9 : 11,
            color: color,
            errorBuilder: (_, __, ___) => Text('﷼',
                style: robotoBold.copyWith(fontSize: 9, color: color)),
          ),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
              fontSize: struck ? 9 : 11,
              decoration: struck ? TextDecoration.lineThrough : null,
              decorationColor: color,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating cart button shown once the cart has items; opens the cart screen.
/// Kept for later reuse — the store screen now uses the app bottom nav bar.
class _StoreCartFab extends StatelessWidget {
  const _StoreCartFab();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(56),
      bottomLeft: Radius.circular(56),
    );
    return GetBuilder<CartController>(
      builder: (cartController) {
        final int count = cartController.cartList.length;
        if (count == 0) return const SizedBox.shrink();
        return Material(
          color: const Color(0xFF30913F),
          elevation: 6,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
            child: SizedBox(
              width: 88,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 26, color: Colors.white),
                  Positioned(
                    top: 8,
                    right: 22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
