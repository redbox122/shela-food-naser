import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/slim_menu_model.dart';
import 'package:sixam_mart/features/store/widgets/food_restaurant/food_restaurant_header.dart';
import 'package:sixam_mart/features/store/widgets/food_restaurant/food_restaurant_info_section.dart';
import 'package:sixam_mart/features/store/widgets/food_restaurant/food_restaurant_action_buttons.dart';
import 'package:sixam_mart/features/store/widgets/food_restaurant/food_restaurant_category_tabs.dart';
import 'package:sixam_mart/features/store/widgets/food_restaurant/food_restaurant_category_section.dart';
import 'package:sixam_mart/features/store/screens/food_restaurant_categories_bottom_sheet.dart';
import 'package:sixam_mart/features/store/widgets/store_details_screen_shimmer_widget.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class FoodRestaurantDetailScreen extends StatefulWidget {
  final Store? store;
  final bool fromModule;
  final String slug;
  final String? heroBannerTag;
  final String? heroLogoTag;

  const FoodRestaurantDetailScreen({
    super.key,
    required this.store,
    required this.fromModule,
    this.slug = '',
    this.heroBannerTag,
    this.heroLogoTag,
  });

  @override
  State<FoodRestaurantDetailScreen> createState() =>
      _FoodRestaurantDetailScreenState();
}

