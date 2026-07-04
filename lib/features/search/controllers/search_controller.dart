
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:convert';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';

class SearchController extends GetxController implements GetxService {
  final SearchServiceInterface searchServiceInterface;
  SearchController({required this.searchServiceInterface});

  List<Item>? _searchItemList;
  List<Item>? get searchItemList => _searchItemList;

  SearchFilterModel? _search_filterModel;
  SearchFilterModel? get search_filterModel => _search_filterModel;

  List<Item>? _allItemList;
  List<Item>? get allItemList => _allItemList;

  List<Item>? _suggestedItemList;
  List<Item>? get suggestedItemList => _suggestedItemList;

  List<Store>? _searchStoreList;
  List<Store>? get searchStoreList => _searchStoreList;

  List<Store>? _allStoreList;
  List<Store>? get allStoreList => _allStoreList;

  String? _searchText = '';
  String? get searchText => _searchText;

  String? _storeResultText = '';

  String? _itemResultText = '';

  double _lowerValue = 0;
  double get lowerValue => _lowerValue;

  double _upperValue = 0;
  double get upperValue => _upperValue;

  List<String> _historyList = [];
  List<String> get historyList => _historyList;

  bool _isSearchMode = true;
  bool get isSearchMode => _isSearchMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasError = false;
  bool get hasError => _hasError;
  bool _isLoadingSuggestedItems = false;
  bool get isLoadingSuggestedItems => _isLoadingSuggestedItems;
  bool _isLoadingPopularCategories = false;
  bool get isLoadingPopularCategories => _isLoadingPopularCategories;
  bool _isLoadingTrendingCategories = false;
  bool get isLoadingTrendingCategories => _isLoadingTrendingCategories;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;
  bool _hasPopularCategoriesError = false;
  bool get hasPopularCategoriesError => _hasPopularCategoriesError;
  bool _hasTrendingCategoriesError = false;
  bool get hasTrendingCategoriesError => _hasTrendingCategoriesError;

  final List<String> _sortList = ['ascending'.tr, 'descending'.tr];
  List<String> get sortList => _sortList;

  int _sortIndex = -1;
  int get sortIndex => _sortIndex;

  int _storeSortIndex = -1;
  int get storeSortIndex => _storeSortIndex;

  int _rating = -1;
  int get rating => _rating;

  int _storeRating = -1;
  int get storeRating => _storeRating;

  bool _isStore = false;
  bool get isStore => _isStore;

  bool _isAvailableItems = false;
  bool get isAvailableItems => _isAvailableItems;

  bool _isAvailableStore = false;
  bool get isAvailableStore => _isAvailableStore;

  bool _isDiscountedItems = false;
  bool get isDiscountedItems => _isDiscountedItems;

  bool _isDiscountedStore = false;
  bool get isDiscountedStore => _isDiscountedStore;

  bool _veg = false;
  bool get veg => _veg;

  bool _storeVeg = false;
  bool get storeVeg => _storeVeg;

  bool _nonVeg = false;
  bool get nonVeg => _nonVeg;

  bool _storeNonVeg = false;
  bool get storeNonVeg => _storeNonVeg;

  String? _searchHomeText = '';
  String? get searchHomeText => _searchHomeText;

  SearchSuggestionModel? _searchSuggestionModel;
  SearchSuggestionModel? get searchSuggestionModel => _searchSuggestionModel;

  List<PopularCategoryModel?>? _popularCategoryList;
  List<PopularCategoryModel?>? get popularCategoryList => _popularCategoryList;

  List<PopularCategoryModel?>? _trendingCategoryList;
  List<PopularCategoryModel?>? get trendingCategoryList =>
      _trendingCategoryList;

  bool _isVertical = false;
  bool get isVertical => _isVertical;

