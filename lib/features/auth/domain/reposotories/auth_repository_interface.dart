// ignore_for_file: non_constant_identifier_names

import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class AuthRepositoryInterface extends RepositoryInterface {
  bool isSharedPrefNotificationActive();
  Future<Response> registration(SignUpBodyModel signUpBody);
  Future<void> clearQrReferralInstallToken();
  //Future<Response> login({String? phone, String? password});
  Future<Response> login(
      {required String emailOrPhone, required String password, required String loginType, required String fieldType});
  Future<Response> otpLogin({required String phone, required String otp, required String loginType, required String verified});
  Future<Response> verifyLoginOtp({required String phone, required String otp});

  // ===== Passwordless auth (v2) =====
  Future<Response> sendOtpV2({required String phone});
  Future<Response> verifyOtpV2({required String phone, required String otp});
  Future<Response> registerV2({
    required String name,
    String? email,
    required String phone,
    required String registrationToken,
    String? refCode,
  });

  Future<Response> resend_Otp({required String phone});

  Future<Response> updatePersonalInfo(
      {required String name, required String? phone, required String loginType, required String? email, required String? referCode});
  //Future<bool> saveUserToken(String token);
  Future<bool> saveUserToken(String token, {bool alreadyInApp = false});
  Future<Response> updateToken({
    String notificationDeviceToken = '',
    bool profileNotificationToggleTrace = false,
    bool? profileNotificationRequestedActive,
    bool forAuth001Recovery = false,
  });
  Future<bool> saveSharedPrefGuestId(String id);
  String getSharedPrefGuestId();
  Future<bool> clearSharedPrefGuestId();
  bool isGuestLoggedIn();
  Future<bool> clearSharedData({bool removeToken = true});
  Future<ResponseModel> guestLogin();
  //Future<Response> loginWithSocialMedia(SocialLogInBody socialLogInBody, int timeout);
  Future<Response> loginWithSocialMedia(SocialLogInBody socialLogInModel);
  bool isLoggedIn();
  Future<bool> clearSharedAddress();
  Future<void> saveUserNumberAndPassword(String number, String password, String countryCode);
  String getUserNumber();
  String getUserCountryCode();
  String getUserPassword();
  Future<bool> clearUserNumberAndPassword();
  String getUserToken();
  Future<Response> updateZone();
  Future<bool> saveGuestContactNumber(String number);
  String getGuestContactNumber();

  /// Persists the selected delivery-man tip index.
  Future<bool> saveDmTipIndex(String index);
  String getDmTipIndex();
  Future<bool> saveEarningPoint(String point);
  String getEarningPint();
  Future<bool> setNotificationActive(bool isActive);
  Future<String?> saveDeviceToken();
}
