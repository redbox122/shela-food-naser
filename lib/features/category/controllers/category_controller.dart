// ignore_for_file: avoid_print, unused_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/core/error/error_handler.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart' show CancelToken;

// #region agent log helper
void _writeDebugLog(String location, String message, Map<String, dynamic> data,
    String hypothesisId) {
  if (!kDebugMode || !AppConstants.enableVerboseLogs) {
    return;
  }
  unawaited(_writeDebugLogAsync(location, message, data, hypothesisId));
}

Future<void> _writeDebugLogAsync(String location, String message,
    Map<String, dynamic> data, String hypothesisId) async {
  if (!kDebugMode || !AppConstants.enableVerboseLogs) {
    return;
  }
  try {
    const logPath = r'c:\Users\pc\Desktop\clone\app-test\.cursor\debug.log';
    final logFile = File(logPath);
    final logDir = logFile.parent;
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final logEntry = {
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
    };
    await logFile.writeAsString('${jsonEncode(logEntry)}\n',
        mode: FileMode.append);
  } catch (e) {
    // Silently fail - don't break the app
  }
}
// #endregion

class CategoryController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;
  final SearchServiceInterface searchServiceInterface;

  CategoryController(
      {required this.categoryServiceInterface,
      required this.searchServiceInterface});

  @override
  void onInit() {
    super.onInit();
    // ⚡ SINGLETON VERIFICATION: Log instance hash to detect multiple instances
    // If you see multiple different hashCodes in logs, there are multiple instances (BUG)
    // If you see same hashCode always, singleton is working correctly ✅
    if (kDebugMode) {
      debugPrint('🧠 CategoryController INIT: hashCode=$hashCode');
    }
  }

  //

  // 🔧 TASK 1: CATEGORY DATA ISOLATION - Separate buckets for Home and Store
  List<CategoryModel>?
      _homeCategoryList; // For Home Screen (NEVER overwritten by Store)
  List<CategoryModel>? _storeCategoryList; // For Store Menu
  List<CategoryModel>?
      _categoryList; // Deprecated - use _homeCategoryList or _storeCategoryList
  int? _homeCategoryModuleId;
  int? get homeCategoryModuleId => _homeCategoryModuleId;
  // Preserve last known good lists to avoid UI disappearing on transient empty responses
  List<CategoryModel>? _lastNonEmptyHomeCategoryList;
  List<CategoryModel>? _lastNonEmptyStoreCategoryList;
  bool hasHomeCategoriesForModule(int? moduleId) {
    if (moduleId == null) return false;
    return _homeCategoryList != null &&
        _homeCategoryList!.isNotEmpty &&
        _homeCategoryModuleId == moduleId;
  }

  List<CategoryModel>? get categoryList {
    // Return store categories if we're on a store detail screen, otherwise home categories
    try {
      if (Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        if (storeController.store != null) {
          // If store categories are not ready, fall back to home categories
          if (_storeCategoryList != null && _storeCategoryList!.isNotEmpty) {
            return _storeCategoryList;
          }
          return _homeCategoryList ?? _categoryList;
        }
      }
    } catch (e) {
      // StoreController not available - return home categories
    }
    return _homeCategoryList ??
        _categoryList; // Fallback to legacy _categoryList for compatibility
  }

  // ⚡ PERFORMANCE: Progressive loading - show initial batch immediately
  List<CategoryModel>? _initialCategoryBatch;
  List<CategoryModel>? _initialHomeCategoryBatch;
  List<CategoryModel>? _initialStoreCategoryBatch;
  List<CategoryModel>? get initialCategoryBatch {
    // Return store batch if we're on a store detail screen, otherwise home batch
    try {
      if (Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        if (storeController.store != null) {
          // If store batch is not ready, fall back to home batch
          if (_initialStoreCategoryBatch != null &&
              _initialStoreCategoryBatch!.isNotEmpty) {
            return _initialStoreCategoryBatch;
          }
          return _initialHomeCategoryBatch ?? _initialCategoryBatch;
        }
      }
    } catch (e) {
      // StoreController not available - return home batch
    }
    return _initialHomeCategoryBatch ??
        _initialCategoryBatch; // Fallback to legacy for compatibility
  }

  /// 🎯 PERFORMANCE: Pre-computed filtered category list (no calculations in build)
  /// Filters out categories with null id
  List<CategoryModel> getFilteredCategoryList(
      List<CategoryModel>? originalList) {
    if (originalList == null) return [];
    // Filter out categories with null id (single pass)
    return originalList.where((value) => value.id != null).toList();
  }

  CategoryModel? _findCategoryById(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return null;
    }
    final int? parsedId = int.tryParse(categoryId);
    if (parsedId == null) {
      return null;
    }
    final List<CategoryModel>? candidates =
        _homeCategoryList ?? _storeCategoryList ?? _categoryList;
    if (candidates == null) {
      return null;
    }
    for (final category in candidates) {
      if (category.id == parsedId) {
        return category;
      }
    }
    return null;
  }

  bool _isLoadingMoreCategories = false;
  bool get isLoadingMoreCategories => _isLoadingMoreCategories;

  // ✅ Lazy loading: عدد الأقسام المرئية
  int visibleCount = 6;
  int _homeCategoryLoadToken = 0;
  final int loadStep = 5;

  void logRenderCategoryCount({required String contextLabel, int? hardCap}) {
    final List<CategoryModel>? list = categoryList;
    final int total = list?.length ?? 0;
    final int cap = hardCap ?? total;
    final int renderCount = total < cap ? total : cap;
    debugPrint(
      '🧭 CategoryController: renderCount=$renderCount (total=$total, cap=${hardCap ?? "none"}, visibleCount=$visibleCount, context=$contextLabel)',
    );
  }

  /// ✅ تحميل المزيد من الأقسام عند الـ scroll
  void loadMoreCategories() {
    final currentList = categoryList;
    if (currentList != null && visibleCount < currentList.length) {
      visibleCount += loadStep;

      if (visibleCount > currentList.length) {
        visibleCount = currentList.length;
      }

      // ✅ Logging للتأكد من عمل الدالة
      if (kDebugMode) {
        print('🧩 Categories visible: $visibleCount / ${currentList.length}');
      }

      update(); // GetX
    }
  }

  // Deep equality checker for categories
  static const DeepCollectionEquality _deepEquality = DeepCollectionEquality();

  List<CategoryModel>? _subCategoryList;
  List<CategoryModel>? get subCategoryList => _subCategoryList;

  // ⚡ RACE CONDITION FIX: Track request ID and parent category ID to prevent stale state
  String? _currentSubCategoryRequestId;
  int? _currentParentCategoryId;

  List<CategoryModel>? _subSubCategoryList;
  List<CategoryModel>? get subSubCategoryList => _subSubCategoryList;

  List<Item>? _categoryItemList;
  List<Item>? get categoryItemList => _categoryItemList;
  final Map<String, String> _categoryPageSignatureByKey = {};
  final Map<String, int> _inFlightCategoryItemOffsets = {};
  final Map<String, int> _inFlightCategoryStoreOffsets = {};
  final Map<String, int> _lastCompletedCategoryItemOffsets = {};
  final Map<String, int> _lastCompletedCategoryStoreOffsets = {};
  CancelToken? _categoryItemsCancelToken;

  // ⚡ GENERATION ID: Prevents stale pagination responses from being applied
  // When switching categories quickly, older requests may complete after newer ones
  // Generation ID ensures only the latest category's data is applied
  int _categoryItemGeneration = 0;
  int get categoryItemGeneration => _categoryItemGeneration;
  String? _currentCategoryItemId;

  /// ⚡ FIX: Deduplicate by NAME (not just ID)
  /// Backend may have same product with different IDs
  /// Use name + storeId as the unique key to prevent visual duplicates
  String _itemDedupKey(Item item) {
    final rawName = (item.name ?? '').trim().toLowerCase();
    final normalizedName = _normalizeItemName(rawName);
    final storeId = item.storeId?.toString() ?? '';
    final bool isEcommerce =
        (Get.find<SplashController>().module?.moduleType.toString() ?? '') ==
            AppConstants.ecommerce;
    // For ecommerce (or when storeId is missing), dedupe by name only to avoid repeated names.
    if (isEcommerce || storeId.isEmpty) {
      return 'name:$normalizedName';
    }
    // Use name + storeId as key (same product from same store = duplicate)
    return 'name:$normalizedName|store:$storeId';
  }

  static String _normalizeItemName(String input) {
    final withoutFormatChars = input.replaceAll(
        RegExp(r'[\u200e\u200f\u200c\u200d\u2066-\u2069\ufeff]'), '');
    final withoutTatweel = withoutFormatChars.replaceAll('\u0640', '');
    final withoutDiacritics =
        withoutTatweel.replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), '');
    final normalizedArabic = withoutDiacritics
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي');
    final normalizedDashes =
        normalizedArabic.replaceAll('–', '-').replaceAll('—', '-');
    return normalizedDashes.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _cancelCategoryItemsRequest() {
    if (_categoryItemsCancelToken != null &&
        !(_categoryItemsCancelToken?.isCancelled ?? true)) {
      _categoryItemsCancelToken!.cancel('Category filter changed');
    }
    _categoryItemsCancelToken = null;
  }

  void _resetItemsForCategorySwitch() {
    _cancelCategoryItemsRequest();
    if (_categoryItemList != null) {
      _categoryItemList!.clear();
    }
    _categoryItemList = null;
    _offset = 0;
    _pageSize = 0;
    _isLoading = false;
    _categoryPageSignatureByKey.clear();
    _inFlightCategoryItemOffsets.clear();
    _lastCompletedCategoryItemOffsets.clear();
    update();
  }

  void _resetStateForSectionSwitch() {
    _cancelCategoryItemsRequest();
    if (_categoryItemList != null) {
      _categoryItemList!.clear();
    }
    _categoryItemList = null;
    if (_subCategoryList != null) {
      _subCategoryList!.clear();
    }
    _subCategoryList = null;
    if (_subSubCategoryList != null) {
      _subSubCategoryList!.clear();
    }
    _subSubCategoryList = null;
    _subCategoryIndex = 0;
    _subSubCategoryIndex = 0;
    _offset = 0;
    _pageSize = 0;
    _isLoading = false;
    _categoryPageSignatureByKey.clear();
    _inFlightCategoryItemOffsets.clear();
    _lastCompletedCategoryItemOffsets.clear();
    update(['sub_categories']);
    update();
  }

  List<Store>? _categoryStoreList;
  List<Store>? get categoryStoreList => _categoryStoreList;

  List<Item>? _searchItemList = [];
  List<Item>? get searchItemList => _searchItemList;

  List<Store>? _searchStoreList = [];
  List<Store>? get searchStoreList => _searchStoreList;

  // 🎯 PERFORMANCE: Pre-computed getters to avoid calculations in build()
  /// Returns items list based on search state (pre-computed in controller)
  List<Item>? get displayItemList {
    if (_isSearching) {
      return _searchItemList;
    }
    return _categoryItemList;
  }

  /// Returns stores list based on search state (pre-computed in controller)
  List<Store>? get displayStoreList {
    if (_isSearching) {
      return _searchStoreList;
    }
    return _categoryStoreList;
  }

  List<bool>? _interestSelectedList;
  List<bool>? get interestSelectedList => _interestSelectedList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _pageSize = 0;
  int? get pageSize => _pageSize;

  int _restPageSize = 0;
  int? get restPageSize => _restPageSize;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  int _subCategoryIndex = 0;
  int get subCategoryIndex => _subCategoryIndex;

  int _subSubCategoryIndex = 0;
  int get subSubCategoryIndex => _subSubCategoryIndex;

  String _type = 'all';
  String get type => _type;

  bool _isStore = false;
  bool get isStore => _isStore;

  final String _searchText = '';
  String? get searchText => _searchText;

  int _offset = 1;
  int get offset => _offset;

  bool _isVertical = false;
  bool get isVertical => _isVertical;

  bool _isPriceAscending = true; // ✅ Mutable
  bool get isPriceAscending => _isPriceAscending;

  String _currentProductArrangement = 'popular';
  String _currentMinPrice = '';
  String _currentMaxPrice = '';
  bool _currentHasDiscount = false;
  String _currentSearchName = '';
  String get currentProductArrangement => _currentProductArrangement;
  String get currentMinPrice => _currentMinPrice;
  String get currentMaxPrice => _currentMaxPrice;
  bool get currentHasDiscount => _currentHasDiscount;
  String get currentSearchName => _currentSearchName;

  // ==================================================================================

  void set_Price(bool value) {
    _isPriceAscending = value;
    update();
  }

  void setVerticalItems(bool value) {
    _isVertical = value;
    update();
  }

  /// Reset category item/store pagination and clear cached lists when entering a new category.
  void resetCategoryPagination({bool notify = true}) {
    _offset = 1;
    _pageSize = 0;
    _restPageSize = 0;
    _isLoading = false;
    _isSearching = false;
    _categoryItemList = null;
    _categoryStoreList = null;
    _searchItemList = [];
    _searchStoreList = [];
    _categoryPageSignatureByKey.clear();
    _inFlightCategoryItemOffsets.clear();
    _inFlightCategoryStoreOffsets.clear();
    _lastCompletedCategoryItemOffsets.clear();
    _lastCompletedCategoryStoreOffsets.clear();
    if (notify) {
      update();
    }
  }

  Future<void> clearCacheForCategory(int? categoryId) async {
    if (categoryId == null) return;
    try {
      await categoryServiceInterface.clearCategoryItemCache(categoryId);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ CategoryController.clearCacheForCategory failed: $e');
      }
    }
  }

  /// Clears all cached category data.
  ///
  /// Setting the lists to `null` (instead of empty collections) ensures the
  /// UI recognises that data is **still loading** and displays the proper
  /// shimmer placeholders.  An empty list was previously interpreted by the
  /// widgets as "nothing to show", which resulted in the category section
  /// disappearing while new data was still being fetched after a module or
  /// tab switch.
  void clearCategoryList(
      {bool skipUpdate = false, bool isStoreDetail = false}) {
    // #region agent log
    _writeDebugLog(
        'category_controller.dart:114',
        'clearCategoryList called',
        {
          'previousHomeCategoryListLength': _homeCategoryList?.length ?? 'null',
          'previousStoreCategoryListLength':
              _storeCategoryList?.length ?? 'null',
          'isStoreDetail': isStoreDetail,
        },
        'A');
    // #endregion
    // 🔧 TASK 1: Clear only the appropriate list based on context
    if (isStoreDetail) {
      _storeCategoryList = null;
      _initialStoreCategoryBatch = null;
    } else {
      _homeCategoryList = null;
      _homeCategoryModuleId = null;
      _initialHomeCategoryBatch = null;
    }
    // Keep legacy for compatibility
    _categoryList = null;
    _initialCategoryBatch = null;
    _interestSelectedList = null;
    // ⚡ FIX: Defer update() if widget tree is locked (during dispose)
    if (!skipUpdate) {
      // Schedule update for next frame to avoid setState() during dispose
      Future.microtask(() {
        if (Get.isRegistered<CategoryController>()) {
          update();
        }
      });
    }
  }

  /// ⚡ TITAN BOARD: Reset controller to default state without deleting instance
  /// Used during module switching to preserve controller in memory
  Future<void> resetToDefault() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 CategoryController: Resetting to default state');
      }

      // Clear all lists
      _homeCategoryList = null;
      _storeCategoryList = null;
      _homeCategoryModuleId = null;
      _categoryList = null; // Legacy
      _initialHomeCategoryBatch = null;
      _initialStoreCategoryBatch = null;
      _initialCategoryBatch = null; // Legacy
      _subCategoryList = null;
      _currentSubCategoryRequestId =
          null; // ⚡ RACE CONDITION FIX: Clear request ID tracking
      _currentParentCategoryId =
          null; // ⚡ RACE CONDITION FIX: Clear parent ID tracking
      _subSubCategoryList = null;
      _categoryItemList = null;
      _categoryStoreList = null;
      _interestSelectedList = null;

      // Reset search lists (empty, not null)
      _searchItemList = [];
      _searchStoreList = [];

      // Reset state flags
      _isLoading = false;
      _isSearching = false;
      _isLoadingMoreCategories = false;

      // ✅ إعادة تعيين visibleCount
      visibleCount = 6;

      // Reset pagination
      _pageSize = 0;
      _offset = 1;

      // Reset filters
      _type = 'all';
      _isStore = false;
      _isVertical = false;

      // Reset indices
      _subCategoryIndex = 0;
      _subSubCategoryIndex = 0;

      if (kDebugMode) {
        debugPrint('✅ CategoryController: Reset to default state completed');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ CategoryController.resetToDefault: Error - $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Set category data from bootstrap endpoint
  /// ⚡ PERFORMANCE: Uses progressive loading - shows first 4 categories immediately
  void setCategoryDataFromBootstrap(List<CategoryModel> categories) {
    // Use _prepareCategoryList to enable progressive loading and filtering
    _prepareCategoryList(categories);
    if (kDebugMode) {
      print(
          '✅ CategoryController: Category data set from bootstrap (${categories.length} categories)');
      if (_initialCategoryBatch != null) {
        print(
            '⚡ CategoryController: Initial batch ready (${_initialCategoryBatch!.length} categories)');
      }
    }
  }

  /// 🎯 API OVERLAP FIX: Set category data from unified endpoint
  ///
  /// This method is called by HomeController when data comes from unified endpoint.
  /// It's a safe setter that doesn't trigger API calls.
  void setFromUnified(List<CategoryModel>? data) {
    if (data == null || data.isEmpty) {
      if (kDebugMode) {
        print(
            '⚠️ CategoryController: setFromUnified called with null or empty data');
      }
      return;
    }

    // Use _prepareCategoryList to enable progressive loading and filtering
    _prepareCategoryList(data);

    if (kDebugMode) {
      print(
          '✅ CategoryController: Category data set from unified endpoint (${data.length} categories)');
    }
  }

  Future<List<CategoryModel>?> getCategoryList(bool reload,
      {bool allCategory = false,
      DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    // OPTIMIZATION: Early return if categories already loaded and no reload requested
    // This prevents redundant cache reads and API calls when navigating between screens
    if (!reload &&
        !fromRecall &&
        _categoryList != null &&
        _categoryList!.isNotEmpty) {
      print(
          '✅ CategoryController: Categories already loaded (${_categoryList!.length}), skipping redundant fetch');
      return _categoryList;
    }

    // Load from cache/API when needed
    if (_categoryList == null ||
        reload ||
        fromRecall ||
        dataSource == DataSourceEnum.local) {
      //
      List<CategoryModel>? categoryList;

      // Settings ===============

      // ⚠️ CRITICAL: Handle case when HomeController is not registered
      HomeController? homeController;
      try {
        if (Get.isRegistered<HomeController>()) {
          homeController = Get.find<HomeController>();
        }
      } catch (e) {
        print('⚠️ CategoryController: HomeController not available: $e');
      }
      final businessSettings = homeController?.business_Settings;

      // Log business settings for debugging
      if (businessSettings?.categoriesSection?.toString() != '1') {
        print(
            '⚠️ CategoryController: Categories section is disabled in business settings (categoriesSection: ${businessSettings?.categoriesSection})');
      } else {
        print(
            '✅ CategoryController: Categories section is enabled (categoriesSection: 1)');
      }

      //

      // ⚡ CACHE FIRST: Check comprehensive cache before making API calls
      if (!reload && dataSource != DataSourceEnum.client) {
        try {
          final cachedData =
              await ComprehensiveHomeCacheManager.loadAllHomeData();
          if (cachedData.containsKey('categories')) {
            final categoryData =
                cachedData['categories'] as Map<String, dynamic>;
            if (categoryData['categoryList'] != null) {
              final cachedCategoryList = (categoryData['categoryList'] as List)
                  .map((json) =>
                      CategoryModel.fromJson(json as Map<String, dynamic>))
                  .toList();
              if (cachedCategoryList.isNotEmpty) {
                print(
                    '✅ CategoryController: Loading ${cachedCategoryList.length} categories from comprehensive cache');
                _prepareCategoryList(cachedCategoryList);
                return _categoryList;
              }
            }
          }
        } catch (e) {
          print(
              '⚠️ CategoryController: Error loading from comprehensive cache: $e');
        }
      }

      try {
        if (dataSource == DataSourceEnum.local) {
          categoryList = await categoryServiceInterface
              .getCategoryList(allCategory, source: DataSourceEnum.local);

          _prepareCategoryList(categoryList);
          // Don't automatically call API when loading from cache
          // The background refresh will handle API updates
        } else {
          categoryList = await categoryServiceInterface
              .getCategoryList(allCategory, source: DataSourceEnum.client);

          _prepareCategoryList(categoryList);
        }
      } catch (e) {
        // 🎯 ERROR HANDLER PILOT: Use unified error handling (logging only, no UI changes)
        ErrorHandler().handleError(
          e,
          context: 'CategoryController.getCategoryList',
          showSnackbar: false, // No UI changes in pilot phase
          logError: true,
        );
        // Preserve existing behavior - return null on error
        return null;
      }
    }
    return _categoryList;
  }

  void _prepareCategoryList(List<CategoryModel>? categoryList) {
    // #region agent log
    _writeDebugLog(
        'category_controller.dart:253',
        '_prepareCategoryList entry',
        {
          'inputCategoryListIsNull': categoryList == null,
          'inputCategoryListLength': categoryList?.length ?? 'null',
          'previousCategoryListLength': _categoryList?.length ?? 'null',
          'useBffV2Endpoint': AppConstants.useBffV2Endpoint,
        },
        'A');
    // #endregion

    // Debug: Log input categories for troubleshooting
    if (categoryList != null && categoryList.isNotEmpty) {
      print(
          '🔍 CategoryController: _prepareCategoryList called with ${categoryList.length} categories');
      print(
          '🔍 CategoryController: useBffV2Endpoint = ${AppConstants.useBffV2Endpoint}');
      // Log first 3 categories for debugging
      final sampleCount = categoryList.length > 3 ? 3 : categoryList.length;
      for (int i = 0; i < sampleCount; i++) {
        final cat = categoryList[i];
        print(
            '   [Sample $i] id: ${cat.id}, name: ${cat.name}, module_id: ${cat.moduleId}, store_id: ${cat.storeId}');
      }
    } else if (categoryList != null && categoryList.isEmpty) {
      print(
          '⚠️ CategoryController: _prepareCategoryList called with EMPTY list (0 categories)');
    } else {
      print(
          '⚠️ CategoryController: _prepareCategoryList called with NULL categoryList');
    }

    // Preserve existing categories if a transient empty/null response arrives
    final bool hasExistingCategories =
        (_homeCategoryList?.isNotEmpty ?? false) ||
            (_storeCategoryList?.isNotEmpty ?? false) ||
            (_categoryList?.isNotEmpty ?? false);
    if ((categoryList == null || categoryList.isEmpty) &&
        hasExistingCategories) {
      if (kDebugMode) {
        print(
            '✅ CategoryController: Empty categories received - preserving existing categories');
      }
      return;
    }

    // Snapshot current lists for deep equality check before mutations.
    final List<Map<String, dynamic>>? oldHomeJson =
        _homeCategoryList?.map((category) => category.toJson()).toList();
    final List<Map<String, dynamic>>? oldStoreJson =
        _storeCategoryList?.map((category) => category.toJson()).toList();

    // 🔧 TASK 1: ECOMMERCE CATEGORY BYPASS - If request is for a Store (Restaurant OR Ecommerce Shop), DISABLE ALL FILTERS
    // Check if we're on a store detail screen by checking if StoreController has a store
    bool isStore = false;
    try {
      if (Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        isStore = storeController.store != null;
        if (isStore && kDebugMode) {
          print(
              '✅ CategoryController: Store detail screen detected (Store ID: ${storeController.store?.id}) - DISABLING ALL FILTERS');
          print(
              '   📦 Returning all ${categoryList?.length ?? 0} categories without filtering');
        }
      }
    } catch (e) {
      // StoreController not available - not a store detail screen
      if (kDebugMode) {
        print(
            '🔍 CategoryController: StoreController not available or error: $e');
      }
    }

    if (isStore && categoryList != null) {
      // 🔧 TASK 1: CATEGORY DATA ISOLATION - Store categories NEVER overwrite Home categories
      // For Store Details, we TRUST the backend. Do not filter by count, do not filter by module.
      // Populate ONLY _storeCategoryList - _homeCategoryList remains untouched
      _storeCategoryList = List.from(categoryList);
      if (_storeCategoryList!.isNotEmpty) {
        _lastNonEmptyStoreCategoryList = List.from(_storeCategoryList!);
      }
      // ✅ إعادة تعيين visibleCount عند تحميل بيانات جديدة
      visibleCount = 6;
      // Only update _interestSelectedList if it's null or needs to match store category count
      if (_interestSelectedList == null ||
          _interestSelectedList!.length != categoryList.length) {
        _interestSelectedList =
            List.generate(categoryList.length, (index) => false);
      }
      _initialStoreCategoryBatch = categoryList.length > visibleCount
          ? categoryList.sublist(0, visibleCount)
          : categoryList;

      // Legacy support - update _categoryList for backward compatibility
      _categoryList = _storeCategoryList;
      _initialCategoryBatch = _initialStoreCategoryBatch;

      if (kDebugMode) {
        print(
            '✅ CategoryController: Store categories set - ${_storeCategoryList!.length} categories (Home categories preserved: ${_homeCategoryList?.length ?? 0})');
      }

      update();
      return;
    }

    if (categoryList != null) {
      // 🔧 TASK 1: CATEGORY DATA ISOLATION - Always populate _homeCategoryList for Home Screen
      _homeCategoryList = [];
      _interestSelectedList = [];
      // Legacy support - will be updated later
      _categoryList = [];

      // ✅ Lazy loading: استخدام visibleCount بدلاً من رقم ثابت
      // This allows the categories section (first section) to render quickly with only 6 categories

      // Get current module ID for filtering (matches backend documentation requirements)
      final splashController = Get.find<SplashController>();
      final currentModuleId = splashController.module?.id;
      _homeCategoryModuleId = currentModuleId;

      // ⚠️ CRITICAL: When using v2/home-unified endpoint, backend has ALREADY filtered categories by module
      // We should NOT filter by module_id again, only filter by store_id to exclude restaurant menu categories
      const bool useV2Endpoint = AppConstants.useBffV2Endpoint;

      // Step 1: Filter by module_id and store_id
      // Per Module 6 API documentation: Only show module-level cuisine categories (store_id == null)
      // Restaurant menu categories have store_id != null and should be excluded
      List<CategoryModel> moduleFilteredList;

      if (useV2Endpoint) {
        // ⚡ V2 ENDPOINT: Backend has already filtered by module_id, TRUST the backend and DISABLE client-side module_id filtering
        // Only filter by store_id (exclude restaurant menu categories)
        if (kDebugMode) {
          print(
              '✅ CategoryController: [BFF v2] Using v2 endpoint - TRUSTING backend, DISABLING module_id filter');
          print(
              '🔍 CategoryController: [BFF v2] Input categories count: ${categoryList.length}');
          print(
              '🔍 CategoryController: [BFF v2] Current module ID from SplashController: $currentModuleId');
        }

        int filteredByStore = 0;
        for (final category in categoryList) {
          if (category.storeId != null) filteredByStore++;
        }

        // ⚡ FIX: Only filter by store_id (exclude restaurant menu categories)
        // DO NOT filter by module_id - backend has already done this
        moduleFilteredList =
            categoryList.where((category) => category.storeId == null).toList();

        if (kDebugMode) {
          if (filteredByStore > 0) {
            print(
                '⚠️ CategoryController: [BFF v2] Filtered out $filteredByStore store-specific categories (store_id != null)');
          }
          print(
              '✅ CategoryController: [BFF v2] After store_id filter: ${moduleFilteredList.length} categories (from ${categoryList.length} total)');
          print(
              '✅ CategoryController: [BFF v2] Module_id filtering DISABLED - trusting backend');

          // Debug: Log sample categories to verify they're not being filtered incorrectly
          if (moduleFilteredList.isEmpty && categoryList.isNotEmpty) {
            print(
                '❌ CategoryController: [BFF v2] WARNING: All categories filtered out! Sample categories:');
            for (int i = 0;
                i < (categoryList.length > 3 ? 3 : categoryList.length);
                i++) {
              final cat = categoryList[i];
              print(
                  '   [$i] id: ${cat.id}, name: ${cat.name}, module_id: ${cat.moduleId}, store_id: ${cat.storeId}');
            }
          }
        }
      } else if (currentModuleId != null) {
        // V1 ENDPOINT: Filter by both module_id and store_id (safety net - repository should already filter)
        // Count filtered categories for logging (count before filtering)
        int filteredByModule = 0;
        int filteredByStore = 0;

        // First pass: count filtered categories
        for (final category in categoryList) {
          if (category.moduleId != null) {
            if (category.moduleId != currentModuleId) filteredByModule++;
            if (category.storeId != null) filteredByStore++;
          } else {
            // Category has no moduleId - exclude it
            filteredByModule++;
          }
        }

        // Second pass: filter categories
        moduleFilteredList = categoryList.where((category) {
          // Only include if module matches AND it's a module-level category (store_id == null)
          if (category.moduleId != null) {
            return category.moduleId == currentModuleId &&
                category.storeId == null;
          }
          // Exclude categories without moduleId when we have a current module
          return false;
        }).toList();

        // Log filtering results
        if (filteredByModule > 0 || filteredByStore > 0) {
          print(
              '⚠️ CategoryController: Filtered out $filteredByModule categories by module_id (expected: $currentModuleId)');
          print(
              '⚠️ CategoryController: Filtered out $filteredByStore store-specific categories (store_id != null)');
        }
      } else {
        // No current module - only exclude store-specific categories for backward compatibility
        int filteredByStore = 0;

        // Count before filtering
        for (final category in categoryList) {
          if (category.storeId != null) filteredByStore++;
        }

        // Filter categories
        moduleFilteredList =
            categoryList.where((category) => category.storeId == null).toList();

        if (filteredByStore > 0) {
          print(
              '⚠️ CategoryController: Filtered out $filteredByStore store-specific categories (store_id != null)');
        }
      }

      // Step 2: Filter by parent_id for Module 7 (only top-level categories)
      // IMPORTANT: For Module 7 (moduleId == 7), backend should return only top-level categories (parent_id == 0)
      // But we add client-side filtering as safety net to ensure only parent_id == 0 or null are shown
      final bool isModule7 = currentModuleId == 7;
      List<CategoryModel> parentFilteredList = moduleFilteredList;

      if (isModule7) {
        // For Module 7 (Grocery), only show top-level categories (parent_id == 0 or null)
        // NOTE: Unlike Module 6 (Food) which uses cat_site_id for external API cuisine categories,
        // Module 7 grocery categories are stored directly in the database without cat_site_id
        final int beforeCount = parentFilteredList.length;

        // Debug: Log category details before filtering
        print(
            '🔍 CategoryController: Module 7 - Checking categories for filtering ($beforeCount total):');
        for (int i = 0; i < (beforeCount > 10 ? 10 : beforeCount); i++) {
          final cat = moduleFilteredList[i];
          print(
              '   [$i] id: ${cat.id}, name: ${cat.name}, parent_id: ${cat.parentId}, cat_site_id: ${cat.catSiteId}');
        }

        // Filter: Only show top-level categories (parent_id == 0 or null)
        // No cat_site_id check needed - Module 7 grocery categories don't have this field
        parentFilteredList = moduleFilteredList.where((category) {
          final isTopLevel =
              category.parentId == null || category.parentId == 0;
          return isTopLevel;
        }).toList();
        final int afterCount = parentFilteredList.length;
        if (beforeCount != afterCount) {
          print(
              '⚠️ CategoryController: Module 7 - Filtered out ${beforeCount - afterCount} categories (parent_id != 0), showing $afterCount top-level categories');
        } else {
          print(
              '✅ CategoryController: Module 7 - All $afterCount categories are top-level');
        }
      }

      // Step 3: Filter by productsCount or childesCount
      // IMPORTANT: For Food module (moduleType == 'food'), cuisine categories are used to show restaurants (not products)
      // IMPORTANT: For Module 7 (moduleId == 7), top-level categories are container categories that organize stores
      // Therefore, we should show ALL categories for these modules regardless of productsCount
      // For other modules (E-commerce, etc.), filter by productsCount/childesCount
      final bool isFood = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.food;
      final bool isPharmacy = splashController.module != null &&
          splashController.module!.moduleType.toString() ==
              AppConstants.pharmacy;
      bool storesLoaded = false;
      if (Get.isRegistered<StoreController>()) {
        final storeController = Get.find<StoreController>();
        storesLoaded = storeController.allStoreModel != null ||
            (storeController.popularStoreList != null &&
                storeController.popularStoreList!.isNotEmpty);
      }

      List<CategoryModel> categoryResults;
      if ((isFood || isPharmacy) && !storesLoaded) {
        // Food/Pharmacy: Don't filter by productsCount until stores are loaded
        categoryResults = parentFilteredList;
        if (kDebugMode) {
          print(
              '✅ CategoryController: ${isFood ? 'Food' : 'Pharmacy'} module - skipping productsCount filtering until stores load');
        }
      } else if (isFood || isModule7) {
        // Food module: Show all cuisine categories (module_id matches, store_id == null)
        // These categories are used to show restaurants, not products, so productsCount doesn't matter
        // Module 7: Show all top-level categories (parent_id == 0)
        // These categories are container categories that organize stores, not products, so productsCount doesn't matter
        categoryResults = parentFilteredList;
        if (isFood) {
          print(
              '✅ CategoryController: Food module - showing all ${parentFilteredList.length} cuisine categories (no count filtering - used for restaurants)');
        } else if (isModule7) {
          print(
              '✅ CategoryController: Module 7 - showing all ${parentFilteredList.length} top-level categories (no count filtering - used for store containers)');
        }
      } else {
        // Other modules (E-commerce, etc.): Filter by productsCount or childesCount
        // Show categories that have products OR have children (parent categories)
        categoryResults = parentFilteredList
            .where((test) =>
                test.productsCount > 0 ||
                (test.childesCount != null && test.childesCount! > 0))
            .toList();
        print(
            '✅ CategoryController: Filtered ${categoryList.length} categories to ${moduleFilteredList.length} (module/store filtering) to ${categoryResults.length} (with count filtering)');
      }

      // Debug: Log sample of filtered categories for verification (first 3 categories)
      if (categoryResults.isNotEmpty) {
        print(
            '✅ CategoryController: Final filtered categories count: ${categoryResults.length}');
        print('🔍 CategoryController: Sample filtered categories (first 3):');
        final sampleCount =
            categoryResults.length > 3 ? 3 : categoryResults.length;
        for (int i = 0; i < sampleCount; i++) {
          final cat = categoryResults[i];
          print(
              '   [$i] id: ${cat.id}, name: ${cat.name}, module_id: ${cat.moduleId}, store_id: ${cat.storeId}, productsCount: ${cat.productsCount}, childesCount: ${cat.childesCount}');
        }
      } else {
        print(
            '❌ CategoryController: categoryResults is EMPTY after all filtering!');
        print('   Input count: ${categoryList.length}');
        print('   After module/store filter: ${moduleFilteredList.length}');
        print('   After parent filter: ${parentFilteredList.length}');
        print('   Final count: ${categoryResults.length}');
      }

      // 🔧 TASK 1: CATEGORY DATA ISOLATION - Populate ONLY _homeCategoryList (NEVER _storeCategoryList)
      // This ensures Home Screen data is NEVER overwritten by Store categories
      _homeCategoryList = [];

      // ✅ إعادة تعيين visibleCount عند تحميل بيانات جديدة
      visibleCount = 6;

      // ✅ Lazy loading: عرض visibleCount أقسام فقط في البداية
      // Categories section is the FIRST section, so we need it to load fast
      if (categoryResults.length > visibleCount) {
        // Extract initial batch for immediate display (using visibleCount instead of fixed 15)
        _initialHomeCategoryBatch = categoryResults.sublist(0, visibleCount);
        _homeCategoryList!.addAll(_initialHomeCategoryBatch!);
        if (_homeCategoryList!.isNotEmpty) {
          _lastNonEmptyHomeCategoryList = List.from(_homeCategoryList!);
        }

        // Add interest flags for initial batch
        if (_interestSelectedList == null ||
            _interestSelectedList!.length != _homeCategoryList!.length) {
          _interestSelectedList = [];
          for (int i = 0; i < _initialHomeCategoryBatch!.length; i++) {
            _interestSelectedList!.add(false);
          }
        }

        // Legacy support
        _categoryList = _homeCategoryList;
        _initialCategoryBatch = _initialHomeCategoryBatch;

        // Update UI immediately with initial batch
        update();

        // #region agent log
        _writeDebugLog(
            'category_controller.dart:425',
            '_prepareCategoryList: Initial batch set',
            {
              'initialBatchLength': _initialHomeCategoryBatch?.length ?? 'null',
              'homeCategoryListLength': _homeCategoryList?.length ?? 'null',
            },
            'A');
        // #endregion

        if (kDebugMode) {
          print(
              '⚡ CategoryController: Showing initial batch of ${_initialHomeCategoryBatch!.length} HOME categories immediately (visibleCount: $visibleCount)');
        }

        // ✅ Load ALL remaining categories in background (non-blocking)
        // But UI will only show visibleCount initially, then loadMoreCategories() will add more
        _homeCategoryLoadToken += 1;
        final int loadToken = _homeCategoryLoadToken;
        Future.microtask(() async {
          if (isClosed ||
              _homeCategoryList == null ||
              loadToken != _homeCategoryLoadToken) {
            return;
          }
          _isLoadingMoreCategories = true;
          update();

          // Small delay to let UI render initial batch
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // Add ALL remaining categories to the full list (for lazy loading)
          final remainingCategories = categoryResults.sublist(visibleCount);
          if (isClosed ||
              _homeCategoryList == null ||
              loadToken != _homeCategoryLoadToken) {
            return;
          }
          _homeCategoryList!.addAll(remainingCategories);

          // Legacy support
          _categoryList = _homeCategoryList;

          // #region agent log
          _writeDebugLog(
              'category_controller.dart:441',
              '_prepareCategoryList: Remaining categories added',
              {
                'remainingCategoriesLength': remainingCategories.length,
                'totalHomeCategoryListLength':
                    _homeCategoryList?.length ?? 'null',
              },
              'A');
          // #endregion

          // Add interest flags for remaining categories
          _interestSelectedList ??= [];
          for (int i = 0; i < remainingCategories.length; i++) {
            _interestSelectedList!.add(false);
          }

          _isLoadingMoreCategories = false;
          update();

          if (kDebugMode) {
            print(
                '✅ CategoryController: Loaded remaining ${remainingCategories.length} HOME categories in background');
          }
        });
      } else {
        // All categories fit in initial batch - add them all
        _initialHomeCategoryBatch = categoryResults;
        _homeCategoryList!.addAll(categoryResults);
        if (_homeCategoryList!.isNotEmpty) {
          _lastNonEmptyHomeCategoryList = List.from(_homeCategoryList!);
        }

        // Legacy support
        _categoryList = _homeCategoryList;
        _initialCategoryBatch = _initialHomeCategoryBatch;

        // #region agent log
        _writeDebugLog(
            'category_controller.dart:470',
            '_prepareCategoryList: All categories added at once',
            {
              'homeCategoryListLength': _homeCategoryList?.length ?? 'null',
            },
            'A');
        // #endregion

        _interestSelectedList = [];
        for (int i = 0; i < _homeCategoryList!.length; i++) {
          _interestSelectedList!.add(false);
        }
      }
    }

    // ⚡ ZERO-FLICKER: Deep equality check - only update if data actually changed
    // Compare the final filtered result with existing data AFTER it's been set
    // 🔧 TASK 1: Use correct list for comparison based on context
    final bool isStoreContext = isStore;
    final newCategoryList =
        isStoreContext ? _storeCategoryList : _homeCategoryList;
    final oldJsonSnapshot = isStoreContext ? oldStoreJson : oldHomeJson;

    if (oldJsonSnapshot != null &&
        newCategoryList != null &&
        newCategoryList.isNotEmpty) {
      final newJson =
          newCategoryList.map((category) => category.toJson()).toList();
      if (_deepEquality.equals(oldJsonSnapshot, newJson)) {
        _isLoading = false;
        if (kDebugMode) {
          print(
              '✅ CategoryController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
        }
        return;
      }
    }

    // #region agent log
    _writeDebugLog(
        'category_controller.dart:480',
        '_prepareCategoryList: Final update() call',
        {
          'finalCategoryListLength': _categoryList?.length ?? 'null',
          'initialBatchLength': _initialCategoryBatch?.length ?? 'null',
        },
        'A');
    // #endregion
    update();
  }

  /// Set category list directly from cache (handles both List<CategoryModel> and raw JSON)
  void setCategoryListFromCache(dynamic data) {
    if (data == null) return;

    try {
      List<CategoryModel>? categoryList;

      if (data is List<CategoryModel>) {
        // Already deserialized model objects
        categoryList = data;
      } else if (data is List) {
        // Raw JSON list from disk cache - deserialize it
        categoryList = data
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print(
            '⚠️ CategoryController: Unexpected data type: ${data.runtimeType}');
        return;
      }

      // ⚡ ZERO-FLICKER: Deep equality check - only update if data actually changed
      if (_categoryList != null) {
        final oldJson = _categoryList!.map((c) => c.toJson()).toList();
        final newJson = categoryList.map((c) => c.toJson()).toList();
        if (_deepEquality.equals(oldJson, newJson)) {
          _isLoading = false;
          if (kDebugMode) {
            print(
                '✅ CategoryController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
          }
          return;
        }
      }

      // ✅ إعادة تعيين visibleCount عند تحميل بيانات جديدة
      visibleCount = 6;

      _prepareCategoryList(categoryList);
      print(
          '✅ CategoryController: Loaded ${_categoryList?.length ?? 0} categories from cache');
    } catch (e) {
      print('❌ CategoryController: Error setting categories from cache: $e');
    }
  }

  void getSubCategoryList(String? categoryID,
      {bool forceRefreshItems = false}) async {
    // ⚡ MANDATORY API CALL: Log entry to verify function is always called
    if (kDebugMode) {
      debugPrint(
          '📞 CategoryController.getSubCategoryList ENTRY: categoryID=$categoryID');
    }

    // ⚡ RACE CONDITION FIX: Generate unique request ID for this call
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    _currentSubCategoryRequestId = requestId;

    // Parse category ID to int for comparison
    final int? parsedCategoryId =
        categoryID != null ? int.tryParse(categoryID) : null;

    // 🔹 إذا تغيّر القسم فعلاً → نظّف الحالة
    if (_currentParentCategoryId != parsedCategoryId) {
      _currentParentCategoryId = parsedCategoryId;
      _resetStateForSectionSwitch();
    }

    _subCategoryIndex = 0;
    _subSubCategoryIndex = 0;
    _subSubCategoryList = null;
    _categoryItemList = null;
    final CategoryModel? category = _findCategoryById(categoryID);
    final bool hasChildesCount = (category?.childesCount ?? 0) > 0;
    final bool hasCatSiteId =
        category?.catSiteId != null && category!.catSiteId!.isNotEmpty;
    if (category != null && !hasChildesCount && !hasCatSiteId) {
      // 🛑 تجاهل أي رد قديم
      if (_currentSubCategoryRequestId != requestId) return;

      _subCategoryList = [];
      _subCategoryList!
          .add(CategoryModel(id: int.parse(categoryID!), name: 'all'.tr));
      if (!_isStore) {
        getCategoryItemList(
          categoryID,
          1,
          'all',
          false,
          includeChildren: true,
          forceRefresh: forceRefreshItems,
        );
      }
      // ⚡ PERFORMANCE: Update only subcategories section, not entire page
      update(['sub_categories']);
      return;
    }
    // ⚡ MANDATORY API CALL: Always make API request, regardless of cache or previous state
    if (kDebugMode) {
      debugPrint(
          '📡 CategoryController.getSubCategoryList: Making API call for categoryID=$categoryID');
    }
    final List<CategoryModel>? subCategoryList =
        await categoryServiceInterface.getSubCategoryList(categoryID);

    // 🛑 تجاهل أي رد قديم
    if (_currentSubCategoryRequestId != requestId) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ CategoryController.getSubCategoryList: Ignoring stale response (requestId mismatch)');
      }
      return;
    }

    // Always create subcategory list with "all" option, even if API returns empty array
    // This ensures the UI can still display items/stores even when there are no subcategories
    _subCategoryList = [];
    _subCategoryList!
        .add(CategoryModel(id: int.parse(categoryID!), name: 'all'.tr));
    if (subCategoryList != null && subCategoryList.isNotEmpty) {
      final List<CategoryModel> subSubCategory = subCategoryList.where((test) {
        return test.productsCount > 0;
      }).toList();
      _subCategoryList!.addAll(subSubCategory);
    }
    // ✅ CUISINE CATEGORY FIX: Only fetch items if NOT showing stores
    // For cuisine categories (position=0, cat_site_id <= 3 digits), we show stores, not items
    // Items will be loaded when user switches to items tab manually
    if (!_isStore) {
      getCategoryItemList(
        categoryID,
        1,
        'all',
        false,
        includeChildren: true,
        forceRefresh: forceRefreshItems,
      );
    }
    // ⚡ PERFORMANCE: Update only subcategories section, not entire page
    update(['sub_categories']);
  }

  void getSubSubCategoryList(CategoryModel category) async {
    _subSubCategoryIndex = 0;
    // Always set to null first to hide section immediately
    _subSubCategoryList = null;
    _categoryItemList = null;
    update(); // Update immediately to hide section

    // Early return for "all" category - no sub-subcategories
    if (category.name == 'all'.tr) {
      return;
    }

    // Early return for cuisine categories (cat_site_id length <= 3) - they don't have subcategories
    if (category.catSiteId != null && category.catSiteId!.length <= 3) {
      return;
    }

    final List<CategoryModel>? subCategoryList = await categoryServiceInterface
        .getSubCategoryList(category.id.toString());

    // Only set list if we have actual items
    if (subCategoryList != null && subCategoryList.isNotEmpty) {
      final List<CategoryModel> subSubCategory = subCategoryList.where((test) {
        return test.productsCount > 0;
      }).toList();

      // Only create list if we have items after filtering
      if (subSubCategory.isNotEmpty) {
        _subSubCategoryList = [];
        _subSubCategoryList!.add(CategoryModel(
            id: int.parse(category.id.toString()), name: 'all'.tr));
        _subSubCategoryList!.addAll(subSubCategory);
      }
      // If empty after filtering, _subSubCategoryList stays null (already set above)
    }
    // If API returns null or empty, _subSubCategoryList stays null (already set above)

    update();
  }

  void setSubCategoryIndex(int index, String? categoryID) {
    _subCategoryIndex = index;
    if (_isStore) {
      getCategoryStoreList(
          _subCategoryIndex == 0
              ? categoryID
              : _subCategoryList![index].id.toString(),
          1,
          _type,
          true);
    } else {
      _resetItemsForCategorySwitch();
      getCategoryItemList(
          _subCategoryIndex == 0
              ? categoryID
              : _subCategoryList![index].id.toString(),
          1,
          _type,
          true,
          includeChildren: _subCategoryIndex == 0);
    }
  }

  void setSubSubCategoryIndex(int index, String? categoryID) {
    _subSubCategoryIndex = index;
    if (_isStore) {
      getCategoryStoreList(
          _subSubCategoryIndex == 0
              ? categoryID
              : _subSubCategoryList![index].id.toString(),
          1,
          _type,
          true);
    } else {
      _resetItemsForCategorySwitch();
      getCategoryItemList(
          _subSubCategoryIndex == 0
              ? categoryID
              : _subSubCategoryList![index].id.toString(),
          1,
          _type,
          true,
          includeChildren: _subSubCategoryIndex == 0 ? true : false);
    }
  }

  void getCategoryItemList(
      String? categoryID, int offset, String type, bool notify,
      {bool? includeChildren, bool forceRefresh = false}) async {
    // ✅ CUISINE CATEGORY FIX: Early return if showing stores
    // For cuisine categories (position=0, cat_site_id <= 3 digits), we show stores, not items
    // This prevents cache hits and API calls for items when we should be showing stores
    if (_isStore) {
      if (kDebugMode) {
        print(
            '🚫 CategoryController: Skipping getCategoryItemList - showing stores (categoryId: $categoryID)');
      }
      return;
    }

    // ✅ Enforce fresh pagination when switching categories
    final bool categoryChanged = _currentCategoryItemId != categoryID;
    final int effectiveOffset = (categoryChanged && offset != 1) ? 1 : offset;

    try {
      _offset = effectiveOffset;
      final bool resolvedIncludeChildren =
          includeChildren ?? (_subCategoryIndex == 0);
      final String includeChildrenKey =
          resolvedIncludeChildren ? 'true' : 'false';
      final String requestKey =
          '${categoryID ?? 'null'}|$type|$includeChildrenKey';

      if (forceRefresh) {
        _cancelCategoryItemsRequest();
        _inFlightCategoryItemOffsets.remove(requestKey);
        _lastCompletedCategoryItemOffsets[requestKey] = 0;
        _categoryPageSignatureByKey.remove(requestKey);
      }

      if (effectiveOffset == 1) {
        _lastCompletedCategoryItemOffsets[requestKey] = 0;
        _categoryPageSignatureByKey.remove(requestKey);
      }

      if (_inFlightCategoryItemOffsets[requestKey] == effectiveOffset) {
        if (kDebugMode) {
          print(
              '⚠️ CategoryController: Skipping duplicate in-flight item request (key=$requestKey, offset=$effectiveOffset)');
        }
        return;
      }

      if (effectiveOffset > 1 &&
          (_lastCompletedCategoryItemOffsets[requestKey] ?? 0) >=
              effectiveOffset) {
        if (kDebugMode) {
          print(
              '⚠️ CategoryController: Skipping already completed item request (key=$requestKey, offset=$effectiveOffset)');
        }
        return;
      }

      _inFlightCategoryItemOffsets[requestKey] = effectiveOffset;

      // ⚡ FIX: Set isLoading for ALL requests (not just first page)
      // This prevents duplicate pagination requests when scrolling fast
      _isLoading = true;

      // ⚡ GENERATION ID: Track category changes to discard stale responses
      if (categoryChanged || effectiveOffset == 1) {
        _categoryItemGeneration++;
        _currentCategoryItemId = categoryID;
        if (kDebugMode) {
          print(
              '🔄 CategoryController: New generation $_categoryItemGeneration for category $categoryID');
        }
      }
      final int currentGeneration = _categoryItemGeneration;

      // 🛑 Cancel previous in-flight request when switching filters
      if (categoryChanged || _categoryItemsCancelToken == null) {
        _cancelCategoryItemsRequest();
        _categoryItemsCancelToken = CancelToken();
      }
      final CancelToken? requestCancelToken = _categoryItemsCancelToken;

      if (effectiveOffset == 1) {
        _categoryPageSignatureByKey.remove(requestKey);
        if (_type == type) {
          _isSearching = false;
        }
        _type = type;
        if (notify) {
          update();
        }
        // ✅ Mandatory reset before any async call
        if (_categoryItemList != null) {
          _categoryItemList!.clear();
        }
        _categoryItemList = null;
      }
      update();

      ItemModel? categoryItem;
      try {
        categoryItem = await categoryServiceInterface.getCategoryItemList(
            categoryID, effectiveOffset, type,
            includeChildren: resolvedIncludeChildren,
            cancelToken: requestCancelToken);
      } catch (e) {
        // 🎯 ERROR HANDLER PILOT: Use unified error handling (logging only, no UI changes)
        ErrorHandler().handleError(
          e,
          context: 'CategoryController.getCategoryItemList',
          showSnackbar: false, // No UI changes in pilot phase
          logError: true,
        );
        // Preserve existing behavior - set loading to false and return
        _isLoading = false;
        update();
        return;
      }

      // ⚡ GENERATION CHECK: Discard stale response if category changed during API call
      if (currentGeneration != _categoryItemGeneration) {
        if (kDebugMode) {
          print(
              '🚫 CategoryController: Discarding stale response (gen $currentGeneration != $_categoryItemGeneration)');
        }
        _isLoading = false;
        return; // Category changed, ignore this response
      }

      if (requestCancelToken?.isCancelled ?? false) {
        _isLoading = false;
        return; // Request cancelled due to filter change
      }

      if (categoryItem != null) {
        if (effectiveOffset == 1) {
          _categoryItemList = [];
        }
        _categoryItemList ??= [];
        _pageSize = categoryItem.totalSize ?? 0;
        if (categoryItem.items != null && categoryItem.items!.isNotEmpty) {
          final List<Item> incomingItems = categoryItem.items!;
          final List<String> pageKeys =
              incomingItems.map(_itemDedupKey).toList();
          final String pageSignature = pageKeys.join(',');
          final String? previousSignature =
              _categoryPageSignatureByKey[requestKey];
          if (effectiveOffset > 1 && previousSignature == pageSignature) {
            _pageSize = _categoryItemList!.length;
            _isLoading = false;
            update();
            return;
          }
          _categoryPageSignatureByKey[requestKey] = pageSignature;

          final List<Item> filteredItems = incomingItems;

          final existingKeys = _categoryItemList!.map(_itemDedupKey).toSet();
          final pageKeysSet = <String>{};

          // 🔍 DEBUG: Log incoming items from API
          if (kDebugMode) {
            print(
                '📦 [Page $effectiveOffset] API returned ${filteredItems.length} items:');
            for (int i = 0; i < filteredItems.length; i++) {
              final item = filteredItems[i];
              print('   ${i + 1}. [ID: ${item.id}] ${item.name}');
            }
          }

          final List<Item> skippedItems = [];
          final newItems = filteredItems.where((item) {
            final key = _itemDedupKey(item);
            if (existingKeys.contains(key) || pageKeysSet.contains(key)) {
              skippedItems.add(item);
              return false;
            }
            pageKeysSet.add(key);
            return true;
          }).toList();

          // 🔍 DEBUG: Log duplicates and new items
          if (kDebugMode) {
            if (skippedItems.isNotEmpty) {
              print(
                  '⚠️ [Page $effectiveOffset] DUPLICATES SKIPPED (${skippedItems.length}):');
              for (final item in skippedItems) {
                print('   ❌ [ID: ${item.id}] ${item.name}');
              }
            }
            print(
                '✅ [Page $effectiveOffset] NEW items added (${newItems.length}):');
            for (final item in newItems) {
              print('   ✓ [ID: ${item.id}] ${item.name}');
            }
          }

          _categoryItemList!.addAll(newItems);

          // 🔍 DEBUG: Log total items in list
          if (kDebugMode) {
            print(
                '📊 [Page $effectiveOffset] Total items in list: ${_categoryItemList!.length}');
          }

          if (effectiveOffset > 1 && newItems.isEmpty) {
            // Stop pagination if backend keeps returning duplicates
            _pageSize = _categoryItemList!.length;
            if (kDebugMode) {
              print(
                  '🛑 [Page $effectiveOffset] Pagination stopped - all items were duplicates');
            }
          }
        }
        _isLoading = false;
      } else {
        if (effectiveOffset == 1) {
          _categoryItemList = [];
        }
        _pageSize = 0;
        _isLoading = false;
      }
      _lastCompletedCategoryItemOffsets[requestKey] = effectiveOffset;
      update();
    } catch (e) {
      // 🎯 ERROR HANDLER PILOT: Use unified error handling (logging only, no UI changes)
      ErrorHandler().handleError(
        e,
        context: 'CategoryController.getCategoryItemList',
        showSnackbar: false, // No UI changes in pilot phase
        logError: true,
      );
      // Preserve existing behavior
      if (effectiveOffset == 1) {
        _categoryItemList = [];
      }
      _pageSize = 0;
      _isLoading = false;
      update();
    } finally {
      final bool resolvedIncludeChildren =
          includeChildren ?? (_subCategoryIndex == 0);
      final String includeChildrenKey =
          resolvedIncludeChildren ? 'true' : 'false';
      final String requestKey =
          '${categoryID ?? 'null'}|$type|$includeChildrenKey';
      if (_inFlightCategoryItemOffsets[requestKey] == effectiveOffset) {
        _inFlightCategoryItemOffsets.remove(requestKey);
      }
    }
  }

  void getCategoryStoreList(
      String? categoryID, int offset, String type, bool notify) async {
    _offset = offset;

    final String requestKey = '${categoryID ?? 'null'}|$type';
    if (offset == 1) {
      _lastCompletedCategoryStoreOffsets[requestKey] = 0;
    }
    if (_inFlightCategoryStoreOffsets[requestKey] == offset) {
      if (kDebugMode) {
        print(
            '⚠️ CategoryController: Skipping duplicate in-flight store request (key=$requestKey, offset=$offset)');
      }
      return;
    }
    if (offset > 1 &&
        (_lastCompletedCategoryStoreOffsets[requestKey] ?? 0) >= offset) {
      if (kDebugMode) {
        print(
            '⚠️ CategoryController: Skipping already completed store request (key=$requestKey, offset=$offset)');
      }
      return;
    }
    _inFlightCategoryStoreOffsets[requestKey] = offset;

    // ⚡ FIX: Set isLoading for ALL requests (not just first page)
    // This prevents duplicate pagination requests when scrolling fast
    _isLoading = true;

    if (offset == 1) {
      if (_type == type) {
        _isSearching = false;
      }
      _type = type;
      if (notify) {
        update();
      }
      _categoryStoreList = null;
    }
    update();

    try {
      final StoreModel? categoryStore = await categoryServiceInterface
          .getCategoryStoreList(categoryID, offset, type);
      if (categoryStore != null) {
        if (offset == 1) {
          _categoryStoreList = [];
        }

        _categoryStoreList ??= [];
        if (categoryStore.stores != null && categoryStore.stores!.isNotEmpty) {
          // ⚡ FIX: Deduplicate stores to prevent duplicates on pagination
          final existingStoreIds = _categoryStoreList!.map((s) => s.id).toSet();
          final newStores = categoryStore.stores!
              .where((store) => !existingStoreIds.contains(store.id))
              .toList();
          _categoryStoreList!.addAll(newStores);
        }
        _restPageSize = categoryStore.totalSize ?? 0;
        _isLoading = false;
      } else {
        if (offset == 1) {
          _categoryStoreList = [];
        }
        _restPageSize = 0;
        _isLoading = false;
      }
      _lastCompletedCategoryStoreOffsets[requestKey] = offset;
      update();
    } finally {
      if (_inFlightCategoryStoreOffsets[requestKey] == offset) {
        _inFlightCategoryStoreOffsets.remove(requestKey);
      }
    }
  }

  // ===================================================================================================================

  void applyFilters({
    required String research_Name,
    required String product_arrangement,
    required String id_category,
    required String id_stores,
    required bool discount,
    required String min,
    required String max,
    required bool fromHome,
  }) {
    _currentProductArrangement = product_arrangement;
    _currentMinPrice = min;
    _currentMaxPrice = max;
    _currentHasDiscount = discount;
    _currentSearchName = research_Name;

    final Search_FilterModel searchFiltermodel = Search_FilterModel(
      research_Name: research_Name,
      product_arrangement: product_arrangement,
      id_category: id_category,
      id_stores: id_stores,
      discount: discount ? '1' : '0',
      min: min,
      max: max,
    );

    update();

    if (!fromHome) {
      // تمرير البيانات الصحيحة
      searchData(search_filterModel: searchFiltermodel);
    }
  }

  void searchData({Search_FilterModel? search_filterModel}) async {
    if (search_filterModel == null) {
      print('Error: search_filterModel is null');
      return;
    }

    _isStore ? _searchStoreList = null : _searchItemList = null;
    _isSearching = true;
    update();

    try {
      final Response response = await searchServiceInterface.getNewSearchFilter(
          search_filterModel, false);

      if (response.statusCode == 200) {
        if (_isStore) {
          _searchStoreList = [];
          final stores =
              StoreModel.fromJson(response.body as Map<String, dynamic>).stores;
          if (stores != null) {
            _searchStoreList!.addAll(stores);
          }
        } else {
          _searchItemList = [];
          final items =
              ItemModel.fromJson(response.body as Map<String, dynamic>).items;
          if (items != null) {
            _searchItemList!.addAll(items);
          }
        }
      }
    } catch (e) {
      // 🎯 ERROR HANDLER PILOT: Use unified error handling (logging only, no UI changes)
      ErrorHandler().handleError(
        e,
        context: 'CategoryController.searchData',
        showSnackbar: false, // No UI changes in pilot phase
        logError: true,
      );
      // Preserve existing behavior - just log and continue
    }

    update();
  }

  // ==========================================================

  void toggleSearch(context) {
    _isSearching = !_isSearching;
    _searchItemList = [];
    if (_categoryItemList != null) {
      _searchItemList!.addAll(_categoryItemList!);
    }

    update();
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  Future<bool> saveInterest(List<int?> interests) async {
    _isLoading = true;
    update();
    final bool isSuccess =
        await categoryServiceInterface.saveUserInterests(interests);
    _isLoading = false;
    update();
    return isSuccess;
  }

  void addInterestSelection(int index) {
    _interestSelectedList![index] = !_interestSelectedList![index];
    update();
  }

  void setRestaurant(bool isRestaurant) {
    _isStore = isRestaurant;
    // Defer update to prevent setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  /// Set category data directly from cache (for instant loading)
  /// Uses _prepareCategoryList() to ensure consistent filtering (module_id, store_id, counts)
  void setCategoryDataFromCache(List<CategoryModel>? categoryList) {
    // Use _prepareCategoryList() instead of directly setting to ensure consistent filtering
    // This ensures cached categories are also filtered by module_id, store_id, and counts
    _prepareCategoryList(categoryList);
  }
}
