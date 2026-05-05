// ignore_for_file: non_constant_identifier_names, unrelated_type_equality_checks

import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/auth/widgets/build_upload_section.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_body.dart';
import 'package:sixam_mart/features/auth/controllers/deliveryman_registration_controller.dart';
import 'package:sixam_mart/features/auth/widgets/condition_check_box_widget.dart';
import 'package:sixam_mart/features/auth/widgets/pass_view_widget.dart';
import 'package:sixam_mart/features/auth/widgets/password_validation_dialog.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';

class DeliveryManRegistrationScreen extends StatefulWidget {
  const DeliveryManRegistrationScreen({super.key});

  @override
  State<DeliveryManRegistrationScreen> createState() =>
      _DeliveryManRegistrationScreenState();
}

class _DeliveryManRegistrationScreenState
    extends State<DeliveryManRegistrationScreen> {
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _identityNumberController =
      TextEditingController();
  final FocusNode _fNameNode = FocusNode();
  final FocusNode _lNameNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _phoneNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();
  final FocusNode _identityNumberNode = FocusNode();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeyStep1;
  GlobalKey<FormState>? _formKeyStep2;
  bool _didCheckRegistrationOnOpen = false;

  String? _normalizedPhone(String? phone) {
    final value = phone?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }
    return value;
  }

  String _toWesternDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();

    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final idxArabic = arabicIndic.indexOf(char);
      if (idxArabic != -1) {
        buffer.write(idxArabic);
        continue;
      }

      final idxEastern = easternArabicIndic.indexOf(char);
      if (idxEastern != -1) {
        buffer.write(idxEastern);
        continue;
      }

      buffer.write(char);
    }

    return buffer.toString();
  }

  String _sanitizePhone(String raw) {
    final value = _toWesternDigits(raw).trim();
    if (value.isEmpty) {
      return '';
    }

    final hasPlusPrefix = value.startsWith('+');
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (hasPlusPrefix) {
      return '+$digitsOnly';
    }
    if (digitsOnly.startsWith('00')) {
      return '+${digitsOnly.substring(2)}';
    }
    return digitsOnly;
  }

  String _resolveDialDigits() {
    final dialFromSelection =
        _countryDialCode ?? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode ?? '';
    return dialFromSelection.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _resolvePhoneWithCountryCode() {
    final profilePhoneRaw =
        _normalizedPhone(Get.find<ProfileController>().userInfoModel?.phone);
    if (profilePhoneRaw != null && profilePhoneRaw.isNotEmpty) {
      final profileSanitized = _sanitizePhone(profilePhoneRaw);
      if (profileSanitized.startsWith('+')) {
        return profileSanitized;
      }

      final dialDigits = _resolveDialDigits();
      if (dialDigits.isNotEmpty) {
        if (profileSanitized.startsWith(dialDigits)) {
          return '+$profileSanitized';
        }
        var nsn = profileSanitized;
        if (nsn.startsWith('0')) {
          nsn = nsn.substring(1);
        }
        return '+$dialDigits$nsn';
      }
      return profileSanitized;
    }

    final rawPhone = _sanitizePhone(_phoneController.text);
    if (rawPhone.isEmpty) {
      return '';
    }

    if (rawPhone.startsWith('+')) {
      return rawPhone;
    }

    final dialDigits = _resolveDialDigits();
    if (dialDigits.isEmpty) {
      return rawPhone;
    }

    var nsn = rawPhone;
    if (nsn.startsWith('0')) {
      nsn = nsn.substring(1);
    }
    if (nsn.startsWith(dialDigits)) {
      return '+$nsn';
    }
    return '+$dialDigits$nsn';
  }

  Future<bool> _canProceedWithRegistration({
    required DeliverymanRegistrationController controller,
    required String phone,
    required String email,
    required String identityNumber,
  }) async {
    final Map<String, dynamic>? response =
        await controller.checkDeliveryManRegistration(
      phone: phone,
      email: email,
      identityNumber: identityNumber,
    );

    if (!mounted) {
      return false;
    }

    if (response == null) {
      showCustomSnackBar('تعذر التحقق من حالة التسجيل، حاول مرة أخرى');
      return false;
    }

    final bool isRegistered = response['is_registered'] == true;
    final bool canRegister = response['can_register'] == true;

    if (isRegistered || !canRegister) {
      String message = 'أنت مسجل بالفعل كرجل توصيل';
      final dynamic deliveryMan = response['delivery_man'];
      if (deliveryMan is Map<String, dynamic>) {
        final String? applicationStatus =
            deliveryMan['application_status']?.toString();
        if (applicationStatus != null && applicationStatus.isNotEmpty) {
          message = '$message (حالة الطلب: $applicationStatus)';
        }
      }
      showCustomSnackBar(message);
      return false;
    }

    return true;
  }

  Future<void> _checkRegistrationOnOpen() async {
    if (_didCheckRegistrationOnOpen) {
      return;
    }
    _didCheckRegistrationOnOpen = true;

    final deliveryController = Get.find<DeliverymanRegistrationController>();
    final profileController = Get.find<ProfileController>();

    final String phone =
        _normalizedPhone(profileController.userInfoModel?.phone) ?? '';
    final String email =
        profileController.userInfoModel?.email?.toString().trim() ?? '';

    final Map<String, dynamic>? response =
        await deliveryController.checkDeliveryManRegistration(
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
    );

    if (!mounted || response == null) {
      return;
    }

    final bool isRegistered = response['is_registered'] == true;
    final bool canRegister = response['can_register'] == true;

    if (isRegistered || !canRegister) {
      String message = 'أنت مسجل بالفعل كرجل توصيل';
      final dynamic deliveryMan = response['delivery_man'];
      if (deliveryMan is Map<String, dynamic>) {
        final String? applicationStatus =
            deliveryMan['application_status']?.toString();
        if (applicationStatus != null && applicationStatus.isNotEmpty) {
          message = '$message (حالة الطلب: $applicationStatus)';
        }
      }
      showCustomSnackBar(message);
      Future.microtask(() => Get.back());
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[DM-REG-SCREEN] initState() START');

    _formKeyStep1 = GlobalKey<FormState>();
    _formKeyStep2 = GlobalKey<FormState>();
    final configModel = Get.find<SplashController>().configModel;
    final country = configModel?.country;
    debugPrint('[DM-REG-SCREEN] initState => country=$country');
    if (country != null && country.isNotEmpty) {
      _countryDialCode = CountryCode.fromCountryCode(country).dialCode;
    }
    debugPrint('[DM-REG-SCREEN] initState => countryDialCode=$_countryDialCode');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[DM-REG-SCREEN] postFrameCallback => initializing controllers');
      final deliveryController = Get.find<DeliverymanRegistrationController>();
      final storeController = Get.find<StoreRegistrationController>();
      final profileController = Get.find<ProfileController>();

      if (deliveryController.showPassView) {
        deliveryController.showHidePass();
      }

      deliveryController.pickDmImage(false, true);
      deliveryController.dmStatusChange(0.4, isUpdate: false);
      storeController.validPassCheck('', isUpdate: false);
      deliveryController.setIdentityTypeIndex(
          deliveryController.identityTypeList[0], false);
      deliveryController.setDMTypeIndex(0, false);
      debugPrint('[DM-REG-SCREEN] postFrameCallback => calling getZoneList() and getVehicleList()');
      deliveryController.getZoneList();
      deliveryController.getVehicleList();

      final profilePhone = _normalizedPhone(profileController.userInfoModel?.phone);
      debugPrint('[DM-REG-SCREEN] postFrameCallback => profilePhone=$profilePhone');
      if (profilePhone == null) {
        debugPrint('[DM-REG-SCREEN] postFrameCallback => phone null, calling getUserInfo()');
        await profileController.getUserInfo();
      }

      await _checkRegistrationOnOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        debugPrint('[DM-REG-SCREEN] onPopInvoked => didPop=$didPop, dmStatus=${Get.find<DeliverymanRegistrationController>().dmStatus}');
        if (Get.find<DeliverymanRegistrationController>().dmStatus != 0.4 &&
            !didPop) {
          debugPrint('[DM-REG-SCREEN] onPopInvoked => going back to step 1');
          Get.find<DeliverymanRegistrationController>().dmStatusChange(0.4);
        } else {
          if (ResponsiveHelper.isDesktop(context)) {
            return;
          } else {
            debugPrint('[DM-REG-SCREEN] onPopInvoked => navigating back');
            Future.delayed(const Duration(), () => Get.back());
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: CustomAppBar(
          title: 'delivery_man_registration'.tr,
          onBackPressed: () {
            debugPrint('[DM-REG-SCREEN] AppBar BACK pressed => dmStatus=${Get.find<DeliverymanRegistrationController>().dmStatus}');
            if (Get.find<DeliverymanRegistrationController>().dmStatus != 0.4) {
              debugPrint('[DM-REG-SCREEN] AppBar BACK => going to step 1');
              Get.find<DeliverymanRegistrationController>().dmStatusChange(0.4);
            } else {
              debugPrint('[DM-REG-SCREEN] AppBar BACK => navigating back');
              Future.delayed(const Duration(), () => Get.back());
            }
          },
        ),
        body: GetBuilder<DeliverymanRegistrationController>(
            builder: (deliverymanRegistrationController) {
          debugPrint('[DM-REG-SCREEN] BUILD => dmStatus=${deliverymanRegistrationController.dmStatus}, isLoading=${deliverymanRegistrationController.isLoading}, zoneList=${deliverymanRegistrationController.zoneList?.length ?? 'null'}, vehicles=${deliverymanRegistrationController.vehicles?.length ?? 'null'}, vehicleIds=${deliverymanRegistrationController.vehicleIds != null ? 'loaded' : 'null'}');
          final profileController = Get.find<ProfileController>();
          final profilePhone =
              _normalizedPhone(profileController.userInfoModel?.phone);
          final List<int> zoneIndexList = [];
          final List<DropdownItem<int>> zoneList = [];
          final List<DropdownItem<int>> vehicleList = [];
          final List<DropdownItem<int>> dmTypeList = [];
          final List<DropdownItem<int>> identityTypeList = [];

          for (int index = 0;
              index < deliverymanRegistrationController.dmTypeList.length;
              index++) {
            dmTypeList.add(DropdownItem<int>(
                value: index,
                child: SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        '${deliverymanRegistrationController.dmTypeList[index]?.tr}'),
                  ),
                )));
          }
          for (int index = 0;
              index < deliverymanRegistrationController.identityTypeList.length;
              index++) {
            identityTypeList.add(DropdownItem<int>(
                value: index,
                child: SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(deliverymanRegistrationController
                        .identityTypeList[index].tr),
                  ),
                )));
          }
          if (deliverymanRegistrationController.zoneList != null) {
            for (int index = 0;
                index < deliverymanRegistrationController.zoneList!.length;
                index++) {
              zoneIndexList.add(index);
              zoneList.add(DropdownItem<int>(
                  value: index,
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          '${deliverymanRegistrationController.zoneList![index].name}'),
                    ),
                  )));
            }
          }
          if (deliverymanRegistrationController.vehicles != null) {
            for (int index = 0;
                index < deliverymanRegistrationController.vehicles!.length;
                index++) {
              vehicleList.add(DropdownItem<int>(
                  value: index,
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          '${deliverymanRegistrationController.vehicles![index].type}'),
                    ),
                  )));
            }
          }

          return SafeArea(
              child: ResponsiveHelper.isDesktop(context)
                  ? webView(deliverymanRegistrationController, zoneList,
                      dmTypeList, vehicleList, identityTypeList)
                  : Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeLarge,
                            vertical: Dimensions.paddingSizeSmall),
                        child: Column(children: [
                          Text(
                            'complete_registration_process_to_serve_as_delivery_man'
                                .tr,
                            style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor),
                          ),

                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          LinearProgressIndicator(
                            backgroundColor: Theme.of(context).disabledColor,
                            minHeight: 2,
                            value: deliverymanRegistrationController.dmStatus,
                          ),
                          // const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                        ]),
                      ),
                      Expanded(
                          child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                            ResponsiveHelper.isDesktop(context)
                                ? 0
                                : Dimensions.paddingSizeLarge),
                        physics: const BouncingScrollPhysics(),
                        child: FooterView(
                          child: SizedBox(
                              width: Dimensions.webMaxWidth,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(children: [
                                      Visibility(
                                        visible:
                                            deliverymanRegistrationController
                                                    .dmStatus ==
                                                0.4,
                                        child: Form(
                                          key: _formKeyStep1,
                                          child: Column(children: [
                                            Align(
                                                child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    child:
                                                        deliverymanRegistrationController
                                                                    .pickedImage !=
                                                                null
                                                            ? GetPlatform.isWeb
                                                                ? Image.network(
                                                                    deliverymanRegistrationController
                                                                        .pickedImage!
                                                                        .path,
                                                                    width: 150,
                                                                    height: 120,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    cacheWidth:
                                                                        300,
                                                                    cacheHeight:
                                                                        300,
                                                                  )
                                                                : Image.file(
                                                                    File(deliverymanRegistrationController
                                                                        .pickedImage!
                                                                        .path),
                                                                    width: 150,
                                                                    height: 120,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                            : SizedBox(
                                                                width: 150,
                                                                height: 120,
                                                                child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .photo_camera,
                                                                          size:
                                                                              38,
                                                                          color:
                                                                              Theme.of(context).disabledColor),
                                                                      const SizedBox(
                                                                          height:
                                                                              Dimensions.paddingSizeSmall),
                                                                      Text(
                                                                        'upload_profile_picture'
                                                                            .tr,
                                                                        style: robotoMedium.copyWith(
                                                                            color:
                                                                                Theme.of(context).disabledColor,
                                                                            fontSize: Dimensions.fontSizeSmall),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                    ]),
                                                              ),
                                                  ),
                                                  Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    top: 0,
                                                    left: 0,
                                                    child: InkWell(
                                                      onTap: () {
                                                        debugPrint('[DM-REG-SCREEN] Profile image TAP => pickDmImage(true, false)');
                                                        deliverymanRegistrationController
                                                            .pickDmImage(
                                                                true, false);
                                                      },
                                                      child: DottedBorder(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        dashPattern: const [
                                                          5,
                                                          5
                                                        ],
                                                        padding:
                                                            const EdgeInsets
                                                                .all(0),
                                                        borderType:
                                                            BorderType.RRect,
                                                        radius: const Radius
                                                            .circular(Dimensions
                                                                .radiusDefault),
                                                        child: Visibility(
                                                          visible:
                                                              deliverymanRegistrationController
                                                                      .pickedImage !=
                                                                  null,
                                                          child: Center(
                                                            child: Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .all(25),
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    width: 2,
                                                                    color: Colors
                                                                        .white),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      Dimensions
                                                                          .paddingSizeLarge),
                                                              child: const Icon(
                                                                  Icons
                                                                      .camera_alt,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  deliverymanRegistrationController
                                                              .pickedImage !=
                                                          null
                                                      ? Positioned(
                                                          bottom: -10,
                                                          right: -10,
                                                          child: InkWell(
                                                            onTap: () {
                                                              debugPrint('[DM-REG-SCREEN] Remove profile image TAP');
                                                              deliverymanRegistrationController
                                                                  .removeDmImage();
                                                            },
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .cardColor,
                                                                    width: 2),
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .error,
                                                              ),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      Dimensions
                                                                          .paddingSizeExtraSmall),
                                                              child: Icon(
                                                                Icons.remove,
                                                                size: 18,
                                                                color: Theme.of(
                                                                        context)
                                                                    .cardColor,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ])),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge),
                                            Row(children: [
                                              Expanded(
                                                  child: CustomTextField(
                                                labelText: 'first_name'.tr,
                                                titleText: 'ex_jhon'.tr,
                                                controller: _fNameController,
                                                capitalization:
                                                    TextCapitalization.words,
                                                inputType: TextInputType.name,
                                                focusNode: _fNameNode,
                                                nextFocus: _lNameNode,
                                                prefixIcon: Icons.person,
                                                required: true,
                                                labelTextSize:
                                                    Dimensions.fontSizeSmall,
                                                validator: (value) =>
                                                    ValidateCheck
                                                        .validateEmptyText(
                                                            value, null),
                                              )),
                                              const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeLarge),
                                              Expanded(
                                                  child: CustomTextField(
                                                labelText: 'last_name'.tr,
                                                titleText: 'ex_doe'.tr,
                                                controller: _lNameController,
                                                capitalization:
                                                    TextCapitalization.words,
                                                inputType: TextInputType.name,
                                                focusNode: _lNameNode,
                                                nextFocus: _phoneNode,
                                                prefixIcon: Icons.person,
                                                required: true,
                                                labelTextSize:
                                                    Dimensions.fontSizeSmall,
                                                validator: (value) =>
                                                    ValidateCheck
                                                        .validateEmptyText(
                                                            value, null),
                                              )),
                                            ]),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge),
                                            profilePhone == null
                                                ? CustomTextField(
                                                    titleText:
                                                        'enter_phone_number'.tr,
                                                    labelText: 'phone'.tr,
                                                    controller:
                                                        _phoneController,
                                                    focusNode: _phoneNode,
                                                    nextFocus: _emailNode,
                                                    inputType:
                                                        TextInputType.phone,
                                                    isPhone: true,
                                                    onCountryChanged:
                                                        (CountryCode
                                                            countryCode) {
                                                      _countryDialCode =
                                                          countryCode.dialCode;
                                                    },
                                                    countryDialCode: _countryDialCode != null
                                                        ? CountryCode.fromCountryCode(
                                                                Get.find<
                                                                        SplashController>()
                                                                    .configModel!
                                                                    .country!)
                                                            .code
                                                        : Get.find<
                                                                LocalizationController>()
                                                            .locale
                                                            .countryCode,
                                                    required: true,
                                                    validator: (value) =>
                                                        ValidateCheck
                                                            .validatePhone(
                                                                value, null),
                                                  )
                                                : Card(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.phone,
                                                                  size: 20,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .hintColor),
                                                              const SizedBox(
                                                                  width: 15),
                                                              Text('رقم الهاتف',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: robotoRegular
                                                                      .copyWith(
                                                                          fontSize:
                                                                              Dimensions.fontSizeLarge)),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 20),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 15),
                                                          child: Text(
                                                            profilePhone,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: robotoMedium
                                                                .copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeLarge),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge),
                                            CustomTextField(
                                              labelText: 'email'.tr,
                                              titleText: 'enter_email'.tr,
                                              controller: _emailController,
                                              focusNode: _emailNode,
                                              nextFocus: _passwordNode,
                                              inputType:
                                                  TextInputType.emailAddress,
                                              prefixIcon: Icons.email,
                                              required: true,
                                              validator: (value) =>
                                                  ValidateCheck
                                                      .validateEmptyText(
                                                          value, null),
                                            ),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge),
                                            CustomTextField(
                                              labelText: 'password'.tr,
                                              titleText: '8_character'.tr,
                                              controller: _passwordController,
                                              focusNode: _passwordNode,
                                              nextFocus: _identityNumberNode,
                                              inputAction: TextInputAction.done,
                                              inputType:
                                                  TextInputType.visiblePassword,
                                              isPassword: true,
                                              prefixIcon: Icons.lock,
                                              onChanged: (value) {
                                                if (value != null &&
                                                    value
                                                        .toString()
                                                        .isNotEmpty) {
                                                  if (!deliverymanRegistrationController
                                                      .showPassView) {
                                                    deliverymanRegistrationController
                                                        .showHidePass();
                                                  }
                                                  deliverymanRegistrationController
                                                      .validPassCheck(
                                                          value.toString());
                                                } else {
                                                  if (deliverymanRegistrationController
                                                      .showPassView) {
                                                    deliverymanRegistrationController
                                                        .showHidePass();
                                                  }
                                                }
                                              },
                                              required: true,
                                              validator: (value) =>
                                                  ValidateCheck
                                                      .validateEmptyText(
                                                          value, null),
                                            ),
                                            deliverymanRegistrationController
                                                    .showPassView
                                                ? const PassViewWidget(
                                                    forStoreRegistration: false)
                                                : const SizedBox(),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge),
                                            CustomTextField(
                                              labelText: 'confirm_password'.tr,
                                              titleText: '8_character'.tr,
                                              controller:
                                                  _confirmPasswordController,
                                              focusNode: _confirmPasswordNode,
                                              inputAction: TextInputAction.done,
                                              inputType:
                                                  TextInputType.visiblePassword,
                                              prefixIcon: Icons.lock,
                                              isPassword: true,
                                              required: true,
                                              validator: (value) =>
                                                  ValidateCheck
                                                      .validateEmptyText(
                                                          value, null),
                                            )
                                          ]),
                                        ),
                                      ),

                                      // ======================================================================

                                      Visibility(
                                        visible:
                                            deliverymanRegistrationController
                                                    .dmStatus !=
                                                0.4,
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    color: Theme.of(context)
                                                        .cardColor,
                                                    border: Border.all(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        width: 0.3)),
                                                child: CustomDropdown<int>(
                                                  onChange:
                                                      (int? value, int index) {
                                                    debugPrint('[DM-REG-SCREEN] DM Type dropdown changed => value=$value, index=$index');
                                                    deliverymanRegistrationController
                                                        .setDMTypeIndex(
                                                            index, true);
                                                  },
                                                  indexZeroNotSelected: true,
                                                  dropdownButtonStyle:
                                                      DropdownButtonStyle(
                                                    height: 45,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: Dimensions
                                                          .paddingSizeExtraSmall,
                                                      horizontal: Dimensions
                                                          .paddingSizeExtraSmall,
                                                    ),
                                                    primaryColor:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge!
                                                            .color,
                                                  ),
                                                  dropdownStyle: DropdownStyle(
                                                    elevation: 10,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    padding: const EdgeInsets
                                                        .all(Dimensions
                                                            .paddingSizeExtraSmall),
                                                  ),
                                                  items: dmTypeList,
                                                  child: Text(
                                                      'select_delivery_type'
                                                          .tr),
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeLarge),

                                              // ===== طويق

                                              deliverymanRegistrationController
                                                          .zoneList !=
                                                      null
                                                  ? Container(
                                                      decoration: BoxDecoration(
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusDefault),
                                                          color:
                                                              Theme.of(context)
                                                                  .cardColor,
                                                          border: Border.all(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              width: 0.3)),
                                                      child:
                                                          CustomDropdown<int>(
                                                        onChange: (int? value,
                                                            int index) {
                                                          debugPrint('[DM-REG-SCREEN] Zone dropdown changed => value=$value, index=$index');
                                                          deliverymanRegistrationController
                                                              .setZoneIndex(
                                                                  value);
                                                        },
                                                        dropdownButtonStyle:
                                                            DropdownButtonStyle(
                                                          height: 45,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: Dimensions
                                                                .paddingSizeExtraSmall,
                                                            horizontal: Dimensions
                                                                .paddingSizeExtraSmall,
                                                          ),
                                                          primaryColor:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .color,
                                                        ),
                                                        dropdownStyle:
                                                            DropdownStyle(
                                                          elevation: 10,
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusDefault),
                                                          padding: const EdgeInsets
                                                              .all(Dimensions
                                                                  .paddingSizeExtraSmall),
                                                        ),
                                                        items: zoneList,
                                                        child: const Text(
                                                            'أختر العنوان'),
                                                      ),
                                                    )
                                                  : const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraLarge),

                                              // وسيله اتوصيل -==========================

                                              deliverymanRegistrationController
                                                          .vehicleIds !=
                                                      null
                                                  ? Container(
                                                      decoration: BoxDecoration(
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusDefault),
                                                          color:
                                                              Theme.of(context)
                                                                  .cardColor,
                                                          border: Border.all(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              width: 0.3)),
                                                      child:
                                                          CustomDropdown<int>(
                                                        onChange: (int? value,
                                                            int index) {
                                                          debugPrint('[DM-REG-SCREEN] Vehicle dropdown changed => value=$value, index=$index');
                                                          deliverymanRegistrationController
                                                              .setVehicleIndex(
                                                                  value, true);
                                                        },
                                                        dropdownButtonStyle:
                                                            DropdownButtonStyle(
                                                          height: 45,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: Dimensions
                                                                .paddingSizeExtraSmall,
                                                            horizontal: Dimensions
                                                                .paddingSizeExtraSmall,
                                                          ),
                                                          primaryColor:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .color,
                                                        ),
                                                        dropdownStyle:
                                                            DropdownStyle(
                                                          elevation: 10,
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusDefault),
                                                          padding: const EdgeInsets
                                                              .all(Dimensions
                                                                  .paddingSizeExtraSmall),
                                                        ),
                                                        items: vehicleList,
                                                        child: const Text(
                                                            'وسيلة التوصيل'),
                                                      ),
                                                    )
                                                  : deliverymanRegistrationController
                                                              .vehicles !=
                                                          null
                                                      ? Text(
                                                          'لا توجد مركبات متاحة',
                                                          style: robotoRegular.copyWith(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .error),
                                                        )
                                                      : const Center(
                                                          child:
                                                              CircularProgressIndicator()),

                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraLarge),

                                              //  =========================================================================================

                                              Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    color: Theme.of(context)
                                                        .cardColor,
                                                    border: Border.all(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        width: 0.3)),
                                                child: CustomDropdown<int>(
                                                  onChange:
                                                      (int? value, int index) {
                                                    debugPrint('[DM-REG-SCREEN] Identity Type dropdown changed => value=$value, index=$index');
                                                    deliverymanRegistrationController
                                                        .setIdentityTypeIndex(
                                                            deliverymanRegistrationController
                                                                    .identityTypeList[
                                                                index],
                                                            true);
                                                  },
                                                  dropdownButtonStyle:
                                                      DropdownButtonStyle(
                                                    height: 45,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: Dimensions
                                                          .paddingSizeExtraSmall,
                                                      horizontal: Dimensions
                                                          .paddingSizeExtraSmall,
                                                    ),
                                                    primaryColor:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge!
                                                            .color,
                                                  ),
                                                  dropdownStyle: DropdownStyle(
                                                    elevation: 10,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    padding: const EdgeInsets
                                                        .all(Dimensions
                                                            .paddingSizeExtraSmall),
                                                  ),
                                                  items: identityTypeList,
                                                  child:
                                                      const Text('نوع الهوية'),
                                                ),
                                              ),

                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraLarge),

                                              //

                                              Form(
                                                key: _formKeyStep2,
                                                child: CustomTextField(
                                                  labelText:
                                                      'identity_number'.tr,
                                                  titleText: deliverymanRegistrationController
                                                              .identityTypeIndex ==
                                                          0
                                                      ? 'Ex: XXXXX-XXXXXXX-X'
                                                      : deliverymanRegistrationController
                                                                  .identityTypeIndex ==
                                                              1
                                                          ? 'L-XXX-XXX-XXX-XXX.'
                                                          : 'XXX-XXXXX',
                                                  controller:
                                                      _identityNumberController,
                                                  focusNode:
                                                      _identityNumberNode,
                                                  inputAction:
                                                      TextInputAction.done,
                                                  required: true,
                                                  validator: (value) =>
                                                      ValidateCheck
                                                          .validateEmptyText(
                                                              value, null),
                                                ),
                                              ),

                                              //

                                              Driver_Documents_Widget(),

                                              // ============================================================================

                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraLarge),
                                              // ListView.builder(
                                              //   scrollDirection: Axis.vertical,
                                              //   shrinkWrap: true,
                                              //   physics: const NeverScrollableScrollPhysics(),
                                              //   itemCount: deliverymanRegistrationController.pickedIdentities.length + 1,
                                              //   itemBuilder: (context, index) {
                                              //     XFile? file = index == deliverymanRegistrationController.pickedIdentities.length
                                              //         ? null
                                              //         : deliverymanRegistrationController.pickedIdentities[index];
                                              //     if (index == deliverymanRegistrationController.pickedIdentities.length) {
                                              //       return InkWell(
                                              //         onTap: () => deliverymanRegistrationController.pickDmImage(false, false),
                                              //         child: DottedBorder(
                                              //           color: Theme.of(context).primaryColor,
                                              //           strokeWidth: 1,
                                              //           strokeCap: StrokeCap.butt,
                                              //           dashPattern: const [5, 5],
                                              //           padding: const EdgeInsets.all(5),
                                              //           borderType: BorderType.RRect,
                                              //           radius: const Radius.circular(Dimensions.radiusDefault),
                                              //           child: SizedBox(
                                              //             height: 120,
                                              //             width: double.infinity,
                                              //             child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              //               Icon(Icons.camera_alt, color: Theme.of(context).disabledColor, size: 38),
                                              //               Text('upload_identity_image'.tr,
                                              //                   style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
                                              //             ]),
                                              //           ),
                                              //         ),
                                              //       );
                                              //     }
                                              //     return Padding(
                                              //       padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                              //       child: DottedBorder(
                                              //         color: Theme.of(context).primaryColor,
                                              //         strokeWidth: 1,
                                              //         strokeCap: StrokeCap.butt,
                                              //         dashPattern: const [5, 5],
                                              //         padding: const EdgeInsets.all(5),
                                              //         borderType: BorderType.RRect,
                                              //         radius: const Radius.circular(Dimensions.radiusDefault),
                                              //         child: Stack(children: [
                                              //           ClipRRect(
                                              //             borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                              //             child: GetPlatform.isWeb
                                              //                 ? Image.network(
                                              //                     file!.path,
                                              //                     width: double.infinity,
                                              //                     height: 120,
                                              //                     fit: BoxFit.cover,
                                              //                   )
                                              //                 : Image.file(
                                              //                     File(file!.path),
                                              //                     width: double.infinity,
                                              //                     height: 120,
                                              //                     fit: BoxFit.cover,
                                              //                   ),
                                              //           ),
                                              //           Positioned(
                                              //             right: 0,
                                              //             top: 0,
                                              //             child: InkWell(
                                              //               onTap: () => deliverymanRegistrationController.removeIdentityImage(index),
                                              //               child: const Padding(
                                              //                 padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                                              //                 child: Icon(Icons.delete_forever, color: Colors.red),
                                              //               ),
                                              //             ),
                                              //           ),
                                              //         ]),
                                              //       ),
                                              //     );
                                              //   },
                                              // ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeSmall),
                                              const ConditionCheckBoxWidget(
                                                  forDeliveryMan: true,
                                                  forSignUp: false),
                                            ]),
                                      ),
                                    ]),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeLarge),
                                    (ResponsiveHelper.isDesktop(context) ||
                                            ResponsiveHelper.isWeb())
                                        ? buttonView()
                                        : const SizedBox(),

                                    //
                                  ])),
                        ),
                      )),
                      (ResponsiveHelper.isDesktop(context) ||
                              ResponsiveHelper.isWeb())
                          ? const SizedBox()
                          : buttonView(),
                    ]));
        }),
      ),
    );
  }

  //

  Widget Driver_Documents_Widget() {
    return GetBuilder<DeliverymanRegistrationController>(
      builder: (deliverymanRegiController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //

            buildUploadSection(
              context,
              title: 'الهوية الشخصية',
              images: deliverymanRegiController.identityImages,
              onAdd: () {
                debugPrint('[DM-REG-SCREEN] Upload identity image TAP');
                deliverymanRegiController.pickImage('identity');
              },
              onRemove: (index) {
                debugPrint('[DM-REG-SCREEN] Remove identity image TAP index=$index');
                deliverymanRegiController.removeImage('identity', index);
              },
            ),

            //

            deliverymanRegiController.vehicleIndex != 0 //  ليس مشاه
                ? buildUploadSection(
                    context,
                    title: 'رخصة السائق',
                    images: deliverymanRegiController.driverLicenseImages,
                    onAdd: () {
                      debugPrint('[DM-REG-SCREEN] Upload driver license image TAP');
                      deliverymanRegiController.pickImage('driver');
                    },
                    onRemove: (index) {
                      debugPrint('[DM-REG-SCREEN] Remove driver license image TAP index=$index');
                      deliverymanRegiController.removeImage('driver', index);
                    },
                  )
                : const SizedBox(),

            deliverymanRegiController.vehicleIndex != 0 //  ليس مشاه
                ? buildUploadSection(
                    context,
                    title: 'رخصة القيادة',
                    images: deliverymanRegiController.vehicleLicenseImages,
                    onAdd: () {
                      debugPrint('[DM-REG-SCREEN] Upload vehicle license image TAP');
                      deliverymanRegiController.pickImage('vehicle');
                    },
                    onRemove: (index) {
                      debugPrint('[DM-REG-SCREEN] Remove vehicle license image TAP index=$index');
                      deliverymanRegiController.removeImage('vehicle', index);
                    },
                  )
                : const SizedBox(),
          ],
        );
      },
    );
  }

  //

  Widget webView(
      DeliverymanRegistrationController deliverymanRegistrationController,
      List<DropdownItem<int>> zoneList,
      List<DropdownItem<int>> typeList,
      List<DropdownItem<int>> vehicleList,
      List<DropdownItem<int>> identityTypeList) {
    return SingleChildScrollView(
      child: Column(
        children: [
          WebScreenTitleWidget(title: 'join_as_delivery_man'.tr),
          FooterView(
            child: Center(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: Column(children: [
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            spreadRadius: 1)
                      ],
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Column(children: [
                      Text('delivery_man_registration'.tr,
                          style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        'complete_registration_process_to_serve_as_delivery_man'
                            .tr,
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Align(
                          child: Stack(children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                          child: deliverymanRegistrationController
                                      .pickedImage !=
                                  null
                              ? GetPlatform.isWeb
                                  ? Image.network(
                                      deliverymanRegistrationController
                                          .pickedImage!.path,
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      cacheWidth: 300,
                                      cacheHeight: 300,
                                    )
                                  : Image.file(
                                      File(deliverymanRegistrationController
                                          .pickedImage!.path),
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    )
                              : SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt,
                                            size: 38,
                                            color: Theme.of(context)
                                                .disabledColor),
                                        const SizedBox(
                                            height:
                                                Dimensions.paddingSizeSmall),
                                        Text(
                                          'upload_deliveryman_photo'.tr,
                                          style: robotoMedium.copyWith(
                                              color: Theme.of(context)
                                                  .disabledColor),
                                          textAlign: TextAlign.center,
                                        ),
                                      ]),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          top: 0,
                          left: 0,
                          child: InkWell(
                            onTap: () => deliverymanRegistrationController
                                .pickDmImage(true, false),
                            child: DottedBorder(
                              color: Theme.of(context).primaryColor,
                              dashPattern: const [5, 5],
                              padding: const EdgeInsets.all(0),
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(
                                  Dimensions.radiusDefault),
                              child: Visibility(
                                visible: deliverymanRegistrationController
                                        .pickedImage !=
                                    null,
                                child: Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          width: 2, color: Colors.white),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeLarge),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ])),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                      Row(children: [
                        Expanded(
                            child: CustomTextField(
                          titleText: 'first_name'.tr,
                          showLabelText: false,
                          controller: _fNameController,
                          capitalization: TextCapitalization.words,
                          inputType: TextInputType.name,
                          focusNode: _fNameNode,
                          nextFocus: _lNameNode,
                          prefixIcon: Icons.person,
                          showTitle: true,
                        )),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                            child: CustomTextField(
                          titleText: 'last_name'.tr,
                          showLabelText: false,
                          controller: _lNameController,
                          capitalization: TextCapitalization.words,
                          inputType: TextInputType.name,
                          focusNode: _lNameNode,
                          nextFocus: _phoneNode,
                          prefixIcon: Icons.person,
                          showTitle: true,
                        )),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: CustomTextField(
                            titleText: 'phone'.tr,
                            showLabelText: false,
                            controller: _phoneController,
                            focusNode: _phoneNode,
                            nextFocus: _emailNode,
                            inputType: TextInputType.phone,
                            isPhone: true,
                            showTitle: ResponsiveHelper.isDesktop(context),
                            onCountryChanged: (CountryCode countryCode) {
                              _countryDialCode = countryCode.dialCode;
                            },
                            countryDialCode: _countryDialCode != null
                                ? CountryCode.fromCountryCode(
                                        Get.find<SplashController>()
                                            .configModel!
                                            .country!)
                                    .code
                                : Get.find<LocalizationController>()
                                    .locale
                                    .countryCode,
                          ),
                        ),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: CustomTextField(
                              titleText: 'email'.tr,
                              showLabelText: false,
                              controller: _emailController,
                              focusNode: _emailNode,
                              nextFocus: _passwordNode,
                              inputType: TextInputType.emailAddress,
                              prefixIcon: Icons.email,
                              showTitle: true,
                            )),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                                child: Column(
                              children: [
                                CustomTextField(
                                  titleText: 'password'.tr,
                                  showLabelText: false,
                                  controller: _passwordController,
                                  focusNode: _passwordNode,
                                  nextFocus: _identityNumberNode,
                                  inputAction: TextInputAction.done,
                                  inputType: TextInputType.visiblePassword,
                                  isPassword: true,
                                  prefixIcon: Icons.lock,
                                  showTitle: true,
                                  onChanged: (value) {
                                    // authController.validPassCheck(value);
                                    if (value != null &&
                                        value.toString().isNotEmpty) {
                                      if (!deliverymanRegistrationController
                                          .showPassView) {
                                        deliverymanRegistrationController
                                            .showHidePass();
                                      }
                                      deliverymanRegistrationController
                                          .validPassCheck(value.toString());
                                    } else {
                                      if (deliverymanRegistrationController
                                          .showPassView) {
                                        deliverymanRegistrationController
                                            .showHidePass();
                                      }
                                    }
                                  },
                                ),
                                deliverymanRegistrationController.showPassView
                                    ? const PassViewWidget(
                                        forStoreRegistration: false)
                                    : const SizedBox(),
                              ],
                            )),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                                child: CustomTextField(
                              titleText: 'confirm_password'.tr,
                              hintText: '8_character'.tr,
                              showLabelText: false,
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordNode,
                              inputAction: TextInputAction.done,
                              inputType: TextInputType.visiblePassword,
                              prefixIcon: Icons.lock,
                              isPassword: true,
                              showTitle: true,
                            ))
                          ]),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            spreadRadius: 1)
                      ],
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.person),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Text('delivery_man_information'.tr,
                            style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall))
                      ]),
                      const Divider(),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Row(children: [
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('delivery_man_type'.tr,
                                style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall)),
                            const SizedBox(
                                height: Dimensions.paddingSizeDefault),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 0.3)),
                              child: CustomDropdown<int>(
                                onChange: (int? value, int index) {
                                  deliverymanRegistrationController
                                      .setDMTypeIndex(index, true);
                                },
                                dropdownButtonStyle: DropdownButtonStyle(
                                  height: 45,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingSizeExtraSmall,
                                    horizontal:
                                        Dimensions.paddingSizeExtraSmall,
                                  ),
                                  primaryColor: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color,
                                ),
                                dropdownStyle: DropdownStyle(
                                  elevation: 10,
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                  padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeExtraSmall),
                                ),
                                items: typeList,
                                child: Text('select_delivery_type'.tr),
                              ),
                            ),
                          ],
                        )),
                        const SizedBox(width: Dimensions.paddingSizeLarge),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('zone'.tr,
                                style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall)),
                            const SizedBox(
                                height: Dimensions.paddingSizeDefault),
                            deliverymanRegistrationController.zoneIds != null
                                ? Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            Dimensions.radiusDefault),
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 0.3)),
                                    child: CustomDropdown<int>(
                                      onChange: (int? value, int index) {
                                        deliverymanRegistrationController
                                            .setZoneIndex(value);
                                      },
                                      dropdownButtonStyle: DropdownButtonStyle(
                                        height: 45,
                                        padding: const EdgeInsets.symmetric(
                                          vertical:
                                              Dimensions.paddingSizeExtraSmall,
                                          horizontal:
                                              Dimensions.paddingSizeExtraSmall,
                                        ),
                                        primaryColor: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color,
                                      ),
                                      dropdownStyle: DropdownStyle(
                                        elevation: 10,
                                        borderRadius: BorderRadius.circular(
                                            Dimensions.radiusDefault),
                                        padding: const EdgeInsets.all(
                                            Dimensions.paddingSizeExtraSmall),
                                      ),
                                      items: zoneList,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(deliverymanRegistrationController
                                                    .selectedZoneIndex ==
                                                -1
                                            ? 'select_zone'.tr
                                            : deliverymanRegistrationController
                                                .zoneList![
                                                    deliverymanRegistrationController
                                                        .selectedZoneIndex!]
                                                .name
                                                .toString()),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                        'service_not_available_in_this_area'
                                            .tr)),
                          ],
                        )),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('vehicle_type'.tr,
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall)),
                                const SizedBox(
                                    height: Dimensions.paddingSizeDefault),
                                deliverymanRegistrationController.vehicleIds !=
                                        null
                                    ? Container(
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.radiusDefault),
                                            color: Theme.of(context).cardColor,
                                            border: Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                width: 0.3)),
                                        child: CustomDropdown<int>(
                                          onChange: (int? value, int index) {
                                            deliverymanRegistrationController
                                                .setVehicleIndex(value, true);
                                          },
                                          dropdownButtonStyle:
                                              DropdownButtonStyle(
                                            height: 45,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: Dimensions
                                                  .paddingSizeExtraSmall,
                                              horizontal: Dimensions
                                                  .paddingSizeExtraSmall,
                                            ),
                                            primaryColor: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color,
                                          ),
                                          dropdownStyle: DropdownStyle(
                                            elevation: 10,
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.radiusDefault),
                                            padding: const EdgeInsets.all(
                                                Dimensions
                                                    .paddingSizeExtraSmall),
                                          ),
                                          items: vehicleList,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            child: Text(
                                                '${(deliverymanRegistrationController.vehicles != null && deliverymanRegistrationController.vehicles!.isNotEmpty) ? deliverymanRegistrationController.vehicles![0].type : ''}'),
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator()),
                              ]),
                        ),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('identity_type'.tr,
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall)),
                                const SizedBox(
                                    height: Dimensions.paddingSizeDefault),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault),
                                      color: Theme.of(context).cardColor,
                                      border: Border.all(
                                          color: Theme.of(context).primaryColor,
                                          width: 0.3)),
                                  child: CustomDropdown<int>(
                                    onChange: (int? value, int index) {
                                      deliverymanRegistrationController
                                          .setIdentityTypeIndex(
                                              deliverymanRegistrationController
                                                  .identityTypeList[index],
                                              true);
                                    },
                                    dropdownButtonStyle: DropdownButtonStyle(
                                      height: 45,
                                      padding: const EdgeInsets.symmetric(
                                        vertical:
                                            Dimensions.paddingSizeExtraSmall,
                                        horizontal:
                                            Dimensions.paddingSizeExtraSmall,
                                      ),
                                      primaryColor: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .color,
                                    ),
                                    dropdownStyle: DropdownStyle(
                                      elevation: 10,
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault),
                                      padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeExtraSmall),
                                    ),
                                    items: identityTypeList,
                                    child: Text(
                                        deliverymanRegistrationController
                                            .identityTypeList[0].tr),
                                  ),
                                ),
                              ]),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: CustomTextField(
                            titleText: deliverymanRegistrationController
                                        .identityTypeIndex ==
                                    0
                                ? 'identity_number'.tr
                                : deliverymanRegistrationController
                                            .identityTypeIndex ==
                                        1
                                    ? 'driving_license_number'.tr
                                    : 'nid_number'.tr,
                            showLabelText: false,
                            controller: _identityNumberController,
                            focusNode: _identityNumberNode,
                            inputAction: TextInputAction.done,
                            showTitle: true,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: deliverymanRegistrationController
                                  .pickedIdentities.length +
                              1,
                          itemBuilder: (context, index) {
                            final XFile? file = index ==
                                    deliverymanRegistrationController
                                        .pickedIdentities.length
                                ? null
                                : deliverymanRegistrationController
                                    .pickedIdentities[index];
                            if (index ==
                                deliverymanRegistrationController
                                    .pickedIdentities.length) {
                              return InkWell(
                                onTap: () => deliverymanRegistrationController
                                    .pickDmImage(false, false),
                                child: DottedBorder(
                                  color: Theme.of(context).primaryColor,
                                  dashPattern: const [5, 5],
                                  padding: const EdgeInsets.all(5),
                                  borderType: BorderType.RRect,
                                  radius: const Radius.circular(
                                      Dimensions.radiusDefault),
                                  child: Container(
                                    height: 120,
                                    width: 150,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeDefault),
                                    child: Column(
                                      children: [
                                        Icon(Icons.camera_alt,
                                            color: Theme.of(context)
                                                .disabledColor),
                                        Text('upload_identity_image'.tr,
                                            style: robotoMedium.copyWith(
                                                color: Theme.of(context)
                                                    .disabledColor),
                                            textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              margin: const EdgeInsets.only(
                                  right: Dimensions.paddingSizeSmall),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2),
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall),
                              ),
                              child: Stack(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSmall),
                                  child: GetPlatform.isWeb
                                      ? Image.network(
                                          file!.path,
                                          width: 150,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          cacheWidth: 300,
                                          cacheHeight: 300,
                                        )
                                      : Image.file(
                                          File(file!.path),
                                          width: 150,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () =>
                                        deliverymanRegistrationController
                                            .removeIdentityImage(index),
                                    child: const Padding(
                                      padding: EdgeInsets.all(
                                          Dimensions.paddingSizeSmall),
                                      child: Icon(Icons.delete_forever,
                                          color: Colors.red),
                                    ),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Container(
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusSmall),
                              border: Border.all(
                                  color: Theme.of(context).hintColor)),
                          width: 165,
                          child: CustomButton(
                            transparent: true,
                            textColor: Theme.of(context).hintColor,
                            radius: Dimensions.radiusSmall,
                            onPressed: () {
                              debugPrint('[DM-REG-SCREEN] RESET button pressed');
                              _phoneController.text = '';
                              _emailController.text = '';
                              _fNameController.text = '';
                              _lNameController.text = '';
                              _lNameController.text = '';
                              _passwordController.text = '';
                              _confirmPasswordController.text = '';
                              _identityNumberController.text = '';
                              deliverymanRegistrationController
                                  .resetDeliveryRegistration();
                            },
                            buttonText: 'reset'.tr,
                            isBold: false,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeLarge),
                        SizedBox(width: 165, child: buttonView()),
                      ])
                    ]),
                  ),
                ]),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buttonView() {
    return GetBuilder<DeliverymanRegistrationController>(
        builder: (deliverymanRegistrationController) {
      return CustomButton(
        isBold: ResponsiveHelper.isDesktop(context) ? false : true,
        radius: ResponsiveHelper.isDesktop(context)
            ? Dimensions.radiusSmall
            : Dimensions.radiusDefault,
        isLoading: deliverymanRegistrationController.isLoading,
        buttonText: deliverymanRegistrationController.dmStatus == 0.4
            ? 'next'.tr
            : 'submit'.tr,
        margin: EdgeInsets.all(
            (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isWeb())
                ? 0
                : Dimensions.paddingSizeSmall),
        height: 50,
        onPressed: !deliverymanRegistrationController.acceptTerms
            ? null
            : () async {
                debugPrint('[DM-REG-SCREEN] BUTTON PRESSED => ${deliverymanRegistrationController.dmStatus == 0.4 ? "NEXT" : "SUBMIT"}');
                debugPrint('[DM-REG-SCREEN]  dmStatus=${deliverymanRegistrationController.dmStatus}');
                debugPrint('[DM-REG-SCREEN]  isLoading=${deliverymanRegistrationController.isLoading}');
                debugPrint('[DM-REG-SCREEN]  acceptTerms=${deliverymanRegistrationController.acceptTerms}');
                deliverymanRegistrationController.printState('buttonView.onPressed');
                if (deliverymanRegistrationController.dmStatus == 0.4 &&
                    !ResponsiveHelper.isDesktop(context)) {
                  final String fName = _fNameController.text.trim();
                  final String lName = _lNameController.text.trim();
                  final String email = _emailController.text.trim();
                  final String password = _passwordController.text.trim();
                  final String confirmPassword =
                      _confirmPasswordController.text.trim();

                  final String numberWithCountryCode =
                      _resolvePhoneWithCountryCode();

                  final PhoneValid phoneValid =
                      await CustomValidator.isPhoneValid(numberWithCountryCode);

                  debugPrint('[DM-REG-SCREEN] NEXT => Step 1 validation start');
                  debugPrint('[DM-REG-SCREEN]  fName="$fName", lName="$lName", email="$email"');
                  debugPrint('[DM-REG-SCREEN]  phone=$numberWithCountryCode, phoneValid=${phoneValid.isValid}');
                  debugPrint('[DM-REG-SCREEN]  pickedImage=${deliverymanRegistrationController.pickedImage != null}');
                  if (_formKeyStep1!.currentState!.validate()) {
                    if (fName.isEmpty) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: fName empty');
                      showCustomSnackBar('enter_delivery_man_first_name'.tr);
                    } else if (lName.isEmpty) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: lName empty');
                      showCustomSnackBar('enter_delivery_man_last_name'.tr);
                    } else if (deliverymanRegistrationController.pickedImage ==
                        null) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: profile image null');
                      showCustomSnackBar('pick_delivery_man_profile_image'.tr);
                    } else if (email.isEmpty) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: email empty');
                      showCustomSnackBar('enter_delivery_man_email_address'.tr);
                    } else if (!GetUtils.isEmail(email)) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: email invalid => $email');
                      showCustomSnackBar('enter_a_valid_email_address'.tr);
                      // } else if (phone.isEmpty) {
                      //   showCustomSnackBar('enter_delivery_man_phone_number'.tr);
                    } else if (!phoneValid.isValid) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: phone invalid => $numberWithCountryCode');
                      showCustomSnackBar('enter_a_valid_phone_number'.tr);
                    } else if (password.isEmpty) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: password empty');
                      showCustomSnackBar('enter_password_for_delivery_man'.tr);
                    } else if (password != confirmPassword) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: password mismatch');
                      showCustomSnackBar(
                          'confirm_password_does_not_matched'.tr);
                    } else if (!deliverymanRegistrationController
                            .spatialCheck ||
                        !deliverymanRegistrationController.lowercaseCheck ||
                        !deliverymanRegistrationController.uppercaseCheck ||
                        !deliverymanRegistrationController.numberCheck ||
                        !deliverymanRegistrationController.lengthCheck) {
                      debugPrint('[DM-REG-SCREEN] STEP1 FAIL: password validation (spatial=${deliverymanRegistrationController.spatialCheck}, lower=${deliverymanRegistrationController.lowercaseCheck}, upper=${deliverymanRegistrationController.uppercaseCheck}, number=${deliverymanRegistrationController.numberCheck}, length=${deliverymanRegistrationController.lengthCheck})');
                      // Show password validation dialog instead of snackbar
                      showPasswordValidationDialog(forStoreRegistration: false);
                    } else {
                      final bool canProceed = await _canProceedWithRegistration(
                        controller: deliverymanRegistrationController,
                        phone: numberWithCountryCode,
                        email: email,
                        identityNumber: '',
                      );
                      if (!canProceed) {
                        debugPrint('[DM-REG-SCREEN] STEP1 BLOCKED: delivery man already registered');
                        return;
                      }
                      debugPrint('[DM-REG-SCREEN] STEP1 PASSED => moving to step 2');
                      deliverymanRegistrationController.dmStatusChange(0.8);
                    }
                  }
                } else {
                  _addDeliveryMan(deliverymanRegistrationController);
                }
              },
      );
    });
  }

  void _addDeliveryMan(
      DeliverymanRegistrationController deliverymanRegiController) async {
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan() START');
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final String fName = _fNameController.text.trim();
    final String lName = _lNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String identityNumber = _identityNumberController.text.trim();
    String numberWithCountryCode = _resolvePhoneWithCountryCode();
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => phone=$numberWithCountryCode');

    final PhoneValid phoneValid =
        await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => phoneValid=${phoneValid.isValid}, resolved=$numberWithCountryCode');
    if (!mounted) {
      debugPrint('[DM-REG-SCREEN] _addDeliveryMan => NOT MOUNTED, aborting');
      return;
    }

    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => vehicleIndex=${deliverymanRegiController.vehicleIndex}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => selectedZoneIndex=${deliverymanRegiController.selectedZoneIndex}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => dmTypeIndex=${deliverymanRegiController.dmTypeIndex}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => identityTypeIndex=${deliverymanRegiController.identityTypeIndex}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => vehicles=${deliverymanRegiController.vehicles?.length ?? 'null'}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => vehicleIds=${deliverymanRegiController.vehicleIds}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => zoneList=${deliverymanRegiController.zoneList?.length ?? 'null'}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => identityImages=${deliverymanRegiController.identityImages.length}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => driverLicenseImages=${deliverymanRegiController.driverLicenseImages.length}');
    debugPrint('[DM-REG-SCREEN] _addDeliveryMan => vehicleLicenseImages=${deliverymanRegiController.vehicleLicenseImages.length}');

    debugPrint('\x1B[32m  /${deliverymanRegiController.vehicleIndex}  \x1B[0m');

    if (!isDesktop) {
      debugPrint('[DM-REG-SCREEN] _addDeliveryMan => MOBILE validation start');
      if (_formKeyStep2!.currentState!.validate()) {
        if (numberWithCountryCode.isEmpty) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: phone is empty');
          showCustomSnackBar('enter_phone_number'.tr);
        } else if (!phoneValid.isValid) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: phone invalid => $numberWithCountryCode');
          showCustomSnackBar('enter_a_valid_phone_number'.tr);
        } else if (identityNumber.isEmpty) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: identityNumber empty');
          showCustomSnackBar('enter_delivery_man_identity_number'.tr);
        } else if (deliverymanRegiController.pickedImage == null) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: profile image null');
          showCustomSnackBar('upload_delivery_man_image'.tr);
        } else if (deliverymanRegiController.selectedZoneIndex == null ||
            deliverymanRegiController.selectedZoneIndex! < 0 ||
            deliverymanRegiController.zoneList == null ||
            deliverymanRegiController.zoneList!.isEmpty ||
            deliverymanRegiController.selectedZoneIndex! >= deliverymanRegiController.zoneList!.length) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: zone not selected => selectedZoneIndex=${deliverymanRegiController.selectedZoneIndex}, zoneList=${deliverymanRegiController.zoneList?.length ?? 'null'}');
          showCustomSnackBar('please_select_zone'.tr);
        } else if (deliverymanRegiController.vehicleIndex == null ||
            deliverymanRegiController.vehicleIndex! < 0 ||
            deliverymanRegiController.vehicles == null ||
            deliverymanRegiController.vehicles!.isEmpty ||
            deliverymanRegiController.vehicleIndex! >= deliverymanRegiController.vehicles!.length) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: vehicle not selected => vehicleIndex=${deliverymanRegiController.vehicleIndex}, vehicles=${deliverymanRegiController.vehicles?.length ?? 'null'}, vehicleIds=${deliverymanRegiController.vehicleIds}');
          showCustomSnackBar('please_select_vehicle_for_the_deliveryman'.tr);
        } else if (deliverymanRegiController.identityImages.isEmpty) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: identity images empty');
          showCustomSnackBar('please_upload_identity_image'.tr);
        } else if (deliverymanRegiController.dmTypeIndex == 0) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: dmTypeIndex=0 (not selected)');
          showCustomSnackBar('please_select_deliveryman_type'.tr);
        } else if (deliverymanRegiController.vehicleLicenseImages.isEmpty &&
            deliverymanRegiController.vehicleIndex != 0) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: vehicle license images empty (vehicleIndex=${deliverymanRegiController.vehicleIndex})');
          showCustomSnackBar('يرجي تحميل صوره الرخصه القيادة');
        } else if (deliverymanRegiController.driverLicenseImages.isEmpty &&
            deliverymanRegiController.vehicleIndex != 0) {
          debugPrint('[DM-REG-SCREEN] VALIDATION FAIL: driver license images empty (vehicleIndex=${deliverymanRegiController.vehicleIndex})');
          showCustomSnackBar('يرجي تحميل صوره الرخصه السائق');
        } else {
          debugPrint('[DM-REG-SCREEN] VALIDATION PASSED => calling registerDeliveryMan()');

          debugPrint(
              "\x1B[32m  /${deliverymanRegiController.dmTypeIndex == 1 ? '1' : '0'}  \x1B[0m");

          debugPrint(
              '\x1B[32m  /${deliverymanRegiController.zoneList![deliverymanRegiController.selectedZoneIndex!].id.toString()}  \x1B[0m');

          debugPrint(
              '\x1B[32m  /${deliverymanRegiController.vehicles![deliverymanRegiController.vehicleIndex!].id.toString()}  \x1B[0m');

          //
          final bool canProceed = await _canProceedWithRegistration(
            controller: deliverymanRegiController,
            phone: numberWithCountryCode,
            email: email,
            identityNumber: identityNumber,
          );
          if (!canProceed) {
            debugPrint('[DM-REG-SCREEN] register blocked: delivery man already registered');
            return;
          }

          deliverymanRegiController.registerDeliveryMan(
            deliverymanRegiController.driverLicenseImages,
            deliverymanRegiController.vehicleLicenseImages,
            deliverymanRegiController.identityImages,
            DeliveryManBody(
              fName: fName,
              lName: lName,
              password: password,
              driverLicenseImage: '',
              drivingLicenseImage: '',
              phone: numberWithCountryCode,
              email: email,
              identityNumber: identityNumber,
              identityType: deliverymanRegiController.identityTypeList[
                  deliverymanRegiController.identityTypeIndex],
              earning: deliverymanRegiController.dmTypeIndex == 1 ? '1' : '0',
              zoneId: deliverymanRegiController
                  .zoneList![deliverymanRegiController.selectedZoneIndex!].id
                  .toString(),
              vehicleId: deliverymanRegiController
                  .vehicles![deliverymanRegiController.vehicleIndex!].id
                  .toString(),
            ),
          );

          //
        }
      }
    }

    if (isDesktop) {
      if (fName.isEmpty) {
        showCustomSnackBar('enter_delivery_man_first_name'.tr);
        return;
      } else if (lName.isEmpty) {
        showCustomSnackBar('enter_delivery_man_last_name'.tr);
        return;
      } else if (deliverymanRegiController.pickedImage == null) {
        showCustomSnackBar('pick_delivery_man_profile_image'.tr);
        return;
      } else if (email.isEmpty) {
        showCustomSnackBar('enter_delivery_man_email_address'.tr);
        return;
      } else if (!GetUtils.isEmail(email)) {
        showCustomSnackBar('enter_a_valid_email_address'.tr);
        return;
        // } else if (phone.isEmpty) {
        //   showCustomSnackBar('enter_delivery_man_phone_number'.tr);
        // return;
      } else if (!phoneValid.isValid) {
        showCustomSnackBar('enter_a_valid_phone_number'.tr);
        return;
      } else if (password.isEmpty) {
        showCustomSnackBar('enter_password_for_delivery_man'.tr);
        return;
      } else if (!deliverymanRegiController.spatialCheck ||
          !deliverymanRegiController.lowercaseCheck ||
          !deliverymanRegiController.uppercaseCheck ||
          !deliverymanRegiController.numberCheck ||
          !deliverymanRegiController.lengthCheck) {
        // Show password validation dialog instead of snackbar
        showPasswordValidationDialog(forStoreRegistration: false);
        return;
      } else if (identityNumber.isEmpty) {
        showCustomSnackBar('enter_delivery_man_identity_number'.tr);
        return;
      } else if (deliverymanRegiController.pickedImage == null) {
        showCustomSnackBar('upload_delivery_man_image'.tr);
        return;
      } else if (deliverymanRegiController.selectedZoneIndex == null ||
          deliverymanRegiController.selectedZoneIndex! < 0 ||
          deliverymanRegiController.zoneList == null ||
          deliverymanRegiController.zoneList!.isEmpty ||
          deliverymanRegiController.selectedZoneIndex! >= deliverymanRegiController.zoneList!.length) {
        showCustomSnackBar('please_select_zone'.tr);
        return;
      } else if (deliverymanRegiController.vehicleIndex == null ||
          deliverymanRegiController.vehicleIndex! < 0 ||
          deliverymanRegiController.vehicles == null ||
          deliverymanRegiController.vehicles!.isEmpty ||
          deliverymanRegiController.vehicleIndex! >= deliverymanRegiController.vehicles!.length) {
        showCustomSnackBar('please_select_vehicle_for_the_deliveryman'.tr);
        return;
      } else if (deliverymanRegiController.pickedIdentities.isEmpty) {
        showCustomSnackBar('please_upload_identity_image'.tr);
        return;
      } else if (deliverymanRegiController.dmTypeIndex == 0) {
        showCustomSnackBar('please_select_deliveryman_type'.tr);
        return;
      } else {
        final bool canProceed = await _canProceedWithRegistration(
          controller: deliverymanRegiController,
          phone: numberWithCountryCode,
          email: email,
          identityNumber: identityNumber,
        );
        if (!canProceed) {
          return;
        }

        deliverymanRegiController.registerDeliveryMan(
            deliverymanRegiController.driverLicenseImages,
            deliverymanRegiController.vehicleLicenseImages,
            deliverymanRegiController.identityImages,
            DeliveryManBody(
              fName: fName,
              lName: lName,
              password: password,
              phone: numberWithCountryCode,
              email: email,
              identityNumber: identityNumber,
              identityType: deliverymanRegiController.identityTypeList[
                  deliverymanRegiController.identityTypeIndex],
              earning: deliverymanRegiController.dmTypeIndex == 1 ? '1' : '0',
              zoneId: deliverymanRegiController
                  .zoneList![deliverymanRegiController.selectedZoneIndex!].id
                  .toString(),
              vehicleId: deliverymanRegiController
                  .vehicles![deliverymanRegiController.vehicleIndex!].id
                  .toString(),
            ));
      }
    }
  }
}
