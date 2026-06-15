part of 'home_screen.dart';

/// 🧹 REFACTOR: Home data-loading instance methods, extracted from
/// _HomeScreenState into a same-library extension to slim home_screen.dart.
/// Behaviour is unchanged — pure mechanical extraction.
extension _HomeScreenDataLoading on _HomeScreenState {
  void _scheduleDeferredLoadCheck() {
    if (_deferredLoadQueued || !mounted) {
      return;
    }
    _deferredLoadQueued = true;
    _deferredLoadTimer?.cancel();
    _deferredLoadTimer = Timer(const Duration(milliseconds: 700), () async {
      _deferredLoadQueued = false;
      if (!mounted) {
        return;
      }

      final loadingManager = LoadingStateManager();
      if (loadingManager.isComprehensiveLoading ||
          loadingManager.isHomeLoading) {
        _scheduleDeferredLoadCheck();
        return;
      }

      final hasData = await _checkControllersHaveData();
      if (!hasData) {
        await _checkAndLoadData();
      }
    });
  }

  /// ⚡ PERFORMANCE: Load stores after first frame
  /// This ensures first frame renders quickly with banners, categories, offers
  /// Stores are loaded separately after UI is visible
  void _loadStoresAfterFirstFrame() {
    if (AppConstants.useBffV2Endpoint) {
      if (kDebugMode) {
        debugPrint(
            '🛡️ HomeScreen: Unified-only policy - skipping post-frame legacy store fetch');
      }
      return;
    }

    if (!Get.isRegistered<StoreController>()) {
      return;
    }

    final storeController = Get.find<StoreController>();

    // ⚡ PERFORMANCE: Only load if stores are not already loaded
    if (storeController.allStoreModel == null && !storeController.isLoading) {
      if (kDebugMode) {
        debugPrint(
            '📡 HomeScreen: Loading stores after first frame (post-frame callback)');
      }

      // ⚡ PERFORMANCE: Load with small limit (7) for first frame
      // Pagination will load more as user scrolls
      storeController.getStoreList(1, false, limit: 7);
    }
  }

  /// Check if data is loaded and load if needed
  Future<void> _checkAndLoadData() async {
    try {
      final splashController = Get.find<SplashController>();

      // ⚡ Cache-First Fix: If module is null, don't try to load data
      // Module must be selected first (will show skeleton until module is selected)
      if (splashController.module == null) {
        if (kDebugMode) {
          debugPrint(
              '[Cache-First] HomeScreen: Skipping data load - module is null (will show skeleton)');
        }
        return;
      }

      // ⚠️ CRITICAL: Skip all data loading if we're showing multi-module screen
      // Multi-module screen doesn't need banners, categories, brands, etc.
      // It only loads modules list, offers (for module 3), and wallet (if logged in)
      final moduleList = splashController.moduleList;
      final moduleListLength = moduleList?.length ?? 0;
      final bool showMultiModuleScreen = splashController.module == null &&
          moduleList != null &&
          moduleListLength > 1;

      if (showMultiModuleScreen) {
        if (kDebugMode) {
          debugPrint(
              '🚫 HomeScreen: Skipping data load - showing multi-module screen');
        }
        _handlePostLoadActions();
        return; // Don't load any data - MultiModuleHomeScreen will handle its own loading
      }

      // ⚠️ CRITICAL: If modules are not loaded yet, don't try to load home data
      // The build method will trigger module loading, and then we'll rebuild
      if (moduleList == null || moduleListLength == 0) {
        if (kDebugMode) {
          debugPrint(
              '🚫 HomeScreen: Skipping data load - modules not loaded yet');
        }
        return;
      }

      // ⚡ Cache-First Fix: Track first load
      final isFirstLoad = !_HomeScreenState._hasLoadedOnce;

      if (isFirstLoad && splashController.module != null) {
        if (kDebugMode) {
          debugPrint(
              '[Cache-First] HomeScreen: First load detected - marking as loaded');
        }
        _HomeScreenState._hasLoadedOnce = true;
        // 🛡️ LOOP PREVENTION: Do NOT manually trigger loadHomeData here
        // The Worker in HomeController will handle data loading when module changes
        // Manual triggers cause Cold Start Loop for new users
      }

      // ⚠️ CRITICAL FIX: Avoid duplicate comprehensive loads
      final loadingManager = LoadingStateManager();
      if (loadingManager.isComprehensiveLoading ||
          loadingManager.isHomeLoading) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ HomeScreen: Loading already in progress - skipping duplicate load');
        }
        _scheduleDeferredLoadCheck();
        return;
      }

