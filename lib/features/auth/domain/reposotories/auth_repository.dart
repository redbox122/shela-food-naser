// ignore_for_file: override_on_non_overriding_member, non_constant_identifier_names

import 'dart:convert';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_connect/connect.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/security/secure_token_storage.dart';
import 'package:sixam_mart/common/utils/secure_log.dart';
import 'package:sixam_mart/features/auth/helper/qr_referral_token_storage.dart';

class AuthRepository implements AuthRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  AuthRepository({required this.sharedPreferences, required this.apiClient});

  static bool _isCmFirebaseTokenApiSuccess(Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      return false;
    }
    if (response.body is! Map) {
      return false;
    }
    final Map<dynamic, dynamic> m = response.body! as Map<dynamic, dynamic>;
    if (m.containsKey('success')) {
      return m['success'] == true;
    }
    return true;
  }

  Future<void> _rollbackFirebaseSubscriptionsAfterFailedEnable() async {
    if (GetPlatform.isWeb) {
      return;
    }
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.topic);
      if (isLoggedIn()) {
        final int? zoneId =
            AddressHelper.getUserAddressFromSharedPref()?.zoneId;
        if (zoneId != null) {
          await FirebaseMessaging.instance
              .unsubscribeFromTopic('zone_${zoneId}_customer');
        }
      }
    } catch (_) {}
  }

  static String _profileNotificationRawBody(dynamic body) {
    if (body == null) {
      return '';
    }
    if (body is String) {
      return body;
    }
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  static void _logProfileNotificationRequest({
    required String method,
    required String path,
    required String fullUrl,
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    required bool? requestedNotificationActive,
    required bool? previousNotificationPref,
  }) {
    debugPrint('[ProfileNotification][REQUEST]');
    debugPrint('- method: $method');
    debugPrint('- url/path: $fullUrl (path: $path)');
    debugPrint('- body: ${_profileNotificationRawBody(body)}');
    debugPrint(
        '- query params: ${queryParameters == null || queryParameters.isEmpty ? '(none)' : _profileNotificationRawBody(queryParameters)}');
    debugPrint(
        '- toggle: requestedNotificationActive=$requestedNotificationActive, previousSharedPrefNotification=$previousNotificationPref');
  }

  static void _logProfileNotificationResponse(Response response) {
    debugPrint('[ProfileNotification][RESPONSE]');
    debugPrint('- status code: ${response.statusCode}');
    debugPrint(
        '- raw response body: ${_profileNotificationRawBody(response.body ?? response.bodyString)}');
  }

  static void _logProfileNotificationErrorFromResponse({
    required Response response,
    required String path,
    required Map<String, dynamic> requestBody,
  }) {
    debugPrint('[ProfileNotification][ERROR]');
    debugPrint('- status code: ${response.statusCode}');
    debugPrint(
        '- raw error response body: ${_profileNotificationRawBody(response.body ?? response.bodyString)}');
    debugPrint('- endpoint path: $path');
    debugPrint('- request body: ${_profileNotificationRawBody(requestBody)}');
  }

  static void _logProfileNotificationDioError({
    required Object error,
    required String path,
    required Map<String, dynamic> requestBody,
  }) {
    debugPrint('[ProfileNotification][ERROR]');
    if (error is dio_pkg.DioException) {
      debugPrint('- status code: ${error.response?.statusCode}');
      debugPrint(
          '- raw error response body: ${_profileNotificationRawBody(error.response?.data)}');
    } else {
      debugPrint('- status code: (no response)');
      debugPrint('- raw error response body: (none)');
    }
    debugPrint('- endpoint path: $path');
    debugPrint('- request body: ${_profileNotificationRawBody(requestBody)}');
    debugPrint('- exception: $error');
  }

  @override
  bool isSharedPrefNotificationActive() {
    return sharedPreferences.getBool(AppConstants.notification) ?? true;
  }

  bool _shouldAttachGuestId(String guestId) {
    if (guestId.isEmpty) {
      return false;
    }
    final List<String>? cachedCart =
        sharedPreferences.getStringList(AppConstants.cartList);
    if (cachedCart == null || cachedCart.isEmpty) {
      return false;
    }
    for (final String item in cachedCart) {
      if (item.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  QrReferralTokenStorage get _qrReferralTokenStorage =>
      QrReferralTokenStorage(sharedPreferences);

  @override
  Future<void> clearQrReferralInstallToken() async {
    await _qrReferralTokenStorage.clearToken();
  }

  @override
  Future<Response> registration(SignUpBodyModel signUpBody) async {
    final Map<String, dynamic> payload = signUpBody.toJson();
    final String? qrReferralToken = _qrReferralTokenStorage.getStoredToken();
    if (qrReferralToken != null && qrReferralToken.isNotEmpty) {
      payload['referral_token'] = qrReferralToken;
      debugPrint(
        '[QR_REFERRAL_SIGNUP_PAYLOAD_ATTACHED] token=$qrReferralToken',
      );
    }
    return await apiClient.postData(
      AppConstants.registerUri,
      payload,
      handleError: false,
    );
  }

  // ================

  @override
  Future<Response> login({
    required String emailOrPhone,
    required String password,
    required String loginType,
    required String fieldType,
    bool alreadyInApp = false,
  }) async {
    final String guestId = getSharedPrefGuestId();

    final Map<String, String> data = {
      'password': password,
      'login_type': loginType,
      'field_type': fieldType,
    };
    if (fieldType == 'phone') {
      data['phone'] = emailOrPhone;
    } else {
      data['email'] = emailOrPhone;
    }

    if (_shouldAttachGuestId(guestId)) {
      data.addAll({'guest_id': guestId});
    }
    return await apiClient.postData(
      AppConstants.loginUri,
      data,
      handleError: false,
    );
  }

  @override
  Future<Response> verifyLoginOtp(
      {required String phone, required String otp}) async {
    final Map<String, String> data = {
      'phone': phone,
      'otp': otp,
    };
    return await apiClient.postData(
      AppConstants.verifyLoginOtpUri,
      data,
      handleError: false,
    );
  }

  // ===== Passwordless auth (v2) =====

  @override
  Future<Response> sendOtpV2({required String phone}) async {
    return await apiClient.postData(
      AppConstants.sendOtpV2Uri,
      {'phone': phone},
      handleError: false,
    );
  }

  @override
  Future<Response> verifyOtpV2(
      {required String phone, required String otp}) async {
    final Map<String, dynamic> data = {'phone': phone, 'otp': otp};
    final String guestId = getSharedPrefGuestId();
    if (_shouldAttachGuestId(guestId)) {
      data['guest_id'] = guestId;
    }
    return await apiClient.postData(
      AppConstants.verifyOtpV2Uri,
      data,
      handleError: false,
    );
  }

  @override
  Future<Response> registerV2({
    required String name,
    String? email,
    required String phone,
    required String registrationToken,
    String? refCode,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'phone': phone,
      'registration_token': registrationToken,
    };
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }
    if (refCode != null && refCode.isNotEmpty) {
      data['ref_code'] = refCode;
    }
    // QR / vendor referral captured from install-referrer or a landing page.
    final String? qrReferralToken = _qrReferralTokenStorage.getStoredToken();
    if (qrReferralToken != null && qrReferralToken.isNotEmpty) {
      data['referral_token'] = qrReferralToken;
      debugPrint('[QR_REFERRAL_REGISTER_V2_ATTACHED] token=<redacted>');
    }
    final String guestId = getSharedPrefGuestId();
    if (_shouldAttachGuestId(guestId)) {
      data['guest_id'] = guestId;
    }
    return await apiClient.postData(
      AppConstants.registerV2Uri,
      data,
      handleError: false,
    );
  }

  @override
  Future<Response> otpLogin(
      {required String phone,
      required String otp,
      required String loginType,
      required String verified}) async {
    final Map<String, String> data = {'phone': phone};
    if (otp.isNotEmpty) {
      data.addAll({'otp': otp});
      return await apiClient.postData(AppConstants.verifyPhoneUri, data,
          handleError: false);
    }
    return await apiClient.postData(AppConstants.resendOtpUri, data,
        handleError: false);
  }

  @override
  Future<Response> resend_Otp({required String phone}) async {
    final Map<String, String> data = {
      'phone': phone,
    };

    return await apiClient.postData(AppConstants.resendOtpUri, data,
        handleError: false);
  }

  @override
  Future<ResponseModel> guestLogin() async {
    ResponseModel? responseModel;

    final String? deviceToken = await saveDeviceToken();
    final Response response = await apiClient
        .postData(AppConstants.guestLoginUri, {'fcm_token': deviceToken});

    if (response.statusCode == 200 && response.body != null) {
      final String guestId = response.body['guest_id'].toString();
      debugPrint('\x1B[32m     guest_id from response: $guestId     \x1B[0m');

      await saveSharedPrefGuestId(guestId);

      // طباعة القيمة المحفوظة بعد الاسترجاع من SharedPreferences
      final String storedGuestId = getSharedPrefGuestId();

      debugPrint(
          '\x1B[34m     guest_id from SharedPreferences: $storedGuestId     \x1B[0m');

      responseModel = ResponseModel(true, guestId);
    } else {
      responseModel = ResponseModel(false, response.statusText ?? 'error');
    }

    return responseModel;
  }

  @override
  Future<Response> updatePersonalInfo(
      {required String name,
      required String? phone,
      required String loginType,
      required String? email,
      required String? referCode}) async {
    final Map<String, String> data = {
      'login_type': loginType,
      'name': name,
      'ref_code': referCode ?? '',
    };
    if (phone != null && phone.isNotEmpty) {
      data.addAll({'phone': phone});
    }
    if (email != null && email.isNotEmpty) {
      data.addAll({'email': email});
    }
    return await apiClient.postData(AppConstants.personalInformationUri, data,
        handleError: false);
  }

/*  @override
  Future<Response> loginWithSocialMedia(SocialLogInBody socialLogInBody, int timeout) async {
    return await apiClient.postData(AppConstants.socialLoginUri, socialLogInBody.toJson(), timeout: timeout);
  }*/

  @override
  Future<Response> loginWithSocialMedia(
      SocialLogInBody socialLogInModel) async {
    final String guestId = getSharedPrefGuestId();
    final Map<String, dynamic> data = socialLogInModel.toJson();
    if (_shouldAttachGuestId(guestId)) {
      data.addAll({'guest_id': guestId});
    }
    return await apiClient.postData(AppConstants.loginUri, data);
  }

  @override
  Future<bool> saveUserToken(String token, {bool alreadyInApp = false}) async {
    // 🔧 CRITICAL FIX: Update API client token and headers IMMEDIATELY (synchronously)
    // This must happen before any async operations to prevent 401 errors on subsequent API calls
    apiClient.token = token;

    // Get address and zone information for header update
    AddressModel? addressModel;
    if (alreadyInApp &&
        sharedPreferences.getString(AppConstants.userAddress) != null) {
      final rawAddress = sharedPreferences.getString(AppConstants.userAddress);
      if (rawAddress != null && rawAddress.isNotEmpty) {
        final dynamic decodedJson = jsonDecode(rawAddress);
        addressModel =
            AddressModel.fromJson(decodedJson as Map<String, dynamic>);
      }
    } else {
      addressModel = AddressHelper.getUserAddressFromSharedPref();
    }

    // 🔧 CRITICAL FIX: Update headers IMMEDIATELY (synchronously) before any async operations
    // This ensures all subsequent API calls (updateToken, getUserInfo) have the correct token
    apiClient.updateHeader(
      token,
      addressModel?.zoneIds,
      addressModel?.areaIds,
      sharedPreferences.getString(AppConstants.languageCode),
      ModuleHelper.getModule()?.id,
      addressModel?.latitude,
      addressModel?.longitude,
    );

    if (kDebugMode) {
      final isJWT = token.contains('.');
      debugPrint(
          '🔐 Token and headers updated IMMEDIATELY: ${isJWT ? "JWT" : "Passport"} token');
      debugPrint('✅ Headers updated before async storage operations');
    }

    // Now save token securely (async operation - can happen in background)
    final secureSaveSuccess = await SecureTokenStorage.saveToken(token);

    if (!secureSaveSuccess) {
      if (kDebugMode) {
        debugPrint(
            '❌ Failed to save token securely, falling back to legacy storage');
      }
      // Fallback to legacy storage for backward compatibility
      await sharedPreferences.setString(AppConstants.token, token);
      return false;
    }

    // Also save to legacy storage for backward compatibility
    await sharedPreferences.setString(AppConstants.token, token);

    if (kDebugMode) {
      debugPrint('🔐 Token saved securely with encryption');
    }

    return secureSaveSuccess;
  }

  @override
  Future<Response> updateToken({
    String notificationDeviceToken = '',
    bool profileNotificationToggleTrace = false,
    bool? profileNotificationRequestedActive,
    bool forAuth001Recovery = false,
  }) async {
    final bool? previousNotificationPref =
        sharedPreferences.containsKey(AppConstants.notification)
            ? sharedPreferences.getBool(AppConstants.notification)
            : null;
    String? deviceToken;
    if (notificationDeviceToken.isEmpty) {
      if (GetPlatform.isIOS && !GetPlatform.isWeb) {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
        final NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          deviceToken = await saveDeviceToken();
        }
      } else {
        deviceToken = await saveDeviceToken();
      }
      if (!GetPlatform.isWeb) {
        final zoneId = AddressHelper.getUserAddressFromSharedPref()?.zoneId ??
            'default_zone';

        FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic);
        FirebaseMessaging.instance.subscribeToTopic('zone_${zoneId}_customer');
      }
    }
    final Map<String, dynamic> requestBody = {
      '_method': 'put',
      'cm_firebase_token': notificationDeviceToken.isNotEmpty
          ? notificationDeviceToken
          : deviceToken
    };
    const String path = AppConstants.tokenUri;
    final String fullUrl = '${apiClient.appBaseUrl}$path';
    if (profileNotificationToggleTrace) {
      _logProfileNotificationRequest(
        method: 'POST',
        path: path,
        fullUrl: fullUrl,
        body: requestBody,
        queryParameters: const <String, dynamic>{},
        requestedNotificationActive: profileNotificationRequestedActive,
        previousNotificationPref: previousNotificationPref,
      );
    }
    try {
      final Response response = await apiClient.postData(
        path,
        requestBody,
        handleError: false,
        skipAuthDeferredRetry: forAuth001Recovery,
      );
      if (profileNotificationToggleTrace) {
        _logProfileNotificationResponse(response);
        final int? code = response.statusCode;
        if (code == null || code < 200 || code >= 300) {
          _logProfileNotificationErrorFromResponse(
            response: response,
            path: path,
            requestBody: requestBody,
          );
        }
      }
      return response;
    } catch (e) {
      if (profileNotificationToggleTrace) {
        _logProfileNotificationDioError(
          error: e,
          path: path,
          requestBody: requestBody,
        );
      }
      rethrow;
    }
  }

  @override
  Future<String?> saveDeviceToken() async {
    String? deviceToken = '@';
    if (!GetPlatform.isWeb) {
      try {
        deviceToken = await FirebaseMessaging.instance.getToken();
        if (deviceToken == null) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ AuthRepository: Firebase token is null - Firebase may not be initialized or permissions not granted');
          }
        }
      } catch (e) {
        // 🔧 FIX: Better error handling for Firebase token
        if (kDebugMode) {
          final errorString = e.toString();
          if (errorString.contains('TOKEN_NOT_FOUND') ||
              errorString.contains('FirebaseApp') ||
              errorString.contains('not initialized') ||
              errorString.contains('SERVICE_NOT_AVAILABLE')) {
            debugPrint(
                '⚠️ AuthRepository: Firebase token loading failed - Firebase may not be initialized yet or FCM is temporarily unavailable');
            debugPrint(
                '   - This is expected during app startup, on weak network, or without Google Play Services');
            debugPrint('   - Token will be retried when Firebase is ready');
          } else {
            debugPrint('❌ AuthRepository: Firebase token loading error: $e');
          }
        }
        // Return default token to prevent null errors
        deviceToken = '@';
      }
    }
    if (deviceToken != null && deviceToken != '@') {
      if (kDebugMode) {
        debugPrint(
            '✅ AuthRepository: Device Token loaded: ${SecureLog.maskToken(deviceToken)}');
      }
    }
    return deviceToken;
  }

  @override
  bool isLoggedIn() {
    // Check both secure and legacy storage for backward compatibility
    final hasLegacyToken = sharedPreferences.containsKey(AppConstants.token);

    // Note: Since SecureTokenStorage methods are async, we'll check legacy storage
    // In production, consider making this method async or using a different approach
    if (hasLegacyToken) {
      // Trigger async check of secure storage
      _checkSecureTokenStatus();
    }

    return hasLegacyToken;
  }

  /// Check secure token status asynchronously
  Future<void> _checkSecureTokenStatus() async {
    try {
      final hasSecureToken = await SecureTokenStorage.hasValidToken();
      // Only log once per session to avoid spam
      if (!hasSecureToken && kDebugMode && !_hasLoggedTokenWarning) {
        debugPrint(
            '⚠️ Legacy token exists but secure token is invalid/expired');
        _hasLoggedTokenWarning = true;
      }
    } catch (e) {
      if (kDebugMode && !_hasLoggedTokenError) {
        debugPrint('❌ Error checking secure token status: $e');
        _hasLoggedTokenError = true;
      }
    }
  }

  // Static flags to prevent repeated warnings
  static bool _hasLoggedTokenWarning = false;
  static bool _hasLoggedTokenError = false;

  @override
  Future<bool> saveSharedPrefGuestId(String id) async {
    return await sharedPreferences.setString(AppConstants.guestId, id);
  }

  @override
  String getSharedPrefGuestId() {
    return sharedPreferences.getString(AppConstants.guestId) ?? '';
  }

  @override
  Future<bool> clearSharedPrefGuestId() async {
    return await sharedPreferences.remove(AppConstants.guestId);
  }

  @override
  bool isGuestLoggedIn() {
    return sharedPreferences.containsKey(AppConstants.guestId);
  }

  @override
  Future<bool> clearSharedAddress() async {
    await sharedPreferences.remove(AppConstants.userAddress);
    return true;
  }

  @override
  Future<bool> clearSharedData({bool removeToken = true}) async {
    if (!GetPlatform.isWeb) {
      FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.topic);
      final address = AddressHelper.getUserAddressFromSharedPref();
      if (address?.zoneId != null) {
        FirebaseMessaging.instance
            .unsubscribeFromTopic('zone_${address!.zoneId}_customer');
      }
      if (removeToken) {
        apiClient.postData(
            AppConstants.tokenUri, {'_method': 'put', 'cm_firebase_token': '@'},
            handleError: false);
      }
    }

    // Clear secure tokens first
    if (removeToken) {
      try {
        await SecureTokenStorage.clearToken();
        if (kDebugMode) {
          debugPrint('🔐 Secure tokens cleared successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error clearing secure tokens: $e');
        }
      }
    }

    // Clear legacy storage
    sharedPreferences.remove(AppConstants.token);
    sharedPreferences.remove(AppConstants.guestId);
    sharedPreferences.setStringList(AppConstants.cartList, []);
    sharedPreferences.remove(AppConstants.intro); // Reset onboarding status
    sharedPreferences
        .remove('app_install_timestamp'); // Reset install detection
    // sharedPreferences.remove(AppConstants.userAddress);
    apiClient.token = null;
    // apiClient.updateHeader(null, null, null, null, null, null, null);
    await guestLogin();
    if (sharedPreferences.getString(AppConstants.userAddress) != null) {
      final rawAddress = sharedPreferences.getString(AppConstants.userAddress);
      if (rawAddress != null && rawAddress.isNotEmpty) {
        final dynamic decodedJson = jsonDecode(rawAddress);
        final AddressModel addressModel =
            AddressModel.fromJson(decodedJson as Map<String, dynamic>);
        apiClient.updateHeader(
          null,
          addressModel.zoneIds,
          null,
          sharedPreferences.getString(AppConstants.languageCode),
          null,
          addressModel.latitude,
          addressModel.longitude,
        );
      }
    }
    return true;
  }

  @override
  Future<void> saveUserNumberAndPassword(
      String number, String password, String countryCode) async {
    try {
      await sharedPreferences.setString(AppConstants.userPassword, password);
      await sharedPreferences.setString(AppConstants.userNumber, number);
      await sharedPreferences.setString(
          AppConstants.userCountryCode, countryCode);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getUserNumber() {
    return sharedPreferences.getString(AppConstants.userNumber) ?? '';
  }

  @override
  String getUserCountryCode() {
    return sharedPreferences.getString(AppConstants.userCountryCode) ?? '';
  }

  @override
  String getUserPassword() {
    return sharedPreferences.getString(AppConstants.userPassword) ?? '';
  }

  @override
  Future<bool> clearUserNumberAndPassword() async {
    await sharedPreferences.remove(AppConstants.userPassword);
    await sharedPreferences.remove(AppConstants.userCountryCode);
    return await sharedPreferences.remove(AppConstants.userNumber);
  }

  @override
  String getUserToken() {
    // Try to get token from secure storage first
    try {
      // Note: This is a synchronous method, so we'll use the legacy storage
      // In production, consider making this method async or using a different approach
      final legacyToken = sharedPreferences.getString(AppConstants.token) ?? '';

      // If we have a legacy token, try to migrate it to secure storage
      if (legacyToken.isNotEmpty) {
        // This will be handled asynchronously in the background
        _migrateTokenToSecureStorage(legacyToken);
      }

      return legacyToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user token: $e');
      }
      return '';
    }
  }

  /// Clear all stored tokens for testing/debugging
  Future<void> clearAllTokens() async {
    try {
      // Clear secure tokens
      await SecureTokenStorage.clearToken();

      // Clear legacy tokens
      await sharedPreferences.remove(AppConstants.token);

      // Clear API client token
      apiClient.token = null;

      // Update headers to remove Authorization
      apiClient.updateHeader(null, null, null, null, null, null, null);

      if (kDebugMode) {
        debugPrint('🧹 All tokens cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing tokens: $e');
      }
    }
  }

  /// Migrate legacy token to secure storage
  Future<void> _migrateTokenToSecureStorage(String token) async {
    try {
      if (token.isNotEmpty) {
        await SecureTokenStorage.saveToken(token);
        if (kDebugMode) {
          debugPrint('🔄 Legacy token migrated to secure storage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to migrate token to secure storage: $e');
      }
    }
  }

  @override
  Future<Response> updateZone() async {
    return await apiClient.getData(AppConstants.updateZoneUri);
  }

  @override
  Future<bool> saveGuestContactNumber(String number) async {
    return await sharedPreferences.setString(AppConstants.guestNumber, number);
  }

  @override
  String getGuestContactNumber() {
    debugPrint('\x1B[32m     ${AppConstants.guestNumber}     \x1B[0m');

    return sharedPreferences.getString(AppConstants.guestNumber) ?? '';
  }

  /// Persists the selected delivery-man tip index.
  @override
  Future<bool> saveDmTipIndex(String index) async {
    debugPrint('\x1B[32m     ${AppConstants.dmTipIndex} ----  $index  \x1B[0m');

    return await sharedPreferences.setString(AppConstants.dmTipIndex, index);
  }

  @override
  String getDmTipIndex() {
    return sharedPreferences.getString(AppConstants.dmTipIndex) ?? '';
  }

  @override
  Future<bool> saveEarningPoint(String point) async {
    return await sharedPreferences.setString(AppConstants.earnPoint, point);
  }

  @override
  String getEarningPint() {
    return sharedPreferences.getString(AppConstants.earnPoint) ?? '';
  }

  @override
  Future<bool> setNotificationActive(bool isActive) async {
    if (isActive) {
      final Response response = await updateToken(
        profileNotificationToggleTrace: true,
        profileNotificationRequestedActive: isActive,
        forAuth001Recovery: false,
      );
      final bool ok = _isCmFirebaseTokenApiSuccess(response);
      if (ok) {
        await sharedPreferences.setBool(AppConstants.notification, true);
      } else {
        await _rollbackFirebaseSubscriptionsAfterFailedEnable();
      }
      if (kDebugMode) {
        debugPrint('[ProfileNotification][FINAL] saved=$ok toggle=$isActive');
      }
      return ok;
    }
    if (GetPlatform.isWeb) {
      await sharedPreferences.setBool(AppConstants.notification, false);
      if (kDebugMode) {
        debugPrint(
          '[ProfileNotification][FINAL] saved=true toggle=$isActive (web, local only)',
        );
      }
      return true;
    }
    final Response response = await updateToken(
      notificationDeviceToken: '@',
      profileNotificationToggleTrace: true,
      profileNotificationRequestedActive: isActive,
      forAuth001Recovery: false,
    );
    final bool ok = _isCmFirebaseTokenApiSuccess(response);
    if (ok) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.topic);
      if (isLoggedIn()) {
        final int? zoneId =
            AddressHelper.getUserAddressFromSharedPref()?.zoneId;
        if (zoneId != null) {
          await FirebaseMessaging.instance
              .unsubscribeFromTopic('zone_${zoneId}_customer');
        }
      }
      await sharedPreferences.setBool(AppConstants.notification, false);
    }
    if (kDebugMode) {
      debugPrint('[ProfileNotification][FINAL] saved=$ok toggle=$isActive');
    }
    return ok;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
