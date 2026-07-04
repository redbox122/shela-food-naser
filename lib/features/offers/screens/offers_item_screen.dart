import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/category/widgets/grocery_category/grocery_product_grid.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/offers/widgets/offers_loading_shimmer.dart';
import 'package:sixam_mart/features/offers/widgets/offers_searching_indicator.dart';
import 'package:sixam_mart/features/offers/widgets/offers_no_results_view.dart';
import 'package:sixam_mart/features/offers/widgets/offers_filter_controls_row.dart';
import 'package:sixam_mart/features/offers/widgets/offers_filter_sheet.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import '../controllers/offers_controller.dart';

class OffersItemScreen extends StatefulWidget {
  final int offerId;
  final String offerName;
  final double? offerDiscount; // Add offer discount parameter
  const OffersItemScreen(
      {super.key,
      required this.offerId,
      required this.offerName,
      this.offerDiscount});

  @override
  State<OffersItemScreen> createState() => _OffersItemScreen();
}

class _OffersItemScreen extends State<OffersItemScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false; // Prevent multiple simultaneous pagination calls
  bool _showSearchBar = false; // Toggled by the AppBar search (lens) icon.
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedSort = 'popular';
  String _selectedPriceLabel = 'all';
  String _minPrice = '';
  String _maxPrice = '';
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

  // Show/hide the inline search bar from the AppBar lens icon.
  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        _searchFocusNode.unfocus();
        Get.find<OffersController>().clearLiveSearch();
      }
    });
  }

  bool _hasActiveOffersFilters(OffersController controller) {
    return _selectedSort != 'popular' ||
        (_minPrice.isNotEmpty && _minPrice != '0') ||
        (_maxPrice.isNotEmpty && _maxPrice != '0') ||
        controller.selectedCategoryIds.isNotEmpty ||
        _searchController.text.trim().isNotEmpty ||
        controller.searchText.trim().isNotEmpty;
  }

  void _resetOffersFiltersAndReload(OffersController controller) {
    setState(() {
      _selectedSort = 'popular';
      _selectedPriceLabel = 'all';
      _minPrice = '';
      _maxPrice = '';
      _searchController.clear();
    });
    controller.resetFilters();
    controller.clearLiveSearch();
    controller.getOffersItemList(
      id: widget.offerId.toString(),
      offset: 1,
      forceRefresh: true,
    );
  }

  Widget _buildNoResultsWithReset({
    required BuildContext context,
    required OffersController controller,
    required String message,
  }) {
    return OffersNoResultsView(
      message: message,
      canReset: _hasActiveOffersFilters(controller),
      onReset: () => _resetOffersFiltersAndReload(controller),
    );
  }

  @override
  void initState() {
    super.initState();

    // Load categories first if not already loaded
    if (Get.find<CategoryController>().categoryList == null) {
      Get.find<CategoryController>().getCategoryList(true);
    }

    // Load initial data after build - categories will be extracted from API response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OffersController>().getOffersItemList(
        id: widget.offerId.toString(),
        offset: 1,
        forceRefresh: true,
      );
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          Get.find<OffersController>().offersItemList != null &&
          !Get.find<OffersController>().isItemsLoading &&
          !_isLoadingMore) {
        // Calculate total pages based on total items and items per page (20)
        final int totalItems = Get.find<OffersController>().pageSize ?? 0;
        const int itemsPerPage = 20; // API limit is 20 items per page
        final int totalPages = (totalItems / itemsPerPage).ceil();

        if (Get.find<OffersController>().offset < totalPages) {
          if (kDebugMode) {
            debugPrint(
                'end of the page - loading page ${Get.find<OffersController>().offset + 1} of $totalPages');
          }

          _isLoadingMore = true; // Set flag to prevent multiple calls
          Get.find<OffersController>().showBottomLoader();

          if (Get.find<OffersController>().isSearching) {
            // For live search, we don't need pagination since we have all results
            if (!Get.find<OffersController>().isLiveSearching) {
              // Only use API search for pagination if not using live search
              Get.find<OffersController>()
                  .getOffersSearchItemList(
                Get.find<OffersController>().searchText,
                offerId: widget.offerId.toString(),
                offset: Get.find<OffersController>().offset + 1,
              )
                  .then((_) {
                _isLoadingMore = false; // Reset flag after completion
              });
            } else {
              _isLoadingMore = false; // Reset flag for live search
            }
          } else {
            Get.find<OffersController>()
                .getOffersItemList(
                    id: widget.offerId.toString(),
                    offset: Get.find<OffersController>().offset + 1)
                .then((_) {
              _isLoadingMore = false; // Reset flag after completion
            });
          }
        } else {
          if (kDebugMode) {
            debugPrint('No more pages to load - reached page $totalPages');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    scrollController.dispose();
    _isLoadingMore = false; // Reset loading flag
    // Reset controller states when leaving the screen
    Get.find<OffersController>().resetFilterState(notify: false);
    Get.find<OffersController>().resetLoadingStates(notify: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // White header: centered title + cart icon at the end (RTL: left).
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        // Soft drop shadow under the header (always visible).
        elevation: 4,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'offers_and_discounts'.tr,
          textAlign: TextAlign.center,
          style: tajawalBold.copyWith(
            fontSize: 18,
            height: 1.6,
            letterSpacing: 0,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          // Search (lens) icon — sits next to the cart. Toggles an inline
          // search bar wired to the existing live-search logic.
          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: _toggleSearchBar,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _showSearchBar ? Icons.close : Icons.search,
                size: 26,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  Images.navBag,
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ],
        // Inline search field, only visible when the lens is toggled on.
        bottom: _showSearchBar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    0,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeSmall,
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => Get.find<OffersController>()
                        .performLiveSearch(value),
                    onSubmitted: (value) => Get.find<OffersController>()
                        .performLiveSearch(value),
                    style: tajawalRegular.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ابحث في العروض...',
                      hintStyle: tajawalRegular.copyWith(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).hintColor, size: 22),
                      suffixIcon: _searchController.text.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                Get.find<OffersController>().clearLiveSearch();
                                setState(() {});
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: GetBuilder<OffersController>(builder: (offersController) {
          final bool hasNoOfferItems =
              (offersController.offersItemList == null ||
                  offersController.offersItemList!.isEmpty);
          final bool shouldShowOffersNetworkError =
              (!Get.find<SplashController>().hasConnection ||
                      offersController.hasItemsError) &&
                  !offersController.isItemsLoading &&
                  !offersController.isSearching &&
                  hasNoOfferItems;
          if (shouldShowOffersNetworkError) {
            return ErrorStateView(
              onRetry: () {
                offersController.getOffersItemList(
                  id: widget.offerId.toString(),
                  offset: 1,
                  forceRefresh: true,
                );
              },
            );
          }
          // Show loading screen for initial load
          if (offersController.offersItemList == null &&
              !offersController.isItemsLoading &&
              !offersController.isSearching) {
            return const Center(
              child: LoadingWidget(),
            );
          }
          return GetBuilder<CategoryController>(builder: (categoryController) {
            final bool hasActiveFilters = _selectedSort != 'popular' ||
                (_minPrice.isNotEmpty && _minPrice != '0') ||
                (_maxPrice.isNotEmpty && _maxPrice != '0') ||
                offersController.selectedCategoryIds.isNotEmpty ||
                _searchController.text.trim().isNotEmpty;
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await Get.find<OffersController>().getOffersItemList(
                      id: widget.offerId.toString(),
                      offset: 1,
                    );
                  },
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: FooterView(
                      child: Column(children: [
                        WebScreenTitleWidget(title: widget.offerName),

                        // Search and Filter Section
                        OffersFilterControlsRow(
                          controller: offersController,
                          hasActiveFilters: hasActiveFilters,
                          onFilterTap: () =>
                              _showFilterBottomSheet(context, offersController),
                        ),

                        SizedBox(
                          width: Dimensions.webMaxWidth,
                          child: _buildOffersContent(
                            context,
                            offersController,
                            isDesktop,
                          ),
                        ),

                        // Footer spinner only during pagination (items already
                        // loaded). The initial load shows the shimmer alone.
                        (offersController.isItemsLoading &&
                                offersController.offersItemList != null &&
                                offersController.offersItemList!.isNotEmpty)
                            ? Center(
                                child: Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeSmall),
                                child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor)),
                              ))
                            : const SizedBox(),
                      ]),
                    ),
                  ),
                ),
              ],
            );
          });
        }),
      ),
    );
  }

  Widget _buildOffersContent(
    BuildContext context,
    OffersController offersController,
    bool isDesktop,
  ) {
    if (offersController.isSearching) {
      if (offersController.isLiveSearching) {
        final liveResults = offersController.liveSearchResults;
        if (offersController.isItemsLoading || liveResults == null) {
          return const OffersSearchingIndicator();
        }
        if (liveResults.isNotEmpty) {
          return _buildOffersItemsView(liveResults, isSearching: true);
        }
        return _buildNoResultsWithReset(
          context: context,
          controller: offersController,
          message: 'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.',
        );
      }

      if (offersController.isItemsLoading &&
          offersController.offersSearchItemModel == null) {
        return const OffersSearchingIndicator();
      }

      final List<Item> searchItems =
          offersController.offersSearchItemModel?.items ?? <Item>[];
      if (searchItems.isNotEmpty) {
        return _buildOffersItemsView(searchItems, isSearching: true);
      }

      return _buildNoResultsWithReset(
        context: context,
        controller: offersController,
        message: 'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.',
      );
    }

    final offerItems = offersController.offersItemList;
    if (offerItems != null) {
      if (offerItems.isNotEmpty) {
        return _buildOffersItemsView(offerItems);
      }
      return _buildNoResultsWithReset(
        context: context,
        controller: offersController,
        message: _hasActiveOffersFilters(offersController)
            ? 'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.'
            : 'no_items_found'.tr,
      );
    }

    if (offersController.isItemsLoading) {
      return OffersLoadingShimmer(isListView: !offersController.isVertical);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'failed_to_load_items'.tr,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Get.find<OffersController>().getOffersItemList(
                id: widget.offerId.toString(),
                offset: 1,
              );
            },
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
      BuildContext context, OffersController controller) {
    // Sort/price selections update the screen's filter state (the source of
    // truth for client-side filtering) without rebuilding while the sheet is
    // open — the controller rebuild on "done" refreshes the list.
    OffersFilterSheet.show(
      context: context,
      controller: controller,
      priceRanges: _priceRanges,
      initialSort: _selectedSort,
      initialPriceLabel: _selectedPriceLabel,
      onSortSelected: (sort) => _selectedSort = sort,
      onPriceRangeSelected: (label, min, max) {
        _selectedPriceLabel = label;
        _minPrice = min;
        _maxPrice = max;
      },
    );
  }

  Widget _buildOffersItemsView(List<Item> items, {bool isSearching = false}) {
    return GetBuilder<OffersController>(builder: (offersController) {
      final List<Item> filteredItems = List<Item>.from(items);

      final double? minPrice =
          _minPrice.isNotEmpty ? double.tryParse(_minPrice) : null;
      final double? maxPrice =
          _maxPrice.isNotEmpty ? double.tryParse(_maxPrice) : null;
      if (minPrice != null && minPrice > 0) {
        filteredItems.removeWhere((item) => (item.price ?? 0) < minPrice);
      }
      if (maxPrice != null && maxPrice > 0) {
        filteredItems.removeWhere((item) => (item.price ?? 0) > maxPrice);
      }

      if (_selectedSort == 'ascending' || _selectedSort == 'descending') {
        filteredItems.sort((a, b) {
          final String nameA = (a.name ?? '').toLowerCase();
          final String nameB = (b.name ?? '').toLowerCase();
          return _selectedSort == 'ascending'
              ? nameA.compareTo(nameB)
              : nameB.compareTo(nameA);
        });
      } else {
        filteredItems.sort((a, b) {
          final double priceA = (a.price ?? 0).toDouble();
          final double priceB = (b.price ?? 0).toDouble();
          return offersController.isPriceAscending
              ? priceA.compareTo(priceB)
              : priceB.compareTo(priceA);
        });
      }

      if (filteredItems.isEmpty) {
        return _buildNoResultsWithReset(
          context: context,
          controller: offersController,
          message: _hasActiveOffersFilters(offersController)
              ? 'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.'
              : 'no_item_available'.tr,
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: GroceryProductGrid(
          items: filteredItems,
          // offers: isVertical == grid (2 columns), otherwise list rows
          isListView: !offersController.isVertical,
          inStore: false,
          offersStyle: true,
        ),
      );
    });
  }
}
