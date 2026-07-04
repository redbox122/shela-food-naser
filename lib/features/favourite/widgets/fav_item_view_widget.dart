import 'dart:collection';

import 'package:intl/intl.dart' hide TextDirection;
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/card_design/store_card_with_distance.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

String _favouriteSectionLabel(DateTime? day) {
  if (day == null) return '';
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int diff = today.difference(day).inDays;
  if (diff == 0) return 'today'.tr;
  if (diff == 1) return 'yesterday'.tr;
  final String locale = Get.find<LocalizationController>().locale.languageCode;
  return DateFormat('d MMMM، yyyy', locale).format(day);
}

DateTime? _dayKey(DateTime? date) {
  if (date == null) return null;
  return DateTime(date.year, date.month, date.day);
}

class FavItemViewWidget extends StatelessWidget {
  final bool isStore;
  final bool isSearch;
  const FavItemViewWidget(
      {super.key, required this.isStore, this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
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
                  padding: EdgeInsets.only(
                      bottom: ResponsiveHelper.isDesktop(context) ? 0 : 80.0),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : hasItems
                          ? (isStore
                              ? _FavouriteStoresList(
                                  stores:
                                      favouriteController.wishStoreList ?? [],
                                )
                              : _FavouriteProductsList(
                                  items: favouriteController.wishItemList!,
                                ))
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

/// Products tab content: favourites grouped by the day they were added
/// (Today / Yesterday / explicit date) with a redesigned product card.
class _FavouriteProductsList extends StatelessWidget {
  final List<Item?> items;
  const _FavouriteProductsList({required this.items});

  /// Groups items by calendar day, preserving the incoming (newest-first) order.
  Map<DateTime?, List<Item>> _grouped() {
    final LinkedHashMap<DateTime?, List<Item>> groups = LinkedHashMap();
    for (final item in items) {
      if (item == null) continue;
      final DateTime? date = item.wishlistedAtDate;
      final DateTime? key = _dayKey(date);
      groups.putIfAbsent(key, () => <Item>[]).add(item);
    }
    return groups;
  }

  String _sectionLabel(DateTime? day) => _favouriteSectionLabel(day);

  @override
  Widget build(BuildContext context) {
    final Map<DateTime?, List<Item>> groups = _grouped();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          if (entry.key != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
              ),
              child: Text(
                _sectionLabel(entry.key),
                textAlign: TextAlign.right,
                style: tajawalBold.copyWith(
                  fontSize: 20,
                  height: 1.6,
                  letterSpacing: 0,
                  // Text/disable-input — hsba(219, 15%, 52%).
                  color: const Color(0xFF717885),
                ),
              ),
            ),
          ...entry.value.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  0,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                ),
                child: _FavouriteProductCard(item: item),
              )),
        ],
      ],
    );
  }
}

/// Stores tab content: favourite stores grouped by wishlist date.
class _FavouriteStoresList extends StatelessWidget {
  final List<Store?> stores;
  const _FavouriteStoresList({required this.stores});

  Map<DateTime?, List<Store>> _grouped() {
    final LinkedHashMap<DateTime?, List<Store>> groups = LinkedHashMap();
    for (final store in stores) {
      if (store == null) continue;
      final DateTime? date = store.wishlistedAtDate;
      final DateTime? key = _dayKey(date);
      groups.putIfAbsent(key, () => <Store>[]).add(store);
    }
    return groups;
  }

  String _sectionLabel(DateTime? day) => _favouriteSectionLabel(day);

  @override
  Widget build(BuildContext context) {
    final Map<DateTime?, List<Store>> groups = _grouped();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          if (entry.key != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
              ),
              child: Text(
                _sectionLabel(entry.key),
                textAlign: TextAlign.right,
                style: tajawalBold.copyWith(
                  fontSize: 20,
                  height: 1.6,
                  letterSpacing: 0,
                  // Text/disable-input — hsba(219, 15%, 52%).
                  color: const Color(0xFF717885),
                ),
              ),
            ),
          ...entry.value.map((store) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  0,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault,
                ),
                child: StoreCardWithDistance(store: store),
              )),
        ],
      ],
    );
  }
}

/// Redesigned horizontal favourite product card.
class _FavouriteProductCard extends StatelessWidget {
  final Item item;
  const _FavouriteProductCard({required this.item});

  double? get _discount =>
      (item.storeDiscount ?? 0) == 0 ? item.discount : item.storeDiscount;
  String? get _discountType =>
      (item.storeDiscount ?? 0) == 0 ? item.discountType : 'percent';

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final double? discount = _discount;
    final bool hasDiscount = discount != null && discount > 0;

    return InkWell(
      onTap: () => Get.find<ItemController>().navigateToItemPage(item, context),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildImage(context, hasDiscount, discount),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _buildInfo(context)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _buildActions(context, primary),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool hasDiscount, double? discount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: CustomImage(
            image: item.displayImage ?? '',
            fallbackUrls: item.imagesFullUrl,
            imageStatus: item.imageStatus,
            height: 96,
            width: 96,
            fit: BoxFit.cover,
          ),
        ),
        if (hasDiscount)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFFFDBDB),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(Dimensions.radiusDefault),
                  bottomLeft: Radius.circular(Dimensions.radiusDefault),
                ),
              ),
              child: Text(
                _discountType == 'amount'
                    ? PriceConverter.convertPrice(discount)
                    : '${discount!.toStringAsFixed(0)}%-',
                style: tajawalBold.copyWith(
                  fontSize: 13.29,
                  height: 1.0,
                  color: const Color(0xFFE53935),
                ),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.name ?? '',
          style:
              tajawalBold.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if ((item.unitType ?? '').isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.unitType!,
            style: tajawalMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xff2F3735),
            ),
          ),
        ],
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PriceConverter.convertPrice2(
              item.price,
              textStyle: tajawalBold.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff111B18),
              ),
            ),
            if (_discount != null &&
                _discount! > 0 &&
                item.originalPrice != null) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              PriceConverter.convertPrice2(
                item.originalPrice!,
                textStyle: tajawalMedium.copyWith(
                  fontSize: 12,
                  color: Color(0xff9499A3),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: const Color(0xFFE53935),
                  decorationThickness: 2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF8F7F9),
          ),
          child: Center(
            child:
                GetBuilder<FavouriteController>(builder: (favouriteController) {
              final bool isWished =
                  favouriteController.wishItemIdList.contains(item.id);
              return CustomFavouriteWidget(
                isWished: isWished,
                item: item,
                size: 18,
              );
            }),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        CartCountView(
          item: item,
          index: 0,
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffD1FDD2),
            ),
            child: Icon(Icons.add, size: 25, color: primary),
          ),
        ),
      ],
    );
  }
}

class _EmptyFavouriteState extends StatelessWidget {
  final bool isStore;
  const _EmptyFavouriteState({required this.isStore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeExtremeLarge,
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Images.no_favourit,
            width: 211,
            height: 210.32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Icon(
              Icons.favorite_border_rounded,
              size: 96,
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'no_favorites_yet'.tr,
            style: tajawalBold.copyWith(
              fontSize: 18,
              height: 1.6,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
