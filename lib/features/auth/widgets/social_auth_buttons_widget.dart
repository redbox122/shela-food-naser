import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/helper/social_login_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class SocialAuthButtonsWidget extends StatelessWidget {
  final bool showDivider;
  const SocialAuthButtonsWidget({super.key, this.showDivider = true});

  // Social login is a first-class option in the passwordless flow: Google is
  // always offered, and Apple is shown on iOS only (platform standard). We no
  // longer gate on the legacy "centralize login" admin toggles.
  static bool get googleLoginActive => true;

  static bool get appleLoginActive => !GetPlatform.isAndroid;

  static bool get hasAnySocial => googleLoginActive || appleLoginActive;

  @override
  Widget build(BuildContext context) {
    if (!hasAnySocial) {
      return const SizedBox();
    }
    return Column(
      children: [
        if (showDivider) ...[
          _OrDivider(text: 'or_continue_with_account'.tr),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
        Row(
          children: [
            if (appleLoginActive)
              Expanded(
                child: _SocialButton(
                  icon: Images.appleLogo,
                  label: 'Apple',
                  onTap: () => SocialLoginHelper.appleLogin(context),
                ),
              ),
            if (appleLoginActive && googleLoginActive)
              const SizedBox(width: Dimensions.paddingSizeDefault),
            if (googleLoginActive)
              Expanded(
                child: _SocialButton(
                  icon: Images.google,
                  label: 'Google',
                  onTap: () => SocialLoginHelper.googleLogin(context),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String text;
  const _OrDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child:
              Divider(color: Theme.of(context).disabledColor, thickness: 0.5)),
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Text(text,
            textAlign: TextAlign.center,
            style: tajawalRegular.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                height: 1.6,
                color: const Color(0xFF545454))),
      ),
      Expanded(
          child:
              Divider(color: Theme.of(context).disabledColor, thickness: 0.5)),
    ]);
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Image.asset(icon, height: 20, width: 20),
          ],
        ),
      ),
    );
  }
}
