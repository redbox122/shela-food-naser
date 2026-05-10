// ignore_for_file: body_might_complete_normally_nullable

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';
import 'package:sixam_mart/features/home/domain/models/cashback_model.dart';
import 'package:sixam_mart/features/home/domain/services/home_service_interface.dart';
import 'package:sixam_mart/common/models/app_init_model.dart';
import 'package:sixam_mart/features/home/domain/home_data_source.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/util/app_constants.dart';

class HomeController extends GetxController implements GetxService {
  final HomeServiceInterface homeServiceInterface;
  HomeController({required this.homeServiceInterface});
  final bool _isUnifiedModeEnabled = AppConstants.useBffV2Endpoint;

  // 🔧 FIX: Track last loaded module to prevent duplicate loads (Cold Start Loop Prevention)
  int? _lastLoadedModuleId;
  int? _lastLoadedZoneId;

  // 🔧 FIX: Track if initial load has happened to prevent Cold Start Loop
  bool _hasInitialLoadCompleted = false;
  Worker? _moduleWorker;
  bool _isHomeDataLoading = false;
  int? _inFlightModuleId;
  int? _queuedModuleId;
  DateTime? _lastHomeDataLoadAt;
  static const Duration _homeDataLoadThrottle = Duration(seconds: 3);

  @override
  void onInit() {
    super.onInit();

    if (kDebugMode) {
      debugPrint('🏠 HomeController.onInit() - Setting up reactive workers');
    }

    // 🔧 FIX 2: Worker 1 - إعادة التحميل فور تغير الموديول (مطاعم، متاجر، إلخ)
    // 🛡️ LOOP PREVENTION: Only fires when module ACTUALLY changes to a DIFFERENT value
    if (Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();
      _moduleWorker?.dispose();
      _moduleWorker = ever(splashController.selectedModule, (module) {
        // 🛡️ Guard 1: Skip if module is null
        if (module == null) {
          if (kDebugMode) {
            debugPrint('⏭️ HomeController: Module is null - skipping reload');
          }
          return;
        }

        // 🛡️ Guard 2: Skip if this is the SAME module as last successful load
        // This is the KEY fix for Cold Start Loop
        if (_lastLoadedModuleId != null && _lastLoadedModuleId == module.id) {
          if (kDebugMode) {
            debugPrint(
                '⏭️ HomeController: Same module (${module.id}) - skipping reload (Loop Prevention)');
          }
          return;
        }

        // 🛡️ Guard 3: For first load, only proceed if module has valid ID
        if (!_hasInitialLoadCompleted && module.id == null) {
          if (kDebugMode) {
            debugPrint(
                '⏭️ HomeController: First load but module.id is null - skipping');
          }
          return;
        }

        // ✅ Valid module change detected - proceed with load
        final previousModuleId = _lastLoadedModuleId;
        _lastLoadedModuleId = module.id;
        _hasInitialLoadCompleted = true;

        if (kDebugMode) {
          debugPrint(
              '🔄 HomeController: Module changed from $previousModuleId to ${module.id} (${module.moduleName}) - reloading home data');
        }

        // Update ApiClient headers with new module (SILENT - no reactive triggers)
        _updateApiHeadersSilent();

        // Reload home data
        loadHomeData(forceRefresh: true);
      });
    }

    // 🔧 FIX 2: Zone changes are handled via reloadOnZoneChange() method
    // LocationController will call this method when zone changes

    if (kDebugMode) {
      debugPrint('✅ HomeController.onInit() completed - Workers registered');
    }

    // Fallback: use cached business settings from SplashController if available
    if (_business_Settings == null && Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();
      if (splashController.cachedBusinessSettings != null) {
        setBusinessSettingsFromAppInit(
            splashController.cachedBusinessSettings!);
        if (kDebugMode) {
          debugPrint(
              '✅ HomeController: Business settings restored from SplashController cache');
        }
      }
    }
  }

  /// 🔧 FIX 2: Called by LocationController when zone changes
  /// This method reloads home data when user confirms location or zone changes
  void reloadOnZoneChange(int newZoneId) {
    if (newZoneId == 0) {
      if (kDebugMode) {
        debugPrint('⏭️ HomeController: ZoneID is 0 - skipping reload');
      }
      return;
    }

    // Prevent duplicate loads for the same zone
    if (_lastLoadedZoneId == newZoneId) {
      if (kDebugMode) {
        debugPrint('⏭️ HomeController: Same zone ($newZoneId) - skipping reload');
      }
      return;
    }

    _lastLoadedZoneId = newZoneId;

    if (kDebugMode) {
      debugPrint(
          '🔄 HomeController: Zone changed to $newZoneId - reloading home data');
    }

    // Update ApiClient headers with new zone (SILENT - no reactive triggers)
    _updateApiHeadersSilent();

    // Reload home data
    loadHomeData(forceRefresh: true);
  }

