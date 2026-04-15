import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class SearchRepositoryInterface extends RepositoryInterface {
  /// يحفظ سجل البحث محلياً أو عبر API
  Future<bool> saveSearchHistory(List<String> searchHistories);

  /// يحصل على عناوين البحث من التخزين
  List<String> getSearchAddress();

  /// يحذف سجل البحث
  Future<bool> clearSearchHistory();

  /// يحصل على قائمة نتائج البحث
  @override
  Future<dynamic> getList(
      {int? offset, String? query, SearchFilterModel? search_filterModel, bool? isStore, bool isSuggestedItems = false});

  /// يحصل على اقتراحات البحث
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText);

  /// يحصل على الفئات الشائعة
  Future<List<PopularCategoryModel?>?> getPopularCategories();

  /// يحصل على الفئات الرائجة في آخر 24 ساعة
  Future<List<PopularCategoryModel?>?> getTrendingCategories();
}
