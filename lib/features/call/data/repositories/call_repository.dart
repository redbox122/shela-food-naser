import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/call/data/models/call_model.dart';

/// Talks to the voice-call backend. Kept isolated so nothing else in the app is
/// touched. Requests an Agora RTC token for a given order/participant pair via
/// `POST /api/v1/call/token`.
class CallRepository {
  static const String appId = 'd0b119f16af84daa93186f1b7fc7dd09';
  static const String tokenUri = '/api/v1/call/token';

  /// Requests a join token. Returns null if the backend is unreachable or the
  /// endpoint isn't deployed yet (so the caller can show an error gracefully).
  Future<CallTokenModel?> requestToken({
    required int orderId,
    required String callerType, // 'customer'
    required int? callerId,
    required int? receiverId,
  }) async {
    if (!Get.isRegistered<ApiClient>()) return null;
    try {
      final res = await Get.find<ApiClient>().postData(tokenUri, {
        'order_id': orderId,
        'caller_type': callerType,
        'caller_id': callerId,
        'receiver_id': receiverId,
      });
      if (res.statusCode == 200 && res.body is Map) {
        return CallTokenModel.fromJson(
            Map<String, dynamic>.from(res.body as Map),
            fallbackAppId: appId);
      }
    } catch (_) {/* fall through to null */}
    return null;
  }
}
