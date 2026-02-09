// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/screens/order_details_screen.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import '../../../common/widgets/loading/loading.dart';

class OrderViewWidget extends StatelessWidget {
  final int isRunning;

  const OrderViewWidget({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    print('$isRunning isRunning');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<OrderController>(builder: (orderController) {
        PaginatedOrderModel? paginatedOrderModel;

        if (isRunning == 0) {
          paginatedOrderModel = orderController.runningOrderModel;
        } else if (isRunning == 1) {
          paginatedOrderModel = orderController.scheduleOrderModel;
        } else {
          paginatedOrderModel = orderController.historyOrderModel;
        }

        if (orderController.Order_isLoading == true) {
          return const Center(child: LoadingWidget());
        }

        if (orderController.Order_isLoading) {
          return const Center(child: LoadingWidget());
        }

        if (paginatedOrderModel == null ||
            paginatedOrderModel.orders == null ||
            paginatedOrderModel.orders!.isEmpty) {
          return Center(child: Text('no_order_found'.tr));
        }

        // Filter out orders with unpaid payment status
        final List<OrderModel> filteredOrders = paginatedOrderModel.orders!
            .where((order) => order.paymentStatus != 'unpaid')
            .toList();

        if (filteredOrders.isEmpty) {
          return Center(child: Text('no_order_found'.tr));
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (isRunning == 0) {
              await orderController.getRunningOrders(1, isUpdate: true);
            } else {
              await orderController.getHistoryOrders(1, isUpdate: true);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 15),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              final bool isParcel = order.orderType == 'parcel';

              return CustomInkWell(
                onTap: () {
                  Get.toNamed(
                    RouteHelper.getOrderDetailsRoute(order.id),
                    arguments: OrderDetailsScreen(
                      orderId: order.id,
                      orderModel: order,
                      contactNumber:
                          order.deliveryAddress?.contactPersonNumber ?? '',
                    ),
                  );
                },
                child: buildOrderCard(
                  context,
                  {
                    'id': order.id,
                    'logo': isParcel
                        ? (order.parcelCategory?.imageFullUrl ?? '')
                        : (order.store?.logoFullUrl ?? ''),
                    'name': isParcel ? 'parcel'.tr : (order.store?.name ?? ''),
                    'date': DateConverter.dateTimeStringToDateTime(
                        order.createdAt ?? ''),
                    'status': order.orderStatus?.tr ?? '',
                    'itemsCount': order.detailsCount ?? 0,
                    'isParcel': isParcel,
                    'contact_number':
                        order.deliveryAddress?.contactPersonNumber ?? '',
                  },
                  isRunning: isRunning,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget buildOrderCard(BuildContext context, Map<String, dynamic> order,
      {required int isRunning}) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          height: 66,
          width: MediaQuery.of(context).size.width,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImage(
                  image: order['logo'] as String? ?? '',
                  height: 66,
                  width: 65,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            order['name'] as String? ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${order["id"]?.toString() ?? ""}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['date'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: buildOrderButtons(context, order, isRunning: isRunning),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOrderButtons(BuildContext context, Map<String, dynamic> order,
      {required int isRunning}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ),
          child: Text(
            order['status'] as String? ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (isRunning != 2)
          InkWell(
            onTap: () {
              Get.toNamed(
                RouteHelper.getOrderTrackingRoute(
                    order['id'] as int?, order['contact_number'] as String?),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: Theme.of(context)
                          .extension<CustomThemeExtension>()
                          ?.yellow_Color ??
                      const Color(0xFFFA9D2B),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (order['isParcel'] as bool?) == true ? 'track_delivery'.tr : 'track_order'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    Images.tracking,
                    height: 15,
                    width: 15,
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }
}
