// ignore_for_file: prefer_const_literals_to_create_immutables, non_constant_identifier_names, camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/personal_information.dart';
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
                                KaidhaSubController.validate_Fields_Screen_1(
                                    context);

                                KaidhaSubController.SendState_kaidha(
                                    'in_progress'); //  ارسال الحاله
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
