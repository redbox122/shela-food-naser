
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/home/widgets/brands_view_widget.dart';
import 'package:sixam_mart/features/offers/widgets/offers_view.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart' show CategoryView, CategoryShimmer;
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/features/home/widgets/shop_home_skeleton.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/features/home/widgets/home_screen_data_provider.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});
  
  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  bool _hasCachedData = false;
  // ⚡ TASK 2: Performance benchmarking
  late Stopwatch _renderStopwatch;
  bool _hasLoggedRenderTime = false;
  
  // ✅ ScrollController للأقسام (lazy loading)
  late final ScrollController _categoryScrollController;
  
  // ✅ Parent ScrollController from HomeScreen (إخفاء/إظهار الأقسام)
  ScrollController? _parentScrollController;
  
  // ✅ متغيرات التحكم في إظهار/إخفاء الأقسام
  bool _showCategories = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('ShopHomeScreen');
    appLogger.info('🏠 ShopHomeScreen: Initializing');
    appLogger.debug('ShopHomeScreen: Module Type = Ecommerce/Shop');
    appLogger.debug('ShopHomeScreen: Starting initialization sequence');
    
    // ⚡ TASK 2: Start performance stopwatch
    _renderStopwatch = Stopwatch()..start();
    
    // ✅ إضافة ScrollController للأقسام (lazy loading)
    _categoryScrollController = ScrollController();
    _categoryScrollController.addListener(() {
      if (_categoryScrollController.position.pixels >=
          _categoryScrollController.position.maxScrollExtent - 100) {
        Get.find<CategoryController>().loadMoreCategories();
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachParentScrollController();
    });
    
    // ⚡ SWR: Load cached data IMMEDIATELY for zero-latency rendering
    _loadCachedDataForInstantUI();
  }
  
  @override
  void dispose() {
    _categoryScrollController.dispose();
    _parentScrollController?.removeListener(_onScroll);
    appLogger.logPageExit();
    appLogger.info('🏠 ShopHomeScreen: Disposed');
    super.dispose();
  }

  void _attachParentScrollController() {
    final scrollable = Scrollable.maybeOf(context);
    final controller = scrollable?.widget.controller;
    if (controller != null && controller != _parentScrollController) {
      _parentScrollController?.removeListener(_onScroll);
      _parentScrollController = controller;
      _parentScrollController!.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final splashController = Get.find<SplashController>();
    final bool isEcommerce =
        splashController.module?.moduleType.toString() == AppConstants.ecommerce;
    if (isEcommerce) {
      return; // Keep categories visible for ecommerce to avoid fast jump to brands
    }
    final controller = _parentScrollController;
    if (controller == null || !controller.hasClients) {
      return;
    }
    final currentOffset = controller.offset;

    // نزول ↓
    if (currentOffset > _lastOffset + 10) {
      if (_showCategories) {
        setState(() => _showCategories = false);
      }
    }

    // صعود ↑
    if (currentOffset < _lastOffset - 10) {
      if (!_showCategories) {
        setState(() => _showCategories = true);
      }
    }

    _lastOffset = currentOffset;
  }

  /// ⚡ SWR: Load cached data from HomeUnifiedController for instant UI rendering
  Future<void> _loadCachedDataForInstantUI() async {
    appLogger.debug('ShopHomeScreen: _loadCachedDataForInstantUI() called');
    appLogger.debug('ShopHomeScreen: useBffV2Endpoint = ${AppConstants.useBffV2Endpoint}');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('ShopHomeScreen: BFF v2 endpoint disabled, skipping cache load');
      return;
    }
    
    try {
        if (Get.isRegistered<HomeUnifiedController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        appLogger.debug('ShopHomeScreen: HomeUnifiedController found, loading cached data');
        appLogger.debug('   📊 HomeUnifiedController State:');
        appLogger.debug('     • hasCachedData: ${unifiedController.hasCachedData}');
        appLogger.debug('     • isLoading: ${unifiedController.isLoading}');
        appLogger.debug('     • unifiedData != null: ${unifiedController.unifiedData != null}');
        appLogger.debug('     • cachedData != null: ${unifiedController.cachedData != null}');
        
        final cacheLoadStartTime = DateTime.now();
        // ⚡ INSTANT: Load cached data synchronously
        final hasCache = await unifiedController.loadCachedDataForInstantUI();
        final cacheLoadDuration = DateTime.now().difference(cacheLoadStartTime).inMilliseconds;
        
        appLogger.debug('   ⏱️ Cache load duration: ${cacheLoadDuration}ms');
        
        if (hasCache) {
          _hasCachedData = true;
          appLogger.info('⚡ ShopHomeScreen: Cached data loaded - UI will render instantly');
          appLogger.debug('ShopHomeScreen: Cache status - hasCachedData = true');
          
          // Log cached data structure
          if (unifiedController.cachedData != null) {
            final cached = unifiedController.cachedData!;
            appLogger.debug('   📦 Cached Data Structure:');
            appLogger.debug('     • banners: ${cached.banners?.length ?? 0} items');
            appLogger.debug('     • categories: ${cached.categories?.length ?? 0} items');
            appLogger.debug('     • brands: ${cached.brands?.length ?? 0} items');
            appLogger.debug('     • offers: ${cached.offers?.fold(0, (sum, offer) => sum + offer.data.length) ?? 0} items');
            appLogger.debug('     • popularStores: ${cached.popularStores?.length ?? 0} items');
          }
          
          // Trigger background refresh (SWR pattern)
          _refreshInBackground();
        } else {
          appLogger.warning('⚠️ ShopHomeScreen: No cached data found, will show loading shimmer');
          appLogger.debug('ShopHomeScreen: Cache status - hasCachedData = false');
          _refreshInBackground();
        }
      } else {
        appLogger.warning('ShopHomeScreen: HomeUnifiedController not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error('⚠️ ShopHomeScreen: Error loading cached data', e, stackTrace);
      _refreshInBackground();
    }
  }

  /// Standardized data loading method for module entry
  /// 
  /// [reload] - If true, forces fresh data fetch bypassing cache
  /// 
  /// This method ensures:
  /// 1. V2 loads top sections (Banners/Categories) via HomeUnifiedController
  /// 2. Legacy engine loads bottom section (All Restaurants) with correct totalSize (300+)
  /// 3. Each module entry is a clean slate - no state contamination
  Future<void> _loadData(bool reload) async {
    appLogger.debug('ShopHomeScreen: _loadData() called with reload=$reload');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('ShopHomeScreen: BFF v2 endpoint disabled, skipping data load');
      return;
    }
    
    try {
      if (Get.isRegistered<HomeUnifiedController>() && 
          Get.isRegistered<SplashController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        final splashController = Get.find<SplashController>();
        
        final moduleId = splashController.module?.id;
        appLogger.debug('ShopHomeScreen: Module ID = $moduleId');
        appLogger.info('ShopHomeScreen: Starting V2 data load (top sections: Banners/Categories/Brands/Offers)');
        
        // 1. Trigger V2 for Top Sections (Banners/Categories)
        appLogger.info('📡 ShopHomeScreen: Calling HomeUnifiedController.loadHomeData()');
        appLogger.debug('   📋 Request params: moduleId=$moduleId, forceRefresh=$reload, showLoading=false');
        appLogger.debug('   🎯 Target endpoint: ${AppConstants.useBffV2Endpoint ? "BFF v2 /home-unified" : "Legacy endpoints"}');
        
        final loadStartTime = DateTime.now();
        await unifiedController.loadHomeData(
          moduleId: moduleId,
          forceRefresh: reload,
          showLoading: false, // Silent refresh - no loading indicator
        );
        final loadDuration = DateTime.now().difference(loadStartTime).inMilliseconds;
        
        appLogger.info('✅ ShopHomeScreen: V2 data loaded (top sections) in ${loadDuration}ms');
        appLogger.debug('ShopHomeScreen: V2 load complete - Banners, Categories, Brands, and Offers should be available');
        
        // 📊 DETAILED API RESPONSE LOGGING
        appLogger.debug('📊 ShopHomeScreen: V2 API Response Details:');
        appLogger.debug('   - UnifiedController.hasCachedData: ${unifiedController.hasCachedData}');
        appLogger.debug('   - UnifiedController.isLoading: ${unifiedController.isLoading}');
        appLogger.debug('   - UnifiedController.unifiedData != null: ${unifiedController.unifiedData != null}');
        
        if (unifiedController.unifiedData != null) {
          final data = unifiedController.unifiedData!;
          appLogger.debug('   - UnifiedData structure:');
          appLogger.debug('     • banners: ${data.banners?.length ?? 0} items');
          appLogger.debug('     • categories: ${data.categories?.length ?? 0} items');
          appLogger.debug('     • brands: ${data.brands?.length ?? 0} items');
          appLogger.debug('     • offers: ${data.offers?.fold(0, (sum, offer) => sum + offer.data.length) ?? 0} items');
          appLogger.debug('     • popularStores: ${data.popularStores?.length ?? 0} items');
          
          // Log first few items of each section
          if (data.banners != null && data.banners!.isNotEmpty) {
            appLogger.debug('     • First banner: id=${data.banners!.first.id}, image=${data.banners!.first.imageFullUrl?.safeSubstring(50) ?? "null"}');
          }
          if (data.categories != null && data.categories!.isNotEmpty) {
            appLogger.debug('     • First category: id=${data.categories!.first.id}, name=${data.categories!.first.name}');
          }
          if (data.brands != null && data.brands!.isNotEmpty) {
            appLogger.debug('     • First brand: id=${data.brands!.first.id}, name=${data.brands!.first.name}');
          }
          if (data.offers != null && data.offers!.isNotEmpty && data.offers!.first.data.isNotEmpty) {
            appLogger.debug('     • First offer: id=${data.offers!.first.data.first.id}, title=${data.offers!.first.data.first.title}');
          }
          if (data.popularStores != null && data.popularStores!.isNotEmpty) {
            appLogger.debug('     • First store: id=${data.popularStores!.first.id}, name=${data.popularStores!.first.name}');
            appLogger.debug('     • First store coverPhoto: ${data.popularStores!.first.coverPhotoFullUrl?.safeSubstring(60) ?? "null"}');
            appLogger.debug('     • First store logo: ${data.popularStores!.first.logoFullUrl?.safeSubstring(60) ?? "null"}');
          }
        }
        
        // Log controller states after V2 load
        appLogger.debug('📊 ShopHomeScreen: Controller States After V2 Load:');
        if (Get.isRegistered<BannerController>()) {
          final bannerController = Get.find<BannerController>();
          appLogger.debug('   - BannerController:');
          appLogger.debug('     • bannerImageList: ${bannerController.bannerImageList?.length ?? 0} items');
          appLogger.debug('     • featuredBannerList: ${bannerController.featuredBannerList?.length ?? 0} items');
        }
        if (Get.isRegistered<CategoryController>()) {
          final categoryController = Get.find<CategoryController>();
          appLogger.debug('   - CategoryController:');
          appLogger.debug('     • categoryList: ${categoryController.categoryList?.length ?? 0} items');
        }
        if (Get.isRegistered<BrandsController>()) {
          final brandsController = Get.find<BrandsController>();
          appLogger.debug('   - BrandsController:');
          appLogger.debug('     • brandList: ${brandsController.brandList?.length ?? 0} items');
        }
        if (Get.isRegistered<OffersController>()) {
          final offersController = Get.find<OffersController>();
          appLogger.debug('   - OffersController:');
          appLogger.debug('     • offersMode.data: ${offersController.offersMode?.data.length ?? 0} items');
        }
        
        // 2. HARD RESET & TRIGGER LEGACY for the bottom section
        // This ensures we get the real total_size (300+) every time we enter
        // V2 must NEVER touch storeModel - only popularStoreList for top sections
        if (Get.isRegistered<StoreController>()) {
          final storeController = Get.find<StoreController>();
          final homeController = Get.find<HomeController>();
          final settings = homeController.business_Settings;
          
          // ⚡ FORCE HYDRATION: Force enable for Ecommerce module (ID: 3)
          // OR check business settings flag for other modules
          final allRestaurantsEnabled = moduleId == 3 
              ? true  // Force enable for Ecommerce module
              : (settings?.allRestaurantsSection?.toString() == '1' ||
                 (settings?.allRestaurantsSection is int && settings?.allRestaurantsSection == 1));
          
          appLogger.debug('ShopHomeScreen: allRestaurantsSection enabled = $allRestaurantsEnabled (moduleId: $moduleId)');
          
          if (allRestaurantsEnabled) {
            if (AppConstants.useBffV2Endpoint) {
              appLogger.info(
                  '🛡️ ShopHomeScreen: Unified-only policy - skipping legacy allStoreModel fetch');
              return;
            }
            appLogger.info('📡 ShopHomeScreen: Initializing legacy pagination engine (allStoreModel)');
            appLogger.debug('ShopHomeScreen: reload=true ensures clean state and correct totalSize (300+)');
            appLogger.debug('ShopHomeScreen: Calling storeController.getStoreList(1, true)');
            appLogger.debug('   📋 Request params: offset=1, reload=true, source=client');
            appLogger.debug('   🎯 Target endpoint: /api/v1/stores/get-stores/all?store_type=all&offset=1&limit=15');
            
            final storeLoadStartTime = DateTime.now();
            // Use reload: true to ensure we get the TRUE totalSize from API (300+)
            // This clears old module data and fetches fresh data
            final storeModelResult = await storeController.getStoreList(1, true);
            final storeLoadDuration = DateTime.now().difference(storeLoadStartTime).inMilliseconds;
            
            appLogger.info('✅ ShopHomeScreen: Store API call completed in ${storeLoadDuration}ms');
            appLogger.debug('   📡 API Response Result:');
            appLogger.debug('     • storeModelResult is null: ${storeModelResult == null}');
            
            // 📊 DETAILED STORE API RESPONSE LOGGING
            if (storeController.allStoreModel != null) {
              final allStoreModel = storeController.allStoreModel!;
              appLogger.debug('   📊 StoreModel Structure:');
              appLogger.debug('     • totalSize: ${allStoreModel.totalSize}');
              appLogger.debug('     • limit: ${allStoreModel.limit}');
              appLogger.debug('     • offset: ${allStoreModel.offset}');
              appLogger.debug('     • stores count: ${allStoreModel.stores?.length ?? 0}');
              
              if (allStoreModel.stores != null && allStoreModel.stores!.isNotEmpty) {
                appLogger.debug('   📋 First 3 Stores Details:');
                for (int i = 0; i < (allStoreModel.stores!.length < 3 ? allStoreModel.stores!.length : 3); i++) {
                  final store = allStoreModel.stores![i];
                  appLogger.debug('     [Store ${i + 1}]');
                  appLogger.debug('       • id: ${store.id}');
                  appLogger.debug('       • name: ${store.name}');
                  appLogger.debug('       • coverPhotoFullUrl: ${store.coverPhotoFullUrl?.safeSubstring(80) ?? "null"}');
                  appLogger.debug('       • logoFullUrl: ${store.logoFullUrl?.safeSubstring(80) ?? "null"}');
                  appLogger.debug('       • avgRating: ${store.avgRating}');
                  appLogger.debug('       • ratingCount: ${store.ratingCount}');
                  appLogger.debug('       • delivery: ${store.delivery}');
                  appLogger.debug('       • takeAway: ${store.takeAway}');
                  appLogger.debug('       • distance: ${store.distance}');
                  appLogger.debug('       • deliveryTime: ${store.deliveryTime}');
                  appLogger.debug('       • moduleId: ${store.moduleId}');
                }
              } else {
                appLogger.warning('   ⚠️ Store list is EMPTY after API call!');
              }
            } else {
              appLogger.warning('   ⚠️ allStoreModel is NULL after API call!');
            }
            
            // ⚡ TASK 3: FORCE UPDATE - Defensive repaint guard with post-frame callback
            if (storeController.allStoreModel != null && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && storeController.allStoreModel != null) {
                  storeController.update(['all_stores_list']);
                  appLogger.debug('⚡ Shop: Forced UI repaint for Stores (${storeController.allStoreModel!.stores?.length ?? 0} stores)');
                }
              });
            }
            
            final totalSize = storeController.allStoreModel?.totalSize;
            final storesCount = storeController.allStoreModel?.stores?.length ?? 0;
            appLogger.info('✅ ShopHomeScreen: Legacy pagination engine initialized (totalSize: $totalSize, stores: $storesCount)');
            appLogger.debug('ShopHomeScreen: Store list loaded - stores count: $storesCount');
            
            // Log StoreController state
            appLogger.debug('📊 ShopHomeScreen: StoreController State:');
            appLogger.debug('   - isLoading: ${storeController.isLoading}');
            appLogger.debug('   - allStoreModel != null: ${storeController.allStoreModel != null}');
            appLogger.debug('   - storeModel != null: ${storeController.storeModel != null}');
            appLogger.debug('   - popularStoreList: ${storeController.popularStoreList?.length ?? 0} items');
          } else {
            appLogger.debug('ShopHomeScreen: All Restaurants section disabled, skipping store list load');
          }
        } else {
          appLogger.warning('ShopHomeScreen: StoreController not registered');
        }
      } else {
        appLogger.warning('ShopHomeScreen: Required controllers not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error('⚠️ ShopHomeScreen: Data loading failed', e, stackTrace);
      appLogger.debug('   📋 Error Details:');
      appLogger.debug('     • Error type: ${e.runtimeType}');
      appLogger.debug('     • Error message: $e');
      appLogger.debug('     • Stack trace: $stackTrace');
      
      // Log controller states on error
      appLogger.debug('   📊 Controller States on Error:');
      appLogger.debug('     • HomeUnifiedController registered: ${Get.isRegistered<HomeUnifiedController>()}');
      appLogger.debug('     • StoreController registered: ${Get.isRegistered<StoreController>()}');
      appLogger.debug('     • SplashController registered: ${Get.isRegistered<SplashController>()}');
      if (Get.isRegistered<SplashController>()) {
        try {
          final splashController = Get.find<SplashController>();
          appLogger.debug('     • Module ID: ${splashController.module?.id}');
        } catch (err) {
          appLogger.debug('     • Error getting module: $err');
        }
      }
    }
  }

  /// ⚡ SWR: Refresh data in background (silent update)
  void _refreshInBackground() {
    appLogger.debug('ShopHomeScreen: _refreshInBackground() called');
    appLogger.debug('ShopHomeScreen: _hasCachedData = $_hasCachedData');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('ShopHomeScreen: BFF v2 endpoint disabled, skipping background refresh');
      return;
    }
    
    Future.delayed(const Duration(milliseconds: 100), () async {
      appLogger.debug('ShopHomeScreen: Starting background refresh (reload=${!_hasCachedData})');
      await _loadData(!_hasCachedData);
      appLogger.debug('ShopHomeScreen: Background refresh complete');
    });
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ TASK 2: Log render time and section count after first frame
    if (!_hasLoggedRenderTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasLoggedRenderTime && mounted) {
          _renderStopwatch.stop();
          final renderTime = _renderStopwatch.elapsedMilliseconds;
          
          // Count enabled sections
          int sectionCount = 0;
          try {
            final homeController = Get.find<HomeController>();
            final splashController = Get.find<SplashController>();
            final settings = homeController.business_Settings;
            final isEcommerce = splashController.module?.moduleType.toString() == AppConstants.ecommerce;
            
            if (settings != null) {
              if (settings.categoriesSection?.toString() == '1' || 
                  (settings.categoriesSection is int && settings.categoriesSection == 1) ||
                  isEcommerce) {
                sectionCount++;
              }
              if (settings.bannersSection?.toString() == '1' || 
                  (settings.bannersSection is int && settings.bannersSection == 1)) {
                sectionCount++;
              }
              if (settings.brandSection?.toString() == '1' || 
                  (settings.brandSection is int && settings.brandSection == 1)) {
                sectionCount++;
              }
              // Offers always shown for ecommerce
              if (isEcommerce) sectionCount++;
              // All Stores always shown for ecommerce (moduleId == 3)
              if (splashController.module?.id == 3) sectionCount++;
            }
          } catch (e) {
            // Ignore errors in counting
          }
          
          appLogger.info('⚡ ShopHomeScreen Sync-UI: Rendered with $sectionCount sections in ${renderTime}ms');
          _hasLoggedRenderTime = true;
        }
      });
    }
    
    // ⚡ BFF API v2: Wrap in GetBuilder for HomeUnifiedController
    // Shows shimmer only if no cached data AND loading
    return GetBuilder<HomeUnifiedController>(
      assignId: true,
      builder: (unifiedController) {
        if (unifiedController.hasError && !unifiedController.isLoading) {
          return ErrorStateView(
            onRetry: () {
              unifiedController.loadHomeData(
                forceRefresh: true,
                showLoading: true,
              );
            },
          );
        }
        // Show shimmer if no cached data and still loading
        if (!unifiedController.hasCachedData && unifiedController.isLoading) {
          return const ShopHomeSkeleton();
        }

        // ⚡ REFACTOR: Use HomeScreenDataProvider to reduce GetBuilder nesting
        return HomeScreenDataProvider(
          builder: ({
            required settings,
            required module,
            required isEcommerce,
            required isFood,
            required isGrocery,
          }) {
            // ⚡ PERFORMANCE: Removed verbose debug logs from build() to prevent main thread blocking
            // Log only on first render or when data structure changes significantly
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 1. BANNERS - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
              // ⚡ TITAN BOARD: Defensive UI guard - check registration before access
              !Get.isRegistered<BannerController>()
                  ? const SizedBox.shrink()
                  : GetBuilder<BannerController>(
                      id: 'banner_section', // ⚡ CRITICAL: Prevents rebuild storms
                      builder: (bannerController) {
                  // ⚡ PRIMARY: Check business_settings flag (backend is source of truth)
                  final isEnabled = settings == null ||
                      settings.bannersSection?.toString() == '1';
                  
                  // Check both featuredBannerList and bannerImageList for compatibility
                  final hasFeaturedBanners = bannerController.featuredBannerList != null &&
                      bannerController.featuredBannerList!.isNotEmpty;
                  final hasRegularBanners = bannerController.bannerImageList != null &&
                      bannerController.bannerImageList!.isNotEmpty;
                  final hasData = hasFeaturedBanners || hasRegularBanners;
                  final currentModuleId = module?.id;
                  final source = hasFeaturedBanners ? 'featured' : 'regular';
                  bannerController.ensureHomeBannersForCurrentModule(
                    currentModuleId: currentModuleId,
                    source: source,
                  );
                  final bannerModuleId = bannerController.currentBannerModuleId;
                  final resolvedBannerModuleId =
                      (hasData && currentModuleId != null && bannerModuleId == null)
                          ? currentModuleId
                          : bannerModuleId;
                  final hasCurrentModuleBanners = currentModuleId == null
                      ? hasData
                      : (hasData && resolvedBannerModuleId == currentModuleId);
                  final bannerCount = hasFeaturedBanners
                      ? bannerController.featuredBannerList!.length
                      : (hasRegularBanners
                          ? bannerController.bannerImageList!.length
                          : 0);
                  if (kDebugMode) {
                    debugPrint(
                        '[HOME_BANNER_RENDER] currentModuleId=$currentModuleId bannerModuleId=$resolvedBannerModuleId count=$bannerCount source=$source');
                    if (currentModuleId != null &&
                        resolvedBannerModuleId != null &&
                        resolvedBannerModuleId != currentModuleId) {
                      debugPrint(
                          '[HOME_BANNER_IGNORED_STALE] currentModuleId=$currentModuleId bannerModuleId=$resolvedBannerModuleId');
                    }
                    if (!hasCurrentModuleBanners) {
                      debugPrint(
                          '[HOME_BANNER_EMPTY] moduleId=$currentModuleId reason=module_banner_mismatch_or_empty');
                    }
                  }
                  
                  // ⚡ PERFORMANCE: Removed verbose banner logging from build() - causes jank at 60fps
                  // Log banner details only when banners first appear, not on every rebuild
                  
                        // Show if enabled in business_settings AND has data
                        return (isEnabled && hasCurrentModuleBanners)
                            ? const BannerView(isFeatured: false)
                            : const SizedBox.shrink();
                      },
                    ),
              // 2. CATEGORIES - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
              // ⚡ TITAN BOARD: Defensive UI guard - check registration before access
              // ✅ Collapse height when hidden to avoid white gaps/overlap in ecommerce
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return ClipRect(
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child: child,
                    ),
                  );
                },
                child: _showCategories
                    ? (!Get.isRegistered<CategoryController>()
                        ? const CategoryShimmer(key: ValueKey('category_shimmer'))
                        : GetBuilder<CategoryController>(
                            key: const ValueKey('category_content'),
                            builder: (categoryController) {
                              // ⚡ SWR: Only show shimmer if no cached data AND data is null
                              if (categoryController.categoryList == null &&
                                  !_hasCachedData) {
                                return const CategoryShimmer();
                              }

                              // ⚡ PRIMARY: Check business_settings flag (backend is source of truth)
                              final isEnabled = settings == null ||
                                  (settings.categoriesSection?.toString() ==
                                          '1' ||
                                      (settings.categoriesSection is int &&
                                          settings.categoriesSection == 1));
                              final categoryList = categoryController.categoryList;
                              final hasData =
                                  categoryList != null && categoryList.isNotEmpty;

                              // Show if enabled in business_settings AND has data
                              return (isEnabled && hasData)
                                  ? CategoryView(
                                      scrollController: _categoryScrollController)
                                  : const SizedBox.shrink();
                            },
                          ))
                    : const SizedBox.shrink(key: ValueKey('category_hidden')),
              ),

              // 3. BRANDS - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
              // ⚡ TITAN BOARD: Defensive UI guard - check registration before access
              !Get.isRegistered<BrandsController>()
                  ? const SizedBox.shrink()
                  : GetBuilder<BrandsController>(
                      id: 'brands_section', // 🔧 TASK 4: Unique ID prevents rebuild storms
                      builder: (brandsController) {
                  // ⚡ PRIMARY: Check business_settings flag (backend is source of truth)
                  final isEnabled = settings == null || 
                      (settings.brandSection?.toString() == '1' || 
                       (settings.brandSection is int && settings.brandSection == 1));
                  final hasData = brandsController.brandList != null &&
                      brandsController.brandList!.isNotEmpty;
                  
                  // ⚡ PERFORMANCE: Removed verbose brand logging from build() - causes jank at 60fps
                  // Log brand details only when brands first appear, not on every rebuild
                  
                        // Show if enabled in business_settings AND has data
                        return (isEnabled && hasData)
                            ? const BrandsViewWidget()
                            : const SizedBox.shrink();
                      },
                    ),

              // 4. OFFERS - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
              // For ecommerce, always show offers if data exists (regardless of flag)
              // ⚡ TITAN BOARD: Defensive UI guard - check registration before access
              !Get.isRegistered<OffersController>()
                  ? const SizedBox.shrink()
                  : GetBuilder<OffersController>(
                      id: 'offers_section', // ⚡ CRITICAL: Prevents rebuild storms
                      builder: (offersController) {
                  final hasData = offersController.offersMode?.data != null &&
                      offersController.offersMode!.data.isNotEmpty;
                  
                  // For ecommerce module, always show offers if data exists
                  final shouldShowForEcommerce = isEcommerce && hasData;
                  
                  // For other modules, check business_settings flag
                  final isEnabled = settings == null || 
                      (settings.topStoresOffersNearMeSection?.toString() == '1' || 
                       (settings.topStoresOffersNearMeSection is int && settings.topStoresOffersNearMeSection == 1) ||
                       settings.offersSection?.toString() == '1' || 
                       (settings.offersSection is int && settings.offersSection == 1));
                  
                  final shouldShow = shouldShowForEcommerce || (isEnabled && hasData);
                  
                  // ⚡ PERFORMANCE: Removed verbose offer logging from build() - causes jank at 60fps
                  // Log offer details only when offers first appear, not on every rebuild
                  
                        // Show if should show AND has data
                        return (shouldShow && hasData)
                            ? const OffersView()
                            : const SizedBox.shrink();
                      },
                    ),

              // 5. POPULAR STORES - ⚠️ COMMENTED OUT: User requested only Categories, Banners, Brands, Offers, and All Stores
              // if (settings?.popularStoresSection?.toString() == '1')
              //   GetBuilder<StoreController>(
              //     builder: (storeController) {
              //       final hasData = (storeController.popularStoreList != null &&
              //               storeController.popularStoreList!.isNotEmpty) ||
              //           (storeController.storeModel != null &&
              //               storeController.storeModel!.stores != null &&
              //               storeController.storeModel!.stores!.isNotEmpty);
              //       return hasData
              //           ? const Column(
              //               children: [
              //                 SizedBox(height: Dimensions.paddingSizeDefault),
              //                 ProductWithCategoriesView(fromShop: true),
              //               ],
              //             )
              //           : const SizedBox.shrink();
              //     },
              //   ),

              const SizedBox.shrink(),
              ],
            );
          },
        );
      },
    );
  }
}
