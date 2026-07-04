import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/profile/screens/delete_account_screen.dart';
import 'package:sixam_mart/features/profile/screens/gender_select_screen.dart';
import 'package:sixam_mart/features/profile/widgets/profile_photo_edit_sheet.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/responsive_size.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  // UI-only gender selection persisted locally (not part of the backend API).
  static const String _genderPrefsKey = 'profile_gender_ui_only';

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  JustTheController toolController = JustTheController();
  final ScrollController scrollController = ScrollController();
  String? _countryDialCode;
  String? _gender;
  // Ensures the existing user data is loaded into the fields exactly once.
  bool _prefilled = false;

  static const Color _fieldColor = Color(0xFFF3F4F6);
  static const Color _labelColor = Color(0xFF2D3633);
  static const Color _header = Color(0xFF111B18);
  static const Color _hintColor = Color(0xFF9AA0A6);

  @override
  void initState() {
    super.initState();
    _initCall();
    _loadGender();
  }

  void _initCall() {
    final AuthController authController = Get.find<AuthController>();
    final String? configCountry =
        Get.find<SplashController>().configModel?.country;
    _countryDialCode = authController.getUserCountryCode().isNotEmpty
        ? authController.getUserCountryCode()
        : (configCountry != null && configCountry.isNotEmpty
            ? CountryCode.fromCountryCode(configCountry).dialCode
            : null);

    if (Get.find<AuthController>().isLoggedIn() &&
        Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
    Get.find<ProfileController>().initData();
  }

  Future<void> _loadGender() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _gender = prefs.getString(_genderPrefsKey);
    });
  }

  @override
  void dispose() {
    toolController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _splitPhoneNumber(String number) async {
    try {
      final PhoneValid phoneNumber = await CustomValidator.isPhoneValid(number);
      _phoneController.text =
          phoneNumber.phone.replaceFirst('+${phoneNumber.countryCode}', '');
      _countryDialCode = '+${phoneNumber.countryCode}';
    } catch (e) {
      if (kDebugMode) debugPrint('$e');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLoggedIn = Get.find<AuthController>().isLoggedIn();
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      appBar: isDesktop ? const WebMenuBar() : _buildAppBar(),
      backgroundColor:
          isDesktop ? theme.colorScheme.surface : AppColors.wtColor,
      body: SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: GetBuilder<ProfileController>(builder: (profileController) {
          // 🎯 Prefill the existing user data into the fields ONCE, as soon as
          // it's available — so the user edits a digit/letter instead of
          // retyping everything. Deferred to post-frame to avoid mutating
          // controllers/state during build.
          if (profileController.userInfoModel != null && !_prefilled) {
            _prefilled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final user = profileController.userInfoModel;
              if (user == null) return;
              _nameController.text =
                  '${user.fName ?? ''} ${user.lName ?? ''}'.trim();
              _emailController.text = user.email ?? '';
              final String phone = user.phone ?? '';
              if (phone.isNotEmpty) {
                _splitPhoneNumber(phone);
              }
            });
          }

          return isLoggedIn
              ? profileController.userInfoModel != null
                  ? isDesktop
                      ? webView(profileController, isLoggedIn)
                      : _buildMobileForm(context, profileController)
                  : const Center(child: CircularProgressIndicator())
              : NotLoggedInScreen(callBack: (value) {
                  _initCall();
                  setState(() {});
                });
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.wtColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        'pf_account_settings'.tr,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18.r(context),
          fontWeight: FontWeight.w700,
          color: _header,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
            size: 18.r(context), color: _labelColor),
        onPressed: () => Get.back(),
      ),
    );
  }

  // ─────────────────────────────── Mobile form ───────────────────────────────

  Widget _buildMobileForm(BuildContext context, ProfileController pc) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                20.r(context), 10.r(context), 20.r(context), 20.r(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 6.r(context)),
                Center(child: _avatarWithBadge(context, pc)),
                SizedBox(height: 30.r(context)),
                _fieldLabel('pf_name'.tr, required: true),
                SizedBox(height: 8.r(context)),
                _filledField(
                  controller: _nameController,
                  hint: 'pf_enter_name'.tr,
                  focusNode: _nameFocus,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 20.r(context)),
                _fieldLabel('pf_email'.tr, required: true),
                SizedBox(height: 8.r(context)),
                _filledField(
                  controller: _emailController,
                  hint: 'pf_enter_email'.tr,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  onChanged: (_) => pc.update(),
                  suffix: _emailSuffix(pc),
                ),
                SizedBox(height: 20.r(context)),
                _fieldLabel('pf_phone_number'.tr, note: 'pf_not_editable'.tr),
                SizedBox(height: 8.r(context)),
                _filledField(
                  controller: _phoneController,
                  hint: '',
                  enabled: false,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: 20.r(context)),
                _fieldLabel('pf_gender'.tr),
                SizedBox(height: 8.r(context)),
                _genderField(context),
                SizedBox(height: 26.r(context)),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _confirmDeleteAccount(context, pc),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF6F5F8),
                      padding: EdgeInsets.symmetric(vertical: 16.r(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'pf_delete_account'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 17.r(context),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xffEB4335),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              20.r(context), 4.r(context), 20.r(context), 16.r(context)),
          child: CustomButton(
            isLoading: pc.isLoading,
            radius: 12,
            fontFamily: 'Tajawal',
            buttonText: 'pf_save'.tr,
            onPressed: () => _updateProfile(
                profileController: pc, fromButton: true, fromPhone: false),
          ),
        ),
      ],
    );
  }

  Widget _avatarWithBadge(BuildContext context, ProfileController pc) {
    final bool hasServerImage = !pc.avatarCleared &&
        (pc.userInfoModel?.imageFullUrl?.isNotEmpty ?? false);
    final bool hasPhoto = pc.pickedFile != null || hasServerImage;
    final double avatarSize = 96.r(context);
    final double innerSize = 92.r(context);
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        children: <Widget>[
          ClipOval(
            child: pc.pickedFile != null
                ? (GetPlatform.isWeb
                    ? Image.network(
                        pc.pickedFile!.path,
                        width: innerSize,
                        height: innerSize,
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                        cacheHeight: 300,
                      )
                    : Image.file(
                        File(pc.pickedFile!.path),
                        width: innerSize,
                        height: innerSize,
                        fit: BoxFit.cover,
                      ))
                : _buildProfileAvatar(pc, innerSize, context,
                    forcePlaceholder: pc.avatarCleared),
          ),
          PositionedDirectional(
            bottom: 0,
            start: 0,
            child: InkWell(
              onTap: () =>
                  hasPhoto ? _openEditPhotoSheet(pc) : _pickProfilePhoto(pc),
              child: Image.asset(
                Images.edit_avatar,
                width: 26.r(context),
                height: 26.r(context),
                errorBuilder: (context, error, stack) => Container(
                  padding: EdgeInsets.all(5.r(context)),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.wtColor, width: 2),
                  ),
                  child: Icon(hasPhoto ? Icons.check : Icons.add,
                      size: 15.r(context), color: AppColors.wtColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditPhotoSheet(ProfileController pc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfilePhotoEditSheet(
        // Frame from the original (un-cropped) image so zoom is reversible.
        localPath: pc.originalPickedFile?.path ?? pc.pickedFile?.path,
        imageUrl: pc.avatarCleared ? null : pc.userInfoModel?.imageFullUrl,
      ),
    );
  }

  Widget? _emailSuffix(ProfileController pc) {
    final bool verified = (pc.userInfoModel?.isEmailVerified ?? false) &&
        pc.userInfoModel?.email == _emailController.text;
    if (verified) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(Images.verifiedIcon, width: 20, height: 20),
      );
    }
    final bool needsVerification = Get.find<SplashController>()
            .configModel
            ?.centralizeLoginSetup
            ?.emailVerificationStatus ??
        false;
    if (!needsVerification) {
      return null;
    }
    return InkWell(
      onTap: () async {
        if (!(pc.userInfoModel!.isEmailVerified ?? false) ||
            pc.userInfoModel!.email != _emailController.text) {
          Get.dialog(const CustomLoaderWidget());
          await _updateProfile(
              profileController: pc, fromButton: false, fromPhone: false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(Images.unverifiedIcon, width: 20, height: 20),
      ),
    );
  }

  Widget _genderField(BuildContext context) {
    final bool hasValue = _gender != null && _gender!.isNotEmpty;
    return GestureDetector(
      onTap: () => _pickGender(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52.r(context),
        padding: EdgeInsets.symmetric(horizontal: 16.r(context)),
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                hasValue ? _gender! : 'pf_select_gender'.tr,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.r(context),
                  fontWeight: FontWeight.w500,
                  color: hasValue ? _labelColor : _hintColor,
                ),
              ),
            ),
            Icon(Icons.arrow_back_ios_new, size: 15.r(context), color: _hintColor),
          ],
        ),
      ),
    );
  }

  Future<void> _pickGender(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final String? selected =
        await Get.to<String>(() => GenderSelectScreen(initial: _gender));
    if (selected == null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderPrefsKey, selected);
    if (!mounted) {
      return;
    }
    setState(() {
      _gender = selected;
    });
  }

  void _confirmDeleteAccount(BuildContext context, ProfileController pc) {
    Get.to(() => const DeleteAccountScreen());
  }

  Future<void> _pickProfilePhoto(ProfileController pc) async {
    final XFile? file =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (file != null) {
      pc.setPickedFile(file);
    }
  }

  // ─────────────────────────────── Field widgets ─────────────────────────────

  Widget _fieldLabel(String label, {bool required = false, String? note}) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16.r(context),
            fontWeight: FontWeight.w700,
            color: _header,
          ),
        ),
        if (required) ...<Widget>[
          SizedBox(width: 3.r(context)),
          Text(
            '*',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16.r(context),
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (note != null) ...<Widget>[
          SizedBox(width: 6.r(context)),
          Text(
            note,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.r(context),
              fontWeight: FontWeight.w500,
              color: const Color(0xff555555),
            ),
          ),
        ],
      ],
    );
  }

  Widget _filledField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    bool enabled = true,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.start,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textDirection: textDirection,
        textAlign: textAlign,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 15.r(context),
          fontWeight: FontWeight.w500,
          color: _header,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: textDirection,
          hintStyle: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14.r(context),
            fontWeight: FontWeight.w400,
            color: _hintColor,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 16.r(context), vertical: 15.r(context)),
          suffixIcon: suffix,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ),
    );
  }

  // ─────────────────────────────── Web (unchanged) ───────────────────────────

  Widget webView(ProfileController profileController, bool isLoggedIn) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();
    return SingleChildScrollView(
      controller: scrollController,
      child: FooterView(
        child: Stack(children: [
          SizedBox(height: 520, width: context.width),
          Center(
            child: Container(
              height: 300,
              width: Dimensions.webMaxWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                image: const DecorationImage(
                    image: AssetImage(Images.profileBg), fit: BoxFit.fill),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                  child: Text('profile'.tr,
                      style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).cardColor)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  alignment: Alignment.topCenter,
                  height: 400,
                  width: Dimensions.webMaxWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Dimensions.radiusExtraLarge),
                        bottom: Radius.circular(Dimensions.radiusDefault)),
                    boxShadow: [
                      BoxShadow(
                        color: (tokens?.outlineSoft ?? theme.dividerColor)
                            .withValues(alpha: 0.35),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                ),
                Positioned(
                  top: -50,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Stack(children: [
                      ClipOval(
                          child: profileController.pickedFile != null
                              ? GetPlatform.isWeb
                                  ? Image.network(
                                      profileController.pickedFile!.path,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      cacheWidth: 300,
                                      cacheHeight: 300,
                                    )
                                  : Image.file(
                                      File(profileController.pickedFile!.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover)
                              : _buildProfileAvatar(
                                  profileController, 100, context)),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        top: 0,
                        left: 0,
                        child: InkWell(
                          onTap: () => profileController.pickImage(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.scrim
                                  .withValues(alpha: 0.30),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 2, color: theme.colorScheme.surface),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt,
                                  color: theme.colorScheme.surface),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 90),
                    child: Center(
                      child: SizedBox(
                        width: 500,
                        child: Column(children: [
                          CustomTextField(
                            titleText: 'enter_name'.tr,
                            controller: _nameController,
                            capitalization: TextCapitalization.words,
                            inputType: TextInputType.name,
                            focusNode: _nameFocus,
                            nextFocus: _emailFocus,
                            prefixIcon: CupertinoIcons.person_alt_circle_fill,
                            labelText: 'name'.tr,
                            required: true,
                            validator: (value) =>
                                ValidateCheck.validateEmptyText(
                                    value, 'first_name_field_is_required'.tr),
                          ),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraOverLarge),
                          CustomTextField(
                            titleText: 'enter_email'.tr,
                            controller: _emailController,
                            focusNode: _emailFocus,
                            inputType: TextInputType.emailAddress,
                            prefixIcon: CupertinoIcons.mail_solid,
                            labelText: 'email'.tr,
                            required: true,
                            validator: (value) =>
                                ValidateCheck.validateEmail(value),
                            onChanged: (value) {
                              profileController.update();
                            },
                            suffixImage: profileController
                                        .userInfoModel!.isEmailVerified! &&
                                    profileController.userInfoModel!.email ==
                                        _emailController.text
                                ? Images.verifiedIcon
                                : Get.find<SplashController>()
                                        .configModel!
                                        .centralizeLoginSetup!
                                        .emailVerificationStatus!
                                    ? Images.unverifiedIcon
                                    : null,
                            suffixOnPressed: () {
                              if (!profileController
                                      .userInfoModel!.isEmailVerified! ||
                                  profileController.userInfoModel!.email !=
                                      _emailController.text) {
                                _updateProfile(
                                    profileController: profileController,
                                    fromButton: false,
                                    fromPhone: false);
                              }
                            },
                          ),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraOverLarge),
                          CustomTextField(
                            titleText: 'phone'.tr,
                            controller: _phoneController,
                            inputType: TextInputType.phone,
                            isEnabled: false,
                            fromUpdateProfile: true,
                            neutralHintForNonChangeable: true,
                            labelText: 'phone'.tr,
                            required: false,
                            isPhone: true,
                            onCountryChanged: (CountryCode countryCode) =>
                                _countryDialCode = countryCode.dialCode,
                            countryDialCode: _countryDialCode ??
                                Get.find<LocalizationController>()
                                    .locale
                                    .countryCode,
                            suffixImage: profileController
                                    .userInfoModel!.isPhoneVerified!
                                ? Images.verifiedIcon
                                : null,
                          ),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraOverLarge),
                          CustomButton(
                            width: 500,
                            buttonText: 'update_profile'.tr,
                            fontSize: Dimensions.fontSizeDefault,
                            isBold: false,
                            radius: Dimensions.radiusSmall,
                            isLoading: profileController.isLoading,
                            onPressed: () => _updateProfile(
                                profileController: profileController,
                                fromButton: true,
                                fromPhone: false),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildProfileAvatar(
      ProfileController profileController, double size, BuildContext context,
      {bool forcePlaceholder = false}) {
    final String? imageUrl =
        forcePlaceholder ? null : profileController.userInfoModel?.imageFullUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Image.asset(Images.profile),
      );
    }

    // Use CustomImage so the CDN-required User-Agent headers are sent.
    // FadeInImage/Image.network omit them, so the CDN returns HTML instead of
    // the image and the avatar falls back to a placeholder even when a photo
    // exists.
    return CustomImage(
      image: imageUrl,
      height: size,
      width: size,
      fit: BoxFit.cover,
      errorWidget: _buildProfileAvatarFallback(size, context),
      placeholderWidget: _buildProfileAvatarFallback(size, context),
    );
  }

  Widget _buildProfileAvatarFallback(double size, BuildContext context) {
    return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Image.asset(Images.profile));
  }

  Future<void> _updateProfile(
      {required ProfileController profileController,
      required bool fromButton,
      required bool fromPhone}) async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String? existingPhone =
        profileController.userInfoModel?.phone?.trim();

    if (name.isEmpty) {
      showCustomSnackBar('enter_your_name'.tr);
    } else if (existingPhone == null || existingPhone.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    } else if (email.isEmpty) {
      showCustomSnackBar('enter_email_address'.tr);
    } else if (!GetUtils.isEmail(email)) {
      showCustomSnackBar('enter_a_valid_email_address'.tr);
    } else {
      final UpdateUserModel updatedUser = UpdateUserModel(
          name: name,
          email: email,
          phone: existingPhone,
          buttonType: fromButton
              ? ''
              : fromPhone
                  ? 'phone'
                  : 'email');
      await profileController.updateUserInfo(
          updatedUser, Get.find<AuthController>().getUserToken(),
          fromButton: fromButton);
    }
  }
}
