import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/auth/domain/models/auth_response_model.dart';
import 'package:sixam_mart/features/auth/domain/models/otp_auth_models.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/features/auth/domain/services/auth_service_interface.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AuthService implements AuthServiceInterface {
  final AuthRepositoryInterface authRepositoryInterface;
  AuthService({required this.authRepositoryInterface});

  @override
  bool isSharedPrefNotificationActive() {
    return authRepositoryInterface.isSharedPrefNotificationActive();
  }

  @override
  Future<ResponseModel> registration(SignUpBodyModel signUpBody) async {
    final Response response =
        await authRepositoryInterface.registration(signUpBody);
    if (response.statusCode == 200) {
      await authRepositoryInterface.clearQrReferralInstallToken();
      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse);
      return ResponseModel(true, authResponse.token ?? '',
          authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> login(
      {required String emailOrPhone,
      required String password,
      required String loginType,
      required String fieldType,
      bool alreadyInApp = false}) async {
    debugPrint('AUTH SERVICE LOGIN CALLED');
    debugPrint('loginType=$loginType hasPassword=${password.isNotEmpty}');
    final Response response = await authRepositoryInterface.login(
        emailOrPhone: emailOrPhone,
        password: password,
        loginType: loginType,
        fieldType: fieldType);
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody =
          (response.body is Map<String, dynamic>)
              ? response.body as Map<String, dynamic>
              : <String, dynamic>{};

      final bool otpRequired = responseBody['otp_required'] == true ||
          responseBody['otp_required'] == 1;
      if (otpRequired) {
        final String otpPhone =
            responseBody['phone']?.toString() ?? emailOrPhone;

        return ResponseModel(true, 'otp_required',
            otpRequired: true, otpPhone: otpPhone);
      }

      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(responseBody);
      await _updateHeaderFunctionality(authResponse,
          alreadyInApp: alreadyInApp);

      // ? PERFORMANCE: Extract user data from login response and update controllers immediately
      _updateUserDataFromLoginResponse(responseBody);

      return ResponseModel(true, authResponse.token ?? '',
          authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  // ===== Passwordless auth (v2) =====

  Map<String, dynamic> _asMap(Response response) =>
      (response.body is Map<String, dynamic>)
          ? response.body as Map<String, dynamic>
          : <String, dynamic>{};

  /// Persist token + user payload from a v2 success body (verify-otp existing
  /// user, or register). Reuses the legacy token storage so the rest of the app
  /// keeps working unchanged.
  Future<void> _handleV2AuthSuccess(Map<String, dynamic> responseBody) async {
    final String token = responseBody['token']?.toString() ?? '';
    if (token.isNotEmpty) {
      await authRepositoryInterface.saveUserToken(token);
      await authRepositoryInterface.updateToken();
      await authRepositoryInterface.clearSharedPrefGuestId();
    }
    _updateUserDataFromLoginResponse(responseBody);
  }

  @override
  Future<OtpSendResult> sendOtp({required String phone}) async {
    final Response response =
        await authRepositoryInterface.sendOtpV2(phone: phone);
    final Map<String, dynamic> body = _asMap(response);
    if (response.statusCode == 200 && body['success'] == true) {
      return OtpSendResult.fromJson(body);
    }
    return OtpSendResult.failure(
      body['message']?.toString() ?? response.statusText,
      errorCode: body['code']?.toString(),
    );
  }

  @override
  Future<OtpVerifyResult> verifyOtp(
      {required String phone, required String otp}) async {
    final Response response =
        await authRepositoryInterface.verifyOtpV2(phone: phone, otp: otp);
    final Map<String, dynamic> body = _asMap(response);
    if (response.statusCode == 200 && body['success'] == true) {
      final OtpVerifyResult result = OtpVerifyResult.fromJson(body);
      if (result.isExisted) {
        await _handleV2AuthSuccess(body);
      }
      return result;
    }
    return OtpVerifyResult.failure(
      body['message']?.toString() ?? response.statusText,
      errorCode: body['code']?.toString(),
    );
  }

  @override
  Future<ResponseModel> registerV2({
    required String name,
    String? email,
    required String phone,
    required String registrationToken,
    String? refCode,
  }) async {
    debugPrint('[REGISTER_V2] phone=$phone tokenLen=${registrationToken.length}'
        ' name="$name" email="${email ?? ''}"');
    final Response response = await authRepositoryInterface.registerV2(
      name: name,
      email: email,
      phone: phone,
      registrationToken: registrationToken,
      refCode: refCode,
    );
    final Map<String, dynamic> body = _asMap(response);
    debugPrint('[REGISTER_V2][RESPONSE] status=${response.statusCode} '
        'body=${response.body}');
    // The register endpoint returns 201 (Created) on success; older builds only
    // accepted 200, which silently dropped the token (account created but user
    // left logged-out, and the guest-cart migration unseen). Accept both.
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      await authRepositoryInterface.clearQrReferralInstallToken();
      await _handleV2AuthSuccess(body);
      // Build a fully-verified auth response so the post-login cart transfer
      // path (in AuthController) triggers like a normal login.
      final AuthResponseModel authResponse = AuthResponseModel(
        token: body['token']?.toString(),
        isPhoneVerified: true,
        isEmailVerified: true,
        isPersonalInfo: true,
      );
      return ResponseModel(true, authResponse.token ?? '',
          authResponseModel: authResponse);
    }
    // Surface the backend code/message so the screen can show a real reason.
    final String? code = body['code']?.toString();
    final String? message = body['message']?.toString();
    return ResponseModel(
      false,
      code ?? message ?? response.statusText,
    );
  }

  @override
  Future<ResponseModel> verifyLoginOtp(
      {required String phone,
      required String otp,
      bool alreadyInApp = false}) async {
    final Response response =
        await authRepositoryInterface.verifyLoginOtp(phone: phone, otp: otp);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody =
          (response.body is Map<String, dynamic>)
              ? response.body as Map<String, dynamic>
              : <String, dynamic>{};
      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(responseBody);
      if (authResponse.token == null || authResponse.token!.isEmpty) {
        return ResponseModel(false, 'Login not completed: missing token');
      }

      if (!responseBody.containsKey('is_phone_verified')) {
        authResponse.isPhoneVerified = true;
      }
      if (!responseBody.containsKey('is_personal_info')) {
        authResponse.isPersonalInfo = true;
      }
      if (!responseBody.containsKey('is_email_verified')) {
        authResponse.isEmailVerified = true;
      }

      await _updateHeaderFunctionality(authResponse,
          alreadyInApp: alreadyInApp);
      _updateUserDataFromLoginResponse(responseBody);
      return ResponseModel(true, authResponse.token ?? '',
          authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  /// ? PERFORMANCE: Update user data from login response (minimal data for instant menu rendering)
  /// Extracts user data and wallet flags from login response and updates controllers immediately
  void _updateUserDataFromLoginResponse(Map<String, dynamic> responseBody) {
    try {
      debugPrint('🔍 AuthService: Checking login response for user data...');

      // Check if user data exists in response (backend will add 'user' field)
      if (responseBody.containsKey('user') && responseBody['user'] is Map) {
        final userData = responseBody['user'] as Map<String, dynamic>;
        debugPrint('✅ AuthService: User data found in login response');
        debugPrint('   - ID: ${userData['id']}');
        debugPrint('   - Name: ${userData['f_name']} ${userData['l_name']}');
        debugPrint('   - Loyalty Points: ${userData['loyalty_point'] ?? 0}');
        debugPrint('   - Wallet Balance: ${userData['wallet_balance'] ?? 0.0}');
        debugPrint(
            '   - Has Qidha Wallet: ${userData['has_qidha_wallet'] ?? false}');

        // Update ProfileController with minimal user data
        if (Get.isRegistered<ProfileController>()) {
          debugPrint(
              '📝 AuthService: Updating ProfileController with user data...');
          final profileController = Get.find<ProfileController>();
          profileController.setUserInfoFromLogin(
            id: userData['id'] is int
                ? userData['id'] as int
                : int.tryParse(userData['id']?.toString() ?? '0'),
            fName: userData['f_name']?.toString(),
            lName: userData['l_name']?.toString(),
            imageFullUrl:
                (userData['image_full_url'] ?? userData['image'])?.toString(),
            loyaltyPoint: userData['loyalty_point'] is int
                ? userData['loyalty_point'] as int
                : (int.tryParse(userData['loyalty_point']?.toString() ?? '0') ??
                    0),
            // ⚡ FIX: Safe parsing - handle both String and numeric values
            walletBalance: (userData['wallet_balance'] is String)
                ? (double.tryParse(userData['wallet_balance'] as String) ?? 0.0)
                : ((userData['wallet_balance'] is num)
                    ? (userData['wallet_balance'] as num).toDouble()
                    : 0.0),
          );
          debugPrint('✅ AuthService: ProfileController updated successfully');
        } else {
          debugPrint('⚠️ AuthService: ProfileController not registered');
        }

        // Update Qidha wallet state if wallet exists
        if (userData['has_qidha_wallet'] == true) {
          debugPrint(
              '💳 AuthService: User has Qidha wallet - updating wallet state...');
          debugPrint(
              '   - Signed: ${userData['qidha_wallet_signed'] ?? false}');
          debugPrint(
              '   - Active: ${userData['qidha_wallet_active'] ?? false}');
          debugPrint(
              '   - Balance: ${userData['qidha_wallet_balance'] ?? 'null'}');

          if (Get.isRegistered<KaidhaSubscriptionController>()) {
            final kaidhaController = Get.find<KaidhaSubscriptionController>();
            kaidhaController.setWalletStateFromLogin(
              signed: userData['qidha_wallet_signed'] == true,
              active: userData['qidha_wallet_active'] == true,
              balance: userData['qidha_wallet_balance']?.toString(),
            );
            debugPrint('✅ AuthService: Wallet state updated successfully');

            // Only fetch full wallet data if wallet is not signed/active (needed for subscription flow)
            final qidhaWalletSigned = userData['qidha_wallet_signed'] is bool
                ? userData['qidha_wallet_signed'] as bool
                : (userData['qidha_wallet_signed']?.toString() == '1' ||
                    userData['qidha_wallet_signed']?.toString() == 'true');
            final qidhaWalletActive = userData['qidha_wallet_active'] is bool
                ? userData['qidha_wallet_active'] as bool
                : (userData['qidha_wallet_active']?.toString() == '1' ||
                    userData['qidha_wallet_active']?.toString() == 'true');
            if (!qidhaWalletSigned || !qidhaWalletActive) {
              debugPrint(
                  '🔄 AuthService: Wallet not signed/active - loading full wallet data in background...');
              // Load full wallet data in background (non-blocking) - needed for subscription flow
              kaidhaController.get_Wallet_Kaidh();
            } else {
              debugPrint(
                  '⚡ AuthService: Wallet is signed and active - no API call needed (balance already set)');
            }
          } else {
            debugPrint(
                '⚠️ AuthService: KaidhaSubscriptionController not registered');
          }
        } else {
          debugPrint('ℹ️ AuthService: User has no Qidha wallet');
        }
      } else {
        debugPrint(
            '⚠️ AuthService: No user data in login response (backend may not have updated yet)');
        debugPrint('   - Response keys: ${responseBody.keys.toList()}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            '❌ AuthService: Error updating user data from login response - $e');
        debugPrint('   Stack trace: $stackTrace');
      }
      // Don't throw - login should still succeed even if user data extraction fails
    }
  }

  Future<void> _updateHeaderFunctionality(AuthResponseModel authResponse,
      {bool alreadyInApp = false}) async {
    if ((authResponse.isPhoneVerified ?? false) &&
        (authResponse.isPersonalInfo ?? false) &&
        authResponse.token != null &&
        authResponse.isExistUser == null) {
      // 🔧 CRITICAL FIX: saveUserToken now updates headers IMMEDIATELY (synchronously)
      // Headers are updated before any async operations complete
      // This ensures updateToken() and getUserInfo() calls have the correct token
      await authRepositoryInterface.saveUserToken(authResponse.token ?? '',
          alreadyInApp: alreadyInApp);
      // ✅ Headers are already updated by saveUserToken, safe to call updateToken now
      await authRepositoryInterface.updateToken();
      await authRepositoryInterface.clearSharedPrefGuestId();
    }
  }

  @override
  Future<ResponseModel> otpLogin(
      {required String phone,
      required String otp,
      required String loginType,
      required String verified,
      bool alreadyInApp = false}) async {
    final Response response = await authRepositoryInterface.otpLogin(
        phone: phone, otp: otp, loginType: loginType, verified: verified);
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody =
          (response.body is Map<String, dynamic>)
              ? response.body as Map<String, dynamic>
              : <String, dynamic>{};
      final bool hasToken = responseBody['token'] != null;
      if (hasToken) {
        final AuthResponseModel authResponse =
            AuthResponseModel.fromJson(responseBody);
        await _updateHeaderFunctionality(authResponse,
            alreadyInApp: alreadyInApp);
        _updateUserDataFromLoginResponse(responseBody);
        return ResponseModel(true, authResponse.token ?? '',
            authResponseModel: authResponse);
      }
      return ResponseModel(true, response.statusText ?? 'success');
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> resendOtp({required String phone}) async {
    final Response response =
        await authRepositoryInterface.resend_Otp(phone: phone);
    if (response.statusCode == 200) {
      return ResponseModel(true, response.statusText ?? 'success');
    } else {
      final dynamic body = response.body;
      final String responseMessage = body is Map<String, dynamic>
          ? (body['message']?.toString() ??
              response.statusText ??
              'unknown_error')
          : (response.statusText ?? 'unknown_error');
      final String statusCode = (response.statusCode ?? -1).toString();
      final String errorDetails =
          'Resend OTP failed (status: $statusCode, endpoint: ${AppConstants.resendOtpUri}, message: $responseMessage)';
      if (kDebugMode) {
        debugPrint('AuthService: $errorDetails');
      }
      return ResponseModel(false, errorDetails);
    }
  }

  @override
  Future<ResponseModel> guestLogin() async {
    return await authRepositoryInterface.guestLogin();
  }

  @override
  Future<ResponseModel> loginWithSocialMedia(SocialLogInBody socialLogInBody,
      {bool isCustomerVerificationOn = false}) async {
    final Response response =
        await authRepositoryInterface.loginWithSocialMedia(socialLogInBody);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse);
      _updateUserDataFromLoginResponse(response.body as Map<String, dynamic>);
      return ResponseModel(true, authResponse.token ?? '',
          authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> updatePersonalInfo(
      {required String name,
      required String? phone,
      required String loginType,
      required String? email,
      required String? referCode,
      bool alreadyInApp = false}) async {
    final Response response = await authRepositoryInterface.updatePersonalInfo(
        name: name,
        phone: phone,
        email: email,
        loginType: loginType,
        referCode: referCode);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse,
          alreadyInApp: alreadyInApp);
      _updateUserDataFromLoginResponse(response.body as Map<String, dynamic>);
      return ResponseModel(true, authResponse.token ?? '',
          authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<Response> updateToken({bool forAuth001Recovery = false}) async {
    return authRepositoryInterface.updateToken(
      forAuth001Recovery: forAuth001Recovery,
    );
  }

  @override
  bool isLoggedIn() {
    return authRepositoryInterface.isLoggedIn();
  }

  @override
  bool isGuestLoggedIn() {
    return authRepositoryInterface.isGuestLoggedIn();
  }

  @override
  String getSharedPrefGuestId() {
    return authRepositoryInterface.getSharedPrefGuestId();
  }

  @override
  Future<bool> clearSharedPrefGuestId() async {
    return await authRepositoryInterface.clearSharedPrefGuestId();
  }

  @override
  Future<bool> clearSharedData({bool removeToken = true}) async {
    return await authRepositoryInterface.clearSharedData(
        removeToken: removeToken);
  }

  @override
  Future<bool> clearSharedAddress() async {
    return await authRepositoryInterface.clearSharedAddress();
  }

  @override
  Future<void> saveUserNumberAndPassword(
      String number, String password, String countryCode) async {
    await authRepositoryInterface.saveUserNumberAndPassword(
        number, password, countryCode);
  }

  @override
  String getUserNumber() {
    return authRepositoryInterface.getUserNumber();
  }

  @override
  String getUserCountryCode() {
    return authRepositoryInterface.getUserCountryCode();
  }

  @override
  String getUserPassword() {
    return authRepositoryInterface.getUserPassword();
  }

  @override
  Future<bool> clearUserNumberAndPassword() async {
    return await authRepositoryInterface.clearUserNumberAndPassword();
  }

  @override
  String getUserToken() {
    return authRepositoryInterface.getUserToken();
  }

  @override
  Future updateZone() async {
    await authRepositoryInterface.updateZone();
  }

  @override
  Future<bool> saveGuestContactNumber(String number) async {
    return authRepositoryInterface.saveGuestContactNumber(number);
  }

  @override
  String getGuestContactNumber() {
    return authRepositoryInterface.getGuestContactNumber();
  }

  /// Persists the selected delivery-man tip index.
  @override
  Future<bool> saveDmTipIndex(String index) async {
    return await authRepositoryInterface.saveDmTipIndex(index);
  }

  @override
  String getDmTipIndex() {
    return authRepositoryInterface.getDmTipIndex();
  }

  @override
  Future<bool> saveEarningPoint(String point) async {
    return await authRepositoryInterface.saveEarningPoint(point);
  }

  @override
  String getEarningPint() {
    return authRepositoryInterface.getEarningPint();
  }

  @override
  Future<bool> setNotificationActive(bool isActive) async {
    return authRepositoryInterface.setNotificationActive(isActive);
  }

  @override
  Future<String?> saveDeviceToken() async {
    return await authRepositoryInterface.saveDeviceToken();
  }
}
