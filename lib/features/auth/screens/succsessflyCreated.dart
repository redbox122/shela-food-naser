// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class Succsessflycreated extends StatelessWidget {
  const Succsessflycreated({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            SizedBox(
              height: size.height / 3.3,
            ),
            Image.asset(Images.logo, height: size.height / 4),
            SizedBox(height: size_16(context)),
            Text(
              'تم إنشاء الحساب بنجاح',
              style: font18Green500W(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size_16(context)),
            Text(
              'يمكنك تصفح التطبيق الــآن مع اخر العروض والخصومات',
              style: font14Grey400W(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size_18(context)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: AppColors.greenColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () async {
                  if (!ResponsiveHelper.isDesktop(context)) {
                    await Get.offAllNamed(
                      RouteHelper.getSignInRoute(RouteHelper.initial),
                    );
                  } else {
                    // Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: true, backFromThis: true)));
                  }
                },
                child:
                    Text('قم بتسجيل الدخول', style: font14White600W(context)),
              ),
            ),
            SizedBox(height: size_18(context)),
          ],
        ),
      ),
    );
  }
}
