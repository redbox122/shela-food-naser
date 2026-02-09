// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';

class Search_Controller extends GetxController implements GetxService {
  final SearchServiceInterface searchServiceInterface;
  Search_Controller({required this.searchServiceInterface});

  List<Item>? _searchItemList;
  List<Item>? get searchItemList => _searchItemList;

  Search_FilterModel? _search_filterModel;
  Search_FilterModel? get search_filterModel => _search_filterModel;

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

  // ===================================================================================================================

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

    final Search_FilterModel searchFiltermodel = Search_FilterModel(
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

  void setStore(bool isStore) {
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
    update();
  }

  void setSearchMode(bool isSearchMode, {bool canUpdate = true}) {
    _isSearchMode = isSearchMode;
    if (isSearchMode) {
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

  void getSuggestedItems() async {
    final List<Item>? suggestedItemList =
        await searchServiceInterface.getSuggestedItems();
    if (suggestedItemList != null) {
      _suggestedItemList = [];
      _suggestedItemList!.addAll(suggestedItemList);
    }
    update();
  }

  void searchData({String? query, bool? fromHome}) async {
    if (query == null || query.isEmpty) return;

    // Check if we need to search both items and stores
    final bool needItemSearch = query != _itemResultText || fromHome == true;
    final bool needStoreSearch = query != _storeResultText || fromHome == true;

    // If we need to search, perform both searches in parallel
    if (needItemSearch || needStoreSearch) {
      _isLoading = true;
      _searchHomeText = query;
      _searchText = query;
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

      if (!_historyList.contains(query)) {
        _historyList.insert(0, query);
      }

      searchServiceInterface.saveSearchHistory(_historyList);
      _isSearchMode = false;

      if (!(fromHome ?? false)) {
        update();
      }

      // Perform both searches in parallel
      final futures = <Future>[];

      if (needItemSearch) {
        futures.add(_searchItems(query));
      }

      if (needStoreSearch) {
        futures.add(_searchStores(query));
      }

      // Wait for both searches to complete
      await Future.wait(futures);

      _isLoading = false;
      update();
    }
  }

  Future<void> _searchItems(String query) async {
    try {
      final Response response =
          await searchServiceInterface.getSearchData(query, false);
      if (response.statusCode == 200) {
        _itemResultText = query;
        _searchItemList = [];
        _allItemList = [];

        // جلب العناصر
        final List<Item> items = ItemModel.fromJson(response.body as Map<String, dynamic>).items ?? [];

        // ✅ ترتيب حسب السعر (تصاعدي أو تنازلي)
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

        // ✅ طباعة اختبارية للتأكد من الترتيب
        print('=== Sorted Prices ===');
        for (final item in items) {
          print('${item.name} - ${item.price}');
        }
      }
    } catch (e) {
      debugPrint('Error searching items: $e');
      _searchItemList = [];
      _allItemList = [];
    }
  }

  Future<void> _searchStores(String query) async {
    try {
      final Response response =
          await searchServiceInterface.getSearchData(query, true);
      if (response.statusCode == 200) {
        _storeResultText = query;
        _searchStoreList = [];
        _allStoreList = [];
        final storeModel = StoreModel.fromJson(response.body as Map<String, dynamic>);
        _searchStoreList!.addAll(storeModel.stores!);
        _allStoreList!.addAll(storeModel.stores!);
      }
    } catch (e) {
      debugPrint('Error searching stores: $e');
      _searchStoreList = [];
      _allStoreList = [];
    }
  }

  void applyNewSearchFilter(
      {Search_FilterModel? searchFilterModel, bool? fromHome}) async {
    if (searchFilterModel == null) return;

    _isLoading = true;
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
      }
    } catch (e) {
      debugPrint('Error applying search filter: $e');
    }

    _isLoading = false;
    update();
  }

  void getHistoryList() {
    _isSearchMode = true;
    _searchText = '';
    _historyList = [];
    _historyList.addAll(searchServiceInterface.getSearchAddress());
  }

  void removeHistory(int index) {
    _historyList.removeAt(index);
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
    _popularCategoryList = null;
    _popularCategoryList = await searchServiceInterface.getPopularCategories();
    update();
  }

  Future<void> getTrendingCategories() async {
    _trendingCategoryList = null;
    _trendingCategoryList =
        await searchServiceInterface.getTrendingCategories();
    update();
  }
}
