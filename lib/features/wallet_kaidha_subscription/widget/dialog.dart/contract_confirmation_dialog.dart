// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_Button_2.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/jason.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class Contract_Confirmation_Dialog extends StatelessWidget {
  const Contract_Confirmation_Dialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: AppColors.greenColor, size: 45),
            const SizedBox(height: 10),
            Custom_Text(
              context,
              text: ' الاطلاع علي العقد',
              style: font10Black600W(context, size: size_14(context)),
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: list_Pdf.map((item) {
                return Custom_Text(
                  context,
                  text: item,
                  textAlign: TextAlign.center,
                  style: font10Grey500W(context, size: size_10(context)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: custom_Button(
                    h: 40,
                    context,
                    title: 'موافق',
                    style: font12White500W(context, size: size_12(context)),
                    onPressed: () {
                      //
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: custom_Button(
                    h: 40,
                    context,
                    title: 'إلغاء',
                    style: font12White500W(context, size: size_12(context)),
                    onPressed: () {
                      Get.back(); // إغلاق النافذة
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
