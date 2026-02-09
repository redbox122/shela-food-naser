import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
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
    Get.find<Offers_Controller>().resetLoadingStates(notify: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: CustomAppBar(title: widget.offerName),
      body: GetBuilder<Offers_Controller>(builder: (offersController) {
        // Show loading screen for initial load
        if (offersController.offersItemList == null &&
            !offersController.isItemsLoading &&
            !offersController.isSearching) {
          return const Center(
            child: LoadingWidget(),
          );
        }
        return GetBuilder<CategoryController>(builder: (categoryController) {
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
                            // Search Bar
                            Container(
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault),
                                color: Theme.of(context).cardColor,
                                border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.40)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      textInputAction: TextInputAction.search,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                ),
                                        hintText: 'search_for_items'.tr,
                                        hintStyle: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context)
                                                .disabledColor),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.radiusSmall),
                                            borderSide: BorderSide.none),
                                        filled: true,
                                        fillColor: Theme.of(context).cardColor,
                                        isDense: true,
                                        prefixIcon: Icon(Icons.search,
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.50)),
                                      ),
                                      onChanged: (String value) {
                                        // Live search as user types
                                        offersController
                                            .performLiveSearch(value);
                                      },
                                      onSubmitted: (String? value) {
                                        if (value!.isNotEmpty) {
                                          offersController
                                              .getOffersSearchItemList(
                                            _searchController.text.trim(),
                                            offerId: widget.offerId.toString(),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeSmall),
                                  InkWell(
                                    onTap: () {
                                      if (!offersController.isSearching) {
                                        // Trigger live search if there's text
                                        if (_searchController.text
                                            .trim()
                                            .isNotEmpty) {
                                          offersController.performLiveSearch(
                                              _searchController.text.trim());
                                        }
                                      } else {
                                        // Clear search
                                        _searchController.text = '';
                                        offersController.clearLiveSearch();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.radiusSmall)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                          horizontal:
                                              Dimensions.paddingSizeSmall),
                                      child: offersController.isSearching
                                          ? const Icon(Icons.clear,
                                              color: Colors.white)
                                          : Text('search'.tr,
                                              style: robotoMedium.copyWith(
                                                  color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: Dimensions.paddingSizeSmall),

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
                                            : Icons.filter_list_sharp,
                                        size: 28,
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
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.1),
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
                                    offersController.toggleFilterModal();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault),
                                      color: Theme.of(context)
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
                                          size: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'filter_categories'.tr,
                                          style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        if (offersController
                                            .selectedCategoryIds.isNotEmpty)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${offersController.selectedCategoryIds.length}',
                                              style: robotoMedium.copyWith(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),

                                // Reset Filters Button
                                InkWell(
                                  onTap: () {
                                    offersController.resetFilters();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault),
                                      color: Theme.of(context)
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
                                          Icons.refresh,
                                          size: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'reset'.tr,
                                          style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color:
                                                Theme.of(context).primaryColor,
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
                        child: offersController.isSearching
                            ? (offersController.isLiveSearching
                                ? (offersController.liveSearchResults != null
                                    ? offersController
                                            .liveSearchResults!.isNotEmpty
                                        ? _buildOffersItemsView(offersController.liveSearchResults!,
                                            isSearching: true)
                                        : Center(
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: isDesktop
                                                        ? context.height * 0.3
                                                        : context.height * 0.4),
                                                child: Text(
                                                    'no_results_found'.tr)))
                                    : _buildLoadingShimmer())
                                : (offersController.offersSearchItemModel !=
                                        null
                                    ? offersController.offersSearchItemModel!
                                            .items!.isNotEmpty
                                        ? _buildOffersItemsView(
                                            offersController
                                                .offersSearchItemModel!.items!,
                                            isSearching: true)
                                        : Center(
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: isDesktop
                                                        ? context.height * 0.3
                                                        : context.height * 0.4),
                                                child: Text('no_results_found'.tr)))
                                    : offersController.isItemsLoading
                                        ? _buildLoadingShimmer()
                                        : const Center(child: LoadingWidget())))
                            : (offersController.offersItemList != null
                                ? offersController.offersItemList!.isNotEmpty
                                    ? _buildOffersItemsView(offersController.offersItemList!)
                                    : Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: isDesktop
                                                  ? context.height * 0.3
                                                  : context.height * 0.4),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                size: 64,
                                                color: Theme.of(context)
                                                    .disabledColor,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'no_items_found'.tr,
                                                style: robotoMedium.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeLarge,
                                                  color: Theme.of(context)
                                                      .disabledColor,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'try_different_search'.tr,
                                                style: robotoRegular.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                  color: Theme.of(context)
                                                      .disabledColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                : offersController.isItemsLoading
                                    ? _buildLoadingShimmer()
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 64,
                                              color: Theme.of(context)
                                                  .disabledColor,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'failed_to_load_items'.tr,
                                              style: robotoMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeLarge,
                                                color: Theme.of(context)
                                                    .disabledColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                Get.find<Offers_Controller>()
                                                    .getOffersItemList(
                                                  id: widget.offerId.toString(),
                                                  offset: 1,
                                                );
                                              },
                                              child: Text('retry'.tr),
                                            ),
                                          ],
                                        ),
                                      )),
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
              // Filter Modal
              if (offersController.isFilterModalOpen)
                _buildFilterModal(context, offersController),
            ],
          );
        });
      }),
    );
  }

  Widget _buildFilterModal(BuildContext context, Offers_Controller controller) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusDefault),
                    topRight: Radius.circular(Dimensions.radiusDefault),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text(
                      'filter_categories'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => controller.closeFilterModal(),
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Categories List
              if (controller.categoryList != null &&
                  controller.categoryList!.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.categoryList!.length,
                    itemBuilder: (context, index) {
                      final category = controller.categoryList![index];
                      final isSelected =
                          controller.selectedCategoryIds.contains(category.id);

                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            controller
                                .toggleCategorySelection(category.id ?? 0);
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          category.name ?? '',
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                        onTap: () {
                          controller.toggleCategorySelection(category.id ?? 0);
                        },
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Text(
                    'no_categories_available'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          controller.selectedCategoryIds.clear();
                          controller.applyCategoryFilter();
                        },
                        style: OutlinedButton.styleFrom(
                          side:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        child: Text(
                          'clear_all'.tr,
                          style: robotoMedium.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.applyCategoryFilter();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          'apply_filter'.tr,
                          style: robotoMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffersItemsView(List<Item> items, {bool isSearching = false}) {
    return GetBuilder<Offers_Controller>(builder: (offersController) {
      return ItemsView(
        isStore: false,
        stores: null,
        items: items,
        verticalItem: offersController.isVertical,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
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
