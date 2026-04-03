import 'package:sixam_mart/features/search/controllers/search_controller.dart' as search;
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/search/widgets/item_view_widget.dart';
import 'package:sixam_mart/features/search/widgets/search_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchResultWidget extends StatefulWidget {
  final String searchText;
  final TabController? tabController;
  const SearchResultWidget({super.key, required this.searchText, this.tabController});

  @override
  SearchResultWidgetState createState() => SearchResultWidgetState();
}

class SearchResultWidgetState extends State<SearchResultWidget> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.tabController != null) {
      _tabController = widget.tabController;
    } else {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ✅ شريط الفلاتر الجديد
      GetBuilder<search.SearchController>(
        builder: (searchController) {
          final isNull = searchController.isStore
              ? searchController.searchStoreList == null
              : searchController.searchItemList == null;
          
          if (isNull) {
            return const SizedBox();
          }
          
          return SearchFilterBar(isStore: searchController.isStore);
        },
      ),
      ResponsiveHelper.isDesktop(context)
          ? const SizedBox()
          : Center(
              child: Container(
              width: Dimensions.webMaxWidth,
              color: Theme.of(context).cardColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorWeight: 3,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).disabledColor,
                unselectedLabelStyle:
                    robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                tabs: [
                  Tab(text: 'item'.tr),
                  Tab(
                      text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                          ? 'restaurants'.tr
                          : 'stores'.tr),
                ],
              ),
            )),
      Expanded(
          child: NotificationListener(
        onNotification: (dynamic scrollNotification) {
          if (scrollNotification is ScrollEndNotification) {
            Get.find<search.SearchController>().setStore(_tabController!.index == 1);
            Get.find<search.SearchController>().searchData(fromHome: false);
          }
          return false;
        },
        child: TabBarView(
          controller: _tabController,
          children: const [
            ItemViewWidget(isItem: false),
            ItemViewWidget(isItem: true),
          ],
        ),
      )),
    ]);
  }
}
