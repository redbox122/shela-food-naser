// ignore_for_file: prefer_const_literals_to_create_immutables, non_constant_identifier_names, camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/personal_information.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/before_Pdf.dart';
import '../../../../util/dimensions.dart';

class Step_1_Screen extends StatefulWidget {
  const Step_1_Screen({super.key});

  @override
  State<Step_1_Screen> createState() => _Step_1_ScreenState();
}

class _Step_1_ScreenState extends State<Step_1_Screen> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(
        builder: (KaidhaSubController) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              KaidhaSubController.isLoading
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 20),

                          //

                          const PersonalInformation(),

                          //
                          const SizedBox(height: 20),
                          Container(
                            width: 1170,
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            child: CustomButton(
                              buttonText: 'next'.tr,
                              onPressed: () async {
                                debugPrint('[QidhaSub][NEXT] pressed');
                                final bool isValid =
                                    KaidhaSubController
                                        .validate_Fields_Screen_1(context);
                                if (isValid) {
                                  KaidhaSubController.SendState_kaidha(
                                      'in_progress');
                                }
                              },
                            ),
                          ),
                          // "استعراض العقد قبل التوقيع" — secondary button that
                          // opens the contract preview filled with the entered data.
                          Container(
                            width: 1170,
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeSmall),
                            child: CustomButton(
                              color: const Color(0xFFF5F5F5),
                              textColor: const Color(0xFF2D3633),
                              buttonText: 'review_contract_before_signing'.tr,
                              onPressed: () {
                                final now = DateTime.now();
                                final time =
                                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                                const days = [
                                  'الاثنين',
                                  'الثلاثاء',
                                  'الأربعاء',
                                  'الخميس',
                                  'الجمعة',
                                  'السبت',
                                  'الأحد'
                                ];
                                Get.to(
                                  () => Befor_Pdf_Screen(
                                    time: time,
                                    day: days[now.weekday - 1],
                                    name:
                                        '${KaidhaSubController.firstname.text} ${KaidhaSubController.fathername.text} ${KaidhaSubController.grandfathername.text} ${KaidhaSubController.last_name.text}',
                                    identityNumber: KaidhaSubController
                                        .identity_card_number.text
                                        .toString(),
                                    nationality: KaidhaSubController.nationality
                                        .toString(),
                                    neighborhood: KaidhaSubController
                                        .neighborhood.text
                                        .toString(),
                                    house_type: KaidhaSubController.house_type
                                        .toString(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      );
    });
  }
}
