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

  bool _hasError = false;
  bool get hasError => _hasError;

  /// جلب قائمة الأصدقاء المدعوين من الـ API.
  Future<void> getInvitedFriends({
    int offset = 1,
    int limit = 10,
    bool reload = true,
  }) async {
    if (reload || _invitedFriends == null) {
      _isLoading = true;
      _hasError = false;
      update();
    }

    try {
      final Response response = await apiClient.getData(
        '/api/v2/customer/referrals/invited-friends?offset=$offset&limit=$limit',
      );

      if (response.statusCode == 200 && response.body != null) {
        final dynamic body = response.body;
        Map<String, dynamic>? map;
        if (body is Map) {
          final Map<String, dynamic> root = body.cast<String, dynamic>();
          // بعض النقاط تُغلّف الاستجابة داخل data
          map = root['data'] is Map
              ? (root['data'] as Map).cast<String, dynamic>()
              : root;
        }
        if (map != null) {
          _invitedFriends = InvitedFriendsModel.fromJson(map);
          _hasError = false;
        } else {
          _hasError = true;
        }
      } else if (response.statusCode == 304 && _invitedFriends != null) {
        // لا تغيير — أبقِ البيانات الحالية
      } else {
        _hasError = true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ReferralController] getInvitedFriends error: $e');
      }
      _hasError = true;
    }

    _isLoading = false;
    update();
  }
}
