// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/order/widgets/track_details_view_widget.dart';
import 'package:sixam_mart/features/order/widgets/tracking_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final route = ModalRoute.of(context);
      if (!mounted || route?.isCurrent != true) {
        return;
      }
      Get.find<OrderController>().timerTrackOrder(widget.orderID.toString(),
          contactNumber: widget.contactNumber);
    });
  }

  @override
  void initState() {
    super.initState();

    _loadData();
    _startApiCall();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'order_tracking'.tr),
      body: GetBuilder<OrderController>(builder: (orderController) {
        OrderModel? track;

        if (orderController.trackModel != null) {
          track = orderController.trackModel;

          if (track!.orderType != 'parcel') {
            if (track.store!.storeBusinessModel == 'commission') {
              showChatPermission = true;
            } else if (track.store!.storeSubscription != null &&
                track.store!.storeBusinessModel == 'subscription') {
              showChatPermission = track.store!.storeSubscription!.chat == 1;
            } else {
              showChatPermission = false;
            }
          } else {
            showChatPermission = AuthHelper.isLoggedIn();
          }
        }

        return track != null
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FooterView(
                  child: Center(
                    child: SizedBox(
                      width: Dimensions.webMaxWidth,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (orderController.orderUpdated.value)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.refresh,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'backend_status_updated'.tr,
                                      style: robotoBold.copyWith(
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                                height: orderController.orderUpdated.value
                                    ? Dimensions.paddingSizeLarge
                                    : 0),
                            Container(
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeDefault),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'check_order_status'.tr,
                                    style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeLarge),
                                  ),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeSmall),
                                  TrackingStepperWidget(
                                    status: track.orderStatus,
                                    takeAway: track.orderType == 'take_away',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            TrackDetailsViewWidget(
                              status: track.orderStatus,
                              track: track,
                              showChatPermission: showChatPermission,
                              callback: () async {
                                _timer?.cancel();
                                await Get.toNamed(RouteHelper.getChatRoute(
                                  notificationBody: NotificationBodyModel(
                                    deliverymanId: track!.deliveryMan!.id,
                                    orderId: int.parse(widget.orderID!),
                                  ),
                                  user: User(
                                    id: track.deliveryMan!.id,
                                    fName: track.deliveryMan!.fName,
                                    lName: track.deliveryMan!.lName,
                                    imageFullUrl:
                                        track.deliveryMan!.imageFullUrl,
                                  ),
                                ));
                                _startApiCall();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const Center(child: LoadingWidget());
      }),
    );
  }
}
