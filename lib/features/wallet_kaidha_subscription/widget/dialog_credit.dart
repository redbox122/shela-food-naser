// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_Button_2.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class Dialog_Credit extends StatelessWidget {
  const Dialog_Credit({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundColor,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.greenColor, size: 45),
          const SizedBox(height: 10),
          Custom_Text(context, text: 'طلبك قيد المراجعة بمحفظة قيدها', style: font10Black600W(context, size: size_14(context))),
          const SizedBox(height: 15),
          Custom_Text(context,
              text: 'شكرآ لك على ملئ البيانات المطلوبة\nسوف نتواصل معك قريبآ',
              textAlign: TextAlign.center,
              style: font10Grey500W(context, size: size_12(context))),
          const SizedBox(height: 15),
          custom_Button(
            h: 50,
            w: 300,
            context,
            title: 'تم',
            style: font12White500W(context, size: size_12(context)),
            onPressed: () => Get.back(),
          )
        ],
      ),
    );
  }
}
