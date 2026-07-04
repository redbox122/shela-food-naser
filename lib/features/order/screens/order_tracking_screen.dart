// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_messaging/firebase_messaging.dart';
// Voice call (additive) — in-app call button beside the driver contact button.
import 'package:sixam_mart/features/call/data/models/call_model.dart';
import 'package:sixam_mart/features/call/presentation/widgets/call_button.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/widgets/arabic_address_text.dart';
import 'package:sixam_mart/features/order/widgets/live_tracking_map.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../common/widgets/loading/loading.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderID;
  final String? contactNumber;
  const OrderTrackingScreen(
      {super.key, required this.orderID, this.contactNumber});

  @override
  OrderTrackingScreenState createState() => OrderTrackingScreenState();
}

class OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _timer;
  bool showChatPermission = true;

  void _loadData() async {
    await Get.find<OrderController>().trackOrder(
      widget.orderID,
      null,
      true,
      contactNumber: widget.contactNumber,
      preserveTrackModel: true,
    );
  }

  void _startApiCall() {
    _timer?.cancel();
    // Poll a touch faster than before so the live driver marker stays fresh.
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      final route = ModalRoute.of(context);
      if (!mounted || route?.isCurrent != true) {
        return;
      }
      final OrderController orderController = Get.find<OrderController>();
      if (_isOrderInTerminalState(orderController.trackModel)) {
        timer.cancel();
        return;
      }
      orderController.timerTrackOrder(widget.orderID.toString(),
          contactNumber: widget.contactNumber);
      if (_isOrderInTerminalState(orderController.trackModel)) {
        timer.cancel();
      }
    });
  }

  bool _isOrderInTerminalState(OrderModel? order) {
    if (order == null || order.id?.toString() != widget.orderID.toString()) {
      return false;
    }
    final String orderStatus = (order.orderStatus ?? '').toLowerCase();
    final String paymentStatus = (order.paymentStatus ?? '').toLowerCase();
    const Set<String> terminalOrderStatuses = <String>{
      'delivered',
      'canceled',
      'cancelled',
      'failed',
      'refunded',
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
    _loadData();
    _startApiCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Last order status we showed an in-app banner for — prevents re-notifying the
  // same status on every rebuild/poll.
  String? _lastNotifiedStatus;

  /// Shows an in-app banner once per real status change, with a friendly message.
  void _maybeNotifyStatusChange(OrderModel track) {
    final status = (track.orderStatus ?? '').toLowerCase();
    if (status.isEmpty) return;
    if (_lastNotifiedStatus == null) {
      // First load — adopt current status silently (no banner on open).
      _lastNotifiedStatus = status;
      return;
    }
    if (status == _lastNotifiedStatus) return;
    _lastNotifiedStatus = status;

    final String? msg =
        _notificationText(status, (track.deliveryMan?.fName ?? '').trim());
    if (msg == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.snackbar(
        _statusTitle(status),
        msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Theme.of(context).primaryColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 14,
        icon: const Icon(Icons.notifications_active, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    });
  }

  /// Opens an in-app chat (driver or store, per the passed body), pausing the
  /// poll timer while away and resuming on return.
  Future<void> _openChat(NotificationBodyModel body) async {
    _timer?.cancel();
    await Get.toNamed(RouteHelper.getChatRoute(notificationBody: body));
    _startApiCall();
  }

  bool _showOtp(OrderModel track) {
    final s = (track.orderStatus ?? '').toLowerCase();
    return (track.otp ?? '').isNotEmpty &&
        track.orderType != 'take_away' &&
        (s == 'processing' ||
            s == 'handover' ||
            s == 'picked_up' ||
            s == 'on_the_way' ||
            s == 'accepted' ||
            s == 'confirmed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<OrderController>(builder: (orderController) {
        final OrderModel? track = orderController.trackModel;

        if (track == null) {
          return const Center(child: LoadingWidget());
        }

        _maybeNotifyStatusChange(track);

        if (track.orderType != 'parcel') {
          if (track.store?.storeBusinessModel == 'commission') {
            showChatPermission = true;
          } else if (track.store?.storeSubscription != null &&
              track.store?.storeBusinessModel == 'subscription') {
            showChatPermission = track.store!.storeSubscription!.chat == 1;
          } else {
            showChatPermission = false;
          }
        } else {
          showChatPermission = AuthHelper.isLoggedIn();
        }

        return Stack(
          children: [
            // ── Live map fills the screen; the sheet floats over its lower half.
            Positioned.fill(child: LiveTrackingMap(track: track)),

            // Top bar: back + help.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Get.back<void>(),
                    ),
                    _CircleButton(
                      icon: Icons.help_outline,
                      onTap: () => _showHelpSheet(context, track),
                    ),
                  ],
                ),
              ),
            ),

            // "Updated" pulse when a websocket/poll refresh lands.
            if (orderController.orderUpdated.value)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('backend_status_updated'.tr,
                            style: robotoMedium.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeSmall)),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Draggable status sheet.
            DraggableScrollableSheet(
              initialChildSize: 0.42,
              minChildSize: 0.18,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeSmall,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeLarge),
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const _NotificationsBanner(),
                      _StatusHeader(track: track),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _IconStepper(status: track.orderStatus),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      const _DeliveryGuaranteeCard(),
                      if (_showOtp(track))
                        _OtpCard(otp: track.otp!),
                      if ((track.orderStatus ?? '').toLowerCase() == 'delivered')
                        _DeliveredCard(orderId: widget.orderID),
                      _DeliveryDetailsSection(
                        track: track,
                        orderId: int.tryParse(widget.orderID ?? ''),
                        showChat: showChatPermission,
                        onChat: _openChat,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _ReceiptCard(track: track),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

/// Big status title + estimated-time-of-arrival badge.
class _StatusHeader extends StatelessWidget {
  final OrderModel track;
  _StatusHeader({required this.track});

  @override
  Widget build(BuildContext context) {
    final status = (track.orderStatus ?? '').toLowerCase();
    final int? eta = _etaMinutes(track);
    final bool showEta = eta != null &&
        status != 'delivered' &&
        status != 'canceled' &&
        status != 'failed' &&
        status != 'refunded';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_statusTitle(status),
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: 2),
              Text(_statusMessage(status, track.orderType == 'take_away'),
                  style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeSmall)),
            ],
          ),
        ),
        if (showEta)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('$eta',
                    style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge,
                        color: Theme.of(context).primaryColor)),
                Text('minutes'.tr,
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).primaryColor)),
              ],
            ),
          ),
      ],
    );
  }
}

