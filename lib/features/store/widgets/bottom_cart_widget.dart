import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';

class BottomCartWidget extends StatelessWidget {
  const BottomCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 FIX: Use cart_count ID to receive updates from _onCartMutated()
    return GetBuilder<CartController>(
      id: 'cart_count',
      builder: (cartController) {
      return Container(
        height: GetPlatform.isIOS ? 100 : 70,
        width: Get.width,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeExtraLarge, /* vertical: Dimensions.PADDING_SIZE_SMALL*/
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${'item'.tr}: ${cartController.cartList.length}',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Row(children: [
              Text(
                '${'total'.tr}: ',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
              ),
              PriceConverter.convertPrice2(
                cartController.subTotal, // 🔥 FIX: Use subTotal getter instead of deprecated calculationCart()
                textStyle: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).primaryColor,
                ),
              )
            ]),
          ]),
          CustomButton(buttonText: 'view_cart'.tr, width: 130, height: 45, onPressed: () => Get.toNamed(RouteHelper.getCartRoute()))
        ]),
      );
    });
  }
}
