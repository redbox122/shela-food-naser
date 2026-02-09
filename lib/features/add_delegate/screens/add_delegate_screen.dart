// ignore_for_file: camel_case_types, unused_local_variable, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/appBar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/features/add_delegate/controllers/delegate_controller.dart';
import 'package:sixam_mart/features/add_delegate/widget/file_upload_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class Add_DelegateScreen extends StatefulWidget {
  final String? fundStatus;
  final String? token;
  const Add_DelegateScreen({super.key, this.fundStatus, this.token});

  @override
  State<Add_DelegateScreen> createState() => _Add_DelegateScreenState();
}

class _Add_DelegateScreenState extends State<Add_DelegateScreen> {
  @override
  void initState() {
    super.initState();
    final profileController = Get.find<ProfileController>();
    if (profileController.userInfoModel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileController.getUserInfo();
      });
    }
  }

  String? _profilePhoneOrNull(ProfileController profileController) {
    final String? phone = profileController.userInfoModel?.phone?.trim();
    if (phone == null || phone.isEmpty || phone.toLowerCase() == 'null') {
      return null;
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    final profileController = Get.find<ProfileController>();
    final String? profilePhone = _profilePhoneOrNull(profileController);

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: custom_AppBar(
        context,
        title: 'المندوب',
        icon: Icons.arrow_back_sharp,
        img_icon: Images.shippingPolicy,
        onPressed: () {
          Get.back();
        },
      ),
      body: GetBuilder<Delegate_Controller>(builder: (delegateController) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: delegateController.isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      SizedBox(height: 30),
                      Text('معلومات المندوب',
                          textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      SizedBox(height: 30),
                      _customText(mycontroller: delegateController.f_name_Controller, text: 'الاسم الأول', context: context),
                      _customText(mycontroller: delegateController.l_name_Controller, text: 'اسم الأب', context: context),
                      SizedBox(height: 25),
                      profilePhone != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'رقم الهاتف',
                                  textAlign: TextAlign.center,
                                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                                ),
                                SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Text(
                                    profilePhone,
                                    textAlign: TextAlign.center,
                                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                                  ),
                                ),
                              ],
                            )
                          : _customText(
                              mycontroller: delegateController.mobile_Controller,
                              text: 'رقم الهاتف',
                              hintText: '05xxxxxxxx',
                              context: context,
                              isNumber: true,
                            ),
                      SizedBox(height: 30),
                      Align(
                        alignment: Alignment.topRight,
                        child: Custom_Text(
                          context,
                          text: 'المستندات',
                          style: font11Black500W(context, size: size_14(context)),
                        ),
                      ),
                      SizedBox(height: 10),

                      Align(
                        child: Text(
                          'أرفق صورًا واضحة لمستنداتك مثل الهوية أو عقد الإيجار، وسمِّ كل ملف قبل رفعه.',
                          textAlign: TextAlign.right,
                          style: robotoRegular.copyWith(
                            color: AppColors.darkGreyColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      //

                      Delegate_FileUploadWidget(),

                      //
                      SizedBox(height: 50),

                      //

                      Container(
                        width: 1170,
                        padding: EdgeInsets.all(Dimensions.fontSizeDefault),
                        child: CustomButton(
                          buttonText: 'إرسال',
                          onPressed: () async {
                            final int? userId = profileController.userInfoModel?.id;
                            final String phone = profilePhone ?? delegateController.mobile_Controller.text.trim();
                            if (userId == null) {
                              Get.showSnackbar(GetSnackBar(
                                message: 'تعذر جلب بيانات المستخدم، حاول مرة أخرى',
                                duration: const Duration(seconds: 2),
                              ));
                              return;
                            }
                            if (phone.isEmpty) {
                              Get.showSnackbar(GetSnackBar(
                                message: 'رجاء إدخال رقم الهاتف',
                                duration: const Duration(seconds: 2),
                              ));
                              return;
                            }
                            await delegateController.sent_Delegate(
                              context,
                              userId,
                              phone,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }),
    );
  }

  Widget _customText({
    String? hintText,
    final bool isNumber = false,
    final bool? obscureText,
    final TextEditingController? mycontroller,
    required String text,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Custom_Text(context, text: text, style: font11Black500W(context, size: size_14(context))),
        SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: TextFormField(
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            cursorColor: AppColors.bgColor,
            controller: mycontroller,
            obscureText: obscureText == null || obscureText == false ? false : true,
            decoration: InputDecoration(
                hintText: hintText,
                hintStyle: font10Grey500W(context, size: size_14(context)),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.gryColor_3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.greenColor),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
      ],
    );
  }
}
