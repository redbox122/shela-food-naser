
import 'dart:async';

import 'package:flutter/foundation.dart';
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
  bool _hasLoadedRunningOrders = false;
  bool get hasLoadedRunningOrders => _hasLoadedRunningOrders;
  bool _isLoadingHistoryOrders = false;
  bool get isLoadingHistoryOrders => _isLoadingHistoryOrders;
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

  static const List<String> _completedStatuses = <String>[
    AppConstants.delivered,
  ];

  static const List<String> _canceledStatuses = <String>[
    'canceled',
    'cancelled',
    'expired',
    'failed',
    'refund_requested',
    'refunded',
    'refund_request_canceled',
  ];

  final Map<int, List<Map<String, dynamic>>> _alternativeStoresByOrderId =
      <int, List<Map<String, dynamic>>>{};
  final Set<int> _alternativeStoresLoading = <int>{};
  final Set<int> _alternativeStoresExpanded = <int>{};

  bool _isCompletedStatus(String? status) {
    final String normalizedStatus = _normalizeStatus(status);
    return _completedStatuses.contains(normalizedStatus);
  }

  bool _isCanceledStatus(String? status) {
    final String normalizedStatus = _normalizeStatus(status);
    return _canceledStatuses.contains(normalizedStatus);
  }

  String _normalizeStatus(String? status) {
    return (status ?? '').toLowerCase().trim();
  }

  String getOrderStatusLabel(String? status) {
    final normalized = (status ?? '').toLowerCase();
    if (normalized == 'expired') {
      return 'order_status_expired_clear'.tr;
    }
    if (normalized == 'failed') {
      return 'order_status_failed_clear'.tr;
    }
    return (status ?? '').tr;
  }

  List<Map<String, dynamic>> getAlternativeStoresForOrder(int orderId) {
    return _alternativeStoresByOrderId[orderId] ?? <Map<String, dynamic>>[];
  }

  bool isAlternativeStoresLoading(int orderId) {
    return _alternativeStoresLoading.contains(orderId);
  }

  bool isAlternativeStoresExpanded(int orderId) {
    return _alternativeStoresExpanded.contains(orderId);
  }

  Future<void> toggleAlternativeStores(int orderId) async {
    if (orderId <= 0) {
      return;
    }
    if (_alternativeStoresExpanded.contains(orderId)) {
      _alternativeStoresExpanded.remove(orderId);
      update();
      return;
    }
    _alternativeStoresExpanded.add(orderId);
    update();
    if (_alternativeStoresByOrderId.containsKey(orderId)) {
      return;
    }
    _alternativeStoresLoading.add(orderId);
    update();
    try {
      final stores =
          await orderServiceInterface.getAlternativeStores(orderId: orderId);
      _alternativeStoresByOrderId[orderId] = stores;
    } finally {
      _alternativeStoresLoading.remove(orderId);
      update();
    }
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

  /// Removes a stale running order from local cache (e.g. unpaid digital order after payment failure).
  void removeRunningOrderLocally(int orderId) {
    final List<OrderModel>? orders = _runningOrderModel?.orders;
    if (orders == null || orders.isEmpty) {
      return;
    }
    final int before = orders.length;
    orders.removeWhere((OrderModel order) => order.id == orderId);
    if (orders.length != before) {
      debugPrint(
          '[OrderCtrl] removeRunningOrderLocally removed orderId=$orderId');
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
      final List<String> rawStatuses = (orderModel.orders ?? [])
          .map((order) =>
              '${order.id}:${_normalizeStatus(order.orderStatus)}')
          .toList();
      debugPrint('[OrderCtrl] getRunningOrders raw ids/statuses=$rawStatuses');
      const Set<String> activeStatuses = <String>{
        'pending',
        'confirmed',
        'accepted',
        'processing',
        'handover',
        'picked_up',
      };
      if (offset == 1) {
        _runningOrderModel = PaginatedOrderModel();
        final List<OrderModel> orders = (orderModel.orders ?? []).where((order) {
          final String status = _normalizeStatus(order.orderStatus);
          final bool allowed = activeStatuses.contains(status);
          debugPrint(
              '[RunningFilter] id=${order.id} raw=${order.orderStatus} normalized=$status allowed=$allowed');
          if (!allowed) {
            debugPrint('[RunningFilter] activeStatuses=$activeStatuses');
          }
          return allowed;
        }).toList();
        final List<String> filteredStatuses = orders
            .map((order) =>
                '${order.id}:${_normalizeStatus(order.orderStatus)}')
            .toList();
        debugPrint(
            '[OrderCtrl] getRunningOrders filtered ids/statuses=$filteredStatuses');
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
        final List<OrderModel> filteredOrders =
            (orderModel.orders ?? []).where((order) {
          final String status = _normalizeStatus(order.orderStatus);
          final bool allowed = activeStatuses.contains(status);
          debugPrint(
              '[RunningFilter] id=${order.id} raw=${order.orderStatus} normalized=$status allowed=$allowed');
          if (!allowed) {
            debugPrint('[RunningFilter] activeStatuses=$activeStatuses');
          }
          return allowed;
        }).toList();
        final List<String> filteredStatuses = filteredOrders
            .map((order) =>
                '${order.id}:${_normalizeStatus(order.orderStatus)}')
            .toList();
        debugPrint(
            '[OrderCtrl] getRunningOrders append filtered ids/statuses=$filteredStatuses');

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
    _hasLoadedRunningOrders = true;
    debugPrint(
      '[OrderCtrl] getRunningOrders done running=${_runningOrderModel?.orders?.length ?? -1} '
      'canceled=${_canceledOrderModel?.orders?.length ?? -1}',
    );
    update();
  }

  Future<void> getHistoryOrders(int offset, {bool isUpdate = false}) async {
    debugPrint(
        '[OrderCtrl] getHistoryOrders start offset=$offset isUpdate=$isUpdate');
    _isLoadingHistoryOrders = true;
    _hasOrderError = false;
    if (offset == 1) {
      _historyOrderModel = null;
      _canceledOrderModel = null;
    }
    if (isUpdate || offset == 1) {
      _updateSafely();
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
      final List<OrderModel> allOrders = (orderModel.orders ?? []);
      final List<OrderModel> paidOrders = allOrders
          .where((order) => order.paymentStatus != 'unpaid')
          .toList();
      final List<OrderModel> completedOrders = paidOrders
          .where((order) => _isCompletedStatus(order.orderStatus))
          .toList();
      final List<OrderModel> canceledOrders = allOrders
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
    _isLoadingHistoryOrders = false;
    debugPrint(
      '[OrderCtrl] getHistoryOrders done history=${_historyOrderModel?.orders?.length ?? -1} '
      'canceled=${_canceledOrderModel?.orders?.length ?? -1}',
    );
    _updateSafely();
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

  /// Clears cached track/details when opening order details for a different [requestedOrderId].
  void prepareOrderDetailsSession(int? requestedOrderId) {
    if (requestedOrderId == null || requestedOrderId <= 0) {
      return;
    }
    final int? cachedId = _trackModel?.id;
    if (kDebugMode) {
      debugPrint('[OrderDetails][OPEN] requestedOrderId=$requestedOrderId');
    }
    if (cachedId != null && cachedId != requestedOrderId) {
      if (kDebugMode) {
        debugPrint(
          '[OrderDetails][CLEAR_STALE] previousOrderId=$cachedId requestedOrderId=$requestedOrderId',
        );
      }
    }
    if (cachedId != requestedOrderId) {
      _trackModel = null;
      _orderDetails = null;
      _hasTrackError = false;
      _updateSafely();
    }
  }

  bool _orderDetailsBelongToOrder(
    List<OrderDetailsModel>? details,
    int? requestedId,
  ) {
    if (details == null || requestedId == null) {
      return true;
    }
    if (details.isEmpty) {
      return true;
    }
    return details.every(
      (OrderDetailsModel d) =>
          d.orderId == null || d.orderId == requestedId,
    );
  }

  List<OrderDetailsModel> _reuseDetailsOnlyIfSameOrder(
    List<OrderDetailsModel>? previous,
    String orderID,
  ) {
    final int? rid = int.tryParse(orderID);
    if (previous != null &&
        rid != null &&
        previous.isNotEmpty &&
        _orderDetailsBelongToOrder(previous, rid)) {
      return List<OrderDetailsModel>.from(previous);
    }
    return <OrderDetailsModel>[];
  }

  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID) async {
    if (kDebugMode) {
      debugPrint('[OrderDetails][FETCH_START] orderId=$orderID');
    }
    final List<OrderDetailsModel>? previousDetails = _orderDetails;
    _isLoading = true;
    _showCancelled = false;

    if (_trackModel == null ||
        (_trackModel!.orderType != 'parcel' &&
            !_trackModel!.prescriptionOrder!)) {
      final List<OrderDetailsModel>? detailsList =
          await orderServiceInterface.getOrderDetails(orderID,
              AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
      _isLoading = false;
      final int? requestedId = int.tryParse(orderID);
      if (detailsList != null) {
        if (!_orderDetailsBelongToOrder(detailsList, requestedId)) {
          if (kDebugMode) {
            debugPrint(
              '[OrderDetails][RENDER_BLOCKED_STALE] requestedOrderId=$requestedId '
              'detailsOrderIds=${detailsList.map((OrderDetailsModel e) => e.orderId).toList()}',
            );
          }
          _orderDetails = <OrderDetailsModel>[];
        } else {
          _orderDetails = <OrderDetailsModel>[...detailsList];
          if (kDebugMode) {
            final int? loadedOid = detailsList.isNotEmpty
                ? detailsList.first.orderId
                : requestedId;
            debugPrint(
              '[OrderDetails][FETCH_SUCCESS] requestedOrderId=$requestedId loadedOrderId=$loadedOid',
            );
          }
        }
      } else {
        _orderDetails = _reuseDetailsOnlyIfSameOrder(previousDetails, orderID);
      }
    } else {
      _isLoading = false;
      _orderDetails = _reuseDetailsOnlyIfSameOrder(previousDetails, orderID);
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
    final int? requestedTrackId =
        orderID != null && orderID.isNotEmpty ? int.tryParse(orderID) : null;
    if (orderModel == null &&
        requestedTrackId != null &&
        _trackModel?.id != null &&
        _trackModel!.id != requestedTrackId) {
      if (kDebugMode) {
        debugPrint(
          '[OrderDetails][CLEAR_STALE] previousOrderId=${_trackModel!.id} requestedOrderId=$requestedTrackId',
        );
      }
      _trackModel = null;
      _updateSafely();
    }
    if (orderModel == null) {
      _isLoading = true;
      if (kDebugMode) {
        debugPrint('[OrderDetails][FETCH_START] orderId=$orderID');
      }

      //

      final Response response = await orderServiceInterface.trackOrder(
          orderID, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
          contactNumber: contactNumber);

      //
      debugPrint('\x1B[32m  trackOrder /${response.statusCode}  \x1B[0m');

      if (response.statusCode == 200 || response.statusCode == 304) {
        if (response.body is Map<String, dynamic>) {
          final OrderModel parsed =
              OrderModel.fromJson(response.body as Map<String, dynamic>);
          if (requestedTrackId != null &&
              parsed.id != null &&
              parsed.id != requestedTrackId) {
            if (kDebugMode) {
              debugPrint(
                '[OrderDetails][RENDER_BLOCKED_STALE] requestedOrderId=$requestedTrackId cachedOrderId=${parsed.id}',
              );
            }
          } else {
            _trackModel = parsed;
            if (kDebugMode) {
              debugPrint(
                '[OrderDetails][FETCH_SUCCESS] requestedOrderId=$requestedTrackId loadedOrderId=${parsed.id}',
              );
            }
          }
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
    final int? requestedId = int.tryParse(orderID);

    debugPrint('\x1B[32m     timerTrackOrder      \x1B[0m');
    try {
      final Response response = await orderServiceInterface.trackOrder(
          orderID, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
          contactNumber: contactNumber);
      if (response.statusCode == 200 || response.statusCode == 304) {
        if (response.body is Map<String, dynamic>) {
          final OrderModel parsed =
              OrderModel.fromJson(response.body as Map<String, dynamic>);
          if (requestedId != null &&
              parsed.id != null &&
              parsed.id != requestedId) {
            if (kDebugMode) {
              debugPrint(
                '[OrderDetails][RENDER_BLOCKED_STALE] requestedOrderId=$requestedId cachedOrderId=${parsed.id} (timer)',
              );
            }
          } else {
            _trackModel = parsed;
          }
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
    // 🔎 DIAGNOSTIC: Show the backend-provided cancel reasons (id + text) next to
    // the value actually being submitted. The submit dialog currently sends the
    // reason TEXT (from a hardcoded Arabic list); this log reveals whether that
    // text matches ANY backend reason id/text — a likely cause of "not found".
    final List<CancellationData> loadedReasons =
        _orderCancelReasons ?? <CancellationData>[];
    final String submitted = (cancelReason ?? '').trim();
    final int? submittedAsId = int.tryParse(submitted);
    bool matchesBackendText = false;
    bool matchesBackendId = false;
    debugPrint('───────── [OrderCancel][REASON_DIAG] ─────────');
    debugPrint('  • submitted reason : "$cancelReason"');
    debugPrint(
        '  • submitted is numeric id? ${submittedAsId != null} (parsed=$submittedAsId)');
    debugPrint('  • backend reasons  : ${loadedReasons.length}');
    for (final CancellationData r in loadedReasons) {
      debugPrint(
          '      - id=${r.id} | userType=${r.userType} | status=${r.status} | reason="${r.reason}"');
      if ((r.reason ?? '').trim() == submitted) matchesBackendText = true;
      if (submittedAsId != null && r.id == submittedAsId) matchesBackendId = true;
    }
    debugPrint('  • matches a backend reason TEXT : $matchesBackendText');
    debugPrint('  • matches a backend reason ID   : $matchesBackendId');
    debugPrint('──────────────────────────────────────────────');
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
        // Force refresh so a refunded balance isn't masked by an ETag 304.
        await Get.find<ProfileController>().getUserInfo(forceRefresh: true);
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
