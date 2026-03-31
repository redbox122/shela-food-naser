import 'package:flutter/material.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/widgets/food_restaurant/food_restaurant_menu_item_card.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:get/get.dart';

class FoodRestaurantCategorySection extends StatelessWidget {
  final CategoryModel category;
  final List<Item> items;
  final GlobalKey sectionKey;
  final bool isLoading;
  final int? highlightedItemId;

  const FoodRestaurantCategorySection({
    super.key,
    required this.category,
    required this.items,
    required this.sectionKey,
    this.isLoading = false,
    this.highlightedItemId,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;
        final TextAlign textAlign = isLtr ? TextAlign.left : TextAlign.right;
        final theme = Theme.of(context);

        return GetBuilder<StoreController>(
          builder: (storeController) {
            final bool isGridView = storeController.isVertical;

            return Column(
              key: sectionKey,
              crossAxisAlignment:
                  isLtr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: 20,
                  ),
                  child: Text(
                    category.name ?? '',
                    textAlign: textAlign,
                    style: robotoBold.copyWith(
                      fontSize: 22,
                      color: theme.textTheme.bodyLarge?.color,
                      letterSpacing: -0.6,
                      height: 1.2,
                    ),
                  ),
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (items.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Center(
                      child: Text(
                        'no_items_available'.tr,
                        textAlign: TextAlign.center,
                        style: robotoRegular.copyWith(
                          fontSize: 14,
                          color: theme.disabledColor,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: isGridView
                        ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return FoodRestaurantMenuItemCard(
                                item: item,
                                isTemporarilyHighlighted:
                                    highlightedItemId != null &&
                                        item.id == highlightedItemId,
                                onTap: () {
                                  Get.find<ItemController>().navigateToItemPage(
                                    item,
                                    context,
                                    inStore: true,
                                  );
                                },
                              );
                            },
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return FoodRestaurantMenuItemCard(
                                item: item,
                                isTemporarilyHighlighted:
                                    highlightedItemId != null &&
                                        item.id == highlightedItemId,
                                onTap: () {
                                  Get.find<ItemController>().navigateToItemPage(
                                    item,
                                    context,
                                    inStore: true,
                                  );
                                },
                              );
                            },
                          ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
