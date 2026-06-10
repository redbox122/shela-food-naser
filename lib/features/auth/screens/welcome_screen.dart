import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/social_auth_buttons_widget.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _guestLogin(BuildContext context, AuthController authController) {
    authController.guestLogin().then((response) {
      if (response.isSuccess) {
        Get.find<ProfileController>().setForceFullyUserEmpty();
        if (context.mounted) {
          Navigator.pushReplacementNamed(
              context, RouteHelper.getInitialRoute());
        }
      }
    });
  }

  void _toggleLanguage(BuildContext context) {
    final localizationController = Get.find<LocalizationController>();
    final bool isArabic = localizationController.locale.languageCode == 'ar';
    // languages[0] = ar, languages[1] = en
    final target =
        isArabic ? AppConstants.languages[1] : AppConstants.languages[0];
    localizationController.setLanguage(
      context,
      Locale(target.languageCode!, target.countryCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: Center(
          child: Container(
            width: isDesktop ? 450 : context.width,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeLarge),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GetBuilder<LocalizationController>(
                    builder: (localizationController) {
                      final bool isArabic =
                          localizationController.locale.languageCode == 'ar';
                      return _LanguagePill(
                        label: isArabic ? 'English' : 'العربية',
                        onTap: () => _toggleLanguage(context),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Images.shellaLogo,
                          width: 223, height: 160, fit: BoxFit.contain),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Text(
                        'welcome_with_you'.tr,
                        textAlign: TextAlign.center,
                        style: tajawalBold.copyWith(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomButton(
                  buttonText: 'continue_with_phone'.tr,
                  isBold: true,
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  textHeight: 1.6,
                  textColor: Colors.white,
                  onPressed: () =>
                      Get.toNamed(RouteHelper.getPhoneLoginRoute()),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                const SocialAuthButtonsWidget(),
                if (SocialAuthButtonsWidget.hasAnySocial)
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                GetBuilder<AuthController>(builder: (authController) {
                  return CustomButton(
                    buttonText: 'continue_as_guest'.tr,
                    isBold: true,
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    textHeight: 1.6,
                    color: const Color(0xFFF1F3F5),
                    textColor: Theme.of(context).textTheme.bodyLarge!.color,
                    isLoading: authController.guestLoading,
                    onPressed: () => _guestLogin(context, authController),
                  );
                }),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LanguagePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language,
                size: 16, color: Theme.of(context).textTheme.bodyLarge!.color),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Text(label,
                style:
                    robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
          ],
        ),
      ),
    );
  }
}
