import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class StagesWidget extends StatelessWidget {
  const StagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(
      builder: (controller) {
        return Column(
          children: [
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildStageIcon(
                      Icons.menu,
                      1,
                      controller,
                      'step1_title'.tr,
                      context,
                    ),
                  ),
                  _buildDynamicDivider(controller.currentStage > 1),
                  Expanded(
                    child: _buildStageIcon(
                      Icons.money,
                      2,
                      controller,
                      'step2_title'.tr,
                      context,
                    ),
                  ),
                  _buildDynamicDivider(controller.currentStage > 2),
                  Expanded(
                    child: _buildStageIcon(
                      Icons.notifications_active_outlined,
                      3,
                      controller,
                      'step3_title'.tr,
                      context,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 0.5),
          ],
        );
      },
    );
  }

  Widget _buildStageIcon(
    IconData icon,
    int stage,
    KaidhaSubscriptionController controller,
    String text,
    BuildContext context,
  ) {
    final isActive = stage <= controller.currentStage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Container(
            height: 48,
            width: 48,
            color: isActive ? AppColors.greenColor : AppColors.gryColor_5,
            child: Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.wtColor : AppColors.bgColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: Custom_Text(
            context,
            text: text,
            textAlign: TextAlign.center,
            style: isActive
                ? font12Green600W(context, size: size_10(context))
                : font10Black600W(context, size: size_10(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicDivider(bool isActive) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Container(
          height: 3,
          width: 59,
          color: isActive ? AppColors.greenColor : AppColors.darkGreyColor,
        ),
      ),
    );
  }
}
