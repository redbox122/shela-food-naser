import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/order/screens/order_details_screen.dart';

class RunningOrderViewWidget extends StatelessWidget {
  final List<OrderModel> reversOrder;
  final Function onOrderTap;
  final VoidCallback? onClose;
  const RunningOrderViewWidget({
    super.key,
    required this.reversOrder,
    required this.onOrderTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      if (reversOrder.isEmpty) {
        return const SizedBox();
      }
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius : const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.paddingSizeExtraLarge),
            topRight : Radius.circular(Dimensions.paddingSizeExtraLarge),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: Column(children: [

           Center(
            child: Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
              height: 3, width: 40,
              decoration: BoxDecoration(
                  color: Theme.of(context).highlightColor,
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
              ),
            ),
           ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
            ),
            child: Column(
              children: [
                _buildOrderStatusPill(context, reversOrder.first, orderController),
                if (reversOrder.length > 1) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  InkWell(
                    onTap: () => onOrderTap(),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Expanded(
                            child: Text(
                              _buildMoreOrdersLabel(reversOrder.length - 1),
                              style: robotoMedium.copyWith(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
         ]),
     );
    });
  }

  Widget _buildOrderStatusPill(
    BuildContext context,
    OrderModel order,
    OrderController orderController,
  ) {
    final String orderStatus = (order.orderStatus ?? AppConstants.pending).tr;
    final Color statusColor = _getStatusColor(order.orderStatus, context);
    final IconData statusIcon = _getStatusIcon(order.orderStatus);
    final int statusLevel = _getStatusLevel(order.orderStatus);
    return InkWell(
      onTap: () async {
        await Get.toNamed(
          RouteHelper.getOrderDetailsRoute(order.id),
          arguments: OrderDetailsScreen(
            orderId: order.id,
            orderModel: order,
          ),
        );
        if (orderController.showBottomSheet) {
          orderController.showRunningOrders();
        }
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 18),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${'order'.tr} #${order.id}',
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      _buildStatusBadge(context, orderStatus, statusColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'track_order'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusProgress(context, statusLevel: statusLevel),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            if (onClose != null)
              const SizedBox(width: Dimensions.paddingSizeSmall),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? orderStatus, BuildContext context) {
    if (orderStatus == AppConstants.pending) {
      return Colors.orange;
    }
    if (orderStatus == AppConstants.accepted ||
        orderStatus == AppConstants.confirmed ||
        orderStatus == AppConstants.processing) {
      return Colors.blue;
    }
    if (orderStatus == AppConstants.handover ||
        orderStatus == AppConstants.pickedUp ||
        orderStatus == 'out_for_delivery') {
      return Colors.green;
    }
    return Theme.of(context).primaryColor;
  }

  IconData _getStatusIcon(String? orderStatus) {
    if (orderStatus == AppConstants.pending) {
      return Icons.hourglass_top_rounded;
    }
    if (orderStatus == AppConstants.accepted ||
        orderStatus == AppConstants.confirmed ||
        orderStatus == AppConstants.processing) {
      return Icons.restaurant_rounded;
    }
    if (orderStatus == AppConstants.handover ||
        orderStatus == AppConstants.pickedUp ||
        orderStatus == 'out_for_delivery') {
      return Icons.delivery_dining_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String orderStatus,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        orderStatus,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: statusColor,
        ),
      ),
    );
  }

  String _buildMoreOrdersLabel(int extraOrdersCount) {
    return '+$extraOrdersCount ${'other_orders'.tr}';
  }

  int _getStatusLevel(String? orderStatus) {
    if (orderStatus == AppConstants.pending) {
      return 1;
    }
    if (orderStatus == AppConstants.accepted ||
        orderStatus == AppConstants.confirmed ||
        orderStatus == AppConstants.processing) {
      return 2;
    }
    if (orderStatus == AppConstants.handover ||
        orderStatus == AppConstants.pickedUp) {
      return 3;
    }
    if (orderStatus == 'out_for_delivery' ||
        orderStatus == AppConstants.delivered) {
      return 4;
    }
    return 1;
  }

  Widget _buildStatusProgress(BuildContext context, {required int statusLevel}) {
    return Row(
      children: List<Widget>.generate(4, (int index) {
        final bool isCompleted = index < statusLevel;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(
              right: index == 3 ? 0 : Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
        );
      }),
    );
  }
}
