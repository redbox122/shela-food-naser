import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeliveryOptionButtonWidget extends StatefulWidget {
  final String value;
  final String title;
  final double? charge;
  final bool? isFree;
  final bool fromWeb;
  final double total;
  final String deliveryChargeForView;
  final double badWeatherCharge;
  final double extraChargeForToolTip;
  const DeliveryOptionButtonWidget(
      {super.key,
      required this.value,
      required this.title,
      required this.charge,
      required this.isFree,
      this.fromWeb = false,
      required this.total,
      required this.deliveryChargeForView,
      required this.badWeatherCharge,
      required this.extraChargeForToolTip});

  @override
  State<DeliveryOptionButtonWidget> createState() =>
      _DeliveryOptionButtonWidgetState();
}

class _DeliveryOptionButtonWidgetState
    extends State<DeliveryOptionButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      id: 'checkout',
      builder: (checkoutController) {
        final bool select = checkoutController.orderType == widget.value;

        return InkWell(
          onTap: () {
            checkoutController.setOrderType(widget.value);
            checkoutController.setInstruction(-1);

            if (checkoutController.orderType == 'take_away') {
              if (checkoutController.isPartialPay) {
                double tips = 0;
                try {
                  tips = double.parse(checkoutController.tipController.text);
                } catch (e) {
                  if (kDebugMode) debugPrint('$e');
                }
                checkoutController.checkBalanceStatus(
                    widget.total, (widget.charge ?? 0) + tips);
              }
            } else {
              if (checkoutController.isPartialPay) {
                checkoutController.changePartialPayment();
              } else {
                checkoutController.setPaymentMethod(-1);
              }
            }
          },
          child: Builder(builder: (context) {
            // 🎨 Ported design (old app): light-green filled card (#EBFEEB) with a
            // green custom radio when selected; light-grey card otherwise. Wiring
            // and the reactive charge label below are unchanged.
            final theme = Theme.of(context);
            final bool isDark = theme.brightness == Brightness.dark;
            final Color primary = theme.primaryColor;
            final Color cardBg = select
                ? const Color(0xFFEBFEEB)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F5F8));
            final Color titleColor = select
                ? const Color(0xFF121C19)
                : (isDark ? Colors.white : const Color(0xFF121C19));
            final Color borderColor = select
                ? primary
                : (isDark
                    ? const Color(0xFF334155)
                    : theme.dividerColor.withValues(alpha: 0.8));
            return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: borderColor, width: select ? 1.4 : 1),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title,
                        textAlign: TextAlign.right,
                        style: tajawalBold.copyWith(
                            fontSize: 16,
                            height: 27 / 16,
                            letterSpacing: 0,
                            color: titleColor)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (select &&
                            (checkoutController.isDeliveryChargeReady ||
                                widget.value != 'delivery')) ...[
                          // ✅ Use controller's calculatedDeliveryCharge for reactive updates
                          checkoutController.distance == null
                              ? Text(
                                  widget.value == 'delivery'
                                      ? '${'charge'.tr}: ${'calculating'.tr}...'
                                      : 'free'.tr,
                                  style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .color),
                                )
                              : Text(
                                  widget.value == 'delivery'
                                      ? '${'charge'.tr}: +${PriceConverter.convertPrice(checkoutController.calculatedDeliveryCharge)}'
                                      : 'free'.tr,
                                  style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .color),
                                ),

                          const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall),

                          widget.deliveryChargeForView !=
                                      PriceConverter.convertPrice(0) &&
                                  widget.value == 'delivery' &&
                                  checkoutController.extraCharge != null &&
                                  (widget.deliveryChargeForView != '0') &&
                                  widget.extraChargeForToolTip > 0
                              ? CustomToolTip(
                                  message:
                                      '${'this_charge_include_extra_vehicle_charge'.tr} ${PriceConverter.convertPrice(widget.extraChargeForToolTip)} ${widget.badWeatherCharge > 0 ? '${'and_bad_weather_charge'.tr} ${PriceConverter.convertPrice(widget.badWeatherCharge)}' : ''}',
                                  child: const Icon(Icons.info,
                                      color: Colors.blue, size: 14),
                                )
                              : const SizedBox(),
                        ] else
                          const SizedBox(),
                      ],
                    ),
                  ],
                ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                // Custom radio at the end (left in RTL): green ring + green dot
                // when selected, light-grey empty ring otherwise.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: select
                        ? Colors.white
                        : (isDark ? const Color(0xFF0F172A) : theme.cardColor),
                    border: Border.all(
                      color: select ? primary : const Color(0xFFC4C9CF),
                      width: select ? 2 : 5,
                    ),
                  ),
                  child: select
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: primary),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            );
          }),
        );
      },
    );
  }
}
