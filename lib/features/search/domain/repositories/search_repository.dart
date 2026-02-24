import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class SearchRepository implements SearchRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  static bool _isNewSearchAvailable = true;

  SearchRepository({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<bool> saveSearchHistory(List<String> searchHistories) async {
    return await sharedPreferences.setStringList(AppConstants.searchHistory, searchHistories);
  }

  @override
  List<String> getSearchAddress() {
    return sharedPreferences.getStringList(AppConstants.searchHistory) ?? [];
  }

  @override
  Future<bool> clearSearchHistory() async {
    return await sharedPreferences.setStringList(AppConstants.searchHistory, []);
  }

  @override
  Future<dynamic> getList({
    int? offset,
    String? query,
    Search_FilterModel? search_filterModel,
    bool? isStore,
    bool isSuggestedItems = false,
  }) async {
    if (isSuggestedItems) {
      return await _getSuggestedItems();
    } else {
      if (search_filterModel == null) {
        return await _getSearchData(query, isStore ?? false);
      } else {
        return await _getFilteredSearchData(search_filterModel, isStore ?? false);
      }
    }
  }

  Future<List<Item>?> _getSuggestedItems() async {
    List<Item>? suggestedItemList;
    final response = await apiClient.getData(AppConstants.suggestedItemUri);

    if (response.statusCode == 200 && response.body != null) {
      suggestedItemList = [];
      for (final item in (response.body as List)) {
        suggestedItemList.add(Item.fromJson(item as Map<String, dynamic>));
      }
    }
    return suggestedItemList;
  }

  Future<Response<dynamic>> _getSearchData(String? query, bool isStore) async {
    final int? moduleId = _resolveModuleId();
    final String safeQuery = Uri.encodeQueryComponent((query ?? '').trim());
    var uri =
        '${AppConstants.searchUri}${isStore ? 'stores' : 'items'}/search?name=$safeQuery&offset=1&limit=50';
    if (moduleId != null) {
      uri = '$uri&module_id=$moduleId';
    }
    return await apiClient.getData(uri);
  }

  Future<Response<dynamic>> _getFilteredSearchData(Search_FilterModel searchFilterModel, bool isStore) async {
    // Hyper all-categories search is more stable on legacy endpoint and supports offset pagination.
    if ((searchFilterModel.id_category ?? '').trim().isEmpty) {
      return _getLegacyFilteredSearchData(searchFilterModel, isStore);
    }

    final data = {
      'name': searchFilterModel.research_Name,
      'product_arrangement': searchFilterModel.product_arrangement,
      'id_category': searchFilterModel.id_category,
      'id_stores': searchFilterModel.id_stores,
      'min_price': searchFilterModel.min,
      'max_price': searchFilterModel.max,
      'discount': searchFilterModel.discount,
      'offset': searchFilterModel.offset ?? '1',
      'limit': searchFilterModel.limit ?? '10',
    };
    final int? moduleId = _resolveModuleId();
    if (moduleId != null) {
      data['module_id'] = moduleId.toString();
    }

    const uri = '${AppConstants.searchUri}items/new-search';
    if (!_isNewSearchAvailable) {
      return _getLegacyFilteredSearchData(searchFilterModel, isStore);
    }
    final Response<dynamic> response = await apiClient.postData(uri, data);
    if (response.statusCode == 404) {
      _isNewSearchAvailable = false;
      return _getLegacyFilteredSearchData(searchFilterModel, isStore);
    }
    return response;
  }

  Future<Response<dynamic>> _getLegacyFilteredSearchData(
    Search_FilterModel searchFilterModel,
    bool isStore,
  ) async {
    final String offset = (searchFilterModel.offset ?? '1').trim().isEmpty
        ? '1'
        : (searchFilterModel.offset ?? '1').trim();
    final String limit = (searchFilterModel.limit ?? '10').trim().isEmpty
        ? '10'
        : (searchFilterModel.limit ?? '10').trim();
    final List<String> params = [
      'name=${Uri.encodeQueryComponent((searchFilterModel.research_Name ?? '').trim())}',
      'offset=$offset',
      'limit=$limit',
    ];
    final int? moduleId = _resolveModuleId();
    if (moduleId != null) {
      params.add('module_id=$moduleId');
    }
    if ((searchFilterModel.id_category ?? '').isNotEmpty) {
      params.add(
          'category_id=${Uri.encodeQueryComponent((searchFilterModel.id_category ?? '').trim())}');
    }
    if ((searchFilterModel.id_stores ?? '').isNotEmpty) {
      params.add(
          'store_id=${Uri.encodeQueryComponent((searchFilterModel.id_stores ?? '').trim())}');
    }
    final String uri =
        '${AppConstants.searchUri}${isStore ? 'stores' : 'items'}/search?${params.join('&')}';
    return apiClient.getData(uri);
  }

  @override
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText) async {
    SearchSuggestionModel? model;
    final String safeSearchText = Uri.encodeQueryComponent(searchText.trim());
    final response = await apiClient
        .getData('${AppConstants.searchSuggestionsUri}?name=$safeSearchText');

    if (response.statusCode == 200 && response.body != null) {
      model = SearchSuggestionModel.fromJson(response.body as Map<String, dynamic>);
    }
    return model;
  }

  @override
  Future<List<PopularCategoryModel?>?> getPopularCategories() async {
    List<PopularCategoryModel?>? categoryList;
    final response = await apiClient.getData(AppConstants.searchPopularCategoriesUri);

    if (response.statusCode == 200 && response.body != null) {
      categoryList = [];
      for (final item in (response.body as List)) {
        categoryList.add(PopularCategoryModel.fromJson(item as Map<String, dynamic>));
      }
    }
    return categoryList;
  }

  @override
  Future<List<PopularCategoryModel?>?> getTrendingCategories() async {
    List<PopularCategoryModel?>? categoryList;
    // Get trending categories from last 24 hours
    final response = await apiClient.getData('${AppConstants.searchPopularCategoriesUri}?trending=true&hours=24');

    if (response.statusCode == 200 && response.body != null) {
      categoryList = [];
      for (final item in (response.body as List)) {
        categoryList.add(PopularCategoryModel.fromJson(item as Map<String, dynamic>));
      }
    }
    return categoryList;
  }

  // Placeholder implementations
  @override
  Future<void> add(dynamic value) => throw UnimplementedError();

  @override
  Future<void> delete(int? id) => throw UnimplementedError();

  @override
  Future<void> get(String? id) => throw UnimplementedError();

  @override
  Future<void> update(Map<String, dynamic> body, int? id) =>
      throw UnimplementedError();

  int? _resolveModuleId() {
    if (Get.isRegistered<SplashController>()) {
      final module = Get.find<SplashController>().module;
      if (module?.id != null) {
        return module!.id;
      }
    }
    final cachedModule = sharedPreferences.getString(AppConstants.cacheModuleId);
    if (cachedModule != null) {
      try {
        return ModuleModel.fromJson(jsonDecode(cachedModule) as Map<String, dynamic>).id;
      } catch (_) {
        // ignore: no-op
      }
    }
    return null;
  }
}
