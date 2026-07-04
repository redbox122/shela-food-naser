import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/refund_model.dart';
import 'package:sixam_mart/features/order/domain/models/support_model.dart';
import 'package:sixam_mart/features/order/domain/repositories/order_repository_interface.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderRepository implements OrderRepositoryInterface {
  final ApiClient apiClient;
  OrderServiceInterface? orderService;

  WebSocketChannel? _channel;
  Stream? _stream;

  OrderRepository({required this.apiClient});

  @override
  Future<Response> submitRefundRequest(
      Map<String, String> body, XFile? data) async {
    return apiClient.postMultipartData(
        AppConstants.refundRequestUri, body, [MultipartBody('image[]', data)]);
  }

  @override
  Future<Response> trackOrder(String? orderID, String? guestId,
      {String? contactNumber}) async {
    String uri = '${AppConstants.trackUri}$orderID';
    if (guestId != null) uri += '&guest_id=$guestId';
    if (contactNumber != null) uri += '&contact_number=$contactNumber';
    debugPrint(
        '[OrderTrack] GET uri=$uri baseUrl=${apiClient.appBaseUrl} useEtag=false');
    final Response response = await apiClient.getData(uri, useEtag: false);
    debugPrint(
        '[OrderTrack] status=${response.statusCode} bodyType=${response.body.runtimeType}');
    return response;
  }

  @override
  Future<Response> switchToCOD(String? orderID, {String? guestId}) async {
    final Map<String, String> data = {'_method': 'put', 'order_id': orderID!};
    if (AuthHelper.isGuestLoggedIn() || guestId != null) {
      data.addAll({'guest_id': guestId ?? AuthHelper.getGuestId()});
    }
    return await apiClient.postData(AppConstants.codSwitchUri, data);
  }

  @override
  Future<bool> cancelOrder(String orderID, String? reason,
      {String? guestId}) async {
    bool success = false;
    final Map<String, String> data = {
      '_method': 'put',
      'order_id': orderID,
      'reason': reason!
    };
    if (AuthHelper.isGuestLoggedIn() || guestId != null) {
      data.addAll({'guest_id': guestId ?? AuthHelper.getGuestId()});
    }
    // 🔎 DIAGNOSTIC: Log the EXACT request being sent for order cancellation.
    // Helps determine whether Flutter sends a wrong order_id/reason field or the
    // backend route/controller returns "not found".
    debugPrint('═══════════════ [OrderCancel][REQUEST] ═══════════════');
    debugPrint('  • endpoint (relative): ${AppConstants.orderCancelUri}');
    debugPrint(
        '  • endpoint (full)    : ${apiClient.appBaseUrl}${AppConstants.orderCancelUri}');
    debugPrint(
        '  • transport method   : POST (Laravel method-spoof _method=${data['_method']})');
    debugPrint('  • order_id           : ${data['order_id']}');
    debugPrint(
        '  • reason (value sent): "${data['reason']}" (type=${reason.runtimeType}, isNumericId=${int.tryParse(reason) != null})');
    debugPrint('  • guest_id           : ${data['guest_id'] ?? '(none)'}');
    debugPrint('  • full body          : ${jsonEncode(data)}');
    debugPrint('══════════════════════════════════════════════════════');

    final Response response =
        await apiClient.postData(AppConstants.orderCancelUri, data);

    String prettyBody;
    try {
      prettyBody = jsonEncode(response.body);
    } catch (_) {
      prettyBody = response.body.toString();
    }
    debugPrint('═══════════════ [OrderCancel][RESPONSE] ══════════════');
    debugPrint('  • status code   : ${response.statusCode}');
    debugPrint('  • status text   : ${response.statusText}');
    debugPrint('  • body type     : ${response.body.runtimeType}');
    debugPrint('  • full body     : $prettyBody');
    debugPrint('══════════════════════════════════════════════════════');
    if (response.body is Map<String, dynamic>) {
      final Map<String, dynamic> map = response.body as Map<String, dynamic>;
      String? resolvedMessage;
      final dynamic directMessage = map['message'];
      if (directMessage != null && directMessage.toString().trim().isNotEmpty) {
        resolvedMessage = directMessage.toString();
      }
      if ((resolvedMessage == null || resolvedMessage.trim().isEmpty) &&
          map['errors'] is List &&
          (map['errors'] as List).isNotEmpty) {
        final dynamic firstError = (map['errors'] as List).first;
        if (firstError is Map<String, dynamic>) {
          final dynamic errorMessage = firstError['message'];
          if (errorMessage != null &&
              errorMessage.toString().trim().isNotEmpty) {
            resolvedMessage = errorMessage.toString();
          }
        }
      }
      resolvedMessage ??= 'ord_cancel_failed'.tr;
      final bool apiSuccess = map['success'] == true ||
          map['success'] == 1 ||
          map['success'] == '1';
      final bool refundProcessed = map['refund_processed'] == true ||
          map['refund_processed'] == 1 ||
          map['refund_processed'] == '1';
      final String refundTarget =
          (map['refund_target']?.toString().toLowerCase() ?? '').trim();
      final dynamic refundAmount = map['refund_amount'];
      final dynamic walletBalanceAfterRefund =
          map['wallet_balance_after_refund'];
      final dynamic refundTransactionId = map['refund_transaction_id'];

      debugPrint('[OrderCancel] cancel response keys=${map.keys.toList()}');
      debugPrint('[OrderCancel] cancel response message=$resolvedMessage');
      debugPrint(
          '[OrderCancel] refund_processed=$refundProcessed refund_target=$refundTarget refund_amount=$refundAmount wallet_balance_after_refund=$walletBalanceAfterRefund refund_transaction_id=$refundTransactionId');

      if (response.statusCode == 200 && apiSuccess) {
        success = true;
        String successMessage = (directMessage != null &&
                directMessage.toString().trim().isNotEmpty)
            ? directMessage.toString()
            : 'order_cancelled'.tr;
        if (refundProcessed) {
          if (refundTarget == 'wallet_qidha') {
            successMessage = 'refund_to_qidha_wallet_processing'.tr;
          } else if (refundTarget == 'wallet') {
            successMessage = 'refund_to_wallet_processing'.tr;
          } else if (refundTarget == 'card') {
            successMessage = 'refund_to_original_payment_processing'.tr;
          } else {
            successMessage = 'order_refund_completed'.tr;
          }
        }
        showCustomSnackBar(
          successMessage,
          isError: false,
        );
      } else {
        showCustomSnackBar(resolvedMessage);
      }
    } else {
      debugPrint('[OrderCancel] cancel response map not available');
      if (response.statusCode == 200) {
        success = true;
      } else {
        showCustomSnackBar('ord_cancel_failed'.tr);
      }
    }
    return success;
  }

  @override
  Future get(String? id, {String? guestId}) async {
    return await _getOrderDetails(id!, guestId);
  }

  Future<List<OrderDetailsModel>?> _getOrderDetails(
      String orderID, String? guestId) async {
    List<OrderDetailsModel>? orderDetails;
    final String uri =
        '${AppConstants.orderDetailsUri}$orderID${guestId != null ? '&guest_id=$guestId' : ''}';
    debugPrint(
        '[OrderDetails] GET uri=$uri baseUrl=${apiClient.appBaseUrl} useEtag=false');
    final Response response = await apiClient.getData(uri, useEtag: false);
    debugPrint(
        '[OrderDetails] status=${response.statusCode} bodyType=${response.body.runtimeType}');
    if (response.statusCode == 200 && response.body is List) {
      orderDetails = [];
      for (var orderDetail in (response.body as List)) {
        orderDetails.add(
            OrderDetailsModel.fromJson(orderDetail as Map<String, dynamic>));
      }
      debugPrint('[OrderDetails] parsedCount=${orderDetails.length}');
      return orderDetails;
    }
    debugPrint(
        '[OrderDetails] no valid list payload; keeping previous details in controller');
    return null;
  }

  @override
  Future getList({
    int? offset,
    bool isRunningOrder = false,
    bool isHistoryOrder = false,
    bool isCancelReasons = false,
    bool isRefundReasons = false,
    bool fromDashboard = false,
    bool isSupportReasons = false,
  }) async {
    if (isRunningOrder) {
      return await _getRunningOrderList(offset!, fromDashboard);
    } else if (isHistoryOrder) {
      return await _getHistoryOrderList(offset!);
    } else if (isCancelReasons) {
      return await _getCancelReasons();
    } else if (isRefundReasons) {
      return await _getRefundReasons();
    } else if (isSupportReasons) {
      return await _getSupportReasons();
    }
  }

  Future<PaginatedOrderModel?> _getRunningOrderList(
      int offset, bool fromDashboard) async {
    PaginatedOrderModel? runningOrderModel;
    final String uri =
        '${AppConstants.runningOrderListUri}?offset=$offset&limit=${fromDashboard ? 50 : 10}';
    debugPrint(
        '[OrderRepo] GET running uri=$uri baseUrl=${apiClient.appBaseUrl}');
    // Show the customer's orders across ALL modules (not just the selected one).
    final Response response = await apiClient.getData(
      uri,
      useEtag: false,
      omitModuleId: true,
    );
    debugPrint(
        '[OrderRepo] running status=${response.statusCode} bodyType=${response.body.runtimeType}');
    if (response.statusCode == 200) {
      runningOrderModel =
          PaginatedOrderModel.fromJson(response.body as Map<String, dynamic>);
      debugPrint(
          '[OrderRepo] running parsedCount=${runningOrderModel.orders?.length ?? 0}');
    }
    return runningOrderModel;
  }

  Future<PaginatedOrderModel?> _getHistoryOrderList(int offset) async {
    PaginatedOrderModel? historyOrderModel;
    final String uri =
        '${AppConstants.historyOrderListUri}?offset=$offset&limit=10';
    debugPrint(
        '[OrderRepo] GET history uri=$uri baseUrl=${apiClient.appBaseUrl}');
    // Show the customer's orders across ALL modules (not just the selected one).
    final Response response = await apiClient.getData(
      uri,
      useEtag: false,
      omitModuleId: true,
    );
    debugPrint(
        '[OrderRepo] history status=${response.statusCode} bodyType=${response.body.runtimeType}');
    if (response.statusCode == 200) {
      historyOrderModel =
          PaginatedOrderModel.fromJson(response.body as Map<String, dynamic>);
      debugPrint(
          '[OrderRepo] history parsedCount=${historyOrderModel.orders?.length ?? 0}');
    }
    return historyOrderModel;
  }

  @override
  Future<List<Map<String, dynamic>>> getAlternativeStores(
      {required int orderId, int limit = 5}) async {
    final String uri =
        '${AppConstants.alternativeStoresUri}?order_id=$orderId&limit=$limit';
    final Response response = await apiClient.getData(uri, useEtag: false);
    if (response.statusCode != 200) {
      return <Map<String, dynamic>>[];
    }
    final dynamic body = response.body;
    if (body is Map<String, dynamic>) {
      final dynamic stores = body['stores'] ?? body['data'];
      if (stores is List) {
        return stores
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } else if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<CancellationData>?> _getCancelReasons() async {
    List<CancellationData>? orderCancelReasons;
    const String uri =
        '${AppConstants.orderCancellationUri}?offset=1&limit=30&type=customer';
    debugPrint('[OrderCancel] get reasons request uri=$uri useEtag=false');
    final Response response = await apiClient.getData(
      uri,
      useEtag: false,
    );
    debugPrint('[OrderCancel] get reasons status=${response.statusCode}');
    debugPrint(
        '[OrderCancel] get reasons bodyType=${response.body.runtimeType}');
    if ((response.statusCode == 200 || response.statusCode == 304) &&
        response.body is Map<String, dynamic>) {
      final OrderCancellationBody orderCancellationBody =
          OrderCancellationBody.fromJson(response.body as Map<String, dynamic>);
      orderCancelReasons = orderCancellationBody.reasons ?? [];
      debugPrint(
          '[OrderCancel] get reasons parsedCount=${orderCancelReasons.length}');
    } else if (response.body is List) {
      final List body = response.body as List;
      debugPrint(
          '[OrderCancel] get reasons unexpected list body length=${body.length}');
    } else {
      debugPrint('[OrderCancel] get reasons unexpected body=${response.body}');
    }
    return orderCancelReasons;
  }

  Future<List<String?>?> _getRefundReasons() async {
    List<String?>? refundReasons;
    final Response response =
        await apiClient.getData(AppConstants.refundReasonUri);
    if (response.statusCode == 200) {
      final RefundModel refundModel =
          RefundModel.fromJson(response.body as Map<String, dynamic>);
      refundReasons = [
        'select_an_option',
        ...?refundModel.refundReasons?.map((e) => e.reason)
      ];
    }
    return refundReasons;
  }

  Future<List<String?>?> _getSupportReasons() async {
    List<String?>? supportReasons;
    final Response response =
        await apiClient.getData(AppConstants.supportReasonUri);
    if (response.statusCode == 200) {
      final SupportModel supportModel =
          SupportModel.fromJson(response.body as Map<String, dynamic>);
      supportReasons = supportModel.data?.map((e) => e.message).toList();
    }
    return supportReasons;
  }

  @override
  Future add(value) => throw UnimplementedError();

  @override
  Future delete(int? id) => throw UnimplementedError();

  @override
  Future update(Map<String, dynamic> body, int? id) =>
      throw UnimplementedError();

  // ✅ WebSocket Integration
  // ===============================================================================================

  @override
  Future<Stream?> connectToOrderWebSocket(String userId) async {
    final url =
        Uri.parse('wss://shalafood.net/order/updates?type=user&id=$userId');

    try {
      _channel = WebSocketChannel.connect(url);
      _stream = _channel!.stream.asBroadcastStream();
      debugPrint('✅ WebSocket connected to $url');
      return _stream;
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      return null; // ⛔ أرجع null بدلاً من stream فارغ
    }
  }

  @override
  void closeWebSocket() {
    _channel?.sink.close();
    debugPrint('🔌 WebSocket connection closed');
  }
}



  // 


 
