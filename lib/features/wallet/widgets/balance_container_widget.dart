// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet/widgets/add_fund_dialogue_widget.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../util/app_colors.dart';
import '../../../util/styles.dart';

class BalanceContainerWidget extends StatelessWidget {
  const BalanceContainerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.wtColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.withValues(alpha: 0.5), blurRadius: 5, offset: const Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Custom_Text(context, text: 'balance'.tr, style: font14Black600W(context)),
                      const SizedBox(width: 10),
                      const Icon(Icons.error_outline),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PriceConverter.convertPrice2(
                    profileController.userInfoModel!.walletBalance,
                    textStyle: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Colors.black,
                    ),
                  )
                ],
              )),
              SizedBox(
                height: 150,
                width: 100,
                child: IconButton(
                  onPressed: () {},
                  icon: Image.asset('assets/image/partial_wallet.png'),
                ),
              ),
              const SizedBox(width: 30),
              CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                radius: 15,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.wtColor,
                  ),
                  onPressed: () {
                    Get.dialog(
                      const Dialog(
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        child: SizedBox(
                          width: 500,
                          child: SingleChildScrollView(child: AddFundDialogueWidget()),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}
