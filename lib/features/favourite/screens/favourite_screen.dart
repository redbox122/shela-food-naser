import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/favourite/widgets/fav_item_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  FavouriteScreenState createState() => FavouriteScreenState();
}

class FavouriteScreenState extends State<FavouriteScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    initCall();
  }

  void initCall() {
    if (AuthHelper.isLoggedIn()) {
      Get.find<FavouriteController>().getFavouriteList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'favourite'.tr, backButton: false),
      body: AuthHelper.isLoggedIn()
          ? SafeArea(
              top: false,
              bottom: true,
              left: false,
              right: false,
              minimum: EdgeInsets.zero,
              child: Column(children: [
              WebScreenTitleWidget(title: 'favourite'.tr),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: SizedBox(
                  width: Dimensions.webMaxWidth,
                  child: _buildStyledTabBar(context),
                ),
              ),
              Expanded(
                  child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  FavItemViewWidget(isStore: false),
                  FavItemViewWidget(isStore: true),
                ],
              )),
            ]))
          : NotLoggedInScreen(callBack: (value) {
              initCall();
              setState(() {});
            }),
    );
  }

  Widget _buildStyledTabBar(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3.0,
            color: Theme.of(context).primaryColor,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 70),
        ),
        tabs: [
          Tab(text: 'item'.tr),
          Tab(
              text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                  ? 'restaurants'.tr
                  : 'stores'.tr),
        ],
      ),
    );
  }
}
