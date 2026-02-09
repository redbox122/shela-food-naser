// ignore_for_file: non_constant_identifier_names, unnecessary_null_comparison

import 'package:flutter/material.dart';

import '../../util/images.dart';

Image custom_Images_asset({required String image, BoxFit? fit, double? h, double? w}) {
  return image != null
      ? Image.asset(image, width: w ?? 75, height: h ?? 75, fit: fit ?? BoxFit.fill)
      : Image.asset(Images.emptyBox, width: w ?? 75, height: h ?? 75);
}
