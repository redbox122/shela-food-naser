// ignore_for_file: camel_case_types, file_names, non_constant_identifier_names, avoid_print, override_on_non_overriding_member, prefer_final_fields, unused_local_variable

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/offers/domain/services/offers_service_interface.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

import '../../item/domain/models/item_model.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import '../../item/domain/repositories/item_repository_interface.dart';

class Offers_Controller extends GetxController implements GetxService {
  final Offers_ServiceInterface offersServiceInterface;
  final ItemRepositoryInterface itemRepository;
  Offers_Controller({
    required this.offersServiceInterface,
    required this.itemRepository,
  });

  @override
  void onInit() {
    super.onInit();
    // ⚡ PERFORMANCE: Skip auto-fetch when using v2 unified endpoint
    // HomeUnifiedController is already handling offers data loading
    // This prevents two systems from fighting over the same widget
    if (AppConstants.useBffV2Endpoint) {
      if (kDebugMode) {
        print(
            '✅ Offers_Controller: Skipping onInit fetch (v2 endpoint enabled - HomeUnifiedController handles data)');
      }
      return;
    }
    // For v1 endpoint, auto-fetch is handled elsewhere (not in onInit)
  }

  //

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isItemsLoading = false;
  bool get isItemsLoading => _isItemsLoading;

  OffersModel? offersMode;
  int _offset = 1;
  int get offset => _offset;

  int? _pageSize;
  int? get pageSize => _pageSize;

  List<Item>? _offersItemList;
  List<Item>? get offersItemList => _offersItemList;

  // Search and filter properties
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String _searchText = '';
  String get searchText => _searchText;

  // Live search properties
  List<Item>? _liveSearchResults;
  List<Item>? get liveSearchResults => _liveSearchResults;

  bool _isLiveSearching = false;
  bool get isLiveSearching => _isLiveSearching;

  String _type = 'all';
  String get type => _type;

  bool _isVertical = false;
  bool get isVertical => _isVertical;

  bool _isPriceAscending = true;
  bool get isPriceAscending => _isPriceAscending;

  int _categoryIndex = 0;
  int get categoryIndex => _categoryIndex;

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  // Multiple category selection
  List<int> _selectedCategoryIds = [];
  List<int> get selectedCategoryIds => _selectedCategoryIds;

  bool _isFilterModalOpen = false;
  bool get isFilterModalOpen => _isFilterModalOpen;

  ItemModel? _offersSearchItemModel;
  ItemModel? get offersSearchItemModel => _offersSearchItemModel;

