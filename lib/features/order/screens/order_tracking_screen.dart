// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/widgets/live_tracking_map.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/features/order/widgets/track_details_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sixam_mart/util/styles.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<OrderController>(builder: (orderController) {
        final OrderModel? track = orderController.trackModel;

        if (track == null) {
          return const Center(child: LoadingWidget());
        }

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
                      if ((track.orderStatus ?? '').toLowerCase() == 'delivered')
                        _DeliveredCard(orderId: widget.orderID),
                      TrackDetailsViewWidget(
                        status: track.orderStatus,
                        track: track,
                        showChatPermission: showChatPermission,
                        callback: () async {
                          _timer?.cancel();
                          await Get.toNamed(RouteHelper.getChatRoute(
                            notificationBody: NotificationBodyModel(
                              adminId: 0,
                              orderId: int.parse(widget.orderID!),
                            ),
                            user: User(id: 0, fName: 'المسئول', lName: ''),
                          ));
                          _startApiCall();
                        },
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
