// import 'package:flutter/material.dart';
// ignore_for_file: use_super_parameters, file_names
import 'package:flutter/material.dart';

import '../../util/app_colors.dart';
import '../../util/styles.dart';

class CustomAppTextField extends StatelessWidget {
  final String labelText;
  final Widget? prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final bool? dottedBorder;
  final String? Function(String?)? validator;
  final double? padding;
  final double? horizontalPadding;
  final bool? readOnly;
  final String? initialValue;
  final Color? borderColor;
  final double? radius;
  final Color? suffixColor;
  final double? borderWidth;
  final Color? enableBorderColor;

  const CustomAppTextField({
    Key? key,
    required this.labelText,
    this.prefixIcon,
    this.dottedBorder,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.padding,
    this.readOnly,
    this.initialValue,
    this.borderColor,
    this.radius,
    this.suffixColor,
    this.horizontalPadding,
    this.borderWidth,
    this.enableBorderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        cursorColor: enableBorderColor ?? AppColors.greenColor,
        readOnly: readOnly ?? false,
        initialValue: initialValue,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: AppColors.bgColor),
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: suffixIcon,
          suffixIconColor: suffixColor,
          prefixIcon: prefixIcon,
          prefixIconColor: AppColors.gryColor_5,
          labelStyle: font12Grey400W(context),
          contentPadding: EdgeInsets.symmetric(vertical: padding ?? 20, horizontal: horizontalPadding ?? 20),
          enabledBorder: dottedBorder ?? false
              ? const OutlineInputBorder(borderSide: BorderSide.none)
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius != null ? radius ?? 0 : 8.0),
                  borderSide: BorderSide(color: borderColor ?? AppColors.bgColor, width: borderWidth ?? 1)),
          focusedBorder:
              OutlineInputBorder(borderSide: BorderSide(color: enableBorderColor ?? AppColors.greenColor, width: borderWidth ?? 1)),
          border: dottedBorder ?? false
              ? const OutlineInputBorder(borderSide: BorderSide.none)
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    width: borderWidth ?? 1,
                  )),
        ),
      ),
    );
  }
}
