import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/refer_and_earn/domain/models/invited_friends_model.dart';

class ReferralController extends GetxController implements GetxService {
  final ApiClient apiClient;
  ReferralController({required this.apiClient});

  InvitedFriendsModel? _invitedFriends;
  InvitedFriendsModel? get invitedFriends => _invitedFriends;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Genuine error (server 5xx / auth / connectivity). Distinct from "empty".
  bool _hasError = false;
  bool get hasError => _hasError;

  // True only for a real connectivity failure (no internet) — lets the UI show
  // the right message instead of blaming the network for a server/empty case.
  bool _isNetworkError = false;
  bool get isNetworkError => _isNetworkError;

  static const String _endpoint =
      '/api/v2/customer/referrals/invited-friends';

  /// جلب قائمة الأصدقاء المدعوين من الـ API.
  Future<void> getInvitedFriends({
    int offset = 1,
    int limit = 10,
    bool reload = true,
  }) async {
    if (reload || _invitedFriends == null) {
      _isLoading = true;
      _hasError = false;
      _isNetworkError = false;
      update();
    }

    try {
      final Response response = await apiClient.getData(
        '$_endpoint?offset=$offset&limit=$limit',
        handleError: false, // handle the outcome here (empty vs error).
      );
      final int? code = response.statusCode;

      if (code == 200 && response.body != null) {
        final dynamic body = response.body;
        Map<String, dynamic> map = <String, dynamic>{};
        if (body is Map) {
          final Map<String, dynamic> root = body.cast<String, dynamic>();
          // بعض النقاط تُغلّف الاستجابة داخل data
          map = root['data'] is Map
              ? (root['data'] as Map).cast<String, dynamic>()
              : root;
        }
        // A valid 200 with no friends is an EMPTY list, not an error.
        _invitedFriends = InvitedFriendsModel.fromJson(map);
        _hasError = false;
      } else if (code == 304 && _invitedFriends != null) {
        // لا تغيير — أبقِ البيانات الحالية
      } else if (code == 404) {
        // The invited-friends endpoint/data isn't available on the backend →
        // show the "no invitees yet" empty state, NOT a connection error.
        _invitedFriends ??= InvitedFriendsModel();
        _hasError = false;
        if (kDebugMode) {
          debugPrint(
              '[ReferralController] $_endpoint → 404 (treated as empty). body=${response.body}');
        }
      } else {
        // Real server error (401/403/5xx…): distinct from empty.
        _hasError = true;
        if (kDebugMode) {
          debugPrint(
              '[ReferralController] $_endpoint → status=$code, body=${response.body}');
        }
      }
    } catch (e) {
      // Tell a genuine connectivity failure apart from other exceptions.
      final String msg = e.toString().toLowerCase();
      _isNetworkError = msg.contains('socket') ||
          msg.contains('failed host lookup') ||
          msg.contains('connection') ||
          msg.contains('network');
      _hasError = true;
      if (kDebugMode) {
        debugPrint(
            '[ReferralController] $_endpoint exception (network=$_isNetworkError): $e');
      }
    }

    _isLoading = false;
    update();
  }
}
