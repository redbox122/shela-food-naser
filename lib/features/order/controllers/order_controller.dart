// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;

  OrderController({required this.orderServiceInterface});

  PaginatedOrderModel? _runningOrderModel;
  PaginatedOrderModel? get runningOrderModel => _runningOrderModel;

  PaginatedOrderModel? _scheduleOrderModel;
  PaginatedOrderModel? get scheduleOrderModel => _scheduleOrderModel;

  PaginatedOrderModel? _historyOrderModel;
  PaginatedOrderModel? get historyOrderModel => _historyOrderModel;

  List<OrderDetailsModel>? _orderDetails;
  List<OrderDetailsModel>? get orderDetails => _orderDetails;

  OrderModel? _trackModel;
  OrderModel? get trackModel => _trackModel;

  bool _Order_isLoading = false;
  bool get Order_isLoading => _Order_isLoading;

  // OrderModel? _track_Model;
  // OrderModel? get track_Model => _track_Model;

  ResponseModel? _responseModel;
  ResponseModel? get responseModel => _responseModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isTimerTrackOrderInProgress = false;

  bool _showCancelled = false;
  bool get showCancelled => _showCancelled;

  bool _showBottomSheet = true;
  bool get showBottomSheet => _showBottomSheet;

  bool _showOneOrder = true;
  bool get showOneOrder => _showOneOrder;

  List<String?>? _refundReasons;
  List<String?>? get refundReasons => _refundReasons;

  int _selectedReasonIndex = 0;
  int get selectedReasonIndex => _selectedReasonIndex;

  XFile? _refundImage;
  XFile? get refundImage => _refundImage;

  String? _cancelReason;
  String? get cancelReason => _cancelReason;

  List<CancellationData>? _orderCancelReasons;
  List<CancellationData>? get orderCancelReasons => _orderCancelReasons;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  List<String?>? _supportReasons;
  List<String?>? get supportReasons => _supportReasons;

  // WebSocket

  // ================================================================================

  StreamSubscription? _subscription;

  RxBool isConnected = false.obs;
  RxBool orderUpdated = false.obs;
  RxString latestMessage = ''.obs;

  static const List<String> _runningStatuses = <String>[
    AppConstants.pending,
    AppConstants.confirmed,
    AppConstants.processing,
    AppConstants.accepted,
    AppConstants.handover,
    AppConstants.pickedUp,
    'out_for_delivery',
    'ongoing',
  ];

  static const List<String> _historyStatuses = <String>[
    AppConstants.delivered,
    'canceled',
    'failed',
    'refund_requested',
    'refunded',
    'refund_request_canceled',
  ];

  bool _isRunningStatus(String? status) {
    if (status == null) return false;
    if (_runningStatuses.contains(status)) return true;
    if (_historyStatuses.contains(status)) return false;
    return true;
  }

  bool _isHistoryStatus(String? status) {
    if (status == null) return false;
    return _historyStatuses.contains(status);
  }

  Future<void> connect(String userId) async {
    if (userId.isEmpty) {
      print('❌ userId is empty. Cannot connect to WebSocket.');
      isConnected.value = false;
      return;
    }

    try {
      await disconnect();

      final Stream? stream =
          await orderServiceInterface.connectToOrderWebSocket(userId);

      if (stream == null) {
        print('⚠️ WebSocket stream is null. No connection established.');
        isConnected.value = false;
        return;
      }

      isConnected.value = true;
      _subscription = stream.listen(
        (data) async {
          latestMessage.value = data.toString();
          orderUpdated.value = true;

          await Future.delayed(const Duration(seconds: 5), () {
            orderUpdated.value = false;
          });

          print('📩 WebSocket Data: $data');
        },
        onError: (Object error) {
          print('❌ WebSocket Error: $error');

          if (error is WebSocketChannelException) {
            print('📛 Detailed Error: ${error.inner}');
          }

          isConnected.value = false;
        },
        onDone: () {
          print('🔌 WebSocket closed');
          isConnected.value = false;
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('⚠️ Failed to connect to WebSocket: $e');
      isConnected.value = false;
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    orderServiceInterface.closeWebSocket();
    isConnected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  // ======

  void expandedUpdate(bool status) {
    _isExpanded = status;
    update();
  }

  void setOrderCancelReason(String? reason) {
    _cancelReason = reason;
    update();
  }

  void selectReason(int index, {bool isUpdate = true}) {
    _selectedReasonIndex = index;
    if (isUpdate) {
      update();
    }
  }

  void showOrders() {
    _showOneOrder = !_showOneOrder;
    update();
  }

  void showRunningOrders({bool canUpdate = true}) {
    _showBottomSheet = !_showBottomSheet;
    if (canUpdate) {
      update();
    }
  }

  void pickRefundImage(bool isRemove) async {
    if (isRemove) {
      _refundImage = null;
    } else {
      _refundImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      update();
    }
  }

  Future<void> getOrderCancelReasons() async {
    _orderCancelReasons = null;
    _orderCancelReasons = await orderServiceInterface.getCancelReasons();
    update();
  }

  Future<void> getRefundReasons() async {
    _selectedReasonIndex = 0;
    _refundReasons = null;
    _refundReasons = await orderServiceInterface.getRefundReasons();
    update();
  }

  Future<void> submitRefundRequest(String note, String? orderId) async {
    _isLoading = true;
    update();
    await orderServiceInterface.submitRefundRequest(
        _selectedReasonIndex, _refundReasons, note, orderId, _refundImage);
    _isLoading = false;
    update();
  }

  Future<void> getRunningOrders(int offset,
      {bool isUpdate = false, bool fromDashboard = false}) async {
    _Order_isLoading = true;

    if (offset == 1) {
      _runningOrderModel = null;
      _scheduleOrderModel = null;
      if (isUpdate) {
        update();
      }
    }

    final PaginatedOrderModel? orderModel =
        await orderServiceInterface.getRunningOrderList(offset, fromDashboard);

    if (orderModel != null) {
      if (offset == 1) {
        _scheduleOrderModel = PaginatedOrderModel();
        _runningOrderModel = PaginatedOrderModel();

        // التأكد من أن orders ليست null وتصفية الطلبات غير المدفوعة
        final List<OrderModel> orders = (orderModel.orders ?? [])
            .where((order) =>
                order.paymentStatus != 'unpaid' &&
                _isRunningStatus(order.orderStatus))
            .toList();

        for (final item in orders) {
          if (item.createdAt.toString() != item.scheduleAt.toString()) {
            _scheduleOrderModel!.orders ??= [];
            _scheduleOrderModel!.orders!.add(item);
          } else {
            _runningOrderModel!.orders ??= [];
            _runningOrderModel!.orders!.add(item);
          }
        }

        // نسخ البيانات المشتركة
        _scheduleOrderModel!.offset = orderModel.offset;
        _scheduleOrderModel!.limit = orderModel.limit;
        _scheduleOrderModel!.totalSize = orderModel.totalSize;

        _runningOrderModel!.offset = orderModel.offset;
        _runningOrderModel!.limit = orderModel.limit;
        _runningOrderModel!.totalSize = orderModel.totalSize;
      } else {
        // Filter out orders with unpaid payment status for pagination
        final List<OrderModel> filteredOrders = (orderModel.orders ?? [])
            .where((order) =>
                order.paymentStatus != 'unpaid' &&
                _isRunningStatus(order.orderStatus))
            .toList();

        _runningOrderModel!.orders ??= [];
        _runningOrderModel!.orders!.addAll(filteredOrders);
        _runningOrderModel!.offset = orderModel.offset;
        _runningOrderModel!.totalSize = _runningOrderModel!.orders!.length;
      }

      update();
    }

    _Order_isLoading = false;
    update();
  }

  Future<void> getHistoryOrders(int offset, {bool isUpdate = false}) async {
    if (offset == 1) {
      _historyOrderModel = null;
      if (isUpdate) {
        update();
      }
    }
    final PaginatedOrderModel? orderModel =
        await orderServiceInterface.getHistoryOrderList(offset);
    if (orderModel != null) {
      // Filter out orders with unpaid payment status
      final List<OrderModel> filteredOrders = (orderModel.orders ?? [])
          .where((order) =>
              order.paymentStatus != 'unpaid' &&
              _isHistoryStatus(order.orderStatus))
          .toList();

      if (offset == 1) {
        _historyOrderModel = PaginatedOrderModel();
        _historyOrderModel!.orders = filteredOrders;
        _historyOrderModel!.offset = orderModel.offset;
        _historyOrderModel!.limit = orderModel.limit;
        _historyOrderModel!.totalSize = filteredOrders.length;
      } else {
        _historyOrderModel!.orders!.addAll(filteredOrders);
        _historyOrderModel!.offset = orderModel.offset;
        _historyOrderModel!.totalSize = _historyOrderModel!.orders!.length;
      }
      update();
    }
  }

  Future<void> getSupportReasons() async {
    _supportReasons = await orderServiceInterface.getSupportReasonsList();
    update();
  }

  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID) async {
    _orderDetails = null;
    _isLoading = true;
    _showCancelled = false;

    if (_trackModel == null ||
        (_trackModel!.orderType != 'parcel' &&
            !_trackModel!.prescriptionOrder!)) {
      final List<OrderDetailsModel>? detailsList =
          await orderServiceInterface.getOrderDetails(orderID,
              AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
      _isLoading = false;
      if (detailsList != null) {
        _orderDetails = [];
        _orderDetails!.addAll(detailsList);
      }
    } else {
      _isLoading = false;
      _orderDetails = [];
    }
    update();
    return _orderDetails;
  }

  void setTrackModel(OrderModel model) {
    _isLoading = true;
    _trackModel = model;
    _isLoading = false;
    update();
  }

  Future<ResponseModel?> trackOrder(
      String? orderID, OrderModel? orderModel, bool fromTracking,
      {String? contactNumber,
      bool? fromGuestInput = false,
      bool preserveTrackModel = false}) async {
    if (!preserveTrackModel) {
      _trackModel = null;
    }
    _responseModel = null;
    if (!fromTracking) {
      _orderDetails = null;
    }
    _showCancelled = false;
    if (orderModel == null) {
      _isLoading = true;

      //

      final Response response = await orderServiceInterface.trackOrder(
          orderID, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
          contactNumber: contactNumber);

      //
      debugPrint('\x1B[32m  trackOrder /${response.statusCode}  \x1B[0m');

      if (response.statusCode == 200) {
        _trackModel =
            OrderModel.fromJson(response.body as Map<String, dynamic>);

        _responseModel = ResponseModel(true, response.body.toString());
      } else {
        _responseModel = ResponseModel(false, response.statusText);
      }

      //

      _isLoading = false;
      update();
    } else {
      _trackModel = orderModel;
      _responseModel = ResponseModel(true, 'Successful');
    }
    return _responseModel;
  }

  // ///////////////////////////

  Future<ResponseModel?> timerTrackOrder(String orderID,
      {String? contactNumber}) async {
    if (_isTimerTrackOrderInProgress) {
      return _responseModel;
    }
    _isTimerTrackOrderInProgress = true;
    _showCancelled = false;

    debugPrint('\x1B[32m     timerTrackOrder      \x1B[0m');
    try {
      final Response response = await orderServiceInterface.trackOrder(
          orderID, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
          contactNumber: contactNumber);
      if (response.statusCode == 200) {
        _trackModel =
            OrderModel.fromJson(response.body as Map<String, dynamic>);
        _responseModel = ResponseModel(true, response.body.toString());
      } else {
        _responseModel = ResponseModel(false, response.statusText);
      }
      update();
      return _responseModel;
    } finally {
      _isTimerTrackOrderInProgress = false;
    }
  }

  Future<bool> cancelOrder(int? orderID, String? cancelReason,
      {String? guestId}) async {
    _isLoading = true;
    update();
    final bool success = await orderServiceInterface
        .cancelOrder(orderID.toString(), cancelReason, guestId: guestId);
    _isLoading = false;
    Get.back();
    if (success) {
      final OrderModel? orderModel =
          orderServiceInterface.prepareOrderModel(_runningOrderModel, orderID);
      if (_runningOrderModel != null) {
        _runningOrderModel!.orders!.remove(orderModel);
      }
      _showCancelled = true;
    }
    update();
    return success;
  }

  Future<bool> switchToCOD(String? orderID, {String? guestId}) async {
    _isLoading = true;
    update();
    final bool isSuccess =
        await orderServiceInterface.switchToCOD(orderID, guestId: guestId);
    _isLoading = false;
    update();
    return isSuccess;
  }

  void paymentRedirect(
      {required String url,
      required bool canRedirect,
      required String? contactNumber,
      required Function onClose,
      required final String? addFundUrl,
      required final String? subscriptionUrl,
      required final String orderID,
      int? storeId,
      required bool createAccount,
      required String guestId}) {
    orderServiceInterface.paymentRedirect(
      url: url,
      canRedirect: canRedirect,
      contactNumber: contactNumber,
      onClose: onClose,
      addFundUrl: addFundUrl,
      subscriptionUrl: subscriptionUrl,
      orderID: orderID,
      storeId: storeId,
      createAccount: createAccount,
      guestId: guestId,
    );
  }
}