  /// 🔧 FIX 4: Update ApiClient headers with current module and zone (SILENT - no reactive triggers)
  /// This method ONLY updates the ApiClient internal state - it does NOT call update() or notify listeners
  void _updateApiHeadersSilent() {
    try {
      if (!Get.isRegistered<ApiClient>()) return;

      final apiClient = Get.find<ApiClient>();
      final AddressModel? address =
          AddressHelper.getUserAddressFromSharedPref();

      int? moduleId;
      if (Get.isRegistered<SplashController>()) {
        moduleId = Get.find<SplashController>().module?.id;
      }

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
        debugPrint(
            '✅ HomeController: ApiClient headers updated (moduleId: $moduleId, zoneIds: ${address?.zoneIds})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HomeController: Error updating ApiClient headers - $e');
      }
    }
  }

  // 🎯 API OVERLAP FIX: Track data source to prevent duplication
  HomeDataSource _dataSource = HomeDataSource.unified;
  HomeDataSource get dataSource => _dataSource;

  /// Set data source (for testing or fallback scenarios)
  void setDataSource(HomeDataSource source) {
    if (_dataSource != source) {
      _dataSource = source;
      if (kDebugMode) {
        debugPrint('🔄 HomeController: Data source changed to ${source.name}');
      }
    }
  }

  List<CashBackModel>? _cashBackOfferList;
  List<CashBackModel>? get cashBackOfferList => _cashBackOfferList;

  BusinessSettingsModel? _business_Settings;
  BusinessSettingsModel? get business_Settings => _business_Settings;

  CashBackModel? _cashBackData;
  CashBackModel? get cashBackData => _cashBackData;

  bool _showFavButton = true;
  bool get showFavButton => _showFavButton;

  // ========================================================================================================

  Future<BusinessSettingsModel?> getBusiness_Settings() async {
    _business_Settings = await homeServiceInterface.getBusiness_Settings();
    update();
  }

  /// Set business settings from cache
  void setBusinessSettingsFromCache(BusinessSettingsModel settings) {
    _business_Settings = settings;
    update();
  }

  /// Set business settings from bootstrap endpoint
  void setBusinessSettingsFromBootstrap(BusinessSettingsModel settings) {
    if (_business_Settings != null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ HomeController: Ignoring bootstrap settings - existing settings preserved');
      }
      return;
    }
    _business_Settings = settings;
    update();
    if (kDebugMode) {
      debugPrint('✅ HomeController: Business settings set from bootstrap');
    }
  }

  /// Set business settings from app-init endpoint
  /// Converts BusinessSettings (app-init) to BusinessSettingsModel
  void setBusinessSettingsFromAppInit(BusinessSettings appInitSettings) {
    _business_Settings = _convertAppInitBusinessSettings(appInitSettings);
    update();
    if (kDebugMode) {
      debugPrint('✅ HomeController: Business settings set from app-init');
    }
  }

  /// Convert BusinessSettings (app-init model) to BusinessSettingsModel
  /// Maps available fields and uses defaults for missing fields
  static BusinessSettingsModel _convertAppInitBusinessSettings(
      BusinessSettings appInitSettings) {
    return BusinessSettingsModel(
      bannersSection: appInitSettings.bannerSection ?? 1,
      categoriesSection: appInitSettings.categoriesSection ?? 1,
      popularStoresSection: appInitSettings.popularStoresSection ?? 1,
      flashSalesSection: appInitSettings.flashSaleSection ?? 1,
      offersSection: appInitSettings.offersSection ?? 0,
      topRestaurantsSection: appInitSettings.topRestaurantsSection ?? 0,
      allRestaurantsSection: appInitSettings.allRestaurantsSection ?? 0,
      allStoresSection: appInitSettings.allStoresSection ?? 0,
      // Fields not available in app-init use defaults from BusinessSettingsModel constructor
      // visitAgainSection, popularProductsSection, campaignsBasicSection, etc. will use defaults
    );
  }

  // ===========================================================

  Future<void> getCashBackOfferList() async {
    _cashBackOfferList = null;
    _cashBackOfferList = await homeServiceInterface.getCashBackOfferList();
    update();
  }

  void forcefullyNullCashBackOffers() {
    _cashBackOfferList = null;
    update();
  }

  /* Future<double> getCashBackAmount(double amount) async {
    _cashBackAmount = await homeServiceInterface.getCashBackAmount(amount);
    return _cashBackAmount;
  }*/

  Future<void> getCashBackData(double amount) async {
    final CashBackModel? cashBackModel =
        await homeServiceInterface.getCashBackData(amount);
    if (cashBackModel != null) {
      _cashBackData = cashBackModel;
    }
    update();
  }

  void changeFavVisibility() {
    _showFavButton = !_showFavButton;
    update();
  }

  Future<bool> saveRegistrationSuccessfulSharedPref(bool status) async {
    return await homeServiceInterface.saveRegistrationSuccessful(status);
  }

  Future<bool> saveIsStoreRegistrationSharedPref(bool status) async {
    return await homeServiceInterface.saveIsRestaurantRegistration(status);
  }

  bool getRegistrationSuccessfulSharedPref() {
    return homeServiceInterface.getRegistrationSuccessful();
  }

  bool getIsStoreRegistrationSharedPref() {
    return homeServiceInterface.getIsRestaurantRegistration();
  }

  // ========================================================================================================
  // 🎯 API OVERLAP FIX: Single entry point for home data loading
  // ========================================================================================================

  /// Load home data from unified or partial endpoints
  ///
  /// This is the ONLY method that should be called from HomeScreen.
  /// It decides whether to use unified endpoint or fallback to partial endpoints.
  ///
  /// [forcePartial] - Force use of partial endpoints (for testing or when unified fails)
  /// [forceRefresh] - Force refresh from API (bypass cache)
  Future<void> loadHomeData({
    bool forcePartial = false,
    bool forceRefresh = false,
  }) async {
    final int? requestedModuleId = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>().module?.id
        : null;
    if (_isHomeDataLoading) {
      if (requestedModuleId != null &&
          _inFlightModuleId != null &&
          requestedModuleId != _inFlightModuleId) {
        _queuedModuleId = requestedModuleId;
        if (kDebugMode) {
          debugPrint(
              '[HOME_LOAD_FORCE_NEW_MODULE] requestedModuleId=$requestedModuleId previousInFlightModuleId=$_inFlightModuleId');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint(
            '[HOME_LOAD_SKIPPED] requestedModuleId=$requestedModuleId inFlightModuleId=$_inFlightModuleId');
      }
      return;
    }

    final now = DateTime.now();
    if (!forceRefresh &&
        _lastHomeDataLoadAt != null &&
        now.difference(_lastHomeDataLoadAt!) < _homeDataLoadThrottle) {
      if (kDebugMode) {
        debugPrint(
            '⏭️ HomeController: loadHomeData throttled (${now.difference(_lastHomeDataLoadAt!).inMilliseconds}ms since last call)');
      }
      return;
    }

    _isHomeDataLoading = true;
    _inFlightModuleId = requestedModuleId;
    _lastHomeDataLoadAt = now;
    if (kDebugMode) {
      debugPrint(
          '🏠 HomeController: loadHomeData called (forcePartial: $forcePartial, forceRefresh: $forceRefresh)');
    }

    try {
      // 🔧 FIX 1: Check if current module is "food" type (restaurants or cafes)
      // Food modules MUST use V2 unified endpoint - no fallback allowed
      bool isFoodModule = false;
      int? currentModuleId;
      String? currentModuleType;
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        currentModuleId = splashController.module?.id;
        currentModuleType = splashController.module?.moduleType;
        isFoodModule = currentModuleType == 'food';
        if (kDebugMode && isFoodModule) {
          appLogger.info('Food module detected - V2 only mode (no fallback)');
        }
      }

      _logHeaderSnapshot(
        source: 'loadHomeData.entry',
        moduleId: currentModuleId,
        moduleType: currentModuleType,
      );

      if (Get.isRegistered<ApiClient>()) {
        final apiClient = Get.find<ApiClient>();
        if (!apiClient.hasValidHomeHeaders()) {
          if (kDebugMode) {
            debugPrint(
                '🚫 HomeController: Home request blocked - invalid headers '
                '(module-id/zone-id missing)');
          }
          return;
        }
      }

      // Decide data source
      // Unified-only policy: when v2 is enabled, direct partial calls are blocked
      // except controlled fallback after specific unified failures.
      final shouldUsePartial = !_isUnifiedModeEnabled &&
          !isFoodModule &&
          (forcePartial || _dataSource == HomeDataSource.partial);

      if (shouldUsePartial) {
        if (kDebugMode) {
          debugPrint('📡 HomeController: Using partial endpoints (fallback mode)');
        }
        await _loadPartialHome(forceRefresh);
      } else {
        if (kDebugMode) {
          debugPrint('⚡ HomeController: Attempting unified endpoint first');
        }
        final success = await _loadUnifiedHome(forceRefresh);
        if (!success) {
          final unifiedController = Get.isRegistered<HomeUnifiedController>()
              ? Get.find<HomeUnifiedController>()
              : null;
          final statusCode = unifiedController?.lastRequestStatusCode;
          final errorCode = unifiedController?.lastRequestErrorCode;
          final bool headerBlocked =
              unifiedController?.wasLastFailureHeaderBlocked == true ||
                  statusCode == 428 ||
                  errorCode == 'home_headers_invalid';
          final bool recoverableFailure =
              statusCode == null || statusCode == 1 || (statusCode >= 500);

          // Food modules never fallback.
          // Unified-only mode: fallback only for recoverable failures, once.
          if (isFoodModule ||
              headerBlocked ||
              (_isUnifiedModeEnabled && !recoverableFailure)) {
            if (kDebugMode) {
              debugPrint(
                  '🛡️ HomeController: Unified failure - partial fallback blocked');
              debugPrint(
                  '   → isFood=$isFoodModule, headerBlocked=$headerBlocked, status=$statusCode, error=$errorCode');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ HomeController: Unified endpoint failed (status=$statusCode), partial fallback allowed once');
            }
            await _loadPartialHome(forceRefresh);
          }
        }
      }
    } finally {
      final int? completedModuleId = _inFlightModuleId;
      _isHomeDataLoading = false;
      _inFlightModuleId = null;
      if (_queuedModuleId != null && _queuedModuleId != completedModuleId) {
        final int queuedModuleId = _queuedModuleId!;
        _queuedModuleId = null;
        if (kDebugMode) {
          debugPrint(
              '[HOME_LOAD_FORCE_NEW_MODULE] requestedModuleId=$queuedModuleId previousInFlightModuleId=$completedModuleId');
        }
        unawaited(loadHomeData(forceRefresh: true));
      }
    }
  }

  void _logHeaderSnapshot({
    required String source,
    int? moduleId,
    String? moduleType,
  }) {
    if (!kDebugMode) return;

    String? headerModuleId;
    String? headerZoneId;
    if (Get.isRegistered<ApiClient>()) {
      final headers = Get.find<ApiClient>().getHeader();
      headerModuleId = headers['module-id'];
      headerZoneId = headers['zone-id'];
    }

    debugPrint(
        '[Diag] HomeController[$source]: moduleId=$moduleId, moduleType=$moduleType, '
        'header.module-id=$headerModuleId, header.zone-id=$headerZoneId');
  }

  /// Load home data from unified endpoint
  /// Returns true if successful, false otherwise
  Future<bool> _loadUnifiedHome(bool forceRefresh) async {
    try {
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        if (!splashController.hasConnection) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ HomeController: Unified fetch skipped - device appears offline');
          }
          return false;
        }
      }
      int? moduleId;
      String? moduleType;
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        moduleId = splashController.module?.id;
        moduleType = splashController.module?.moduleType;
      }
      _logHeaderSnapshot(
        source: 'unified.before_request',
        moduleId: moduleId,
        moduleType: moduleType,
      );

      // Check if HomeUnifiedController is registered
      if (!Get.isRegistered<HomeUnifiedController>()) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ HomeController: HomeUnifiedController not registered, cannot use unified endpoint');
        }
        return false;
      }

      final unifiedController = Get.find<HomeUnifiedController>();

      // Load data from unified endpoint
      final success = await unifiedController.loadHomeData(
        forceRefresh: forceRefresh,
        showLoading: false,
      );
      final statusCode = unifiedController.lastRequestStatusCode;
      final errorCode = unifiedController.lastRequestErrorCode;

      // 🔧 FIX (HOME_UNIFIED Issue 3): Trust the parsed model presence instead
      // of relying solely on `success` boolean. If HTTP=200 and the parsed model
      // contains usable content (categories/banners/offers/brands), accept it.
      final unifiedData = unifiedController.unifiedData;
      final int categoriesCount = unifiedData?.categories?.length ?? 0;
      final int offersCount = unifiedData?.offers?.length ?? 0;
      final int bannersCount = unifiedData?.banners?.length ?? 0;
      final int brandsCount = unifiedData?.brands?.length ?? 0;
      final bool hasParsedContent = categoriesCount > 0 ||
          bannersCount > 0 ||
          offersCount > 0 ||
          brandsCount > 0;
      final bool hasUsableUnifiedData = unifiedController.hasCachedData ||
          (unifiedData?.isValid ?? false) ||
          hasParsedContent;
      final bool isConnectivityFailure = statusCode == 1;
      final bool effectiveSuccess = success && !isConnectivityFailure;
      final bool isUnifiedSuccess = effectiveSuccess ||
          statusCode == 304 ||
          (hasUsableUnifiedData && !isConnectivityFailure) ||
          // ⚡ Decisive accept: 200 + any parsed content = success regardless of
          // success flag, even when controller-level dedup returned false.
          (statusCode == 200 && hasParsedContent && !isConnectivityFailure);

      if (kDebugMode) {
        debugPrint(
            '[HOME_UNIFIED][CONTROLLER_RECEIVE] success=$success hasData=$hasUsableUnifiedData '
            'categories=$categoriesCount offers=$offersCount banners=$bannersCount brands=$brandsCount');
      }

      if (isUnifiedSuccess) {
        if (kDebugMode) {
          debugPrint(
              '[HOME_UNIFIED][RESULT] status=$statusCode parsedSuccess=$success '
              'hasData=$hasUsableUnifiedData categories=$categoriesCount offers=$offersCount');
          debugPrint('[HOME_UNIFIED][ACCEPTED]');
        }
        _dataSource = HomeDataSource.unified;
        return true;
      }

      if (kDebugMode) {
        debugPrint(
            '[HOME_UNIFIED][RESULT] status=$statusCode parsedSuccess=$success '
            'hasData=$hasUsableUnifiedData categories=$categoriesCount offers=$offersCount');
        debugPrint(
            '[HOME_UNIFIED][REJECTED] reason=not_unified_success connectivity=$isConnectivityFailure error=$errorCode');
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeController: Error loading from unified endpoint - $e');
      }
      return false;
    }
  }

  /// Load home data from partial endpoints (fallback)
  ///
  /// This method loads data from individual API endpoints.
  /// It should only be used when unified endpoint fails or is disabled.
  Future<void> _loadPartialHome(bool forceRefresh) async {
    try {
      if (_isUnifiedModeEnabled) {
        if (kDebugMode) {
          debugPrint(
              '🛡️ HomeController: Unified-only mode enabled - skipping partial endpoints');
        }
        return;
      }

      int? moduleId;
      String? moduleType;
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        moduleId = splashController.module?.id;
        moduleType = splashController.module?.moduleType;
      }
      _logHeaderSnapshot(
        source: 'partial.before_request',
        moduleId: moduleId,
        moduleType: moduleType,
      );

      if (kDebugMode) {
        debugPrint('📡 HomeController: Loading from partial endpoints');
      }

      _dataSource = HomeDataSource.partial;

      // Load data from individual controllers in parallel
      final futures = <Future<void>>[];

      // Load categories
      if (Get.isRegistered<CategoryController>()) {
        futures.add(
          Get.find<CategoryController>()
              .getCategoryList(forceRefresh, expectedModuleId: moduleId)
              .catchError((dynamic e) {
            if (kDebugMode) {
              debugPrint('⚠️ HomeController: Error loading categories - $e');
            }
            return <CategoryModel>[];
          }),
        );
      }

      // Load stores
      if (Get.isRegistered<StoreController>()) {
        futures.add(
          Get.find<StoreController>()
              .getStoreList(1, forceRefresh)
              .catchError((dynamic e) {
            if (kDebugMode) {
              debugPrint('⚠️ HomeController: Error loading stores - $e');
            }
            return StoreModel(stores: [], totalSize: 0, offset: 1, limit: '12');
          }),
        );
      }

      // Load banners
      if (Get.isRegistered<BannerController>()) {
        futures.add(
          Get.find<BannerController>()
              .getBannerList(forceRefresh)
              .catchError((dynamic e) {
            if (kDebugMode) {
              debugPrint('⚠️ HomeController: Error loading banners - $e');
            }
            return BannerModel(banners: [], campaigns: []);
          }),
        );
      }

      // Wait for all partial loads to complete
      await Future.wait(futures);

      if (kDebugMode) {
        debugPrint('✅ HomeController: Partial endpoints loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HomeController: Error loading from partial endpoints - $e');
      }
      rethrow;
    }
  }

  @override
  void onClose() {
    _moduleWorker?.dispose();
    super.onClose();
  }
}
