import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

class OrderBannerViewWidget extends StatelessWidget {
  final OrderModel order;
  final bool ongoing;
  final bool parcel;
  final bool prescriptionOrder;
  final OrderController orderController;

  const OrderBannerViewWidget({
    super.key,
    required this.order,
    required this.ongoing,
    required this.parcel,
    required this.prescriptionOrder,
    required this.orderController,
  });

  String getOrderImage() {
    switch (order.orderStatus) {
      case 'pending':
        return Images.pendingOrder;
      case 'confirmed':
        return Images.confirmedOrder;
      case 'processing':
        return Images.preparingOrder;
      case 'delivered':
        return Images.deliveredOrder;
      case 'handover':
        return Images.handoverOrder;
      default:
        return Images.pendingOrder;
    }
  }

  Widget buildImageOrCover({required bool condition, double height = 160}) {
    return condition
        ? Image.asset(
            getOrderImage(),
            height: height,
            width: double.infinity,
            fit: BoxFit.contain,
          )
        : CustomImage(
            image: '${order.store?.coverPhotoFullUrl}',
            height: height,
            width: double.infinity,
          );
  }

  @override
  Widget build(BuildContext context) {
    final splashController = Get.find<SplashController>();
    final moduleConfig = splashController.getModuleConfig(order.moduleType);

    return Column(children: [
      if (DateConverter.isBeforeTime(order.scheduleAt) && (moduleConfig.newVariation ?? false))
        ongoing
            ? Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    getOrderImage(),
                    fit: BoxFit.contain,
                    height: 200,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(
                  'your_food_will_delivered_within'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateConverter.differenceInMinute(
                                    order.store!.deliveryTime, order.createdAt, order.processingTime, order.scheduleAt) <
                                5
                            ? '1 - 5'
                            : '${DateConverter.differenceInMinute(order.store!.deliveryTime, order.createdAt, order.processingTime, order.scheduleAt) - 5} - '
                                '${DateConverter.differenceInMinute(order.store!.deliveryTime, order.createdAt, order.processingTime, order.scheduleAt)}',
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        'min'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              ])
            : CustomImage(
                image: '${order.store?.coverPhotoFullUrl}',
                height: 150,
                width: double.infinity,
              ),
      if (parcel)
        (ongoing && order.orderStatus == 'pending')
            ? Image.asset(
                Images.pendingOrderDetails,
                height: 160,
                width: double.infinity,
              )
            : CustomImage(
                image: '${order.parcelCategory?.imageFullUrl}',
                height: 160,
              ),
      if (prescriptionOrder) buildImageOrCover(condition: ongoing, height: 180),
      if (orderController.orderDetails!.isNotEmpty) ...[
        if (orderController.orderDetails![0].itemDetails!.moduleType == 'grocery')
          buildImageOrCover(condition: ongoing && order.orderStatus == 'pending', height: 180),
        if (orderController.orderDetails![0].itemDetails!.moduleType == 'pharmacy')
          buildImageOrCover(condition: ongoing && order.orderStatus == 'pending', height: 180),
        if (orderController.orderDetails![0].itemDetails!.moduleType == 'ecommerce')
          buildImageOrCover(condition: ongoing && order.orderStatus == 'pending', height: 180),
      ]
    ]);
  }
}
