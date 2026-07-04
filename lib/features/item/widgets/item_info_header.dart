import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 NEW DESIGN: product info header — favourite heart on the start edge,
/// name / description / unit right-aligned beside it.
class ItemInfoHeader extends StatelessWidget {
  final Item item;
  const ItemInfoHeader({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String description =
        (item.description != null && item.description!.trim().isNotEmpty)
            ? item.description!.trim()
            : (item.genericName != null && item.genericName!.isNotEmpty)
                ? item.genericName!.join('، ')
                : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name ?? '',
                textAlign: TextAlign.right,
                style: tajawalBold.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  letterSpacing: 0,
                  color: AppColors.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.right,
                  style: tajawalMedium.copyWith(
                    fontSize: 16,
                    height: 1.4,
                    letterSpacing: 0,
                    color: AppColors.gryColor_2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if ((item.unitType ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.unitType!,
                  style: tajawalMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    height: 1.4,
                    color: AppColors.gryColor_2,
                  ),
                ),
              ],
              // Rating (value + star) — always shown; defaults to 0.0.
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Color(0xFF121C19)),
                  const SizedBox(width: 4),
                  Text(
                    (item.avgRating ?? 0).toStringAsFixed(1),
                    style: tajawalBold.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        // Favourite — pinned to the end edge (left in RTL).
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
              color: Color(0xFFF8F7F9), shape: BoxShape.circle),
          child: Center(
            child:
                GetBuilder<FavouriteController>(builder: (favouriteController) {
              final bool isWished =
                  favouriteController.wishItemIdList.contains(item.id);
              return CustomFavouriteWidget(
                  isWished: isWished,
                  item: item,
                  size: 22,
                  unselectedColor: Colors.black);
            }),
          ),
        ),
      ],
    );
  }
}
