import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/code_picker_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/helper/otp_error_helper.dart';
import 'package:sixam_mart/features/auth/widgets/social_auth_buttons_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Saudi mobile numbers are 9 digits after the country code.
const int _kPhoneMaxDigits = 9;

/// Headline text color from the design system — hsba(162, 37%, 11%).
const Color _kHeadlineColor = Color(0xFF121C19);

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _countryDialCode;

  @override
  void initState() {
    super.initState();
    _countryDialCode = CountryCode.fromCountryCode(
            Get.find<SplashController>().configModel?.country ?? 'SA')
        .dialCode;
    // Rebuild on focus change so the field shows the active (green) border.
    _phoneFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onFocusChange);
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(AuthController authController) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    String fullPhone = (_countryDialCode ?? '') + _phoneController.text.trim();
    final PhoneValid phoneValid = await CustomValidator.isPhoneValid(fullPhone);
    fullPhone = phoneValid.phone;
    if (!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
      return;
    }

    final result = await authController.sendOtp(phone: fullPhone);
    if (result.success) {
      Get.toNamed(
        RouteHelper.getOtpVerificationRoute(),
        arguments: {
          'phone': fullPhone,
          'cooldown': result.cooldownSeconds,
          'expires': result.expiresInSeconds,
        },
      );
    } else {
      showCustomSnackBar(mapOtpAuthError(result.errorCode, result.message));
    }
  }

  /// Phone field — a SINGLE [TextFormField] whose border (managed by the
  /// framework) turns green on focus. The country code is a prefix inside the
  /// same field, so it always reads as ONE field (never two boxes).
  Widget _buildPhoneField(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder borderWith(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          borderSide: BorderSide(color: color, width: width),
        );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: _phoneController,
        focusNode: _phoneFocus,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        cursorColor: theme.primaryColor,
        style: tajawalRegular.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            height: 1.6,
            color: _kHeadlineColor),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9]')),
          LengthLimitingTextInputFormatter(_kPhoneMaxDigits),
        ],
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeLarge),
          hintText: '00 000 0000',
          hintStyle: tajawalRegular.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.6,
              color: theme.hintColor),
          enabledBorder: borderWith(theme.disabledColor, 0.5),
          focusedBorder: borderWith(theme.primaryColor, 1.2),
          border: borderWith(theme.disabledColor, 0.5),
          // Country code lives inside the same field as a prefix.
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeDefault),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CodePickerWidget(
                  flagWidth: 25,
                  padding: EdgeInsets.zero,
                  showFlagMain: false, // dial code only, no flag
                  onChanged: (CountryCode countryCode) {
                    _countryDialCode = countryCode.dialCode;
                  },
                  initialSelection: _countryDialCode,
                  favorite: [_countryDialCode ?? ''],
                  enabled: Get.find<SplashController>()
                          .configModel
                          ?.countryPickerStatus ??
                      true,
                  dialogBackgroundColor: theme.cardColor,
                  textStyle: tajawalRegular.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.6,
                    color: _kHeadlineColor,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                // Separator inside the single field (not a second box).
                Container(
                    width: 1,
                    height: 22,
                    color: theme.disabledColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
        validator: (value) => (value == null || value.trim().isEmpty)
            ? 'please_enter_phone_number'.tr
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        // Back icon pinned to the physical left (LTR icon) regardless of RTL.
        actions: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back_ios_new,
                  size: 20,
                  color: Theme.of(context).textTheme.bodyLarge!.color),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            width: isDesktop ? 450 : context.width,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top content (scrolls if the keyboard reduces space).
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'login'.tr,
                              textAlign: TextAlign.start,
                              style: tajawalBold.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                height: 41 / 34,
                                letterSpacing: 0.4,
                                color: _kHeadlineColor,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraLarge),
                          // Label above the field (RTL — sits on the right).
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: Dimensions.paddingSizeSmall),
                            child: Text('phone_number_label'.tr,
                                style: tajawalMedium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.6,
                                    color: _kHeadlineColor)),
                          ),
                          _buildPhoneField(context),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            'otp_sms_hint'.tr,
                            textAlign: TextAlign.start,
                            style: tajawalRegular.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                                color: const Color(0xFF545454)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom-pinned actions.
                  GetBuilder<AuthController>(builder: (authController) {
                    return CustomButton(
                      buttonText: 'continue_action'.tr,
                      isBold: true,
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      textHeight: 1.6,
                      isLoading: authController.isLoading,
                      onPressed: () => _sendOtp(authController),
                    );
                  }),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  const SocialAuthButtonsWidget(),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
