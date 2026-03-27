/// Grocery Category Detail Screen - Module 7
/// 
/// Specialized category detail screen for grocery stores (module ID 7)
/// with green header, navigation tabs, promotional banner, and 2-column product grid.
/// 
/// File: grocery_category_detail_screen.dart
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/item_shimmer.dart';
import 'package:sixam_mart/features/category/widgets/grocery_category/grocery_category_header.dart';
import 'package:sixam_mart/features/category/widgets/grocery_category/grocery_category_tabs.dart';
import 'package:sixam_mart/features/category/widgets/grocery_category/grocery_category_banner.dart';
import 'package:sixam_mart/features/category/widgets/grocery_category/grocery_product_grid.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class GroceryCategoryDetailScreen extends StatefulWidget {
  final int? categoryId;
  final String categoryName;
  final Store? store;

  const GroceryCategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.store,
  });

  @override
  State<GroceryCategoryDetailScreen> createState() =>
      _GroceryCategoryDetailScreenState();
}

class _GroceryCategoryDetailScreenState
    extends State<GroceryCategoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedSubCategoryId;
  List<Item> _items = [];
  bool _isLoading = true;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryDetailScreen] initState() - File: grocery_category_detail_screen.dart');
      debugPrint(
          '   Category ID: ${widget.categoryId}, Name: ${widget.categoryName}');
    }
    _initializeData();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryDetailScreen] dispose() - File: grocery_category_detail_screen.dart');
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryDetailScreen] _initializeData() - File: grocery_category_detail_screen.dart');
    }
    final categoryController = Get.find<CategoryController>();
    categoryController.resetCategoryPagination(notify: false);
    await categoryController.clearCacheForCategory(widget.categoryId);

    // Load subcategories (void method, no await needed)
    categoryController.getSubCategoryList(widget.categoryId.toString());

    // Wait a bit for subcategories to load, then load items
    await Future.delayed(const Duration(milliseconds: 300));

    // Load items for this category
    await _loadCategoryItems();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCategoryItems({int? subCategoryId}) async {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryDetailScreen] _loadCategoryItems() - File: grocery_category_detail_screen.dart');
      debugPrint('   SubCategory ID: $subCategoryId');
    }
    final categoryController = Get.find<CategoryController>();

    setState(() {
      _isLoading = true;
    });

    try {
      _hasLoadError = false;
      // Use the category ID or subcategory ID
      final categoryIdToLoad = subCategoryId ?? widget.categoryId;
      
      if (categoryIdToLoad != null) {
        categoryController.getCategoryItemList(
          categoryIdToLoad.toString(),
          1,
          'all',
          true, // notify parameter
          includeChildren: true,
        );

        // Wait for items to load (controller updates asynchronously)
        await Future.delayed(const Duration(milliseconds: 800));

        // Get items from controller after it has loaded
        if (categoryController.categoryItemList != null) {
          _items = List<Item>.from(categoryController.categoryItemList!);
        }
      }
    } catch (e) {
      _hasLoadError = true;
      if (kDebugMode) {
        debugPrint('   ❌ Error loading category items: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onSubCategorySelected(int? subCategoryId) {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryDetailScreen] _onSubCategorySelected() - File: grocery_category_detail_screen.dart');
      debugPrint('   SubCategory ID: $subCategoryId');
    }
    setState(() {
      _selectedSubCategoryId = subCategoryId;
    });
    _loadCategoryItems(subCategoryId: subCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
          '📍 [GroceryCategoryDetailScreen] build() - File: grocery_category_detail_screen.dart');
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          final storeController = Get.find<StoreController>();
          final store = widget.store ?? storeController.store;
          final subCategories = categoryController.subCategoryList ?? [];
          
          // Get all categories from store (already loaded from store details)
          storeController.setCategoryList();
          final allCategories = storeController.categoryList ?? [];
          // Filter out the "all" category (index 0) and get store categories
          final storeCategories = allCategories.length > 1
              ? List<CategoryModel>.from(allCategories.sublist(1))
              : <CategoryModel>[];

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Green header with store name, category name, search bar
              SliverToBoxAdapter(
                child: GroceryCategoryHeader(
                  storeName: store?.name ?? '',
                  categoryName: widget.categoryName,
                  storeId: store?.id,
                ),
              ),
              // Swipeable category list (using existing categories from store)
              if (storeCategories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      itemCount: storeCategories.length,
                      itemBuilder: (context, index) {
                        final category = storeCategories[index];
                        final isSelected = category.id == widget.categoryId;

                        return GestureDetector(
                          onTap: () {
                            if (kDebugMode) {
                              debugPrint(
                                  '📍 [GroceryCategoryDetailScreen] Category tapped: ${category.name} (ID: ${category.id})');
                            }
                            // Navigate to the selected category
                            if (category.id != null && category.id != widget.categoryId) {
                              Get.to(() => GroceryCategoryDetailScreen(
                                    categoryId: category.id,
                                    categoryName: category.name ?? '',
                                    store: store,
                                  ));
                            }
                          },
                          child: Container(
                            width: 80,
                            margin: EdgeInsets.only(
                              right: index < storeCategories.length - 1
                                  ? Dimensions.paddingSizeDefault
                                  : 0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Category image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF31A342).withValues(alpha: 0.1)
                                        : AppColors.backgroundColor,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF31A342)
                                          : AppColors.gryColor_3,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                    child: CustomImage(
                                      image: category.imageFullUrl ?? '',
                                      width: 60,
                                      height: 60,
                                      placeholder: Images.placeholder,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Category name
                                Text(
                                  category.name ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: robotoRegular.copyWith(
                                    fontSize: 10,
                                    color: isSelected
                                        ? const Color(0xFF31A342)
                                        : AppColors.textColor,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Navigation tabs for subcategories
              if (subCategories.isNotEmpty)
                SliverToBoxAdapter(
                  child: GroceryCategoryTabs(
                    subCategories: subCategories,
                    selectedSubCategoryId: _selectedSubCategoryId,
                    onSubCategorySelected: _onSubCategorySelected,
                  ),
                ),
              // Promotional banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    0,
                  ),
                  child: GroceryCategoryBanner(
                    storeBanners: storeController.storeBanners ?? [],
                  ),
                ),
              ),
              // Product grid (2 columns)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeLarge,
                  ),
                  child: _isLoading
                      ? GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: Dimensions.paddingSizeSmall,
                            mainAxisSpacing: Dimensions.paddingSizeSmall,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: 6,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => const ItemShimmer(
                            isEnabled: true,
                            hasDivider: false,
                          ),
                        ) // ⚡ TASK 2: Instant skeleton morphing
                      : _hasLoadError && _items.isEmpty
                          ? ErrorStateView(
                              onRetry: () {
                                _loadCategoryItems(
                                  subCategoryId: _selectedSubCategoryId,
                                );
                              },
                            )
                      : GroceryProductGrid(
                          items: _items,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