String _statusTitle(String status) {
  switch (status) {
    case 'pending':
      return 'order_placed'.tr;
    case 'accepted':
    case 'confirmed':
      return 'order_confirmed'.tr;
    case 'processing':
      return 'preparing_item'.tr;
    case 'handover':
    case 'picked_up':
    case 'on_the_way':
      return 'delivery_on_the_way'.tr;
    case 'delivered':
      return 'delivered'.tr;
    case 'canceled':
    case 'cancelled':
      return 'order_canceled'.tr;
    default:
      return 'order_tracking'.tr;
  }
}

/// Friendly in-app notification copy fired on each status change.
String? _notificationText(String status, String driverName) {
  final bool isArabic = Get.locale?.languageCode == 'ar';
  switch (status) {
    case 'pending':
      return isArabic
          ? 'ord_received_awaiting'.tr
          : 'Order received, waiting for store confirmation';
    case 'accepted':
    case 'confirmed':
      return isArabic ? 'ord_store_confirmed'.tr : 'The store confirmed your order ✅';
    case 'processing':
      return isArabic
          ? 'ord_store_preparing2'.tr
          : 'The store is preparing your order 👨‍🍳';
    case 'handover':
      return isArabic
          ? '${driverName.isEmpty ? 'ord_driver'.tr : driverName} في طريقه لاستلام طلبك 🛵'
          : '${driverName.isEmpty ? 'The courier' : driverName} is picking up your order 🛵';
    case 'picked_up':
    case 'on_the_way':
      return isArabic ? 'ord_on_the_way'.tr : 'Your order is on the way';
    case 'delivered':
      return isArabic
          ? 'ord_delivered_rate'.tr
          : 'Your order was delivered 🎉 — rate your experience';
    default:
      return null;
  }
}

