// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
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

            // Back button.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _CircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Get.back<void>(),
                  ),
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
                      _StatusHeader(track: track),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _HorizontalStepper(
                        status: track.orderStatus,
                        takeAway: track.orderType == 'take_away',
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
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
  const _StatusHeader({required this.track});

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
          ? 'تم استلام طلبك، بانتظار تأكيد المتجر'
          : 'Order received, waiting for store confirmation';
    case 'accepted':
    case 'confirmed':
      return isArabic ? 'أكّد المتجر طلبك ✅' : 'The store confirmed your order ✅';
    case 'processing':
      return isArabic
          ? 'المتجر يجهّز طلبك 👨‍🍳'
          : 'The store is preparing your order 👨‍🍳';
    case 'handover':
      return isArabic
          ? '${driverName.isEmpty ? 'المندوب' : driverName} في طريقه لاستلام طلبك 🛵'
          : '${driverName.isEmpty ? 'The courier' : driverName} is picking up your order 🛵';
    case 'picked_up':
    case 'on_the_way':
      return isArabic ? 'طلبك في الطريق إليك' : 'Your order is on the way';
    case 'delivered':
      return isArabic
          ? 'تم تسليم طلبك، بالهناء والشفاء 🎉 — قيّم تجربتك'
          : 'Your order was delivered 🎉 — rate your experience';
    default:
      return null;
  }
}

String _statusMessage(String status, bool takeAway) {
  final bool isArabic = Get.locale?.languageCode == 'ar';
  switch (status) {
    case 'pending':
      return isArabic ? 'بانتظار تأكيد المتجر' : 'Waiting for store confirmation';
    case 'accepted':
    case 'confirmed':
      return isArabic ? 'تم تأكيد طلبك' : 'Your order is confirmed';
    case 'processing':
      return isArabic ? 'المتجر يجهّز طلبك الآن' : 'The store is preparing your order';
    case 'handover':
    case 'picked_up':
    case 'on_the_way':
      return takeAway
          ? (isArabic ? 'طلبك جاهز للاستلام' : 'Your order is ready')
          : (isArabic ? 'المندوب في الطريق إليك' : 'Your courier is on the way');
    case 'delivered':
      return isArabic ? 'تم توصيل طلبك بنجاح 🎉' : 'Your order was delivered 🎉';
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

/// Compact horizontal 5-step progress bar that mirrors the order status.
class _HorizontalStepper extends StatelessWidget {
  final String? status;
  final bool takeAway;
  const _HorizontalStepper({required this.status, required this.takeAway});

  @override
  Widget build(BuildContext context) {
    final int state = _statusIndex(status, takeAway);
    final bool isArabic = Get.locale?.languageCode == 'ar';
    final List<String> labels = [
      'order_placed'.tr,
      'order_confirmed'.tr,
      'preparing_item'.tr,
      takeAway ? 'ready_for_handover'.tr : 'delivery_on_the_way'.tr,
      takeAway ? (isArabic ? 'تم الاستلام' : 'Received') : 'delivered'.tr,
    ];

    final Color active = Theme.of(context).primaryColor;
    const Color current = Colors.orange;
    final Color pending = Theme.of(context).disabledColor.withValues(alpha: 0.4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length * 2 - 1, (i) {
        // Even indices are nodes; odd indices are the connector lines.
        if (i.isOdd) {
          final int leftNode = i ~/ 2;
          final bool done = state > leftNode;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 26),
              color: done ? active : pending,
            ),
          );
        }
        final int index = i ~/ 2;
        final bool isDone = state >= 0 && index < state;
        final bool isCurrent = state >= 0 && index == state;
        final Color c = isDone ? active : (isCurrent ? current : pending);
        return SizedBox(
          width: 54,
          child: Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone || isCurrent ? c : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : Text('${index + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : c)),
              ),
              const SizedBox(height: 5),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.15,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isDone ? active : (isCurrent ? current : pending),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

int _statusIndex(String? status, bool takeAway) {
  switch (status) {
    case 'pending':
      return 0;
    case 'accepted':
    case 'confirmed':
      return 1;
    case 'processing':
      return 2;
    case 'handover':
      return takeAway ? 3 : 2;
    case 'picked_up':
    case 'on_the_way':
      return 3;
    case 'delivered':
      return 4;
    default:
      return -1;
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
                  ? 'وصل طلبك! يسعدنا تقييمك للتجربة'
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
  const _DeliveryDetailsSection(
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
            rating: driver.avgRating,
            ratingCount: driver.ratingCount,
            circular: true,
            showChat: showChat,
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
  if (km < 1) return '${(km * 1000).round()} ${isArabic ? 'م' : 'm'}';
  return '${km.toStringAsFixed(1)} ${isArabic ? 'كم' : 'km'}';
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
  final double? rating;
  final int? ratingCount;
  final bool circular;
  final bool showChat;
  final VoidCallback onContact;
  const _ContactCard({
    required this.name,
    required this.fallbackName,
    required this.image,
    required this.rating,
    required this.ratingCount,
    required this.circular,
    required this.showChat,
    required this.onContact,
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
                const SizedBox(height: 2),
                RatingBar(
                    rating: rating ?? 0, size: 12, ratingCount: ratingCount),
              ],
            ),
          ),
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
                  isArabic ? 'رمز التسليم' : 'Delivery code',
                  style: robotoBold.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'أعطِ هذا الرمز للسائق عند الاستلام'
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
