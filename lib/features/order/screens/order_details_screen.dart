// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/order/widgets/order_calcuation_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/checkout/widgets/offline_success_dialog.dart';
import 'package:sixam_mart/features/order/widgets/cancellation_dialogue_widget.dart';
import 'package:sixam_mart/features/order/widgets/order_info_widget.dart';
import 'package:sixam_mart/features/review/screens/rate_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/loading/loading.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? orderModel;
  final int? orderId;
  final bool fromNotification;
  final bool fromOfflinePayment;
  final String? contactNumber;
  const OrderDetailsScreen(
      {super.key,
      required this.orderModel,
      required this.orderId,
      this.fromNotification = false,
      this.fromOfflinePayment = false,
      this.contactNumber});

  @override
  OrderDetailsScreenState createState() => OrderDetailsScreenState();
}

class OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Timer? _timer;
  Timer? _slowLoadTimer;
  double? _maxCodOrderAmount;
  bool? _isCashOnDeliveryActive = false;
  final ScrollController scrollController = ScrollController();
  bool _isInitialLoading = true;
  bool _showRetryAction = false;

  Future<void> _loadData(BuildContext context, bool reload) async {
    if (mounted) {
      setState(() {
        _isInitialLoading = true;
        _showRetryAction = false;
      });
    }

    _slowLoadTimer?.cancel();
    _slowLoadTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isInitialLoading) {
        setState(() {
          _showRetryAction = true;
        });
      }
    });

    try {
      await Future.wait<void>([
        // Always force fresh track API on entry so fees/delivery details are
        // up-to-date immediately (without waiting for periodic poll).
        Get.find<OrderController>().trackOrder(
          widget.orderId.toString(),
          null,
          false,
          contactNumber: widget.contactNumber,
        ),
        Get.find<OrderController>().getOrderDetails(widget.orderId.toString()),
      ]);

      if (widget.fromOfflinePayment) {
        Future.delayed(
            const Duration(seconds: 2),
            () => showAnimatedDialog(
                Get.context!, OfflineSuccessDialog(orderId: widget.orderId)));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _showRetryAction = true;
        });
      }
    } finally {
      _slowLoadTimer?.cancel();
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _startApiCall() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final route = ModalRoute.of(context);
      if (!mounted || route?.isCurrent != true) {
        return;
      }
      await Get.find<OrderController>().timerTrackOrder(
          widget.orderId.toString(),
          contactNumber: widget.contactNumber);
    });
  }

  @override
  void initState() {
    super.initState();

    _loadData(context, true);

    _startApiCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slowLoadTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.fromNotification || widget.fromOfflinePayment) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'order_details'.tr,
          onBackPressed: () {
            if (widget.fromNotification || widget.fromOfflinePayment) {
              Get.offAllNamed(RouteHelper.getInitialRoute());
            } else {
              Get.back();
            }
          },
        ),
        endDrawerEnableOpenDragGesture: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
            child: GetBuilder<OrderController>(builder: (orderController) {
          //

          final bool hasReadyData = orderController.orderDetails != null &&
              orderController.trackModel != null;
          if (!hasReadyData) {
            return _buildLoadingView(orderController);
          }
          final List<OrderDetailsModel> orderDetailsList =
              orderController.orderDetails!;
          final OrderModel order = orderController.trackModel!;

          double deliveryCharge = 0;
          double itemsPrice = 0;
          double discount = 0;
          double couponDiscount = 0;
          double tax = 0;
          double addOns = 0;
          double dmTips = 0;
          double additionalCharge = 0;
          double extraPackagingCharge = 0;
          double referrerBonusAmount = 0;
          bool parcel = false;
          bool prescriptionOrder = false;
          bool taxIncluded = false;
          bool ongoing = false;
          bool showChatPermission = true;
          double subTotal = 0;
          double taxFromDetails = 0;
          double total = order.orderAmount ?? 0;
          parcel = order.orderType == 'parcel';
          prescriptionOrder = order.prescriptionOrder ?? false;
          deliveryCharge = order.deliveryCharge ?? 0;
          couponDiscount = order.couponDiscountAmount ?? 0;
          discount = (order.storeDiscountAmount ?? 0) +
              (order.flashAdminDiscountAmount ?? 0) +
              (order.flashStoreDiscountAmount ?? 0);

          // Tax: match checkout by using the same formula:
          // _calculateTax(taxIncluded, orderAmount: subTotal, taxPercent)
          final double taxPercent =
              order.store?.tax?.toDouble() ?? order.taxPercentage ?? 0;

          dmTips = order.dmTips ?? 0;
          taxIncluded = order.taxStatus ?? false;
          additionalCharge = order.additionalCharge ?? 0;
          extraPackagingCharge = order.extraPackagingAmount ?? 0;
          referrerBonusAmount = order.referrerBonusAmount ?? 0;

          // Some APIs return order_amount as 0 for old/legacy orders.
          // Fallback to successful payment rows when available.
          if (total <= 0 &&
              order.payments != null &&
              order.payments!.isNotEmpty) {
            double paymentsTotal = 0;
            for (final payment in order.payments!) {
              paymentsTotal += payment.amount ?? 0;
            }
            if (paymentsTotal > 0) {
              total = PriceConverter.toFixed(paymentsTotal);
              if (kDebugMode) {
                debugPrint('[FEES FALLBACK] using payments sum as total');
                debugPrint('   - paymentsTotal: $total');
              }
            }
          }

          // Align delivery fee and app fee with checkout logic when backend
          // collapses them into deliveryfee_tax / original_delivery_charge.
          final config = Get.find<SplashController>().configModel;
          final bool configAppFeeEnabled =
              config?.additionalChargeStatus ?? false;
          final double configAppFee =
              configAppFeeEnabled ? (config?.additionCharge ?? 0) : 0;
          final double combinedDeliveryFee =
              order.deliveryfeeTax ?? 0; // includes delivery + app fee
          final double originalDeliveryCharge =
              order.originalDeliveryCharge ?? 0;

          // If both delivery and app fee are zero but combined fee exists,
          // split it into delivery + app fee using the same app fee config
          // used on checkout, so order details matches checkout summary.
          if (deliveryCharge == 0 &&
              additionalCharge == 0 &&
              combinedDeliveryFee > 0) {
            if (configAppFee > 0 && combinedDeliveryFee > configAppFee) {
              additionalCharge = PriceConverter.toFixed(configAppFee);
              deliveryCharge = PriceConverter.toFixed(
                  combinedDeliveryFee - additionalCharge);
            } else {
              // Fallback: treat the whole combined fee as delivery
              deliveryCharge = PriceConverter.toFixed(combinedDeliveryFee);
            }
          }

          // If deliveryCharge is still zero but backend sent originalDeliveryCharge,
          // use it for display so delivery is not shown as free.
          if (deliveryCharge == 0 && originalDeliveryCharge > 0) {
            deliveryCharge = PriceConverter.toFixed(originalDeliveryCharge);
          }

          if (prescriptionOrder) {
            final double orderAmount = order.orderAmount ?? 0;
            itemsPrice = (orderAmount + discount) -
                ((taxIncluded ? 0 : tax) + deliveryCharge) -
                dmTips -
                additionalCharge;
          } else {
            for (final OrderDetailsModel orderDetails in orderDetailsList) {
              for (final AddOn addOn in orderDetails.addOns ?? []) {
                addOns += (addOn.price ?? 0) * (addOn.quantity ?? 0);
              }
              // Calculate discounted price for each item
              final double discountedPrice = (orderDetails.price ?? 0) -
                  (orderDetails.discountOnItem ?? 0);
              itemsPrice += discountedPrice * (orderDetails.quantity ?? 0);
              taxFromDetails += orderDetails.taxAmount ?? 0;
            }
          }

          itemsPrice = PriceConverter.toFixed(itemsPrice);
          addOns = PriceConverter.toFixed(addOns);
          subTotal = PriceConverter.toFixed(itemsPrice + addOns);
          taxFromDetails = PriceConverter.toFixed(taxFromDetails);

          // Calculate tax after we know subTotal, using checkout-style logic
          tax = _calculateTax(
            taxIncluded: order.taxStatus ?? false,
            orderAmount: subTotal,
            taxPercent: taxPercent,
          );

          // Rebuild expected total from visible breakdown to keep summary consistent.
          final double reconstructedTotal = PriceConverter.toFixed(
            subTotal -
                discount -
                couponDiscount -
                referrerBonusAmount +
                deliveryCharge +
                additionalCharge +
                extraPackagingCharge +
                dmTips +
                ((order.taxStatus ?? false) ? 0 : tax),
          );

          // If total is missing, use reconstructed value.
          if (total <= 0 && reconstructedTotal > 0) {
            total = reconstructedTotal;
            if (kDebugMode) {
              debugPrint('[FEES FALLBACK] reconstructed total from breakdown');
              debugPrint('   - reconstructedTotal: $total');
            }
          }

          // If backend total differs from breakdown, prefer reconstructed value
          // so tax/additional lines match the displayed total.
          if (total > 0 && reconstructedTotal > 0) {
            final double signedDelta =
                PriceConverter.toFixed(total - reconstructedTotal);
            final double delta = signedDelta.abs();
            if (delta >= 0.05) {
              if (kDebugMode) {
                debugPrint(
                    '[FEES ADJUST] Backend total differs from breakdown');
                debugPrint('   - backendTotal: $total');
                debugPrint('   - reconstructedTotal: $reconstructedTotal');
                debugPrint('   - delta: $delta');
              }

              // If backend total is higher and delivery charge is zero, infer missing delivery fee
              // from the difference instead of forcing total down to reconstructed value.
              final bool missingDeliveryLikely =
                  signedDelta > 0 && deliveryCharge == 0;
              if (missingDeliveryLikely) {
                deliveryCharge = PriceConverter.toFixed(signedDelta);
                if (kDebugMode) {
                  debugPrint(
                      '[FEES ADJUST] Inferred missing delivery charge from delta');
                  debugPrint('   - inferredDeliveryCharge: $deliveryCharge');
                  debugPrint('   - keeping backend total: $total');
                }
              } else {
                total = reconstructedTotal;
              }
            }
          }

          final bool hasZeroBreakdown =
              itemsPrice == 0 && addOns == 0 && subTotal == 0 && total > 0;
          if (hasZeroBreakdown) {
            final double orderLevelTax = PriceConverter.toFixed(
              order.totalTaxAmount ?? taxFromDetails,
            );
            final double taxForEquation =
                (order.taxStatus ?? false) ? 0 : orderLevelTax;

            final double derivedSubTotal = PriceConverter.toFixed(
              total +
                  discount +
                  couponDiscount +
                  referrerBonusAmount -
                  deliveryCharge -
                  additionalCharge -
                  extraPackagingCharge -
                  dmTips -
                  taxForEquation,
            );

            if (derivedSubTotal > 0) {
              subTotal = derivedSubTotal;
              itemsPrice = derivedSubTotal;
            } else {
              subTotal = total;
              itemsPrice = total;
            }
            addOns = 0;
            tax = orderLevelTax;

            if (kDebugMode) {
              debugPrint(
                  '[FEES FALLBACK] derived subtotal from backend total because details breakdown was empty');
              debugPrint('   - derivedSubTotal: $subTotal');
              debugPrint('   - orderLevelTax: $tax');
            }
          }

          debugPrint('🔍 [FEES DEBUG] Final values before widget:');
          debugPrint('   - itemsPrice: $itemsPrice');
          debugPrint('   - addOns: $addOns');
          debugPrint('   - discount: $discount');
          debugPrint('   - couponDiscount: $couponDiscount');
          debugPrint('   - deliveryCharge: $deliveryCharge');
          debugPrint('   - additionalCharge: $additionalCharge');
          debugPrint('   - extraPackagingCharge: $extraPackagingCharge');
          debugPrint('   - dmTips: $dmTips');
          debugPrint('   - tax: $tax');
          debugPrint('   - subTotal: $subTotal');
          debugPrint('   - total (resolved): $total');

          // #region debug - tax calculation
          debugPrint('🔍 [TAX DEBUG] Before tax resolution:');
          debugPrint('   - order.totalTaxAmount: ${order.totalTaxAmount}');
          debugPrint('   - tax (checkout-style on subTotal): $tax');
          debugPrint('   - taxFromDetails (sum of items): $taxFromDetails');
          debugPrint('   - subTotal: $subTotal');
          // #endregion

          if (!parcel && order.store != null) {
            final userAddress = AddressHelper.getUserAddressFromSharedPref();
            if (userAddress != null && userAddress.zoneData != null) {
              for (final ZoneData zData in userAddress.zoneData!) {
                if (zData.id == order.store!.zoneId) {
                  _isCashOnDeliveryActive = zData.cashOnDelivery ?? false;
                }
                for (final Modules m in zData.modules ?? []) {
                  if (m.id == order.store!.moduleId) {
                    _maxCodOrderAmount = m.pivot?.maximumCodOrderAmount ?? 0;
                    break;
                  }
                }
              }
            }
          }

          if (order.store != null) {
            if (order.store!.storeBusinessModel == 'commission') {
              showChatPermission = true;
            } else if (order.store!.storeSubscription != null &&
                order.store!.storeBusinessModel == 'subscription') {
              showChatPermission = order.store!.storeSubscription!.chat == 1;
            } else {
              showChatPermission = false;
            }
          } else {
            showChatPermission = AuthHelper.isLoggedIn();
          }

          ongoing = (order.orderStatus != 'delivered' &&
              order.orderStatus != 'failed' &&
              order.orderStatus != 'canceled' &&
              order.orderStatus != 'refund_requested' &&
              order.orderStatus != 'refunded' &&
              order.orderStatus != 'refund_request_canceled');
          return Column(children: [
            ResponsiveHelper.isDesktop(context)
                ? Container(
                    height: 64,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.10),
                    child: Center(
                        child: Text('order_details'.tr, style: robotoMedium)),
                  )
                : const SizedBox(),
            Expanded(
                child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              child: FooterView(
                  child: SizedBox(
                      width: Dimensions.webMaxWidth,
                      child: Column(
                        children: [
                          ResponsiveHelper.isDesktop(context)
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Expanded(
                                        flex: 6,
                                        child: OrderInfoWidget(
                                          order: order,
                                          ongoing: ongoing,
                                          parcel: parcel,
                                          prescriptionOrder: prescriptionOrder,
                                          timerCancel: () => _timer?.cancel(),
                                          startApiCall: () => _startApiCall(),
                                          orderController: orderController,
                                          showChatPermission:
                                              showChatPermission,
                                        ),
                                      ),
                                      const SizedBox(
                                          width: Dimensions.paddingSizeLarge),
                                      Expanded(
                                        flex: 4,
                                        child: Builder(builder: (context) {
                                          // #region debug - final tax value
                                          debugPrint(
                                              '📊 [FINAL TAX] Passing to OrderCalculationWidget:');
                                          debugPrint('   - tax: $tax');
                                          debugPrint(
                                              '   - subTotal: $subTotal');
                                          debugPrint('   - total: $total');
                                          debugPrint(
                                              '   - order.taxPercentage: ${order.taxPercentage}');
                                          // #endregion
                                          return OrderCalculationWidget(
                                            orderController: orderController,
                                            order: order,
                                            ongoing: ongoing,
                                            parcel: parcel,
                                            prescriptionOrder:
                                                prescriptionOrder,
                                            deliveryCharge: deliveryCharge,
                                            itemsPrice: itemsPrice,
                                            discount: discount,
                                            couponDiscount: couponDiscount,
                                            tax: tax,
                                            addOns: addOns,
                                            dmTips: dmTips,
                                            taxIncluded: taxIncluded,
                                            subTotal: subTotal,
                                            total: total,
                                            bottomView: _bottomView(
                                                orderController,
                                                order,
                                                parcel,
                                                total),
                                            extraPackagingAmount:
                                                extraPackagingCharge,
                                            referrerBonusAmount:
                                                referrerBonusAmount,
                                            additionalCharge: additionalCharge,
                                            timerCancel: () => _timer?.cancel(),
                                            startApiCall: () => _startApiCall(),
                                          );
                                        }),
                                      ),
                                    ])
                              : const SizedBox(),
                          ResponsiveHelper.isDesktop(context)
                              ? const SizedBox()
                              : OrderInfoWidget(
                                  order: order,
                                  ongoing: ongoing,
                                  parcel: parcel,
                                  prescriptionOrder: prescriptionOrder,
                                  timerCancel: () => _timer?.cancel(),
                                  startApiCall: () => _startApiCall(),
                                  orderController: orderController,
                                  showChatPermission: showChatPermission,
                                ),
                          ResponsiveHelper.isDesktop(context)
                              ? const SizedBox()
                              : OrderCalculationWidget(
                                  orderController: orderController,
                                  order: order,
                                  ongoing: ongoing,
                                  parcel: parcel,
                                  prescriptionOrder: prescriptionOrder,
                                  deliveryCharge: deliveryCharge,
                                  itemsPrice: itemsPrice,
                                  discount: discount,
                                  couponDiscount: couponDiscount,
                                  tax: tax,
                                  addOns: addOns,
                                  dmTips: dmTips,
                                  taxIncluded: taxIncluded,
                                  subTotal: subTotal,
                                  total: total,
                                  bottomView: const SizedBox(),
                                  extraPackagingAmount: extraPackagingCharge,
                                  referrerBonusAmount: referrerBonusAmount,
                                  additionalCharge: additionalCharge,
                                  timerCancel: () => _timer?.cancel(),
                                  startApiCall: () => _startApiCall(),
                                ),
                        ],
                      ))),
            )),
            ResponsiveHelper.isDesktop(context)
                ? const SizedBox()
                : _bottomView(orderController, order, parcel, total),
          ]);
        })),
      ),
    );
  }

  Widget _buildLoadingView(OrderController orderController) {
    final bool showRetry = _showRetryAction && !orderController.isLoading;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingWidget(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'please_wait'.tr,
              style: robotoRegular,
              textAlign: TextAlign.center,
            ),
            if (showRetry) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              TextButton(
                onPressed: () => _loadData(context, true),
                child: Text('retry'.tr, style: robotoBold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void openDialog(BuildContext context, String imageUrl) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                child: PhotoView(
                  tightMode: true,
                  imageProvider: NetworkImage(imageUrl),
                  heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
                ),
              ),
              Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    splashRadius: 5,
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  )),
            ]),
          );
        },
      );

  Widget _bottomView(OrderController orderController, OrderModel order,
      bool parcel, double totalPrice) {
    return Column(children: [
      !orderController.showCancelled
          ? Center(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: Row(children: [
                  ((order.orderStatus == 'pending' &&
                              order.paymentMethod != 'digital_payment') ||
                          order.orderStatus == 'accepted' ||
                          order.orderStatus == 'confirmed' ||
                          order.orderStatus == 'processing' ||
                          order.orderStatus == 'handover' ||
                          order.orderStatus == 'picked_up')
                      ? Expanded(
                          child: CustomButton(
                            buttonText:
                                parcel ? 'track_delivery'.tr : 'track_order'.tr,
                            margin: ResponsiveHelper.isDesktop(context)
                                ? null
                                : const EdgeInsets.all(
                                    Dimensions.paddingSizeSmall),
                            onPressed: () async {
                              _timer?.cancel();
                              await Get.toNamed(
                                      RouteHelper.getOrderTrackingRoute(
                                          order.id, widget.contactNumber))
                                  ?.whenComplete(() {
                                _startApiCall();
                              });
                            },
                          ),
                        )
                      : const SizedBox(),
                  (order.orderStatus == 'pending' &&
                          order.paymentStatus == 'unpaid' &&
                          order.paymentMethod == 'digital_payment' &&
                          _isCashOnDeliveryActive!)
                      ? Expanded(
                          child: CustomButton(
                            buttonText: 'switch_to_cod'.tr,
                            margin: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            onPressed: () {
                              Get.dialog(ConfirmationDialog(
                                  icon: Images.warning,
                                  description: 'are_you_sure_to_switch'.tr,
                                  onYesPressed: () {
                                    if ((((_maxCodOrderAmount != null &&
                                                    totalPrice <
                                                        _maxCodOrderAmount!) ||
                                                _maxCodOrderAmount == null ||
                                                _maxCodOrderAmount == 0) &&
                                            !parcel) ||
                                        parcel) {
                                      orderController
                                          .switchToCOD(order.id.toString());
                                    } else {
                                      if (Get.isDialogOpen!) {
                                        Get.back();
                                      }
                                      showCustomSnackBar(
                                          '${'you_cant_order_more_then'.tr} ${PriceConverter.convertPrice2(_maxCodOrderAmount)} ${'in_cash_on_delivery'.tr}');
                                    }
                                  }));
                            },
                          ),
                        )
                      : const SizedBox(),
                  order.orderStatus == 'pending'
                      ? const SizedBox(width: Dimensions.paddingSizeSmall)
                      : const SizedBox(),
                  (order.orderStatus == 'pending' &&
                          (Get.find<AuthController>().isLoggedIn()
                              ? true
                              : (orderController.orderDetails != null &&
                                      orderController
                                          .orderDetails!.isNotEmpty &&
                                      orderController
                                              .orderDetails?[0].isGuest ==
                                          1
                                  ? true
                                  : false)))
                      ? Expanded(
                          child: Padding(
                          padding: ResponsiveHelper.isDesktop(context)
                              ? EdgeInsets.zero
                              : const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall),
                          child: TextButton(
                            style: TextButton.styleFrom(
                                minimumSize: const Size(1, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                  side: BorderSide(
                                      width: 2,
                                      color: Theme.of(context).disabledColor),
                                )),
                            onPressed: () {
                              //  الغاء الطلب  ======================================================================

                              orderController.setOrderCancelReason('');
                              Get.dialog(CancellationDialogueWidget(
                                  orderId: order.id));
                            },
                            child: Text(
                                parcel
                                    ? 'cancel_delivery'.tr
                                    : 'cancel_order'.tr,
                                style: robotoBold.copyWith(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: Dimensions.fontSizeLarge,
                                )),
                          ),
                        ))
                      : const SizedBox(),
                ]),
              ),
            )
          : Center(
              child: Container(
                width: Dimensions.webMaxWidth,
                height: 50,
                margin: ResponsiveHelper.isDesktop(context)
                    ? null
                    : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                      width: 2, color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Text('order_cancelled'.tr,
                    style: robotoMedium.copyWith(
                        color: Theme.of(context).primaryColor)),
              ),
            ),
      !AuthHelper.isGuestLoggedIn() &&
              (order.orderStatus == 'delivered' &&
                  (parcel
                      ? order.deliveryMan != null
                      : (orderController.orderDetails!.isNotEmpty &&
                          orderController.orderDetails![0].itemCampaignId ==
                              null)))
          ? Center(
              child: Container(
                width: Dimensions.webMaxWidth,
                padding: ResponsiveHelper.isDesktop(context)
                    ? null
                    : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: CustomButton(
                  buttonText: 'review'.tr,
                  onPressed: () {
                    final List<OrderDetailsModel> orderDetailsList = [];
                    final List<int?> orderDetailsIdList = [];
                    for (final orderDetail in orderController.orderDetails!) {
                      if (!orderDetailsIdList
                          .contains(orderDetail.itemDetails!.id)) {
                        orderDetailsList.add(orderDetail);
                        orderDetailsIdList.add(orderDetail.itemDetails!.id);
                      }
                    }
                    Get.toNamed(RouteHelper.getReviewRoute(),
                        arguments: RateReviewScreen(
                          orderDetailsList: orderDetailsList,
                          deliveryMan: order.deliveryMan,
                          orderID: order.id,
                        ));
                  },
                ),
              ),
            )
          : const SizedBox(),
      (order.orderStatus == 'failed' &&
              Get.find<SplashController>().configModel!.cashOnDelivery!)
          ? Center(
              child: Container(
                width: Dimensions.webMaxWidth,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: CustomButton(
                  buttonText: 'switch_to_cash_on_delivery'.tr,
                  onPressed: () {
                    Get.dialog(ConfirmationDialog(
                        icon: Images.warning,
                        description: 'are_you_sure_to_switch'.tr,
                        onYesPressed: () {
                          orderController
                              .switchToCOD(order.id.toString())
                              .then((isSuccess) {
                            Get.back();
                            if (isSuccess) {
                              Get.back();
                            }
                          });
                        }));
                  },
                ),
              ),
            )
          : const SizedBox(),
    ]);
  }

  /// Calculate tax based on original prices
  double _calculateTax({
    required bool taxIncluded,
    required double orderAmount,
    required double? taxPercent,
  }) {
    if (taxPercent == null || taxPercent == 0) {
      return 0.0;
    }

    double tax = 0;
    if (taxIncluded) {
      tax = orderAmount * taxPercent / (100 + taxPercent);
    } else {
      tax = PriceConverter.calculation(orderAmount, taxPercent, 'percent', 1);
    }
    return PriceConverter.toFixed(tax);
  }
}
