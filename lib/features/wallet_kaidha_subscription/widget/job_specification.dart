import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class JobSpecification extends StatelessWidget {
  const JobSpecification({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(
      builder: (kaidhaFormController) {
        return Column(
          children: [
            _buildRadioOption(
              context: context,
              icon: Icons.business,
              mainlabel: 'government_employee'.tr,
              seclabel: 'government_employee_desc'.tr,
              value: 'government employee',
              groupValue: kaidhaFormController.jobSpecification,
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              kaidhaFormController.updatejobSpecification(value!);
            });
          },
        ),
            const SizedBox(height: 20),
            _buildRadioOption(
              context: context,
              icon: Icons.shopping_bag_outlined,
              mainlabel: 'private_sector_employee'.tr,
              seclabel: 'private_sector_employee_desc'.tr,
              value: 'private sector employee',
              groupValue: kaidhaFormController.jobSpecification,
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              kaidhaFormController.updatejobSpecification(value!);
            });
          },
        ),
            const SizedBox(height: 20),
            _buildRadioOption(
              context: context,
              icon: Icons.home_outlined,
              mainlabel: 'self_employed'.tr,
              seclabel: 'self_employed_desc'.tr,
              value: 'self-employed',
              groupValue: kaidhaFormController.jobSpecification,
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              kaidhaFormController.updatejobSpecification(value!);
            });
          },
        ),
            const SizedBox(height: 20),
            _buildRadioOption(
              context: context,
              icon: Icons.account_circle_outlined,
              mainlabel: 'retired'.tr,
              seclabel: 'retired_desc'.tr,
              value: 'retired',
              groupValue: kaidhaFormController.jobSpecification,
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              kaidhaFormController.updatejobSpecification(value!);
            });
          },
        ),
          ],
        );
      },
    );
  }

  Widget _buildRadioOption({
    required BuildContext context,
    required IconData icon,
    required String mainlabel,
    required String seclabel,
    required String value,
    required String? groupValue,
    required void Function(String?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.gryColor_3),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipOval(
                  child: Container(
                height: 48,
                width: 48,
                color: AppColors.greenColor,
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.backgroundColor,
                ),
              )),
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainlabel,
                    textAlign: TextAlign.center,
                    style:
                        robotoBold.copyWith(fontSize: Dimensions.fontSizeMedim),
                  ),
                  Text(
                    seclabel,
                    textAlign: TextAlign.center,
                    style: robotoBold.copyWith(
                        color: Theme.of(context).disabledColor,
                        fontSize: Dimensions.fontSizeMedim),
                  ),
                ],
              ),
              const Spacer(flex: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}
