import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/helper/otp_error_helper.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

const Color _kHeadlineColor = Color(0xFF121C19);

const Color _kDisabledInputColor = Color(0xFF717885);

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _acceptedTerms = false;

  /// Submit is enabled once a name is entered AND the terms are accepted
  /// (button shows a disabled grey state otherwise).
  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && _acceptedTerms;

  @override
  void initState() {
    super.initState();
    // Rebuild so the submit button reflects whether a name has been entered.
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _register(AuthController authController) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptedTerms) {
      showCustomSnackBar('please_accept_terms'.tr);
      return;
    }

    final response = await authController.registerV2(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: authController.otpPhone,
      registrationToken: authController.registrationToken,
    );
    if (!mounted) {
      return;
    }
    if (response.isSuccess) {
      Get.find<LocationController>()
          .navigateToLocationScreen(context, 'sign-in', offNamed: true);
    } else {
      // response.message carries the backend code (or message) — map it.
      showCustomSnackBar(mapOtpAuthError(response.message, response.message));
      // Expired/invalid registration token: the OTP session is no longer
      // valid, so send the user back to the phone screen to start over.
      if (response.message == 'invalid_registration_token') {
        Get.until((route) =>
            route.settings.name == RouteHelper.phoneLogin || route.isFirst);
      }
    }
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: Text(text,
            style: tajawalBold.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.6,
                color: _kHeadlineColor)),
      );

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    required TextInputType inputType,
    TextInputAction inputAction = TextInputAction.next,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: inputType,
      textInputAction: inputAction,
      textCapitalization: capitalization,
      // Re-validate as the user types so the error/red border clears once valid.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: theme.primaryColor,
      style: tajawalRegular.copyWith(
          fontSize: 16, height: 1.6, color: _kHeadlineColor),
      onFieldSubmitted: (_) => nextFocus != null
          ? FocusScope.of(context).requestFocus(nextFocus)
          : null,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeLarge),
        hintText: hint,
        hintStyle: tajawalMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.6,
            color: _kDisabledInputColor),
        enabledBorder: _border(theme.disabledColor, 0.5),
        focusedBorder: _border(theme.primaryColor, 1.2),
        border: _border(theme.disabledColor, 0.5),
      ),
      validator: validator,
    );
  }

  Widget _lockedPhoneField(String fullPhone) {
    final theme = Theme.of(context);
    final String national = fullPhone.length >= 9
        ? fullPhone.substring(fullPhone.length - 9)
        : fullPhone;
    final String dial = fullPhone.length >= 9
        ? fullPhone.substring(0, fullPhone.length - 9)
        : '';
    final TextStyle textStyle = tajawalRegular.copyWith(
        fontSize: 16, height: 1.6, color: _kHeadlineColor);
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        // Subtle grey fill signals the field is locked (read-only).
        color: theme.disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: theme.disabledColor, width: 0.5),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Text(dial,
                style: tajawalRegular.copyWith(
                    fontSize: 14, height: 1.6, color: _kHeadlineColor)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Container(
                width: 1,
                height: 22,
                color: theme.disabledColor.withValues(alpha: 0.5)),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(child: Text(national, style: textStyle)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final authController = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          Text('create_account'.tr,
                              style: tajawalBold.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: _kHeadlineColor,
                              )),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraLarge),
                          _label('user_name'.tr),
                          _field(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            nextFocus: _emailFocus,
                            hint: 'enter_username'.tr,
                            inputType: TextInputType.name,
                            capitalization: TextCapitalization.words,
                            validator: (value) =>
                                ValidateCheck.validateEmptyText(
                                    value, 'please_enter_your_name'.tr),
                          ),
                          // Full-name hint — shown only while the name is empty.
                          if (_nameController.text.trim().isEmpty) ...[
                            const SizedBox(
                                height: Dimensions.paddingSizeSmall),
                            Text('enter_full_name_hint'.tr,
                                style: tajawalMedium.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.6,
                                    color: const Color(0xFFE53935))),
                          ],
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          // "Email" in headline + "(optional)" in muted grey.
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: Dimensions.paddingSizeSmall),
                            child: Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: 'email_label'.tr,
                                  style: tajawalBold.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.6,
                                      color: _kHeadlineColor)),
                              TextSpan(
                                  text: ' ${'optional_label'.tr}',
                                  style: tajawalMedium.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.6,
                                      color: _kDisabledInputColor)),
                            ])),
                          ),
                          _field(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            hint: 'write_email'.tr,
                            inputType: TextInputType.emailAddress,
                            inputAction: TextInputAction.done,
                            // Email is optional.
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? null
                                    : ValidateCheck.validateEmail(value),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          _label('phone_number_label'.tr),
                          _lockedPhoneField(authController.otpPhone),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => setState(
                                    () => _acceptedTerms = !_acceptedTerms),
                                child: Image.asset(
                                  _acceptedTerms
                                      ? Images.checkbox_activate
                                      : Images.checkbox_notactivate,
                                  height: 22,
                                  width: 22,
                                  errorBuilder: (context, error, stack) => Icon(
                                    _acceptedTerms
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 22,
                                    color: _acceptedTerms
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).disabledColor,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  width: Dimensions.paddingSizeSmall),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _acceptedTerms = !_acceptedTerms),
                                  child: Text('agree_terms_privacy'.tr,
                                      style: tajawalRegular.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          height: 1.6,
                                          color: _kHeadlineColor)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  GetBuilder<AuthController>(builder: (authController) {
                    return CustomButton(
                      buttonText: 'create_account'.tr,
                      isBold: true,
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      textHeight: 1.6,
                      // Disabled (grey #E2E4E6) until name + terms are valid.
                      textColor:
                          _canSubmit ? Colors.white : _kDisabledInputColor,
                      disabledColor: const Color(0xFFE2E4E6),
                      isLoading: authController.isLoading,
                      onPressed:
                          _canSubmit ? () => _register(authController) : null,
                    );
                  }),
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
