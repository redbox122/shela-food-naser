import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/screens/market_product_screen.dart';
// For showProductOptions(): opening the options sheet enforces REQUIRED choices
// on the offers "+" (it falls back to a quick-add for items with no options).
import 'package:sixam_mart/features/home/screens/market_store_screen.dart'
    show showProductOptions;
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_cart_helper.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_models.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Compact product card (≈104×130): image with red "-X%" badge + add button,
/// then name and price (struck original + discounted).
class OfferProductCard extends StatelessWidget {
  final OfferProduct product;
  final int? storeId;
  final int moduleId;
  final Color accent;
  const OfferProductCard({
    super.key,
    required this.product,
    this.storeId,
    this.moduleId = 3,
    this.accent = const Color(0xFF1F7A35),
  });

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    // Outer Stack so the "+" control is a SIBLING on top of the card, not a
    // descendant of the navigation InkWell. A button placed inside the InkWell
    // that overflows the image bounds (bottom: -14) loses hit-testing on the
    // overflowing part, so taps there fall through to the open-product gesture
    // and navigate instead of adding. (Same fix as _ProductCard.)
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          // Without a valid item id the details endpoint would 404; skip the tap.
          onTap: (product.id == null || product.id == 0)
              ? null
              : () => MarketProductScreen.show(
                    itemId: product.id!,
                    storeId: storeId,
                    moduleId: moduleId,
                  ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEFEFF1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Image zoomed inside a fixed-size box (the box/card stays the
                    // same size; the overflow is clipped) so the product reads big.
                    SizedBox(
                      width: double.infinity,
                      height: 85,
                      child: ClipRect(
                        child: Transform.scale(
                          scale: 1.2,
                          child: CustomImage(
                            image: product.image ?? '',
                            width: double.infinity,
                            height: 85,
                            fit: BoxFit.cover,
                            placeholder: Images.placeholder,
                          ),
                        ),
                      ),
                    ),
                    if (product.discountPercent > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFDCDC),
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(6)),
                          ),
                          child: Text(
                            '-${product.discountPercent}%',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              color: Colors.red,
                            ),
                          ),
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
                        // Reserve the left lane so a long (2-line) name wraps
                        // beside the "+" button instead of sliding underneath it.
                        // The text stays right-aligned, so short names are
                        // unaffected.
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text(
                            product.name ?? '',
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              height: 1.3,
                              color: Color(0xFF121C19),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Discounted price + struck original on a single line.
                        Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _price(product.shownPrice, bold: true),
                                if (product.hasDiscount) ...[
                                  const SizedBox(width: 4),
                                  _price(product.price, struck: true),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // "+" / qty stepper straddling the image's bottom-left, on top of the
        // card so its taps add to the cart instead of opening the product.
        Positioned(
          left: 4,
          top: 85 - 24,
          child: OfferAddControl(
            product: product,
            storeId: storeId,
            moduleId: moduleId,
            accent: accent,
          ),
        ),
      ],
    );
  }

  Widget _price(double value, {bool bold = false, bool struck = false}) {
    final color = struck ? const Color(0xFF717885) : const Color(0xFF121C19);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.sar,
            width: struck ? 11 : 14,
            height: struck ? 11 : 14,
            color: color,
            errorBuilder: (_, __, ___) => Text('﷼',
                style: robotoBold.copyWith(
                    fontSize: struck ? 11 : 14, color: color)),
          ),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
              fontSize: struck ? 11 : 14,
              height: 1.2,
              decoration: struck ? TextDecoration.lineThrough : null,
              decorationColor: struck ? Colors.red : color,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Add button on a product card: a green "+" circle that becomes a green
/// "- qty +" stepper once the item is in the cart.
class OfferAddControl extends StatelessWidget {
  final OfferProduct product;
  final int? storeId;
  final int moduleId;
  final Color accent;
  const OfferAddControl({
    super.key,
    required this.product,
    this.storeId,
    this.moduleId = 3,
    this.accent = const Color(0xFF1F7A35),
  });

  @override
  Widget build(BuildContext context) {
    final Color addFill = Color.lerp(accent, Colors.white, 0.82)!;
    return GetBuilder<CartController>(
      builder: (_) {
        final int qty = offerCartQty(product.id);
        if (qty == 0) {
          return Material(
            color: addFill,
            shape: const CircleBorder(),
            child: InkWell(
              // First add opens the options sheet so REQUIRED choices are
              // enforced and selected variations reach the cart/order. Items
              // with no options fall back to a quick-add inside the sheet.
              onTap: () {
                if (product.id == null) return;
                showProductOptions(
                  itemId: product.id!,
                  storeId: storeId,
                  moduleId: moduleId,
                  name: product.name,
                  image: product.image,
                  price: product.shownPrice,
                );
              },
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  Icons.add,
                  size: 24,
                  color: Color(0xff30913F),
                ),
              ),
            ),
          );
        }
        // Lift the stepper up so it sits over the image, not the name text
        // (it is wider/taller than the "+" circle, so the shared low anchor
        // would otherwise cover the title).
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 32,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _step(Icons.remove, () => decOfferFromCart(product)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              _step(
                  Icons.add, () => addOfferToCart(product, storeId, moduleId)),
            ],
          ),
        );
      },
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
