// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sixam_mart/util/images.dart';

import '../../util/styles.dart';
import 'custom_Images.dart';
import 'custom_text.dart';

PreferredSize customAppBar(BuildContext context, {String? title, String? img, IconData? icon, Function()? onPressed}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(80),
    child: AppBar(
      backgroundColor: Colors.green,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Custom_Text(context, text: ' $title ', style: font14White600W(context)),
                  const SizedBox(width: 10),
                  icon != null
                      ? Icon(icon, color: Colors.white, size: 22)
                      : custom_Images_asset(image: img ?? Images.orderConfirmIcon, h: 20, w: 25, fit: BoxFit.none),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 10,
            start: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
              onPressed: onPressed ??
                  () {
                    Navigator.pop(context);
                  },
            ),
          ),
        ],
      ),
    ),
  );
}
