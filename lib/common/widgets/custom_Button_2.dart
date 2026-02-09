// ignore_for_file: non_constant_identifier_names, file_names

import 'package:flutter/material.dart';
import '../../util/app_colors.dart';
import '../../util/dimensions.dart';
import 'custom_text.dart';

Widget custom_Button(
  BuildContext context, {
  double? h,
  double? w,
  double? borderwidth,
  Color? buttoncolor,
  Color? bordersidecolor,
  Color? textcolor,
  FontWeight? fontweight,
  double? fontSize,
  TextStyle? style,
  IconData? icon,
  Color? iconcolor,
  bool isIcon = false,
  required String title,
  required VoidCallback onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: SizedBox(
      height: h ?? 62,
      width: w ?? width_media(context),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttoncolor ?? AppColors.greenColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: bordersidecolor ?? AppColors.greenColor, width: borderwidth ?? 2),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Custom_Text(context, text: title, style: style, color: textcolor ?? AppColors.wtColor, size: fontSize ?? size_14(context)),
            isIcon ? const SizedBox(width: 10) : const SizedBox.shrink(),
            isIcon
                ? Icon(
                    icon,
                    size: 24,
                    color: iconcolor,
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    ),
  );
}
