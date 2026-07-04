import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/widgets/sold_with_item_card.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 NEW DESIGN: "يُباع معها أيضاً" — a 2-column grid of 167×190 similar-item
/// cards. Collapses to nothing when there are no similar products.
class ItemSoldWithGrid extends StatelessWidget {
  final List<Item>? items;

  const ItemSoldWithGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final List<Item> products = items ?? const [];
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('sold_with_it'.tr,
            textAlign: TextAlign.right,
            style: tajawalBold.copyWith(
              fontSize: 16,
              height: 1.4,
              letterSpacing: 0,
            )),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        // 🎨 NEW DESIGN: 2-column grid (167×190 cards, 8px gap).
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            // Fixed 190px card height (width is whatever 2 columns allow ≈167).
            mainAxisExtent: 190,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return SoldWithItemCard(item: products[index], index: index);
          },
        ),
      ],
    );
  }
}
