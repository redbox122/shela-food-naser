import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/checkout/widgets/time_slot_bottom_sheet.dart';

class TimeSlotSection extends StatelessWidget {
  final int? storeId;
  final CheckoutController checkoutController;
  final List<CartModel?>? cartList;
  final JustTheController tooltipController2;
  final bool tomorrowClosed;
  final bool todayClosed;
  final Module? module;
  const TimeSlotSection({
    super.key,
    this.storeId,
    required this.checkoutController,
    this.cartList,
    required this.tooltipController2,
    required this.tomorrowClosed,
    required this.todayClosed,
    this.module,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    final store = checkoutController.store;
    final cartItem = cartList != null && cartList!.isNotEmpty ? cartList![0] : null;

    final bool shouldShowTimeSlot = !isGuestLoggedIn &&
        storeId == null &&
        store != null &&
        store.scheduleOrder == true &&
        cartItem != null &&
        cartItem.item != null &&
        cartItem.item!.availableDateStarts == null;

    return Column(children: [
      shouldShowTimeSlot
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeLarge,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('preference_time'.tr, style: robotoMedium),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    JustTheTooltip(
                      backgroundColor: theme.colorScheme.scrim.withValues(alpha: 0.92),
                      controller: tooltipController2,
                      preferredDirection: AxisDirection.right,
                      tailLength: 14,
                      tailBaseWidth: 20,
                      content: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'schedule_time_tool_tip'.tr,
                          style: robotoRegular.copyWith(color: theme.colorScheme.surface),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => tooltipController2.showTooltip(),
                        child: const Icon(Icons.info_outline),
                      ),
                    ),
                  ]),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  InkWell(
                    onTap: () {
                      if (ResponsiveHelper.isDesktop(context)) {
                        showDialog(
                          context: context,
                          builder: (con) => Dialog(
                            child: TimeSlotBottomSheet(
                              tomorrowClosed: tomorrowClosed,
                              todayClosed: todayClosed,
                              module: module,
                            ),
                          ),
                        );
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (con) => TimeSlotBottomSheet(
                            tomorrowClosed: tomorrowClosed,
                            todayClosed: todayClosed,
                            module: module,
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      height: 50,
                      child: Row(
                        children: [
                          const SizedBox(width: Dimensions.paddingSizeLarge),
                          Expanded(
                            child: ((checkoutController.selectedDateSlot == 0 && todayClosed) ||
                                    (checkoutController.selectedDateSlot == 1 && tomorrowClosed))
                                ? Center(
                                    child: Text(
                                      module?.showRestaurantText == true ? 'restaurant_is_closed'.tr : 'store_is_closed'.tr,
                                    ),
                                  )
                                : Text(
                                    checkoutController.preferableTime.isNotEmpty ? checkoutController.preferableTime : 'instance'.tr,
                                  ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 28),
                          Icon(
                            Icons.access_time_filled_outlined,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],
              ),
            )
          : const SizedBox(),
      SizedBox(height: shouldShowTimeSlot ? Dimensions.paddingSizeSmall : 0),
    ]);
  }
}
