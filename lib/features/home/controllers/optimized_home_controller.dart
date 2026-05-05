
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/api/api_call_manager.dart';
import 'package:sixam_mart/common/api/optimized_api_client.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
// import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart'; // Removed - not needed for home screen
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/test/pharmacy_api_test.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/my_coupon/controllers/my_coupon_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/cache/smart_preloader.dart';

/// Optimized home data loading with intelligent caching and deduplication
class OptimizedHomeDataLoader {
  static final OptimizedHomeDataLoader _instance =
      OptimizedHomeDataLoader._internal();
  factory OptimizedHomeDataLoader() => _instance;
  OptimizedHomeDataLoader._internal();

  bool _isLoading = false;
  DateTime? _lastLoadTime;
  static const Duration _minLoadInterval = Duration(seconds: 2);

  /// Load home data with intelligent optimization
  static Future<void> loadData(
    BuildContext context,
    bool reload, {
    bool fromModule = false,
    List<String>? specificSections,
    bool allowDuringComprehensiveLoading = false, // Allow when called from ComprehensiveHomeLoader
  }) async {
    final instance = OptimizedHomeDataLoader();
    final loadingManager = LoadingStateManager();

    // Prevent rapid successive calls
    if (instance._isLoading) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Home data loading already in progress, skipping');
      }
      return;
    }

    // Check if any loading operation is in progress
    // Allow if called from ComprehensiveHomeLoader (comprehensive loading is expected)
    if (!allowDuringComprehensiveLoading) {
      if (loadingManager.isAnyLoading) {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint(
              '🚫 Cannot start home data loading - another operation in progress');
        }
        return;
      }
    } else {
      // When called from ComprehensiveHomeLoader, only block if other operations (not comprehensive) are in progress
      if (loadingManager.isSplashLoading || loadingManager.isHomeLoading || loadingManager.isBackgroundRefreshing) {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint(
              '🚫 Cannot start home data loading - another operation in progress (splash/home/background)');
        }
        return;
      }
    }

    // Check minimum interval between loads
    if (!reload &&
        instance._lastLoadTime != null &&
        DateTime.now().difference(instance._lastLoadTime!) <
            OptimizedHomeDataLoader._minLoadInterval) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        debugPrint('🚫 Too soon since last load, skipping');
      }
      return;
    }

    instance._isLoading = true;
    instance._lastLoadTime = DateTime.now();

    try {
      // Ensure headers are valid before loading data
      Get.find<OptimizedApiClient>().ensureHeadersAreValid();

      // ⚡ CRITICAL: Load business settings FIRST (blocking) - needed to filter sections
      // Zone sync can run in parallel
      await _loadBusinessSettings();
      final criticalFutures = <Future<void>>[
        Get.find<LocationController>().syncZoneData(shouldRedirect: false), // Can run in parallel
      ];

      // Clear flash sale if from module (synchronous, fast)
      Get.find<FlashSaleController>().setEmptyFlashSale(fromModule: fromModule);

      // Load cart data only if not already loaded or stale (non-blocking)
      final cartController = Get.find<CartController>();
      if (cartController.cartList.isEmpty ||
          cartController.lastSuccessfulCartLoad == null ||
          DateTime.now().difference(cartController.lastSuccessfulCartLoad!) >
              const Duration(minutes: 5)) {
        debugPrint('🔄 OptimizedHomeController: Loading stale cart data');
        // Don't await - let it load in background
        cartController.getCartDataOnline();
      } else {
        debugPrint('💾 OptimizedHomeController: Using cached cart data');
      }

      // Checkout initialization removed - not needed for home screen
      // MyFatoorah calls will only happen when user actually goes to checkout

      // ⚡ PERFORMANCE: Start module-specific data loading immediately in parallel
      // Don't wait for business settings - sections will use cached/default values
      final moduleDataFuture = _loadModuleSpecificData(reload, fromModule, specificSections);

      // Wait for remaining critical operations and module data in parallel
      await Future.wait([
        ...criticalFutures,
        moduleDataFuture,
      ]);

      // Load user-specific data if logged in
      if (AuthHelper.isLoggedIn()) {
        await _loadUserSpecificData(reload);
      }

      // Start smart preloading in background - ONLY if a module is selected
      final splashController = Get.find<SplashController>();
      if (splashController.module != null) {
        _startSmartPreloading();
      }

      // Load fallback data if no module
      await _loadFallbackData();

      // Load parcel data if applicable
      await _loadParcelData();

      // Load pharmacy data if applicable
      await _loadPharmacyData(reload);

      // Run pharmacy API tests in debug mode
      if (kDebugMode) {
        final splashController = Get.find<SplashController>();
        if (splashController.module?.moduleType.toString() == AppConstants.pharmacy) {
          try {
            await _runPharmacyApiTests();
          } catch (e) {
            debugPrint('❌ Error running pharmacy API tests: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Home data loading completed successfully');
        _printPerformanceStats();
      }

      // Reset the skip zone validation flag after all home data loading is complete
      if (Get.isRegistered<LocationController>()) {
        final locationController = Get.find<LocationController>();
        if (locationController.skipZoneValidation) {
          debugPrint(
              '🏠 HomeController: Resetting skip zone validation flag after data loading');
          locationController.resetSkipZoneValidation();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading home data: $e');
      }
    } finally {
      instance._isLoading = false;
    }
  }

  /// Load business settings (always required)
  /// ⚡ OPTIMIZATION: Skip separate API call if already loaded from app-init or v2/home-unified
  static Future<void> _loadBusinessSettings() async {
    final homeController = Get.find<HomeController>();
    
    // ⚡ OPTIMIZATION: If already loaded from app-init, skip API call
    // Business settings are set in HomeController during splash screen app-init
    if (homeController.business_Settings != null) {
      if (kDebugMode) {
        debugPrint('✅ OptimizedHomeController: Business settings already loaded (from app-init), skipping API call');
      }
      return;
    }
    
    // ⚡ DEPRECATED: Business settings now come from /api/v1/app-init (startup) and /api/v2/home-unified (home screen)
    // The old /api/v1/business-settings/mobile-app-home-screen-setup endpoint is deprecated
    // Business settings are automatically loaded via:
    // 1. AppInitService during splash (from /api/v1/app-init)
    // 2. HomeUnifiedController for home screen (from /api/v2/home-unified)
    if (kDebugMode) {
      debugPrint('⚡ OptimizedHomeController: Business settings come from app-init and home-unified endpoints (deprecated endpoint removed)');
    }
    // No action needed - business settings are loaded via modern endpoints
  }

  /// Load module-specific data based on current module
  /// ⚡ BFF API v2: Tries home-unified endpoint first, falls back to individual calls
  static Future<void> _loadModuleSpecificData(
    bool reload,
    bool fromModule,
    List<String>? specificSections,
  ) async {
    final splashController = Get.find<SplashController>();

    if (splashController.module == null ||
        splashController.configModel?.moduleConfig?.module?.isParcel == true ||
        splashController.configModel?.moduleConfig?.module?.isTaxi == true) {
      return;
    }

    // ⚡ CRITICAL: Filter sections based on business settings BEFORE bootstrap check
    // This prevents loading disabled sections even if bootstrap succeeds
    var filteredSections = specificSections;
    if (filteredSections != null) {
      filteredSections = _filterEnabledSections(filteredSections);
      if (filteredSections.isEmpty) {
        if (kDebugMode) {
          debugPrint('🚫 OptimizedHomeController: All requested sections are disabled, skipping load');
        }
        return;
      }
    }

    // ⚡ BFF API v2: EXCLUSIVE USE of unified endpoint
    // This replaces 17 API calls with 1 single call, reducing load time by 80%
    if (AppConstants.useBffV2Endpoint) {
      final success = await _tryLoadFromHomeUnified(reload);
      if (success) {
        if (kDebugMode) {
          debugPrint('✅ OptimizedHomeController: Loaded from unified endpoint (17 calls → 1 call)');
        }
        return; // ✅ Success - exit early
      }
      
      // Only fallback if unified endpoint completely fails
      if (kDebugMode) {
        debugPrint('⚠️ OptimizedHomeController: Unified endpoint failed, falling back to individual calls');
      }
    }

    // ⚠️ FALLBACK ONLY: Use individual API calls ONLY if unified endpoint is disabled or fails
    // This should rarely happen in production once unified endpoint is stable
    if (kDebugMode) {
      debugPrint('🌐 OptimizedHomeController: Loading from individual API calls (fallback mode)');
    }

    // Load sections individually (use filtered sections)
    await _loadSectionsIndividually(reload, fromModule, filteredSections);
  }

  /// ⚡ BFF API v2: Try loading from home-unified endpoint
  static Future<bool> _tryLoadFromHomeUnified(bool reload) async {
    try {
      // Check if HomeUnifiedController is registered
      if (!Get.isRegistered<HomeUnifiedController>()) {
        if (kDebugMode) {
          debugPrint('⚠️ OptimizedHomeController: HomeUnifiedController not registered');
        }
        return false;
      }

      final unifiedController = Get.find<HomeUnifiedController>();
      final success = await unifiedController.loadHomeData(
        forceRefresh: reload,
        showLoading: false,
      );

      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ OptimizedHomeController: Error loading from home-unified: $e');
      }
      return false;
    }
  }


  /// Filter sections based on business settings
  /// Only returns sections that are enabled in business settings
  static List<String> _filterEnabledSections(List<String> sections) {
    try {
      final homeController = Get.find<HomeController>();
      final businessSettings = homeController.business_Settings;
      
      if (businessSettings == null) {
        if (kDebugMode) {
          debugPrint('⚠️ OptimizedHomeController: Business settings not loaded yet, loading all sections');
        }
        return sections; // Load all if settings not available yet
      }

      final enabledSections = <String>[];
      
      for (final section in sections) {
        bool isEnabled = true;
        
        switch (section) {
          case 'categories':
            isEnabled = businessSettings.categoriesSection?.toString() == '1';
            if (!isEnabled && kDebugMode) {
              debugPrint('🚫 OptimizedHomeController: Skipping categories (disabled in business settings)');
            }
            break;
          case 'brands':
            isEnabled = businessSettings.brandSection?.toString() == '1';
            if (!isEnabled && kDebugMode) {
              debugPrint('🚫 OptimizedHomeController: Skipping brands (disabled in business settings)');
            }
            break;
          case 'stores':
            // Only load stores if popularStoresSection is enabled
            isEnabled = businessSettings.popularStoresSection?.toString() == '1';
            if (!isEnabled && kDebugMode) {
              debugPrint('🚫 OptimizedHomeController: Skipping stores (popularStoresSection disabled in business settings)');
            }
            break;
          case 'banners':
            // Only load banners if bannersSection is enabled
            isEnabled = businessSettings.bannersSection?.toString() == '1';
            if (!isEnabled && kDebugMode) {
              debugPrint('🚫 OptimizedHomeController: Skipping banners (disabled in business settings)');
            }
            break;
          case 'offers':
            // Offers don't have a business settings flag, but we'll load them if requested
            // For module 7, if user only wants stores/categories, they won't request offers
            isEnabled = true; // Load if requested
            break;
          case 'items':
          case 'campaigns':
          case 'profile':
          case 'checkout':
          case 'wallet':
            // These sections are only loaded if explicitly requested (not for basic home screen)
            // They don't have business settings flags, so load if requested
            isEnabled = true; // Load if explicitly requested
            break;
          default:
            isEnabled = false; // Unknown sections are disabled by default
        }
        
        if (isEnabled) {
          enabledSections.add(section);
        }
      }
      
      if (kDebugMode && enabledSections.length != sections.length) {
        debugPrint('✅ OptimizedHomeController: Filtered sections - ${sections.length} → ${enabledSections.length} (removed ${sections.length - enabledSections.length} disabled sections)');
      }
      
      return enabledSections;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ OptimizedHomeController: Error filtering sections: $e - loading all sections');
      }
      return sections; // Fallback to all sections on error
    }
  }

  /// Load sections individually (fallback when bootstrap is not available)
  /// ⚡ PERFORMANCE: Prioritizes critical sections (banners, popular stores) first
  /// Non-critical sections (categories) load in background after UI renders
  static Future<void> _loadSectionsIndividually(
    bool reload,
    bool fromModule,
    List<String>? specificSections,
  ) async {
    // Define section loading functions
    final sectionLoaders = <String, Future<void> Function()>{
      'banners': () => loadBanners(reload),
      'stores': () => loadStores(reload, fromModule),
      'categories': () => loadCategories(reload),
      'items': () => _loadItems(reload),
      'campaigns': () => _loadCampaigns(reload),
      'brands': () => loadBrands(reload),
      'offers': () => loadOffers(reload),
      'profile': () => _loadProfile(reload),
      'checkout': () => _loadCheckout(),
      'wallet': () => _loadWallet(),
    };

    // Load specific sections or only enabled sections (not all sections)
    var sectionsToLoad = specificSections;
    
    // Check if this is ecommerce module 3
    final splashController = Get.find<SplashController>();
    final isEcommerce = splashController.module?.moduleType.toString() == AppConstants.ecommerce;
    final moduleId = splashController.module?.id;
    
    // If no specific sections requested, only load sections that are enabled in business settings
    if (sectionsToLoad == null) {
      try {
        final homeController = Get.find<HomeController>();
        final businessSettings = homeController.business_Settings;
        
        sectionsToLoad = <String>[];
        
        // ⚡ ECOMMERCE MODULE 3: Always load categories and stores, plus banners/brands if enabled
        if (isEcommerce && moduleId == 3) {
          // Always load both - UI will check business settings and data before showing
          sectionsToLoad.add('categories');
          sectionsToLoad.add('stores');
          
          // Also load banners and brands if enabled in business settings
          if (businessSettings?.bannersSection?.toString() == '1') {
            sectionsToLoad.add('banners');
          }
          if (businessSettings?.brandSection?.toString() == '1') {
            sectionsToLoad.add('brands');
          }
          if (businessSettings?.topStoresOffersNearMeSection?.toString() == '1') {
            sectionsToLoad.add('offers');
          }
          
          if (kDebugMode) {
            debugPrint('✅ OptimizedHomeController: Ecommerce module 3 - Loading sections: ${sectionsToLoad.join(", ")}');
          }
        } else {
          // Other modules: strict business settings check
          if (businessSettings?.categoriesSection?.toString() == '1') {
            sectionsToLoad.add('categories');
          }
          if (businessSettings?.popularStoresSection?.toString() == '1') {
            sectionsToLoad.add('stores');
          }
          if (businessSettings?.bannersSection?.toString() == '1') {
            sectionsToLoad.add('banners');
          }
          if (businessSettings?.brandSection?.toString() == '1') {
            sectionsToLoad.add('brands');
          }
          
          if (kDebugMode) {
            debugPrint('✅ OptimizedHomeController: Default sections to load (strict business settings): ${sectionsToLoad.join(", ")}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ OptimizedHomeController: Error getting business settings: $e');
        }
        sectionsToLoad = <String>[]; // Don't load anything if settings unavailable
      }
    }
    
    // ⚡ CRITICAL: Filter out disabled sections based on business settings
    sectionsToLoad = _filterEnabledSections(sectionsToLoad);

    // ⚡ ECOMMERCE MODULE 3: Parallel loading - categories and stores together (FASTER!)
    if (isEcommerce && moduleId == 3) {
      final futures = <Future<void>>[];
      if (sectionsToLoad.contains('categories')) {
        futures.add(sectionLoaders['categories']!());
      }
      if (sectionsToLoad.contains('stores')) {
        futures.add(sectionLoaders['stores']!());
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures);
        if (kDebugMode) {
          debugPrint('✅ OptimizedHomeController: Categories and stores loaded in parallel (FAST!)');
        }
      }
    } else {
      // Other modules: Load critical sections first, then non-critical
      final criticalSections = <String>[];
      final nonCriticalSections = <String>[];

      for (final section in sectionsToLoad) {
        if (['categories', 'banners', 'stores'].contains(section)) {
          criticalSections.add(section);
        } else {
          nonCriticalSections.add(section);
        }
      }

      // Phase 1: Load critical sections first (blocking)
      final criticalFutures = <Future<void>>[];
      for (final section in criticalSections) {
        if (sectionLoaders.containsKey(section)) {
          criticalFutures.add(sectionLoaders[section]!());
        }
      }

      if (criticalFutures.isNotEmpty) {
        await Future.wait(criticalFutures);
        if (kDebugMode) {
          debugPrint('✅ OptimizedHomeController: Critical sections loaded');
        }
      }

      // Phase 2: Load non-critical sections in background (non-blocking)
      if (nonCriticalSections.isNotEmpty) {
        Future.microtask(() async {
          final nonCriticalFutures = <Future<void>>[];
          for (final section in nonCriticalSections) {
            if (sectionLoaders.containsKey(section)) {
              nonCriticalFutures.add(sectionLoaders[section]!());
            }
          }
          await Future.wait(nonCriticalFutures);
          if (kDebugMode) {
            debugPrint('✅ OptimizedHomeController: Non-critical sections loaded');
          }
        });
      }
    }
  }

  /// Load banners with caching
  static Future<void> loadBanners(bool reload) async {
    // 🚫 TASK 1: TOTAL LEGACY DECOMMISSION - Skip if V2 endpoint is enabled
    // Banners must be populated ONLY via HomeUnifiedController
    if (AppConstants.useBffV2Endpoint) {
      if (kDebugMode) {
        debugPrint('🚫 OptimizedHomeController: Skipping loadBanners - V2 endpoint enabled (HomeUnifiedController handles banners)');
      }
      return;
    }
    
    final bannerController = Get.find<BannerController>();
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id ?? 0;

    // Load main banners - force API call when reloading
    await ApiCallManager.instance.executeCall(
      'banners_module_$moduleId',
      () => bannerController.getBannerList(reload,
          dataSource: reload ? DataSourceEnum.client : DataSourceEnum.local),
      cacheDuration: const Duration(minutes: 10),
    ).then((data) {
      if (data != null) bannerController.setBannerModelFromCache(data);
    });

    // Load promotional banners
    await ApiCallManager.instance.executeCall(
      'banners_promotional_module_$moduleId',
      () => bannerController.getPromotionalBannerList(reload),
      cacheDuration: const Duration(minutes: 10),
    ).then((data) {
      if (data != null) bannerController.setPromotionalBannerFromCache(data);
    });
  }

  /// Load stores with intelligent batching (for all modules)
  /// ⚡ PERFORMANCE: Prioritizes popular stores first, all stores load in background
  static Future<void> loadStores(bool reload, bool fromModule) async {
    final splashController = Get.find<SplashController>();

    // Load stores for all modules that support stores
    final moduleType = splashController.module?.moduleType.toString();
    if (moduleType != AppConstants.food &&
        moduleType != AppConstants.grocery &&
        moduleType != AppConstants.pharmacy &&
        moduleType != AppConstants.ecommerce) {
      if (kDebugMode) {
        debugPrint('🚫 Skipping store loading for module type: $moduleType');
      }
      return;
    }

    final storeController = Get.find<StoreController>();

    // 🚫 TASK 1: TOTAL LEGACY DECOMMISSION - Skip popular stores if V2 endpoint is enabled
    // Popular stores must be populated ONLY via HomeUnifiedController
    if (AppConstants.useBffV2Endpoint) {
      if (kDebugMode) {
        debugPrint('🚫 OptimizedHomeController: Skipping getPopularStoreList - V2 endpoint enabled (HomeUnifiedController handles popular stores)');
      }
      // Still load all stores (storeModel) for pagination - this is NOT popular stores
      // This is the legacy pagination engine that handles the "All Restaurants" section
      // V2 only handles popularStoreList, NOT storeModel
    } else {
      // ⚡ PERFORMANCE: Load popular stores first (critical for home screen)
      // This is what users see first, so prioritize it
      try {
        await storeController.getPopularStoreList(
          reload,
          'all',
          false,
          dataSource: reload ? DataSourceEnum.client : DataSourceEnum.local,
        );
        if (kDebugMode) {
          debugPrint('✅ OptimizedHomeController: Popular stores loaded (critical section)');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ OptimizedHomeController: Popular stores load failed: $e');
        }
      }
    }

    // Load other store types in background (non-blocking)
    // Visit-again and all stores can load after popular stores are shown
    Future.microtask(() async {
      try {
        // Load visit again stores if logged in (NOT guest users)
        if (AuthHelper.isLoggedIn() && !AuthHelper.isGuestLoggedIn()) {
          await ApiCallManager.instance.executeCall(
            'stores_visit_again',
            () => storeController.getVisitAgainStoreList(fromModule: fromModule),
            cacheDuration: const Duration(minutes: 15),
          );
        }

        // All stores - load in background
        // ⚠️ CRITICAL: When reload=true, bypass cache to get fresh data
        // Otherwise ApiCallManager returns stale cache and overwrites fresh API data
        if (reload) {
          // Force fresh API call without cache wrapper
          if (kDebugMode) {
            debugPrint('🔄 OptimizedHomeController: reload=true - bypassing cache, calling API directly');
          }
          await storeController.getStoreList(1, reload);
        } else {
          // Use cache when reload=false
          await ApiCallManager.instance.executeCall<dynamic>(
            'stores_all_module_${splashController.module?.id ?? 0}',
            () => storeController.getStoreList(1, reload),
          ).then((data) async {
          if (data != null) {
            try {
              // 🔧 FIX: Handle type conversion from cache (Map) to StoreModel
              StoreModel? storeModel;
              
              if (data is StoreModel) {
                // Already a StoreModel (from fresh API call)
                storeModel = data;
              } else if (data is Map<String, dynamic>) {
                // Cached data is JSON Map - convert to StoreModel
                if (kDebugMode) {
                  debugPrint('🔄 OptimizedHomeController: Converting cached Map to StoreModel');
                }
                storeModel = StoreModel.fromJson(data);
                
                // ✅ VALIDATION: Check if cache data looks valid
                // Backend should return 300+ stores, so cache with < 50 is suspicious
                // This catches stale cache from before backend fix
                if (storeModel.totalSize != null && storeModel.totalSize! < 50) {
                  // Suspiciously low store count - likely stale/corrupted cache
                  if (kDebugMode) {
                    debugPrint('⚠️ OptimizedHomeController: Cache has suspiciously low store count (${storeModel.totalSize} stores). Expected 300+. This is likely stale cache from before backend fix. Clearing cache and fetching fresh data...');
                  }
                  // Clear the invalid cache
                  final cacheKey = 'stores_all_module_${splashController.module?.id ?? 0}';
                  await ApiCallManager.instance.clearCache(cacheKey);
                  // Fetch fresh data immediately
                  if (kDebugMode) {
                    debugPrint('🔄 OptimizedHomeController: Fetching fresh store data from API after cache validation failure...');
                  }
                  storeController.getStoreList(1, true).catchError((Object error) {
                    if (kDebugMode) {
                      debugPrint('❌ OptimizedHomeController: Failed to fetch fresh store data: $error');
                    }
                    return null; // Return null for catchError
                  });
                  // Don't use this invalid cache
                  return;
                }
              } else {
                throw FormatException('Unexpected data type: ${data.runtimeType}. Expected StoreModel or Map<String, dynamic>');
              }
              
              storeController.setStoreDataFromCache(storeModel: storeModel);
              if (kDebugMode) {
                debugPrint('✅ OptimizedHomeController: Store data loaded from cache - totalSize: ${storeModel.totalSize}, stores: ${storeModel.stores?.length ?? 0}');
              }
            } catch (e, stackTrace) {
              // 🧹 CACHE ERROR HANDLING: Clear corrupted cache and fetch fresh
              if (kDebugMode) {
                debugPrint('❌ OptimizedHomeController: Cache parsing failed: $e');
                debugPrint('   Stack trace: $stackTrace');
                debugPrint('   Data type: ${data.runtimeType}');
                debugPrint('🧹 Clearing invalid cache and fetching fresh data...');
              }
              
              // Clear the corrupted cache entry
              final cacheKey = 'stores_all_module_${splashController.module?.id ?? 0}';
              await ApiCallManager.instance.clearCache(cacheKey);
              
              // Fetch fresh data from API (force refresh)
              if (kDebugMode) {
                debugPrint('🔄 OptimizedHomeController: Fetching fresh store data from API...');
              }
              storeController.getStoreList(1, true).catchError((error) {
                if (kDebugMode) {
                  debugPrint('❌ OptimizedHomeController: Failed to fetch fresh store data: $error');
                }
                return null; // Return null for catchError
              });
            }
          }
          });
        }

        if (kDebugMode) {
          debugPrint('✅ OptimizedHomeController: All stores loaded (background)');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('⚠️ OptimizedHomeController: Background store loading failed: $e');
          debugPrint('   Stack trace: $stackTrace');
        }
      }
    });
  }

  /// Load categories with caching
  /// ⚡ PERFORMANCE: Categories is the FIRST section, so it's critical
  /// Loads first 4 categories immediately, rest in background
  static Future<void> loadCategories(bool reload) async {
    // 🚫 TASK 1: TOTAL LEGACY DECOMMISSION - Skip if V2 endpoint is enabled
    // Categories must be populated ONLY via HomeUnifiedController
    if (AppConstants.useBffV2Endpoint) {
      if (kDebugMode) {
        debugPrint('🚫 OptimizedHomeController: Skipping loadCategories - V2 endpoint enabled (HomeUnifiedController handles categories)');
      }
      return;
    }
    
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id ?? 0;
    
    // ⚡ PERFORMANCE: Categories is FIRST section - load it immediately (not background)
    // The controller will show first 4 categories immediately, then load rest
    try {
      await ApiCallManager.instance.executeCall(
        'categories_module_$moduleId',
        () => Get.find<CategoryController>().getCategoryList(reload,
            expectedModuleId: moduleId,
            dataSource: reload ? DataSourceEnum.client : DataSourceEnum.local),
        cacheDuration: const Duration(minutes: 15),
      ).then((data) {
        if (data != null) {
          Get.find<CategoryController>().setCategoryListFromCache(
            data,
            expectedModuleId: moduleId,
          );
        }
      });
      
      if (kDebugMode) {
        debugPrint('✅ OptimizedHomeController: Categories loaded (first section - critical)');
      }
    } catch (e) {
      // Categories is critical, but don't fail entire home load
      if (kDebugMode) {
        debugPrint('⚠️ OptimizedHomeController: Categories load failed: $e');
      }
    }
  }

  /// Load items based on module type
  static Future<void> _loadItems(bool reload) async {
    final splashController = Get.find<SplashController>();
    final itemController = Get.find<ItemController>();
    final moduleId = splashController.module?.id ?? 0;

    if (splashController.module?.moduleType.toString() ==
        AppConstants.ecommerce) {
      // Load ecommerce items concurrently
      final itemFutures = <Future<void>>[
        ApiCallManager.instance.executeCall(
          'items_featured_module_$moduleId',
          () => itemController.getFeaturedCategoriesItemList(false, false),
          cacheDuration: const Duration(minutes: 10),
        ).then((data) {
          if (data != null) itemController.setItemDataFromCache('featured', data);
        }),
        ApiCallManager.instance.executeCall(
          'items_discounted_module_$moduleId',
          () => itemController.getDiscountedItemList(reload, false, 'all'),
          cacheDuration: const Duration(minutes: 10),
        ).then((data) {
          if (data != null) itemController.setItemDataFromCache('discounted', data);
        }),
        ApiCallManager.instance.executeCall(
          'items_popular_module_$moduleId',
          () => itemController.getPopularItemList(reload, 'all', false),
          cacheDuration: const Duration(minutes: 10),
        ).then((data) {
          if (data != null) itemController.setItemDataFromCache('popular', data);
        }),
        ApiCallManager.instance.executeCall(
          'items_reviewed_module_$moduleId',
          () => itemController.getReviewedItemList(reload, 'all', false),
          cacheDuration: const Duration(minutes: 10),
        ).then((data) {
          if (data != null) itemController.setItemDataFromCache('reviewed', data);
        }),
        ApiCallManager.instance.executeCall(
          'items_recommended_module_$moduleId',
          () => itemController.getRecommendedItemList(reload, 'all', false),
          cacheDuration: const Duration(minutes: 10),
        ).then((data) {
          if (data != null) itemController.setItemDataFromCache('recommended', data);
        }),
      ];

      await Future.wait(itemFutures);
    }

    // Load flash sales for grocery only
    if (splashController.module?.moduleType.toString() ==
        AppConstants.grocery) {
      await ApiCallManager.instance.executeCall(
        'flash_sales_module_$moduleId',
        () => Get.find<FlashSaleController>().getFlashSale(reload, false),
      );
    }
  }

  /// Load campaigns (only for food/grocery modules)
  static Future<void> _loadCampaigns(bool reload) async {
    final splashController = Get.find<SplashController>();

    // Only load campaigns for food, grocery, or pharmacy modules
    final moduleType = splashController.module?.moduleType.toString();
    if (moduleType != AppConstants.food &&
        moduleType != AppConstants.grocery &&
        moduleType != AppConstants.pharmacy) {
      if (kDebugMode) {
        debugPrint('🚫 Skipping campaign loading for module type: $moduleType');
      }
      return;
    }

    final campaignController = Get.find<CampaignController>();
    final moduleId = splashController.module?.id ?? 0;

    final campaignFutures = <Future<void>>[
      ApiCallManager.instance.executeCall(
        'campaigns_basic_module_$moduleId',
        () => campaignController.getBasicCampaignList(reload),
        cacheDuration: const Duration(minutes: 10),
      ).then((data) {
        if (data != null) campaignController.setBasicCampaignListFromCache(data);
      }),
      ApiCallManager.instance.executeCall(
        'campaigns_item_module_$moduleId',
        () => campaignController.getItemCampaignList(reload),
        cacheDuration: const Duration(minutes: 10),
      ).then((data) {
        if (data != null) campaignController.setItemCampaignListFromCache(data);
      }),
    ];

    await Future.wait(campaignFutures);
  }

  /// Load brands for all modules
  static Future<void> loadBrands(bool reload) async {
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id ?? 0;
    
    debugPrint('🏷️ Loading brands for module $moduleId...');
    // ⚠️ CRITICAL FIX: Call controller method directly instead of wrapping with ApiCallManager
    // ApiCallManager disk cache was bypassing the controller method and returning raw JSON
    // The controller already has its own cache logic via DataSourceEnum
    // Pass forceRefresh=true when reload=true to ensure fresh data is loaded even if _brandList is populated
    await Get.find<BrandsController>().getBrandList(
        dataSource: reload ? DataSourceEnum.client : DataSourceEnum.local,
        forceRefresh: reload);
  }

  /// Load offers for all modules
  static Future<void> loadOffers(bool reload) async {
    if (AppConstants.useBffV2Endpoint) {
      return;
    }
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id ?? 0;
    
    await ApiCallManager.instance.executeCall(
      'offers_module_$moduleId',
      () => Get.find<OffersController>().getOffers(),
      cacheDuration: const Duration(minutes: 10),
    ).then((data) {
      if (data != null) Get.find<OffersController>().setOffersFromCache(data);
    });
  }

  /// Load user profile data
  static Future<void> _loadProfile(bool reload) async {
    if (AuthHelper.isLoggedIn()) {
      await ApiCallManager.instance.executeCall(
        'profile',
        () => Get.find<ProfileController>().getUserInfo(),
      );
    }
  }

  /// Load checkout data - disabled for home screen optimization
  static Future<void> _loadCheckout() async {
    // Checkout initialization removed - MyFatoorah calls only needed at checkout
    // await Get.find<CheckoutController>().initiate(Get.context!);
  }

  /// Load wallet data
  static Future<void> _loadWallet() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<KaidhaSubscriptionController>().get_Wallet_Kaidh();
    });
  }

  /// Load user-specific data
  static Future<void> _loadUserSpecificData(bool reload) async {
    final userFutures = <Future<void>>[
      ApiCallManager.instance.executeCall(
        'user_profile',
        () => Get.find<ProfileController>().getUserInfo(),
        cacheDuration: const Duration(minutes: 30),
      ),
      ApiCallManager.instance.executeCall(
        'notifications',
        () => Get.find<NotificationController>().getNotificationList(reload),
      ),
      ApiCallManager.instance.executeCall(
        'coupons',
        () => Get.find<CouponController>().getCouponList(),
        cacheDuration: const Duration(minutes: 15),
      ),
    ];

    await Future.wait(userFutures);
  }

  /// Load fallback data when no module is set
  static Future<void> _loadFallbackData() async {
    final splashController = Get.find<SplashController>();

    if (splashController.module == null &&
        splashController.configModel?.module == null) {
      final fallbackFutures = <Future<void>>[
        ApiCallManager.instance.executeCall(
          'banners_featured',
          () => Get.find<BannerController>().getFeaturedBanner(),
          cacheDuration: const Duration(minutes: 10),
        ),
        ApiCallManager.instance.executeCall(
          'stores_featured',
          () => Get.find<StoreController>().getFeaturedStoreList(),
          cacheDuration: const Duration(minutes: 10),
        ),
      ];

      if (AuthHelper.isLoggedIn()) {
        fallbackFutures.add(
          ApiCallManager.instance.executeCall(
            'addresses',
            () => Get.find<AddressController>().getAddressList(),
            cacheDuration: const Duration(minutes: 30),
          ),
        );
      }

      await Future.wait(fallbackFutures);
    }
  }

  /// Load parcel-specific data
  static Future<void> _loadParcelData() async {
    final splashController = Get.find<SplashController>();

    if (splashController.module != null &&
        splashController.configModel?.moduleConfig?.module?.isParcel == true) {
      await ApiCallManager.instance.executeCall(
        'parcel_categories',
        () => Get.find<ParcelController>().getParcelCategoryList(),
        cacheDuration: const Duration(minutes: 30),
      );
    }
  }

  /// Load pharmacy-specific data
  static Future<void> _loadPharmacyData(bool reload) async {
    final splashController = Get.find<SplashController>();

    if (splashController.module?.moduleType.toString() ==
        AppConstants.pharmacy) {
      final storeController = Get.find<StoreController>();
      final itemController = Get.find<ItemController>();

      final pharmacyFutures = <Future<void>>[
        // Basic medicine (Product with Categories)
        ApiCallManager.instance.executeCall(
          'pharmacy_basic_medicine',
          () => itemController.getBasicMedicine(reload, false),
          cacheDuration: const Duration(minutes: 15),
        ),
        // Featured stores (Best Store Nearby)
        ApiCallManager.instance.executeCall(
          'pharmacy_featured_stores',
          () => storeController.getFeaturedStoreList(),
          cacheDuration: const Duration(minutes: 10),
        ),
        // Common conditions
        ApiCallManager.instance.executeCall(
          'pharmacy_common_conditions',
          () => itemController.getCommonConditions(false),
          cacheDuration: const Duration(minutes: 30),
        ),
        // Latest stores (New On Mart)
        ApiCallManager.instance.executeCall(
          'pharmacy_latest_stores',
          () => storeController.getLatestStoreList(reload, 'all', false),
          cacheDuration: const Duration(minutes: 10),
        ),
        // Top offer stores (Top Offers Near Me)
        ApiCallManager.instance.executeCall(
          'pharmacy_top_offer_stores',
          () => storeController.getTopOfferStoreList(reload, false),
          cacheDuration: const Duration(minutes: 10),
        ),
        // Advertisements (Highlights) - only if controller is registered
        if (Get.isRegistered<AdvertisementController>())
          ApiCallManager.instance.executeCall(
            'pharmacy_advertisements',
            () => Get.find<AdvertisementController>().getAdvertisementList(),
            cacheDuration: const Duration(minutes: 10),
          ),
      ];

      await Future.wait(pharmacyFutures);

      // Load conditions-wise items if conditions exist
      if (itemController.commonConditions?.isNotEmpty == true) {
        await ApiCallManager.instance.executeCall(
          'pharmacy_conditions_items',
          () => itemController.getConditionsWiseItem(
            itemController.commonConditions![0].id!,
            false,
          ),
          cacheDuration: const Duration(minutes: 15),
        );
      }
    }
  }

  /// Run pharmacy API tests
  static Future<void> _runPharmacyApiTests() async {
    try {
      // Import the test class dynamically to avoid circular dependencies
      final testResults = await PharmacyApiTest.testAllPharmacyApis();
      
      // Print detailed results
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔬 PHARMACY MODULE API TEST RESULTS');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      if (testResults.containsKey('error')) {
        debugPrint('❌ Error: ${testResults['error']}');
        return;
      }
      
      debugPrint('Module ID: ${testResults['module_id']}');
      debugPrint('Module Name: ${testResults['module_name']}');
      debugPrint('');
      
      int successCount = 0;
      int dataCount = 0;
      int totalCount = 0;
      
      testResults.forEach((key, dynamicValue) {
        if (key != 'module_id' && key != 'module_name' && key != 'error') {
          final value = dynamicValue as Map<String, dynamic>;
          totalCount++;
          final success = value['success'] == true;
          final hasData = value['data'] == true;
          
          if (success) successCount++;
          if (hasData) dataCount++;
          
          final status = success ? '✅' : '❌';
          final dataStatus = hasData ? '(HAS DATA)' : hasData == false ? '(NO DATA)' : '';
          final count = value['count'] != null ? 'Count: ${value['count']}' : '';
          
          debugPrint('$status $key: $count $dataStatus');
          
          if (value['error'] != null) {
            debugPrint('   Error: ${value['error']}');
          }
          
          // Print additional details for specific APIs
          if (key == 'basic_medicine') {
            debugPrint('   - Categories: ${value['categories_count'] ?? 0}');
            debugPrint('   - Products: ${value['products_count'] ?? 0}');
          }
        }
      });
      
      debugPrint('');
      debugPrint('📊 Summary:');
      debugPrint('   Total APIs: $totalCount');
      debugPrint('   Successful: $successCount');
      debugPrint('   With Data: $dataCount');
      debugPrint('   Without Data: ${successCount - dataCount}');
      debugPrint('   Failed: ${totalCount - successCount}');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error running pharmacy API tests: $e');
    }
  }

  /// Print performance statistics
  static void _printPerformanceStats() {
    final stats = Get.find<OptimizedApiClient>().getPerformanceStats();
    if (kDebugMode) {
      debugPrint('📊 API Performance Stats:');
      debugPrint('   Total Calls: ${stats['totalCalls']}');
      debugPrint('   Duplicates Prevented: ${stats['duplicateCallsPrevented']}');
      debugPrint('   Cache Hits: ${stats['cacheHits']}');
      debugPrint('   Cache Hit Rate: ${stats['cacheHitRate']}%');
      debugPrint('   Ongoing Calls: ${stats['ongoingCalls']}');
      debugPrint('   Cached Responses: ${stats['cachedResponses']}');
    }
  }

  /// Clear all caches
  static void clearAllCaches() {
    ApiCallManager.instance.clearCache();
    if (kDebugMode) {
      debugPrint('🗑️ All caches cleared');
    }
  }

  /// Preload critical data for better performance
  static Future<void> preloadCriticalData() async {
    try {
      await Get.find<OptimizedApiClient>().preloadCriticalData();
      if (kDebugMode) {
        debugPrint('⚡ Critical data preloaded');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error preloading critical data: $e');
      }
    }
  }

  /// Start smart preloading in background
  static void _startSmartPreloading() {
    // Run preloading in background without blocking UI
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await SmartPreloader.preloadPopularSections();
        if (kDebugMode) {
          debugPrint('🚀 Smart preloading completed in background');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error in smart preloading: $e');
        }
      }
    });
  }
}
