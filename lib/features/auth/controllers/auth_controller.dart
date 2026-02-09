// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/domain/services/auth_service_interface.dart';
import 'package:sixam_mart/features/verification/screens/verification_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class AuthController extends GetxController implements GetxService {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface}) {
    _notification = authServiceInterface.isSharedPrefNotificationActive();
  }

  bool _notification = true;
  bool get notification => _notification;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isTransferringGuestCart = false;

  bool _guestLoading = false;
  bool get guestLoading => _guestLoading;

  bool _acceptTerms = true;
  bool get acceptTerms => _acceptTerms;

  bool _isActiveRememberMe = false;
  bool get isActiveRememberMe => _isActiveRememberMe;

  bool _notificationLoading = false;
  bool get notificationLoading => _notificationLoading;

  bool _isNumberLogin = false;
  bool get isNumberLogin => _isNumberLogin;

  var countryDialCode = '+966';

  // ===========================================================================================================

  Future<ResponseModel> registration(SignUpBodyModel signUpBody) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel =
        await authServiceInterface.registration(signUpBody);
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<ResponseModel> login(
      {required String emailOrPhone,
      required String password,
      required String loginType,
      required String fieldType,
      bool alreadyInApp = false}) async {
    _isLoading = true;
    update();
    print('$password password');
    print('$emailOrPhone emailOrPhone');
    final ResponseModel responseModel = await authServiceInterface.login(
        emailOrPhone: emailOrPhone,
        password: password,
        loginType: loginType,
        fieldType: fieldType,
        alreadyInApp: alreadyInApp);
    _getUserAndCartData(responseModel);
    // Don't set _isLoading = false here - let _transferGuestCartToUser handle it
    return responseModel;
  }

  Future<ResponseModel> otpLogin(
      {required String phone,
      required String loginType,
      required String otp,
      required String verified,
      bool alreadyInApp = false}) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel = await authServiceInterface.otpLogin(
        phone: phone,
        otp: otp,
        loginType: loginType,
        verified: verified,
        alreadyInApp: alreadyInApp);
    _getUserAndCartData(responseModel);

    debugPrint('\x1B[32m  /${phone}  \x1B[0m');

    // Don't set _isLoading = false here - let _transferGuestCartToUser handle it
    return responseModel;
  }

  Future<ResponseModel> resend_Otp({required String phone}) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel =
        await authServiceInterface.resendOtp(phone: phone);
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<ResponseModel> guestLogin() async {
    _guestLoading = true;
    update();

    final ResponseModel responseModel = await authServiceInterface.guestLogin();

    debugPrint(
        '\x1B[32m   /////////////  ${responseModel.isSuccess}     \x1B[0m');

    _guestLoading = false;
    update();
    return responseModel;
  }

  /*Future<void> loginWithSocialMedia(SocialLogInBody socialLogInBody) async {
    _isLoading = true;
    update();
    bool canNavigateToLocation = await authServiceInterface.loginWithSocialMedia(socialLogInBody, 60, Get.find<SplashController>().configModel!.customerVerification!);
    if(canNavigateToLocation) {
      Get.find<LocationController>().navigateToLocationScreen('sign-in');
    }
    _isLoading = false;
    update();
  }*/

  Future<ResponseModel> loginWithSocialMedia(
      SocialLogInBody socialLogInBody) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel =
        await authServiceInterface.loginWithSocialMedia(socialLogInBody,
            isCustomerVerificationOn: Get.find<SplashController>()
                .configModel!
                .customerVerification!);
    _getUserAndCartData(responseModel);
    // Don't set _isLoading = false here - let _transferGuestCartToUser handle it
    return responseModel;
  }

  void toggleIsNumberLogin({bool? value, bool willUpdate = true}) {
    if (value == null) {
      _isNumberLogin = !_isNumberLogin;
    } else {
      _isNumberLogin = value;
    }
    initCountryCode();
    if (willUpdate) {
      update();
    }
  }

  Future<ResponseModel> updatePersonalInfo(
      {required String name,
      required String? phone,
      required String loginType,
      required String? email,
      required String? referCode,
      bool alreadyInApp = false}) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel = await authServiceInterface.updatePersonalInfo(
        name: name,
        phone: phone,
        email: email,
        loginType: loginType,
        referCode: referCode,
        alreadyInApp: alreadyInApp);
    _getUserAndCartData(responseModel);
    // Don't set _isLoading = false here - let _transferGuestCartToUser handle it
    return responseModel;
  }

  void _getUserAndCartData(ResponseModel responseModel) {
    if (responseModel.isSuccess &&
        responseModel.authResponseModel != null &&
        responseModel.authResponseModel!.isPhoneVerified! &&
        responseModel.authResponseModel!.isPersonalInfo!) {
      debugPrint('✅ Login successful - starting guest cart transfer process');

      // ⚡ PERFORMANCE FIX: Clear loading state immediately for instant UI update
      // Cart transfer will happen in background without blocking navigation
      _isLoading = false;
      update();

      // Transfer guest cart after login
      // Run in background - don't await to avoid blocking UI
      final String guestId = AuthHelper.getGuestId();
      _transferGuestCartToUser(guestId);
      
      // ⚡ PERFORMANCE: User info is already set from login response in AuthService
      // Only call getUserInfo if it wasn't set (fallback for backward compatibility)
      final profileController = Get.find<ProfileController>();
      print('🔍 AuthController: Checking if user info needs to be loaded...');
      print('   - userInfoModel: ${profileController.userInfoModel != null ? 'SET (${profileController.userInfoModel?.fName} ${profileController.userInfoModel?.lName})' : 'NULL'}');
      
      if (profileController.userInfoModel == null) {
        print('🔄 AuthController: User info not set from login - calling getUserInfo()...');
        profileController.getUserInfo();
      } else {
        print('⏭️ AuthController: User info already set from login - skipping getUserInfo()');
      }
    } else {
      debugPrint('❌ Login failed or incomplete - skipping guest cart transfer');
      // Set loading to false if login failed
      _isLoading = false;
      update();
    }
  }

  /// Handle guest cart after login - Laravel already transfers, we just clear cache
  /// ⚡ PERFORMANCE FIX: This runs in background and doesn't block UI state updates
  Future<void> _transferGuestCartToUser(String guestId) async {
    // Prevent duplicate calls if already transferring
    if (_isTransferringGuestCart) {
      debugPrint(
          '⚠️ Guest cart transfer already in progress - skipping duplicate call');
      return;
    }

    try {
      if (guestId.isEmpty) {
        debugPrint('⚠️ Guest cart transfer skipped - guestId is empty');
        return;
      }

      _isTransferringGuestCart = true;
      // Also set the cart controller's transfer flag
      Get.find<CartController>().setTransferringGuestCart(true);
      debugPrint('🔄 Starting guest cart merge after login (background)...');
      showCustomSnackBar('restoring_cart'.tr, isError: false, showDuration: 2);

      final bool mergeSuccess =
          await Get.find<CartController>().mergeGuestCart(guestId);

      if (mergeSuccess) {
        // Clear local cache after successful merge
        await Get.find<CartController>().clearLocalCacheOnly();
        debugPrint('🧹 Cleared local cart cache after merge');
      } else {
        showCustomSnackBar('cart_restore_failed'.tr, isError: true);
      }

      // Clear guest data when merge completes
      authServiceInterface.clearSharedPrefGuestId();
      debugPrint('✅ Guest cart merge completed');
    } catch (e) {
      debugPrint('❌ Error in guest cart cleanup: $e');
    } finally {
      // Reset transfer flag when done (don't touch _isLoading - already cleared for instant UI update)
      _isTransferringGuestCart = false;
      // Also reset the cart controller's transfer flag
      Get.find<CartController>().setTransferringGuestCart(false);
      // Note: _isLoading was already cleared in _getUserAndCartData for instant UI update
    }
  }

  void initCountryCode({String? countryCode}) {
    countryDialCode = countryCode ??
        CountryCode.fromCountryCode(
                Get.find<SplashController>().configModel!.country ?? 'BD')
            .dialCode ??
        '+880';
  }

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  void toggleTerms() {
    _acceptTerms = !_acceptTerms;
    update();
  }

  // ⚡ TASK 4: Firebase token retry limit - only retry once
  int _firebaseTokenRetryCount = 0;
  static const int _maxFirebaseTokenRetries = 1;

  Future<void> updateToken() async {
    try {
      await authServiceInterface.updateToken();
      // Reset retry count on success
      _firebaseTokenRetryCount = 0;
    } catch (e) {
      // ⚡ TASK 4: Only retry once, then defer
      if (_firebaseTokenRetryCount < _maxFirebaseTokenRetries) {
        _firebaseTokenRetryCount++;
        if (kDebugMode) {
          debugPrint('🔄 AuthController: Firebase token update failed, retrying (attempt $_firebaseTokenRetryCount/$_maxFirebaseTokenRetries)...');
        }
        try {
          await authServiceInterface.updateToken();
          _firebaseTokenRetryCount = 0; // Reset on success
        } catch (retryError) {
          // Second attempt failed - defer and let user continue
          if (kDebugMode) {
            debugPrint('⚠️ AuthController: Firebase sync deferred after $_maxFirebaseTokenRetries attempts - user can continue');
          }
          // Don't throw - let the app continue without blocking UI
        }
      } else {
        // Already retried once - defer
        if (kDebugMode) {
          debugPrint('⚠️ AuthController: Firebase sync deferred (already retried) - user can continue');
        }
        // Don't throw - let the app continue without blocking UI
      }
    }
  }

  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  bool isGuestLoggedIn() {
    return authServiceInterface.isGuestLoggedIn() &&
        !authServiceInterface.isLoggedIn();
  }

  String getGuestId() {
    debugPrint(
        '\x1B[32m     ${authServiceInterface.getSharedPrefGuestId()}     \x1B[0m');

    return authServiceInterface.getSharedPrefGuestId();
  }

  Future<bool> clearSharedData({bool removeToken = true}) async {
    // 🏗️ MODULE-FIRST ARCHITECTURE: Do not clear module on logout
    // Module selection persists across sessions
    // User will select module again if needed through module selection screen
    if (Get.context != null && !ResponsiveHelper.isDesktop(Get.context!)) {
      // 🏗️ MODULE-FIRST: Clear selectedModule.value instead of setModule(null)
      // This maintains architectural consistency
      final splashController = Get.find<SplashController>();
      splashController.selectedModule.value = null;
      // Note: _module is a private field and is synced with selectedModule through getter
      // Clearing selectedModule.value is sufficient - _module will be null through getter
      
      if (kDebugMode) {
        debugPrint('🏗️ [Module-First] AuthController: Cleared module selection on logout');
      }
    }

    // Refresh cart data after logout to ensure consistency
    try {
      await Get.find<CartController>().getCartDataOnline(forceRefresh: true);
      debugPrint('🔄 Cart refreshed after logout');
    } catch (e) {
      debugPrint('❌ Error refreshing cart after logout: $e');
    }

    return await authServiceInterface.clearSharedData(removeToken: removeToken);
  }

  Future<void> socialLogout() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    googleSignIn.disconnect();
    await FacebookAuth.instance.logOut();
  }

  Future<bool> clearSharedAddress() async {
    return await authServiceInterface.clearSharedAddress();
  }

  Future<void> saveUserNumberAndPasswordSharedPref(
      String number, String password, String countryCode) async {
    await authServiceInterface.saveUserNumberAndPassword(
        number, password, countryCode);
  }

  String getUserNumber() {
    return authServiceInterface.getUserNumber();
  }

  String getUserCountryCode() {
    return authServiceInterface.getUserCountryCode();
  }

  String getUserPassword() {
    return authServiceInterface.getUserPassword();
  }

  void saveUserNumberAndPassword(
      String number, String password, String countryCode) {
    authServiceInterface.saveUserNumberAndPassword(
        number, password, countryCode);
  }

  Future<bool> clearUserNumberAndPassword() async {
    return authServiceInterface.clearUserNumberAndPassword();
  }

  String getUserToken() {
    return authServiceInterface.getUserToken();
  }

  Future<void> updateZone() async {
    await authServiceInterface.updateZone();
  }

  Future<void> saveGuestNumber(String number) async {
    await authServiceInterface.saveGuestContactNumber(number);
  }

  String getGuestNumber() {
    return authServiceInterface.getGuestContactNumber();
  }

  Future<void> saveDmTipIndex(String i) async {
    await authServiceInterface.saveDmTipIndex(i);
  }

  String getDmTipIndex() {
    return authServiceInterface.getDmTipIndex();
  }

  void saveEarningPoint(String point) {
    authServiceInterface.saveEarningPoint(point);
  }

  String getEarningPint() {
    return authServiceInterface.getEarningPint();
  }

  Future<bool> setNotificationActive(bool isActive) async {
    _notificationLoading = true;
    update();
    _notification = isActive;
    await authServiceInterface.setNotificationActive(isActive);
    _notificationLoading = false;
    update();
    return _notification;
  }

  Future<String?> saveDeviceToken() async {
    return await authServiceInterface.saveDeviceToken();
  }

  Future<void> firebaseVerifyPhoneNumber(
      String phoneNumber, String? token, String loginType,
      {bool fromSignUp = true,
      bool canRoute = true,
      UpdateUserModel? updateUserModel}) async {
    _isLoading = true;
    update();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        _isLoading = false;
        update();

        if (Get.isDialogOpen!) {
          Get.back();
        }

        if (e.code == 'invalid-phone-number') {
          showCustomSnackBar('please_submit_a_valid_phone_number'.tr);
        } else {
          showCustomSnackBar(e.message?.replaceAll('_', ' '));
        }
      },
      codeSent: (String vId, int? resendToken) {
        if (Get.isDialogOpen!) {
          Get.back();
        }

        _isLoading = false;
        update();
        if (updateUserModel != null) {
          updateUserModel.sessionInfo = vId;
        }

        if (canRoute) {
          if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
            Get.back();
            Get.dialog(VerificationScreen(
              number: phoneNumber,
              token: token,
              fromSignUp: fromSignUp,
              fromForgetPassword: !fromSignUp,
              loginType: loginType,
              password: '',
              firebaseSession: vId,
              userModel: updateUserModel,
            ));
          } else {
            Get.toNamed(RouteHelper.getVerificationRoute(
                phoneNumber,
                '',
                token,
                fromSignUp ? RouteHelper.signUp : RouteHelper.forgotPassword,
                '',
                loginType,
                session: vId,
                updateUserModel: updateUserModel));
          }
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (Get.isDialogOpen!) {
          Get.back();
        }
        showCustomSnackBar('timed_out_please_try_again_after_few_minutes'.tr);
      },
    );
  }
}
