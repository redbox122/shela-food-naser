// ignore_for_file: non_constant_identifier_names, file_names

import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import '../../util/app_colors.dart';
import '../../util/styles.dart';

PreferredSize custom_AppBar(BuildContext context,
    {String? title,
    IconData? icon,
    String? img_icon,
    IconData? titleIcon,
    Function()? onPressed}) {
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
                  Custom_Text(context,
                      text: ' $title ', style: font14White600W(context)),
                  const SizedBox(width: 10),
                  (img_icon != null && img_icon.isNotEmpty)
                      ? Image.asset(img_icon,
                          height: 18,
                          width: 18,
                          color: Theme.of(context).cardColor)
                      : Icon(titleIcon,
                          color: Theme.of(context).cardColor, size: 22)
                ],
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 10,
            start: 15,
            child: IconButton(
              icon: Icon(icon, color: AppColors.wtColor, size: 26),
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
