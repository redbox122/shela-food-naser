import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';

/// Floating action for the offers screen. Two shapes:
/// • Default (category browser): a 128×64 pill with a cart button (live count
///   badge) on the left and a search button on the right.
/// • [showSearch] = false (branded store "see more"): a single 56×56 cart
///   button — search already lives in the branded header, and the design places
///   this button alone on the right.
class CartFab extends StatelessWidget {
  /// Brand accent (the fill); falls back to the market green.
  final Color accent;

  /// Opens the search screen (ignored when [showSearch] is false).
  final VoidCallback onSearch;

  /// Whether to include the search button (and render as the wide pill).
  final bool showSearch;

  const CartFab({
    super.key,
    required this.accent,
    required this.onSearch,
    this.showSearch = true,
  });

  static const double _width = 128;
  static const double _height = 64;

  /// The pill is split into two coloured halves: the cart (bag) side and a
  /// slightly darker search side, matching the design.
  static const Color _cartColor = Color(0xFF30913F);
  static const Color _searchColor = Color(0xFF237D2D);

  @override
  Widget build(BuildContext context) {
    // Cart-only mode: an 88×56 half-pill rounded on the LEFT only, so it sits
    // flush against the screen's right edge (matches the design).
    if (!showSearch) {
      return Material(
        color: accent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(56),
          bottomLeft: Radius.circular(56),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
          child: SizedBox(
            width: 76,
            height: 65,
            child: Center(
              child: GetBuilder<CartController>(
                builder: (cart) => _iconWithBadge(
                  Images.bag_v2_active,
                  Icons.shopping_bag_outlined,
                  cart.cartList.length,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: accent,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(25),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: _width,
        height: _height,
        child: Row(
          // Force LTR so the cart stays on the LEFT and search on the RIGHT
          // regardless of the app's RTL direction (matches the design).
          textDirection: TextDirection.ltr,
          children: [
            // Cart: rebuilds with the live line count for its badge.
            Expanded(
              child: GetBuilder<CartController>(
                builder: (cart) => _action(
                  asset: Images.bag_v2_active,
                  fallback: Icons.shopping_bag_outlined,
                  count: cart.cartList.length,
                  bg: _cartColor,
                  onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
                ),
              ),
            ),
            Expanded(
              child: _action(
                asset: Images.search_v2,
                fallback: Icons.search,
                count: 0,
                bg: _searchColor,
                onTap: onSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required String asset,
    required IconData fallback,
    required int count,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: _iconWithBadge(asset, fallback, count),
        ),
      ),
    );
  }

  /// The icon plus a white count badge when [count] > 0.
  Widget _iconWithBadge(String asset, IconData fallback, int count) {
    final Widget icon = Image.asset(
      asset,
      width: 24,
      height: 24,
      color: Colors.white,
      errorBuilder: (_, __, ___) =>
          Icon(fallback, size: 24, color: Colors.white),
    );
    if (count <= 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          bottom: -6,
          left: -6,
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
