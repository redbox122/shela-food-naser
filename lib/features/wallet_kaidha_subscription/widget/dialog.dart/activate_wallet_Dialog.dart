// ignore_for_file: file_names, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

Widget buildWalletDialogContent(context) {
  return Center(
    child: Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.all(8.0), child: Image.asset(Images.activate_wallet, height: 70, width: 70)),
          const SizedBox(height: 20),
          Text('في انتظار تفعيل محفظة قيدها', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: 7),
          Text('يمكنك الآن متابعة رصيدك وإجراء المعاملات بسهولة.',
              style: robotoBold.copyWith(color: Theme.of(context as BuildContext).disabledColor, fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(height: 30),
          Container(
            width: 200,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: CustomButton(
              buttonText: 'تم',
              onPressed: () async {
                Get.offAllNamed(RouteHelper.getMainRoute('menu'));
              },
            ),
          ),
        ],
      ),
    ),
  );
}
