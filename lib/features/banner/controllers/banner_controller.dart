import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/others_banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/promotional_banner_model.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/features/banner/domain/services/banner_service_interface.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:collection/collection.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';

class BannerController extends GetxController implements GetxService {
  final BannerServiceInterface bannerServiceInterface;
  BannerController({required this.bannerServiceInterface});

  Worker? _moduleWorker;

  @override
  void onClose() {
    _moduleWorker?.dispose();
    invalidateAll();
    super.onClose();
  }

  // Public getter for promotional content loading (used by SplashController)
  BannerServiceInterface get bannerService => bannerServiceInterface;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🚫 UI THREAD PROTECTION: Track last loaded module ID to prevent duplicate API calls
  int? _lastLoadedModuleId;
  int? get lastLoadedModuleId => _lastLoadedModuleId;
  int? _currentBannerModuleId;
  int? get currentBannerModuleId => _currentBannerModuleId;
  final Map<int, BannerModel> _featuredBannerCacheByModule = {};
  final Map<int, Future<BannerModel?>> _featuredBannerRequests = {};

  // Deep equality checker for banners
  static const DeepCollectionEquality _deepEquality = DeepCollectionEquality();
  // TEMP: Disable deep equality checks to force UI updates.
  static const bool _disableDeepEquality = true;
  bool _hasDistributedOnce = false;
  Future<void>? _inFlightStartupPreload;
  DateTime? _lastGlobalStartupPreloadAt;

  bool _shouldUseUnifiedOnly(ModuleModel? module) {
    return AppConstants.useBffV2Endpoint && module?.moduleType == 'food';
  }

  // 🚫 REMOVED: Static variable hack - causes race conditions and state ghosts
  // BannerController is the single source of truth for banner state
  // No need for static variables that bypass state management

  List<String?>? _bannerImageList;
  List<String?>? get bannerImageList => _bannerImageList;

  List<String?>? _taxiBannerImageList;
  List<String?>? get taxiBannerImageList => _taxiBannerImageList;

  List<String?>? _featuredBannerList;
  List<String?>? get featuredBannerList => _featuredBannerList;

  List<dynamic>? _bannerDataList;
  List<dynamic>? get bannerDataList => _bannerDataList;

  List<dynamic>? _taxiBannerDataList;
  List<dynamic>? get taxiBannerDataList => _taxiBannerDataList;

  List<dynamic>? _featuredBannerDataList;
  List<dynamic>? get featuredBannerDataList => _featuredBannerDataList;

  int get homeBannerCount {
    final int featuredCount = _featuredBannerList?.length ?? 0;
    final int regularCount = _bannerImageList?.length ?? 0;
    return featuredCount > 0 ? featuredCount : regularCount;
  }

  bool get hasAnyHomeBanners => homeBannerCount > 0;

  void _bindBannerModuleId({
    required int? moduleId,
    required String source,
  }) {
    if (moduleId == null) {
      return;
    }
    _currentBannerModuleId = moduleId;
    if (kDebugMode) {
      debugPrint(
          '[HOME_BANNER_ACCEPTED] moduleId=$_currentBannerModuleId count=$homeBannerCount source=$source');
    }
  }

  bool ensureHomeBannersForCurrentModule({
    required int? currentModuleId,
    required String source,
  }) {
    if (currentModuleId == null || !hasAnyHomeBanners) {
      return false;
    }
    if (_currentBannerModuleId == null) {
      _currentBannerModuleId = currentModuleId;
      if (kDebugMode) {
        debugPrint(
            '[HOME_BANNER_NULL_MODULE_ADOPTED] currentModuleId=$currentModuleId count=$homeBannerCount source=$source');
      }
      return true;
    }
    if (_currentBannerModuleId != currentModuleId) {
      if (kDebugMode) {
        debugPrint(
            '[HOME_BANNER_IGNORED_STALE] currentModuleId=$currentModuleId bannerModuleId=$_currentBannerModuleId');
      }
    }
    return false;
  }

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  ParcelOtherBannerModel? _parcelOtherBannerModel;
  ParcelOtherBannerModel? get parcelOtherBannerModel => _parcelOtherBannerModel;

  PromotionalBanner? _promotionalBanner;
  PromotionalBanner? get promotionalBanner => _promotionalBanner;

  @override
  void onInit() {
    super.onInit();

    // 🚫 REMOVED: Static variable restoration - causes race conditions
    // Banner data should come from cache or API, not static variables

    // 🏗️ MODULE-FIRST ARCHITECTURE: Only load banners when module is selected
    // Controllers must wait for module context before making API calls
    if (Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();

      // Check if module is already selected
      if (splashController.selectedModule.value != null) {
        // Module already selected - load banners immediately
        if (kDebugMode) {
          appLogger.debug(
              '🏗️ [Module-First] BannerController: Module already selected (id=${splashController.selectedModule.value?.id}) - loading banners');
        }
        if (_shouldUseUnifiedOnly(splashController.selectedModule.value)) {
          if (kDebugMode) {
            appLogger.debug(
                '🛡️ BannerController: Skipping legacy featured banner fetch for food module (V2 unified is source of truth)');
          }
        } else {
          getFeaturedBanner();
        }
      } else {
        // Module not selected yet - listen for module selection
        if (kDebugMode) {
          appLogger.debug(
              '🏗️ [Module-First] BannerController: No module selected yet - waiting for module selection');
        }
      }

      // 🏗️ MODULE-FIRST: React to module selection changes
      // 🔒 BOOTSTRAP PROTECTION: Guard against null module and duplicate loading
      _moduleWorker =
          ever(splashController.selectedModule, (ModuleModel? module) {
        if (module != null) {
          // 🚫 UI THREAD PROTECTION: Skip if banners already loaded for this module
          if (_lastLoadedModuleId != null &&
              _lastLoadedModuleId == module.id &&
              _featuredBannerList != null &&
              _featuredBannerList!.isNotEmpty) {
            if (kDebugMode) {
              appLogger.debug(
                  '⚡ BannerControllers: Banners already loaded for module ${module.id} - skipping');
            }
            return;
          }

          if (kDebugMode) {
            appLogger.debug(
                '🏗️ [Module-First] BannerController: Module selected (id=${module.id}) - loading banners');
          }
          if (_shouldUseUnifiedOnly(module)) {
            if (kDebugMode) {
              appLogger.debug(
                  '🛡️ BannerController: Ignoring legacy featured banner fetch on module change (food + V2)');
            }
            return;
          }
          getFeaturedBanner();
        } else {
          // Global banners: keep last loaded banners even if module becomes null
          if (kDebugMode) {
            appLogger.debug(
                '🏗️ [Module-First] BannerController: Module cleared - preserving banner data');
          }
          _lastLoadedModuleId = null;
        }
      });
    }
  }

