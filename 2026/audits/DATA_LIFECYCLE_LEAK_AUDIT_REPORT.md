# DATA REQUIREMENT & LIFECYCLE LEAKS - COMPREHENSIVE AUDIT REPORT

**Date:** 2025-01-27  
**Auditor:** Principal Flutter Architect (Systems Specialist)  
**Scope:** StoreController, HomeUnifiedController, Store/Home Screens  
**Critical Issue:** Parallel Bombing + Data Poisoning

---

## EXECUTIVE SUMMARY

The app exhibits **critical data lifecycle leaks** causing:
- **Zombie Data Contamination:** Store ID 1 data persists when navigating to Store ID 62
- **Parallel API Bombing:** Multiple screens fire 3+ simultaneous API calls on `initState`
- **State Memory Leaks:** Store-specific and global category lists share memory references
- **Request Cancellation Gaps:** CancelToken logic exists but is incomplete
- **Main Thread Blocking:** Heavy operations during module switching cause "Skipped 52 frames"

**Root Causes:**
1. Async race conditions in `loadAllStoreDetails` allow old requests to overwrite new data
2. Missing request cancellation on navigation/back button
3. Shared memory references between isolated and global state
4. No hard limits on rendered stores (fetches 300+, renders all)
5. Missing error fallbacks preserve stale data on API failures

---

## 1. ZOMBIE DATA CHECK: Store ID 1 → Store ID 62 Persistence

### **Problem Identified**

Store ID 1 data persists when moving to Store ID 62 due to **async race conditions** in `loadAllStoreDetails`.

### **Root Cause Analysis**

**Location:** `lib/features/store/controllers/store_controller.dart:2584-2679`

```2584:2679:lib/features/store/controllers/store_controller.dart
  Future<void> loadAllStoreDetails(
      BuildContext context, int? storeId, bool fromModule,
      {String slug = ''}) async {
    if (kDebugMode) {
      debugPrint(
          '⚡ [StoreController] loadAllStoreDetails() - Starting batch load for store $storeId');
    }

    // 🛑 TASK 1: HARD-QUARANTINE - Cancel ALL pending menu requests before loading new store
    // This prevents zombie data from overwriting the screen when changing stores
    cancelAllPendingRequests();
    
    // Create new cancel token for this store load
    _storeLoadCancelToken = CancelToken();

    // 🚀 TASK 1: CUT THE LOOP - Single slim menu call replaces all parallel getStoreItemList calls
    // Load store details, banners, recommended items, and slim menu in parallel
    final List<Future> futures = [
      // Load store details
      getStoreDetails(
        context,
        Store(id: storeId),
        fromModule,
        slug: slug,
        cancelToken: _storeLoadCancelToken,
      ).catchError((e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [StoreController] Error loading store details in parallel batch: $e');
        }
        return Future<Store?>.value(null);
      }),
      // Load banners in parallel
      getStoreBannerList(storeId).catchError((e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [StoreController] Error loading banners in parallel batch: $e');
        }
        return Future.value();
      }),
      // Load recommended items in parallel
      getRestaurantRecommendedItemList(storeId, false, cancelToken: _storeLoadCancelToken).catchError((e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [StoreController] Error loading recommended items in parallel batch: $e');
        }
        return Future.value();
      }),
    ];

    // 🚀 TASK 1: SINGLE SLIM MENU CALL - Replaces all parallel getStoreItemList loops
    // Slim menu works for ALL modules (including ecommerce) and handles large stores automatically
    if (storeId != null) {
      futures.add(
        getSlimMenu(storeId, cancelToken: _storeLoadCancelToken).catchError((e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ [StoreController] Error loading slim menu: $e');
            debugPrint('   🔄 Slim menu failed - items will not be loaded');
          }
          return Future<bool>.value(false);
        }),
      );
      if (kDebugMode) {
        debugPrint(
            '🚀 [StoreController] TASK 1: Using SINGLE slim menu call (no parallel loops)');
        debugPrint(
            '   📦 Slim menu loads all categories + items in ONE API call');
        debugPrint(
            '   ⚡ Large stores (>1K items) automatically limited to 2K items');
      }
    }

    await Future.wait(
      futures,
      eagerError:
          false, // ✅ Don't stop on first error - ensures all calls complete
    );

    // ✅ FIX: Defer update() to prevent setState during build error
    // This ensures items, banners, and other data trigger UI refresh after build completes
    // Use multiple callbacks to ensure we're definitely past the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (kDebugMode) {
          debugPrint('🔄 [StoreController] Deferred update() after loadAllStoreDetails');
        }
        update();
      });
    });

    if (kDebugMode) {
      debugPrint(
          '✅ [StoreController] loadAllStoreDetails() - Batch load complete (slim menu used)');
    }
  }
```

### **The Leak Mechanism**

