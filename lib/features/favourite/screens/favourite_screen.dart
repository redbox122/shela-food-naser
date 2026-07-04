import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/favourite/widgets/fav_item_view_widget.dart';
import 'package:sixam_mart/features/favourite/widgets/fav_order_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  FavouriteScreenState createState() => FavouriteScreenState();
}

class FavouriteScreenState extends State<FavouriteScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

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
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'my_favourites'.tr,
          style: tajawalBold.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: AuthHelper.isLoggedIn()
          ? SafeArea(
              top: false,
              bottom: true,
              left: false,
              right: false,
              minimum: EdgeInsets.zero,
              child: Column(children: [
                WebScreenTitleWidget(title: 'my_favourites'.tr),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
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
                    FavOrderViewWidget(),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xff000000),
        labelStyle:
            tajawalBold.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        unselectedLabelStyle: tajawalBold.copyWith(fontSize: 18),
        tabs: [
          Tab(
            height: 40,
            text: 'favourite_products_tab'.tr,
          ),
          Tab(height: 40, text: 'favourite_stores_tab'.tr),
          Tab(height: 40, text: 'favourite_orders_tab'.tr),
        ],
      ),
    );
  }
}