String _statusMessage(String status, bool takeAway) {
  final bool isArabic = Get.locale?.languageCode == 'ar';
  switch (status) {
    case 'pending':
      return isArabic ? 'ord_awaiting_store'.tr : 'Waiting for store confirmation';
    case 'accepted':
    case 'confirmed':
      return isArabic ? 'ord_order_confirmed'.tr : 'Your order is confirmed';
    case 'processing':
      return isArabic ? 'ord_store_preparing'.tr : 'The store is preparing your order';
    case 'handover':
    case 'picked_up':
    case 'on_the_way':
      return takeAway
          ? (isArabic ? 'ord_ready_pickup'.tr : 'Your order is ready')
          : (isArabic ? 'ord_driver_on_way'.tr : 'Your courier is on the way');
    case 'delivered':
      return isArabic ? 'ord_delivered_success'.tr : 'Your order was delivered 🎉';
    default:
      return '';
  }
}

/// Estimated minutes to delivery. Driver→customer once on the way, otherwise a
/// prep buffer + store→customer travel. Null when delivered/closed or unknown.
int? _etaMinutes(OrderModel track) {
  final status = (track.orderStatus ?? '').toLowerCase();
  if (status == 'delivered' ||
      status == 'canceled' ||
      status == 'failed' ||
      status == 'refunded') {
    return null;
  }

  LatLng? p(String? la, String? ln) {
    final a = double.tryParse(la ?? ''), b = double.tryParse(ln ?? '');
    if (a == null || b == null || (a == 0 && b == 0)) return null;
    return LatLng(a, b);
  }

  final store = p(track.store?.latitude, track.store?.longitude);
  final customer =
      p(track.deliveryAddress?.latitude, track.deliveryAddress?.longitude);
  final driver = p(track.deliveryMan?.lat, track.deliveryMan?.lng);

  const double speedKmh = 25; // average city driving speed
  final bool onTheWay =
      status == 'picked_up' || status == 'handover' || status == 'on_the_way';

  if (onTheWay && driver != null && customer != null) {
    final km = _distanceKm(driver, customer);
    return math.max(1, (km / speedKmh * 60).ceil());
  }

  // Before pickup: prep time (if any) + travel store→customer.
  int prep = 0;
  if (track.processingTime != null && track.processingTime! > 0) {
    // processing_time is stored in minutes in most modules; clamp to sane range.
    prep = math.min(track.processingTime!, 90);
  }
  if (store != null && customer != null) {
    final km = _distanceKm(store, customer);
    return math.max(1, prep + (km / speedKmh * 60).ceil());
  }
  return prep > 0 ? prep : null;
}

