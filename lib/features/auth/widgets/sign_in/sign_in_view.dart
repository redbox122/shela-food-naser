import 'dart:async';
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';
import 'package:sixam_mart/features/auth/screens/new_user_setup_screen.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/manual_login_widget.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/otp_login_widget.dart';
import 'package:sixam_mart/features/auth/widgets/social_login_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/checkout_loading_dialog.dart';
import 'package:sixam_mart/features/verification/domein/enum/verification_type_enum.dart';
import 'package:sixam_mart/features/verification/screens/verification_screen.dart';
import 'package:sixam_mart/helper/centralize_login_helper.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/get_di.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

class SignInView extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromResetPassword;
  final Function(bool val)? isOtpViewEnable;
  const SignInView(
      {super.key,
      required this.exitFromApp,
      required this.backFromThis,
      this.fromResetPassword = false,
      this.isOtpViewEnable});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _countryDialCode;
  GlobalKey<FormState>? _formKeyLogin;
  bool _isOtpViewEnable = false;

  @override
  void initState() {
    super.initState();

    _formKeyLogin = GlobalKey<FormState>();

    intS();
  }

  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  CentralizeLoginSetup _getLoginSetup() {
    final splashController = Get.find<SplashController>();
    return splashController.configModel?.centralizeLoginSetup ??
        CentralizeLoginSetup(
          manualLoginStatus: true,
          otpLoginStatus: false,
          socialLoginStatus: false,
        );
  }

  Future<void> intS() async {
    await init();
    final AuthController authController = Get.find<AuthController>();
    final SplashController splashController = Get.find<SplashController>();

    _countryDialCode = authController.getUserCountryCode().isNotEmpty
        ? authController.getUserCountryCode()
        : CountryCode.fromCountryCode(
                splashController.configModel?.country ?? 'SA')
            .dialCode;
    phoneController.text = authController.getUserNumber();
    passwordController.text = authController.getUserPassword();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginSetup = _getLoginSetup();
      final loginMethod = CentralizeLoginHelper.getPreferredLoginMethod(
          loginSetup, _isOtpViewEnable);
      final bool isOtpActive = loginMethod.type == CentralizeLoginType.otp ||
          loginMethod.type == CentralizeLoginType.otpAndSocial;

      if (_countryDialCode != '' &&
          phoneController.text != '' &&
          phoneController.text.contains('@') &&
          isOtpActive) {
        phoneController.text = '';
      } else if (_countryDialCode != '' &&
          phoneController.text != '' &&
          !phoneController.text.contains('@')) {
        authController.toggleIsNumberLogin(value: true);
      } else {
        authController.toggleIsNumberLogin(value: false);
      }
      authController.initCountryCode(
          countryCode: _countryDialCode != '' ? _countryDialCode : null);
    });

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_phoneFocus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (authController) {
      return Form(
        key: _formKeyLogin,
        child: activeCentralizeLogin(authController, _getLoginSetup()),
      );
    });
  }

  Widget activeCentralizeLogin(AuthController authController,
      CentralizeLoginSetup centralizeLoginSetup) {
    final CentralizeLoginSetup uiLoginSetup = CentralizeLoginSetup(
      manualLoginStatus: true,
      otpLoginStatus: false,
      socialLoginStatus: centralizeLoginSetup.socialLoginStatus,
    );
    final CentralizeLoginType centralizeLogin =
        CentralizeLoginHelper.getPreferredLoginMethod(
                uiLoginSetup, _isOtpViewEnable)
            .type;
    switch (centralizeLogin) {
      case CentralizeLoginType.otp:
        return OtpLoginWidget(
          phoneController: phoneController,
          phoneFocus: _phoneFocus,
          countryDialCode: _countryDialCode,
          onCountryChanged: (CountryCode countryCode) =>
              _countryDialCode = countryCode.dialCode,
          onClickLoginButton: () {
            _otpLogin(Get.find<AuthController>(), _countryDialCode!,
                CentralizeLoginType.otp);
          },
        );

      case CentralizeLoginType.manual:
        return ManualLoginWidget(
          phoneController: phoneController,
          passwordController: passwordController,
          phoneFocus: _phoneFocus,
          passwordFocus: _passwordFocus,
          onWebSubmit: () {},
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.social:
        return const SocialLoginWidget(onlySocialLogin: true);

      case CentralizeLoginType.manualAndSocial:
        return ManualLoginWidget(
          phoneController: phoneController,
          passwordController: passwordController,
          phoneFocus: _phoneFocus,
          passwordFocus: _passwordFocus,
          socialEnable: true,
          onWebSubmit: () {},
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.manualAndOtp:
        return ManualLoginWidget(
          phoneController: phoneController,
          passwordController: passwordController,
          phoneFocus: _phoneFocus,
          passwordFocus: _passwordFocus,
          onOtpViewClick: () {
            widget.isOtpViewEnable!(true);
            if (_countryDialCode != '' &&
                phoneController.text != '' &&
                phoneController.text.contains('@')) {
              phoneController.text = '';
            }
            setState(() {
              _isOtpViewEnable = true;
            });
          },
          onWebSubmit: () {},
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.otpAndSocial:
        return SocialLoginWidget(
            onlySocialLogin: true,
            onOtpViewClick: () {
              widget.isOtpViewEnable!(true);
              if (_countryDialCode != '' &&
                  phoneController.text != '' &&
                  phoneController.text.contains('@')) {
                phoneController.text = '';
              }
              setState(() {
                _isOtpViewEnable = true;
              });
            });

      case CentralizeLoginType.manualAndSocialAndOtp:
        return ManualLoginWidget(
          phoneController: phoneController,
          passwordController: passwordController,
          phoneFocus: _phoneFocus,
          passwordFocus: _passwordFocus,
          onWebSubmit: () {},
          socialEnable: true,
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
          onOtpViewClick: () {
            widget.isOtpViewEnable!(true);
            if (_countryDialCode != '' &&
                phoneController.text != '' &&
                phoneController.text.contains('@')) {
              phoneController.text = '';
            }
            setState(() {
              _isOtpViewEnable = true;
            });
          },
        );
    }
  }

  void _otpLogin(AuthController authController, String countryDialCode,
      CentralizeLoginType loginType) async {
    debugPrint('🔥 OTP LOGIN PATH');
    final String phone = phoneController.text.trim();
    String numberWithCountryCode = countryDialCode + phone;
    final PhoneValid phoneValid =
        await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (_formKeyLogin!.currentState!.validate()) {
      if (!phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        authController
            .resend_Otp(phone: numberWithCountryCode)
            .then((response) {
          if (response.isSuccess) {
            _processOtpSuccessSetup(
                response, authController, phone, countryDialCode);
          } else {
            showCustomSnackBar(response.message);
          }
        });
      }
    }
  }

  void _login(
      AuthController authController, CentralizeLoginType loginType) async {
    final String phone = phoneController.text.trim();
    final String password = passwordController.text.trim();
    String numberWithCountryCode = authController.countryDialCode + phone;
    final PhoneValid phoneValid =
        await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;
    debugPrint('$phone phone');
    if (_formKeyLogin!.currentState!.validate()) {
      final String isPhone = ValidateCheck.getValidPhone(
          authController.countryDialCode + phoneController.text.trim(),
          withCountryCode: true);

      if (isPhone != '' && !phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        authController
            .login(
          emailOrPhone: isPhone != '' ? isPhone : phone,
          password: password,
          loginType: loginType.name,
          fieldType: isPhone != ''
              ? VerificationTypeEnum.phone.name
              : VerificationTypeEnum.email.name,
          alreadyInApp: widget.backFromThis,
        )
            .then((status) async {
          if (status.isSuccess) {
            if (status.otpRequired) {
              final String otpPhone = status.otpPhone ?? numberWithCountryCode;
              String? nextPage = Get.parameters['page'];
              if (nextPage == null || nextPage.isEmpty) {
                final Uri? currentUri = Uri.tryParse(Get.currentRoute);
                nextPage = currentUri?.queryParameters['page'];
              }
              // Do NOT pass flow/auth routes as redirect targets — they would
              // send the user back to reset-password / sign-in after OTP success.
              final String? normalizedNext = nextPage?.toLowerCase();
              final bool nextIsFlowRoute = normalizedNext != null &&
                  (normalizedNext.contains(RouteHelper.resetPassword) ||
                      normalizedNext.contains('reset-password') ||
                      normalizedNext.contains('from-reset-password') ||
                      normalizedNext.contains(RouteHelper.forgotPassword) ||
                      normalizedNext.contains(RouteHelper.signIn) ||
                      normalizedNext.contains(RouteHelper.verification));
              debugPrint('[Login][NAV] previousRoute=${Get.previousRoute}');
              debugPrint('[Login][NAV] currentRoute=${Get.currentRoute}');
              debugPrint('[Login][NAV] savedRedirect=$nextPage');
              if (nextIsFlowRoute) {
                debugPrint(
                    '[Login][NAV] clearedForgotPasswordRoute=true (was: $nextPage)');
                nextPage = null;
              }
              Get.toNamed(RouteHelper.getLoginOtpRoute(
                  otpPhone, CentralizeLoginType.manual.name,
                  nextPage: nextPage));
              return;
            }
            if (status.isSuccess &&
                !status.authResponseModel!.isPersonalInfo!) {
              if (Get.context != null &&
                  ResponsiveHelper.isDesktop(Get.context!)) {
                Get.back();
                Get.dialog(NewUserSetupScreen(
                    name: '',
                    loginType: loginType.name,
                    phone: numberWithCountryCode,
                    email: ''));
              } else {
                Get.toNamed(RouteHelper.getNewUserSetupScreen(
                    name: '',
                    loginType: loginType.name,
                    phone: numberWithCountryCode,
                    email: ''));
              }
            } else {
              _processSuccessSetup(
                  authController, phone, isPhone, password, status);
            }
          } else {
            showCustomSnackBar('تأكد من الرقم او كلمة المرور');
          }
        });
      }
    }
  }

  Future<void> _processSuccessSetup(AuthController authController, String phone,
      String email, String password, ResponseModel status) async {
    // E-commerce data is completely independent of user authentication
    // No need to invalidate anything - cache persists across login/logout

    if (authController.isActiveRememberMe) {
      debugPrint('\x1B[32m  111111111  \x1B[0m');

      authController.saveUserNumberAndPassword(
          phone, password, authController.countryDialCode);
    } else {
      debugPrint('\x1B[32m  22222  \x1B[0m');

      authController.clearUserNumberAndPassword();
    }
    if (GetPlatform.isWeb) {
      debugPrint('\x1B[32m  333  \x1B[0m');

      await Get.find<FavouriteController>().getFavouriteList();
      if (!mounted) {
        return;
      }
    }
    if (status.authResponseModel != null &&
        !status.authResponseModel!.isPhoneVerified!) {
      debugPrint('\x1B[32m  444444  \x1B[0m');

      final List<int> encoded = utf8.encode(password);
      final String data = base64Encode(encoded);
      final String token = status.authResponseModel!.token ?? '';

      if (Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
        debugPrint('\x1B[32m  55555555  \x1B[0m');
        Get.find<AuthController>().firebaseVerifyPhoneNumber(
            phone, token, CentralizeLoginType.manual.name);
      } else {
        debugPrint('\x1B[32m  6666666  \x1B[0m');

        Get.toNamed(
          RouteHelper.getVerificationRoute(phone, null, token,
              RouteHelper.signUp, data, CentralizeLoginType.manual.name),
        );
      }
    } else if (status.authResponseModel != null &&
        !status.authResponseModel!.isEmailVerified!) {
      debugPrint('\x1B[32m  777777777  \x1B[0m');

      final List<int> encoded = utf8.encode(password);
      final String data = base64Encode(encoded);
      final String token = status.authResponseModel!.token ?? '';

      Get.toNamed(RouteHelper.getVerificationRoute(null, email, token,
          RouteHelper.signUp, data, CentralizeLoginType.manual.name));
    } else {
      debugPrint('\x1B[32m  88888888  \x1B[0m');
      debugPrint('[Login][SUCCESS] response ok');
      debugPrint('[Login][NAV] previousRoute=${Get.previousRoute}');
      debugPrint('[Login][NAV] currentRoute=${Get.currentRoute}');
      debugPrint('[Login][NAV] fromResetPassword=${widget.fromResetPassword}');
      debugPrint(
          '🚀 SignInView: Login successful - starting optimistic navigation...');

      // ⚡ PERFORMANCE: Optimistic navigation - navigate immediately after login
      // User data and wallet state are already set from login response in AuthService
      // Menu screen can render immediately with data from login response

      // Check current state before navigation
      final profileController = Get.find<ProfileController>();
      final kaidhaController = Get.find<KaidhaSubscriptionController>();
      debugPrint('🔍 SignInView: Pre-navigation state check:');
      debugPrint(
          '   - User Info: ${profileController.userInfoModel != null ? 'SET (${profileController.userInfoModel?.fName} ${profileController.userInfoModel?.lName})' : 'NULL'}');
      debugPrint(
          '   - Wallet State: ${kaidhaController.walletKaidhaModel != null ? 'SET (${kaidhaController.walletKaidhaModel?.wallet?.status})' : 'NULL'}');

      // Navigate IMMEDIATELY (don't wait for API calls)
      debugPrint(
          '⚡ SignInView: Navigating immediately (optimistic navigation)...');
      // Close stale modal overlays from previous checkout/login steps.
      dismissCheckoutLoadingDialogSafely();
      if (Get.isDialogOpen ?? false) {
        Get.back<void>(closeOverlays: true);
      }
      if (widget.backFromThis) {
        if (Get.context != null &&
            (ResponsiveHelper.isDesktop(Get.context!) ||
                widget.fromResetPassword)) {
          debugPrint('\x1B[32m  56666565656565  \x1B[0m');
          debugPrint(
              '📱 SignInView: Navigating to initial route (desktop/reset password)');
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          debugPrint('📱 SignInView: Navigating back');
          Get.back();
        }
      } else {
        debugPrint('\x1B[32m  99999999  \x1B[0m');
        debugPrint(
            '📱 SignInView: Navigating to location screen (or home if address exists)');
        // Navigate to location screen (or home if address already exists)
        // navigateToLocationScreen handles navigation - no need for redundant Get.offAllNamed
        // If user has address, it navigates directly to home
        // If user doesn't have address, it navigates to location screen which will navigate to home after selection
        Get.find<LocationController>()
            .navigateToLocationScreen(context, 'sign-in', offNamed: true);
      }
      debugPrint(
          '✅ SignInView: Navigation completed - menu screen should render immediately');

      // Load remaining data in background (non-blocking)
      // User info and wallet state are already set from login response
      debugPrint(
          '🔄 SignInView: Starting background data loading (non-blocking)...');
      unawaited(_loadBackgroundDataAfterLogin());
    }
  }

  void _processOtpSuccessSetup(
      ResponseModel response,
      AuthController authController,
      String phone,
      String countryDialCode) async {
    // E-commerce data is completely independent of user authentication
    // No need to invalidate anything - cache persists across login/logout

    if (authController.isActiveRememberMe) {
      authController.saveUserNumberAndPassword(phone, '', countryDialCode);
    } else {
      authController.clearUserNumberAndPassword();
    }
    if (GetPlatform.isWeb && response.authResponseModel == null) {
      await Get.find<FavouriteController>().getFavouriteList();
      if (!mounted) {
        return;
      }
    }

    String? nextPage = Get.parameters['page'];
    if (nextPage == null || nextPage.isEmpty) {
      final Uri? currentUri = Uri.tryParse(Get.currentRoute);
      nextPage = currentUri?.queryParameters['page'];
    }

    if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
      Get.back();
      Get.dialog(VerificationScreen(
        number: countryDialCode + phone,
        token: '',
        fromSignUp: false,
        fromForgetPassword: false,
        fromLogin2fa: true,
        nextPage: nextPage,
        loginType: CentralizeLoginType.otp.name,
        password: '',
      ));
    } else {
      Get.toNamed(
        RouteHelper.getLoginOtpRoute(
          countryDialCode + phone,
          CentralizeLoginType.otp.name,
          nextPage: nextPage,
        ),
      );
    }
  }

  /// ⚡ PERFORMANCE: Load remaining data in background after optimistic navigation
  /// User info and wallet state are already set from login response
  /// This loads additional data (cart, wishlist) in parallel without blocking UI
  Future<void> _loadBackgroundDataAfterLogin() async {
    try {
      debugPrint('🔄 SignInView: Loading background data after navigation...');
      final startTime = DateTime.now();

      // Check if cache is valid and restore data
      if (await ComprehensiveHomeCacheManager.isCacheValid()) {
        debugPrint('📦 SignInView: Cache is valid, restoring data...');

        // Load cached data
        final cachedData =
            await ComprehensiveHomeCacheManager.loadAllHomeData();

        if (cachedData.isNotEmpty) {
          // Restore data to controllers
          await ComprehensiveHomeCacheManager.restoreDataToControllers(
              cachedData);
          debugPrint('✅ SignInView: Data restored successfully');
        }
      } else {
        debugPrint(
            '⚠️ SignInView: Cache not valid, will load from API after navigation');
      }

      // Load remaining data in parallel (non-blocking)
      // User info and wallet state are already set from login response
      if (AuthHelper.isLoggedIn()) {
        try {
          final profileController = Get.find<ProfileController>();
          final kaidhaController = Get.find<KaidhaSubscriptionController>();
          final cartController = Get.find<CartController>();
          final favouriteController = Get.find<FavouriteController>();

          final futures = <Future>[];

          // Only load full user info if not already set from login response
          if (profileController.userInfoModel == null) {
            debugPrint(
                '🔄 SignInView: User info not set from login - loading from API...');
            futures.add(profileController.getUserInfo());
          } else {
            debugPrint(
                '⏭️ SignInView: User info already set from login - skipping API call');
          }

          // Only load wallet if not already set from login response (inactive/unsigned wallets)
          // Active wallets already have state set from login - no API call needed!
          if (kaidhaController.walletKaidhaModel == null) {
            debugPrint(
                '🔄 SignInView: Wallet state not set from login - loading from API...');
            futures.add(kaidhaController.get_Wallet_Kaidh());
          } else {
            debugPrint(
                '⏭️ SignInView: Wallet state already set from login - skipping API call');
          }

          // Load module-specific cart (non-blocking)
          debugPrint('🔄 SignInView: Loading cart data...');
          futures.add(cartController.getCartDataOnline());

          // Load wishlist (non-blocking)
          debugPrint('🔄 SignInView: Loading wishlist data...');
          futures.add(favouriteController.getFavouriteList());

          debugPrint(
              '🔄 SignInView: Waiting for ${futures.length} background API calls...');
          await Future.wait(futures);

          final duration = DateTime.now().difference(startTime);
          debugPrint(
              '✅ SignInView: Background data loaded successfully in ${duration.inMilliseconds}ms');
        } catch (e) {
          debugPrint('⚠️ SignInView: Error loading background data - $e');
          // Don't block - data will load when user navigates to those screens
        }
      }
    } catch (e) {
      debugPrint('❌ SignInView: Error loading background data - $e');
    }
  }
}