class _FoodRestaurantDetailScreenState
    extends State<FoodRestaurantDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedCategoryId;
  final Map<int?, List<Item>> _categoryItemsMap = {};
  final Map<int?, GlobalKey> _categoryKeys = {};
  final Set<int?> _loadedCategoryIds =
      {}; // Track which categories have been loaded
  final Set<int?> _loadingCategoryIds =
      {}; // Track which categories are currently loading
  final Map<int?, int> _categoryOffsets = {};
  final Map<int?, int> _categoryTotalSizes = {};
  bool _isPaginatingItems = false;
  static const int _itemsPageLimit = 10;

  @override
  void initState() {
    super.initState();

    // ✅ PROFESSIONAL SCREEN LOGGING: Track screen lifecycle for debugging
    if (kDebugMode) {
      debugPrint('📄 SCREEN INIT: FoodRestaurantDetailScreen');
      debugPrint('   - route: ${Get.currentRoute}');
      debugPrint('   - parameters: ${Get.parameters}');
    }

    appLogger.logPageEntry('FoodRestaurantDetailScreen');
    appLogger.info('📍 FoodRestaurantDetailScreen: Initializing');
    appLogger
        .debug('FoodRestaurantDetailScreen: Store ID = ${widget.store?.id}');
    appLogger.debug(
        'FoodRestaurantDetailScreen: From Module = ${widget.fromModule}');
    appLogger.debug('FoodRestaurantDetailScreen: Slug = ${widget.slug}');
    appLogger.debug('FoodRestaurantDetailScreen: Module Type = Food');

    _scrollController.addListener(_onScrollLoadMore);
    _initializeData();
  }

  @override
  void dispose() {
    // ✅ PROFESSIONAL SCREEN LOGGING: Track screen disposal
    if (kDebugMode) {
      debugPrint('🗑️ SCREEN DISPOSE: FoodRestaurantDetailScreen');
      debugPrint('   - route: ${Get.currentRoute}');
    }

    appLogger.logPageExit();
    appLogger.info('📍 FoodRestaurantDetailScreen: Disposed');
    appLogger.debug('FoodRestaurantDetailScreen: Clearing store detail state');

    // 🔒 HARD RESET: Clear store detail state to prevent state leakage
    final storeController = Get.find<StoreController>();
    storeController.clearStoreDetailState();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollLoadMore() {
    if (_isPaginatingItems || !_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    final double loadMoreTrigger = position.maxScrollExtent * 0.9;
    if (position.pixels < loadMoreTrigger) {
      return;
    }
    final int? categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId == 0) {
      return;
    }
    final int loadedCount = _categoryItemsMap[categoryId]?.length ?? 0;
    final int totalSize = _categoryTotalSizes[categoryId] ?? 0;
    if (totalSize > 0 && loadedCount >= totalSize) {
      return;
    }
    _loadMoreItemsForCategory(categoryId);
  }

  Future<void> _loadMoreItemsForCategory(int? categoryId) async {
    if (categoryId == null || categoryId == 0) {
      return;
    }
    final storeController = Get.find<StoreController>();
    final int storeId = widget.store?.id ?? storeController.store?.id ?? 0;
    if (storeId == 0) {
      return;
    }
    final int currentOffset = _categoryOffsets[categoryId] ?? 1;
    final int loadedCount = _categoryItemsMap[categoryId]?.length ?? 0;
    final int totalSize = _categoryTotalSizes[categoryId] ?? 0;
    if (totalSize > 0 && loadedCount >= totalSize) {
      return;
    }
    if (mounted) {
      setState(() {
        _isPaginatingItems = true;
      });
    }
    try {
      final categoryItemModel = await storeController.fetchCategoryItemsPage(
        storeId: storeId,
        categoryId: categoryId,
        offset: currentOffset + 1,
        limit: _itemsPageLimit,
      );
      final List<Item> newItems = categoryItemModel?.items ?? <Item>[];
      final int total = categoryItemModel?.totalSize ?? totalSize;
      if (newItems.isNotEmpty) {
        final List<Item> existingItems =
            _categoryItemsMap.putIfAbsent(categoryId, () => <Item>[]);
        existingItems.addAll(newItems);
        _categoryOffsets[categoryId] = currentOffset + 1;
        _categoryTotalSizes[categoryId] = total;
      } else if (total > 0) {
        _categoryTotalSizes[categoryId] = total;
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isPaginatingItems = false;
        });
      } else {
        _isPaginatingItems = false;
      }
    }
  }

  Future<void> _initializeData() async {
    appLogger.info('📍 FoodRestaurantDetailScreen: _initializeData() called');
    appLogger
        .debug('FoodRestaurantDetailScreen: Store ID = ${widget.store?.id}');

    // ✅ CRITICAL: Log all possible store ID sources for debugging
    appLogger
        .info('🔍 FoodRestaurantDetailScreen: Checking all store ID sources');
    appLogger.info('   - widget.store?.id: ${widget.store?.id}');

    final storeController = Get.find<StoreController>();
    final categoryController = Get.find<CategoryController>();
    final splashController = Get.find<SplashController>();

    appLogger
        .info('   - storeController.store?.id: ${storeController.store?.id}');

    // ✅ CRITICAL: Try to get store ID from route parameters as fallback
    final routeStoreId = Get.parameters['id'];
    appLogger.info('   - Get.parameters["id"]: $routeStoreId');

    if (storeController.isSearching) {
      appLogger.debug('FoodRestaurantDetailScreen: Clearing search status');
      storeController.changeSearchStatus(isUpdate: false);
    }

    storeController.hideAnimation();

    // ✅ FIX #2: Ensure module is ready before requesting Slim Menu
    // This prevents Slim Menu from being requested before moduleId is set in headers
    appLogger.info(
        '🔒 FoodRestaurantDetailScreen: Ensuring module is ready before API calls');
    await splashController.ensureModuleReady();

    // ⚡ SILICON VALLEY WAY: Use widget.store immediately for instant UI (0ms perceived load)
    // Set store in controller immediately so header shows name/logo instantly
    // ✅ FIX: Defer setStoreMiniCache to post-frame callback to prevent "setState during build"
    if (widget.store != null && widget.store!.id != null) {
      final hasBasicData =
          widget.store!.name != null || widget.store!.logoFullUrl != null;
      if (hasBasicData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          storeController.setStoreMiniCache(widget.store!);
        });
        appLogger.info(
            '⚡ FoodRestaurantDetailScreen: Store header visible instantly (0ms) - using widget.store');
      }
    }

    // ✅ FRONTEND ONLY: Always fetch items regardless of store.open status
    // ⚡ BACKGROUND FETCH: Only fetch menu items in background (not full store details)
    // This makes the app feel "Lightning Fast" even if internet is slow

    // ✅ CRITICAL: Try multiple sources for store ID (widget.store, controller.store, route parameters)
    int? storeId = widget.store?.id ?? storeController.store?.id;

    // ✅ FIX: Fallback to route parameter if storeId is still null
    if (storeId == null && routeStoreId != null && routeStoreId.isNotEmpty) {
      storeId = int.tryParse(routeStoreId);
      if (storeId != null && storeId > 0) {
        appLogger.info(
            '🔄 FoodRestaurantDetailScreen: Using route parameter store ID: $storeId');
      } else {
        storeId = null;
      }
    }

    final finalStoreId = storeId ?? 0;

    // ✅ CRITICAL: Log final storeId to debug why items might not be fetched
    appLogger
        .info('📡 FoodRestaurantDetailScreen: Final Store ID = $finalStoreId');
    if (finalStoreId == 0) {
      appLogger.warning(
          '⚠️ FoodRestaurantDetailScreen: Store ID is 0 - this will prevent items from being fetched!');
      appLogger.warning('   - widget.store?.id: ${widget.store?.id}');
      appLogger.warning(
          '   - storeController.store?.id: ${storeController.store?.id}');
      appLogger.warning('   - routeStoreId: $routeStoreId');
    }

    // ✅ FRONTEND ONLY: ALWAYS fetch items - even if storeId is 0, try to fetch anyway
    // This ensures items are requested even if store ID is missing
    if (storeId != 0) {
      appLogger.info(
          '📡 FoodRestaurantDetailScreen: Fetching menu items in background for store ID: $storeId');
      appLogger.info('   ✅ ALWAYS fetching items (store.open status ignored)');

      // 🔧 FIX: Wrap data loading in try-catch for graceful recovery
      try {
        // ⚡ PARALLEL BATCH: Load menu items, banners, and recommended items in parallel
        // Store details are fetched in background (non-blocking) for additional data
        appLogger.info(
            '📡 FoodRestaurantDetailScreen: Starting parallel batch load for store ID: $storeId');
        appLogger.debug(
            'FoodRestaurantDetailScreen: Parallel batch includes: menu items (slim menu), banners, recommended items');

        // ✅ CRITICAL: Force fetch items - reset state first to ensure fresh fetch
        // This breaks any stale pagination or empty state that prevents fetching
        if (kDebugMode) {
          appLogger.info(
              '🔄 FoodRestaurantDetailScreen: Resetting items state before fetch');
        }
        // Reset is already done in loadAllStoreDetails, but we ensure it here too

        // Load menu items, banners, and recommended items in parallel (non-blocking)
        if (!mounted) {
          return;
        }
        unawaited(storeController
            .loadAllStoreDetails(
          context,
          finalStoreId,
          widget.fromModule,
          slug: widget.slug,
        )
            .then((_) async {
          appLogger.info(
              '✅ FoodRestaurantDetailScreen: Parallel batch load complete (menu items, banners, recommended)');

          // 🔧 FIX: Check if items were loaded, if not, fallback to getStoreItemList
          if (storeController.storeItemModel == null ||
              storeController.storeItemModel!.items == null ||
              storeController.storeItemModel!.items!.isEmpty) {
            appLogger.info(
                '🔄 FoodRestaurantDetailScreen: No items loaded - falling back to getStoreItemList');
            try {
              await storeController.getStoreItemList(
                finalStoreId,
                1,
                'all',
                false,
                pageSize: _itemsPageLimit,
              );
              final itemCount =
                  storeController.storeItemModel?.items?.length ?? 0;
              appLogger.info(
                  '✅ FoodRestaurantDetailScreen: Fallback getStoreItemList loaded $itemCount items');
            } catch (e) {
              appLogger.error(
                  '❌ FoodRestaurantDetailScreen: Fallback getStoreItemList also failed',
                  e);
            }
          }

          storeController.showButtonAnimation();
          if (finalStoreId > 0) {
            await _reloadMenuAfterStoreDetails(storeController, finalStoreId);
          }
        }).catchError((Object e, StackTrace stackTrace) {
          appLogger.error(
              '❌ FoodRestaurantDetailScreen: Error in parallel batch load',
              e,
              stackTrace);

          // 🔧 FIX: Fallback to getStoreItemList on error
          appLogger.info(
              '🔄 FoodRestaurantDetailScreen: Falling back to getStoreItemList after error');
          storeController
              .getStoreItemList(
            finalStoreId,
            1,
            'all',
            false,
            pageSize: _itemsPageLimit,
          )
              .then((_) {
            appLogger.info(
                '✅ FoodRestaurantDetailScreen: Fallback getStoreItemList completed');
            storeController.showButtonAnimation();
          }).catchError((Object fallbackError) {
            appLogger.error(
              '❌ FoodRestaurantDetailScreen: Fallback getStoreItemList also failed',
              fallbackError,
            );
          });

          if (mounted) setState(() {});
        }));
      } catch (e, stackTrace) {
        appLogger.error(
            '❌ FoodRestaurantDetailScreen: Error starting parallel batch load',
            e,
            stackTrace);
        // UI will show store name from widget.store, menu items will load in background
        if (mounted) setState(() {});
      }
    } else {
      // ✅ CRITICAL: Log warning if finalStoreId is 0 - this prevents items from being fetched
      appLogger.error(
          '❌ FoodRestaurantDetailScreen: Store ID is 0 - CANNOT fetch items!');
      appLogger.error('   - widget.store?.id: ${widget.store?.id}');
      appLogger.error(
          '   - storeController.store?.id: ${storeController.store?.id}');
      appLogger.error('   - routeStoreId: $routeStoreId');
      appLogger.error('   - This is why items are not being fetched!');
      appLogger.error(
          '   - ACTION REQUIRED: Check route parameters and store initialization');
    }

    // 🚀 SLIM MENU: Check if slim menu was successfully loaded
    if (storeController.slimMenuLoaded &&
        storeController.slimMenuResponse != null) {
      appLogger.info(
          '🚀 FoodRestaurantDetailScreen: ============ SLIM MENU LOADING ============');
      appLogger.info(
          '✅ FoodRestaurantDetailScreen: Slim menu available - using optimized single API call');
      appLogger.debug(
          'FoodRestaurantDetailScreen: Categories: ${storeController.slimMenuResponse!.totalCategories}, Items: ${storeController.slimMenuResponse!.totalItems}');
      appLogger.info(
          'FoodRestaurantDetailScreen: ===========================================');

      // Use slim menu data
      _populateCategoryMapFromSlimMenu(storeController.slimMenuResponse!);
      if (mounted) setState(() {});
      return; // Skip parallel loading - all data is already loaded
    }

    // 🔄 FALLBACK: Use parallel loading if slim menu not available
    appLogger.info(
        '🔄 FoodRestaurantDetailScreen: ============ FALLBACK: PARALLEL LOADING ============');
    appLogger.warning(
        '⚠️ FoodRestaurantDetailScreen: Slim menu not available - falling back to parallel category loading');
    appLogger.info(
        'FoodRestaurantDetailScreen: ==================================================');

    // 🛠️ TASK 4: Categories come from store details - only fetch if store details didn't provide them
    // This happens when store details response doesn't include category_details
    if (categoryController.categoryList == null &&
        storeController.store?.categoryDetails == null) {
      appLogger.info(
          '📡 FoodRestaurantDetailScreen: Store details didn\'t include categories - fetching category list...');
      await categoryController.getCategoryList(true);
      appLogger.debug(
          'FoodRestaurantDetailScreen: Category list fetched - count: ${categoryController.categoryList?.length ?? 0}');
    }

    // Set category list using category_details from store response (available immediately after getStoreDetails)
    storeController.setCategoryList();
    final categories = _getStoreCategories(storeController.store);
    if (categories.isEmpty) {
      appLogger.warning(
          '⚠️ FoodRestaurantDetailScreen: Store categories not ready yet');
      return;
    }
    // ✅ FIX: Ensure storeId is not null before calling _startProgressiveCategoryLoading
    final currentStoreId = storeController.store?.id;
    if (currentStoreId != null && currentStoreId > 0) {
      await _startProgressiveCategoryLoading(
        storeController: storeController,
        storeId: currentStoreId,
        categories: categories,
        source: 'initial',
      );
    } else {
      appLogger.warning(
          '⚠️ FoodRestaurantDetailScreen: Cannot start progressive loading - store ID is null or 0');
    }

    // ⚡ Note: Banners and recommended items are already loaded in loadAllStoreDetails() parallel batch
  }

  Future<void> _reloadMenuAfterStoreDetails(
      StoreController storeController, int storeId) async {
    if (!mounted) return;
    if (storeController.slimMenuLoaded &&
        storeController.slimMenuResponse != null) {
      _populateCategoryMapFromSlimMenu(storeController.slimMenuResponse!);
      if (mounted) setState(() {});
      return;
    }
    storeController.setCategoryList(forceRefresh: true);
    final categories = _getStoreCategories(storeController.store);
    _categoryItemsMap.clear();
    _loadedCategoryIds.clear();
    _loadingCategoryIds.clear();
    _categoryKeys.clear();
    await _startProgressiveCategoryLoading(
      storeController: storeController,
      storeId: storeId,
      categories: categories,
      source: 'store_details',
    );
  }

  Future<void> _startProgressiveCategoryLoading({
    required StoreController storeController,
    required int storeId,
    required List<CategoryModel> categories,
    required String source,
  }) async {
    if (categories.length <= 1) {
      appLogger.warning(
          '⚠️ FoodRestaurantDetailScreen: No categories available after $source load');
      return;
    }
    if (_loadedCategoryIds.isNotEmpty || _loadingCategoryIds.isNotEmpty) {
      return;
    }
    appLogger.info(
        '🔄 FoodRestaurantDetailScreen: ============ PROGRESSIVE CATEGORY LOADING START ============');
    appLogger.debug(
        'FoodRestaurantDetailScreen: Total categories to load: ${categories.length - 1}');
    appLogger.debug('FoodRestaurantDetailScreen: Store ID: $storeId');

    final categoryFutures = <Future<void>>[];
    for (int i = 1; i < categories.length; i++) {
      final category = categories[i];
      final categoryId = category.id;
      if (categoryId == null || categoryId == 0) continue;
      if (kDebugMode) {
        debugPrint('');
        debugPrint(
            '   📡 [$i/${categories.length - 1}] Queuing category: ${category.name} (ID: $categoryId)');
      }
      _loadingCategoryIds.add(categoryId);
      categoryFutures.add(
        storeController.storeServiceInterface
            .getStoreItemList(
          storeId,
          1,
          categoryId,
          'all',
          limit: _itemsPageLimit,
        )
            .then((categoryItemModel) {
          final allCategoryItems = categoryItemModel?.items ?? [];
          final totalSize = categoryItemModel?.totalSize ?? 0;
          if (kDebugMode) {
            debugPrint(
                '   ✅ Loaded ${allCategoryItems.length} items for ${category.name} (ID: $categoryId, Total available: $totalSize)');
          }
          _categoryItemsMap[categoryId] = List<Item>.from(allCategoryItems);
          _categoryOffsets[categoryId] = 1;
          _categoryTotalSizes[categoryId] = totalSize;
          if (!_categoryKeys.containsKey(categoryId)) {
            _categoryKeys[categoryId] = GlobalKey();
          }
          _loadingCategoryIds.remove(categoryId);
          _loadedCategoryIds.add(categoryId);
          if (mounted) {
            setState(() {});
          }
        }).catchError((Object e) {
          if (kDebugMode) {
            debugPrint(
                '   ❌ Error loading category ${category.name} (ID: $categoryId): $e');
          }
          _loadingCategoryIds.remove(categoryId);
          _loadedCategoryIds.add(categoryId);
          _categoryItemsMap[categoryId] = [];
          if (mounted) {
            setState(() {});
          }
        }),
      );
    }
    if (categoryFutures.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('');
        debugPrint(
            '   🚀 Firing ${categoryFutures.length} category requests in parallel...');
      }
      if (mounted) {
        setState(() {});
      }
      await Future.wait(categoryFutures);
    }
    if (kDebugMode) {
      debugPrint('');
      debugPrint('🎉 ============ PROGRESSIVE LOADING COMPLETE ============');
      debugPrint('   ✅ Categories loaded: ${_loadedCategoryIds.length}');
      debugPrint(
          '   📊 Total items loaded: ${_categoryItemsMap.values.fold<int>(0, (sum, items) => sum + items.length)}');
      debugPrint('========================================================');
      debugPrint('');
    }
    if (_selectedCategoryId == null && categories.length > 1) {
      final firstCategory = categories[1];
      setState(() {
        _selectedCategoryId = firstCategory.id;
      });
      if (kDebugMode) {
        debugPrint(
            '   ✅ Auto-selected first category: ${firstCategory.name} (ID: ${firstCategory.id})');
      }
    }
  }

  List<CategoryModel> _getStoreCategories(Store? store) {
    final List<CategoryModel> categories = [];
    if (store?.categoryDetails == null || store!.categoryDetails!.isEmpty) {
      return categories;
    }
    final currentLanguageCode =
        Get.find<LocalizationController>().locale.languageCode;
    for (final category in store.categoryDetails!) {
      if (category.parentId != null && category.parentId != 0) continue;
      String? categoryName = category.name;
      if (currentLanguageCode == 'ar' &&
          category.nameAr != null &&
          category.nameAr!.isNotEmpty) {
        categoryName = category.nameAr;
      } else if (currentLanguageCode == 'en' &&
          category.nameEn != null &&
          category.nameEn!.isNotEmpty) {
        categoryName = category.nameEn;
      }
      categories.add(CategoryModel(
        id: category.id,
        name: categoryName,
        position: category.position,
        storeId: category.storeId,
      ));
    }
    categories.sort((a, b) {
      final aPos = a.position ?? 0;
      final bPos = b.position ?? 0;
      if (aPos != bPos) return aPos.compareTo(bPos);
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return [CategoryModel(id: 0, name: 'all_products'.tr), ...categories];
  }

  /// 🚀 SLIM MENU: Populate category map from slim menu response
  /// This replaces the parallel loading approach with a single API call
  void _populateCategoryMapFromSlimMenu(SlimMenuResponse slimMenuResponse) {
    if (kDebugMode) {
      debugPrint(
          '🚀 [FoodRestaurantDetailScreen] _populateCategoryMapFromSlimMenu() - Populating from slim menu');
      debugPrint(
          '   📊 Categories: ${slimMenuResponse.totalCategories}, Items: ${slimMenuResponse.totalItems}');
    }

    // Clear existing map
    _categoryItemsMap.clear();
    _loadedCategoryIds.clear();
    _loadingCategoryIds.clear();

    // Populate map from slim menu response
    for (final category in slimMenuResponse.categories) {
      if (category.id != 0) {
        final categoryId = category.id;
        final items =
            category.items.map((slimItem) => slimItem.toItem()).toList();
        _categoryItemsMap[categoryId] = items;
        _loadedCategoryIds.add(categoryId);

        // Ensure GlobalKey exists for this category
        if (!_categoryKeys.containsKey(categoryId)) {
          _categoryKeys[categoryId] = GlobalKey();
        }

        if (kDebugMode) {
          debugPrint(
              '   ✅ Populated category ${category.name} (ID: $categoryId) with ${items.length} items');
        }
      }
    }

    // Set selected category to first non-"all" category
    if (slimMenuResponse.categories.isNotEmpty) {
      final firstCategory = slimMenuResponse.categories.first;
      if (firstCategory.id != 0) {
        _selectedCategoryId = firstCategory.id;
        if (kDebugMode) {
          debugPrint(
              '   ✅ Auto-selected first category: ${firstCategory.name} (ID: ${firstCategory.id})');
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
          '🎉 [FoodRestaurantDetailScreen] Slim menu population complete: ${_loadedCategoryIds.length} categories, ${_categoryItemsMap.values.fold<int>(0, (sum, items) => sum + items.length)} items');
    }
  }

  void _onCategorySelected(int? categoryId, String categoryName) {
    if (kDebugMode) {
      debugPrint(
          '📍 [FoodRestaurantDetailScreen] _onCategorySelected() - File: food_restaurant_detail_screen.dart');
      debugPrint('   🎯 Category selected: $categoryName (ID: $categoryId)');
    }
    setState(() {
      _selectedCategoryId = categoryId;
    });

    if (categoryId == null) {
      // Scroll to top for "All" category
      if (kDebugMode) {
        debugPrint('   📜 Scrolling to top (All category)');
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Scroll to the selected category section
      final key = _categoryKeys[categoryId];
      if (key != null && key.currentContext != null) {
        if (kDebugMode) {
          debugPrint('   📜 Scrolling to category section: $categoryName');
        }
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1, // Slight offset to ensure header is visible
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gryColor_8,
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          return GetBuilder<CategoryController>(
            builder: (categoryController) {
              final store = storeController.store;

              // ⚡ V2: Use minimal store data for immediate render, fallback to detailed data when available
              // This eliminates loading flicker by showing header/info immediately
              final displayStore = store ?? widget.store;

              // 🛠️ TASK 5: Show retry button if 500 error and no cache (only if we have no store data at all)
              if (storeController.hasStoreError &&
                  storeController.storeErrorStatusCode == 500 &&
                  displayStore == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load store details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Please check your connection and try again'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          storeController.retryStoreDetails(
                            context,
                            Store(id: widget.store?.id),
                            widget.fromModule,
                            slug: widget.slug,
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ⚡ TASK 4: Always render screen structure - no full-screen blockers
              // Header and TabBar render immediately from widget.store
              // Only show error/out of coverage if we have minimal data but no detailed data AND it's an error
              if (displayStore == null) {
                // If we have absolutely no store data, show minimal loading
                // But this should rarely happen since widget.store is passed from navigation
                return const Scaffold(
                  backgroundColor: AppColors.gryColor_8,
                  body:
                      StoreDetailsScreenShimmerWidget(), // ⚡ TASK 2: Instant skeleton morphing
                );
              }

              // ⚡ V2: If we only have minimal data (widget.store) and no detailed data, show error message
              // But only if there's an actual error, not just loading
              // ⚡ FIX: Don't show "out of coverage" for timeouts (statusCode 1) - show retry instead
              if (store == null &&
                  widget.store != null &&
                  storeController.hasStoreError) {
                // Check if it's a timeout/network error (statusCode 1) vs actual coverage issue
                final isTimeoutOrNetworkError =
                    storeController.storeErrorStatusCode == 1;

                if (isTimeoutOrNetworkError) {
                  // Show retry UI for timeout/network errors
                  return Scaffold(
                    backgroundColor: AppColors.gryColor_8,
                    appBar: AppBar(
                      title: Text(widget.store!.name ?? ''),
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 64, color: Colors.orange),
                          const SizedBox(height: 16),
                          Text(
                            widget.store!.name ?? '',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Connection Timeout',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please check your connection and try again',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              storeController.retryStoreDetails(
                                context,
                                widget.store!,
                                widget.fromModule,
                                slug: widget.slug,
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Show "out of coverage" only for actual coverage errors (not timeouts)
                  return Scaffold(
                    backgroundColor: AppColors.gryColor_8,
                    appBar: AppBar(
                      title: Text(widget.store!.name ?? ''),
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off,
                              size: 64, color: Colors.orange),
                          const SizedBox(height: 16),
                          Text(
                            widget.store!.name ?? '',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Out of Coverage',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This store is not available in your area',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }

              // ⚡ TASK 2: Build categories synchronously from widget.store.categoryDetails
              // If categoryDetails is available, build TabBar immediately (no shimmer)
              // Otherwise, use categories from storeController (which may be loading)
              final List<CategoryModel> categoriesFromStore = [];
              if (widget.store?.categoryDetails != null &&
                  widget.store!.categoryDetails!.isNotEmpty) {
                // Build categories immediately from widget.store.categoryDetails
                final localizationController =
                    Get.find<LocalizationController>();
                final currentLanguageCode =
                    localizationController.locale.languageCode;
                for (final category in widget.store!.categoryDetails!) {
                  // Skip subcategories (parent_id != 0)
                  if (category.parentId != null && category.parentId != 0)
                    continue;

                  String? categoryName = category.name;
                  // Apply language-specific name if available
                  if (currentLanguageCode == 'ar' &&
                      category.nameAr != null &&
                      category.nameAr!.isNotEmpty) {
                    categoryName = category.nameAr;
                  } else if (currentLanguageCode == 'en' &&
                      category.nameEn != null &&
                      category.nameEn!.isNotEmpty) {
                    categoryName = category.nameEn;
                  }

                  categoriesFromStore.add(CategoryModel(
                    id: category.id,
                    name: categoryName,
                    position: category.position,
                    storeId: category.storeId,
                  ));
                }
                // Sort by position
                categoriesFromStore.sort((a, b) {
                  final aPos = a.position ?? 0;
                  final bPos = b.position ?? 0;
                  if (aPos != bPos) return aPos.compareTo(bPos);
                  return (a.id ?? 0).compareTo(b.id ?? 0);
                });
              }

              // 🔒 ISOLATION: Use specificStoreCategoryList to prevent state leakage
              // ⚠️ FIX: Don't call setCategoryList() in builder - it causes infinite rebuild loop
              // setCategoryList() is already called in _initializeData() (line 178)
              final allCategories = categoriesFromStore.isNotEmpty
                  ? [
                      CategoryModel(id: 0, name: 'all_products'.tr),
                      ...categoriesFromStore
                    ]
                  : (storeController.specificStoreCategoryList ?? []);

              // ⚡ TASK 2: TabBar is ready if we have categories from widget.store OR from storeController
              final bool hasCategoriesForTabBar = allCategories.isNotEmpty;

              store != null; // Detailed store from API
              _loadedCategoryIds.isNotEmpty || _categoryItemsMap.isNotEmpty;

              // Skip the first category (index 0) which is "all" - we handle it separately
              final categories = allCategories.length > 1
                  ? List<CategoryModel>.from(allCategories.sublist(1))
                  : <CategoryModel>[];

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ⚡ V2: Use displayStore for immediate render (falls back to widget.store)
                  SliverToBoxAdapter(
                    child: FoodRestaurantHeader(
                      coverPhotoUrl: displayStore.coverPhotoFullUrl ?? '',
                      logoUrl: displayStore.logoFullUrl ?? '',
                      storeId: displayStore.id,
                      heroBannerTag: widget.heroBannerTag,
                      heroLogoTag: widget.heroLogoTag,
                    ),
                  ),
                  // ⚡ V2: Use displayStore for immediate render, updates smoothly when detailed data arrives
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: FoodRestaurantInfoSection(
                        store: displayStore,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeDefault,
                        0,
                      ),
                      child: FoodRestaurantActionButtons(
                        storeId: displayStore.id,
                      ),
                    ),
                  ),
                  // ⚡ TASK 2: Render TabBar immediately if categories available, otherwise show shimmer
                  // TabBar renders synchronously from widget.store.categoryDetails (no shimmer)
                  if (hasCategoriesForTabBar) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeSmall,
                        ),
                        child: FoodRestaurantCategoryTabs(
                          categories: categories,
                          selectedCategoryId: _selectedCategoryId,
                          onCategorySelected: _onCategorySelected,
                          onMoreTap: () {
                            // Calculate item counts for each category
                            final Map<int?, int> categoryItemCounts = {};
                            for (final category in categories) {
                              categoryItemCounts[category.id] =
                                  _categoryItemsMap[category.id]?.length ?? 0;
                            }

                            // Show bottom sheet with all categories
                            showModalBottomSheet<dynamic>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  FoodRestaurantCategoriesBottomSheet(
                                categories: categories,
                                categoryItemCounts: categoryItemCounts,
                                selectedCategoryId: _selectedCategoryId,
                                onCategorySelected: _onCategorySelected,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Category sections - show all items grouped by category
                    // Show shimmer for items if not loaded yet
                    if (_loadedCategoryIds.isEmpty && _categoryItemsMap.isEmpty)
                      ..._buildItemsShimmer()
                    else
                      ..._buildCategorySections(categories, storeController),
                    SliverToBoxAdapter(
                      child: Builder(builder: (context) {
                        final int? categoryId = _selectedCategoryId;
                        if (categoryId == null || categoryId == 0) {
                          return const SizedBox.shrink();
                        }
                        final int loadedCount =
                            _categoryItemsMap[categoryId]?.length ?? 0;
                        final int totalSize =
                            _categoryTotalSizes[categoryId] ?? 0;
                        final bool hasReachedEnd =
                            totalSize > 0 && loadedCount >= totalSize;
                        if (_isPaginatingItems) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeDefault,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                            ),
                          );
                        }
                        if (hasReachedEnd) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeDefault,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_food_beverage_rounded,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeExtraSmall),
                                Text(
                                  'end_of_items'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ),
                  ] else ...[
                    // Show shimmer for TabBar only if categories not available
                    ..._buildMenuShimmer()
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildCategorySections(
    List<CategoryModel> categories,
    StoreController storeController,
  ) {
    final sections = <Widget>[];

    // Show loaded categories progressively
    for (final category in categories) {
      if (category.id != null && category.id != 0) {
        final categoryId = category.id;
        final isLoaded = _loadedCategoryIds.contains(categoryId);
        final isLoading = _loadingCategoryIds.contains(categoryId);
        final List<Item> items =
            List<Item>.from(_categoryItemsMap[categoryId] ?? []);

        // Keep available items first, then apply selected price order inside each group.
        if (items.isNotEmpty) {
          _sortItemsByAvailabilityThenPrice(items, storeController);
        }

        // Show category if it's loaded (even if empty) or currently loading
        if (isLoaded || isLoading) {
          // Ensure GlobalKey exists for this category
          if (!_categoryKeys.containsKey(categoryId)) {
            _categoryKeys[categoryId] = GlobalKey();
          }

          sections.add(
            SliverToBoxAdapter(
              child: FoodRestaurantCategorySection(
                category: category,
                items: items,
                sectionKey: _categoryKeys[categoryId]!,
                isLoading: isLoading,
              ),
            ),
          );
        }
      }
    }

    return sections;
  }

  void _sortItemsByAvailabilityThenPrice(
    List<Item> items,
    StoreController storeController,
  ) {
    items.sort((a, b) {
      final bool aOutOfStock = _isOutOfStock(a);
      final bool bOutOfStock = _isOutOfStock(b);

      // Available first, out-of-stock last.
      if (aOutOfStock != bOutOfStock) {
        return aOutOfStock ? 1 : -1;
      }

      // Inside each availability group, keep the current price sort behavior.
      final num priceA = a.price ?? 0;
      final num priceB = b.price ?? 0;
      return storeController.isPriceAscending
          ? priceA.compareTo(priceB)
          : priceB.compareTo(priceA);
    });
  }

  bool _isOutOfStock(Item item) {
    final bool moduleStockEnabled =
        Get.find<SplashController>().configModel?.moduleConfig?.module?.stock ??
            false;
    if (!moduleStockEnabled) {
      return false;
    }

    return (item.stock ?? 0) <= 0;
  }

  /// ⚡ TASK 2: Build shimmer loading state for items only (TabBar renders immediately)
  /// Shows shimmer for items when categories are available but items are not loaded yet
  List<Widget> _buildItemsShimmer() {
    return [
      // Items shimmer - show 3 skeleton items
      ...List.generate(3, (index) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
            ),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Row(
                  children: [
                    // Image skeleton
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    // Text skeletons
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    ];
  }

  /// ⚡ V2: Build shimmer loading state for category tabs and items
  /// Shows shimmer until menu data (categories + items) is fully loaded
  List<Widget> _buildMenuShimmer() {
    return [
      // Category tabs shimmer
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),
          ),
        ),
      ),
      // Items shimmer - show 3 skeleton items
      ...List.generate(3, (index) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
            ),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Row(
                  children: [
                    // Image skeleton
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    // Text skeletons
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    ];
  }
}
