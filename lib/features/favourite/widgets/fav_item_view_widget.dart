import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavItemViewWidget extends StatelessWidget {
  final bool isStore;
  final bool isSearch;
  const FavItemViewWidget({super.key, required this.isStore, this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<FavouriteController>(builder: (favouriteController) {
        final bool isLoading = isStore
            ? favouriteController.wishStoreList == null
            : favouriteController.wishItemList == null;
        final bool hasItems = isStore
            ? (favouriteController.wishStoreList?.isNotEmpty ?? false)
            : (favouriteController.wishItemList?.isNotEmpty ?? false);
        if (!isLoading && favouriteController.hasError) {
          return ErrorStateView(
            onRetry: () => favouriteController.getFavouriteList(),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await favouriteController.getFavouriteList();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: FooterView(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.isDesktop(context) ? 0 : 80.0),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : hasItems
                          ? ItemsView(
                              isStore: isStore,
                              items: favouriteController.wishItemList,
                              stores: favouriteController.wishStoreList,
                              noDataText: 'no_wish_data_found'.tr,
                              isFeatured: true,
                            )
                          : _EmptyFavouriteState(isStore: isStore),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyFavouriteState extends StatelessWidget {
  final bool isStore;
  const _EmptyFavouriteState({required this.isStore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            'no_favorites_yet'.tr,
            style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            isStore
                ? 'no_favorites_yet_subtitle_stores'.tr
                : 'no_favorites_yet_subtitle_items'.tr,
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
