import 'dart:async';
import 'package:sixam_mart/features/search/controllers/search_controller.dart'
    as search;
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/widgets/search_suggestions_dropdown.dart';
import 'package:sixam_mart/util/design_tokens.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

part 'search_screen.builders.dart';

class SearchScreen extends StatefulWidget {
  final String? queryText;
  const SearchScreen({super.key, required this.queryText});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  final TextEditingController _SearchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late bool _isLoggedIn;

  Timer? _debounceTimer;
  // Live search: filter results as the user types (debounced), no Enter needed.
  Timer? _liveSearchTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 400);
  bool _showSuggestion = false;
  bool _isLoadingSuggestions = false;
  final Map<int, int> _storeVisibleItemCount = <int, int>{};
  String? _lastSearchResultsQuery;
  bool _isSyncingSearchText = false;
  int? _selectedSearchModuleId;
  String _selectedSearchModuleName = '';
  String _selectedSearchModuleType = '';
  bool _isHandlingQueryClear = false;
  final Set<int> _loggedComingSoonModules = <int>{};

  late AnimationController _focusAnimationController;
  late Animation<double> _focusScaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isLoggedIn = AuthHelper.isLoggedIn();

    _focusAnimationController = AnimationController(
      duration: DesignTokens.animationDefault,
      vsync: this,
    );
    _focusScaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(
          parent: _focusAnimationController, curve: DesignTokens.curveEaseOut),
    );

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _focusAnimationController.forward();
      } else {
        _focusAnimationController.reverse();
      }
    });

    Get.find<search.SearchController>().setSearchMode(true, canUpdate: false);

    // Set default module to Module 3 (هايبر شله/Ecommerce) if not set
    final splashController = Get.find<SplashController>();
    if (splashController.moduleList != null &&
        splashController.moduleList!.isNotEmpty) {
      if (splashController.module == null) {
        // Find Module 3 (ecommerce) or fallback to first module
        final module3 = splashController.moduleList!.firstWhere(
          (m) => m.id == 3 || m.moduleType == 'ecommerce',
          orElse: () => splashController.moduleList!.first,
        );
        splashController.setModule(module3);
      }
    }

    // Set default tab based on module type
    // For Module 3 (ecommerce): default to Items (false)
    // For other modules: default to Stores (true)
    final isEcommerce = splashController.module?.moduleType == 'ecommerce';
    Get.find<search.SearchController>().setStore(!isEcommerce);
    Get.find<search.SearchController>()
        .setActiveModuleId(splashController.module?.id);
    _selectedSearchModuleId = splashController.module?.id;
    _selectedSearchModuleName = splashController.module?.moduleName ?? '';
    _selectedSearchModuleType = splashController.module?.moduleType ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSearchStateOnOpen();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _searchSuggestions(String query) async {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      _showSuggestion = false;
      _isLoadingSuggestions = false;
      setState(() {});
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestion = true;
    });

    _debounceTimer = Timer(_debounceDelay, () async {
      try {
        await Get.find<search.SearchController>().getSearchSuggestions(query);
      } catch (e) {
        debugPrint('[Search][ERROR] suggestions $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingSuggestions = false;
          });
        }
      }
    });
  }

  /// Schedules a debounced live search so results filter as the user types,
  /// without needing to press Enter. Keeps the keyboard focused so typing can
  /// continue uninterrupted.
  void _scheduleLiveSearch(
      String text, search.SearchController searchController) {
    _liveSearchTimer?.cancel();
    final String query = text.trim();
    if (query.isEmpty) return;
    _liveSearchTimer = Timer(_debounceDelay, () {
      if (!mounted) return;
      if (_SearchController.text.trim() != query) return;
      _actionSearch(searchController.isStore, query, false, keepFocus: true);
    });
  }

  void _actionSearch(bool isStore, String? queryText, bool fromHome,
      {bool keepFocus = false}) {
    if (queryText != null && queryText.isNotEmpty) {
      if (_lastSearchResultsQuery != queryText) {
        _storeVisibleItemCount.clear();
      }
      _showSuggestion = false;
      if (!keepFocus) {
        _searchFocusNode.unfocus();
      }
      if (kDebugMode) {
        appLogger.debug(
            '🔍 Search triggered: $queryText, isStore: $isStore, fromHome: $fromHome');
      }

      final searchController = Get.find<search.SearchController>();

      // Update store mode + exit search mode WITHOUT rebuilding yet, so the UI
      // doesn't flash the stale "no results" state for one frame before the
      // loading state is set. searchData() below sets isLoading=true and rebuilds.
      searchController.setStore(isStore, canUpdate: false);
      debugPrint(
          '[SEARCH_FETCH_START] query=$queryText selectedType=${isStore ? 'stores' : 'items'}');

      // Exit search mode so results can be displayed
      searchController.setSearchMode(false, canUpdate: false);

      // Save the real (explicit) search term to recent history — the live-typing
      // path (searchData alone) no longer writes history.
      searchController.saveSearch(queryText);

      // Trigger search (sets loading state synchronously, then fetches).
      searchController.searchData(query: queryText, fromHome: fromHome);

      // Force UI update (now reflects the loading state, not the stale one).
      setState(() {});
    }
  }

  Future<void> _handleModuleSwitch(ModuleModel module) async {
    final searchController = Get.find<search.SearchController>();
    final splashController = Get.find<SplashController>();
    final int? fromModuleId = splashController.module?.id;
    final String currentQuery = (searchController.searchText ?? '').trim();
    final bool hasQuery = currentQuery.isNotEmpty;
    _selectedSearchModuleId = module.id;
    _selectedSearchModuleName = module.moduleName ?? '';
    _selectedSearchModuleType = module.moduleType ?? '';
    debugPrint(
        '[Search][TAB_SWITCH] fromModuleId=${fromModuleId ?? 'null'} toModuleId=${module.id ?? 'null'} query=$currentQuery');
    await splashController.setModule(module);
    searchController.resetForModuleSwitch(hasQuery: hasQuery);
    searchController.setActiveModuleId(module.id);
    searchController.setStore(module.moduleType != 'ecommerce');
    if (hasQuery) {
      searchController.setSearchMode(false);
      searchController.setSearchText(currentQuery);
      searchController.searchData(query: currentQuery, fromHome: false);
    } else {
      searchController.setSearchMode(true);
      searchController.getHistoryList();
      await searchController.getPopularCategories();
      await searchController.getTrendingCategories();
      if (_isLoggedIn) {
        searchController.getSuggestedItems();
      }
      final List<CategoryModel> fallbackCategories =
          await _resolveDiscoveryFallbackCategories(module.id);
      searchController.setDiscoveryFallbackCategories(
        fallbackCategories,
        moduleId: module.id,
      );
    }
    debugPrint(
        '[Search][TAB_DONE] moduleId=${module.id ?? 'null'} query=$currentQuery hasQuery=$hasQuery loading=false moduleName=$_selectedSearchModuleName moduleType=$_selectedSearchModuleType');
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<CategoryModel>> _resolveDiscoveryFallbackCategories(
      int? moduleId) async {
    if (!Get.isRegistered<CategoryController>()) {
      debugPrint(
          '[Search][DISCOVERY_FALLBACK_CATEGORIES] moduleId=${moduleId ?? 'null'} count=0');
      return <CategoryModel>[];
    }
    final CategoryController categoryController = Get.find<CategoryController>();
    if (moduleId != null) {
      await categoryController.getCategoryList(
        true,
        expectedModuleId: moduleId,
        dataSource: DataSourceEnum.client,
      );
    }
    final List<CategoryModel> sourceCategories =
        List<CategoryModel>.from(categoryController.categoryList ?? <CategoryModel>[]);
    final List<CategoryModel> filtered = sourceCategories
        .where((category) =>
            category.id != null &&
            (moduleId == null || category.moduleId == null || category.moduleId == moduleId))
        .toList();
    debugPrint(
        '[Search][FALLBACK_SOURCE] activeModuleId=${_selectedSearchModuleId ?? 'null'} fallbackModuleId=${moduleId ?? 'null'} count=${filtered.length}');
    return filtered;
  }

  Future<void> _handleQueryClear() async {
    if (_isHandlingQueryClear) {
      return;
    }
    _isHandlingQueryClear = true;
    try {
      final searchController = Get.find<search.SearchController>();
      final int? activeModuleId =
          _selectedSearchModuleId ?? Get.find<SplashController>().module?.id;
      debugPrint('[Search][QUERY_CLEAR] activeModuleId=${activeModuleId ?? 'null'}');
      searchController.setSearchText('');
      searchController.resetForModuleSwitch(hasQuery: false);
      searchController.setActiveModuleId(activeModuleId);
      searchController.getHistoryList();
      await searchController.getPopularCategories();
      await searchController.getTrendingCategories();
      if (_isLoggedIn) {
        searchController.getSuggestedItems();
      }
      final List<CategoryModel> fallbackCategories =
          await _resolveDiscoveryFallbackCategories(activeModuleId);
      searchController.setDiscoveryFallbackCategories(
        fallbackCategories,
        moduleId: activeModuleId,
      );
      if (mounted) {
        setState(() {});
      }
    } finally {
      _isHandlingQueryClear = false;
    }
  }

  bool _isComingSoonModule(ModuleModel module) {
    final String moduleType =
        (module.moduleType ?? '').toString().trim().toLowerCase();
    final String moduleName =
        (module.moduleName ?? '').toString().trim().toLowerCase();

    final bool isPharmacy = moduleType == AppConstants.pharmacy ||
        moduleName.contains('صيدلي') ||
        moduleName.contains('pharmacy') ||
        moduleName.contains('pharm');
    final bool isCommercialStores = moduleName.contains('المحلات التجارية') ||
        moduleName.contains('محلات تجارية') ||
        moduleName.contains('commercial') ||
        moduleName.contains('shop');

    return isPharmacy || isCommercialStores;
  }

  int _moduleSortPriority(ModuleModel module) {
    final String moduleType =
        (module.moduleType ?? '').toString().trim().toLowerCase();
    final String moduleName =
        (module.moduleName ?? '').toString().trim().toLowerCase();

    if (_isComingSoonModule(module)) return 90;
    if (moduleType == AppConstants.ecommerce ||
        moduleName.contains('هايبر') ||
        moduleName.contains('hyper')) {
      return 1; // Hyper first
    }
    if (moduleName.contains('مطعم') || moduleName.contains('restaurant')) {
      return 2; // Restaurants second
    }
    if (moduleName.contains('مقهى') ||
        moduleName.contains('كاف') ||
        moduleName.contains('cafe') ||
        moduleName.contains('coffee')) {
      return 3; // Cafes third
    }
    return 10;
  }

  bool _isRestaurantModule(ModuleModel module) {
    final String moduleType =
        (module.moduleType ?? '').toString().trim().toLowerCase();
    final String moduleName =
        (module.moduleName ?? '').toString().trim().toLowerCase();
    return moduleName.contains('مطعم') ||
        moduleName.contains('restaurant') ||
        (moduleType.isNotEmpty && moduleType != AppConstants.ecommerce);
  }

  void _switchTab(bool isStore) {
    final searchController = Get.find<search.SearchController>();

    // Only switch if different from current mode
    if (searchController.isStore != isStore) {
      debugPrint(
          '[Search][TAB] selected=${isStore ? 'stores' : 'items'}');
      searchController.setStore(isStore);
      // No need to re-search, data is already loaded
      setState(() {});
    }
  }

  Future<void> _initializeSearchStateOnOpen() async {
    final searchController = Get.find<search.SearchController>();
    final splashController = Get.find<SplashController>();
    final ModuleModel? initialModule = splashController.module;
    final List<ModuleModel> sortedModules =
        List<ModuleModel>.from(splashController.moduleList ?? <ModuleModel>[])
          ..sort((a, b) {
            final int p = _moduleSortPriority(a).compareTo(_moduleSortPriority(b));
            if (p != 0) return p;
            return (a.id ?? 0).compareTo(b.id ?? 0);
          });
    final int initialVisualIndex = sortedModules
        .indexWhere((module) => module.id != null && module.id == initialModule?.id);
    debugPrint('[SEARCH_OPEN]');
    debugPrint(
        '[SEARCH_INITIAL_VISUAL_TAB] index=$initialVisualIndex module=${initialModule?.moduleName ?? 'null'} moduleId=${initialModule?.id ?? 'null'}');
    debugPrint(
        '[SEARCH_INITIAL_CONTROLLER_TAB] isStore=${searchController.isStore} activeModuleId=${searchController.activeModuleId ?? 'null'}');
    final String initialQuery = (widget.queryText ?? '').trim();
    if (initialQuery.isNotEmpty) {
      searchController.setSearchText(initialQuery);
    }
    if (initialModule != null) {
      if (_isRestaurantModule(initialModule)) {
        debugPrint('[SEARCH_RESTAURANT_INIT_CALL]');
      }
      await _handleModuleSwitch(initialModule);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (Get.find<search.SearchController>().isSearchMode) {
          return;
        } else {
          Get.find<search.SearchController>().setSearchMode(true);
        }
      },
      child: Scaffold(
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        body: SafeArea(
          child: GetBuilder<search.SearchController>(
            builder: (searchController) {
              if (!GetPlatform.isWeb) {
                final String desiredText = searchController.searchText ?? '';
                if (_SearchController.text != desiredText) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (_SearchController.text == desiredText) return;
                    _isSyncingSearchText = true;
                    _SearchController.value = TextEditingValue(
                      text: desiredText,
                      selection:
                          TextSelection.collapsed(offset: desiredText.length),
                    );
                    _isSyncingSearchText = false;
                  });
                }
              }

              return Directionality(
                textDirection: Get.locale?.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLarge,
                    DesignTokens.spaceSmall,
                    DesignTokens.spaceLarge,
                    DesignTokens.spaceDefault,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search Input Field (with suggestions dropdown and back button)
                      _SearchInputField(searchController),
                      const SizedBox(height: DesignTokens.spaceMedium),

                      // Module Chips Section
                      _ModuleChipsSection(),
                      const SizedBox(height: DesignTokens.spaceMedium),

                      // Search tabs - shown ONLY when searching
                      if (searchController.searchText != null &&
                          searchController.searchText!.isNotEmpty) ...[
                        _SearchCategoryTabs(),
                        const SizedBox(height: DesignTokens.spaceMedium),
                      ],

                      // Discovery sections (category chips + content) - shown ONLY when NOT searching
                      if (searchController.searchText == null ||
                          searchController.searchText!.isEmpty) ...[
                        // Category Filter Chips
                        _CategoryTabs(),
                        const SizedBox(height: DesignTokens.spaceDefault),

                        // Recent Searches Section
                        _RecentSearchesSection(searchController),
                        const SizedBox(height: DesignTokens.spaceLarge),

                        // Most Searched Section
                        _MostSearchedSection(searchController),
                        _DiscoveryEmptyState(searchController),
                      ],

                      // Search Results Section - show when we have search text
                      if (searchController.searchText != null &&
                          searchController.searchText!.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.spaceLarge),
                        _SearchResultsSection(searchController),
                      ],

                      const SizedBox(height: DesignTokens.spaceSmall),

                      // Home Indicator
                      _HomeIndicator(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _liveSearchTimer?.cancel();
    _tabController?.dispose();
    _searchFocusNode.dispose();
    _focusAnimationController.dispose();
    _SearchController.dispose();
    super.dispose();
  }
}
