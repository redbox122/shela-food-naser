// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import '../../util/app_colors.dart';
import '../../util/dimensions.dart';
import '../../util/styles.dart';

Text Custom_Text(BuildContext context, {int? maxLines,TextOverflow? textOverFlow,TextAlign? textAlign,required String text, double? size, Color? color, bool underline = false, TextStyle? style,}) {
  return Text(
    text,
    textAlign: textAlign,
    overflow: textOverFlow,
    maxLines: maxLines,
    style: style ??
        font10Black400W(context).copyWith(
          fontSize: size ?? size_10(context),
          color: color ?? AppColors.bgColor,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
        ),
  );
}
