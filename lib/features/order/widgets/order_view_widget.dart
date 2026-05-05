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
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import '../../../common/widgets/loading/loading.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class OrderViewWidget extends StatelessWidget {
  final int isRunning;

  const OrderViewWidget({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    debugPrint('[OrderView] build tab=$isRunning');
    if (kDebugMode) {
      appLogger.debug('$isRunning isRunning');
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<OrderController>(builder: (orderController) {
        PaginatedOrderModel? paginatedOrderModel;

        if (isRunning == 0) {
          paginatedOrderModel = orderController.runningOrderModel;
        } else if (isRunning == 1) {
          paginatedOrderModel = orderController.canceledOrderModel;
        } else {
          paginatedOrderModel = orderController.historyOrderModel;
        }
        debugPrint(
          '[OrderView] tab=$isRunning '
          'loading=${orderController.Order_isLoading} '
          'historyLoading=${orderController.isLoadingHistoryOrders} '
          'modelNull=${paginatedOrderModel == null} '
          'ordersCount=${paginatedOrderModel?.orders?.length ?? -1}',
        );

        final bool isHistoryTab = isRunning == 1 || isRunning == 2;
        if (orderController.Order_isLoading == true ||
            (isHistoryTab && orderController.isLoadingHistoryOrders)) {
          debugPrint('[OrderView] tab=$isRunning showing loader');
          return const Center(child: LoadingWidget());
        }
        if (isRunning == 0 && !orderController.hasLoadedRunningOrders) {
          debugPrint('[OrderView] tab=0 waiting first running load');
          return const Center(child: LoadingWidget());
        }

        if (orderController.Order_isLoading) {
          debugPrint(
              '[OrderView] tab=$isRunning showing loader (duplicate guard)');
          return const Center(child: LoadingWidget());
        }
        if (paginatedOrderModel == null && orderController.hasOrderError) {
          return ErrorStateView(
            onRetry: () {
              if (isRunning == 0) {
                orderController.getRunningOrders(1, isUpdate: true);
              } else {
                orderController.getHistoryOrders(1, isUpdate: true);
              }
            },
          );
        }

        if (isHistoryTab &&
            paginatedOrderModel == null &&
            !orderController.hasOrderError) {
          return const Center(child: LoadingWidget());
        }

        if (paginatedOrderModel == null ||
            paginatedOrderModel.orders == null ||
            paginatedOrderModel.orders!.isEmpty) {
          debugPrint(
              '[OrderView] tab=$isRunning empty: model/orders null or empty');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'no_orders_yet'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_orders_yet_subtitle'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Get.toNamed<void>(RouteHelper.getMainRoute('home'));
                    },
                    child: Text(
                      'order_now'.tr,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final List<OrderModel> filteredOrders = isRunning == 0
            ? List<OrderModel>.from(paginatedOrderModel.orders!)
            : paginatedOrderModel.orders!
                .where((order) => order.paymentStatus != 'unpaid')
                .toList();
        debugPrint(
          '[OrderView] tab=$isRunning raw=${paginatedOrderModel.orders!.length} '
          'filtered=${filteredOrders.length}',
        );

        if (filteredOrders.isEmpty) {
          debugPrint(
              '[OrderView] tab=$isRunning empty after paymentStatus filtering');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'no_orders_yet'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_orders_yet_subtitle'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Get.toNamed<void>(RouteHelper.getMainRoute('home'));
                    },
                    child: Text(
                      'order_now'.tr,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            debugPrint('[OrderView] tab=$isRunning pull-to-refresh');
            if (isRunning == 0) {
              await orderController.getRunningOrders(1, isUpdate: true);
            } else {
              await orderController.getHistoryOrders(1, isUpdate: true);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 15, bottom: 100),
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
                        (order.createdAt ?? '')),
                    'status': order.orderStatus?.tr ?? '',
                    'raw_status': order.orderStatus ?? '',
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
          width: MediaQuery.of(context).size.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order['name'] as String? ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: buildOrderButtons(context, order,
                      isRunning: isRunning,
                      orderController: Get.find<OrderController>()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOrderButtons(BuildContext context, Map<String, dynamic> order,
      {required int isRunning, required OrderController orderController}) {
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
            orderController.getOrderStatusLabel(order['raw_status'] as String?),
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (isRunning == 0)
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
                    (order['isParcel'] as bool?) == true
                        ? 'track_delivery'.tr
                        : 'track_order'.tr,
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
