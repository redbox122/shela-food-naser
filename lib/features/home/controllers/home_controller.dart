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
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';

class HomeController extends GetxController implements GetxService {
  final HomeServiceInterface homeServiceInterface;
  HomeController({required this.homeServiceInterface});

  // 🔧 FIX: Track last loaded module to prevent duplicate loads (Cold Start Loop Prevention)
  int? _lastLoadedModuleId;
  int? _lastLoadedZoneId;

  // 🔧 FIX: Track if initial load has happened to prevent Cold Start Loop
  bool _hasInitialLoadCompleted = false;

  @override
  void onInit() {
    super.onInit();

    if (kDebugMode) {
      print('🏠 HomeController.onInit() - Setting up reactive workers');
    }

    // 🔧 FIX 2: Worker 1 - إعادة التحميل فور تغير الموديول (مطاعم، متاجر، إلخ)
    // 🛡️ LOOP PREVENTION: Only fires when module ACTUALLY changes to a DIFFERENT value
    if (Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();
      ever(splashController.selectedModule, (module) {
        // 🛡️ Guard 1: Skip if module is null
        if (module == null) {
          if (kDebugMode) {
            print('⏭️ HomeController: Module is null - skipping reload');
          }
          return;
        }

        // 🛡️ Guard 2: Skip if this is the SAME module as last successful load
        // This is the KEY fix for Cold Start Loop
        if (_lastLoadedModuleId != null && _lastLoadedModuleId == module.id) {
          if (kDebugMode) {
            print(
                '⏭️ HomeController: Same module (${module.id}) - skipping reload (Loop Prevention)');
          }
          return;
        }

        // 🛡️ Guard 3: For first load, only proceed if module has valid ID
        if (!_hasInitialLoadCompleted && module.id == null) {
          if (kDebugMode) {
            print(
                '⏭️ HomeController: First load but module.id is null - skipping');
          }
          return;
        }

        // ✅ Valid module change detected - proceed with load
        final previousModuleId = _lastLoadedModuleId;
        _lastLoadedModuleId = module.id;
        _hasInitialLoadCompleted = true;

        if (kDebugMode) {
          print(
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
      print('✅ HomeController.onInit() completed - Workers registered');
    }

    // Fallback: use cached business settings from SplashController if available
    if (_business_Settings == null && Get.isRegistered<SplashController>()) {
      final splashController = Get.find<SplashController>();
      if (splashController.cachedBusinessSettings != null) {
        setBusinessSettingsFromAppInit(
            splashController.cachedBusinessSettings!);
        if (kDebugMode) {
          print(
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
        print('⏭️ HomeController: ZoneID is 0 - skipping reload');
      }
      return;
    }

    // Prevent duplicate loads for the same zone
    if (_lastLoadedZoneId == newZoneId) {
      if (kDebugMode) {
        print('⏭️ HomeController: Same zone ($newZoneId) - skipping reload');
      }
      return;
    }

    _lastLoadedZoneId = newZoneId;

    if (kDebugMode) {
      print(
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
        print(
            '✅ HomeController: ApiClient headers updated (moduleId: $moduleId, zoneIds: ${address?.zoneIds})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ HomeController: Error updating ApiClient headers - $e');
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
        print('🔄 HomeController: Data source changed to ${source.name}');
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
        print(
            '⚠️ HomeController: Ignoring bootstrap settings - existing settings preserved');
      }
      return;
    }
    _business_Settings = settings;
    update();
    if (kDebugMode) {
      print('✅ HomeController: Business settings set from bootstrap');
    }
  }

  /// Set business settings from app-init endpoint
  /// Converts BusinessSettings (app-init) to BusinessSettingsModel
  void setBusinessSettingsFromAppInit(BusinessSettings appInitSettings) {
    _business_Settings = _convertAppInitBusinessSettings(appInitSettings);
    update();
    if (kDebugMode) {
      print('✅ HomeController: Business settings set from app-init');
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
    if (kDebugMode) {
      print(
          '🏠 HomeController: loadHomeData called (forcePartial: $forcePartial, forceRefresh: $forceRefresh)');
    }

    // 🔧 FIX 1: Check if current module is "food" type (restaurants or cafes)
    // Food modules MUST use V2 unified endpoint - no fallback allowed
    bool isFoodModule = false;
    if (Get.isRegistered<SplashController>()) {
      final moduleType = Get.find<SplashController>().module?.moduleType;
      isFoodModule = moduleType == 'food';
      if (kDebugMode && isFoodModule) {
        print(
            '🍽️ HomeController: Food module detected - V2 only mode (no fallback)');
      }
    }

    // Decide data source
    // 🔧 FIX 1: Food modules always use unified (never partial)
    final shouldUsePartial = !isFoodModule &&
        (forcePartial || _dataSource == HomeDataSource.partial);

    if (shouldUsePartial) {
      if (kDebugMode) {
        print('📡 HomeController: Using partial endpoints (fallback mode)');
      }
      await _loadPartialHome(forceRefresh);
    } else {
      if (kDebugMode) {
        print('⚡ HomeController: Attempting unified endpoint first');
      }
      final success = await _loadUnifiedHome(forceRefresh);
      if (!success) {
        // 🔧 FIX 1: Food modules do NOT fall back - stay on loading until V2 succeeds
        if (isFoodModule) {
          if (kDebugMode) {
            print(
                '🛡️ HomeController: Food module - NO fallback to partial (V2 required)');
            print(
                '   → User will see loading state until V2 endpoint returns data');
          }
          // Do NOT call _loadPartialHome() for food modules
          // This forces the app to wait for V2 endpoint
        } else {
          if (kDebugMode) {
            print(
                '⚠️ HomeController: Unified endpoint failed, falling back to partial');
          }
          await _loadPartialHome(forceRefresh);
        }
      }
    }
  }

  /// Load home data from unified endpoint
  /// Returns true if successful, false otherwise
  Future<bool> _loadUnifiedHome(bool forceRefresh) async {
    try {
      // Check if HomeUnifiedController is registered
      if (!Get.isRegistered<HomeUnifiedController>()) {
        if (kDebugMode) {
          print(
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

      if (success) {
        if (kDebugMode) {
          print('✅ HomeController: Unified endpoint loaded successfully');
        }
        _dataSource = HomeDataSource.unified;
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeController: Error loading from unified endpoint - $e');
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
      if (kDebugMode) {
        print('📡 HomeController: Loading from partial endpoints');
      }

      _dataSource = HomeDataSource.partial;

      // Load data from individual controllers in parallel
      final futures = <Future<void>>[];

      // Load categories
      if (Get.isRegistered<CategoryController>()) {
        futures.add(
          Get.find<CategoryController>()
              .getCategoryList(forceRefresh)
              .catchError((dynamic e) {
            if (kDebugMode) {
              print('⚠️ HomeController: Error loading categories - $e');
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
              print('⚠️ HomeController: Error loading stores - $e');
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
              print('⚠️ HomeController: Error loading banners - $e');
            }
            return BannerModel(banners: [], campaigns: []);
          }),
        );
      }

      // Wait for all partial loads to complete
      await Future.wait(futures);

      if (kDebugMode) {
        print('✅ HomeController: Partial endpoints loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeController: Error loading from partial endpoints - $e');
      }
      rethrow;
    }
  }
}
