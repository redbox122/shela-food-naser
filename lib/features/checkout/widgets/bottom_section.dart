import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/prescription_image_picker_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/checkout/widgets/coupon_section.dart';
import 'package:sixam_mart/features/checkout/widgets/note_prescription_section.dart';
import 'package:sixam_mart/features/checkout/widgets/partial_pay_view.dart';

import '../../my_coupon/controllers/my_coupon_controller.dart';

class BottomSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final double total;
  final Module module;
  final double subTotal;
  final double discount;
  final CouponController couponController;
  final bool taxIncluded;
  final double tax;
  final double? deliveryCharge;
  final bool todayClosed;
  final bool tomorrowClosed;
  final double orderAmount;
  final double? maxCodOrderAmount;
  final int? storeId;
  final double? taxPercent;
  final double price;
  final double addOns;
  final Widget? checkoutButton;
  final bool isPrescriptionRequired;
  final double referralDiscount;
  final double variationPrice;

  const BottomSection(
      {super.key,
      required this.checkoutController,
      required this.total,
      required this.module,
      required this.subTotal,
      required this.discount,
      required this.couponController,
      required this.taxIncluded,
      required this.tax,
      required this.deliveryCharge,
      required this.todayClosed,
      required this.tomorrowClosed,
      required this.orderAmount,
      this.maxCodOrderAmount,
      this.storeId,
      this.taxPercent,
      required this.price,
      required this.addOns,
      this.checkoutButton,
      required this.isPrescriptionRequired,
      required this.referralDiscount,
      required this.variationPrice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();
    final bool isDark = theme.brightness == Brightness.dark;
    final bool takeAway = checkoutController.orderType == 'take_away';
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    final bool shouldShowPrescription = isPrescriptionRequired;
    return Container(
      decoration: ResponsiveHelper.isDesktop(context)
          ? BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: isDark
                  ? Border.all(color: const Color(0xFF334155), width: 1)
                  : null,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: (tokens?.outlineSoft ?? theme.dividerColor)
                            .withValues(alpha: 0.35),
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ],
            )
          : null,
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // ✅ Fix: تقليل حجم Column لتجنب overflow
        children: [
          isDesktop
              ? pricingView(context: context, takeAway: takeAway)
              : const SizedBox(),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          /// Coupon
          isDesktop && !isGuestLoggedIn
              ? CouponSection(
                  storeId: storeId,
                  checkoutController: checkoutController,
                  total: total,
                  price: price,
                  discount: discount,
                  addOns: addOns,
                  deliveryCharge: deliveryCharge,
                  variationPrice: variationPrice,
                )
              : const SizedBox(),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Theme.of(context).cardColor,
              border: isDark
                  ? Border.all(color: const Color(0xFF334155), width: 1)
                  : null,
            ),
            padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeDefault,
                horizontal: Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // ✅ Fix: تقليل حجم Column لتجنب overflow
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Note
                NoteAndPrescriptionSection(
                    checkoutController: checkoutController, storeId: storeId),

                isDesktop && !isGuestLoggedIn
                    ? PartialPayView(context,
                        totalPrice: total,
                        isPrescription: shouldShowPrescription)
                    : const SizedBox(),

                /// Ditels — invoice details (تفاصيل الفاتورة)
                !isDesktop
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('invoice_details'.tr,
                              textAlign: TextAlign.right,
                              style: tajawalBold.copyWith(
                                fontSize: 18,
                                height: 1.6,
                                letterSpacing: 0,
                              )),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xffF6F5F8),
                              border: isDark
                                  ? Border.all(
                                      color: const Color(0xFF334155), width: 1)
                                  : null,
                              borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                pricingView(
                                    context: context, takeAway: takeAway),
                                // Final order total row (إجمالي الطلب).
                                GetBuilder<CheckoutController>(
                                  id: 'total',
                                  builder: (controller) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('order_total'.tr,
                                            textAlign: TextAlign.right,
                                            style: tajawalBold.copyWith(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2,
                                                letterSpacing: 0,
                                                color: Theme.of(context)
                                                    .primaryColor)),
                                        PriceConverter.convertPrice2(
                                          controller.viewTotalPrice ?? 0.0,
                                          textStyle: tajawalBold.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              height: 1.2,
                                              letterSpacing: 0,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                /// Image Picker
                PrescriptionImagePickerWidget(
                    checkoutController: checkoutController,
                    storeId: storeId,
                    isPrescriptionRequired: shouldShowPrescription),

                const SizedBox(height: Dimensions.paddingSizeLarge),
                ResponsiveHelper.isDesktop(context)
                    ? GetBuilder<CheckoutController>(
                        id: 'checkout',
                        builder: (controller) {
                          if (!controller.isDeliveryChargeReady) {
                            return const SizedBox();
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('total_amount'.tr,
                                          style: robotoMedium.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                      storeId == null
                                          ? const SizedBox()
                                          : Text(
                                              'Once_your_order_is_confirmed_you_will_receive'
                                                  .tr,
                                              style: robotoRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeOverSmall,
                                                color: Theme.of(context)
                                                    .disabledColor,
                                              ),
                                            ),
                                    ],
                                  ),
                                  storeId == null
                                      ? const SizedBox()
                                      : Text(
                                          'a_notification_with_your_bill_total'
                                              .tr,
                                          style: robotoRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeOverSmall,
                                            color:
                                                Theme.of(context).disabledColor,
                                          ),
                                        ),
                                ],
                              ),
                              GetBuilder<CheckoutController>(
                                id: 'total', // ✅ استخدام ID محدد لتحديث المبلغ الإجمالي فقط - يمنع rebuild loop
                                builder: (controller) {
                                  return PriceConverter.convertAnimationPrice(
                                    controller.viewTotalPrice ?? 0.0,
                                    textStyle: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        color: controller.isPartialPay
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .color
                                            : Theme.of(context).primaryColor),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      )
                    : const SizedBox(),
                ResponsiveHelper.isDesktop(context)
                    ? Padding(
                        padding: const EdgeInsets.only(
                            top: Dimensions.paddingSizeLarge),
                        child: checkoutButton,
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pricingView({required BuildContext context, required bool takeAway}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double effectiveTaxPercent =
        (taxPercent != null && taxPercent! > 0) ? taxPercent! : 15.0;
    final String taxLabel =
        '${'taxes'.tr} (${effectiveTaxPercent.toStringAsFixed(0)}%)';
    // Figma: invoice rows → Tajawal Bold 16 / 160% (mobile only).
    final TextStyle rowStyle = ResponsiveHelper.isDesktop(context)
        ? robotoRegular
        : tajawalBold.copyWith(
            fontSize: 16,
            height: 1.6,
            letterSpacing: 0,
            color: isDark ? Colors.white : const Color(0xFF121C19),
          );
    return Column(
        mainAxisSize:
            MainAxisSize.min, // ✅ Fix: تقليل حجم Column لتجنب overflow
        children: [
          ResponsiveHelper.isDesktop(context)
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeSmall),
                    child: Text('order_summary'.tr,
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge)),
                  ),
                )
              : const SizedBox(),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isDesktop(context)
                    ? Dimensions.paddingSizeLarge
                    : 0),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // ✅ Fix: تقليل حجم Column لتجنب overflow
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('total_products'.tr, style: rowStyle),
                    PriceConverter.convertPrice2(
                      subTotal,
                      textStyle: rowStyle,
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Get.find<SplashController>()
                        .configModel!
                        .additionalChargeStatus!
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text('service_fee'.tr, style: rowStyle),
                            PriceConverter.convertPrice2(
                              Get.find<SplashController>()
                                  .configModel!
                                  .additionCharge,
                              prefixText: '(+) ',
                              textStyle: rowStyle,
                            ),
                          ])
                    : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                // ✅ SIMPLIFIED: Use controller's calculatedDeliveryCharge for reactive UI
                (AuthHelper.isGuestLoggedIn() &&
                        checkoutController.guestAddress == null)
                    ? const SizedBox()
                    : GetBuilder<CheckoutController>(
                        id: 'delivery_charge', // Use specific ID for delivery charge updates
                        builder: (controller) {
                          if (controller.orderType == 'take_away') {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('shipping_fees'.tr, style: rowStyle),
                                PriceConverter.convertPrice2(
                                  0,
                                  textStyle: rowStyle,
                                ),
                              ],
                            );
                          }

                          // Show loader while calculating
                          if (!controller.isDeliveryChargeReady) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('shipping_fees'.tr, style: rowStyle),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            );
                          }

                          final bool isCalculating =
                              controller.distance == null ||
                                  controller.distance == -1;

                          // ✅ Use controller's pre-calculated delivery charge
                          final double charge =
                              controller.calculatedDeliveryCharge;
                          final bool isFree = !isCalculating &&
                              charge == 0 &&
                              controller.orderType != 'take_away';

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('shipping_fees'.tr, style: rowStyle),
                              isCalculating
                                  ? Text(
                                      'calculating'.tr,
                                      style: rowStyle.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                    )
                                  : isFree
                                      ? Text(
                                          'free'.tr,
                                          style: rowStyle.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        )
                                      : charge > 0
                                          ? PriceConverter.convertPrice2(
                                              charge,
                                              prefixText: '(+) ',
                                              textStyle: rowStyle,
                                            )
                                          : Text(
                                              'calculating'.tr,
                                              style: rowStyle.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error),
                                            ),
                            ],
                          );
                        },
                      ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                // Taxes row - show tax information
                tax > 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(taxLabel, style: rowStyle),
                          PriceConverter.convertPrice2(
                            tax,
                            textStyle: rowStyle,
                          ),
                        ],
                      )
                    : const SizedBox(),
                SizedBox(height: tax > 0 ? Dimensions.paddingSizeSmall : 0),
                storeId == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text('discount'.tr, style: rowStyle),
                            PriceConverter.convertPrice2(
                              discount,
                              prefixText: '(-) ',
                              textStyle: rowStyle,
                            ),
                          ])
                    : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                // 🔥 BUG FIX: Null-safe access - discount may be null
                ((couponController.discount ?? 0) > 0 ||
                        couponController.freeDelivery)
                    ? Column(
                        mainAxisSize: MainAxisSize
                            .min, // ✅ Fix: تقليل حجم Column لتجنب overflow
                        children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('coupon_discount'.tr, style: rowStyle),
                                  // 🔥 BUG FIX: Null-safe access - coupon may be null
                                  (couponController.coupon != null &&
                                          couponController.coupon?.couponType ==
                                              'free_delivery')
                                      ? Text(
                                          'free_delivery'.tr,
                                          style: rowStyle.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        )
                                      : PriceConverter.convertPrice2(
                                          couponController.discount,
                                          prefixText: '(-) ',
                                          textStyle: rowStyle,
                                        ),
                                ]),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                          ])
                    : const SizedBox(),
                referralDiscount > 0
                    ? Column(
                        mainAxisSize: MainAxisSize
                            .min, // ✅ Fix: تقليل حجم Column لتجنب overflow
                        children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('referral_discount'.tr,
                                      style: robotoRegular),
                                  PriceConverter.convertPrice2(
                                    referralDiscount,
                                    prefixText: '(-) ',
                                    textStyle: robotoRegular,
                                  ),
                                ]),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                          ])
                    : const SizedBox(),
                (!takeAway &&
                        Get.find<SplashController>()
                                .configModel!
                                .dmTipsStatus ==
                            1)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('delivery_man_tips'.tr, style: robotoRegular),
                          PriceConverter.convertPrice2(
                            checkoutController.tips,
                            prefixText: '(+) ',
                            textStyle: robotoRegular,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                SizedBox(
                    height: !takeAway &&
                            Get.find<SplashController>()
                                    .configModel!
                                    .dmTipsStatus ==
                                1
                        ? Dimensions.paddingSizeSmall
                        : 0.0),
                // 🔥 BUG FIX: Null-safe access - store may be null during initial load
                (checkoutController.store?.extraPackagingStatus == true &&
                        Get.find<CartController>().needExtraPackage)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('extra_packaging'.tr, style: robotoRegular),
                          PriceConverter.convertPrice2(
                            checkoutController.store?.extraPackagingAmount ??
                                0.0,
                            prefixText: '(+) ',
                            textStyle: robotoRegular,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                SizedBox(
                    height: checkoutController.store?.extraPackagingStatus ==
                                true &&
                            Get.find<CartController>().needExtraPackage
                        ? Dimensions.paddingSizeSmall
                        : 0.0),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeSmall),
                  child: Divider(
                      thickness: 1,
                      color:
                          Theme.of(context).hintColor.withValues(alpha: 0.5)),
                ),
                // Removed duplicate subtotal row (already shown above)
                SizedBox(
                    height: checkoutController.isPartialPay
                        ? Dimensions.paddingSizeSmall
                        : 0),
                checkoutController.isPartialPay
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text('paid_by_wallet'.tr, style: robotoRegular),
                            // 🔥 BUG FIX: Null-safe access - userInfoModel and walletBalance may be null
                            PriceConverter.convertPrice2(
                              Get.find<ProfileController>()
                                      .userInfoModel
                                      ?.walletBalance ??
                                  0.0,
                              prefixText: '(-) ',
                              textStyle: robotoRegular,
                            ),
                          ])
                    : const SizedBox(),
                SizedBox(
                    height: checkoutController.isPartialPay
                        ? Dimensions.paddingSizeSmall
                        : 0),
                checkoutController.isPartialPay
                    ? GetBuilder<CheckoutController>(
                        id: 'checkout',
                        builder: (controller) {
                          if (!controller.isDeliveryChargeReady) {
                            return const SizedBox();
                          }
                          return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'due_payment'.tr,
                                  style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      color:
                                          !ResponsiveHelper.isDesktop(context)
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .color
                                              : Theme.of(context).primaryColor),
                                ),
                                GetBuilder<CheckoutController>(
                                  id: 'total', // ✅ استخدام ID محدد لتحديث المبلغ الإجمالي فقط - يمنع rebuild loop
                                  builder: (controller) {
                                    return PriceConverter.convertAnimationPrice(
                                      controller.viewTotalPrice ?? 0.0,
                                      textStyle: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeLarge,
                                          color: !ResponsiveHelper.isDesktop(
                                                  context)
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .color
                                              : Theme.of(context).primaryColor),
                                    );
                                  },
                                )
                              ]);
                        },
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ]);
  }
}
