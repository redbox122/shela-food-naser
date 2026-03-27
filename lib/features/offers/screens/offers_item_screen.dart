import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
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

  bool _hasActiveOffersFilters(Offers_Controller controller) {
    return _selectedSort != 'popular' ||
        (_minPrice.isNotEmpty && _minPrice != '0') ||
        (_maxPrice.isNotEmpty && _maxPrice != '0') ||
        controller.selectedCategoryIds.isNotEmpty ||
        _searchController.text.trim().isNotEmpty ||
        controller.searchText.trim().isNotEmpty;
  }

  void _resetOffersFiltersAndReload(Offers_Controller controller) {
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
    required Offers_Controller controller,
    required String message,
  }) {
    final bool canReset = _hasActiveOffersFilters(controller);
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          top: ResponsiveHelper.isDesktop(context)
              ? context.height * 0.3
              : context.height * 0.4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (canReset) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              OutlinedButton(
                onPressed: () => _resetOffersFiltersAndReload(controller),
                child: Text('reset'.tr),
              ),
            ],
          ],
        ),
      ),
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
      Get.find<Offers_Controller>().getOffersItemList(
        id: widget.offerId.toString(),
        offset: 1,
        forceRefresh: true,
      );
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          Get.find<Offers_Controller>().offersItemList != null &&
          !Get.find<Offers_Controller>().isItemsLoading &&
          !_isLoadingMore) {
        // Calculate total pages based on total items and items per page (20)
        final int totalItems = Get.find<Offers_Controller>().pageSize ?? 0;
        const int itemsPerPage = 20; // API limit is 20 items per page
        final int totalPages = (totalItems / itemsPerPage).ceil();

        if (Get.find<Offers_Controller>().offset < totalPages) {
          if (kDebugMode) {
            print(
                'end of the page - loading page ${Get.find<Offers_Controller>().offset + 1} of $totalPages');
          }

          _isLoadingMore = true; // Set flag to prevent multiple calls
          Get.find<Offers_Controller>().showBottomLoader();

          if (Get.find<Offers_Controller>().isSearching) {
            // For live search, we don't need pagination since we have all results
            if (!Get.find<Offers_Controller>().isLiveSearching) {
              // Only use API search for pagination if not using live search
              Get.find<Offers_Controller>()
                  .getOffersSearchItemList(
                Get.find<Offers_Controller>().searchText,
                offerId: widget.offerId.toString(),
                offset: Get.find<Offers_Controller>().offset + 1,
              )
                  .then((_) {
                _isLoadingMore = false; // Reset flag after completion
              });
            } else {
              _isLoadingMore = false; // Reset flag for live search
            }
          } else {
            Get.find<Offers_Controller>()
                .getOffersItemList(
                    id: widget.offerId.toString(),
                    offset: Get.find<Offers_Controller>().offset + 1)
                .then((_) {
              _isLoadingMore = false; // Reset flag after completion
            });
          }
        } else {
          if (kDebugMode) {
            print('No more pages to load - reached page $totalPages');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
    scrollController.dispose();
    _isLoadingMore = false; // Reset loading flag
    // Reset controller states when leaving the screen
    Get.find<Offers_Controller>().resetFilterState(notify: false);
    Get.find<Offers_Controller>().resetLoadingStates(notify: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: CustomAppBar(title: widget.offerName),
      body: SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: GetBuilder<Offers_Controller>(builder: (offersController) {
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
          const Color selectedChipColor = Color(0xFFC8E6C9);
          final bool hasActiveFilters =
              _selectedSort != 'popular' ||
              (_minPrice.isNotEmpty && _minPrice != '0') ||
              (_maxPrice.isNotEmpty && _maxPrice != '0') ||
              offersController.selectedCategoryIds.isNotEmpty ||
              _searchController.text.trim().isNotEmpty;
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await Get.find<Offers_Controller>().getOffersItemList(
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
                      Container(
                        width: Dimensions.webMaxWidth,
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(
                          children: [
                            // Filter Controls
                            Row(
                              children: [
                                // Grid/List Toggle
                                InkWell(
                                  onTap: () {
                                    offersController.setVerticalItems(
                                        !offersController.isVertical);
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
                                        offersController.isVertical
                                            ? Icons.list
                                            : Icons.grid_view,
                                        size: 24,
                                        color: Theme.of(context).primaryColor),
                                  ),
                                ),

                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),

                                // Price Sort Toggle
                                InkWell(
                                  onTap: () {
                                    offersController.setPrice(
                                        !offersController.isPriceAscending);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault),
                                      color: offersController.isPriceAscending
                                          ? Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.1)
                                          : selectedChipColor,
                                    ),
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeExtraSmall),
                                    child: Icon(
                                        offersController.isPriceAscending
                                            ? Icons.trending_down
                                            : Icons.trending_up,
                                        size: 28,
                                        color: Theme.of(context).primaryColor),
                                  ),
                                ),

                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),

                                // Filter Categories Button
                                InkWell(
                                  onTap: () {
                                    _showFilterBottomSheet(
                                        context, offersController);
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
                                        vertical:
                                            Dimensions.paddingSizeExtraSmall),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.filter_list,
                                          size: 20,
                                          color: hasActiveFilters
                                              ? const Color(0xFF1B5E20)
                                              : Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'filter'.tr,
                                          style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: hasActiveFilters
                                                ? const Color(0xFF1B5E20)
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
                      ),

                      SizedBox(
                        width: Dimensions.webMaxWidth,
                        child: _buildOffersContent(
                          context,
                          offersController,
                          isDesktop,
                        ),
                      ),

                      offersController.isItemsLoading
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
    Offers_Controller offersController,
    bool isDesktop,
  ) {
    if (offersController.isSearching) {
      if (offersController.isLiveSearching) {
        final liveResults = offersController.liveSearchResults;
        if (offersController.isItemsLoading || liveResults == null) {
          return _buildSearchingIndicator(context);
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
        return _buildSearchingIndicator(context);
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
      return _buildLoadingShimmer();
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
              Get.find<Offers_Controller>().getOffersItemList(
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
      BuildContext context, Offers_Controller controller) {
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
          builder: (context, scrollController) => SafeArea(
            top: false,
            bottom: true,
            left: false,
            right: false,
            minimum: EdgeInsets.zero,
            child: Container(
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
                        _buildSectionTitle('sort_by'.tr),
                        _buildSortChips(modalSetState: modalSetState),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildSectionTitle('product_name'.tr),
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
                        _buildSectionTitle('price_range'.tr),
                        _buildPriceRangeChips(modalSetState: modalSetState),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildSectionTitle('filter_categories'.tr),
                        _buildCategoryChips(controller,
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
                          if (_selectedSort == 'ascending') {
                            controller.setPrice(true);
                          } else if (_selectedSort == 'descending') {
                            controller.setPrice(false);
                          }
                          final String query = _searchController.text.trim();
                          if (query.isNotEmpty) {
                            controller.getOffersSearchItemList(
                              query,
                              offerId: widget.offerId.toString(),
                              offset: 1,
                            );
                          } else {
                            controller.clearLiveSearch();
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Text(
        title,
        style: robotoBold.copyWith(
          fontSize: Dimensions.fontSizeDefault,
        ),
      ),
    );
  }

  Widget _buildSortChips({StateSetter? modalSetState}) {
    const Color selectedChipColor = Color(0xFFC8E6C9);
    const values = <String>['popular', 'ascending', 'descending'];
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
          showCheckmark: true,
          checkmarkColor: const Color(0xFF1B5E20),
          onSelected: (selected) {
            if (!selected) return;
            final updater = modalSetState ?? setState;
            updater(() {
              _selectedSort = value;
            });
          },
          selectedColor: selectedChipColor,
          labelStyle: TextStyle(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeChips({StateSetter? modalSetState}) {
    const Color selectedChipColor = Color(0xFFC8E6C9);
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
          showCheckmark: true,
          checkmarkColor: const Color(0xFF1B5E20),
          onSelected: (selected) {
            if (!selected) return;
            final updater = modalSetState ?? setState;
            updater(() {
              _selectedPriceLabel = range['label']!;
              _minPrice = range['min']!;
              _maxPrice = range['max']!;
            });
          },
          selectedColor: selectedChipColor,
          labelStyle: TextStyle(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips(Offers_Controller controller,
      {StateSetter? modalSetState}) {
    if (controller.categoryList == null || controller.categoryList!.isEmpty) {
      return Text(
        'no_categories_available'.tr,
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Theme.of(context).disabledColor,
        ),
      );
    }

    const Color selectedChipColor = Color(0xFFC8E6C9);
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: controller.categoryList!.map((category) {
        final int categoryId = category.id ?? 0;
        final bool isSelected =
            controller.selectedCategoryIds.contains(categoryId);
        return ChoiceChip(
          label: Text(category.name ?? ''),
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: const Color(0xFF1B5E20),
          onSelected: (_) {
            controller.toggleCategorySelection(categoryId);
            final updater = modalSetState ?? setState;
            updater(() {});
          },
          selectedColor: selectedChipColor,
          labelStyle: TextStyle(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOffersItemsView(List<Item> items, {bool isSearching = false}) {
    return GetBuilder<Offers_Controller>(builder: (offersController) {
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

      return ItemsView(
        isStore: false,
        stores: null,
        items: filteredItems,
        verticalItem: offersController.isVertical,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        noDataText: _hasActiveOffersFilters(offersController)
            ? 'ما في نتائج بهاي الفلاتر.\nجرّب كلمة ثانية أو صفّر الفلتر.'
            : 'no_item_available'.tr,
        noDataActionText: 'reset'.tr,
        onNoDataActionTap: _hasActiveOffersFilters(offersController)
            ? () => _resetOffersFiltersAndReload(offersController)
            : null,
      );
    });
  }

  /// ⚡ TASK 3: Neutral Grey Shimmer - No purple gradients
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Row(
                children: [
                  // Image placeholder - neutral grey only
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title placeholder
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                          ),
                          // Subtitle placeholder
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                          ),
                          // Price and icon row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                height: 20,
                                width: 20,
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
      },
    );
  }
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
