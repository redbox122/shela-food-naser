import 'package:sixam_mart/common/widgets/card_design/store_card_with_distance.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/home/utils/store_filter_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemsView extends StatefulWidget {
  final List<Item?>? items;
  final List<Store?>? stores;
  final bool isStore;
  final EdgeInsetsGeometry padding;
  final bool isScrollable;
  final int shimmerLength;
  final String? noDataText;
  final bool isCampaign;
  final bool inStorePage;
  final bool isFeatured;
  final bool verticalItem;
  final bool? isFoodOrGrocery;
  final bool navigateItemToStoreOnTap;
  final String? noDataActionText;
  final VoidCallback? onNoDataActionTap;
  const ItemsView(
      {super.key,
      required this.stores,
      required this.items,
      required this.isStore,
      this.isScrollable = false,
      this.shimmerLength = 20,
      this.padding = const EdgeInsets.all(Dimensions.paddingSizeDefault),
      this.noDataText,
      this.isCampaign = false,
      this.verticalItem = false,
      this.inStorePage = false,
      this.isFeatured = false,
      this.isFoodOrGrocery = true,
      this.navigateItemToStoreOnTap = false,
      this.noDataActionText,
      this.onNoDataActionTap});

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  @override
  Widget build(BuildContext context) {
    bool isNull = true;
    int length = 0;
    // RULE #2 (defence): hide stores with no image before they reach the grid,
    // so an imageless store never renders as a grey placeholder card. Products
    // are intentionally NOT filtered here (rule scoped to stores).
    final List<Store?>? stores = (widget.isStore && widget.stores != null)
        ? widget.stores!
            .where((s) => s != null && StoreFilterHelper.storeHasImage(s))
            .toList()
        : widget.stores;
    if (widget.isStore) {
      isNull = stores == null;
      if (stores != null) {
        length = stores.length;
      }
    } else {
      isNull = widget.items == null;
      if (!isNull) {
        length = widget.items!.length;
      }
    }

    return Column(children: [
      !isNull
          ? length > 0
              ? GridView.builder(
                  // 🎯 PERFORMANCE: Use stable key based on widget properties
                  // Avoid UniqueKey() which forces full rebuild on every build
                  key: ValueKey(
                      'items_${length}_${widget.isStore}_${widget.verticalItem}'),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: ResponsiveHelper.isDesktop(context)
                        ? Dimensions.paddingSizeExtremeLarge
                        : widget.stores != null
                            ? Dimensions.paddingSizeLarge
                            : Dimensions.paddingSizeLarge,
                    mainAxisSpacing: ResponsiveHelper.isDesktop(context)
                        ? Dimensions.paddingSizeExtremeLarge
                        : widget.stores != null && widget.isStore
                            ? Dimensions.paddingSizeLarge
                            : Dimensions.paddingSizeSmall,
                    // childAspectRatio: ResponsiveHelper.isDesktop(context) && widget.isStore ? (1/0.6)
                    //     : ResponsiveHelper.isMobile(context) ? widget.stores != null && widget.isStore ? 2 : 3.8
                    //     : 3.3,
                    mainAxisExtent:
                        ResponsiveHelper.isDesktop(context) && widget.isStore
                            ? 220
                            : ResponsiveHelper.isMobile(context)
                                ? widget.stores != null && widget.isStore
                                    ? 200
                                    : widget.verticalItem
                                        ? 200
                                        : 122
                                : 122,
                    crossAxisCount: ResponsiveHelper.isMobile(context)
                        ? widget.verticalItem
                            ? 2
                            : 1
                        : ResponsiveHelper.isDesktop(context) &&
                                widget.stores != null
                            ? 3
                            : 3,
                  ),
                  physics: widget.isScrollable
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  shrinkWrap: widget.isScrollable ? false : true,
                  itemCount: length,
                  padding: widget.padding,
                  addAutomaticKeepAlives:
                      false, // ⚡ TASK 3: Disable keepAlive for 2K items
                  itemBuilder: (context, index) {
                    return stores != null && widget.isStore
                        ? StoreCardWithDistance(
                            store: stores[index]!,
                            fromAllStore: true,
                            heroSection: 'items_view_store_grid',
                            heroIndex: index,
                          )
                        : ItemWidget(
                            key: ValueKey(
                                'item_${widget.items![index]?.id}_$index'), // 🎯 PERFORMANCE: Key for stable rebuilds
                            isStore: widget.isStore,
                            item: widget.isStore ? null : widget.items![index],
                            isFeatured: widget.isFeatured,
                            store: widget.isStore ? stores![index] : null,
                            index: index,
                            length: length,
                            isCampaign: widget.isCampaign,
                            verticalItem: widget.verticalItem,
                            inStore: widget.inStorePage,
                            navigateItemToStoreOnTap:
                                widget.navigateItemToStoreOnTap,
                          );
                  },
                )
              : Column(
                  children: [
                    NoDataScreen(
                      text: widget.noDataText ??
                          (widget.isStore
                              ? Get.find<SplashController>()
                                      .configModel!
                                      .moduleConfig!
                                      .module!
                                      .showRestaurantText!
                                  ? 'no_restaurant_available'.tr
                                  : 'no_store_available'.tr
                              : 'no_item_available'.tr),
                      actionWidget: widget.onNoDataActionTap != null
                          ? OutlinedButton(
                              onPressed: widget.onNoDataActionTap,
                              child:
                                  Text(widget.noDataActionText ?? 'reset'.tr),
                            )
                          : null,
                    ),
                  ],
                )
          : widget.isStore
              ? GridView.builder(
                  // 🎯 PERFORMANCE: Use stable key, avoid UniqueKey()
                  key: ValueKey('skeleton_${widget.shimmerLength}'),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: ResponsiveHelper.isDesktop(context)
                        ? Dimensions.paddingSizeExtremeLarge
                        : widget.stores != null
                            ? Dimensions.paddingSizeLarge
                            : Dimensions.paddingSizeLarge,
                    mainAxisSpacing: ResponsiveHelper.isDesktop(context)
                        ? Dimensions.paddingSizeLarge
                        : widget.stores != null
                            ? Dimensions.paddingSizeLarge
                            : Dimensions.paddingSizeSmall,
                    // childAspectRatio: ResponsiveHelper.isDesktop(context) && widget.isStore ? (1/0.6)
                    //     : ResponsiveHelper.isMobile(context) ? widget.isStore ? 2 : 3.8
                    //     : 3,
                    mainAxisExtent:
                        ResponsiveHelper.isDesktop(context) && widget.isStore
                            ? 220
                            : ResponsiveHelper.isMobile(context)
                                ? widget.isStore
                                    ? 200
                                    : 110
                                : 110,
                    crossAxisCount: ResponsiveHelper.isMobile(context)
                        ? 1
                        : ResponsiveHelper.isDesktop(context)
                            ? 3
                            : 3,
                  ),
                  physics: widget.isScrollable
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  shrinkWrap: widget.isScrollable ? false : true,
                  itemCount: widget.shimmerLength,
                  padding: widget.padding,
                  addAutomaticKeepAlives:
                      false, // ⚡ TASK 3: Performance optimization
                  itemBuilder: (context, index) {
                    return const NewOnShimmerView();
                  },
                )
              : LoadingWidget(
                  messageKey: widget.isStore
                      ? 'bringing_great_stores'
                      : 'bringing_great_products',
                ),
    ]);
  }
}

class NewOnShimmerView extends StatelessWidget {
  const NewOnShimmerView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Stack(children: [
        Container(
          // width: fromAllStore ?  MediaQuery.of(context).size.width : 260,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusDefault),
                    topRight: Radius.circular(Dimensions.radiusDefault)),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                  Positioned(
                    top: 15,
                    right: 50,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Theme.of(context).cardColor.withValues(alpha: 0.8),
                      ),
                      child: Icon(Icons.favorite_border,
                          color: Theme.of(context).primaryColor, size: 20),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: Column(children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 95),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              height: 5,
                              width: 100,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.blue, size: 15),
                            const SizedBox(
                                width: Dimensions.paddingSizeExtraSmall),
                            Expanded(
                              child: Container(
                                height: 10,
                                width: 100,
                                color: Theme.of(context).cardColor,
                              ),
                            ),
                          ]),
                        ]),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 10,
                            width: 70,
                            padding: const EdgeInsets.symmetric(
                                vertical: 3,
                                horizontal: Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusLarge),
                            ),
                          ),
                          Container(
                            height: 20,
                            width: 65,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusSmall),
                            ),
                          ),
                        ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        Positioned(
          top: 60,
          left: 15,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 65,
                width: 65,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
