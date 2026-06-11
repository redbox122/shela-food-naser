
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart' hide Response;
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/store/domain/models/cart_suggested_item_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/recommended_product_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/review/domain/models/review_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/store/domain/models/subcategory_samples_model.dart';
import 'package:sixam_mart/features/store/domain/models/slim_menu_model.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/api/api_client.dart';

import '../../my_coupon/controllers/my_coupon_controller.dart';

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
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('Debug log error: $e');
    }
  }
}
// #endregion

class StoreController extends GetxController implements GetxService {
  final StoreServiceInterface storeServiceInterface;

  StoreController({required this.storeServiceInterface});

  // 🔒 Guard to prevent store fetches before module is locked
  bool _canFetchStores() {
    final splash = Get.find<SplashController>();
    if (!splash.isModuleLocked) {
      final apiClient = Get.find<ApiClient>();
      final headerModuleId =
          apiClient.getHeader()[AppConstants.moduleId]?.toString();
      final selectedModuleId = splash.module?.id?.toString();
      if (headerModuleId != null &&
          headerModuleId == selectedModuleId &&
          !splash.isModuleSwitching) {
        debugPrint(
            '⚠️ StoreController: Module lock false but headers ready (moduleId=$headerModuleId). Allowing fetch.');
        return true;
      }
      debugPrint(
          '⏸️ StoreController: Module not locked yet, skipping store fetch');
      return false;
    }
    return true;
  }

  StoreModel? _storeModel;
  StoreModel? get storeModel => _storeModel;

  // ⚡ HARD-ISOLATION: Private data bucket for "All Restaurants" section
  // This is ONLY for the legacy pagination engine and is NEVER touched by V2
  StoreModel? _allStoreModel;
  StoreModel? get allStoreModel => _allStoreModel;

  List<Store>? _popularStoreList;
  List<Store>? get popularStoreList => _popularStoreList;

  List<Store>? _latestStoreList;
  List<Store>? get latestStoreList => _latestStoreList;

  List<Store>? _topOfferStoreList;
  List<Store>? get topOfferStoreList => _topOfferStoreList;

  List<Store>? _featuredStoreList;
  List<Store>? get featuredStoreList => _featuredStoreList;

  List<Store>? _visitAgainStoreList;
  List<Store>? get visitAgainStoreList => _visitAgainStoreList;

  Store? _store;
  Store? get store => _store;

  int _pageSize = 0;
  int? get pageSize => _pageSize;

  ItemModel? _storeItemModel;
  ItemModel? get storeItemModel => _storeItemModel;

  // ⚡ STREAMING BUCKET: Master record for all items (2,000 items)
  List<Item>? _allStoreItems;

  // ⚡ STREAMING BUCKET: Visible items for UI (starts with 20, grows to 2,000)
  List<Item>? _visibleItemList;
  List<Item>? get visibleItemList => _visibleItemList;

  ItemModel? _storeSearchItemModel;
  ItemModel? get storeSearchItemModel => _storeSearchItemModel;

  int _categoryIndex = 0;
  int get categoryIndex => _categoryIndex;

  // 🔒 TASK 1: PERMANENT CATEGORY ISOLATION - Renamed to make it clear this is NEVER for global categories
  // This variable is DEPRECATED and should NEVER be assigned when storeId != null
  // It exists only for backward compatibility in the getter fallback
  List<CategoryModel>? _storeSpecificCategoryList;
  List<CategoryModel>? _allCategories; // Store all categories for lazy loading
  int _visibleCategoryCount = 15; // Show 15 categories initially
  bool _isLoadingMoreCategories = false;
  int? _lastStoreIdForCategories; // Track which store the categories belong to

  // 🔒 ISOLATION: Separate category list for store detail screens to prevent state leakage
  List<CategoryModel>? _specificStoreCategoryList;

  List<CategoryModel>? get categoryList {
    // Return only visible categories for lazy loading
    // ⚠️ DEPRECATED FALLBACK: _storeSpecificCategoryList should never be used for store categories
    // Store categories should use _specificStoreCategoryList or _allCategories
    if (_allCategories == null) return _storeSpecificCategoryList;
    final allCats = _allCategories!;
    if (allCats.length <= _visibleCategoryCount) return allCats;
    return allCats.sublist(0, _visibleCategoryCount);
  }

  /// Isolated category list for store detail screens - prevents poisoning global categories
  List<CategoryModel>? get specificStoreCategoryList =>
      _specificStoreCategoryList;

  /// Full category list for current store (including those beyond the lazy-loaded visible window).
  /// This is primarily used by detailed restaurant pages that need all menu sections at once.
  List<CategoryModel>? get fullCategoryList => _allCategories;

  bool get hasMoreCategories =>
      _allCategories != null && _allCategories!.length > _visibleCategoryCount;
  bool get isLoadingMoreCategories => _isLoadingMoreCategories;

  List<CategoryModel>? _subCategoryList;
  List<CategoryModel>? get subCategoryList => _subCategoryList;

  int _subCategoryIndex = 0;
  int get subCategoryIndex => _subCategoryIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasAllStoresError = false;
  bool get hasAllStoresError => _hasAllStoresError;

  bool _hasPopularStoresError = false;
  bool get hasPopularStoresError => _hasPopularStoresError;

  void _updateHomeRestaurantSections() {
    update(['popular_restaurants', 'all_restaurants_list']);
  }

  // ⚠️ CRITICAL: Loading locks to prevent duplicate API calls when switching modules
  bool _isLoadingPopularStores = false;
  Completer<List<Store>?>? _popularStoresLoadingCompleter;

  // 🔒 REQUEST LOCKING: Prevent duplicate API calls
  bool _isFetchingStores = false;
  DateTime? _lastStoreListRequestAt;
  String? _lastStoreListRequestSignature;
  static const Duration _storeListDebounce = Duration(milliseconds: 500);

  // ⚡ CONTENT POP: Prevent duplicate getStoreDetails calls
  int? _loadingStoreDetailsId;
  bool _isLoadingStoreDetails = false;
  bool get isLoadingStoreDetails => _isLoadingStoreDetails;
  Completer<Store?>? _storeDetailsCompleter;
  int? _activeStoreModuleId;
  int? get activeStoreModuleId => _activeStoreModuleId;

  // 🔧 FIX: Request cancellation and debouncing for category switching
  CancelToken? _itemsRequestCancelToken;
  Timer? _categoryDebounceTimer;
  bool _isLoadingItems = false;
  bool get isLoadingItems => _isLoadingItems;

  // 🔧 TASK 1: Request cancellation token for store detail loads
  CancelToken? _storeLoadCancelToken;

  // ✅ FIX #6: Protection against duplicate update() calls
  bool _didFinalUpdate = false;
  int? _loadingAllStoreDetailsId;
  bool _isLoadingAllStoreDetails = false;

  // 🚀 SLIM MENU: Track slim menu loading state and response
  bool _slimMenuLoaded = false;
  bool get slimMenuLoaded => _slimMenuLoaded;
  SlimMenuResponse? _slimMenuResponse;
  SlimMenuResponse? get slimMenuResponse => _slimMenuResponse;

  /// ⚡ TASK 3: Check if current store is a large store (>= 2000 items in slim menu)
  /// Large stores have their menu limited to 2K items by the backend
  bool get isLargeStore => _slimMenuResponse?.isLargeStore ?? false;

  // Items pagination state
  // Default page size for store items (can be overridden per call).
  int _itemsPageSize = 10;
  int _currentItemsOffset = 1;
  bool _hasMoreItems = true;

  int get itemsPageSize => _itemsPageSize;
  int get currentItemsOffset => _currentItemsOffset;
  bool get hasMoreItems => _hasMoreItems;

  String _filterType = 'all';
  String get filterType => _filterType;

  String _storeType = 'all';
  String get storeType => _storeType;

  // Filter state variables
  bool? _recentlyAdded;
  bool? get recentlyAdded => _recentlyAdded;

  bool? _highestRated;
  bool? get highestRated => _highestRated;

  bool? _fastestDelivery;
  bool? get fastestDelivery => _fastestDelivery;

  double? _minPrice;
  double? get minPrice => _minPrice;

  double? _maxPrice;
  double? get maxPrice => _maxPrice;

  String? _sortBy;
  String? get sortBy => _sortBy;

  List<ReviewModel>? _storeReviewList;
  List<ReviewModel>? get storeReviewList => _storeReviewList;

  String _type = 'all';
  String get type => _type;

  String _searchType = 'all';
  String get searchType => _searchType;

  String _searchText = '';
  String get searchText => _searchText;

  String _storeSearchFilterName = '';
  String _storeSearchFilterSort = 'popular';
  String _storeSearchFilterCategoryId = '';
  bool _storeSearchFilterDiscount = false;
  String _storeSearchFilterMin = '';
  String _storeSearchFilterMax = '';
  bool get hasActiveStoreSearchFilters =>
      _storeSearchFilterName.trim().isNotEmpty ||
      _storeSearchFilterSort != 'popular' ||
      _storeSearchFilterCategoryId.isNotEmpty ||
      _storeSearchFilterDiscount ||
      _storeSearchFilterMin.isNotEmpty ||
      _storeSearchFilterMax.isNotEmpty;

  bool _currentState = true;
  bool get currentState => _currentState;

  bool _showFavButton = true;
  bool get showFavButton => _showFavButton;

  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  RecommendedItemModel? _recommendedItemModel;
  RecommendedItemModel? get recommendedItemModel => _recommendedItemModel;

  CartSuggestItemModel? _cartSuggestItemModel;
  CartSuggestItemModel? get cartSuggestItemModel => _cartSuggestItemModel;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _hasStoreSearchError = false;
  bool get hasStoreSearchError => _hasStoreSearchError;

  // Live search properties
  List<Item>? _liveSearchResults;
  List<Item>? get liveSearchResults => _liveSearchResults;

  bool _isLiveSearching = false;
  bool get isLiveSearching => _isLiveSearching;

  bool _isSearchFieldVisible = false;
  bool get isSearchFieldVisible => _isSearchFieldVisible;

  // Live search debouncing
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  bool _isVertical = false;
  bool get isVertical => _isVertical;

  bool _isPriceAscending = true;
  bool get isPriceAscending => _isPriceAscending;

  List<StoreBannerModel>? _storeBanners;
  List<StoreBannerModel>? get storeBanners => _storeBanners;

  List<Store>? _recommendedStoreList;
  List<Store>? get recommendedStoreList => _recommendedStoreList;

  // Subcategories with sample items (for new backend endpoint)
  StoreSubcategorySamplesModel? _subcategorySamplesModel;
  bool _isLoadingSubcategorySamples = false;

  StoreSubcategorySamplesModel? get subcategorySamplesModel =>
      _subcategorySamplesModel;
  bool get isLoadingSubcategorySamples => _isLoadingSubcategorySamples;

  // =================================================================================================

  void set_Price_store_Search(bool value) {
    _isPriceAscending = value;

    if (_storeSearchItemModel!.items != null &&
        _storeSearchItemModel!.items!.isNotEmpty) {
      _storeSearchItemModel!.items!.sort((a, b) {
        final double priceA = a.price ?? 0;
        final double priceB = b.price ?? 0;

        return _isPriceAscending
            ? priceA.compareTo(priceB) // تصاعدي
            : priceB.compareTo(priceA); // تنازلي
      });
    }

    update();
  }

  double getRestaurantDistance(LatLng storeLatLng) {
    double distance = 0;
    final AddressModel? addressModel =
        AddressHelper.getUserAddressFromSharedPref();
    if (addressModel != null &&
        addressModel.latitude != null &&
        addressModel.longitude != null) {
      distance = Geolocator.distanceBetween(
              storeLatLng.latitude,
              storeLatLng.longitude,
              double.parse(addressModel.latitude!),
              double.parse(addressModel.longitude!)) /
          1000;
    }
    return distance;
  }

  String filteringUrl(String slug) {
    return storeServiceInterface.filterRestaurantLinkUrl(slug, _store!);
  }

  void pickPrescriptionImage(
      {required bool isRemove, required bool isCamera}) async {
    if (isRemove) {
      _pickedPrescriptions = [];
    } else {
      final XFile? xFile = await ImagePicker().pickImage(
          source: isCamera ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 50);
      if (xFile != null) {
        _pickedPrescriptions.add(xFile);
      }
      update();
    }
  }

  void removePrescriptionImage(int index) {
    _pickedPrescriptions.removeAt(index);
    update();
  }

  void changeFavVisibility() {
    _showFavButton = !_showFavButton;
    update();
  }

  void hideAnimation() {
    _currentState = false;
  }

