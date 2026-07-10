/// Sold-With Item Card
///
/// Compact 167×190 product tile used in the "يُباع معها أيضاً" (sold with it)
/// horizontal strip on the product details screen. Matches the new design:
/// discount badge on the top start, favourite on the top end, product image
/// centered, then name / unit / price, with the add control docked at the
/// bottom start.
///
/// All cart and favourite behaviour is delegated to the shared [CartCountView]
/// and [CustomFavouriteWidget] so existing logic stays unchanged.
///
/// File: sold_with_item_card.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class SoldWithItemCard extends StatelessWidget {
  final Item item;
  final int index;

  const SoldWithItemCard({super.key, required this.item, required this.index});

  static const Color _addBg = Color(0xFFD1FDD2);
  static const Color _favBg = Color(0xFFF8F7F9);
  static const Color _priceColor = Color(0xFF121C19);
  static const Color _oldPriceColor = Color(0xFF717885);

  bool get _hasDiscount =>
      (item.originalPrice ?? 0) > 0 &&
      (item.originalPrice ?? 0) > (item.price ?? 0);

  int get _discountPercent {
    final double original = (item.originalPrice ?? 0).toDouble();
    final double current = (item.price ?? 0).toDouble();
    if (original <= 0 || current >= original) return 0;
    return ((original - current) / original * 100).round();
  }

  void _openItem(BuildContext context) {
    Get.find<ItemController>()
        .navigateToItemPage(item, context, inStore: false);
  }

  Widget _discountBadge() {
    final int percent = _discountPercent;
    if (percent <= 0) return const SizedBox();
    return Container(
      width: 38,
      height: 19.77,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF9D7D7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6.64),
          bottomRight: Radius.circular(6.64),
        ),
      ),
      child: Text(
        '-$percent%',
        textAlign: TextAlign.center,
        style: tajawalBold.copyWith(
          fontSize: 12,
          height: 1.0,
          letterSpacing: 0,
          color: const Color(0xFFDB2525),
        ),
      ),
    );
  }

  Widget _favouriteButton() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(color: _favBg, shape: BoxShape.circle),
      child: Center(
        child: GetBuilder<FavouriteController>(
          builder: (favouriteController) {
            final bool isWished =
                favouriteController.wishItemIdList.contains(item.id);
            return CustomFavouriteWidget(
              isWished: isWished,
              item: item,
              size: 18,
            );
          },
        ),
      ),
    );
  }

  Widget _addButton() {
    return CartCountView(
      item: item,
      index: index,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: _addBg, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Color(0xff30913F), size: 20),
      ),
    );
  }

  Widget _priceRow() {
    return Row(
      children: [
        Text(
          PriceConverter.convertPrice(item.price ?? 0),
          textAlign: TextAlign.right,
          style: tajawalMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: 0,
            color: _priceColor,
          ),
        ),
        const SizedBox(width: 2),
        Image.asset(Images.sar, height: 13, color: _priceColor),
        if (_hasDiscount) ...[
          const SizedBox(width: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    PriceConverter.convertPrice(item.originalPrice ?? 0),
                    textAlign: TextAlign.center,
                    style: tajawalMedium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      letterSpacing: 0,
                      color: _oldPriceColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Image.asset(Images.sar, height: 10, color: _oldPriceColor),
                ],
              ),
              Positioned.fill(
                child: Center(
                  child: Container(height: 1.2, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openItem(context),
      child: Container(
        // Fills the grid cell (≈167×190). No border — soft drop shadow only.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        // color: _imageBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomImage(
                        image: item.displayImage ?? '',
                        fallbackUrls: item.imagesFullUrl,
                        imageStatus: item.imageStatus,
                        placeholder: Images.placeholder,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name ?? '',
                          textAlign: TextAlign.right,
                          style: tajawalBold.copyWith(
                            fontSize: 13,
                            height: 1.35,
                            letterSpacing: 0,
                            color: AppColors.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((item.unitType ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.unitType!,
                              textAlign: TextAlign.right,
                              style: tajawalMedium.copyWith(
                                fontSize: 12,
                                height: 1.3,
                                letterSpacing: 0,
                                color: AppColors.gryColor_2,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        _priceRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Physical corners to match the design exactly (independent of RTL):
            // discount top-left, favourite top-right, add bottom-left.
            // Favourite + add on the left edge; discount on the right.
            Positioned(top: 8, left: 8, child: _favouriteButton()),
            Positioned(top: 5, right: 5, child: _discountBadge()),
            Positioned(bottom: 8, left: 8, child: _addButton()),
          ],
        ),
      ),
    );
  }
}
