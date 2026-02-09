// ignore_for_file: unnecessary_brace_in_string_interps, use_build_context_synchronously, unused_local_variable, unnecessary_import, non_constant_identifier_names, avoid_print, unrelated_type_equality_checks, unnecessary_string_interpolations

import 'dart:io';
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
import 'package:sixam_mart/helper/responsive_helper.dart';
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
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();

    return GetBuilder<CheckoutController>(
      id: 'checkout', // التحديث الجزئي باستخدام ID
      builder: (controller) {
        // نستخدم controller المتاح هنا لضمان الحصول على أحدث البيانات المحسوبة
        final bool takeAway = (controller.orderType == 'take_away');

        return Container(
          decoration: ResponsiveHelper.isDesktop(context)
              ? BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
                  ],
                )
              : null,
          child: Column(
            children: [
              // قسم الروشتة (Prescription)
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
                                backgroundColor: Colors.black87,
                                controller: tooltipController1,
                                preferredDirection: AxisDirection.right,
                                tailLength: 14,
                                tailBaseWidth: 20,
                                content: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('prescription_tool_tip'.tr,
                                      style: robotoRegular.copyWith(color: Colors.white)),
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

              // قسم خيارات التوصيل (Delivery Option)
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
                    
                    // ✅ استخدام deliveryCharge من الـ parameter
                    DeliveryOptionButtonWidget(
                      value: 'delivery',
                      title: 'home_delivery'.tr,
                      charge: deliveryCharge,
                      isFree: controller.store?.freeDelivery ?? false,
                      fromWeb: true,
                      total: total,
                      deliveryChargeForView: controller.isDeliveryChargeReady
                          ? deliveryChargeForView
                          : 'loading'.tr, // إظهار حالة التحميل
                      badWeatherCharge: badWeatherCharge,
                      extraChargeForToolTip: extraChargeForToolTip,
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // قسم عرض موقع التوصيل مع حالة الحساب الجاري
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Text('delivery_location'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                          ]),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          
                          // 💡 تنبيه المستخدم أثناء الحساب
                          if (!controller.isDeliveryChargeReady && !takeAway)
                             Padding(
                               padding: const EdgeInsets.only(bottom: 8.0),
                               child: Text('calculating_delivery_fee'.tr, style: robotoRegular.copyWith(color: Colors.orange, fontSize: Dimensions.fontSizeSmall)),
                             ),

                          if (address.isNotEmpty && controller.addressIndex != null && controller.addressIndex! < address.length)
                            Text(address[controller.addressIndex!].address ?? '', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault))
                          else
                            Text('no_address_selected'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // قسم العنوان (DeliverySection)
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

              // تعليمات التوصيل
              !takeAway ? (isDesktop ? const WebDeliveryInstructionView() : const DeliveryInstructionView()) : const SizedBox(),
              
              SizedBox(height: !takeAway ? (isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall) : 0),

              // إنشاء حساب للضيوف
              isGuestLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus!
                  ? GuestCreateAccount(
                      guestPasswordController: guestPasswordController,
                      guestConfirmPasswordController: guestConfirmPasswordController,
                      guestPasswordNode: guestPasswordNode,
                      guestConfirmPasswordNode: guestConfirmPasswordNode,
                    )
                  : const SizedBox(),

              SizedBox(height: isGuestLoggedIn ? Dimensions.paddingSizeSmall : 0),

              // اختيار الوقت (Time Slot)
              TimeSlotSection(
                storeId: storeId,
                checkoutController: controller,
                cartList: cartList,
                tooltipController2: tooltipController2,
                tomorrowClosed: tomorrowClosed,
                todayClosed: todayClosed,
                module: module,
              ),

              // قسم الكوبون
              !isDesktop && !isGuestLoggedIn
                  ? CouponSection(
                      storeId: storeId,
                      checkoutController: controller,
                      total: total, price: price, discount: discount, addOns: addOns,
                      deliveryCharge: deliveryCharge, // استخدام الـ parameter
                      variationPrice: variationPrice,
                    )
                  : const SizedBox(),

              // بقشيش المندوب
              DeliveryManTipsSection(
                takeAway: takeAway,
                tooltipController3: dmTipsTooltipController,
                totalPrice: total,
                onTotalChange: (double price) => total + price,
                storeId: storeId,
              ),

              // قسم الدفع (Payment)
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
