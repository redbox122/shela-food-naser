import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/home/domain/models/home_unified_model.dart';
//import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';
import 'package:sixam_mart/features/home/domain/services/home_unified_service.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/cache_invalidation_service.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';

//فث
/// Home Unified Controller
///
/// ⚡ BFF API v2: Controller for unified home data loading
///
/// This controller:
/// 1. Fetches ALL home data in a single API call
/// 2. Distributes data to respective controllers (Banner, Category, Store, Brands)
/// 3. Implements local-first UX (render from cache, update from API)
/// 4. Handles cross-fade animation when new data arrives
///
/// Performance Impact:
/// - Single API call vs 5+ individual calls
/// - Instant home screen from cache
/// - Background refresh with subtle UI update
class HomeUnifiedController extends GetxController implements GetxService {
  final HomeUnifiedService homeUnifiedService;

  HomeUnifiedController({required this.homeUnifiedService});

  // ⚡ MULTI-TENANT: Map-based cache to hold data for multiple modules simultaneously
  // This enables instant module switching (0ms) when switching between previously viewed modules
  final Map<int, HomeUnifiedModel> _moduleDataCache = {};

  /// Get current module's data from memory cache
  HomeUnifiedModel? _getCurrentModuleData() {
    final moduleId = ModuleHelper.getModule()?.id;
    return moduleId != null ? _moduleDataCache[moduleId] : null;
  }

  /// Get data for a specific module (public getter for external access)
  HomeUnifiedModel? getModuleData(int moduleId) => _moduleDataCache[moduleId];

  // State
  HomeUnifiedModel? get unifiedData => _getCurrentModuleData();

  /// ⚡ SWR: Get cached data for instant UI rendering
  /// Returns cached data if available, null otherwise
  /// Use this to check if UI should render immediately without loading shimmer
  HomeUnifiedModel? get cachedData => _getCurrentModuleData();

  /// ⚡ SWR: Check if we have cached data available
  /// Returns true if cached data exists and is valid
  bool get hasCachedData {
    final data = _getCurrentModuleData();
    return data != null && data.isValid;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🛠️ TASK 1: Request lock to prevent duplicate API calls
  bool _isFetching = false;

  // ⚡ GENERATION ID: Prevents stale API responses from being applied
  // When switching modules quickly, older requests may complete after newer ones
  // Generation ID ensures only the latest request's data is applied
  int _homeGeneration = 0;
  int get homeGeneration => _homeGeneration;

  // Debounce burst load requests for the same module.
  DateTime? _lastLoadRequestTime;
  int? _lastLoadRequestModuleId;
  static const Duration _loadRequestDebounce = Duration(milliseconds: 700);

  // ⚡ OPTIMIZATION: Track last fetch per module to prevent duplicate calls
  final Map<int, DateTime> _lastFetchTimePerModule = {};
  static const Duration _minFetchInterval =
      Duration(seconds: 5); // Minimum 5 seconds between calls for same module

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _lastFetchTime;
  DateTime? get lastFetchTime => _lastFetchTime;

  // 🔧 FIX: Track if data was just pre-fetched to skip immediate background refresh
  DateTime? _lastPreFetchTime;

  // Cache service
  final HiveHomeCacheService _cacheService = HiveHomeCacheService();

  /// ⚡ Cache-First: Load cached data synchronously for instant UI rendering
  ///
  /// الفلسفة: الكاش هو المصدر الأول للعرض
  /// - تحميل من الكاش فورًا (0ms)
  /// - عرض البيانات مباشرة
  /// - بدون انتظار API
  ///
  /// ⚡ PERFORMANCE: Only loads critical sections (banners, categories, offers) for first frame
  /// Stores are loaded separately after first frame to avoid blocking UI
  ///
  /// Returns true if cached data was loaded successfully
  Future<bool> loadCachedDataForInstantUI({bool loadStores = false}) async {
    final moduleId = ModuleHelper.getModule()?.id;
    if (moduleId == null) {
      return false;
    }

    try {
      // ⚡ STEP A: Check memory cache first (instant switch - 0ms)
      if (_moduleDataCache.containsKey(moduleId)) {
        final memoryData = _moduleDataCache[moduleId]!;
        if (memoryData.isValid) {
          // 🔧 FIX: Wrap distribution AND update in Future.microtask to fix setState during build
          Future.microtask(() {
            _distributeDataToControllers(memoryData, loadStores: loadStores);
            update();
          });
          if (kDebugMode) {
            print('[Cache] HIT: home_unified_$moduleId (memory - 0ms)');
          }
          appLogger.debug('[Cache] HIT: home_unified_$moduleId (memory)');
          return true;
        }
      }

      // ⚡ STEP B: Load from disk cache (Hive)
      final cachedData = await _loadFromCache(moduleId);
      if (cachedData != null && cachedData.isValid) {
        // Store in memory cache for future instant switches
        _moduleDataCache[moduleId] = cachedData;
        // 🔧 FIX: Wrap distribution AND update in Future.microtask to fix setState during build
        Future.microtask(() {
          _distributeDataToControllers(cachedData, loadStores: loadStores);
          update();
        });
        if (kDebugMode) {
          print('[Cache] HIT: home_unified_$moduleId (disk)');
        }
        appLogger.debug('[Cache] HIT: home_unified_$moduleId (disk)');
        return true;
      }

      if (kDebugMode) {
        print('[Cache] MISS: home_unified_$moduleId (not found or expired)');
      }
      appLogger.debug('[Cache] MISS: home_unified_$moduleId');
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[Cache] MISS: home_unified_$moduleId (error: $e)');
      }
      appLogger.error('Cache load failed', e);
      return false;
    }
  }