  Future<BannerModel?> getFeaturedBanner() async {
    try {
      final bool hadExistingBanners =
          _featuredBannerList != null && _featuredBannerList!.isNotEmpty;
      final List<String?> previousFeaturedImages =
          List<String?>.from(_featuredBannerList ?? <String?>[]);
      final List<dynamic> previousFeaturedData =
          List<dynamic>.from(_featuredBannerDataList ?? <dynamic>[]);

      // Get current module ID
      int? currentModuleId;
      ModuleModel? currentModule;
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        currentModule = splashController.selectedModule.value;
        currentModuleId = currentModule?.id;
        if (currentModule != null) {
          final apiClient = Get.find<ApiClient>();
          final headerModuleId = apiClient.getHeader()[AppConstants.moduleId];
          if (headerModuleId != currentModuleId?.toString()) {
            await splashController.setModuleHeaderOnly(currentModule);
          }
        }
      }

      // Global banners: if module is null, do not clear or force reload
      if (currentModule == null) {
        if (kDebugMode) {
          appLogger.debug(
              '🚫 BannerController.getFeaturedBanner: No module selected - preserving existing banners');
        }
        return null;
      }

      if (_shouldUseUnifiedOnly(currentModule)) {
        if (kDebugMode) {
          appLogger.debug(
              '🛡️ BannerController.getFeaturedBanner: Skipped legacy endpoint for food module; waiting for unified banners');
        }
        return null;
      }

      if (currentModuleId != null &&
          _featuredBannerCacheByModule.containsKey(currentModuleId)) {
        final cached = _featuredBannerCacheByModule[currentModuleId]!;
        _lastLoadedModuleId = currentModuleId;
        setFromUnified(
          bannerModel: cached,
          moduleId: currentModuleId,
          source: 'in_memory_cache',
          silent: true,
        );
        if (kDebugMode) {
          appLogger.debug(
              'BannerController.getFeaturedBanner: Using in-memory cache for module $currentModuleId');
        }
        return cached;
      }

      if (currentModuleId != null &&
          _featuredBannerRequests.containsKey(currentModuleId)) {
        if (kDebugMode) {
          appLogger.debug(
              'BannerController.getFeaturedBanner: Waiting for in-flight request of module $currentModuleId');
        }
        return _featuredBannerRequests[currentModuleId]!;
      }

      // 🚫 UI THREAD PROTECTION: Skip if banners already loaded for this module
      if (_lastLoadedModuleId != null &&
          _lastLoadedModuleId == currentModuleId &&
          _featuredBannerList != null &&
          _featuredBannerList!.isNotEmpty) {
        if (kDebugMode) {
          appLogger.debug(
              '⚡ BannerController.getFeaturedBanner: Banners already loaded for module $currentModuleId - skipping API call');
        }
        return null;
      }

      final businessSettings = Get.find<HomeController>().business_Settings;
      // ✅ Treat null as enabled (default behavior) - if backend doesn't specify, assume banners are enabled
      // Only disable if explicitly set to something other than "1"
      final bannersSectionValue = businessSettings?.bannersSection?.toString();
      final bannersSectionEnabled =
          bannersSectionValue == null || bannersSectionValue == '1';

      if (kDebugMode) {
        appLogger.debug(
            '🔍 BannerController.getFeaturedBanner: bannersSection=$bannersSectionValue, enabled=$bannersSectionEnabled');
      }

      if (!bannersSectionEnabled) {
        if (kDebugMode) {
          appLogger.warning(
              '⚠️ BannerController.getFeaturedBanner: Banners section is disabled (bannersSection="$bannersSectionValue")');
        }
        // Initialize empty lists to prevent null issues in UI
        _featuredBannerList = [];
        _featuredBannerDataList = [];
        update();
        return BannerModel(campaigns: [], banners: []);
      }

      // Set loading state and current module ID
      _isLoading = true;
      _lastLoadedModuleId = currentModuleId;

      if (kDebugMode) {
        appLogger.debug(
            '🚀 BannerController.getFeaturedBanner: Loading featured banners from API for module $currentModuleId...');
      }

      final request = bannerServiceInterface.getFeaturedBannerList();
      if (currentModuleId != null) {
        _featuredBannerRequests[currentModuleId] = request;
      }
      final BannerModel? bannerModel = await request;
      if (currentModuleId != null) {
        final active = _featuredBannerRequests[currentModuleId];
        if (identical(active, request)) {
          _featuredBannerRequests.remove(currentModuleId);
        }
      }

      if (bannerModel == null) {
        if (kDebugMode) {
          appLogger.warning(
              '⚠️ BannerController.getFeaturedBanner: API returned null banner model');
        }
        _isLoading = false;
        if (hadExistingBanners) {
          if (kDebugMode) {
            appLogger.debug(
                '🛡️ BannerController.getFeaturedBanner: Preserving existing banners after null API response');
          }
          return null;
        }
        _featuredBannerList = <String?>[];
        _featuredBannerDataList = <dynamic>[];
        _bannerImageList = <String?>[];
        _bannerDataList = <dynamic>[];
        update();
        return BannerModel(campaigns: [], banners: []);
      }

      if (kDebugMode) {
        appLogger.debug(
            '📦 BannerController.getFeaturedBanner: Received banner model - campaigns: ${bannerModel.campaigns?.length ?? 0}, banners: ${bannerModel.banners?.length ?? 0}');
      }

      _featuredBannerList = [];
      _featuredBannerDataList = [];

      // Process campaigns
      if (bannerModel.campaigns != null && bannerModel.campaigns!.isNotEmpty) {
        for (final campaign in bannerModel.campaigns!) {
          if (campaign.imageFullUrl != null &&
              campaign.imageFullUrl!.isNotEmpty) {
            if (_featuredBannerList!.contains(campaign.imageFullUrl)) {
              _featuredBannerList!.add(
                  '${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
            } else {
              _featuredBannerList!.add(campaign.imageFullUrl);
            }
            _featuredBannerDataList!.add(campaign);
          }
        }
      }

      // Process banners
      if (bannerModel.banners != null && bannerModel.banners!.isNotEmpty) {
        for (final banner in bannerModel.banners!) {
          if (banner.imageFullUrl != null && banner.imageFullUrl!.isNotEmpty) {
            if (_featuredBannerList!.contains(banner.imageFullUrl)) {
              _featuredBannerList!.add(
                  '${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
            } else {
              _featuredBannerList!.add(banner.imageFullUrl);
            }

            if (banner.item != null) {
              _featuredBannerDataList!.add(banner.item);
            } else if (banner.store != null) {
              _featuredBannerDataList!.add(banner.store);
            } else if (banner.type == 'default') {
              _featuredBannerDataList!.add(banner.link);
            } else {
              _featuredBannerDataList!.add(null);
            }
          }
        }
      }

      if (_featuredBannerList == null || _featuredBannerList!.isEmpty) {
        _isLoading = false;
        if (hadExistingBanners) {
          _featuredBannerList = previousFeaturedImages;
          _featuredBannerDataList = previousFeaturedData;
          _bannerImageList = List<String?>.from(previousFeaturedImages);
          _bannerDataList = List<dynamic>.from(previousFeaturedData);
          if (kDebugMode) {
            appLogger.debug(
                '🛡️ BannerController.getFeaturedBanner: Empty API payload - preserving previous banners');
          }
          update();
          return null;
        }
      }

      if (kDebugMode) {
        appLogger.info(
            '✅ BannerController.getFeaturedBanner: Loaded ${_featuredBannerList!.length} featured banners successfully for module $currentModuleId');
      }

      // Keep regular banner lists in sync for UI compatibility checks.
      _bannerImageList = List<String?>.from(_featuredBannerList ?? <String?>[]);
      _bannerDataList =
          List<dynamic>.from(_featuredBannerDataList ?? <dynamic>[]);
      _bindBannerModuleId(
        moduleId: currentModuleId,
        source: 'featured_api',
      );

      if (currentModuleId != null) {
        _featuredBannerCacheByModule[currentModuleId] = bannerModel;
      }
      _isLoading = false;
      update();
      return bannerModel;
    } catch (e, stackTrace) {
      final failedModuleId = _lastLoadedModuleId;
      if (failedModuleId != null) {
        _featuredBannerRequests.remove(failedModuleId);
      }
      if (kDebugMode) {
        appLogger.error(
            '❌ BannerController.getFeaturedBanner: Error loading featured banners: $e',
            e,
            stackTrace);
      }
      _isLoading = false;
      if (_featuredBannerList == null || _featuredBannerList!.isEmpty) {
        _featuredBannerList = <String?>[];
        _featuredBannerDataList = <dynamic>[];
        _bannerImageList = <String?>[];
        _bannerDataList = <dynamic>[];
        update();
      }
      return null;
    }
  }

  void clearBanner() {
    _bannerImageList = null;
  }

  void invalidateModule(int moduleId) {
    _featuredBannerCacheByModule.remove(moduleId);
    _featuredBannerRequests.remove(moduleId);
    if (_lastLoadedModuleId == moduleId) {
      _lastLoadedModuleId = null;
    }
    if (kDebugMode) {
      appLogger.debug(
          'BannerController: Invalidated in-memory banner cache for module $moduleId');
    }
  }

  void invalidateAll() {
    _featuredBannerCacheByModule.clear();
    _featuredBannerRequests.clear();
    _lastLoadedModuleId = null;
    if (kDebugMode) {
      appLogger.debug('BannerController: Cleared all in-memory banner cache');
    }
  }

  Future<BannerModel?> forceRefresh(int moduleId) async {
    invalidateModule(moduleId);
    return getFeaturedBanner();
  }

  /// Warm up featured banners once at app startup and treat them as global.
  /// This allows food modules with empty unified banners to still render banners.
  ///
  /// Uses Future-based deduplication: if a preload is already in flight, concurrent
  /// callers AWAIT the same Future instead of returning immediately (which was the
  /// old boolean-flag bug that caused banners not to be ready in time).
  Future<void> preloadGlobalBannersAtStartup({bool force = false}) async {
    // If already in flight, await the existing request instead of returning early.
    // This ensures callers like preloadCoreModulesForFastSwitch() actually wait.
    if (_inFlightStartupPreload != null && !force) {
      await _inFlightStartupPreload;
      return;
    }

    final bool hasInMemoryBanners =
        (_featuredBannerList?.isNotEmpty ?? false) ||
            (_bannerImageList?.isNotEmpty ?? false);
    final bool calledRecently = _lastGlobalStartupPreloadAt != null &&
        DateTime.now().difference(_lastGlobalStartupPreloadAt!) <
            const Duration(seconds: 20);
    if (!force && (hasInMemoryBanners || calledRecently)) {
      return;
    }

    // Assign before awaiting so any concurrent caller that arrives now will await it.
    _inFlightStartupPreload = _runStartupPreload();
    try {
      await _inFlightStartupPreload!;
    } finally {
      _inFlightStartupPreload = null;
    }
  }

  Future<void> _runStartupPreload() async {
    ApiClient? apiClient;
    ModuleModel? selectedBefore;
    try {
      final splashController = Get.isRegistered<SplashController>()
          ? Get.find<SplashController>()
          : null;
      apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;

      selectedBefore = splashController?.selectedModule.value;
      final int? previousModuleId = selectedBefore?.id;

      // Featured banners are global from backend perspective. We warm them via module 3.
      if (apiClient != null) {
        apiClient.updateHeader(
          null,
          null,
          null,
          null,
          3,
          null,
          null,
        );
      }

      // Force fresh featured banners on startup warm-up to avoid 304+empty-cache.
      await HiveHomeCacheService()
          .clearETagForUri('${AppConstants.bannerUri}?featured=1');
      // Also clear ETag for promotional banner to prevent 304+no-local-cache scenario.
      await HiveHomeCacheService()
          .clearETagForUri(AppConstants.promotionalBannerUri);

      final BannerModel? bannerModel =
          await bannerServiceInterface.getFeaturedBannerList();
      final PromotionalBanner? promotionalBanner =
          await bannerServiceInterface.getPromotionalBannerList();
      // Apply promotional banner first — independent of whether featured banners loaded.
      if (promotionalBanner != null) {
        _promotionalBanner = promotionalBanner;
        if (kDebugMode) {
          appLogger.info(
              '✅ BannerController.preloadGlobalBannersAtStartup: Warmed promotional banner');
        }
      } else {
        if (kDebugMode) {
          appLogger.warning(
              '⚠️ BannerController.preloadGlobalBannersAtStartup: Promotional banner payload is empty');
        }
      }

      final bool hasPayload = bannerModel != null &&
          ((bannerModel.banners?.isNotEmpty ?? false) ||
              (bannerModel.campaigns?.isNotEmpty ?? false));

      if (!hasPayload) {
        if (kDebugMode) {
          appLogger.warning(
              '⚠️ BannerController.preloadGlobalBannersAtStartup: API returned empty payload');
        }
        // Still refresh UI so promotional banner (if loaded) is displayed.
        update();
        return;
      }

      setFromUnified(
        bannerModel: bannerModel,
        moduleId: 3,
        source: 'startup_preload',
        silent: false,
      );

      // Persist the same banner payload for all known modules to maximize cache hits.
      final cacheService = HiveHomeCacheService();
      final Set<int> moduleIds = <int>{3};
      if (previousModuleId != null) {
        moduleIds.add(previousModuleId);
      }
      final modules = splashController?.moduleList;
      if (modules != null) {
        for (final module in modules) {
          if (module.id != null) {
            moduleIds.add(module.id!);
          }
        }
      }

      for (final moduleId in moduleIds) {
        _featuredBannerCacheByModule[moduleId] = bannerModel;
        await cacheService.saveBanners(moduleId, bannerModel);
      }

      // Refresh listeners once after startup warm-up for both featured + promotional banners.
      update();

      if (kDebugMode) {
        appLogger.info(
            '✅ BannerController.preloadGlobalBannersAtStartup: Warmed ${bannerModel.banners?.length ?? 0} banners for modules=${moduleIds.toList()}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        appLogger.error('❌ BannerController.preloadGlobalBannersAtStartup: $e',
            e, stackTrace);
      }
    } finally {
      if (apiClient != null && selectedBefore?.id != null) {
        apiClient.updateHeader(
          null,
          null,
          null,
          null,
          selectedBefore!.id,
          null,
          null,
        );
      }
      _lastGlobalStartupPreloadAt = DateTime.now();
    }
  }

  Future<void> resetToDefault() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 BannerController: Resetting to default state');
      }

