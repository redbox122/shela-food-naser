import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/features/auth/screens/new_user_setup_screen.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/existing_user_bottom_sheet.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';

/// Shared social-login handlers (Google / Apple / Facebook).
///
/// Extracted from [SocialLoginWidget] so multiple entry points (the legacy
/// sign-in widget and the new welcome screen) drive the exact same flow.
/// Social login intentionally keeps the legacy auth-response handling
/// (is_exist_user / is_personal_info) unchanged.
class SocialLoginHelper {
  const SocialLoginHelper._();

  static void googleLogin(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        return;
      }
      final GoogleSignInAuthentication auth = await googleAccount.authentication;

      final SocialLogInBody googleBodyModel = SocialLogInBody(
        email: googleAccount.email,
        token: auth.accessToken,
        uniqueId: googleAccount.id,
        medium: 'google',
        accessToken: 1,
        loginType: CentralizeLoginType.social.name,
      );

      final response = await Get.find<AuthController>()
          .loginWithSocialMedia(googleBodyModel);
      if (response.isSuccess) {
        if (!context.mounted) {
          return;
        }
        _processSocialSuccessSetup(
            context, response, googleBodyModel, null, null);
      } else {
        showCustomSnackBar(response.message);
      }
    } catch (e) {
      showCustomSnackBar(e.toString());
    }
  }

  static void facebookLogin(BuildContext context) async {
    final LoginResult result = await FacebookAuth.instance
        .login(permissions: ['public_profile', 'email']);
    if (result.status == LoginStatus.success) {
      final Map<String, dynamic> userData =
          await FacebookAuth.instance.getUserData();

      final SocialLogInBody facebookBodyModel = SocialLogInBody(
        email: userData['email']?.toString(),
        token: result.accessToken!.token,
        uniqueId: result.accessToken!.userId,
        medium: 'facebook',
        loginType: CentralizeLoginType.social.name,
      );

      Get.find<AuthController>()
          .loginWithSocialMedia(facebookBodyModel)
          .then((response) {
        if (response.isSuccess) {
          if (!context.mounted) {
            return;
          }
          _processSocialSuccessSetup(
              context, response, null, null, facebookBodyModel);
        } else {
          showCustomSnackBar(response.message);
        }
      });
    }
  }

  static void appleLogin(BuildContext context) async {
    try {
      // On iOS the native flow is used, so clientId/redirectUrl are only needed
      // for the web fallback. Read them defensively (config may be empty) to
      // avoid a force-unwrap crash when Apple config is missing.
      WebAuthenticationOptions? webOptions;
      if (!GetPlatform.isIOS) {
        final appleConfig =
            Get.find<SplashController>().configModel?.appleLogin;
        if (appleConfig != null && appleConfig.isNotEmpty) {
          webOptions = WebAuthenticationOptions(
            clientId: appleConfig[0].clientId ?? '',
            redirectUri: Uri.parse(appleConfig[0].redirectUrl ?? ''),
          );
        }
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: webOptions,
      );

      // userIdentifier is Apple's STABLE per-user id (same on every sign-in);
      // authorizationCode is a one-time code that changes each time, so it can
      // never be used to match a returning user. Use userIdentifier as the
      // backend unique_id and fall back to authorizationCode only if absent.
      final SocialLogInBody appleBodyModel = SocialLogInBody(
        email: credential.email,
        token: credential.identityToken ?? credential.authorizationCode,
        uniqueId: credential.userIdentifier ?? credential.authorizationCode,
        medium: 'apple',
        loginType: CentralizeLoginType.social.name,
        platform: GetPlatform.isIOS ? 'flutter_app' : 'flutter_web',
      );

      final response =
          await Get.find<AuthController>().loginWithSocialMedia(appleBodyModel);
      if (response.isSuccess) {
        if (!context.mounted) {
          return;
        }
        _processSocialSuccessSetup(context, response, null, appleBodyModel, null);
      } else {
        showCustomSnackBar(response.message);
      }
    } on SignInWithAppleAuthorizationException catch (_) {
      // User cancelled the Apple sheet — do nothing (no crash, no error).
    } catch (e) {
      showCustomSnackBar(e.toString());
    }
  }

  static void _processSocialSuccessSetup(
      BuildContext context,
      ResponseModel response,
      SocialLogInBody? googleBodyModel,
      SocialLogInBody? appleBodyModel,
      SocialLogInBody? facebookBodyModel) {
    String? email = googleBodyModel != null
        ? googleBodyModel.email
        : appleBodyModel != null
            ? appleBodyModel.email
            : facebookBodyModel?.email;
    if (response.isSuccess &&
        response.authResponseModel != null &&
        response.authResponseModel!.isExistUser != null) {
      if (appleBodyModel != null) {
        email = response.authResponseModel!.email;
        appleBodyModel.email = email;
      }
      if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
        Get.back<void>();
        Get.dialog<void>(Center(
          child: ExistingUserBottomSheet(
            userModel: response.authResponseModel!.isExistUser!,
            email: email,
            loginType: CentralizeLoginType.social.name,
            socialLogInBodyModel:
                googleBodyModel ?? appleBodyModel ?? facebookBodyModel,
          ),
        ));
      } else {
        Get.bottomSheet<void>(ExistingUserBottomSheet(
          userModel: response.authResponseModel!.isExistUser!,
          loginType: CentralizeLoginType.social.name,
          socialLogInBodyModel:
              googleBodyModel ?? appleBodyModel ?? facebookBodyModel,
          email: email,
        ));
      }
    } else if (response.isSuccess &&
        response.authResponseModel != null &&
        !response.authResponseModel!.isPersonalInfo!) {
      final String? displayName = googleBodyModel != null
          ? googleBodyModel.email?.split('@')[0]
          : appleBodyModel != null
              ? appleBodyModel.email?.split('@')[0]
              : facebookBodyModel?.email?.split('@')[0];

      if (appleBodyModel != null) {
        email = response.authResponseModel!.email;
      }
      if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
        Get.back<void>();
        Get.dialog<void>(NewUserSetupScreen(
            name: displayName ?? '',
            loginType: CentralizeLoginType.social.name,
            phone: '',
            email: email));
      } else {
        Get.toNamed<void>(RouteHelper.getNewUserSetupScreen(
            name: displayName ?? '',
            loginType: CentralizeLoginType.social.name,
            phone: '',
            email: email));
      }
    } else {
      Get.find<LocationController>()
          .navigateToLocationScreen(context, 'sign-in', offNamed: true);
    }
  }
}
