
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/splash/domain/models/landing_model.dart';
import 'package:sixam_mart/features/splash/domain/services/app_init_service.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/models/app_init_model.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/controllers/taxi_favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/header_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/splash/domain/services/splash_service_interface.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/helper/splash_route_helper.dart';
import 'package:sixam_mart/common/cache/smart_cache_manager.dart';
import 'package:sixam_mart/common/cache/splash_cache_manager.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:universal_html/html.dart' as html;
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart'
    show OffersModel;
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// ⚡ PERF: Top-level function for compute() isolate.
/// Parses ConfigModel, ModuleModel, and module list off the main thread
/// to prevent frame drops during splash GIF animation.
Map<String, dynamic> _parseModelsInIsolate(Map<String, dynamic> input) {
  final configData = input['configData'] as Map<String, dynamic>?;
  final moduleData = input['moduleData'] as Map<String, dynamic>?;
  final moduleListData = input['moduleListData'] as List<dynamic>?;

  final result = <String, dynamic>{};

  if (configData != null) {
    result['configModel'] = ConfigModel.fromJson(configData);
  }

  if (moduleData != null) {
    result['module'] = ModuleModel.fromJson(moduleData);
  }

  if (moduleListData != null) {
    result['moduleList'] = moduleListData
        .map((data) => ModuleModel.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  return result;
}

class SplashController extends GetxController implements GetxService {
  final SplashServiceInterface splashServiceInterface;
  SplashController({required this.splashServiceInterface});

  bool _hasLoadedPromotionalContent = false;
  bool get isPromotionalContentReady => _hasLoadedPromotionalContent;
  bool _hasAttemptedPromotionalLoad = false;
  bool get hasAttemptedPromotionalLoad => _hasAttemptedPromotionalLoad;
  final Map<int, bool> _promotionalBannerLoadInProgress = {};
  final Map<int, DateTime> _promotionalContentLastLoadedAt = {};
  static const Duration _promotionalReloadCooldown = Duration(seconds: 12);
  bool _firstInstallCheckDone = false;
  static const String _firstLaunchMarkerKey = 'app_first_launch_marker_v2';
  static const String _legacyFirstLaunchMarkerKey =
      'splash_first_launch_marker_v1';

  BusinessSettings? _cachedBusinessSettings;
  BusinessSettings? get cachedBusinessSettings => _cachedBusinessSettings;

  @override
  void onInit() {
    super.onInit();

    // 🔍 DIAGNOSTIC LOG: Confirm onInit is called
    if (kDebugMode) {
      debugPrint(
          '🧠 SplashController.onInit() CALLED - Setting up module selection listener');
    }

    // 🔥 PROMOTIONAL CONTENT: Deferred until after app-init completes and moduleList is populated.
    // Previously fired as microtask in onInit, racing against CachedSplashLoader and causing
    // duplicate API calls with empty headers.  Now triggered from _loadWithAppInit after modules arrive.

    // 🔧 SAFETY: getModules() removed from onInit — app-init endpoint already returns modules.
    // The duplicate call was racing with CachedSplashLoader.loadSplashData and hitting the API
    // before valid headers existed, causing wasted requests and main-thread contention.

    // 🔧 ARCHITECTURE FIX: Centralized module selection listener
    // This ensures banners and offers are loaded reactively when module is selected
    // Single listener prevents race conditions and duplicate API calls
    ever(selectedModule, (ModuleModel? module) {
      // 🔍 DIAGNOSTIC LOG: Confirm listener is triggered
      if (kDebugMode) {
        debugPrint(
            '🎯 selectedModule CHANGED -> ${module?.id} ${module?.moduleName ?? "null"}');
      }

      if (module == null) {
        if (kDebugMode) {
          debugPrint(
              '⏭️ SplashController.ever: Module is null - skipping promotional content load');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '⏭️ SplashController.ever: Module selected (id=${module.id}) - skipping promotional content refresh');
      }
    });

    if (kDebugMode) {
      debugPrint(
          '✅ SplashController.onInit() COMPLETED - Listener registered for selectedModule changes');
    }
  }

  /// Load promotional banners and offers for MultiModuleHomeScreen
  /// This loads content from Module 3 (eCommerce) to display on multi-module screen
  /// Can be called before module selection (promotional content) or after (reactive update)
  /// Uses loadAndCachePromotionalContent() which handles API calls and Controller updates

  ConfigModel? _configModel;
  ConfigModel? get configModel => _configModel;

  bool _firstTimeConnectionCheck = true;
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  ModuleModel? _module;
  // ⚠️ DEPRECATED: Use selectedModule.value instead
  // Kept for backward compatibility during migration
  // NOTE: Remove after full migration to Module-First architecture

  // 🔒 Module lock to prevent premature API calls before headers are ready
  bool _isModuleLocked = false;
  bool get isModuleLocked => _isModuleLocked;

  ModuleModel? _cacheModule;
  ModuleModel? get cacheModule => _cacheModule;

  List<ModuleModel>? _moduleList;
  List<ModuleModel>? get moduleList => _moduleList;

  int _moduleIndex = 0;
  int get moduleIndex => _moduleIndex;

  Map<String, dynamic>? _data = {};
  Map<String, dynamic>? get rawConfigData => _data;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🔧 CRITICAL FIX: Guard clause to prevent infinite config recursion
  bool _isLoadingConfig = false;
  bool get isLoadingConfig => _isLoadingConfig;

  bool _homeDataPreLoaded = false;
  bool get homeDataPreLoaded => _homeDataPreLoaded;

  int _selectedModuleIndex = 0;
  int get selectedModuleIndex => _selectedModuleIndex;

  LandingModel? _landingModel;
  LandingModel? get landingModel => _landingModel;

  bool _savedCookiesData = false;
  bool get savedCookiesData => _savedCookiesData;

  bool _webSuggestedLocation = false;
  bool get webSuggestedLocation => _webSuggestedLocation;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _showReferBottomSheet = false;
  bool get showReferBottomSheet => _showReferBottomSheet;

  // ⚡ MODULE SWITCHING: Track module switch state for shimmer display
  bool _isModuleSwitching = false;
  bool get isModuleSwitching => _isModuleSwitching;
  DateTime? _lastModuleSwitchAt;
  static const Duration _moduleSwitchDebounce = Duration(milliseconds: 500);

  bool _isStartupModulePreloadRunning = false;
  final Set<int> _startupPreloadedModuleIds = <int>{};
  bool _isSplashFlowActive = false;
  bool _isSplashCacheReady = false;
  bool _isFirstNavigationReleased = false;

  // 🏗️ MODULE-FIRST ARCHITECTURE: Single Source of Truth
  // This is the ONLY source of module selection state in the application
  // No route, memory, or UI should determine module - only this Rx variable
  final Rx<ModuleModel?> selectedModule = Rx<ModuleModel?>(null);

  // Computed getter for backward compatibility with existing code
  ModuleModel? get module => selectedModule.value;

  DateTime get currentTime => DateTime.now();

  bool get isSplashFlowActive => _isSplashFlowActive;
  bool get isSplashCacheReady => _isSplashCacheReady;
  bool get isFirstNavigationReleased => _isFirstNavigationReleased;

  void markSplashFlowActive() {
    _isSplashFlowActive = true;
    _isSplashCacheReady = false;
    _isFirstNavigationReleased = false;
    if (kDebugMode) {
      debugPrint('🧭 SplashController: splash flow marked ACTIVE');
    }
  }

  void markSplashFlowStopped() {
    _isSplashFlowActive = false;
    if (kDebugMode) {
      debugPrint('🧭 SplashController: splash flow marked STOPPED');
    }
  }

  void markSplashReadyFromCache() {
    _isSplashCacheReady = true;
    if (kDebugMode) {
      debugPrint('✅ SplashController: Splash ready from cache');
    }
  }

  void markFirstNavigationReleased() {
    _isFirstNavigationReleased = true;
    if (kDebugMode) {
      debugPrint('✅ SplashController: First navigation released');
    }
  }

  /// ✅ Check if splash data is ready (config and modules loaded)
  bool get isReady {
    return _configModel != null &&
        _moduleList != null &&
        _moduleList!.isNotEmpty &&
        !_isLoadingConfig;
  }

  bool _hasStartupLocationHeadersReady() {
    final address = AddressHelper.getUserAddressFromSharedPref();
    final hasZone = address?.zoneIds != null && address!.zoneIds!.isNotEmpty;
    final hasLat = (address?.latitude ?? '').trim().isNotEmpty;
    final hasLng = (address?.longitude ?? '').trim().isNotEmpty;
    return hasZone && hasLat && hasLng;
  }

  /// 🔧 FIX 5: Get default moduleId for API calls when no module is selected
  /// This is used for guest/new user initial load to prevent empty headers
  /// Returns module 3 (eCommerce) as default, or first available module
  int? getDefaultModuleId() {
    // Return selected module if available
    if (selectedModule.value?.id != null) {
      return selectedModule.value!.id;
    }

    // Return module 3 if available (eCommerce - common default)
    if (_moduleList != null && _moduleList!.any((m) => m.id == 3)) {
      return 3;
    }

    // Return first available module
    if (_moduleList != null &&
        _moduleList!.isNotEmpty &&
        _moduleList!.first.id != null) {
      return _moduleList!.first.id;
    }

    return null;
  }

  /// ✅ Wait until splash data is ready (with timeout)
  /// ⚡ PERF FIX: Uses exponential back-off instead of fixed 100ms polling
  /// to avoid burning frames on the main thread during startup.
  Future<void> waitUntilReady(
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (isReady) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    int delayMs = 50; // start at 50ms, back off to 400ms max
    while (!isReady) {
      if (stopwatch.elapsed > timeout) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Timeout waiting for data to be ready');
        }
        break;
      }
      await Future.delayed(Duration(milliseconds: delayMs));
      if (delayMs < 400) delayMs = (delayMs * 1.5).round();
    }
  }

  ConfigModel _buildFallbackConfig() {
    final fallbackModule = ModuleModel(
      id: 3,
      moduleName: 'Default Module',
      moduleType: 'ecommerce',
      themeId: 1,
      storesCount: 0,
    );

    return ConfigModel(
      businessName: 'Default',
      defaultLocation: DefaultLocation(lat: '0', lng: '0'),
      currencySymbol: 'SAR',
      currencySymbolDirection: 'right',
      appMinimumVersionAndroid: 0.0,
      appMinimumVersionIos: 0.0,
      customerVerification: false,
      scheduleOrder: true,
      orderDeliveryVerification: false,
      cashOnDelivery: true,
      digitalPayment: true,
      demo: false,
      maintenanceMode: false,
      loyaltyPointStatus: 0,
      customerWalletStatus: 0,
      refEarningStatus: 0,
      dmTipsStatus: 0,
      toggleDmRegistration: false,
      toggleStoreRegistration: false,
      toggleVegNonVeg: false,
      scheduleOrderSlotDuration: 30,
      digitAfterDecimalPoint: 2,
      module: fallbackModule,
      moduleConfig: ModuleConfig(
        moduleType: ['ecommerce'],
        module: Module(
          orderPlaceToScheduleInterval: 0,
          addOn: true,
          stock: true,
          vegNonVeg: false,
          unit: true,
          orderAttachment: false,
          showRestaurantText: false,
          isParcel: false,
          isTaxi: false,
          newVariation: false,
          description: 'Fallback module config',
        ),
      ),
      additionalChargeStatus: false,
      additionCharge: 0.0,
    );
  }

  /// Apply fallback config to prevent stuck splash when API/cache both fail
  void applyFallbackConfig({String? reason}) {
    _applyFallbackConfig(reason: reason);
  }

  void _applyFallbackConfig({String? reason}) {
    if (_configModel != null) {
      return;
    }

    final fallbackConfig = _buildFallbackConfig();
    _configModel = fallbackConfig;
    _data = fallbackConfig.toJson();

    // Do NOT override module list with a single fallback module.
    // Module list should come from cache or modules API.
    update(['moduleList']);

    // If modules are still missing, try loading them asynchronously.
    if (_moduleList == null || _moduleList!.isEmpty) {
      Future.microtask(() async {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: moduleList still empty after fallback - fetching modules from API');
        }
        try {
          await getModules(dataSource: DataSourceEnum.client);
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ SplashController: Failed to fetch modules after fallback: $e');
          }
        }
      });
    }

    if (kDebugMode) {
      debugPrint(
          '⚠️ SplashController: Applied fallback ConfigModel${reason != null ? " ($reason)" : ""}');
    }
  }

  Module _buildDefaultModuleConfig(String? moduleType) {
    final String? normalizedType = moduleType?.toLowerCase();
    final bool isFood = normalizedType == AppConstants.food;
    final bool isParcel = normalizedType == AppConstants.parcel;
    final bool isTaxi = normalizedType == AppConstants.taxi;

    return Module(
      orderPlaceToScheduleInterval: 0,
      addOn: true,
      stock: true,
      vegNonVeg: isFood ? true : false,
      unit: true,
      orderAttachment: true,
      showRestaurantText: isFood ? true : false,
      isParcel: isParcel,
      isTaxi: isTaxi,
      newVariation: isFood ? true : false,
      description: 'Fallback module config (${moduleType ?? "unknown"})',
    );
  }

  void selectModuleIndex(int index) {
    _selectedModuleIndex = index;
    update();
  }

  /// 🏗️ MODULE-FIRST ARCHITECTURE: Resolve initial module selection
  /// This method determines which module should be selected based on:
  /// 1. Cached module (last user selection)
  /// 2. Single module (auto-select)
  /// 3. Multiple modules (user must choose)
  ///
  /// Returns true if module is resolved, false if user selection is required
  Future<bool> resolveInitialModule(List<ModuleModel> modules) async {
    if (modules.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ SplashController.resolveInitialModule: No modules available');
      }
      selectedModule.value = null;
      return false;
    }

    // Step 1: Check for cached module (last user selection)
    final cachedModuleId = await HiveHomeCacheService.getLastSelectedModuleId();
    if (cachedModuleId != null) {
      final cachedModule =
          modules.firstWhereOrNull((m) => m.id == cachedModuleId);
      if (cachedModule != null) {
        selectedModule.value = cachedModule;
        if (kDebugMode) {
          debugPrint(
              '✅ SplashController.resolveInitialModule: Using cached module (id=${cachedModule.id}, name=${cachedModule.moduleName})');
        }
        // Sync with legacy _module for backward compatibility
        _module = cachedModule;

        // 🔥 MODULE-READY TRIGGER: Notify HomeUnifiedController that module is ready
        if (cachedModule.id != null &&
            Get.isRegistered<HomeUnifiedController>()) {
          try {
            final homeUnifiedController = Get.find<HomeUnifiedController>();
            homeUnifiedController.onModuleReady(cachedModule.id!);
            if (kDebugMode) {
              debugPrint(
                  '🎯 SplashController.resolveInitialModule: Triggered onModuleReady for cached module ${cachedModule.id}');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ SplashController.resolveInitialModule: Error triggering onModuleReady: $e');
            }
          }
        }

        return true;
      }
    }

    // Step 2: Auto-select if single module
    if (modules.length == 1) {
      selectedModule.value = modules.first;
      if (kDebugMode) {
        debugPrint(
            '✅ SplashController.resolveInitialModule: Auto-selected single module (id=${modules.first.id}, name=${modules.first.moduleName})');
      }
      // Sync with legacy _module for backward compatibility
      _module = modules.first;

      // 🔥 MODULE-READY TRIGGER: Notify HomeUnifiedController that module is ready
      if (modules.first.id != null &&
          Get.isRegistered<HomeUnifiedController>()) {
        try {
          final homeUnifiedController = Get.find<HomeUnifiedController>();
          homeUnifiedController.onModuleReady(modules.first.id!);
          if (kDebugMode) {
            debugPrint(
                '🎯 SplashController.resolveInitialModule: Triggered onModuleReady for auto-selected module ${modules.first.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ SplashController.resolveInitialModule: Error triggering onModuleReady: $e');
          }
        }
      }

      return true;
    }

    // Step 3: Multiple modules - user must choose
    // 🔒 BOOTSTRAP PROTECTION: Don't clear selectedModule if it's already set
    // Only set to null if there's no cached module and multiple modules exist
    if (selectedModule.value == null) {
      selectedModule.value = null;
      if (kDebugMode) {
        debugPrint(
            '🔄 SplashController.resolveInitialModule: Multiple modules available - user selection required');
      }
    } else {
      // Module already selected (from previous session) - keep it
      if (kDebugMode) {
        debugPrint(
            '✅ SplashController.resolveInitialModule: Module already selected (id=${selectedModule.value?.id}) - keeping it');
      }
      return true;
    }
    return false;
  }

  /// 🏗️ MODULE-FIRST ARCHITECTURE: Select module (with persistence)
  /// This method should be called when user explicitly selects a module
  /// 🏗️ MODULE-FIRST ARCHITECTURE: Simple module selection method
  /// This method ONLY updates the module state and navigates to Dashboard
  /// No cleanup, no API calls, no heavy operations
  /// This ensures clean separation of concerns: UI selects, architecture navigates
  ///
  /// 🔁 USER INTENT RESPECT: Same module tap forces refresh and re-navigation
  Future<void> selectModule(ModuleModel module, {BuildContext? context}) async {
    // 🔍 DIAGNOSTIC LOG: Confirm selectModule is called
    if (kDebugMode) {
      debugPrint(
          '✅ selectModule CALLED -> id=${module.id} name=${module.moduleName}');
      debugPrint(
          '   Current selectedModule.value: ${selectedModule.value?.id} ${selectedModule.value?.moduleName ?? "null"}');
    }

    if (_isModuleSwitching) {
      if (kDebugMode) {
        debugPrint(
            '🚫 SplashController.selectModule: Module switch in progress - ignoring new selection');
      }
      return;
    }
    final now = DateTime.now();
    if (_lastModuleSwitchAt != null &&
        now.difference(_lastModuleSwitchAt!) < _moduleSwitchDebounce) {
      if (kDebugMode) {
        debugPrint(
            '⏳ SplashController.selectModule: Debounced rapid module tap');
      }
      return;
    }
    _lastModuleSwitchAt = now;

    final isSameModule = selectedModule.value?.id == module.id;

    if (isSameModule) {
      if (kDebugMode) {
        debugPrint(
            'SplashController.selectModule: Same module tapped (id=${module.id}) - forcing refresh');
      }

      // Force reactive rebuild for same module selection
      selectedModule.value = module;
      selectedModule.refresh();
      _module = module;

      if (module.id != null && Get.isRegistered<HomeUnifiedController>()) {
        try {
          final homeUnifiedController = Get.find<HomeUnifiedController>();
          homeUnifiedController.allowImmediateFetchForModule(module.id!);
          await homeUnifiedController.onModuleReady(module.id!);
          if (kDebugMode) {
            debugPrint(
                'SplashController.selectModule: onModuleReady re-triggered for module ${module.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'SplashController.selectModule: Error re-triggering onModuleReady: $e');
          }
        }
      }

      if (context != null) {
        final int? targetModuleId = module.id;
        if (targetModuleId != null) {
          Get.offAllNamed(
            RouteHelper.getModuleHomeRoute(targetModuleId),
            arguments: {
              'module_id': targetModuleId,
              'prev_module_id': selectedModule.value?.id,
              'skip_splash': true,
              'same_module': true,
            },
          );
          unawaited(_triggerSoftRefreshAfterModuleSwitch(targetModuleId));
        } else {
          Get.offAllNamed(RouteHelper.main, arguments: {
            'module_id': module.id,
            'prev_module_id': selectedModule.value?.id,
            'skip_splash': true,
            'same_module': true,
          });
        }
      }
      return;
    }

    final ModuleModel? previousModule = selectedModule.value;
    if (kDebugMode) {
      debugPrint(
          '[HOME_MODULE_SWITCH] from=${previousModule?.id} to=${module.id}');
    }
    if (previousModule?.id != null &&
        previousModule!.id != module.id &&
        Get.isRegistered<BannerController>()) {
      Get.find<BannerController>().invalidateModule(previousModule.id!);
      if (kDebugMode) {
        debugPrint(
            'SplashController.selectModule: Cleared banner cache for old module ${previousModule.id}');
      }
    }

    // ⚡ MODULE SWITCH: set switching state immediately (for shimmer)
    _isModuleSwitching = true;
    update(['moduleList']);
    _isModuleLocked = false;
    LoadingStateManager().startHomeLoading(force: true);

    try {
      // HomeScreen._hasLoadedOnce resets automatically via ValueKey:
      // ModuleHomeRouterScreen(key: ValueKey('module_home_$id')) creates a
      // fresh widget tree on each module switch, so initState starts clean.

      // CACHE-FIRST: Pre-load new module's Hive data into memory BEFORE resetting
      // controller state. prepareForModuleSwitch() never clears _moduleDataCache,
      // so this data survives the reset. When onModuleReady -> loadHomeData runs
      // after navigation it hits the memory-cache path (0ms) and renders instantly
      // instead of showing a loading shimmer while the API call completes.
      bool cacheHitForNewModule = false;
      if (module.id != null && Get.isRegistered<HomeUnifiedController>()) {
        cacheHitForNewModule =
            await Get.find<HomeUnifiedController>().applyFromCache(module.id!);
      }

      // ⚡ GENERATION ID: Prepare HomeUnifiedController for module switch
      if (Get.isRegistered<HomeUnifiedController>()) {
        final homeUnifiedController = Get.find<HomeUnifiedController>();
        homeUnifiedController.forceResetLoadingState();
        homeUnifiedController.prepareForModuleSwitch();
        if (module.id != null) {
          homeUnifiedController.allowImmediateFetchForModule(module.id!);
        }
        // CACHE-MISS FIX: When no cache exists, pre-set _isLoading=true and wipe
        // stale child-controller data so the very first frame of the new screen
        // shows a clean shimmer instead of the previous module's data.
        if (!cacheHitForNewModule) {
          homeUnifiedController.prepareForCacheMissSwitch();
        }
      }

      // ⚡ Ensure zone/module headers are updated before any new API calls
      // resetHeaders() clears everything, so inject zone AFTER rebuilding headers
      Get.find<ApiClient>().resetHeaders();
      await setModuleHeaderOnly(module);
      await _injectLastKnownZoneFromHive(); // fallback if addressModel has no zoneIds
      if (Get.isRegistered<StoreController>()) {
        await Get.find<StoreController>().clearStoreData();
      }

      // 🏗️ MODULE-FIRST: Update Single Source of Truth (only if different module)
      if (kDebugMode) {
        debugPrint(
            '🔄 SplashController.selectModule: Updating selectedModule.value from ${selectedModule.value?.id} to ${module.id}');
      }
      selectedModule.value = module;

      // 🔍 DIAGNOSTIC LOG: Confirm selectedModule.value was updated
      if (kDebugMode) {
        debugPrint(
            '✅ SplashController.selectModule: selectedModule.value updated -> ${selectedModule.value?.id} ${selectedModule.value?.moduleName}');
      }

      // Sync with legacy _module for backward compatibility
      _module = module;

      // Persist selection for next app launch
      if (module.id != null) {
        await HiveHomeCacheService.saveLastSelectedModuleId(module.id!);
      }

      if (kDebugMode) {
        debugPrint(
            '✅ SplashController.selectModule: Module selected (id=${module.id}, name=${module.moduleName})');
      }

      // 🏗️ MODULE-FIRST: Open a new DashboardScreen for this module (keep back stack)
      if (module.id != null) {
        Get.offAllNamed(
          RouteHelper.getModuleHomeRoute(module.id!),
          arguments: {
            'module_id': module.id,
            'prev_module_id': previousModule?.id,
            'skip_splash': true,
          },
        );
        unawaited(_triggerSoftRefreshAfterModuleSwitch(module.id!));
      } else {
        Get.offAllNamed(RouteHelper.main, arguments: {
          'module_id': module.id,
          'prev_module_id': previousModule?.id,
          'skip_splash': true,
        });
      }

      // Data loading is owned by the widget lifecycle - no manual call needed here.
      // Flow: Get.offAllNamed -> new DashboardScreen -> _buildHomeRoot() Obx ->
      //   ModuleHomeRouterScreen(key: ValueKey('module_home_$id')) ->
      //   ModuleHomeScreenBase.initState -> _ensureModuleReady -> onModuleReady.
      // A manual onModuleReady() here was a 3rd duplicate that only the
      // _isFetching guard was silently swallowing.
    } finally {
      _isModuleSwitching = false;
      update(['moduleList']);
      LoadingStateManager().completeHomeLoading();
      if (kDebugMode) {
        debugPrint(
            '✅ SplashController.selectModule: Module switching state reset');
      }
    }
  }

  /// Runs a light post-navigation refresh so module switch behaves like manual pull-to-refresh.
  Future<void> _triggerSoftRefreshAfterModuleSwitch(int moduleId) async {
    // Let navigation and first frame settle first for smoother UX.
    await Future.delayed(const Duration(milliseconds: 350));
    try {
      if (AppConstants.useBffV2Endpoint &&
          Get.isRegistered<HomeUnifiedController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        unifiedController.allowImmediateFetchForModule(moduleId);
        final bool success = await unifiedController.loadHomeData(
          forceRefresh: true,
          showLoading: false,
        );
        if (!success && Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().loadHomeData(forceRefresh: true);
        }
        return;
      }
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().loadHomeData(forceRefresh: true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ SplashController: soft refresh after module switch failed: $e');
      }
    }
  }

  Future<void> getConfigData(BuildContext context,
      {NotificationBodyModel? notificationBody,
      bool loadModuleData = false,
      bool loadLandingData = false,
      DataSourceEnum source = DataSourceEnum.local,
      bool fromMainFunction = false,
      bool fromDemoReset = false,
      bool shouldRoute = true}) async {
    // ⚡ PERFORMANCE: Start timing for config loading
    final configStartTime = DateTime.now();
    appLogger.info(
        '⏱️ PERFORMANCE: getConfigData() started at ${configStartTime.millisecondsSinceEpoch}ms');

    // 🔧 CRITICAL FIX: Guard clause to prevent infinite config recursion
    // If already loading config, skip to prevent duplicate API calls
    if (_isLoadingConfig) {
      if (kDebugMode) {
        debugPrint(
            '🚫 SplashController.getConfigData: Already loading config - skipping duplicate call');
      }
      return;
    }
    _isLoadingConfig = true;

    _hasConnection = true;
    _moduleIndex = 0;

    // Always use app-init endpoint for client requests (mandatory)
    if (source == DataSourceEnum.client) {
      if (kDebugMode) {
        debugPrint('🚀 SplashController: Using app-init endpoint');
      }

      await _loadWithAppInit(context, notificationBody, loadModuleData,
          loadLandingData, fromMainFunction, fromDemoReset, shouldRoute);
    } else {
      // Legacy flow - only for local cache access (DataSourceEnum.local)
      if (kDebugMode) {
        debugPrint('📦 SplashController: Loading from local cache');
      }

      Response response;
      if (source == DataSourceEnum.local && !fromDemoReset) {
        response = await splashServiceInterface.getConfigData(
            source: DataSourceEnum.local);
        // 🔧 Reset guard clause after local load
        _isLoadingConfig = false;
        if (!context.mounted) {
          return;
        }
        _handleConfigResponse(
            context,
            response,
            loadModuleData,
            loadLandingData,
            fromMainFunction,
            fromDemoReset,
            notificationBody,
            shouldRoute);
        // Note: Recursive call to getConfigData will set _isLoadingConfig again
        if (!context.mounted) {
          return;
        }
        getConfigData(context,
            loadModuleData: loadModuleData,
            loadLandingData: loadLandingData,
            source: DataSourceEnum.client,
            shouldRoute: shouldRoute);
      } else {
        response = await splashServiceInterface.getConfigData(
            source: DataSourceEnum.client);
        // 🔧 Reset guard clause after client load
        _isLoadingConfig = false;
        if (!context.mounted) {
          return;
        }
        _handleConfigResponse(
            context,
            response,
            loadModuleData,
            loadLandingData,
            fromMainFunction,
            fromDemoReset,
            notificationBody,
            shouldRoute);
      }
    }
  }

  /// Load all startup data using app-init endpoint (mandatory)
  /// Consolidates config, modules, zones, and business settings into a single API call
  /// ⚡ OPTIMIZATION: Parallel loading - app-init and home-unified load simultaneously
  /// ⚡ DIRECTIVE 2: skipAppInit parameter physically blocks app-init call during module switching
  Future<void> _loadWithAppInit(
      BuildContext context,
      NotificationBodyModel? notificationBody,
      bool loadModuleData,
      bool loadLandingData,
      bool fromMainFunction,
      bool fromDemoReset,
      bool shouldRoute,
      {bool skipAppInit = false}) async {
    // ⚡ DIRECTIVE 2: Physical app-init blockade
    // If skipAppInit is true, return early before app-init call
    // This guarantees no redundant app-init during module switching
    if (skipAppInit) {
      if (kDebugMode) {
        debugPrint(
            '⚡ SplashController._loadWithAppInit: App-init BLOCKED (skipAppInit=true) - module switch in progress');
      }
      return;
    }

    await _runFirstInstallCacheInvalidationIfNeeded();

    // 🔧 FIX: If cache is valid and BOTH configModel AND moduleList exist, skip app-init API call
    // This prevents redundant API calls when cache is already loaded
    if (!fromMainFunction && !fromDemoReset) {
      try {
        final cacheValid = await SplashCacheManager.isSplashCacheValid();
        if (cacheValid &&
            _configModel != null &&
            _moduleList != null &&
            _moduleList!.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
                '⚡ SplashController._loadWithAppInit: Cache valid and data exists (configModel + moduleList) - skipping app-init API call');
            debugPrint('   - App-init will refresh in background if needed');
          }
          // 🔧 FIX: Reset _isLoadingConfig before early return to prevent isReady from staying false
          _isLoadingConfig = false;
          // Background refresh will happen via CachedSplashLoader._refreshInBackground
          return;
        } else if (kDebugMode && cacheValid && _configModel != null) {
          debugPrint(
              '⚠️ SplashController._loadWithAppInit: Cache valid but moduleList missing - proceeding with API call');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController._loadWithAppInit: Error checking cache validity: $e');
        }
        // Continue with API call if cache check fails
      }
    }

    try {
      // 🚫 REMOVED: Hive box pre-opening from _loadWithAppInit
      // ⚡ OPTIMIZATION: Hive boxes will open lazily on first use
      // Only app_config box is opened in initSharedData for routing decision
      if (kDebugMode) {
        debugPrint(
            '⚡ SplashController: Hive box pre-opening skipped - boxes will open on first use');
      }

      final appInitService = AppInitService(apiClient: Get.find<ApiClient>());
      final apiClient = Get.find<ApiClient>();

      if (kDebugMode) {
        debugPrint(
            '📡 SplashController: Starting parallel loading (app-init + home-unified)...');
        debugPrint(
            '🧭 SplashController: startup prerequisites=app-init config/modules; deferred=profile, notifications, banners');
        debugPrint('   ⚡ TASK 3: Core Four Endpoints:');
        debugPrint('      1. /api/v1/app-init (Config)');
        debugPrint('      2. /api/v2/home-unified (Home Content)');
        debugPrint(
            '      3. /api/v1/customer/info (User/Wallet Balance) - non-blocking');
        debugPrint(
            '      4. /api/v1/customer/notifications (Unread Signal) - non-blocking');
      }

      // 🔧 FIX: Ensure Atomic Module Header Update - update headers BEFORE parallel requests
      // This ensures the parallel request isn't blocked by ApiClient missing module context
      // CRITICAL: Set header first so pre-fetch request includes moduleId in headers
      if (kDebugMode) {
        debugPrint(
            '🔧 SplashController: Updating API client headers with moduleId=3 for pre-fetch...');
      }
      apiClient.updateHeader(
        apiClient.token, // token (preserve auth header if logged in)
        null, // zoneIDs
        null, // operationIds
        null, // languageCode
        3, // moduleID - eCommerce module for promotional content
        null, // latitude
        null, // longitude
      );

      if (kDebugMode) {
        debugPrint(
            '✅ SplashController: API client headers updated - pre-fetch will include moduleId=3');
      }

      // Defer global banners out of splash to keep startup deterministic.
      // Banner warm-up can run after first usable screen instead.
      final hasAddress = AddressHelper.getUserAddressFromSharedPref() != null;
      if (kDebugMode) {
        debugPrint(
            '⏭️ SplashController: Deferred global banner warm-up until post-splash');
      }

      // ⚡ TASK 2: Parallel loading - trigger both simultaneously
      final appInitFuture = appInitService.getAppInitData(
        headers: {
          ...HeaderHelper.featuredHeader(),
          'X-No-Retry': 'true',
          'X-Startup-Owner': 'splash',
        },
      );

      // 🔧 CRITICAL FIX: Check if this is a fresh install (no address)
      // If fresh install, defer home-unified pre-fetch until after location is selected
      // This prevents blocking navigation to Language/Onboarding screens

      // 🚫 REMOVED: Location fetching from SplashController
      // ⚡ OPTIMIZATION: Location refresh moved to Home screen postFrameCallback
      // Use last known location or default for routing decision
      // Location will be refreshed silently after Home screen appears
      if (kDebugMode) {
        debugPrint(
            '⚡ SplashController: Location fetching skipped - using last known/default location for routing');
      }

      // 🚫 REMOVED: Heavy API prefetch (home-unified) from SplashController
      // ⚡ OPTIMIZATION: Home-unified prefetch moved to MultiModuleHomeScreen.postFrameCallback
      // Bug#1 FIX: homeUnifiedFuture = Future.value(false) removed.
      // Prefetch now starts AFTER app-init so the correct module ID is known.
      // It runs non-blocking (unawaited) so routing is not delayed.

      // 🚫 REMOVED: Wallet pre-fetch - must load lazily when user navigates to wallet screen
      // ⚡ TASK 3: Pre-load user profile data during splash (non-blocking)
      // This ensures ProfileController.userInfoModel is populated BEFORE Menu screen appears
      // Core Endpoint #3: /api/v1/customer/info (User/Wallet Balance)
      if (kDebugMode) {
        debugPrint(
            '⏭️ SplashController: Deferred /api/v1/customer/info until post-splash (not part of splash prerequisites)');
      }

      // ⚡ TASK 3: Pre-load notifications during splash (non-blocking)
      // Core Endpoint #4: /api/v1/customer/notifications (Unread Signal)
      if (kDebugMode) {
        debugPrint(
            '⏭️ SplashController: Deferred /api/v1/customer/notifications until post-splash (not part of splash prerequisites)');
      }

      // Bug#1 FIX: Always await app-init first so _moduleList is populated.
      // Then trigger home-unified prefetch non-blockingly with the correct module.
      final appInitData = await appInitFuture;
      if (!_isSplashFlowActive) {
        if (kDebugMode) {
          debugPrint(
              '🧹 SplashController: Splash flow no longer active after app-init await - skipping splash-owned follow-up tasks');
        }
        return;
      }
      // Determine best module now that _moduleList is populated after app-init.
      int? prefetchModuleId;
      final ModuleModel? selected = selectedModule.value ?? _module;
      if (selected != null && selected.id != null) {
        prefetchModuleId = selected.id;
      } else if (_moduleList != null && _moduleList!.length == 1) {
        prefetchModuleId = _moduleList!.first.id;
      } else if (kDebugMode) {
        debugPrint(
            '⏭️ SplashController: Skipping home-unified prefetch - module unresolved (multi-module flow)');
      }
      if (prefetchModuleId != null &&
          Get.isRegistered<HomeUnifiedController>() &&
          hasAddress) {
        // Ensure headers carry the right module before the prefetch call.
        apiClient.updateHeader(
          apiClient.token,
          null,
          null,
          null,
          prefetchModuleId,
          null,
          null,
        );
        unawaited(
          Get.find<HomeUnifiedController>()
              .preloadModuleDataForSplash(prefetchModuleId)
              .catchError((Object e) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ SplashController: home-unified prefetch error (non-blocking): $e');
            }
            return false;
          }),
        );
        if (kDebugMode) {
          debugPrint(
              '⚡ SplashController: home-unified prefetch started for module '
              '$prefetchModuleId (background, non-blocking)');
        }
      } else if (kDebugMode && prefetchModuleId != null && !hasAddress) {
        debugPrint(
            '⚡ SplashController: Skipping home-unified prefetch — no address/zone headers yet (fresh install)');
      }

      if (kDebugMode) {
        debugPrint('✅ SplashController: App-init completed');
        final appInitStatus = appInitData != null
            ? 'ok (200)'
            : (_configModel != null ? 'FROM_CACHE (304)' : 'error');
        debugPrint('   - App-init: $appInitStatus');
        if (prefetchModuleId != null && hasAddress) {
          debugPrint(
              '   - Home-unified: STARTED in background for module $prefetchModuleId');
        } else if (prefetchModuleId == null) {
          debugPrint(
              '   - Home-unified: SKIPPED (module unresolved during startup)');
        } else {
          debugPrint(
              '   - Home-unified: SKIPPED (zone/location headers not ready)');
        }
        // 🚫 REMOVED: Wallet and User Profile logging - no longer pre-fetched during splash

        // 🚫 REMOVED: Wallet verification - no longer pre-fetched during splash
      }

      // 🚫 REMOVED: Image pre-warming from SplashController
      // ⚡ OPTIMIZATION: Image warming moved to MultiModuleHomeScreen.postFrameCallback
      // This ensures first frame renders faster (300-500ms target)
      // Images will be warmed 1-2 seconds after Home screen appears
      if (kDebugMode) {
        debugPrint(
            '⚡ SplashController: Image pre-warming skipped - will happen after first frame in Home screen');
      }

      if (appInitData != null) {
        if (kDebugMode) {
          debugPrint('✅ SplashController: App-init data received successfully');
          debugPrint('   - Config: ${appInitData.config != null ? "✓" : "✗"}');
          debugPrint('   - Modules: ${appInitData.modules?.length ?? 0}');
          debugPrint('   - Zones: ${appInitData.zones?.length ?? 0}');
          debugPrint('   - User Zone ID: ${appInitData.userZoneId}');
          debugPrint(
              '   - Business Settings: ${appInitData.businessSettings != null ? "✓" : "✗"}');
        }

        // Store all the data
        _configModel = appInitData.config;
        _data = appInitData.config?.toJson();
        _moduleList = appInitData.modules;
        if (kDebugMode) {
          debugPrint(
              '🧭 SplashController: app-init hydration done; readyToExit=${_configModel != null && (_moduleList?.isNotEmpty ?? false)}');
        }
        // Promotional content preloading is intentionally deferred out of splash.
        // MultiModuleHomeScreen can load this after splash route transition.

        // Extract business settings from app-init and set in HomeController
        if (appInitData.businessSettings != null) {
          _cachedBusinessSettings = appInitData.businessSettings;
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>()
                .setBusinessSettingsFromAppInit(appInitData.businessSettings!);
            if (kDebugMode) {
              debugPrint(
                  '💾 SplashController: Business settings extracted from app-init and set in HomeController');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ SplashController: HomeController not registered yet, business settings will be set when HomeController is available');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint(
                '⚠️ SplashController: Business settings not available in app-init response');
          }
        }

        // 🔧 Reset guard clause on success
        _isLoadingConfig = false;

        // ⚡ PERFORMANCE: Only update moduleList listeners, not entire UI
        // This prevents flickering in MultiModuleHomeScreen when config/business_settings finish
        update(['moduleList']);

        // Store zone ID if provided
        if (appInitData.userZoneId != null) {
          // NOTE: Store zone ID in shared preferences
          if (kDebugMode) {
            debugPrint(
                '💾 SplashController: Zone ID ${appInitData.userZoneId} from app-init');
          }
        }

        // ⚡ TASK 3: Store app-init data in Hive app_config box (migrated from SharedPreferences)
        final cacheService = HiveHomeCacheService();
        await cacheService.saveAppInitData(appInitData);

        if (kDebugMode) {
          debugPrint(
              '💾 SplashController: App-init data cached in Hive app_config box');
        }

        // ⚡ TASK 2: Do NOT await setModule() or getLandingPageData() before routing
        // Route immediately to MultiModuleHomeScreen, let these run in background
        if (_configModel!.module != null) {
          setModule(_configModel!.module); // ✅ Non-blocking
        } else if (GetPlatform.isWeb || (loadModuleData && _module != null)) {
          setModule(GetPlatform.isWeb
              ? splashServiceInterface.getModule()
              : _module); // ✅ Non-blocking
        }

        // ⚡ TASK 2: Load landing data in background (non-blocking)
        if (loadLandingData) {
          getLandingPageData().catchError((e) {
            if (kDebugMode) {
              debugPrint('⚠️ SplashController: Error loading landing data: $e');
            }
          });
        }

        // ⚡ PERFORMANCE: Log routing decision timing
        final routeStartTime = DateTime.now();
        appLogger.info(
            '⏱️ PERFORMANCE: Routing decision started at ${routeStartTime.millisecondsSinceEpoch}ms');

        // 🔒 BOOTSTRAP PROTECTION: Mark bootstrap as complete after config is loaded
        _hasCompletedBootstrap = true;

        // ⚡ TASK 2: Route immediately without waiting for setModule/getLandingPageData
        if (fromMainFunction) {
          _mainConfigRouting();
        } else if (fromDemoReset) {
          // 🚫 FIX: Don't use Get.offAllNamed with route name - it opens DashboardScreen
          // Use route() function which handles MultiModuleHomeScreen correctly
          if (!context.mounted) {
            return;
          }
          route(context, body: notificationBody);
        } else if (shouldRoute) {
          if (!context.mounted) {
            return;
          }
          route(context, body: notificationBody); // ✅ Routes immediately
        }

        final routeEndTime = DateTime.now();
        final routeDuration =
            routeEndTime.difference(routeStartTime).inMilliseconds;
        appLogger.info(
            '⏱️ PERFORMANCE: Routing decision completed in ${routeDuration}ms');

        _onRemoveLoader();
      } else {
        // 🛠️ TASK 3: App-init returned null (could be 304 Not Modified, 500 error, or other error)
        // ⚡ CRITICAL FIX: MUST hydrate configModel from Hive - never leave it null
        if (kDebugMode) {
          debugPrint(
              '🔍 SplashController: App-init returned null - FORCING Hive hydration (304/500/error)...');
        }

        // ⚡ CRITICAL: Try loading from Hive app_config box FIRST (mandatory for 304)
        final cacheService = HiveHomeCacheService();
        final cachedAppInitData = await cacheService.loadAppInitData();

        if (cachedAppInitData != null && cachedAppInitData.config != null) {
          if (kDebugMode) {
            debugPrint(
                '✅ SplashController: 304 HYDRATION SUCCESS - Loaded ModuleModel from Hive app_config box');
            debugPrint(
                '   - Modules: ${cachedAppInitData.modules?.length ?? 0}');
            debugPrint('   - Zones: ${cachedAppInitData.zones?.length ?? 0}');
            debugPrint(
                '   - Config: ${cachedAppInitData.config != null ? "✓" : "✗"}');
            debugPrint(
                '   - ✅ configModel will NOT be null - recursion blocked');
          }

          // 🔧 CRITICAL: Hydrate from Hive cache - NEVER leave configModel null
          _configModel = cachedAppInitData.config;
          _data = cachedAppInitData.config?.toJson();
          _moduleList = cachedAppInitData.modules;
          if (cachedAppInitData.businessSettings != null) {
            _cachedBusinessSettings = cachedAppInitData.businessSettings;
            if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().setBusinessSettingsFromAppInit(
                  cachedAppInitData.businessSettings!);
            }
          }

          // 🔧 Reset guard clause on success
          _isLoadingConfig = false;

          // 🔧 FIX: If moduleList is still missing after Hive hydration, load from modules endpoint
          if (_moduleList == null || _moduleList!.isEmpty) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ SplashController: moduleList missing after Hive hydration - loading from modules endpoint');
            }
            try {
              await getModules(dataSource: DataSourceEnum.client);
              if (kDebugMode) {
                debugPrint(
                    '✅ SplashController: moduleList loaded successfully from fallback endpoint');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                    '❌ SplashController: Failed to load modules from fallback endpoint: $e');
              }
            }
          }

          // ⚡ PERFORMANCE: Only update moduleList listeners
          update(['moduleList']);

          if (kDebugMode) {
            debugPrint(
                '✅ SplashController: Successfully hydrated ModuleModel from Hive cache (304/500 fallback)');
          }
        } else if (_configModel != null) {
          // Fallback: Use in-memory cached config data
          if (kDebugMode) {
            debugPrint(
                '✅ SplashController: Using in-memory cached config data (no Hive cache available)');
            debugPrint('   - ✅ configModel already exists - recursion blocked');
          }
          // 🔧 Reset guard clause
          _isLoadingConfig = false;

          // 🔧 FIX: If moduleList is missing, try to load it from modules endpoint
          if (_moduleList == null || _moduleList!.isEmpty) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ SplashController: moduleList missing - loading from modules endpoint');
            }
            try {
              await getModules(dataSource: DataSourceEnum.client);
              if (kDebugMode) {
                debugPrint(
                    '✅ SplashController: moduleList loaded successfully from fallback endpoint');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                    '❌ SplashController: Failed to load modules from fallback endpoint: $e');
              }
            }
          }
        } else {
          // ⚡ ERROR UI: No cached data available - fall back to legacy calls silently
          // Don't show error dialog - let legacy flow handle it gracefully
          if (kDebugMode) {
            debugPrint(
                '⚠️ SplashController: No Hive cache found, falling back to legacy calls');
            debugPrint('   - ✅ No error dialog shown - graceful fallback');
          }

          // 🔧 Reset guard clause before legacy call to allow it to proceed
          _isLoadingConfig = false;

          // ✅ HARD SAFETY NET: Ensure configModel is not null before legacy call
          _applyFallbackConfig(reason: 'app-init null + no cache');

          final Response response = await splashServiceInterface.getConfigData(
              source: DataSourceEnum.client);
          if (!context.mounted) {
            return;
          }
          _handleConfigResponse(
              context,
              response,
              loadModuleData,
              loadLandingData,
              fromMainFunction,
              fromDemoReset,
              notificationBody,
              shouldRoute);
          return; // Exit early - legacy flow handles routing
        }

        // ⚡ TASK 2: Continue with cached data - route immediately
        if (loadLandingData) {
          getLandingPageData().catchError((e) {
            if (kDebugMode) {
              debugPrint('⚠️ SplashController: Error loading landing data: $e');
            }
          });
        }

        // 🔒 BOOTSTRAP PROTECTION: Mark bootstrap as complete after config is loaded
        _hasCompletedBootstrap = true;

        if (fromMainFunction) {
          _mainConfigRouting();
        } else if (fromDemoReset) {
          // 🚫 FIX: Don't use Get.offAllNamed with route name - it opens DashboardScreen
          // Use route() function which handles MultiModuleHomeScreen correctly
          if (!context.mounted) {
            return;
          }
          route(context, body: notificationBody);
        } else if (shouldRoute) {
          if (!context.mounted) {
            return;
          }
          route(context, body: notificationBody); // ✅ Routes immediately
        }

        _onRemoveLoader();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SplashController: Error in app-init: $e');
        debugPrint('   Stack trace: $stackTrace');
        debugPrint('⚠️ Falling back to legacy API calls');
      }

      // 🔧 Reset guard clause before legacy fallback
      _isLoadingConfig = false;

      // ✅ HARD SAFETY NET: Ensure configModel is not null before legacy call
      _applyFallbackConfig(reason: 'app-init exception');

      // Fall back to legacy calls on error
      final Response response = await splashServiceInterface.getConfigData(
          source: DataSourceEnum.client);
      if (!context.mounted) {
        return;
      }
      _handleConfigResponse(context, response, loadModuleData, loadLandingData,
          fromMainFunction, fromDemoReset, notificationBody, shouldRoute);
    }

    // 🔧 Final guard clause reset (in case of any other exit path)
    _isLoadingConfig = false;
    update();
  }

  Future<void> _runFirstInstallCacheInvalidationIfNeeded() async {
    if (_firstInstallCheckDone) {
      return;
    }
    _firstInstallCheckDone = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasLaunchedBefore =
          (prefs.getBool(_firstLaunchMarkerKey) ?? false) ||
              (prefs.getBool(_legacyFirstLaunchMarkerKey) ?? false);

      if (hasLaunchedBefore) {
        // Migrate from legacy marker key once and keep only the new key.
        if (!(prefs.getBool(_firstLaunchMarkerKey) ?? false)) {
          await prefs.setBool(_firstLaunchMarkerKey, true);
        }
        return;
      }

      await prefs.setBool(_firstLaunchMarkerKey, true);
      if (kDebugMode) {
        debugPrint(
            '🆕 SplashController: First launch detected - clearing stale caches');
      }
      await _clearAllStartupCaches();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ SplashController: First-launch cache check failed (continuing): $e');
      }
    }
  }

  Future<void> _clearAllStartupCaches() async {
    try {
      await HiveHomeCacheService().clearAllCache();
      await SplashCacheManager.clearSplashCache();
      await SmartCacheManager.clearCache();

      // Clear cached image files to prevent PathNotFoundException from
      // orphaned file references (OS/user cleared cache directory but
      // the image-cache DB still points at deleted files).
      try {
        await DefaultCacheManager().emptyCache();
      } catch (e) { if (kDebugMode) debugPrint('$e'); }

      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys().where((key) =>
          key.startsWith('home_unified_') ||
          key.startsWith('stores_') ||
          key.startsWith('categories_') ||
          (key.startsWith('splash_') && key != _firstLaunchMarkerKey) ||
          key.startsWith('home_cache_'));

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      if (kDebugMode) {
        debugPrint('✅ SplashController: Startup caches cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SplashController: Failed clearing startup caches: $e');
      }
    }
  }

  Future<bool> _preloadGlobalBannersAtStartup() async {
    if (!Get.isRegistered<BannerController>()) {
      return false;
    }
    try {
      await Get.find<BannerController>().preloadGlobalBannersAtStartup();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Warm critical modules in background while splash/onboarding is active.
  /// Non-blocking by design: it should never delay routing flow.
  Future<void> preloadCoreModulesForFastSwitch() async {
    if (_isStartupModulePreloadRunning) {
      return;
    }
    if (!Get.isRegistered<HomeUnifiedController>()) {
      return;
    }

    if (!_hasStartupLocationHeadersReady()) {
      if (kDebugMode) {
        debugPrint(
            '⏭️ SplashController: Skip core module preload - zone/location headers not ready');
      }
      return;
    }

    final modules = _moduleList;
    if (modules == null || modules.isEmpty) {
      return;
    }

    final Set<int> targetIds = <int>{};

    // Always prioritize currently selected module first if present.
    final selectedId = selectedModule.value?.id;
    if (selectedId != null && selectedId > 0) {
      targetIds.add(selectedId);
    }

    // Food modules = restaurants/cafes equivalents.
    for (final module in modules) {
      if (module.id != null &&
          module.id! > 0 &&
          module.moduleType == AppConstants.food) {
        targetIds.add(module.id!);
      }
    }

    // Hyper module (ecommerce) - prefer id=3 then fallback to first ecommerce.
    final hyperById = modules
        .firstWhereOrNull((module) => module.id == 3 && module.id != null);
    if (hyperById?.id != null) {
      targetIds.add(hyperById!.id!);
    } else {
      final firstEcommerce = modules.firstWhereOrNull((module) =>
          module.id != null &&
          module.id! > 0 &&
          module.moduleType == AppConstants.ecommerce);
      if (firstEcommerce?.id != null) {
        targetIds.add(firstEcommerce!.id!);
      }
    }

    // Prevent unnecessary heavy preloading.
    final List<int> idsToPreload = targetIds
        .where((id) => !_startupPreloadedModuleIds.contains(id))
        .take(4)
        .toList();

    if (idsToPreload.isEmpty) {
      return;
    }

    _isStartupModulePreloadRunning = true;
    if (kDebugMode) {
      debugPrint(
          '🚀 SplashController: Starting core module preload (post-splash): $idsToPreload');
    }

    try {
      // Keep global banners warm as part of startup preloading.
      await _preloadGlobalBannersAtStartup();

      final homeUnifiedController = Get.find<HomeUnifiedController>();
      final results = await Future.wait(
        idsToPreload.map(
          (id) => homeUnifiedController.preloadModuleDataForSplash(id),
        ),
      );

      for (int i = 0; i < idsToPreload.length; i++) {
        if (results[i]) {
          _startupPreloadedModuleIds.add(idsToPreload[i]);
        }
      }

      if (kDebugMode) {
        debugPrint(
            '✅ SplashController: Core module preload done. success=${results.where((r) => r).length}/${results.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ SplashController: Core module preload failed (non-blocking): $e');
      }
    } finally {
      _isStartupModulePreloadRunning = false;
    }
  }

  /// Pre-load user profile data during splash screen
  /// Only loads if userInfoModel is not already set (e.g., from login response)
  /// ⚡ TASK 3: Core Endpoint #3 - /api/v1/customer/info (User/Wallet Balance)

  /// Pre-load notifications during splash screen
  /// ⚡ TASK 3: Core Endpoint #4 - /api/v1/customer/notifications (Unread Signal)

  Future<void> _handleConfigResponse(
      BuildContext context,
      Response response,
      bool loadModuleData,
      bool loadLandingData,
      bool fromMainFunction,
      bool fromDemoReset,
      NotificationBodyModel? notificationBody,
      bool shouldRoute) async {
    if (response.statusCode == 200) {
      _data = response.body as Map<String, dynamic>?;
      _configModel =
          ConfigModel.fromJson(response.body as Map<String, dynamic>);

      // Set module immediately when config is loaded to prevent flash
      if (_configModel!.module != null) {
        await setModule(_configModel!.module);
      } else if (GetPlatform.isWeb || (loadModuleData && _module != null)) {
        await setModule(
            GetPlatform.isWeb ? splashServiceInterface.getModule() : _module);
      }

      if (loadLandingData) {
        await getLandingPageData();
      }
      if (!context.mounted) {
        return;
      }
      if (fromMainFunction) {
        _mainConfigRouting();
        // 🔧 FIX: On web, also call route() after _mainConfigRouting
        // because _mainConfigRouting doesn't route on web
        if (GetPlatform.isWeb && context.mounted) {
          if (kDebugMode) {
            debugPrint('🌐 Web: Calling route() after _mainConfigRouting');
          }
          route(context);
        }
      } else if (fromDemoReset) {
        // 🚫 FIX: Don't use Get.offAllNamed with route name - it opens DashboardScreen
        // Use route() function which handles MultiModuleHomeScreen correctly
        route(context, body: notificationBody);
      } else if (shouldRoute) {
        route(context, body: notificationBody);
      }
      _onRemoveLoader();
    } else {
      if (response.statusText == ApiClient.noInternetMessage) {
        // `noInternetMessage` is also returned for transient API failures
        // (timeouts / DNS / cold-start), not just a real offline device. Showing
        // NoInternetScreen on those makes the wifi screen flash briefly before
        // home loads. Only flip the flag when the device is GENUINELY offline.
        final List<ConnectivityResult> connectivity =
            await Connectivity().checkConnectivity();
        final bool reallyOffline = !(connectivity
                .contains(ConnectivityResult.wifi) ||
            connectivity.contains(ConnectivityResult.mobile) ||
            connectivity.contains(ConnectivityResult.ethernet) ||
            connectivity.contains(ConnectivityResult.vpn));
        _hasConnection = !reallyOffline;
      }
    }
    update();
  }

  Future<void> _mainConfigRouting() async {
    if (Get.find<AuthController>().isLoggedIn()) {
      Get.find<AuthController>().updateToken();
      if (Get.find<SplashController>().module != null) {
        // 🚫 REMOVED: getFavouriteList() - must load lazily in WishlistScreen only
        // This call was causing jank on home screens - wishlist should only load when user navigates to WishlistScreen
      }
    }
  }

  void _onRemoveLoader() {
    final preloader = html.document.querySelector('.preloader');
    if (preloader != null) {
      preloader.remove();
    }
  }

  Future<void> getLandingPageData(
      {DataSourceEnum source = DataSourceEnum.local}) async {
    LandingModel? landingModel;
    if (source == DataSourceEnum.local) {
      landingModel = await splashServiceInterface.getLandingPageData(
          source: DataSourceEnum.local);
      _prepareLandingModel(landingModel);
      getLandingPageData(source: DataSourceEnum.client);
    } else {
      landingModel = await splashServiceInterface.getLandingPageData(
          source: DataSourceEnum.client);
      _prepareLandingModel(landingModel);
    }
  }

  void _prepareLandingModel(LandingModel? landingModel) {
    if (landingModel != null) {
      _landingModel = landingModel;
      hoverStates = List<bool>.generate(
          _landingModel!.availableZoneList!.length, (index) => false);
    }
    update();
  }

  Future<void> initSharedData() async {
    // ⚡ OPTIMIZATION: Only open app_config box in Splash
    // Other boxes (promotional, home-unified) will open on first use
    // This reduces startup time significantly

    // 🔒 BOOTSTRAP PROTECTION: Don't set _module = null after bootstrap
    // Only set to null during initial bootstrap (before _hasCompletedBootstrap = true)
    if (!GetPlatform.isWeb) {
      // Only set to null if bootstrap hasn't completed yet
      if (!_hasCompletedBootstrap) {
        _module = null;
      }
      splashServiceInterface.initSharedData();
    } else {
      _module = await splashServiceInterface.initSharedData();
    }
    _cacheModule = splashServiceInterface.getCacheModule();
    // Only set module if it's not null (don't clear existing module after bootstrap)
    if (_module != null) {
      setModule(_module, notify: false);
    }

    // ⚡ OPTIMIZATION: Only validate cache, don't pre-open boxes
    // Boxes will open lazily when needed (first use)
    await _validateCache();

    if (kDebugMode) {
      debugPrint(
          '✅ SplashController: initSharedData completed - only app_config box opened, other boxes will open on first use');
    }
  }

  /// Validate cache and clear if version mismatch
  Future<void> _validateCache() async {
    try {
      final cacheInfo = await SmartCacheManager.getCacheInfo();
      debugPrint('📊 Cache Info: $cacheInfo');

      // If cache is invalid, it will be cleared automatically
      // when CachedDataLoader tries to load data
    } catch (e) {
      debugPrint('❌ Cache validation error: $e');
    }
  }

  void setCacheConfigModule(ModuleModel? cacheModule) {
    // ✅ FIX: Add null check to prevent crash
    if (_configModel != null &&
        _data != null &&
        _data!['module_config'] != null &&
        cacheModule != null) {
      final moduleConfig = _data!['module_config'] as Map<String, dynamic>;
      if (moduleConfig[cacheModule.moduleType] != null) {
        _configModel!.moduleConfig!.module = Module.fromJson(
            moduleConfig[cacheModule.moduleType] as Map<String, dynamic>);
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ setCacheConfigModule: Cannot set config - missing data');
      }
    }
  }

  bool? showIntro() {
    return splashServiceInterface.showIntro();
  }

  void disableIntro() {
    splashServiceInterface.disableIntro();
  }

  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  void setHomeDataPreLoaded(bool preLoaded) {
    _homeDataPreLoaded = preLoaded;
  }

  /// ⚡ DIRECTIVE 1: Standalone header injection method
  /// Updates ONLY ApiClient headers and local storage moduleId
  /// Does NOT trigger _mainConfigRouting, cart loading, or UI updates
  /// Used for fast module switching without full re-initialization
  Future<void> setModuleHeaderOnly(ModuleModel? module) async {
    if (module != null) {
      final apiClient = Get.find<ApiClient>();
      final addressModel = AddressHelper.getUserAddressFromSharedPref();
      final sharedPreferences = Get.find<SharedPreferences>();

      // Update ApiClient headers immediately
      apiClient.updateHeader(
        apiClient.token,
        addressModel?.zoneIds,
        addressModel?.areaIds,
        sharedPreferences.getString(AppConstants.languageCode),
        module.id, // ✅ Use new module ID
        addressModel?.latitude,
        addressModel?.longitude,
      );

      // Update local storage moduleId
      _module = module;
      await splashServiceInterface.setModule(module);
      _isModuleLocked = true;

      if (kDebugMode) {
        debugPrint(
            '⚡ SplashController.setModuleHeaderOnly: Updated headers and storage with moduleId=${module.id}');
        debugPrint(
            '🔒 SplashController.setModuleHeaderOnly: Module lock = true');
      }
    }
  }

  /// Update cacheModule only (used by CartController before cart fetch)
  Future<void> setCacheModuleOnly(ModuleModel? module) async {
    if (module == null) {
      return;
    }
    _cacheModule = await splashServiceInterface.setCacheModule(module);
  }

  // 🔒 BOOTSTRAP PROTECTION: Track if app has completed bootstrap
  // After bootstrap, module should never be set to null (except logout/clear data)
  bool _hasCompletedBootstrap = false;

  // ✅ FIX #2: Ensure module is ready before API calls
  // This prevents Slim Menu from being requested before module is set
  // 🔧 FIX 5: Also sets default moduleId in headers for guest/new users
  Future<void> ensureModuleReady() async {
    if (_module != null) {
      return; // Module already set
    }

    // Wait for module to be set (with timeout)
    final startTime = DateTime.now();
    while (_module == null) {
      if (DateTime.now().difference(startTime).inSeconds > 5) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Timeout waiting for module to be set');
        }
        break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (kDebugMode && _module != null) {
      debugPrint('✅ SplashController: Module ready (ID: ${_module!.id})');
    }

    // Bug#5 FIX: Do NOT write a default moduleId into the API headers when the
    // module is still null after timeout. Injecting module 3 (or any fallback)
    // here poisons the cache: subsequent loadHomeData() calls go out with the
    // wrong module-id, and the response gets stored under a module the user
    // never selected. Headers will be updated correctly by setModule() once
    // the user makes a real selection.
    if (_module == null && kDebugMode) {
      debugPrint(
          '⚠️ SplashController.ensureModuleReady: Timeout — module still null. '
          'Headers left unchanged to prevent cache poisoning.');
    }
  }

  Future<void> setModule(ModuleModel? module, {bool notify = true}) async {
    debugPrint('🟡 SplashController.setModule: Setting module');
    if (module != null) {
      debugPrint('   - Module ID: ${module.id}');
      debugPrint('   - Module Name: ${module.moduleName}');
      debugPrint('   - Module Type: ${module.moduleType}');
    } else {
      // 🚫 BOOTSTRAP PROTECTION: Block setModule(null) after bootstrap
      if (_hasCompletedBootstrap) {
        if (kDebugMode) {
          debugPrint(
              '⛔ SplashController.setModule: setModule(null) BLOCKED - not allowed after bootstrap');
          debugPrint(
              '   Module can only be cleared during logout or app reset');
        }
        return; // Block the operation
      }
      debugPrint(
          '   - Module is null (clearing module) - allowed during bootstrap only');
    }

    // 🏗️ MODULE-FIRST ARCHITECTURE: Update Single Source of Truth
    selectedModule.value = module;
    _module = module;
    await splashServiceInterface.setModule(module);

    // ⚡ TASK 1: Header Sync - Update ApiClient headers immediately after setting module
    // This prevents race condition where HomeScreen.loadData() uses old moduleId
    if (module != null) {
      final apiClient = Get.find<ApiClient>();
      final addressModel = AddressHelper.getUserAddressFromSharedPref();
      final sharedPreferences = Get.find<SharedPreferences>();

      apiClient.updateHeader(
        apiClient.token,
        addressModel?.zoneIds,
        addressModel?.areaIds,
        sharedPreferences.getString(AppConstants.languageCode),
        module.id, // ✅ Use new module ID
        addressModel?.latitude,
        addressModel?.longitude,
      );

      if (kDebugMode) {
        debugPrint(
            '✅ SplashController.setModule: Updated ApiClient headers with moduleId=${module.id}');
      }
    }

    if (module != null) {
      if (kDebugMode) {
        debugPrint(
            '🔍 setModule: _configModel=${_configModel != null ? "✓" : "✗"}, _data=${_data != null ? "✓" : "✗"}');
        if (_data != null) {
          debugPrint('🔍 setModule: _data keys: ${_data!.keys}');
          final moduleConfig = _data!['module_config'] as Map<String, dynamic>?;
          debugPrint(
              '🔍 setModule: module_config exists: ${moduleConfig != null ? "✓" : "✗"}');
          if (moduleConfig != null) {
            debugPrint(
                '🔍 setModule: module_config keys: ${moduleConfig.keys}');
            debugPrint(
                '🔍 setModule: Looking for module type: ${module.moduleType}');
          }
        }
      }
      if (_configModel != null &&
          _data != null &&
          _data!['module_config'] != null) {
        final moduleConfig = _data!['module_config'] as Map<String, dynamic>?;
        dynamic moduleTypeConfig =
            moduleConfig != null ? moduleConfig[module.moduleType] : null;
        if (moduleTypeConfig == null &&
            module.moduleType == AppConstants.ecommerce &&
            moduleConfig != null &&
            moduleConfig['grocery'] != null) {
          moduleTypeConfig = moduleConfig['grocery'];
          if (kDebugMode) {
            debugPrint(
                '[MODULE_CONFIG][FALLBACK] type=ecommerce fallback=grocery');
          }
        }
        if (moduleTypeConfig != null &&
            moduleTypeConfig is Map<String, dynamic>) {
          try {
            _configModel!.moduleConfig!.module =
                Module.fromJson(moduleTypeConfig);
            if (kDebugMode) {
              debugPrint(
                  '✅ setModule: module_config["${module.moduleType}"] loaded successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '❌ setModule: Error parsing module_config["${module.moduleType}"] - $e');
              debugPrint('   - Using default config as fallback');
            }
            appLogger.error('Error parsing module_config', e, null);
            _configModel!.moduleConfig!.module =
                _buildDefaultModuleConfig(module.moduleType);
          }
        } else {
          if (kDebugMode) {
            debugPrint(
                '[MODULE_CONFIG][FALLBACK] type=${module.moduleType} fallback=default');
          }
          _configModel!.moduleConfig!.module =
              _buildDefaultModuleConfig(module.moduleType);
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '[MODULE_CONFIG][FALLBACK] type=${module.moduleType} fallback=default reason=missing_config');
        }
        if (_configModel != null && _configModel!.moduleConfig != null) {
          _configModel!.moduleConfig!.module =
              _buildDefaultModuleConfig(module.moduleType);
        }
      }
      _cacheModule = await splashServiceInterface.setCacheModule(module);
      if ((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) &&
          cacheModule != null) {
        // Only load cart data if not already loaded
        final cartController = Get.find<CartController>();
        if (cartController.cartList.isEmpty) {
          debugPrint('🔄 SplashController: Loading cart data (empty cart)');
          cartController.getCartDataOnline();
        } else {
          debugPrint('💾 SplashController: Using existing cart data');
        }
      }
    }

    if (_cacheModule != null &&
        _cacheModule!.moduleType.toString() == AppConstants.taxi) {
      Get.find<TaxiCartController>().getCarCartList();
    }

    if (AuthHelper.isLoggedIn()) {
      if (Get.find<SplashController>().module != null) {
        // 🚫 REMOVED: getCashBackOfferList() - must load lazily in CashbackScreen only
        // 🚫 REMOVED: getFavouriteList() - must load lazily in WishlistScreen only
        // These calls were causing 118+ frame skips and 14s delays on home screens
        // They have dedicated NavBar buttons and MUST load lazily when user navigates to those screens
        if (module?.moduleType.toString() == AppConstants.taxi) {
          // Taxi favourite list is OK to keep here as it's taxi-specific
          Get.find<TaxiFavouriteController>().getFavouriteTaxiList();
        }
        // 🚫 REMOVED: FavouriteController.getFavouriteList() - lazy load in WishlistScreen only
      } else if (_cacheModule != null &&
          _cacheModule!.moduleType.toString() == AppConstants.taxi) {
        Get.find<TaxiCartController>().getCarCartList();
      }
    }
    // 🔒 Lock module after headers + storage + state are set
    _isModuleLocked = module != null;

    if (notify) {
      update();
    }
  }

  Module getModuleConfig(String? moduleType) {
    // Early null checks
    if (_data == null || _data!['module_config'] == null) {
      return _buildDefaultModuleConfig(moduleType);
    }

    final moduleConfig = _data!['module_config'] as Map<String, dynamic>;

    // Check if moduleType is valid
    if (moduleType == null || moduleConfig[moduleType] == null) {
      return _buildDefaultModuleConfig(moduleType);
    }

    try {
      final moduleData = moduleConfig[moduleType] as Map<String, dynamic>;
      final Module module = Module.fromJson(moduleData);
      module.newVariation = moduleType == 'food';
      return module;
    } catch (e) {
      debugPrint('Error parsing module config: $e');
      return _buildDefaultModuleConfig(moduleType);
    }
  }

  Future<void> getModules(
      {Map<String, String>? headers,
      DataSourceEnum dataSource = DataSourceEnum.local}) async {
    _moduleIndex = 0;
    List<ModuleModel>? moduleList;
    if (kDebugMode) {
      debugPrint('📡 SplashController.getModules: start (source=$dataSource)');
    }
    if (dataSource == DataSourceEnum.local) {
      // Load from local cache first for instant display
      moduleList = await splashServiceInterface.getModules(
          headers: headers, source: DataSourceEnum.local);
      if (moduleList != null && moduleList.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
              '📦 SplashController.getModules: local cache count=${moduleList.length}');
        }
        _prepareModuleList(moduleList);
        // During active splash, do not block routing on client refresh if we
        // already have local modules. Refresh in background instead.
        if (_isSplashFlowActive) {
          unawaited(getModules(headers: headers, dataSource: DataSourceEnum.client));
          return;
        }
      }
      // CRITICAL: Await client data to ensure all modules are loaded
      // This prevents showing partial/cached modules before all modules arrive
      await getModules(headers: headers, dataSource: DataSourceEnum.client);
    } else {
      // Load from client API - this has the complete, up-to-date module list
      moduleList = await splashServiceInterface.getModules(
          headers: headers, source: DataSourceEnum.client);
      if (moduleList != null && moduleList.isNotEmpty) {
        _prepareModuleList(moduleList);
        debugPrint(
            '✅ SplashController: Loaded ${moduleList.length} modules from client API');
      } else {
        if (kDebugMode) {
          debugPrint(
              '❌ SplashController.getModules: client API returned 0 modules');
        }
      }
    }
  }

  void _prepareModuleList(List<ModuleModel>? moduleList) {
    if (moduleList != null) {
      _moduleList = [];
      for (final module in moduleList) {
        if (module.moduleType != AppConstants.taxi && GetPlatform.isWeb) {
          _moduleList!.add(module);
        } else if (!GetPlatform.isWeb) {
          _moduleList!.add(module);
        }
      }
      debugPrint(
          '📋 SplashController: Prepared ${_moduleList?.length ?? 0} modules');
      // ⚡ PERFORMANCE: Only update moduleList listeners
      // This prevents flickering in MultiModuleHomeScreen when config/business_settings finish
      update(['moduleList']);
    }
  }

  void switchModule(BuildContext context, int index, bool fromPhone) async {
    if (_moduleList == null || index < 0 || index >= _moduleList!.length) {
      return;
    }
    await selectModule(_moduleList![index], context: context);
  }

  /// ⚡ TASK 2: Pre-emptive Zone Injection - Load last known zone from Hive
  /// Inject it immediately into ApiClient headers and LocationController
  /// Skip get-zone-id API call if user is within 500m of cached coordinates
  Future<void> _injectLastKnownZoneFromHive() async {
    try {
      final cachedZoneData = await HiveHomeCacheService().loadLastKnownZone();

      if (cachedZoneData != null &&
          cachedZoneData['zoneId'] != null &&
          cachedZoneData['latitude'] != null &&
          cachedZoneData['longitude'] != null) {
        final int lastKnownZoneId = cachedZoneData['zoneId'] as int;
        final String lastKnownLatitude = cachedZoneData['latitude'] as String;
        final String lastKnownLongitude = cachedZoneData['longitude'] as String;

        // 1. Inject into ApiClient headers
        final apiClient = Get.find<ApiClient>();
        apiClient.updateHeader(
          apiClient.token,
          [lastKnownZoneId],
          null, // areaIds
          Get.find<SharedPreferences>().getString(AppConstants.languageCode),
          _module?.id,
          lastKnownLatitude,
          lastKnownLongitude,
        );
        if (kDebugMode) {
          debugPrint(
              '⚡ SplashController: Injected last known zone ID $lastKnownZoneId into ApiClient headers (0ms)');
        }

        // 2. Inject into LocationController
        if (Get.isRegistered<LocationController>()) {
          final locationController = Get.find<LocationController>();
          locationController.setZoneID(lastKnownZoneId);
          locationController.update();
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: No last known zone data in Hive, proceeding with normal zone detection');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            '❌ SplashController: Error injecting last known zone from Hive - $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Continue gracefully even if Hive read fails
    }
  }

  /// Clear all controller data when switching modules
  /// This prevents showing data from the previous module
  // ignore: unused_element
  Future<void> _clearAllControllerData(
    String? newModuleType,
    int? newModuleId, {
    bool forceClear = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
          '🧹 SplashController: Clearing all controller data for module switch');
    }

    // Reset loading state to allow fresh data loading for new module
    LoadingStateManager().resetLoadingState();

    // 🔧 TASK 2: ItemController - RESET, don't delete (persist across module switches)
    // ItemController must remain in memory to prevent "Controller not registered" errors
    if (Get.isRegistered<ItemController>()) {
      try {
        final itemController = Get.find<ItemController>();
        await itemController.resetToDefault();
        if (kDebugMode) {
          debugPrint(
              '🔄 SplashController: Reset ItemController to default state');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ SplashController: Error resetting ItemController: $e');
        }
      }
    }

    // CategoryController requires both CategoryServiceInterface and SearchServiceInterface
    // Check if both are registered before accessing CategoryController
    // 🚫 PRODUCTION SAFE: Always check registration before accessing Services/Controllers
    if (Get.isRegistered<CategoryServiceInterface>() &&
        Get.isRegistered<SearchServiceInterface>() &&
        Get.isRegistered<CategoryController>()) {
      try {
        final categoryController = Get.find<CategoryController>();
        final hasCachedDataForModule =
            categoryController.hasHomeCategoriesForModule(newModuleId);
        if (forceClear || !hasCachedDataForModule) {
          categoryController.clearCategoryList();
        } else if (kDebugMode) {
          debugPrint(
              '[Cache-First] SplashController: Preserving CategoryController cached data for moduleId=$newModuleId');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Error clearing CategoryController: $e');
        }
      }
    }

    // 🚫 PRODUCTION SAFE: CampaignController cleanup with safe access
    if (Get.isRegistered<CampaignController>()) {
      try {
        final campaignController = Get.find<CampaignController>();
        campaignController.itemAndBasicCampaignNull();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Error clearing CampaignController: $e');
        }
      }
    }

    // 🚫 PRODUCTION SAFE: FlashSaleController cleanup with safe access
    if (Get.isRegistered<FlashSaleController>()) {
      try {
        final flashSaleController = Get.find<FlashSaleController>();
        flashSaleController.setEmptyFlashSale(fromModule: true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Error clearing FlashSaleController: $e');
        }
      }
    }

    // ⚡ Cache-First Fix: Only reset controllers if they don't have cached data
    // Golden Rule: Never reset controller if it has valid cached data
    // ⚡ TITAN BOARD: Core controllers - RESET only if no cached data
    if (Get.isRegistered<StoreController>()) {
      try {
        final storeController = Get.find<StoreController>();
        await storeController.resetToDefault();
        if (kDebugMode) {
          debugPrint(
              '[Cache-First] SplashController: Reset StoreController for module switch');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Error resetting StoreController: $e');
        }
      }
    }

    if (Get.isRegistered<CategoryController>()) {
      try {
        final categoryController = Get.find<CategoryController>();
        // ⚡ Check if has cached data before reset
        final hasCachedDataForModule =
            categoryController.hasHomeCategoriesForModule(newModuleId);
        if (forceClear || !hasCachedDataForModule) {
          categoryController.resetToDefault();
          if (kDebugMode) {
            debugPrint(
                '[Cache-First] SplashController: Reset CategoryController (forceClear=$forceClear, moduleId=$newModuleId)');
          }
        } else if (kDebugMode) {
          debugPrint(
              '[Cache-First] SplashController: Preserving CategoryController cached data for moduleId=$newModuleId');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Error resetting CategoryController: $e');
        }
      }
    }

    if (Get.isRegistered<OffersController>()) {
      try {
        final offersController = Get.find<OffersController>();
        // ⚡ Check if has cached data before reset
        final hasCachedData = offersController.offersMode != null &&
            offersController.offersMode!.data.isNotEmpty;
        if (forceClear || !hasCachedData) {
          offersController.resetToDefault();
          if (kDebugMode) {
            debugPrint(
                '[Cache-First] SplashController: Reset OffersController (forceClear=$forceClear)');
          }
        } else if (kDebugMode) {
          debugPrint(
              '[Cache-First] SplashController: Preserving OffersController cached data');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController: Error resetting OffersController: $e');
        }
      }
    }

    // ⚡ TITAN BOARD: Non-core controllers - DELETE to free memory
    // These controllers are module-specific and can be safely deleted
    // 🚨 TITAN BOARD MAINTENANCE WARNING:
    // ====================================================================================
    // This is a HARDCODED list. When adding new modules (e.g., Pharmacy with PrescriptionController),
    // you MUST add the new controller to this list or memory leaks will return.
    //
    // NOTE: Consider creating BaseModuleController interface and iterating through active instances
    // NOTE: Or use Get.deleteAll(bool force) if DI supports tracking module-specific controllers
    // ====================================================================================
    //
    // Current module controllers that must be deleted on module switch:
    // 🔧 TASK 2: ItemController is NOT deleted - it's reset above to persist across module switches
    try {
      if (Get.isRegistered<BannerController>()) {
        try {
          final bannerController = Get.find<BannerController>();
          // ⚡ Check if has cached data before reset
          final hasCachedData = (bannerController.bannerImageList != null &&
                  bannerController.bannerImageList!.isNotEmpty) ||
              (bannerController.featuredBannerList != null &&
                  bannerController.featuredBannerList!.isNotEmpty);
          if (forceClear || !hasCachedData) {
            await bannerController.resetToDefault();
            if (kDebugMode) {
              debugPrint(
                  '[Cache-First] SplashController: Reset BannerController (forceClear=$forceClear)');
            }
          } else if (kDebugMode) {
            debugPrint(
                '[Cache-First] SplashController: Preserving BannerController cached data');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ SplashController: Error resetting BannerController: $e');
          }
        }
      }
      if (Get.isRegistered<CampaignController>()) {
        Get.delete<CampaignController>(force: true);
        if (kDebugMode) {
          debugPrint('🗑️ SplashController: Deleted CampaignController');
        }
      }
      if (Get.isRegistered<FlashSaleController>()) {
        Get.delete<FlashSaleController>(force: true);
        if (kDebugMode) {
          debugPrint('🗑️ SplashController: Deleted FlashSaleController');
        }
      }
      if (Get.isRegistered<BrandsController>()) {
        try {
          final brandsController = Get.find<BrandsController>();
          // ⚡ Check if has cached data before reset
          final hasCachedData = brandsController.brandList != null &&
              brandsController.brandList!.isNotEmpty;
          if (forceClear || !hasCachedData) {
            await brandsController.resetToDefault();
            if (kDebugMode) {
              debugPrint(
                  '[Cache-First] SplashController: Reset BrandsController (forceClear=$forceClear)');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '[Cache-First] SplashController: Preserving BrandsController cached data');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ SplashController: Error resetting BrandsController: $e');
          }
        }
      }
      // ⚠️ ADD NEW MODULE CONTROLLERS HERE WHEN CREATED
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ SplashController: Error deleting controllers: $e');
      }
    }

    // CartController: Only clear if module type changed (don't delete, just clear data)
    if (Get.isRegistered<CartController>()) {
      final cartController = Get.find<CartController>();
      final currentModule = _module?.moduleType?.toString();

      // Only clear cart if module type actually changed
      if (currentModule != null && currentModule != newModuleType) {
        if (kDebugMode) {
          debugPrint(
              '🛒 SplashController: Clearing cart (module type changed: $currentModule -> $newModuleType)');
        }
        await cartController.clearCartOnline();
      }
    }

    if (kDebugMode) {
      debugPrint('✅ SplashController: All controller state cleared');
    }
  }

  int getCacheModule() {
    return splashServiceInterface.getCacheModule()?.id ?? 0;
  }

  void setModuleIndex(int index) {
    _moduleIndex = index;
    update();
  }

  /// 🏗️ MODULE-FIRST ARCHITECTURE: Deprecated method - no longer clears module
  /// In Module-First architecture, module should not be cleared manually
  /// Module is cleared only when explicitly required (e.g., logout, app reset)
  /// This method is kept for backward compatibility but does nothing
  @Deprecated(
      'Module-First Architecture: Use selectModule() or switchModule() instead')
  void removeModule() {
    // 🏗️ MODULE-FIRST ARCHITECTURE: Do not clear module manually
    // Module state is managed through selectedModule.value
    // Controllers will react to module changes automatically
    if (kDebugMode) {
      debugPrint(
          '⚠️ SplashController.removeModule: Deprecated - module will not be cleared in Module-First architecture');
      debugPrint(
          '   Use selectModule() or switchModule() to change modules instead');
    }

    // Only refresh module list - do not clear current module
    getModules();

    // Clear related controller data without clearing module
    // 🚫 PRODUCTION SAFE: Always check registration before accessing Controllers
    if (Get.isRegistered<HomeController>()) {
      try {
        Get.find<HomeController>().forcefullyNullCashBackOffers();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController.removeModule: Error clearing HomeController: $e');
        }
      }
    }
    if (AuthHelper.isLoggedIn() && Get.isRegistered<AddressController>()) {
      try {
        Get.find<AddressController>().getAddressList();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController.removeModule: Error clearing AddressController: $e');
        }
      }
    }
    if (Get.isRegistered<StoreController>()) {
      try {
        Get.find<StoreController>().getFeaturedStoreList();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController.removeModule: Error clearing StoreController: $e');
        }
      }
    }
    if (Get.isRegistered<CampaignController>()) {
      try {
        Get.find<CampaignController>().itemAndBasicCampaignNull();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ SplashController.removeModule: Error clearing CampaignController: $e');
        }
      }
    }

    // 🏗️ MODULE-FIRST: Do not trigger BannerController without module
    // BannerController will load automatically when module is selected
  }

  Future<void> removeCacheModule() async {
    _cacheModule = await splashServiceInterface.setCacheModule(null);
  }

  Future<bool> subscribeMail(String email) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel =
        await splashServiceInterface.subscribeEmail(email);
    if (responseModel.isSuccess) {
      showCustomSnackBar(responseModel.message, isError: false);
    } else {
      showCustomSnackBar(responseModel.message);
    }
    _isLoading = false;
    update();
    return responseModel.isSuccess;
  }

  void saveCookiesData(bool data) {
    splashServiceInterface.saveCookiesData(data);
    _savedCookiesData = true;
    update();
  }

  void getCookiesData() {
    _savedCookiesData = splashServiceInterface.getSavedCookiesData();
    update();
  }

  void cookiesStatusChange(String? data) {
    splashServiceInterface.cookiesStatusChange(data);
  }

  bool getAcceptCookiesStatus(String data) =>
      splashServiceInterface.getAcceptCookiesStatus(data);

  void saveWebSuggestedLocationStatus(bool data) {
    splashServiceInterface.saveSuggestedLocationStatus(data);
    _webSuggestedLocation = true;
    update();
  }

  void getWebSuggestedLocationStatus() {
    _webSuggestedLocation = splashServiceInterface.getSuggestedLocationStatus();
  }

  void setRefreshing(bool status) {
    _isRefreshing = status;
    update();
  }

  void saveReferBottomSheetStatus(bool data) {
    splashServiceInterface.saveReferBottomSheetStatus(data);
    _showReferBottomSheet = data;
    update();
  }

  void getReferBottomSheetStatus() {
    _showReferBottomSheet = splashServiceInterface.getReferBottomSheetStatus();
  }

  var hoverStates = <bool>[];

  void setHover(int index, bool state) {
    hoverStates[index] = state;
    // 🔥 FIX: Use Future.microtask to prevent setState during mouse tracking
    // This prevents "Failed assertion: '!_debugDuringDeviceUpdate'" error
    Future.microtask(() => update());
  }

  /// Restore splash data from cache for instant startup
  Future<void> restoreFromCache({
    required Map<String, dynamic> configData,
    Map<String, dynamic>? moduleData,
    List<dynamic>? moduleListData,
  }) async {
    try {
      // ⚡ PERF FIX: Parse ALL models in a single isolate to avoid blocking
      // main thread during splash GIF animation (~170 frame skips → 0)
      final parsed = await compute(_parseModelsInIsolate, {
        'configData': configData,
        'moduleData': moduleData,
        'moduleListData': moduleListData,
      });

      // Assign parsed results to controller state (fast, just references)
      _data = configData;
      _configModel = parsed['configModel'] as ConfigModel?;
      _module = parsed['module'] as ModuleModel?;
      _moduleList = parsed['moduleList'] as List<ModuleModel>?;

      // Apply module config (needs access to _data, _configModel, _module)
      if (_module != null && _configModel != null && _data != null) {
        // 🔧 FIX: Handle null module_config gracefully (prevent cast error)
        final moduleConfig = _data!['module_config'];
        if (moduleConfig != null && moduleConfig is Map) {
          dynamic moduleTypeConfig = moduleConfig[_module!.moduleType];
          // [MODULE_CONFIG][FALLBACK] – ecommerce → grocery → default
          if (moduleTypeConfig == null &&
              _module!.moduleType == AppConstants.ecommerce &&
              moduleConfig['grocery'] != null) {
            moduleTypeConfig = moduleConfig['grocery'];
            if (kDebugMode) {
              debugPrint(
                  '[MODULE_CONFIG][FALLBACK] type=${_module!.moduleType} fallback=grocery');
            }
          }
          if (moduleTypeConfig != null &&
              moduleTypeConfig is Map<String, dynamic>) {
            _configModel!.moduleConfig!.module =
                Module.fromJson(moduleTypeConfig);
          } else {
            if (kDebugMode) {
              debugPrint(
                  '[MODULE_CONFIG][FALLBACK] type=${_module!.moduleType} fallback=default');
            }
            _configModel!.moduleConfig!.module =
                _buildDefaultModuleConfig(_module!.moduleType);
          }
        } else {
          if (kDebugMode) {
            debugPrint(
                '[MODULE_CONFIG][FALLBACK] type=${_module!.moduleType} fallback=default reason=missing_config');
          }
          _configModel!.moduleConfig!.module =
              _buildDefaultModuleConfig(_module!.moduleType);
        }
      }
      // Promotional content preloading is intentionally deferred out of splash.
      // Keep cache restore focused on config/module readiness only.
      _isSplashCacheReady = true;

      debugPrint(
          '✅ SplashController: Data restored from cache - instant startup ready');
      update();
    } catch (e) {
      debugPrint('❌ SplashController: Error restoring from cache - $e');
    }
  }

  /// Load and cache promotional content for Module 3 (eCommerce)
  /// This is used by the multi-module home screen to display promotional banners and offers
  /// The content is cached in a dedicated Hive box for instant loading
  Future<void> loadAndCachePromotionalContent({int? moduleId}) async {
    _hasAttemptedPromotionalLoad = true;
    try {
      final int targetModuleId = moduleId ??
          selectedModule.value?.id ??
          _module?.id ??
          getCacheModule();

      // 🔧 FIX: Use Module 3 as default for new users instead of skipping
      // This ensures new users see promotional content on first launch
      final int finalModuleId = targetModuleId == 0 ? 3 : targetModuleId;

      if (kDebugMode) {
        if (targetModuleId == 0) {
          debugPrint(
              '🆕 PromotionalContent: New user detected - using Module 3 as default content module');
        }
        debugPrint(
            '🚀 PromotionalContent: Loading for Module $finalModuleId (splashActive=$_isSplashFlowActive)');
      }
      final DateTime? lastLoadedAt =
          _promotionalContentLastLoadedAt[finalModuleId];
      final bool isWithinCooldown = lastLoadedAt != null &&
          DateTime.now().difference(lastLoadedAt) < _promotionalReloadCooldown;
      if (isWithinCooldown && _hasLoadedPromotionalContent) {
        if (kDebugMode) {
          debugPrint(
              '⏭️ SplashController: Promotional content recently loaded for module $finalModuleId - skipping duplicate trigger');
        }
        return;
      }

      if (_promotionalBannerLoadInProgress[finalModuleId] == true) {
        if (kDebugMode) {
          debugPrint(
              'SplashController: Promotional load already in progress for module $finalModuleId - skipping');
        }
        return;
      }
      _promotionalBannerLoadInProgress[finalModuleId] = true;

      final apiClient = Get.find<ApiClient>();
      final addressModel = AddressHelper.getUserAddressFromSharedPref();
      final sharedPreferences = Get.find<SharedPreferences>();

      // Save current module ID from headers
      final currentModuleId = apiClient.getHeader()['module-id'];

      // Set Module ID for promotional content
      apiClient.updateHeader(
        apiClient.token,
        addressModel?.zoneIds,
        addressModel?.areaIds,
        sharedPreferences.getString(AppConstants.languageCode),
        finalModuleId,
        addressModel?.latitude,
        addressModel?.longitude,
      );

      BannerModel? bannerModel;
      OffersModel? offersModel;
      bool hasPromotionalBottomBanner = false;

      // Load banners from Module 3 directly from API (bypass module check)
      // Call API directly since getFeaturedBanner() requires selectedModule
      if (Get.isRegistered<BannerController>()) {
        try {
          final bannerController = Get.find<BannerController>();
          // Load directly from API using bannerService (bypasses module check)
          bannerModel =
              await bannerController.bannerService.getFeaturedBannerList();

          // Update BannerController directly using setFromUnified
          if (bannerModel != null) {
            bannerController.setFromUnified(
              bannerModel: bannerModel,
              moduleId: finalModuleId,
              source: 'splash_promotional_preload',
            );
            if (kDebugMode) {
              debugPrint(
                  '✅ SplashController: Loaded ${bannerModel.banners?.length ?? 0} promotional banners');
            }
          }

          await bannerController.getPromotionalBannerList(true);
          final String? promoUrl =
              bannerController.promotionalBanner?.bottomSectionBannerFullUrl;
          hasPromotionalBottomBanner = promoUrl != null && promoUrl.isNotEmpty;
          if (kDebugMode) {
            debugPrint(
                '✅ SplashController: Promotional bottom banner loaded: $hasPromotionalBottomBanner');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ SplashController: Error loading promotional banners: $e');
          }
        }
      }

      // Load offers: prefer home-unified cached data over /api/v1/offers/active.
      // Reason: home-unified returns correct active offers while /api/v1/offers/active
      // may return empty due to different backend filtering, which would overwrite
      // valid offers already loaded during the preload phase.
      if (Get.isRegistered<OffersController>()) {
        try {
          final offersController = Get.find<OffersController>();
          bool loadedFromUnified = false;

          if (Get.isRegistered<HomeUnifiedController>()) {
            final unifiedController = Get.find<HomeUnifiedController>();
            final cachedUnified =
                unifiedController.getModuleData(finalModuleId);
            if (cachedUnified?.offers != null &&
                cachedUnified!.offers!.isNotEmpty &&
                cachedUnified.offers!.first.data.isNotEmpty) {
              offersController.setOffersFromBootstrap(cachedUnified.offers!);
              offersModel = offersController.offersMode;
              loadedFromUnified = true;
              if (kDebugMode) {
                debugPrint(
                    'SplashController: Loaded ${offersModel?.data.length ?? 0} promotional offers from home-unified cache');
              }
            }
          }

          if (!loadedFromUnified) {
            offersModel = await offersController.getOffers(
                specificModuleId: finalModuleId);
            if (kDebugMode && offersModel != null) {
              debugPrint(
                  'SplashController: Loaded ${offersModel.data.length} promotional offers');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'SplashController: Error loading promotional offers: $e');
          }
        }
      }

      // Save to dedicated Hive cache box
      if (bannerModel != null ||
          offersModel != null ||
          hasPromotionalBottomBanner) {
        await HiveHomeCacheService().savePromotionalContent(
          banners: bannerModel,
          offers: offersModel,
        );
        if (kDebugMode) {
          debugPrint('💾 SplashController: Saved promotional content to cache');
        }
        _hasLoadedPromotionalContent = true;
        _promotionalContentLastLoadedAt[finalModuleId] = DateTime.now();
        update(['promotional_content']);
      }

      // Restore original module ID in headers
      apiClient.updateHeader(
        apiClient.token,
        addressModel?.zoneIds,
        addressModel?.areaIds,
        sharedPreferences.getString(AppConstants.languageCode),
        currentModuleId != null ? int.tryParse(currentModuleId) : null,
        addressModel?.latitude,
        addressModel?.longitude,
      );

      if (kDebugMode) {
        debugPrint('✅ SplashController: Promotional content loaded and cached');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SplashController: Error loading promotional content: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
    } finally {
      final int targetModuleId = moduleId ??
          selectedModule.value?.id ??
          _module?.id ??
          getCacheModule();
      final int finalModuleId = targetModuleId == 0 ? 3 : targetModuleId;
      Future.delayed(const Duration(seconds: 2), () {
        _promotionalBannerLoadInProgress.remove(finalModuleId);
      });
    }
  }

  @override
  void onClose() {
    _isSplashFlowActive = false;
    _promotionalBannerLoadInProgress.clear();
    _promotionalContentLastLoadedAt.clear();
    super.onClose();
  }
}
