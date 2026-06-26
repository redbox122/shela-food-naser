import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    SearchFilterModel? search_filterModel,
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
    // RULE #1: scope suggestions to the current module explicitly.
    final int? moduleId = _resolveModuleId();
    _logSearchRequest(endpoint: AppConstants.suggestedItemUri, method: 'GET');
    final response = await apiClient.getData(
      moduleId != null
          ? '${AppConstants.suggestedItemUri}?module_id=$moduleId'
          : AppConstants.suggestedItemUri,
      useEtag: false,
      headers: <String, String>{
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        if (moduleId != null) AppConstants.moduleId: moduleId.toString(),
      },
    );
    _logSearchResponse(response);
    if (response.statusCode == 304) {
      debugPrint('[Search][CACHE_304] type=suggested_items hasCache=false');
      debugPrint(
          '[Search][NO_INTERNET_BLOCKED_FOR_304] type=suggested_items');
      return <Item>[];
    }

    if (response.statusCode == 200 && response.body != null) {
      suggestedItemList = [];
      for (final item in (response.body as List)) {
        suggestedItemList.add(Item.fromJson(item as Map<String, dynamic>));
      }
      debugPrint(
          '[Search][CACHE_USED] type=suggested_items count=${suggestedItemList.length}');
    } else if (response.statusCode != 200) {
      debugPrint(
          '[Search][NO_INTERNET_SHOWN] type=suggested_items reason=status_${response.statusCode}');
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
    _logSearchRequest(
      endpoint: uri,
      method: 'GET',
      moduleId: moduleId,
    );
    final Response<dynamic> response = await apiClient.getData(uri);
    _logSearchResponse(response);
    return response;
  }

  Future<Response<dynamic>> _getFilteredSearchData(SearchFilterModel searchFilterModel, bool isStore) async {
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
    SearchFilterModel searchFilterModel,
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
    _logSearchRequest(
      endpoint: uri,
      method: 'GET',
      moduleId: moduleId,
    );
    final Response<dynamic> response = await apiClient.getData(uri);
    _logSearchResponse(response);
    return response;
  }

  @override
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText) async {
    SearchSuggestionModel? model;
    final String safeSearchText = Uri.encodeQueryComponent(searchText.trim());
    final String endpoint =
        '${AppConstants.searchSuggestionsUri}?name=$safeSearchText';
    _logSearchRequest(endpoint: endpoint, method: 'GET');
    final response = await apiClient.getData(endpoint);
    _logSearchResponse(response);

    if (response.statusCode == 200 && response.body != null) {
      model = SearchSuggestionModel.fromJson(response.body as Map<String, dynamic>);
    }
    return model;
  }

  @override
  Future<List<PopularCategoryModel?>?> getPopularCategories() async {
    List<PopularCategoryModel?>? categoryList;
    // RULE #1: scope popular categories to the current module explicitly.
    final int? moduleId = _resolveModuleId();
    _logSearchRequest(
        endpoint: AppConstants.searchPopularCategoriesUri, method: 'GET');
    final response = await apiClient.getData(
      moduleId != null
          ? '${AppConstants.searchPopularCategoriesUri}?module_id=$moduleId'
          : AppConstants.searchPopularCategoriesUri,
      useEtag: false,
      headers: <String, String>{
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        if (moduleId != null) AppConstants.moduleId: moduleId.toString(),
      },
    );
    _logSearchResponse(response);
    if (response.statusCode == 304) {
      debugPrint('[Search][CACHE_304] type=popular_categories hasCache=false');
      debugPrint(
          '[Search][NO_INTERNET_BLOCKED_FOR_304] type=popular_categories');
      return <PopularCategoryModel?>[];
    }

    if (response.statusCode == 200 && response.body != null) {
      categoryList = [];
      for (final item in (response.body as List)) {
        categoryList.add(PopularCategoryModel.fromJson(item as Map<String, dynamic>));
      }
      debugPrint(
          '[Search][CACHE_USED] type=popular_categories count=${categoryList.length}');
    } else if (response.statusCode != 200) {
      debugPrint(
          '[Search][NO_INTERNET_SHOWN] type=popular_categories reason=status_${response.statusCode}');
    }
    return categoryList;
  }

  @override
  Future<List<PopularCategoryModel?>?> getTrendingCategories() async {
    List<PopularCategoryModel?>? categoryList;
    // Get trending categories from last 24 hours
    const String endpoint =
        '${AppConstants.searchPopularCategoriesUri}?trending=true&hours=24';
    _logSearchRequest(endpoint: endpoint, method: 'GET');
    final response = await apiClient.getData(
      endpoint,
      useEtag: false,
      headers: <String, String>{
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
    _logSearchResponse(response);
    if (response.statusCode == 304) {
      debugPrint('[Search][CACHE_304] type=trending_categories hasCache=false');
      debugPrint(
          '[Search][NO_INTERNET_BLOCKED_FOR_304] type=trending_categories');
      return <PopularCategoryModel?>[];
    }

    if (response.statusCode == 200 && response.body != null) {
      categoryList = [];
      for (final item in (response.body as List)) {
        categoryList.add(PopularCategoryModel.fromJson(item as Map<String, dynamic>));
      }
      debugPrint(
          '[Search][CACHE_USED] type=trending_categories count=${categoryList.length}');
    } else if (response.statusCode != 200) {
      debugPrint(
          '[Search][NO_INTERNET_SHOWN] type=trending_categories reason=status_${response.statusCode}');
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

  void _logSearchRequest({
    required String endpoint,
    required String method,
    int? moduleId,
  }) {
    if (!kDebugMode) return;
    final Map<String, String> headers = apiClient.getHeader();
    final String? moduleFromHeader =
        headers[AppConstants.moduleId] ?? headers['module-id'];
    final String? zoneFromHeader =
        headers[AppConstants.zoneId] ?? headers['zone-id'];
    final bool authPresent =
        (headers['Authorization'] ?? '').trim().isNotEmpty;
    debugPrint('[Search][ENDPOINT] $endpoint');
    debugPrint('[Search][METHOD] $method');
    debugPrint(
        '[Search][HEADERS] moduleId=${moduleId ?? moduleFromHeader ?? 'null'} zoneId=${zoneFromHeader ?? 'null'} authPresent=$authPresent');
  }

  void _logSearchResponse(Response<dynamic> response) {
    if (!kDebugMode) return;
    debugPrint('[Search][STATUS] ${response.statusCode}');
    debugPrint('[Search][RAW_TYPE] ${response.body.runtimeType}');
    final String rawBody = _truncateBody(response.body);
    debugPrint('[Search][RAW_BODY] truncated $rawBody');
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