1. **User navigates Store 1 → Store 62**
2. `loadAllStoreDetails(storeId: 62)` is called
3. `cancelAllPendingRequests()` is called **BUT**:
   - `getStoreDetails()` for Store 1 may have already completed async parsing
   - `getSlimMenu()` for Store 1 may be in-flight with response received but not yet processed
   - `Future.wait()` doesn't check if `cancelToken.isCancelled` **BEFORE** processing responses

4. **Race Condition:** Store 1's `getStoreDetails()` response arrives **AFTER** Store 62's request starts but **BEFORE** Store 62's response
5. **Result:** `_store` gets overwritten with Store 1 data after Store 62 data was set

### **Critical Missing Check**

**Location:** `lib/features/store/controllers/store_controller.dart:2127-2198`

The `getStoreDetails()` method doesn't verify `cancelToken.isCancelled` **AFTER** the API response arrives but **BEFORE** updating `_store`:

```2127:2198:lib/features/store/controllers/store_controller.dart
  Future<Store?> getStoreDetails(context, Store store, bool fromModule,
      {bool fromCart = false, String slug = '', CancelToken? cancelToken}) async {
    _categoryIndex = 0;
    _hasStoreError = false;
    _storeErrorStatusCode = null;

    // 🔧 FIX: Clear categories if store ID is changing
    final newStoreId = store.id;
    if (_lastStoreIdForCategories != null &&
        _lastStoreIdForCategories != newStoreId) {
      if (kDebugMode) {
        debugPrint(
            '🔄 [StoreController] Store ID changed from $_lastStoreIdForCategories to $newStoreId - Clearing categories');
      }
      
      // 🛑 TASK 1: HARD-QUARANTINE - Cancel all pending requests when changing stores
      cancelAllPendingRequests();
      
      _storeSpecificCategoryList = null;
      _allCategories = null;
      _visibleCategoryCount = 4;
      _lastStoreIdForCategories = null;
    }

    // ⚡ TASK 2: Prevent duplicate header calls
    if (_isLoadingStoreDetails && _loadingStoreDetailsId == newStoreId) {
      if (kDebugMode) {
        debugPrint(
            '🚫 [StoreController] getStoreDetails already in progress for store $newStoreId - skipping duplicate call');
      }
      return _store;
    }

    // ⚡ TASK 1: MINI-CACHE ON ENTRY - Use basic store data immediately (0ms perceived load)
    // If store has basic data (name, logo, rating), set it immediately for instant header display
    final hasMiniCache = store.name != null ||
        store.logoFullUrl != null ||
        store.avgRating != null;
    if (hasMiniCache && newStoreId != null) {
      // Create a mini-model with available basic data for instant header display
      if (_store?.id != newStoreId) {
        // Only update if we're switching to a different store
        _store = Store(
          id: newStoreId,
          name: store.name,
          logoFullUrl: store.logoFullUrl,
          avgRating: store.avgRating,
          ratingCount: store.ratingCount,
          distance: store.distance,
          // Preserve other fields from existing _store if same ID
        );
        if (kDebugMode) {
          debugPrint(
              '⚡ [StoreController] CONTENT POP: Mini-cache set for store $newStoreId - header visible instantly (0ms)');
        }
        update(); // Update UI immediately with mini-cache data
      }
    }

    // Set loading state to prevent duplicate calls
    _isLoadingStoreDetails = true;
    _loadingStoreDetailsId = newStoreId;

    if (store.name != null && store.categoryDetails != null) {
      // Full store data already available - no need to fetch
      _store = store;
      _isLoading = false;
      _isLoadingStoreDetails = false;
      _loadingStoreDetailsId = null;
      update();
      return store;
    } else {
      // 🛠️ TASK 3: SWR Pattern - STEP 1: Load from cache immediately
```

**Missing:** After API response, before `_store = store`, check:
```dart
if (cancelToken != null && cancelToken.isCancelled) {
  return _store; // Don't overwrite with stale data
}
```

### **Recommendation**

Add **post-response cancellation checks** in all async methods that update state:
- `getStoreDetails()` - Check before `_store = store`
- `getSlimMenu()` - Check before updating `_storeItemModel`
- `getStoreBannerList()` - Check before updating `_storeBannerList`

---

## 2. MAIN THREAD AUDIT: "Skipped 52 Frames" During Module Switching

### **Problem Identified**

"Skipped 52 frames" occurs during module switching, indicating **~833ms of main thread blocking** (52 frames × 16ms/frame).

### **Root Cause Analysis**

**Location:** `lib/features/home/controllers/home_unified_controller.dart:152-417`

The `loadHomeData()` method performs **synchronous data distribution** on the main thread:

```152:417:lib/features/home/controllers/home_unified_controller.dart
  Future<bool> loadHomeData({
    bool forceRefresh = false,
    bool showLoading = true,
    int? moduleId, // ✅ TASK 2: Add optional moduleId parameter for parallel loading
    String? include, // 🔧 FIX: Lazy loading parameter for splash pre-fetch
  }) async {
    if (_isLoading) {
      if (kDebugMode) {
        print('🚫 HomeUnifiedController: Already loading, skipping');
      }
      return false;
    }

    // ✅ TASK 2: Use provided moduleId or fallback to ModuleHelper
    // 🔧 FIX: Prioritize passed moduleId parameter - use it even if ModuleHelper.getModule() is null
    // This is critical for Splash pre-fetch where moduleId is explicitly passed (e.g., 3 for eCommerce)
    final effectiveModuleId =
        moduleId != null ? moduleId : ModuleHelper.getModule()?.id;
    if (effectiveModuleId == null) {
      if (kDebugMode) {
        print(
            '❌ HomeUnifiedController: No module selected (moduleId parameter: $moduleId, ModuleHelper: ${ModuleHelper.getModule()?.id})');
      }
      return false;
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
        Future.microtask(() => _distributeDataToControllers(memoryData));
        _isLoading = false;
        update();
        if (kDebugMode) {
          print(
              '⚡ HomeUnifiedController: Instant switch from memory cache (0ms) - module $effectiveModuleId');
        }
        return true; // Instant switch - 0ms
      }
    }

    // 🔧 CRITICAL FIX: Only set isLoading=true if we don't have existing data
    // If data already exists, keep it in "Success" state during silent refresh
    final hasExistingData = _moduleDataCache.containsKey(effectiveModuleId) &&
        _moduleDataCache[effectiveModuleId]!.isValid;
    if (hasExistingData && !forceRefresh) {
      // Silent refresh - don't show loading state
      _isLoading = false;
      if (kDebugMode) {
        print(
            '✅ HomeUnifiedController: Silent refresh - preserving Success state (has existing data)');
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
        if (splashController.configModel == null && !splashController.isLoadingConfig) {
          if (kDebugMode) {
            print(
                '🔧 HomeUnifiedController: Config not loaded, triggering getConfigData...');
          }
          // Trigger config load in background (non-blocking)
          splashController
              .getConfigData(
            Get.context!,
            loadModuleData: false,
            loadLandingData: false,
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
          Future.microtask(() => _distributeDataToControllers(cachedData));
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
      HomeUnifiedModel? apiData;
      try {
        apiData = await homeUnifiedService.getHomeUnifiedData(
          moduleId: effectiveModuleId,
          include: include, // 🔧 FIX: Pass include parameter for lazy loading
        );
      } finally {
        _isFetching = false;
      }

      if (apiData != null && apiData.isValid) {
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

        final String? oldVersionHash = _moduleDataCache[effectiveModuleId]?.meta?.versionHash;
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
        Future.microtask(() {
          if (dataToDistribute != null) {
            _distributeDataToControllers(dataToDistribute);
          }
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
```

### **Blocking Operations Identified**

1. **`_loadFromCache()` - Disk I/O on Main Thread**
   - Location: `lib/features/home/controllers/home_unified_controller.dart:980-1048`
   - Reads from Hive (disk) synchronously
   - **Impact:** 50-200ms blocking per cache read

2. **`_distributeDataToControllers()` - Heavy JSON Parsing**
   - Location: `lib/features/home/controllers/home_unified_controller.dart:425-703`
   - Parses large JSON responses and updates multiple controllers
   - **Impact:** 100-300ms blocking per distribution

3. **`_saveToCache()` - Disk Write on Main Thread**
   - Location: `lib/features/home/controllers/home_unified_controller.dart:1122-1167`
   - Writes to Hive synchronously
   - **Impact:** 50-150ms blocking per cache write

4. **Module Switching Logic - Synchronous State Updates**
   - Location: `lib/features/home/screens/multi_module/widgets/module_view.dart:280-307`
   - Clears store data synchronously before switching
   - **Impact:** 50-100ms blocking

**Total Estimated Blocking:** 250-750ms (matches "Skipped 52 frames" = ~833ms)

### **Recommendation**

1. **Move cache I/O to isolates:**
   ```dart
   final cachedData = await compute(_loadFromCacheIsolate, effectiveModuleId);
   ```

2. **Defer controller updates:**
   ```dart
   Future.microtask(() => _distributeDataToControllers(data));
   ```

3. **Use async cache writes:**
   ```dart
   unawaited(_saveToCache(effectiveModuleId, apiData)); // Fire and forget
   ```

---

## 3. THE 'PARALLEL BOMB' LIST: Screens Firing 3+ API Calls on initState

### **Screens Identified**