double _distanceKm(LatLng a, LatLng b) {
  const double r = 6371; // km
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _rad(double deg) => deg * math.pi / 180;

/// Signature 4-icon progress bar (receipt → store → courier → home). Stages
/// fill with Shella green as the order advances; the connector before a reached
/// stage is coloured too. RTL: the first stage (order placed) sits on the right.
class _IconStepper extends StatelessWidget {
  final String? status;
  const _IconStepper({required this.status});

  /// 0 placed/confirmed · 1 preparing · 2 on the way · 3 delivered.
  int get _stage {
    switch ((status ?? '').toLowerCase()) {
      case 'pending':
      case 'accepted':
      case 'confirmed':
        return 0;
      case 'processing':
        return 1;
      case 'handover':
      case 'picked_up':
      case 'on_the_way':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int stage = _stage;
    final Color active = Theme.of(context).primaryColor;
    final Color pending =
        Theme.of(context).disabledColor.withValues(alpha: 0.35);

    const stages = <_IconStep>[
      _IconStep(Icons.receipt_long, 'order_placed'),
      _IconStep(Icons.storefront, 'preparing_item'),
      _IconStep(Icons.delivery_dining, 'delivery_on_the_way'),
      _IconStep(Icons.home_rounded, 'delivered'),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final bool done = stage > i ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(top: 22),
              decoration: BoxDecoration(
                color: done ? active : pending,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final int idx = i ~/ 2;
        final bool reached = idx <= stage;
        final Color c = reached ? active : pending;
        return SizedBox(
          width: 62,
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: reached ? active : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2),
                ),
                child: Icon(stages[idx].icon,
                    size: 22, color: reached ? Colors.white : c),
              ),
              const SizedBox(height: 6),
              Text(
                stages[idx].labelKey.tr,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: idx == stage ? FontWeight.bold : FontWeight.w500,
                  color: reached ? active : pending,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _IconStep {
  final IconData icon;
  final String labelKey;
  const _IconStep(this.icon, this.labelKey);
}

/// Prompts the customer to enable push notifications so they receive order
/// progress updates. Hides itself once notifications are authorized.
class _NotificationsBanner extends StatefulWidget {
  const _NotificationsBanner();

  @override
  State<_NotificationsBanner> createState() => _NotificationsBannerState();
}

class _NotificationsBannerState extends State<_NotificationsBanner> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) {
        setState(() => _show =
            settings.authorizationStatus != AuthorizationStatus.authorized);
      }
    } catch (_) {/* keep hidden */}
  }

  Future<void> _enable() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (mounted) {
        setState(() => _show =
            settings.authorizationStatus != AuthorizationStatus.authorized);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final bool isArabic = Get.locale?.languageCode == 'ar';
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.orange),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              isArabic
                  ? 'ord_enable_notif'.tr
                  : 'Enable notifications for order updates',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ),
          TextButton(
            onPressed: _enable,
            child: Text(isArabic ? 'ord_enable'.tr : 'Enable',
                style: robotoBold.copyWith(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

/// Trust element: a green "on-time delivery guarantee" card.
class _DeliveryGuaranteeCard extends StatelessWidget {
  const _DeliveryGuaranteeCard();

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Get.locale?.languageCode == 'ar';
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: Theme.of(context).primaryColor, size: 26),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'ord_ontime_guarantee'.tr
                      : 'On-time delivery guarantee',
                  style: robotoBold.copyWith(
                      color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'ord_late_compensation'.tr
                      : 'If your order is late, we’ll make it up with a coupon',
                  style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebration + rate CTA shown once the order is delivered.
class _DeliveredCard extends StatelessWidget {
  final String? orderId;
  const _DeliveredCard({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 26)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              Get.locale?.languageCode == 'ar'
                  ? 'ord_arrived_rate'.tr
                  : 'Delivered! We’d love your rating',
              style: robotoMedium,
            ),
          ),
          TextButton(
            onPressed: orderId == null
                ? null
                : () => Get.toNamed(
                    RouteHelper.getOrderDetailsRoute(int.tryParse(orderId!))),
            child: Text('rate_review'.tr,
                style: robotoBold.copyWith(
                    color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }
}

/// Professional delivery details: store info card, a clean driver card (avatar ·
/// name · rating · contact) when a courier is assigned (a "not assigned yet"
/// pill before), the trip distance, and a tidy "deliver to" address row. Each
/// contact button opens a unified options sheet (WhatsApp · call · in-app chat).
class _DeliveryDetailsSection extends StatelessWidget {
  final OrderModel track;
  final int? orderId;
  final bool showChat;
  final Future<void> Function(NotificationBodyModel) onChat;
  _DeliveryDetailsSection(
      {required this.track,
      required this.orderId,
      required this.showChat,
      required this.onChat});

  bool get _takeAway => track.orderType == 'take_away';

  @override
  Widget build(BuildContext context) {
    final driver = track.deliveryMan;
    final bool hasDriver = driver != null;
    final status = (track.orderStatus ?? '').toLowerCase();
    final bool preDriver = !_takeAway &&
        !hasDriver &&
        status != 'delivered' &&
        status != 'canceled';
    final String? distance = _tripDistanceText(track);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Store information.
        if (track.store != null) ...[
          Text('store_information'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _StoreInfoCard(store: track.store!),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        // ── Trip distance (validated; never drawn from 0,0 / invalid coords).
        if (distance != null) ...[
          _InfoChipRow(icon: Icons.route, label: 'distance'.tr, value: distance),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        // ── Courier.
        if (hasDriver && !_takeAway) ...[
          Text('delivery_man'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _ContactCard(
            name: '${driver.fName ?? ''} ${driver.lName ?? ''}'.trim(),
            fallbackName: 'delivery_man'.tr,
            image: driver.imageFullUrl,
            subtitle: driver.vehicleType,
            rating: driver.avgRating,
            ratingCount: driver.ratingCount,
            circular: true,
            showChat: showChat,
            // In-app voice call (Agora) — added beside the existing contact
            // button, which is kept as-is.
            leadingAction: CallButton(
              orderId: orderId ?? 0,
              customerId: null,
              driverId: driver.id,
              peer: CallPeer(
                name: '${driver.fName ?? ''} ${driver.lName ?? ''}'.trim(),
                imageUrl: driver.imageFullUrl,
                vehicleNumber: driver.vehicleType,
              ),
              size: 40,
            ),
            onContact: () => _showTrackContactSheet(
              context,
              phone: driver.phone,
              showChat: showChat,
              onChat: () => onChat(NotificationBodyModel(
                  orderId: orderId, deliverymanId: driver.id)),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],
        if (preDriver) ...[
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Row(
              children: [
                Icon(Icons.delivery_dining,
                    color: Theme.of(context).hintColor, size: 22),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text('delivery_man_not_assigned'.tr,
                      style: robotoMedium.copyWith(
                          color: Theme.of(context).hintColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        // "Deliver to" address row (or pickup store for take-away). Rendered in
        // Arabic via reverse-geocoding when the stored address is English.
        _AddressRow(
          icon: _takeAway ? Icons.storefront : Icons.location_on,
          title: _takeAway ? 'store'.tr : 'delivery_address'.tr,
          subtitle: _takeAway
              ? (track.store?.address ?? '')
              : (track.deliveryAddress?.address ?? ''),
          lat: _takeAway
              ? track.store?.latitude
              : track.deliveryAddress?.latitude,
          lng: _takeAway
              ? track.store?.longitude
              : track.deliveryAddress?.longitude,
        ),
      ],
    );
  }
}

/// Store info card: logo · name · rating · address + a contact button.
class _StoreInfoCard extends StatelessWidget {
  final Store store;
  const _StoreInfoCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomImage(
                  image: store.logoFullUrl ?? '',
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold),
                    const SizedBox(height: 2),
                    RatingBar(
                        rating: store.avgRating ?? 0,
                        size: 12,
                        ratingCount: store.ratingCount),
                  ],
                ),
              ),
              // Only the location/directions button on the store card — no chat
              // with the merchant.
              _ActionButton(
                icon: Icons.directions_outlined,
                color: Theme.of(context).primaryColor,
                onTap: () => _openDirections(store.latitude, store.longitude),
              ),
            ],
          ),
          if ((store.address ?? '').isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Theme.of(context).hintColor),
                const SizedBox(width: 4),
                Expanded(
                  child: ArabicAddressText(
                    fallback: store.address!,
                    lat: store.latitude,
                    lng: store.longitude,
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openDirections(String? lat, String? lng) async {
  final a = double.tryParse(lat ?? ''), b = double.tryParse(lng ?? '');
  if (a == null || b == null || (a == 0 && b == 0)) return;
  final url = 'https://www.google.com/maps/dir/?api=1&destination=$a,$b&mode=d';
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  } else {
    showCustomSnackBar('unable_to_launch_google_map'.tr);
  }
}

/// Validated trip distance store→customer. Returns null when either endpoint is
/// missing / (0,0) / implausibly far (guards against flipped or empty coords).
String? _tripDistanceText(OrderModel track) {
  LatLng? p(String? la, String? ln) {
    final a = double.tryParse(la ?? ''), b = double.tryParse(ln ?? '');
    if (a == null || b == null || (a == 0 && b == 0)) return null;
    if (a.abs() > 90 || b.abs() > 180) return null; // flipped/invalid
    return LatLng(a, b);
  }

  final store = p(track.store?.latitude, track.store?.longitude);
  final customer =
      p(track.deliveryAddress?.latitude, track.deliveryAddress?.longitude);
  if (store == null || customer == null) return null;
  final km = _distanceKm(store, customer);
  if (km <= 0 || km > 300) return null; // sanity cap for a delivery
  final bool isArabic = Get.locale?.languageCode == 'ar';
  if (km < 1) return '${(km * 1000).round()} ${isArabic ? 'ord_meter'.tr : 'm'}';
  return '${km.toStringAsFixed(1)} ${isArabic ? 'ord_km'.tr : 'km'}';
}

/// Unified contact options sheet: WhatsApp · phone call · in-app chat. Each row
/// appears only when it is usable (phone present / chat allowed & assigned).
void _showTrackContactSheet(
  BuildContext context, {
  required String? phone,
  required bool showChat,
  required VoidCallback onChat,
}) {
  final String clean = (phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('contact_options'.tr, style: robotoBold),
            const SizedBox(height: 6),
            if (clean.isNotEmpty)
              _ContactTile(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                label: 'whatsapp'.tr,
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = 'https://wa.me/$clean';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url,
                        mode: LaunchMode.externalApplication);
                  } else {
                    showCustomSnackBar('${'can_not_launch'.tr} WhatsApp');
                  }
                },
              ),
            if (clean.isNotEmpty)
              _ContactTile(
                icon: Icons.call,
                color: const Color(0xFF1F7A35),
                label: 'call'.tr,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (await canLaunchUrlString('tel:$clean')) {
                    await launchUrlString('tel:$clean',
                        mode: LaunchMode.externalApplication);
                  } else {
                    showCustomSnackBar('${'can_not_launch'.tr} $clean');
                  }
                },
              ),
            if (showChat)
              _ContactTile(
                icon: Icons.chat_bubble_outline,
                color: Theme.of(ctx).primaryColor,
                label: 'in_app_chat'.tr,
                onTap: () {
                  Navigator.pop(ctx);
                  onChat();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ContactTile(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: robotoRegular),
      onTap: onTap,
    );
  }
}

/// Reusable contact row card (avatar · name · rating · single contact button).
class _ContactCard extends StatelessWidget {
  final String name;
  final String fallbackName;
  final String? image;
  final String? subtitle;
  final double? rating;
  final int? ratingCount;
  final bool circular;
  final bool showChat;
  final VoidCallback onContact;
  // Optional extra action rendered before the contact button (e.g. a voice-call
  // button). Null keeps the existing single-button layout unchanged.
  final Widget? leadingAction;
  const _ContactCard({
    required this.name,
    required this.fallbackName,
    required this.image,
    this.subtitle,
    required this.rating,
    required this.ratingCount,
    required this.circular,
    required this.showChat,
    required this.onContact,
    this.leadingAction,
  });

  @override
  Widget build(BuildContext context) {
    final img = CustomImage(
        image: image ?? '', height: 50, width: 50, fit: BoxFit.cover);
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          circular
              ? ClipOval(child: img)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10), child: img),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? fallbackName : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoBold),
                if ((subtitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.two_wheeler,
                          size: 13, color: Theme.of(context).hintColor),
                      const SizedBox(width: 3),
                      Text(subtitle!,
                          style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).hintColor)),
                    ],
                  ),
                ],
                const SizedBox(height: 2),
                RatingBar(
                    rating: rating ?? 0, size: 12, ratingCount: ratingCount),
              ],
            ),
          ),
          if (leadingAction != null) ...[
            leadingAction!,
            const SizedBox(width: Dimensions.paddingSizeSmall),
          ],
          _ActionButton(
            icon: Icons.headset_mic_outlined,
            color: Theme.of(context).primaryColor,
            onTap: onContact,
          ),
        ],
      ),
    );
  }
}

