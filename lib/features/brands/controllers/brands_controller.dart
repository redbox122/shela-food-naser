import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/brands/domain/services/brands_service_interface.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/core/isolate/json_isolate_helper.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/core/api/api_scheduler.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:collection/collection.dart';
import 'package:sixam_mart/features/item/domain/repositories/item_repository_interface.dart';

class BrandsController extends GetxController implements GetxService {
  final BrandsServiceInterface brandsServiceInterface;
  final ItemRepositoryInterface itemRepository;
  final ApiScheduler _apiScheduler = ApiScheduler();
  static const int _itemsPerPage = 12;
  static const int _paginationBatchPages = 5;

  // Track active API calls for cancellation
  CancellationToken? _currentBrandItemsToken;
  CancellationToken? _currentCategoriesToken;

  BrandsController({
    required this.brandsServiceInterface,
    required this.itemRepository,
  });

  List<BrandModel>? _brandList;
  List<BrandModel>? get brandList => _brandList;

  // Deep equality checker for brands
  static const DeepCollectionEquality _deepEquality = DeepCollectionEquality();

  List<Item>? _brandItems;
  List<Item>? get brandItems => _brandItems;

  // âŒ REMOVED: _originalBrandItemList - no longer needed for local filtering

  int _offset = 1;
  int get offset => _offset;

  int? _pageSize;
  int? get pageSize => _pageSize;

  // ðŸ”§ FIX: Track unique items count from last request to prevent infinite pagination
  int? _lastRequestUniqueItemsCount;
  int? get lastRequestUniqueItemsCount => _lastRequestUniqueItemsCount;
  bool _hasReachedEnd = false;
  bool get hasReachedEnd => _hasReachedEnd;
  bool _isEndReached = false;
  bool get isEndReached => _isEndReached;
  static final Set<int> _brandsReachedEnd = <int>{};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isBrandLoadError = false;
  bool get isBrandLoadError => _isBrandLoadError;

  // ðŸ”§ FIX: Separate flag for pagination loading (different from initial loading)
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  // âœ… Helper to check if there are more items to load
  // ðŸ”§ FIX: Check based on totalSize vs loaded items
  // pageSize represents total available items from API
  bool get hasMoreData {
    if (_hasReachedEnd) return false;
    if (_brandItems == null) return false;

    // Primary strategy: rely on backend total size when available
    if (_pageSize != null) {
      final loadedCount = _brandItems!.length;
      final totalAvailable = _pageSize!;
      return loadedCount < totalAvailable;
    }

    // Fallback strategy: when total size is missing, keep paginating
    // until a request marks the end (empty/duplicate-only response).
    if (_lastRequestUniqueItemsCount == null) {
      return true;
    }
    return _lastRequestUniqueItemsCount! > 0;
  }

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

  // Filter properties
  bool _isFilterModalOpen = false;
  bool get isFilterModalOpen => _isFilterModalOpen;

  final List<int> _selectedCategoryIds = [];
  List<int> get selectedCategoryIds => _selectedCategoryIds;

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  ItemModel? _brandSearchItemModel;
  ItemModel? get brandSearchItemModel => _brandSearchItemModel;

  int? _currentBrandId;
  int? get currentBrandId => _currentBrandId;

  // âš¡ TASK 1: Track last module ID for autonomous reset detection
  int? _lastModuleId;

  // âš¡ PERFORMANCE: Lock to prevent reset + load + reset cycles
  bool _isResetting = false;

