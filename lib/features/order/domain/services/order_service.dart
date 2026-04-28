
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/repositories/order_repository_interface.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class OrderService implements OrderServiceInterface {
  final OrderRepositoryInterface orderRepositoryInterface;

  OrderService({required this.orderRepositoryInterface});

  @override
  Future<PaginatedOrderModel?> getRunningOrderList(int offset, bool fromDashboard) async {
    final result = await orderRepositoryInterface.getList(isRunningOrder: true, offset: offset, fromDashboard: fromDashboard);
    return result is PaginatedOrderModel? ? result : null;
  }

  @override
  Future<PaginatedOrderModel?> getHistoryOrderList(int offset) async {
    final result = await orderRepositoryInterface.getList(isHistoryOrder: true, offset: offset);
    return result is PaginatedOrderModel? ? result : null;
  }

  @override
  Future<List<String?>?> getSupportReasonsList() async {
    final result = await orderRepositoryInterface.getList(isSupportReasons: true);
    return result is List<String?>? ? result : null;
  }

  @override
  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID, String? guestId) async {
    final result = await orderRepositoryInterface.get(orderID, guestId: guestId);
    return result is List<OrderDetailsModel>? ? result : null;
  }

  @override
  Future<List<CancellationData>?> getCancelReasons() async {
    final result = await orderRepositoryInterface.getList(isCancelReasons: true);
    return result is List<CancellationData>? ? result : null;
  }

  @override
  Future<List<String?>?> getRefundReasons() async {
    final result = await orderRepositoryInterface.getList(isRefundReasons: true);
    return result is List<String?>? ? result : null;
  }

  @override
  Future<void> submitRefundRequest(
    int selectedReasonIndex,
    List<String?>? refundReasons,
    String note,
    String? orderId,
    XFile? refundImage,
  ) async {
    if (selectedReasonIndex == 0) {
      showCustomSnackBar('please_select_reason'.tr);
    } else {
      final Map<String, String> body = {
        'customer_reason': refundReasons![selectedReasonIndex]!,
        'order_id': orderId!,
        'customer_note': note,
      };
      final Response response = await orderRepositoryInterface.submitRefundRequest(body, refundImage);
      if (response.statusCode == 200) {
        showCustomSnackBar((response.body as Map<String, dynamic>)['message'] as String?, isError: false);
        Get.offAllNamed(RouteHelper.getInitialRoute());
      }
    }
  }

  @override
  Future<Response> trackOrder(String? orderID, String? guestId, {String? contactNumber}) async {
    return await orderRepositoryInterface.trackOrder(orderID, guestId, contactNumber: contactNumber);
  }

  @override
  Future<bool> cancelOrder(String orderID, String? reason, {String? guestId}) async {
    return await orderRepositoryInterface.cancelOrder(orderID, reason, guestId: guestId);
  }

  @override
  OrderModel? prepareOrderModel(PaginatedOrderModel? runningOrderModel, int? orderID) {
    if (runningOrderModel?.orders == null) return null;

    for (final OrderModel order in runningOrderModel!.orders!) {
      if (order.id == orderID) {
        debugPrint('✅ Found order with ID = ${order.id}');
        return order;
      }
    }
    debugPrint('⚠️ Order ID $orderID not found');
    return null;
  }

  @override
  Future<bool> switchToCOD(String? orderID, {String? guestId}) async {
    final Response response = await orderRepositoryInterface.switchToCOD(orderID, guestId: guestId);
    if (response.statusCode == 200) {
      await Get.offAllNamed(RouteHelper.getInitialRoute());
      showCustomSnackBar((response.body as Map<String, dynamic>)['message'] as String?, isError: false);
      return true;
    }
    return false;
  }

  @override
  Future<List<Map<String, dynamic>>> getAlternativeStores(
      {required int orderId, int limit = 5}) async {
    return await orderRepositoryInterface.getAlternativeStores(
        orderId: orderId, limit: limit);
  }

  @override
  void paymentRedirect({
    required String url,
    required bool canRedirect,
    required String? contactNumber,
    required Function onClose,
    required final String? addFundUrl,
    required final String? subscriptionUrl,
    required final String orderID,
    int? storeId,
    required bool createAccount,
    required String guestId,
  }) {
    final bool forOrder = (addFundUrl == '' && addFundUrl!.isEmpty && subscriptionUrl == '' && subscriptionUrl!.isEmpty);
    final bool forSubscription = (subscriptionUrl != null && subscriptionUrl.isNotEmpty && addFundUrl == '' && addFundUrl!.isEmpty);

    if (canRedirect) {
      final bool isSuccess =
          url.startsWith('${AppConstants.baseUrl}/payment-success') || url.startsWith('${AppConstants.baseUrl}/subscription-success');
      final bool isFailed =
          url.startsWith('${AppConstants.baseUrl}/payment-fail') || url.startsWith('${AppConstants.baseUrl}/subscription-fail');
      final bool isCancel =
          url.startsWith('${AppConstants.baseUrl}/payment-cancel') || url.startsWith('${AppConstants.baseUrl}/subscription-cancel');

      if (isSuccess || isFailed || isCancel) {
        canRedirect = false;
        onClose();
      }

      if (forOrder) {
        if (isSuccess || isFailed || isCancel) {
          Get.offNamed(RouteHelper.getOrderSuccessRoute(orderID, contactNumber, createAccount: createAccount, guestId: guestId));
        }
      } else {
        if (isSuccess || isFailed || isCancel) {
          if (Get.currentRoute.contains(RouteHelper.payment)) {
            Get.back();
          }
          if (forSubscription) {
            Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(true);
            Get.find<HomeController>().saveIsStoreRegistrationSharedPref(true);
            Get.offAllNamed(RouteHelper.getSubscriptionSuccessRoute(
              status: isSuccess
                  ? 'success'
                  : isFailed
                      ? 'fail'
                      : 'cancel',
              fromSubscription: true,
              storeId: storeId,
            ));
          } else {
            Get.toNamed(RouteHelper.getWalletRoute(
              fundStatus: isSuccess
                  ? 'success'
                  : isFailed
                      ? 'fail'
                      : 'cancel',
              token: UniqueKey().toString(),
            ));
          }
        }
      }
    }
  }

  // ==============================================================

  @override
  Future<Stream?> connectToOrderWebSocket(String userId) async {
    return await orderRepositoryInterface.connectToOrderWebSocket(userId);
  }

  @override
  void closeWebSocket() {
    orderRepositoryInterface.closeWebSocket();
  }

  // ==============================================================
}