      // ⚡ BFF API v2: Check HomeUnifiedController first (single source of truth)
      if (AppConstants.useBffV2Endpoint &&
          Get.isRegistered<HomeUnifiedController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        final int? currentModuleId = splashController.module?.id;
        final bool shouldForceRecoveryRefresh =
            splashController.hasConnection &&
                unifiedController.lastRequestStatusCode == 1 &&
                !unifiedController.isLoading &&
                currentModuleId != null &&
                _lastConnectivityRecoveryModuleId != currentModuleId;
        final int? recoveryModuleId =
            shouldForceRecoveryRefresh ? currentModuleId : null;

        // ⚡ PERFORMANCE: First frame - load from cache only (banners, categories, offers) without stores
        final cacheLoaded = await unifiedController.loadCachedDataForInstantUI(
            loadStores: false);
        if (cacheLoaded) {
          if (kDebugMode) {
            debugPrint(
                '⚡ HomeScreen: First frame loaded from cache (banners, categories, offers)');
          }

          // ⚡ PERFORMANCE: Trigger background refresh AFTER first frame
          // This ensures UI appears instantly while data refreshes in background
          Future.microtask(() {
            if (!mounted) {
              return;
            }
            if (recoveryModuleId != null) {
              _lastConnectivityRecoveryModuleId = recoveryModuleId;
              unifiedController.allowImmediateFetchForModule(recoveryModuleId);
              unifiedController.loadHomeData(
                forceRefresh: true,
                showLoading: false,
              );
            } else {
              HomeLoadService.refreshInBackground(context);
            }
          });

          // ⚡ PERFORMANCE: Load stores AFTER first frame (post-frame callback)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _loadStoresAfterFirstFrame();
              }
            });
          });

          _handlePostLoadActions();
          return;
        }

        // If no cached data, trigger unified load (but still skip stores for first frame)
        if (!unifiedController.isLoading) {
          // ⚡ Cache-First Fix: Force fetch on first load
          final isFirstLoad = !_HomeScreenState._hasLoadedOnce;
          await unifiedController.loadHomeData(
            showLoading: false,
            forceRefresh: isFirstLoad, // Force fetch on first load
          );

          // Load stores after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _loadStoresAfterFirstFrame();
              }
            });
          });
        }
        _handlePostLoadActions();
        return;
      }

      // Fallback: Legacy individual controller checks (if unified endpoint disabled)
      // First check if data is already available in controllers
      final bool hasData = await _checkControllersHaveData();

      if (hasData) {
        _handlePostLoadActions();
        return;
      }

      // Check if we should force data restoration due to user state change
      final bool forceRestoration =
          await ComprehensiveHomeCacheManager.shouldForceDataRestoration();

      // Check if cache is valid and restore data from cache first
      final bool cacheValid =
          await ComprehensiveHomeCacheManager.isCacheValid();

      if (cacheValid || forceRestoration) {
        await _restoreDataFromCache();

        // Verify data was restored (non-blocking check)
        final bool dataRestored = await _checkControllersHaveData();
        if (dataRestored) {
          _handlePostLoadActions();
          return; // IMPORTANT: Don't call HomeScreen.loadData() after successful cache restoration
        }
      }

      // Try to load data normally only if cache restoration failed
      if (!mounted) {
        return;
      }
      await HomeScreen.loadData(context, false);

      // Check if data is actually loaded
      await _verifyDataLoaded();

      // If still no data, force load individual controllers
      final bool stillNoData = !(await _checkControllersHaveData());
      if (stillNoData) {
        await _forceLoadIndividualControllers();
      }

      _handlePostLoadActions();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeScreen: Error loading data - $e');
      }
      // Fallback to direct API loading
      await _fallbackDataLoading();
      _handlePostLoadActions();
    }
  }

  /// Check if controllers already have data
  Future<bool> _checkControllersHaveData() async {
    try {
      // Check if controllers have data
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        if (bannerController.bannerImageList == null ||
            bannerController.bannerImageList!.isEmpty) {
          return false;
        }
      }

      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (categoryController.categoryList == null ||
            categoryController.categoryList!.isEmpty) {
          return false;
        }
      }

      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        if (brandsController.brandList == null ||
            brandsController.brandList!.isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeScreen: Error checking controller data - $e');
      }
      return false;
    }
  }

  /// Verify that data is actually loaded in controllers
  Future<void> _verifyDataLoaded() async {
    try {
      bool needsFallback = false;

      // Check if controllers have data
      if (Get.isRegistered<BannerController>()) {
        final bannerController = Get.find<BannerController>();
        if (bannerController.bannerImageList == null ||
            bannerController.bannerImageList!.isEmpty) {
          needsFallback = true;
        }
      }

      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (categoryController.categoryList == null ||
            categoryController.categoryList!.isEmpty) {
          needsFallback = true;
        }
      }

      if (Get.isRegistered<BrandsController>()) {
        final brandsController = Get.find<BrandsController>();
        if (brandsController.brandList == null ||
            brandsController.brandList!.isEmpty) {
          needsFallback = true;
        }
      }

      if (needsFallback) {
        await _fallbackDataLoading();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeScreen: Error verifying data - $e');
      }
      await _fallbackDataLoading();
    }
  }

  /// Fallback data loading if cache restoration fails
  /// ⚡ BFF API v2: Use unified endpoint instead of individual API calls
  Future<void> _fallbackDataLoading() async {
    try {
      appLogger.logPageEntry('HomeScreen');
      appLogger.info('🔄 HomeScreen: Starting fallback data loading');

      // ⚡ BFF API v2: Use unified endpoint if enabled
      if (AppConstants.useBffV2Endpoint &&
          Get.isRegistered<HomeUnifiedController>()) {
        appLogger.info(
            '📡 HomeScreen: Using unified endpoint: ${AppConstants.homeUnifiedUri}');
        final stopwatch = Stopwatch()..start();
        try {
          final unifiedController = Get.find<HomeUnifiedController>();
          await unifiedController.loadHomeData(
            forceRefresh: true, // Force refresh since cache restoration failed
            showLoading: false, // Silent refresh
          );
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Unified endpoint completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          stopwatch.stop();
          appLogger.error('❌ HomeScreen: Unified endpoint failed', e);
        }
        return;
      }

      // Fallback to individual API calls if unified endpoint is disabled
      // ⚠️ CRITICAL: Ensure headers are valid with moduleId before making API calls
      final apiClient = Get.find<ApiClient>();
      apiClient.ensureHeadersAreValid();

      // Direct API calls to controllers to ensure data is loaded
      // Use individual try-catch to prevent one failure from stopping others
      if (Get.isRegistered<BannerController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling banner API: ${AppConstants.bannerUri}');
          await Get.find<BannerController>().getBannerList(true);
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Banner API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading banners in fallback', e);
        }
      }
      if (Get.isRegistered<CategoryController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling category API: ${AppConstants.categoryUri}');
          await Get.find<CategoryController>().getCategoryList(true,
              expectedModuleId:
                  Get.find<SplashController>().selectedModule.value?.id);
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Category API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error(
              '❌ HomeScreen: Error loading categories in fallback', e);
        }
      }
      if (Get.isRegistered<BrandsController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info('📡 HomeScreen: Calling brands API');
          await Get.find<BrandsController>().getBrandList();
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Brands API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading brands in fallback', e);
        }
      }
      if (Get.isRegistered<StoreController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling store API: ${AppConstants.storeUri}?offset=1&limit=12');
          await Get.find<StoreController>().getStoreList(1, true);
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Store API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading stores in fallback', e);
        }
      }
      if (!AppConstants.useBffV2Endpoint &&
          Get.isRegistered<OffersController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling offers API: ${AppConstants.offersUri}');
          // getOffers() will use current module ID from SplashController
          await Get.find<OffersController>().getOffers();
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: Offers API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error('❌ HomeScreen: Error loading offers in fallback', e);
        }
      }
      // Only call auth APIs if user is logged in (NOT guest users)
      if (AuthHelper.isLoggedIn() && Get.isRegistered<ProfileController>()) {
        try {
          final stopwatch = Stopwatch()..start();
          appLogger.info(
              '📡 HomeScreen: Calling user info API: ${AppConstants.customerInfoUri}');
          await Get.find<ProfileController>().getUserInfo();
          stopwatch.stop();
          appLogger.info(
              '✅ HomeScreen: User info API completed in ${stopwatch.elapsedMilliseconds}ms');
        } catch (e) {
          appLogger.error(
              '❌ HomeScreen: Error loading user info in fallback', e);
        }
      }
    } catch (e) {
      appLogger.error('❌ HomeScreen: Fallback data loading failed', e);
    }
  }

  /// Force load individual controllers when data is missing
  Future<void> _forceLoadIndividualControllers() async {
    try {
      if (AppConstants.useBffV2Endpoint) {
        appLogger.info(
            '🛡️ HomeScreen: Unified-only policy - skipping force load of individual controllers');
        return;
      }

      appLogger.info('🔄 HomeScreen: Force loading individual controllers');

      // ⚠️ CRITICAL: Ensure headers are valid with moduleId before making API calls
      final apiClient = Get.find<ApiClient>();
      apiClient.ensureHeadersAreValid();

      // Force load each controller individually with API calls
      final futures = <Future<void>>[];

      if (Get.isRegistered<BannerController>()) {
        futures.add(Get.find<BannerController>()
            .getBannerList(true, dataSource: DataSourceEnum.client)
            .then((_) {
          appLogger.info('✅ HomeScreen: Banner controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading banners', e);
        }));
      }
      if (Get.isRegistered<CategoryController>()) {
        futures.add(Get.find<CategoryController>()
            .getCategoryList(true, dataSource: DataSourceEnum.client)
            .then((_) {
          appLogger
              .info('✅ HomeScreen: Category controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading categories', e);
        }));
      }
      if (Get.isRegistered<BrandsController>()) {
        futures.add(Get.find<BrandsController>()
            .getBrandList(dataSource: DataSourceEnum.client)
            .then((_) {
          appLogger.info('✅ HomeScreen: Brands controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading brands', e);
        }));
      }
      if (Get.isRegistered<StoreController>()) {
        futures.add(Get.find<StoreController>().getStoreList(1, true).then((_) {
          appLogger.info('✅ HomeScreen: Store controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading stores', e);
        }));
      }
      if (Get.isRegistered<OffersController>()) {
        futures.add(Get.find<OffersController>().getOffers().then((_) {
          appLogger.info('✅ HomeScreen: Offers controller loaded successfully');
        }).catchError((e) {
          appLogger.error('❌ HomeScreen: Error loading offers', e);
        }));
      }

      // Wait for all controllers to load
      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();
      appLogger.info(
          '✅ HomeScreen: All controllers loaded in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      appLogger.error(
          '❌ HomeScreen: Error force loading individual controllers',
          e,
          stackTrace);
    }
  }

  /// Restore data from cache to controllers
  Future<void> _restoreDataFromCache() async {
    try {
      // Load cached data
      final cachedData = await ComprehensiveHomeCacheManager.loadAllHomeData();

      if (cachedData.isNotEmpty) {
        // Restore data to controllers
        await ComprehensiveHomeCacheManager.restoreDataToControllers(
            cachedData);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeScreen: Error restoring data from cache - $e');
      }
    }
  }

  /// Handle post-load actions
  void _handlePostLoadActions() {
    if (Get.isRegistered<SplashController>()) {
      Get.find<SplashController>().getReferBottomSheetStatus();

      if ((Get.find<ProfileController>().userInfoModel?.isValidForDiscount ??
              false) &&
          Get.find<SplashController>().showReferBottomSheet) {
        showReferBottomSheet();
      }
    }
  }

  void showReferBottomSheet() {
    ResponsiveHelper.isDesktop(context)
        ? Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusExtraLarge)),
              insetPadding: const EdgeInsets.all(22),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: const ReferBottomSheetWidget(),
            ),
            useSafeArea: false,
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false))
        : showModalBottomSheet(
            isScrollControlled: true,
            useRootNavigator: true,
            context: Get.context!,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusExtraLarge),
                  topRight: Radius.circular(Dimensions.radiusExtraLarge)),
            ),
            builder: (context) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: const ReferBottomSheetWidget(),
              );
            },
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false));
  }

  void _logUiStateSnapshot(String source, SplashController splashController) {
    if (!kDebugMode) {
      return;
    }

    int bannerCount = -1;
    int categoryCount = -1;
    int offersCount = -1;
    if (Get.isRegistered<BannerController>()) {
      final bannerController = Get.find<BannerController>();
      bannerCount = bannerController.featuredBannerList?.length ??
          bannerController.bannerImageList?.length ??
          0;
    }
    if (Get.isRegistered<CategoryController>()) {
      categoryCount = Get.find<CategoryController>().categoryList?.length ?? 0;
    }
    if (Get.isRegistered<OffersController>()) {
      offersCount = Get.find<OffersController>().offersMode?.data.length ?? 0;
    }

    final signature = [
      'm=${splashController.module?.id}',
      'b=$bannerCount',
      'c=$categoryCount',
      'o=$offersCount',
    ].join('|');

    final now = DateTime.now();
    final shouldLog = _lastUiDiagSignature != signature ||
        _lastUiDiagAt == null ||
        now.difference(_lastUiDiagAt!) > const Duration(seconds: 3);
    if (!shouldLog) {
      return;
    }

    _lastUiDiagAt = now;
    _lastUiDiagSignature = signature;
    debugPrint(
        '[Diag][$source] UI => module=${splashController.module?.id}, banners=$bannerCount, categories=$categoryCount, offers=$offersCount');
  }
}
