/// Pharmacy Home Screen
///
/// This screen displays all sections for the pharmacy module.
/// Sections are conditionally rendered only when they have data to avoid empty placeholders.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:sixam_mart/features/home/widgets/bad_weather_widget.dart';
import 'package:sixam_mart/features/home/widgets/highlight_widget.dart';
import 'package:sixam_mart/features/home/widgets/views/product_with_categories_view.dart';
import 'package:sixam_mart/features/home/widgets/views/best_store_nearby_view.dart';
import 'package:sixam_mart/features/home/widgets/views/common_condition_view.dart';
import 'package:sixam_mart/features/home/widgets/views/just_for_you_view.dart';
import 'package:sixam_mart/features/home/widgets/views/middle_section_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/new_on_mart_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/top_offers_near_me.dart';
import 'package:sixam_mart/features/home/widgets/views/visit_again_view.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/util/app_constants.dart';

class PharmacyHomeScreen extends StatefulWidget {
  const PharmacyHomeScreen({super.key});

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  // ⚡ BFF API v2: Simplified state - all loading handled by HomeUnifiedController
  bool _hasCachedData = false;
  // ⚡ TASK 2: Performance benchmarking
  late Stopwatch _renderStopwatch;
  bool _hasLoggedRenderTime = false;

  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('PharmacyHomeScreen');
    appLogger.info('🏠 PharmacyHomeScreen: Initializing');
    appLogger.debug('PharmacyHomeScreen: Module Type = Pharmacy');
    appLogger.debug('PharmacyHomeScreen: Starting initialization sequence');

    // ⚡ TASK 2: Start performance stopwatch
    _renderStopwatch = Stopwatch()..start();

    // ⚡ SWR: Load cached data IMMEDIATELY for zero-latency rendering
    _loadCachedDataForInstantUI();

