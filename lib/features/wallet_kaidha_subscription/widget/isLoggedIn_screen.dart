// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/appBar.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/util/images.dart';

class Kiadha_WalletScreen extends StatelessWidget {
  const Kiadha_WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: custom_AppBar(
        context,
        title: 'kiadha_wallet'.tr,
        img_icon: Images.walletIcon,
        titleIcon: Icons.account_balance_wallet_outlined,
      ),
      body: NotLoggedInScreen(callBack: (value) {}),
    );
  }
}
