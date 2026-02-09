import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('categories'.tr),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3633)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
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
                      color: const Color(0xFF787878),
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
                                  color: const Color(0xFFF1EFEF),
                                ),
                              ),
                              child: Container(
                                color: const Color(0xFFF1EFEF),
                                child: const Icon(
                                  Icons.all_inclusive,
                                  color: Color(0xFF787878),
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
                              color: const Color(0xFF2D3633),
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
                                color: const Color(0xFFF1EFEF),
                              ),
                            ),
                            child: Container(
                              color: const Color(0xFFF1EFEF),
                              child: const Icon(
                                Icons.category,
                                color: Color(0xFF787878),
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
                            color: const Color(0xFF2D3633),
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