/// A labelled value chip row, e.g. "🛣 المسافة  3.4 كم".
class _InfoChipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChipRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text(label, style: robotoRegular),
          const Spacer(),
          Text(value,
              style:
                  robotoBold.copyWith(color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? lat;
  final String? lng;
  const _AddressRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.lat,
      this.lng});

  @override
  Widget build(BuildContext context) {
    if (subtitle.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor)),
                const SizedBox(height: 2),
                ArabicAddressText(
                  fallback: subtitle,
                  lat: lat,
                  lng: lng,
                  style: robotoMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent delivery-code (OTP) card — a trust element the customer reads out
/// to the courier on hand-off.
class _OtpCard extends StatelessWidget {
  final String otp;
  const _OtpCard({required this.otp});

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Get.locale?.languageCode == 'ar';
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.78),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 30),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'ord_delivery_code'.tr : 'Delivery code',
                  style: robotoBold.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'ord_give_code_driver2'.tr
                      : 'Give this code to the courier on delivery',
                  style: robotoRegular.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: Dimensions.fontSizeExtraSmall),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              otp,
              style: robotoBold.copyWith(
                color: Theme.of(context).primaryColor,
                fontSize: Dimensions.fontSizeExtraLarge,
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Order help" sheet — ready options + the rule that cancelling after a courier
/// is assigned goes through support only.
void _showHelpSheet(BuildContext context, OrderModel track) {
  final bool isArabic = Get.locale?.languageCode == 'ar';
  final status = (track.orderStatus ?? '').toLowerCase();
  final bool driverAssigned = track.deliveryMan != null;
  final options = isArabic
      ? <String>[
          'ord_how_cancel'.tr,
          'ord_change_items'.tr,
          'ord_change_address_notes'.tr,
          'ord_store_closed'.tr,
          'ord_item_unavailable'.tr,
          'ord_why_not_accepted'.tr,
          'ord_other'.tr,
        ]
      : <String>[
          'How do I cancel my order?',
          'I want to change items',
          'Change address or notes',
          'The store is closed',
          'An item is out of stock',
          'Why wasn’t my order accepted?',
          'Something else',
        ];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).disabledColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(isArabic ? 'ord_order_help'.tr : 'Order help',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            // Order summary line.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${'order'.tr} #${track.id ?? ''} · ${_statusTitle(status)}',
                style: robotoRegular.copyWith(
                    color: Theme.of(ctx).hintColor,
                    fontSize: Dimensions.fontSizeSmall),
              ),
            ),
            const Divider(),
            ...options.map((o) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o, style: robotoRegular),
                  trailing: const Icon(Icons.chevron_left, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(RouteHelper.getSupportRoute());
                  },
                )),
            // Cancel-after-assignment note.
            if (driverAssigned)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'ord_cancel_after_driver'.tr
                            : 'After a courier is assigned, cancellation is via support only',
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Receipt-style order summary: total · delivery fee · payment + a button to the
/// full invoice. Ticket look via a dashed divider.
class _ReceiptCard extends StatelessWidget {
  final OrderModel track;
  _ReceiptCard({required this.track});

