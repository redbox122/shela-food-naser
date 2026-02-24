// ignore_for_file: non_constant_identifier_names, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final kaidhaController = Get.find<KaidhaSubscription_Controller>();
      final profileController = Get.find<ProfileController>();

      if (profileController.userInfoModel == null) {
        await profileController.getUserInfo();
      }
      final userInfo = profileController.userInfoModel;

      if (userInfo != null) {
        if (kaidhaController.firstname.text.trim().isEmpty &&
            (userInfo.fName?.isNotEmpty ?? false)) {
          kaidhaController.firstname.text = userInfo.fName!;
        }
        if (kaidhaController.last_name.text.trim().isEmpty &&
            (userInfo.lName?.isNotEmpty ?? false)) {
          kaidhaController.last_name.text = userInfo.lName!;
        }
      }

      final profilePhone = userInfo?.phone?.toString().trim();
      final authPhone = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>().getUserNumber().trim()
          : '';
      final phone =
          (profilePhone != null && profilePhone.isNotEmpty) ? profilePhone : authPhone;
      if (kaidhaController.phoneController.text.trim().isEmpty &&
          phone.isNotEmpty) {
        kaidhaController.phoneController.text =
            phone.replaceAll(RegExp(r'\\D'), '');
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    // الدول العربية

    final List<Map<String, dynamic>> nationalities = [
      {'name': 'select_nationality'.tr, 'code': '', 'flag': ''},

      {
        'name': Get.locale?.languageCode == 'ar' ? 'جزائري' : 'Algerian',
        'code': 'DZ',
        'flag': '🇩🇿'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'بحريني' : 'Bahraini',
        'code': 'BH',
        'flag': '🇧🇭'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'جزر القمر' : 'Comorian',
        'code': 'KM',
        'flag': '🇰🇲'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'جيبوتي' : 'Djiboutian',
        'code': 'DJ',
        'flag': '🇩🇯'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'مصري' : 'Egyptian',
        'code': 'EG',
        'flag': '🇪🇬'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'عراقي' : 'Iraqi',
        'code': 'IQ',
        'flag': '🇮🇶'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'أردني' : 'Jordanian',
        'code': 'JO',
        'flag': '🇯🇴'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'كويتي' : 'Kuwaiti',
        'code': 'KW',
        'flag': '🇰🇼'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'لبناني' : 'Lebanese',
        'code': 'LB',
        'flag': '🇱🇧'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'ليبي' : 'Libyan',
        'code': 'LY',
        'flag': '🇱🇾'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'موريتاني' : 'Mauritanian',
        'code': 'MR',
        'flag': '🇲🇷'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'مغربي' : 'Moroccan',
        'code': 'MA',
        'flag': '🇲🇦'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'عماني' : 'Omani',
        'code': 'OM',
        'flag': '🇴🇲'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'فلسطيني' : 'Palestinian',
        'code': 'PS',
        'flag': '🇵🇸'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'قطري' : 'Qatari',
        'code': 'QA',
        'flag': '🇶🇦'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'سعودي' : 'Saudi',
        'code': 'SA',
        'flag': '🇸🇦'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'صومالي' : 'Somali',
        'code': 'SO',
        'flag': '🇸🇴'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'سوداني' : 'Sudanese',
        'code': 'SD',
        'flag': '🇸🇩'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'سوري' : 'Syrian',
        'code': 'SY',
        'flag': '🇸🇾'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'تونسي' : 'Tunisian',
        'code': 'TN',
        'flag': '🇹🇳'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'إماراتي' : 'Emirati',
        'code': 'AE',
        'flag': '🇦🇪'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'يمني' : 'Yemeni',
        'code': 'YE',
        'flag': '🇾🇪'
      },

      // دول رئيسية أخرى
      {
        'name': Get.locale?.languageCode == 'ar' ? 'أمريكي' : 'American',
        'code': 'US',
        'flag': '🇺🇸'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'أسترالي' : 'Australian',
        'code': 'AU',
        'flag': '🇦🇺'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'برازيلي' : 'Brazilian',
        'code': 'BR',
        'flag': '🇧🇷'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'بريطاني' : 'British',
        'code': 'GB',
        'flag': '🇬🇧'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'كندي' : 'Canadian',
        'code': 'CA',
        'flag': '🇨🇦'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'صيني' : 'Chinese',
        'code': 'CN',
        'flag': '🇨🇳'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'فرنسي' : 'French',
        'code': 'FR',
        'flag': '🇫🇷'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'ألماني' : 'German',
        'code': 'DE',
        'flag': '🇩🇪'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'هندي' : 'Indian',
        'code': 'IN',
        'flag': '🇮🇳'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'إيطالي' : 'Italian',
        'code': 'IT',
        'flag': '🇮🇹'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'ياباني' : 'Japanese',
        'code': 'JP',
        'flag': '🇯🇵'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'روسي' : 'Russian',
        'code': 'RU',
        'flag': '🇷🇺'
      },
      {
        'name':
            Get.locale?.languageCode == 'ar' ? 'جنوب أفريقي' : 'South African',
        'code': 'ZA',
        'flag': '🇿🇦'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'إسباني' : 'Spanish',
        'code': 'ES',
        'flag': '🇪🇸'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'تركي' : 'Turkish',
        'code': 'TR',
        'flag': '🇹🇷'
      },
    ];

    return GetBuilder<KaidhaSubscription_Controller>(
        builder: (KaidhaSub_Controller) {
      return Form(
        key: KaidhaSub_Controller.formstate,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'personal_information'.tr,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),

            _customTextFormAuth(
              KaidhaSub_Controller,
              context: context,
              text: 'first_name'.tr,
              mycontroller: KaidhaSub_Controller.firstname,
              focusNode: KaidhaSub_Controller.firstNameFocus,
              isEmpty: KaidhaSub_Controller.isFirstNameEmpty,
            ),

            _customTextFormAuth(
              KaidhaSub_Controller,
              mycontroller: KaidhaSub_Controller.fathername,
              text: 'father_name'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.fatherNameFocus,
              isEmpty: KaidhaSub_Controller.isFatherNameEmpty,
            ),

            _customTextFormAuth(
              KaidhaSub_Controller,
              mycontroller: KaidhaSub_Controller.grandfathername,
              text: 'grandfather_name'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.grandFatherNameFocus,
              isEmpty: KaidhaSub_Controller.isGrandFatherNameEmpty,
            ),

            _customTextFormAuth(
              KaidhaSub_Controller,
              mycontroller: KaidhaSub_Controller.last_name,
              text: 'last_name'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.lastNameFocus,
              isEmpty: KaidhaSub_Controller.isLastNameEmpty,
            ),

            _buildDate_old_10(context, KaidhaSub_Controller),

            const SizedBox(height: 10),
            Text(
              'select_nationality'.tr,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
            const SizedBox(height: 10),

            //  'اختر الجنسية'

            Focus(
              focusNode: KaidhaSub_Controller.nationalityFocus,
              child: Container(
                key: KaidhaSubscription_Controller.nationalityKey,
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: (nationalities.firstWhere(
                    (c) => c['name'] == KaidhaSub_Controller.nationality,
                    orElse: () => {'code': null},
                  )['code'] as String?),
                  onChanged: (String? newCode) {
                    if (newCode != null && newCode.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final selectedCountry = nationalities.firstWhere(
                          (country) => country['code'] == newCode,
                          orElse: () => {'name': '', 'code': '', 'flag': ''},
                        );

                        KaidhaSub_Controller.updateNationality(
                          (selectedCountry['name'] as String?) ?? '',
                        );
                      });
                    }
                  },
                  items: nationalities.map((country) {
                    final code = country['code'] ?? '';
                    final name = country['name'] ?? '';
                    final flag = country['flag'] ?? '';

                    final String codeStr = code.toString();
                    final String flagStr = flag.toString();
                    return DropdownMenuItem<String>(
                      value: codeStr,
                      child: Row(
                        children: [
                          if (codeStr.isNotEmpty && flagStr.isNotEmpty)
                            Text(flagStr, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text((name as String?) ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    hintText: 'select_nationality'.tr,
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: KaidhaSub_Controller.isNationalityEmpty
                            ? Colors.red
                            : AppColors.gryColor_3,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: KaidhaSub_Controller.isNationalityEmpty
                            ? Colors.red
                            : AppColors.greenColor,
                      ),
                    ),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildMaritalStatusRadio(context),

            // عدد أفراد الأسرة
            _custom_number(
              KaidhaSub_Controller,
              mycontroller: KaidhaSub_Controller.number_of_family_members,
              disallowZero: true,
              text: 'number_of_family_members'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.numberOfFamilyFocus,
              containerKey: KaidhaSubscription_Controller.numberOfFamilyKey,
              isEmpty: KaidhaSub_Controller.isNumberOfFamilyEmpty,
            ),

            // رقم بطاقة الأحوال
            _custom_number(
              KaidhaSub_Controller,
              hintText: 'XXXXXX-XXXXX-X',
              obscureText: false,
              mycontroller: KaidhaSub_Controller.identity_card_number,
              text: 'identity_card_number'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.identityCardFocus,
              containerKey: KaidhaSubscription_Controller.identityCardKey,
              isEmpty: KaidhaSub_Controller.isIdentityCardEmpty,
              errorKey: 'identity_card_number',
              errorText:
                  KaidhaSub_Controller.fieldErrors['identity_card_number'],
            ),

            _buildExpirationDateField(context, text: 'identity_card_expiry'.tr),

            const SizedBox(height: 25),

            _custom_number(
              KaidhaSub_Controller,
              hintText: '05XXXXXXXX',
              obscureText: false,
              mycontroller: KaidhaSub_Controller.phoneController,
              text: 'phone_number'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.phoneFocus,
              containerKey: KaidhaSubscription_Controller.phoneKey,
              isEmpty: KaidhaSub_Controller.isPhoneEmpty,
              errorKey: 'mobile',
              errorText: KaidhaSub_Controller.fieldErrors['mobile'],
            ),

            const SizedBox(height: 20),

            _buildHouseType(context),

            const SizedBox(height: 10),

            _buildCitySelection(context),

            const SizedBox(height: 10),

            _customTextFormAuth(
              KaidhaSub_Controller,
              mycontroller: KaidhaSub_Controller.neighborhood,
              text: 'neighborhood'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.neighborhoodFocus,
              isEmpty: KaidhaSub_Controller.isNeighborhoodEmpty,
            ),

            // AddressDetailsWidget(addressDetails: address),

            // ===============

            const SizedBox(height: 20),

            _customTextFormAuth(
              KaidhaSub_Controller,
              mycontroller: KaidhaSub_Controller.name_of_employer,
              text: 'employer_name'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.employerFocus,
              isEmpty: KaidhaSub_Controller.isEmployerEmpty,
            ),

            _custom_number(
              KaidhaSub_Controller,
              mycontroller: KaidhaSub_Controller.total_salary,
              text: 'total_salary'.tr,
              context: context,
              focusNode: KaidhaSub_Controller.totalSalaryFocus,
              containerKey: KaidhaSubscription_Controller.totalSalaryKey,
              isEmpty: KaidhaSub_Controller.isTotalSalaryEmpty,
            ),

            _buildInstallments(context),
          ],
        ),
      );
    });
  }

  Widget _buildInstallments(BuildContext context) {
    final KaidhaSub_Controller = Get.find<KaidhaSubscription_Controller>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'installments'.tr,
          textAlign: TextAlign.center,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
        ),
        Row(
          children: [
            _buildRadioOption(
              context: context,
              label: 'yes'.tr,
              value: 'yes',
              groupValue: KaidhaSub_Controller.Installments,
              onChanged: (value) {
                KaidhaSub_Controller.updateInstallments(value!);
                KaidhaSub_Controller.debouncedSaveState();
              },
            ),
            _buildRadioOption(
              context: context,
              label: 'no'.tr,
              value: 'no',
              groupValue: KaidhaSub_Controller.Installments,
              onChanged: (value) {
                KaidhaSub_Controller.updateInstallments(value!);
                KaidhaSub_Controller.debouncedSaveState();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaritalStatusRadio(BuildContext context) {
    final KaidhaSub_Controller = Get.find<KaidhaSubscription_Controller>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Custom_Text(
          context,
          text: 'marital_status'.tr,
          style: font11Black600W(context, size: size_14(context)),
        ),
        Row(
          children: [
            _buildRadioOption(
              context: context,
              label: 'single'.tr,
              value: 'single',
              groupValue: KaidhaSub_Controller.marital_status,
              onChanged: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  KaidhaSub_Controller.updateMaritalStatus(value!);
                });
              },
            ),
            _buildRadioOption(
              context: context,
              label: 'married'.tr,
              value: 'married',
              groupValue: KaidhaSub_Controller.marital_status,
              onChanged: (value) {
                KaidhaSub_Controller.updateMaritalStatus(value!);
              },
            ),
            _buildRadioOption(
              context: context,
              label: 'divorced'.tr,
              value: 'divorced',
              groupValue: KaidhaSub_Controller.marital_status,
              onChanged: (value) {
                KaidhaSub_Controller.updateMaritalStatus(value!);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHouseType(BuildContext context) {
    return GetBuilder<KaidhaSubscription_Controller>(
      builder: (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Custom_Text(context,
              text: 'house_type'.tr,
              style: font11Black600W(context, size: size_14(context))),
          ...[
            {'label': 'house'.tr, 'value': 'منزل'},
            {'label': 'apartment'.tr, 'value': 'شقة'},
            {'label': 'villa'.tr, 'value': 'فيلا'}
          ].map((type) => _buildRadioOption(
                context: context,
                label: type['label']!,
                value: type['value']!,
                groupValue: c.house_type,
                onChanged: (v) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    c.updateHousetype(v!);
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _buildCitySelection(BuildContext context) {
    // Saudi cities list - display names change based on language, but values stay consistent
    final List<Map<String, String>> cities = [
      {'name': 'select_city'.tr, 'value': ''},
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الرياض' : 'Riyadh',
        'value': 'الرياض'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'جدة' : 'Jeddah',
        'value': 'جدة'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'مكة' : 'Makkah',
        'value': 'مكة'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'المدينة' : 'Madinah',
        'value': 'المدينة'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الدمام' : 'Dammam',
        'value': 'الدمام'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الطائف' : 'Taif',
        'value': 'الطائف'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'تبوك' : 'Tabuk',
        'value': 'تبوك'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'بريدة' : 'Buraydah',
        'value': 'بريدة'
      },
      {
        'name':
            Get.locale?.languageCode == 'ar' ? 'خميس مشيط' : 'Khamis Mushait',
        'value': 'خميس مشيط'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الهفوف' : 'Al-Hufuf',
        'value': 'الهفوف'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'المبرز' : 'Al-Mubarraz',
        'value': 'المبرز'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'حائل' : 'Hail',
        'value': 'حائل'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'نجران' : 'Najran',
        'value': 'نجران'
      },
      {
        'name':
            Get.locale?.languageCode == 'ar' ? 'حفر الباطن' : 'Hafar Al-Batin',
        'value': 'حفر الباطن'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الجبيل' : 'Jubayl',
        'value': 'الجبيل'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'أبها' : 'Abha',
        'value': 'أبها'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الخرج' : 'Al Khardj',
        'value': 'الخرج'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الثقبة' : 'Tuqba',
        'value': 'الثقبة'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'ينبع البحر' : 'Yanbu',
        'value': 'ينبع البحر'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الخبر' : 'Khobar',
        'value': 'الخبر'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'عرعر' : 'Arar',
        'value': 'عرعر'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الحوية' : 'Al-Hawiyya',
        'value': 'الحوية'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'عنيزة' : 'Unaizah',
        'value': 'عنيزة'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'سكاكة' : 'Sakaka',
        'value': 'سكاكة'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'جيزان' : 'Jizan',
        'value': 'جيزان'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'القرية' : 'Al-Qurayyat',
        'value': 'القرية'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'القطيف' : 'Al-Qatif',
        'value': 'القطيف'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الظهران' : 'Dhahran',
        'value': 'الظهران'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الباحة' : 'Al Bahah',
        'value': 'الباحة'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'تاروت' : 'Tarut',
        'value': 'تاروت'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الرس' : 'Ar-Rass',
        'value': 'الرس'
      },
      {
        'name': Get.locale?.languageCode == 'ar'
            ? 'وادى الدواسر'
            : 'Wadi ad-Dawasir',
        'value': 'وادى الدواسر'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'بيشه' : 'Bishah',
        'value': 'بيشه'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'سيهات' : 'Saihat',
        'value': 'سيهات'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'شروره' : 'Sharurah',
        'value': 'شروره'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'بحره' : 'Bahra',
        'value': 'بحره'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الخفجي' : 'Ras al-Khafji',
        'value': 'الخفجي'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الدوادمى' : 'Dawadimi',
        'value': 'الدوادمى'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'صبياء' : 'Sabya',
        'value': 'صبياء'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'الزلفى' : 'Zulfi',
        'value': 'الزلفى'
      },
      {
        'name': Get.locale?.languageCode == 'ar' ? 'احد رفيده' : 'Ahad Rafida',
        'value': 'احد رفيده'
      },
    ];

    return GetBuilder<KaidhaSubscription_Controller>(
      builder: (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Custom_Text(context,
              text: 'city'.tr,
              style: font11Black600W(context, size: size_14(context))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gryColor_3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: (c.city.isNotEmpty &&
                      cities.any((city) => city['value'] == c.city))
                  ? c.city
                  : null,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                border: InputBorder.none,
                hintText: 'select_city'.tr,
              ),
              items: cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city['value'],
                  child: Text(city['name']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    c.updateCity(newValue);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required BuildContext context,
    required String label,
    required String value,
    required String? groupValue,
    required void Function(String?) onChanged,
  }) {
    return Row(
      children: [
        RadioTheme(
          data: RadioThemeData(
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.greenColor;
              }
              return AppColors.gryColor_3;
            }),
          ),
          // ignore: deprecated_member_use
          child: Radio<String>(
            value: value,
            // ignore: deprecated_member_use
            groupValue: groupValue,
            // ignore: deprecated_member_use
            onChanged: onChanged,
          ),
        ),
        Custom_Text(
          context,
          text: label,
          style: font11Black500W(context, size: size_14(context)),
        )
      ],
    );
  }

  Widget _custom_number(
    KaidhaSubscription_Controller KaidhaSub_Controller, {
    String? hintText,
    final bool? obscureText,
    final TextEditingController? mycontroller,
    bool disallowZero = false,
    String? errorKey,
    String? errorText,
    required String text,
    required BuildContext context,
    required FocusNode focusNode,
    required GlobalKey containerKey,
    required bool isEmpty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Custom_Text(context,
            text: text,
            style: font11Black500W(context, size: size_14(context))),
        const SizedBox(height: 10),
        Focus(
          focusNode: focusNode,
          child: Container(
            key: containerKey,
            margin: const EdgeInsets.only(bottom: 20),
            child: TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              cursorColor: AppColors.bgColor,
              controller: mycontroller,
              obscureText: obscureText ?? false,
              onChanged: (value) {
                if (disallowZero && value == '0') {
                  mycontroller?.clear();
                  return;
                }
                if (errorKey != null && errorKey.isNotEmpty) {
                  KaidhaSub_Controller.clearFieldError(errorKey);
                }
                KaidhaSub_Controller.debouncedSaveState();
              },
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: font10Grey500W(context, size: size_14(context)),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isEmpty ? Colors.red : AppColors.gryColor_3,
                    width: isEmpty ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isEmpty ? Colors.red : AppColors.greenColor,
                    width: isEmpty ? 1.5 : 1.0,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                // ignore: deprecated_member_use
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'يجب إدخال أرقام فقط';
                }
                return null;
              },
            ),
          ),
        ),
        if (errorText != null && errorText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: robotoRegular.copyWith(
              color: Colors.red,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _customTextFormAuth(
    KaidhaSubscription_Controller KaidhaSub_Controller, {
    String? hintText,
    bool isNumber = false,
    bool? obscureText,
    TextEditingController? mycontroller,
    required FocusNode? focusNode,
    required String text,
    required BuildContext context,
    required bool isEmpty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Custom_Text(
          context,
          text: text,
          style: font11Black500W(context, size: size_14(context)),
        ),
        const SizedBox(height: 10),

        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: TextFormField(
            focusNode: focusNode,
            controller: mycontroller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            cursorColor: AppColors.bgColor,
            obscureText: obscureText ?? false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            },
            onChanged: (value) {
              KaidhaSub_Controller.debouncedSaveState();
            },
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: font10Grey500W(context, size: size_14(context)),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isEmpty == true && mycontroller!.text.isEmpty
                      ? Colors.red
                      : AppColors.gryColor_3,
                  width: isEmpty ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isEmpty == true && mycontroller!.text.isEmpty
                      ? AppColors.redColor
                      : AppColors.greenColor,
                  width: isEmpty ? 1.5 : 1.0,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isEmpty ? Colors.red : AppColors.gryColor_3,
                ),
              ),
            ),
          ),
        ),

        //
      ],
    );
  }

  Widget _buildDate_old_10(BuildContext context,
      KaidhaSubscription_Controller KaidhaSub_Controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Custom_Text(
          context,
          text: 'birth_date'.tr,
          style: font11Black500W(context, size: size_14(context)),
        ),
        const SizedBox(height: 10),
        Focus(
          focusNode: KaidhaSub_Controller.birthDateFocus,
          child: Container(
            key: KaidhaSubscription_Controller.birthDateKey, // <-- مهم
            child: TextFormField(
              controller:
                  TextEditingController(text: KaidhaSub_Controller.birthDate),
              readOnly: true,
              onTap: () => _selectDate_Old_10(context, KaidhaSub_Controller),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء اختيار تاريخ الميلاد';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                hintStyle: font10Grey500W(context, size: size_14(context)),
                suffixIcon:
                    const Icon(Icons.calendar_today, color: AppColors.gryColor_3),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: KaidhaSub_Controller.isBirthDateEmpty
                        ? Colors.red
                        : AppColors.gryColor_3,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: KaidhaSub_Controller.isBirthDateEmpty
                        ? Colors.red
                        : AppColors.greenColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate_Old_10(
      BuildContext context, KaidhaSubscription_Controller controller) async {
    final DateTime today = DateTime.now();
    final DateTime maxAllowedDate = DateTime(
        today.year - 10, today.month, today.day); // الحد الأقصى (العمر >= 10)
    final DateTime firstDate =
        DateTime(today.year - 100); // الحد الأدنى (العمر <= 100)
    final DateTime initialDate = controller.birthDate != null
        ? DateTime.tryParse(controller.birthDate) ?? maxAllowedDate
        : maxAllowedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: maxAllowedDate,
      locale:
          const Locale('en', 'US'), // يمكن تغييره إلى Locale("ar", "SA") مثلاً
    );

    if (picked != null) {
      final String formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      controller.updateBirthDate(formattedDate);
    }
  }

  Widget _buildExpirationDateField(BuildContext context, {String? text}) {
    final KaidhaSub_Controller = Get.find<KaidhaSubscription_Controller>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Custom_Text(
          context,
          text: text ?? 'تاريخ الانتهاء',
          style: font11Black500W(context, size: size_14(context)),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: KaidhaSubscription_Controller.endDateKey,
          focusNode: KaidhaSub_Controller.endDateFocus,
          controller:
              TextEditingController(text: KaidhaSub_Controller.end_date),
          readOnly: true,
          onTap: () => _selectExpirationDate(context),
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.gryColor_3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: KaidhaSub_Controller.isEndDateEmpty
                    ? Colors.red
                    : AppColors.gryColor_3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: KaidhaSub_Controller.isEndDateEmpty &&
                        KaidhaSub_Controller.end_date.isEmpty
                    ? Colors.red
                    : AppColors.greenColor,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              KaidhaSub_Controller.isEndDateEmpty = true;

              // التمرير إلى الحقل
              Future.delayed(const Duration(milliseconds: 100), () {
                Scrollable.ensureVisible(
                  KaidhaSubscription_Controller.endDateKey.currentContext!,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                KaidhaSub_Controller.endDateFocus.requestFocus();
              });

              return 'الرجاء اختيار تاريخ الانتهاء';
            }

            KaidhaSub_Controller.isEndDateEmpty = false;
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _selectExpirationDate(BuildContext context) async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(today.year + 30),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.greenColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      Get.find<KaidhaSubscription_Controller>()
          .updateExpirationDate(formattedDate);
    }
  }
}
