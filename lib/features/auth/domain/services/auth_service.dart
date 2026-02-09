import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/auth/domain/models/auth_response_model.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/features/auth/domain/services/auth_service_interface.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';

class AuthService implements AuthServiceInterface {
  final AuthRepositoryInterface authRepositoryInterface;
  AuthService({required this.authRepositoryInterface});

  @override
  bool isSharedPrefNotificationActive() {
    return authRepositoryInterface.isSharedPrefNotificationActive();
  }

  /*@override
  Future<ResponseModel> registration(SignUpBodyModel signUpBody, bool isCustomerVerificationOn) async {
    ResponseModel responseModel = await authRepositoryInterface.registration(signUpBody);
    if(responseModel.isSuccess) {
      if(!isCustomerVerificationOn) {
        authRepositoryInterface.saveUserToken(responseModel.message!);
        await authRepositoryInterface.updateToken();
        authRepositoryInterface.clearSharedPrefGuestId();
      }
    }
    return responseModel;
  }*/

  @override
  Future<ResponseModel> registration(SignUpBodyModel signUpBody) async {
    final Response response = await authRepositoryInterface.registration(signUpBody);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse = AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse);
      return ResponseModel(true, authResponse.token ?? '', authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

/*  @override
  Future<ResponseModel> login({String? phone, String? password, required bool isCustomerVerificationOn}) async {
    Response response = await authRepositoryInterface.login(phone: phone, password: password);
    ResponseModel responseModel;
    if (response.statusCode == 200) {

      // Get.find<AuthController>().firebaseVerifyPhoneNumber(phone!);
      // responseModel = ResponseModel(false, 'success');
      if(isCustomerVerificationOn && response.body['is_phone_verified'] == 0) {

      }else {
        authRepositoryInterface.saveUserToken(response.body['token']);
        await authRepositoryInterface.updateToken();
        authRepositoryInterface.clearSharedPrefGuestId();
      }
      responseModel = ResponseModel(true, '${response.body['is_phone_verified']}${response.body['token']}', isPhoneVerified: response.body['is_phone_verified'] == 1);
    } else {
      responseModel = ResponseModel(false, response.statusText, isPhoneVerified: response.body['is_phone_verified'] == 1);
    }
    return responseModel;
  }*/

  @override
  Future<ResponseModel> login(
      {required String emailOrPhone,
      required String password,
      required String loginType,
      required String fieldType,
      bool alreadyInApp = false}) async {
    final Response response = await authRepositoryInterface.login(
        emailOrPhone: emailOrPhone, password: password, loginType: loginType, fieldType: fieldType);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse = AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse, alreadyInApp: alreadyInApp);
      
      // ⚡ PERFORMANCE: Extract user data from login response and update controllers immediately
      _updateUserDataFromLoginResponse(response.body as Map<String, dynamic>);
      
      return ResponseModel(true, authResponse.token ?? '', authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  /// ⚡ PERFORMANCE: Update user data from login response (minimal data for instant menu rendering)
  /// Extracts user data and wallet flags from login response and updates controllers immediately
  void _updateUserDataFromLoginResponse(Map<String, dynamic> responseBody) {
    try {
      print('🔍 AuthService: Checking login response for user data...');
      
      // Check if user data exists in response (backend will add 'user' field)
      if (responseBody.containsKey('user') && responseBody['user'] is Map) {
        final userData = responseBody['user'] as Map<String, dynamic>;
        print('✅ AuthService: User data found in login response');
        print('   - ID: ${userData['id']}');
        print('   - Name: ${userData['f_name']} ${userData['l_name']}');
        print('   - Loyalty Points: ${userData['loyalty_point'] ?? 0}');
        print('   - Wallet Balance: ${userData['wallet_balance'] ?? 0.0}');
        print('   - Has Qidha Wallet: ${userData['has_qidha_wallet'] ?? false}');
        
        // Update ProfileController with minimal user data
        if (Get.isRegistered<ProfileController>()) {
          print('📝 AuthService: Updating ProfileController with user data...');
          final profileController = Get.find<ProfileController>();
          profileController.setUserInfoFromLogin(
            id: userData['id'] is int ? userData['id'] as int : int.tryParse(userData['id']?.toString() ?? '0'),
            fName: userData['f_name']?.toString(),
            lName: userData['l_name']?.toString(),
            imageFullUrl: (userData['image_full_url'] ?? userData['image'])?.toString(),
            loyaltyPoint: userData['loyalty_point'] is int ? userData['loyalty_point'] as int : (int.tryParse(userData['loyalty_point']?.toString() ?? '0') ?? 0),
            // ⚡ FIX: Safe parsing - handle both String and numeric values
            walletBalance: (userData['wallet_balance'] is String)
                ? (double.tryParse(userData['wallet_balance'] as String) ?? 0.0)
                : ((userData['wallet_balance'] is num) ? (userData['wallet_balance'] as num).toDouble() : 0.0),
          );
          print('✅ AuthService: ProfileController updated successfully');
        } else {
          print('⚠️ AuthService: ProfileController not registered');
        }
        
        // Update Qidha wallet state if wallet exists
        if (userData['has_qidha_wallet'] == true) {
          print('💳 AuthService: User has Qidha wallet - updating wallet state...');
          print('   - Signed: ${userData['qidha_wallet_signed'] ?? false}');
          print('   - Active: ${userData['qidha_wallet_active'] ?? false}');
          print('   - Balance: ${userData['qidha_wallet_balance'] ?? 'null'}');
          
          if (Get.isRegistered<KaidhaSubscription_Controller>()) {
            final kaidhaController = Get.find<KaidhaSubscription_Controller>();
            kaidhaController.setWalletStateFromLogin(
              signed: userData['qidha_wallet_signed'] == true,
              active: userData['qidha_wallet_active'] == true,
              balance: userData['qidha_wallet_balance']?.toString(),
            );
            print('✅ AuthService: Wallet state updated successfully');
            
            // Only fetch full wallet data if wallet is not signed/active (needed for subscription flow)
            final qidhaWalletSigned = userData['qidha_wallet_signed'] is bool 
                ? userData['qidha_wallet_signed'] as bool 
                : (userData['qidha_wallet_signed']?.toString() == '1' || userData['qidha_wallet_signed']?.toString() == 'true');
            final qidhaWalletActive = userData['qidha_wallet_active'] is bool 
                ? userData['qidha_wallet_active'] as bool 
                : (userData['qidha_wallet_active']?.toString() == '1' || userData['qidha_wallet_active']?.toString() == 'true');
            if (!qidhaWalletSigned || !qidhaWalletActive) {
              print('🔄 AuthService: Wallet not signed/active - loading full wallet data in background...');
              // Load full wallet data in background (non-blocking) - needed for subscription flow
              kaidhaController.get_Wallet_Kaidh();
            } else {
              print('⚡ AuthService: Wallet is signed and active - no API call needed (balance already set)');
            }
          } else {
            print('⚠️ AuthService: KaidhaSubscription_Controller not registered');
          }
        } else {
          print('ℹ️ AuthService: User has no Qidha wallet');
        }
      } else {
        print('⚠️ AuthService: No user data in login response (backend may not have updated yet)');
        print('   - Response keys: ${responseBody.keys.toList()}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ AuthService: Error updating user data from login response - $e');
        print('   Stack trace: $stackTrace');
      }
      // Don't throw - login should still succeed even if user data extraction fails
    }
  }

  Future<void> _updateHeaderFunctionality(AuthResponseModel authResponse, {bool alreadyInApp = false}) async {
    if (authResponse.isEmailVerified! &&
        authResponse.isPhoneVerified! &&
        authResponse.isPersonalInfo! &&
        authResponse.token != null &&
        authResponse.isExistUser == null) {
      // 🔧 CRITICAL FIX: saveUserToken now updates headers IMMEDIATELY (synchronously)
      // Headers are updated before any async operations complete
      // This ensures updateToken() and getUserInfo() calls have the correct token
      await authRepositoryInterface.saveUserToken(authResponse.token ?? '', alreadyInApp: alreadyInApp);
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
    final Response response = await authRepositoryInterface.otpLogin(phone: phone, otp: otp, loginType: loginType, verified: verified);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse = AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse, alreadyInApp: alreadyInApp);
      return ResponseModel(true, authResponse.token ?? '', authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> resendOtp({required String phone}) async {
    final Response response = await authRepositoryInterface.resend_Otp(phone: phone);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse = AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse);
      return ResponseModel(true, authResponse.token ?? '', authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> guestLogin() async {
    return await authRepositoryInterface.guestLogin();
  }

  /*@override
  Future<bool> loginWithSocialMedia(SocialLogInBody socialLogInBody, int timeout, bool isCustomerVerificationOn) async {
    bool canNavigateToLocation = false;
    Response response = await authRepositoryInterface.loginWithSocialMedia(socialLogInBody, timeout);
    if (response.statusCode == 200) {
      String? token = response.body['token'];
      if(token != null && token.isNotEmpty) {
        if(isCustomerVerificationOn && response.body['is_phone_verified'] == 0) {
          if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
            Get.find<AuthController>().firebaseVerifyPhoneNumber(response.body['phone'], token, fromSignUp: true);
          }else{
            Get.toNamed(RouteHelper.getVerificationRoute(response.body['phone'] ?? socialLogInBody.email, token, RouteHelper.signUp, ''));
          }
        }else {
          authRepositoryInterface.saveUserToken(response.body['token']);
          await authRepositoryInterface.updateToken();
          authRepositoryInterface.clearSharedPrefGuestId();
          canNavigateToLocation = true;
        }
      }else {
        Get.toNamed(RouteHelper.getForgotPassRoute(true, socialLogInBody));
      }
    }else if(response.statusCode == 403 && response.body['errors'][0]['code'] == 'email'){
      Get.toNamed(RouteHelper.getForgotPassRoute(true, socialLogInBody));
    } else {
      showCustomSnackBar(response.statusText);
    }
    return canNavigateToLocation;
  }*/

  @override
  Future<ResponseModel> loginWithSocialMedia(SocialLogInBody socialLogInModel, {bool isCustomerVerificationOn = false}) async {
    final Response response = await authRepositoryInterface.loginWithSocialMedia(socialLogInModel);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse = AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse);
      return ResponseModel(true, authResponse.token ?? '', authResponseModel: authResponse);
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
        name: name, phone: phone, email: email, loginType: loginType, referCode: referCode);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse = AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      await _updateHeaderFunctionality(authResponse, alreadyInApp: alreadyInApp);
      return ResponseModel(true, authResponse.token ?? '', authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<void> updateToken() async {
    await authRepositoryInterface.updateToken();
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
    return await authRepositoryInterface.clearSharedData(removeToken: removeToken);
  }

  @override
  Future<bool> clearSharedAddress() async {
    return await authRepositoryInterface.clearSharedAddress();
  }

  @override
  Future<void> saveUserNumberAndPassword(String number, String password, String countryCode) async {
    await authRepositoryInterface.saveUserNumberAndPassword(number, password, countryCode);
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

  ///Todo:
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
  Future<void> setNotificationActive(bool isActive) async {
    await authRepositoryInterface.setNotificationActive(isActive);
  }

  @override
  Future<String?> saveDeviceToken() async {
    return await authRepositoryInterface.saveDeviceToken();
  }
}