  /// Load home data using unified endpoint
  ///
  /// [forceRefresh] - If true, bypasses cache and fetches fresh data
  /// [showLoading] - If true, shows loading indicator
  /// [moduleId] - Optional moduleId for parallel loading during splash
  /// [include] - Lazy loading: 'banners,offers' for splash pre-fetch, null for full data
  ///
  /// Returns true if data was loaded successfully
  Future<bool> loadHomeData({
    bool forceRefresh = false,
    bool showLoading = true,
    int?
        moduleId, // ✅ TASK 2: Add optional moduleId parameter for parallel loading
    String? include, // 🔧 FIX: Lazy loading parameter for splash pre-fetch
  }) async {
    if (Get.isRegistered<SplashController>()) {
      await Get.find<SplashController>().ensureModuleReady();
    }
    if (_isLoading || _isFetching) {
      if (kDebugMode) {
        print(
            '🚫 HomeUnifiedController: Already loading/fetching, skipping duplicate call');
      }
      return false;
    }
    final int? moduleForDebounce = ModuleHelper.getModule()?.id;
    final DateTime now = DateTime.now();
    if (!forceRefresh &&
        moduleForDebounce != null &&
        _lastLoadRequestModuleId == moduleForDebounce &&
        _lastLoadRequestTime != null &&
        now.difference(_lastLoadRequestTime!) < _loadRequestDebounce) {
      if (kDebugMode) {
        print(
            'HomeUnifiedController: Debounced duplicate request for module $moduleForDebounce');
      }
      return hasCachedData;
    }
    _lastLoadRequestModuleId = moduleForDebounce;
    _lastLoadRequestTime = now;

    // ⚡ GENERATION ID: Increment generation to invalidate any pending requests
    // This ensures stale responses from previous module switches are discarded
    final int currentGeneration = ++_homeGeneration;
    if (kDebugMode) {
      print(
          '🔄 HomeUnifiedController: Starting load with generation $currentGeneration');
    }

    // ⚡ Cache-First Fix: Always use current module ID (never accept different moduleId)
    // ❌ CRITICAL: moduleId parameter breaks Cache-First philosophy
    // If cache is for module 6 but API is called with moduleId=3, cache becomes invalid
    final currentModuleId = ModuleHelper.getModule()?.id;
    if (currentModuleId == null) {
      if (kDebugMode) {
        print('[Cache-First] ERROR: No module selected - cannot load data');
      }
      return false;
    }

    // ⚡ CRITICAL: Assert moduleId matches current module (if provided)
    if (moduleId != null && moduleId != currentModuleId) {
      if (kDebugMode) {
        print('[Cache-First] ERROR: Module ID mismatch!');
        print('   - Cache is for module: $currentModuleId');
        print('   - API called with moduleId: $moduleId');
        print(
            '   - This breaks Cache-First philosophy - ignoring moduleId parameter');
      }
      appLogger.error('Module ID mismatch in loadHomeData', null);
      // Use current module ID instead of provided one
    }

    final effectiveModuleId = currentModuleId; // Always use current module

    if (forceRefresh) {
      await _cacheService.invalidateHomeUnifiedCache(effectiveModuleId);
      _moduleDataCache.remove(effectiveModuleId);
    }

    // 🔧 FIX 4: Ensure ApiClient headers are updated with current module/zone BEFORE API call
    // This fixes the issue where headers have stale data when requesting home data
    _ensureApiHeadersUpdated(effectiveModuleId);

    // ⚡ OPTIMIZATION: Check if we recently fetched this module (prevent rapid duplicate calls)
    if (!forceRefresh) {
      final lastFetchTime = _lastFetchTimePerModule[effectiveModuleId];
      if (lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(lastFetchTime);
        if (timeSinceLastFetch < _minFetchInterval) {
          if (kDebugMode) {
            print(
                '⚡ HomeUnifiedController: Skipping duplicate call (last fetch ${timeSinceLastFetch.inSeconds}s ago for module $effectiveModuleId, min interval: ${_minFetchInterval.inSeconds}s)');
          }
          return false;
        }
      }
    }

    if (kDebugMode && moduleId != null) {
      print(
          '✅ HomeUnifiedController: Loading home data with moduleId: $moduleId (pre-fetch mode)');
    }

    // ⚡ MULTI-TENANT: Check memory cache first (instant switch - 0ms)
    if (!forceRefresh && _moduleDataCache.containsKey(effectiveModuleId)) {
      final memoryData = _moduleDataCache[effectiveModuleId]!;
      if (memoryData.isValid) {
        // 🔧 TASK 2: Wrap in Future.microtask to fix setState during build
        Future.microtask(
            () => _distributeDataToControllers(memoryData, loadStores: true));
        _isLoading = false;
        update();
        if (kDebugMode) {
          print(
              '⚡ HomeUnifiedController: Instant switch from memory cache (0ms) - module $effectiveModuleId');
        }
        return true; // Instant switch - 0ms
      }
    }

    // ⚡ Cache-First Fix: Only set isLoading if no cached data exists
    // If cached data exists, keep UI in "Success" state (no loading spinner)
    final hasExistingData = _moduleDataCache.containsKey(effectiveModuleId) &&
        _moduleDataCache[effectiveModuleId]!.isValid;
    if (hasExistingData && !forceRefresh) {
      // ⚡ Cache-First: Silent refresh - preserve Success state
      _isLoading = false;
      if (kDebugMode) {
        print(
            '[Cache-First] Silent refresh - preserving Success state (cached data exists)');
      }
    } else {
      // First load or force refresh - show loading state
      _isLoading = showLoading;
      if (showLoading) {
        update();
      }
    }

    _hasError = false;
    _errorMessage = null;

    try {
      // 🔧 FIX 3: Ensure config is initialized before loading data
      // This ensures business settings flags are loaded (banners_section, etc.)
      // 🔧 CRITICAL FIX: Check isLoadingConfig to prevent infinite recursion
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        if (splashController.configModel == null &&
            !splashController.isLoadingConfig) {
          if (kDebugMode) {
            print(
                '🔧 HomeUnifiedController: Config not loaded, triggering getConfigData...');
          }
          // Trigger config load in background (non-blocking)
          splashController
              .getConfigData(
            Get.context!,
            source: DataSourceEnum.client,
            shouldRoute: false,
          )
              .catchError((e) {
            if (kDebugMode) {
              print('⚠️ HomeUnifiedController: Error loading config: $e');
            }
          });
        } else if (splashController.isLoadingConfig && kDebugMode) {
          print(
              '🚫 HomeUnifiedController: Config already being loaded - skipping duplicate trigger');
        }
      }

      // ⚡ BFF API v2: Business settings come from /api/v2/home-unified response
      // DO NOT fallback to getBusiness_Settings() which calls old /api/v1/business-settings endpoint
      // The old endpoint is missing new section flags (offers_section, all_stores_section, etc.)
      // If v2 API doesn't return business_settings, we'll set a default in _distributeDataToControllers()

      // Step 1: Load from disk cache (if not already in memory)
      if (!forceRefresh) {
        final cachedData = await _loadFromCache(effectiveModuleId);
        if (cachedData != null && cachedData.isValid) {
          if (kDebugMode) {
            print(
                '✅ HomeUnifiedController: Loaded from disk cache, storing in memory and distributing data...');
          }
          // Store in memory cache for future instant switches
          _moduleDataCache[effectiveModuleId] = cachedData;
          // 🔧 TASK 2: Wrap in Future.microtask to fix setState during build
          Future.microtask(
              () => _distributeDataToControllers(cachedData, loadStores: true));
          update();

          // 🔧 FIX: Check if data was just pre-fetched before triggering background refresh
          // If there's an ongoing fetch or data was just fetched, skip background refresh
          final shouldSkipBackgroundRefresh = _isFetching ||
              (_lastFetchTime != null &&
                  DateTime.now().difference(_lastFetchTime!).inSeconds < 10) ||
              (_lastPreFetchTime != null &&
                  effectiveModuleId == 3 &&
                  DateTime.now().difference(_lastPreFetchTime!).inSeconds < 10);

          if (shouldSkipBackgroundRefresh) {
            if (kDebugMode) {
              print(
                  '🚫 HomeUnifiedController: Skipping background refresh - data was just pre-fetched or fetch in progress');
            }
          } else {
            // Step 2: Refresh from API in background (will skip if data was just pre-fetched)
            _refreshFromApiInBackground(effectiveModuleId);
          }

          _isLoading = false;
          return true;
        }
      }

      // Step 3: No cache or force refresh - fetch from API
      // 🛠️ TASK 1: Check request lock to prevent duplicate calls
      if (_isFetching) {
        if (kDebugMode) {
          print(
              '🚫 HomeUnifiedController: Already fetching, skipping duplicate call');
        }
        _isLoading = false;
        return false;
      }

      _isFetching = true;

      // ⚡ OPTIMIZATION: Update last fetch time per module (even if API call fails)
      final effectiveModuleIdForFetch =
          moduleId ?? ModuleHelper.getModule()?.id;
      if (effectiveModuleIdForFetch != null) {
        _lastFetchTimePerModule[effectiveModuleIdForFetch] = DateTime.now();
      }
      HomeUnifiedModel? apiData;
      try {
        apiData = await homeUnifiedService.getHomeUnifiedData(
          moduleId: effectiveModuleId,
          include: include, // 🔧 FIX: Pass include parameter for lazy loading
        );
      } finally {
        _isFetching = false;
        _lastLoadRequestTime = null;
        _lastLoadRequestModuleId = null;
      }

      if (apiData != null && apiData.isValid) {
        // ⚡ GENERATION CHECK: Discard stale response if module switched during API call
        if (currentGeneration != _homeGeneration) {
          if (kDebugMode) {
            print(
                '🚫 HomeUnifiedController: Discarding stale response (gen $currentGeneration != $_homeGeneration)');
          }
          _isLoading = false;
          return false; // Module switched, ignore this response
        }

        // 🔧 FIX 3: Check if new API data is identical to cached data BEFORE updating
        // This prevents flicker when skeleton disappears and data reloads
        final cachedDataBeforeUpdate = _moduleDataCache[effectiveModuleId];
        final isDataIdentical = cachedDataBeforeUpdate != null &&
            !_hasDataChanged(cachedDataBeforeUpdate, apiData);

        // 🔧 FIX: Force update if cached data has empty banners but API has banner URLs
        final hasBannerUpgrade =
            _hasBannerUpgrade(cachedDataBeforeUpdate, apiData);
        final shouldForceUpdate = hasBannerUpgrade;

        if (isDataIdentical && !shouldForceUpdate) {
          if (kDebugMode) {
            print(
                '✅ HomeUnifiedController: API data identical to cached data, skipping update() to prevent flicker');
            print('   - Version hash: ${apiData.meta?.versionHash}');
          }
          // Still save to cache to update timestamps, but don't update UI
          await _saveToCache(effectiveModuleId, apiData);
          _lastFetchTime = DateTime.now();
          _isLoading = false;
          return true; // Return early - no UI update needed
        }

        if (shouldForceUpdate && kDebugMode) {
          print(
              '🔄 HomeUnifiedController: Banner upgrade detected - forcing UI update');
        }

        final String? oldVersionHash =
            _moduleDataCache[effectiveModuleId]?.meta?.versionHash;
        final String? newVersionHash = apiData.meta?.versionHash;

        // ⚡ MULTI-TENANT: Store in memory cache (enables instant switching)
        _moduleDataCache[effectiveModuleId] = apiData;
        _lastFetchTime = DateTime.now();
        // 🔧 FIX: Track pre-fetch time to skip immediate background refresh
        if (moduleId != null && moduleId == 3) {
          // Only track for module 3 (promotional content pre-fetch)
          _lastPreFetchTime = DateTime.now();
        }

        if (kDebugMode && moduleId != null) {
          print(
              '✅ HomeUnifiedController: Pre-fetch complete - data stored in memory cache (moduleId: $moduleId)');
          print(
              '   - Banners: ${apiData.banners?.length ?? 0}, Offers: ${apiData.offers?.length ?? 0}');
          print(
              '   - Stored in _moduleDataCache[$moduleId] for instant switching');
        }

        // Distribute to controllers
        // 🔧 TASK 2: Wrap in Future.microtask to fix setState during build
        // Store in local variable to ensure non-null in closure
        final dataToDistribute = apiData;
        final genAtDistribute = currentGeneration;
        Future.microtask(() {
          // ⚡ GENERATION CHECK: Skip distribution if module switched
          if (genAtDistribute != _homeGeneration) {
            if (kDebugMode) {
              print(
                  '🚫 HomeUnifiedController: Skipping distribution (gen $genAtDistribute != $_homeGeneration)');
            }
            return;
          }
          _distributeDataToControllers(dataToDistribute, loadStores: true);
        });

        // Save to cache
        await _saveToCache(effectiveModuleId, apiData);

        if (kDebugMode) {
          print('✅ HomeUnifiedController: API data loaded and distributed');
        }

        _isLoading = false;

        // 🔧 FIX 2: Stop rebuild loop if version hash is identical
        if (oldVersionHash != null &&
            newVersionHash != null &&
            oldVersionHash == newVersionHash) {
          if (kDebugMode) {
            print(
                '✅ HomeUnifiedController: Skip update() - version hash unchanged ($oldVersionHash)');
          }
          return true;
        }

        update();
        return true;
      } else {
        // ⚠️ 304 or empty/invalid payload fallback: keep last known good cache
        final fallbackData = _moduleDataCache[effectiveModuleId] ??
            await _loadFromCache(effectiveModuleId);
        if (fallbackData != null && fallbackData.isValid) {
          if (kDebugMode) {
            print(
                '⚠️ HomeUnifiedController: Empty/invalid API response - preserving cached data for module $effectiveModuleId');
          }
          _moduleDataCache[effectiveModuleId] = fallbackData;
          _lastFetchTime = DateTime.now();
          Future.microtask(() {
            if (currentGeneration != _homeGeneration) {
              if (kDebugMode) {
                print(
                    '🚫 HomeUnifiedController: Skipping fallback distribution (gen $currentGeneration != $_homeGeneration)');
              }
              return;
            }
            _distributeDataToControllers(fallbackData, loadStores: true);
          });
          _isLoading = false;
          update();
          return true;
        }

        _hasError = true;
        _errorMessage = 'Failed to load home data';
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeUnifiedController: Error loading home data: $e');
      }
      _hasError = true;
      _errorMessage = e.toString();
      _isLoading = false;
      update();
      return false;
    }
  }

  /// Distribute unified data to respective controllers
  ///
  /// This is the core of the BFF pattern - one fetch, multiple controllers updated
  /// ⚡ BFF API v2: Only updates controllers if new data is better (not empty, more items)
  /// [skipUpdateIfIdentical] - If true, compares with cached data and skips update() if identical
  /// Returns true if any controller was updated (for determining if UI update is needed)
  ///
  /// ⚡ PERFORMANCE: loadStores parameter controls whether to load stores data
  /// - false: Skip stores (for first frame - only banners, categories, offers)
  /// - true: Load stores (after first frame)
  // 🔧 FIX: Track last distributed data hash to prevent duplicate distribution
  int? _lastDistributedHash;
  int? _lastDistributedModuleId;

  List<Store>? _filterStoresByModule(List<Store>? stores, int? moduleId) {
    if (stores == null || moduleId == null) {
      return stores;
    }
    return stores.where((store) => store.moduleId == moduleId).toList();
  }

  // 🔧 FIX 3: Track if this is first distribution (for guest/new user)
  bool _hasEverDistributed = false;

  bool _distributeDataToControllers(HomeUnifiedModel data,
      {bool skipUpdateIfIdentical = false,
      bool loadStores = true,
      bool force = false}) {
    final int? currentModuleId =
        data.meta?.moduleId ?? ModuleHelper.getModule()?.id;
    final dataHash = data.hashCode;

    // 🔧 FIX 3: Detect module change for hard reset logic
    final bool isModuleChange = _lastDistributedModuleId != null &&
        _lastDistributedModuleId != currentModuleId;

    // 🔧 FIX 3: Force distribution on first load (for guest/new user)
    // This ensures UI always gets data on first launch even if hash matches cached
    final isFirstDistribution = !_hasEverDistributed;
    if (isFirstDistribution) {
      _hasEverDistributed = true;
      if (kDebugMode) {
        print(
            '🚀 HomeUnifiedController: First distribution - forcing update (guest/new user fix)');
      }
    }

    // 🔧 FIX 3: If module changed, log and prepare for hard reset
    if (isModuleChange && kDebugMode) {
      print(
          '🔄 HomeUnifiedController: MODULE CHANGE detected ($_lastDistributedModuleId → $currentModuleId)');
      print('   → Hard reset: will NOT preserve old module data');
    }

    // 🔧 FIX: Prevent duplicate distribution ONLY if moduleId is the same and hash matches
    // BUT skip this check on first distribution to ensure UI always gets data
    if (!force &&
        !isFirstDistribution &&
        !isModuleChange && // 🔧 FIX 3: Always distribute on module change
        _lastDistributedModuleId == currentModuleId &&
        _lastDistributedHash == dataHash) {
      if (kDebugMode) {
        print(
            '✅ HomeUnifiedController: Skipping duplicate distribution (same module: $currentModuleId, same hash: $dataHash)');
      }
      return false; // No update needed
    }

    // Update tracking
    _lastDistributedHash = dataHash;
    _lastDistributedModuleId = currentModuleId;

    if (kDebugMode) {
      print(
          '🔄 HomeUnifiedController: Distributing data to controllers... (module: $currentModuleId)');
    }

    bool shouldUpdateUI = false;

    // 1. Banner Controller
    if (Get.isRegistered<BannerController>()) {
      final bannerController = Get.find<BannerController>();

      // 🔍 DEBUG: Log banner data from API response
      if (kDebugMode) {
        print('🔍 HomeUnifiedController: Banner distribution check');
        print('   - data.banners: ${data.banners?.length ?? 0} items');
        print('   - data.campaigns: ${data.campaigns?.length ?? 0} items');
        if (data.banners != null && data.banners!.isNotEmpty) {
          print('   - First banner: ${data.banners!.first.imageFullUrl}');
        }
        if (data.campaigns != null && data.campaigns!.isNotEmpty) {
          print('   - First campaign: ${data.campaigns!.first.imageFullUrl}');
        }
        print(
            '   - Existing banners: ${bannerController.bannerImageList?.length ?? 0}');
        print(
            '   - Existing featured: ${bannerController.featuredBannerList?.length ?? 0}');
      }

      // ⚡ TASK 2: STABILIZE V2 DISTRIBUTION - Protect against empty data overwriting populated data
      final hasExistingBanners = (bannerController.bannerImageList != null &&
              bannerController.bannerImageList!.isNotEmpty) ||
          (bannerController.featuredBannerList != null &&
              bannerController.featuredBannerList!.isNotEmpty);
      final hasNewBanners =
          (data.banners != null && data.banners!.isNotEmpty) ||
              (data.campaigns != null && data.campaigns!.isNotEmpty);

      if (kDebugMode) {
        print('   - hasExistingBanners: $hasExistingBanners');
        print('   - hasNewBanners: $hasNewBanners');
      }

      // Only update if we have new banners AND (no existing banners OR new banners are not empty)
      if (hasNewBanners) {
        final bannerModel = data.toBannerModel();

        // ⚡ PERFORMANCE: Deep equality check to prevent flickering
        bool shouldUpdateBanners = true;
        if (skipUpdateIfIdentical && !isModuleChange) {
          // 🔧 FIX 3: Skip equality check on module change
          // Get cached data for current module to compare
          final currentModuleId = ModuleHelper.getModule()?.id;
          final cachedData = currentModuleId != null
              ? _moduleDataCache[currentModuleId]
              : null;
          if (cachedData != null) {
            final cachedBannerModel = cachedData.toBannerModel();
            if (_areBannersIdentical(cachedBannerModel, bannerModel)) {
              if (kDebugMode) {
                print(
                    '   ✓ BannerController: Data identical, skipping update() to prevent flicker');
              }
              // Data is identical - don't update controller but still save to cache (handled by caller)
              shouldUpdateBanners = false;
            }
          }
        }

        if (shouldUpdateBanners) {
          // 🔧 PROTECTIVE DISTRIBUTION: Wrap in try-catch to prevent crash from blocking other controllers
          try {
            bannerController.setBannerDataFromBootstrap(bannerModel);
            shouldUpdateUI = true;
            if (kDebugMode) {
              print(
                  '   ✓ BannerController: ${data.banners?.length ?? 0} banners, ${data.campaigns?.length ?? 0} campaigns');
            }
          } catch (e, stackTrace) {
            appLogger.error('Banner Distribution Failed', e, stackTrace);
            if (kDebugMode) {
              print('   ❌ BannerController: Distribution failed - $e');
            }
          }
        }
      } else if (hasExistingBanners && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing banners if SAME module
        // If module changed, do NOT preserve - clear old data
        if (kDebugMode) {
          print(
              '   🛡️ BannerController: Discarding empty update - preserving existing banners (same module)');
        }
      } else if (isModuleChange) {
        // Global banners: do NOT clear on module change
        if (kDebugMode) {
          print(
              '   🛡️ BannerController: Module changed - preserving global banners');
        }
      } else {
        // 🔍 DEBUG: Log when no banners are found
        if (kDebugMode) {
          print(
              '   ⚠️ BannerController: No banners in API response and no existing banners');
          print('      - banners: ${data.banners?.length ?? 0}');
          print('      - campaigns: ${data.campaigns?.length ?? 0}');
        }

        // 🔧 FALLBACK: If unified endpoint returns no banners, try loading from legacy banner endpoint
        // This ensures banners show even if unified endpoint has issues
        if (!hasExistingBanners && Get.isRegistered<BannerController>()) {
          final bannerController = Get.find<BannerController>();
          // Only trigger fallback if we truly have no banners (not just empty update)
          if (bannerController.bannerImageList == null &&
              bannerController.featuredBannerList == null) {
            if (kDebugMode) {
              print(
                  '   🔄 BannerController: Triggering fallback to legacy banner endpoint...');
            }
            // Load banners from legacy endpoint in background
            bannerController
                .getBannerList(false, dataSource: DataSourceEnum.client)
                .catchError((Object e) {
              if (kDebugMode) {
                print(
                    '   ⚠️ BannerController: Fallback banner load failed: $e');
              }
              return null;
            });
          }
        }
      }
    }

    // 2. Category Controller
    // 🔧 FIX: Only update categories if a module is selected (not on Multi-Module screen)
    if (Get.isRegistered<CategoryController>() &&
        Get.isRegistered<SplashController>() &&
        Get.find<SplashController>().module != null) {
      final categoryController = Get.find<CategoryController>();

      // ⚡ TASK 2: STABILIZE V2 DISTRIBUTION - Protect against empty data overwriting populated data
      final hasExistingCategories = categoryController.categoryList != null &&
          categoryController.categoryList!.isNotEmpty;
      final hasNewCategories =
          data.categories != null && data.categories!.isNotEmpty;

      // Only update if we have new categories AND (no existing categories OR new categories are not empty)
      if (hasNewCategories) {
        // 🔧 PROTECTIVE DISTRIBUTION: Wrap in try-catch to prevent crash from blocking other controllers
        try {
          categoryController.setCategoryListFromCache(data.categories!);
          if (kDebugMode) {
            print(
                '   ✓ CategoryController: ${data.categories!.length} categories');
          }
        } catch (e, stackTrace) {
          appLogger.error('Category Distribution Failed', e, stackTrace);
          if (kDebugMode) {
            print('   ❌ CategoryController: Distribution failed - $e');
          }
        }
      } else if (hasExistingCategories && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing categories if SAME module
        // If module changed, do NOT preserve - clear old data
        if (kDebugMode) {
          print(
              '   🛡️ CategoryController: Discarding empty update - preserving existing ${categoryController.categoryList!.length} categories (same module)');
        }
      } else if (isModuleChange) {
        // 🔧 FIX 3: Module changed - HARD RESET categories
        if (kDebugMode) {
          print(
              '   🗑️ CategoryController: Module changed - clearing old categories (hard reset)');
        }
        try {
          categoryController.clearCategoryList(skipUpdate: true);
          shouldUpdateUI = true;
        } catch (e) {
          if (kDebugMode) {
            print('   ⚠️ CategoryController: Error during hard reset - $e');
          }
        }
      }
    }

    // 3. Store Controller (Popular Stores)
    // 🚫 CRITICAL: V2 ISOLATION - V2 must NEVER touch storeModel OR allStoreModel
    // V2 only populates curated lists (popularStoreList) for top sections
    // Legacy pagination engine (getStoreList) handles allStoreModel independently
    // This prevents V2 from overwriting totalSize with wrong value (9 popular stores vs 300+ all stores)
    // ⚡ HARD-ISOLATION: allStoreModel is exclusively for "All Restaurants" section pagination
    // ⚡ PERFORMANCE: Skip stores loading for first frame (loadStores = false)
    if (loadStores && Get.isRegistered<StoreController>()) {
      final storeController = Get.find<StoreController>();
      final List<Store>? filteredPopularStores =
          _filterStoresByModule(data.popularStores, currentModuleId);

      // ⚡ TASK 2: STABILIZE V2 DISTRIBUTION - Protect against empty data overwriting populated data
      final hasExistingPopularStores =
          storeController.popularStoreList != null &&
              storeController.popularStoreList!.isNotEmpty;
      final hasNewPopularStores =
          filteredPopularStores != null && filteredPopularStores.isNotEmpty;

      // Only update if we have new stores AND (no existing stores OR new stores are not empty)
      if (hasNewPopularStores) {
        // 🔧 PROTECTIVE DISTRIBUTION: Wrap in try-catch to prevent crash from blocking other controllers
        try {
          // Create StoreModel wrapper for popular stores
          final storeModel = StoreModel(
            totalSize: filteredPopularStores.length,
            stores: filteredPopularStores,
          );
          // ✅ SAFE: This only sets popularStoreList, NOT storeModel
          storeController.setPopularStoreDataFromBootstrap(storeModel);
          if (kDebugMode) {
            print(
                '   ✓ StoreController: ${data.popularStores!.length} popular stores (popularStoreList only)');
          }
        } catch (e, stackTrace) {
          appLogger.error('Store Distribution Failed', e, stackTrace);
          if (kDebugMode) {
            print('   ❌ StoreController: Distribution failed - $e');
          }
        }
      } else if (hasExistingPopularStores && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing stores if SAME module
        if (kDebugMode) {
          print(
              '   🛡️ StoreController: Discarding empty update - preserving existing ${storeController.popularStoreList!.length} popular stores (same module)');
        }
      } else if (isModuleChange) {
        // 🔧 FIX 3: Module changed - HARD RESET stores
        if (kDebugMode) {
          print(
              '   🗑️ StoreController: Module changed - clearing old stores (hard reset)');
        }
        try {
          storeController.resetStoreData();
          shouldUpdateUI = true;
        } catch (e) {
          if (kDebugMode) {
            print('   ⚠️ StoreController: Error during hard reset - $e');
          }
        }
      }

      // 🚫 DEFENSIVE CHECK: Verify we never set storeModel or allStoreModel directly
      // If this assertion fails, it means V2 is contaminating legacy state
      if (kDebugMode) {
        // Verify setPopularStoreDataFromBootstrap doesn't touch storeModel or allStoreModel
        // This is a runtime check to catch any accidental contamination
        final currentStoreModel = storeController.storeModel;
        final currentAllStoreModel = storeController.allStoreModel;
        if (currentStoreModel != null &&
            currentStoreModel.totalSize == data.popularStores?.length) {
          print(
              '   ⚠️ WARNING: StoreModel totalSize matches popularStores count - possible V2 contamination!');
        }
        // ⚡ HARD-ISOLATION: Verify allStoreModel is never touched by V2
        if (currentAllStoreModel != null &&
            currentAllStoreModel.totalSize == data.popularStores?.length) {
          print(
              '   ⚠️ CRITICAL: allStoreModel totalSize matches popularStores count - V2 contamination detected!');
        }
      }
    }

    // 4. Brands Controller
    // 🔧 FIX: Only update brands if a module is selected (not on Multi-Module screen)
    if (Get.isRegistered<BrandsController>() &&
        Get.isRegistered<SplashController>() &&
        Get.find<SplashController>().module != null) {
      final brandsController = Get.find<BrandsController>();

      // ⚡ TASK 2: STABILIZE V2 DISTRIBUTION - Protect against empty data overwriting populated data
      final hasExistingBrands = brandsController.brandList != null &&
          brandsController.brandList!.isNotEmpty;
      final hasNewBrands = data.brands != null && data.brands!.isNotEmpty;

      // Only update if we have new brands AND (no existing brands OR new brands are not empty)
      if (hasNewBrands) {
        // 🔧 PROTECTIVE DISTRIBUTION: Wrap in try-catch to prevent crash from blocking other controllers
        try {
          brandsController.setBrandListFromBootstrap(data.brands!);

          // ⚡ TASK 2: SAFE FRAME-PERFECT HYDRATION - Use proper Flutter lifecycle
          // ✅ PROPER: Safe frame callback with context check
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (Get.isRegistered<BrandsController>()) {
              Get.find<BrandsController>().update();
              appLogger.info('⚡ Brands: Frame-perfect hydration complete');
            }
          });

          if (kDebugMode) {
            print('   ✓ BrandsController: ${data.brands!.length} brands');
          }
        } catch (e, stackTrace) {
          appLogger.error('Brands Distribution Failed', e, stackTrace);
          if (kDebugMode) {
            print('   ❌ BrandsController: Distribution failed - $e');
          }
        }
      } else if (hasExistingBrands && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing brands if SAME module
        if (kDebugMode) {
          print(
              '   🛡️ BrandsController: Discarding empty update - preserving existing ${brandsController.brandList!.length} brands (same module)');
        }
      } else if (isModuleChange) {
        // 🔧 FIX 3: Module changed - HARD RESET brands
        if (kDebugMode) {
          print(
              '   🗑️ BrandsController: Module changed - clearing old brands (hard reset)');
        }
        try {
          brandsController.clearBrandList();
          shouldUpdateUI = true;
        } catch (e) {
          if (kDebugMode) {
            print('   ⚠️ BrandsController: Error during hard reset - $e');
          }
        }
      }
    }

    // 5. Offers Controller
    if (Get.isRegistered<Offers_Controller>()) {
      final offersController = Get.find<Offers_Controller>();

      // 🔧 FIX: Check if controller already has data from splash pre-fetch
      final hasExistingOffers = offersController.offersMode != null &&
          offersController.offersMode!.data.isNotEmpty;

      // Only update if we have offers (preserve existing if new data is empty)
      if (data.offers != null && data.offers!.isNotEmpty) {
        // 🔧 FIX: Force update if screen is empty (first-time load)
        final isEmpty = offersController.offersMode == null ||
            offersController.offersMode!.data.isEmpty;
        final newOffersNotEmpty = data.offers!.isNotEmpty;

        // ⚡ PERFORMANCE: Deep equality check to prevent flickering
        bool shouldUpdateOffers = true;
        if (skipUpdateIfIdentical && !isEmpty) {
          // 🔧 FIX: Never skip if screen is empty
          // Get cached data for current module to compare
          final currentModuleId = ModuleHelper.getModule()?.id;
          final cachedData = currentModuleId != null
              ? _moduleDataCache[currentModuleId]
              : null;
          if (cachedData != null &&
              cachedData.offers != null &&
              cachedData.offers!.isNotEmpty) {
            if (_areOffersIdentical(
                cachedData.offers!.first, data.offers!.first)) {
              if (kDebugMode) {
                print(
                    '   ✓ Offers_Controller: Data identical, skipping update() to prevent flicker');
              }
              // Data is identical - don't update controller but still save to cache (handled by caller)
              shouldUpdateOffers = false;
            }
          }
        }

        // 🔧 FIX: Force update if screen is empty and we have new offers
        if (isEmpty && newOffersNotEmpty) {
          shouldUpdateOffers = true;
          if (kDebugMode) {
            print(
                '   ✓ Offers_Controller: Screen is empty, forcing update with ${data.offers!.length} offers');
          }
        }

        if (shouldUpdateOffers) {
          // 🔧 TASK 1: Titan Mandate - If offers count is 0, do NOT update Offers_Controller state
          // This prevents empty cached responses from wiping the UI
          final offersCount = data.offers!.first.data.length;
          if (offersCount == 0) {
            if (kDebugMode) {
              print(
                  '   🛡️ Offers_Controller: Offers count is 0, preserving existing data (Titan Mandate)');
            }
            // Don't update - preserve existing offers data
          } else {
            // 🔧 PROTECTIVE DISTRIBUTION: Wrap in try-catch to prevent crash from blocking other controllers
            try {
              offersController.setOffersFromBootstrap(data.offers!);
              shouldUpdateUI = true;
              if (kDebugMode) {
                print(
                    '   ✓ Offers_Controller: Injected ${data.offers!.length} offers ($offersCount items)');
              }
            } catch (e, stackTrace) {
              appLogger.error('Offers Distribution Failed', e, stackTrace);
              if (kDebugMode) {
                print('   ❌ Offers_Controller: Distribution failed - $e');
              }
            }
          }
        }
      } else if (hasExistingOffers) {
        // 🔧 FIX: Preserve existing offers if bootstrap returns empty
        if (kDebugMode) {
          print(
              '   ✓ Offers_Controller: Bootstrap has no offers, preserving existing ${offersController.offersMode!.data.length} offers');
        }
        // Don't update - keep existing data
      }
    }

    // 6. Profile Controller (Customer Data)
    if (Get.isRegistered<ProfileController>()) {
      final profileController = Get.find<ProfileController>();
      if (data.customer != null && data.customer!.isNotEmpty) {
        try {
          final userInfoModel = UserInfoModel.fromJson(data.customer!);
          profileController.setUserInfoFromUnified(userInfoModel);
          if (kDebugMode) {
            print('   ✓ ProfileController: Customer data loaded');
          }
        } catch (e) {
          if (kDebugMode) {
            print('   ⚠️ ProfileController: Error parsing customer data: $e');
          }
        }
      }
    }

    // 🔧 FIX 3: Sync business settings from V2 response to HomeController
    // This ensures Home Screen 'settings' are no longer null
    // If API returns null, set default BusinessSettings to prevent infinite waiting
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      if (data.businessSettings != null) {
        if (homeController.business_Settings == null) {
          homeController
              .setBusinessSettingsFromBootstrap(data.businessSettings!);
          if (kDebugMode) {
            print(
                '   ✓ HomeController: Business settings synced from V2 response');
          }
        } else if (kDebugMode) {
          print(
              '   ⚠️ HomeController: Skipping V2 settings - app-init already set');
        }
      } else {
        if (homeController.business_Settings == null &&
            Get.isRegistered<SplashController>()) {
          final splashController = Get.find<SplashController>();
          final cachedSettings = splashController.cachedBusinessSettings;
          if (cachedSettings != null) {
            homeController.setBusinessSettingsFromAppInit(cachedSettings);
            if (kDebugMode) {
              print(
                  '   ✅ HomeController: Business settings restored from SplashController cache');
            }
          }
        }
        if (kDebugMode) {
          print(
              '   ⚠️ HomeController: Business settings missing in V2 payload, preserving existing settings');
        }
      }
    }

    if (kDebugMode) {
      print('✅ HomeUnifiedController: Data distribution complete');
    }

    update();
    return shouldUpdateUI;
  }

  /// Refresh data from API in background
  ///
  /// Called after cache is loaded to ensure fresh data
  /// ⚡ BFF API v2: Only updates if data actually changed (version_hash comparison)
  /// ⚡ EDGE CACHE: Handles s-maxage expiration (60 seconds) - data might be stale from edge
  void _refreshFromApiInBackground(int moduleId) {
    // ⚡ GENERATION ID: Capture generation at start to detect stale responses
    final int refreshGeneration = _homeGeneration;

    Future.delayed(const Duration(milliseconds: 100), () async {
      // ⚡ GENERATION CHECK: Skip if module switched during delay
      if (refreshGeneration != _homeGeneration) {
        if (kDebugMode) {
          print(
              '🚫 HomeUnifiedController: Background refresh aborted - module switched (gen $refreshGeneration != $_homeGeneration)');
        }
        return;
      }

      // 🔧 FIX: Skip background refresh if data was just pre-fetched (within last 10 seconds)
      // This prevents unnecessary API calls when navigating from splash to home
      // Check both _lastFetchTime (from API fetch) and _lastPreFetchTime (from pre-fetch)
      bool shouldSkip = false;

      if (_lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
        if (timeSinceLastFetch.inSeconds < 10) {
          shouldSkip = true;
          if (kDebugMode) {
            print(
                '🚫 HomeUnifiedController: Skipping background refresh - data was just fetched ${timeSinceLastFetch.inSeconds}s ago');
          }
        }
      }

      // Also check pre-fetch time (for module 3 promotional content)
      if (!shouldSkip && _lastPreFetchTime != null && moduleId == 3) {
        final timeSincePreFetch = DateTime.now().difference(_lastPreFetchTime!);
        if (timeSincePreFetch.inSeconds < 10) {
          shouldSkip = true;
          if (kDebugMode) {
            print(
                '🚫 HomeUnifiedController: Skipping background refresh - data was just pre-fetched ${timeSincePreFetch.inSeconds}s ago (module 3)');
          }
        }
      }

      if (shouldSkip) {
        return;
      }

      // ⚡ Cache-First Fix: Background refresh must be truly background
      // Rules:
      // 1. Only if cached data exists (don't block first load)
      // 2. No isLoading changes
      // 3. No reset operations
      // 4. After first frame is stable

      final hasCachedData = _moduleDataCache.containsKey(moduleId) &&
          _moduleDataCache[moduleId]!.isValid;
      if (!hasCachedData) {
        if (kDebugMode) {
          print(
              '[Cache-First] Background refresh skipped - no cached data (first load)');
        }
        return; // First load - not background refresh
      }

      // 🛠️ TASK 1: Check request lock to prevent duplicate calls
      if (_isFetching) {
        if (kDebugMode) {
          print('[Cache-First] Background refresh skipped - already fetching');
        }
        return;
      }

      _isFetching = true;

      // ⚡ OPTIMIZATION: Update last fetch time per module (even if API call fails)
      final effectiveModuleIdForFetch =
          moduleId ?? ModuleHelper.getModule()?.id;
      if (effectiveModuleIdForFetch != null) {
        _lastFetchTimePerModule[effectiveModuleIdForFetch] = DateTime.now();
      }
      try {
        if (kDebugMode) {
          print(
              '[API] background refresh started (truly background - no UI blocking)');
        }
        appLogger.debug('[API] background refresh started');

        final apiData = await homeUnifiedService.getHomeUnifiedData(
          moduleId: moduleId,
        );

        // ⚡ GENERATION CHECK: Discard stale response if module switched during API call
        if (refreshGeneration != _homeGeneration) {
          if (kDebugMode) {
            print(
                '🚫 HomeUnifiedController: Discarding stale background response (gen $refreshGeneration != $_homeGeneration)');
          }
          return; // Module switched, ignore this response
        }

        if (apiData != null && apiData.isValid) {
          // ⚡ Cache-First Philosophy: Check if data changed
          final cachedData = _moduleDataCache[moduleId];

          // ⚡ STEP 1: Check version_hash (fastest check)
          if (cachedData != null &&
              cachedData.meta?.versionHash != null &&
              apiData.meta?.versionHash != null &&
              cachedData.meta!.versionHash == apiData.meta!.versionHash) {
            if (kDebugMode) {
              print('[API] data identical → skip update (version_hash match)');
            }
            appLogger.debug('[API] data identical → skip update');
            return; // Data is identical - no update needed
          }

          // ⚡ STEP 2: Deep equality check (if version_hash not available)
          final hasChanges =
              cachedData == null || _hasDataChanged(cachedData, apiData);

          if (hasChanges) {
            // ⚡ Cache-First: Only update if new data is better than existing
            final shouldUpdate = _shouldUpdateData(cachedData, apiData);

            if (shouldUpdate) {
              // ⚡ MULTI-TENANT: Store in memory cache
              _moduleDataCache[moduleId] = apiData;
              _lastFetchTime = DateTime.now();

              if (kDebugMode) {
                print('[API] data changed → updating UI');
              }
              appLogger.debug('[API] data changed → updating');

              // ⚡ Cache-First: Distribute new data WITHOUT resetting scroll position
              // Preserve UI state during silent refresh
              Future.microtask(() async {
                final shouldUpdateUI = _distributeDataToControllers(apiData,
                    skipUpdateIfIdentical: true, loadStores: true);

                // ⚡ Save to cache (always save to update timestamps)
                await _saveToCache(moduleId, apiData);

                // ⚡ Only trigger UI update if data actually changed
                if (shouldUpdateUI) {
                  update();

                  if (kDebugMode) {
                    print(
                        '✅ HomeUnifiedController: Silent refresh complete - UI updated without scroll reset');
                    print(
                        '   - Edge cache expired, new data from origin server');
                  }
                } else {
                  if (kDebugMode) {
                    print(
                        '✅ HomeUnifiedController: Data identical, skipped update() to prevent flicker');
                  }
                }
              });
            } else {
              if (kDebugMode) {
                print(
                    '✅ HomeUnifiedController: Background refresh - new data is not better, preserving existing');
              }
            }
          } else {
            if (kDebugMode) {
              print(
                  '✅ HomeUnifiedController: Background refresh complete - no changes (version_hash match)');
            }
          }
        } else {
          // ⚡ EDGE CACHE: Handle edge cache expiration gracefully
          // If API returns null/invalid, check if it's due to edge cache expiration
          // In this case, preserve existing cache data and retry later
          if (kDebugMode) {
            print(
                '⚠️ HomeUnifiedController: Background refresh - API returned invalid data, preserving cache');
            print('   - This may be due to edge cache (s-maxage) expiration');
            print('   - Will retry on next background refresh cycle');
          }
          // Don't update - preserve existing cache data
          // Background refresh will retry automatically on next cycle
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ HomeUnifiedController: Background refresh failed: $e');
        }
        // Don't update error state - cache data is still valid
      } finally {
        _isFetching = false;
      }
    });
  }

  /// Check if new data is better than existing data
  /// ⚡ BFF API v2: Only update if new data has more items or existing is empty
  bool _shouldUpdateData(HomeUnifiedModel? oldData, HomeUnifiedModel newData) {
    if (oldData == null) return true; // No existing data, always update
    if (!newData.isValid) return false; // New data is invalid, don't update

    // Check if new data has more items than old data
    final oldItemCount = (oldData.banners?.length ?? 0) +
        (oldData.categories?.length ?? 0) +
        (oldData.popularStores?.length ?? 0) +
        (oldData.brands?.length ?? 0) +
        (oldData.offers?.length ?? 0);

    final newItemCount = (newData.banners?.length ?? 0) +
        (newData.categories?.length ?? 0) +
        (newData.popularStores?.length ?? 0) +
        (newData.brands?.length ?? 0) +
        (newData.offers?.length ?? 0);

    // Update if new data has more items, or if old data is empty
    return newItemCount > oldItemCount || oldItemCount == 0;
  }

  /// Deep equality check for banners - compares IDs and lengths
  /// Returns true if banners are identical (same IDs and same count)
  bool _areBannersIdentical(BannerModel cached, BannerModel newData) {
    // Compare lengths first (fast check)
    final cachedBannerCount =
        (cached.banners?.length ?? 0) + (cached.campaigns?.length ?? 0);
    final newBannerCount =
        (newData.banners?.length ?? 0) + (newData.campaigns?.length ?? 0);

    if (cachedBannerCount != newBannerCount) {
      return false;
    }

    // Compare banner IDs
    final cachedBannerIds = <int?>{};
    if (cached.banners != null) {
      cachedBannerIds
          .addAll(cached.banners!.map((b) => b.id).whereType<int?>());
    }
    if (cached.campaigns != null) {
      cachedBannerIds
          .addAll(cached.campaigns!.map((c) => c.id).whereType<int?>());
    }

    final newBannerIds = <int?>{};
    if (newData.banners != null) {
      newBannerIds.addAll(newData.banners!.map((b) => b.id).whereType<int?>());
    }
    if (newData.campaigns != null) {
      newBannerIds
          .addAll(newData.campaigns!.map((c) => c.id).whereType<int?>());
    }

    // Check if sets are identical
    if (cachedBannerIds.length != newBannerIds.length) {
      return false;
    }

    return cachedBannerIds.containsAll(newBannerIds) &&
        newBannerIds.containsAll(cachedBannerIds);
  }

  /// Deep equality check for offers - compares IDs and lengths
  /// Returns true if offers are identical (same IDs and same count)
  bool _areOffersIdentical(OffersModel cached, OffersModel newData) {
    // Compare lengths first (fast check)
    if (cached.data.length != newData.data.length) {
      return false;
    }

    // Compare offer IDs
    final cachedOfferIds = cached.data.map((o) => o.id).toSet();
    final newOfferIds = newData.data.map((o) => o.id).toSet();

    // Check if sets are identical
    if (cachedOfferIds.length != newOfferIds.length) {
      return false;
    }

    return cachedOfferIds.containsAll(newOfferIds) &&
        newOfferIds.containsAll(cachedOfferIds);
  }

  /// Check if data has changed using version_hash or fallback to item counts
  /// ⚡ BFF API v2: Uses version_hash from meta for efficient cache invalidation
  bool _hasDataChanged(HomeUnifiedModel? oldData, HomeUnifiedModel? newData) {
    if (oldData == null || newData == null) return true;

    // ⚡ BFF API v2: Check version_hash from meta if available (most efficient)
    if (oldData.meta?.versionHash != null &&
        newData.meta?.versionHash != null) {
      final hasChanged = oldData.meta!.versionHash != newData.meta!.versionHash;
      if (kDebugMode && hasChanged) {
        print(
            '🔄 HomeUnifiedController: Data changed (version_hash: ${oldData.meta!.versionHash} -> ${newData.meta!.versionHash})');
      }
      return hasChanged;
    }

    // Fallback: Simple comparison based on counts
    if ((oldData.banners?.length ?? 0) != (newData.banners?.length ?? 0)) {
      return true;
    }
    if ((oldData.categories?.length ?? 0) !=
        (newData.categories?.length ?? 0)) {
      return true;
    }
    if ((oldData.popularStores?.length ?? 0) !=
        (newData.popularStores?.length ?? 0)) {
      return true;
    }
    if ((oldData.brands?.length ?? 0) != (newData.brands?.length ?? 0)) {
      return true;
    }
    if ((oldData.offers?.length ?? 0) != (newData.offers?.length ?? 0)) {
      return true;
    }

    return false;
  }

  /// Load data from Hive cache
  /// ⚡ BFF API v2: Try unified cache first, fallback to individual caches
  Future<HomeUnifiedModel?> _loadFromCache(int moduleId) async {
    try {
      // ⚡ BFF API v2: Try unified cache first (single box, faster)
      final unifiedData = await _cacheService.loadHomeUnifiedData(moduleId);
      if (unifiedData != null && unifiedData.isValid) {
        // 🔧 FIX: Validate offers have banner URLs - invalidate cache if empty
        final hasEmptyBanners = _hasOffersWithEmptyBanners(unifiedData);
        if (hasEmptyBanners) {
          if (kDebugMode) {
            print(
                '⚠️ HomeUnifiedController: Cached offers have empty banners - invalidating cache');
          }
          // Invalidate cache to force refresh
          await _cacheService.invalidateHomeUnifiedCache(moduleId);
          return null; // Force refresh from API
        }

        if (kDebugMode) {
          print('✅ HomeUnifiedController: Loaded from unified cache');
        }
        return unifiedData;
      }

      // Fallback: Load individual cached data and combine into unified model
      // This maintains backward compatibility with old cache structure
      final banners = await _cacheService.loadBanners(moduleId);
      final categories = await _cacheService.loadCategories(moduleId);
      final stores = await _cacheService.loadStores(moduleId);
      final brands = await _cacheService.loadBrands(moduleId);
      final offers = await _cacheService.loadOffers(moduleId);

      // Check if we have any cached data
      if (banners == null &&
          categories == null &&
          stores == null &&
          brands == null &&
          offers == null) {
        return null;
      }

      final fallbackData = HomeUnifiedModel(
        banners: banners?.banners,
        campaigns: banners?.campaigns,
        categories: categories,
        popularStores: stores?.stores,
        brands: brands,
        offers: offers != null ? [offers] : null,
      );

      // 🔧 FIX: Validate offers have banner URLs - invalidate cache if empty
      final hasEmptyBanners = _hasOffersWithEmptyBanners(fallbackData);
      if (hasEmptyBanners) {
        if (kDebugMode) {
          print(
              '⚠️ HomeUnifiedController: Cached offers have empty banners - invalidating cache');
        }
        // Invalidate cache to force refresh
        await _cacheService.invalidateHomeUnifiedCache(moduleId);
        return null; // Force refresh from API
      }

      return fallbackData;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HomeUnifiedController: Error loading from cache: $e');
      }
      return null;
    }
  }

  /// Check if offers have empty banners (stale cache detection)
  bool _hasOffersWithEmptyBanners(HomeUnifiedModel data) {
    if (data.offers == null || data.offers!.isEmpty) {
      return false; // No offers to check
    }

    // Check all offers for empty banners
    for (final offerModel in data.offers!) {
      if (offerModel.data.isNotEmpty) {
        for (final offer in offerModel.data) {
          // If any offer has an empty banner, consider cache stale
          if (offer.banner == null || offer.banner!.isEmpty) {
            if (kDebugMode) {
              print(
                  '⚠️ HomeUnifiedController: Found offer with empty banner - id: ${offer.id}, name: ${offer.name}');
            }
            return true;
          }
        }
      }
    }

    return false; // All offers have banners
  }

  /// Check if API data has banner URLs but cached data has empty banners (banner upgrade)
  bool _hasBannerUpgrade(
      HomeUnifiedModel? cachedData, HomeUnifiedModel apiData) {
    if (cachedData == null) {
      return false; // No cached data to compare
    }

    // Check if cached offers have empty banners but API offers have banner URLs
    if (cachedData.offers != null &&
        cachedData.offers!.isNotEmpty &&
        apiData.offers != null &&
        apiData.offers!.isNotEmpty) {
      // Compare offers by ID
      for (final cachedOfferModel in cachedData.offers!) {
        for (final apiOfferModel in apiData.offers!) {
          if (cachedOfferModel.data.isNotEmpty &&
              apiOfferModel.data.isNotEmpty) {
            // Match offers by ID
            for (final cachedOffer in cachedOfferModel.data) {
              for (final apiOffer in apiOfferModel.data) {
                if (cachedOffer.id == apiOffer.id) {
                  // Found matching offer - check if banner was upgraded
                  final cachedBannerEmpty =
                      cachedOffer.banner == null || cachedOffer.banner!.isEmpty;
                  final apiBannerNotEmpty =
                      apiOffer.banner != null && apiOffer.banner!.isNotEmpty;

                  if (cachedBannerEmpty && apiBannerNotEmpty) {
                    if (kDebugMode) {
                      print(
                          '🔄 HomeUnifiedController: Banner upgrade detected for offer ${cachedOffer.id} - empty → ${apiOffer.banner}');
                    }
                    return true; // Banner was upgraded
                  }
                }
              }
            }
          }
        }
      }
    }

    return false; // No banner upgrade detected
  }

  /// Save data to Hive cache
  /// ⚡ BFF API v2: Save to unified cache (single box) + individual caches (backward compatibility)
  Future<void> _saveToCache(int moduleId, HomeUnifiedModel data) async {
    try {
      // ⚡ BFF API v2: Save to unified cache first (single box, faster)
      await _cacheService.saveHomeUnifiedData(moduleId, data);

      // Also save to individual caches for backward compatibility
      // This ensures old cache structure still works during migration
      if (data.banners != null || data.campaigns != null) {
        final bannerModel = BannerModel(
          banners: data.banners,
          campaigns: data.campaigns,
        );
        await _cacheService.saveBanners(moduleId, bannerModel);
      }

      if (data.categories != null && data.categories!.isNotEmpty) {
        await _cacheService.saveCategories(moduleId, data.categories!);
      }

      if (data.popularStores != null && data.popularStores!.isNotEmpty) {
        final List<Store>? filteredPopularStores =
            _filterStoresByModule(data.popularStores, moduleId);
        if (filteredPopularStores != null && filteredPopularStores.isNotEmpty) {
          final storeModel = StoreModel(
            totalSize: filteredPopularStores.length,
            stores: filteredPopularStores,
          );
          await _cacheService.saveStores(moduleId, storeModel);
        }
      }

      if (data.brands != null && data.brands!.isNotEmpty) {
        await _cacheService.saveBrands(moduleId, data.brands!);
      }

      if (data.offers != null && data.offers!.isNotEmpty) {
        await _cacheService.saveOffers(moduleId, data.offers!.first);
      }

      if (kDebugMode) {
        print('💾 HomeUnifiedController: Data saved to unified cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HomeUnifiedController: Error saving to cache: $e');
      }
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    final moduleId = ModuleHelper.getModule()?.id;
    if (moduleId != null) {
      await _cacheService.clearModuleCache(moduleId);
      // ⚡ MULTI-TENANT: Remove from memory cache
      _moduleDataCache.remove(moduleId);
    }
    _lastFetchTime = null;
    update();
  }

  /// Debug helper: clear home_unified cache for known modules.
  /// Use this to break loop-prevention caused by stale cache.
  Future<void> clearHomeUnifiedCacheForAllModules() async {
    await CacheInvalidationService().invalidateAllHomeUnifiedCache();
    _moduleDataCache.clear();
    _lastFetchTimePerModule.clear();
    _lastFetchTime = null;
    _lastPreFetchTime = null;
    _lastLoadRequestTime = null;
    _lastLoadRequestModuleId = null;
    _homeGeneration = 0;
    update();
  }

  /// Clear cache and force fresh API request (bypasses 304)
  /// 🔧 FIX: Used when backend cache version changes (e.g., $bannersVersion = 'v2')
  Future<void> clearCacheAndForceRefresh({int? moduleId}) async {
    final effectiveModuleId = moduleId ?? ModuleHelper.getModule()?.id;
    if (effectiveModuleId == null) {
      if (kDebugMode) {
        print('❌ HomeUnifiedController: Cannot clear cache - no module ID');
      }
      return;
    }

    if (kDebugMode) {
      print(
          '🗑️ HomeUnifiedController: Clearing cache and forcing fresh request for module $effectiveModuleId');
    }

    // 1. Invalidate Hive cache
    await _cacheService.invalidateHomeUnifiedCache(effectiveModuleId);

    // 2. Clear memory cache
    _moduleDataCache.remove(effectiveModuleId);

    // 3. Clear ETags to force fresh request (bypass 304)
    // This ensures we get fresh data from API, not cached 304 responses
    // ETags are stored in HiveHomeCacheService - clear them via invalidateHomeUnifiedCache
    // The invalidateHomeUnifiedCache already clears the cache, which will force a fresh request

    // 4. Reset fetch time to force immediate refresh
    _lastFetchTime = null;
    _lastPreFetchTime = null;
    _lastLoadRequestTime = null;
    _lastLoadRequestModuleId = null;

    if (kDebugMode) {
      print(
          '✅ HomeUnifiedController: Cache cleared - next request will bypass 304 and fetch fresh data');
    }

    update();
  }

  /// Check if cache is stale (older than TTL)
  bool isCacheStale({Duration ttl = const Duration(minutes: 10)}) {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > ttl;
  }

  /// Called when a module is selected/ready
  /// Loads home data for the specified module
  Future<void> onModuleReady(int moduleId) async {
    forceResetLoadingState();
    await loadHomeData(moduleId: moduleId, forceRefresh: false);
  }

  /// ⚡ MODULE SWITCH: Prepare controller for module switch
  /// Call this BEFORE switching modules to:
  /// 1. Invalidate pending API requests (via generation increment)
  /// 2. Reset distribution tracking
  /// 3. Clear stale data from controllers
  /// This prevents race conditions when switching modules quickly
  void prepareForModuleSwitch() {
    // ⚡ STEP 1: Increment generation to invalidate all pending requests
    final int oldGen = _homeGeneration;
    _homeGeneration++;

    // ⚡ STEP 2: Reset distribution tracking
    _lastDistributedHash = null;
    _lastDistributedModuleId = null;

    // ⚡ STEP 3: Reset loading state
    _isLoading = false;
    _isFetching = false;
    _lastLoadRequestTime = null;
    _lastLoadRequestModuleId = null;

    if (kDebugMode) {
      print('🔄 HomeUnifiedController: Prepared for module switch');
      print('   - Generation: $oldGen → $_homeGeneration');
      print('   - Distribution tracking reset');
      print('   - Loading state reset');
    }
  }

  /// Allow immediate fetch for a module by clearing its last fetch timestamp.
  /// This prevents the min-interval guard from skipping a fresh load after a module switch.
  void allowImmediateFetchForModule(int moduleId) {
    _lastFetchTimePerModule.remove(moduleId);
  }

  /// Force unlock loading state (used before navigation/module switch)
  void forceResetLoadingState() {
    _isLoading = false;
    _isFetching = false;
    _lastLoadRequestTime = null;
    _lastLoadRequestModuleId = null;
  }

  /// ⚡ MODULE SWITCH: Clear current module data from controllers
  /// Call this when switching modules to ensure UI shows fresh data
  void clearCurrentModuleData() {
    final currentModuleId = ModuleHelper.getModule()?.id;
    if (currentModuleId == null) return;

    if (kDebugMode) {
      print(
          '🗑️ HomeUnifiedController: Clearing data for module $currentModuleId');
    }

    // Clear controller data to force fresh UI
    if (Get.isRegistered<BannerController>()) {
      Get.find<BannerController>().resetToDefault();
    }

    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().clearCategoryList(skipUpdate: true);
    }

    if (Get.isRegistered<StoreController>()) {
      Get.find<StoreController>().resetStoreData();
    }

    if (Get.isRegistered<BrandsController>()) {
      Get.find<BrandsController>().clearBrandList();
    }

    if (Get.isRegistered<Offers_Controller>()) {
      Get.find<Offers_Controller>().clearAllCache();
    }

    update();
  }

  /// 🔧 FIX 4: Ensure ApiClient headers are updated with current module/zone
  /// This is called before any API request to ensure headers have correct data
  /// Fixes the issue where headers have stale moduleId or zoneId
  void _ensureApiHeadersUpdated(int moduleId) {
    try {
      if (!Get.isRegistered<ApiClient>()) return;

      final apiClient = Get.find<ApiClient>();
      final AddressModel? address =
          AddressHelper.getUserAddressFromSharedPref();

      // Update headers with current module and zone
      apiClient.updateHeader(
        apiClient.token,
        address?.zoneIds,
        address?.areaIds,
        null, // languageCode - keep current
        moduleId,
        address?.latitude,
        address?.longitude,
      );

      if (kDebugMode) {
        print(
            '✅ HomeUnifiedController: ApiClient headers updated before API call');
        print('   - moduleId: $moduleId');
        print('   - zoneIds: ${address?.zoneIds}');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '⚠️ HomeUnifiedController: Error updating ApiClient headers - $e');
      }
    }
  }
}