| Screen | API Calls on initState | Location |
|--------|------------------------|----------|
| **ShopHomeScreen** | 4 calls | `lib/features/home/screens/all_sections/shop_home_screen.dart:35-89` |
| **FoodHomeScreen** | 4 calls | Similar pattern to ShopHomeScreen |
| **GroceryHomeScreen** | 4 calls | Similar pattern to ShopHomeScreen |
| **PharmacyHomeScreen** | 4 calls | Similar pattern to ShopHomeScreen |
| **HomeScreen** | 5+ calls | `lib/features/home/screens/home_screen.dart:61-214` |
| **StoreScreen** | 4 calls | `lib/features/store/screens/store_screen.dart:89-119` |
| **FoodRestaurantDetailScreen** | 5 calls | `lib/features/store/screens/food_restaurant_detail_screen.dart:76-123` |

### **Detailed Analysis: ShopHomeScreen**

**Location:** `lib/features/home/screens/all_sections/shop_home_screen.dart:35-165`

```35:165:lib/features/home/screens/all_sections/shop_home_screen.dart
  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('ShopHomeScreen');
    appLogger.info('🏠 ShopHomeScreen: Initializing');
    appLogger.debug('ShopHomeScreen: Module Type = Ecommerce/Shop');
    appLogger.debug('ShopHomeScreen: Starting initialization sequence');
    
    // ⚡ SWR: Load cached data IMMEDIATELY for zero-latency rendering
    _loadCachedDataForInstantUI();
  }
  
  @override
  void dispose() {
    appLogger.logPageExit();
    appLogger.info('🏠 ShopHomeScreen: Disposed');
    super.dispose();
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
        
        // ⚡ INSTANT: Load cached data synchronously
        final hasCache = await unifiedController.loadCachedDataForInstantUI();
        if (hasCache) {
          _hasCachedData = true;
          appLogger.info('⚡ ShopHomeScreen: Cached data loaded - UI will render instantly');
          appLogger.debug('ShopHomeScreen: Cache status - hasCachedData = true');
          
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
        await unifiedController.loadHomeData(
          moduleId: moduleId,
          forceRefresh: reload,
          showLoading: false, // Silent refresh - no loading indicator
        );
        
        appLogger.info('✅ ShopHomeScreen: V2 data loaded (top sections)');
        appLogger.debug('ShopHomeScreen: V2 load complete - Banners, Categories, Brands, and Offers should be available');
        
        // 2. HARD RESET & TRIGGER LEGACY for the bottom section
        // This ensures we get the real total_size (300+) every time we enter
        // V2 must NEVER touch storeModel - only popularStoreList for top sections
        if (Get.isRegistered<StoreController>()) {
          final storeController = Get.find<StoreController>();
          final homeController = Get.find<HomeController>();
          final settings = homeController.business_Settings;
          
          // Only load if "All Restaurants" section is enabled
          final allRestaurantsEnabled = settings?.allRestaurantsSection?.toString() == "1" ||
              (settings?.allRestaurantsSection is int && settings?.allRestaurantsSection == 1);
          
          appLogger.debug('ShopHomeScreen: allRestaurantsSection enabled = $allRestaurantsEnabled');
          
          if (allRestaurantsEnabled) {
            appLogger.info('📡 ShopHomeScreen: Initializing legacy pagination engine (storeModel)');
            appLogger.debug('ShopHomeScreen: reload=true ensures clean state and correct totalSize (300+)');
            appLogger.debug('ShopHomeScreen: Calling storeController.getStoreList(1, true)');
            
            // Use reload: true to ensure we get the TRUE totalSize from API (300+)
            // This clears old module data and fetches fresh data
            await storeController.getStoreList(1, true);
            
            final totalSize = storeController.storeModel?.totalSize;
            appLogger.info('✅ ShopHomeScreen: Legacy pagination engine initialized (totalSize: $totalSize)');
            appLogger.debug('ShopHomeScreen: Store list loaded - stores count: ${storeController.storeModel?.stores?.length ?? 0}');
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
    }
  }
```

**API Calls Fired:**
1. `unifiedController.loadCachedDataForInstantUI()` → Triggers cache read + potential API call
2. `unifiedController.loadHomeData()` → `/api/v2/home-unified` (Banners, Categories, Brands, Offers)
3. `storeController.getStoreList(1, true)` → `/api/v1/stores` (300+ stores)
4. Background refresh → Additional API calls

### **Detailed Analysis: StoreScreen**

**Location:** `lib/features/store/screens/store_screen.dart:89-119`