  bool _isPriceAscending = false;
  bool get isPriceAscending => _isPriceAscending;
  int? _activeModuleId;
  int? get activeModuleId => _activeModuleId;
  List<CategoryModel> _discoveryFallbackCategories = <CategoryModel>[];
  List<CategoryModel> get discoveryFallbackCategories =>
      _discoveryFallbackCategories;
  int? _fallbackCategoriesModuleId;
  int? get fallbackCategoriesModuleId => _fallbackCategoriesModuleId;

  // ===================================================================================================================

  // Lightweight, release-safe perf logging for the search flow.
  // Guarded by kDebugMode so no string building / IO happens in release.
  void _perf(String stage, [String extra = '']) {
    if (kDebugMode) {
      debugPrint('[SearchPerf][$stage]${extra.isEmpty ? '' : ' $extra'}');
    }
  }

  void set_Price(bool value) {
    _isPriceAscending = value;

    if (_searchItemList != null && _searchItemList!.isNotEmpty) {
      _searchItemList!.sort((a, b) {
        final double priceA = a.price ?? 0;
        final double priceB = b.price ?? 0;

        return _isPriceAscending
            ? priceA.compareTo(priceB) // تصاعدي
            : priceB.compareTo(priceA); // تنازلي
      });
    }

    update(); // لتحديث الواجهة
  }

  // ----------------------------

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
    //

    final SearchFilterModel searchFiltermodel = SearchFilterModel(
      research_Name: research_Name,
      product_arrangement: product_arrangement,
      id_category: id_category,
      id_stores: id_stores,
      discount: discount == false ? '0' : '1',
      min: min,
      max: max,
    );

    update();

