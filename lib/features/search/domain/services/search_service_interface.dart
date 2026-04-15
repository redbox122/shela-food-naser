import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';

abstract class SearchServiceInterface {
  /// تنفيذ البحث النصي العادي
  Future<Response<dynamic>> getSearchData(String? query, bool isStore);

  /// تنفيذ البحث باستخدام الفلترة الجديدة
  Future<Response<dynamic>> getNewSearchFilter(SearchFilterModel? searchFilterModel, bool isStore);

  /// جلب العناصر المقترحة
  Future<List<Item>?> getSuggestedItems();

  /// حفظ سجل البحث
  Future<bool> saveSearchHistory(List<String> searchHistories);

  /// الحصول على سجل البحث
  List<String> getSearchAddress();

  /// حذف سجل البحث
  Future<bool> clearSearchHistory();

  // ❌ REMOVED: sortItemSearchList - filtering now handled by API
  // ❌ REMOVED: sortStoreSearchList - filtering now handled by API

  /// الحصول على اقتراحات البحث
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText);

  /// الحصول على الفئات الشائعة
  Future<List<PopularCategoryModel?>?> getPopularCategories();

  /// الحصول على الفئات الرائجة في آخر 24 ساعة
  Future<List<PopularCategoryModel?>?> getTrendingCategories();
}
