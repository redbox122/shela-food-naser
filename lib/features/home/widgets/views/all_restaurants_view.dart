import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/filter_bottom_sheet.dart';
import 'package:sixam_mart/features/home/widgets/groups_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

/// All Restaurants View Widget
///
/// Displays restaurants with filter tabs (All, Newly Joined, Popular, Top Rated)
/// and a list of restaurant cards matching the selected filter
class AllRestaurantsView extends StatefulWidget {
  const AllRestaurantsView({super.key});

  @override
  State<AllRestaurantsView> createState() => _AllRestaurantsViewState();
}

class _AllRestaurantsViewState extends State<AllRestaurantsView> {
  bool _isLoadingMore = false;
  ScrollController? _parentScrollController;

  bool _hasActiveStoreFilters(StoreController controller) {
    return controller.filterType != 'all' ||
        controller.storeType != 'all' ||
        controller.recentlyAdded == true ||
        controller.highestRated == true ||
        controller.fastestDelivery == true ||
        controller.minPrice != null ||
        controller.maxPrice != null ||
        controller.sortBy != null;
  }

  String _buildNoStoreResultText(bool showRestaurantText) {
    if (showRestaurantText) {
      return 'ما في نتائج بهاي الفلاتر.\nجرّب بحث/فلتر مختلف أو صفّر الفلتر.';
    }
    return 'ما في نتائج بهاي الفلاتر.\nجرّب بحث/فلتر مختلف أو صفّر الفلتر.';
  }