  void showButtonAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      _currentState = true;
      update();
    });
  }

  Future<void> getRestaurantRecommendedItemList(int? storeId, bool reload,
      {CancelToken? cancelToken}) async {
    if (reload) {
      _storeModel = null;
      update();
    }
    final RecommendedItemModel? recommendedItemModel =
        await storeServiceInterface.getStoreRecommendedItemList(storeId,
            cancelToken: cancelToken);

    // 🛑 PHASE 2: Check cancellation immediately after response
    if ((cancelToken?.isCancelled ?? false) ||
        (_storeLoadCancelToken?.isCancelled ?? false)) {
      if (kDebugMode) {
        debugPrint(
            '🚫 [StoreController] Request cancelled - discarding recommended items response');
      }
      return; // Don't update state
    }

    if (recommendedItemModel != null) {
      // aziz: Defensive filtering - ensure recommended items belong to this store
      // Backend should already handle this, but we add client-side validation as safety net
      if (recommendedItemModel.items != null && storeId != null) {
        final originalCount = recommendedItemModel.items!.length;

        // Filter items to ensure they belong to the requested store
        recommendedItemModel.items = recommendedItemModel.items!.where((item) {
          final belongsToStore = item.storeId == storeId;

          // Log data integrity issues for monitoring
          if (!belongsToStore && item.storeId != null) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ DATA INTEGRITY WARNING: Recommended items API returned '
                  'item ${item.id} "${item.name}" with store_id=${item.storeId}, '
                  'expected $storeId. Filtering out.');
            }
          }

          return belongsToStore;
        }).toList();

        final filteredCount = recommendedItemModel.items!.length;
        if (kDebugMode && originalCount != filteredCount) {
          debugPrint(
              '🛡️ Filtered recommended items: $filteredCount/$originalCount items belong to store $storeId');
        }
      }

      _recommendedItemModel = recommendedItemModel;
    }
    update();
  }

  void setSubCategoryIndex(int index, {bool itemSearching = false}) {
    _subCategoryIndex = index;
    if (itemSearching) {
      _storeSearchItemModel = null;
      getStoreSearchItemList(_searchText, _store!.id.toString(), 1, type);
    } else {
      _storeItemModel = null;
      getStoreItemList(_store!.id, 1, Get.find<StoreController>().type, false,
          subCategory: true);
    }
    update();
  }

  void getSubCategoryList(String? categoryID) async {
    // Skip fetching subcategories for restaurant menu categories (they don't have subcategories)
    // Restaurant menu categories: have position > 0 OR storeId != null OR are from category_details
    // Cuisine categories: have position = 0 AND storeId = null
    if (_store != null &&
        _storeSpecificCategoryList != null &&
        _categoryIndex < _storeSpecificCategoryList!.length) {
      final currentCategory = _storeSpecificCategoryList![_categoryIndex];
      final isRestaurantMenuCategory = (currentCategory.position != null &&
              currentCategory.position! > 0) ||
          (currentCategory.storeId != null && currentCategory.storeId! > 0) ||
          (_store!.categoryDetails != null &&
              _store!.categoryDetails!
                  .any((cat) => cat.id == currentCategory.id));

      if (isRestaurantMenuCategory) {
        if (kDebugMode) {
          debugPrint(
              '📍 [StoreController] getSubCategoryList() - Skipping subcategory fetch for restaurant menu category ${currentCategory.id} (restaurant menu categories are flat, no subcategories)');
        }
        _subCategoryList = [];
        _subCategoryIndex = 0;
        update();
        return;
      }
    }

    if (kDebugMode) {
      debugPrint(
          '📍 [StoreController] getSubCategoryList() - Fetching subcategories for category: $categoryID');
    }
    _subCategoryIndex = 0;
    _subCategoryList = null;
    final List<CategoryModel>? subCategoryList =
        await storeServiceInterface.getSubCategoryList(parentID: categoryID);
    if (kDebugMode) {
      debugPrint(
          '   📋 Subcategories fetched: ${subCategoryList?.length ?? 0}');
    }
    if (subCategoryList == null || subCategoryList.isEmpty) {
      _subCategoryList = [];
      update();
      return;
    }
    _subCategoryList = [];
    _subCategoryList!
        .add(CategoryModel(id: int.parse(categoryID!), name: 'all'.tr));

    final List<CategoryModel> subSubCategory = subCategoryList.where((test) {
      return test.productsCount > 0;
    }).toList();
    _subCategoryList!.addAll(subSubCategory);
    update();
  }

  Future<void> getCartStoreSuggestedItemList(int? storeId) async {
    final CartSuggestItemModel? cartSuggestItemModel =
        await storeServiceInterface.getCartStoreSuggestedItemList(
            storeId,
            Get.find<LocalizationController>().locale.languageCode,
            ModuleHelper.getModule(),
            ModuleHelper.getCacheModule()?.id,
            ModuleHelper.getModule()?.id);
    if (cartSuggestItemModel != null) {
      _cartSuggestItemModel = cartSuggestItemModel;
    }
    update();
  }

  /// Load subcategories with sample items for a given parent category and store.
  ///
  /// This uses the backend endpoint:
  /// GET /api/v1/stores/{store_id}/categories/{category_id}/subcategories-with-samples
  Future<void> getSubcategoriesWithSamples({
    required int storeId,
    required int parentCategoryId,
    int limit = 20,
    int offset = 1,
    int sampleSize = 3,
    String type = 'all',
    bool includeChildren = true,
  }) async {
    if (_isLoadingSubcategorySamples) {
      return;
    }

    _isLoadingSubcategorySamples = true;
    update();

    try {
      if (kDebugMode) {
        debugPrint(
            '📡 [StoreController] getSubcategoriesWithSamples: storeId=$storeId, parentCategoryId=$parentCategoryId, offset=$offset, limit=$limit, sampleSize=$sampleSize, type=$type, includeChildren=$includeChildren');
      }

      final StoreSubcategorySamplesModel? result =
          await storeServiceInterface.getStoreSubcategoriesWithSamples(
        storeId: storeId,
        categoryId: parentCategoryId,
        limit: limit,
        offset: offset,
        sampleSize: sampleSize,
        type: type,
        includeChildren: includeChildren,
      );

      _subcategorySamplesModel = result;

      if (kDebugMode && result != null) {
        debugPrint(
            '✅ [StoreController] Loaded ${result.subcategories.length} subcategories with samples (totalSize=${result.totalSize}, offset=${result.offset}, limit=${result.limit})');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            '❌ [StoreController] Error in getSubcategoriesWithSamples: $e');
        debugPrint('   - Stack trace: $stackTrace');
      }
    } finally {
      _isLoadingSubcategorySamples = false;
      update();
    }
  }

  Future<void> getStoreBannerList(int? storeId,
      {CancelToken? cancelToken}) async {
    final List<StoreBannerModel>? storeBanners = await storeServiceInterface
        .getStoreBannerList(storeId, cancelToken: cancelToken);

    // 🛑 PHASE 2: Check cancellation immediately after response
    if ((cancelToken?.isCancelled ?? false) ||
        (_storeLoadCancelToken?.isCancelled ?? false)) {
      if (kDebugMode) {
        debugPrint(
            '🚫 [StoreController] Request cancelled - discarding banner response');
      }
      return; // Don't update state
    }

    if (storeBanners != null) {
      _storeBanners = [];
      _storeBanners!.addAll(storeBanners);
    }
    update();
  }

  /// ⚡ Cache-First: Load stores with pagination
  ///
  /// الفلسفة:
  /// - أول تحميل: من الكاش فورًا (page 1, limit 7)
  /// - Background refresh: تحديث في الخلفية
  /// - Pagination: تحميل صفحات إضافية عند التمرير
  Future<StoreModel?> getStoreList(int offset, bool reload,
      {DataSourceEnum source = DataSourceEnum.local, int? limit}) async {
    if (!_canFetchStores()) {
      return _allStoreModel;
    }
    _hasAllStoresError = false;
    final String requestSignature =
        'offset=$offset|reload=$reload|source=$source|limit=${limit ?? -1}|'
        'filter=$_filterType|storeType=$_storeType|recent=$_recentlyAdded|'
        'rating=$_highestRated|fast=$_fastestDelivery|min=$_minPrice|'
        'max=$_maxPrice|sort=$_sortBy';
    final DateTime now = DateTime.now();

    // 🔒 REQUEST DEBOUNCE: Drop rapid duplicate calls with identical params.
    if (_lastStoreListRequestSignature == requestSignature &&
        _lastStoreListRequestAt != null &&
        now.difference(_lastStoreListRequestAt!) < _storeListDebounce) {
      if (kDebugMode) {
        debugPrint('🚫 StoreController.getStoreList: Debounced duplicate request '
            '(within ${_storeListDebounce.inMilliseconds}ms)');
      }
      return _allStoreModel;
    }

    // 🔒 REQUEST LOCKING: Prevent overlapping calls while one is already in-flight.
    if (_isFetchingStores) {
      if (kDebugMode) {
        debugPrint('[API] stores already loading → skip duplicate');
      }
      return _allStoreModel;
    }

    _lastStoreListRequestAt = now;
    _lastStoreListRequestSignature = requestSignature;
    _isFetchingStores = true;

    // ⚡ Cache-First: Preserve cache during background refresh
    // If data already exists, keep it visible until new data arrives
    final hasExistingData = _allStoreModel != null &&
        _allStoreModel!.stores != null &&
        _allStoreModel!.stores!.isNotEmpty;

    // ⚡ STEP A: Load from cache first (if first page and not reloading)
    if (offset == 1 &&
        !reload &&
        source == DataSourceEnum.local &&
        hasExistingData) {
      if (kDebugMode) {
        debugPrint(
            '[Cache] HIT: stores_page1 (${_allStoreModel!.stores!.length} stores)');
      }
      // Return cached data immediately
      _isFetchingStores = false;
      return _allStoreModel;
    }

    if (reload) {
      // Only clear state if there's no existing data (first load or module switch)
      // If data exists, preserve it for visual continuity during background refresh
      if (!hasExistingData) {
        // 🚫 CRITICAL: Clear ALL module-specific state before fetching
        // This ensures each module entry is a clean slate - no state contamination
        // When switching modules, old module's data must be completely cleared
        // ⚡ HARD-ISOLATION: Clear _allStoreModel (legacy pagination engine) instead of _storeModel
        _allStoreModel = null;
        _filterType = 'all';
        _storeType = 'all';
        _recentlyAdded = null;
        _highestRated = null;
        _fastestDelivery = null;
        _minPrice = null;
        _maxPrice = null;
        _sortBy = null;

        if (kDebugMode) {
          debugPrint(
              '🔄 StoreController: Clearing all module state (reload=true, no existing data)');
          debugPrint(
              '   - This ensures clean state and correct totalSize (300+) from API');
        }
      } else {
        // ⚡ SILENT_FETCH: Data exists - preserve it during background refresh
        if (kDebugMode) {
          debugPrint(
              '🔇 StoreController: SILENT_FETCH mode - preserving ${_allStoreModel!.stores!.length} cached stores during background refresh');
          debugPrint('   - Old stores will remain visible until new data arrives');
        }
      }
      _isLoading = true;
      update();
    }

    try {
      StoreModel? storeModel;

      // When reload is true (filter/location changed), ALWAYS fetch fresh data from API
      // This ensures cache doesn't show stale data when filters or location change
      // CRITICAL: When filters change, we must bypass cache completely to get correct results
      if (reload) {
        // 🔍 SECTION 3 API DEBUG: All Restaurants
        debugPrint('🔍 SECTION 3 API - getStoreList called (reload=true):');
        debugPrint(
            '   - offset: $offset, filterType: $_filterType, storeType: $_storeType');
        if (kDebugMode) {
          debugPrint(
              '🔄 Filter/Location changed - forcing fresh API call with filterType: $_filterType, storeType: $_storeType');
        }
        // Always use client source (API) when reload=true to bypass cache
        // ⚡ PERFORMANCE: Calculate effective limit (7 per page)
        // Small limit (7) ensures first frame loads quickly
        final effectiveLimit = limit ?? 7;
        if (kDebugMode) {
          debugPrint(
              '[API] background refresh started (offset=$offset, limit=$effectiveLimit)');
        }
        storeModel = await storeServiceInterface.getStoreList(
            offset, _filterType, _storeType,
            source: DataSourceEnum.client,
            recentlyAdded: _recentlyAdded,
            highestRated: _highestRated,
            fastestDelivery: _fastestDelivery,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            sortBy: _sortBy,
            limit: effectiveLimit);
        debugPrint('   📡 SECTION 3 API - API response received:');
        debugPrint('   - storeModel is null: ${storeModel == null}');
        if (storeModel != null) {
          debugPrint('   - totalSize: ${storeModel.totalSize}');
          debugPrint('   - stores count: ${storeModel.stores?.length ?? 0}');
          if (storeModel.stores != null && storeModel.stores!.isNotEmpty) {
            debugPrint(
                '   ✅ SECTION 3 API - Successfully loaded ${storeModel.stores!.length} restaurants');
            debugPrint(
                '   📋 SECTION 3 API - First restaurant: id=${storeModel.stores![0].id}, name=${storeModel.stores![0].name}');
          } else {
            debugPrint('   ⚠️ SECTION 3 API - API returned EMPTY stores list');
          }
        } else {
          debugPrint('   ❌ SECTION 3 API - API returned NULL');
        }
        _prepareStoreModel(storeModel, offset);
      } else if (source == DataSourceEnum.client) {
        // 🔍 SECTION 3 API DEBUG: All Restaurants
        debugPrint('🔍 SECTION 3 API - getStoreList called (source=client):');
        debugPrint(
            '   - offset: $offset, filterType: $_filterType, storeType: $_storeType');
        // Explicit client source request - fetch from API
        // ⚡ PERFORMANCE: Calculate effective limit (7 per page)
        // Small limit (7) ensures first frame loads quickly
        final effectiveLimit = limit ?? 7;
        debugPrint(
            '   🌐 SECTION 3 API - Calling API endpoint: /api/v1/stores/get-stores/$_filterType?store_type=$_storeType&offset=$offset&limit=$effectiveLimit');
        storeModel = await storeServiceInterface.getStoreList(
            offset, _filterType, _storeType,
            source: DataSourceEnum.client,
            recentlyAdded: _recentlyAdded,
            highestRated: _highestRated,
            fastestDelivery: _fastestDelivery,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            sortBy: _sortBy,
            limit: effectiveLimit);
        debugPrint('   📡 SECTION 3 API - API response received:');
        debugPrint('   - storeModel is null: ${storeModel == null}');
        if (storeModel != null) {
          debugPrint('   - totalSize: ${storeModel.totalSize}');
          debugPrint('   - stores count: ${storeModel.stores?.length ?? 0}');
          if (storeModel.stores != null && storeModel.stores!.isNotEmpty) {
            debugPrint(
                '   ✅ SECTION 3 API - Successfully loaded ${storeModel.stores!.length} restaurants');
            debugPrint(
                '   📋 SECTION 3 API - First restaurant: id=${storeModel.stores![0].id}, name=${storeModel.stores![0].name}');
          } else {
            debugPrint('   ⚠️ SECTION 3 API - API returned EMPTY stores list');
          }
        } else {
          debugPrint('   ❌ SECTION 3 API - API returned NULL');
        }
        _prepareStoreModel(storeModel, offset);
      } else {
        // 🚫 FIX: Skip comprehensive cache for "All Restaurants" section (allStoreModel)
        // The comprehensive cache stores storeModel (popular stores with totalSize: 10)
        // but allStoreModel needs the full API response (totalSize: 300+) for pagination
        // Loading popular stores into allStoreModel breaks pagination (thinks only 10 stores exist)
        // Comprehensive cache should only be used for popularStoreList, NOT for pagination
        if (kDebugMode &&
            offset == 1 &&
            _filterType == 'all' &&
            _storeType == 'all') {
          debugPrint(
              '⚠️ StoreController: Skipping comprehensive cache for allStoreModel (stores popular stores, not all stores)');
          debugPrint(
              '   - Will fetch from API to get correct totalSize (300+) for pagination');
        }

        // Try cache first only if reload is false and source is local
        // ⚡ PERFORMANCE: Calculate effective limit (8 for initial fetch, 12 for pagination)
        // Small limit (8) ensures first frame loads quickly
        final effectiveLimit = limit ?? (offset == 1 ? 8 : 12);
        storeModel = await storeServiceInterface.getStoreList(
            offset, _filterType, _storeType,
            source: DataSourceEnum.local,
            recentlyAdded: _recentlyAdded,
            highestRated: _highestRated,
            fastestDelivery: _fastestDelivery,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            sortBy: _sortBy,
            limit: effectiveLimit);

        // If cache is empty or null, fallback to API call
        if (storeModel == null ||
            storeModel.stores == null ||
            storeModel.stores!.isEmpty) {
          if (kDebugMode) {
            debugPrint('🏪 Cache empty, falling back to API call for stores');
          }
          storeModel = await storeServiceInterface.getStoreList(
              offset, _filterType, _storeType,
              source: DataSourceEnum.client,
              recentlyAdded: _recentlyAdded,
              highestRated: _highestRated,
              fastestDelivery: _fastestDelivery,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              sortBy: _sortBy,
              limit: effectiveLimit);
          _prepareStoreModel(storeModel, offset);
        } else {
          _prepareStoreModel(storeModel, offset);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading stores: $e');
      _hasAllStoresError = true;
      // ✅ TASK 2: PROTECT CACHE - Only set empty model if no existing data
      if (offset == 1 && _allStoreModel == null) {
        // First load, no cache exists - set empty model
        _allStoreModel =
            StoreModel(stores: [], totalSize: 0, offset: 1, limit: '12');
      }
      // If _allStoreModel exists, preserve it (don't overwrite with empty)
      update(); // Refresh UI with cached data
    } finally {
      _isLoading = false;
      _isFetchingStores = false; // 🔒 Release lock
      update();
    }
    // ⚡ HARD-ISOLATION: Return _allStoreModel (legacy pagination engine)
    return _allStoreModel;
  }

  /// Set store data from cache (handles both StoreModel and raw JSON)
  void setStoreDataFromCache({
    List<Store>? popularStoreList,
    StoreModel? storeModel,
    List<Store>? featuredStoreList,
    List<Store>? latestStoreList,
    List<Store>? topOfferStoreList,
    List<Store>? visitAgainStoreList,
  }) {
    if (popularStoreList != null) {
      _popularStoreList = popularStoreList;
      debugPrint(
          '✅ StoreController: Loaded ${_popularStoreList!.length} popular stores from cache');
    }

    if (storeModel != null) {
      _storeModel = storeModel;
      debugPrint(
          '✅ StoreController: Loaded store model with ${storeModel.stores?.length ?? 0} stores from cache');
    }

    if (featuredStoreList != null) _featuredStoreList = featuredStoreList;
    if (latestStoreList != null) _latestStoreList = latestStoreList;
    if (topOfferStoreList != null) _topOfferStoreList = topOfferStoreList;
    if (visitAgainStoreList != null) _visitAgainStoreList = visitAgainStoreList;

    update();
    _updateHomeRestaurantSections();
  }

  /// 🎯 API OVERLAP FIX: Set store data from unified endpoint
  ///
  /// This method is called by HomeController when data comes from unified endpoint.
  /// It's a safe setter that doesn't trigger API calls.
  ///
  /// [stores] - List of stores from unified endpoint
  void setFromUnified(List<Store>? stores) {
    if (stores == null || stores.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreController: setFromUnified called with null or empty data');
      }
      return;
    }

    // Set popular stores list (for top sections)
    _popularStoreList = stores;

    if (kDebugMode) {
      debugPrint(
          '✅ StoreController: Store data set from unified endpoint (${stores.length} stores)');
    }

    update();
    _updateHomeRestaurantSections();
  }

  /// ⚡ BFF API v2: Set popular store data from home-unified endpoint
  ///
  /// Called by HomeUnifiedController to distribute popular stores data
  ///
  /// 🚫 CRITICAL: This method ONLY sets _popularStoreList, NEVER _storeModel OR _allStoreModel
  /// V2 must NEVER touch storeModel or allStoreModel - they're exclusively managed by legacy pagination engine
  /// ⚡ HARD-ISOLATION: allStoreModel is for "All Restaurants" section pagination only
  /// This prevents V2 from overwriting totalSize with wrong value (9 popular stores vs 300+ all stores)
  void setPopularStoreDataFromBootstrap(StoreModel storeModel) {
    if (storeModel.stores == null || storeModel.stores!.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreController: Bootstrap has no popular stores, keeping existing data');
      }
      return;
    }

    // ✅ SAFE: Only sets popularStoreList for top sections, NOT storeModel or allStoreModel
    _popularStoreList = storeModel.stores;

    // 🚫 DEFENSIVE: Verify we never accidentally set storeModel or allStoreModel
    // This is a compile-time guarantee - if you see _storeModel = ... or _allStoreModel = ... here, it's a bug!

    if (kDebugMode) {
      debugPrint(
          '✅ StoreController: Popular stores set from bootstrap (${_popularStoreList!.length} stores)');
      debugPrint(
          '   - Only popularStoreList updated, storeModel and allStoreModel untouched (V2 hard-isolation)');
    }

    update();
    _updateHomeRestaurantSections();
  }

  // ⚡ HARD-ISOLATION: This method now updates _allStoreModel (legacy pagination engine)
  // V2 must NEVER call this method or touch _allStoreModel
  void _prepareStoreModel(StoreModel? storeModel, int offset) {
    if (storeModel != null) {
      // ⚡ SWR OVERWRITE FIX: If API returns valid data (even if different from cache), FORCE UI update
      // Note: Repository already handles retry logic for empty stores with valid totalSize
      // If repository retry also returns 0 stores, backend genuinely has no stores for this location/offset
      final hasCachedData = _allStoreModel != null &&
          _allStoreModel!.stores != null &&
          _allStoreModel!.stores!.isNotEmpty;

      // ✅ FORCE UPDATE: If API returns valid list, always update UI (even if different from cache)
      if (offset == 1) {
        // ⚡ HARD-ISOLATION: Use _allStoreModel instead of _storeModel
        _allStoreModel = storeModel;
        if (kDebugMode) {
          debugPrint(
              '📊 StoreController: Initial load (allStoreModel) - totalSize: ${storeModel.totalSize}, stores: ${storeModel.stores?.length ?? 0}');
          debugPrint(
              '[StoreList][HOME_COMPARE] homeStores=${_popularStoreList?.length ?? 0} allStores=${storeModel.stores?.length ?? 0}');
          if (hasCachedData &&
              storeModel.stores != null &&
              storeModel.stores!.isNotEmpty) {
            debugPrint(
                '   ✅ SWR: Forcing UI update with API data (overwriting cache)');
          }
        }
      } else {
        if (_allStoreModel != null) {
          final previousCount = _allStoreModel!.stores?.length ?? 0;
          _allStoreModel!.totalSize = storeModel.totalSize;
          _allStoreModel!.offset = storeModel.offset;
          if (_allStoreModel!.stores != null && storeModel.stores != null) {
            _allStoreModel!.stores!.addAll(storeModel.stores!);
          }
          final newCount = _allStoreModel!.stores?.length ?? 0;
          if (kDebugMode) {
            debugPrint(
                '📊 StoreController: Pagination (allStoreModel) - offset: $offset, totalSize: ${storeModel.totalSize}, loaded: ${storeModel.stores?.length ?? 0}, total loaded: $newCount (was $previousCount)');
          }
        } else {
          // No existing model - create new one
          _allStoreModel = storeModel;
        }
      }
      // ✅ CRITICAL: Always call update() to refresh UI when API returns valid data
      update();
      _updateHomeRestaurantSections();
    }
  }

  void setFilterType(String type) {
    if (_filterType != type) {
      _filterType = type;
      if (kDebugMode) {
        debugPrint('🔍 Filter changed to: $type - using SWR pattern');
      }
      // ⚡ SWR PATTERN: Check Hive cache first, show immediately, then fetch in background
      _loadFiltersWithSWR();
    }
  }

  /// ⚡ SECTION ISOLATION: Reset only store list state, not categories or popular lists
  /// This ensures filters only affect the store list section, keeping the rest of the page stable
  void _silentStoreReset() {
    // Only reset store list state - do NOT clear categories or popular lists
    _allStoreModel = null;
    // Reset offset to 1 for fresh pagination
    // Note: offset is managed by _allStoreModel, so setting it to null is sufficient
    if (kDebugMode) {
      debugPrint(
          '🔄 StoreController: Silent store reset - only clearing store list (categories/popular preserved)');
    }
  }

  void setStoreType(String type) {
    if (_storeType != type) {
      _storeType = type;
      if (kDebugMode) {
        debugPrint('🏪 Store type changed to: $type - using SWR pattern');
      }

      // 🔒 HARD RESET: Clear allStoreModel but preserve popularStoreList
      // Reset offset to 1 for fresh pagination
      _allStoreModel = null;

      // ✅ CRITICAL FIX: Update UI immediately so green indicator moves
      update();

      // ⚡ SWR PATTERN: Check Hive cache first, show immediately, then fetch in background
      _loadStoreTypeWithSWR(type);
    }
  }

  /// ⚡ SWR PATTERN: Load store type with stale-while-revalidate
  /// 1. Check Hive cache for this specific filter
  /// 2. If found, update UI IMMEDIATELY with cached data
  /// 3. Fire API call in background
  /// 4. If API returns stores, swap them. If API returns 0, KEEP cached stores visible
  Future<void> _loadStoreTypeWithSWR(String type) async {
    try {
      final splashController = Get.find<SplashController>();
      final moduleId = splashController.module?.id;

      if (moduleId == null) {
        // No module - fallback to normal loading
        _loadStoreTypeDirect(type);
        return;
      }

      // ⚡ STEP 1: Check Hive cache for this filter type
      final hiveService = HiveHomeCacheService();
      StoreModel? cachedStoreModel;

      if (type == 'all' || type == 'top_rated') {
        // For 'all' and 'top_rated', check Hive stores cache
        cachedStoreModel = await hiveService.loadStores(moduleId);

        if (cachedStoreModel != null &&
            cachedStoreModel.stores != null &&
            cachedStoreModel.stores!.isNotEmpty) {
          // ⚡ STEP 2: Update UI IMMEDIATELY with cached data
          _allStoreModel = cachedStoreModel;
          update();

          if (kDebugMode) {
            debugPrint(
                '⚡ SWR: Loaded ${cachedStoreModel.stores!.length} cached stores for filter "$type" - UI updated instantly');
          }
        }
      } else if (type == 'popular') {
        // Popular stores are stored separately - check if we have cached popular list
        // Note: Popular stores might be in memory already from previous load
        if (_popularStoreList != null && _popularStoreList!.isNotEmpty) {
          // Already in memory - no need to load from Hive
          if (kDebugMode) {
            debugPrint(
                '⚡ SWR: Using ${_popularStoreList!.length} cached popular stores from memory - UI updated instantly');
          }
          update();
        }
      } else if (type == 'newly_joined') {
        // Latest stores are stored separately - check if we have cached latest list
        if (_latestStoreList != null && _latestStoreList!.isNotEmpty) {
          // Already in memory - no need to load from Hive
          if (kDebugMode) {
            debugPrint(
                '⚡ SWR: Using ${_latestStoreList!.length} cached latest stores from memory - UI updated instantly');
          }
          update();
        }
      }

      // ⚡ STEP 3: Fire API call in background (non-blocking)
      // Use silent reset to only clear store list, not categories/popular
      _silentStoreReset();

      // Load in background - if API returns data, it will overwrite cached data
      // If API returns 0, cached data remains visible (handled by EMPTY_V2 fix)
      _loadStoreTypeDirect(type);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreController: Error in SWR pattern - $e, falling back to direct load');
      }
      // Fallback to direct loading if SWR fails
      _silentStoreReset();
      _loadStoreTypeDirect(type);
    }
  }

  /// Direct loading method (called after SWR cache check)
  void _loadStoreTypeDirect(String type) {
    if (type == 'popular') {
      getPopularStoreList(true, 'all', true, dataSource: DataSourceEnum.client);
    } else if (type == 'newly_joined') {
      // ✅ RE-ENABLED: Backend UTF-8 and 500 errors have been fixed
      getLatestStoreList(true, 'all', true, dataSource: DataSourceEnum.client);
    } else {
      // For 'all' and 'top_rated', use getStoreList
      getStoreList(1, true, source: DataSourceEnum.client);
    }
  }

  void resetStoreData() {
    _filterType = 'all';
    _storeType = 'all';
    _recentlyAdded = null;
    _highestRated = null;
    _fastestDelivery = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = null;
  }

  /// Apply filters from bottom sheet
  /// ⚡ SWR PATTERN: Check cache first, show immediately, then fetch in background
  void applyStoreFilters(Map<String, dynamic> filters) {
    _recentlyAdded = filters['recentlyAdded'] as bool?;
    _highestRated = filters['highestRated'] as bool?;
    _fastestDelivery = filters['fastestDelivery'] as bool?;

    if (filters['priceRange'] != null) {
      final priceRange = filters['priceRange'] as Map<String, dynamic>;
      _minPrice = priceRange['min'] as double?;
      _maxPrice = priceRange['max'] as double?;
    }

    _sortBy = filters['sortBy'] as String?;

    if (kDebugMode) {
      debugPrint(
          '🔍 Filters applied: recentlyAdded=$_recentlyAdded, highestRated=$_highestRated, fastestDelivery=$_fastestDelivery, minPrice=$_minPrice, maxPrice=$_maxPrice, sortBy=$_sortBy');
    }

    // ⚡ SWR PATTERN: Check Hive cache first, show immediately, then fetch in background
    _loadFiltersWithSWR();
  }

  /// ⚡ SWR PATTERN: Load filtered stores with stale-while-revalidate
  /// 1. Check Hive cache (if no advanced filters applied)
  /// 2. If found, update UI IMMEDIATELY with cached data
  /// 3. Fire API call in background
  /// 4. If API returns stores, swap them. If API returns 0, KEEP cached stores visible
  Future<void> _loadFiltersWithSWR() async {
    try {
      final splashController = Get.find<SplashController>();
      final moduleId = splashController.module?.id;

      // Only use cache if no advanced filters are applied (cache doesn't store filtered results)
      final hasAdvancedFilters = _recentlyAdded == true ||
          _highestRated == true ||
          _fastestDelivery == true ||
          _minPrice != null ||
          _maxPrice != null ||
          _sortBy != null;

      if (moduleId != null && !hasAdvancedFilters) {
        // ⚡ STEP 1: Check Hive cache (only for simple filters)
        final hiveService = HiveHomeCacheService();
        final cachedStoreModel = await hiveService.loadStores(moduleId);

        if (cachedStoreModel != null &&
            cachedStoreModel.stores != null &&
            cachedStoreModel.stores!.isNotEmpty) {
          // ⚡ STEP 2: Update UI IMMEDIATELY with cached data
          _allStoreModel = cachedStoreModel;
          update();

          if (kDebugMode) {
            debugPrint(
                '⚡ SWR: Loaded ${cachedStoreModel.stores!.length} cached stores for filters - UI updated instantly');
          }
        }
      }

      // ⚡ STEP 3: Fire API call in background (non-blocking)
      // Use silent reset to only clear store list, not categories/popular
      _silentStoreReset();

      // Load in background - if API returns data, it will overwrite cached data
      // If API returns 0, cached data remains visible (handled by EMPTY_V2 fix)
      getStoreList(1, true, source: DataSourceEnum.client);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ StoreController: Error in SWR pattern for filters - $e, falling back to direct load');
      }
      // Fallback to direct loading if SWR fails
      _silentStoreReset();
      getStoreList(1, true, source: DataSourceEnum.client);
    }
  }

  /// Clear all filters
  void clearFilters() {
    _recentlyAdded = null;
    _highestRated = null;
    _fastestDelivery = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = null;

    if (kDebugMode) {
      debugPrint('🔍 Filters cleared');
    }

    // Reload stores without filters
    getStoreList(1, true, source: DataSourceEnum.client);
  }

  /// Reset all store listing filters to default state.
  /// Set [reload] to true when you want fresh unfiltered stores immediately.
  void resetAllStoreFilters({bool reload = false, bool notify = true}) {
    _filterType = 'all';
    _storeType = 'all';
    _recentlyAdded = null;
    _highestRated = null;
    _fastestDelivery = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = null;

    if (reload) {
      _silentStoreReset();
      getStoreList(1, true, source: DataSourceEnum.client);
      return;
    }

    if (notify) {
      update();
    }
  }

  /// 🔒 TASK 2: Clear all module state including Hive cache
  /// This physically deletes cached data from Hive, forcing a fresh fetch
  Future<void> clearAllModuleState({bool reload = false}) async {
    if (kDebugMode) {
      debugPrint(
          '🧹 [StoreController] clearAllModuleState() - Clearing all module state and Hive cache');
    }

    // Clear Hive cache for current module
    try {
      final splashController = Get.find<SplashController>();
      final moduleId = splashController.module?.id;
      if (moduleId != null) {
        await _cacheService.clearModuleCache(moduleId);
        if (kDebugMode) {
          debugPrint(
              '✅ [StoreController] Hive cache cleared for module $moduleId');
        }
      } else {
        // If no module, clear all cache
        await _cacheService.clearAllCache();
        if (kDebugMode) {
          debugPrint('✅ [StoreController] All Hive cache cleared (no module)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [StoreController] Error clearing Hive cache: $e');
      }
    }

    // Clear all store data
    await clearStoreData();

    if (reload) {
      // Force reload stores for new location
      if (kDebugMode) {
        debugPrint('🔄 [StoreController] Reloading stores for new location');
      }
      getStoreList(1, true);
    }
  }

  /// Clear all store-related cached data when switching modules
  /// This ensures each module shows only its own stores and prevents ghost data contamination
  Future<void> clearStoreData() async {
    // ⚠️ CRITICAL FIX: Cancel any ongoing loading operations
    if (_isLoadingPopularStores && _popularStoresLoadingCompleter != null) {
      debugPrint(
          '🛑 StoreController: Cancelling ongoing popular stores load during module switch');
      if (!_popularStoresLoadingCompleter!.isCompleted) {
        _popularStoresLoadingCompleter!.complete(null);
      }
      _isLoadingPopularStores = false;
      _popularStoresLoadingCompleter = null;
    }

    // Cancel item loading
    if (_itemsRequestCancelToken != null) {
      _itemsRequestCancelToken!.cancel();
      _itemsRequestCancelToken = null;
    }

    // Cancel category debounce timer
    _categoryDebounceTimer?.cancel();
    _categoryDebounceTimer = null;

    // ⚡ HARD-ISOLATION: Clear both storeModel and allStoreModel
    _storeModel = null;
    _allStoreModel = null;

    // ✅ CLEAR ALL STORE DATA IMMEDIATELY (prevent ghost data)
    _store = null; // Current store details
    _popularStoreList = null;
    _latestStoreList = null;
    _topOfferStoreList = null;
    _featuredStoreList = null;
    _visitAgainStoreList = null;
    _recommendedStoreList = null;

    // ✅ CLEAR ALL CATEGORY DATA IMMEDIATELY (prevent ghost data)
    _storeSpecificCategoryList = null; // Categories from previous module
    _allCategories = null; // All categories from previous module
    _subCategoryList = null; // Subcategories from previous module
    _lastStoreIdForCategories = null; // Previous store ID tracking
    _visibleCategoryCount = 15; // Reset visible count
    _isLoadingMoreCategories = false; // Reset loading flag

    // ✅ CLEAR ALL ITEM DATA IMMEDIATELY (prevent ghost data)
    _storeItemModel = null; // Items from previous module
    _storeSearchItemModel = null; // Search items from previous module
    // ⚡ STREAMING BUCKET: Clear streaming state when switching modules
    _allStoreItems = null;
    _visibleItemList = null;
    _categoryIndex = 0; // Reset category index
    _subCategoryIndex = 0; // Reset subcategory index
    _currentItemsOffset = 1; // Reset pagination state
    _hasMoreItems = true; // Reset pagination flag

    // Reset filters to default
    _filterType = 'all';
    _storeType = 'all';
    _type = 'all'; // Reset type filter
    _recentlyAdded = null;
    _highestRated = null;
    _fastestDelivery = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = null;

    update(); // Update UI immediately to show empty state

    // Small delay to ensure UI properly updates before loading new data
    await Future.delayed(const Duration(milliseconds: 100));

    if (kDebugMode) {
      debugPrint(
          '✅ StoreController: Cleared ALL store data for module switch (including ghost data)');
    }
  }

  /// Get popular store list for top sections (V2/legacy)
  ///
  /// 🚫 CRITICAL: This method ONLY sets _popularStoreList, NEVER _storeModel
  /// V2 must NEVER touch storeModel - it's exclusively managed by legacy pagination engine
  /// This prevents V2 from overwriting totalSize with wrong value (9 popular stores vs 300+ all stores)
  Future<List<Store>?> getPopularStoreList(
      bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    if (!_canFetchStores()) {
      return _popularStoreList;
    }
    _hasPopularStoresError = false;
    // 🔍 DEBUG: Entry point verification
    debugPrint(
        '🚀 getPopularStoreList() ENTRY - reload: $reload, type: $type, dataSource: $dataSource');

    // 🚫 DEFENSIVE: Verify we never accidentally set storeModel
    // This is a compile-time guarantee - if you see _storeModel = ... here, it's a bug!

    // ⚠️ CRITICAL FIX: Prevent duplicate simultaneous calls when switching modules
    // If already loading, wait for the existing call to complete
    if (_isLoadingPopularStores && _popularStoresLoadingCompleter != null) {
      debugPrint(
          '⏳ getPopularStoreList: Already loading, waiting for existing call...');
      return await _popularStoresLoadingCompleter!.future;
    }

    // ⚠️ CRITICAL: Handle case when HomeController is not registered
    HomeController? homeController;
    try {
      if (Get.isRegistered<HomeController>()) {
        homeController = Get.find<HomeController>();
      }
    } catch (e) {
      debugPrint('⚠️ StoreController: HomeController not available: $e');
    }
    final businessSettings = homeController?.business_Settings;

    // ✅ تحقق من تفعيل قسم المتاجر الشائعة
    // BYPASS: Always show Top Restaurants for Food and Ecommerce modules
    final splashController = Get.find<SplashController>();
    final isEcommerce = splashController.module?.moduleType.toString() ==
        AppConstants.ecommerce;
    final isFood =
        splashController.module?.moduleType.toString() == AppConstants.food;

    // 🔍 SECTION 2 API DEBUG: Business Settings Check
    debugPrint('🔍 SECTION 2 API - Business settings check:');
    debugPrint(
        '   - popularStoresSection: ${businessSettings?.popularStoresSection}');
    debugPrint('   - isEcommerce: $isEcommerce');
    debugPrint('   - isFood: $isFood');
    debugPrint(
        '   - Will load: ${businessSettings?.popularStoresSection?.toString() == "1" || isEcommerce || isFood}');

    if (businessSettings?.popularStoresSection?.toString() == '1' ||
        isEcommerce ||
        isFood) {
      _type = type;

      // ⚡ SILENT_FETCH MODE: Preserve cache during background refresh
      // If data already exists in memory, do NOT clear it - just fetch in background and overwrite when ready
      final hasExistingPopularData =
          _popularStoreList != null && _popularStoreList!.isNotEmpty;

      if (reload) {
        // Only clear if there's no existing data (first load or module switch)
        // If data exists, preserve it for visual continuity during background refresh
        if (!hasExistingPopularData) {
          _popularStoreList = null;
          if (kDebugMode) {
            debugPrint(
                '🔄 StoreController: Clearing popular stores (reload=true, no existing data)');
          }
        } else {
          // ⚡ SILENT_FETCH: Data exists - preserve it during background refresh
          if (kDebugMode) {
            debugPrint(
                '🔇 StoreController: SILENT_FETCH mode - preserving ${_popularStoreList!.length} cached popular stores during background refresh');
            debugPrint('   - Old stores will remain visible until new data arrives');
          }
        }
      }
      if (notify) {
        update();
      }

      if (_popularStoreList == null || reload || fromRecall) {
        // ⚠️ CRITICAL FIX: Set loading lock to prevent duplicate calls
        _isLoadingPopularStores = true;
        _popularStoresLoadingCompleter = Completer<List<Store>?>();

        try {
          List<Store>? popularStoreList;

          // 🔍 SECTION 2 API DEBUG: Popular Stores
          debugPrint('🔍 SECTION 2 API - getPopularStoreList called:');
          debugPrint('   - reload: $reload, type: $type, dataSource: $dataSource');
          debugPrint(
              '   - businessSettings.popularStoresSection: ${businessSettings?.popularStoresSection}');
          debugPrint('   - isEcommerce: $isEcommerce');

          if (dataSource == DataSourceEnum.local) {
            popularStoreList = await storeServiceInterface
                .getPopularStoreList(type, source: DataSourceEnum.local);
            debugPrint(
                '   📦 SECTION 2 API - Cache response: ${popularStoreList?.length ?? 0} restaurants');
            if (popularStoreList != null && popularStoreList.isNotEmpty) {
              _popularStoreList = [];
              _popularStoreList!.addAll(popularStoreList);
              debugPrint(
                  '   ✅ SECTION 2 API - Loaded ${popularStoreList.length} restaurants from cache');
              update();
              _updateHomeRestaurantSections();
            } else {
              debugPrint(
                  '   ⚠️ SECTION 2 API - Cache returned NULL or empty, falling back to API');
              // Fallback to API when cache is empty/null
              popularStoreList = await storeServiceInterface
                  .getPopularStoreList(type, source: DataSourceEnum.client);
              debugPrint(
                  '   📡 SECTION 2 API - API response: ${popularStoreList?.length ?? 0} restaurants');
              if (popularStoreList != null && popularStoreList.isNotEmpty) {
                _popularStoreList = [];
                _popularStoreList!.addAll(popularStoreList);
                debugPrint(
                    '   ✅ SECTION 2 API - Loaded ${popularStoreList.length} restaurants from API');
              } else {
                // ⚡ EMPTY_V2 CONTAMINATION FIX: If API returns empty but we have cached data, keep it
                // Better to show old stores than empty screen
                if (hasExistingPopularData &&
                    _popularStoreList != null &&
                    _popularStoreList!.isNotEmpty) {
                  if (kDebugMode) {
                    debugPrint(
                        '⚠️ StoreController: EMPTY_V2 contamination - API returned empty popular stores');
                    debugPrint(
                        '   - Keeping ${_popularStoreList!.length} cached popular stores visible (better than empty screen)');
                  }
                  // Don't update - keep showing cached stores
                } else {
                  // ⚡ FIX: Set empty list instead of null to show empty state UI
                  _popularStoreList = [];
                  debugPrint(
                      '   ⚠️ SECTION 2 API - API returned empty/null, setting empty list for empty state');
                }
              }
              update();
              _updateHomeRestaurantSections();
            }
          } else {
            debugPrint(
                '   🌐 SECTION 2 API - Calling API endpoint: /api/v1/stores/popular?type=$type');
            popularStoreList = await storeServiceInterface
                .getPopularStoreList(type, source: DataSourceEnum.client);
            debugPrint(
                '   📡 SECTION 2 API - API response: ${popularStoreList?.length ?? 0} restaurants');
            if (popularStoreList != null && popularStoreList.isNotEmpty) {
              debugPrint(
                  '   ✅ SECTION 2 API - Successfully loaded ${popularStoreList.length} restaurants');
              debugPrint(
                  '   📋 SECTION 2 API - First restaurant: id=${popularStoreList[0].id}, name=${popularStoreList[0].name}');
              _popularStoreList = [];
              _popularStoreList!.addAll(popularStoreList);
            } else {
              // ⚡ EMPTY_V2 CONTAMINATION FIX: If API returns empty but we have cached data, keep it
              // Better to show old stores than empty screen
              if (hasExistingPopularData &&
                  _popularStoreList != null &&
                  _popularStoreList!.isNotEmpty) {
                if (kDebugMode) {
                  debugPrint(
                      '⚠️ StoreController: EMPTY_V2 contamination - API returned empty popular stores');
                  debugPrint(
                      '   - Keeping ${_popularStoreList!.length} cached popular stores visible (better than empty screen)');
                }
                // Don't update - keep showing cached stores
              } else {
                // ⚡ FIX: Set empty list instead of null to show empty state UI
                _popularStoreList = [];
                debugPrint(
                    '   ❌ SECTION 2 API - API returned NULL or EMPTY list, setting empty list for empty state');
              }
            }
            update();
            _updateHomeRestaurantSections();
          }

          // Complete the completer with result
          if (!_popularStoresLoadingCompleter!.isCompleted) {
            _popularStoresLoadingCompleter!.complete(_popularStoreList);
          }
        } catch (e) {
          debugPrint('❌ getPopularStoreList: Error loading stores - $e');
          _hasPopularStoresError = true;
          // ⚡ FIX: Set empty list on error to show empty state UI instead of shimmer
          _popularStoreList = [];
          update();
          // Complete the completer with empty list
          if (!_popularStoresLoadingCompleter!.isCompleted) {
            _popularStoresLoadingCompleter!.complete(_popularStoreList);
          }
          // Don't rethrow - we've handled it by setting empty list
        } finally {
          // Reset loading lock
          _isLoadingPopularStores = false;
          _popularStoresLoadingCompleter = null;
        }
      } else {
        debugPrint(
            '🔍 SECTION 2 API - Skipping API call (data already loaded, reload=$reload, fromRecall=$fromRecall)');
      }
    }
    return _popularStoreList;
  }

  Future<void> getLatestStoreList(bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    if (!_canFetchStores()) {
      return;
    }
    // ✅ RE-ENABLED: Backend UTF-8 and 500 errors have been fixed
    if (reload) {
      _latestStoreList = null;
    }
    if (notify) {
      update();
    }
    if (_latestStoreList == null || reload || fromRecall) {
      List<Store>? latestStoreList;
      if (dataSource == DataSourceEnum.local) {
        latestStoreList = await storeServiceInterface.getLatestStoreList(type,
            source: DataSourceEnum.local);
        if (latestStoreList != null && latestStoreList.isNotEmpty) {
          _latestStoreList = [];
          _latestStoreList!.addAll(latestStoreList);
          update();
          await getLatestStoreList(false, type, notify,
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          // Fallback to API when cache is empty/null
          latestStoreList = await storeServiceInterface.getLatestStoreList(type,
              source: DataSourceEnum.client);
          if (latestStoreList != null && latestStoreList.isNotEmpty) {
            _latestStoreList = [];
            _latestStoreList!.addAll(latestStoreList);
          } else {
            _latestStoreList = [];
          }
          update();
        }
      } else {
        latestStoreList = await storeServiceInterface.getLatestStoreList(type,
            source: DataSourceEnum.client);
        if (latestStoreList != null && latestStoreList.isNotEmpty) {
          _latestStoreList = [];
          _latestStoreList!.addAll(latestStoreList);
        } else {
          _latestStoreList = [];
        }
        update();
      }
    }
  }

  Future<void> getTopOfferStoreList(bool reload, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    if (!_canFetchStores()) {
      return;
    }
    // ⚠️ CRITICAL: Handle case when HomeController is not registered
    HomeController? homeController;
    try {
      if (Get.isRegistered<HomeController>()) {
        homeController = Get.find<HomeController>();
      }
    } catch (e) {
      debugPrint('⚠️ StoreController: HomeController not available: $e');
    }
    final businessSettings = homeController?.business_Settings;

    // ✅ تحقق من تفعيل القسم
    if (businessSettings?.topStoresOffersNearMeSection?.toString() == '1') {
      if (reload) {
        _topOfferStoreList = null;
      }
      if (notify) {
        update();
      }
      if (_topOfferStoreList == null || reload || fromRecall) {
        List<Store>? latestStoreList;
        if (dataSource == DataSourceEnum.local) {
          latestStoreList = await storeServiceInterface.getTopOfferStoreList(
              source: DataSourceEnum.local);
          _topOfferStoreList = [];
          if (latestStoreList != null) {
            _topOfferStoreList!.addAll(latestStoreList);
          }
          update();
          await getTopOfferStoreList(false, notify,
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          latestStoreList = await storeServiceInterface.getTopOfferStoreList(
              source: DataSourceEnum.client);
          _topOfferStoreList = [];
          if (latestStoreList != null) {
            _topOfferStoreList!.addAll(latestStoreList);
          }
          update();
        }
      }
    }
  }

  Future<void> getFeaturedStoreList(
      {DataSourceEnum dataSource = DataSourceEnum.local}) async {
    if (!_canFetchStores()) {
      return;
    }
    List<Store>? stores;
    if (dataSource == DataSourceEnum.local) {
      stores =
          await storeServiceInterface.getFeaturedStoreList(source: dataSource);
      _prepareFeaturedStore(stores);
      getFeaturedStoreList(dataSource: DataSourceEnum.client);
    } else {
      stores =
          await storeServiceInterface.getFeaturedStoreList(source: dataSource);
      _prepareFeaturedStore(stores);
    }
  }

  void _prepareFeaturedStore(List<Store>? stores) {
    if (stores != null) {
      _featuredStoreList = [];
      final List<Modules> moduleList = [];
      moduleList.addAll(storeServiceInterface.moduleList());
      for (final Store store in stores) {
        for (final module in moduleList) {
          if (module.id == store.moduleId) {
            if (module.pivot!.zoneId == store.zoneId) {
              _featuredStoreList!.add(store);
            }
          }
        }
      }
    }
    update();
  }

  Future<void> getVisitAgainStoreList({
    bool fromModule = false,
    DataSourceEnum dataSource = DataSourceEnum.local,
    bool fromRecall = false,
  }) async {
    if (!_canFetchStores()) {
      return;
    }
    // ✅ FIXED: Don't call visit-again API for guest users (prevents 500 errors)
    if (!AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) {
      if (kDebugMode) {
        debugPrint(
            '🚫 getVisitAgainStoreList: Skipping - user is guest or not logged in');
      }
      return;
    }

    final businessSettings = Get.find<HomeController>().business_Settings;

    if (businessSettings?.visitAgainSection?.toString() == '1') {
      List<Store>? stores;

      if (fromModule && !fromRecall) {
        _visitAgainStoreList = null;
      }

      if (dataSource == DataSourceEnum.local) {
        stores = await storeServiceInterface.getVisitAgainStoreList(
            source: DataSourceEnum.local);
        _prepareVisitAgainStore(stores);

        // ✅ FIXED: Only call client API if local cache is empty/null
        // This prevents unnecessary duplicate API calls
        if (stores == null || stores.isEmpty) {
          await getVisitAgainStoreList(
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          if (kDebugMode) {
            debugPrint(
                '✅ getVisitAgainStoreList: Using cached data, skipping client API call');
          }
        }
      } else {
        stores = await storeServiceInterface.getVisitAgainStoreList(
            source: DataSourceEnum.client);
        _prepareVisitAgainStore(stores);
      }
      update();
    }
  }

  void _prepareVisitAgainStore(List<Store>? stores) {
    if (stores != null) {
      _visitAgainStoreList = [];
      final List<Modules> moduleList = [];
      moduleList.addAll(storeServiceInterface.moduleList());
      for (final store in stores) {
        for (final module in moduleList) {
          if (module.id == store.moduleId) {
            if (module.pivot!.zoneId == store.zoneId) {
              _visitAgainStoreList!.add(store);
            }
          }
        }
      }
    }
    update();
  }

  void setCategoryList({bool forceRefresh = false}) {
    // #region agent log
    _writeDebugLog(
        'store_controller.dart:982',
        'setCategoryList called',
        {
          'storeId': _store?.id,
          'hasStore': _store != null,
          'forceRefresh': forceRefresh,
        },
        'D');
    // #endregion

    if (_store == null) {
      if (kDebugMode) {
        debugPrint(
            '📍 [StoreController] setCategoryList() - File: store_controller.dart');
        debugPrint('   ⚠️ Store is null');
      }
      return;
    }

    // 🔧 CRITICAL FIX: Skip setCategoryList if categoryDetails is empty
    // Categories should only be built from store.category_details, not from CategoryController or fallback
    // This prevents building empty/fake categories that break the menu display
    if (_store!.categoryDetails == null || _store!.categoryDetails!.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '⏭️ [StoreController] setCategoryList() - Skipping: store.categoryDetails is empty');
        debugPrint(
            '   💡 Categories must come from store.category_details - skipping setCategoryList()');
      }
      return;
    }

    // 🔒 TASK 1: BLOCK GLOBAL FALLBACK - Never assign to _storeSpecificCategoryList when storeId != null
    // This physically prevents any store data from ever touching the global variable used by the Home Screen
    final storeId = _store?.id;
    if (storeId != null) {
      // When we have a store ID, we MUST use _specificStoreCategoryList only
      // NEVER assign to _storeSpecificCategoryList - it's reserved for global categories (Home Screen)
      // Early return ensures we never accidentally touch _storeSpecificCategoryList in this method
    }

    // 🎯 CRITICAL FIX: If slim menu is loaded, NEVER overwrite its categories
    // Slim menu already has all categories and items - don't let setCategoryList() destroy it
    if (_slimMenuLoaded &&
        _allCategories != null &&
        _allCategories!.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '🚀 [StoreController] setCategoryList() - SKIPPING: Slim menu already loaded with ${_allCategories!.length} categories');
        debugPrint(
            '   💡 Slim menu categories take priority - store details categories ignored');
      }
      return; // Don't overwrite slim menu categories!
    }

    // Prevent excessive rebuilds - if categories already set and store hasn't changed, skip
    // 🔧 FIX: Check if categories belong to current store before skipping
    // ⚠️ CRITICAL: Also check if categoryDetails is now available (wasn't before)
    // If categoryDetails is available, we should use it even if _allCategories is already set
    final currentStoreId = _store?.id;
    final hasCategoryDetails =
        _store?.categoryDetails != null && _store!.categoryDetails!.isNotEmpty;
    final shouldSkip = !forceRefresh &&
        _allCategories != null &&
        _allCategories!.isNotEmpty &&
        _lastStoreIdForCategories == currentStoreId &&
        !hasCategoryDetails; // Don't skip if categoryDetails is now available

    if (shouldSkip) {
      if (kDebugMode) {
        debugPrint(
            '📍 [StoreController] setCategoryList() - Skipping (categories already loaded for store $currentStoreId)');
      }
      return;
    }

    // If categoryDetails is now available but wasn't used before, force refresh
    if (hasCategoryDetails &&
        _allCategories != null &&
        _allCategories!.isNotEmpty &&
        _lastStoreIdForCategories == currentStoreId) {
      if (kDebugMode) {
        debugPrint(
            '🔄 [StoreController] setCategoryList() - categoryDetails now available, refreshing categories');
      }
      // Continue to reload with categoryDetails
    }

    // 🔧 FIX: If store changed, clear old categories
    if (_lastStoreIdForCategories != null &&
        _lastStoreIdForCategories != currentStoreId) {
      if (kDebugMode) {
        debugPrint(
            '🔄 [StoreController] setCategoryList() - Store changed from $_lastStoreIdForCategories to $currentStoreId - Clearing old categories');
      }
      _storeSpecificCategoryList = null;
      _allCategories = null;
      _visibleCategoryCount = 15;
    }

    if (kDebugMode) {
      debugPrint(
          '📍 [StoreController] setCategoryList() - File: store_controller.dart');
      debugPrint('   🏪 Store ID: ${_store!.id}, Store name: ${_store!.name}');
      debugPrint('   📋 Store categoryIds: ${_store!.categoryIds}');
      debugPrint(
          '   📋 Store categoryDetails: ${_store!.categoryDetails?.length ?? 0} categories');
      if (_store!.categoryDetails != null &&
          _store!.categoryDetails!.isNotEmpty) {
        debugPrint(
            '   📋 categoryDetails IDs: ${_store!.categoryDetails!.map((c) => c.id).toList()}');
      } else if (_store!.categoryIds != null &&
          _store!.categoryIds!.isNotEmpty) {
        debugPrint(
            '   ⚠️ categoryDetails is empty but categoryIds exist: ${_store!.categoryIds}');
        debugPrint(
            '   💡 This means category_details was not included in store details API response');
      }
    }

    // Reset lazy loading state
    _visibleCategoryCount = 15;
    _allCategories = [];
    _allCategories!.add(CategoryModel(id: 0, name: 'all_products'.tr));
    // 🔒 TASK 1: ISOLATE CATEGORY LISTS - Don't set _storeSpecificCategoryList (it's for global categories)
    _specificStoreCategoryList = null; // Reset store-specific list

    // Priority 1: Use category_details from store response (CORRECT APPROACH per backend documentation)
    if (_store!.categoryDetails != null &&
        _store!.categoryDetails!.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '   ✅ Using category_details from store response (${_store!.categoryDetails!.length} categories)');
        debugPrint(
            '   📋 Category IDs: ${_store!.categoryDetails!.map((c) => c.id).toList()}');
      }

      // Get current language code
      final currentLanguageCode =
          Get.find<LocalizationController>().locale.languageCode;

      // Filter out duplicate categories (same name and position) and parent categories (parent_id != 0)
      final Map<String, CategoryModel> uniqueCategories = {};

      for (final category in _store!.categoryDetails!) {
        // Skip categories with parent_id (these are subcategories, not main menu categories)
        if (category.parentId != null && category.parentId != 0) {
          if (kDebugMode) {
            debugPrint(
                '      ⏭️ Skipping subcategory ${category.id} (parent_id: ${category.parentId})');
          }
          continue;
        }

        // Create a copy to avoid modifying the original
        final categoryCopy = CategoryModel(
          id: category.id,
          name: category.name,
          nameAr: category.nameAr,
          nameEn: category.nameEn,
          parentId: category.parentId,
          position: category.position,
          storeId: category.storeId,
          productsCount: category.productsCount,
          childesCount: category.childesCount,
          createdAt: category.createdAt,
          updatedAt: category.updatedAt,
          image: category.image,
          imageFullUrl: category.imageFullUrl,
          moduleId: category.moduleId,
          catSiteId: category.catSiteId,
        );

        // Debug: Log what we received from API
        if (kDebugMode) {
          debugPrint('      📦 Category ${category.id} from API:');
          debugPrint('         - name: ${category.name}');
          debugPrint('         - nameAr: ${category.nameAr ?? "NULL"}');
          debugPrint('         - nameEn: ${category.nameEn ?? "NULL"}');
          debugPrint('         - parentId: ${category.parentId}');
        }

        // Apply language-specific name if available
        // Backend should return translated name in 'name' field, but use nameAr/nameEn as fallback
        if (currentLanguageCode == 'ar') {
          if (category.nameAr != null && category.nameAr!.isNotEmpty) {
            categoryCopy.name = category.nameAr;
            if (kDebugMode) {
              debugPrint(
                  '      ✅ Using Arabic name for category ${category.id}: ${category.nameAr}');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '      ⚠️ Category ${category.id} has no Arabic name (nameAr is null/empty), using: ${category.name}');
            }
          }
        } else if (currentLanguageCode == 'en') {
          if (category.nameEn != null && category.nameEn!.isNotEmpty) {
            categoryCopy.name = category.nameEn;
            if (kDebugMode) {
              debugPrint(
                  '      ✅ Using English name for category ${category.id}: ${category.nameEn}');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '      ⚠️ Category ${category.id} has no English name (nameEn is null/empty), using: ${category.name}');
            }
          }
        }

        // Use position + name as unique key to filter duplicates
        final uniqueKey = '${category.position ?? 0}_${categoryCopy.name}';
        if (!uniqueCategories.containsKey(uniqueKey)) {
          uniqueCategories[uniqueKey] = categoryCopy;
        } else {
          // If duplicate found, keep the one with lower ID
          final existing = uniqueCategories[uniqueKey]!;
          if (category.id != null &&
              existing.id != null &&
              category.id! < existing.id!) {
            uniqueCategories[uniqueKey] = categoryCopy;
            if (kDebugMode) {
              debugPrint(
                  '      🔄 Replaced duplicate category (kept lower ID: ${category.id})');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '      ⏭️ Skipping duplicate category ${category.id} (already have ${existing.id})');
            }
          }
        }
      }

      // Convert to list and sort
      final sortedCategories = uniqueCategories.values.toList()
        ..sort((a, b) {
          final aPos = a.position ?? 0;
          final bPos = b.position ?? 0;
          if (aPos != bPos) return aPos.compareTo(bPos);
          return (a.id ?? 0).compareTo(b.id ?? 0);
        });

      _allCategories!.addAll(sortedCategories);
      // 🔒 TASK 1: ISOLATE CATEGORY LISTS - Save to store-specific list, NOT global _storeSpecificCategoryList
      // This prevents store categories from overwriting global categories on Home Screen
      _specificStoreCategoryList = List.from(_allCategories!);
      // ⚠️ DO NOT set _storeSpecificCategoryList here - it's for global categories only

      // 🔧 FIX: Track which store these categories belong to
      _lastStoreIdForCategories = _store?.id;

      if (kDebugMode) {
        debugPrint(
            '   📊 Categories from store response: ${sortedCategories.length}');
        debugPrint('   🌐 Current language: $currentLanguageCode');
        debugPrint('   📦 Total categories loaded: ${_allCategories!.length}');
        debugPrint('   👁️ Visible categories: $_visibleCategoryCount');
        debugPrint(
            '   🏪 Categories belong to store ID: $_lastStoreIdForCategories');
        for (final cat in sortedCategories.take(5)) {
          debugPrint(
              '      - ID: ${cat.id}, Name: ${cat.name}, Position: ${cat.position}');
        }
        if (sortedCategories.length > 5) {
          debugPrint('      ... and ${sortedCategories.length - 5} more');
        }
      }

      // 🔧 DISABLED: Auto-load-more was causing premature expansion
      // Categories now load only when user scrolls near the end (see store_screen.dart line 2101)
      // if (_allCategories!.length > _visibleCategoryCount) {
      //   Future.delayed(const Duration(milliseconds: 500), () {
      //     loadMoreCategories();
      //   });
      // }
    }
    // Priority 2: Extract categories from items' categoryIds arrays (fallback if category_details not available)
    else if (_storeItemModel != null &&
        _storeItemModel!.items != null &&
        _storeItemModel!.items!.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '   ⚠️ category_details not available, extracting from items (${_storeItemModel!.items!.length} items)');
      }

      final Map<int, CategoryModel> uniqueCategories = {};

      for (final item in _storeItemModel!.items!) {
        // Extract categories from item's categoryIds array
        if (item.categoryIds != null && item.categoryIds!.isNotEmpty) {
          for (final categoryData in item.categoryIds!) {
            if (categoryData.id != null &&
                categoryData.id! > 0 &&
                categoryData.name != null) {
              if (!uniqueCategories.containsKey(categoryData.id!)) {
                uniqueCategories[categoryData.id!] = CategoryModel(
                  id: categoryData.id,
                  name: categoryData.name,
                  storeId: _store!.id,
                  position: categoryData.position,
                );
                if (kDebugMode) {
                  debugPrint(
                      '      ✅ Extracted category from items - ID: ${categoryData.id}, Name: ${categoryData.name}');
                }
              }
            }
          }
        }
        // Fallback: Use item's categoryId if categoryIds array is empty
        else if (item.categoryId != null && item.categoryId! > 0) {
          if (!uniqueCategories.containsKey(item.categoryId!)) {
            // Try to find category name from CategoryController first
            String? categoryName;
            if (Get.find<CategoryController>().categoryList != null) {
              try {
                final foundCategory =
                    Get.find<CategoryController>().categoryList!.firstWhere(
                          (cat) => cat.id == item.categoryId,
                          orElse: () => CategoryModel(),
                        );
                if (foundCategory.id != null) {
                  categoryName = foundCategory.name;
                }
              } catch (e) {
                // Category not found, will use default name
              }
            }

            uniqueCategories[item.categoryId!] = CategoryModel(
              id: item.categoryId,
              name: categoryName ?? 'Category ${item.categoryId}',
              storeId: _store!.id,
            );
            if (kDebugMode) {
              debugPrint(
                  '      ✅ Extracted category from item.categoryId - ID: ${item.categoryId}, Name: ${categoryName ?? "Unknown"}');
            }
          }
        }
      }

      // Add unique categories to the list, sorted by position if available
      final sortedCategories = uniqueCategories.values.toList()
        ..sort((a, b) {
          final aPos = a.position ?? 0;
          final bPos = b.position ?? 0;
          if (aPos != bPos) return aPos.compareTo(bPos);
          return (a.id ?? 0).compareTo(b.id ?? 0);
        });

      _allCategories!.addAll(sortedCategories);
      // 🔒 TASK 1: ISOLATE CATEGORY LISTS - Save to store-specific list, NOT global _storeSpecificCategoryList
      // This prevents store categories from overwriting global categories on Home Screen
      _specificStoreCategoryList = List.from(_allCategories!);
      // ⚠️ DO NOT set _storeSpecificCategoryList here - it's for global categories only

      // 🔧 FIX: Track which store these categories belong to
      _lastStoreIdForCategories = _store?.id;

      if (kDebugMode) {
        debugPrint(
            '   📊 Categories extracted from items: ${sortedCategories.length}');
        debugPrint(
            '      - Total categories in store list: ${_allCategories!.length}');
        debugPrint('      - Visible categories: $_visibleCategoryCount');
        debugPrint(
            '      - Categories belong to store ID: $_lastStoreIdForCategories');
      }

      // 🔧 DISABLED: Auto-load-more was causing premature expansion
      // Categories now load only when user scrolls near the end (see store_screen.dart line 2101)
      // if (_allCategories!.length > _visibleCategoryCount) {
      //   Future.delayed(const Duration(milliseconds: 500), () {
      //     loadMoreCategories();
      //   });
      // }
    }
    // Priority 3: Try to match from CategoryController (last resort fallback)
    // ⚠️ CRITICAL FIX: Only match by categoryIds, NOT by storeId
    // Matching by storeId is too loose and can match wrong categories from global list
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
      for (final category in Get.find<CategoryController>().categoryList!) {
        // Only match if category.id is in store's categoryIds array
        if (category.id != null && _store!.categoryIds!.contains(category.id)) {
          // 🔒 PHASE 2: Deep clone to prevent memory sharing
          _allCategories!.add(CategoryModel.fromJson(category.toJson()));
          matchedByCategoryIds++;
          if (kDebugMode) {
            debugPrint(
                '      ✅ Matched by categoryIds - Category ID: ${category.id}, Name: ${category.name}');
          }
        }
      }

      // Only proceed if we found matches
      if (matchedByCategoryIds > 0) {
        // 🔒 TASK 1: ISOLATE CATEGORY LISTS - Save to store-specific list, NOT global _storeSpecificCategoryList
        // This prevents store categories from overwriting global categories on Home Screen
        // 🔒 PHASE 2: Deep clone to ensure physical memory isolation
        _specificStoreCategoryList = _allCategories!
            .map((cat) => CategoryModel.fromJson(cat.toJson()))
            .toList();
        // ⚠️ DO NOT set _storeSpecificCategoryList here - it's for global categories only

        // 🔧 FIX: Track which store these categories belong to
        _lastStoreIdForCategories = _store?.id;

        if (kDebugMode) {
          debugPrint('   📊 Category matching results:');
          debugPrint('      - Matched by categoryIds: $matchedByCategoryIds');
          debugPrint(
              '      - Total categories in store list: ${_allCategories!.length}');
          debugPrint('      - Visible categories: $_visibleCategoryCount');
          debugPrint(
              '      - Categories belong to store ID: $_lastStoreIdForCategories');
        }

        // 🔧 DISABLED: Auto-load-more was causing premature expansion
        // Categories now load only when user scrolls near the end (see store_screen.dart line 2101)
        // if (_allCategories!.length > _visibleCategoryCount) {
        //   Future.delayed(const Duration(milliseconds: 500), () {
        //     loadMoreCategories();
        //   });
        // }
      } else {
        if (kDebugMode) {
          debugPrint(
              '   ⚠️ No categories matched from CategoryController - store categoryIds ${_store!.categoryIds} not found in global category list');
          debugPrint(
              '   💡 This is expected if store uses module-specific categories not in global list');
        }
        // Don't set _specificStoreCategoryList - keep it null so UI can handle empty state
      }
    } else {
      if (kDebugMode) {
        if (_store!.categoryIds == null || _store!.categoryIds!.isEmpty) {
          debugPrint(
              '   ⚠️ No category sources available - store has no categoryIds');
        } else {
          debugPrint(
              '   ⚠️ No category sources available (category_details, items, or CategoryController)');
        }
      }
    }
  }

  /// Load more categories in the background (lazy loading)
  /// Increases visible count gradually to improve performance
  void loadMoreCategories() {
    if (_allCategories == null || _isLoadingMoreCategories) return;
    if (_allCategories!.length <= _visibleCategoryCount) return;

    _isLoadingMoreCategories = true;

    if (kDebugMode) {
      debugPrint(
          '🔄 [StoreController] loadMoreCategories() - Loading more categories');
      debugPrint(
          '   📊 Current visible: $_visibleCategoryCount / ${_allCategories!.length}');
    }

    // Load in batches: increase by 4 more categories
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_allCategories == null) {
        _isLoadingMoreCategories = false;
        return;
      }

      // 🔧 FIX: Only update if visible count actually changed
      final previousCount = _visibleCategoryCount;
      final newCount =
          (_visibleCategoryCount + 15).clamp(0, _allCategories!.length);
      _visibleCategoryCount = newCount;
      _isLoadingMoreCategories = false;

      if (kDebugMode) {
        debugPrint(
            '   ✅ Loaded more categories: $_visibleCategoryCount / ${_allCategories!.length} visible');
      }

      // Only call update() if the visible count actually changed
      if (previousCount != _visibleCategoryCount) {
        update(); // Notify UI to rebuild
      } else if (kDebugMode) {
        debugPrint(
            '   ⏭️ Skipping update() - visible count unchanged ($previousCount)');
      }

      // 🔧 DISABLED: Auto-load-more was causing premature expansion
      // Categories now load only when user scrolls near the end (see store_screen.dart line 2101)
      // if (_allCategories!.length > _visibleCategoryCount) {
      //   Future.delayed(const Duration(milliseconds: 200), () {
      //     loadMoreCategories();
      //   });
      // }
    });
  }

  Future<void> initCheckoutData(context, int? storeId) async {
    Get.find<CouponController>().removeCouponData(false);
    Get.find<CheckoutController>().clearPrevData();
    await Get.find<StoreController>()
        .getStoreDetails(context, Store(id: storeId), false);
    Get.find<CheckoutController>().initializeTimeSlot(_store!);
  }

  // 🛠️ TASK 3: SWR Pattern - Cache service for store details
  final HiveHomeCacheService _cacheService = HiveHomeCacheService();

  // Error state for retry button
  bool _hasStoreError = false;
  bool get hasStoreError => _hasStoreError;
  int? _storeErrorStatusCode;
  int? get storeErrorStatusCode => _storeErrorStatusCode;

  /// ⚡ SILICON VALLEY WAY: Set mini-cache for instant UI display
  /// Uses basic store data (name, logo, rating, etc.) immediately for 0ms perceived load
  /// Includes all fields needed for instant header/info section display
  /// ✅ FIX: Uses Future.microtask to defer update() and prevent "setState during build" errors
  void setStoreMiniCache(Store store) {
    if (store.id == null) return;

    final newStoreId = store.id;
    // Only update if we're switching to a different store or store is null
    if (_store?.id != newStoreId) {
      _store = Store(
        id: newStoreId,
        name: store.name,
        logoFullUrl: store.logoFullUrl,
        coverPhotoFullUrl: store.coverPhotoFullUrl,
        avgRating: store.avgRating,
        ratingCount: store.ratingCount,
        distance: store.distance,
        address: store.address,
        deliveryTime: store.deliveryTime,
        minimumOrder: store.minimumOrder,
        minimumShippingCharge: store.minimumShippingCharge,
        maximumShippingCharge: store.maximumShippingCharge,
        perKmShippingCharge: store.perKmShippingCharge,
        freeDelivery: store.freeDelivery,
        delivery: store.delivery,
        takeAway: store.takeAway,
        isOpen: store.isOpen,
        isOpenNow: store.isOpenNow,
        active: store.active,
        discount: store.discount,
        categoryIds: store.categoryIds,
        categoryDetails: store.categoryDetails,
        moduleId: store.moduleId,
        slug: store.slug,
        // Preserve other fields from existing _store if same ID
      );
      if (kDebugMode) {
        debugPrint(
            '⚡ [StoreController] SILICON VALLEY WAY: Mini-cache set for store $newStoreId - header visible instantly (0ms)');
        debugPrint(
            '   📋 Cached fields: name, logo, coverPhoto, rating, distance, deliveryTime, address, pricing');
      }
      // ✅ FIX: Defer update() using microtask to prevent setState during build
      // microtask is lighter than postFrameCallback and ensures update runs after current stack
      Future.microtask(() {
        if (!isClosed) update();
      });
    }
  }

  Future<Store?> getStoreDetails(context, Store store, bool fromModule,
      {bool fromCart = false,
      String slug = '',
      CancelToken? cancelToken}) async {
    _categoryIndex = 0;
    _hasStoreError = false;
    _storeErrorStatusCode = null;

    // 🔧 FIX: Clear categories if store ID is changing
    final newStoreId = store.id;
    _activeStoreModuleId =
        store.moduleId ?? Get.find<SplashController>().module?.id;
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
      _visibleCategoryCount = 15;
      _lastStoreIdForCategories = null;
    }

    // ⚡ TASK 2: Prevent duplicate header calls
    if (_isLoadingStoreDetails && _loadingStoreDetailsId == newStoreId) {
      if (kDebugMode) {
        debugPrint(
            '🚫 [StoreController] getStoreDetails already in progress for store $newStoreId - skipping duplicate call');
      }
      if (_store != null) {
        return _store;
      }
      if (_storeDetailsCompleter != null) {
        return await _storeDetailsCompleter!.future;
      }
      return _store;
    }

    // ⚡ TASK 1: MINI-CACHE ON ENTRY - Use basic store data immediately (0ms perceived load)
    // If store has basic data (name, logo, rating), set it immediately for instant header display
    // ✅ FIX: Skip mini-cache in getStoreDetails - it's already handled by setStoreMiniCache in screens
    // This prevents duplicate updates and potential setState during build issues

    // Set loading state to prevent duplicate calls
    _isLoadingStoreDetails = true;
    _loadingStoreDetailsId = newStoreId;
    _storeDetailsCompleter = Completer<Store?>();

    if (store.name != null && store.categoryDetails != null) {
      // Full store data already available - no need to fetch
      _store = store;
      _isLoading = false;
      _isLoadingStoreDetails = false;
      _loadingStoreDetailsId = null;
      if (!(_storeDetailsCompleter?.isCompleted ?? true)) {
        _storeDetailsCompleter?.complete(_store);
      }
      _storeDetailsCompleter = null;
      // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
      return store;
    } else {
      // 🛠️ TASK 3: SWR Pattern - STEP 1: Load from cache immediately
      if (newStoreId != null) {
        try {
          final cachedStore = await _cacheService.loadStoreDetails(newStoreId);
          if (cachedStore != null) {
            if (kDebugMode) {
              debugPrint(
                  '⚡ [StoreController] SWR: Loaded store $newStoreId from cache - data loaded (update deferred to loadAllStoreDetails)');
            }
            _store = cachedStore;
            _lastStoreIdForCategories = newStoreId;
            // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ [StoreController] SWR: Error loading from cache: $e');
          }
        }
      }

      // 🛠️ TASK 3: SWR Pattern - STEP 2: Fetch fresh data from API in background
      _isLoading = true;
      // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
      // Don't clear store or update UI if we have cached data (prevents flicker)
      // Loading state will be shown by loadAllStoreDetails if needed

      try {
        final SplashController splashController = Get.find<SplashController>();
        final int? targetModuleId =
            _activeStoreModuleId ?? splashController.module?.id;
        ModuleModel? targetModule;
        if (targetModuleId != null) {
          final List<ModuleModel> modules =
              splashController.moduleList ?? <ModuleModel>[];
          for (final ModuleModel moduleItem in modules) {
            if (moduleItem.id == targetModuleId) {
              targetModule = moduleItem;
              break;
            }
          }
        }
        final Store? storeDetails = await storeServiceInterface.getStoreDetails(
            store.id.toString(),
            fromCart,
            slug,
            Get.find<LocalizationController>().locale.languageCode,
            targetModule ?? ModuleHelper.getModule(),
            targetModuleId ?? ModuleHelper.getCacheModule()?.id,
            targetModuleId ?? ModuleHelper.getModule()?.id,
            cancelToken);

        // 🛑 PHASE 1: Check cancellation immediately after response
        if (_storeLoadCancelToken?.isCancelled ?? false) {
          if (kDebugMode) {
            debugPrint(
                '🚫 [StoreController] Request cancelled - discarding store details response');
          }
          return _store; // Return existing data, don't update
        }

        // 🔧 FIX 3: Store page safety - handle 500/null by exposing retry state
        if (storeDetails == null) {
          _hasStoreError = true;
          _storeErrorStatusCode = 500; // Assume 500 if null
          _isLoading = false;
          _isLoadingStoreDetails = false;
          _loadingStoreDetailsId = null;

          if (!(_storeDetailsCompleter?.isCompleted ?? true)) {
            _storeDetailsCompleter?.complete(_store);
          }
          _storeDetailsCompleter = null;

          // 🛡️ PHASE 4: Error Fallback - Keep existing data visible
          // Don't clear _store - preserve it so user sees old data instead of white screen
          if (_store != null && kDebugMode) {
            debugPrint(
                '⚠️ [StoreController] Store details request failed - preserving existing store data');
            debugPrint('   - store.isOpen from cache: ${_store!.isOpen}');
            debugPrint('   - store.active: ${_store!.active}');
          }
          // ✅ FIX: Skip update() here - error will be shown by loadAllStoreDetails final update
          return _store; // Return existing data instead of null
        } else {
          _hasStoreError = false;
          _storeErrorStatusCode = null;
        }

        // 🛠️ TASK 3: SWR Pattern - STEP 3: Update UI if data changed
        // Use versionHash if available (BFF API v2), otherwise compare key fields
        // Note: storeDetails is guaranteed non-null here (checked above)
        final hasChanged = _store == null ||
            _store?.id != storeDetails.id ||
            _store?.name != storeDetails.name ||
            (_store?.versionHash != null &&
                storeDetails.versionHash != null &&
                _store!.versionHash != storeDetails.versionHash) ||
            (_store?.versionHash == null &&
                (_store?.tax != storeDetails.tax ||
                    _store?.minimumOrder != storeDetails.minimumOrder ||
                    _store?.avgRating != storeDetails.avgRating));

        // 🔧 FIX: Always update if categoryDetails changed (even if other fields unchanged)
        final categoryDetailsChanged = _store == null ||
            (_store!.categoryDetails?.length ?? 0) !=
                (storeDetails.categoryDetails?.length ?? 0);

        if (hasChanged || _store == null || categoryDetailsChanged) {
          // 🔧 FIX: Preserve distance from cache/previous state to prevent flicker
          // Only update distance if API provides a valid one, otherwise keep existing
          final previousDistance = _store?.distance;
          final apiProvidedDistance = storeDetails.distance != null &&
              storeDetails.distance! > 0 &&
              storeDetails.distance! < 999999 &&
              storeDetails.distance! != -1;
          final shouldPreserveDistance = previousDistance != null &&
              previousDistance > 0 &&
              previousDistance != -1 &&
              !apiProvidedDistance; // Only preserve if API didn't provide valid distance

          _store = storeDetails;

          // 🔧 FIX: Preserve distance if API distance is invalid (-1 or null)
          // This prevents flicker when distance is being recalculated
          // We'll still recalculate it below, but this keeps UI stable during the transition
          if (shouldPreserveDistance) {
            _store!.distance = previousDistance;
            if (kDebugMode) {
              debugPrint(
                  '🔧 [StoreController] Preserving previous distance ${previousDistance.toStringAsFixed(2)}m to prevent flicker (will recalculate)');
            }
          }

          // 🔧 TASK 3: CRITICAL ERROR LOGGING - Check for null coordinates (backend issue)
          if (storeDetails.latitude == null || storeDetails.longitude == null) {
            if (kDebugMode) {
              debugPrint(
                  '🚨 CRITICAL [StoreController] Store ${storeDetails.id} (${storeDetails.name}) has NULL coordinates!');
              debugPrint(
                  '   ⚠️ Backend is sending null latitude/longitude - this breaks distance calculation and location features.');
              debugPrint(
                  '   📍 latitude: ${storeDetails.latitude}, longitude: ${storeDetails.longitude}');
              debugPrint(
                  '   💡 UI will gracefully hide location/distance features, but backend needs to be fixed.');
            }
          }

          // Save to cache
          if (newStoreId != null) {
            try {
              await _cacheService.saveStoreDetails(newStoreId, storeDetails);
              if (kDebugMode) {
                debugPrint(
                    '💾 [StoreController] SWR: Saved store $newStoreId to cache');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                    '⚠️ [StoreController] SWR: Error saving to cache: $e');
              }
            }
          }

          if (kDebugMode) {
            if (hasChanged) {
              debugPrint(
                  '🔄 [StoreController] SWR: Store data changed - UI updated');
            } else if (categoryDetailsChanged) {
              debugPrint(
                  '🔄 [StoreController] SWR: Category details changed - UI updated');
              debugPrint(
                  '   📋 Old categories: ${_store?.categoryDetails?.length ?? 0}');
              debugPrint(
                  '   📋 New categories: ${storeDetails.categoryDetails?.length ?? 0}');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '✅ [StoreController] SWR: Store data unchanged - no UI update needed');
            }
          }

          // 🔧 FIX: Clear categories if store ID changed
          if (_lastStoreIdForCategories != null &&
              _lastStoreIdForCategories != _store!.id) {
            if (kDebugMode) {
              debugPrint(
                  '🔄 [StoreController] Store ID changed from $_lastStoreIdForCategories to ${_store!.id} - Clearing categories');
            }
            _storeSpecificCategoryList = null;
            _allCategories = null;
            _visibleCategoryCount = 15;
          }
          _lastStoreIdForCategories = _store!.id;

          // 🔧 FIX: Initialize time slot and calculate distance (removed duplicate code)
          Get.find<CheckoutController>().initializeTimeSlot(_store!);

          // 🔧 FIX: Calculate distance for ALL cases (not just when slug is empty)
          // Distance should be shown regardless of how user navigated to store detail page
          // ⚡ V2: Prefer API-provided distance, only calculate if missing
          // ✅ FIX: Skip distance calculation if API already provided valid distance (prevents duplicate calculation)
          if (!fromCart) {
            final userAddress = AddressHelper.getUserAddressFromSharedPref();
            if (kDebugMode) {
              debugPrint('📍 [StoreController] Distance calculation check:');
              debugPrint('   - fromCart: $fromCart');
              debugPrint('   - slug: "$slug"');
              debugPrint(
                  '   - API distance: ${_store?.distance?.toStringAsFixed(2) ?? "null"} meters');
              debugPrint(
                  '   - userAddress: ${userAddress != null ? "exists" : "null"}');
              if (userAddress != null) {
                debugPrint('   - userLat: ${userAddress.latitude}');
                debugPrint('   - userLng: ${userAddress.longitude}');
              }
              debugPrint('   - storeLat: ${_store?.latitude}');
              debugPrint('   - storeLng: ${_store?.longitude}');
            }

            // ✅ FIX #5: Check if API already provided valid distance
            // Use apiProvidedDistance flag from getStoreDetails to determine if distance came from API
            // This prevents duplicate distance calculation when API already provides it
            if (apiProvidedDistance &&
                _store?.distance != null &&
                _store!.distance! > 0 &&
                _store!.distance! < 999999) {
              if (kDebugMode) {
                debugPrint(
                    '✅ [StoreController] Using API-provided distance: ${_store!.distance?.toStringAsFixed(2)} meters - skipping calculation');
              }
              // Distance is already in meters from API, no conversion needed
              // No update() needed - will be handled by loadAllStoreDetails final update
            } else if (_store?.latitude != null && _store?.longitude != null) {
              // If API distance was invalid (>= 999999) or parsing failed (-1), try to calculate
              if (_store?.distance != null) {
                if (_store!.distance! == -1) {
                  // Parsing failed - silently try to calculate from coordinates
                  if (kDebugMode) {
                    debugPrint(
                        '🔄 [StoreController] Distance parsing failed (-1), calculating from coordinates...');
                  }
                  _store!.distance =
                      null; // Clear sentinel value before calculation
                } else if (_store!.distance! >= 999999) {
                  // Parsing succeeded but coordinates invalid - this is true "Out of Coverage"
                  if (kDebugMode) {
                    debugPrint(
                        '⚠️ [StoreController] API distance indicates out of coverage (${_store!.distance}), recalculating from coordinates...');
                  }
                  _store!.distance = null; // Clear invalid distance
                }
              }
              // API didn't provide distance, calculate using coordinates
              final userLatitude =
                  userAddress?.latitude ?? '24.604301879077966';
              final userLongitude =
                  userAddress?.longitude ?? '46.59593515098095';

              try {
                if (kDebugMode) {
                  debugPrint(
                      '🔄 [StoreController] API distance not available, calculating from coordinates...');
                }
                // Calculate distance using coordinates
                final calculatedDistance =
                    await Get.find<CheckoutController>().getDistanceInKM(
                  LatLng(
                    double.parse(userLatitude),
                    double.parse(userLongitude),
                  ),
                  LatLng(double.parse(_store!.latitude!),
                      double.parse(_store!.longitude!)),
                );

                // Set distance on store object so UI can display it
                if (calculatedDistance != null && calculatedDistance > 0) {
                  final newDistance =
                      calculatedDistance * 1000; // Convert km to meters

                  // ✅ FIX: Set distance but skip update() - will be updated at end of loadAllStoreDetails
                  if (_store!.distance != newDistance) {
                    _store!.distance = newDistance;
                    if (kDebugMode) {
                      debugPrint(
                          '✅ [StoreController] Distance calculated and set: ${_store!.distance?.toStringAsFixed(2)} meters (${calculatedDistance.toStringAsFixed(2)} km) - update() deferred to loadAllStoreDetails');
                    }
                    // No update() here - will be handled by loadAllStoreDetails final update
                  } else if (kDebugMode) {
                    debugPrint(
                        '⏭️ [StoreController] Distance unchanged (${newDistance.toStringAsFixed(2)}m), skipping UI update');
                  }
                } else {
                  if (kDebugMode) {
                    debugPrint(
                        '⚠️ [StoreController] Distance calculation returned null or 0: $calculatedDistance');
                  }
                }
              } catch (e, stackTrace) {
                if (kDebugMode) {
                  debugPrint(
                      '❌ [StoreController] Error calculating distance: $e');
                  debugPrint('   Stack trace: $stackTrace');
                }
              }
            } else {
              if (kDebugMode) {
                debugPrint(
                    '⚠️ [StoreController] Cannot calculate distance - store coordinates are null');
              }
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '⏭️ [StoreController] Skipping distance calculation (fromCart=true)');
            }
          }

          if (slug.isNotEmpty &&
              _store?.latitude != null &&
              _store?.longitude != null) {
            await Get.find<LocationController>().setStoreAddressToUserAddress(
                LatLng(double.parse(_store!.latitude!),
                    double.parse(_store!.longitude!)));
          }
          if (fromModule) {
            HomeScreen.loadData(context, true);
          } else {
            Get.find<CheckoutController>().clearPrevData();
          }
        } else {
          // API returned null - check if we have cache
          if (_store == null) {
            _hasStoreError = true;
            _storeErrorStatusCode = 500;
            if (kDebugMode) {
              debugPrint(
                  '❌ [StoreController] SWR: API failed and no cache available');
            }
          } else {
            // We have cache, so error is not critical
            if (kDebugMode) {
              debugPrint(
                  '⚠️ [StoreController] SWR: API failed but using cached data');
              debugPrint('   - store.isOpen from cache: ${_store!.isOpen}');
              debugPrint('   - store.active: ${_store!.active}');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '❌ [StoreController] SWR: Exception in getStoreDetails: $e');
        }
        _hasStoreError = true;
        // ⚡ FIX: Detect timeout errors (statusCode 1) vs server errors (500)
        // Check if exception is related to timeout/network
        if (e.toString().contains('TimeoutException') ||
            e.toString().contains('timeout') ||
            e.toString().contains('SocketException')) {
          _storeErrorStatusCode = 1; // Timeout/network error
        } else {
          _storeErrorStatusCode = 500; // Server error
        }

        // 🛡️ PHASE 4: Error Fallback - Preserve existing data on exceptions
        // Don't clear _store - preserve it so user sees old data instead of white screen
        // 🔥 CRITICAL FIX: Don't trust cache open status - check cart items instead
        if (_store != null) {
          // Do not override open status from cache.

          if (kDebugMode) {
            debugPrint(
                '⚠️ [StoreController] Store details exception - preserving existing store data');
            debugPrint('   - store.isOpen from cache: ${_store!.isOpen}');
            debugPrint('   - store.active: ${_store!.active}');
          }
        }

        // Reset loading flags on error
        _isLoading = false;
        _isLoadingStoreDetails = false;
        _loadingStoreDetailsId = null;
        if (!(_storeDetailsCompleter?.isCompleted ?? true)) {
          _storeDetailsCompleter?.complete(_store);
        }
        _storeDetailsCompleter = null;
        // ✅ FIX: Skip update() here - error will be shown by loadAllStoreDetails final update
      }

      final CheckoutController checkoutController = Get.find<CheckoutController>();
      final bool supportsDelivery = _store?.delivery ?? true;
      final bool supportsTakeAway = _store?.takeAway ?? true;

      final String fallbackOrderType =
          supportsDelivery ? 'delivery' : 'take_away';
      final String? currentOrderType = checkoutController.orderType;

      final bool shouldSetInitialOrderType = currentOrderType == null;
      final bool currentSelectionInvalid =
          (currentOrderType == 'delivery' && !supportsDelivery) ||
              (currentOrderType == 'take_away' && !supportsTakeAway);

      // Preserve user's explicit checkout choice unless it's invalid for this store.
      if (shouldSetInitialOrderType || currentSelectionInvalid) {
        checkoutController.setOrderType(
          fallbackOrderType,
          notify: false,
        );
      }
      _isLoading = false;
      // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
      // No need for individual update() calls in getStoreDetails - all updates happen once at end of loadAllStoreDetails
    }

    // ⚡ TASK 2: Reset loading flags after completion
    _isLoadingStoreDetails = false;
    _loadingStoreDetailsId = null;

    if (!(_storeDetailsCompleter?.isCompleted ?? true)) {
      _storeDetailsCompleter?.complete(_store);
    }
    _storeDetailsCompleter = null;

    // 🛡️ PHASE 4: Always return existing _store (preserved on errors)
    return _store;
  }

  /// ⚡ PARALLEL BATCH LOADING: Load store details, items, banners, and recommended items in parallel
  /// This reduces load time from 1.8s to 0.4s by parallelizing independent API calls
  /// ✅ DATA-DRIVEN: Parallel batch loading for ALL modules
  /// Works universally across Food, Grocery, Pharmacy, Ecommerce, Coffee, etc.
  /// No hardcoded module checks - adapts based on store data structure
  Future<void> loadAllStoreDetails(
      BuildContext context, int? storeId, bool fromModule,
      {String slug = ''}) async {
    if (_isLoadingAllStoreDetails && _loadingAllStoreDetailsId == storeId) {
      return;
    }
    _isLoadingAllStoreDetails = true;
    _loadingAllStoreDetailsId = storeId;

    try {
      // ✅ PROFESSIONAL METHOD LOGGING: Track controller method calls
      if (kDebugMode) {
        debugPrint('📦 [StoreController] loadAllStoreDetails() CALLED');
        debugPrint('   - method: loadAllStoreDetails');
        debugPrint('   - storeId: $storeId');
        debugPrint('   - route: ${Get.currentRoute}');
        debugPrint('   - parameters: ${Get.parameters}');
        debugPrint('   - hasStoreItemModel: ${_storeItemModel != null}');
        debugPrint('   - hasVisibleItems: ${_visibleItemList != null}');
      }

      // ✅ FRONTEND ONLY: Always fetch items regardless of store.open status
      // Items should be fetched ALWAYS - store.open only affects ordering, not fetching
      if (kDebugMode) {
        debugPrint(
            '⚡ [StoreController] loadAllStoreDetails() - Starting batch load for store $storeId');
        debugPrint(
            '   📦 ALWAYS fetching items (regardless of store.open status)');
      }

      // ✅ CRITICAL FIX: Reset pagination and items state to force fresh fetch
      // This ensures items are always fetched, even if previous state was empty
      if (kDebugMode) {
        debugPrint(
            '🔄 [StoreController] Resetting pagination and items state for fresh fetch');
      }
      _storeItemModel = null; // Reset to force fresh fetch
      _visibleItemList = null; // Reset visible items
      _allStoreItems = null; // Reset all items
      _slimMenuLoaded = false; // Reset slim menu flag
      _slimMenuResponse = null; // Reset slim menu response
      _hasMoreItems = true; // Reset pagination state
      _currentItemsOffset = 1; // Reset offset
      _isLoadingItems = false; // Reset loading state

      // ✅ FIX #4: Reset update flag for new batch
      _didFinalUpdate = false;

      // ✅ FIX #4: Cancel ALL pending menu requests BEFORE creating new cancel token
      // This prevents cancelling requests that were just created
      // Must be done BEFORE creating new cancel token to avoid race condition
      cancelAllPendingRequests();

      // Create new cancel token for this store load (AFTER cancelling old ones)
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
          return Future<Store?>.value();
        }),
        // Load banners in parallel
        getStoreBannerList(storeId, cancelToken: _storeLoadCancelToken)
            .catchError((e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ [StoreController] Error loading banners in parallel batch: $e');
          }
          return Future.value();
        }),
        // Load recommended items in parallel
        getRestaurantRecommendedItemList(storeId, false,
                cancelToken: _storeLoadCancelToken)
            .catchError((e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ [StoreController] Error loading recommended items in parallel batch: $e');
          }
          return Future.value();
        }),
      ];

      // 🚀 TASK 1: SINGLE SLIM MENU CALL - Replaces all parallel getStoreItemList loops
      // ✅ FRONTEND ONLY: Always fetch items - store.open does NOT prevent fetching
      // Slim menu works for ALL modules (including ecommerce) and handles large stores automatically
      bool slimMenuSuccess = false;
      if (storeId != null) {
        if (kDebugMode) {
          debugPrint(
              '📦 [StoreController] ALWAYS fetching items for store $storeId (store.open status ignored)');
        }
        futures.add(
          getSlimMenu(storeId, cancelToken: _storeLoadCancelToken)
              .then((success) {
            slimMenuSuccess = success;
            if (kDebugMode) {
              if (success) {
                debugPrint('✅ [StoreController] Slim menu loaded successfully');
              } else {
                debugPrint(
                    '⚠️ [StoreController] Slim menu returned false - will fallback to getStoreItemList');
              }
            }
            return success;
          }).catchError((e) {
            if (kDebugMode) {
              debugPrint('⚠️ [StoreController] Error loading slim menu: $e');
              debugPrint(
                  '   🔄 Slim menu failed - will fallback to getStoreItemList');
            }
            slimMenuSuccess = false;
            return Future<bool>.value(false);
          }),
        );
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [StoreController] Store ID is null - cannot fetch items');
        }
      }

      await Future.wait(
        futures,
      );

      // ✅ FRONTEND ONLY: Fallback to getStoreItemList if slim menu failed or returned no items
      // This ensures items are ALWAYS loaded, regardless of store.open status
      // Items fetching is NEVER blocked by store.open - only ordering is blocked
      if (storeId != null &&
          (!slimMenuSuccess ||
              _storeItemModel == null ||
              _storeItemModel!.items == null ||
              _storeItemModel!.items!.isEmpty)) {
        if (kDebugMode) {
          debugPrint(
              '🔄 [StoreController] Slim menu failed or returned no items - falling back to getStoreItemList');
          debugPrint(
              '   📦 ALWAYS fetching items for store $storeId using getStoreItemList (store.open ignored)');
        }
        try {
          await getStoreItemList(
            storeId,
            1,
            'all',
            false, // Don't notify immediately - will update at end
            pageSize: 50,
          );
          if (kDebugMode) {
            final itemCount = _storeItemModel?.items?.length ?? 0;
            debugPrint(
                '✅ [StoreController] Fallback getStoreItemList loaded $itemCount items');
            if (itemCount == 0) {
              debugPrint(
                  '   ⚠️ [StoreController] WARNING: getStoreItemList returned 0 items - this might be a backend issue');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ [StoreController] Fallback getStoreItemList also failed: $e');
            debugPrint(
                '   ⚠️ [StoreController] CRITICAL: No items could be loaded - check backend API');
          }
        }
      } else if (storeId != null &&
          slimMenuSuccess &&
          _storeItemModel != null &&
          _storeItemModel!.items != null &&
          _storeItemModel!.items!.isNotEmpty) {
        if (kDebugMode) {
          final itemCount = _storeItemModel!.items!.length;
          debugPrint(
              '✅ [StoreController] Items loaded successfully via slim menu: $itemCount items');
        }
      }

      // ✅ FIX #6: Defer update() to prevent setState during build error + prevent duplicate calls
      // This ensures items, banners, and other data trigger UI refresh after build completes
      // Use multiple callbacks to ensure we're definitely past the build phase
      // Protection against duplicate update() calls in same batch
      if (!_didFinalUpdate) {
        _didFinalUpdate = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (kDebugMode) {
              debugPrint(
                  '🔄 [StoreController] Deferred update() after loadAllStoreDetails');
            }
            update();
          });
        });
      }

      if (kDebugMode) {
        debugPrint(
            '✅ [StoreController] loadAllStoreDetails() - Batch load complete (slim menu used)');
      }
    } finally {
      _isLoadingAllStoreDetails = false;
      _loadingAllStoreDetailsId = null;
    }
  }

  /// 🛠️ TASK 5: Retry method for 500 errors
  Future<void> retryStoreDetails(context, Store store, bool fromModule,
      {bool fromCart = false, String slug = ''}) async {
    _hasStoreError = false;
    _storeErrorStatusCode = null;
    await getStoreDetails(context, store, fromModule,
        fromCart: fromCart, slug: slug);
  }

  Future<void> getRecommendedStoreList(
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    if (!_canFetchStores()) {
      return;
    }
    if (!fromRecall) {
      _recommendedStoreList = null;
    }
    List<Store>? recommendedStoreList;
    if (dataSource == DataSourceEnum.local) {
      recommendedStoreList = await storeServiceInterface
          .getRecommendedStoreList(source: DataSourceEnum.local);
      _prepareRecommendedStores(recommendedStoreList);
      getRecommendedStoreList(
          dataSource: DataSourceEnum.client, fromRecall: true);
    } else {
      recommendedStoreList = await storeServiceInterface
          .getRecommendedStoreList(source: DataSourceEnum.client);
      _prepareRecommendedStores(recommendedStoreList);
    }
  }

  void _prepareRecommendedStores(List<Store>? recommendedStoreList) {
    if (recommendedStoreList != null) {
      _recommendedStoreList = [];
      _recommendedStoreList!.addAll(recommendedStoreList);
    }
    update();
  }

  void set_Price(bool value) {
    _isPriceAscending = value;

    // Re-sort the currently displayed lists immediately so tapping the button
    // reorders the visible items right away (not only on the next data load).
    int byPrice(Item a, Item b) => _isPriceAscending
        ? (a.price ?? 0).compareTo(b.price ?? 0)
        : (b.price ?? 0).compareTo(a.price ?? 0);

    _storeItemModel?.items?.sort(byPrice);
    _visibleItemList?.sort(byPrice);
    _allStoreItems?.sort(byPrice);

    update();
  }

  void setVerticalItems(bool value) {
    _isVertical = value;
    update();
  }

  /// 🚀 BULK MENU INJECTION: Fetch entire menu (categories + items) in a single API call
  /// ✅ FRONTEND ONLY: Always fetch items - store.open does NOT prevent fetching
  /// This replaces the parallel bombing pattern of 10+ requests with one efficient bulk request
  /// Returns true if successful, false otherwise
  Future<bool> getSlimMenu(int? storeId, {CancelToken? cancelToken}) async {
    // ✅ PROFESSIONAL METHOD LOGGING: Track controller method calls
    if (kDebugMode) {
      debugPrint('📦 [StoreController] getSlimMenu() CALLED');
      debugPrint('   - method: getSlimMenu');
      debugPrint('   - storeId: $storeId');
      debugPrint('   - route: ${Get.currentRoute}');
      debugPrint('   - parameters: ${Get.parameters}');
      debugPrint('   - slimMenuLoaded: $_slimMenuLoaded');
      debugPrint('   - hasStoreItemModel: ${_storeItemModel != null}');
    }

    if (storeId == null) {
      if (kDebugMode) {
        debugPrint(
            '📍 [StoreController] getSlimMenu() - Store ID is null, cannot get menu');
      }
      return false;
    }

    // ✅ FRONTEND ONLY: Always fetch items regardless of store.open
    // store.open only affects ordering, NOT fetching
    if (kDebugMode) {
      debugPrint(
          '📦 [StoreController] getSlimMenu() - ALWAYS fetching items for store $storeId');
      debugPrint(
          '   ✅ store.open status is ignored - items are always fetched');
    }

    // ✅ UPDATE: Slim menu now works for ALL modules including ecommerce
    // According to backend documentation, slim menu endpoint handles large stores
    // (10K+ items) by limiting to 2,000 items automatically
    // No need to skip ecommerce - it's supported and recommended

    _isLoadingItems = true;
    _slimMenuLoaded = false;
    _slimMenuResponse = null;
    // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
    // No need for immediate update as this is called from loadAllStoreDetails which handles final update

    try {
      if (kDebugMode) {
        debugPrint(
            '📡 [API REQUEST] getSlimMenu - calling API for store $storeId');
      }
      final slimMenuResponse = await storeServiceInterface.getSlimMenu(
        storeId,
        moduleId: _activeStoreModuleId,
        cancelToken: cancelToken,
      );

      // 🛑 PHASE 1: Check cancellation immediately after response
      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          debugPrint(
              '🚫 [StoreController] Request cancelled - discarding slim menu response');
        }
        _isLoadingItems = false;
        // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
        return false; // Don't update state
      }

      if (slimMenuResponse == null || !slimMenuResponse.success) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [StoreController] getSlimMenu() - API returned null or unsuccessful');
        }
        _isLoadingItems = false;
        _slimMenuLoaded = false;
        _slimMenuResponse = null;
        // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
        return false;
      }

      final itemCount = slimMenuResponse.totalItems;

      // 🚀 SLIM MENU: Store response for screen access
      _slimMenuResponse = slimMenuResponse;
      _slimMenuLoaded = true;

      // ⚠️ LARGE STORE DETECTION: If totalItems == 2000, this is likely a large store
      // Backend automatically limits large stores (>1K items) to 2,000 items
      // This is a partial menu, not the complete catalog
      final isLargeStore = itemCount >= 2000;

      // ⚡ PRODUCTION: Keep only critical logs for errors
      // Verbose success logs removed for 120Hz performance

      // ⚡ INJECTION: Populate categories from SlimMenuResponse
      _allCategories = [];
      // Add "All" category at index 0
      _allCategories!.add(CategoryModel(id: 0, name: 'all_products'.tr));

      // Extract categories from slim menu response
      // Each SlimMenuCategory has id, name, and items
      for (final slimCategory in slimMenuResponse.categories) {
        // Skip if invalid category
        if (slimCategory.id == 0) continue;

        // Create CategoryModel from SlimMenuCategory
        final categoryModel = CategoryModel(
          id: slimCategory.id,
          name: slimCategory.name,
          productsCount: slimCategory.items.length,
          // Note: SlimMenuCategory only has id and name - image/parentId/position
          // may not be available in slim response, but that's okay for menu display
        );

        _allCategories!.add(categoryModel);
      }

      // Set category list tracking
      _lastStoreIdForCategories = storeId;
      _visibleCategoryCount = 15; // Reset lazy loading
      // 🚀 SLIM MENU: Set specificStoreCategoryList from slim menu categories
      _specificStoreCategoryList = List.from(_allCategories!);

      // ⚡ TASK 3: Force re-sync - clear UI first to prevent "Ghost Cache Hit"
      _visibleItemList = [];
      _allStoreItems = null;
      // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update

      // ⚡ INJECTION: Flatten all items from all categories for "All" view
      // SlimMenuResponse has items nested in categories, so we need to flatten them
      final allItems = slimMenuResponse.getAllItems();

      // Convert SlimMenuItem to Item for compatibility with existing UI
      final itemList = allItems.map((slimItem) => slimItem.toItem()).toList();

      // Apply price sorting if enabled (before streaming)
      if (_isPriceAscending == true || _isPriceAscending == false) {
        itemList.sort((a, b) => _isPriceAscending
            ? (a.price ?? 0).compareTo(b.price ?? 0)
            : (b.price ?? 0).compareTo(a.price ?? 0));
      }

      // ⚡ STREAMING BUCKET: Store all items in master record
      _allStoreItems = itemList;

      // ⚡ STREAMING BUCKET: Show first 20 items instantly (<100ms perceived speed)
      const int initialVisibleCount = 20;
      _visibleItemList = itemList.length > initialVisibleCount
          ? itemList.sublist(0, initialVisibleCount)
          : List<Item>.from(itemList);

      // ⚡ STREAMING BUCKET: Create ItemModel with visible items for UI
      _storeItemModel = ItemModel(
        items: _visibleItemList,
        totalSize: itemCount,
        offset: 1,
        limit: itemCount.toString(),
      );

      // Update pagination state
      _type = 'all';
      // ⚠️ LARGE STORE: If totalItems == 2000, there might be more items in the database
      // But slim menu only returns first 2K items for large stores
      // Set hasMoreItems based on whether this is a partial menu
      _hasMoreItems = isLargeStore; // If large store, there might be more items
      _currentItemsOffset = 1;

      _isLoadingItems = false;

      // ⚡ PRODUCTION: Verbose logs removed for 120Hz performance

      // 🎯 TASK 2 FIX: Set category index WITHOUT triggering API call (items already loaded from slim menu)
      if (_allCategories != null && _allCategories!.isNotEmpty) {
        _categoryIndex =
            0; // Set index directly - don't call setCategoryIndex() which triggers getStoreItemList()
        if (kDebugMode) {
          debugPrint(
              '✅ [StoreController] Slim menu loaded: ${itemList.length} items, category index set to 0');
        }
      }

      // ⚡ STREAMING BUCKET: Start background streaming of remaining items
      if (itemList.length > initialVisibleCount) {
        Future.microtask(() => _streamRemainingItems());
      }

      // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
      // Update will happen once at end of loadAllStoreDetails to prevent multiple rebuilds
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [StoreController] getSlimMenu() - Error: $e');
        debugPrint('   📋 Stack trace: $stackTrace');
      }
      _isLoadingItems = false;
      _slimMenuLoaded = false;
      _slimMenuResponse = null;
      // ✅ FIX: Skip update() here - will be handled by loadAllStoreDetails final update
      return false;
    }
  }

  // ⚡ STREAMING BUCKET: Background thread to hydrate remaining items
  // Adds 50 items every 200ms until all items are visible
  // Uses targeted update(['item_list_section']) to prevent flickering
  void _streamRemainingItems() async {
    if (_allStoreItems == null || _visibleItemList == null) return;

    const int batchSize = 50;
    const int delayMs = 200;
    final int totalItems = _allStoreItems!.length;
    int currentIndex = _visibleItemList!.length;

    while (currentIndex < totalItems) {
      await Future<void>.delayed(const Duration(milliseconds: delayMs));

      // Check if controller is still valid (not disposed)
      if (!Get.isRegistered<StoreController>()) break;

      final int endIndex = math.min(currentIndex + batchSize, totalItems);
      final List<Item> batch = _allStoreItems!.sublist(currentIndex, endIndex);

      _visibleItemList!.addAll(batch);

      // ⚡ TARGETED UPDATE: Only update the item list section, not the entire screen
      // This prevents Categories/Banners from flickering while items stream in
      update(['item_list_section']);

      currentIndex = endIndex;
    }

    // Final update to sync ItemModel with complete list
    if (_storeItemModel != null && _visibleItemList != null) {
      _storeItemModel = ItemModel(
        items: _visibleItemList,
        totalSize: _storeItemModel!.totalSize,
        offset: _storeItemModel!.offset,
        limit: _storeItemModel!.limit,
      );
      update(['item_list_section']);
    }
  }

  Future<void> getStoreItemList(
      int? storeID, int offset, String type, bool notify,
      {bool subCategory = false,
      CancelToken? cancelToken,
      int? pageSize,
      int? categoryId}) async {
    // ⚡ TASK 3: Allow blind pre-fetching - work without _store being set
    // Use storeID parameter directly, and categoryId if provided
    if (storeID == null) {
      if (kDebugMode) {
        debugPrint(
            '📍 [StoreController] getStoreItemList() - Store ID is null, cannot get items');
      }
      _isLoadingItems = false;
      if (notify) {
        // ✅ FIX: Defer update to prevent setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          update();
        });
      }
      return;
    }

    // ✅ CRITICAL FIX: Always reset state when starting fresh (offset == 1) OR when items are empty
    // This ensures items are fetched even if previous call returned empty list
    final bool isNewLoad = offset == 1 || _storeItemModel == null;
    final bool hasEmptyItems = _storeItemModel != null &&
        (_storeItemModel!.items == null || _storeItemModel!.items!.isEmpty);

    if (isNewLoad || hasEmptyItems) {
      if (kDebugMode && hasEmptyItems) {
        debugPrint(
            '🔄 [StoreController] Detected empty items state - resetting for fresh fetch');
        debugPrint(
            '   - Previous items count: ${_storeItemModel?.items?.length ?? 0}');
      }

      _type = type;
      _storeItemModel = null; // Reset to force fresh fetch
      _visibleItemList = null; // Reset visible items
      _allStoreItems = null; // Reset all items

      // Initialize paging state for a new sequence.
      if (pageSize != null && pageSize > 0) {
        _itemsPageSize = pageSize;
      }
      _currentItemsOffset = 1;
      _hasMoreItems =
          true; // Reset pagination - always assume more items available

      if (kDebugMode) {
        debugPrint(
            '✅ [StoreController] State reset complete - will force fresh fetch from API');
      }

      if (notify) {
        // ✅ FIX: Defer update to prevent setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          update();
        });
      }
    }

    ItemModel? storeItemModel;
    // Resolve effective page size (fallback to existing state to avoid changing other flows).
    // 🔧 FIX: Change limit=0 to 100 to prevent 403 error from backend
    int resolvedPageSize = pageSize ?? _itemsPageSize;
    if (resolvedPageSize <= 0) {
      resolvedPageSize =
          100; // Default to 100 instead of 0 to prevent 403 error
      if (kDebugMode) {
        debugPrint(
            '   ⚠️ [StoreController] Page size was 0 or negative, changed to 100 to prevent 403 error');
      }
    }
    final int effectivePageSize = resolvedPageSize;

    // 🔍 DEBUG: Log API request parameters
    // ✅ FRONTEND ONLY: This API call happens ALWAYS, regardless of store.open
    if (kDebugMode) {
      debugPrint('📡 [API REQUEST] getStoreItemList called');
      debugPrint('   🏪 Store ID: $storeID');
      debugPrint('   📄 Offset: $offset');
      debugPrint('   🏷️ Type: $type');
      debugPrint('   🔄 SubCategory mode: $subCategory');
      debugPrint('   ✅ ALWAYS fetching (store.open ignored)');

      if (subCategory) {
        debugPrint('   📂 Subcategory index: $_subCategoryIndex');
        if (_subCategoryList != null &&
            _subCategoryIndex < _subCategoryList!.length) {
          debugPrint(
              '   📂 Subcategory ID: ${_subCategoryList![_subCategoryIndex].id}');
          debugPrint(
              '   📂 Subcategory name: ${_subCategoryList![_subCategoryIndex].name}');
        }
      } else {
        debugPrint('   📂 Category index: $_categoryIndex');
        if (_storeSpecificCategoryList != null &&
            _categoryIndex < _storeSpecificCategoryList!.length) {
          debugPrint(
              '   📂 Category ID: ${_storeSpecificCategoryList![_categoryIndex].id}');
          debugPrint(
              '   📂 Category name: ${_storeSpecificCategoryList![_categoryIndex].name}');
        }
      }
    }

    // 🔧 FIX: Check if request was cancelled before making API call
    if (cancelToken != null && cancelToken.isCancelled) {
      if (kDebugMode) {
        debugPrint('   🛑 Request cancelled before API call');
      }
      return;
    }

    // ⚡ TASK 3: SWR Pattern Implementation
    // STEP 1: Load from cache immediately and show cached data
    // STEP 2: Fetch fresh data from API in background
    // STEP 3: Silently update UI only if data has changed

    // Build cache key (same as repository)
    final int? moduleId =
        _activeStoreModuleId ?? Get.find<SplashController>().module?.id;
    if (moduleId == null) {
      if (kDebugMode) {
        debugPrint('⚠️ [StoreController] Cannot load items - module not set');
      }
      _isLoadingItems = false;
      if (notify) {
        // Defer update to prevent setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          update();
        });
      }
      return;
    }

    final int requestedLimit = effectivePageSize;
    final int effectiveLimit =
        requestedLimit == 0 ? 0 : requestedLimit.clamp(1, 50);

    // Determine effective category ID
    // 🔧 FIX: Handle null or "null" string categoryId - default to 0 or remove parameter
    int? effectiveCategoryId = categoryId;

    // Fix null categoryId bug - if null or "null" string, treat as 0 (all items)
    if (effectiveCategoryId == null) {
      if (subCategory &&
          _subCategoryIndex != 0 &&
          _subCategoryList != null &&
          _subCategoryIndex < _subCategoryList!.length &&
          _subCategoryList![_subCategoryIndex].id != -1) {
        effectiveCategoryId = _subCategoryList![_subCategoryIndex].id;
      } else if (!subCategory &&
          _storeSpecificCategoryList != null &&
          _categoryIndex < _storeSpecificCategoryList!.length &&
          _storeSpecificCategoryList![_categoryIndex].id != -1) {
        effectiveCategoryId = _storeSpecificCategoryList![_categoryIndex].id;
      } else {
        // Default to 0 (all items) if no valid category found
        effectiveCategoryId = 0;
      }
    }

    // Additional check: if categoryId was explicitly passed as null or invalid, use 0
    if (effectiveCategoryId != null && effectiveCategoryId < 0) {
      effectiveCategoryId = 0;
    }

    final String cacheKey =
        'store_items_v3_${storeID}_${effectiveCategoryId}_${offset}_${effectiveLimit}_${type}_$moduleId';

    // STEP 1: Load from cache immediately
    ItemModel? cachedModel;
    try {
      final String? cacheResponseData = await LocalClient.organize(
          DataSourceEnum.local, cacheKey, null, null);
      if (cacheResponseData != null) {
        cachedModel = ItemModel.fromJson(
            jsonDecode(cacheResponseData) as Map<String, dynamic>);
        final cachedItemCount = cachedModel.items?.length ?? 0;
        final cachedTotalSize = cachedModel.totalSize ?? 0;

        // Validate cache (same logic as repository)
        bool shouldUseCache = true;
        if (cachedItemCount == 0 && offset == 1) {
          shouldUseCache = false;
        } else if (cachedTotalSize > 0 && cachedItemCount < cachedTotalSize) {
          shouldUseCache = false;
        } else if (effectiveLimit == 0 && cachedItemCount < cachedTotalSize) {
          shouldUseCache = false;
        }

        if (shouldUseCache) {
          if (kDebugMode) {
            debugPrint(
                '⚡ [SWR] Cache HIT - showing cached data immediately: $cachedItemCount items');
          }

          // Show cached data immediately
          _pageSize = subCategory ? _pageSize : cachedModel.totalSize ?? 0;
          final List<Item>? cachedItems = cachedModel.items?.toList();

          if (offset == 1) {
            _storeItemModel = ItemModel(
              items: cachedItems,
              totalSize: cachedModel.totalSize,
              offset: cachedModel.offset,
            );
          } else {
            _storeItemModel ??=
                ItemModel(items: [], totalSize: 0, offset: offset);
            _storeItemModel!.items ??= [];
            _storeItemModel!.items!.addAll(cachedItems ?? []);
            _storeItemModel!.totalSize = cachedModel.totalSize;
            _storeItemModel!.offset = cachedModel.offset;
          }

          final int fetchedCount = cachedItems?.length ?? 0;
          if (fetchedCount < effectivePageSize) {
            _hasMoreItems = false;
          } else {
            _currentItemsOffset = offset;
            _hasMoreItems = true;
          }

          if (_isPriceAscending == true || _isPriceAscending == false) {
            _storeItemModel!.items!.sort((a, b) => _isPriceAscending
                ? (a.price ?? 0).compareTo(b.price ?? 0)
                : (b.price ?? 0).compareTo(a.price ?? 0));
          }

          _isLoadingItems = false;
          if (notify) {
            // Defer update to prevent setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              update();
            });
          }
        } else {
          cachedModel = null; // Cache invalid, will fetch from API
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SWR] Cache read error: $e');
      }
      cachedModel = null;
    }

    // STEP 2: Fetch fresh data from API in background (always, even if cache exists)
    _isLoadingItems = cachedModel == null; // Only show loading if no cache
    if (notify && cachedModel == null) {
      // ✅ FIX: Defer update to prevent setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        update();
      });
    }

    try {
      if (subCategory && _subCategoryIndex != 0) {
        if (_subCategoryList != null &&
            _subCategoryList![_subCategoryIndex].id != -1) {
          if (kDebugMode) {
            debugPrint(
                '   🌐 [SWR] Fetching fresh data with subcategory ID: ${_subCategoryList![_subCategoryIndex].id}');
          }
          storeItemModel = await storeServiceInterface.getStoreItemList(
            storeID,
            offset,
            _subCategoryList![_subCategoryIndex].id!,
            type,
            moduleId: moduleId,
            limit: effectivePageSize,
            cancelToken: cancelToken,
          );
        } else {
          if (kDebugMode) {
            debugPrint('   ⚠️ Subcategory list null or category ID is -1');
          }
        }
      } else {
        // 🔧 FIX: Use 0 instead of null for "all items" to prevent 403 errors
        // effectiveCategoryId is guaranteed to be >= 0 after our fix above
        if (effectiveCategoryId != null &&
            effectiveCategoryId != -1 &&
            effectiveCategoryId > 0) {
          if (kDebugMode) {
            debugPrint(
                '   🌐 [SWR] Fetching fresh data with category ID: $effectiveCategoryId ${categoryId != null ? "(blind pre-fetch)" : "(from category list)"}');
          }
          storeItemModel = await storeServiceInterface.getStoreItemList(
            storeID,
            offset,
            effectiveCategoryId,
            type,
            moduleId: moduleId,
            limit: effectivePageSize,
            cancelToken: cancelToken,
          );
        } else {
          // Use 0 for "all items" instead of null to prevent 403 errors
          if (kDebugMode) {
            debugPrint(
                '   ⚠️ Category ID is null, -1, or 0 - calling API with category ID 0 (all items)');
          }
          storeItemModel = await storeServiceInterface.getStoreItemList(
            storeID,
            offset,
            0, // Use 0 instead of null to prevent 403 errors
            type,
            moduleId: moduleId,
            limit: effectivePageSize,
            cancelToken: cancelToken,
          );
        }
      }

      // 🔧 FIX: Check if request was cancelled after API call
      if (cancelToken != null && cancelToken.isCancelled) {
        if (kDebugMode) {
          debugPrint('   🛑 Request cancelled after API call, ignoring result');
        }
        _isLoadingItems = false;
        return;
      }

      // STEP 3: Only update UI if fresh data is different from cached data
      if (storeItemModel != null) {
        // Check if data has changed (compare item IDs and counts)
        bool dataChanged = true;
        if (cachedModel != null) {
          final cachedItemIds =
              cachedModel.items?.map((e) => e.id).toSet() ?? <int>{};
          final freshItemIds =
              storeItemModel.items?.map((e) => e.id).toSet() ?? <int>{};
          final cachedCount = cachedModel.items?.length ?? 0;
          final freshCount = storeItemModel.items?.length ?? 0;

          dataChanged = cachedItemIds != freshItemIds ||
              cachedCount != freshCount ||
              cachedModel.totalSize != storeItemModel.totalSize;

          if (kDebugMode) {
            if (!dataChanged) {
              debugPrint(
                  '⚡ [SWR] Fresh data matches cache - skipping UI update');
            } else {
              debugPrint('⚡ [SWR] Fresh data differs from cache - updating UI');
              debugPrint(
                  '   📊 Cached: $cachedCount items, Fresh: $freshCount items');
            }
          }
        }

        // Only update if data changed or if we didn't have cache
        if (dataChanged || cachedModel == null) {
          _pageSize = subCategory ? _pageSize : storeItemModel.totalSize!;

          // aziz: Backend now guarantees items are filtered by store_id and stock for non-food modules.
          // We keep only lightweight validation/logging here to avoid double filtering on large pages.
          final List<Item>? newItems = storeItemModel.items?.toList();
          if (newItems != null && newItems.isNotEmpty && kDebugMode) {
            int wrongStoreCount = 0;
            for (final Item item in newItems) {
              if (item.storeId != null && item.storeId != storeID) {
                wrongStoreCount++;
                debugPrint(
                    '⚠️ DATA INTEGRITY WARNING: API returned item ${item.id} "${item.name}" '
                    'with store_id=${item.storeId}, expected $storeID.');
              }
            }
            if (wrongStoreCount > 0) {
              debugPrint(
                  '⚠️ DATA INTEGRITY SUMMARY: $wrongStoreCount item(s) had mismatched store_id for storeId=$storeID');
            }
          }

          if (offset == 1) {
            // First page: start fresh with pre-filtered items
            _storeItemModel = ItemModel(
              items: newItems,
              totalSize: storeItemModel.totalSize,
              offset: storeItemModel.offset,
            );
          } else {
            // Subsequent pages: add pre-filtered items directly
            _storeItemModel ??=
                ItemModel(items: [], totalSize: 0, offset: offset);
            _storeItemModel!.items ??= [];
            _storeItemModel!.items!.addAll(newItems ?? []);
            _storeItemModel!.totalSize = storeItemModel.totalSize;
            _storeItemModel!.offset = storeItemModel.offset;
          }

          // Update paging state: if we received less than a full page, there are no more items.
          final int fetchedCount = newItems?.length ?? 0;
          if (fetchedCount < effectivePageSize) {
            _hasMoreItems = false;
          } else {
            _currentItemsOffset = offset;
            _hasMoreItems = true;
          }

          // Optimize: Only sort if price sorting is enabled, avoid double filtering
          if (_isPriceAscending == true || _isPriceAscending == false) {
            _storeItemModel!.items!.sort((a, b) => _isPriceAscending
                ? (a.price ?? 0).compareTo(b.price ?? 0)
                : (b.price ?? 0).compareTo(a.price ?? 0));
          }

          if (notify) {
            // Defer update to prevent setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              update();
            });
          }
        }
      } else {
        // 🔧 ERROR HANDLING: Set empty ItemModel to prevent infinite loading (only if no cache)
        if (cachedModel == null) {
          if (kDebugMode) {
            debugPrint(
                '   🔧 Setting empty ItemModel to prevent infinite loading');
          }
          _storeItemModel = ItemModel(
            items: [],
            totalSize: 0,
            offset: offset,
          );
          if (notify) {
            // ✅ FIX: Defer update to prevent setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              update();
            });
          }
        }
      }
    } catch (e, stackTrace) {
      // 🔧 FIX: Check if error is due to cancellation
      if (cancelToken != null && cancelToken.isCancelled) {
        if (kDebugMode) {
          debugPrint('   🛑 Request was cancelled, ignoring error');
        }
        _isLoadingItems = false;
        return;
      }

      // 🔧 ERROR HANDLING: Catch any exceptions and set empty model
      if (kDebugMode) {
        debugPrint('   ❌ ERROR in getStoreItemList: $e');
        debugPrint('   📋 Stack trace: $stackTrace');
      }
      _storeItemModel = ItemModel(
        items: [],
        totalSize: 0,
        offset: offset,
      );
    } finally {
      // 🔧 FIX: Clear loading state
      _isLoadingItems = false;
    }

    // Defer update to prevent setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  /// Load next page of items for the current store/category/subcategory.
  /// Uses the existing paging state to request the next offset with the same page size.
  Future<void> loadMoreItems() async {
    if (_store == null) {
      return;
    }
    if (_isLoadingItems || !_hasMoreItems) {
      return;
    }

    final int nextOffset = _currentItemsOffset + 1;
    if (kDebugMode) {
      debugPrint('▶️ [PAGINATION] loadMoreItems called');
      debugPrint('   🏪 Store ID: ${_store!.id}');
      debugPrint('   📄 Current offset: $_currentItemsOffset');
      debugPrint('   📄 Next offset: $nextOffset');
      debugPrint('   🔢 Page size: $_itemsPageSize');
    }

    // For pagination we keep the same category/subcategory context and type.
    if (_subCategoryList != null && _subCategoryIndex != 0) {
      await getStoreItemList(
        _store!.id,
        nextOffset,
        _type,
        false,
        subCategory: true,
        pageSize: _itemsPageSize,
      );
    } else {
      await getStoreItemList(
        _store!.id,
        nextOffset,
        _type,
        false,
        pageSize: _itemsPageSize,
      );
    }
  }

  /// Lightweight fetch used by store detail pagination per category.
  /// Keeps pagination state in screen-level maps and avoids mutating
  /// controller-wide item lists.
  Future<ItemModel?> fetchCategoryItemsPage({
    required int storeId,
    required int categoryId,
    required int offset,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    return storeServiceInterface.getStoreItemList(
      storeId,
      offset,
      categoryId,
      'all',
      moduleId: _activeStoreModuleId,
      limit: limit,
      cancelToken: cancelToken,
    );
  }

  // Search  ======================================================================================================================

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
    final searchFiltermodel = SearchFilterModel(
      research_Name: research_Name,
      product_arrangement: product_arrangement,
      id_category: id_category,
      id_stores: id_stores,
      discount: discount ? '1' : '0',
      min: min,
      max: max,
    );

    _storeSearchFilterName = research_Name.trim() == ' ' ? '' : research_Name;
    _storeSearchFilterSort = product_arrangement;
    _storeSearchFilterCategoryId = id_category;
    _storeSearchFilterDiscount = discount;
    _storeSearchFilterMin = min;
    _storeSearchFilterMax = max;

    update();
    getStoreSearch(searchFiltermodel);
  }

  //   ===============================
  Future<void> getStoreSearch(SearchFilterModel searchFiltermodel) async {
    _isSearching = true;
    _hasStoreSearchError = false;
    _storeSearchItemModel = null;
    update();

    if (kDebugMode) {
      debugPrint('[SearchPerf][QUERY_START] storeFilter');
    }

    try {
      // 🟡 استدعاء API
      final Response response =
          await storeServiceInterface.get_new_search_filtera(
        search_filterModel: searchFiltermodel,
      );

      if (kDebugMode) {
        debugPrint('[SearchPerf][API_DONE] storeFilter status=${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final storeSearchItemModel =
            ItemModel.fromJson(response.body as Map<String, dynamic>);

        // ✅ ترتيب العناصر قبل الحفظ (قائمة صغيرة، فرز رخيص بلا طباعة لكل عنصر)
        final List<Item>? items = storeSearchItemModel.items;
        if (items != null) {
          items.sort((a, b) {
            final double priceA = a.price ?? 0;
            final double priceB = b.price ?? 0;
            return _isPriceAscending
                ? priceA.compareTo(priceB)
                : priceB.compareTo(priceA);
          });
        }

        // 🟢 حفظ النموذج بعد الترتيب
        _storeSearchItemModel = ItemModel(items: items);
        if (kDebugMode) {
          debugPrint('[SearchPerf][PARSE_DONE] storeFilter count=${items?.length ?? 0}');
        }
      } else {
        _hasStoreSearchError = true;
      }
    } catch (e) {
      _hasStoreSearchError = true;
      if (kDebugMode) {
        debugPrint('❌ StoreController.getStoreSearch: $e');
      }
    }

    _isSearching = false;
    if (kDebugMode) {
      debugPrint('[SearchPerf][UI_UPDATE] storeFilter error=$_hasStoreSearchError');
    }
    update();
  }

  // ======================================================================================================================

  Future<void> getStoreSearchItemList(
      String searchText, String? storeID, int offset, String type) async {
    if (searchText.isEmpty) {
      showCustomSnackBar('write_item_name'.tr);
    } else {
      _hasStoreSearchError = false;
      _isSearching = true;
      _searchText = searchText;
      _type = type;
      if (offset == 1 || _storeSearchItemModel == null) {
        _searchType = type;
        _storeSearchItemModel = null;
        update();
      }
      ItemModel? storeSearchItemModel;
      try {
        storeSearchItemModel = await storeServiceInterface.getStoreSearchItemList(
            searchText,
            storeID,
            offset,
            type,
            (_store != null &&
                    _store!.categoryIds!.isNotEmpty &&
                    _categoryIndex != 0)
                ? _storeSpecificCategoryList![_categoryIndex].id
                : 0);
      } catch (e) {
        _hasStoreSearchError = true;
        _isSearching = false;
        if (kDebugMode) {
          debugPrint('❌ StoreController.getStoreSearchItemList: $e');
        }
        update();
        return;
      }

      if (storeSearchItemModel != null) {
        if (offset == 1) {
          _storeSearchItemModel = storeSearchItemModel;
        } else {
          _storeSearchItemModel!.items!.addAll(storeSearchItemModel.items!);
          _storeSearchItemModel!.totalSize = storeSearchItemModel.totalSize;
          _storeSearchItemModel!.offset = storeSearchItemModel.offset;
          //_pageSize = storeSearchItemModel.totalSize!;
        }
      }
      _isSearching = false;
      update();
    }
  }

  void changeSearchStatus({bool isUpdate = true}) {
    _isSearching = !_isSearching;
    if (isUpdate) {
      update();
    }
  }

  void initSearchData() {
    _storeSearchItemModel = ItemModel(items: []);
    _hasStoreSearchError = false;
    _searchText = '';
    resetStoreSearchFilterState(notify: false);
  }

  void resetStoreSearchFilterState({bool notify = true}) {
    _storeSearchFilterName = '';
    _storeSearchFilterSort = 'popular';
    _storeSearchFilterCategoryId = '';
    _storeSearchFilterDiscount = false;
    _storeSearchFilterMin = '';
    _storeSearchFilterMax = '';
    if (notify) {
      update();
    }
  }

  // Live search functionality
  void performLiveSearch(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    _hasStoreSearchError = false;

    // Set new timer
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      _searchText = query.trim();

      if (query.isEmpty) {
        // Clear search results
        _liveSearchResults = null;
        _isLiveSearching = false;
        _isSearching = false;
        debugPrint('🔍 Store live search cleared');
      } else {
        // Perform API search instead of local filtering
        _performApiSearch(query);
      }

      update();
    });
  }

  // Perform API search for live search
  Future<void> _performApiSearch(String query) async {
    try {
      _hasStoreSearchError = false;
      _isLiveSearching = true;
      _isSearching = true;
      update();

      debugPrint('🔍 Performing API search for: "$query"');

      // Get current store ID
      final String? storeId = _store?.id?.toString();
      if (storeId == null) {
        debugPrint('⚠️ No store ID available for search');
        _liveSearchResults = [];
        _isLiveSearching = false;
        _isSearching = false;
        update();
        return;
      }

      // Call API search
      final ItemModel? searchResult =
          await storeServiceInterface.getStoreSearchItemList(
        query,
        storeId,
        1, // offset
        'all', // type
        (_store != null &&
                _store!.categoryIds!.isNotEmpty &&
                _categoryIndex != 0)
            ? _storeSpecificCategoryList![_categoryIndex].id
            : 0, // categoryID
      );

      if (searchResult != null && searchResult.items != null) {
        _liveSearchResults = searchResult.items!;
        debugPrint(
            '🔍 API search completed: ${_liveSearchResults!.length} results for "$query"');
      } else {
        _liveSearchResults = [];
        debugPrint('🔍 API search returned no results for "$query"');
      }
    } catch (e) {
      debugPrint('❌ API search failed: $e');
      _hasStoreSearchError = true;
      _liveSearchResults = [];
    } finally {
      _isLiveSearching = false;
      _isSearching = false;
      update();
    }
  }

  // Toggle search field visibility
  void toggleSearchField() {
    _isSearchFieldVisible = !_isSearchFieldVisible;
    if (!_isSearchFieldVisible) {
      // Clear search when hiding field
      clearLiveSearch();
    }
    debugPrint('🔍 Search field visibility: $_isSearchFieldVisible');
    update();
  }

  // Clear live search
  void clearLiveSearch() {
    _searchDebounceTimer?.cancel();
    _hasStoreSearchError = false;
    _liveSearchResults = null;
    _isLiveSearching = false;
    _isSearching = false;
    _searchText = '';
    debugPrint('🔍 Store live search cleared');
    update();
  }

  /// Clear all store lists when switching modules
  /// This prevents showing data from the previous module
  void clearAllModuleData() {
    if (kDebugMode) {
      debugPrint('🧹 StoreController: Clearing all store lists for module switch');
    }
    _popularStoreList = null;
    _latestStoreList = null;
    _topOfferStoreList = null;
    _featuredStoreList = null;
    _visitAgainStoreList = null;
    // ⚡ HARD-ISOLATION: Clear both storeModel and allStoreModel
    _storeModel = null;
    _allStoreModel = null;
    _store = null;
    _storeItemModel = null;
    _storeSearchItemModel = null;
    _storeSpecificCategoryList = null;
    _allCategories = null;
    _visibleCategoryCount = 15;
    _isLoadingMoreCategories = false;
    _lastStoreIdForCategories = null; // 🔧 FIX: Clear store ID tracking
    _subCategoryList = null;
    _categoryIndex = 0;
    _subCategoryIndex = 0;
    _filterType = 'all';
    _storeType = 'all';
    _type = 'all';
    if (kDebugMode) {
      debugPrint('✅ StoreController: All store data cleared');
    }
    update();
  }

  /// ⚡ TITAN BOARD: Reset controller to default state without deleting instance
  /// Used during module switching to preserve controller in memory
  Future<void> resetToDefault() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 StoreController: Resetting to default state');
      }

      // Clear all lists
      _storeModel = null;
      _allStoreModel = null;
      _popularStoreList = null;
      _latestStoreList = null;
      _topOfferStoreList = null;
      _featuredStoreList = null;
      _visitAgainStoreList = null;

      // Clear category-related data
      _allCategories = null;
      _specificStoreCategoryList = null;
      _storeSpecificCategoryList = null;
      _visibleCategoryCount = 15;
      _lastStoreIdForCategories = null;
      _subCategoryList = null;

      // Reset state flags
      _isLoading = false;
      _isFetchingStores = false;
      _isLoadingItems = false;

      // Reset pagination
      _pageSize = 0;
      _itemsPageSize = 10;
      _currentItemsOffset = 1;

      // Clear current store
      _store = null;
      _storeItemModel = null;
      _storeSearchItemModel = null;

      // Reset indices and filters
      _categoryIndex = 0;
      _subCategoryIndex = 0;
      _filterType = 'all';
      _storeType = 'all';
      _type = 'all';

      if (kDebugMode) {
        debugPrint('✅ StoreController: Reset to default state completed');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ StoreController.resetToDefault: Error - $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  void setCategoryIndex(int index, {bool itemSearching = false}) {
    // 🔧 FIX: Cancel previous debounce timer
    _categoryDebounceTimer?.cancel();
    _categoryDebounceTimer = null;

    // 🔧 FIX: Cancel previous API request (guarded by debug flag)
    if (!AppConstants.debugDisableItemsCancelToken) {
      if (_itemsRequestCancelToken != null &&
          !_itemsRequestCancelToken!.isCancelled) {
        if (kDebugMode) {
          final int? currentStoreId = _store?.id;
          final int? currentCategoryId = (_storeSpecificCategoryList != null &&
                  _categoryIndex < _storeSpecificCategoryList!.length)
              ? _storeSpecificCategoryList![_categoryIndex].id
              : null;
          debugPrint(
              '🛑 [CATEGORY SWITCH] Cancelling previous items request (storeId=$currentStoreId, categoryId=$currentCategoryId, index=$_categoryIndex, itemSearching=$itemSearching)');
        }
        _itemsRequestCancelToken!.cancel();
        _itemsRequestCancelToken = null;
      }
    } else if (kDebugMode) {
      debugPrint(
          '🧪 [CATEGORY SWITCH] debugDisableItemsCancelToken=true → skipping CancelToken cancellation for items/latest');
    }

    _categoryIndex = index;

    // 🔍 DEBUG: Log category selection
    if (kDebugMode) {
      debugPrint('🔘 [CATEGORY CLICK] setCategoryIndex called');
      debugPrint('   📌 Selected category index: $index');
      // 🎯 TASK 2 FIX: Check both _allCategories (slim menu) and _storeSpecificCategoryList (legacy)
      final categoryListToCheck = _allCategories ?? _storeSpecificCategoryList;
      if (categoryListToCheck != null && index < categoryListToCheck.length) {
        final selectedCategory = categoryListToCheck[index];
        debugPrint('   📌 Selected category ID: ${selectedCategory.id}');
        debugPrint('   📌 Selected category name: ${selectedCategory.name}');
      } else {
        debugPrint('   ⚠️ Invalid index or category list is null');
        debugPrint('   🔍 _allCategories: ${_allCategories?.length ?? "null"}');
        debugPrint(
            '   🔍 _storeSpecificCategoryList: ${_storeSpecificCategoryList?.length ?? "null"}');
      }
      debugPrint('   🏪 Store ID: ${_store?.id}');
      debugPrint('   🔍 Item searching mode: $itemSearching');
    }

    // 🔧 FIX: Debounce category switching (300ms delay)
    _categoryDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (itemSearching) {
        _storeSearchItemModel = null;
        getStoreSearchItemList(_searchText, _store!.id.toString(), 1, type);
      } else {
        _storeItemModel = null;
        if (AppConstants.debugDisableItemsCancelToken) {
          if (kDebugMode) {
            debugPrint(
                '🧪 [CATEGORY SWITCH] debugDisableItemsCancelToken=true → loading items without CancelToken');
          }
          getStoreItemList(
              _store!.id, 1, Get.find<StoreController>().type, false);
        } else {
          // Create new cancel token for this request
          _itemsRequestCancelToken = CancelToken();
          if (kDebugMode) {
            // 🎯 TASK 2 FIX: Use _allCategories (slim menu) or fallback to _storeSpecificCategoryList
            final categoryListToUse =
                _allCategories ?? _storeSpecificCategoryList;
            final int? newCategoryId = (categoryListToUse != null &&
                    _categoryIndex < categoryListToUse.length)
                ? categoryListToUse[_categoryIndex].id
                : null;
            debugPrint(
                '▶️ [CATEGORY SWITCH] Starting new items request (storeId=${_store?.id}, categoryId=$newCategoryId, index=$_categoryIndex) with CancelToken');
          }
          getStoreItemList(
              _store!.id, 1, Get.find<StoreController>().type, false,
              cancelToken: _itemsRequestCancelToken);
        }
        // 🎯 TASK 2 FIX: Use _allCategories (slim menu) or fallback to _storeSpecificCategoryList
        final categoryListToUse = _allCategories ?? _storeSpecificCategoryList;
        if (categoryListToUse != null &&
            _categoryIndex < categoryListToUse.length &&
            categoryListToUse[_categoryIndex].id != -1) {
          getSubCategoryList(categoryListToUse[_categoryIndex].id.toString());
        }
      }
      update();
    });

    // Update UI immediately to show selected category
    update();
  }

  /// ❌ DEPRECATED: This method calculates time on frontend (WRONG!)
  /// ✅ Use isOpenNow(Store? store) instead - it uses store.isOpen from API
  /// Backend is the single source of truth for store open/close status
  @Deprecated(
      'Use isOpenNow(Store? store) instead - backend decides open/close status')
  bool isStoreClosed(bool today, bool active, List<Schedules>? schedules) {
    // ⚠️ DEPRECATED: This method should not be used
    // Backend already calculated isOpen based on schedules/time
    // Flutter should only use store.isOpen from API
    debugPrint(
        '⚠️ DEPRECATED: isStoreClosed() called - use isOpenNow(store) instead');
    // Fallback: If no store object available, return false (don't block)
    return false;
  }

  /// ❌ DEPRECATED: This method calculates time on frontend (WRONG!)
  /// ✅ Use isOpenNow(Store? store) instead - it uses store.isOpen from API
  /// Backend is the single source of truth for store open/close status
  @Deprecated(
      'Use isOpenNow(Store? store) instead - backend decides open/close status')
  bool isStoreOpenNow(bool active, List<Schedules>? schedules) {
    // ⚠️ DEPRECATED: This method should not be used
    // Backend already calculated isOpen based on schedules/time
    // Flutter should only use store.isOpen from API
    debugPrint(
        '⚠️ DEPRECATED: isStoreOpenNow() called - use isOpenNow(store) instead');
    // Fallback: If no store object available, return true (don't block)
    return true;
  }

  /// ✅ FRONTEND ONLY: Get store open status from API only
  /// ❌ NO DateTime calculations, NO schedule checks, NO time logic
  /// Flutter is just a UI - backend decides open/close status
  bool isOpenNow(Store? store) {
    if (store == null) {
      return false;
    }
    return store.isOpen == true;
  }

  /// 🔥 SMART: Check if store is available (open OR has items in cart)
  /// This is the definitive check - if user has items in cart, store is available
  bool isStoreAvailable(Store? store) {
    return isOpenNow(store);
  }

  double? getDiscount(Store store) =>
      store.discount != null ? store.discount!.discount : 0;

  String? getDiscountType(Store store) =>
      store.discount != null ? store.discount!.discountType : 'percent';

  void shareStore() {
    if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
      final String shareUrl =
          '${AppConstants.webHostedUrl}${filteringUrl(store!.slug ?? '')}';

      Clipboard.setData(ClipboardData(text: shareUrl));
      showCustomSnackBar('store_url_copied'.tr, isError: false);
    } else {
      final String shareUrl =
          '${AppConstants.webHostedUrl}${filteringUrl(store!.slug ?? '')}';
      Share.share(shareUrl);
    }
  }

  /// Set popular stores from bootstrap endpoint
  void setPopularStoresFromBootstrap(StoreModel storeModel) {
    _popularStoreList = storeModel.stores;
    update();
    if (kDebugMode) {
      debugPrint(
          '✅ StoreController: Popular stores set from bootstrap (${storeModel.stores?.length ?? 0} stores)');
    }
  }

  /// Set store data from bootstrap endpoint
  void setStoreDataFromBootstrap(StoreModel storeModel) {
    _storeModel = storeModel;
    update();
    if (kDebugMode) {
      debugPrint(
          '✅ StoreController: Store data set from bootstrap (${storeModel.stores?.length ?? 0} stores)');
    }
  }

  /// Set latest stores from bootstrap endpoint
  void setLatestStoresFromBootstrap(StoreModel storeModel) {
    _latestStoreList = storeModel.stores;
    update();
    if (kDebugMode) {
      debugPrint(
          '✅ StoreController: Latest stores set from bootstrap (${storeModel.stores?.length ?? 0} stores)');
    }
  }

  /// 🔒 HARD RESET: Clear all store detail state to prevent state leakage
  /// Call this when exiting store detail screens to ensure clean slate
  void clearStoreDetailState() {
    if (kDebugMode) {
      debugPrint(
          '🧹 [StoreController] clearStoreDetailState() - Clearing store detail state');
    }

    // 🔒 TASK 3: Clear store-specific category list (prevents poisoning global categories)
    _specificStoreCategoryList = null;
    _allCategories = null;
    _lastStoreIdForCategories = null;

    // ✅ CRITICAL: Clear current store reference so home uses HOME categories
    _store = null;

    // Keep CategoryController data intact; categories should refresh on page entry

    // Clear store items
    _storeItemModel = null;

    // ⚡ STREAMING BUCKET: Clear streaming state
    _allStoreItems = null;
    _visibleItemList = null;

    // 🚀 SLIM MENU: Clear slim menu state
    _slimMenuLoaded = false;
    _slimMenuResponse = null;

    // Reset item pagination state
    _currentItemsOffset = 1;
    _hasMoreItems = true;
    _isLoadingItems = false;

    // Cancel any pending item requests
    _itemsRequestCancelToken?.cancel();
    _itemsRequestCancelToken = null;

    // 🔧 TASK 1: Cancel any pending store load requests
    _storeLoadCancelToken?.cancel();
    _storeLoadCancelToken = null;

    if (kDebugMode) {
      debugPrint(
          '   ✅ Store detail state cleared - ready for next store visit');
    }

    // 🔒 TASK 3: DELAY STATE CLEAR - Fix 'Locked Framework' exception
    // Wait for Flutter to finish destroying the store screen before updating
    // This prevents the 'Locked Framework' exception when dispose triggers updates
    SchedulerBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  /// 🛑 TASK 1: HARD-QUARANTINE - Cancel all pending menu requests
  /// Called when user clicks 'Back' or 'Change Store' to prevent zombie data
  void cancelAllPendingRequests() {
    if (kDebugMode) {
      debugPrint(
          '🛑 [StoreController] cancelAllPendingRequests() - Cancelling all pending menu requests');
    }

    // Cancel items request token
    if (_itemsRequestCancelToken != null &&
        !_itemsRequestCancelToken!.isCancelled) {
      _itemsRequestCancelToken!.cancel();
      _itemsRequestCancelToken = null;
      if (kDebugMode) {
        debugPrint('   ✅ Cancelled _itemsRequestCancelToken');
      }
    }

    // Cancel store load token
    if (_storeLoadCancelToken != null && !_storeLoadCancelToken!.isCancelled) {
      _storeLoadCancelToken!.cancel();
      _storeLoadCancelToken = null;
      if (kDebugMode) {
        debugPrint('   ✅ Cancelled _storeLoadCancelToken');
      }
    }

    // Cancel category debounce timer
    _categoryDebounceTimer?.cancel();
    _categoryDebounceTimer = null;

    if (kDebugMode) {
      debugPrint(
          '   ✅ All pending requests cancelled - zombie data prevention active');
    }
  }

  @override
  void onClose() {
    // 🔧 FIX: Cleanup timers and cancel tokens
    _searchDebounceTimer?.cancel();
    _categoryDebounceTimer?.cancel();
    _itemsRequestCancelToken?.cancel();
    _storeLoadCancelToken?.cancel();
    super.onClose();
  }
}
