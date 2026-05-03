import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/splash/domain/services/splash_service_interface.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/recommended_product_model.dart';
import 'package:sixam_mart/features/store/domain/models/cart_suggested_item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/features/store/domain/models/subcategory_samples_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_filter_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/splash/domain/models/landing_model.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/language/domain/service/language_service_interface.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/store/domain/models/slim_menu_model.dart';

// Minimal mocks - just return null for all methods
// Minimal mock – matches StoreServiceInterface exactly
class MockStoreServiceInterface implements StoreServiceInterface {
  @override
  Future<StoreModel?> getStoreList(
    int offset,
    String filterBy,
    String storeType, {
    required DataSourceEnum source,
    bool? recentlyAdded,
    bool? highestRated,
    bool? fastestDelivery,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    int? limit,
  }) async {
    return null;
  }

  @override
  Future<List<Store>?> getPopularStoreList(
    String type, {
    required DataSourceEnum source,
  }) async {
    return null;
  }

  @override
  Future<List<Store>?> getLatestStoreList(
    String type, {
    required DataSourceEnum source,
  }) async {
    return null;
  }

  @override
  Future<List<Store>?> getTopOfferStoreList({
    required DataSourceEnum source,
  }) async {
    return null;
  }

  @override
  Future<List<Store>?> getFeaturedStoreList({
    required DataSourceEnum source,
  }) async {
    return null;
  }

  @override
  Future<List<Store>?> getVisitAgainStoreList({
    required DataSourceEnum source,
  }) async {
    return null;
  }

  @override
  Future<Store?> getStoreDetails(
    String storeID,
    bool fromCart,
    String slug,
    String languageCode,
    ModuleModel? module,
    int? cacheModuleId,
    int? moduleId,
    CancelToken? cancelToken,
  ) async {
    return null;
  }

