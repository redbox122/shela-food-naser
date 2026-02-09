// ignore_for_file: avoid_print

import 'package:get/get_connect/connect.dart';
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
  Future<Response> submitRefundRequest(Map<String, String> body, XFile? data) async {
    return apiClient.postMultipartData(AppConstants.refundRequestUri, body, [MultipartBody('image[]', data)]);
  }

  @override
  Future<Response> trackOrder(String? orderID, String? guestId, {String? contactNumber}) async {
    String uri = '${AppConstants.trackUri}$orderID';
    if (guestId != null) uri += '&guest_id=$guestId';
    if (contactNumber != null) uri += '&contact_number=$contactNumber';
    return await apiClient.getData(uri);
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
  Future<bool> cancelOrder(String orderID, String? reason, {String? guestId}) async {
    bool success = false;
    final Map<String, String> data = {'_method': 'put', 'order_id': orderID, 'reason': reason!};
    if (AuthHelper.isGuestLoggedIn() || guestId != null) {
      data.addAll({'guest_id': guestId ?? AuthHelper.getGuestId()});
    }
    final Response response = await apiClient.postData(AppConstants.orderCancelUri, data);
    if (response.statusCode == 200) {
      success = true;
      showCustomSnackBar((response.body as Map<String, dynamic>)['message'] as String?, isError: false);
    }
    return success;
  }

  @override
  Future get(String? id, {String? guestId}) async {
    return await _getOrderDetails(id!, guestId);
  }

  Future<List<OrderDetailsModel>?> _getOrderDetails(String orderID, String? guestId) async {
    List<OrderDetailsModel>? orderDetails;
    final Response response =
        await apiClient.getData('${AppConstants.orderDetailsUri}$orderID${guestId != null ? '&guest_id=$guestId' : ''}');
    if (response.statusCode == 200) {
      orderDetails = [];
      for (var orderDetail in (response.body as List)) {
        orderDetails.add(OrderDetailsModel.fromJson(orderDetail as Map<String, dynamic>));
      }
    }
    return orderDetails;
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

  Future<PaginatedOrderModel?> _getRunningOrderList(int offset, bool fromDashboard) async {
    PaginatedOrderModel? runningOrderModel;
    final Response response = await apiClient.getData(
      '${AppConstants.runningOrderListUri}?offset=$offset&limit=${fromDashboard ? 50 : 10}',
      useEtag: false,
    );
    if (response.statusCode == 200) {
      runningOrderModel = PaginatedOrderModel.fromJson(response.body as Map<String, dynamic>);
    }
    return runningOrderModel;
  }

  Future<PaginatedOrderModel?> _getHistoryOrderList(int offset) async {
    PaginatedOrderModel? historyOrderModel;
    final Response response = await apiClient.getData(
      '${AppConstants.historyOrderListUri}?offset=$offset&limit=10',
      useEtag: false,
    );
    if (response.statusCode == 200) {
      historyOrderModel = PaginatedOrderModel.fromJson(response.body as Map<String, dynamic>);
    }
    return historyOrderModel;
  }

  Future<List<CancellationData>?> _getCancelReasons() async {
    List<CancellationData>? orderCancelReasons;
    final Response response = await apiClient.getData('${AppConstants.orderCancellationUri}?offset=1&limit=30&type=customer');
    if (response.statusCode == 200) {
      final OrderCancellationBody orderCancellationBody = OrderCancellationBody.fromJson(response.body as Map<String, dynamic>);
      orderCancelReasons = orderCancellationBody.reasons ?? [];
    }
    return orderCancelReasons;
  }

  Future<List<String?>?> _getRefundReasons() async {
    List<String?>? refundReasons;
    final Response response = await apiClient.getData(AppConstants.refundReasonUri);
    if (response.statusCode == 200) {
      final RefundModel refundModel = RefundModel.fromJson(response.body as Map<String, dynamic>);
      refundReasons = ['select_an_option', ...?refundModel.refundReasons?.map((e) => e.reason)];
    }
    return refundReasons;
  }

  Future<List<String?>?> _getSupportReasons() async {
    List<String?>? supportReasons;
    final Response response = await apiClient.getData(AppConstants.supportReasonUri);
    if (response.statusCode == 200) {
      final SupportModel supportModel = SupportModel.fromJson(response.body as Map<String, dynamic>);
      supportReasons = supportModel.data?.map((e) => e.message).toList();
    }
    return supportReasons;
  }

  @override
  Future add(value) => throw UnimplementedError();

  @override
  Future delete(int? id) => throw UnimplementedError();

  @override
  Future update(Map<String, dynamic> body, int? id) => throw UnimplementedError();

  // ✅ WebSocket Integration
  // ===============================================================================================

  @override
  Future<Stream?> connectToOrderWebSocket(String userId) async {
    final url = Uri.parse('wss://shalafood.net/order/updates?type=user&id=$userId');

    try {
      _channel = WebSocketChannel.connect(url);
      _stream = _channel!.stream.asBroadcastStream();
      print('✅ WebSocket connected to $url');
      return _stream;
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      return null; // ⛔ أرجع null بدلاً من stream فارغ
    }
  }

  @override
  void closeWebSocket() {
    _channel?.sink.close();
    print('🔌 WebSocket connection closed');
  }
}



  // 


 
