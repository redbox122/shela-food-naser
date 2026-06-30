import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';

/// Floating cart button for module storefronts (restaurants / cafés / pharmacy
/// / shops). A green circular button with a bag icon + item-count badge and a
/// "اضغط لتفاصيل السلة" hint pill. Hidden while the cart is empty; tapping it
/// opens the cart screen.
class ModuleCartFab extends StatelessWidget {
  const ModuleCartFab({super.key});

  static const Color _green = Color(0xFF30913F);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final int count = cartController.cartList.length;
        if (count == 0) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: _green,
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: const Color(0x6630913F),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 26, color: Colors.white),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              height: 1.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 1)),
                ],
              ),
              child: Text(
                'sticky_cart_details_hint'.tr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  height: 1.4,
                  color: Color(0xFF121C19),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
