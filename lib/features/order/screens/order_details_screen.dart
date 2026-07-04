// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:sixam_mart/common/widgets/card_design/store_list_card.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/offline_success_dialog.dart';
import 'package:sixam_mart/features/order/widgets/cancellation_dialogue_widget.dart';
import 'package:sixam_mart/features/order/widgets/order_info_widget.dart';
import 'package:sixam_mart/features/order/widgets/order_details_redesign_view.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Map<int, List<Item>> _productAlternativesByOrderId =
      <int, List<Item>>{};
  final Set<int> _productAlternativesLoading = <int>{};
  final Set<int> _productAlternativesExpanded = <int>{};
  final Set<int> _productAlternativesLoaded = <int>{};

  bool _isFailedOrExpiredStatus(String? status) {
    final normalized = (status ?? '').toLowerCase();
    return _isTerminalOrderStatus(normalized);
  }

  bool _isTerminalOrderStatus(String? status) {
    const Set<String> terminalStatuses = <String>{
      'expired',
      'failed',
      'canceled',
      'cancelled',
      'refunded',
      'refund_requested',
      'refund_request_canceled',
    };
    return terminalStatuses.contains((status ?? '').toLowerCase());
  }

  Future<void> _loadData(BuildContext context, bool reload) async {
    if (widget.orderId != null && widget.orderId! > 0) {
      Get.find<OrderController>().prepareOrderDetailsSession(widget.orderId);
    }
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
      final OrderController orderController = Get.find<OrderController>();
      await Future.wait<void>([
        // Always force fresh track API on entry so fees/delivery details are
        // up-to-date immediately (without waiting for periodic poll).
        orderController.trackOrder(
          widget.orderId.toString(),
          null,
          false,
          contactNumber: widget.contactNumber,
        ),
        orderController.getOrderDetails(widget.orderId.toString()),
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
      final OrderController orderController = Get.find<OrderController>();
      if (_isOrderInTerminalState(orderController.trackModel)) {
        timer.cancel();
        return;
      }
      await orderController.timerTrackOrder(widget.orderId.toString(),
          contactNumber: widget.contactNumber);
      if (_isOrderInTerminalState(orderController.trackModel)) {
        timer.cancel();
      }
    });
  }

  bool _isOrderInTerminalState(OrderModel? order) {
    if (order == null || order.id?.toString() != widget.orderId.toString()) {
      return false;
    }
    final String orderStatus = (order.orderStatus ?? '').toLowerCase();
    final String paymentStatus = (order.paymentStatus ?? '').toLowerCase();
    const Set<String> terminalOrderStatuses = <String>{
      'delivered',
      'canceled',
      'cancelled',
      'failed',
      'expired',
      'refunded',
      'refund_requested',
      'refund_request_canceled',
    };
    const Set<String> terminalPaymentStatuses = <String>{
      'paid',
      'failed',
      'canceled',
      'cancelled',
      'refunded',
    };
    return terminalOrderStatuses.contains(orderStatus) ||
        terminalPaymentStatuses.contains(paymentStatus);
  }

  @override
  void initState() {
    super.initState();

    _loadData(context, true);

    _startApiCall();
  }

  @override
  void didUpdateWidget(OrderDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      if (kDebugMode) {
        debugPrint(
          '[OrderDetails][OPEN] requestedOrderId=${widget.orderId} (route changed from ${oldWidget.orderId})',
        );
      }
      _timer?.cancel();
      _loadData(context, true);
      _startApiCall();
    }
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
        // 🎨 REDESIGN: clean white app bar (was the green CustomAppBar) to match
        // the new order-details design.
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          automaticallyImplyLeading: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          title: Text(
            'ord_your_order_details'.tr,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Color(0xFF121C19),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF121C19), size: 20),
            onPressed: () {
              if (widget.fromNotification || widget.fromOfflinePayment) {
                Get.offAllNamed(RouteHelper.getInitialRoute());
              } else {
                Get.back();
              }
            },
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: Dimensions.paddingSizeDefault),
              child: Icon(Icons.bookmark_border, color: Color(0xFF121C19)),
            ),
          ],
        ),
        endDrawerEnableOpenDragGesture: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
            child: GetBuilder<OrderController>(builder: (orderController) {
          //

          final int? routeOrderId = widget.orderId;
          final OrderModel? track = orderController.trackModel;
          final List<OrderDetailsModel>? details = orderController.orderDetails;
          final bool trackMatchesRoute =
              routeOrderId != null && track != null && track.id == routeOrderId;
          final bool detailsMatchRoute = details == null ||
              details.isEmpty ||
              details.every(
                (OrderDetailsModel d) =>
                    d.orderId == null || d.orderId == routeOrderId,
              );
          final bool hasReadyData =
              trackMatchesRoute && detailsMatchRoute && details != null;
          if (!hasReadyData) {
            if (kDebugMode &&
                track != null &&
                routeOrderId != null &&
                track.id != routeOrderId) {
              debugPrint(
                '[OrderDetails][RENDER_BLOCKED_STALE] requestedOrderId=$routeOrderId cachedOrderId=${track.id}',
              );
            }
            return _buildLoadingView(orderController);
          }
          final List<OrderDetailsModel> orderDetailsList = details;
          final OrderModel order = track;
          if (kDebugMode) {
            debugPrint(
              '[ORDER_DETAILS_BUILD] orderId=${order.id} status=${order.orderStatus} '
              'storeId=${order.store?.id} hasStore=${order.store != null}',
            );
          }

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
              order.orderStatus != 'expired' &&
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
                              : OrderDetailsRedesignView(
                                  order: order,
                                  orderDetails: orderDetailsList,
                                  parcel: parcel,
                                  taxIncluded: taxIncluded,
                                  itemsPrice: itemsPrice,
                                  addOns: addOns,
                                  deliveryCharge: deliveryCharge,
                                  additionalCharge: additionalCharge,
                                  extraPackagingCharge: extraPackagingCharge,
                                  discount: discount,
                                  couponDiscount: couponDiscount,
                                  referrerBonusAmount: referrerBonusAmount,
                                  tax: tax,
                                  dmTips: dmTips,
                                  total: total,
                                ),
                          if (_isFailedOrExpiredStatus(order.orderStatus))
                            _buildFailedOrderRecoverySection(
                              orderController,
                              order,
                              orderDetailsList,
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
                  imageProvider: CachedNetworkImageProvider(imageUrl),
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
    if (_isTerminalOrderStatus(order.orderStatus)) {
      return const SizedBox();
    }
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
                  // Explicit, user-initiated payment recovery for an unpaid
                  // DIGITAL/MyFatoorah order (e.g. app was killed during the
                  // WebView). Shown when the order is 'payment_pending', OR
                  // 'pending' with payment_status 'unpaid'. Only for
                  // digital_payment — never wallet_qidha / wallet / COD.
                  ((order.orderStatus == 'payment_pending' ||
                              (order.orderStatus == 'pending' &&
                                  order.paymentStatus == 'unpaid')) &&
                          order.paymentMethod == 'digital_payment')
                      ? Expanded(
                          child: CustomButton(
                            buttonText: 'ord_check_payment'.tr,
                            margin: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            onPressed: () async {
                              final MyFatoorahPaymentResult result =
                                  await Get.find<CheckoutController>()
                                      .checkOrderPaymentStatusExplicit(
                                order.id!,
                                contactNumber: widget.contactNumber,
                              );
                              // Refresh this order's details after the check so
                              // the UI reflects the latest status.
                              debugPrint(
                                  '[PaymentRecovery][EXPLICIT_ORDER_REFRESH] '
                                  'orderId=${order.id} result=$result');
                              if (!mounted) return;
                              _loadData(Get.context!, true);
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
      // 🎨 REDESIGN: review button removed for the completed order screen —
      // the "أعد طلب الأوردر" action replaces it per the design.
      const SizedBox(),
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

  Widget _buildFailedOrderRecoverySection(
    OrderController orderController,
    OrderModel order,
    List<OrderDetailsModel> orderDetailsList,
  ) {
    final int orderId = order.id ?? 0;
    final bool loading = orderController.isAlternativeStoresLoading(orderId);
    final bool expanded = orderController.isAlternativeStoresExpanded(orderId);
    final stores = orderController.getAlternativeStoresForOrder(orderId);
    final bool productLoading = _productAlternativesLoading.contains(orderId);
    final bool productExpanded = _productAlternativesExpanded.contains(orderId);
    final List<Item> productAlternatives =
        _productAlternativesByOrderId[orderId] ?? <Item>[];

    final String moduleType = _resolveOrderModuleTypeForRecovery(order);
    final bool isRestaurantModule = _isRestaurantModuleType(moduleType);
    final bool isEcommerceLike = _isEcommerceModuleType(
      moduleType,
      storeModuleId: order.store?.moduleId,
      storeName: order.store?.name,
    );

    if (kDebugMode) {
      debugPrint(
        '[CANCELLED_ORDER_RECOVERY_BUILD] orderId=$orderId',
      );
      debugPrint(
        '[CANCELLED_ORDER_MODULE_FIELDS] moduleType=${order.moduleType} '
        'moduleId=${order.store?.moduleId} storeModuleType=$moduleType '
        'storeId=${order.store?.id} storeName=${order.store?.name}',
      );
      debugPrint(
        '[CANCELLED_ORDER_IS_RESTAURANT] orderId=$orderId value=$isRestaurantModule',
      );
      debugPrint(
        '[CANCELLED_ORDER_IS_ECOMMERCE] orderId=$orderId value=$isEcommerceLike',
      );
      debugPrint(
        '[ALTERNATIVES_SECTION_TYPE] orderId=$orderId '
        'type=${isRestaurantModule ? 'restaurant' : (isEcommerceLike ? 'hidden' : 'hidden')} '
        'count=${stores.length}',
      );
      debugPrint(
        '[RECOVERY_SECTION_TYPE] orderId=$orderId '
        'type=${isRestaurantModule ? 'restaurant' : (isEcommerceLike ? 'product' : 'hidden')}',
      );
      if (!isRestaurantModule && !isEcommerceLike) {
        final String hiddenReason = isEcommerceLike
            ? 'ecommerce_or_grocery_no_product_alternatives_api'
            : 'unknown_module_safe_hide';
        debugPrint(
          '[ALTERNATIVES_SECTION_HIDDEN] orderId=$orderId '
          'reason=$hiddenReason',
        );
        debugPrint(
          '[RECOVERY_SECTION_HIDDEN_REASON] orderId=$orderId reason=$hiddenReason',
        );
      }
    }

    return Container(
      width: Dimensions.webMaxWidth,
      margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ord_complete_failed'.tr, style: robotoBold),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text('ord_refunded_wallet'.tr, style: robotoRegular),
          // Alternatives section is restaurant/cafe only. We do NOT have a
          // product-alternatives API to honour the ecommerce/grocery case, so
          // we hide the section gracefully instead of inventing fake data or
          // showing restaurant wording.
          if (isRestaurantModule) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            OutlinedButton(
              onPressed: () {
                orderController.toggleAlternativeStores(orderId);
              },
              child: Text('ord_alt_stores'.tr),
            ),
            if (expanded && loading)
              const Padding(
                padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                child: LoadingWidget(),
              ),
            if (expanded && !loading && stores.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                child: Text('ord_no_alt_stores'.tr,
                    style: robotoRegular),
              ),
            if (expanded && !loading && stores.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return _buildAlternativeStoreTile(store);
                },
                separatorBuilder: (_, __) =>
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                itemCount: stores.length,
              ),
          ],
          if (isEcommerceLike) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            OutlinedButton(
              onPressed: () {
                _toggleProductAlternatives(
                  order: order,
                  orderDetailsList: orderDetailsList,
                );
              },
              child: Text('ord_alt_products'.tr),
            ),
            if (productExpanded && productLoading)
              const Padding(
                padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                child: LoadingWidget(),
              ),
            if (productExpanded && !productLoading && productAlternatives.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                child: Text('ord_no_alt_products'.tr,
                    style: robotoRegular),
              ),
            if (productExpanded && !productLoading && productAlternatives.isNotEmpty)
              Builder(builder: (_) {
                if (kDebugMode) {
                  debugPrint(
                      '[PRODUCT_ALTERNATIVES_RENDER] orderId=$orderId count=${productAlternatives.length}');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final Item item = productAlternatives[index];
                    return _buildAlternativeProductTile(item);
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: productAlternatives.length,
                );
              }),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleProductAlternatives({
    required OrderModel order,
    required List<OrderDetailsModel> orderDetailsList,
  }) async {
    final int orderId = order.id ?? 0;
    if (orderId <= 0) {
      return;
    }
    if (_productAlternativesExpanded.contains(orderId)) {
      setState(() {
        _productAlternativesExpanded.remove(orderId);
      });
      return;
    }
    setState(() {
      _productAlternativesExpanded.add(orderId);
    });
    if (_productAlternativesLoaded.contains(orderId)) {
      return;
    }
    await _fetchProductAlternatives(
      order: order,
      orderDetailsList: orderDetailsList,
    );
  }

  Future<void> _fetchProductAlternatives({
    required OrderModel order,
    required List<OrderDetailsModel> orderDetailsList,
  }) async {
    final int orderId = order.id ?? 0;
    final int? storeId = order.store?.id;
    final int? moduleId = order.store?.moduleId;
    final int? categoryId = _resolveOrderCategoryId(orderDetailsList);
    final Set<int> excludedItemIds = _extractOrderedItemIds(orderDetailsList);

    if (kDebugMode) {
      debugPrint(
        '[PRODUCT_ALTERNATIVES_FETCH_START] orderId=$orderId storeId=$storeId '
        'moduleId=$moduleId categoryId=$categoryId',
      );
    }

    if (orderId <= 0 || storeId == null || storeId <= 0) {
      if (kDebugMode) {
        debugPrint(
            '[PRODUCT_ALTERNATIVES_FETCH_EMPTY] orderId=$orderId reason=missing_store_id');
      }
      if (mounted) {
        setState(() {
          _productAlternativesByOrderId[orderId] = <Item>[];
          _productAlternativesLoaded.add(orderId);
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _productAlternativesLoading.add(orderId);
      });
    }

    try {
      final StoreController storeController = Get.find<StoreController>();
      ItemModel? itemModel;
      if (categoryId != null && categoryId > 0) {
        itemModel = await storeController.fetchCategoryItemsPage(
          storeId: storeId,
          categoryId: categoryId,
          offset: 1,
          limit: 20,
        );
      }
      itemModel ??= await storeController.fetchCategoryItemsPage(
        storeId: storeId,
        categoryId: 0,
        offset: 1,
        limit: 20,
      );

      final List<Item> rawItems = itemModel?.items ?? <Item>[];
      final List<Item> filtered = <Item>[];
      for (final Item item in rawItems) {
        final int? itemId = item.id;
        if (itemId == null) {
          continue;
        }
        if (excludedItemIds.contains(itemId)) {
          continue;
        }
        if (item.storeId != null && item.storeId != storeId) {
          continue;
        }
        filtered.add(item);
      }
      final List<Item> deduped = <Item>[];
      final Set<int> seen = <int>{};
      for (final Item item in filtered) {
        if (item.id == null) {
          continue;
        }
        if (seen.add(item.id!)) {
          deduped.add(item);
        }
      }
      final List<Item> resolved = deduped.take(6).toList();
      if (kDebugMode) {
        if (resolved.isEmpty) {
          debugPrint('[PRODUCT_ALTERNATIVES_FETCH_EMPTY] orderId=$orderId');
        } else {
          debugPrint(
              '[PRODUCT_ALTERNATIVES_FETCH_SUCCESS] orderId=$orderId count=${resolved.length}');
        }
      }
      if (mounted) {
        setState(() {
          _productAlternativesByOrderId[orderId] = resolved;
          _productAlternativesLoaded.add(orderId);
        });
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[PRODUCT_ALTERNATIVES_FETCH_EMPTY] orderId=$orderId');
      }
      if (mounted) {
        setState(() {
          _productAlternativesByOrderId[orderId] = <Item>[];
          _productAlternativesLoaded.add(orderId);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _productAlternativesLoading.remove(orderId);
        });
      }
    }
  }

  int? _resolveOrderCategoryId(List<OrderDetailsModel> orderDetailsList) {
    for (final OrderDetailsModel detail in orderDetailsList) {
      final int? directCategoryId = detail.itemDetails?.categoryId;
      if (directCategoryId != null && directCategoryId > 0) {
        return directCategoryId;
      }
      final List<CategoryIds>? categoryIds = detail.itemDetails?.categoryIds;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        final int? nestedCategoryId = categoryIds.first.id;
        if (nestedCategoryId != null && nestedCategoryId > 0) {
          return nestedCategoryId;
        }
      }
    }
    return null;
  }

  Set<int> _extractOrderedItemIds(List<OrderDetailsModel> orderDetailsList) {
    final Set<int> ids = <int>{};
    for (final OrderDetailsModel detail in orderDetailsList) {
      if (detail.itemId != null) {
        ids.add(detail.itemId!);
      }
      if (detail.itemDetails?.id != null) {
        ids.add(detail.itemDetails!.id!);
      }
    }
    return ids;
  }

  String _normalizeModuleType(String? moduleType) {
    if (moduleType == null) {
      return '';
    }
    return moduleType
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
  }

  String _resolveOrderModuleTypeForRecovery(OrderModel order) {
    final String direct = _normalizeModuleType(order.moduleType);
    if (direct.isNotEmpty && direct != 'null') {
      return direct;
    }
    final int? storeModuleId = order.store?.moduleId;
    if (storeModuleId != null) {
      final SplashController splashController = Get.find<SplashController>();
      final List<dynamic> modules = splashController.moduleList ?? <dynamic>[];
      for (final dynamic module in modules) {
        final int? id = module?.id is int ? module.id as int : null;
        if (id == storeModuleId) {
          final String resolved = _normalizeModuleType(module?.moduleType?.toString());
          if (resolved.isNotEmpty) {
            return resolved;
          }
          break;
        }
      }
      if (storeModuleId == 7) {
        return 'grocery';
      }
    }
    final String storeName = _normalizeModuleType(order.store?.name);
    if (storeName.contains('hypershella') || storeName.contains('هايبرشله')) {
      return 'ecommerce';
    }
    return '';
  }

  bool _isRestaurantModuleType(String moduleType) {
    return moduleType == 'food' ||
        moduleType == 'restaurant' ||
        moduleType == 'cafe';
  }

  bool _isEcommerceModuleType(
    String moduleType, {
    int? storeModuleId,
    String? storeName,
  }) {
    final String normalizedName = _normalizeModuleType(storeName);
    final bool matchedByName = normalizedName.contains('هايبرشله') ||
        normalizedName.contains('شله') ||
        normalizedName.contains('hypershella') ||
        normalizedName.contains('shellamarket') ||
        normalizedName.contains('market');
    return moduleType == 'ecommerce' ||
        moduleType == 'grocery' ||
        moduleType == 'pharmacy' ||
        moduleType == 'shop' ||
        moduleType == 'store' ||
        storeModuleId == 3 ||
        matchedByName;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final dynamic value in values) {
      if (value == null) continue;
      final String text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') continue;
      return text;
    }
    return null;
  }

  Widget _buildAlternativeStoreTile(Map<String, dynamic> store) {
    final int? storeId =
        int.tryParse('${store['id'] ?? store['store_id'] ?? ''}');
    final String name =
        '${store['name'] ?? store['store_name'] ?? ''}'.trim();
    final String? logoUrl = _firstNonEmptyString(<dynamic>[
      store['logo_full_url'],
      store['logoFullUrl'],
      store['cover_photo_full_url'],
      store['coverPhotoFullUrl'],
      store['image_full_url'],
      store['image'],
      store['logo'],
      store['cover_photo'],
    ]);

    double toDouble(dynamic v) =>
        v == null ? 0 : (double.tryParse('$v') ?? 0);
    bool toBool(dynamic v) =>
        v == true || v == 1 || v == '1' || v == 'true';

    final double rating = toDouble(store['avg_rating'] ?? store['rating']);
    final double distance =
        toDouble(store['distance'] ?? store['distance_metres']);
    final bool freeDelivery = toBool(store['free_delivery']);
    final String? deliveryTime =
        '${store['delivery_time'] ?? ''}'.trim().isEmpty
            ? null
            : '${store['delivery_time']}';

    // Unified store card (same design as every other store list in the app).
    return StoreListCard(
      name: name.isEmpty ? '#${storeId ?? ''}' : name,
      logo: logoUrl,
      rating: rating,
      distanceMetres: distance,
      deliveryTime: deliveryTime,
      freeDelivery: freeDelivery,
      onTap: storeId == null
          ? null
          : () {
              final int? targetModuleId = int.tryParse(
                '${store['module_id'] ?? store['moduleId'] ?? ''}',
              );
              // Open the SAME unified storefront the rest of the app uses, so
              // the store page looks identical no matter where it was opened.
              Get.to<void>(
                () => MarketStoreScreen(
                  storeId: storeId,
                  moduleId: targetModuleId ?? 3,
                  name: name.isEmpty ? null : name,
                  logo: logoUrl,
                  rating: rating,
                  freeDelivery: freeDelivery,
                  deliveryTime: deliveryTime,
                  distance: distance,
                  useCoverHeader: true,
                ),
              );
            },
    );
  }

  Widget _buildAlternativeProductTile(Item item) {
    final String? imageUrl = _firstNonEmptyString(<dynamic>[
      item.imageFullUrl,
      item.imagesFullUrl != null && item.imagesFullUrl!.isNotEmpty
          ? item.imagesFullUrl!.first
          : null,
    ]);
    final ThemeData theme = Theme.of(context);
    final Widget thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: SizedBox(
        width: 44,
        height: 44,
        child: imageUrl == null
            ? _buildAlternativePlaceholder(theme)
            : CustomImage(
                image: imageUrl,
                width: 44,
                height: 44,
                errorWidget: _buildAlternativePlaceholder(theme),
              ),
      ),
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: thumbnail,
      title: Text(
        item.name ?? '#${item.id ?? ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.price == null
          ? null
          : Text(
              PriceConverter.convertPrice(item.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: item.id == null
          ? null
          : () {
              if (kDebugMode) {
                debugPrint('[PRODUCT_ALTERNATIVES_TAP] itemId=${item.id}');
              }
              Get.toNamed(
                RouteHelper.getItemDetailsRoute(item.id, false),
              );
            },
    );
  }

  Widget _buildAlternativePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        size: 22,
        color: theme.disabledColor,
      ),
    );
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
