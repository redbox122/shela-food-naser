import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
// Additive: reusable sort/filter bar for the module store list.
import 'package:sixam_mart/features/restaurant/controllers/restaurant_filter_controller.dart';
import 'package:sixam_mart/features/restaurant/widgets/restaurant_filter_bar.dart';

class AllStoreScreen extends StatefulWidget {
  final bool isPopular;
  final bool isFeatured;
  final bool isNearbyStore;
  final bool isTopOfferStore;
  const AllStoreScreen(
      {super.key,
      required this.isPopular,
      required this.isFeatured,
      required this.isNearbyStore,
      required this.isTopOfferStore});

  @override
  State<AllStoreScreen> createState() => _AllStoreScreenState();
}

class _AllStoreScreenState extends State<AllStoreScreen> {
  final ScrollController scrollController = ScrollController();
  static const int _pageLimit = 7;
  bool _isPaginating = false;
  bool _sortOpenFirst = true;
  bool _sortAvailableMealsFirst = true;
  _StoreSortMode _sortMode = _StoreSortMode.nearest;

  String _getScreenTitle(StoreController storeController) {
    if (widget.isFeatured) {
      return 'featured_stores'.tr;
    }
    if (widget.isPopular) {
      return Get.find<SplashController>()
              .configModel!
              .moduleConfig!
              .module!
              .showRestaurantText!
          ? widget.isNearbyStore
              ? 'best_store_nearby'.tr
              : 'popular_restaurants'.tr
          : widget.isNearbyStore
              ? 'best_store_nearby'.tr
              : 'popular_stores'.tr;
    }
    if (widget.isTopOfferStore) {
      return 'top_offers_near_me'.tr;
    }
    return '${'new_on'.tr} ${AppConstants.appName}';
  }

  late final String _filterTag;

  void _reloadStoresForFilter() {
    final StoreController sc = Get.find<StoreController>();
    if (widget.isFeatured) {
      sc.getFeaturedStoreList();
    } else if (widget.isPopular) {
      sc.getPopularStoreList(true, sc.type, false);
    } else if (widget.isTopOfferStore) {
      sc.getTopOfferStoreList(true, false);
    } else {
      sc.getStoreList(1, true, limit: _pageLimit);
    }
  }