  @override
  void initState() {
    super.initState();
    // Try to get parent scroll controller after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachScrollListener();
    });
  }

  void _attachScrollListener() {
    try {
      // Get the nearest Scrollable ancestor (the CustomScrollView in HomeScreen)
      // Use maybeOf to avoid exception if no Scrollable found
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable != null) {
        _parentScrollController = scrollable.widget.controller;
        if (_parentScrollController != null &&
            _parentScrollController!.hasClients) {
          _parentScrollController!.addListener(_onScroll);
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '✅ AllRestaurantsView: Attached scroll listener to parent ScrollController');
          }
        } else {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.warning(
                '⚠️ AllRestaurantsView: Parent Scrollable found but has no controller');
          }
        }
      } else {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.warning('⚠️ AllRestaurantsView: No parent Scrollable found');
        }
      }
    } catch (e) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        appLogger.error('⚠️ AllRestaurantsView: Error attaching scroll listener: $e', e);
      }
    }
  }

  void _onScroll() {
    if (_parentScrollController == null ||
        !_parentScrollController!.hasClients) {
      return;
    }

    final position = _parentScrollController!.position;
    final storeController = Get.find<StoreController>();

    // Check if we're near the bottom (within 300 pixels)
    final isNearBottom = position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 300;
    final isAtBottom = position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 50;

    if (kDebugMode &&
        AppConstants.enableVerboseLogs &&
        (isNearBottom || isAtBottom)) {
      final scrollPercent = position.maxScrollExtent > 0
          ? (position.pixels / position.maxScrollExtent * 100)
          : 0;
      appLogger.debug(
          '🔍 AllRestaurantsView: Near/at bottom - pixels: ${position.pixels.toStringAsFixed(0)}, max: ${position.maxScrollExtent.toStringAsFixed(0)}, percent: ${scrollPercent.toStringAsFixed(1)}%');
    }

    if (isNearBottom || isAtBottom) {
      // Only paginate for 'all' and 'top_rated' filters that support pagination
      final supportsPagination = storeController.storeType == 'all' ||
          storeController.storeType == 'top_rated';

      // ⚡ HARD-ISOLATION: Use allStoreModel (legacy pagination engine) instead of storeModel
      if (supportsPagination &&
          storeController.allStoreModel != null &&
          !storeController.isLoading &&
          !_isLoadingMore) {
        final totalSize = storeController.allStoreModel!.totalSize ?? 0;
        final currentOffset = storeController.allStoreModel!.offset ?? 1;
        const itemsPerPage = 7; // API limit
        final totalPages = (totalSize / itemsPerPage).ceil();
        final loadedCount = storeController.allStoreModel!.stores?.length ?? 0;

        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug(
              '🔍 AllRestaurantsView: Pagination check - totalSize: $totalSize, currentOffset: $currentOffset, totalPages: $totalPages, loadedCount: $loadedCount');
        }

        // 🔧 TASK 2: Load more if we haven't loaded all stores (check both offset and count)
        // This ensures pagination continues even if API returns 0 stores but totalSize > 0
        final hasMoreStores = loadedCount < totalSize;
        final hasMorePages = currentOffset < totalPages;

        if (hasMoreStores && hasMorePages) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.info(
                '📄 AllRestaurantsView: ⚡ TRIGGERING PAGINATION - Loading page ${currentOffset + 1} of $totalPages (total: $totalSize stores, currently loaded: $loadedCount)');
          }
          setState(() {
            _isLoadingMore = true;
          });
          storeController
              .getStoreList(currentOffset + 1, false, limit: 7)
              .then((_) {
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
              if (kDebugMode && AppConstants.enableVerboseLogs) {
                final newLoadedCount =
                    storeController.allStoreModel?.stores?.length ?? 0;
                appLogger.info(
                    '✅ AllRestaurantsView: Pagination complete - now loaded: $newLoadedCount stores (was $loadedCount)');
              }
            }
          }).catchError((Object error) {
            if (kDebugMode && AppConstants.enableVerboseLogs) {
              appLogger.error('❌ AllRestaurantsView: Error loading more stores: $error', error);
            }
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
            }
          });
        } else {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.info(
                'ℹ️ AllRestaurantsView: ⚠️ Cannot paginate - hasMoreStores: $hasMoreStores, hasMorePages: $hasMorePages | totalSize: $totalSize stores | loaded: $loadedCount stores | currentOffset: $currentOffset | totalPages: $totalPages');
          }
        }
      } else if (kDebugMode &&
          AppConstants.enableVerboseLogs &&
          (isNearBottom || isAtBottom)) {
        appLogger.warning('⚠️ AllRestaurantsView: Pagination blocked:');
        appLogger.warning(
            '   - supportsPagination: $supportsPagination (storeType: ${storeController.storeType})');
        appLogger.warning(
            '   - allStoreModel is null: ${storeController.allStoreModel == null}');
        appLogger.warning('   - isLoading: ${storeController.isLoading}');
        appLogger.warning('   - _isLoadingMore: $_isLoadingMore');
      }
    }
  }

  @override
  void dispose() {
    _parentScrollController?.removeListener(_onScroll);
    if (Get.isRegistered<StoreController>()) {
      Get.find<StoreController>().resetAllStoreFilters(reload: false, notify: false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-attach listener if context changed (e.g., after rebuild)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_parentScrollController == null) {
        _attachScrollListener();
      }
    });

    return GetBuilder<StoreController>(
      builder: (storeController) {
        final splashController = Get.find<SplashController>();
        final currentModuleId = splashController.module?.id;
        final showRestaurantText = splashController
            .configModel!.moduleConfig!.module!.showRestaurantText!;

        // ⚡ BFF API v2: Wait for V2 data distribution before loading stores for pagination
        // This prevents race conditions where getStoreList() is called before V2 data is distributed
        bool v2DataReady = true; // Default to true if V2 is not enabled
        if (AppConstants.useBffV2Endpoint &&
            Get.isRegistered<HomeUnifiedController>()) {
          try {
            final unifiedController = Get.find<HomeUnifiedController>();
            // V2 data is ready if we have cached data OR loading is complete
            v2DataReady =
                unifiedController.hasCachedData || !unifiedController.isLoading;
            if (kDebugMode && AppConstants.enableVerboseLogs && !v2DataReady) {
              appLogger.debug(
                  '⏳ AllRestaurantsView: Waiting for V2 data distribution...');
            }
          } catch (e) {
            if (kDebugMode && AppConstants.enableVerboseLogs) {
              appLogger.error('⚠️ AllRestaurantsView: Error checking V2 status: $e', e);
            }
            // If we can't check V2 status, proceed anyway (fallback)
            v2DataReady = true;
          }
        }

        // ⚡ MODULE SYNC: Verify StoreController is synced to current moduleId
        if (currentModuleId != null &&
            kDebugMode &&
            AppConstants.enableVerboseLogs) {
          // Module sync is handled by StoreRepository._filterStoresByModule()
          // This is just for verification logging
          // ⚡ HARD-ISOLATION: Use allStoreModel instead of storeModel
          if (storeController.allStoreModel != null) {
            final stores = storeController.allStoreModel!.stores;
            if (stores != null && stores.isNotEmpty) {
              final wrongModuleStores =
                  stores.where((s) => s.moduleId != currentModuleId).length;
              if (wrongModuleStores > 0) {
                appLogger.warning(
                    '⚠️ AllRestaurantsView: Found $wrongModuleStores stores from wrong module (expected: $currentModuleId)');
              }
            }
          }
        }

        // ⚡ PERFORMANCE: Load stores AFTER first frame (post-frame callback)
        // This ensures first frame renders quickly with banners, categories, offers
        // Stores are loaded separately after UI is visible
        // ⚡ CRITICAL: Only load if V2 data distribution is complete (prevents race condition)
        // ⚡ HARD-ISOLATION: Use allStoreModel instead of storeModel
        if (storeController.storeType == 'all' &&
            storeController.allStoreModel == null &&
            !storeController.isLoading &&
            v2DataReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // ⚡ PERFORMANCE: Small delay to ensure first frame is rendered
            Future.delayed(const Duration(milliseconds: 100), () {
              if (kDebugMode) {
                appLogger.debug(
                    '📡 AllRestaurantsView: Loading stores for "all" filter (post-frame, limit=7)');
              }
              // ⚡ PERFORMANCE: Load with small limit (7) for first frame
              storeController.getStoreList(1, false, limit: 7);
            });
          });
        } else if (storeController.storeType == 'popular' &&
            storeController.popularStoreList == null &&
            !storeController.isLoading &&
            v2DataReady) {
          if (kDebugMode) {
            appLogger.debug(
                '⏭️ AllRestaurantsView: Skipping post-frame popular load to avoid duplicate call');
          }
        } else if (storeController.storeType == 'newly_joined' &&
            storeController.latestStoreList == null &&
            !storeController.isLoading &&
            v2DataReady) {
          // 🚫 TEMPORARILY DISABLED: getLatestStoreList causes 22-second hangs and 500 errors
          // Note: Re-enable after backend fix
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   Future.delayed(const Duration(milliseconds: 100), () {
          //     if (kDebugMode) {
          //       debugPrint('📡 AllRestaurantsView: Loading stores for "newly_joined" filter (post-frame)');
          //     }
          //     storeController.getLatestStoreList(false, 'all', false);
          //   });
          // });
        } else if (storeController.storeType == 'top_rated' &&
            storeController.allStoreModel == null &&
            !storeController.isLoading &&
            v2DataReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (kDebugMode) {
                appLogger.debug(
                    '📡 AllRestaurantsView: Loading stores for "top_rated" filter (post-frame, limit=7)');
              }
              // ⚡ PERFORMANCE: Load with small limit (7) for first frame
              storeController.getStoreList(1, false, limit: 7);
            });
          });
        }

        // Get store list based on filter type
        List<Store>? displayStores;
        bool supportsPagination = false;

        if (storeController.storeType == 'popular') {
          displayStores = storeController.popularStoreList;
          supportsPagination = false; // Popular stores don't support pagination
        } else if (storeController.storeType == 'newly_joined') {
          displayStores = storeController.latestStoreList;
          supportsPagination = false; // Latest stores don't support pagination
        } else {
          // For 'all' and 'top_rated', use allStoreModel (legacy pagination engine)
          // ⚡ HARD-ISOLATION: Use allStoreModel instead of storeModel
          displayStores = storeController.allStoreModel?.stores;
          supportsPagination = true; // These support pagination
        }

        // ⚠️ CRITICAL FIX: Filter stores by current module ID to prevent cross-module contamination
        // This ensures each module only shows its own stores, especially when using filter chips
        if (currentModuleId != null && displayStores != null) {
          final originalCount = displayStores.length;
          displayStores = displayStores.where((store) {
            final matches =
                store.moduleId == null || store.moduleId == currentModuleId;
            if (!matches && kDebugMode) {
              appLogger.warning(
                  '⚠️ AllRestaurantsView: Filtered out store ${store.id} (module_id: ${store.moduleId}, expected: $currentModuleId)');
            }
            return matches;
          }).toList();

          if (kDebugMode && originalCount != displayStores.length) {
            appLogger.info(
                '✅ AllRestaurantsView: Filtered ${originalCount - displayStores.length} stores from wrong module (filter: ${storeController.storeType})');
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Groups Widget - Replaces title and filter tabs section
            Groups(
              selectedStoreType: storeController.storeType,
              onStoreTypeSelected: (String storeType) {
                if (kDebugMode) {
                  appLogger.debug('Store type chip selected: $storeType');
                }
                storeController.setStoreType(storeType);
              },
              onFilterTap: () {
                if (kDebugMode) {
                  appLogger.debug('Filter button tapped');
                }
                showModalBottomSheet(
                  context: Get.context!,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FilterBottomSheet(
                    onApply: (filters) {
                      if (kDebugMode) {
                        appLogger.debug('Filters applied: $filters');
                      }
                      // Apply filterType if provided
                      if (filters.containsKey('filterType') &&
                          filters['filterType'] != null) {
                        storeController
                            .setFilterType(filters['filterType'] as String);
                      }
                      // Apply all other filters using the new applyStoreFilters method
                      storeController.applyStoreFilters(filters);
                    },
                    onClear: () {
                      if (kDebugMode) {
                        appLogger.debug('Filters cleared');
                      }
                      // Reset filterType to 'all'
                      storeController.setFilterType('all');
                      // Clear all filters using the new clearFilters method
                      storeController.clearFilters();
                    },
                  ),
                );
              },
              onOffersTap: () {
                // Note: Implement offers filter
              },
              onTopRatedTap: () {
                // Note: Implement top rated filter (4.5+ rating)
              },
              onFastestDeliveryTap: () {
                // Note: Implement fastest delivery filter (up to 30 minutes)
              },
              onIconButtonTap: () {
                storeController.setVerticalItems(!storeController.isVertical);
              },
            ),

            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Restaurants List Section with Pagination Support
            // Pagination is handled via NotificationListener above
            Column(
              children: [
                ItemsView(
                  isStore: true,
                  items: null,
                  stores: displayStores?.map((s) => s as Store?).toList(),
                  noDataText: _hasActiveStoreFilters(storeController)
                      ? _buildNoStoreResultText(showRestaurantText)
                      : (showRestaurantText
                          ? 'no_restaurant_available'.tr
                          : 'no_store_available'.tr),
                  noDataActionText: 'reset'.tr,
                  onNoDataActionTap: _hasActiveStoreFilters(storeController)
                      ? () {
                          storeController.resetAllStoreFilters(reload: true);
                        }
                      : null,
                  verticalItem: storeController.isVertical,
                ),
                // Show loading indicator when loading more stores
                if (_isLoadingMore && supportsPagination)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'جاري التحميل...',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