  // Cache for offers items by offer ID
  Map<String, List<Item>> _offersItemsCache = {};
  Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 10);

  // Live search debouncing
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  // Deep equality checker for offers data
  static const DeepCollectionEquality _deepEquality =
      DeepCollectionEquality();

  /// Check if two OffersModel instances have the same data content
  bool _areOffersEqual(OffersModel? oldOffers, OffersModel? newOffers) {
    if (oldOffers == null && newOffers == null) return true;
    if (oldOffers == null || newOffers == null) return false;
    if (oldOffers.success != newOffers.success) return false;
    if (oldOffers.message != newOffers.message) return false;
    if (oldOffers.data.length != newOffers.data.length) return false;
    // Compare data lists using deep equality on their JSON representations
    final oldDataJson = oldOffers.data.map((d) => d.toJson()).toList();
    final newDataJson = newOffers.data.map((d) => d.toJson()).toList();
    return _deepEquality.equals(oldDataJson, newDataJson);
  }

  // -----------------------------------------------------------------------------------------------
  Future<OffersModel?> getOffers({int? specificModuleId}) async {
    // ⚠️ CRITICAL: Prevent duplicate concurrent calls
    if (_isLoading) {
      print('⚠️ Offers: Already loading, skipping duplicate call');
      return offersMode;
    }

    // ⚡ CACHE FIRST: Check comprehensive cache before making API calls
    if (offersMode == null) {
      try {
        final cachedData =
            await ComprehensiveHomeCacheManager.loadAllHomeData();
        if (cachedData.containsKey('offers')) {
          final offersData = cachedData['offers'];
          if (offersData is Map<String, dynamic> &&
              offersData['data'] != null) {
            final dataList = offersData['data'];
            if (dataList is List) {
              final cachedOffersList = dataList
                  .map((json) => Datum.fromJson(json as Map<String, dynamic>))
                  .toList();
              if (cachedOffersList.isNotEmpty) {
                print(
                    '✅ Offers_Controller: Loading ${cachedOffersList.length} offers from comprehensive cache');
                offersMode = OffersModel(
                  success: (offersData['success'] as bool?) ?? false,
                  data: cachedOffersList,
                  message: (offersData['message'] as String?) ?? '',
                );
                update();
                return offersMode;
              }
            }
          }
        }
      } catch (e) {
        print(
            '⚠️ Offers_Controller: Error loading from comprehensive cache: $e');
      }
    }

    try {
      // ⚡ Save old offers BEFORE any changes to compare later
      final oldOffers = offersMode;

      // 🔧 CRITICAL FIX: Only set loading to true if we don't have existing offers
      // If offers already exist, keep it in "Success" state during silent refresh
      final hasExistingOffers =
          offersMode != null && offersMode!.data.isNotEmpty;
      if (hasExistingOffers) {
        // Silent refresh - don't show loading state
        _isLoading = false;
        if (kDebugMode) {
          print(
              '✅ Offers_Controller: Silent refresh - preserving Success state (has existing offers)');
        }
      } else {
        // First load - show loading state
        _isLoading = true;
        update();
      }

      // ⚠️ CRITICAL: Use current module ID for offers API call
      final apiClient = Get.find<ApiClient>();
      final splashController = Get.find<SplashController>();

      // Use specific module ID if provided, otherwise use current selected module
      final moduleIdForOffers = specificModuleId ?? splashController.module?.id;
      if (moduleIdForOffers == null) {
        print('⚠️ Offers: No module selected, skipping offers load');
        _isLoading = false;
        
        // 🔒 PROTECTION: Don't clear existing offers if no module selected
        // Preserve cache data if it exists
        if (hasExistingOffers) {
          if (kDebugMode) {
            print(
                '🔒 Offers_Controller: No module selected, preserving existing offers (${offersMode!.data.length} offers)');
          }
          return offersMode; // Return existing data without modifying state
        }
        
        // Only set empty if we had no existing data
        offersMode = OffersModel(
            success: false, data: [], message: 'No module selected');
        update();
        return offersMode;
      }

      final AddressModel? addressModel = AddressHelper.getUserAddressFromSharedPref();
      final sharedPreferences = Get.find<SharedPreferences>();

      apiClient.updateHeader(
        apiClient.token,
        addressModel?.zoneIds,
        addressModel?.areaIds,
        sharedPreferences.getString(AppConstants.languageCode),
        moduleIdForOffers, // Use specific or current module ID
        addressModel?.latitude,
        addressModel?.longitude,
      );
      final moduleName = specificModuleId != null
          ? '(specific module)'
          : "(current module: ${splashController.module?.moduleName ?? 'unknown'})";
      print('✅ Offers: Set moduleId=$moduleIdForOffers in headers $moduleName');

      // ⚠️ OPTIMIZED: Reduced timeout from 30s to 10s for better UX
      // Most API calls should complete within 3-5 seconds
      final loadedOffers = await offersServiceInterface.getOffers().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Offers loading timed out after 10 seconds');
          return OffersModel(
              success: false, data: [], message: 'Request timed out');
        },
      );
      // 🔒 PROTECTION: Validate API response before updating state
      // If API returns invalid/empty data but we have existing offers, preserve them
      final hasValidResponse = loadedOffers.success == true && 
                               loadedOffers.data.isNotEmpty;
      // Reuse hasExistingOffers from earlier in the function
      final hasValidExistingOffers = oldOffers != null && 
                                     oldOffers.data.isNotEmpty;

      // 🔥 CRITICAL: Don't override cache with invalid/empty API response
      if (!hasValidResponse && hasValidExistingOffers) {
        _isLoading = false;
        // Keep existing offersMode - don't update or trigger rebuild
        if (kDebugMode) {
          print(
              '🔒 Offers_Controller: API returned invalid/empty response, preserving existing offers (${oldOffers.data.length} offers)');
        }
        return oldOffers; // Return existing data without modifying state
      }

      // If API response is valid, proceed with update
      if (hasValidResponse) {
        print(
            '✅ Offers: Data loaded - success: ${loadedOffers.success}, count: ${loadedOffers.data.length}');
        if (loadedOffers.data.isNotEmpty) {
          print('📦 Offers: First offer: ${loadedOffers.data[0].name}');
        }
      } else {
        print('⚠️ Offers: No offers found in response');
      }

      // Only update offersMode and trigger UI update if data actually changed
      if (!_areOffersEqual(oldOffers, loadedOffers)) {
        offersMode = loadedOffers;
        _isLoading = false;
        update();
        if (kDebugMode) {
          print('🔄 Offers_Controller: Data changed, UI updated');
        }
      } else {
        // Data unchanged - keep existing offersMode and don't trigger UI update to prevent flicker
        _isLoading = false;
        // Don't call update() - this prevents unnecessary UI rebuild/flicker
        if (kDebugMode) {
          print(
              '✅ Offers_Controller: Data unchanged (deep equality check), skipping UI update to prevent flicker');
        }
      }
    } catch (e) {
      print('❌ Error loading offers: $e');
      _isLoading = false;
      
      // 🔒 PROTECTION: Don't clear existing offers on error
      // If we have existing offers in cache, preserve them instead of clearing
      final hasExistingOffers = offersMode != null && offersMode!.data.isNotEmpty;
      if (hasExistingOffers) {
        // Keep existing offersMode - don't update or trigger rebuild
        if (kDebugMode) {
          print(
              '🔒 Offers_Controller: Error occurred, preserving existing offers (${offersMode!.data.length} offers)');
        }
        return offersMode; // Return existing data without modifying state
      }
      
      // Only set empty offers if we had no existing data
      offersMode = OffersModel(
          success: false, data: [], message: 'Failed to load offers');
      update();
    }
    return offersMode;
  }

  /// Set offers data directly from cache (handles both OffersModel and raw JSON)
  void setOffersFromCache(dynamic data) {
    if (data == null) return;

    try {
      final oldOffers = offersMode;
      OffersModel? newOffers;

      if (data is OffersModel) {
        // Already deserialized model object
        newOffers = data;
        offersMode = data;
      } else if (data is Map<String, dynamic>) {
        // Raw JSON from disk cache - deserialize it
        newOffers = OffersModel.fromJson(data);
        offersMode = newOffers;
      } else {
        print(
            '⚠️ Offers_Controller: Unexpected data type: ${data.runtimeType}');
        return;
      }

      // 🔧 FIX: Set isLoading to false to prevent skeleton from appearing
      _isLoading = false;

      // Only update UI if data actually changed
      if (!_areOffersEqual(oldOffers, newOffers)) {
        update();
        if (kDebugMode) {
          print(
              '✅ Offers_Controller: Loaded ${offersMode?.data.length ?? 0} offers from cache - data changed, UI updated');
        }
      } else {
        if (kDebugMode) {
          print(
              '✅ Offers_Controller: Loaded ${offersMode?.data.length ?? 0} offers from cache - data unchanged (deep equality check), skipping UI update');
        }
      }
    } catch (e) {
      print('❌ Offers_Controller: Error setting offers from cache: $e');
    }
  }

  /// ⚡ BFF API v2: Set offers from home-unified endpoint
  /// ⚡ PERFORMANCE: Skip parsing if offers already exist in cache and are identical
  void setOffersFromBootstrap(List<OffersModel> offers) {
    // 🔧 TASK 2: Data Integrity Check - preserve existing data if new offers are empty
    if (offers.isEmpty) {
      if (kDebugMode) {
        print(
            '⚠️ Offers_Controller.setOffersFromBootstrap: Received empty offers list. Preserving existing data.');
      }
      _isLoading = false;
      return; // 🔥 ELITE MOVE: Don't kill the UI if the API is starving
    }

    final newOffers = offers.first;
    if (newOffers.data.isEmpty) {
      if (kDebugMode) {
        print(
            '⚠️ Offers_Controller.setOffersFromBootstrap: Received empty offers from Bootstrap. Preserving existing data.');
      }
      _isLoading = false;
      return; // 🔥 ELITE MOVE: Don't kill the UI if the API is starving
    }

    // Use the first offer model (unified endpoint returns list)
    final oldOffers = offersMode;

    // ⚡ PERFORMANCE: Early exit if offers already exist and are identical
    // Prevents unnecessary parsing and UI rebuilds
    if (offersMode != null) {
      // Quick check: If counts match, do deep equality check before parsing
      if (offersMode!.data.length == newOffers.data.length) {
        if (_areOffersEqual(offersMode, newOffers)) {
          if (kDebugMode) {
            print(
                '✅ Offers_Controller: setOffersFromBootstrap - Data unchanged (deep equality), skipping parse and update');
          }
          _isLoading = false;
          return; // Exit early - no need to parse or update UI
        }
      }
    }

    // 🔧 SEAL: CRITICAL LOCK - if new offers are empty but we have existing data, preserve it
    // This prevents broken 304/empty responses from hiding your offers
    if (newOffers.data.isEmpty &&
        oldOffers != null &&
        oldOffers.data.isNotEmpty) {
      if (kDebugMode) {
        print(
            '🔒 Offers_Controller: New offers are empty, preserving pre-warmed data (${oldOffers.data.length} offers)');
      }
      _isLoading = false;
      return; // Don't overwrite with empty data
    }

    // 🔧 SEAL: Additional guard - prevent empty responses from clearing existing offers
    // This is the lock requested: if (newOffers.isEmpty && _offersList.isNotEmpty) return;
    final currentOffersList = offersMode?.data ?? [];
    if (newOffers.data.isEmpty && currentOffersList.isNotEmpty) {
      if (kDebugMode) {
        print(
            '🔒 Offers_Controller: Empty new offers detected, preserving existing offers (${currentOffersList.length} offers)');
      }
      _isLoading = false;
      return; // Don't clear existing offers with empty response
    }

    offersMode = newOffers;

    // 🔧 FIX: Set isLoading to false to prevent skeleton from appearing
    _isLoading = false;

    // Only update UI if data actually changed
    if (!_areOffersEqual(oldOffers, newOffers)) {
      update(['offers']); // 🔧 FIX: Use specific ID for offers widget re-render
      if (kDebugMode) {
        print(
            '✅ Offers_Controller: Injected ${offersMode?.data.length ?? 0} offers');
      }
    } else {
      if (kDebugMode) {
        print(
            '✅ Offers_Controller: Offers set from bootstrap (${offersMode?.data.length ?? 0} offers) - data unchanged (deep equality check), skipping UI update');
      }
    }
  }

  Future<void> getOffersItemList({
    required String? id,
    required int offset,
    int limit = 20,
    bool notify = true,
  }) async {
    // 🔧 TASK 1: Prevent double-fetch - check if already loading
    if (_isItemsLoading) {
      if (kDebugMode) {
        print(
            '⚠️ Offers_Controller: getOffersItemList already in progress, skipping duplicate call (id: $id, offset: $offset)');
      }
      return;
    }

    // Check cache first for offset 1
    if (offset == 1 && id != null) {
      if (_isCacheValid(id)) {
        _offersItemList = List.from(_offersItemsCache[id] ?? []);
        _isLoading = false;
        update();
        return;
      }
    }

    if (offset == 1) {
      _offersItemList = null;
      if (notify) {
        update();
      }
    }

    _isItemsLoading = true;
    update();

    final ItemModel? brandItemModel = await offersServiceInterface.getOffersItem(
        id: id, offset: offset, limit: limit);
      if (brandItemModel != null) {
      if (offset == 1) {
        _offersItemList = [];
        // Extract categories from the response for filtering
        setCategoryListFromResponse(brandItemModel);
        // Cache the results for offset 1
        if (id != null) {
          _offersItemsCache[id] = List.from(brandItemModel.items!);
          _cacheTimestamps[id] = DateTime.now();
        }
      }

      // Only add items if they're not already present (avoid duplicates)
      if (brandItemModel.items != null && brandItemModel.items!.isNotEmpty) {
        // Check if items are already loaded to prevent duplicates
        _offersItemList ??= [];

        // For pagination, only add new items that aren't already in the list
        for (final newItem in brandItemModel.items!) {
          final bool itemExists = _offersItemList!
              .any((existingItem) => existingItem.id == newItem.id);
          if (!itemExists) {
            _offersItemList!.add(newItem);
          }
        }
      }

      _pageSize = brandItemModel.totalSize;
      _isItemsLoading = false;
    } else {
      _isItemsLoading = false;
    }
    update();
  }

  // Check if cache is still valid
  bool _isCacheValid(String id) {
    if (!_offersItemsCache.containsKey(id) ||
        !_cacheTimestamps.containsKey(id)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[id]!;
    final now = DateTime.now();
    return now.difference(cacheTime) < _cacheValidityDuration;
  }

  // Clear cache for specific offer
  void clearOfferCache(String id) {
    _offersItemsCache.remove(id);
    _cacheTimestamps.remove(id);
  }

  // Clear all cache
  void clearAllCache() {
    _offersItemsCache.clear();
    _cacheTimestamps.clear();
  }

  // Reset all loading states
  void resetLoadingStates({bool notify = true}) {
    _isLoading = false;
    _isItemsLoading = false;
    _isSearching = false;
    _isLiveSearching = false;
    _isFilterModalOpen = false;
    if (notify) {
      update();
    }
  }

  /// ⚡ TITAN BOARD: Reset controller to default state without deleting instance
  /// Used during module switching to preserve controller in memory
  Future<void> resetToDefault() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Offers_Controller: Resetting to default state');
      }

      // Clear model
      offersMode = null;

      // Clear all lists
      _offersItemList = null;
      _categoryList = null;
      _liveSearchResults = null;

      // Reset state flags
      _isLoading = false;
      _isItemsLoading = false;
      _isSearching = false;
      _isLiveSearching = false;

      // Reset pagination
      _offset = 1;
      _pageSize = null;

      // Clear cache
      _offersItemsCache = {};
      _cacheTimestamps = {};

      // Reset filters
      _type = 'all';
      _isVertical = false;
      _searchText = '';
      _selectedCategoryIds = [];
      _isFilterModalOpen = false;

      // Reset indices
      _categoryIndex = 0;

      // Cancel any active timers
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = null;

      if (kDebugMode) {
        debugPrint('✅ Offers_Controller: Reset to default state completed');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Offers_Controller.resetToDefault: Error - $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  // Reset offers loading state specifically
  void resetOffersLoading() {
    _isLoading = false;
    offersMode = null;
    update();
  }

  void showBottomLoader() {
    _isItemsLoading = true;
    update();
  }

  // Search and filter methods
  void setVerticalItems(bool value) {
    _isVertical = value;
    update();
  }

  void setPrice(bool value) {
    _isPriceAscending = value;
    // ❌ REMOVED: Local sorting - now handled by API via sortOrder parameter
    // When price sort changes, reload from API with new sortOrder
    if (_currentOfferId != null) {
      getOffersItemListWithFilters(
        id: _currentOfferId,
        categoryId: _categoryIndex > 0 && _categoryList != null && _categoryList!.isNotEmpty
            ? _categoryList![_categoryIndex].id.toString()
            : null,
        sortBy: 'price',
        sortOrder: _isPriceAscending ? 'asc' : 'desc',
      );
    }

    update();
  }

  void changeSearchStatus({bool isUpdate = true}) {
    if (!_isSearching) {
      _isSearching = true;
    } else {
      _isSearching = false;
      _offersSearchItemModel = null;
    }
    if (isUpdate) {
      update();
    }
  }

  void initSearchData() {
    _offersSearchItemModel = ItemModel(items: []);
    _searchText = '';
  }

  // Live search functionality
  void performLiveSearch(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      clearLiveSearch();
      return;
    }

    // Set new timer with debounce
    _searchDebounceTimer = Timer(_searchDebounceDelay, () async {
      // ✅ CRITICAL: Reset state before new search (NO CACHE)
      resetSearchState();
      
      _isLiveSearching = true;
      _isSearching = true;
      _searchText = query.trim();

      // ✅ Use API search instead of local filtering
      if (_currentOfferId != null) {
        try {
          // Use ItemRepository.searchItems for live search
          final itemModel = await itemRepository.searchItems(
            name: query,
            sortBy: _isPriceAscending ? 'price' : null,
            sortOrder: _isPriceAscending ? 'asc' : 'desc',
            page: 1,
            limit: 50,
          );
          
          if (itemModel != null && itemModel.items != null) {
            _liveSearchResults = List<Item>.from(itemModel.items ?? []);
          } else {
            _liveSearchResults = [];
          }
        } catch (e) {
          debugPrint('Error in live search: $e');
          _liveSearchResults = [];
        }
      } else {
        _liveSearchResults = [];
      }

      update();
    });
  }

  // ❌ REMOVED: _filterItemsBySearchQuery - now using API search instead

  // Clear live search
  void clearLiveSearch() {
    _searchDebounceTimer?.cancel();
    _liveSearchResults = null;
    _isLiveSearching = false;
    _isSearching = false;
    _searchText = '';
    print('🔍 Live search cleared');
    update();
  }

  void setCategoryList(String offerId) {
    // Initialize with "All Products" option
    _categoryList = [];
    _categoryList!.add(CategoryModel(id: 0, name: 'all_products'.tr));
  }

  void setCategoryListFromResponse(ItemModel? itemModel) {
    _categoryList = [];
    _categoryList!.add(CategoryModel(id: 0, name: 'all_products'.tr));

    print('🔍 Extracting categories from offers response...');
    print('📊 Categories in response: ${itemModel?.categories?.length ?? 0}');
    print('📊 Items in response: ${itemModel?.items?.length ?? 0}');

    if (itemModel?.categories != null && itemModel!.categories!.isNotEmpty) {
      // Add categories from the API response if available
      print('✅ Using categories from API response');
      for (final category in itemModel.categories!) {
        _categoryList!.add(CategoryModel(
          id: category.id,
          name: category.name,
          parentId: category.parentId,
          position: category.position,
          productsCount: category.productsCount ?? 0,
          createdAt: category.createdAt,
          updatedAt: category.updatedAt,
        ));
      }
    } else if (itemModel?.items != null && itemModel!.items!.isNotEmpty) {
      // Extract categories from products if no categories array in response
      print('✅ Extracting categories from products');
      final Map<int, String> uniqueCategories = {};

      for (final item in itemModel.items!) {
        if (item.categoryId != null && item.categoryId! > 0) {
          // Get category name from category_ids array in the item
          if (item.categoryIds != null && item.categoryIds!.isNotEmpty) {
            for (final catData in item.categoryIds!) {
              if (catData.id != null &&
                  catData.name != null &&
                  catData.id! > 0) {
                if (!uniqueCategories.containsKey(catData.id!)) {
                  uniqueCategories[catData.id!] = catData.name!;
                }
              }
            }
          }
        }
      }

      print(
          '📊 Found ${uniqueCategories.length} unique categories from products');

      // Add unique categories to the list
      uniqueCategories.forEach((id, name) {
        _categoryList!.add(CategoryModel(
          id: id,
          name: name,
        ));
      });
    } else {
      // Fallback to global categories if no data available
      print('⚠️ No categories found, using global categories');
      if (Get.find<CategoryController>().categoryList != null) {
        for (final category in Get.find<CategoryController>().categoryList!) {
          _categoryList!.add(category);
        }
      }
    }

    print('📊 Total categories available: ${_categoryList!.length}');
    for (final cat in _categoryList!) {
      print('  - ${cat.id}: ${cat.name}');
    }
  }

  void setCategoryIndex(int index, {bool itemSearching = false}) {
    _categoryIndex = index;
    print(
        '🔍 Category filter selected: index=$index, itemSearching=$itemSearching');

    if (itemSearching) {
      _offersSearchItemModel = null;
      if (_searchText.isNotEmpty && _currentOfferId != null) {
        getOffersSearchItemList(_searchText,
            offerId: _currentOfferId);
      }
    } else {
      // ❌ REMOVED: Frontend filtering - now always use API
      // Always call API with category filter
      _offersItemList = null;
      if (_currentOfferId != null) {
        if (index > 0 && _categoryList != null && _categoryList!.isNotEmpty) {
          print(
              '📡 Making API call for category: ${_categoryList![index].name}');
          getOffersItemListWithFilters(
            id: _currentOfferId,
            categoryId: _categoryList![index].id.toString(),
            sortBy: 'price',
            sortOrder: _isPriceAscending ? 'asc' : 'desc',
          );
        } else {
          print('📡 Making API call for all products');
          getOffersItemList(id: _currentOfferId, offset: 1);
        }
      }
    }
    update();
  }

  // ❌ REMOVED: _applyPriceSorting - sorting now handled by API
  // ❌ REMOVED: _filterItemsByCategory - filtering now handled by API

  // Reset all filters and reload from API
  void resetFilters() {
    _categoryIndex = 0;
    _isPriceAscending = true;
    _selectedCategoryIds.clear();
    // Clear live search when resetting filters
    _liveSearchResults = null;
    _isLiveSearching = false;
    _isSearching = false;
    _searchText = '';
    // ❌ REMOVED: Local filtering - reload from API instead
    if (_currentOfferId != null) {
      getOffersItemList(id: _currentOfferId, offset: 1);
      print('✅ Filters reset - reloading from API');
    } else {
      update();
    }
  }

  // Filter modal methods
  void toggleFilterModal() {
    _isFilterModalOpen = !_isFilterModalOpen;
    update();
  }

  void closeFilterModal() {
    _isFilterModalOpen = false;
    update();
  }

  // Category selection methods
  void toggleCategorySelection(int categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    print('📊 Selected categories: $_selectedCategoryIds');
    update();
  }

  void applyCategoryFilter() {
    // ❌ REMOVED: Local filtering - use API instead
    if (_currentOfferId != null) {
      if (_selectedCategoryIds.isEmpty) {
        // Show all items if no categories selected
        getOffersItemList(id: _currentOfferId, offset: 1);
        print('✅ Showing all items (no categories selected)');
      } else {
        // TODO: Support multiple categories in API call
        // For now, use first selected category
        final categoryId = _selectedCategoryIds.first.toString();
        getOffersItemListWithFilters(
          id: _currentOfferId,
          categoryId: categoryId,
          sortBy: 'price',
          sortOrder: _isPriceAscending ? 'asc' : 'desc',
        );
        print('✅ Filtered by ${_selectedCategoryIds.length} categories');
      }
    }
    closeFilterModal();
  }

  // ❌ REMOVED: _filterItemsByMultipleCategories - filtering now handled by API

  String? _currentOfferId;

  // ✅ Reset search state (NO CACHE for search)
  void resetSearchState() {
    _offset = 1;
    _isLoading = false;
    _isItemsLoading = false;
    _offersSearchItemModel = null;
    _liveSearchResults = null;
    _searchText = '';
    _isSearching = false;
    _isLiveSearching = false;
    update();
  }

  Future<void> getOffersSearchItemList(String searchText,
      {String? offerId, int offset = 1}) async {
    if (searchText.isEmpty) {
      showCustomSnackBar('write_item_name'.tr);
    } else {
      // ✅ CRITICAL: Reset state before new search (NO CACHE)
      if (offset == 1) {
        resetSearchState();
      }
      
      _isSearching = true;
      _searchText = searchText;
      _currentOfferId = offerId;
      _isItemsLoading = true;
      update();

      _isItemsLoading = true;
      update();

      if (offerId == null) {
        _isItemsLoading = false;
        update();
        return;
      }

      final ItemModel? offersSearchItemModel =
          await offersServiceInterface.getOffersSearchItemList(
        searchText,
        offerId,
        offset,
        type,
        (_categoryList != null &&
                _categoryList!.isNotEmpty &&
                _categoryIndex != 0)
            ? _categoryList![_categoryIndex].id ?? 0
            : 0,
      );

      if (offersSearchItemModel != null) {
        if (offset == 1) {
          _offersSearchItemModel = offersSearchItemModel;
          // Apply price sorting to search results
        // ❌ REMOVED: Local price sorting - should be handled by API
        } else {
          if (offersSearchItemModel.items != null &&
              offersSearchItemModel.items!.isNotEmpty) {
            _offersSearchItemModel!.items!.addAll(offersSearchItemModel.items!);
            // ❌ REMOVED: Local price sorting - should be handled by API via sortOrder
          }
          _offersSearchItemModel!.totalSize = offersSearchItemModel.totalSize;
          _offersSearchItemModel!.offset = offersSearchItemModel.offset;
        }
      } else {
        // Handle null response (API error)
        if (offset == 1) {
          _offersSearchItemModel = ItemModel(items: []);
        }
        print('❌ Failed to load search results - API returned null');
      }

      _isItemsLoading = false;
      update();
    }
  }

  Future<void> getOffersItemListWithFilters({
    int offset = 1,
    int limit = 20,
    String? id,
    bool notify = false,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  }) async {
    _offset = offset;
    _currentOfferId = id;

    if (offset == 1) {
      _offersItemList = null;
      if (notify) {
        update();
      }
    }

    _isItemsLoading = true;
    update();

    final ItemModel? brandItemModel =
        await offersServiceInterface.getOffersItemWithFilters(
      id: id,
      offset: offset,
      limit: limit,
      categoryId: categoryId,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

      if (brandItemModel != null) {
      if (offset == 1) {
        _offersItemList = [];
        // Extract categories from the response for filtering
        setCategoryListFromResponse(brandItemModel);
      }
      if (brandItemModel.items != null && brandItemModel.items!.isNotEmpty) {
        _offersItemList!.addAll(brandItemModel.items!);
        // ❌ REMOVED: Local price sorting - handled by API via sortOrder
      }
      _pageSize = brandItemModel.totalSize;
      _isItemsLoading = false;
    } else {
      // Handle null response (API error) - fallback to regular offers API
      if (offset == 1) {
        _offersItemList = [];
        print('❌ Filter API failed, falling back to regular offers API');
        // Try to load regular offers as fallback
        await getOffersItemList(
            id: id, offset: offset, limit: limit, notify: notify);
        return;
      }
      _isItemsLoading = false;
      print('❌ Failed to load offers items with filters - API returned null');
    }
    update();
  }

  /// Set offer data from bootstrap endpoint
  void setOfferDataFromBootstrap(OffersModel offers) {
    final oldOffers = offersMode;
    offersMode = offers;

    // Only update UI if data actually changed
    if (!_areOffersEqual(oldOffers, offers)) {
      update();
      if (kDebugMode) {
        print(
            '✅ OffersController: Offer data set from bootstrap (${offers.data.length} offers) - data changed, UI updated');
      }
    } else {
      if (kDebugMode) {
        print(
            '✅ OffersController: Offer data set from bootstrap (${offers.data.length} offers) - data unchanged (deep equality check), skipping UI update');
      }
    }
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    resetLoadingStates(notify: false);
    super.onClose();
  }
}