  Timer? _searchDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      appLogger.info('[BRANDS_CTRL] onInit hash=$hashCode');
    }
  }

  Future<List<BrandModel>?> getBrandList(
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool forceRefresh = false}) async {
    // ðŸ” DEBUG: Entry point verification
    if (kDebugMode) {
      appLogger.debug(
          'ðŸš€ getBrandList() ENTRY - dataSource: $dataSource, forceRefresh: $forceRefresh');
    }

    // âš ï¸ CRITICAL: Handle case when HomeController is not registered
    HomeController? homeController;
    try {
      if (Get.isRegistered<HomeController>()) {
        homeController = Get.find<HomeController>();
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger
            .warning('âš ï¸ BrandsController: HomeController not available: $e');
      }
    }
    final businessSettings = homeController?.business_Settings;
    if (kDebugMode) {
      appLogger.debug(
          'ðŸ·ï¸ BrandsController: brandSection = ${businessSettings?.brandSection}');
    }

    // âœ… ØªØ­Ù‚Ù‚ Ù…Ù† ØªÙØ¹ÙŠÙ„ Ù‚Ø³Ù… Ø§Ù„Ø¹Ù„Ø§Ù…Ø§Øª Ø§Ù„ØªØ¬Ø§Ø±ÙŠØ©
    // âš¡ PERFORMANCE: Skip brands API call for pharmacy module (returns 404)
    // Pharmacy module doesn't have brands endpoint, so skip API call to prevent 404 noise
    try {
      if (Get.isRegistered<SplashController>()) {
        final splashController = Get.find<SplashController>();
        final currentModuleType =
            splashController.module?.moduleType.toString();
        if (currentModuleType == AppConstants.pharmacy) {
          if (kDebugMode) {
            appLogger.debug(
                'ðŸ·ï¸ BrandsController: Skipping brands API call for pharmacy module (endpoint not available)');
          }
          return _brandList; // Return existing data if any, otherwise null
        }
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger
            .warning('âš ï¸ BrandsController: Error checking module type: $e');
      }
      // Continue with brands loading if check fails
    }

    if (businessSettings?.brandSection?.toString() == '1') {
      // Load brands if:
      // 1. _brandList is null (first load)
      // 2. _brandList is empty AND dataSource is client (cache returned empty, need API call)
      // 3. dataSource is local (always load from cache)
      // 4. forceRefresh is true (force reload even if data exists)
      final isEmpty = _brandList != null && _brandList!.isEmpty;
      if (_brandList == null ||
          (isEmpty && dataSource == DataSourceEnum.client) ||
          dataSource == DataSourceEnum.local ||
          forceRefresh) {
        if (kDebugMode) {
          appLogger.debug(
              'ðŸ·ï¸ BrandsController: Loading brands with dataSource = $dataSource');
        }
        List<BrandModel>? brandList;

        // âš¡ CACHE FIRST: Check comprehensive cache before making API calls
        if (!forceRefresh && dataSource != DataSourceEnum.client) {
          try {
            final splashController = Get.find<SplashController>();
            final moduleId = splashController.module?.id;
            final cachedData =
                await ComprehensiveHomeCacheManager.loadAllHomeData(moduleId);
            if (cachedData.containsKey('brands')) {
              final brandData = cachedData['brands'] as Map<String, dynamic>;
              if (brandData['brandList'] != null) {
                final cachedBrandList = (brandData['brandList'] as List)
                    .map((json) =>
                        BrandModel.fromJson(json as Map<String, dynamic>))
                    .toList();
                if (cachedBrandList.isNotEmpty) {
                  if (kDebugMode) {
                    appLogger.info(
                        'âœ… BrandsController: Loading ${cachedBrandList.length} brands from comprehensive cache');
                  }
                  _prepareBandList(cachedBrandList);
                  return _brandList;
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              appLogger.warning(
                  'âš ï¸ BrandsController: Error loading from comprehensive cache: $e');
            }
          }
        }

        if (dataSource == DataSourceEnum.local) {
          brandList =
              await brandsServiceInterface.getBrandList(DataSourceEnum.local);
          if (kDebugMode) {
            appLogger.debug(
                'ðŸ·ï¸ BrandsController: Local brands loaded: ${brandList?.length ?? 0}');
          }
          _prepareBandList(brandList);

          // Don't automatically call API when loading from cache
          // The background refresh will handle API updates
        } else {
          brandList =
              await brandsServiceInterface.getBrandList(DataSourceEnum.client);
          if (kDebugMode) {
            appLogger.debug(
                'ðŸ·ï¸ BrandsController: Client brands loaded: ${brandList?.length ?? 0}');
          }
          _prepareBandList(brandList);
        }
      } else {
        if (kDebugMode) {
          appLogger.debug(
              'ðŸ·ï¸ BrandsController: Skipping load - brandList already populated and not forcing refresh');
        }
      }
    } else {
      if (kDebugMode) {
        appLogger.debug(
            'ðŸ·ï¸ BrandsController: Brand section disabled, skipping brands loading');
      }
    }
    return _brandList;
  }

  void _prepareBandList(List<BrandModel>? brandList) {
    if (brandList != null) {
      // âš¡ ZERO-FLICKER: Deep equality check - only update if data actually changed
      final oldBrandList = _brandList;
      final newBrandList = List<BrandModel>.from(brandList);

      if (oldBrandList != null) {
        final oldJson = oldBrandList.map((b) => b.toJson()).toList();
        final newJson = newBrandList.map((b) => b.toJson()).toList();
        if (_deepEquality.equals(oldJson, newJson)) {
          _isLoading = false;
          if (kDebugMode) {
            appLogger.debug(
                'âœ… BrandsController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
          }
          return;
        }
      }

      _brandList = [];
      _brandList!.addAll(brandList);
    }
    update();
  }

  /// Clear brand list when switching modules
  /// This ensures fresh data is loaded for the new module
  void clearBrandList() {
    _brandList = null;
    if (kDebugMode) {
      appLogger
          .debug('ðŸ§¹ BrandsController: Cleared brand list for module switch');
    }
    update();
  }

  /// âš¡ TASK 1: Autonomous reset with internal module detection
  /// Automatically detects module switches and preserves brand data when appropriate
  Future<void> resetToDefault({bool force = false}) async {
    // âš¡ PERFORMANCE: Prevent reset + load + reset cycles
    if (_isResetting) {
      if (kDebugMode) {
        debugPrint(
            'ðŸš« BrandsController: Reset already in progress, skipping duplicate reset');
      }
      return;
    }

    _isResetting = true;
    try {
      if (kDebugMode) {
        debugPrint(
            'ðŸ”„ BrandsController: Resetting to default state (force: $force)');
      }

      // âš¡ TASK 1: AUTONOMOUS DETECTION - Fetch current module ID
      int? currentModuleId;
      try {
        if (Get.isRegistered<SplashController>()) {
          final splashController = Get.find<SplashController>();
          currentModuleId = splashController.module?.id;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('âš ï¸ BrandsController: Error fetching module ID: $e');
        }
      }

      // âš¡ TASK 1: PRESERVE brands if same module AND not forced AND brands exist
      if (!force &&
          _brandList != null &&
          _brandList!.isNotEmpty &&
          currentModuleId != null &&
          _lastModuleId == currentModuleId) {
        appLogger.debug(
            'ðŸ›¡ï¸ Brands: Same module detected (ID: $currentModuleId), preserving brand data');

        // Reset only non-brand fields (items, search, filters)
        _brandItems = null;
        _liveSearchResults = null;
        _brandSearchItemModel = null;
        _categoryList = null;

        // Reset pagination
        _offset = 1;
        _pageSize = null;

        // Reset search state
        _searchText = '';
        _isSearching = false;
        _isLiveSearching = false;

        // Reset filters
        _type = 'all';
        _selectedCategoryIds.clear();
        _currentBrandId = null;
        _categoryIndex = 0;

        // Reset state flags
        _isLoading = false;

        if (kDebugMode) {
          debugPrint(
              'âœ… BrandsController: Partial reset completed (brands preserved)');
        }
        update();
        return; // âœ… ELITE: Exit early - brands preserved!
      }

      // âš¡ CRITICAL: Save brands to persistent cache BEFORE reset if they exist
      if (_brandList != null && _brandList!.isNotEmpty && !force) {
        try {
          if (currentModuleId != null) {
            final prefs = await SharedPreferences.getInstance();
            final brandCacheKey =
                'comprehensive_brand_cache_module_$currentModuleId';

            final brandData = {
              'brandList': _brandList!.map((b) => b.toJson()).toList(),
            };

            // Use isolate for JSON encoding to avoid blocking main thread
            final jsonString = await JsonIsolateHelper.encodeJson(brandData);
            await prefs.setString(brandCacheKey, jsonString);

            appLogger.debug(
                'ðŸ’¾ Brands: Saved ${_brandList!.length} brands to persistent cache before reset');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'âš ï¸ BrandsController: Error saving to cache before reset: $e');
          }
        }
      }

      // âš¡ TASK 2: PERSISTENT BRAND HYDRATION - If module switching, try to restore from persistent cache
      // Detect module switch BEFORE tracking the new module ID
      final bool isModuleSwitching = currentModuleId != null &&
          _lastModuleId != null &&
          _lastModuleId != currentModuleId;

      if (isModuleSwitching && !force) {
        try {
          final cachedData =
              await ComprehensiveHomeCacheManager.loadAllHomeData();
          if (cachedData.containsKey('brands')) {
            final brandData = cachedData['brands'] as Map<String, dynamic>;
            if (brandData['brandList'] != null) {
              final cachedBrandList = (brandData['brandList'] as List)
                  .map((json) =>
                      BrandModel.fromJson(json as Map<String, dynamic>))
                  .toList();
              if (cachedBrandList.isNotEmpty) {
                appLogger.debug(
                    'ðŸ”„ Brands: Module switch detected, restoring ${cachedBrandList.length} brands from persistent cache');
                _brandList = cachedBrandList;
                // Continue with reset of other fields below, but preserve _brandList
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'âš ï¸ BrandsController: Error restoring from persistent cache: $e');
          }
        }
      }

      // âš¡ TASK 1: Track module for next comparison
      _lastModuleId = currentModuleId;

      // Full reset for module switch or force reset
      if (kDebugMode && isModuleSwitching) {
        debugPrint(
            'ðŸ”„ BrandsController: Module switch detected ($_lastModuleId â†’ $currentModuleId), full reset');
      }

      // âš¡ TASK 2: PERSISTENT BRAND HYDRATION - Only clear if not module switching (brands restored from cache above)
      // If isModuleSwitching is true and we successfully restored, skip the _brandList = null line
      if (force || (!isModuleSwitching || _brandList == null)) {
        _brandList = null;
      }
      _brandItems = null;
      _liveSearchResults = null;
      _categoryList = null;
      _brandSearchItemModel = null;

      // Reset pagination
      _offset = 1;
      _pageSize = null;
      _lastRequestUniqueItemsCount = null; // ðŸ”§ FIX: Reset unique items counter

      // Reset search state
      _searchText = '';
      _isSearching = false;
      _isLiveSearching = false;

      // Reset filters
      _type = 'all';
      _selectedCategoryIds.clear(); // âš¡ CRITICAL: Use clear(), not null
      _currentBrandId = null;
      _categoryIndex = 0;

      // Reset state flags
      _isLoading = false;

      if (kDebugMode) {
        debugPrint('âœ… BrandsController: Full reset to default state completed');
      }
    } catch (e, stackTrace) {
      appLogger.error('Brands Reset Failed', e, stackTrace);
      if (kDebugMode) {
        debugPrint('âŒ BrandsController.resetToDefault: Error - $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } finally {
      _isResetting = false;
    }
    update();
  }

  /// ðŸ”¥ BACKGROUND SYNC PATTERN: Display cache immediately, update in background
  ///
  /// Flow:
  /// 1ï¸âƒ£ Read from Cache â†’ Display instantly
  /// 2ï¸âƒ£ Start API in background (no await)
  /// 3ï¸âƒ£ When API returns â†’ Update cache & UI smoothly
  Future<void> getBrandItemList(int brandId, int offset, bool notify) async {
    if (kDebugMode) {
      appLogger.info(
        '[BRANDS_CTRL] request brandId=$brandId offset=$offset '
        'currentOffset=$_offset isLoading=$_isLoading isLoadingMore=$_isLoadingMore '
        'isEndReached=$_isEndReached hasReachedEnd=$_hasReachedEnd hasMoreData=$hasMoreData',
      );
    }
    if (offset > 1 && _brandsReachedEnd.contains(brandId)) {
      if (kDebugMode) {
        appLogger.info(
          '[BRANDS_CTRL] skip: brandId=$brandId marked as reached end',
        );
      }
      return;
    }
    if (offset > 1 && _hasReachedEnd) {
      if (kDebugMode) {
        appLogger.info(
          '[BRANDS_CTRL] skip: global end flag true (brandId=$brandId)',
        );
      }
      return;
    }
    // ðŸ”§ FIX: Prevent duplicate API calls for same offset
    if (_isLoading && _offset == offset) {
      if (kDebugMode) {
        appLogger.info('[BRANDS_CTRL] skip: offset=$offset already loading');
      }
      return;
    }

    // ðŸ”§ FIX: If offset is same as current and we have items, skip (already loaded)
    if (_offset == offset &&
        _brandItems != null &&
        _brandItems!.isNotEmpty &&
        offset > 1) {
      if (kDebugMode) {
        appLogger.info(
          '[BRANDS_CTRL] skip: offset=$offset already loaded (${_brandItems!.length} items)',
        );
      }
      return;
    }

    // ðŸ”§ FIX: Set pagination loading flag (different from initial loading)
    if (offset > 1) {
      _isLoadingMore = true;
    }

    _offset = offset;
    _currentBrandId = brandId;
    if (offset == 1) {
      if (!_brandsReachedEnd.contains(brandId)) {
        _hasReachedEnd = false;
      }
      _isEndReached = false;
      _lastRequestUniqueItemsCount = null;
    }

    if (offset == 1) {
      // ðŸ”¥ STEP 1: Try to load from cache FIRST (instant display)
      final ItemModel? cachedData =
          await _getBrandItemsFromCache(brandId, offset);
      if (cachedData != null &&
          cachedData.items != null &&
          cachedData.items!.isNotEmpty) {
        _brandItems = List<Item>.from(cachedData.items!);
        _pageSize = cachedData.totalSize;
        setCategoryListFromResponse(cachedData);

        // ðŸŽ¯ Display cached data instantly (no loading spinner)
        if (notify) {
          update(['items_list']);
        }

        // Log cache hit
        if (kDebugMode) {
          appLogger.info(
              'âš¡ BACKGROUND SYNC: Displayed cached brand items (brandId=$brandId, offset=$offset, items=${cachedData.items!.length})');
        }
      } else {
        // No cache - show loading state
        _brandItems = null;
        _isLoading = true;
        if (notify) {
          update(['items_list']);
        }
      }
    } else {
      // Pagination - show loading
      _isLoading = true;
      if (notify) {
        update(['items_list']);
      }
    }

    // ðŸ”¥ STEP 2: Cancel previous high-priority call if exists
    if (_currentBrandItemsToken != null && offset == 1) {
      _apiScheduler.cancel(_currentBrandItemsToken!);
    }

    // ðŸ”¥ STEP 3: Fetch from API via scheduler (HIGH priority - current screen)
    _currentBrandItemsToken = _apiScheduler.add(
      () async {
        try {
          final List<int?> limitCandidates = offset > 1
              ? <int?>[
                  _itemsPerPage * _paginationBatchPages,
                  _itemsPerPage * 3,
                  _itemsPerPage,
                ]
              : <int?>[null];
          ItemModel? brandItemModel;
          for (final int? candidateLimit in limitCandidates) {
            try {
              // âœ… Use unified searchItems API instead of brand-specific endpoint
              brandItemModel = await itemRepository.searchItems(
                brandId: brandId.toString(),
                page: offset,
                limit: candidateLimit ?? 12,
              );
              if (kDebugMode) {
                appLogger.info(
                  '[BRANDS_API] request brandId=$brandId page=$offset limit=${candidateLimit ?? 12}',
                );
              }
              break;
            } on TimeoutException {
              if (kDebugMode) {
                appLogger.warning(
                  'â±ï¸ Brand items timeout - retrying with smaller limit (brandId=$brandId, offset=$offset, limit=$candidateLimit)',
                );
              }
            }
          }

          if (brandItemModel != null) {
            _isBrandLoadError = false;
            bool reachedEndThisRequest = false;
            if (offset == 1) {
              _brandItems = [];
              // Extract categories from the response
              setCategoryListFromResponse(brandItemModel);

              // ðŸŽ¯ Prefetch categories for filtering (MEDIUM priority)
              _prefetchBrandCategories(brandId);
            }

            // ðŸ”§ FIX: Prevent duplicate items - deduplicate by ID before adding
            if (brandItemModel.items != null &&
                brandItemModel.items!.isNotEmpty) {
              final existingIds = _brandItems!.map((e) => e.id).toSet();
              final newItems = brandItemModel.items!
                  .where((item) => !existingIds.contains(item.id))
                  .toList();

              // ðŸ”§ FIX: Track unique items count for prefetch logic
              _lastRequestUniqueItemsCount = newItems.length;

              // ðŸ›‘ CRITICAL FIX: Stop pagination if unique items <= 1
              // This prevents infinite loops when API returns mostly duplicates.
              if ((_lastRequestUniqueItemsCount ?? 0) <= 1 && offset > 1) {
                reachedEndThisRequest = true;
                _hasReachedEnd = true;
                _isEndReached = true;
                _brandsReachedEnd.add(brandId);
                if (kDebugMode) {
                  appLogger.warning(
                    'ðŸ›‘ Stopping pagination: Only $_lastRequestUniqueItemsCount unique item(s) (offset=$offset, loaded=${_brandItems!.length})',
                  );
                }
                _pageSize = _brandItems!
                    .length; // Set to loaded count to stop pagination
                _isLoadingMore = false;
                if (newItems.isNotEmpty) {
                  _brandItems!.addAll(newItems);
                }
              } else if (newItems.isNotEmpty) {
                _brandItems!.addAll(newItems);
                if (kDebugMode &&
                    newItems.length < brandItemModel.items!.length) {
                  appLogger.info(
                      'ðŸ›¡ï¸ Deduplication: Filtered out ${brandItemModel.items!.length - newItems.length} duplicate items (unique: ${newItems.length})');
                }
              } else {
                // ðŸ”§ FIX: If all items are duplicates, backend might be returning wrong page
                // Stop pagination to prevent infinite loop
                reachedEndThisRequest = true;
                _hasReachedEnd = true;
                _isEndReached = true;
                _brandsReachedEnd.add(brandId);
                if (kDebugMode) {
                  appLogger.warning(
                      'âš ï¸ All items are duplicates - stopping pagination (offset=$offset, loaded=${_brandItems!.length})');
                }
                _pageSize = _brandItems!
                    .length; // Set to loaded count to stop pagination
                _isLoadingMore = false;
              }
            } else {
              // No items returned - track as 0 unique items
              reachedEndThisRequest = true;
              _hasReachedEnd = true;
              _isEndReached = true;
              _brandsReachedEnd.add(brandId);
              _lastRequestUniqueItemsCount = 0;
              if (kDebugMode) {
                appLogger.info(
                  'ðŸ Pagination end reached: fetched=0 (offset=$offset)',
                );
              }
            }
            if (!reachedEndThisRequest) {
              _pageSize = brandItemModel.totalSize;
            }
            // ðŸ”§ FIX: Update offset after successful API call to prevent duplicate requests
            _offset = offset;
            _isLoading = false;
            _isLoadingMore = false; // ðŸ”§ FIX: Reset pagination loading flag

            // ðŸŽ¯ STEP 4: Smooth update (no spinner, no reload - just refresh data)
            if (notify) {
              update(['items_list']);
            }

            // Log background sync completion
            if (kDebugMode) {
              appLogger.info(
                  'âœ… PRIORITY API: Updated brand items from API (brandId=$brandId, offset=$offset, items=${brandItemModel.items!.length})');
            }
          } else {
            if (offset == 1) {
              _isBrandLoadError = true;
            }
            _isLoading = false;
            _isLoadingMore = false;
            if (notify) {
              update(['items_list']);
            }
          }
        } catch (error) {
          // Error handling - don't break UI if API fails
          _isLoading = false;
          _isLoadingMore =
              false; // 🔧 FIX: Reset pagination loading flag on error
          if (offset == 1) {
            _isBrandLoadError = true;
          }
          if (notify) {
            update(['items_list']);
          }
          if (kDebugMode) {
            appLogger.error(
                'âŒ PRIORITY API: Error for brand items (brandId=$brandId): $error');
          }
          rethrow; // Re-throw to let scheduler handle it
        }
      },
      priority: ApiPriority.high,
      tag: 'getBrandItemList_${brandId}_$offset',
    );
  }

  void resetReachedEndForBrand(int brandId) {
    _brandsReachedEnd.remove(brandId);
    if (_currentBrandId == brandId) {
      _hasReachedEnd = false;
      _isEndReached = false;
    }
  }

  /// ðŸ”¥ Helper: Read brand items from cache (for instant display)
  Future<ItemModel?> _getBrandItemsFromCache(int brandId, int offset) async {
    try {
      // Use same cache key as repository
      final moduleId = Get.find<SplashController>().module?.id;
      if (moduleId == null) return null;

      final String cacheKey = 'brand_items_${brandId}_${offset}_$moduleId';
      final String? cacheResponseData = await LocalClient.organize(
          DataSourceEnum.local, cacheKey, null, null);

      if (cacheResponseData != null) {
        try {
          // ðŸŽ¯ Parse JSON from cache (using dart:convert which is imported)
          final Map<String, dynamic> jsonData =
              jsonDecode(cacheResponseData) as Map<String, dynamic>;
          final brandItemModel = ItemModel.fromJson(jsonData);

          // Verify cache has required fields
          if (brandItemModel.items != null &&
              brandItemModel.items!.isNotEmpty) {
            final hasOriginalPrice =
                brandItemModel.items!.first.originalPrice != null;
            if (hasOriginalPrice) {
              return brandItemModel;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning(
                'âš ï¸ Cache corrupted for brand items (brandId=$brandId): $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.warning('âš ï¸ Error reading cache for brand items: $e');
      }
    }
    return null;
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  /// ðŸ”¥ Prefetch brand categories for filtering (MEDIUM priority)
  /// Called after main brand items are loaded
  void _prefetchBrandCategories(int brandId) {
    // Cancel previous prefetch if exists
    if (_currentCategoriesToken != null) {
      _apiScheduler.cancel(_currentCategoriesToken!);
    }

    // Prefetch categories with MEDIUM priority (runs when HIGH queue is empty)
    _currentCategoriesToken = _apiScheduler.add(
      () async {
        try {
          // Note: Add method to prefetch categories for brand filtering
          // This is a placeholder - implement when category prefetch API is available
          if (kDebugMode) {
            appLogger.info(
                'ðŸ“¦ PRIORITY API: Prefetching categories for brand $brandId (MEDIUM priority)');
          }
        } catch (e) {
          if (kDebugMode) {
            appLogger
                .warning('âš ï¸ PRIORITY API: Failed to prefetch categories: $e');
          }
        }
      },
      priority: ApiPriority.medium,
      tag: 'prefetchCategories_$brandId',
    );
  }

  /// ðŸ”¥ Cancel all non-critical API calls when user navigates away
  void cancelBackgroundRequests() {
    _apiScheduler.clearNonCritical();
    _currentCategoriesToken = null;
    if (kDebugMode) {
      appLogger.info('ðŸ›‘ PRIORITY API: Cancelled non-critical requests');
    }
  }

  /// Set brand data directly from cache (handles both List<BrandModel> and raw JSON)
  void setBrandDataFromCache(dynamic data) {
    if (data == null) return;

    try {
      List<BrandModel>? newBrandList;
      if (data is List<BrandModel>) {
        // Already deserialized model objects
        newBrandList = data;
      } else if (data is List) {
        // Raw JSON list from disk cache - deserialize it
        newBrandList = data
            .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          appLogger.warning(
              'âš ï¸ BrandsController: Unexpected data type: ${data.runtimeType}');
        }
        return;
      }

      // âš¡ ZERO-FLICKER: Deep equality check - only update if data actually changed
      if (_brandList != null) {
        final oldJson = _brandList!.map((b) => b.toJson()).toList();
        final newJson = newBrandList.map((b) => b.toJson()).toList();
        if (_deepEquality.equals(oldJson, newJson)) {
          _isLoading = false;
          if (kDebugMode) {
            appLogger.debug(
                'âœ… BrandsController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
          }
          return;
        }
      }

      _brandList = newBrandList;
      update();
      if (kDebugMode) {
        appLogger.info(
            'âœ… BrandsController: Loaded ${_brandList!.length} brands from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            'âŒ BrandsController: Error setting brands from cache: $e', e);
      }
    }
  }

  // Search and filter methods
  void setVerticalItems(bool value) {
    _isVertical = value;
    // ðŸŽ¯ PERFORMANCE: Update only filter controls, not entire screen
    update(['filter_controls', 'items_list']);
  }

  void setPrice(bool value) {
    _isPriceAscending = value;
    // âŒ REMOVED: Local price sorting - reload from API with sortOrder parameter
    // Reload items with new sort order
    if (_isSearching && _searchText.isNotEmpty && _currentBrandId != null) {
      // For search, reload search results with new sort order
      getBrandSearchItemList(_searchText, _currentBrandId!);
    } else if (_currentBrandId != null) {
      // For regular items, reload with filters
      final categoryId = _categoryIndex > 0 &&
              _categoryList != null &&
              _categoryList!.isNotEmpty
          ? _categoryList![_categoryIndex].id.toString()
          : null;
      getBrandItemWithFilters(
        brandId: _currentBrandId!,
        categoryId: categoryId,
        sortBy: 'price',
        sortOrder: _isPriceAscending ? 'asc' : 'desc',
      );
    }
  }

  // Local-only price sort (no API reload)
  void setPriceLocal(bool value) {
    _isPriceAscending = value;
    update(['filter_controls', 'items_list']);
  }

  void changeSearchStatus({bool isUpdate = true}) {
    if (!_isSearching) {
      _isSearching = true;
    } else {
      _isSearching = false;
      _brandSearchItemModel = null;
    }
    if (isUpdate) {
      update();
    }
  }

  void initSearchData() {
    _brandSearchItemModel = ItemModel(items: []);
    _searchText = '';
  }

  // Live search functionality
  // âœ… Reset search state (NO CACHE for search)
  void resetSearchState() {
    _offset = 1;
    _hasReachedEnd = false;
    _isEndReached = false;
    _isLoading = false;
    _isLoadingMore = false;
    _liveSearchResults = null;
    _brandSearchItemModel = null;
    _searchText = '';
    _isSearching = false;
    _isLiveSearching = false;
    update(['items_list']);
  }

  void performLiveSearch(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      clearLiveSearch();
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // âœ… CRITICAL: Reset state before new search (NO CACHE)
      resetSearchState();

      _isLiveSearching = true;
      _isSearching = true; // Set searching state for UI
      _searchText = query; // Update search text

      // âŒ REMOVED: Local search filtering - use unified API instead
      // Use ItemRepository.searchItems() for live search
      if (_currentBrandId != null) {
        try {
          final itemModel = await itemRepository.searchItems(
            name: query,
            brandId: _currentBrandId.toString(),
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

      // ðŸŽ¯ PERFORMANCE: Update only items list, not entire screen
      update(['items_list']);
    });
  }

  void clearLiveSearch() {
    _isLiveSearching = false;
    _isSearching = false; // Reset searching state
    _searchText = ''; // Clear search text
    _liveSearchResults = null;
    if (kDebugMode) {
      appLogger.debug('ðŸ” Live search cleared');
    }
    // ðŸŽ¯ PERFORMANCE: Update only items list, not entire screen
    update(['items_list']);
  }

  // API search functionality - now uses unified /api/v1/items/search endpoint
  Future<void> getBrandSearchItemList(String searchText, int brandId,
      {int offset = 1}) async {
    if (searchText.isEmpty) {
      showCustomSnackBar('write_item_name'.tr);
    } else {
      // âœ… CRITICAL: Reset state before new search (NO CACHE)
      if (offset == 1) {
        resetSearchState();
      }

      _isSearching = true;
      _searchText = searchText;
      _currentBrandId = brandId;
      _isLoading = true;
      // ðŸŽ¯ PERFORMANCE: Update only items list, not entire screen
      update(['items_list']);

      // âœ… Use unified searchItems API instead of brand-specific search endpoint
      String? categoryId;
      if (_categoryList != null &&
          _categoryList!.isNotEmpty &&
          _categoryIndex != 0) {
        categoryId = _categoryList![_categoryIndex].id?.toString();
      }

      final ItemModel? brandSearchItemModel = await itemRepository.searchItems(
        name: searchText,
        brandId: brandId.toString(),
        categoryId: categoryId,
        type: _type != 'all' ? _type : null,
        sortBy: _isPriceAscending ? 'price' : null,
        sortOrder: _isPriceAscending ? 'asc' : 'desc',
        page: offset,
        limit: 12,
      );

      if (brandSearchItemModel != null) {
        if (offset == 1) {
          _brandSearchItemModel = brandSearchItemModel;
        } else {
          if (brandSearchItemModel.items != null &&
              brandSearchItemModel.items!.isNotEmpty) {
            // ðŸ”§ FIX: Prevent duplicate items - deduplicate by ID before adding
            final existingIds =
                _brandSearchItemModel!.items!.map((e) => e.id).toSet();
            final newItems = brandSearchItemModel.items!
                .where((item) => !existingIds.contains(item.id))
                .toList();

            if (newItems.isNotEmpty) {
              _brandSearchItemModel!.items!.addAll(newItems);
              if (kDebugMode &&
                  newItems.length < brandSearchItemModel.items!.length) {
                debugPrint(
                    'ðŸ›¡ï¸ Search Deduplication: Filtered out ${brandSearchItemModel.items!.length - newItems.length} duplicate items');
              }
            }
          }
          _brandSearchItemModel!.totalSize = brandSearchItemModel.totalSize;
          _brandSearchItemModel!.offset = brandSearchItemModel.offset;
        }
      } else {
        // Handle null response (API error)
        if (offset == 1) {
          _brandSearchItemModel = ItemModel(items: []);
        }
        if (kDebugMode) {
          appLogger
              .warning('âŒ Failed to load search results - API returned null');
        }
      }

      _isLoading = false;
      // ðŸŽ¯ PERFORMANCE: Update only items list, not entire screen
      update(['items_list']);
    }
  }

  // Filter modal methods
  void toggleFilterModal() {
    _isFilterModalOpen = !_isFilterModalOpen;
    // ðŸŽ¯ PERFORMANCE: Update only filter modal, not entire screen
    update(['filter_modal']);
  }

  void closeFilterModal() {
    _isFilterModalOpen = false;
    // ðŸŽ¯ PERFORMANCE: Update only filter modal, not entire screen
    update(['filter_modal']);
  }

  // Category selection methods
  void toggleCategorySelection(int categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    // ðŸŽ¯ PERFORMANCE: Update only filter controls, not entire screen
    update(['filter_controls']);
  }

  void clearCategorySelections({bool notify = false}) {
    _selectedCategoryIds.clear();
    if (notify) {
      update(['filter_controls']);
    }
  }

  void applyCategoryFilter() {
    // âŒ REMOVED: Local filtering - use API instead
    if (_currentBrandId != null) {
      if (_selectedCategoryIds.isEmpty) {
        // Show all items if no categories selected
        getBrandItemList(_currentBrandId!, 1, true);
      } else {
        // Note: Support multiple categories in API call
        // For now, use first selected category
        final categoryId = _selectedCategoryIds.first.toString();
        getBrandItemWithFilters(
          brandId: _currentBrandId!,
          categoryId: categoryId,
          sortBy: 'price',
          sortOrder: _isPriceAscending ? 'asc' : 'desc',
        );
      }
    }
    closeFilterModal();
  }

  void resetFilters() {
    _selectedCategoryIds.clear();
    _categoryIndex = 0;
    _isPriceAscending = true;
    _isVertical = false;
    _type = 'all';

    // âŒ REMOVED: Local filtering - reload from API instead
    if (_currentBrandId != null) {
      getBrandItemList(_currentBrandId!, 1, true);
    } else {
      // ðŸŽ¯ PERFORMANCE: Update items list and filter controls
      update(['items_list', 'filter_controls']);
    }
  }

  void resetFilterState({bool notify = true}) {
    _selectedCategoryIds.clear();
    _categoryIndex = 0;
    _isPriceAscending = true;
    _isVertical = false;
    _type = 'all';
    _isFilterModalOpen = false;

    _searchText = '';
    _isSearching = false;
    _isLiveSearching = false;
    _liveSearchResults = null;
    _brandSearchItemModel = null;

    if (notify) {
      update(['filter_controls', 'filter_modal', 'items_list']);
    }
  }

  // Category list management
  void setCategoryListFromResponse(ItemModel response) {
    if (response.items != null && response.items!.isNotEmpty) {
      final Set<int> categoryIds = {};
      final List<CategoryModel> categories = [];

      // Extract unique categories from items
      for (final Item item in response.items!) {
        if (item.categoryId != null && !categoryIds.contains(item.categoryId)) {
          categoryIds.add(item.categoryId!);
          categories.add(CategoryModel(
            id: item.categoryId,
            name:
                'Category ${item.categoryId}', // Use categoryId as name for now
          ));
        }
      }

      // Add "All Products" option at the beginning
      categories.insert(
          0,
          CategoryModel(
            id: 0,
            name: 'all_products'.tr,
          ));

      _categoryList = categories;
      if (kDebugMode) {
        appLogger.info(
            'âœ… Categories extracted from brand items: ${categories.length}');
      }
    }
  }

  void setCategoryIndex(int index, {bool itemSearching = false}) {
    _categoryIndex = index;
    if (kDebugMode) {
      appLogger.debug(
          'ðŸ” Category filter selected: index=$index, itemSearching=$itemSearching');
    }

    if (itemSearching) {
      _brandSearchItemModel = null;
      if (_searchText.isNotEmpty && _currentBrandId != null) {
        getBrandSearchItemList(_searchText, _currentBrandId!);
      }
    } else {
      // âŒ REMOVED: Frontend filtering - always use API
      _brandItems = null;
      if (_currentBrandId != null) {
        if (index > 0 && _categoryList != null && _categoryList!.isNotEmpty) {
          if (kDebugMode) {
            appLogger.debug(
                'ðŸ“¡ Making API call for category: ${_categoryList![index].name}');
          }
          getBrandItemWithFilters(
            brandId: _currentBrandId!,
            categoryId: _categoryList![index].id.toString(),
            sortBy: 'price',
            sortOrder: _isPriceAscending ? 'asc' : 'desc',
          );
        } else {
          if (kDebugMode) {
            appLogger.debug('ðŸ“¡ Making API call for all products');
          }
          getBrandItemList(_currentBrandId!, 1, true);
        }
      }
    }
    update();
  }

  // âŒ REMOVED: _filterItemsByCategory - filtering now handled by API
  // âŒ REMOVED: _filterItemsBySearch - search now handled by API

  // API filter method - now uses unified /api/v1/items/search endpoint
  Future<void> getBrandItemWithFilters({
    int offset = 1,
    int? limit = 12,
    int? brandId,
    bool notify = false,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  }) async {
    _offset = offset;
    _currentBrandId = brandId;

    if (offset == 1) {
      _brandItems = null;
      if (notify) {
        update();
      }
    }

    _isLoading = true;
    update();

    // âœ… Use unified searchItems API instead of brand-specific endpoint
    final ItemModel? brandItemModel = await itemRepository.searchItems(
      brandId: brandId?.toString(),
      categoryId: categoryId,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: offset,
      limit: limit ?? 12,
    );

    if (brandItemModel != null) {
      if (offset == 1) {
        _brandItems = [];
        // Extract categories from the response for filtering
        setCategoryListFromResponse(brandItemModel);
      }

      // ðŸ”§ FIX: Prevent duplicate items - deduplicate by ID before adding
      if (brandItemModel.items != null && brandItemModel.items!.isNotEmpty) {
        final existingIds = _brandItems!.map((e) => e.id).toSet();
        final newItems = brandItemModel.items!
            .where((item) => !existingIds.contains(item.id))
            .toList();

        if (newItems.isNotEmpty) {
          _brandItems!.addAll(newItems);
          if (kDebugMode && newItems.length < brandItemModel.items!.length) {
            debugPrint(
                'ðŸ›¡ï¸ Filter Deduplication: Filtered out ${brandItemModel.items!.length - newItems.length} duplicate items');
          }
        }
      }
      _pageSize = brandItemModel.totalSize;
      _isLoading = false;
    } else {
      // Handle null response (API error) - fallback to regular brand API
      if (offset == 1) {
        _brandItems = [];
        if (kDebugMode) {
          appLogger.warning(
              'âŒ Filter API failed, falling back to regular brand API');
        }
        // Try to load regular brand items as fallback
        await getBrandItemList(brandId!, offset, notify);
        return;
      }
      _isLoading = false;
      if (kDebugMode) {
        appLogger.warning(
            'âŒ Failed to load brand items with filters - API returned null');
      }
    }
    update();
  }

  // Reset all loading states
  void resetLoadingStates({bool notify = true}) {
    _isLoading = false;
    _isSearching = false;
    _isLiveSearching = false;
    _isFilterModalOpen = false;
    _isEndReached = false;
    if (notify) {
      update();
    }
  }

  /// Set brand data from bootstrap endpoint
  /// âš¡ TASK 2: PERSISTENT BRAND HYDRATION - Save to persistent cache that resetToDefault cannot touch
  void setBrandDataFromBootstrap(List<BrandModel> brands) {
    // âš¡ ZERO-FLICKER: Deep equality check - only update if data actually changed
    if (_brandList != null && brands.isNotEmpty) {
      final oldJson = _brandList!.map((b) => b.toJson()).toList();
      final newJson = brands.map((b) => b.toJson()).toList();
      if (_deepEquality.equals(oldJson, newJson)) {
        _isLoading = false;
        if (kDebugMode) {
          appLogger.debug(
              'âœ… BrandsController: Data unchanged (deep equality check), skipping UI update to prevent flicker');
        }
        return;
      }
    }

    // âš¡ TASK 2: PERSISTENT CACHE - Data is saved automatically via ComprehensiveHomeCacheManager.saveAllHomeData()
    // This cache survives module switches and is restored in resetToDefault() when isModuleSwitching is true
    _brandList = brands;
    update();
    if (kDebugMode) {
      appLogger.info(
          'âœ… BrandsController: Brand data set from bootstrap (${brands.length} brands)');
    }
  }

  /// âš¡ BFF API v2: Set brand list from home-unified endpoint
  /// Alias for setBrandDataFromBootstrap for consistency
  void setBrandListFromBootstrap(List<BrandModel> brands) {
    setBrandDataFromBootstrap(brands);
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    resetLoadingStates(notify: false);
    // ðŸ”¥ Cancel all non-critical API calls when controller is disposed
    _apiScheduler.clearNonCritical();
    super.onClose();
  }
}

