import 'dart:async';

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
import 'package:sixam_mart/util/app_constants.dart';

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

  // Disposal guard: prevents timer callbacks from executing after onClose()
  bool _disposed = false;

  int? get lastRequestStatusCode => homeUnifiedService.lastRequestStatusCode;
  String? get lastRequestErrorCode => homeUnifiedService.lastRequestErrorCode;
  bool get wasLastFailureHeaderBlocked =>
      homeUnifiedService.wasLastFailureHeaderBlocked;

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
  final Map<int, Future<HomeUnifiedModel?>> _activeApiRequests = {};

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
  final Map<int, DateTime> _lastStaleCacheInvalidationPerModule = {};
  static const Duration _staleCacheInvalidationInterval =
      Duration(minutes: 5);

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _lastFetchTime;
  DateTime? get lastFetchTime => _lastFetchTime;

  // 🔧 FIX: Track if data was just pre-fetched to skip immediate background refresh
  DateTime? _lastPreFetchTime;

  // Smart hidden polling for food modules (restaurants/cafes)
  Timer? _foodSmartRefreshTimer;
  int? _foodPollingModuleId;
  String? _lastFoodPollingFingerprint;
  int _stableFoodPollingTicks = 0;
  int _foodPollingAttempts = 0;
  static const Duration _foodSmartPollingInterval = Duration(seconds: 3);
  static const int _maxStableFoodPollingTicks = 2;
  static const int _maxFoodPollingAttempts = 20;

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
          if (kDebugMode) {
            final int bannerCount = (memoryData.banners?.length ?? 0) +
                (memoryData.campaigns?.length ?? 0);
            debugPrint(
                '[HOME_BANNER_CACHE_LOAD] moduleId=$moduleId count=$bannerCount source=memory');
          }
          // 🔧 FIX: Wrap distribution AND update in Future.microtask to fix setState during build
          Future.microtask(() {
            _distributeDataToControllers(memoryData,
                loadStores: loadStores, sourceModuleId: moduleId);
            update();
          });
          if (kDebugMode) {
            appLogger.debug('[Cache] HIT: home_unified_$moduleId (memory - 0ms)');
          }
          return true;
        }
      }

      // ⚡ STEP B: Load from disk cache (Hive)
      final cachedData = await _loadFromCache(moduleId);
      if (cachedData != null &&
          cachedData.isValid &&
          _isCachePayloadValid(cachedData, moduleId)) {
        if (kDebugMode) {
          final int bannerCount = (cachedData.banners?.length ?? 0) +
              (cachedData.campaigns?.length ?? 0);
          debugPrint(
              '[HOME_BANNER_CACHE_LOAD] moduleId=$moduleId count=$bannerCount source=hive');
        }
        // Store in memory cache for future instant switches
        _moduleDataCache[moduleId] = cachedData;
        // 🔧 FIX: Wrap distribution AND update in Future.microtask to fix setState during build
        Future.microtask(() {
          _distributeDataToControllers(cachedData,
              loadStores: loadStores, sourceModuleId: moduleId);
          update();
        });
        if (kDebugMode) {
          appLogger.debug('[Cache] HIT: home_unified_$moduleId (disk)');
        }
        return true;
      }

      if (kDebugMode) {
        appLogger.debug('[Cache] MISS: home_unified_$moduleId (not found or expired)');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('[Cache] MISS: home_unified_$moduleId (error: $e)', e);
      }
      return false;
    }
  }

  /// Cache-First: Pre-populate memory cache for instant module-switch rendering.
  ///
  /// Call this BEFORE navigating to a new module's home screen (e.g. in selectModule).
  /// Because [prepareForModuleSwitch] never clears [_moduleDataCache], the data
  /// pre-loaded here survives the reset and is hit immediately by the first
  /// [loadHomeData] call (memory-cache path, 0ms).
  ///
  /// Returns true if usable cache data was found (memory or Hive disk).
  Future<bool> applyFromCache(int moduleId) async {
    // Memory hit — already warm, nothing to do.
    final existing = _moduleDataCache[moduleId];
    if (existing != null &&
        existing.isValid &&
        _isCachePayloadValid(existing, moduleId)) {
      if (kDebugMode) {
        appLogger.debug(
            '⚡ applyFromCache: memory HIT for module $moduleId (0ms)');
      }
      return true;
    }

    // Hive disk read — fast (~2–10ms).
    try {
      final diskData = await _loadFromCache(moduleId);
      if (diskData != null &&
          diskData.isValid &&
          _isCachePayloadValid(diskData, moduleId)) {
        _moduleDataCache[moduleId] = diskData;
        if (kDebugMode) {
          appLogger.debug(
              '⚡ applyFromCache: Hive HIT for module $moduleId — pre-loaded into memory');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.warning(
            '⚠️ applyFromCache: error reading module $moduleId from Hive: $e');
      }
    }

    if (kDebugMode) {
      appLogger.debug(
          '⚡ applyFromCache: MISS for module $moduleId — no usable cache');
    }
    return false;
  }

  bool _isStaleGeneration(int requestGeneration, String scope) {
    final isStale = requestGeneration != _homeGeneration;
    if (isStale && kDebugMode) {
      appLogger.debug(
          '🚫 HomeUnifiedController: Discarding stale $scope response (gen $requestGeneration != $_homeGeneration)');
    }
    return isStale;
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
    final int? activeModuleId = ModuleHelper.getModule()?.id;
    // 🔧 FIX (Bug 1): Even with forceRefresh=true, if a request for this module
    // is already in flight, JOIN it instead of bailing. We also pre-populate
    // the memory cache here so that the calling controller's `unifiedData`
    // getter sees the parsed model BEFORE the original fetcher's
    // post-processing runs (which can be discarded by a stale generation).
    if (activeModuleId != null &&
        _activeApiRequests.containsKey(activeModuleId)) {
      if (kDebugMode) {
        appLogger.debug(
            'HomeUnifiedController: Reusing in-flight request for module $activeModuleId (forceRefresh=$forceRefresh)');
      }
      final reusedResponse = await _activeApiRequests[activeModuleId]!;
      if (reusedResponse != null && reusedResponse.isValid) {
        // ⚡ Defensive cache write: ensure `unifiedData` getter returns content
        // for HomeController's accept logic even if the original fetcher's
        // continuation has not yet run (or is about to be discarded by a
        // generation check).
        final existing = _moduleDataCache[activeModuleId];
        if (existing == null || !existing.isValid) {
          _moduleDataCache[activeModuleId] = reusedResponse;
          _lastFetchTime = DateTime.now();
          _lastFetchTimePerModule[activeModuleId] = DateTime.now();
          if (kDebugMode) {
            appLogger.debug(
                '⚡ HomeUnifiedController: Dedup-branch populated _moduleDataCache[$activeModuleId] '
                '(categories=${reusedResponse.categories?.length ?? 0}, '
                'offers=${reusedResponse.offers?.length ?? 0}, '
                'banners=${reusedResponse.banners?.length ?? 0})');
          }
          // Distribute on next microtask so callers see a populated cache first.
          Future.microtask(() => _distributeDataToControllers(
                reusedResponse,
                loadStores: true,
                sourceModuleId: activeModuleId,
              ));
        }
        return true;
      }
      return false;
    }
    if (_isLoading || _isFetching) {
      if (kDebugMode) {
        appLogger.debug(
            '🚫 HomeUnifiedController: Already loading/fetching, skipping duplicate call');
      }
      return hasCachedData;
    }
    final int? moduleForDebounce = ModuleHelper.getModule()?.id;
    final DateTime now = DateTime.now();
    if (!forceRefresh &&
        moduleForDebounce != null &&
        _lastLoadRequestModuleId == moduleForDebounce &&
        _lastLoadRequestTime != null &&
        now.difference(_lastLoadRequestTime!) < _loadRequestDebounce) {
      if (kDebugMode) {
        appLogger.debug(
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
      appLogger.debug(
          '🔄 HomeUnifiedController: Starting load with generation $currentGeneration');
    }

    // ⚡ Cache-First Fix: Always use current module ID (never accept different moduleId)
    // ❌ CRITICAL: moduleId parameter breaks Cache-First philosophy
    // If cache is for module 6 but API is called with moduleId=3, cache becomes invalid
    final currentModuleId = ModuleHelper.getModule()?.id;
    if (currentModuleId == null) {
      if (kDebugMode) {
        appLogger.error('[Cache-First] ERROR: No module selected - cannot load data', null);
      }
      return false;
    }

    // ⚡ CRITICAL: Assert moduleId matches current module (if provided)
    if (moduleId != null && moduleId != currentModuleId) {
      if (kDebugMode) {
        appLogger.error('[Cache-First] ERROR: Module ID mismatch!', null);
        appLogger.error('   - Cache is for module: $currentModuleId', null);
        appLogger.error('   - API called with moduleId: $moduleId', null);
        appLogger.error(
            '   - This breaks Cache-First philosophy - ignoring moduleId parameter', null);
      }
      // Use current module ID instead of provided one
    }

    final effectiveModuleId = currentModuleId; // Always use current module

    if (forceRefresh) {
      await _cacheService.invalidateHomeUnifiedCache(
        effectiveModuleId,
        clearEtag: true,
      );
      _moduleDataCache.remove(effectiveModuleId);
    }

    // 🔧 FIX 4: Ensure ApiClient headers are updated with current module/zone BEFORE API call
    // This fixes the issue where headers have stale data when requesting home data
    _ensureApiHeadersUpdated(effectiveModuleId);

    // ⚡ OPTIMIZATION: Check if we recently fetched this module (prevent rapid duplicate calls)
    // Bug#4 FIX: Only apply the interval guard when valid data already exists in memory.
    // If memory cache is empty (e.g. 304 + empty Hive), allow immediate retry
    // regardless of how recently _lastFetchTimePerModule was set.
    if (!forceRefresh) {
      final lastFetchTime = _lastFetchTimePerModule[effectiveModuleId];
      if (lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(lastFetchTime);
        if (timeSinceLastFetch < _minFetchInterval) {
          // Only block if we actually have usable data for this module.
          final cached = _moduleDataCache[effectiveModuleId];
          final hasValidData = cached != null &&
              cached.isValid &&
              _isCachePayloadValid(cached, effectiveModuleId);
          if (hasValidData) {
            if (kDebugMode) {
              appLogger.debug(
                  '⚡ HomeUnifiedController: Skipping duplicate call — has valid data '
                  '(last fetch ${timeSinceLastFetch.inSeconds}s ago, module $effectiveModuleId)');
            }
            return true;
          } else if (kDebugMode) {
            appLogger.debug(
                '⚡ HomeUnifiedController: Bypassing interval — no valid data for '
                'module $effectiveModuleId, allowing retry.');
          }
        }
      }
    }

    if (kDebugMode && moduleId != null) {
      appLogger.debug(
          '✅ HomeUnifiedController: Loading home data with moduleId: $moduleId (pre-fetch mode)');
    }

    // ⚡ MULTI-TENANT: Check memory cache first (instant switch - 0ms)
    if (!forceRefresh && _moduleDataCache.containsKey(effectiveModuleId)) {
      final memoryData = _moduleDataCache[effectiveModuleId]!;
      if (memoryData.isValid) {
        // 🔧 TASK 2: Wrap in Future.microtask to fix setState during build
        Future.microtask(
            () => _distributeDataToControllers(memoryData, loadStores: true, sourceModuleId: effectiveModuleId));
        _isLoading = false;
        update();
        if (kDebugMode) {
          appLogger.debug(
              '⚡ HomeUnifiedController: Instant switch from memory cache (0ms) - module $effectiveModuleId');
        }
        // SWR: render from memory instantly, then silently refresh from API so
        // new categories/banners are always up-to-date (especially after module switch).
        // _refreshFromApiInBackground handles all guards internally:
        //   • skips if fetched < 10s ago (no redundant calls on quick back-nav)
        //   • skips if generation changed (no stale responses)
        //   • skips if already fetching
        _refreshFromApiInBackground(effectiveModuleId);
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
        appLogger.debug(
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
            appLogger.debug(
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
              appLogger.warning('⚠️ HomeUnifiedController: Error loading config: $e');
            }
          });
        } else if (splashController.isLoadingConfig && kDebugMode) {
          appLogger.debug(
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
        if (cachedData != null &&
            cachedData.isValid &&
            _isCachePayloadValid(cachedData, effectiveModuleId)) {
          if (kDebugMode) {
            appLogger.info(
                '✅ HomeUnifiedController: Loaded from disk cache, storing in memory and distributing data...');
          }
          // Store in memory cache for future instant switches
          _moduleDataCache[effectiveModuleId] = cachedData;
          // 🔧 TASK 2: Wrap in Future.microtask to fix setState during build
          Future.microtask(
              () => _distributeDataToControllers(cachedData, loadStores: true, sourceModuleId: effectiveModuleId));
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
              appLogger.debug(
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
          appLogger.debug(
              '🚫 HomeUnifiedController: Already fetching, skipping duplicate call');
        }
        _isLoading = false;
        return hasCachedData;
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
        apiData = await _fetchHomeUnifiedDataDeduped(
          moduleId: effectiveModuleId,
          include: include, // 🔧 FIX: Pass include parameter for lazy loading
        );
      } finally {
        _isFetching = false;
        _lastLoadRequestTime = null;
        _lastLoadRequestModuleId = null;
      }

      if (apiData != null && apiData.isValid) {
        // 🔧 FIX (Bug 1): Persist parsed data into memory cache IMMEDIATELY
        // (before the generation check). The generation check is only meant
        // to gate UI distribution when the user switched modules during the
        // fetch — it must NOT cause the parsed payload to be lost. Storing
        // here is keyed by `effectiveModuleId` which is the moduleId we
        // fetched for, so it is always correct for that module.
        _moduleDataCache[effectiveModuleId] = apiData;
        _lastFetchTime = DateTime.now();
        _lastFetchTimePerModule[effectiveModuleId] = DateTime.now();

        // ⚡ GENERATION CHECK: Discard stale UI distribution if module switched
        if (_isStaleGeneration(currentGeneration, 'main API')) {
          _isLoading = false;
          // Even on stale generation, the data is preserved in cache so any
          // subsequent loadHomeData (or unifiedData getter) sees real content.
          return true;
        }

        // 🔧 FIX 3: Check if new API data is identical to cached data BEFORE updating
        // This prevents flicker when skeleton disappears and data reloads
        final cachedDataBeforeUpdate = _moduleDataCache[effectiveModuleId];
        apiData = _preserveBannersFromCacheIfApiEmpty(
          cachedDataBeforeUpdate: cachedDataBeforeUpdate,
          apiData: apiData,
          moduleId: effectiveModuleId,
        );
        final isDataIdentical = cachedDataBeforeUpdate != null &&
            !_hasDataChanged(cachedDataBeforeUpdate, apiData);

        // 🔧 FIX: Force update if cached data has empty banners but API has banner URLs
        final hasBannerUpgrade =
            _hasBannerUpgrade(cachedDataBeforeUpdate, apiData);
        final shouldForceUpdate = hasBannerUpgrade;

        if (isDataIdentical && !shouldForceUpdate) {
          if (kDebugMode) {
            appLogger.debug(
                '✅ HomeUnifiedController: API data identical to cached data, skipping update() to prevent flicker');
            appLogger.debug('   - Version hash: ${apiData.meta?.versionHash}');
          }
          // Still save to cache to update timestamps, but don't update UI
          await _saveToCache(effectiveModuleId, apiData);
          _lastFetchTime = DateTime.now();
          _isLoading = false;
          return true; // Return early - no UI update needed
        }

        if (shouldForceUpdate && kDebugMode) {
          appLogger.debug(
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
          appLogger.info(
              '✅ HomeUnifiedController: Pre-fetch complete - data stored in memory cache (moduleId: $moduleId)');
          appLogger.debug(
              '   - Banners: ${apiData.banners?.length ?? 0}, Offers: ${apiData.offers?.length ?? 0}');
          appLogger.debug(
              '   - Stored in _moduleDataCache[$moduleId] for instant switching');
        }

        // Distribute to controllers
        // 🔧 TASK 2: Wrap in Future.microtask to fix setState during build
        // Store in local variable to ensure non-null in closure
        final dataToDistribute = apiData;
        final genAtDistribute = currentGeneration;
        Future.microtask(() {
          // ⚡ GENERATION CHECK: Skip distribution if module switched
          if (_isStaleGeneration(genAtDistribute, 'distribution')) {
            return;
          }
          _distributeDataToControllers(dataToDistribute, loadStores: true, sourceModuleId: effectiveModuleId);
        });

        // Save to cache
        await _saveToCache(effectiveModuleId, apiData);

        if (kDebugMode) {
          appLogger.info('✅ HomeUnifiedController: API data loaded and distributed');
        }

        _isLoading = false;

        // 🔧 FIX 2: Stop rebuild loop if version hash is identical
        if (oldVersionHash != null &&
            newVersionHash != null &&
            oldVersionHash == newVersionHash) {
          if (kDebugMode) {
            appLogger.debug(
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
            appLogger.warning(
                '⚠️ HomeUnifiedController: Empty/invalid API response - preserving cached data for module $effectiveModuleId');
          }
          _moduleDataCache[effectiveModuleId] = fallbackData;
          _lastFetchTime = DateTime.now();
          Future.microtask(() {
            if (_isStaleGeneration(currentGeneration, 'fallback distribution')) {
              return;
            }
            _distributeDataToControllers(fallbackData, loadStores: true, sourceModuleId: effectiveModuleId);
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
        appLogger.error('❌ HomeUnifiedController: Error loading home data: $e', e);
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
      bool force = false,
      int? sourceModuleId}) {
    final int? activeModuleId = ModuleHelper.getModule()?.id;
    final int? responseModuleId =
        sourceModuleId ?? data.meta?.moduleId ?? activeModuleId;
    final int? currentModuleId = responseModuleId;
    final dataHash = data.hashCode;

    // Reject stale payloads when module switched before microtask execution.
    if (activeModuleId != null &&
        responseModuleId != null &&
        activeModuleId != responseModuleId) {
      if (kDebugMode) {
        debugPrint(
            '[HOME_BANNER_IGNORED_STALE] responseModuleId=$responseModuleId currentModuleId=$activeModuleId');
      }
      return false;
    }

    // 🔧 FIX 3: Detect module change for hard reset logic
    final bool isModuleChange = _lastDistributedModuleId != null &&
        _lastDistributedModuleId != currentModuleId;

    // 🔧 FIX 3: Force distribution on first load (for guest/new user)
    // This ensures UI always gets data on first launch even if hash matches cached
    final isFirstDistribution = !_hasEverDistributed;
    if (isFirstDistribution) {
      _hasEverDistributed = true;
      if (kDebugMode) {
        appLogger.debug(
            '🚀 HomeUnifiedController: First distribution - forcing update (guest/new user fix)');
      }
    }

    // 🔧 FIX 3: If module changed, log and prepare for hard reset
    if (isModuleChange && kDebugMode) {
      appLogger.info(
          '🔄 HomeUnifiedController: MODULE CHANGE detected ($_lastDistributedModuleId → $currentModuleId)');
      appLogger.debug('   → Hard reset: will NOT preserve old module data');
    }

    // 🔧 FIX: Prevent duplicate distribution ONLY if moduleId is the same and hash matches
    // BUT skip this check on first distribution to ensure UI always gets data
    if (!force &&
        !isFirstDistribution &&
        !isModuleChange && // 🔧 FIX 3: Always distribute on module change
        _lastDistributedModuleId == currentModuleId &&
        _lastDistributedHash == dataHash) {
      if (kDebugMode) {
        appLogger.debug(
            '✅ HomeUnifiedController: Skipping duplicate distribution (same module: $currentModuleId, same hash: $dataHash)');
      }
      return false; // No update needed
    }

    // Update tracking
    _lastDistributedHash = dataHash;
    _lastDistributedModuleId = currentModuleId;

    if (kDebugMode) {
      appLogger.debug(
          '🔄 HomeUnifiedController: Distributing data to controllers... (module: $currentModuleId)');
    }

    bool shouldUpdateUI = false;

    // 1. Banner Controller
    if (Get.isRegistered<BannerController>()) {
      final bannerController = Get.find<BannerController>();

      // 🔍 DEBUG: Log banner data from API response
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        appLogger.debug('🔍 HomeUnifiedController: Banner distribution check');
        appLogger.debug('   - data.banners: ${data.banners?.length ?? 0} items');
        appLogger.debug('   - data.campaigns: ${data.campaigns?.length ?? 0} items');
        if (data.banners != null && data.banners!.isNotEmpty) {
          appLogger.debug('   - First banner: ${data.banners!.first.imageFullUrl}');
        }
        if (data.campaigns != null && data.campaigns!.isNotEmpty) {
          appLogger.debug('   - First campaign: ${data.campaigns!.first.imageFullUrl}');
        }
        appLogger.debug(
            '   - Existing banners: ${bannerController.bannerImageList?.length ?? 0}');
        appLogger.debug(
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

      if (kDebugMode && AppConstants.enableVerboseLogs) {
        appLogger.debug('   - hasExistingBanners: $hasExistingBanners');
        appLogger.debug('   - hasNewBanners: $hasNewBanners');
      }

      // Only update if we have new banners AND (no existing banners OR new banners are not empty)
      if (hasNewBanners) {
        if (kDebugMode) {
          final int newBannerCount =
              (data.banners?.length ?? 0) + (data.campaigns?.length ?? 0);
          debugPrint(
              '[HOME_BANNER_API_SUCCESS] moduleId=$currentModuleId count=$newBannerCount');
        }
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
                appLogger.debug(
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
            bannerController.setFromUnified(
              bannerModel: bannerModel,
              moduleId: currentModuleId,
              source: 'home_unified',
            );
            shouldUpdateUI = true;
            if (kDebugMode) {
              appLogger.debug(
                  '   ✓ BannerController: ${data.banners?.length ?? 0} banners, ${data.campaigns?.length ?? 0} campaigns');
            }
          } catch (e, stackTrace) {
            appLogger.error('Banner Distribution Failed', e, stackTrace);
            if (kDebugMode) {
              appLogger.error('   ❌ BannerController: Distribution failed - $e', e);
            }
          }
        }
      } else if (hasExistingBanners && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing banners if SAME module
        // If module changed, do NOT preserve - clear old data
        if (kDebugMode) {
          appLogger.debug(
              '   🛡️ BannerController: Discarding empty update - preserving existing banners (same module)');
        }
      } else if (isModuleChange) {
        // Module changed + no banners in payload: clear stale banners from previous module.
        if (kDebugMode) {
          appLogger.info(
              '   🗑️ BannerController: Module changed with empty banners - clearing stale banner state');
        }
        try {
          bannerController.clearUnifiedBanners(
            notify: true,
            moduleId: currentModuleId,
            reason: 'module_change_empty_payload',
          );
          shouldUpdateUI = true;
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning('   ⚠️ BannerController: Error while clearing stale banners - $e');
          }
        }
      } else {
        // 🔍 DEBUG: Log when no banners are found
        if (kDebugMode) {
          debugPrint(
              '[HOME_BANNER_EMPTY] moduleId=$currentModuleId reason=distribution_no_banners');
          appLogger.warning(
              '   ⚠️ BannerController: No banners in API response and no existing banners');
          appLogger.debug('      - banners: ${data.banners?.length ?? 0}');
          appLogger.debug('      - campaigns: ${data.campaigns?.length ?? 0}');
        }

        // 🔧 FALLBACK: If unified endpoint returns no banners, try loading from legacy banner endpoint
        // This ensures banners show even if unified endpoint has issues
        if (!hasExistingBanners && Get.isRegistered<BannerController>()) {
          final bannerController = Get.find<BannerController>();
          // Only trigger fallback if we truly have no banners (not just empty update)
          if (bannerController.bannerImageList == null &&
              bannerController.featuredBannerList == null) {
            if (kDebugMode) {
              appLogger.debug(
                  '   🔄 BannerController: Triggering fallback to legacy banner endpoint...');
            }
            // Load banners from legacy endpoint in background
            bannerController
                .getBannerList(false, dataSource: DataSourceEnum.client)
                .catchError((Object e) {
              if (kDebugMode) {
                appLogger.warning(
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
          categoryController.setCategoryListFromCache(
            data.categories!,
            expectedModuleId: currentModuleId,
          );
          if (kDebugMode) {
            appLogger.debug(
                '   ✓ CategoryController: ${data.categories!.length} categories');
          }
        } catch (e, stackTrace) {
          appLogger.error('Category Distribution Failed', e, stackTrace);
          if (kDebugMode) {
            appLogger.error('   ❌ CategoryController: Distribution failed - $e', e);
          }
        }
      } else if (hasExistingCategories && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing categories if SAME module
        // If module changed, do NOT preserve - clear old data
        if (kDebugMode) {
          appLogger.debug(
              '   🛡️ CategoryController: Discarding empty update - preserving existing ${categoryController.categoryList!.length} categories (same module)');
        }
      } else if (isModuleChange) {
        // 🔧 FIX 3: Module changed - HARD RESET categories
        if (kDebugMode) {
          appLogger.info(
              '   🗑️ CategoryController: Module changed - clearing old categories (hard reset)');
        }
        try {
          categoryController.clearCategoryList(skipUpdate: true);
          shouldUpdateUI = true;
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning('   ⚠️ CategoryController: Error during hard reset - $e');
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
            appLogger.debug(
                '   ✓ StoreController: ${data.popularStores!.length} popular stores (popularStoreList only)');
          }
        } catch (e, stackTrace) {
          appLogger.error('Store Distribution Failed', e, stackTrace);
          if (kDebugMode) {
            appLogger.error('   ❌ StoreController: Distribution failed - $e', e);
          }
        }
      } else if (hasExistingPopularStores && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing stores if SAME module
        if (kDebugMode) {
          appLogger.debug(
              '   🛡️ StoreController: Discarding empty update - preserving existing ${storeController.popularStoreList!.length} popular stores (same module)');
        }
      } else if (isModuleChange) {
        // 🔧 FIX 3: Module changed - HARD RESET stores
        if (kDebugMode) {
          appLogger.info(
              '   🗑️ StoreController: Module changed - clearing old stores (hard reset)');
        }
        try {
          storeController.resetStoreData();
          shouldUpdateUI = true;
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning('   ⚠️ StoreController: Error during hard reset - $e');
          }
        }
      }

      // 🚫 DEFENSIVE CHECK: Verify we never set storeModel or allStoreModel directly
      // If this assertion fails, it means V2 is contaminating legacy state
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        // Verify setPopularStoreDataFromBootstrap doesn't touch storeModel or allStoreModel
        // This is a runtime check to catch any accidental contamination
        final currentStoreModel = storeController.storeModel;
        final currentAllStoreModel = storeController.allStoreModel;
        if (currentStoreModel != null &&
            currentStoreModel.totalSize == data.popularStores?.length) {
          appLogger.warning(
              '   ⚠️ WARNING: StoreModel totalSize matches popularStores count - possible V2 contamination!');
        }
        // ⚡ HARD-ISOLATION: Verify allStoreModel is never touched by V2
        if (currentAllStoreModel != null &&
            currentAllStoreModel.totalSize == data.popularStores?.length) {
          appLogger.warning(
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
            appLogger.debug('   ✓ BrandsController: ${data.brands!.length} brands');
          }
        } catch (e, stackTrace) {
          appLogger.error('Brands Distribution Failed', e, stackTrace);
          if (kDebugMode) {
            appLogger.error('   ❌ BrandsController: Distribution failed - $e', e);
          }
        }
      } else if (hasExistingBrands && !isModuleChange) {
        // 🔧 FIX 3: Only preserve existing brands if SAME module
        if (kDebugMode) {
          appLogger.debug(
              '   🛡️ BrandsController: Discarding empty update - preserving existing ${brandsController.brandList!.length} brands (same module)');
        }
      } else if (isModuleChange) {
        // 🔧 FIX 3: Module changed - HARD RESET brands
        if (kDebugMode) {
          appLogger.info(
              '   🗑️ BrandsController: Module changed - clearing old brands (hard reset)');
        }
        try {
          brandsController.clearBrandList();
          shouldUpdateUI = true;
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning('   ⚠️ BrandsController: Error during hard reset - $e');
          }
        }
      }
    }

    // 5. Offers Controller
    if (Get.isRegistered<OffersController>()) {
      final offersController = Get.find<OffersController>();

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
                appLogger.debug(
                    '   ✓ OffersController: Data identical, skipping update() to prevent flicker');
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
            appLogger.debug(
                '   ✓ OffersController: Screen is empty, forcing update with ${data.offers!.length} offers');
          }
        }

        if (shouldUpdateOffers) {
          // 🔧 TASK 1: Titan Mandate - If offers count is 0, do NOT update OffersController state
          // This prevents empty cached responses from wiping the UI
          final offersCount = data.offers!.first.data.length;
          if (offersCount == 0) {
            if (isModuleChange) {
              if (kDebugMode) {
                appLogger.info(
                    '   🗑️ OffersController: Module changed with empty offers - clearing stale offers');
              }
              offersController.clearOffersFromUnified(notify: true);
              shouldUpdateUI = true;
            } else {
              if (kDebugMode) {
                appLogger.debug(
                    '   🛡️ OffersController: Offers count is 0, preserving existing data (same module)');
              }
              // Don't update - preserve existing offers data on same module
            }
          } else {
            // 🔧 PROTECTIVE DISTRIBUTION: Wrap in try-catch to prevent crash from blocking other controllers
            try {
              offersController.setOffersFromBootstrap(data.offers!);
              shouldUpdateUI = true;
              if (kDebugMode) {
                appLogger.debug(
                    '   ✓ OffersController: Injected ${data.offers!.length} offers ($offersCount items)');
              }
            } catch (e, stackTrace) {
              appLogger.error('Offers Distribution Failed', e, stackTrace);
              if (kDebugMode) {
                appLogger.error('   ❌ OffersController: Distribution failed - $e', e);
              }
            }
          }
        }
      } else if (hasExistingOffers) {
        if (isModuleChange) {
          if (kDebugMode) {
            appLogger.info(
                '   🗑️ OffersController: Module changed and bootstrap has no offers - clearing stale offers');
          }
          offersController.clearOffersFromUnified(notify: true);
          shouldUpdateUI = true;
        } else if (kDebugMode) {
          appLogger.debug(
              '   ✓ OffersController: Bootstrap has no offers, preserving existing ${offersController.offersMode!.data.length} offers (same module)');
        }
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
            appLogger.debug('   ✓ ProfileController: Customer data loaded');
          }
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning('   ⚠️ ProfileController: Error parsing customer data: $e');
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
            appLogger.debug(
                '   ✓ HomeController: Business settings synced from V2 response');
          }
        } else if (kDebugMode) {
          appLogger.debug(
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
              appLogger.debug(
                  '   ✅ HomeController: Business settings restored from SplashController cache');
            }
          }
        }
        if (kDebugMode) {
          appLogger.debug(
              '   ⚠️ HomeController: Business settings missing in V2 payload, preserving existing settings');
        }
      }
    }

    if (kDebugMode) {
      appLogger.info('✅ HomeUnifiedController: Data distribution complete');
    }

    update();
    return shouldUpdateUI;
  }

  Future<HomeUnifiedModel?> _fetchHomeUnifiedDataDeduped({
    required int moduleId,
    String? include,
  }) {
    final existingRequest = _activeApiRequests[moduleId];
    if (existingRequest != null) {
      if (kDebugMode) {
        appLogger.debug(
            '🔄 HomeUnifiedController: Reusing in-flight API request for module $moduleId');
      }
      return existingRequest;
    }

    final request = homeUnifiedService.getHomeUnifiedData(
      moduleId: moduleId,
      include: include,
    );
    _activeApiRequests[moduleId] = request;
    request.whenComplete(() {
      final current = _activeApiRequests[moduleId];
      if (identical(current, request)) {
        _activeApiRequests.remove(moduleId);
      }
    });

    return request;
  }

  /// Warm a specific module payload during splash/startup without touching UI state.
  /// This fills memory + Hive cache so switching modules later is instant.
  Future<bool> preloadModuleDataForSplash(
    int moduleId, {
    bool forceRefresh = false,
  }) async {
    if (moduleId <= 0) {
      return false;
    }

    try {
      if (!forceRefresh) {
        final inMemory = _moduleDataCache[moduleId];
        if (inMemory != null && inMemory.isValid) {
          if (kDebugMode) {
            appLogger.debug(
                '⚡ HomeUnifiedController: Splash preload skip (memory hit) for module $moduleId');
          }
          return true;
        }

        final onDisk = await _loadFromCache(moduleId);
        if (onDisk != null &&
            onDisk.isValid &&
            _isCachePayloadValid(onDisk, moduleId)) {
          _moduleDataCache[moduleId] = onDisk;
          if (kDebugMode) {
            appLogger.debug(
                '⚡ HomeUnifiedController: Splash preload hydrated from disk for module $moduleId');
          }
          return true;
        }
      }

      final int preloadGeneration = _homeGeneration;
      final apiData = await _fetchHomeUnifiedDataDeduped(moduleId: moduleId);
      final activeModuleId = ModuleHelper.getModule()?.id;
      if (activeModuleId == moduleId &&
          _isStaleGeneration(preloadGeneration, 'splash-preload')) {
        return false;
      }
      if (apiData != null && apiData.isValid) {
        _moduleDataCache[moduleId] = apiData;
        await _saveToCache(moduleId, apiData);
        _lastFetchTimePerModule[moduleId] = DateTime.now();

        if (kDebugMode) {
          appLogger.debug(
              '✅ HomeUnifiedController: Splash preload completed for module $moduleId');
        }
        return true;
      }

      if (kDebugMode) {
        appLogger.warning(
            '⚠️ HomeUnifiedController: Splash preload returned empty for module $moduleId');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        appLogger.warning(
            '⚠️ HomeUnifiedController: Splash preload failed for module $moduleId: $e');
      }
      return false;
    }
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
      if (_isStaleGeneration(refreshGeneration, 'background-delay')) {
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
            appLogger.debug(
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
            appLogger.debug(
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
          appLogger.debug(
              '[Cache-First] Background refresh skipped - no cached data (first load)');
        }
        return; // First load - not background refresh
      }

      // 🛠️ TASK 1: Check request lock to prevent duplicate calls
      if (_isFetching) {
        if (kDebugMode) {
          appLogger.debug('[Cache-First] Background refresh skipped - already fetching');
        }
        return;
      }

      _isFetching = true;

      // ⚡ OPTIMIZATION: Update last fetch time per module (even if API call fails)
      final effectiveModuleIdForFetch = ModuleHelper.getModule()?.id;
      if (effectiveModuleIdForFetch != null) {
        _lastFetchTimePerModule[effectiveModuleIdForFetch] = DateTime.now();
      }
      try {
        if (kDebugMode) {
          appLogger.debug(
              '[API] background refresh started (truly background - no UI blocking)');
        }

        final apiData = await _fetchHomeUnifiedDataDeduped(
          moduleId: moduleId,
        );

        // ⚡ GENERATION CHECK: Discard stale response if module switched during API call
        if (_isStaleGeneration(refreshGeneration, 'background API')) {
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
              appLogger.debug('[API] data identical → skip update (version_hash match)');
            }
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
                appLogger.debug('[API] data changed → updating UI');
              }

              // ⚡ Cache-First: Distribute new data WITHOUT resetting scroll position
              // Preserve UI state during silent refresh
              Future.microtask(() async {
                if (_isStaleGeneration(refreshGeneration, 'background distribution')) {
                  return;
                }
                final shouldUpdateUI = _distributeDataToControllers(apiData,
                    skipUpdateIfIdentical: true,
                    loadStores: true,
                    sourceModuleId: moduleId);

                // ⚡ Save to cache (always save to update timestamps)
                await _saveToCache(moduleId, apiData);

                // ⚡ Only trigger UI update if data actually changed
                if (shouldUpdateUI) {
                  update();

                  if (kDebugMode) {
                    appLogger.info(
                        '✅ HomeUnifiedController: Silent refresh complete - UI updated without scroll reset');
                    appLogger.debug(
                        '   - Edge cache expired, new data from origin server');
                  }
                } else {
                  if (kDebugMode) {
                    appLogger.debug(
                        '✅ HomeUnifiedController: Data identical, skipped update() to prevent flicker');
                  }
                }
              });
            } else {
              if (kDebugMode) {
                appLogger.debug(
                    '✅ HomeUnifiedController: Background refresh - new data is not better, preserving existing');
              }
            }
          } else {
            if (kDebugMode) {
              appLogger.debug(
                  '✅ HomeUnifiedController: Background refresh complete - no changes (version_hash match)');
            }
          }
        } else {
          // ⚡ EDGE CACHE: Handle edge cache expiration gracefully
          // If API returns null/invalid, check if it's due to edge cache expiration
          // In this case, preserve existing cache data and retry later
          if (kDebugMode) {
            appLogger.warning(
                '⚠️ HomeUnifiedController: Background refresh - API returned invalid data, preserving cache');
            appLogger.debug('   - This may be due to edge cache (s-maxage) expiration');
            appLogger.debug('   - Will retry on next background refresh cycle');
          }
          // Don't update - preserve existing cache data
          // Background refresh will retry automatically on next cycle
        }
      } catch (e) {
        if (kDebugMode) {
          appLogger.warning('⚠️ HomeUnifiedController: Background refresh failed: $e');
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

  HomeUnifiedModel _preserveBannersFromCacheIfApiEmpty({
    required HomeUnifiedModel? cachedDataBeforeUpdate,
    required HomeUnifiedModel apiData,
    required int moduleId,
  }) {
    if (cachedDataBeforeUpdate == null) {
      return apiData;
    }
    final bool apiHasNoBanners =
        (apiData.banners == null || apiData.banners!.isEmpty) &&
            (apiData.campaigns == null || apiData.campaigns!.isEmpty);
    final bool cacheHasBanners =
        (cachedDataBeforeUpdate.banners != null &&
                cachedDataBeforeUpdate.banners!.isNotEmpty) ||
            (cachedDataBeforeUpdate.campaigns != null &&
                cachedDataBeforeUpdate.campaigns!.isNotEmpty);

    if (!apiHasNoBanners || !cacheHasBanners) {
      return apiData;
    }

    if (kDebugMode) {
      appLogger.warning(
          '⚠️ HomeUnifiedController: API banners empty for module $moduleId - preserving cached banners');
      appLogger.debug(
          '   - cached banners: ${cachedDataBeforeUpdate.banners?.length ?? 0}, campaigns: ${cachedDataBeforeUpdate.campaigns?.length ?? 0}');
    }

    return HomeUnifiedModel(
      banners: cachedDataBeforeUpdate.banners,
      campaigns: cachedDataBeforeUpdate.campaigns,
      categories: apiData.categories,
      popularStores: apiData.popularStores,
      brands: apiData.brands,
      offers: apiData.offers,
      customer: apiData.customer,
      businessSettings: apiData.businessSettings,
      promotionalBanner: apiData.promotionalBanner,
      meta: apiData.meta,
    );
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
        appLogger.debug(
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
      if (unifiedData != null &&
          unifiedData.isValid &&
          _isCachePayloadValid(unifiedData, moduleId)) {
        // 🔧 FIX: Validate offers have banner URLs - invalidate cache if empty
        final hasEmptyBanners = _hasOffersWithEmptyBanners(unifiedData);
        if (hasEmptyBanners) {
          if (kDebugMode) {
            appLogger.warning(
                '⚠️ HomeUnifiedController: Cached offers have empty banners - invalidating cache');
          }
          // Invalidate cache to force refresh
          await _invalidateStaleCacheIfNeeded(
            moduleId,
            reason: 'offers with empty banners in unified cache',
          );
          return null; // Force refresh from API
        }

        if (kDebugMode) {
          appLogger.info('✅ HomeUnifiedController: Loaded from unified cache');
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

      // Reject weak/empty payloads that can cause blank module home on first render.
      if (!_isCachePayloadValid(fallbackData, moduleId)) {
        await _invalidateStaleCacheIfNeeded(
          moduleId,
          reason: 'weak fallback cache payload',
        );
        return null;
      }

      // 🔧 FIX: Validate offers have banner URLs - invalidate cache if empty
      final hasEmptyBanners = _hasOffersWithEmptyBanners(fallbackData);
      if (hasEmptyBanners) {
        if (kDebugMode) {
          appLogger.warning(
              '⚠️ HomeUnifiedController: Cached offers have empty banners - invalidating cache');
        }
        // Invalidate cache to force refresh
        await _invalidateStaleCacheIfNeeded(
          moduleId,
          reason: 'offers with empty banners in fallback cache',
        );
        return null; // Force refresh from API
      }

      return fallbackData;
    } catch (e) {
      if (kDebugMode) {
        appLogger.warning('⚠️ HomeUnifiedController: Error loading from cache: $e');
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
              appLogger.warning(
                  '⚠️ HomeUnifiedController: Found offer with empty banner - id: ${offer.id}, name: ${offer.name}');
            }
            return true;
          }
        }
      }
    }

    return false; // All offers have banners
  }

  Future<void> _invalidateStaleCacheIfNeeded(
    int moduleId, {
    required String reason,
  }) async {
    final now = DateTime.now();
    final lastInvalidation = _lastStaleCacheInvalidationPerModule[moduleId];
    if (lastInvalidation != null &&
        now.difference(lastInvalidation) < _staleCacheInvalidationInterval) {
      if (kDebugMode) {
        appLogger.debug(
            '[Cache] SKIP INVALIDATE: home_unified_$moduleId - throttled ($reason)');
      }
      return;
    }

    _lastStaleCacheInvalidationPerModule[moduleId] = now;
    await _cacheService.invalidateHomeUnifiedCache(moduleId);
    if (kDebugMode) {
      appLogger.debug('[Cache] INVALIDATED: home_unified_$moduleId - $reason');
    }
  }

  /// Validate cached home payload before rendering it.
  /// A payload is valid if it has any usable section content.
  bool _isCachePayloadValid(HomeUnifiedModel data, int moduleId) {
    final bool hasBanners = (data.banners?.isNotEmpty ?? false) ||
        (data.campaigns?.isNotEmpty ?? false);
    final bool hasCategories = data.categories?.isNotEmpty ?? false;
    final bool hasStores = data.popularStores?.isNotEmpty ?? false;
    final bool hasBrands = data.brands?.isNotEmpty ?? false;
    final bool hasOffers = (data.offers?.any((e) => e.data.isNotEmpty) ?? false);

    if (hasBanners || hasCategories || hasStores || hasBrands || hasOffers) {
      return true;
    }

    if (kDebugMode) {
      appLogger.debug(
          '[Cache] INVALID: home_unified_$moduleId - no usable sections, forcing API');
    }
    return false;
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
                      appLogger.debug(
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
      final hasBannerPayload = (data.banners?.isNotEmpty ?? false) ||
          (data.campaigns?.isNotEmpty ?? false);
      if (hasBannerPayload) {
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
        appLogger.debug('💾 HomeUnifiedController: Data saved to unified cache');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.warning('⚠️ HomeUnifiedController: Error saving to cache: $e');
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
    _activeApiRequests.clear();
    _lastFetchTimePerModule.clear();
    _lastStaleCacheInvalidationPerModule.clear();
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
        appLogger.error('❌ HomeUnifiedController: Cannot clear cache - no module ID', null);
      }
      return;
    }

    if (kDebugMode) {
      appLogger.info(
          '🗑️ HomeUnifiedController: Clearing cache and forcing fresh request for module $effectiveModuleId');
    }

    // 1. Invalidate Hive cache
    await _cacheService.invalidateHomeUnifiedCache(
      effectiveModuleId,
      clearEtag: true,
    );

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
      appLogger.info(
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
    // If an API request for this module is already in-flight, await it instead
    // of resetting — forceResetLoadingState() would clear _activeApiRequests and
    // then loadHomeData() would increment _homeGeneration, causing the in-flight
    // request to be discarded as stale and HomeController to see success=false.
    final existingRequest = _activeApiRequests[moduleId];
    if (existingRequest != null) {
      if (kDebugMode) {
        appLogger.debug(
            '⏭️ HomeUnifiedController.onModuleReady: In-flight request for module $moduleId — awaiting instead of resetting');
      }
      await existingRequest;
      _restartSmartFoodPollingIfNeeded(moduleId);
      return;
    }
    forceResetLoadingState();
    await loadHomeData(moduleId: moduleId, forceRefresh: false);
    _restartSmartFoodPollingIfNeeded(moduleId);
  }

  /// ⚡ MODULE SWITCH: Prepare controller for module switch
  /// Call this BEFORE switching modules to:
  /// 1. Invalidate pending API requests (via generation increment)
  /// 2. Reset distribution tracking
  /// 3. Clear stale data from controllers
  /// This prevents race conditions when switching modules quickly
  void prepareForModuleSwitch() {
    _stopSmartFoodPolling();

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
    _activeApiRequests.clear();
    _lastFetchTimePerModule.clear();

    if (kDebugMode) {
      appLogger.info('🔄 HomeUnifiedController: Prepared for module switch');
      appLogger.debug('   - Generation: $oldGen → $_homeGeneration');
      appLogger.debug('   - Distribution tracking reset');
      appLogger.debug('   - Loading state reset');
    }
  }

  /// Cache-Miss preparation: pre-set loading state and wipe stale child-controller
  /// data so the very first frame of the new module's screen shows a clean shimmer
  /// instead of rendering stale data from the previous module.
  ///
  /// Call AFTER [prepareForModuleSwitch] when [applyFromCache] returned false.
  void prepareForCacheMissSwitch() {
    _isLoading = true; // First frame must see loading=true → shimmer
    _clearStaleChildControllers();
    if (kDebugMode) {
      appLogger.debug(
          '⚡ HomeUnifiedController: Cache miss — child controllers cleared, '
          'shimmer will show from first frame');
    }
  }

  /// Wipe data from the child controllers that distribute home-screen sections.
  /// Only clears, never triggers an update() — the caller owns the rebuild cycle.
  void _clearStaleChildControllers() {
    if (Get.isRegistered<BannerController>()) {
      try {
        Get.find<BannerController>().clearBanner();
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
    }
    if (Get.isRegistered<CategoryController>()) {
      try {
        Get.find<CategoryController>().clearCategoryList(skipUpdate: true);
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
    }
    if (Get.isRegistered<BrandsController>()) {
      try {
        Get.find<BrandsController>().clearBrandList();
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
    }
    // StoreController is already cleared by clearStoreData() in selectModule().
  }

  /// Allow immediate fetch for a module by clearing its last fetch timestamp.
  /// This prevents the min-interval guard from skipping a fresh load after a module switch.
  void allowImmediateFetchForModule(int moduleId) {
    _lastFetchTimePerModule.remove(moduleId);
  }

  /// Force unlock loading state (used before navigation/module switch)
  void forceResetLoadingState() {
    _stopSmartFoodPolling();
    _isLoading = false;
    _isFetching = false;
    _lastLoadRequestTime = null;
    _lastLoadRequestModuleId = null;
    _activeApiRequests.clear();
  }

  /// ⚡ MODULE SWITCH: Clear current module data from controllers
  /// Call this when switching modules to ensure UI shows fresh data
  void clearCurrentModuleData() {
    final currentModuleId = ModuleHelper.getModule()?.id;
    if (currentModuleId == null) return;

    if (kDebugMode) {
      appLogger.info(
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

    if (Get.isRegistered<OffersController>()) {
      Get.find<OffersController>().clearAllCache();
    }

    update();
  }

  bool _isFoodModuleForSmartPolling(int moduleId) {
    final module = ModuleHelper.getModule();
    return module?.id == moduleId && module?.moduleType == AppConstants.food;
  }

  bool _isFoodDataIncomplete(HomeUnifiedModel? data, int moduleId) {
    if (data == null || !data.isValid) {
      return true;
    }

    final bool hasCategories = data.categories?.isNotEmpty ?? false;
    final bool hasBanners = (data.banners?.isNotEmpty ?? false) ||
        (data.campaigns?.isNotEmpty ?? false);
    final bool hasOffers =
        data.offers?.any((offer) => offer.data.isNotEmpty) ?? false;

    // For food modules, categories are the critical minimum payload.
    // Banners/offers can be intentionally empty for some modules.
    if (!hasCategories && !hasBanners && !hasOffers) {
      return true;
    }

    return !_isCachePayloadValid(data, moduleId);
  }

  String _buildFoodDataFingerprint(HomeUnifiedModel? data) {
    if (data == null) {
      return 'null';
    }
    final String? versionHash = data.meta?.versionHash;
    if (versionHash != null && versionHash.isNotEmpty) {
      return 'v:$versionHash';
    }
    final int categories = data.categories?.length ?? 0;
    final int banners = (data.banners?.length ?? 0) + (data.campaigns?.length ?? 0);
    final int offers = data.offers?.fold<int>(0, (count, offer) => count + offer.data.length) ?? 0;
    return 'f:$categories:$banners:$offers';
  }

  void _restartSmartFoodPollingIfNeeded(int moduleId) {
    if (!_isFoodModuleForSmartPolling(moduleId)) {
      _stopSmartFoodPolling();
      return;
    }

    if (_foodSmartRefreshTimer != null &&
        _foodSmartRefreshTimer!.isActive &&
        _foodPollingModuleId == moduleId) {
      return;
    }

    _stopSmartFoodPolling();
    _foodPollingModuleId = moduleId;
    _lastFoodPollingFingerprint = _buildFoodDataFingerprint(_moduleDataCache[moduleId]);
    _stableFoodPollingTicks = 0;
    _foodPollingAttempts = 0;

    if (kDebugMode) {
      appLogger.debug(
          '🔄 HomeUnifiedController: Starting smart hidden refresh (every ${_foodSmartPollingInterval.inSeconds}s) for food module $moduleId');
    }

    _foodSmartRefreshTimer =
        Timer.periodic(_foodSmartPollingInterval, (_) => _runSmartFoodPollingTick(moduleId));
  }

  void _runSmartFoodPollingTick(int moduleId) {
    if (_disposed) return;
    if (!_isFoodModuleForSmartPolling(moduleId) || ModuleHelper.getModule()?.id != moduleId) {
      _stopSmartFoodPolling();
      return;
    }

    _foodPollingAttempts++;
    if (_foodPollingAttempts > _maxFoodPollingAttempts) {
      if (kDebugMode) {
        appLogger.debug(
            '⏹️ HomeUnifiedController: Stopping smart refresh for module $moduleId (max attempts reached)');
      }
      _stopSmartFoodPolling();
      return;
    }

    if (_isFetching) {
      return;
    }

    final HomeUnifiedModel? currentData = _moduleDataCache[moduleId];
    final bool isIncomplete = _isFoodDataIncomplete(currentData, moduleId);
    final String currentFingerprint = _buildFoodDataFingerprint(currentData);

    if (!isIncomplete) {
      if (_lastFoodPollingFingerprint == currentFingerprint) {
        _stableFoodPollingTicks++;
      } else {
        _stableFoodPollingTicks = 0;
        _lastFoodPollingFingerprint = currentFingerprint;
      }

      if (_stableFoodPollingTicks >= _maxStableFoodPollingTicks) {
        if (kDebugMode) {
          appLogger.debug(
              '✅ HomeUnifiedController: Smart refresh stopped for module $moduleId (data stable)');
        }
        _stopSmartFoodPolling();
        return;
      }
    } else {
      _stableFoodPollingTicks = 0;
    }

    _refreshFromApiInBackground(moduleId);
  }

  void _stopSmartFoodPolling() {
    _foodSmartRefreshTimer?.cancel();
    _foodSmartRefreshTimer = null;
    _foodPollingModuleId = null;
    _lastFoodPollingFingerprint = null;
    _stableFoodPollingTicks = 0;
    _foodPollingAttempts = 0;
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
        appLogger.debug(
            '✅ HomeUnifiedController: ApiClient headers updated before API call');
        appLogger.debug('   - moduleId: $moduleId');
        appLogger.debug('   - zoneIds: ${address?.zoneIds}');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.warning(
            '⚠️ HomeUnifiedController: Error updating ApiClient headers - $e');
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    _stopSmartFoodPolling();
    super.onClose();
  }
}

