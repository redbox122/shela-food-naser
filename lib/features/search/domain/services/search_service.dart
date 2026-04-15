import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository_interface.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
// ❌ REMOVED: import 'package:sixam_mart/helper/date_converter.dart'; - no longer needed after removing local filtering

class SearchService implements SearchServiceInterface {
  final SearchRepositoryInterface searchRepositoryInterface;

  SearchService({required this.searchRepositoryInterface});

  @override
  Future<Response<dynamic>> getSearchData(String? query, bool isStore) async {
    final result = await searchRepositoryInterface.getList(query: query, isStore: isStore);
    return result is Response<dynamic> ? result : const Response<dynamic>();
  }

  @override
  Future<Response<dynamic>> getNewSearchFilter(SearchFilterModel? searchFilterModel, bool isStore) async {
    final result = await searchRepositoryInterface.getList(search_filterModel: searchFilterModel, isStore: isStore);
    return result is Response<dynamic> ? result : const Response<dynamic>();
  }

  @override
  Future<List<Item>?> getSuggestedItems() async {
    final result = await searchRepositoryInterface.getList(isSuggestedItems: true);
    return result is List<Item>? ? result : null;
  }

  @override
  Future<bool> saveSearchHistory(List<String> searchHistories) async {
    return await searchRepositoryInterface.saveSearchHistory(searchHistories);
  }

  @override
  List<String> getSearchAddress() {
    return searchRepositoryInterface.getSearchAddress();
  }

  @override
  Future<bool> clearSearchHistory() async {
    return await searchRepositoryInterface.clearSearchHistory();
  }

  // ❌ REMOVED: sortItemSearchList - filtering now handled by API via ItemRepository.searchItems()
  // ❌ REMOVED: sortStoreSearchList - filtering now handled by API (NOTE: store search API integration pending backend endpoint)

  @override
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText) async {
    return await searchRepositoryInterface.getSearchSuggestions(searchText);
  }

  @override
  Future<List<PopularCategoryModel?>?> getPopularCategories() async {
    return await searchRepositoryInterface.getPopularCategories();
  }

  @override
  Future<List<PopularCategoryModel?>?> getTrendingCategories() async {
    return await searchRepositoryInterface.getTrendingCategories();
  }
}