      // Clear all banner lists
      _bannerImageList = null;
      _taxiBannerImageList = null;
      _featuredBannerList = null;
      _bannerDataList = null;
      _taxiBannerDataList = null;
      _featuredBannerDataList = null;

      // Clear other banner models
      _parcelOtherBannerModel = null;
      _promotionalBanner = null;

      // Reset state
      _currentIndex = 0;
      _isLoading = false;
      _lastLoadedModuleId = null; // Clear module tracking
      _currentBannerModuleId = null;
      _featuredBannerCacheByModule.clear();
      _featuredBannerRequests.clear();
      _hasDistributedOnce = false;

      // 🚫 REMOVED: Static variable cleanup - no longer used

      if (kDebugMode) {
        debugPrint('✅ BannerController: Reset to default state completed');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ BannerController.resetToDefault: Error - $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    update();
  }

  Future<BannerModel?> getBannerList(bool reload,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    int? currentModuleId;
    if (Get.isRegistered<SplashController>()) {
      currentModuleId = Get.find<SplashController>().selectedModule.value?.id;
    }
    if (!reload &&
        !fromRecall &&
        dataSource == DataSourceEnum.local &&
        currentModuleId != null &&
        _lastLoadedModuleId == currentModuleId &&
        _featuredBannerList != null &&
        _featuredBannerList!.isNotEmpty) {
      if (kDebugMode) {
        appLogger.debug(
            'BannerController.getBannerList: Module $currentModuleId banners already in memory - skip local cache reload');
      }
      return null;
    }

    // Always load from cache when dataSource is local, even if data exists
    if (_bannerImageList == null ||
        reload ||
        fromRecall ||
        dataSource == DataSourceEnum.local) {
      if (reload) {
        _bannerImageList = null;
      }

      // 🔧 CRITICAL FIX: Only set loading to true if we don't have existing banners
      // If banners already exist, keep it in "Success" state during silent refresh
      final hasExistingBanners =
          _featuredBannerList != null && _featuredBannerList!.isNotEmpty;
      if (hasExistingBanners &&
          !reload &&
          dataSource != DataSourceEnum.client) {
        // Silent refresh - don't show loading state
        _isLoading = false;
        if (kDebugMode) {
          appLogger.debug(
              '✅ BannerController: Silent refresh - preserving Success state (has existing banners)');
        }
      } else if (reload || dataSource == DataSourceEnum.client) {
        // First load or force refresh - show loading state
        _isLoading = true;
        update();
      }

      // ⚡ CACHE FIRST: Check comprehensive cache before making API calls
      bool loadedFromCache = false;
      if (!reload && dataSource != DataSourceEnum.client) {
        try {
          final cachedData =
              await ComprehensiveHomeCacheManager.loadAllHomeData();
          if (cachedData.containsKey('banners')) {
            final bannerData = cachedData['banners'] as Map<String, dynamic>;
            if (bannerData['bannerImageList'] != null ||
                bannerData['bannerDataList'] != null) {
              appLogger.info(
                  '✅ BannerController: Loading banners from comprehensive cache');
              setBannerDataFromCache(
                bannerImageList: bannerData['bannerImageList'] is List
                    ? List<String?>.from(bannerData['bannerImageList'] as List)
                    : null,
                bannerDataList: bannerData['bannerDataList'] is List
                    ? List<dynamic>.from(bannerData['bannerDataList'] as List)
                    : null,
                featuredBannerList: bannerData['featuredBannerList'] is List
                    ? List<String?>.from(
                        bannerData['featuredBannerList'] as List)
                    : null,
                featuredBannerDataList:
                    bannerData['featuredBannerDataList'] is List
                        ? List<dynamic>.from(
                            bannerData['featuredBannerDataList'] as List)
                        : null,
                promotionalBanner: bannerData['promotionalBanner'] != null
                    ? PromotionalBanner.fromJson(
                        bannerData['promotionalBanner'] as Map<String, dynamic>)
                    : null,
              );
              _isLoading = false;
              update();
              loadedFromCache = true;

              // 🔧 FIX: If loaded from cache, refresh in background (non-blocking)
              // This ensures data is fresh without blocking UI
              if (kDebugMode) {
                appLogger.debug(
                    '🔄 BannerController: Cache loaded - refreshing in background');
              }
              bannerServiceInterface
                  .getBannerList(source: DataSourceEnum.client)
                  .then((bannerModel) {
                if (bannerModel != null) {
                  // 🔧 FIX: Check if we're transitioning from empty to non-empty
                  final wasEmpty = _featuredBannerList == null ||
                      _featuredBannerList!.isEmpty;
                  _prepareBanner(bannerModel);
                  // If was empty and now has data, force update
                  final nowHasData = _featuredBannerList != null &&
                      _featuredBannerList!.isNotEmpty;
                  if (wasEmpty && nowHasData) {
                    if (kDebugMode) {
                      appLogger.debug(
                          '🔧 BannerController: Background refresh - empty-to-non-empty transition, forcing update');
                    }
                    update(); // Force update after background refresh
                  }
                  if (kDebugMode) {
                    appLogger.info(
                        '✅ BannerController: Background refresh completed');
                  }
                }
              }).catchError((Object e) {
                if (kDebugMode) {
                  appLogger.warning(
                      '⚠️ BannerController: Background refresh failed: $e');
                }
              });

              return null; // Return null since we set data directly
            }
          }
        } catch (e) {
          appLogger.warning(
              '⚠️ BannerController: Error loading from comprehensive cache: $e');
        }
      }

      // Only make API call if not loaded from cache
      BannerModel? bannerModel;
      if (!loadedFromCache) {
        if (dataSource == DataSourceEnum.local) {
          bannerModel = await bannerServiceInterface.getBannerList(
              source: DataSourceEnum.local);
          await _prepareBanner(bannerModel);

          // Don't automatically call API when loading from cache
          // The background refresh will handle API updates
        } else {
          bannerModel = await bannerServiceInterface.getBannerList(
              source: DataSourceEnum.client);
          _prepareBanner(bannerModel);
        }

        _isLoading = false;
        update();
      }

      return bannerModel;
    }
    return null;
  }

