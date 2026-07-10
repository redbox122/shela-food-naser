import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/images.dart';
import '../../../util/styles.dart';

class BalanceContainerWidget extends StatelessWidget {
  const BalanceContainerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: AspectRatio(
          aspectRatio: 1.95,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // خلفية البطاقة الخضراء
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    Images.card_quidha,
                    fit: BoxFit.cover,
                  ),
                ),

                // الرصيد المتاح
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'available_balance'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PriceConverter.convertPrice2(
                        profileController.userInfoModel!.walletBalance,
                        symbolColor: Colors.white,
                        textStyle: tajawalBold.copyWith(
                          fontSize: 38,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
