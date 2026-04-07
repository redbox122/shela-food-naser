//import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/item_widget.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class BrandsItemScreen extends StatefulWidget {
  final int brandId;
  final String brandName;
  const BrandsItemScreen(
      {super.key, required this.brandId, required this.brandName});

  @override
  State<BrandsItemScreen> createState() => _BrandsItemScreenState();
}

class _BrandsItemScreenState extends State<BrandsItemScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int?
      _lastOffset; // 🔧 FIX: Track last offset to reset scroll only when needed
  bool _hasReachedEnd = false;
  String _selectedSort = 'popular';
  String _selectedPriceLabel = 'all';
  String _minPrice = '';
  String _maxPrice = '';
  bool _isPriceSortActive = false;
  final List<Map<String, String>> _priceRanges = [
    {'label': 'all', 'min': '0', 'max': '0'},
    {'label': '0 - 10', 'min': '0', 'max': '10'},
    {'label': '20 - 40', 'min': '20', 'max': '40'},
    {'label': '40 - 70', 'min': '40', 'max': '70'},
    {'label': '70 - 100', 'min': '70', 'max': '100'},
    {'label': '150 - 200', 'min': '150', 'max': '200'},
    {'label': '200 - 300', 'min': '200', 'max': '300'},
    {'label': '300 - 500', 'min': '300', 'max': '500'},
    {'label': '500 - 700', 'min': '500', 'max': '700'},
    {'label': '700 - 1000', 'min': '700', 'max': '1000'},
  ];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      final controller = Get.find<BrandsController>();
      debugPrint(
          '[BRANDS_UI] init controller hash=${controller.hashCode} items=${controller.brandItems?.length ?? 0} hasMore=${controller.hasMoreData} end=${controller.isEndReached}');
    }

    // Load categories first if not already loaded
    if (Get.find<CategoryController>().categoryList == null) {
      Get.find<CategoryController>().getCategoryList(true);
    }

    // ✅ تحميل أول دفعة فقط (بدون preload لتقليل API calls)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<BrandsController>().getBrandItemList(widget.brandId, 1, true);
      // 🔧 FIX: Reset scroll position after initial load
      _resetScrollPosition();
    });

    // ✅ تحسين Listener للـ Scroll - Prefetch ذكي عند 70% من القائمة
    scrollController.addListener(() {
      final brandsController = Get.find<BrandsController>();
      if (kDebugMode) {
        debugPrint(
          '[BRANDS_UI] scroll pixels=${scrollController.position.pixels.toStringAsFixed(1)} '
          'max=${scrollController.position.maxScrollExtent.toStringAsFixed(1)} '
          'offset=${brandsController.offset} hasMore=${brandsController.hasMoreData} '
          'isLoading=${brandsController.isLoading} isLoadingMore=${brandsController.isLoadingMore} '
          'isEndReached=${brandsController.isEndReached}',
        );
      }
      if (brandsController.hasReachedEnd || brandsController.isEndReached) {
        _hasReachedEnd = true;
        return;
      }
      if (_hasReachedEnd) {
        return;
      }

      // 🔧 FIX: Prefetch عند 70% من القائمة (بدلاً من 300px فقط)
      // هذا يجعل التحميل أسرع وأكثر سلاسة للمستخدم
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final scrollPercentage =
          maxScroll > 0 ? (currentScroll / maxScroll) : 0.0;

      // Trigger عند 70% من القائمة (أو 300px قبل النهاية إذا القائمة صغيرة)
      final shouldPrefetch = scrollPercentage >= 0.6 ||
          (currentScroll >= maxScroll - 300 && maxScroll > 300);

      if (shouldPrefetch) {
        // Let controller decide pagination eligibility.
        // UI should only avoid firing while actively loading/searching.
        if (brandsController.isLoading ||
            brandsController.isLoadingMore ||
            brandsController.isSearching) {
          return;
        }

        // 🔧 FIX: Calculate next offset based on limit (12 items per page)
        // API uses offset as page index (1-based), so we increment by 1 for each page
        final nextOffset = brandsController.offset + 1; // Page-based pagination

        if (kDebugMode) {
          debugPrint(
              '[BRANDS_UI] near bottom -> requesting loadMore offset=$nextOffset (scroll: ${(scrollPercentage * 100).toStringAsFixed(1)}%)');
        }

        brandsController.getBrandItemList(
          widget.brandId,
          nextOffset,
          true,
        );
      }
    });
  }

  // 🔧 FIX: Helper method to reset scroll position
  void _resetScrollPosition() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void _resetPaginationGuard() {
    _hasReachedEnd = false;
    if (Get.isRegistered<BrandsController>()) {
      Get.find<BrandsController>().resetReachedEndForBrand(widget.brandId);
    }
  }

  @override
  void dispose() {
    scrollController.dispose(); // ✅ Dispose ScrollController لمنع memory leaks
    _searchController.dispose();
    // Reset controller states when leaving the screen
    final brandsController = Get.find<BrandsController>();
    brandsController.resetFilterState(notify: false);
    brandsController.resetLoadingStates(notify: false);
    // 🔥 Cancel all non-critical API calls when user navigates away
    brandsController.cancelBackgroundRequests();
    super.dispose();
  }

  List<Item> _applyLocalBrandFilters(List<Item> items) {
    final List<Item> filtered = List<Item>.from(items);
    final double? minPrice =
        _minPrice.isNotEmpty ? double.tryParse(_minPrice) : null;
    final double? maxPrice =
        _maxPrice.isNotEmpty ? double.tryParse(_maxPrice) : null;

    if (minPrice != null && minPrice > 0) {
      filtered.removeWhere((item) => (item.price ?? 0) < minPrice);
    }
    if (maxPrice != null && maxPrice > 0) {
      filtered.removeWhere((item) => (item.price ?? 0) > maxPrice);
    }

    final brandsController = Get.find<BrandsController>();
    if (_isPriceSortActive) {
      filtered.sort((a, b) {
        final double priceA = (a.price ?? 0).toDouble();
        final double priceB = (b.price ?? 0).toDouble();
        return brandsController.isPriceAscending
            ? priceA.compareTo(priceB)
            : priceB.compareTo(priceA);
      });
    } else if (_selectedSort == 'ascending' || _selectedSort == 'descending') {
      filtered.sort((a, b) {
        final String nameA = (a.name ?? '').toLowerCase();
        final String nameB = (b.name ?? '').toLowerCase();
        return _selectedSort == 'ascending'
            ? nameA.compareTo(nameB)
            : nameB.compareTo(nameA);
      });
    }

    return filtered;
  }

  bool _hasActiveBrandFilters(BrandsController controller) {
    return _selectedSort != 'popular' ||
        (_minPrice.isNotEmpty && _minPrice != '0') ||
        (_maxPrice.isNotEmpty && _maxPrice != '0') ||
        _searchController.text.trim().isNotEmpty ||
        controller.searchText.trim().isNotEmpty;
  }

  void _resetBrandFiltersAndReload(BrandsController controller) {
    setState(() {
      _selectedSort = 'popular';
      _selectedPriceLabel = 'all';
      _minPrice = '';
      _maxPrice = '';
      _isPriceSortActive = false;
      _searchController.clear();
    });
    controller.resetFilters();
    controller.clearLiveSearch();
    controller.getBrandItemList(widget.brandId, 1, true);
  }

  Widget _buildNoResultsWithReset({
    required BuildContext context,
    required BrandsController controller,
    required String message,
  }) {
    final bool canReset = _hasActiveBrandFilters(controller);
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
            top: ResponsiveHelper.isDesktop(context)
                ? context.height * 0.3
                : context.height * 0.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (canReset) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              OutlinedButton(
                onPressed: () => _resetBrandFiltersAndReload(controller),
                child: Text('reset'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Text(
        title,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
    );
  }

  Widget _buildBrandSortOptions(BuildContext context,
      {StateSetter? modalSetState}) {
    final List<String> values = ['popular', 'ascending', 'descending'];
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: values.map((value) {
        final bool isSelected = _selectedSort == value;
        final String label = value == 'popular'
            ? 'popular'.tr
            : value == 'ascending'
                ? 'ascending'.tr
                : 'descending'.tr;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              final updater = modalSetState ?? setState;
              updater(() {
                _selectedSort = value;
                _isPriceSortActive = false;
              });
            }
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBrandPriceRangeChips(BuildContext context,
      {StateSetter? modalSetState}) {
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _priceRanges.map((range) {
        final bool isSelected = _selectedPriceLabel == range['label'];
        final String label =
            range['label'] == 'all' ? 'all'.tr : range['label']!;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              final updater = modalSetState ?? setState;
              updater(() {
                _selectedPriceLabel = range['label']!;
                _minPrice = range['min']!;
                _maxPrice = range['max']!;
              });
            }
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: CustomAppBar(title: widget.brandName),
      // 🎯 PERFORMANCE: Remove GetBuilder wrapping entire screen
      // Use GetBuilder only for specific parts that need rebuilding
      body: GetBuilder<CategoryController>(builder: (categoryController) {
        final Widget headerContent = Column(
          children: [
            WebScreenTitleWidget(title: widget.brandName),

            // Search and Filter Section
            GetBuilder<BrandsController>(
              id: 'filter_controls', // 🎯 PERFORMANCE: Rebuild only filter controls
              builder: (brandsController) {
                final theme = Theme.of(context);
                final tokens = theme.extension<AppColorTokens>()!;
                final Color selectedChipColor = tokens.successSoft;
                final Color selectedChipTextColor = theme.primaryColor;
                final bool hasActiveFilters =
                    _selectedSort != 'popular' ||
                    (_minPrice.isNotEmpty && _minPrice != '0') ||
                    (_maxPrice.isNotEmpty && _maxPrice != '0') ||
                    _searchController.text.trim().isNotEmpty;
                return Container(
                  width: Dimensions.webMaxWidth,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Column(
                    children: [
                      // Filter Controls
                      Row(
                        children: [
                          // Grid/List Toggle
                          InkWell(
                            onTap: () {
                              brandsController.setVerticalItems(
                                  !brandsController.isVertical);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault),
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                              ),
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeExtraSmall),
                              child: Icon(
                                  brandsController.isVertical
                                      ? Icons.list
                                      : Icons.grid_view,
                                  size: 24,
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),

                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          // Price Sort Toggle
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isPriceSortActive = true;
                              });
                              brandsController.setPriceLocal(
                                  !brandsController.isPriceAscending);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault),
                                color: brandsController.isPriceAscending
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.1)
                                    : selectedChipColor,
                              ),
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeExtraSmall),
                              child: Icon(
                                  brandsController.isPriceAscending
                                      ? Icons.trending_down
                                      : Icons.trending_up,
                                  size: 28,
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),

                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          // Filter Categories Button
                          InkWell(
                            onTap: () {
                              _showFilterBottomSheet(context, brandsController);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault),
                                color: hasActiveFilters
                                    ? selectedChipColor
                                    : Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeSmall,
                                  vertical: Dimensions.paddingSizeExtraSmall),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 20,
                                    color: hasActiveFilters
                                        ? selectedChipTextColor
                                        : Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'filter'.tr,
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: hasActiveFilters
                                          ? selectedChipTextColor
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Expanded(child: SizedBox()),
                        ],
                      ),

                      const SizedBox(height: Dimensions.paddingSizeSmall),
                    ],
                  ),
                );
              },
            ),
          ],
        );

        return CustomScrollView(
              controller: scrollController,
              slivers: [
                // Header Section
                SliverToBoxAdapter(
                  child: isDesktop
                      ? FooterView(
                          minHeight: 0,
                          child: headerContent,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall,
                          ),
                          child: headerContent,
                        ),
                ),

                // 🔧 FIX: Items list as Sliver (prevents nested scrollable widgets)
                GetBuilder<BrandsController>(
                  id: 'items_list', // Rebuild only when items change
                  builder: (brandsController) {
                    // 🔧 FIX: Reset scroll position when loading new data (offset=1)
                    // This prevents "empty space at top" issue after reload/refresh
                    // Only reset if offset changed from >1 to 1 (not on every rebuild)
                    final currentOffset = brandsController.offset;
                    if (currentOffset == 1 &&
                        _lastOffset != null &&
                        _lastOffset! > 1 &&
                        brandsController.brandItems != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _resetScrollPosition();
                      });
                      _resetPaginationGuard();
                    }
                    _lastOffset = currentOffset;

                    // Handle search results
                    if (brandsController.isSearching) {
                      if (brandsController.isLiveSearching) {
                        final liveResults = brandsController.liveSearchResults;
                        if (brandsController.isLoading || liveResults == null) {
                          return SliverFillRemaining(
                            child: _buildSearchingIndicator(context),
                          );
                        }
                        if (liveResults.isNotEmpty) {
                          final filteredLiveResults =
                              _applyLocalBrandFilters(liveResults);
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeSmall,
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                            sliver: _buildSliverItemsView(
                              context,
                              filteredLiveResults,
                              brandsController.isVertical,
                            ),
                          );
                        }
                        return SliverFillRemaining(
                          child: _buildNoResultsWithReset(
                            context: context,
                            controller: brandsController,
                            message:
                                'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.',
                          ),
                        );
                      }

                      if (brandsController.isLoading) {
                        return SliverFillRemaining(
                          child: _buildSearchingIndicator(context),
                        );
                      }

                      final searchItems =
                          brandsController.brandSearchItemModel?.items ?? [];
                      if (searchItems.isNotEmpty) {
                        final filteredSearchItems =
                            _applyLocalBrandFilters(searchItems);
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall,
                            vertical: Dimensions.paddingSizeSmall,
                          ),
                          sliver: _buildSliverItemsView(
                            context,
                            filteredSearchItems,
                            brandsController.isVertical,
                          ),
                        );
                      }

                      return SliverFillRemaining(
                        child: _buildNoResultsWithReset(
                          context: context,
                          controller: brandsController,
                          message:
                              'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.',
                        ),
                      );
                    }

                    // Handle brand items
                    final brandItems = brandsController.brandItems;
                    final bool showOfflineBrandError =
                        !Get.find<SplashController>().hasConnection &&
                            !brandsController.isLoading &&
                            (brandItems == null || brandItems.isEmpty);

                    // ✅ FIX: Show beautiful loading animation when items are being fetched
                    if (brandsController.isLoading &&
                        (brandItems == null || brandItems.isEmpty)) {
                      return SliverFillRemaining(
                        child: _buildInitialLoadingView(context),
                      );
                    }

                    if (brandItems != null && brandItems.isNotEmpty) {
                      final filteredBrandItems =
                          _applyLocalBrandFilters(brandItems);
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        sliver: _buildSliverItemsViewWithPagination(
                          context,
                          filteredBrandItems,
                          brandsController,
                          verticalItem: brandsController.isVertical,
                        ),
                      );
                    } else if (showOfflineBrandError ||
                        (brandItems == null && brandsController.isBrandLoadError)) {
                      // API failed / timeout — show error + retry
                      return SliverFillRemaining(
                        child: ErrorStateView(
                          onRetry: () => brandsController.getBrandItemList(
                            widget.brandId,
                            1,
                            true,
                          ),
                        ),
                      );
                    } else {
                      return SliverFillRemaining(
                        child: _buildNoResultsWithReset(
                          context: context,
                          controller: brandsController,
                          message: _hasActiveBrandFilters(brandsController)
                              ? 'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.'
                              : 'no_brand_item_found'.tr,
                        ),
                      );
                    }
                  },
                ),
              ],
        );
      }),
    );
  }

  Widget _buildSearchingIndicator(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'searching_for_products'.tr,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
      BuildContext context, BrandsController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'filter'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, 'sort_by'.tr),
                        _buildBrandSortOptions(context,
                            modalSetState: modalSetState),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildSectionTitle(context, 'product_name'.tr),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'search_for_items'.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault),
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildSectionTitle(context, 'price_range'.tr),
                        _buildBrandPriceRangeChips(context,
                            modalSetState: modalSetState),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          controller.resetFilters();
                          modalSetState(() {
                            _selectedSort = 'popular';
                            _selectedPriceLabel = 'all';
                            _minPrice = '';
                            _maxPrice = '';
                            _isPriceSortActive = false;
                            _searchController.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeDefault),
                        ),
                        child: Text('reset'.tr),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final String query = _searchController.text.trim();
                          if (query.isNotEmpty) {
                            controller.getBrandSearchItemList(
                              query,
                              widget.brandId,
                              offset: 1,
                            );
                          } else {
                            controller.clearLiveSearch();
                            controller.clearCategorySelections();
                            controller.applyCategoryFilter();
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeDefault),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          'apply'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎯 PERFORMANCE: Build items view (kept for backward compatibility)
  /// Note: Now using Sliver version in main screen
  @pragma('vm:entry-point')
  Widget _buildBrandItemsView(List<Item> items, {bool? verticalItem}) {
    // Use controller's verticalItem if not provided
    final isVertical = verticalItem ?? Get.find<BrandsController>().isVertical;

    return ItemsView(
      isStore: false,
      stores: null,
      items: items,
      verticalItem: isVertical,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeSmall,
      ),
    );
  }

  /// 🔧 FIX: Build Sliver for items view (for search results)
  Widget _buildSliverItemsView(
      BuildContext context, List<Item> items, bool isVertical) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    if (isVertical) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ItemWidget(
              key: ValueKey('item_${items[index].id}_$index'),
              isStore: false,
              item: items[index],
              store: null,
              index: index,
              length: items.length,
              verticalItem: true,
            );
          },
          childCount: items.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisSpacing: isDesktop
              ? Dimensions.paddingSizeExtremeLarge
              : Dimensions.paddingSizeLarge,
          mainAxisSpacing: isDesktop
              ? Dimensions.paddingSizeExtremeLarge
              : Dimensions.paddingSizeSmall,
          mainAxisExtent: isDesktop ? 220 : 200,
          crossAxisCount: isDesktop ? 3 : 2,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return ItemWidget(
            key: ValueKey('item_${items[index].id}_$index'),
            isStore: false,
            item: items[index],
            store: null,
            index: index,
            length: items.length,
            verticalItem: false,
          );
        },
        childCount: items.length,
      ),
    );
  }

  /// 🔧 FIX: Build Sliver with pagination loader inside the list
  /// This prevents nested scrollable widgets (RenderBox layout error)
  Widget _buildSliverItemsViewWithPagination(
    BuildContext context,
    List<Item> items,
    BrandsController controller, {
    bool? verticalItem,
  }) {
    final isVertical = verticalItem ?? controller.isVertical;
    final isLoadingMore = controller.isLoadingMore;
    final hasMore = controller.hasMoreData;
    final lastRequestUniqueItems =
        controller.lastRequestUniqueItemsCount ?? 999; // Default to high number
    final showEndReachedMessage = !isLoadingMore &&
        controller.isEndReached &&
        controller.offset > 1 &&
        items.isNotEmpty;
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    // 🛑 CRITICAL FIX: Only show loader if we got more than 1 unique item in last request
    // This prevents showing loader when pagination has effectively stopped
    final showLoader = isLoadingMore && hasMore && lastRequestUniqueItems > 1;

    // 🔧 FIX: Calculate item count including pagination loader
    final itemCount =
        items.length + (showLoader ? 1 : 0) + (showEndReachedMessage ? 1 : 0);

    if (isVertical) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Show items
            if (index < items.length) {
              return ItemWidget(
                key: ValueKey('item_${items[index].id}_$index'),
                isStore: false,
                item: items[index],
                store: null,
                index: index,
                length: items.length,
                verticalItem: true,
              );
            }

            if (showLoader) {
              return _buildPaginationLoader(context, controller);
            }

            return _buildEndReachedIndicator(context);
          },
          childCount: itemCount,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisSpacing: isDesktop
              ? Dimensions.paddingSizeExtremeLarge
              : Dimensions.paddingSizeLarge,
          mainAxisSpacing: isDesktop
              ? Dimensions.paddingSizeExtremeLarge
              : Dimensions.paddingSizeSmall,
          mainAxisExtent: isDesktop ? 220 : 200,
          crossAxisCount: isDesktop ? 3 : 2,
        ),
      );
    }

    // Horizontal list view
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Show items
          if (index < items.length) {
            return ItemWidget(
              key: ValueKey('item_${items[index].id}_$index'),
              isStore: false,
              item: items[index],
              store: null,
              index: index,
              length: items.length,
              verticalItem: false,
            );
          }

          if (showLoader) {
            return _buildPaginationLoader(context, controller);
          }

          return _buildEndReachedIndicator(context);
        },
        childCount: itemCount,
      ),
    );
  }

  Widget _buildEndReachedIndicator(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          'لا يوجد المزيد من النتائج',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 13,
              ),
        ),
      ),
    );
  }

  /// 🔥 UX: Elegant pagination loader with skeleton cards
  /// Shows animated skeleton that mimics actual product cards
  /// 🔧 FIX: Must have fixed height for Sliver compatibility (prevents RenderBox layout error)
  Widget _buildPaginationLoader(
      BuildContext context, BrandsController controller) {
    // 🔧 FIX: Container with fixed height - required for Sliver layout
    // Slivers require children with known sizes (cannot be unbounded)
    return SizedBox(
      height: 80, // Fixed height - safe for both GridView and ListView
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Take minimum space needed
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'جاري تحميل المزيد...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 UX: Skeleton cards that mimic actual product cards
  /// Creates illusion that products are loading (like Amazon/Talabat)
  /// Note: Currently using simple loader, uncomment in _buildPaginationLoader to use skeleton cards
  @pragma('vm:entry-point')
  List<Widget> _buildPaginationSkeletonCards(BuildContext context) {
    final isVertical = Get.find<BrandsController>().isVertical;

    return List.generate(2, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          color: Colors.grey[300]!,
          child: Container(
            height: isVertical ? 200 : 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: isVertical
                ? Column(
                    children: [
                      // Image skeleton
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(Dimensions.radiusDefault),
                            topRight: Radius.circular(Dimensions.radiusDefault),
                          ),
                        ),
                      ),
                      // Content skeleton
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                              ),
                              Container(
                                height: 14,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Image skeleton
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                      // Content skeleton
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                              ),
                              Container(
                                height: 14,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 16,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    height: 28,
                                    width: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  /// ✨ Beautiful animated loading view for initial product loading
  /// Shows engaging animation to keep user entertained while products load
  Widget _buildInitialLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated shopping bag icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: 0.5 + (0.5 * value),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Loading indicator
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Loading text
          Text(
            'جاري تحميل المنتجات...',
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'يرجى الانتظار قليلاً',
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
            ),
          ),

          const SizedBox(height: 32),

          // Animated dots
          _buildAnimatedDots(context),
        ],
      ),
    );
  }

  /// Animated loading dots
  Widget _buildAnimatedDots(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(
                      alpha: 0.3 + (0.7 * ((value + index * 0.3) % 1.0)),
                    ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  /// 🎯 UX: Skeleton loading that mimics actual item cards
  /// Shows 6 skeleton cards immediately - user sees content structure, not blank screen
}

// class BrandItemScreenShimmer extends StatelessWidget {
//   const BrandItemScreenShimmer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ResponsiveHelper.isDesktop(context)
//         ? GridView.builder(
//             shrinkWrap: true,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               mainAxisExtent: 150,
//             ),
//             itemCount: 12,
//             itemBuilder: (context, index) {
//               return Shimmer(
//                 duration: const Duration(seconds: 2),
//                 enabled: true,
//                 colorOpacity: 0.1,
//                 child: Container(
//                   height: 100,
//                   margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//                   padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//                   decoration: BoxDecoration(
//                     color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[300],
//                     borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//                     boxShadow: [
//                       BoxShadow(
//                           color: Get.isDarkMode ? Colors.black12 : Colors.grey.withValues(alpha: 0.1),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                           offset: const Offset(0, 1))
//                     ],
//                   ),
//                   child: Row(children: [
//                     Container(
//                       height: 80,
//                       width: 80,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//                         color: Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor,
//                       ),
//                     ),
//                     const SizedBox(width: Dimensions.paddingSizeSmall),
//                     Expanded(
//                       child:
//                           Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
//                         Container(
//                             height: 20,
//                             width: double.maxFinite,
//                             color:
//                                 Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor),
//                         const SizedBox(height: Dimensions.paddingSizeSmall),
//                         Container(
//                             height: 15,
//                             width: double.maxFinite,
//                             color:
//                                 Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor),
//                         const SizedBox(height: Dimensions.paddingSizeSmall),
//                         Container(
//                             height: 15,
//                             width: double.maxFinite,
//                             color:
//                                 Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor),
//                       ]),
//                     ),
//                   ]),
//                 ),
//               );
//             },
//           )
//         : ListView.builder(
//             itemCount: 8,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemBuilder: (context, index) {
//               return Shimmer(
//                 duration: const Duration(seconds: 2),
//                 enabled: true,
//                 colorOpacity: 0.1,
//                 child: Container(
//                   height: 100,
//                   margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//                   padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//                   decoration: BoxDecoration(
//                     color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[300],
//                     borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//                     boxShadow: [
//                       BoxShadow(
//                           color: Get.isDarkMode ? Colors.black12 : Colors.grey.withValues(alpha: 0.1),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                           offset: const Offset(0, 1))
//                     ],
//                   ),
//                   child: Row(children: [
//                     Container(
//                       height: 80,
//                       width: 80,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//                         color: Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor,
//                       ),
//                     ),
//                     const SizedBox(width: Dimensions.paddingSizeSmall),
//                     Expanded(
//                       child:
//                           Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
//                         Container(
//                             height: 20,
//                             width: double.maxFinite,
//                             color:
//                                 Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor),
//                         const SizedBox(height: Dimensions.paddingSizeSmall),
//                         Container(
//                             height: 15,
//                             width: double.maxFinite,
//                             color:
//                                 Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor),
//                         const SizedBox(height: Dimensions.paddingSizeSmall),
//                         Container(
//                             height: 15,
//                             width: double.maxFinite,
//                             color:
//                                 Get.isDarkMode ? Theme.of(context).disabledColor.withValues(alpha: 0.2) : Theme.of(context).cardColor),
//                       ]),
//                     ),
//                   ]),
//                 ),
//               );
//             },
//           );
//   }
// }