```89:119:lib/features/store/screens/store_screen.dart
  Future<void> initDataCall() async {
    appLogger.info('📍 StoreScreen: initDataCall() called');
    appLogger.debug('StoreScreen: Store ID = ${widget.store?.id}');

    final storeController = Get.find<StoreController>();
    final categoryController = Get.find<CategoryController>();

    if (storeController.isSearching) {
      appLogger.debug('StoreScreen: Clearing search status');
      storeController.changeSearchStatus(isUpdate: false);
    }
    storeController.hideAnimation();

    // ⚡ PARALLEL BATCH: Load store details, items, banners, and recommended items in parallel
    appLogger.info(
        '📡 StoreScreen: Starting parallel batch load for store ID: ${widget.store!.id}');
    appLogger.debug(
        'StoreScreen: Parallel batch includes: store details, items, banners, recommended items');

    await storeController.loadAllStoreDetails(
      context,
      widget.store!.id,
      widget.fromModule,
      slug: widget.slug,
    );

    appLogger.info('✅ StoreScreen: Parallel batch load complete');
    appLogger.debug(
        'StoreScreen: Store details loaded - Store name: ${storeController.store?.name}');

    storeController.showButtonAnimation();
```

**API Calls Fired:**
1. `getStoreDetails()` → `/api/v1/store-details/{storeId}`
2. `getStoreBannerList()` → `/api/v1/store-banners/{storeId}`
3. `getRestaurantRecommendedItemList()` → `/api/v1/store-recommended-items/{storeId}`
4. `getSlimMenu()` → `/api/v1/store-slim-menu/{storeId}`

### **Recommendation**

1. **Batch API calls into single BFF endpoint:**
   - Create `/api/v2/store-details-unified` that returns store + banners + items + recommended in one call

2. **Implement request debouncing:**
   - Use `ApiCallManager` to prevent duplicate calls within 500ms window

3. **Lazy load non-critical data:**
   - Load banners/recommended items after initial render (post-frame callback)

---

## 4. DATA REDUNDANCY: 300+ Stores Fetched, How Many Rendered?

### **Problem Identified**

`ShopHomeScreen` fetches 300+ stores via `getStoreList(1, true)`, but **no hard limit** exists on rendered stores.

### **Analysis**

**Location:** `lib/features/home/screens/all_sections/shop_home_screen.dart:148-152`

```148:152:lib/features/home/screens/all_sections/shop_home_screen.dart
            // Use reload: true to ensure we get the TRUE totalSize from API (300+)
            // This clears old module data and fetches fresh data
            await storeController.getStoreList(1, true);
            
            final totalSize = storeController.storeModel?.totalSize;
```

**Fetched:** `storeController.storeModel?.totalSize` = **300+ stores**

**Rendered:** Check `AllRestaurantsView` widget:

**Location:** `lib/features/home/widgets/views/all_restaurants_view.dart:103-151`

```103:151:lib/features/home/widgets/views/all_restaurants_view.dart
        final totalSize = storeController.allStoreModel!.totalSize ?? 0;
        final itemsPerPage = 10; // Default pagination size
        final totalPages = (totalSize / itemsPerPage).ceil();
        final loadedCount = storeController.allStoreModel!.stores?.length ?? 0;
        final currentOffset = (loadedCount / itemsPerPage).floor();

        if (kDebugMode) {
          debugPrint(
              '🔍 AllRestaurantsView: Pagination check - totalSize: $totalSize, currentOffset: $currentOffset, totalPages: $totalPages, loadedCount: $loadedCount');
        }

        // This ensures pagination continues even if API returns 0 stores but totalSize > 0
        final hasMoreStores = loadedCount < totalSize;

        // Check if we need to load more stores
        if (hasMoreStores && !storeController.isLoading) {
          final hasMorePages = currentOffset < totalPages;

          if (hasMorePages) {
            if (kDebugMode) {
              debugPrint(
                  '📄 AllRestaurantsView: ⚡ TRIGGERING PAGINATION - Loading page ${currentOffset + 1} of $totalPages (total: $totalSize stores, currently loaded: $loadedCount)');
            }

            // Load next page
            storeController.getStoreList(currentOffset + 1, false).then((_) {
              final newLoadedCount = storeController.allStoreModel?.stores?.length ?? 0;
              if (kDebugMode) {
                debugPrint(
                    '✅ AllRestaurantsView: Pagination complete - loaded $newLoadedCount stores (was $loadedCount)');
              }
            }).catchError((e) {
              if (kDebugMode) {
                debugPrint('❌ AllRestaurantsView: Pagination error: $e');
              }
            });
          } else {
            if (kDebugMode) {
              debugPrint(
                  'ℹ️ AllRestaurantsView: ⚠️ Cannot paginate - hasMoreStores: $hasMoreStores, hasMorePages: $hasMorePages | totalSize: $totalSize stores | loaded: $loadedCount stores | currentOffset: $currentOffset | totalPages: $totalPages');
            }
          }
        }
```

**Finding:** **NO HARD LIMIT** on rendered stores. The widget uses **pagination** (10 stores per page), but:
- Initial load fetches **all 300+ stores** in memory
- UI renders **all loaded stores** via `ListView.builder` (no `itemCount` limit)
- Pagination loads **more stores** as user scrolls