  @override
  void initState() {
    super.initState();

    // Additive: register a per-module filter controller and wire "apply" to a
    // reload. UI-only for now (server-side params wired later).
    _filterTag =
        Get.find<SplashController>().module?.moduleType?.toString() ??
            'restaurants';
    if (!Get.isRegistered<RestaurantFilterController>(tag: _filterTag)) {
      Get.put(RestaurantFilterController(moduleType: _filterTag),
          tag: _filterTag);
    }
    Get.find<RestaurantFilterController>(tag: _filterTag).onApply =
        (_) => _reloadStoresForFilter();

    final bool isAllPage =
        !widget.isFeatured && !widget.isPopular && !widget.isTopOfferStore;
    if (isAllPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Get.find<StoreController>().getStoreList(1, true, limit: _pageLimit);
      });
      scrollController.addListener(() {
        if (_isPaginating) {
          return;
        }
        if (!scrollController.hasClients) {
          return;
        }
        if (scrollController.position.pixels <
            scrollController.position.maxScrollExtent - 200) {
          return;
        }
        final StoreController storeController = Get.find<StoreController>();
        final int loadedCount =
            storeController.allStoreModel?.stores?.length ?? 0;
        final int totalSize = storeController.allStoreModel?.totalSize ?? 0;
        if (loadedCount >= totalSize || totalSize == 0) {
          return;
        }
        final int currentOffset = storeController.allStoreModel?.offset ?? 1;
        if (mounted) {
          setState(() {
            _isPaginating = true;
          });
        } else {
          _isPaginating = true;
        }
        storeController
            .getStoreList(
          currentOffset + 1,
          false,
          source: DataSourceEnum.client,
          limit: _pageLimit,
        )
            .whenComplete(() {
          if (mounted) {
            setState(() {
              _isPaginating = false;
            });
          } else {
            _isPaginating = false;
          }
        });
      });
    }

    if (widget.isFeatured) {
      Get.find<StoreController>().getFeaturedStoreList();
    } else if (widget.isPopular) {
      Get.find<StoreController>().getPopularStoreList(false, 'all', false);
    } else if (widget.isTopOfferStore) {
      Get.find<StoreController>().getTopOfferStoreList(false, false);
    } else if (!isAllPage) {
      Get.find<StoreController>().getLatestStoreList(false, 'all', false);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      final String screenTitle = _getScreenTitle(storeController);
      final String resultsLabel = '${'results'.tr}: $screenTitle';
      final bool isRestaurantLikeModule =
          (Get.find<SplashController>().module?.moduleType?.toLowerCase() ??
                  '') ==
              AppConstants.food;
      final bool isArabic = Get.locale?.languageCode == 'ar';
      return Scaffold(
        appBar: CustomAppBar(
          title: screenTitle,
          type: widget.isFeatured ? null : storeController.type,
          onVegFilterTap: (String type) {
            if (widget.isPopular) {
              Get.find<StoreController>().getPopularStoreList(true, type, true);
            } else {
              Get.find<StoreController>().getLatestStoreList(true, type, true);
            }
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            if (widget.isFeatured) {
              await Get.find<StoreController>().getFeaturedStoreList();
            } else if (widget.isPopular) {
              await Get.find<StoreController>().getPopularStoreList(
                true,
                Get.find<StoreController>().type,
                false,
              );
            } else {
              await Get.find<StoreController>().getLatestStoreList(
                true,
                Get.find<StoreController>().type,
                false,
              );
            }
          },
          child: SingleChildScrollView(
              controller: scrollController,
              child: FooterView(
                  child: Column(
                children: [
                  WebScreenTitleWidget(
                    title: screenTitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeExtraSmall),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 18,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Expanded(
                          child: Text(
                            resultsLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Additive: sort/filter bar (UI). RTL, scrollable.
                  RestaurantFilterBar(moduleType: _filterTag),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  if (isRestaurantLikeModule)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: Dimensions.paddingSizeExtraSmall,
                          runSpacing: Dimensions.paddingSizeExtraSmall,
                          children: [
                            FilterChip(
                              selected: _sortOpenFirst,
                              label: Text(
                                isArabic ? 'المفتوح أولاً' : 'Open First',
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _sortOpenFirst = selected;
                                });
                              },
                            ),
                            FilterChip(
                              selected: _sortAvailableMealsFirst,
                              label: Text(
                                isArabic
                                    ? 'الوجبات المتوفرة أولاً'
                                    : 'Available Meals First',
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _sortAvailableMealsFirst = selected;
                                });
                              },
                            ),
                            ChoiceChip(
                              selected: _sortMode == _StoreSortMode.nearest,
                              label: Text(
                                isArabic ? 'الأقرب' : 'Nearest',
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _sortMode = _StoreSortMode.nearest;
                                });
                              },
                            ),
                            ChoiceChip(
                              selected:
                                  _sortMode == _StoreSortMode.highestRated,
                              label: Text(
                                isArabic ? 'الأعلى تقييماً' : 'Highest Rated',
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _sortMode = _StoreSortMode.highestRated;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: Dimensions.webMaxWidth,
                    child:
                        GetBuilder<StoreController>(builder: (storeController) {
                      final bool isAllPage = !widget.isFeatured &&
                          !widget.isPopular &&
                          !widget.isTopOfferStore;
                      final List<Store?>? stores = isAllPage
                          ? storeController.allStoreModel?.stores
                          : widget.isFeatured
                              ? storeController.featuredStoreList
                              : widget.isPopular
                                  ? storeController.popularStoreList
                                  : widget.isTopOfferStore
                                      ? storeController.topOfferStoreList
                                      : storeController.latestStoreList;
                      final List<Store?> sortedStores =
                          _applyStoreFilters(stores, storeController);
                      final bool isInitialBranchFailure = !isAllPage &&
                          stores == null &&
                          !storeController.isLoading;
                      final _StoreCounters counters =
                          _calculateCounters(stores, storeController);
                      final int loadedCount = stores?.length ?? 0;
                      final int totalSize =
                          storeController.allStoreModel?.totalSize ?? 0;
                      final bool hasReachedEnd = isAllPage &&
                          totalSize > 0 &&
                          loadedCount >= totalSize;
                      return Column(
                        children: [
                          if (isRestaurantLikeModule)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: Dimensions.paddingSizeExtraSmall,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  isArabic
                                      ? 'مفتوح: ${counters.open} | مغلق: ${counters.closed}   •   متوفر: ${counters.availableMeals} | غير متوفر: ${counters.unavailableMeals}'
                                      : 'Open: ${counters.open} | Closed: ${counters.closed} • Available: ${counters.availableMeals} | Unavailable: ${counters.unavailableMeals}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          if (isAllPage &&
                              storeController.hasAllStoresError &&
                              sortedStores.isEmpty &&
                              !storeController.isLoading)
                            ErrorStateView(
                              onRetry: () {
                                storeController.getStoreList(
                                  1,
                                  true,
                                  limit: _pageLimit,
                                );
                              },
                            )
                          else if (widget.isPopular &&
                              storeController.hasPopularStoresError &&
                              sortedStores.isEmpty &&
                              !storeController.isLoading)
                            ErrorStateView(
                              onRetry: () {
                                storeController.getPopularStoreList(
                                  true,
                                  storeController.type,
                                  true,
                                );
                              },
                            )
                          else if (isInitialBranchFailure)
                            ErrorStateView(
                              onRetry: () {
                                if (widget.isFeatured) {
                                  storeController.getFeaturedStoreList();
                                } else if (widget.isTopOfferStore) {
                                  storeController.getTopOfferStoreList(true, true);
                                } else {
                                  storeController.getLatestStoreList(
                                    true,
                                    storeController.type,
                                    true,
                                  );
                                }
                              },
                            )
                          else
                            ItemsView(
                              isStore: true,
                              items: null,
                              isFeatured: widget.isFeatured,
                              noDataText: widget.isFeatured
                                  ? 'no_store_available'.tr
                                  : Get.find<SplashController>()
                                          .configModel!
                                          .moduleConfig!
                                          .module!
                                          .showRestaurantText!
                                      ? 'no_restaurant_available'.tr
                                      : 'no_store_available'.tr,
                              // While the first fetch is in flight and we have no
                              // stores yet, pass null so ItemsView shows the
                              // loading shimmer instead of flashing the empty
                              // "no restaurants available" state for one frame.
                              stores: (storeController.isLoading &&
                                      sortedStores.isEmpty)
                                  ? null
                                  : sortedStores,
                            ),
                          if (isAllPage &&
                              !hasReachedEnd &&
                              (storeController.isLoading || _isPaginating))
                            Padding(
                              padding: const EdgeInsets.only(
                                top: Dimensions.paddingSizeDefault,
                                bottom: Dimensions.paddingSizeDefault,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeExtraSmall),
                                  Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    'loading_more_stores'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          if (hasReachedEnd)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: Dimensions.paddingSizeDefault,
                                bottom: Dimensions.paddingSizeDefault,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_food_beverage_rounded,
                                    size: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    'end_of_restaurants'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                ],
              ))),
        ),
      );
    });
  }

  List<Store?> _applyStoreFilters(
      List<Store?>? stores, StoreController storeController) {
    if (stores == null || stores.isEmpty) {
      return <Store?>[];
    }

    final List<Store?> sorted = List<Store?>.from(stores);
    sorted.sort((a, b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;

      if (_sortOpenFirst) {
        final bool aOpen = storeController.isOpenNow(a);
        final bool bOpen = storeController.isOpenNow(b);
        if (aOpen != bOpen) {
          return aOpen ? -1 : 1;
        }
      }

      if (_sortAvailableMealsFirst) {
        final bool aHasAvailableMeals = _hasAvailableMeals(a);
        final bool bHasAvailableMeals = _hasAvailableMeals(b);
        if (aHasAvailableMeals != bHasAvailableMeals) {
          return aHasAvailableMeals ? -1 : 1;
        }
      }

      if (_sortMode == _StoreSortMode.highestRated) {
        final double aRating = a.avgRating ?? 0;
        final double bRating = b.avgRating ?? 0;
        final int byRating = bRating.compareTo(aRating);
        if (byRating != 0) {
          return byRating;
        }
      }

      final double aDistance = a.distance ?? double.infinity;
      final double bDistance = b.distance ?? double.infinity;
      return aDistance.compareTo(bDistance);
    });
    return sorted;
  }

  bool _hasAvailableMeals(Store store) {
    if (store.itemCount != null) {
      return store.itemCount! > 0;
    }
    if (store.items != null && store.items!.isNotEmpty) {
      return store.items!.any((item) => (item.stock ?? 0) > 0);
    }
    return store.active ?? true;
  }

  _StoreCounters _calculateCounters(
      List<Store?>? stores, StoreController storeController) {
    if (stores == null || stores.isEmpty) {
      return const _StoreCounters(
        open: 0,
        closed: 0,
        availableMeals: 0,
        unavailableMeals: 0,
      );
    }

    int open = 0;
    int closed = 0;
    int availableMeals = 0;
    int unavailableMeals = 0;

    for (final store in stores) {
      if (store == null) continue;
      if (storeController.isOpenNow(store)) {
        open++;
      } else {
        closed++;
      }

      if (_hasAvailableMeals(store)) {
        availableMeals++;
      } else {
        unavailableMeals++;
      }
    }

    return _StoreCounters(
      open: open,
      closed: closed,
      availableMeals: availableMeals,
      unavailableMeals: unavailableMeals,
    );
  }
}

enum _StoreSortMode { nearest, highestRated }

class _StoreCounters {
  final int open;
  final int closed;
  final int availableMeals;
  final int unavailableMeals;

  const _StoreCounters({
    required this.open,
    required this.closed,
    required this.availableMeals,
    required this.unavailableMeals,
  });
}
