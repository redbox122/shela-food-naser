import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 NEW DESIGN: centered floating cart pill — a bag (add-to-cart / open cart)
/// segment and a search segment in two green shades, divided by a thin rule.
class ItemFloatingCartBar extends StatelessWidget {
  final bool isCampaign;
  final bool isLoading;
  final Future<void> Function() onAddToCart;
  final VoidCallback onSearch;

  const ItemFloatingCartBar({
    super.key,
    required this.isCampaign,
    required this.isLoading,
    required this.onAddToCart,
    required this.onSearch,
  });

  static const double _height = 64;
  // Full pill (radius = height/2) per the design.
  static const double _radius = _height / 2;

  // Cart segment + search segment colors (fixed per the design).
  static const Color green = Color(0xFF30913F); // cart
  static const Color darkGreen = Color(0xFF237D2D); // search

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bag / add-to-cart segment.
            Material(
              color: green,
              child: InkWell(
                onTap: isLoading ? null : () => onAddToCart(),
                child: SizedBox(
                  width: 74,
                  height: _height,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        // Live cart count badge — rebuilds on cart mutations
                        // ('cart_count') so it appears immediately on add.
                        : GetBuilder<CartController>(
                            id: 'cart_count',
                            builder: (cartController) {
                              final int count =
                                  cartController.totalCartQuantity;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Image.asset(Images.active_navbag,
                                      width: 28, height: 28),
                                  if (!isCampaign && count > 0)
                                    Positioned(
                                      top: -6,
                                      right: -10,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                            minWidth: 18, minHeight: 18),
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFF04444)),
                                        alignment: Alignment.center,
                                        child: Text(
                                          count > 99 ? '99+' : '$count',
                                          style: tajawalBold.copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                              height: 1.0),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 30, color: Colors.white24),
            // Search segment (darker green).
            Material(
              color: darkGreen,
              child: InkWell(
                onTap: onSearch,
                child: const SizedBox(
                  width: 53,
                  height: _height,
                  child: Center(
                    child: Icon(Icons.search, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