  Future<void> _prepareBanner(BannerModel? bannerModel) async {
    if (bannerModel != null) {
      // ⚡ ZERO-FLICKER: Store old data before preparing new data
      final oldImageList = List<String?>.from(_bannerImageList ?? []);
      final oldDataList = List<dynamic>.from(_bannerDataList ?? []);

      _bannerImageList = [];
      _bannerDataList = [];

      // Process campaigns (if any)
      if (bannerModel.campaigns != null && bannerModel.campaigns!.isNotEmpty) {
        for (final campaign in bannerModel.campaigns!) {
          if (campaign.imageFullUrl != null &&
              campaign.imageFullUrl!.isNotEmpty) {
            if (_bannerImageList!.contains(campaign.imageFullUrl)) {
              _bannerImageList!.add(
                  '${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
            } else {
              _bannerImageList!.add(campaign.imageFullUrl);
            }
            _bannerDataList!.add(campaign);
          }
        }
      }

      // Process banners (if any)
      if (bannerModel.banners != null && bannerModel.banners!.isNotEmpty) {
        for (final banner in bannerModel.banners!) {
          if (banner.imageFullUrl != null && banner.imageFullUrl!.isNotEmpty) {
            if (_bannerImageList!.contains(banner.imageFullUrl)) {
              _bannerImageList!.add(
                  '${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
            } else {
              _bannerImageList!.add(banner.imageFullUrl);
            }

            if (banner.item != null) {
              _bannerDataList!.add(banner.item);
            } else if (banner.store != null) {
              _bannerDataList!.add(banner.store);
            } else if (banner.type == 'default') {
              _bannerDataList!.add(banner.link);
            } else {
              _bannerDataList!.add(null);
            }
          }
        }
      }

      // 🔧 CRITICAL FIX: Check for empty-to-non-empty transition (must always update)
      final wasEmpty = oldImageList.isEmpty;
      final nowHasData =
          _bannerImageList != null && _bannerImageList!.isNotEmpty;
      final isEmptyToNonEmpty = wasEmpty && nowHasData;

      // ⚡ ZERO-FLICKER: Deep equality check - only update if data actually changed
      // BUT: Always update if transitioning from empty to non-empty
      final newImageList = List<String?>.from(_bannerImageList ?? []);
      final newDataList = List<dynamic>.from(_bannerDataList ?? []);

      if (!_disableDeepEquality &&
          !isEmptyToNonEmpty &&
          _deepEquality.equals(oldImageList, newImageList) &&
          _deepEquality.equals(oldDataList, newDataList)) {
        _isLoading = false;
        if (kDebugMode) {
          appLogger.debug(
              '✅ BannerController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
        }
        return;
      }

      if (isEmptyToNonEmpty && kDebugMode) {
        appLogger.debug(
            '🔧 BannerController._prepareBanner: Empty-to-non-empty transition detected - forcing update');
      }
      final bool hasAnyBanners =
          _bannerImageList != null && _bannerImageList!.isNotEmpty;
      if (!_hasDistributedOnce && hasAnyBanners) {
        _hasDistributedOnce = true;
        if (kDebugMode) {
          appLogger.debug(
              '⚡ BannerController._prepareBanner: First distribution detected - forcing update');
        }
      }
      final int? selectedModuleId = Get.isRegistered<SplashController>()
          ? Get.find<SplashController>().selectedModule.value?.id
          : null;
      if (hasAnyBanners) {
        _bindBannerModuleId(
          moduleId: selectedModuleId,
          source: 'regular_banner_payload',
        );
      }
    }
    update();
  }

  /// Set banner data from bootstrap endpoint
  /// ⚡ CRITICAL FIX: Don't overwrite existing banners if bootstrap has no banners
  void setBannerDataFromBootstrap(BannerModel bannerModel) {
    final int? selectedModuleId = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>().selectedModule.value?.id
        : null;
    // Check if bootstrap actually has banners
    final hasCampaigns =
        bannerModel.campaigns != null && bannerModel.campaigns!.isNotEmpty;
    final hasBanners =
        bannerModel.banners != null && bannerModel.banners!.isNotEmpty;
    final hasExistingBanners =
        _featuredBannerList != null && _featuredBannerList!.isNotEmpty;

    // If bootstrap has no banners and we already have banners loaded, don't overwrite
    if (!hasCampaigns && !hasBanners && hasExistingBanners) {
      if (kDebugMode) {
        appLogger.warning(
            '⚠️ BannerController: Bootstrap has no banners, keeping existing ${_featuredBannerList!.length} banners');
      }
      return;
    }

    // 🔧 CRITICAL FIX: Store old data BEFORE clearing (for empty-to-non-empty check)
    final oldImageList = List<String?>.from(_featuredBannerList ?? []);
    final oldDataList = List<dynamic>.from(_featuredBannerDataList ?? []);

    // Only clear if we're actually going to set new data
    if (hasCampaigns || hasBanners) {
      _featuredBannerList = [];
      _featuredBannerDataList = [];
      // Also set bannerImageList for compatibility with BannerView(isFeatured: false)
      _bannerImageList = [];
      _bannerDataList = [];

      // 🚫 REMOVED: Static variable hack - causes race conditions
      // BannerController is the single source of truth for banner state
    }

    // Process campaigns
    if (hasCampaigns) {
      for (final campaign in bannerModel.campaigns!) {
        if (campaign.imageFullUrl != null &&
            campaign.imageFullUrl!.isNotEmpty) {
          if (_featuredBannerList!.contains(campaign.imageFullUrl)) {
            _featuredBannerList!.add(
                '${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
          } else {
            _featuredBannerList!.add(campaign.imageFullUrl);
          }
          _featuredBannerDataList!.add(campaign);

          // Also add to bannerImageList for compatibility
          if (_bannerImageList!.contains(campaign.imageFullUrl)) {
            _bannerImageList!.add(
                '${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
          } else {
            _bannerImageList!.add(campaign.imageFullUrl);
          }
          _bannerDataList!.add(campaign);
        }
      }
    }

    // Process banners (global banners: no module filtering)

    if (hasBanners) {
      for (final banner in bannerModel.banners!) {
        if (banner.imageFullUrl != null && banner.imageFullUrl!.isNotEmpty) {
          if (_featuredBannerList!.contains(banner.imageFullUrl)) {
            _featuredBannerList!.add(
                '${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
          } else {
            _featuredBannerList!.add(banner.imageFullUrl);
          }

          dynamic bannerData;
          if (banner.item != null) {
            bannerData = banner.item;
            _featuredBannerDataList!.add(banner.item);
          } else if (banner.store != null) {
            bannerData = banner.store;
            _featuredBannerDataList!.add(banner.store);
          } else if (banner.type == 'default') {
            bannerData = banner.link;
            _featuredBannerDataList!.add(banner.link);
          } else {
            bannerData = null;
            _featuredBannerDataList!.add(null);
          }

          // Also add to bannerImageList for compatibility
          if (_bannerImageList!.contains(banner.imageFullUrl)) {
            _bannerImageList!.add(
                '${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
          } else {
            _bannerImageList!.add(banner.imageFullUrl);
          }
          _bannerDataList!.add(bannerData);
        }
      }
    }

    // 🔧 CRITICAL FIX: Check for empty-to-non-empty transition (must always update)
    // This fixes the bug where banners don't appear after loading from bootstrap
    final wasFeaturedBannerEmpty = oldImageList.isEmpty;
    final nowHasFeaturedBanners =
        _featuredBannerList != null && _featuredBannerList!.isNotEmpty;
    final isEmptyToNonEmpty = wasFeaturedBannerEmpty && nowHasFeaturedBanners;

    if (isEmptyToNonEmpty && kDebugMode) {
      appLogger.debug(
          '🔧 BannerController.setBannerDataFromBootstrap: Empty-to-non-empty transition detected (${_featuredBannerList!.length} banners) - forcing update');
    }

    // ⚡ ZERO-FLICKER: Deep equality check - only update if data actually changed
    // BUT: Always update if transitioning from empty to non-empty
    final newImageList = List<String?>.from(_featuredBannerList ?? []);
    final newDataList = List<dynamic>.from(_featuredBannerDataList ?? []);

    if (!_disableDeepEquality &&
        !isEmptyToNonEmpty &&
        _deepEquality.equals(oldImageList, newImageList) &&
        _deepEquality.equals(oldDataList, newDataList)) {
      _isLoading = false;
      if (kDebugMode) {
        appLogger.debug(
            '✅ BannerController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
      }
      return;
    }

    if (kDebugMode && isEmptyToNonEmpty) {
      appLogger.info(
          '✅ BannerController.setBannerDataFromBootstrap: Updating UI after empty-to-non-empty transition');
    }
    _bindBannerModuleId(
      moduleId: selectedModuleId,
      source: 'bootstrap',
    );
    update();
    if (kDebugMode) {
      final bannerCount = _featuredBannerList?.length ?? 0;
      appLogger.info(
          '✅ BannerController: Banner data set from bootstrap ($bannerCount banners)');
    }
  }

  /// Set banner data from HomeUnifiedController (single source of truth)
  /// 🔧 ARCHITECTURAL FIX: This method is the ONLY way HomeUnifiedController should update banners
  /// [silent] - If true, only updates if empty-to-non-empty transition (prevents unnecessary updates)
  void setFromUnified({
    required BannerModel bannerModel,
    int? moduleId,
    String source = 'unified',
    bool silent = false,
  }) {
    final int? selectedModuleId =
        Get.isRegistered<SplashController>()
            ? Get.find<SplashController>().selectedModule.value?.id
            : null;
    final int? effectiveModuleId = moduleId ?? selectedModuleId;
    if (selectedModuleId != null &&
        effectiveModuleId != null &&
        selectedModuleId != effectiveModuleId) {
      if (kDebugMode) {
        debugPrint(
            '[HOME_BANNER_IGNORED_STALE] currentModuleId=$selectedModuleId bannerModuleId=$effectiveModuleId');
      }
      return;
    }
    // Check if bootstrap actually has banners
    final hasCampaigns =
        bannerModel.campaigns != null && bannerModel.campaigns!.isNotEmpty;
    final hasBanners =
        bannerModel.banners != null && bannerModel.banners!.isNotEmpty;

    if (!hasCampaigns && !hasBanners) {
      // No banners in unified data - don't overwrite existing banners
      if (kDebugMode) {
        debugPrint(
            '[HOME_BANNER_EMPTY] moduleId=${effectiveModuleId ?? selectedModuleId} reason=unified_payload_empty source=$source');
      }
      return;
    }

    // 🔧 CRITICAL FIX: Store old data BEFORE clearing (for empty-to-non-empty check)
    final oldFeaturedBannerList = List<String?>.from(_featuredBannerList ?? []);
    final oldBannerImageList = List<String?>.from(_bannerImageList ?? []);

    // Clear existing data
    _featuredBannerList = [];
    _featuredBannerDataList = [];
    _bannerImageList = [];
    _bannerDataList = [];

    // Process campaigns
    if (hasCampaigns) {
      for (final campaign in bannerModel.campaigns!) {
        if (campaign.imageFullUrl != null &&
            campaign.imageFullUrl!.isNotEmpty) {
          if (_featuredBannerList!.contains(campaign.imageFullUrl)) {
            _featuredBannerList!.add(
                '${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
          } else {
            _featuredBannerList!.add(campaign.imageFullUrl);
          }
          _featuredBannerDataList!.add(campaign);

          // Also add to bannerImageList for compatibility
          if (_bannerImageList!.contains(campaign.imageFullUrl)) {
            _bannerImageList!.add(
                '${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
          } else {
            _bannerImageList!.add(campaign.imageFullUrl);
          }
          _bannerDataList!.add(campaign);
        }
      }
    }

    // Process banners (global banners: no module filtering)

    if (hasBanners) {
      for (final banner in bannerModel.banners!) {
        if (banner.imageFullUrl != null && banner.imageFullUrl!.isNotEmpty) {
          if (_featuredBannerList!.contains(banner.imageFullUrl)) {
            _featuredBannerList!.add(
                '${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
          } else {
            _featuredBannerList!.add(banner.imageFullUrl);
          }

          dynamic bannerData;
          if (banner.item != null) {
            bannerData = banner.item;
            _featuredBannerDataList!.add(banner.item);
          } else if (banner.store != null) {
            bannerData = banner.store;
            _featuredBannerDataList!.add(banner.store);
          } else if (banner.type == 'default') {
            bannerData = banner.link;
            _featuredBannerDataList!.add(banner.link);
          } else {
            bannerData = null;
            _featuredBannerDataList!.add(null);
          }

          // Also add to bannerImageList for compatibility
          if (_bannerImageList!.contains(banner.imageFullUrl)) {
            _bannerImageList!.add(
                '${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
          } else {
            _bannerImageList!.add(banner.imageFullUrl);
          }
          _bannerDataList!.add(bannerData);
        }
      }
    }

    // 🔧 CRITICAL FIX: Check for empty-to-non-empty transition (must always update)
    final wasFeaturedBannerEmpty = oldFeaturedBannerList.isEmpty;
    final wasBannerImageEmpty = oldBannerImageList.isEmpty;
    final nowHasFeaturedBanners =
        _featuredBannerList != null && _featuredBannerList!.isNotEmpty;
    final nowHasBannerImages =
        _bannerImageList != null && _bannerImageList!.isNotEmpty;
    final isEmptyToNonEmpty =
        (wasFeaturedBannerEmpty && nowHasFeaturedBanners) ||
            (wasBannerImageEmpty && nowHasBannerImages);

    final bool hasAnyBanners = nowHasFeaturedBanners || nowHasBannerImages;
    if (!_hasDistributedOnce && hasAnyBanners) {
      _hasDistributedOnce = true;
      _bindBannerModuleId(
        moduleId: effectiveModuleId ?? selectedModuleId,
        source: source,
      );
      if (kDebugMode) {
        appLogger.debug(
            '⚡ BannerController.setFromUnified: First distribution detected - forcing update');
      }
      update();
      return;
    }

    // 🔥 RULE: Empty-to-non-empty transition = ALWAYS update (no silent mode)
    if (isEmptyToNonEmpty) {
      _bindBannerModuleId(
        moduleId: effectiveModuleId ?? selectedModuleId,
        source: source,
      );
      if (kDebugMode) {
        appLogger.debug(
            '🔧 BannerController.setFromUnified: Empty-to-non-empty transition detected - forcing update');
      }
      update();
      return;
    }

    // If silent mode and not empty-to-non-empty, skip update
    if (silent && !_disableDeepEquality) {
      if (kDebugMode) {
        appLogger.debug(
            '✅ BannerController.setFromUnified: Silent mode - skipping update (no empty-to-non-empty transition)');
      }
      return;
    }

    // Normal update
    _bindBannerModuleId(
      moduleId: effectiveModuleId ?? selectedModuleId,
      source: source,
    );
    update();
    if (kDebugMode) {
      final bannerCount = _featuredBannerList?.length ?? 0;
      appLogger.info(
          '✅ BannerController.setFromUnified: Updated banners ($bannerCount banners)');
    }
  }

  /// Clear unified banners when switching modules and new payload is empty.
  void clearUnifiedBanners({
    bool notify = true,
    int? moduleId,
    String reason = 'unknown',
  }) {
    final int? selectedModuleId =
        Get.isRegistered<SplashController>()
            ? Get.find<SplashController>().selectedModule.value?.id
            : null;
    if (moduleId != null &&
        selectedModuleId != null &&
        moduleId != selectedModuleId) {
      if (kDebugMode) {
        debugPrint(
            '[HOME_BANNER_IGNORED_STALE] currentModuleId=$selectedModuleId bannerModuleId=$moduleId');
      }
      return;
    }
    _featuredBannerList = [];
    _featuredBannerDataList = [];
    _bannerImageList = [];
    _bannerDataList = [];
    _isLoading = false;
    _currentBannerModuleId = moduleId ?? selectedModuleId;
    if (kDebugMode) {
      debugPrint(
          '[HOME_BANNER_EMPTY] moduleId=$_currentBannerModuleId reason=$reason');
    }
    if (notify) {
      update();
    }
  }

  Future<void> getTaxiBannerList(bool reload) async {
    if (_taxiBannerImageList == null || reload) {
      _taxiBannerImageList = null;
      final BannerModel? bannerModel =
          await bannerServiceInterface.getTaxiBannerList();
      if (bannerModel != null) {
        _taxiBannerImageList = [];
        _taxiBannerDataList = [];
        for (final campaign in bannerModel.campaigns!) {
          _taxiBannerImageList!.add(campaign.imageFullUrl);
          _taxiBannerDataList!.add(campaign);
        }
        for (final banner in bannerModel.banners!) {
          _taxiBannerImageList!.add(banner.imageFullUrl);
          if (banner.item != null) {
            _taxiBannerDataList!.add(banner.item);
          } else if (banner.store != null) {
            _taxiBannerDataList!.add(banner.store);
          } else if (banner.type == 'default') {
            _taxiBannerDataList!.add(banner.link);
          } else {
            _taxiBannerDataList!.add(null);
          }
        }
        if (Get.context != null &&
            ResponsiveHelper.isDesktop(Get.context!) &&
            _taxiBannerImageList!.length % 2 != 0) {
          _taxiBannerImageList!.add(_taxiBannerImageList![0]);
          _taxiBannerDataList!.add(_taxiBannerDataList![0]);
        }
      }
      update();
    }
  }

  Future<void> getParcelOtherBannerList(bool reload,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    if (_parcelOtherBannerModel == null || reload || fromRecall) {
      ParcelOtherBannerModel? parcelOtherBannerModel;
      if (dataSource == DataSourceEnum.local) {
        parcelOtherBannerModel = await bannerServiceInterface
            .getParcelOtherBannerList(source: dataSource);
        _prepareParcelBanner(parcelOtherBannerModel);
        getParcelOtherBannerList(false,
            dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        parcelOtherBannerModel = await bannerServiceInterface
            .getParcelOtherBannerList(source: dataSource);
        _prepareParcelBanner(parcelOtherBannerModel);
      }
    }
  }

  void _prepareParcelBanner(ParcelOtherBannerModel? parcelOtherBannerModel) {
    if (parcelOtherBannerModel != null) {
      _parcelOtherBannerModel = parcelOtherBannerModel;
    }
    update();
  }

  Future<PromotionalBanner?> getPromotionalBannerList(bool reload) async {
    try {
      if (_promotionalBanner == null || reload) {
        if (kDebugMode) {
          appLogger.debug(
              '🚀 BannerController.getPromotionalBannerList: Loading promotional banners from API...');
        }

        final PromotionalBanner? promotionalBanner =
            await bannerServiceInterface.getPromotionalBannerList();
        if (promotionalBanner != null) {
          _promotionalBanner = promotionalBanner;
          final String? promoUrl = promotionalBanner.bottomSectionBannerFullUrl;
          if (kDebugMode) {
            appLogger.info(
                '✅ BannerController.getPromotionalBannerList: Loaded promotional banner successfully');
            appLogger.info(
                '🔍 BannerController.getPromotionalBannerList: bottomSectionBannerFullUrl=${promoUrl ?? "null"}');
          }
        } else {
          if (kDebugMode) {
            appLogger.warning(
                '⚠️ BannerController.getPromotionalBannerList: API returned null promotional banner');
          }
        }
        update();
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '❌ BannerController.getPromotionalBannerList: Error fetching promotional banner: $e',
            e);
      }
      update();
      return null;
    }
    return _promotionalBanner;
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }

  /// Set banner data directly from cache (for instant loading)
  void setBannerDataFromCache({
    List<String?>? bannerImageList,
    List<dynamic>? bannerDataList,
    List<String?>? featuredBannerList,
    List<dynamic>? featuredBannerDataList,
    PromotionalBanner? promotionalBanner,
  }) {
    final int? selectedModuleId = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>().selectedModule.value?.id
        : null;
    // 🔧 CRITICAL FIX: Check for empty-to-non-empty transition (must always update)
    // This fixes the bug where banners don't appear after loading from cache
    bool isEmptyToNonEmpty = false;

    // Check if transitioning from empty/null to non-empty
    final wasFeaturedBannerEmpty =
        _featuredBannerList == null || _featuredBannerList!.isEmpty;
    final isFeaturedBannerNonEmpty =
        featuredBannerList != null && featuredBannerList.isNotEmpty;
    if (wasFeaturedBannerEmpty && isFeaturedBannerNonEmpty) {
      isEmptyToNonEmpty = true;
      if (kDebugMode) {
        appLogger.debug(
            '🔧 BannerController: Empty-to-non-empty transition detected for featured banners (${featuredBannerList.length} items) - forcing update');
      }
    }

    final wasBannerImageEmpty =
        _bannerImageList == null || _bannerImageList!.isEmpty;
    final isBannerImageNonEmpty =
        bannerImageList != null && bannerImageList.isNotEmpty;
    if (wasBannerImageEmpty && isBannerImageNonEmpty) {
      isEmptyToNonEmpty = true;
      if (kDebugMode) {
        appLogger.debug(
            '🔧 BannerController: Empty-to-non-empty transition detected for regular banners (${bannerImageList.length} items) - forcing update');
      }
    }

    // ⚡ ZERO-FLICKER: Deep equality check - only update if data actually changed
    // BUT: Always update if transitioning from empty to non-empty
    bool hasChanged = isEmptyToNonEmpty; // Force update on empty-to-non-empty

    final bool hasAnyBanners =
        (featuredBannerList != null && featuredBannerList.isNotEmpty) ||
            (bannerImageList != null && bannerImageList.isNotEmpty);
    if (!_hasDistributedOnce && hasAnyBanners) {
      _hasDistributedOnce = true;
      hasChanged = true;
      if (kDebugMode) {
        appLogger.debug(
            '⚡ BannerController.setBannerDataFromCache: First distribution detected - forcing update');
      }
    }

    if (bannerImageList != null &&
        (_disableDeepEquality ||
            !_deepEquality.equals(_bannerImageList, bannerImageList))) {
      _bannerImageList = bannerImageList;
      hasChanged = true;
    }
    if (bannerDataList != null &&
        (_disableDeepEquality ||
            !_deepEquality.equals(_bannerDataList, bannerDataList))) {
      _bannerDataList = bannerDataList;
      hasChanged = true;
    }
    if (featuredBannerList != null &&
        (_disableDeepEquality ||
            !_deepEquality.equals(_featuredBannerList, featuredBannerList))) {
      _featuredBannerList = featuredBannerList;
      hasChanged = true;
    }
    if (featuredBannerDataList != null &&
        (_disableDeepEquality ||
            !_deepEquality.equals(
                _featuredBannerDataList, featuredBannerDataList))) {
      _featuredBannerDataList = featuredBannerDataList;
      hasChanged = true;
    }
    if (promotionalBanner != null && _promotionalBanner != promotionalBanner) {
      _promotionalBanner = promotionalBanner;
      hasChanged = true;
    }

    if (hasChanged) {
      _bindBannerModuleId(
        moduleId: selectedModuleId,
        source: 'cache',
      );
      if (kDebugMode && isEmptyToNonEmpty) {
        appLogger.info(
            '✅ BannerController: Updating UI after empty-to-non-empty transition');
      }
      update();
    } else {
      _isLoading = false;
      if (kDebugMode) {
        appLogger.debug(
            '✅ BannerController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
      }
    }
  }

  /// Set banner data from cache (handles both BannerModel and raw JSON)
  /// Sets REGULAR banners (not featured)
  void setBannerModelFromCache(dynamic data) {
    if (data == null) return;

    try {
      BannerModel? bannerModel;
      if (data is BannerModel) {
        // Already deserialized model object
        bannerModel = data;
      } else if (data is Map<String, dynamic>) {
        // Raw JSON from disk cache - deserialize it
        bannerModel = BannerModel.fromJson(data);
      } else {
        appLogger.warning(
            '⚠️ BannerController: Unexpected data type for banner: ${data.runtimeType}');
        return;
      }

      _prepareBanner(bannerModel);
      appLogger.info('✅ BannerController: Loaded banners from cache');
    } catch (e) {
      appLogger.error(
          '❌ BannerController: Error setting banner from cache: $e', e);
    }
  }

  /// Set FEATURED banner data from cache (for multi-module screen)
  /// Similar to setBannerDataFromBootstrap but for cache
  void setFeaturedBannerModelFromCache(dynamic data) {
    if (data == null) return;

    try {
      BannerModel? bannerModel;
      if (data is BannerModel) {
        bannerModel = data;
      } else if (data is Map<String, dynamic>) {
        bannerModel = BannerModel.fromJson(data);
      } else {
        if (kDebugMode) {
          appLogger.warning(
              '⚠️ BannerController: Unexpected data type for featured banner: ${data.runtimeType}');
        }
        return;
      }

      // Check if we actually have banners
      final hasCampaigns =
          bannerModel.campaigns != null && bannerModel.campaigns!.isNotEmpty;
      final hasBanners =
          bannerModel.banners != null && bannerModel.banners!.isNotEmpty;

      if (!hasCampaigns && !hasBanners) {
        if (kDebugMode) {
          appLogger
              .warning('⚠️ BannerController: Cache has no featured banners');
        }
        _featuredBannerList = [];
        _featuredBannerDataList = [];
        update();
        return;
      }

      // Clear existing featured banners
      _featuredBannerList = [];
      _featuredBannerDataList = [];

      // Process campaigns
      if (hasCampaigns) {
        for (final campaign in bannerModel.campaigns!) {
          if (campaign.imageFullUrl != null &&
              campaign.imageFullUrl!.isNotEmpty) {
            if (_featuredBannerList!.contains(campaign.imageFullUrl)) {
              _featuredBannerList!.add(
                  '${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
            } else {
              _featuredBannerList!.add(campaign.imageFullUrl);
            }
            _featuredBannerDataList!.add(campaign);
          }
        }
      }

      // Process banners
      if (hasBanners) {
        for (final banner in bannerModel.banners!) {
          if (banner.imageFullUrl != null && banner.imageFullUrl!.isNotEmpty) {
            if (_featuredBannerList!.contains(banner.imageFullUrl)) {
              _featuredBannerList!.add(
                  '${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
            } else {
              _featuredBannerList!.add(banner.imageFullUrl);
            }

            if (banner.item != null) {
              _featuredBannerDataList!.add(banner.item);
            } else if (banner.store != null) {
              _featuredBannerDataList!.add(banner.store);
            } else if (banner.type == 'default') {
              _featuredBannerDataList!.add(banner.link);
            } else {
              _featuredBannerDataList!.add(null);
            }
          }
        }
      }

      // 🔧 FIX: Set isLoading to false to prevent skeleton from appearing
      _isLoading = false;
      final int? selectedModuleId = Get.isRegistered<SplashController>()
          ? Get.find<SplashController>().selectedModule.value?.id
          : null;
      _bindBannerModuleId(
        moduleId: selectedModuleId,
        source: 'featured_cache',
      );
      update();
      if (kDebugMode) {
        final bannerCount = _featuredBannerList?.length ?? 0;
        appLogger.info(
            '✅ BannerController: Loaded $bannerCount featured banners from cache');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        appLogger.error(
            '❌ BannerController: Error setting featured banner from cache: $e',
            e,
            stackTrace);
      }
      _featuredBannerList = [];
      _featuredBannerDataList = [];
      update();
    }
  }

  /// Set promotional banner from cache (handles both PromotionalBanner and raw JSON)
  void setPromotionalBannerFromCache(dynamic data) {
    if (data == null) return;

    try {
      if (data is PromotionalBanner) {
        // Already deserialized model object
        _promotionalBanner = data;
      } else if (data is Map<String, dynamic>) {
        // Raw JSON from disk cache - deserialize it
        _promotionalBanner = PromotionalBanner.fromJson(data);
      } else {
        appLogger.warning(
            '⚠️ BannerController: Unexpected data type for promotional banner: ${data.runtimeType}');
        return;
      }
      update();
      appLogger
          .info('✅ BannerController: Loaded promotional banner from cache');
    } catch (e) {
      appLogger.error(
          '❌ BannerController: Error setting promotional banner from cache: $e',
          e);
    }
  }
}