  @override
  Future<ItemModel?> getStoreItemList(
    int? storeID,
    int offset,
    int? categoryID,
    String type, {
    int? moduleId,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    return null;
  }

  @override
  Future<ItemModel?> getStoreSearchItemList(
    String searchText,
    String? storeID,
    int offset,
    String type,
    int? categoryID,
  ) async {
    return null;
  }

  @override
  Future<RecommendedItemModel?> getStoreRecommendedItemList(
    int? storeId, {
    CancelToken? cancelToken,
  }) async {
    return null;
  }

  @override
  Future<CartSuggestItemModel?> getCartStoreSuggestedItemList(
    int? storeId,
    String languageCode,
    ModuleModel? module,
    int? cacheModuleId,
    int? moduleId,
  ) async {
    return null;
  }

  @override
  Future<List<StoreBannerModel>?> getStoreBannerList(
    int? storeId, {
    CancelToken? cancelToken,
  }) async {
    return null;
  }

  @override
  Future<List<Store>?> getRecommendedStoreList({
    required DataSourceEnum source,
  }) async {
    return null;
  }

  @override
  List<Modules> moduleList() {
    return [];
  }

  @override
  String filterRestaurantLinkUrl(String slug, Store store) {
    return '';
  }

  // ignore: non_constant_identifier_names
  @override
  Future<Response<dynamic>> get_new_search_filtera({
    // ignore: non_constant_identifier_names
    required SearchFilterModel search_filterModel,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CategoryModel>?> getSubCategoryList({
    String? parentID,
  }) async {
    return null;
  }

  @override
  Future<StoreSubcategorySamplesModel?> getStoreSubcategoriesWithSamples({
    required int storeId,
    required int categoryId,
    int limit = 10,
    int offset = 1,
    int sampleSize = 3,
    String type = 'all',
    bool includeChildren = false,
  }) async {
    return null;
  }

  @override
  Future<SlimMenuResponse?> getSlimMenu(
    int? storeId, {
    int? moduleId,
    CancelToken? cancelToken,
  }) async {
    return null;
  }
}

class MockCategoryServiceInterface implements CategoryServiceInterface {
  @override
  Future<List<CategoryModel>?> getCategoryList(bool allCategory,
          {DataSourceEnum? source}) async =>
      null;

  @override
  Future<List<CategoryModel>?> getSubCategoryList(String? parentID) async =>
      null;

  @override
  Future<ItemModel?> getCategoryItemList(
          String? categoryID, int offset, String type,
          {bool? includeChildren, CancelToken? cancelToken}) async =>
      null;

  @override
  Future<void> clearCategoryItemCache(int categoryId) async {}

  @override
  Future<StoreModel?> getCategoryStoreList(
          String? categoryID, int offset, String type) async =>
      null;

  @override
  Future<Response<dynamic>> getSearchData(
      String? query, String? categoryID, bool isStore, String type) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> saveUserInterests(List<int?> interests) async => false;
}

class MockSearchServiceInterface implements SearchServiceInterface {
  @override
  Future<Response<dynamic>> getSearchData(String? query, bool isStore) async {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> getNewSearchFilter(
      SearchFilterModel? searchFilterModel, bool isStore) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Item>?> getSuggestedItems() async => null;

  @override
  Future<bool> saveSearchHistory(List<String> searchHistories) async => false;

  @override
  List<String> getSearchAddress() => [];

  @override
  Future<bool> clearSearchHistory() async => false;

  List<Item>? sortItemSearchList(
          List<Item>? allItemList,
          double upperValue,
          double lowerValue,
          int rating,
          bool veg,
          bool nonVeg,
          bool isAvailableItems,
          bool isDiscountedItems,
          int sortIndex) =>
      null;

  List<Store>? sortStoreSearchList(
          List<Store>? allStoreList,
          int storeRating,
          bool storeVeg,
          bool storeNonVeg,
          bool isAvailableStore,
          bool isDiscountedStore,
          int storeSortIndex) =>
      null;

  @override
  Future<SearchSuggestionModel?> getSearchSuggestions(
          String searchText) async =>
      null;

  @override
  Future<List<PopularCategoryModel?>?> getPopularCategories() async => null;

  @override
  Future<List<PopularCategoryModel?>?> getTrendingCategories() async => null;
}

class MockSplashServiceInterface implements SplashServiceInterface {
  @override
  Future<Response<dynamic>> getConfigData(
      {required DataSourceEnum source}) async {
    throw UnimplementedError();
  }

  @override
  ConfigModel? prepareConfigData(Response<dynamic> response) => null;

  @override
  Future<LandingModel?> getLandingPageData(
          {required DataSourceEnum source}) async =>
      null;

  @override
  Future<ModuleModel?> initSharedData() async => null;

  @override
  void disableIntro() {}

  @override
  bool? showIntro() => false;

  @override
  Future<void> setStoreCategory(int storeCategoryID) async {}

  @override
  Future<List<ModuleModel>?> getModules(
          {Map<String, String>? headers,
          required DataSourceEnum source}) async =>
      null;

  @override
  Future<void> setModule(ModuleModel? module) async {}

  @override
  Future<ModuleModel?> setCacheModule(ModuleModel? module) async => null;

  @override
  ModuleModel? getCacheModule() => null;

  @override
  ModuleModel? getModule() => null;

  @override
  Future<ResponseModel> subscribeEmail(String email) async {
    throw UnimplementedError();
  }

  @override
  bool getSavedCookiesData() => false;

  @override
  Future<void> saveCookiesData(bool data) async {}

  @override
  void cookiesStatusChange(String? data) {}

  @override
  bool getAcceptCookiesStatus(String data) => false;

  @override
  bool getSuggestedLocationStatus() => false;

  @override
  Future<void> saveSuggestedLocationStatus(bool data) async {}

  @override
  bool getReferBottomSheetStatus() => false;

  @override
  Future<void> saveReferBottomSheetStatus(bool data) async {}
}

class MockLanguageServiceInterface implements LanguageServiceInterface {
  @override
  bool setLTR(Locale locale) => true;

  @override
  void updateHeader(Locale locale, int? moduleId) {}

  @override
  Locale getLocaleFromSharedPref() => const Locale('en', 'US');

  @override
  int setSelectedIndex(List languages, Locale locale) => 0;

  @override
  void saveLanguage(Locale locale) {}

  @override
  void saveCacheLanguage(Locale locale) {}

  @override
  Locale getCacheLocaleFromSharedPref() => const Locale('en', 'US');
}

class MockFavouriteServiceInterface implements FavouriteServiceInterface {
  @override
  Future<Response<dynamic>> getFavouriteList() async {
    throw UnimplementedError();
  }

  @override
  Future<ResponseModel> addFavouriteList(int? id, bool isStore) async {
    throw UnimplementedError();
  }

  @override
  Future<ResponseModel> removeFavouriteList(int? id, bool isStore) async {
    throw UnimplementedError();
  }

  @override
  List<Item?> wishItemList(Item item) => [];

  @override
  List<int?> wishItemIdList(Item item) => [];

  @override
  List<Store?> wishStoreList(dynamic store) => [];

  @override
  List<int?> wishStoreIdList(dynamic store) => [];
}

void main() {
  group('StoreScreen Instant UI Tests', () {
    late StoreController storeController;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Get.testMode = true;

      // Register ThemeController first
      if (!Get.isRegistered<ThemeController>()) {
        Get.put<ThemeController>(
          ThemeController(sharedPreferences: prefs),
          permanent: true,
        );
      }
    });

    setUp(() {
      // Reset Get before each test
      Get.reset();
      Get.testMode = true;

      storeController = StoreController(
        storeServiceInterface: MockStoreServiceInterface(),
      );
      Get.put<StoreController>(storeController, permanent: true);

      if (!Get.isRegistered<CategoryController>()) {
        Get.put<CategoryController>(
          CategoryController(
            categoryServiceInterface: MockCategoryServiceInterface(),
            searchServiceInterface: MockSearchServiceInterface(),
          ),
          permanent: true,
        );
      }

      if (!Get.isRegistered<SplashController>()) {
        Get.put<SplashController>(
          SplashController(
              splashServiceInterface: MockSplashServiceInterface()),
          permanent: true,
        );
      }

      // Add LocalizationController
      if (!Get.isRegistered<LocalizationController>()) {
        Get.put<LocalizationController>(
          LocalizationController(
              languageServiceInterface: MockLanguageServiceInterface()),
          permanent: true,
        );
      }

      // Add FavouriteController
      if (!Get.isRegistered<FavouriteController>()) {
        Get.put<FavouriteController>(
          FavouriteController(
              favouriteServiceInterface: MockFavouriteServiceInterface()),
          permanent: true,
        );
      }
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets(
        'should render without error when widget.store is provided even if storeController.store is null',
        (WidgetTester tester) async {
      // Arrange: Create a Store with name and logo
      final testStore = Store(
        id: 1,
        name: 'Test Restaurant',
        logoFullUrl: 'https://example.com/logo.png',
        active: true,
      );

      // Act: Build StoreScreen with widget.store populated but controller.store null
      await tester.pumpWidget(
        GetMaterialApp(
          home: StoreScreen(
            store: testStore,
            fromModule: false,
          ),
        ),
      );

      await tester.pump();

      // Assert: Error message should NOT appear (verifies fallback logic works)
      // The fallback: displayStore = storeController.store ?? widget.store
      // should use widget.store when controller.store is null
      expect(
        find.text('failed_to_load_store'.tr),
        findsNothing,
        reason: 'Error message should not appear when widget.store is provided',
      );

      // Verify no full-screen CircularProgressIndicator
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason:
            'Should not show full-screen loading indicator when widget.store is provided',
      );
    });

    testWidgets(
        'should use widget.store fallback when storeController.store is null',
        (WidgetTester tester) async {
      // Arrange: Create a Store
      final testStore = Store(
        id: 1,
        name: 'My Test Store',
        logoFullUrl: 'https://example.com/store-logo.jpg',
        active: true,
      );

      // Act: Build StoreScreen
      await tester.pumpWidget(
        GetMaterialApp(
          home: StoreScreen(
            store: testStore,
            fromModule: false,
          ),
        ),
      );

      await tester.pump();

      // Assert: Fallback logic should prevent error state
      expect(
        find.text('failed_to_load_store'.tr),
        findsNothing,
        reason: 'Fallback to widget.store should prevent error state',
      );
    });

    testWidgets(
        'should not show CircularProgressIndicator as full-screen loader when widget.store is provided',
        (WidgetTester tester) async {
      // Arrange: Create a Store
      final testStore = Store(
        id: 1,
        name: 'Quick Load Store',
        logoFullUrl: 'https://example.com/logo.png',
        active: true,
      );

      // Act: Build StoreScreen
      await tester.pumpWidget(
        GetMaterialApp(
          home: StoreScreen(
            store: testStore,
            fromModule: false,
          ),
        ),
      );

      await tester.pump();

      // Assert: No full-screen CircularProgressIndicator
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason:
            'Should not show full-screen CircularProgressIndicator when widget.store is provided',
      );
    });
  });
}
