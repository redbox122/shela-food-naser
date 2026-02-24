import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helper/responsive_helper.dart';

class Dimensions {
  static double fontSizeOverSmall = Get.context!.width >= 1300 ? 10 : 8;
  static double fontSizeExtraSmall = Get.context!.width >= 1300 ? 12 : 10;
  static double fontSizeSmall = Get.context!.width >= 1300 ? 14 : 12;
  static double fontSizeDefault = Get.context!.width >= 1300 ? 16 : 14;
  static double fontSizeLarge = Get.context!.width >= 1300 ? 18 : 16;
  static double fontSizeMedim = Get.context!.width >= 1300 ? 17 : 15;

  static double fontSizeExtraLarge = Get.context!.width >= 1300 ? 20 : 18;
  static double fontSizeOverLarge = Get.context!.width >= 1300 ? 26 : 24;

  static const double paddingSizeExtraSmall = 5.0;
  static const double paddingSizeSmall = 10.0;
  static const double paddingSizeDefault = 15.0;
  static const double paddingSizeLarge = 20.0;
  static const double paddingSizeExtraLarge = 25.0;
  static const double paddingSizeExtremeLarge = 30.0;
  static const double paddingSizeExtraOverLarge = 35.0;

  static const double radiusSmall = 5.0;
  static const double radiusDefault = 10.0;
  static const double radiusLarge = 15.0;
  static const double radiusExtraLarge = 20.0;

  static const double webMaxWidth = 1170;
  static const int messageInputLength = 1000;

  static const double pickMapIconSize = 100.0;
}

double width_media(BuildContext context) {
  final double reswidth = MediaQuery.sizeOf(context).width;
  return reswidth;
}

double height_media(BuildContext context) {
  final double resheight = MediaQuery.sizeOf(context).height;
  return resheight;
}

double size_4(BuildContext context) => sp(context, 4);
double size_6(BuildContext context) => sp(context, 6);
double size_8(BuildContext context) => sp(context, 8);
double size_9(BuildContext context) => sp(context, 9);

double size_10(BuildContext context) => sp(context, 10);
double size_11(BuildContext context) => sp(context, 11);

double size_12(BuildContext context) => sp(context, 12);
double size_13(BuildContext context) => sp(context, 13);
double size_14(BuildContext context) => sp(context, 14);
double size_15(BuildContext context) => sp(context, 15);
double size_16(BuildContext context) => sp(context, 16);
double size_18(BuildContext context) => sp(context, 18);
double size_20(BuildContext context) => sp(context, 20);
double size_22(BuildContext context) => sp(context, 22);
double size_24(BuildContext context) => sp(context, 24);

double sp(BuildContext context, double fontSize) {
  // ⚙️ إذا كان الويب واستخدام تصميم الموبايل مفعّل، استخدم أحجام الموبايل
  final bool useWebScaling = ResponsiveHelper.isWeb() && !ResponsiveHelper.useMobileDesignOnWeb;
  
  final double scaleFactor = useWebScaling ? MediaQuery.of(context).size.width / 1420 : MediaQuery.of(context).size.width / 375;
  final double heightFactor = useWebScaling ? MediaQuery.of(context).size.width / 700 : MediaQuery.of(context).size.height / 812;

  final double responsiveFactor = (scaleFactor + heightFactor) / 2;

  return fontSize * responsiveFactor;
}

// =========================================================
