// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'custom_text.dart';

class TextButtonWidget extends StatelessWidget {
  final Color? backgroundColor;
  final VoidCallback onPressed;
  final String text;
  final TextStyle? textStyle;
  final double radius;
  final double? verticalPadd;
  final double? horizontalPadd;
  final double? height;
  final double? width;
  final Color? borderColor;
  final double? borderWidth;
  const TextButtonWidget(
      {super.key,
      this.backgroundColor,
      required this.onPressed,
      required this.text,
      this.textStyle,
      required this.radius,
      this.verticalPadd,
      this.horizontalPadd,
      this.height,
      this.width,
      this.borderColor,
      this.borderWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: backgroundColor,
          border: Border.all(color: borderColor ?? Colors.transparent, width: borderWidth ?? 0)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadd ?? 16, horizontal: horizontalPadd ?? 16),
        child: TextButton(
          onPressed: onPressed,
          style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.zero)),
          child: Custom_Text(context, text: text, style: textStyle),
        ),
      ),
    );
  }
}
