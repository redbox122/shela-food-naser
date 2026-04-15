
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet/controllers/wallet_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;

  OrderController({required this.orderServiceInterface});

  PaginatedOrderModel? _runningOrderModel;
  PaginatedOrderModel? get runningOrderModel => _runningOrderModel;

  PaginatedOrderModel? _canceledOrderModel;
  PaginatedOrderModel? get canceledOrderModel => _canceledOrderModel;

  PaginatedOrderModel? _historyOrderModel;
  PaginatedOrderModel? get historyOrderModel => _historyOrderModel;

  List<OrderDetailsModel>? _orderDetails;
  List<OrderDetailsModel>? get orderDetails => _orderDetails;

  OrderModel? _trackModel;
  OrderModel? get trackModel => _trackModel;

  bool _Order_isLoading = false;
  bool get Order_isLoading => _Order_isLoading;
  bool _hasOrderError = false;
  bool get hasOrderError => _hasOrderError;

  // OrderModel? _track_Model;
  // OrderModel? get track_Model => _track_Model;

  ResponseModel? _responseModel;
  ResponseModel? get responseModel => _responseModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasTrackError = false;
  bool get hasTrackError => _hasTrackError;

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
  bool _isCancelReasonsLoading = false;
  bool get isCancelReasonsLoading => _isCancelReasonsLoading;
  bool _cancelReasonsLoadFailed = false;
  bool get cancelReasonsLoadFailed => _cancelReasonsLoadFailed;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  List<String?>? _supportReasons;
  List<String?>? get supportReasons => _supportReasons;
  bool _isSupportReasonsLoading = false;
  bool get isSupportReasonsLoading => _isSupportReasonsLoading;

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

  static const List<String> _completedStatuses = <String>[
    AppConstants.delivered,
  ];

  static const List<String> _canceledStatuses = <String>[
    'canceled',
  ];

  bool _isRunningStatus(String? status) {
    if (status == null) return false;
    if (_runningStatuses.contains(status)) return true;
    if (_completedStatuses.contains(status) ||
        _canceledStatuses.contains(status)) {
      return false;
    }
    return true;
  }

  bool _isCompletedStatus(String? status) {
    if (status == null) return false;
    return _completedStatuses.contains(status);
  }

  bool _isCanceledStatus(String? status) {
    if (status == null) return false;
    return _canceledStatuses.contains(status);
  }

  Future<void> connect(String userId) async {
    if (userId.isEmpty) {
      debugPrint('❌ userId is empty. Cannot connect to WebSocket.');
      isConnected.value = false;
      return;
    }

    try {
      await disconnect();

      final Stream? stream =
          await orderServiceInterface.connectToOrderWebSocket(userId);

      if (stream == null) {
        debugPrint('⚠️ WebSocket stream is null. No connection established.');
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

          debugPrint('📩 WebSocket Data: $data');
        },
        onError: (Object error) {
          debugPrint('❌ WebSocket Error: $error');

          if (error is WebSocketChannelException) {
            debugPrint('📛 Detailed Error: ${error.inner}');
          }

          isConnected.value = false;
        },
        onDone: () {
          debugPrint('🔌 WebSocket closed');
          isConnected.value = false;
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to connect to WebSocket: $e');
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
    debugPrint('[OrderCancel] controller getOrderCancelReasons start');
    _isCancelReasonsLoading = true;
    _cancelReasonsLoadFailed = false;
    _orderCancelReasons = null;
    update();
    try {
      final List<CancellationData>? reasons =
          await orderServiceInterface.getCancelReasons();
      if (reasons == null) {
        _orderCancelReasons = <CancellationData>[];
        _cancelReasonsLoadFailed = true;
        debugPrint(
            '[OrderCancel] controller reasons=null => mark loadFailed=true');
      } else {
        _orderCancelReasons = reasons;
        debugPrint(
            '[OrderCancel] controller reasons loaded count=${reasons.length}');
      }
    } catch (e) {
      debugPrint('[OrderCancel] getOrderCancelReasons failed: $e');
      _orderCancelReasons = <CancellationData>[];
      _cancelReasonsLoadFailed = true;
    } finally {
      _isCancelReasonsLoading = false;
      debugPrint(
        '[OrderCancel] controller getOrderCancelReasons done '
        'loading=$_isCancelReasonsLoading failed=$_cancelReasonsLoadFailed '
        'count=${_orderCancelReasons?.length ?? -1}',
      );
    }
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
    debugPrint(
        '[OrderCtrl] getRunningOrders start offset=$offset isUpdate=$isUpdate fromDashboard=$fromDashboard');
    _Order_isLoading = true;
    _hasOrderError = false;

    if (offset == 1) {
      _runningOrderModel = null;
      if (isUpdate) {
        update();
      }
    }

    final PaginatedOrderModel? orderModel =
        await orderServiceInterface.getRunningOrderList(offset, fromDashboard);
    debugPrint(
        '[OrderCtrl] getRunningOrders apiResult null=${orderModel == null} rawCount=${orderModel?.orders?.length ?? -1}');
    if (orderModel?.orders != null && orderModel!.orders!.isNotEmpty) {
      final List<int?> sampleIds =
          orderModel.orders!.take(5).map((e) => e.id).toList();
      debugPrint('[OrderCtrl] getRunningOrders sampleIds=$sampleIds');
    }

    if (orderModel != null) {
      _hasOrderError = false;
      if (offset == 1) {
        _runningOrderModel = PaginatedOrderModel();

        // التأكد من أن orders ليست null وتصفية الطلبات غير المدفوعة
        final List<OrderModel> orders = (orderModel.orders ?? [])
            .where((order) =>
                order.paymentStatus != 'unpaid' &&
                _isRunningStatus(order.orderStatus))
            .toList();
        debugPrint(
            '[OrderCtrl] getRunningOrders filtered running statuses count=${orders.length}');

        for (final item in orders) {
          _runningOrderModel!.orders ??= [];
          _runningOrderModel!.orders!.add(item);
        }

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
        debugPrint(
            '[OrderCtrl] getRunningOrders append result runningCount=${_runningOrderModel!.orders!.length}');
      }

      update();
    } else {
      _hasOrderError = true;
    }

    _Order_isLoading = false;
    debugPrint(
      '[OrderCtrl] getRunningOrders done running=${_runningOrderModel?.orders?.length ?? -1} '
      'canceled=${_canceledOrderModel?.orders?.length ?? -1}',
    );
    update();
  }

  Future<void> getHistoryOrders(int offset, {bool isUpdate = false}) async {
    debugPrint(
        '[OrderCtrl] getHistoryOrders start offset=$offset isUpdate=$isUpdate');
    _hasOrderError = false;
    if (offset == 1) {
      _historyOrderModel = null;
      _canceledOrderModel = null;
      if (isUpdate) {
        update();
      }
    }
    final PaginatedOrderModel? orderModel =
        await orderServiceInterface.getHistoryOrderList(offset);
    debugPrint(
        '[OrderCtrl] getHistoryOrders apiResult null=${orderModel == null} rawCount=${orderModel?.orders?.length ?? -1}');
    if (orderModel?.orders != null && orderModel!.orders!.isNotEmpty) {
      final List<int?> sampleIds =
          orderModel.orders!.take(5).map((e) => e.id).toList();
      debugPrint('[OrderCtrl] getHistoryOrders sampleIds=$sampleIds');
    }
    if (orderModel != null) {
      _hasOrderError = false;
      final List<OrderModel> paidOrders = (orderModel.orders ?? [])
          .where((order) => order.paymentStatus != 'unpaid')
          .toList();
      final List<OrderModel> completedOrders = paidOrders
          .where((order) => _isCompletedStatus(order.orderStatus))
          .toList();
      final List<OrderModel> canceledOrders = paidOrders
          .where((order) => _isCanceledStatus(order.orderStatus))
          .toList();
      debugPrint(
          '[OrderCtrl] getHistoryOrders completed=${completedOrders.length} canceled=${canceledOrders.length}');

      if (offset == 1) {
        _historyOrderModel = PaginatedOrderModel();
        _historyOrderModel!.orders = completedOrders;
        _historyOrderModel!.offset = orderModel.offset;
        _historyOrderModel!.limit = orderModel.limit;
        _historyOrderModel!.totalSize = completedOrders.length;

        _canceledOrderModel = PaginatedOrderModel();
        _canceledOrderModel!.orders = canceledOrders;
        _canceledOrderModel!.offset = orderModel.offset;
        _canceledOrderModel!.limit = orderModel.limit;
        _canceledOrderModel!.totalSize = canceledOrders.length;
      } else {
        _historyOrderModel!.orders ??= [];
        _historyOrderModel!.orders!.addAll(completedOrders);
        _historyOrderModel!.offset = orderModel.offset;
        _historyOrderModel!.totalSize = _historyOrderModel!.orders!.length;

        _canceledOrderModel!.orders ??= [];
        _canceledOrderModel!.orders!.addAll(canceledOrders);
        _canceledOrderModel!.offset = orderModel.offset;
        _canceledOrderModel!.totalSize = _canceledOrderModel!.orders!.length;
      }
      update();
    } else {
      _hasOrderError = true;
    }
    debugPrint(
      '[OrderCtrl] getHistoryOrders done history=${_historyOrderModel?.orders?.length ?? -1} '
      'canceled=${_canceledOrderModel?.orders?.length ?? -1}',
    );
  }

  Future<void> getSupportReasons() async {
    _isSupportReasonsLoading = true;
    _supportReasons = null;
    _updateSafely();
    try {
      _supportReasons = await orderServiceInterface
          .getSupportReasonsList()
          .timeout(const Duration(seconds: 15));
      _supportReasons ??= <String?>[];
    } catch (e) {
      debugPrint('[SupportFlow] getSupportReasons failed: $e');
      _supportReasons = <String?>[];
    } finally {
      _isSupportReasonsLoading = false;
      _updateSafely();
    }
  }

  void _updateSafely() {
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      update();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        update();
      }
    });
  }

  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID) async {
    final previousDetails = _orderDetails;
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
      } else {
        _orderDetails = previousDetails ?? [];
      }
    } else {
      _isLoading = false;
      _orderDetails = previousDetails ?? [];
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
    _responseModel = null;
    _hasTrackError = false;
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

      if (response.statusCode == 200 || response.statusCode == 304) {
        if (response.body is Map<String, dynamic>) {
          _trackModel =
              OrderModel.fromJson(response.body as Map<String, dynamic>);
        } else if (!preserveTrackModel) {
          // Keep existing track model when body is empty (304 with cache hit)
          _trackModel = _trackModel;
        }
        _responseModel = ResponseModel(true, response.body.toString());
      } else {
        _hasTrackError = true;
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
      if (response.statusCode == 200 || response.statusCode == 304) {
        if (response.body is Map<String, dynamic>) {
          _trackModel =
              OrderModel.fromJson(response.body as Map<String, dynamic>);
        }
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
    debugPrint(
        '[OrderCancel] controller cancelOrder start orderId=$orderID reason=$cancelReason');
    _isLoading = true;
    update();
    bool success = false;
    try {
      success = await orderServiceInterface
          .cancelOrder(orderID.toString(), cancelReason, guestId: guestId);
      debugPrint(
          '[OrderCancel] controller cancelOrder service result=$success');
      if (success) {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        final OrderModel? runningOrderModelItem = orderServiceInterface
            .prepareOrderModel(_runningOrderModel, orderID);
        if (_runningOrderModel?.orders != null &&
            runningOrderModelItem != null) {
          _runningOrderModel!.orders!.remove(runningOrderModelItem);
        }
        _showCancelled = true;

        // Refresh profile + wallet state so refunded balance appears quickly.
        await _refreshWalletAfterCancellation();
        await getHistoryOrders(1, isUpdate: true);
      }
    } catch (e) {
      debugPrint('[OrderCancel] cancelOrder failed: $e');
      showCustomSnackBar('failed_to_cancel_order'.tr);
    } finally {
      _isLoading = false;
      debugPrint(
          '[OrderCancel] controller cancelOrder end loading=$_isLoading');
      update();
    }
    return success;
  }

  Future<void> _refreshWalletAfterCancellation() async {
    try {
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().getUserInfo();
      }

      if (Get.isRegistered<WalletController>()) {
        final WalletController walletController = Get.find<WalletController>();
        await walletController.getWalletTransactionList('1', true, 'all');
      }

      if (Get.isRegistered<KaidhaSubscriptionController>()) {
        final KaidhaSubscriptionController qidhaController =
            Get.find<KaidhaSubscriptionController>();

        // Refresh now, then retry shortly because some backends apply refund asynchronously.
        await qidhaController.get_Wallet_Kaidh(forceRefresh: true);
        await Future.delayed(const Duration(milliseconds: 900));
        await qidhaController.get_Wallet_Kaidh(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('[OrderCancel] wallet/profile refresh failed: $e');
    }
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
