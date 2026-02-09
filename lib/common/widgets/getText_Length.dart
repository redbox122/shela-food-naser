// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

double getText_Length(BuildContext context, String text, TextStyle style) {
  final TextSpan textSpan = TextSpan(text: text, style: style);
  final TextPainter textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  )..layout();
  return textPainter.width;
}
