import 'package:get/get.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

final robotoRegular = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault,
);

final robotoMedium = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontWeight: FontWeight.w500,
  fontSize: Dimensions.fontSizeDefault,
);

final robotoBold = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

final robotoBlack = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontWeight: FontWeight.w900,
  fontSize: Dimensions.fontSizeDefault,
);

final tajawalRegular = TextStyle(
  fontFamily: 'Tajawal',
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault,
);

final tajawalMedium = TextStyle(
  fontFamily: 'Tajawal',
  fontWeight: FontWeight.w500,
  fontSize: Dimensions.fontSizeDefault,
);

final tajawalBold = TextStyle(
  fontFamily: 'Tajawal',
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

final BoxDecoration riderContainerDecoration = BoxDecoration(
  borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
  color: Theme.of(Get.context!).primaryColor.withValues(alpha: 0.1),
);

TextStyle font10Black400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font10White400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font10Black300W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w300,
  );
}

TextStyle font10Black600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font11Black400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_11(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font11Black500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_11(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font11Black600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_11(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font13Black400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_13(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font16SecondaryColor400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_16(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font12Black400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font8Black400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_8(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font6SecondaryColor400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_6(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font6WhiteColor400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_6(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font12Black300W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w300,
  );
}

TextStyle font14Black400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font14Black500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font14Black600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font18Black600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_18(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font18Black700W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_18(context),
    color: AppColors.bgColor,
    fontWeight: FontWeight.w700,
  );
}

//========================================================

TextStyle font10SecondaryColor600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font12SecondaryColor600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font12SecondaryColor400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font13SecondaryColor400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_13(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font13SecondaryColor600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_13(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font14SecondaryColor500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w500,
  );
}

// ==================== 13 ====================

TextStyle font11White300W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_11(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w300,
  );
}

TextStyle font11White400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_11(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font12White500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font12White600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font12White700W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w700,
  );
}

TextStyle font13White400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_13(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font14White400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font14White500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font14White600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.wtColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font16SecondaryColor700W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_16(context),
    color: AppColors.secondaryColor,
    fontWeight: FontWeight.w700,
  );
}
// ==================== 12 ====================

TextStyle font10Grey400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.gryColor_2,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font10Grey600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.gryColor_2,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font10Grey500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_10(context),
    color: AppColors.gryColor_2,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font11Grey400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_11(context),
    color: AppColors.wGreyColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font11Grey700W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_11(context),
    color: AppColors.wGreyColor,
    fontWeight: FontWeight.w700,
  );
}

TextStyle font12Grey400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.wGreyColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font12Green400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.greenColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font12Green600W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.greenColor,
    fontWeight: FontWeight.w600,
  );
}

TextStyle font12Green300W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_12(context),
    color: AppColors.greenColor,
    fontWeight: FontWeight.w300,
  );
}

TextStyle font13Grey400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_13(context),
    color: AppColors.wGreyColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font14Grey400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.wGreyColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font14Grey500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.wGreyColor,
    fontWeight: FontWeight.w500,
  );
}

// ==================== 13 ===================

TextStyle font13Green500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_13(context),
    color: AppColors.greenColor,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font14Green500W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.greenColor,
    fontWeight: FontWeight.w500,
  );
}

TextStyle font14Green400W(
  BuildContext context, {
  double? size,
  double? lineHeight,
}) {
  return TextStyle(
    fontFamily: 'ReadexPro',
    height: lineHeight ?? 1.5,
    fontSize: size ?? size_14(context),
    color: AppColors.greenColor,
    fontWeight: FontWeight.w400,
  );
}

TextStyle font18Green500W(BuildContext context, {double? size, double? lineHeight}) {
  return TextStyle(
      fontFamily: 'ReadexPro',
      height: lineHeight ?? 1.5,
      fontSize: size ?? size_18(context),
      color: AppColors.greenColor,
      fontWeight: FontWeight.w500);
}
