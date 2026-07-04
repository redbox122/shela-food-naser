import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:sixam_mart/features/home/controllers/akhdamni_flow_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/widgets/cashback_logo_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_dialog_widget.dart';
import 'package:sixam_mart/features/home/widgets/refer_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/home/services/home_load_service.dart';
import 'package:sixam_mart/features/home/widgets/home_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/home_top_notice_strip.dart';
import 'package:sixam_mart/features/home/widgets/home_header.dart';
import 'package:sixam_mart/features/home/widgets/home_services_grid.dart';
import 'package:sixam_mart/features/home/widgets/home_current_offers_section.dart';
import 'package:sixam_mart/features/home/widgets/home_reorder_section.dart';
import 'package:sixam_mart/features/home/widgets/akhdamni/akhdamni_flow_section.dart';
import 'package:sixam_mart/features/home/widgets/shop_home_skeleton.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/rental_module/home/screens/taxi_home_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/home/screens/web_new_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/flattened_module_content.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_category_screen.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
// Old "عروض وخصومات" promo design, shown alongside the current-offers rail.
import 'package:sixam_mart/features/offers/widgets/offers_view.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

part 'home_screen_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// ✅ FIX: Reset static flags when switching modules
  /// This prevents stale state from previous module
  static void resetModuleState() {
    _HomeScreenState._hasLoadedOnce = false;
    debugPrint('🔄 HomeScreen: Module state reset - _hasLoadedOnce = false');
  }

  // 🧹 REFACTOR: Loading orchestration extracted to HomeLoadService. These stay
  // as thin delegates because external callers use HomeScreen.loadData / etc.
  static Future<void> loadData(dynamic context, bool reload,
          {bool fromModule = false}) =>
      HomeLoadService.loadData(context, reload, fromModule: fromModule);

  static Future<void> performHardRefresh(BuildContext context) =>
      HomeLoadService.performHardRefresh(context);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController scrollController = ScrollController();
  bool searchBgShow = false;
  final GlobalKey headerKey = GlobalKey();
  Timer? _deferredLoadTimer;
  bool _deferredLoadQueued = false;
  int? _lastConnectivityRecoveryModuleId;

  // 🩹 SELF-HEAL: guards the one-shot module resolution kicked off when the
  // home is entered with no module selected (e.g. straight after login).
  bool _resolvingModule = false;

  // ⚡ Cache-First Fix: Track if first load completed
  static bool _hasLoadedOnce = false;
  DateTime? _lastUiDiagAt;
  String? _lastUiDiagSignature;

  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('HomeScreen');
    appLogger.info('🏠 HomeScreen: Initializing');

    // Check if data is already loaded using instant loading manager
    _checkAndLoadData();

    // Load cart data only if not already loaded or stale
    // This prevents redundant API calls on home screen
    Future.microtask(() async {
      if (AuthHelper.isLoggedIn() && Get.isRegistered<CartController>()) {
        final cartController = Get.find<CartController>();

        // Only load if cart data is not available or is stale (older than 5 minutes)
        if (cartController.cartList.isEmpty ||
            cartController.lastSuccessfulCartLoad == null ||
            DateTime.now().difference(cartController.lastSuccessfulCartLoad!) >
                const Duration(minutes: 5)) {
          // Wait for guest cart transfer to complete (if any)
          await Future.delayed(const Duration(milliseconds: 2000));
          debugPrint(
              '🔄 HomeScreen: Loading cart data on init (stale or empty)');
          cartController.getCartDataOnline(forceRefresh: true);
        } else {
          debugPrint('💾 HomeScreen: Using cached cart data');
        }
      }
    });

    if (!ResponsiveHelper.isWeb()) {
      Future.microtask(() {
        if (Get.isRegistered<LocationController>()) {
          // Check if we should skip zone validation (when using current location)
          final locationController = Get.find<LocationController>();
          if (locationController.skipZoneValidation) {
            debugPrint(
                '🏠 HomeScreen: Skipping zone validation due to current location usage');
            // Don't reset the flag here - let it be reset after all data loading is complete
            return;
          }

          // 🔧 FIX: Null-safe address access - prevent crash for new users without address
          final AddressModel? userAddress =
              AddressHelper.getUserAddressFromSharedPref();
          if (userAddress?.latitude != null && userAddress?.longitude != null) {
            Get.find<LocationController>().getZone(
                userAddress!.latitude, userAddress.longitude, false,
                updateInAddress: true);
          } else {
            debugPrint(
                '⚠️ HomeScreen: No saved address found - skipping zone validation');
          }
        }
      });
    }

    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (Get.find<HomeController>().showFavButton) {
          Get.find<HomeController>().changeFavVisibility();
          Future.delayed(const Duration(milliseconds: 800),
              () => Get.find<HomeController>().changeFavVisibility());
        }
      } else {
        if (Get.find<HomeController>().showFavButton) {
          Get.find<HomeController>().changeFavVisibility();
          Future.delayed(const Duration(milliseconds: 800),
              () => Get.find<HomeController>().changeFavVisibility());
        }
      }
    });
  }

  @override
  void dispose() {
    appLogger.logPageExit();
    _deferredLoadTimer?.cancel();
    super.dispose();
    scrollController.dispose();
  }

  /// 🩹 SELF-HEAL: ensures a module is selected so the unified home can render.
  /// Resolves in order: existing cached/single module (via resolveInitialModule),
  /// then a sensible default (module 3 or the first available). Without this,
  /// entering the home with no module selected (e.g. right after login) leaves
  /// the build guard stuck on an infinite "loading" spinner.
  Future<void> _ensureModuleSelected(SplashController splashController) async {
    if (_resolvingModule || splashController.selectedModule.value != null) {
      return;
    }
    _resolvingModule = true;
    try {
      List<ModuleModel>? list = splashController.moduleList;
      if (list == null || list.isEmpty) {
        await splashController.getModules();
        list = splashController.moduleList;
      }
      if (splashController.selectedModule.value != null) return;
      if (list == null || list.isEmpty) return;

      // Try cached / single-module resolution first.
      await splashController.resolveInitialModule(list);
      if (splashController.selectedModule.value != null) {
        // resolveInitialModule sets the Rx directly without notifying the
        // GetBuilder — force a rebuild so the home renders immediately.
        splashController.update();
        return;
      }

      // Multiple modules and no cached choice → fall back to a default so the
      // unified home still renders (module can be switched from the home).
      final int? defaultId = splashController.getDefaultModuleId();
      ModuleModel? def;
      for (final m in list) {
        if (m.id == defaultId) {
          def = m;
          break;
        }
      }
      def ??= list.first;
      await splashController.setModule(def); // setModule() calls update()
    } finally {
      _resolvingModule = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      // 🏗️ MODULE-FIRST ARCHITECTURE: Defensive Layer
      // This is a safety net - Route Guard should prevent this, but defense in depth
      final selectedModule = splashController.selectedModule.value;
      if (selectedModule == null && splashController.module == null) {
        // 🩹 SELF-HEAL: instead of spinning forever, resolve a module (cached /
        // single / sensible default) so the unified home can render. This is
        // what unsticks the loader users hit straight after login, where the
        // post-OTP navigation lands on the dashboard without a selected module.
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _ensureModuleSelected(splashController));
        if (kDebugMode) {
          debugPrint(
              '🏗️ [Module-First] HomeScreen: Module is null - resolving module (self-heal)');
        }
        // Show the home skeleton (shimmer) while the module self-heals, instead
        // of a spinner + "loading" text.
        return const Scaffold(
          backgroundColor: Color(0xffFFFFFF),
          body: SafeArea(child: ShopHomeSkeleton()),
        );
      }

      // FIRST: Check if we should show multi-module selection screen (MAIN ENTRY POINT)
      // Multi-module screen is ALWAYS the main home screen when multiple modules exist
      // This check must happen BEFORE any auto-switching or config module logic
      final moduleList = splashController.moduleList;
      final moduleListLength = moduleList?.length ?? 0;

      // CRITICAL: Load modules if not loaded yet or if list is empty
      if (moduleList == null || moduleListLength == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          splashController.getModules();
        });
        // When API returns empty module list, show empty state instead of spinner.
        return NoDataScreen(
          text: 'home_no_places_available'.tr,
          subtitle: 'home_no_places_available_subtitle'.tr,
          actionWidget: ElevatedButton(
            onPressed: () {
              splashController.getModules(dataSource: DataSourceEnum.client);
            },
            child: Text('retry'.tr),
          ),
          showFooter: false,
        );
      }

      // 🏗️ MODULE-FIRST ARCHITECTURE: Check Single Source of Truth
      // Show multi-module screen when:
      // 1. No module is currently selected (selectedModule == null)
      // 2. Multiple modules exist (moduleListLength > 1)
      // This takes priority over configModel.module to ensure user always sees module selection
      // Note: selectedModule already defined above (line 800)
      final bool showMultiModuleScreen = selectedModule == null &&
          splashController.module == null &&
          moduleListLength > 1;

      // Multi-module screen is handled by DashboardScreen.
      if (showMultiModuleScreen) {
        return const SizedBox.shrink();
      }

      // 🏗️ MODULE-FIRST ARCHITECTURE: Handle single module auto-selection
      // Only auto-select if there's exactly 1 module (skip selection screen)
      if (splashController.moduleList != null &&
          splashController.moduleList!.length == 1 &&
          selectedModule == null &&
          splashController.module == null) {
        final singleModule = splashController.moduleList!.first;
        splashController.selectModule(singleModule, context: context);
      }

      // Only use config module if:
      // 1. No module is selected
      // 2. Module list is null or has only 1 module (so we're not bypassing multi-module screen)
      // This ensures configModel doesn't override the multi-module screen choice
      if (splashController.module == null &&
          splashController.configModel != null &&
          splashController.configModel!.module != null &&
          (moduleListLength <= 1)) {
        splashController.setModule(splashController.configModel!.module);
      }

      // ⚡ Cache-First Fix: Show Skeleton if module == null (no module selected)
      // This prevents empty screen on first load when module hasn't been selected yet
      if (splashController.module == null) {
        if (kDebugMode) {
          debugPrint(
              '[Cache-First] HomeScreen: Module is null - showing skeleton');
        }
        // Show the home skeleton (shimmer) while waiting for module selection
        // instead of a spinner, so the loading state matches the rest of the app.
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const SafeArea(child: ShopHomeSkeleton()),
        );
      }

      // Show loading screen if module is being determined
      // But only if we don't have data loaded yet
      if (splashController.module == null &&
          splashController.configModel != null &&
          splashController.configModel!.module != null) {
        // Check if we have data loaded - if we do, don't show loading screen
        bool hasData = false;
        try {
          if (Get.isRegistered<BannerController>()) {
            final bannerController = Get.find<BannerController>();
            if (bannerController.bannerImageList != null &&
                bannerController.bannerImageList!.isNotEmpty) {
              hasData = true;
            }
          }
        } catch (e) {
          // Controller not ready yet
        }

        if (!hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(Images.logo_gif, width: 200),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
      }


      // Use config module as fallback if module is null
      final ModuleModel? currentModule =
          splashController.module ?? splashController.configModel?.module;

      // bool isParcel = splashController.module != null && splashController.configModel!.moduleConfig!.module!.isParcel!;
      final bool isParcel = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.parcel;
      // 🎨 REDESIGN: Module-specific legacy content is hidden for all modules
      // except taxi, so only the parcel/taxi flags are still needed here.
      final bool isTaxi = currentModule != null &&
          currentModule.moduleType.toString() == AppConstants.taxi;

      _logUiStateSnapshot('HomeScreen.build', splashController);

      return GetBuilder<HomeController>(builder: (homeController) {
        final bool showUnifiedHomeError = !isParcel &&
            AppConstants.useBffV2Endpoint &&
            Get.isRegistered<HomeUnifiedController>() &&
            Get.find<HomeUnifiedController>().hasError &&
            !Get.find<HomeUnifiedController>().isLoading &&
            !Get.find<HomeUnifiedController>().hasCachedData;
        return Scaffold(
          appBar: ResponsiveHelper.isDesktop(context)
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(120.0),
                  child: WebMenuBar(),
                )
              // 🎨 REDESIGN: White greeting header (replaces green gradient bar)
              : PreferredSize(
                  preferredSize:
                      Size.fromHeight(MediaQuery.of(context).padding.top + 60),
                  child: const HomeHeader(),
                ),

          // endDrawer: const MenuDrawer(),
          endDrawerEnableOpenDragGesture: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: isParcel
              ? const ParcelCategoryScreen()
              : showUnifiedHomeError
                  ? ErrorStateView(
                      onRetry: () {
                        if (Get.isRegistered<HomeUnifiedController>()) {
                          Get.find<HomeUnifiedController>().loadHomeData(
                            forceRefresh: true,
                            showLoading: true,
                          );
                        }
                      },
                    )
                  : SafeArea(
                      top: false,
                      bottom: true,
                      left: false,
                      right: false,
                      minimum: EdgeInsets.zero,
                      child: RefreshIndicator(
                        onRefresh: () async {
                          splashController.setRefreshing(true);
                          try {
                            await HomeScreen.performHardRefresh(context);
                          } finally {
                            splashController.setRefreshing(false);
                          }
                        },
                        child: ResponsiveHelper.isDesktop(context)
                            ? WebNewHomeScreen(
                                scrollController: scrollController,
                              )
                            : CustomScrollView(
                                controller: scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  // 🎨 REDESIGN: Context-aware notice (join / set address)
                                  const SliverToBoxAdapter(
                                    child: HomeTopNoticeStrip(),
                                  ),

                                  // 🎨 REDESIGN: Promotional banner (≈ 322×152)
                                  const SliverToBoxAdapter(
                                    child: HomeBannerView(),
                                  ),

                                  // 🎨 REDESIGN: "خدماتنا" services bento grid
                                  const SliverToBoxAdapter(
                                    child: HomeServicesGrid(),
                                  ),

                                  // 🎨 REDESIGN: "العروض الحالية" offers rail —
                                  // all sections, auto-scrolls back and forth.
                                  const SliverToBoxAdapter(
                                    child: HomeCurrentOffersSection(
                                      autoScroll: true,
                                    ),
                                  ),

                                  // Old "عروض وخصومات" promo design (OffersView)
                                  // shown alongside — additive, nothing removed.
                                  const SliverToBoxAdapter(
                                      child: _OldOffersSection()),

                                  // "اكتشف خدمات أكثر" promo banner removed.

                                  // 🎨 REDESIGN: "أعد طلبك" recent orders
                                  const SliverToBoxAdapter(
                                    child: HomeReorderSection(),
                                  ),

                                  // 🎨 REDESIGN: Horizontal module switcher hidden —
                                  // module switching now lives in HomeServicesGrid.
                                  const SliverToBoxAdapter(
                                      child: SizedBox.shrink()),

                                  // Module-specific home screens content.
                                  // 🎨 REDESIGN: the legacy multi-module list
                                  // (ModuleView) is no longer shown — service
                                  // navigation lives in HomeServicesGrid. Only
                                  // the taxi flow / Akhdamni flow render here.
                                  SliverToBoxAdapter(
                                    child: FlattenedModuleContent(
                                      // ⚡ TASK 1: Flattened widget tree
                                      moduleWidget:
                                          GetBuilder<AkhdamniFlowController>(
                                        builder: (akhdamniController) {
                                          if (akhdamniController.isFlowActive) {
                                            return const AkhdamniFlowSection();
                                          }
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Legacy module content (categories,
                                              // brands, offers, products, banners,
                                              // top stores) is hidden for every
                                              // module except taxi.
                                              isTaxi
                                                  ? TaxiHomeScreen()
                                                  : const SizedBox.shrink(),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // ⚡ UNIFIED: "All Stores" section moved to ShopHomeScreen
                                  // This keeps all module-specific content in one place
                                ],
                              ),
                      ),
                    ),
          floatingActionButton: AuthHelper.isLoggedIn() &&
                  homeController.cashBackOfferList != null &&
                  homeController.cashBackOfferList!.isNotEmpty
              ? homeController.showFavButton
                  ? Padding(
                      padding: EdgeInsets.only(
                          bottom: 50.0,
                          right: ResponsiveHelper.isDesktop(context) ? 50 : 0),
                      child: InkWell(
                        onTap: () => Get.dialog(const CashBackDialogWidget()),
                        child: const CashBackLogoWidget(),
                      ),
                    )
                  : null
              : null,
        );
      });
    });
  }
}

/// Additive wrapper for the old "عروض وخصومات" design on the unified home:
/// loads offers across the available modules (once, if empty) so [OffersView]
/// has data, then renders it. Nothing existing is touched.
class _OldOffersSection extends StatefulWidget {
  const _OldOffersSection();

  @override
  State<_OldOffersSection> createState() => _OldOffersSectionState();
}

class _OldOffersSectionState extends State<_OldOffersSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!Get.isRegistered<OffersController>() ||
        !Get.isRegistered<SplashController>()) {
      return;
    }
    final controller = Get.find<OffersController>();
    if (controller.offersMode?.data.isNotEmpty ?? false) return; // already loaded
    final ids = (Get.find<SplashController>().moduleList ?? const [])
        .map((m) => m.id)
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return;
    await controller.getAggregatedOffers(ids);
  }

  @override
  Widget build(BuildContext context) => const OffersView();
}
