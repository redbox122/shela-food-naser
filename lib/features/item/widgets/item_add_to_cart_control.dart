import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 NEW DESIGN: morphing add-to-cart control for the product details screen.
/// Renders one of three states:
///  • [outOfStock]      → muted pill showing "product_not_available"
///  • not [active]      → a single circular "+" button
///  • [active]          → a green pill counter "- N +"
class ItemAddToCartControl extends StatelessWidget {
  final bool outOfStock;
  final bool active;
  final int quantity;
  final bool isLoading;
  final VoidCallback onActivate;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ItemAddToCartControl({
    super.key,
    required this.outOfStock,
    required this.active,
    required this.quantity,
    required this.isLoading,
    required this.onActivate,
    required this.onIncrement,
    required this.onDecrement,
  });

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    if (outOfStock) {
      // 🎨 NEW DESIGN: 175×40 cream pill, rounded top-right + bottom-left (8),
      // warning icon + bold text.
      const Color bg = Color(0xFFFCF0D9); // hsba(39,14%,99%)
      return Container(
        width: 175,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Images.information_v2,
              height: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'product_not_available'.tr,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tajawalBold.copyWith(
                  fontSize: 14,
                  height: 27 / 14,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: active
          ? Container(
              key: const ValueKey('counter'),
              width: 104,
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(74.55),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PillButton(
                    icon: Icons.remove,
                    onTap: isLoading ? null : onDecrement,
                  ),
                  Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: tajawalBold.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                  _PillButton(
                    icon: Icons.add,
                    onTap: isLoading ? null : onIncrement,
                  ),
                ],
              ),
            )
          : Material(
              key: const ValueKey('add'),
              color: const Color(0xFFD1FDD2), // light green — matches cards
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isLoading ? null : onActivate,
                child: const SizedBox(
                  height: _height,
                  width: _height,
                  child: Icon(Icons.add, color: Color(0xff30913F), size: 24),
                ),
              ),
            ),
    );
  }
}

/// Tappable +/- icon inside the [ItemAddToCartControl] counter pill.
class _PillButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PillButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        height: ItemAddToCartControl._height,
        width: 24,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
