// ignore_for_file: unnecessary_brace_in_string_interps, use_build_context_synchronously, unused_local_variable, unnecessary_import, non_constant_identifier_names, unrelated_type_equality_checks, unnecessary_string_interpolations

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/checkout/widgets/guest_create_account.dart';
import 'package:sixam_mart/features/checkout/widgets/kaidha_wallet_pay_view.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/features/cart/widgets/delivery_option_button_widget.dart';
import 'package:sixam_mart/features/checkout/widgets/coupon_section.dart';
import 'package:sixam_mart/features/checkout/widgets/delivery_instruction_view.dart';
import 'package:sixam_mart/features/checkout/widgets/delivery_section.dart';
import 'package:sixam_mart/features/checkout/widgets/deliveryman_tips_section.dart';
import 'package:sixam_mart/features/checkout/widgets/partial_pay_view.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_section.dart';
import 'package:sixam_mart/features/checkout/widgets/time_slot_section.dart';
import 'package:sixam_mart/features/checkout/widgets/web_delivery_instruction_view.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/widgets/camera_button_sheet_widget.dart';

class TopSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final double charge;
  final double? deliveryCharge;
  final List<DropdownItem<int>> addressList;
  final bool tomorrowClosed;
  final bool todayClosed;
  final Module? module;
  final bool isPrescriptionRequired;
  final double price;
  final double discount;
  final double addOns;
  final int? storeId;
  final List<AddressModel> address;
  final List<CartModel?>? cartList;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final double total;
  final bool isOfflinePaymentActive;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  final JustTheController tooltipController1;
  final JustTheController tooltipController2;
  final JustTheController dmTipsTooltipController;
  final TextEditingController guestPasswordController;
  final TextEditingController guestConfirmPasswordController;
  final FocusNode guestPasswordNode;
  final FocusNode guestConfirmPasswordNode;
  final double variationPrice;
  final String deliveryChargeForView;
  final double badWeatherCharge;
  final double extraChargeForToolTip;

  const TopSection({
    super.key,
    required this.deliveryCharge,
    required this.charge,
    required this.tomorrowClosed,
    required this.todayClosed,
    required this.price,
    required this.discount,
    required this.addOns,
    required this.addressList,
    required this.checkoutController,
    this.module,
    required this.isPrescriptionRequired,
    this.storeId,
    required this.address,
    required this.cartList,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.total,
    required this.isOfflinePaymentActive,
    required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController,
    required this.guestNumberNode,
    required this.guestEmailController,
    required this.guestEmailNode,
    required this.tooltipController1,
    required this.tooltipController2,
    required this.dmTipsTooltipController,
    required this.guestPasswordController,
    required this.guestConfirmPasswordController,
    required this.guestPasswordNode,
    required this.guestConfirmPasswordNode,
    required this.variationPrice,
    required this.deliveryChargeForView,
    required this.badWeatherCharge,
    required this.extraChargeForToolTip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();

    return GetBuilder<CheckoutController>(
      id: 'checkout', // Partial rebuild using checkout ID.
      builder: (controller) {
        // Use the reactive controller instance to ensure latest computed values.
        final bool takeAway = (controller.orderType == 'take_away');
        final bool hasStoreDetailsName =
            (controller.store?.name ?? '').trim().isNotEmpty;
        final bool hasStoreDetailsAddress =
            (controller.store?.address ?? '').trim().isNotEmpty;
        final int? pickupStoreId = controller.store?.id ??
            (cartList != null && cartList!.isNotEmpty
                ? cartList!.first?.item?.storeId
                : null);
        final bool hasCartFallbackName = cartList != null &&
            cartList!.isNotEmpty &&
            (cartList!.first?.item?.storeName ?? '').trim().isNotEmpty;
        final String pickupDataSource = (hasStoreDetailsName ||
                hasStoreDetailsAddress)
            ? 'checkout_store_details'
            : (hasCartFallbackName ? 'cart_item_fallback' : 'none');
        final String pickupStoreName = hasStoreDetailsName
            ? (controller.store!.name ?? '')
            : (hasCartFallbackName
                ? (cartList!.first?.item?.storeName ?? '')
                : '');
        String pickupStoreAddress = (controller.store?.address ?? '').trim();

        if (pickupStoreAddress.isEmpty && pickupStoreId != null) {
          try {
            final StoreController storeController = Get.find<StoreController>();
            final cachedStores = <dynamic>[
              ...(storeController.popularStoreList ?? const []),
              ...(storeController.latestStoreList ?? const []),
              ...(storeController.featuredStoreList ?? const []),
              ...(storeController.topOfferStoreList ?? const []),
              ...(storeController.visitAgainStoreList ?? const []),
              ...(storeController.allStoreModel?.stores ?? const []),
              ...(storeController.storeModel?.stores ?? const []),
            ];
            final String resolvedStoreId = pickupStoreId.toString();
            int matchedStores = 0;
            for (final s in cachedStores) {
              if (s == null) continue;
              final String sid = (s.id ?? '').toString();
              if (sid == resolvedStoreId) {
                matchedStores++;
                final String candidateAddress = (s.address ?? '').toString().trim();
                if (candidateAddress.isNotEmpty) {
                  pickupStoreAddress = candidateAddress;
                  break;
                }
              }
            }
            if (kDebugMode && takeAway) {
              debugPrint(
                  '📍 [PickupLocationUI] cache-fallback lookup: targetStoreId=$resolvedStoreId, matchedStores=$matchedStores, resolvedAddress="$pickupStoreAddress"');
            }
          } catch (e) { if (kDebugMode) debugPrint('$e'); }
        }

        if (kDebugMode && takeAway) {
          debugPrint('📍 [PickupLocationUI] source=$pickupDataSource');
          debugPrint('   - orderType: ${controller.orderType}');
          debugPrint('   - store.id(resolved): $pickupStoreId');
          debugPrint('   - store.id: ${controller.store?.id}');
          debugPrint('   - store.name(raw): ${controller.store?.name}');
          debugPrint('   - store.address(raw): ${controller.store?.address}');
          debugPrint(
              '   - cart.first.item.storeName(raw): ${cartList != null && cartList!.isNotEmpty ? cartList!.first?.item?.storeName : null}');
          debugPrint('   - pickupStoreName(resolved): $pickupStoreName');
          debugPrint('   - pickupStoreAddress(resolved): $pickupStoreAddress');
        }

        return Container(
          decoration: ResponsiveHelper.isDesktop(context)
              ? BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: (tokens?.outlineSoft ?? theme.dividerColor)
                          .withValues(alpha: 0.35),
                      blurRadius: 5,
                      spreadRadius: 1,
                    )
                  ],
                )
              : null,
          child: Column(
            children: [
              // Prescription section.
              storeId != null && isPrescriptionRequired
                  ? Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                              blurRadius: 10)
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeLarge,
                          vertical: Dimensions.paddingSizeSmall),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text('your_prescription'.tr, style: robotoMedium),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              JustTheTooltip(
                                backgroundColor: theme.colorScheme.scrim.withValues(alpha: 0.92),
                                controller: tooltipController1,
                                preferredDirection: AxisDirection.right,
                                tailLength: 14,
                                tailBaseWidth: 20,
                                content: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('prescription_tool_tip'.tr,
                                      style: robotoRegular.copyWith(color: theme.colorScheme.surface)),
                                ),
                                child: InkWell(
                                  onTap: () => tooltipController1.showTooltip(),
                                  child: const Icon(Icons.info_outline),
                                ),
                              ),
                            ]),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: controller.pickedPrescriptions.length + 1,
                                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                                itemBuilder: (context, index) {
                                  final XFile? file = index == controller.pickedPrescriptions.length ? null : controller.pickedPrescriptions[index];
                                  if (index < 5 && index == controller.pickedPrescriptions.length) {
                                    return InkWell(
                                      onTap: () {
                                        if (ResponsiveHelper.isDesktop(context) || GetPlatform.isIOS) {
                                          controller.pickPrescriptionImage(isRemove: false, isCamera: false);
                                        } else {
                                          Get.bottomSheet<void>(const CameraButtonSheetWidget());
                                        }
                                      },
                                      child: DottedBorder(
                                        color: Theme.of(context).primaryColor,
                                        dashPattern: const [5, 5],
                                        padding: const EdgeInsets.all(0),
                                        borderType: BorderType.RRect,
                                        radius: const Radius.circular(Dimensions.radiusDefault),
                                        child: Container(
                                          height: 98, width: 98,
                                          alignment: Alignment.center,
                                          child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.cloud_upload, color: Theme.of(context).disabledColor, size: 32),
                                                Text('upload_your_prescription'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center),
                                              ]),
                                        ),
                                      ),
                                    );
                                  }
                                  return file != null
                                      ? Container(
                                          margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                                          child: DottedBorder(
                                            color: Theme.of(context).primaryColor,
                                            dashPattern: const [5, 5],
                                            borderType: BorderType.RRect,
                                            radius: const Radius.circular(Dimensions.radiusDefault),
                                            child: Padding(
                                              padding: const EdgeInsets.all(5.0),
                                              child: Stack(children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                                  child: GetPlatform.isWeb
                                                      ? Image.network(file.path, width: 98, height: 98, fit: BoxFit.cover)
                                                      : Image.file(File(file.path), width: 98, height: 98, fit: BoxFit.cover),
                                                ),
                                                Positioned(
                                                  right: 0, top: 0,
                                                  child: InkWell(
                                                    onTap: () => controller.removePrescriptionImage(index),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                      child: Icon(Icons.delete_forever, color: Colors.red),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                            ),
                                          ),
                                        )
                                      : const SizedBox();
                                },
                              ),
                            ),
                          ]),
                    )
                  : const SizedBox(),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Delivery options section.
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('delivery_type'.tr, style: robotoMedium),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    
                    // Use deliveryCharge passed from parent.
                    DeliveryOptionButtonWidget(
                      value: 'delivery',
                      title: 'home_delivery'.tr,
                      charge: deliveryCharge,
                      isFree: controller.store?.freeDelivery ?? false,
                      fromWeb: true,
                      total: total,
                      deliveryChargeForView: controller.isDeliveryChargeReady
                          ? deliveryChargeForView
                          : 'loading'.tr, // Show loading state.
                      badWeatherCharge: badWeatherCharge,
                      extraChargeForToolTip: extraChargeForToolTip,
                    ),

                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    DeliveryOptionButtonWidget(
                      value: 'take_away',
                      title: 'take_away'.tr,
                      charge: 0,
                      isFree: true,
                      fromWeb: true,
                      total: total,
                      deliveryChargeForView: PriceConverter.convertPrice(0),
                      badWeatherCharge: 0,
                      extraChargeForToolTip: 0,
                    ),

                    if (takeAway) ...[
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      // 🎨 Ported (old app): "عنوان المتجر" heading + pin + address
                      // line — same style as the "سيصلك على" block.
                      Text('store_address'.tr,
                          textAlign: TextAlign.right,
                          style: tajawalBold.copyWith(
                            fontSize: 18,
                            height: 1.6,
                            letterSpacing: 0,
                          )),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on,
                              size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pickupStoreAddress.isNotEmpty
                                  ? (pickupStoreName.isNotEmpty
                                      ? '$pickupStoreName، $pickupStoreAddress'
                                      : pickupStoreAddress)
                                  : (pickupStoreName.isNotEmpty
                                      ? pickupStoreName
                                      : 'no_data_found'.tr),
                              textAlign: TextAlign.right,
                              style: tajawalMedium.copyWith(
                                fontSize: 16,
                                height: 1.6,
                                letterSpacing: 0,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // Delivery address section.
              DeliverySection(
                checkoutController: controller,
                address: address,
                addressList: addressList,
                guestNameTextEditingController: guestNameTextEditingController,
                guestNumberTextEditingController: guestNumberTextEditingController,
                guestNumberNode: guestNumberNode,
                guestEmailController: guestEmailController,
                guestEmailNode: guestEmailNode,
              ),

              SizedBox(height: !takeAway ? (isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall) : 0),

              // Delivery instructions.
              !takeAway ? (isDesktop ? const WebDeliveryInstructionView() : const DeliveryInstructionView()) : const SizedBox(),
              
              SizedBox(height: !takeAway ? (isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall) : 0),

              // Guest account creation.
              isGuestLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus!
                  ? GuestCreateAccount(
                      guestPasswordController: guestPasswordController,
                      guestConfirmPasswordController: guestConfirmPasswordController,
                      guestPasswordNode: guestPasswordNode,
                      guestConfirmPasswordNode: guestConfirmPasswordNode,
                    )
                  : const SizedBox(),

              SizedBox(height: isGuestLoggedIn ? Dimensions.paddingSizeSmall : 0),

              // Time slot selection.
              TimeSlotSection(
                storeId: storeId,
                checkoutController: controller,
                cartList: cartList,
                tooltipController2: tooltipController2,
                tomorrowClosed: tomorrowClosed,
                todayClosed: todayClosed,
                module: module,
              ),

              // Coupon section. storeId is passed null so the section always
              // renders (matches old app); coupon apply uses StoreController.
              !isDesktop && !isGuestLoggedIn
                  ? CouponSection(
                      storeId: null,
                      checkoutController: controller,
                      total: total, price: price, discount: discount, addOns: addOns,
                      deliveryCharge: deliveryCharge, // Use value from parent.
                      variationPrice: variationPrice,
                    )
                  : const SizedBox(),

              // Delivery man tips.
              DeliveryManTipsSection(
                takeAway: takeAway,
                tooltipController3: dmTipsTooltipController,
                totalPrice: total,
                onTotalChange: (double price) => total + price,
                storeId: storeId,
              ),

              // Payment section.
              Container(
                decoration: isDesktop ? const BoxDecoration() : BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)
                    ],
                  ),
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: Dimensions.paddingSizeLarge),
                child: Column(children: [
                  PaymentSection(
                    partialPayView: !isDesktop && !isGuestLoggedIn
                        ? PartialPayView(context, totalPrice: total, isPrescription: storeId != null)
                        : const SizedBox(),
                    storeId: storeId,
                    isCashOnDeliveryActive: isCashOnDeliveryActive,
                    isDigitalPaymentActive: isDigitalPaymentActive,
                    isWalletActive: isWalletActive,
                    total: total,
                    isOfflinePaymentActive: isOfflinePaymentActive,
                    Kaidha_Wallat_PayView: !isDesktop && !isGuestLoggedIn ? const Kaidha_Wallet_Pay_BottomSheet() : const SizedBox(),
                  ),
                ]),
              ),

              SizedBox(height: isDesktop ? Dimensions.paddingSizeLarge : 0),
            ],
          ),
        );
      },
    );
  }
}