    applyNewSearchFilter(
        searchFilterModel: searchFiltermodel, fromHome: fromHome);
  }

  //============================

  void toggleVeg() {
    _veg = !_veg;
    update();
  }

  void toggleStoreVeg() {
    _storeVeg = !_storeVeg;
    update();
  }

  void toggleNonVeg() {
    _nonVeg = !_nonVeg;
    update();
  }

  void setVertical(bool value) {
    _isVertical = value;
    update();
  }

  void toggleStoreNonVeg() {
    _storeNonVeg = !_storeNonVeg;
    update();
  }

  void toggleAvailableItems() {
    _isAvailableItems = !_isAvailableItems;
    update();
  }

  void toggleAvailableStore() {
    _isAvailableStore = !_isAvailableStore;
    update();
  }

  void toggleDiscountedItems() {
    _isDiscountedItems = !_isDiscountedItems;
    update();
  }

  void toggleDiscountedStore() {
    _isDiscountedStore = !_isDiscountedStore;
    update();
  }

  void setStore(bool isStore, {bool canUpdate = true}) {
    // If switching modes, clear the opposite mode's result text to force re-search
    if (_isStore != isStore) {
      if (isStore) {
        // Switching to store mode, clear item result
        _itemResultText = '';
      } else {
        // Switching to item mode, clear store result
        _storeResultText = '';
      }
    }
    _isStore = isStore;
    if (canUpdate) {
      update();
    }
  }

  void setSearchMode(bool isSearchMode, {bool canUpdate = true}) {
    _isSearchMode = isSearchMode;
    if (isSearchMode) {
      _isLoading = false;
      _hasError = false;
      _searchText = '';
      _itemResultText = '';
      _storeResultText = '';
      _allStoreList = null;
      _allItemList = null;
      _searchItemList = null;
      _searchStoreList = null;
      _sortIndex = -1;
      _storeSortIndex = -1;
      _isDiscountedItems = false;
      _isDiscountedStore = false;
      _isAvailableItems = false;
      _isAvailableStore = false;
      _veg = false;
      _storeVeg = false;
      _nonVeg = false;
      _storeNonVeg = false;
      _rating = -1;
      _storeRating = -1;
      _upperValue = 0;
      _lowerValue = 0;
    }
    if (_isStore) {
      _isStore = !_isStore;
    }
    if (canUpdate) {
      update();
    }
  }

  void setLowerAndUpperValue(double lower, double upper) {
    _lowerValue = lower;
    _upperValue = upper;
    update();
  }

  // ❌ REMOVED: sortItemSearchList - filtering now handled by API
  // Re-search with current filters instead
  void sortItemSearchList() {
    if (_searchText != null && _searchText!.isNotEmpty) {
      searchData(query: _searchText);
    }
  }

  // ❌ REMOVED: sortStoreSearchList - filtering now handled by API
  // Re-search with current filters instead
  void sortStoreSearchList() {
    if (_searchText != null && _searchText!.isNotEmpty) {
      searchData(query: _searchText);
    }
  }

  void setSearchText(String text) {
    _searchText = text;
    update();
  }

  void resetForModuleSwitch({required bool hasQuery}) {
    _hasError = false;
    _hasPopularCategoriesError = false;
    _hasTrendingCategoriesError = false;
    _isLoading = false;
    _isLoadingSuggestedItems = false;
    _isLoadingPopularCategories = false;
    _isLoadingTrendingCategories = false;
    _isLoadingHistory = false;
    _searchSuggestionModel = null;
    _suggestedItemList = <Item>[];
    _searchItemList = <Item>[];
    _allItemList = <Item>[];
    _searchStoreList = <Store>[];
    _allStoreList = <Store>[];
    _popularCategoryList = <PopularCategoryModel?>[];
    _trendingCategoryList = <PopularCategoryModel?>[];
    _discoveryFallbackCategories = <CategoryModel>[];
    if (!hasQuery) {
      _searchText = '';
      _isSearchMode = true;
    }
    update();
  }

  void setActiveModuleId(int? moduleId) {
    _activeModuleId = moduleId;
  }

  void setDiscoveryFallbackCategories(List<CategoryModel> categories,
      {required int? moduleId}) {
    _fallbackCategoriesModuleId = moduleId;
    _discoveryFallbackCategories = List<CategoryModel>.from(categories);
    debugPrint(
        '[Search][DISCOVERY_FALLBACK_CATEGORIES] moduleId=${moduleId ?? 'null'} count=${_discoveryFallbackCategories.length}');
    if (_discoveryFallbackCategories.isEmpty) {
      debugPrint(
          '[Search][SECTION_EMPTY] type=discovery_fallback_categories moduleId=${moduleId ?? 'null'}');
    }
    update();
  }

  void getSuggestedItems() async {
    _isLoadingSuggestedItems = true;
    final int? moduleId =
        Get.isRegistered<SplashController>() ? Get.find<SplashController>().module?.id : null;
    debugPrint(
        '[Search][FETCH_START] type=suggested_items moduleId=${moduleId ?? 'null'}');
    update();
    try {
      final List<Item>? suggestedItemList =
          await searchServiceInterface.getSuggestedItems();
      _suggestedItemList = <Item>[];
      if (suggestedItemList != null) {
        _suggestedItemList!.addAll(suggestedItemList);
      }
      debugPrint(
          '[Search][PARSED_COUNT] type=suggested_items moduleId=${moduleId ?? 'null'} count=${_suggestedItemList?.length ?? 0}');
      if ((_suggestedItemList?.isEmpty ?? true)) {
        debugPrint(
            '[Search][SECTION_EMPTY] type=suggested_items moduleId=${moduleId ?? 'null'}');
      }
    } catch (e) {
      _suggestedItemList = <Item>[];
      debugPrint('[Search][ERROR] suggested_items $e');
    } finally {
      _isLoadingSuggestedItems = false;
      debugPrint(
          '[Search][DONE] type=suggested_items moduleId=${moduleId ?? 'null'} loading=false');
      debugPrint(
          '[Search][FINALLY] type=suggested_items moduleId=${moduleId ?? 'null'} loading=false');
      update();
    }
  }

  void searchData({String? query, bool? fromHome}) async {
    final String normalizedQuery = (query ?? '').trim();
    if (normalizedQuery.isEmpty) {
      _isLoading = false;
      _hasError = false;
      _searchText = '';
      _searchItemList = <Item>[];
      _allItemList = <Item>[];
      _searchStoreList = <Store>[];
      _allStoreList = <Store>[];
      _isSearchMode = true;
      debugPrint('[Search][EMPTY_QUERY] handled=true');
      debugPrint('[Search][DONE] loading=false');
      debugPrint('[Search][FINALLY] loading=false');
      update();
      return;
    }

    // Check if we need to search both items and stores
    final bool needItemSearch =
        normalizedQuery != _itemResultText || fromHome == true;
    final bool needStoreSearch =
        normalizedQuery != _storeResultText || fromHome == true;

    // If we need to search, perform both searches in parallel
    if (needItemSearch || needStoreSearch) {
      _perf('QUERY_START', 'q=$normalizedQuery item=$needItemSearch store=$needStoreSearch');
      // أثناء وجود استعلام بحث نشط لا نطلب أقسام الاكتشاف
      // (suggested / popular / trending) — تُطلب فقط عند تفريغ البحث.
      _perf('SKIP_DISCOVERY_DURING_QUERY', 'q=$normalizedQuery');
      _isLoading = true;
      _hasError = false;
      _searchHomeText = normalizedQuery;
      _searchText = normalizedQuery;
      _rating = -1;
      _storeRating = -1;
      _upperValue = 0;
      _lowerValue = 0;

      if (needItemSearch) {
        _searchItemList = null;
        _allItemList = null;
      }
      if (needStoreSearch) {
        _searchStoreList = null;
        _allStoreList = null;
      }

      // History is saved ONLY on an explicit search (Go/Enter) via saveSearch(),
      // so partial/live-typed queries no longer pollute the recent list.
      _isSearchMode = false;

      if (!(fromHome ?? false)) {
        update();
      }

      // Perform both searches in parallel
      final futures = <Future>[];

      bool itemSearchOk = true;
      bool storeSearchOk = true;
      if (needItemSearch) {
        debugPrint('[Search][FETCH_START] type=items');
        futures.add(_searchItems(normalizedQuery).then((value) {
          itemSearchOk = value;
        }));
      }

      if (needStoreSearch) {
        debugPrint('[Search][FETCH_START] type=stores');
        futures.add(_searchStores(normalizedQuery).then((value) {
          storeSearchOk = value;
        }));
      }

      try {
        // Wait for both searches to complete
        await Future.wait(futures);
      } catch (e) {
        _hasError = true;
        debugPrint('[SEARCH_FETCH_ERROR] status=exception message=$e');
        debugPrint('[Search][ERROR] $e');
      } finally {
        final bool allRequestedFailed = (!needItemSearch || !itemSearchOk) &&
            (!needStoreSearch || !storeSearchOk);
        final bool hasAnyItemData = (_searchItemList?.isNotEmpty ?? false);
        final bool hasAnyStoreData = (_searchStoreList?.isNotEmpty ?? false);
        final int itemCount = _searchItemList?.length ?? 0;
        final int storeCount = _searchStoreList?.length ?? 0;
        _hasError = allRequestedFailed && !hasAnyItemData && !hasAnyStoreData;
        if (_hasError) {
          debugPrint('[SEARCH_FETCH_ERROR] status=all_failed message=no_data');
        } else if (!hasAnyItemData && !hasAnyStoreData) {
          debugPrint('[SEARCH_FETCH_EMPTY]');
        } else {
          debugPrint(
              '[SEARCH_FETCH_SUCCESS] selectedType=${_isStore ? 'stores' : 'items'} itemCount=$itemCount storeCount=$storeCount');
        }
        _isLoading = false;
        debugPrint('[Search][DONE] loading=false');
        debugPrint('[Search][FINALLY] loading=false');
        _perf('UI_UPDATE', 'items=$itemCount stores=$storeCount error=$_hasError');
        update();
      }
    }
  }

  Future<bool> _searchItems(String query) async {
    try {
      final Response response =
          await searchServiceInterface.getSearchData(query, false);
      if (response.statusCode == 200) {
        _hasError = false;
        _itemResultText = query;
        _searchItemList = [];
        _allItemList = [];

        _perf('API_DONE', 'type=items status=200');

        // جلب العناصر
        final List<Item> items = ItemModel.fromJson(response.body as Map<String, dynamic>).items ?? [];

        // ✅ ترتيب حسب السعر (تصاعدي أو تنازلي)
        // قائمة صغيرة (≤ limit) فالفرز رخيص على خيط الواجهة.
        items.sort((a, b) {
          final double priceA = a.price ?? 0;
          final double priceB = b.price ?? 0;

          return _isPriceAscending
              ? priceA.compareTo(priceB) // من الأقل إلى الأعلى
              : priceB.compareTo(priceA); // من الأعلى إلى الأقل
        });

        // ✅ إضافة العناصر المرتبة
        _searchItemList!.addAll(items);
        _allItemList!.addAll(items);

        // ⚡ تمت إزالة حلقة الطباعة لكل منتج ("=== Sorted Prices ===")
        // التي كانت تطبع كل عنصر على خيط الواجهة وتسبب تقطيع الإطارات.
        _perf('PARSE_DONE', 'type=items count=${items.length}');
        return true;
      } else {
        debugPrint(
            '[SEARCH_FETCH_ERROR] status=${response.statusCode} message=items_request_failed');
        debugPrint('[Search][STATUS] type=items code=${response.statusCode}');
        debugPrint('[Search][RAW_TYPE] type=items rawType=${response.body.runtimeType}');
        debugPrint(
            '[Search][RAW_BODY] truncated ${_truncateBody(response.body)}');
        _hasError = true;
        _searchItemList = [];
        _allItemList = [];
        return false;
      }
    } catch (e) {
      debugPrint('[SEARCH_FETCH_ERROR] status=exception message=items_$e');
      debugPrint('[Search][ERROR] items $e');
      _hasError = true;
      _searchItemList = [];
      _allItemList = [];
      return false;
    }
  }

  Future<bool> _searchStores(String query) async {
    try {
      final Response response =
          await searchServiceInterface.getSearchData(query, true);
      if (response.statusCode == 200) {
        _hasError = false;
        _storeResultText = query;
        _searchStoreList = [];
        _allStoreList = [];
        _perf('API_DONE', 'type=stores status=200');
        final storeModel = StoreModel.fromJson(response.body as Map<String, dynamic>);
        _searchStoreList!.addAll(storeModel.stores!);
        _allStoreList!.addAll(storeModel.stores!);
        _perf('PARSE_DONE', 'type=stores count=${_searchStoreList!.length}');
        return true;
      } else {
        debugPrint(
            '[SEARCH_FETCH_ERROR] status=${response.statusCode} message=stores_request_failed');
        debugPrint('[Search][STATUS] type=stores code=${response.statusCode}');
        debugPrint(
            '[Search][RAW_TYPE] type=stores rawType=${response.body.runtimeType}');
        debugPrint(
            '[Search][RAW_BODY] truncated ${_truncateBody(response.body)}');
        _hasError = true;
        _searchStoreList = [];
        _allStoreList = [];
        return false;
      }
    } catch (e) {
      debugPrint('[SEARCH_FETCH_ERROR] status=exception message=stores_$e');
      debugPrint('[Search][ERROR] stores $e');
      _hasError = true;
      _searchStoreList = [];
      _allStoreList = [];
      return false;
    }
  }

  void applyNewSearchFilter(
      {SearchFilterModel? searchFilterModel, bool? fromHome}) async {
    if (searchFilterModel == null) return;

    _isLoading = true;
    _hasError = false;
    // إعادة تعيين المتغيرات
    _rating = -1;
    _storeRating = -1;
    _upperValue = 0;
    _lowerValue = 0;

    if (_isStore) {
      _searchStoreList = null;
      _allStoreList = null;
    } else {
      _searchItemList = null;
      _allItemList = null;
    }

    _isSearchMode = false;

    if (!(fromHome ?? false)) {
      update();
    }

    try {
      final response = await searchServiceInterface.getNewSearchFilter(
          searchFilterModel, _isStore);

      if (response.statusCode == 200 && response.body != null) {
        _hasError = false;
        if (_isStore) {
          final storeModel = StoreModel.fromJson(response.body as Map<String, dynamic>);
          _storeResultText = searchFilterModel.research_Name ?? '';
          _searchStoreList = List<Store>.from(storeModel.stores ?? []);
          _allStoreList = List<Store>.from(storeModel.stores ?? []);
        } else {
          final itemModel = ItemModel.fromJson(response.body as Map<String, dynamic>);
          _itemResultText = searchFilterModel.research_Name ?? '';
          _searchItemList = List<Item>.from(itemModel.items ?? []);
          _allItemList = List<Item>.from(itemModel.items ?? []);
        }
      } else {
        _hasError = true;
        if (_isStore) {
          _searchStoreList = [];
          _allStoreList = [];
        } else {
          _searchItemList = [];
          _allItemList = [];
        }
      }
    } catch (e) {
      debugPrint('Error applying search filter: $e');
      _hasError = true;
    }

    _isLoading = false;
    update();
  }

  void getHistoryList() {
    _isLoadingHistory = true;
    _isSearchMode = true;
    _searchText = '';
    _historyList = [];
    try {
      final List<String> stored = searchServiceInterface.getSearchAddress();
      // Sanitize legacy history: drop short/blank terms and duplicates, cap 10.
      final List<String> cleaned = <String>[];
      for (final String s in stored) {
        final String t = s.trim();
        if (t.length >= 2 && !cleaned.contains(t)) cleaned.add(t);
      }
      if (cleaned.length > 10) cleaned.removeRange(10, cleaned.length);
      _historyList.addAll(cleaned);
      // Persist the cleaned list so the garbage doesn't come back.
      if (cleaned.length != stored.length) {
        searchServiceInterface.saveSearchHistory(_historyList);
      }
      debugPrint('[Search][PARSED_COUNT] type=recent_searches count=${_historyList.length}');
    } catch (e) {
      debugPrint('[Search][ERROR] recent_searches $e');
      _historyList = <String>[];
    } finally {
      _isLoadingHistory = false;
      debugPrint('[Search][FINALLY] type=recent_searches loading=false');
      update();
    }
  }

  void removeHistory(int index) {
    _historyList.removeAt(index);
    searchServiceInterface.saveSearchHistory(_historyList);
    update();
  }

  /// Persists a real search term to the recent-search history. Call this ONLY
  /// on an explicit search (Go/Enter) — never on live/incremental typing.
  /// Ignores terms shorter than 2 chars, de-duplicates (most-recent first),
  /// and caps the history at 10 entries.
  void saveSearch(String query) {
    final String q = query.trim();
    if (q.length < 2) return;
    _historyList.remove(q); // drop any existing duplicate
    _historyList.insert(0, q); // newest first
    if (_historyList.length > 10) {
      _historyList.removeRange(10, _historyList.length);
    }
    searchServiceInterface.saveSearchHistory(_historyList);
    update();
  }

  void clearSearchHistory() async {
    searchServiceInterface.clearSearchHistory();
    _historyList = [];
    update();
  }

  void setRating(int rate) {
    _rating = rate;
    update();
  }

  void setStoreRating(int rate) {
    _storeRating = rate;
    update();
  }

  void setSortIndex(int index) {
    _sortIndex = index;
    update();
  }

  void setStoreSortIndex(int index) {
    _storeSortIndex = index;
    update();
  }

  void resetFilter() {
    _rating = -1;
    _upperValue = 0;
    _lowerValue = 0;
    _isAvailableItems = false;
    _isDiscountedItems = false;
    _veg = false;
    _nonVeg = false;
    _sortIndex = -1;
    update();
  }

  void resetStoreFilter() {
    _storeRating = -1;
    _isAvailableStore = false;
    _isDiscountedStore = false;
    _storeVeg = false;
    _storeNonVeg = false;
    _storeSortIndex = -1;
    update();
  }

  void clearSearchHomeText() {
    _searchHomeText = '';
    update();
  }

  Future<List<String>> getSearchSuggestions(String searchText) async {
    final List<String> items = <String>[];
    _searchSuggestionModel =
        await searchServiceInterface.getSearchSuggestions(searchText);
    if (_searchSuggestionModel != null) {
      for (final item in _searchSuggestionModel!.items!) {
        items.add(item.name!);
      }
      for (final store in _searchSuggestionModel!.stores!) {
        items.add(store.name!);
      }
    }
    return items;
  }

  Future<void> getPopularCategories() async {
    _isLoadingPopularCategories = true;
    debugPrint('[Search][FETCH_START] type=popular_categories');
    _popularCategoryList = <PopularCategoryModel?>[];
    _hasPopularCategoriesError = false;
    update();
    try {
      _popularCategoryList = await searchServiceInterface.getPopularCategories();
      debugPrint(
          '[Search][PARSED_COUNT] type=popular_categories count=${_popularCategoryList?.length ?? 0}');
      if (_popularCategoryList == null) {
        _hasPopularCategoriesError = true;
        debugPrint(
            '[Search][NO_INTERNET_SHOWN] type=popular_categories reason=null_response');
        _popularCategoryList = <PopularCategoryModel?>[];
      } else if (_popularCategoryList!.isEmpty) {
        debugPrint('[Search][SECTION_EMPTY] type=popular_categories');
      }
    } catch (e) {
      debugPrint('[Search][ERROR] popular_categories $e');
      _hasPopularCategoriesError = true;
      debugPrint(
          '[Search][NO_INTERNET_SHOWN] type=popular_categories reason=exception');
      _popularCategoryList = <PopularCategoryModel?>[];
    } finally {
      _isLoadingPopularCategories = false;
      debugPrint('[Search][DONE] type=popular_categories loading=false');
      debugPrint('[Search][FINALLY] type=popular_categories loading=false');
    }
    update();
  }

  Future<void> getTrendingCategories() async {
    _isLoadingTrendingCategories = true;
    debugPrint('[Search][FETCH_START] type=trending_categories');
    _trendingCategoryList = <PopularCategoryModel?>[];
    _hasTrendingCategoriesError = false;
    update();
    try {
      _trendingCategoryList =
          await searchServiceInterface.getTrendingCategories();
      debugPrint(
          '[Search][PARSED_COUNT] type=trending_categories count=${_trendingCategoryList?.length ?? 0}');
      if (_trendingCategoryList == null) {
        _hasTrendingCategoriesError = true;
        debugPrint(
            '[Search][NO_INTERNET_SHOWN] type=trending_categories reason=null_response');
        _trendingCategoryList = <PopularCategoryModel?>[];
      } else if (_trendingCategoryList!.isEmpty) {
        debugPrint('[Search][SECTION_EMPTY] type=trending_categories');
      }
    } catch (e) {
      debugPrint('[Search][ERROR] trending_categories $e');
      _hasTrendingCategoriesError = true;
      debugPrint(
          '[Search][NO_INTERNET_SHOWN] type=trending_categories reason=exception');
      _trendingCategoryList = <PopularCategoryModel?>[];
    } finally {
      _isLoadingTrendingCategories = false;
      debugPrint('[Search][DONE] type=trending_categories loading=false');
      debugPrint('[Search][FINALLY] type=trending_categories loading=false');
    }
    update();
  }

  String _truncateBody(dynamic body) {
    try {
      final String raw =
          body is String ? body : jsonEncode(body ?? <String, dynamic>{});
      if (raw.length <= 400) {
        return raw;
      }
      return '${raw.substring(0, 400)}...';
    } catch (_) {
      return body?.toString() ?? '';
    }
  }
}