  String _money(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Get.locale?.languageCode == 'ar';
    final double total = track.orderAmount ?? 0;
    final double delivery = track.deliveryCharge ?? 0;
    final String pay = (track.paymentMethod ?? '').replaceAll('_', ' ');
    final String cur = isArabic ? 'ord_sar'.tr : 'SAR';

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              children: [
                _row(context, isArabic ? 'ord_delivery_fee'.tr : 'Delivery fee',
                    '${_money(delivery)} $cur'),
                const SizedBox(height: 6),
                _row(
                  context,
                  isArabic ? 'ord_total'.tr : 'Total',
                  '${_money(total)} $cur',
                  bold: true,
                ),
                if (pay.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 18, color: Theme.of(context).hintColor),
                      const SizedBox(width: 6),
                      Text(pay,
                          style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => Get.toNamed(
                RouteHelper.getOrderDetailsRoute(track.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isArabic ? 'ord_order_details'.tr : 'Order details',
                      style: robotoBold.copyWith(
                          color: Theme.of(context).primaryColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_left,
                      size: 20, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold
                ? robotoBold
                : robotoRegular.copyWith(color: Theme.of(context).hintColor)),
        Text(value, style: bold ? robotoBold : robotoMedium),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 22, color: Theme.of(context).iconTheme.color),
        ),
      ),
    );
  }
}
