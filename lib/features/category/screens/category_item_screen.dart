
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/widgets/search_filter.dart';
import 'package:sixam_mart/features/category/widgets/category_filter_bar.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/widgets/category_selector_button.dart';
import 'package:sixam_mart/features/category/widgets/category_bottom_sheet.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

import '../../../common/widgets/loading/loading.dart';

class CategoryItemScreen extends StatefulWidget {
  final String? categoryID;
  final String categoryName;
  const CategoryItemScreen(
      {super.key, required this.categoryID, required this.categoryName});

  @override
  CategoryItemScreenState createState() => CategoryItemScreenState();
}

class CategoryItemScreenState extends State<CategoryItemScreen>
    with TickerProviderStateMixin {
  bool get _hideProductsTab => Get.find<SplashController>().module?.id != 3;
  final ScrollController scrollController = ScrollController();
  final ScrollController storeScrollController = ScrollController();
  TabController? _tabController;
  int _lastTabIndex = 0;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final subScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Find the category model to check cat_site_id
    final categoryController = Get.find<CategoryController>();
    categoryController.resetCategoryPagination(notify: false);
    if (widget.categoryID != null) {
      Future.microtask(() {
        categoryController
            .clearCacheForCategory(int.tryParse(widget.categoryID!));
      });
    }
    final splashController = Get.find<SplashController>();
    CategoryModel? category;

    if (categoryController.categoryList != null) {
      category = categoryController.categoryList!
          .firstWhereOrNull((cat) => cat.id.toString() == widget.categoryID);
    }

    // Default to items (index 0)
    int initialIndex = 0;
    bool isStore = false;

    // Only apply cuisine routing logic for modules 6, 7, 8 (Food, Groceries, Pharmacies)
    // Ecommerce and other modules should continue showing items by default
    final currentModuleId = splashController.module?.id;
    final shouldApplyCuisineRouting = currentModuleId != null &&
        (currentModuleId == 6 || currentModuleId == 7 || currentModuleId == 8);

    // Check if it's a cuisine category (position=0 AND cat_site_id <= 3 digits)
    // Per Module 6 API guide: Cuisines show stores, Menu Categories show items
    // Rule: position=0 AND cat_site_id <= 3 digits â†’ show STORES
    //       position > 0 OR cat_site_id > 3 digits â†’ show ITEMS
    // This only applies to Food, Groceries, and Pharmacy modules
    if (shouldApplyCuisineRouting && category != null) {
      // Check if position is available, otherwise fall back to catSiteId length check
      final hasPosition = category.position != null;
      final catSiteId = category.catSiteId;
      final hasCatSiteId = catSiteId != null && catSiteId.isNotEmpty;
      final bool isFoodModule = currentModuleId == 6;
      final bool missingCuisineMetadata = !hasPosition && !hasCatSiteId;
      final bool isModuleLevelCategory = category.storeId == null;
      final bool hasChildren = (category.childesCount ?? 0) > 0;
      final isCuisineCategory = hasPosition
          ? (category.position == 0 && (!hasCatSiteId || catSiteId.length <= 3))
          : (hasCatSiteId &&
              catSiteId.length <= 3); // Fallback if position not available
      final bool fallbackCuisineByModule = isFoodModule &&
          isModuleLevelCategory &&
          missingCuisineMetadata &&
          hasChildren;

      if (isCuisineCategory || fallbackCuisineByModule) {
        initialIndex = 1; // Stores tab
        isStore = true;
        if (kDebugMode) {
          debugPrint(
              'CategoryItemScreen: Module $currentModuleId - Detected cuisine category (id: ${category.id}, position: ${category.position}, cat_site_id: ${category.catSiteId}, store_id: ${category.storeId}) - showing stores');
          if (fallbackCuisineByModule) {
            debugPrint(
                '   Fallback cuisine detection: missing metadata + childesCount=${category.childesCount}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              'âœ… CategoryItemScreen: Module $currentModuleId - Detected Menu Category (id: ${category.id}, position: ${category.position}, cat_site_id: ${category.catSiteId}) - Showing Items');
        }
      }
    } else if (!shouldApplyCuisineRouting) {
      if (kDebugMode) {
        debugPrint(
            'âœ… CategoryItemScreen: Module $currentModuleId - Ecommerce/Other module - Showing Items by default');
      }
    } else if (category == null) {
      if (kDebugMode) {
        debugPrint(
            'âš ï¸ CategoryItemScreen: Category not found in categoryList (id: ${widget.categoryID}) - Defaulting to items tab');
        debugPrint(
            '   This might be a cuisine category - detection will be updated when childes response arrives');
      }
    } else if (kDebugMode &&
        (category.catSiteId == null || category.catSiteId!.isEmpty)) {
      debugPrint(
          'âš ï¸ CategoryItemScreen: Category found but missing catSiteId (id: ${category.id}, name: ${category.name}) - Defaulting to items tab');
    }

    // âœ… CRITICAL: Set _isStore IMMEDIATELY before postFrameCallback to prevent cache hits
    // This must happen before any async operations that might check cache
    if (_hideProductsTab) {
      initialIndex = 1;
      isStore = true;
    }
    categoryController.setRestaurant(isStore);

    _tabController =
        TabController(length: 2, initialIndex: initialIndex, vsync: this);
    _lastTabIndex = initialIndex;
    if (!_hideProductsTab) {
      _tabController!.addListener(() {
      if (_tabController == null || _tabController!.indexIsChanging) return;
      if (_tabController!.index == _lastTabIndex) return;
      _lastTabIndex = _tabController!.index;

      categoryController.setRestaurant(_tabController!.index == 1);
      if (!categoryController.isSearching) {
        if (_tabController!.index == 1) {
          categoryController.getCategoryStoreList(
            categoryController.subCategoryIndex == 0
                ? widget.categoryID
                : categoryController
                    .subCategoryList![categoryController.subCategoryIndex].id
                    .toString(),
            1,
            categoryController.type,
            false,
          );
        } else {
          categoryController.getCategoryItemList(
            categoryController.subCategoryIndex == 0
                ? widget.categoryID
                : categoryController
                    .subCategoryList![categoryController.subCategoryIndex].id
                    .toString(),
            1,
            categoryController.type,
            false,
            includeChildren: categoryController.subCategoryIndex == 0,
          );
        }
      }
      });
    }

    // âš¡ MANDATORY CALL: getSubCategoryList MUST be called on every screen entry
    // This ensures subcategories are always loaded, regardless of cache or previous state
    // Defer to postFrameCallback to avoid build errors, but ALWAYS execute
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ðŸ”¥ CRITICAL: Always call getSubCategoryList - no conditions, no checks
      // This is the root cause fix - ensures API call happens every time
      if (widget.categoryID != null && widget.categoryID!.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
              'ðŸ“ž CategoryItemScreen: Calling getSubCategoryList for categoryId: ${widget.categoryID}');
        }
        categoryController.getSubCategoryList(
          widget.categoryID,
          forceRefreshItems: true,
          fetchItems: !isStore && !_hideProductsTab,
        );
      } else if (kDebugMode) {
        debugPrint(
            'âš ï¸ CategoryItemScreen: categoryID is null or empty, skipping getSubCategoryList');
      }

      // Preload stores count/list on first open so the stores tab count
      // is accurate before the user taps it.
      if (isStore || _hideProductsTab) {
        categoryController.getCategoryStoreList(
            widget.categoryID, 1, categoryController.type, false);
        if (!_hideProductsTab) {
          // Preload item data for Tab 2 so both tabs have counts/content ready.
          categoryController.getCategoryItemList(
            widget.categoryID,
            1,
            categoryController.type,
            false,
            includeChildren: true,
            forceRefresh: true,
            allowWhenStore: true,
          );
        }
      } else {
        // For all modules, preload stores in background so the stores count
        // appears immediately instead of showing 0 until tab click.
        if (kDebugMode) {
          debugPrint(
              'CategoryItemScreen: Preloading stores in background (categoryId: ${widget.categoryID}, moduleId: $currentModuleId)');
        }
        categoryController.getCategoryStoreList(
            widget.categoryID, 1, categoryController.type, false);
      }
    });

    scrollController.addListener(() {
      final categoryController = Get.find<CategoryController>();
      if (categoryController.isSearching) {
        if (scrollController.position.pixels ==
                scrollController.position.maxScrollExtent &&
            !categoryController.isLoading &&
            categoryController.hasMoreSearchResults) {
          categoryController.loadMoreSearchResults();
        }
        return;
      }
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          categoryController.categoryItemList != null &&
          !categoryController.isLoading) {
        final int pageSize = (categoryController.pageSize! / 10).ceil();
        if (categoryController.offset < pageSize) {
          if (kDebugMode) {
            debugPrint('end of the page');
          }
          categoryController.showBottomLoader();
          categoryController.getCategoryItemList(
            categoryController.subCategoryIndex == 0
                ? widget.categoryID
                : categoryController
                    .subCategoryList![categoryController.subCategoryIndex].id
                    .toString(),
            categoryController.offset + 1,
            categoryController.type,
            false,
            includeChildren:
                categoryController.subCategoryIndex == 0 ? true : false,
          );
        }
      }
    });
    storeScrollController.addListener(() {
      final catController = Get.find<CategoryController>();
      if (storeScrollController.position.pixels ==
              storeScrollController.position.maxScrollExtent &&
          catController.categoryStoreList != null &&
          !catController.isLoading) {
        // Check if we've loaded all stores by comparing loaded count vs totalSize
        final loadedCount = catController.categoryStoreList!.length;
        final totalSize = catController.restPageSize ?? 0;
        if (loadedCount < totalSize) {
          if (kDebugMode) {
            debugPrint(
                'end of the page - loading more stores: $loadedCount/$totalSize');
          }
          catController.showBottomLoader();
          catController.getCategoryStoreList(
            catController.subCategoryIndex == 0
                ? widget.categoryID
                : catController
                    .subCategoryList![catController.subCategoryIndex].id
                    .toString(),
            catController.offset + 1,
            catController.type,
            false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().resetFilterState(notify: false);
    }
    scrollController.dispose();
    storeScrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void openFilterSheet({
    required BuildContext context,
    required String categoryId,
  }) {
    Get.bottomSheet<void>(
      SearchFilter(categoryID: categoryId),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  List<Item> _applyLocalItemFilters(
      CategoryController controller, List<Item> items) {
    debugPrint('[CAT_FILTER][CLIENT_FILTER_START] count=${items.length}');
    if (controller.isSearching) {
      debugPrint(
          '[CAT_FILTER][CLIENT_FILTER_RESULT] before=${items.length} after=${items.length}');
      return List<Item>.from(items);
    }
    final splashController = Get.find<SplashController>();
    final bool isEcommerceModule =
        splashController.module?.moduleType == AppConstants.ecommerce ||
            splashController.module?.id == 3;

    // Hyper module search should mirror global search breadth.
    // Do not trim search results by local stock filter.
    final List<Item> filtered = (controller.isSearching && isEcommerceModule)
        ? List<Item>.from(items)
        : items.where((e) => (e.stock ?? 0) != 0).toList();

    final double? minPrice = controller.currentMinPrice.isNotEmpty
        ? double.tryParse(controller.currentMinPrice)
        : null;
    final double? maxPrice = controller.currentMaxPrice.isNotEmpty
        ? double.tryParse(controller.currentMaxPrice)
        : null;

    if (minPrice != null && minPrice > 0) {
      filtered.removeWhere((item) => (item.price ?? 0) < minPrice);
    }
    if (maxPrice != null && maxPrice > 0) {
      filtered.removeWhere((item) => (item.price ?? 0) > maxPrice);
    }

    if (controller.currentHasDiscount) {
      filtered.removeWhere((item) => (item.discount ?? 0) <= 0);
    }

    final String nameQuery = controller.currentSearchName.trim().toLowerCase();
    if (nameQuery.isNotEmpty && nameQuery != ' ') {
      filtered.removeWhere((item) {
        final String itemName = (item.name ?? '').toLowerCase();
        final bool matches = itemName.contains(nameQuery);
        if (!matches) {
          debugPrint(
              '[CAT_FILTER][CLIENT_FILTER_REMOVED] id=${item.id} name=${item.name ?? ''} reason=name_mismatch');
        }
        return !matches;
      });
    }

    // Preserve pagination order when loading more pages.
    if (controller.offset <= 1) {
      final String arrangement = controller.currentProductArrangement;
      if (arrangement == 'ascending' || arrangement == 'descending') {
        filtered.sort((a, b) {
          final String nameA = (a.name ?? '').toLowerCase();
          final String nameB = (b.name ?? '').toLowerCase();
          return arrangement == 'ascending'
              ? nameA.compareTo(nameB)
              : nameB.compareTo(nameA);
        });
      } else {
        filtered.sort((a, b) => controller.isPriceAscending
            ? (a.price ?? 0).compareTo(b.price ?? 0)
            : (b.price ?? 0).compareTo(a.price ?? 0));
      }
    }

    debugPrint(
        '[CAT_FILTER][CLIENT_FILTER_RESULT] before=${items.length} after=${filtered.length}');
    return filtered;
  }

  String _buildNoItemFoundText(CategoryController controller) {
    final String query = controller.currentSearchName.trim();
    if (query.isNotEmpty) {
      return '${'no_results_found'.tr} "$query"\n'
          '${'try_another_keyword_or_reset_filter'.tr}';
    }
    return 'no_category_item_found'.tr;
  }

  bool _shouldShowNoResultResetButton(CategoryController controller) {
    return controller.currentSearchName.trim().isNotEmpty;
  }

  void _resetCategoryFilters(CategoryController catController) {
    final String categoryId = catController.subCategoryIndex == 0
        ? (widget.categoryID ?? '')
        : catController.subCategoryList![catController.subCategoryIndex].id
            .toString();
    catController.resetFilterState(notify: false);
    catController.getCategoryItemList(
      categoryId,
      1,
      catController.type,
      false,
      includeChildren: catController.subCategoryIndex == 0,
      forceRefresh: true,
    );
  }

  void applyQuickFilter({
    required CategoryController controller,
    required String categoryId,
    required String productArrangement,
    required bool hasDiscount,
  }) {
    controller.applyFilters(
      research_Name: ' ',
      product_arrangement: productArrangement,
      id_category: categoryId,
      id_stores: '',
      discount: hasDiscount,
      min: '0',
      max: '0',
      fromHome: true,
    );
  }

  Widget buildQuickFilterTile({
    required BuildContext context,
    required IconData iconData,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeExtraSmall,
        ),
        margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 22,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              label,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  CategoryModel? findCategoryById({
    required List<CategoryModel>? categories,
    required String? categoryId,
  }) {
    if (categories == null || categoryId == null) {
      return null;
    }
    for (final CategoryModel category in categories) {
      if (category.id.toString() == categoryId) {
        return category;
      }
      final List<CategoryModel>? subCategories = category.subCategories;
      if (subCategories != null && subCategories.isNotEmpty) {
        final CategoryModel? match = findCategoryById(
          categories: subCategories,
          categoryId: categoryId,
        );
        if (match != null) {
          return match;
        }
      }
    }
    return null;
  }

  /// âš¡ Skeleton loader for subcategories while loading
  Widget _buildSubCategorySkeleton(BuildContext context) {
    return Center(
      child: Container(
        height: 120,
        width: Dimensions.webMaxWidth,
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeExtraSmall),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
          physics: const BouncingScrollPhysics(),
          itemCount: 4, // Show 4 skeleton items
          itemBuilder: (context, index) {
            return Container(
              width: 80,
              margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                  SizedBox(height: Dimensions.fontSizeSmall),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// âœ… DATA-DRIVEN: Recursive subcategory rendering for infinite browsing depth
  /// Uses sub_categories metadata from backend API response
  /// âš¡ PERFORMANCE: Always shows "All" button, loads subcategories in background
  Widget _buildRecursiveCategoryTiles({
    required BuildContext context,
    required CategoryController categoryController,
    required String parentCategoryId,
    int depth = 0,
  }) {
    // Find current category from categoryList
    CategoryModel? currentCategory;
    if (categoryController.categoryList != null) {
      currentCategory = categoryController.categoryList!.firstWhereOrNull(
        (cat) => cat.id.toString() == parentCategoryId,
      );
    }

    // âœ… Priority 1: Use sub_categories from API metadata (data-driven)
    List<CategoryModel>? subCategoriesToRender;
    if (currentCategory?.subCategories != null &&
        currentCategory!.subCategories!.isNotEmpty) {
      subCategoriesToRender = currentCategory.subCategories!
          .where((subCat) =>
              subCat.productsCount > 0 ||
              (subCat.subCategories != null &&
                  subCat.subCategories!.isNotEmpty))
          .toList();
    }
    // âœ… Priority 2: Fallback to controller's subCategoryList (for backward compatibility)
    else if (categoryController.subCategoryList != null &&
        categoryController.subCategoryList!.isNotEmpty &&
        depth == 0) {
      subCategoriesToRender = categoryController.subCategoryList;
    }

    // âš¡ ALWAYS SHOW: Even if subcategories are loading or empty, show "All" button
    // This ensures UI consistency and prevents flickering
    if (subCategoriesToRender == null || subCategoriesToRender.isEmpty) {
      // Show skeleton while loading (only for top level)
      if (depth == 0 && subCategoriesToRender == null) {
        return _buildSubCategorySkeleton(context);
      }
      // If empty (not loading), show at least "All" button
      if (depth == 0) {
        subCategoriesToRender = [
          CategoryModel(
              id: int.tryParse(parentCategoryId) ?? 0, name: 'all'.tr),
        ];
      } else {
        return const SizedBox.shrink();
      }
    }

    final List<CategoryModel> visibleSubCategories =
        List<CategoryModel>.from(subCategoriesToRender);
    return Column(
      children: [
        // Current level subcategories - horizontal scrollable list
        Center(
          child: Container(
            height: depth == 0
                ? 120
                : 70, // Taller for first level, shorter for nested
            width: Dimensions.webMaxWidth,
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeExtraSmall),
            child: ListView.builder(
              key: depth == 0 ? scaffoldKey : null,
              scrollDirection: Axis.horizontal,
              itemCount: visibleSubCategories.length,
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                // âš ï¸ UI REQUIREMENT: Only "all" (subcategories) should be visible
                // Do NOT re-add discounts / popular / filter buttons
                // Removed filter buttons (filter, popular, discounts) - only showing subcategories now
                // Safe access - we already checked subCategoriesToRender is not null above
                final subCategory = visibleSubCategories[index];
                final isSelected =
                    depth == 0 && index == categoryController.subCategoryIndex;

                return InkWell(
                  onTap: () {
                    if (depth == 0) {
                      // Top-level subcategory: Use existing logic
                      categoryController.setSubCategoryIndex(
                          index, parentCategoryId);
                    } else {
                      // âœ… RECURSIVE NAVIGATION: Navigate to deeper level using pre-fetched data
                      // This achieves 0ms navigation delay by using sub_categories from API metadata
                      final subCategory = subCategoriesToRender![index];
                      Get.toNamed<void>(
                        RouteHelper.getCategoryItemRoute(
                          subCategory.id,
                          subCategory.name ?? '',
                        ),
                      );
                      // Note: The new screen will use pre-fetched sub_categories from the category model
                      // No additional API call needed - data is already in categoryList
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    margin: const EdgeInsets.only(
                        right: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                      color: isSelected
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        subCategory.imageFullUrl != null &&
                                subCategory.imageFullUrl!.isNotEmpty
                            ? CustomImage(
                                image: subCategory.imageFullUrl ?? '',
                                height: 50,
                                width: 50,
                                placeholder: Images.placeholder,
                              )
                            : Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .disabledColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSmall),
                                ),
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  size: 24,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                        SizedBox(height: Dimensions.fontSizeSmall),
                        Text(
                          subCategory.name ?? '',
                          style: isSelected
                              ? robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).primaryColor,
                                )
                              : robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Recursively render nested subcategories if they exist
        ...subCategoriesToRender.map((subCategory) {
          if (subCategory.subCategories != null &&
              subCategory.subCategories!.isNotEmpty) {
            return _buildRecursiveCategoryTiles(
              context: context,
              categoryController: categoryController,
              parentCategoryId: subCategory.id.toString(),
              depth: depth + 1,
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (catController) {
      // ðŸŽ¯ PERFORMANCE: Use pre-computed getters from controller
      // No calculations (.addAll, condition checks) in build()
      final List<Item>? item = catController.displayItemList;
      final List<Store>? stores = catController.displayStoreList;

      final CategoryModel? resolvedCategory = findCategoryById(
        categories: catController.categoryList,
        categoryId: widget.categoryID,
      );
      final bool navigateItemToStoreOnTap =
          Get.find<SplashController>().module?.moduleType.toString() ==
              AppConstants.food;
      final SplashController splashController = Get.find<SplashController>();
      final bool isFoodModule =
          splashController.module?.moduleType.toString() == AppConstants.food;
      final bool showRestaurantText = isFoodModule &&
          (splashController
                  .configModel?.moduleConfig?.module?.showRestaurantText ??
              false);
      final bool hasCategoryDataMissing =
          (catController.isStore && (stores == null || stores.isEmpty)) ||
              (!catController.isStore && (item == null || item.isEmpty));
      final bool showCategoryError =
          (catController.hasCategoryError || !splashController.hasConnection) &&
          !catController.isLoading &&
          hasCategoryDataMissing;
      final List<Item> filteredDisplayItems = _applyLocalItemFilters(
        catController,
        (catController.isSearching
                ? catController.searchItemList
                : catController.categoryItemList) ??
            <Item>[],
      );
      debugPrint('[CAT_FILTER][DISPLAY_LIST_COUNT] ${filteredDisplayItems.length}');
      if (!catController.isStore &&
          !catController.isLoading &&
          filteredDisplayItems.isEmpty) {
        final String emptyReason = catController.isSearching
            ? 'search_results_empty_after_display'
            : 'category_items_empty';
        debugPrint('[CAT_FILTER][EMPTY_STATE_SHOWN] reason=$emptyReason');
      }
      return PopScope(
        onPopInvokedWithResult: (didPop, result) async {
          if (catController.isSearching) {
            catController.toggleSearch(context);
          } else {
            return;
          }
        },
        child: Scaffold(
          key: ValueKey('category_${widget.categoryID ?? "null"}'),
          appBar: (ResponsiveHelper.isDesktop(context)
              ? const WebMenuBar()
              : AppBar(
                  backgroundColor: Theme.of(context).cardColor,
                  surfaceTintColor: Theme.of(context).cardColor,
                  shadowColor:
                      Theme.of(context).disabledColor.withValues(alpha: 0.5),
                  elevation: 2,
                  title: catController.categoryList != null
                      ? CategorySelectorButton(
                          currentCategory: resolvedCategory,
                          onTap: () {
                            if (catController.categoryList != null) {
                              Get.bottomSheet<void>(
                                CategoryBottomSheet(
                                  categoryList: catController.categoryList!,
                                  currentCategory: resolvedCategory,
                                  onCategorySelected:
                                      (CategoryModel selectedCategory) {
                                    Get.back<void>();
                                    Get.toNamed<void>(
                                      RouteHelper.getCategoryItemRoute(
                                        selectedCategory.id,
                                        selectedCategory.name ?? '',
                                      ),
                                    );
                                  },
                                ),
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                              );
                            }
                          },
                        )
                      : Text(widget.categoryName,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          )),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    onPressed: () {
                      // if (catController.isSearching) {
                      //   catController.toggleSearch(context);
                      // } else {
                      Get.back<void>();
                      // }
                    },
                  ),

                  // ===================================================================================

                  actions: [
                    // Search icon temporarily hidden for debugging.
                    IconButton(
                      onPressed: () =>
                          Get.toNamed<void>(RouteHelper.getCartRoute()),
                      icon: CartWidget(
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                          size: 25),
                    ),
                    // VegFilterWidget(
                    //     type: catController.type,
                    //     fromAppBar: true,
                    //     onSelected: (String type) {
                    //       if (catController.isSearching) {
                    //         // catController.searchData(
                    //         //   null,
                    //         //   catController.subCategoryIndex == 0
                    //         //       ? widget.categoryID
                    //         //       : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                    //         //   '1',
                    //         //   type,
                    //         // );
                    //       } else {
                    //         if (catController.isStore) {
                    //           catController.getCategoryStoreList(
                    //             catController.subCategoryIndex == 0
                    //                 ? widget.categoryID
                    //                 : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                    //             1,
                    //             type,
                    //             true,
                    //           );
                    //         } else {
                    //           catController.getCategoryItemList(
                    //             catController.subCategoryIndex == 0
                    //                 ? widget.categoryID
                    //                 : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                    //             1,
                    //             type,
                    //             true,
                    //           );
                    //         }
                    //       }
                    //     }),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                  ],
                )),
          body: showCategoryError
              ? ErrorStateView(
                  onRetry: () {
                    if (catController.isStore) {
                      catController.getCategoryStoreList(
                        catController.subCategoryIndex == 0
                            ? widget.categoryID
                            : catController
                                .subCategoryList![catController.subCategoryIndex]
                                .id
                                .toString(),
                        1,
                        catController.type,
                        true,
                      );
                    } else {
                      catController.getCategoryItemList(
                        catController.subCategoryIndex == 0
                            ? widget.categoryID
                            : catController
                                .subCategoryList![catController.subCategoryIndex]
                                .id
                                .toString(),
                        1,
                        catController.type,
                        true,
                        includeChildren: catController.subCategoryIndex == 0,
                        forceRefresh: true,
                      );
                    }
                  },
                )
              : ResponsiveHelper.isDesktop(context)
              ? SingleChildScrollView(
                  child: FooterView(
                    child: Center(
                        child: SizedBox(
                      width: Dimensions.webMaxWidth,
                      child: Column(children: [
                        (catController.subCategoryList != null &&
                                !catController.isSearching &&
                                catController.subCategoryList!.isNotEmpty)
                            ? Center(
                                child: Container(
                                height: 40,
                                width: Dimensions.webMaxWidth,
                                color: Theme.of(context).cardColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingSizeExtraSmall),
                                child: ListView.builder(
                                  key: scaffoldKey,
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      catController.subCategoryList!.length,
                                  padding: const EdgeInsets.only(
                                      left: Dimensions.paddingSizeSmall),
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () =>
                                          catController.setSubCategoryIndex(
                                              index, widget.categoryID),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeSmall,
                                            vertical: Dimensions
                                                .paddingSizeExtraSmall),
                                        margin: const EdgeInsets.only(
                                            right: Dimensions.paddingSizeSmall),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.radiusSmall),
                                          color: index ==
                                                  catController.subCategoryIndex
                                              ? Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.1)
                                              : Colors.transparent,
                                        ),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                catController
                                                    .subCategoryList![index]
                                                    .name!,
                                                style: index ==
                                                        catController
                                                            .subCategoryIndex
                                                    ? robotoMedium.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall,
                                                        color: Theme.of(context)
                                                            .primaryColor)
                                                    : robotoRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall),
                                              ),
                                            ]),
                                      ),
                                    );
                                  },
                                ),
                              ))
                            : const SizedBox(),
                        Center(
                            child: Container(
                          width: Dimensions.webMaxWidth,
                          color: Theme.of(context).cardColor,
                          child: _hideProductsTab
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingSizeSmall,
                                  ),
                                  child: Center(
                                    child: Text(
                                      showRestaurantText
                                          ? 'restaurants'.tr
                                          : 'stores'.tr,
                                      style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                )
                              : TabBar(
                                  controller: _tabController,
                                  indicatorColor: Theme.of(context).primaryColor,
                                  indicatorWeight: 3,
                                  labelColor: Theme.of(context).primaryColor,
                                  unselectedLabelColor:
                                      Theme.of(context).disabledColor,
                                  unselectedLabelStyle: robotoRegular.copyWith(
                                      color: Theme.of(context).disabledColor,
                                      fontSize: Dimensions.fontSizeSmall),
                                  labelStyle: robotoBold.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).primaryColor),
                                  tabs: [
                                    Tab(text: 'item'.tr),
                                    Tab(
                                      text: showRestaurantText
                                          ? 'restaurants'.tr
                                          : 'stores'.tr,
                                    ),
                                  ],
                                ),
                        )),
                        SizedBox(
                          height: 600,
                          child: _hideProductsTab
                              ? SingleChildScrollView(
                                  controller: storeScrollController,
                                  child: ItemsView(
                                    isStore: true,
                                    items: null,
                                    stores: stores,
                                    noDataText: showRestaurantText
                                        ? 'no_category_restaurant_found'.tr
                                        : 'no_category_store_found'.tr,
                                  ),
                                )
                              : TabBarView(
                                  controller: _tabController,
                                  children: [
                                    SingleChildScrollView(
                                      controller: scrollController,
                                      child: ItemsView(
                                        isStore: false,
                                        items: item,
                                        stores: null,
                                        navigateItemToStoreOnTap:
                                            navigateItemToStoreOnTap,
                                        noDataText:
                                            _buildNoItemFoundText(catController),
                                        noDataActionText:
                                            _shouldShowNoResultResetButton(
                                                    catController)
                                                ? 'reset'.tr
                                                : null,
                                        onNoDataActionTap:
                                            _shouldShowNoResultResetButton(
                                                    catController)
                                                ? () => _resetCategoryFilters(
                                                    catController)
                                                : null,
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      controller: storeScrollController,
                                      child: ItemsView(
                                        isStore: true,
                                        items: null,
                                        stores: stores,
                                        noDataText: showRestaurantText
                                            ? 'no_category_restaurant_found'.tr
                                            : 'no_category_store_found'.tr,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        (catController.isLoading &&
                                ((catController.isStore &&
                                        catController.categoryStoreList !=
                                            null) ||
                                    (!catController.isStore &&
                                        catController.categoryItemList !=
                                            null)))
                            ? Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeSmall),
                                child: Center(
                                  child: Text(
                                    catController.isStore
                                        ? 'loading_more_stores'.tr
                                        : 'loading_more_items'.tr,
                                    style: robotoRegular.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ]),
                    )),
                  ),
                )
              : SizedBox(
                  width: Dimensions.webMaxWidth,
                  child: Column(children: [
                    // Ø§Ù„Ø¬Ù…ÙŠØ¹  =========================================================================

                    const SizedBox(height: 10),

                    // âœ… DATA-DRIVEN: Recursive subcategory rendering from backend metadata
                    // âš¡ PERFORMANCE: Reactive update only for subcategories section
                    if (widget.categoryID != null)
                      GetBuilder<CategoryController>(
                        id: 'sub_categories',
                        builder: (controller) => _buildRecursiveCategoryTiles(
                          context: context,
                          categoryController: controller,
                          parentCategoryId: widget.categoryID!,
                        ),
                      ),

                    // Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª  =========================================================================

                    const SizedBox(height: 10),

                    // âœ… Ø´Ø±ÙŠØ· Ø§Ù„ÙÙ„Ø§ØªØ± Ø§Ù„Ø¬Ø¯ÙŠØ¯
                    if (widget.categoryID != null)
                      CategoryFilterBar(
                        categoryID: catController.subCategoryIndex == 0
                            ? widget.categoryID!
                            : catController
                                .subCategoryList![
                                    catController.subCategoryIndex]
                                .id
                                .toString(),
                      ),

                    const SizedBox(height: 10),

                    // =========================================================================

                    Center(
                        child: Container(
                      width: Dimensions.webMaxWidth,
                      color: Theme.of(context).cardColor,
                      child: Builder(builder: (_) {
                        final bool itemsCountLoading = !catController.isStore &&
                            catController.isLoading &&
                            item == null;
                        final bool storesCountLoading = catController.isStore &&
                            catController.isLoading &&
                            stores == null;
                        final String itemsCountText = itemsCountLoading
                            ? '...'
                            : '${catController.pageSize ?? (item?.length ?? 0)}';
                        final String storesCountText = storesCountLoading
                            ? '...'
                            : '${catController.restPageSize ?? (stores?.length ?? 0)}';
                        if (_hideProductsTab) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    showRestaurantText
                                        ? 'restaurants'.tr
                                        : 'stores'.tr,
                                    style: robotoBold.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    storesCountText,
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return TabBar(
                          controller: _tabController,
                          indicatorColor: Theme.of(context).primaryColor,
                          indicatorWeight: 3,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Theme.of(context).disabledColor,
                          unselectedLabelStyle: robotoRegular.copyWith(
                              color: Theme.of(context).disabledColor,
                              fontSize: Dimensions.fontSizeSmall),
                          labelStyle: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).primaryColor),
                          tabs: [
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tab(text: 'item'.tr),
                                  SizedBox(width: Dimensions.fontSizeSmall),
                                  Text(
                                    itemsCountText,
                                    style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tab(
                                    text: showRestaurantText
                                        ? 'restaurants'.tr
                                        : 'stores'.tr,
                                  ),
                                  SizedBox(width: Dimensions.fontSizeSmall),
                                  Text(
                                    storesCountText,
                                    style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    )),

                    // ===================================

                    ((!catController.isStore && item == null) ||
                            (catController.isStore && stores == null))
                        ? Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeSmall),
                                child: LoadingWidget(
                                  messageKey: catController.isStore
                                      ? 'bringing_great_stores'
                                      : 'bringing_great_products',
                                ),
                              ),
                            ),
                          )
                        : Expanded(
                            child: _hideProductsTab
                                ? SingleChildScrollView(
                                    controller: storeScrollController,
                                    child: ItemsView(
                                      isStore: true,
                                      items: null,
                                      stores: stores,
                                      verticalItem: catController.isVertical,
                                      noDataText: showRestaurantText
                                          ? 'no_category_restaurant_found'.tr
                                          : 'no_category_store_found'.tr,
                                    ),
                                  )
                                : TabBarView(
                                    controller: _tabController,
                                    children: [
                                      SingleChildScrollView(
                                        controller: scrollController,
                                        child: ItemsView(
                                          isStore: false,
                                          items: filteredDisplayItems,
                                          stores: null,
                                          verticalItem: catController.isVertical,
                                          navigateItemToStoreOnTap:
                                              navigateItemToStoreOnTap,
                                          noDataText:
                                              _buildNoItemFoundText(catController),
                                          noDataActionText:
                                              _shouldShowNoResultResetButton(
                                                      catController)
                                                  ? 'reset'.tr
                                                  : null,
                                          onNoDataActionTap:
                                              _shouldShowNoResultResetButton(
                                                      catController)
                                                  ? () => _resetCategoryFilters(
                                                      catController)
                                                  : null,
                                        ),
                                      ),
                                      SingleChildScrollView(
                                        controller: storeScrollController,
                                        child: ItemsView(
                                          isStore: true,
                                          items: null,
                                          stores: stores,
                                          verticalItem: catController.isVertical,
                                          noDataText: showRestaurantText
                                              ? 'no_category_restaurant_found'.tr
                                              : 'no_category_store_found'.tr,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),

                    (catController.isLoading &&
                            ((catController.isStore &&
                                    catController.categoryStoreList != null) ||
                                (!catController.isStore &&
                                    catController.categoryItemList != null)))
                        ? Center(
                            child: Padding(
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            child: Text(
                              catController.isStore
                                  ? 'loading_more_stores'.tr
                                  : 'loading_more_items'.tr,
                              style: robotoRegular.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ))
                        : const SizedBox(),
                  ]),
                ),
        ),
      );
    });
  }
}
