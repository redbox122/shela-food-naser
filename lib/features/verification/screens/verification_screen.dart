import 'dart:async';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';
import 'package:sixam_mart/features/auth/screens/new_user_setup_screen.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/existing_user_bottom_sheet.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/verification/controllers/verification_controller.dart';
import 'package:sixam_mart/features/verification/screens/new_pass_screen.dart';
import 'package:sixam_mart/features/checkout/widgets/checkout_loading_dialog.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerificationScreen extends StatefulWidget {
  final String? number;
  final String? email;
  final bool fromSignUp;
  final String? token;
  final String? password;
  final String loginType;
  final String? firebaseSession;
  final bool fromForgetPassword;
  final bool fromLogin2fa;
  final UpdateUserModel? userModel;
  final String? nextPage;
  const VerificationScreen(
      {super.key,
      required this.number,
      required this.password,
      required this.fromSignUp,
      required this.token,
      this.email,
      required this.loginType,
      this.firebaseSession,
      required this.fromForgetPassword,
      this.fromLogin2fa = false,
      this.userModel,
      this.nextPage});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  String? _number;
  String? _email;
  Timer? _timer;
  int _seconds = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Get.find<VerificationController>()
        .updateVerificationCode('', canUpdate: false);
    if (widget.number != null) {
      final String trimmedNumber = widget.number!.trim();
      if (trimmedNumber.startsWith('+')) {
        _number = trimmedNumber;
      } else if (trimmedNumber.startsWith('00')) {
        _number = '+${trimmedNumber.substring(2)}';
      } else {
        _number = '+$trimmedNumber';
      }
    }
    _email = widget.email;
    _startTimer();
  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds - 1;
      if (_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  void _navigateAfterLoginOtpSuccess() {
    dismissCheckoutLoadingDialogSafely();
    if (Get.isDialogOpen ?? false) {
      Get.back<void>(closeOverlays: true);
    }

    String? next = widget.nextPage;
    if (next == null || next.isEmpty) {
      final Uri? previousUri = Uri.tryParse(Get.previousRoute);
      final String? previousPage = previousUri?.queryParameters['page'];
      if (previousPage != null && previousPage.isNotEmpty) {
        next = previousPage;
      }
    }

    debugPrint('[Login][SUCCESS] OTP verified');
    debugPrint('[Login][NAV] previousRoute=${Get.previousRoute}');
    debugPrint('[Login][NAV] currentRoute=${Get.currentRoute}');
    debugPrint('[Login][NAV] targetRoute=$next');

    if (next != null && next.isNotEmpty) {
      final String normalized = next.toLowerCase();
      final bool isLoopRoute = normalized
              .contains(RouteHelper.succsessflycreated) ||
          normalized.contains(RouteHelper.signIn) ||
          normalized.contains(RouteHelper.verification) ||
          normalized.contains(RouteHelper.loginOtp) ||
          // Block stale forgot/reset-password routes — after login success
          // the user must always go to home, never back to password-reset flow.
          normalized.contains(RouteHelper.resetPassword) ||
          normalized.contains('reset-password') ||
          normalized.contains('from-reset-password') ||
          normalized.contains(RouteHelper.forgotPassword);
      if (!isLoopRoute) {
        debugPrint('[Login][NAV] navigating to saved redirect: $next');
        Get.offAllNamed(next);
        return;
      } else {
        debugPrint(
            '[Login][NAV] clearedForgotPasswordRoute=true (blocked loop route: $next)');
      }
    }

    debugPrint('[Login][NAV] navigating to home (default)');
    Get.offAllNamed(RouteHelper.getMainRoute('home'));
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    const double borderWidth = 0.7;
    return Directionality(
      textDirection: TextDirection.ltr, // Force LTR for OTP input layout
      child: Scaffold(
        appBar: isDesktop
            ? null
            : CustomAppBar(
                title: _email != null
                    ? 'email_verification'.tr
                    : 'phone_verification'.tr),
        backgroundColor: isDesktop ? Colors.transparent : null,
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Center(
              child: Container(
            width: context.width > 700 ? 500 : context.width,
            padding: context.width > 700
                ? const EdgeInsets.all(Dimensions.paddingSizeDefault)
                : null,
            decoration: context.width > 700
                ? BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  )
                : null,
            child: GetBuilder<VerificationController>(
                builder: (verificationController) {
              if (verificationController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(children: [
                isDesktop
                    ? Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.clear)),
                      )
                    : const SizedBox(),
                isDesktop
                    ? Padding(
                        padding: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeLarge),
                        child: Text(
                          'otp_verification'.tr,
                          style: robotoRegular,
                        ),
                      )
                    : const SizedBox(),
                Image.asset(
                  Images.otpVerification,
                  fit: BoxFit.fill,
                  height: 250,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtremeLarge),
                Get.find<SplashController>().configModel!.demo!
                    ? Text(
                        'for_demo_purpose'.tr,
                        style: robotoMedium,
                      )
                    : SizedBox(
                        width: 250,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                    text: 'we_have_a_verification_code'.tr,
                                    style: robotoRegular.copyWith(
                                        color:
                                            Theme.of(context).disabledColor)),
                                TextSpan(
                                    text: ' ${_email ?? _number}',
                                    style: robotoMedium.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color)),
                              ]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.width > 850
                          ? 50
                          : Dimensions.paddingSizeDefault,
                      vertical: 35),
                  child: PinCodeTextField(
                    length: 6,
                    appContext: context,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      fieldHeight: 60,
                      fieldWidth: 50,
                      borderWidth: borderWidth,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                      selectedColor: Theme.of(context).primaryColor,
                      selectedFillColor: Colors.white,
                      inactiveFillColor: Theme.of(context).cardColor,
                      inactiveColor: Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.6),
                      activeColor: Theme.of(context).disabledColor,
                      activeFillColor: Theme.of(context).cardColor,
                      inactiveBorderWidth: borderWidth,
                      selectedBorderWidth: borderWidth,
                      disabledBorderWidth: borderWidth,
                      errorBorderWidth: borderWidth,
                      activeBorderWidth: borderWidth,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    onChanged: verificationController.updateVerificationCode,
                    beforeTextPaste: (text) => true,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                GetBuilder<ProfileController>(builder: (profileController) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            isDesktop ? 32 : Dimensions.paddingSizeSmall),
                    child: CustomButton(
                      buttonText: 'verify'.tr,
                      isLoading: verificationController.isLoading ||
                          profileController.isLoading,
                      onPressed: verificationController
                                  .verificationCode.length <
                              6
                          ? null
                          : () {
                              if (widget.firebaseSession != null &&
                                  widget.userModel == null) {
                                verificationController
                                    .verifyFirebaseOtp(
                                  phoneNumber: _number!,
                                  session: widget.firebaseSession!,
                                  loginType: widget.loginType,
                                  otp: verificationController.verificationCode,
                                  token: widget.token,
                                  isForgetPassPage: widget.fromForgetPassword,
                                  isSignUpPage: widget.loginType ==
                                          CentralizeLoginType.otp.name
                                      ? false
                                      : true,
                                )
                                    .then((value) {
                                  if (value.isSuccess) {
                                    _handleVerifyResponse(
                                        value, _number, _email);
                                  } else {
                                    showCustomSnackBar(value.message);
                                  }
                                });
                              } else if (widget.userModel != null) {
                                widget.userModel!.otp =
                                    verificationController.verificationCode;
                                Get.find<ProfileController>().updateUserInfo(
                                    widget.userModel!,
                                    Get.find<AuthController>().getUserToken(),
                                    fromButton: true);
                              } else if (widget.fromSignUp) {
                                if (widget.loginType ==
                                    CentralizeLoginType.otp.name) {
                                  Get.find<AuthController>()
                                      .otpLogin(
                                    phone: _number!,
                                    otp:
                                        verificationController.verificationCode,
                                    loginType: widget.loginType,
                                    verified: '',
                                  )
                                      .then((value) {
                                    if (value.isSuccess) {
                                      _navigateAfterLoginOtpSuccess();
                                    } else {
                                      showCustomSnackBar('Invalid code');
                                    }
                                  });
                                } else {
                                  verificationController
                                      .verifyPhone(
                                          _number!,
                                          verificationController
                                              .verificationCode)
                                      .then((value) {
                                    if (value.isSuccess) {
                                      _handleVerifyResponse(
                                          value, _number, _email);
                                    } else {
                                      showCustomSnackBar('Invalid code');
                                    }
                                  });
                                }
                              } else if (widget.fromLogin2fa) {
                                Get.find<AuthController>()
                                    .verifyLoginOtp(
                                  phone: _number!,
                                  otp: verificationController.verificationCode,
                                )
                                    .then((value) {
                                  final token =
                                      value.authResponseModel?.token ?? '';
                                  if (value.isSuccess && token.isNotEmpty) {
                                    _navigateAfterLoginOtpSuccess();
                                  } else {
                                    showCustomSnackBar('Login not completed');
                                  }
                                });
                              } else {
                                verificationController
                                    .verifyToken(_number)
                                    .then((value) {
                                  if (value.isSuccess) {
                                    if (ResponsiveHelper.isDesktop(
                                        Get.context!)) {
                                      Get.dialog(Center(
                                          child: NewPassScreen(
                                              resetToken: verificationController
                                                  .verificationCode,
                                              number: _number,
                                              fromPasswordChange: false,
                                              fromDialog: true)));
                                    } else {
                                      debugPrint(
                                          '\x1B[32m  /777777777  \x1B[0m');

                                      Get.toNamed(
                                          RouteHelper.getResetPasswordRoute(
                                              _number,
                                              verificationController
                                                  .verificationCode,
                                              'reset-password'));
                                    }
                                  } else {
                                    showCustomSnackBar('Send a new code');
                                  }
                                });
                              }
                            },
                    ),
                  );
                }),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          isDesktop ? 29 : Dimensions.paddingSizeDefault),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'did_not_receive_the_code'.tr,
                          style: robotoRegular.copyWith(
                              color: Theme.of(context).disabledColor),
                        ),
                        TextButton(
                          onPressed: _seconds < 1
                              ? () async {
                                  if (widget.firebaseSession != null) {
                                    await Get.find<AuthController>()
                                        .firebaseVerifyPhoneNumber(_number!,
                                            widget.token, widget.loginType,
                                            fromSignUp: widget.fromSignUp,
                                            canRoute: false);
                                    _startTimer();
                                  } else {
                                    _resendOtp();
                                  }
                                }
                              : null,
                          child: Text(
                            '${'resent_it'.tr}${_seconds > 0 ? ' (${_seconds}s)' : ''}',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ]);
            }),
          )),
        ))),
      ),
    );
  }

  void _handleVerifyResponse(
      ResponseModel response, String? number, String? email) {
    debugPrint('\x1B[32m  /${response.message}  \x1B[0m');

    if (response.authResponseModel != null &&
        response.authResponseModel!.isExistUser != null) {
      if (ResponsiveHelper.isDesktop(context)) {
        Get.back();
        Get.dialog(Center(
          child: ExistingUserBottomSheet(
            userModel: response.authResponseModel!.isExistUser!,
            number: _number,
            email: _email,
            loginType: widget.loginType,
            otp: Get.find<VerificationController>().verificationCode,
          ),
        ));
      } else {
        Get.bottomSheet(ExistingUserBottomSheet(
          userModel: response.authResponseModel!.isExistUser!,
          number: _number,
          email: _email,
          loginType: widget.loginType,
          otp: Get.find<VerificationController>().verificationCode,
        ));
      }
    } else if (response.authResponseModel != null &&
        !response.authResponseModel!.isPersonalInfo!) {
      if (ResponsiveHelper.isDesktop(context)) {
        Get.back();
        Get.dialog(NewUserSetupScreen(
            name: '',
            loginType: widget.loginType,
            phone: number,
            email: email));
      } else {
        // Get.offAllNamed(RouteHelper.getNewUserSetupScreen(name: '', loginType: widget.loginType, phone: number, email: email));
        // Get.offAllNamed(RouteHelper.getSuccsessfly_createdRoute());

        Get.offAllNamed(RouteHelper.getSuccsessfly_createdRoute());
      }
    } else {
      Get.offAllNamed(RouteHelper.getSuccsessfly_createdRoute());

      // if (widget.fromForgetPassword) {
      //   Get.offAllNamed(
      //       RouteHelper.getResetPasswordRoute(_number, Get.find<VerificationController>().verificationCode, 'reset-password'));
      // } else {
      //   Get.find<LocationController>().navigateToLocationScreen(context, 'verification', offNamed: true);
      // }
    }
  }

  void _resendOtp() {
    if (_number == null || _number!.isEmpty) {
      showCustomSnackBar('invalid_phone_number'.tr);
      return;
    }

    void onSuccess() {
      Get.find<VerificationController>()
          .updateVerificationCode('', canUpdate: false);
      _startTimer();
      showCustomSnackBar('resend_code_successful'.tr, isError: false);
    }

    if (widget.userModel != null) {
      Get.find<ProfileController>().updateUserInfo(
          widget.userModel!, Get.find<AuthController>().getUserToken(),
          fromVerification: true);
    } else if (widget.fromLogin2fa) {
      Get.find<AuthController>().resend_Otp(phone: _number!).then((value) {
        if (value.isSuccess) {
          onSuccess();
        } else {
          showCustomSnackBar(value.message);
        }
      });
    } else if (widget.fromSignUp) {
      Get.find<AuthController>().resend_Otp(phone: _number!).then((value) {
        if (value.isSuccess) {
          onSuccess();
        } else {
          showCustomSnackBar(value.message);
        }
      });
    } else {
      Get.find<VerificationController>().forgetPassword(_number).then((value) {
        if (value.isSuccess) {
          onSuccess();
        } else {
          showCustomSnackBar(value.message);
        }
      });
    }
  }
}