    // ⚡ BFF API v2: All data loading is handled by HomeUnifiedController
    // No need for individual API calls - unified endpoint handles everything
  }
  
  @override
  void dispose() {
    appLogger.logPageExit();
    appLogger.info('🏠 PharmacyHomeScreen: Disposed');
    super.dispose();
  }

  /// ⚡ SWR: Load cached data from HomeUnifiedController for instant UI rendering
  /// This runs synchronously in initState to show UI before first frame
  Future<void> _loadCachedDataForInstantUI() async {
    appLogger.debug('PharmacyHomeScreen: _loadCachedDataForInstantUI() called');
    appLogger.debug('PharmacyHomeScreen: useBffV2Endpoint = ${AppConstants.useBffV2Endpoint}');
    
    // Only use unified endpoint if feature flag is enabled
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('PharmacyHomeScreen: BFF v2 endpoint disabled, skipping cache load');
      return;
    }

    try {
      if (Get.isRegistered<HomeUnifiedController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        appLogger.debug('PharmacyHomeScreen: HomeUnifiedController found, loading cached data');

        // ⚡ INSTANT: Load cached data synchronously
        final hasCache = await unifiedController.loadCachedDataForInstantUI();
        if (hasCache) {
          _hasCachedData = true;
          appLogger.info('⚡ PharmacyHomeScreen: Cached data loaded - UI will render instantly');
          appLogger.debug('PharmacyHomeScreen: Cache status - hasCachedData = true');

          // Trigger background refresh (SWR pattern)
          _refreshInBackground();
        } else {
          appLogger.warning('⚠️ PharmacyHomeScreen: No cached data found, will show loading shimmer');
          appLogger.debug('PharmacyHomeScreen: Cache status - hasCachedData = false');
          // No cache - trigger normal load
          _refreshInBackground();
        }
      } else {
        appLogger.warning('PharmacyHomeScreen: HomeUnifiedController not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error('⚠️ PharmacyHomeScreen: Error loading cached data', e, stackTrace);
      // Fallback to normal load
      _refreshInBackground();
    }
  }

  /// Standardized data loading method for module entry
  ///
  /// [reload] - If true, forces fresh data fetch bypassing cache
  ///
  /// This method ensures:
  /// 1. V2 loads top sections (Banners/Categories) via HomeUnifiedController
  /// 2. Legacy engine loads bottom section (All Restaurants) with correct totalSize (300+)
  /// 3. Each module entry is a clean slate - no state contamination
  Future<void> _loadData(bool reload) async {
    appLogger.debug('PharmacyHomeScreen: _loadData() called with reload=$reload');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('PharmacyHomeScreen: BFF v2 endpoint disabled, skipping data load');
      return;
    }

    try {
      if (Get.isRegistered<HomeUnifiedController>() &&
          Get.isRegistered<SplashController>()) {
        final unifiedController = Get.find<HomeUnifiedController>();
        final splashController = Get.find<SplashController>();

        final moduleId = splashController.module?.id;
        appLogger.debug('PharmacyHomeScreen: Module ID = $moduleId');
        appLogger.info('PharmacyHomeScreen: Starting V2 data load (top sections: Banners/Categories)');

        // 1. Trigger V2 for Top Sections (Banners/Categories)
        await unifiedController.loadHomeData(
          moduleId: moduleId,
          forceRefresh: reload,
          showLoading: false, // Silent refresh - no loading indicator
        );

        appLogger.info('✅ PharmacyHomeScreen: V2 data loaded (top sections)');
        appLogger.debug('PharmacyHomeScreen: V2 load complete - Banners and Categories should be available');

        // 2. HARD RESET & TRIGGER LEGACY for the bottom section
        // This ensures we get the real total_size (300+) every time we enter
        // V2 must NEVER touch storeModel - only popularStoreList for top sections
        if (Get.isRegistered<StoreController>()) {
          final storeController = Get.find<StoreController>();
          final homeController = Get.find<HomeController>();
          final settings = homeController.business_Settings;

          // Only load if "All Restaurants" section is enabled
          final allRestaurantsEnabled = settings == null ||
              settings.allRestaurantsSection?.toString() == '1' ||
              (settings.allRestaurantsSection is int &&
                  settings.allRestaurantsSection == 1);

          appLogger.debug('PharmacyHomeScreen: allRestaurantsSection enabled = $allRestaurantsEnabled');

          if (allRestaurantsEnabled) {
            if (AppConstants.useBffV2Endpoint) {
              appLogger.info(
                  '🛡️ PharmacyHomeScreen: Unified-only policy - skipping legacy allStoreModel fetch');
              return;
            }
            appLogger.info('📡 PharmacyHomeScreen: Initializing legacy pagination engine (allStoreModel)');
            appLogger.debug('PharmacyHomeScreen: reload=true ensures clean state and correct totalSize (300+)');
            appLogger.debug('PharmacyHomeScreen: Calling storeController.getStoreList(1, true)');
            
            // Use reload: true to ensure we get the TRUE totalSize from API (300+)
            // This clears old module data and fetches fresh data
            await storeController.getStoreList(1, true);
            
            // ⚡ TASK 1: Use allStoreModel instead of storeModel for paginated data
            final totalSize = storeController.allStoreModel?.totalSize;
            appLogger.info('✅ PharmacyHomeScreen: Legacy pagination engine initialized (totalSize: $totalSize)');
            appLogger.debug('PharmacyHomeScreen: Store list loaded - stores count: ${storeController.allStoreModel?.stores?.length ?? 0}');
          } else {
            appLogger.debug('PharmacyHomeScreen: All Restaurants section disabled, skipping store list load');
          }
        } else {
          appLogger.warning('PharmacyHomeScreen: StoreController not registered');
        }
      } else {
        appLogger.warning('PharmacyHomeScreen: Required controllers not registered');
      }
    } catch (e, stackTrace) {
      appLogger.error('❌ PharmacyHomeScreen: Data loading failed', e, stackTrace);
    }
  }

  /// ⚡ SWR: Refresh data in background (silent update)
  void _refreshInBackground() {
    appLogger.debug('PharmacyHomeScreen: _refreshInBackground() called');
    appLogger.debug('PharmacyHomeScreen: _hasCachedData = $_hasCachedData');
    
    if (!AppConstants.useBffV2Endpoint) {
      appLogger.debug('PharmacyHomeScreen: BFF v2 endpoint disabled, skipping background refresh');
      return;
    }

    // Delay to ensure UI has rendered first
    Future.delayed(const Duration(milliseconds: 100), () async {
      appLogger.debug('PharmacyHomeScreen: Starting background refresh (reload=${!_hasCachedData})');
      await _loadData(!_hasCachedData);
      appLogger.debug('PharmacyHomeScreen: Background refresh complete');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();

    // ⚡ TASK 2: Log render time and section count after first frame
    if (!_hasLoggedRenderTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasLoggedRenderTime && mounted) {
          _renderStopwatch.stop();
          final renderTime = _renderStopwatch.elapsedMilliseconds;
          
          // Count enabled sections
          int sectionCount = 0;
          try {
            final homeController = Get.find<HomeController>();
            final settings = homeController.business_Settings;
            
            if (settings != null) {
              if (settings.categoriesSection?.toString() == '1' || 
                  (settings.categoriesSection is int && settings.categoriesSection == 1)) {
                sectionCount++;
              }
              if (settings.bannersSection?.toString() == '1' || 
                  (settings.bannersSection is int && settings.bannersSection == 1)) {
                sectionCount++;
              }
              // Count other sections that are conditionally rendered
              if (isLoggedIn) sectionCount++; // Visit Again
              // Add more sections as needed based on data availability
            }
          } catch (e) {
            // Ignore errors in counting
          }
          
          appLogger.info('⚡ PharmacyHomeScreen Sync-UI: Rendered with $sectionCount sections in ${renderTime}ms');
          _hasLoggedRenderTime = true;
        }
      });
    }

    // ⚡ BFF API v2: Wrap in GetBuilder for HomeUnifiedController
    // Shows shimmer only if no cached data AND loading
    return GetBuilder<HomeUnifiedController>(
      builder: (unifiedController) {
        if (unifiedController.hasError && !unifiedController.isLoading) {
          return ErrorStateView(
            onRetry: () {
              unifiedController.loadHomeData(
                forceRefresh: true,
                showLoading: true,
              );
            },
          );
        }
        // Show shimmer if no cached data and still loading
        if (!unifiedController.hasCachedData && unifiedController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return GetBuilder<HomeController>(
          builder: (homeController) {
            final settings = homeController.business_Settings;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
                // Banners section - ⚡ BUSINESS SETTINGS: Use backend flags as source of truth
                GetBuilder<BannerController>(
                  builder: (bannerController) {
                    final isEnabled = settings == null ||
                        (settings.bannersSection?.toString() == '1' ||
                            (settings.bannersSection is int &&
                                settings.bannersSection == 1));
                    final hasFeaturedBanners =
                        bannerController.featuredBannerList != null &&
                            bannerController.featuredBannerList!.isNotEmpty;
                    final hasRegularBanners =
                        bannerController.bannerImageList != null &&
                            bannerController.bannerImageList!.isNotEmpty;
                    final hasData = hasFeaturedBanners || hasRegularBanners;
                    return (isEnabled && hasData)
                        ? Container(
                            width: MediaQuery.of(context).size.width,
                            color: Theme.of(context)
                                .disabledColor
                                .withValues(alpha: 0.1),
                            child: const Column(
                              children: [
                                BadWeatherWidget(),
                                BannerView(isFeatured: false),
                                SizedBox(height: 12),
                              ],
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
                GetBuilder<CategoryController>(
                  builder: (categoryController) {
                    final isEnabled = settings == null ||
                        (settings.categoriesSection?.toString() == '1' ||
                            (settings.categoriesSection is int &&
                                settings.categoriesSection == 1));
                    final hasData = categoryController.categoryList != null &&
                        categoryController.categoryList!.isNotEmpty;
                    return (isEnabled && hasData)
                        ? const CategoryView()
                        : const SizedBox.shrink();
                  },
                ),

                // Visit Again - Only show if logged in AND has data
                if (isLoggedIn)
                  GetBuilder<StoreController>(
                    builder: (storeController) {
                      final hasVisitAgainData =
                          storeController.visitAgainStoreList != null &&
                              storeController.visitAgainStoreList!.isNotEmpty;
                      return hasVisitAgainData
                          ? const VisitAgainView()
                          : const SizedBox.shrink();
                    },
                  ),

                // Product With Categories (Basic Medicine) - Only show if has data
                GetBuilder<ItemController>(
                  builder: (itemController) {
                    final hasBasicMedicineData = itemController
                                .basicMedicineModel !=
                            null &&
                        itemController.basicMedicineModel!.products != null &&
                        itemController.basicMedicineModel!.products!.isNotEmpty;
                    return hasBasicMedicineData
                        ? const ProductWithCategoriesView()
                        : const SizedBox.shrink();
                  },
                ),

                // Highlight Widget (Advertisements) - Only show if has data
                GetBuilder<AdvertisementController>(
                  builder: (advertisementController) {
                    final hasAdvertisementData =
                        advertisementController.advertisementList != null &&
                            advertisementController
                                .advertisementList!.isNotEmpty;
                    return hasAdvertisementData
                        ? const HighlightWidget()
                        : const SizedBox.shrink();
                  },
                ),

                // Middle Section Banner (Basic Campaigns) - Only show if has data
                GetBuilder<CampaignController>(
                  builder: (campaignController) {
                    final hasBasicCampaignData =
                        campaignController.basicCampaignList != null &&
                            campaignController.basicCampaignList!.isNotEmpty;
                    return hasBasicCampaignData
                        ? const MiddleSectionBannerView()
                        : const SizedBox.shrink();
                  },
                ),

                // Best Store Nearby (Featured Stores for Pharmacy) - Only show if has data
                GetBuilder<StoreController>(
                  builder: (storeController) {
                    final hasFeaturedStoreData =
                        storeController.featuredStoreList != null &&
                            storeController.featuredStoreList!.isNotEmpty;
                    return hasFeaturedStoreData
                        ? const BestStoreNearbyView()
                        : const SizedBox.shrink();
                  },
                ),

                // Just For You (Item Campaigns) - Only show if has data
                GetBuilder<CampaignController>(
                  builder: (campaignController) {
                    final hasItemCampaignData =
                        campaignController.itemCampaignList != null &&
                            campaignController.itemCampaignList!.isNotEmpty;
                    return hasItemCampaignData
                        ? const JustForYouView()
                        : const SizedBox.shrink();
                  },
                ),

                // Top Offers Near Me - Only show if has data
                GetBuilder<StoreController>(
                  builder: (storeController) {
                    final hasTopOfferData =
                        storeController.topOfferStoreList != null &&
                            storeController.topOfferStoreList!.isNotEmpty;
                    return hasTopOfferData
                        ? const TopOffersNearMe()
                        : const SizedBox.shrink();
                  },
                ),

                // New On Mart (Latest Stores) - Only show if has data
                GetBuilder<StoreController>(
                  builder: (storeController) {
                    final hasLatestStoreData =
                        storeController.latestStoreList != null &&
                            storeController.latestStoreList!.isNotEmpty;
                    return hasLatestStoreData
                        ? const NewOnMartView(
                            isShop: false, isPharmacy: true, isNewStore: true)
                        : const SizedBox.shrink();
                  },
                ),

                // Common Condition View - Only show if has data
                GetBuilder<ItemController>(
                  builder: (itemController) {
                    final hasCommonConditionsData =
                        itemController.commonConditions != null &&
                            itemController.commonConditions!.isNotEmpty;
                    return hasCommonConditionsData
                        ? const CommonConditionView()
                        : const SizedBox.shrink();
                  },
                ),

                // Promotional Banner - Only show if has data
                GetBuilder<BannerController>(
                  builder: (bannerController) {
                    final hasPromotionalBannerData =
                        bannerController.promotionalBanner != null &&
                            bannerController.promotionalBanner!
                                    .bottomSectionBannerFullUrl !=
                                null;
                    return hasPromotionalBannerData
                        ? const PromotionalBannerView()
                        : const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
