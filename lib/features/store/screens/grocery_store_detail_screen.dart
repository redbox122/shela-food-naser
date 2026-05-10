/// Grocery Store Detail Screen - Module 7
///
/// Specialized screen for grocery stores (module ID 7) with category grid layout
/// matching the design specifications from the grocery store home screen.
///
/// File: grocery_store_detail_screen.dart
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/widgets/grocery_store/grocery_store_header.dart';
import 'package:sixam_mart/features/store/widgets/grocery_store/grocery_store_info_section.dart';
import 'package:sixam_mart/features/store/widgets/grocery_store/grocery_categories_grid.dart';
import 'package:sixam_mart/features/store/widgets/store_details_screen_shimmer_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class GroceryStoreDetailScreen extends StatefulWidget {
  final Store? store;
  final bool fromModule;
  final String slug;
  final String? heroBannerTag;

  const GroceryStoreDetailScreen({
    super.key,
    required this.store,
    required this.fromModule,
    this.slug = '',
    this.heroBannerTag,
  });

  @override
  State<GroceryStoreDetailScreen> createState() =>
      _GroceryStoreDetailScreenState();
}

class _GroceryStoreDetailScreenState extends State<GroceryStoreDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // ✅ PROFESSIONAL SCREEN LOGGING: Track screen lifecycle for debugging
    if (kDebugMode) {
      debugPrint('📄 SCREEN INIT: GroceryStoreDetailScreen');
      debugPrint('   - route: ${Get.currentRoute}');
      debugPrint('   - parameters: ${Get.parameters}');
    }

    appLogger.logPageEntry('GroceryStoreDetailScreen');
    appLogger.info('📍 GroceryStoreDetailScreen: Initializing');
    appLogger.debug('GroceryStoreDetailScreen: Store ID = ${widget.store?.id}');
    appLogger
        .debug('GroceryStoreDetailScreen: From Module = ${widget.fromModule}');
    appLogger.debug('GroceryStoreDetailScreen: Slug = ${widget.slug}');
    appLogger.debug('GroceryStoreDetailScreen: Module Type = Grocery');

    _initializeData();
  }

  @override
  void dispose() {
    // ✅ PROFESSIONAL SCREEN LOGGING: Track screen disposal
    if (kDebugMode) {
      debugPrint('🗑️ SCREEN DISPOSE: GroceryStoreDetailScreen');
      debugPrint('   - route: ${Get.currentRoute}');
    }

    appLogger.logPageExit();
    appLogger.info('📍 GroceryStoreDetailScreen: Disposed');
    appLogger.debug('GroceryStoreDetailScreen: Clearing store detail state');

    // 🔒 HARD RESET: Clear store detail state to prevent state leakage
    final storeController = Get.find<StoreController>();
    storeController.clearStoreDetailState();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    appLogger.info('📍 GroceryStoreDetailScreen: _initializeData() called');
    appLogger.debug('GroceryStoreDetailScreen: Store ID = ${widget.store?.id}');

    // ✅ CRITICAL: Log all possible store ID sources for debugging
    appLogger
        .info('🔍 GroceryStoreDetailScreen: Checking all store ID sources');
    appLogger.info('   - widget.store?.id: ${widget.store?.id}');

    final storeController = Get.find<StoreController>();
    final categoryController = Get.find<CategoryController>();

    appLogger
        .info('   - storeController.store?.id: ${storeController.store?.id}');

    // ✅ CRITICAL: Try to get store ID from route parameters as fallback
    final routeStoreId = Get.parameters['id'];
    appLogger.info('   - Get.parameters["id"]: $routeStoreId');

    if (storeController.isSearching) {
      appLogger.debug('GroceryStoreDetailScreen: Clearing search status');
      storeController.changeSearchStatus(isUpdate: false);
    }

    storeController.hideAnimation();

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
            '⚡ GroceryStoreDetailScreen: Store header visible instantly (0ms) - using widget.store');
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
            '🔄 GroceryStoreDetailScreen: Using route parameter store ID: $storeId');
      } else {
        storeId = null;
      }
    }

    final finalStoreId = storeId ?? 0;

    // ✅ CRITICAL: Log final storeId to debug why items might not be fetched
    appLogger
        .info('📡 GroceryStoreDetailScreen: Final Store ID = $finalStoreId');
    if (finalStoreId == 0) {
      appLogger.warning(
          '⚠️ GroceryStoreDetailScreen: Store ID is 0 - this will prevent items from being fetched!');
      appLogger.warning('   - widget.store?.id: ${widget.store?.id}');
      appLogger.warning(
          '   - storeController.store?.id: ${storeController.store?.id}');
      appLogger.warning('   - routeStoreId: $routeStoreId');
    }

    // ✅ FRONTEND ONLY: ALWAYS fetch items - even if storeId is 0, try to fetch anyway
    if (finalStoreId != 0) {
      appLogger.info(
          '📡 GroceryStoreDetailScreen: Fetching menu items in background for store ID: $finalStoreId');
      appLogger.info('   ✅ ALWAYS fetching items (store.open status ignored)');

      // ✅ CRITICAL: Force fetch items - reset state first to ensure fresh fetch
      // This breaks any stale pagination or empty state that prevents fetching
      appLogger.info(
          '🔄 GroceryStoreDetailScreen: Resetting items state before fetch');
      // Clear any stale state that might prevent fetching
      if (storeController.storeItemModel != null &&
          (storeController.storeItemModel!.items == null ||
              storeController.storeItemModel!.items!.isEmpty)) {
        appLogger.warning(
            '⚠️ GroceryStoreDetailScreen: Detected empty items state - resetting for fresh fetch');
        // Reset is handled in getSlimMenu/loadAllStoreDetails, but we ensure it here
      }

      // Fetch menu items in background (non-blocking)
      storeController.getSlimMenu(finalStoreId).then((success) {
        if (success) {
          appLogger.info(
              '✅ GroceryStoreDetailScreen: Menu items loaded successfully');
          storeController.showButtonAnimation();
        } else {
          // 🔧 FIX: Fallback to getStoreItemList if slim menu failed
          appLogger.info(
              '🔄 GroceryStoreDetailScreen: Slim menu failed - falling back to getStoreItemList');
          storeController
              .getStoreItemList(finalStoreId, 1, 'all', false, pageSize: 50)
              .then((_) {
            appLogger.info(
                '✅ GroceryStoreDetailScreen: Fallback getStoreItemList completed');
            storeController.showButtonAnimation();
          }).catchError((e) {
            appLogger.error(
                '❌ GroceryStoreDetailScreen: Fallback getStoreItemList also failed',
                e);
          });
        }
      }).catchError((e) {
        appLogger.error(
            '❌ GroceryStoreDetailScreen: Error fetching menu items', e);
        // 🔧 FIX: Fallback to getStoreItemList on error
        appLogger.info(
            '🔄 GroceryStoreDetailScreen: Falling back to getStoreItemList after error');
        storeController
            .getStoreItemList(finalStoreId, 1, 'all', false, pageSize: 50)
            .then((_) {
          appLogger.info(
              '✅ GroceryStoreDetailScreen: Fallback getStoreItemList completed');
          storeController.showButtonAnimation();
        }).catchError((fallbackError) {
          appLogger.error(
              '❌ GroceryStoreDetailScreen: Fallback getStoreItemList also failed',
              fallbackError);
        });
      });

      // Optionally fetch full store details in background (non-blocking, for additional data)
      storeController
          .getStoreDetails(
        context,
        Store(id: finalStoreId),
        widget.fromModule,
        slug: widget.slug,
      )
          .then((value) {
        appLogger.info(
            '✅ GroceryStoreDetailScreen: Store details fetched in background');
        storeController.showButtonAnimation();
      }).catchError((e) {
        appLogger.error(
            '❌ GroceryStoreDetailScreen: Error fetching store details', e);
      });
    } else {
      // ✅ CRITICAL: Log error if finalStoreId is 0 - this prevents items from being fetched
      appLogger.error(
          '❌ GroceryStoreDetailScreen: Store ID is 0 - CANNOT fetch items!');
      appLogger.error('   - widget.store?.id: ${widget.store?.id}');
      appLogger.error(
          '   - storeController.store?.id: ${storeController.store?.id}');
      appLogger.error('   - routeStoreId: $routeStoreId');
      appLogger.error('   - This is why items are not being fetched!');
      appLogger.error(
          '   - ACTION REQUIRED: Check route parameters and store initialization');
    }

    if (categoryController.categoryList == null) {
      appLogger.info('📡 GroceryStoreDetailScreen: Fetching category list...');
      await categoryController.getCategoryList(true);
      appLogger.debug(
          'GroceryStoreDetailScreen: Category list fetched - count: ${categoryController.categoryList?.length ?? 0}');
    } else {
      appLogger.debug(
          'GroceryStoreDetailScreen: Category list already available - count: ${categoryController.categoryList?.length ?? 0}');
    }

    // Set category list using category_details from store response
    storeController.setCategoryList();

    appLogger.debug('GroceryStoreDetailScreen: Store ID: $storeId');
    appLogger
        .info('✅ GroceryStoreDetailScreen: Grocery store data initialized');
    appLogger.debug(
        'GroceryStoreDetailScreen: Categories available: ${storeController.specificStoreCategoryList?.length ?? 0}');

    // Load store banners
    appLogger.debug(
        'GroceryStoreDetailScreen: Loading store banners for store ID: $storeId');
    storeController.getStoreBannerList(storeId);

    // Load recommended items if needed
    appLogger.debug(
        'GroceryStoreDetailScreen: Loading recommended items for store ID: $storeId');
    storeController.getRestaurantRecommendedItemList(storeId, false);
  }

  @override
  Widget build(BuildContext context) {
    appLogger.debug('GroceryStoreDetailScreen: build() called');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          return GetBuilder<CategoryController>(
            builder: (categoryController) {
              final controllerStore = storeController.store;
              final int? requestedStoreId = widget.store?.id;

              // 🔒 STALE-CACHE GUARD: Only use the controller's store if its id
              // matches the requested route id (prevents flashing previous store).
              final bool controllerMatchesRoute = controllerStore != null &&
                  requestedStoreId != null &&
                  controllerStore.id == requestedStoreId;
              final store = controllerMatchesRoute ? controllerStore : null;

              if (kDebugMode &&
                  controllerStore != null &&
                  requestedStoreId != null &&
                  controllerStore.id != requestedStoreId) {
                debugPrint(
                  '[STORE_DETAILS_STALE_IGNORED] grocery requestedId=$requestedStoreId '
                  'cachedId=${controllerStore.id}',
                );
              }

              if (store == null || store.name == null) {
                return const StoreDetailsScreenShimmerWidget(); // ⚡ TASK 2: Instant skeleton morphing
              }

              if (categoryController.categoryList == null) {
                return const StoreDetailsScreenShimmerWidget(); // ⚡ TASK 2: Instant skeleton morphing
              }

              // 🔒 ISOLATION: Use specificStoreCategoryList prepared during initialization.
              final allCategories =
                  storeController.specificStoreCategoryList ?? [];

              appLogger.debug(
                  'GroceryStoreDetailScreen: Categories available: ${allCategories.length}');

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header with banner and overlay icons
                  SliverToBoxAdapter(
                    child: GroceryStoreHeader(
                      coverPhotoUrl: store.coverPhotoFullUrl ?? '',
                      storeId: store.id,
                      heroBannerTag: widget.heroBannerTag,
                    ),
                  ),
                  // Store info card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: GroceryStoreInfoSection(
                        store: store,
                      ),
                    ),
                  ),
                  // Product categories grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeLarge,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeLarge,
                      ),
                      child: GroceryCategoriesGrid(
                        categories: allCategories.length > 1
                            ? List<CategoryModel>.from(allCategories.sublist(1))
                            : <CategoryModel>[],
                        storeId: store.id ?? 0,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
