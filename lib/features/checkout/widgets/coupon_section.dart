import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/widgets/coupon_bottom_sheet.dart';

import '../../my_coupon/controllers/my_coupon_controller.dart';

class CouponSection extends StatelessWidget {
  final int? storeId;
  final CheckoutController checkoutController;
  final double total;
  final double price;
  final double discount;
  final double addOns;
  final double? deliveryCharge;
  final double variationPrice;
  const CouponSection(
      {super.key,
      this.storeId,
      required this.checkoutController,
      required this.total,
      required this.price,
      required this.discount,
      required this.addOns,
      required this.deliveryCharge,
      required this.variationPrice});

  @override
  Widget build(BuildContext context) {
    double totalPrice = total;
    final bool isDeliveryChargeLoading = deliveryCharge == null;
    return storeId == null
        ? GetBuilder<CouponController>(
            builder: (couponController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('have_promo_code'.tr,
                        style: tajawalBold.copyWith(
                            fontSize: 18, height: 1.6, letterSpacing: 0)),
                    InkWell(
                      onTap: () {
                        if (ResponsiveHelper.isDesktop(context)) {
                          Get.dialog(Dialog(
                              child: CouponBottomSheet(
                                  storeId: Get.find<StoreController>().store!.id, checkoutController: checkoutController)));
                        } else {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (con) => CouponBottomSheet(
                                storeId: Get.find<StoreController>().store!.id, checkoutController: checkoutController),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(children: [
                          Text('coupons'.tr,
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Icon(Icons.add, size: 20, color: Theme.of(context).primaryColor),
                        ]),
                      ),
                    )
                  ]),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  if (isDeliveryChargeLoading)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeExtraSmall),
                      child: Row(
                        children: [
                          Text('delivery_fee'.tr,
                              style: robotoRegular.copyWith(
                                  color: Theme.of(context).hintColor)),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text('calculating'.tr,
                              style: robotoRegular.copyWith(
                                  color: Theme.of(context).hintColor,
                                  fontSize: Dimensions.fontSizeSmall)),
                        ],
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Theme.of(context).primaryColor, width: 1.5),
                    ),
                    padding: const EdgeInsets.only(left: 5),
                    child: Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: TextField(
                            controller: checkoutController.couponController,
                            style: robotoRegular.copyWith(height: ResponsiveHelper.isMobile(context) ? null : 2),
                            decoration: InputDecoration(
                              hintText: 'promo_code_example'.tr,
                              hintStyle: tajawalRegular.copyWith(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor),
                              isDense: true,
                              filled: true,
                              enabled: !couponController.hasAppliedCoupon,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(Get.find<LocalizationController>().isLtr ? 10 : 0),
                                  right: Radius.circular(Get.find<LocalizationController>().isLtr ? 0 : 10),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Image.asset(Images.couponIcon, height: 10, width: 20, color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          if (isDeliveryChargeLoading) {
                            showCustomSnackBar('calculating_delivery_fee'.tr);
                            return;
                          }
                          if (checkoutController.couponController.text.isNotEmpty) {
                            if (!Get.find<CouponController>().hasAppliedCoupon) {
                              if (checkoutController.couponController.text.isNotEmpty && !Get.find<CouponController>().isLoading) {
                                Get.find<CouponController>()
                                    .applyCoupon(
                                        checkoutController.couponController.text,
                                        (price - discount) + addOns + variationPrice,
                                        deliveryCharge ?? 0.0,
                                        Get.find<StoreController>().store!.id)
                                    .then((double? appliedDiscount) {
                                  if (appliedDiscount != null && appliedDiscount > 0) {
                                    showCustomSnackBar(
                                      'coupon_applied_successfully'.tr,
                                      isError: false,
                                    );

                                    if (checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1) {
                                      totalPrice = totalPrice - appliedDiscount;
                                      checkoutController.checkBalanceStatus(totalPrice, appliedDiscount);
                                    }
                                  }
                                });
                              } else if (checkoutController.couponController.text.isEmpty) {
                                showCustomSnackBar('enter_a_coupon_code'.tr);
                              }
                            } else {
                              totalPrice = totalPrice + (couponController.discount ?? 0.0);
                              Get.find<CouponController>().removeCouponData(true);
                              checkoutController.couponController.text = '';
                              if (checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1) {
                                checkoutController.checkBalanceStatus(totalPrice, 0);
                              }
                            }
                          } else {
                            showCustomSnackBar('enter_a_coupon_code'.tr);
                          }
                        },
                        child: Container(
                          height: 45,
                          width: !couponController.hasAppliedCoupon ? 96 : 48,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: !couponController.hasAppliedCoupon
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: !couponController.hasAppliedCoupon
                              ? !couponController.isLoading
                                  ? Text(
                                      'activate'.tr,
                                      style: tajawalBold.copyWith(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.6),
                                    )
                                  : const SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    )
                              : Icon(Icons.clear, color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ]),
              );
            },
          )
        : const SizedBox();
  }
}