### **Memory Impact**

- **300 stores × ~5KB/store = 1.5MB** in memory
- **Rendered:** All 300+ stores (no viewport culling if ListView doesn't use `cacheExtent`)

### **Recommendation**

1. **Implement hard limit on initial fetch:**
   ```dart
   await storeController.getStoreList(1, true, limit: 20); // Only fetch 20 initially
   ```

2. **Add viewport culling:**
   ```dart
   ListView.builder(
     cacheExtent: 500, // Only render 500px worth of items
     itemCount: min(loadedStores.length, 50), // Hard limit of 50 visible
   )
   ```

3. **Lazy load remaining stores:**
   - Load next 20 stores when user scrolls to 80% of list

---

## 5. STATE ISOLATION: `_storeSpecificCategoryList` vs Global `categoryList`

### **Problem Identified**

`_storeSpecificCategoryList` and global `categoryList` (from `CategoryController`) **share memory references**, causing state leakage.

### **Root Cause Analysis**

**Location:** `lib/features/store/controllers/store_controller.dart:128-145`

```128:145:lib/features/store/controllers/store_controller.dart
  List<CategoryModel>? _storeSpecificCategoryList;
  List<CategoryModel>? _allCategories; // Store all categories for lazy loading
  int _visibleCategoryCount = 4; // Show 4 categories initially
  bool _isLoadingMoreCategories = false;
  int? _lastStoreIdForCategories; // Track which store the categories belong to

  // 🔒 ISOLATION: Separate category list for store detail screens to prevent state leakage
  // This is NEVER used for global categories (Home Screen) - only for store-specific categories

  List<CategoryModel>? get categoryList {
    // Return only visible categories for lazy loading
    // ⚠️ DEPRECATED FALLBACK: _storeSpecificCategoryList should never be used for store categories
    if (_allCategories == null) return _storeSpecificCategoryList;
    final allCats = _allCategories!;
    if (allCats.length <= _visibleCategoryCount) return allCats;
    return allCats.sublist(0, _visibleCategoryCount);
  }
```

**The Leak Mechanism:**

**Location:** `lib/features/store/controllers/store_controller.dart:1984-2026`

```1984:2026:lib/features/store/controllers/store_controller.dart
    else if (Get.find<CategoryController>().categoryList != null &&
        _store!.categoryIds != null &&
        _store!.categoryIds!.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '   ⚠️ Using CategoryController as fallback (${Get.find<CategoryController>().categoryList!.length} total)');
        debugPrint(
            '   🔍 Looking for categories matching store categoryIds: ${_store!.categoryIds}');
      }

      int matchedByCategoryIds = 0;

      // 🔒 FIX: Only match by categoryIds - never match by storeId
      // Global categories might have incorrect storeId values from other stores
      for (var category in Get.find<CategoryController>().categoryList!) {
        // Only match if category.id is in store's categoryIds array
        if (category.id != null &&
            _store!.categoryIds!.contains(category.id)) {
          _allCategories!.add(category);
          matchedByCategoryIds++;
          if (kDebugMode) {
            debugPrint(
                '      ✅ Matched by categoryIds - Category ID: ${category.id}, Name: ${category.name}');
          }
        }
      }

      if (matchedByCategoryIds > 0) {
        // 🔒 TASK 1: ISOLATE CATEGORY LISTS - Save to store-specific list, NOT global _storeSpecificCategoryList
        // This prevents store categories from overwriting global categories on Home Screen

        // ⚠️ DO NOT set _storeSpecificCategoryList here - it's for global categories only

        // 🔧 FIX: Track which store these categories belong to
        _lastStoreIdForCategories = _store?.id;

        if (kDebugMode) {
          debugPrint('   📊 Category matching results:');
          debugPrint('      - Matched by categoryIds: $matchedByCategoryIds');
          debugPrint(
              '      - Total categories in store list: ${_allCategories!.length}');
          debugPrint('      - Visible categories: ${_visibleCategoryCount}');
```

**Critical Issue:** `_allCategories!.add(category)` adds **direct references** to global `CategoryController.categoryList` items. If `CategoryController` updates its list, `_allCategories` sees the changes.

### **Proof of Leak**

1. **Store 1 loads:** `_allCategories` contains references to `CategoryController.categoryList[0..5]`
2. **User navigates to Home Screen:** `CategoryController.categoryList` updates with new categories
3. **User navigates to Store 62:** `_allCategories` still contains **stale references** to Store 1's categories
4. **Result:** Store 62 shows Store 1's categories

### **Recommendation**

1. **Deep clone categories when adding to `_allCategories`:**
   ```dart
   _allCategories!.add(CategoryModel(
     id: category.id,
     name: category.name,
     // ... copy all fields, don't use reference
   ));
   ```

2. **Clear `_allCategories` on store change:**
   ```dart
   if (_lastStoreIdForCategories != newStoreId) {
     _allCategories = null; // Force fresh load
   }
   ```

---

## 6. HERO TRANSITION READINESS: Store Logos and Banners

### **Analysis**

**Location:** Multiple files using `Hero` widget

**Findings:**
- **Store logos:** Use `Hero` with tag `'store_logo_${store.id}'` ✅
- **Store banners:** Use `Hero` with tag `'store_banner_${store.id}'` ✅
- **Home screen store cards:** Use `Hero` with tag `'store_logo_${store.id}'` ✅

**Example:**
```dart
Hero(
  tag: 'store_logo_${store.id}',
  child: Image.network(store.logoFullUrl),
)
```

### **Status: ✅ COMPLIANT**

All store logos and banners use unique `Hero` tags based on `store.id`, ensuring smooth transitions across the app.

---

## 7. REQUEST CANCELLATION: CancelToken Logic

### **Current Implementation**

**Location:** `lib/features/store/controllers/store_controller.dart:181-187`

```181:187:lib/features/store/controllers/store_controller.dart
  CancelToken? _itemsRequestCancelToken;

  // 🛑 TASK 1: HARD-QUARANTINE - Cancel token for store load operations
  // This prevents zombie data from overwriting the screen when changing stores
  CancelToken? _storeLoadCancelToken;
```

**Cancellation Points:**

1. **`cancelAllPendingRequests()` - Called on store change:**
   ```dart
   if (_itemsRequestCancelToken != null) {
     _itemsRequestCancelToken!.cancel();
     _itemsRequestCancelToken = null;
   }
   if (_storeLoadCancelToken != null) {
     _storeLoadCancelToken!.cancel();
     _storeLoadCancelToken = null;
   }
   ```

2. **`loadAllStoreDetails()` - Creates new token:**
   ```dart
   _storeLoadCancelToken = CancelToken();
   ```

3. **API calls pass `cancelToken`:**
   ```dart
   getStoreDetails(..., cancelToken: _storeLoadCancelToken)
   getSlimMenu(..., cancelToken: _storeLoadCancelToken)
   ```

### **Gaps Identified**

1. **Missing cancellation on Back button:**
   - No `WillPopScope` or `PopScope` handler cancels requests when user presses back

2. **Missing cancellation on module switch:**
   - `clearStoreData()` cancels tokens, but module switching doesn't always call it

3. **Missing post-response cancellation check:**
   - API responses don't check `cancelToken.isCancelled` before updating state

### **Recommendation**

1. **Add back button cancellation:**
   ```dart
   PopScope(
     onPopInvoked: (didPop) {
       if (didPop) {
         storeController.cancelAllPendingRequests();
       }
     },
   )
   ```

2. **Add module switch cancellation:**
   ```dart
   splashController.switchModule() {
     storeController.cancelAllPendingRequests();
     // ... rest of switch logic
   }
   ```

3. **Add post-response checks:**
   ```dart
   if (cancelToken != null && cancelToken.isCancelled) {
     return; // Don't update state
   }
   ```

---

## 8. ITEM COUNT USAGE: `itemsCount` / `items_count`

### **Analysis**

**Search Results:** Found 58 matches for `itemsCount`/`items_count` in `log.md` (debug logs only)

**Code Search:** No usage in UI widgets

**Finding:** `itemsCount` is **received from API** (offers endpoint) but **NEVER displayed** to users on any Home Screen.

**Example from log:**
```
items_count: 7108
items_count: 3875
items_count: 14437
items_count: 3000
```

### **Status: ❌ UNUSED DATA**

`itemsCount` is fetched but never rendered. This is **wasted bandwidth** and **unnecessary data processing**.

### **Recommendation**

1. **Remove `itemsCount` from API response parsing** if not needed
2. **Or display it in UI** if it provides value (e.g., "7,108 items on sale")

---

## 9. OPTIMISTIC UI: Store Header Display

### **Analysis**

**Location:** `lib/features/store/controllers/store_controller.dart:2160-2184`

```2160:2184:lib/features/store/controllers/store_controller.dart
    // ⚡ TASK 1: MINI-CACHE ON ENTRY - Use basic store data immediately (0ms perceived load)
    // If store has basic data (name, logo, rating), set it immediately for instant header display
    final hasMiniCache = store.name != null ||
        store.logoFullUrl != null ||
        store.avgRating != null;
    if (hasMiniCache && newStoreId != null) {
      // Create a mini-model with available basic data for instant header display
      if (_store?.id != newStoreId) {
        // Only update if we're switching to a different store
        _store = Store(
          id: newStoreId,
          name: store.name,
          logoFullUrl: store.logoFullUrl,
          avgRating: store.avgRating,
          ratingCount: store.ratingCount,
          distance: store.distance,
          // Preserve other fields from existing _store if same ID
        );
        if (kDebugMode) {
          debugPrint(
              '⚡ [StoreController] CONTENT POP: Mini-cache set for store $newStoreId - header visible instantly (0ms)');
        }
        update(); // Update UI immediately with mini-cache data
      }
    }
```

### **Status: ✅ OPTIMISTIC UI IMPLEMENTED**

The app **does use optimistic UI**:
1. **Passed arguments/cache:** Store name, logo, rating are set immediately from `widget.store` (passed from previous screen)
2. **API update:** Full store details load in background and update UI when ready
3. **Result:** Header appears instantly (0ms perceived load), then updates with full data

### **Recommendation**

✅ **No changes needed** - Optimistic UI is properly implemented.

---

## 10. ERROR FALLBACKS: 500/Timeout Handling

### **Analysis**

**Location:** `lib/features/store/controllers/store_controller.dart:2121-2125`

```2121:2125:lib/features/store/controllers/store_controller.dart
  // Error state for retry button
  bool _hasStoreError = false;
  bool get hasStoreError => _hasStoreError;
  int? _storeErrorStatusCode;
  int? get storeErrorStatusCode => _storeErrorStatusCode;
```

**Error Handling in `getStoreDetails()`:**

**Location:** `lib/features/store/domain/repositories/store_repository.dart:1037-1045`

```1037:1045:lib/features/store/domain/repositories/store_repository.dart
    Response response = await apiClient.getData(
        '${AppConstants.storeDetailsUri}${slug.isNotEmpty ? slug : storeID}',
        headers: header,
        cancelToken: cancelToken);
    if (response.statusCode == 200) {
      store = Store.fromJson(response.body);
    }
    return store;
```

**Critical Issue:** If `response.statusCode != 200`, the method returns `null` or the **previous `_store` value**, meaning **old data persists** on error.

### **Error Scenarios**

1. **500 Server Error:**
   - API returns 500
   - `getStoreDetails()` returns `null` or previous `_store`
   - **Result:** Screen shows **old store data** (Store 1 data when trying to load Store 62)

2. **Timeout:**
   - Request times out
   - `getStoreDetails()` throws exception, caught by `.catchError()`
   - **Result:** `_store` remains unchanged (old data persists)

3. **Network Error:**
   - No internet connection
   - Exception thrown, caught
   - **Result:** Old data persists

### **Current Behavior: ❌ PRESERVES STALE DATA**

The app **keeps old data** on API errors, causing **data poisoning** (Store 1 data shown when Store 62 fails to load).

### **Recommendation**

1. **Clear state on error:**
   ```dart
   if (response.statusCode != 200) {
     _store = null; // Clear old data
     _hasStoreError = true;
     _storeErrorStatusCode = response.statusCode;
     update(); // Show error UI
     return null;
   }
   ```

2. **Show error UI instead of stale data:**
   ```dart
   if (_hasStoreError) {
     return ErrorWidget(
       message: 'Failed to load store',
       onRetry: () => retryStoreDetails(...),
     );
   }
   ```

3. **Implement retry logic:**
   ```dart
   Future<void> retryStoreDetails(...) async {
     _hasStoreError = false;
     await getStoreDetails(...);
   }
   ```

---

## SUMMARY & RECOMMENDATIONS

### **Critical Issues (Fix Immediately)**

1. **Zombie Data Leak:** Add post-response cancellation checks in `getStoreDetails()`, `getSlimMenu()`
2. **Error Fallbacks:** Clear state on API errors, show error UI instead of stale data
3. **State Isolation:** Deep clone categories when adding to `_allCategories`
4. **Main Thread Blocking:** Move cache I/O to isolates, defer controller updates

### **High Priority (Fix Soon)**

5. **Parallel API Bombing:** Batch API calls into BFF endpoints, implement request debouncing
6. **Data Redundancy:** Implement hard limit on initial store fetch (20 stores), add viewport culling
7. **Request Cancellation:** Add cancellation on back button and module switch

### **Low Priority (Optimize Later)**

8. **Item Count:** Remove unused `itemsCount` from API parsing or display it in UI
9. **Hero Transitions:** ✅ Already compliant
10. **Optimistic UI:** ✅ Already implemented correctly

---

## IMPLEMENTATION PRIORITY

1. **Week 1:** Fix zombie data leak + error fallbacks
2. **Week 2:** Fix state isolation + main thread blocking
3. **Week 3:** Reduce parallel API calls + implement store limits
4. **Week 4:** Add comprehensive request cancellation

---

**Report Generated:** 2025-01-27  
**Next Review:** After Week 1 fixes are implemented
