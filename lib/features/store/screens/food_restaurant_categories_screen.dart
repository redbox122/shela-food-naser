import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodRestaurantCategoriesScreen extends StatelessWidget {
  final Function(int?, String)? onCategorySelected;
  
  const FoodRestaurantCategoriesScreen({
    super.key,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text('categories'.tr),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          return GetBuilder<CategoryController>(
            builder: (categoryController) {
              final store = storeController.store;
              if (store == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final allCategories = categoryController.categoryList ?? [];
              final storeCategories = allCategories.where((cat) {
                return store.categoryIds?.contains(cat.id) ?? false;
              }).toList();

              if (storeCategories.isEmpty) {
                return Center(
                  child: Text(
                    'no_categories_available'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: 14,
                      color: theme.disabledColor,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: Dimensions.paddingSizeDefault,
                  mainAxisSpacing: Dimensions.paddingSizeDefault,
                  childAspectRatio: 0.8,
                ),
                itemCount: storeCategories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () {
                        if (onCategorySelected != null) {
                          onCategorySelected!(null, 'all');
                        }
                        Navigator.of(context).pop();
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: tokens.outlineSoft,
                                ),
                              ),
                              child: Container(
                                color: tokens.surfaceSoft,
                                child: Icon(
                                  Icons.all_inclusive,
                                  color: theme.disabledColor,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            'all'.tr,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(
                              fontSize: 12,
                              color: theme.textTheme.bodyLarge?.color,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final category = storeCategories[index - 1];
                  return GestureDetector(
                    onTap: () {
                      if (onCategorySelected != null) {
                        onCategorySelected!(category.id, category.name ?? '');
                      }
                      Navigator.of(context).pop();
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tokens.outlineSoft,
                              ),
                            ),
                            child: Container(
                              color: tokens.surfaceSoft,
                              child: Icon(
                                Icons.category,
                                color: theme.disabledColor,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          category.name ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(
                            fontSize: 12,
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
