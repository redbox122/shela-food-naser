import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';

import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/item_widget.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/common/widgets/veg_filter_widget.dart';
import 'package:sixam_mart/common/widgets/web_item_view.dart';
import 'package:sixam_mart/common/widgets/web_item_widget.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/search/widgets/custom_check_box_widget.dart';
import 'package:sixam_mart/features/store/widgets/customizable_space_bar_widget.dart';
import 'package:sixam_mart/features/store/widgets/store_banner_widget.dart';
import 'package:sixam_mart/features/store/widgets/store_description_view_widget.dart';
import 'package:sixam_mart/features/store/widgets/flattened_store_header_web.dart';
import 'package:sixam_mart/features/store/screens/food_restaurant_detail_screen.dart';
import 'package:sixam_mart/features/store/screens/grocery_store_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/loading/loading.dart';
import '../widgets/bottom_cart_widget.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class StoreScreen extends StatefulWidget {
  final Store? store;
  final bool fromModule;
  final String slug;
  final String? heroBannerTag;
  final String? heroLogoTag;
  const StoreScreen(
      {super.key,
      required this.store,
      required this.fromModule,
      this.slug = '',
      this.heroBannerTag,
      this.heroLogoTag});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ScrollController scrollController = ScrollController();
  final ScrollController scrollController2 = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _requestedStoreBootstrap = false;
  int? _resolveTargetModuleId() {
    return widget.store?.moduleId ?? Get.find<SplashController>().module?.id;
  }
  String? _resolveTargetModuleType() {
    final SplashController splashController = Get.find<SplashController>();
    final int? targetModuleId = _resolveTargetModuleId();
    if (targetModuleId != null) {
      final ModuleModel? targetModule = splashController.moduleList
          ?.cast<ModuleModel?>()
          .firstWhere(
            (ModuleModel? module) => module?.id == targetModuleId,
            orElse: () => null,
          );
      if (targetModule?.moduleType != null &&
          targetModule!.moduleType!.isNotEmpty) {
        return targetModule.moduleType;
      }
    }
    return splashController.module?.moduleType?.toString();
  }

  @override
  void initState() {
    super.initState();

    // ✅ PROFESSIONAL SCREEN LOGGING: Track screen lifecycle for debugging
    if (kDebugMode) {
      debugPrint('📄 SCREEN INIT: StoreScreen');
      debugPrint('   - route: ${Get.currentRoute}');
      debugPrint('   - parameters: ${Get.parameters}');
      debugPrint('   - arguments: ${Get.arguments}');
    }

    appLogger.logPageEntry('StoreScreen');
    appLogger
        .info('📍 StoreScreen: Initializing (redirect only - no data loading)');
    appLogger.debug('StoreScreen: Store ID = ${widget.store?.id}');
    appLogger.debug('StoreScreen: From Module = ${widget.fromModule}');
    appLogger.debug('StoreScreen: Slug = ${widget.slug}');

    // ✅ FIX #1: StoreScreen is ONLY a redirect wrapper - no data loading needed
    // FoodRestaurantDetailScreen / GroceryStoreDetailScreen handle all data loading
    // This prevents 3 lifecycle calls and duplicate API requests
    // initDataCall() removed - specialized screens handle initialization
    _bootstrapStoreIfNeeded();
  }

  void _bootstrapStoreIfNeeded() {
    final String? moduleType = _resolveTargetModuleType();
    final int? targetModuleId = _resolveTargetModuleId();
    final bool isFood = moduleType == AppConstants.food;
    final bool isGrocery = moduleType == AppConstants.grocery || targetModuleId == 7;

    // Food/Grocery have dedicated screens that handle their own loading.
    if (isFood || isGrocery) return;

    final int? storeId = widget.store?.id;
    final bool hasFullStoreData = (widget.store?.name ?? '').isNotEmpty;
    if (storeId == null || storeId <= 0 || hasFullStoreData) return;
    if (_requestedStoreBootstrap) return;

    _requestedStoreBootstrap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<StoreController>()
          .getStoreDetails(
            context,
            Store(id: storeId, moduleId: targetModuleId),
            widget.fromModule,
            slug: widget.slug,
          )
          .catchError((_) => null);
    });
  }

  @override
  void dispose() {
    // ✅ PROFESSIONAL SCREEN LOGGING: Track screen disposal
    if (kDebugMode) {
      debugPrint('🗑️ SCREEN DISPOSE: StoreScreen');
      debugPrint('   - route: ${Get.currentRoute}');
    }

    appLogger.logPageExit();
    appLogger.info('📍 StoreScreen: Disposed');

    scrollController.dispose();
    scrollController2.dispose();
    super.dispose();
  }

  // ✅ FIX #1: initDataCall() removed - StoreScreen is ONLY a redirect wrapper
  // All data loading is handled by FoodRestaurantDetailScreen / GroceryStoreDetailScreen
  // This prevents duplicate API calls and lifecycle conflicts

  @override
  Widget build(BuildContext context) {
    // ⚡ TASK 4: Removed appLogger from build loop for 120Hz performance

    // Check module type and redirect to specialized screens
    final String? moduleType = _resolveTargetModuleType();
    final int? targetModuleId = _resolveTargetModuleId();
    final bool isFood = moduleType == AppConstants.food;
    final bool isGrocery =
        moduleType == AppConstants.grocery || targetModuleId == 7;

    // For food module, use the redesigned FoodRestaurantDetailScreen
    if (isFood) {
      // ⚡ TASK 4: Removed appLogger from build loop for 120Hz performance
      return FoodRestaurantDetailScreen(
        store: widget.store,
        fromModule: widget.fromModule,
        slug: widget.slug,
        heroBannerTag: widget.heroBannerTag,
        heroLogoTag: widget.heroLogoTag,
      );
    }

    // For grocery module (module ID 7), use the specialized GroceryStoreDetailScreen
    if (isGrocery) {
      // ⚡ TASK 4: Removed appLogger from build loop for 120Hz performance
      return GroceryStoreDetailScreen(
        store: widget.store,
        fromModule: widget.fromModule,
        slug: widget.slug,
        heroBannerTag: widget.heroBannerTag,
      );
    }

    // Unified StoreScreen implementation for other modules (ecommerce, pharmacy, etc.)
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // 🛑 TASK 1: HARD-QUARANTINE - Cancel all pending menu requests on Back button
          // This prevents zombie data from overwriting the screen
          final storeController = Get.find<StoreController>();
          storeController.cancelAllPendingRequests();
        }
      },
      child: Scaffold(
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        endDrawerEnableOpenDragGesture: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: GetBuilder<StoreController>(builder: (storeController) {
          // ⚡ INSTANT UI: Use widget.store for immediate render, fallback to storeController.store
          // This achieves 0ms perceived load time by showing header immediately
          // 🔒 STALE-CACHE GUARD: Only use the controller's store if its id matches
          // the requested route id. Otherwise the previously visited store
          // (e.g. "Hyper Shella") would flash before the new store loads.
          final Store? controllerStore = storeController.store;
          final int? requestedStoreId = widget.store?.id;
          final bool controllerMatchesRoute = controllerStore != null &&
              requestedStoreId != null &&
              controllerStore.id == requestedStoreId;

          if (kDebugMode &&
              controllerStore != null &&
              requestedStoreId != null &&
              controllerStore.id != requestedStoreId) {
            debugPrint(
              '[STORE_DETAILS_STALE_IGNORED] generic requestedId=$requestedStoreId '
              'cachedId=${controllerStore.id}',
            );
          }

          Store? displayStore;
          if (controllerMatchesRoute) {
            displayStore = controllerStore;
          } else if (widget.store != null) {
            displayStore = widget.store;
          }

          // ✅ FIX: If widget.store is missing cover photo but storeController.store has it, prefer storeController.store
          // (only when the controller store id matches the requested route id)
          if (controllerMatchesRoute &&
              displayStore == widget.store &&
              (displayStore?.coverPhotoFullUrl == null ||
                  displayStore!.coverPhotoFullUrl!.isEmpty) &&
              controllerStore.coverPhotoFullUrl != null &&
              controllerStore.coverPhotoFullUrl!.isNotEmpty) {
            displayStore = controllerStore;
          }

          // Ensure displayStore is not null for the rest of the build
          displayStore ??= widget.store;

          // Only show error if both storeController.store AND widget.store are null
          if (displayStore == null || displayStore.name == null) {
            // No error code yet → still loading (initial fetch / module switch).
            // Show the loading state instead of flashing the error screen.
            final bool hasRealError =
                storeController.storeErrorStatusCode != null;
            if (!hasRealError) {
              return const Center(
                child: LoadingWidget(messageKey: 'loading', showMessage: true),
              );
            }
            final bool isNetworkError =
                storeController.storeErrorStatusCode == 1;
            return ErrorStateView(
              titleKey: 'something_went_wrong',
              subtitleKey: isNetworkError
                  ? 'no_internet_connection'
                  : 'unable_to_load_store_data',
              onRetry: () {
                final int? storeId = widget.store?.id;
                if (storeId != null && storeId > 0) {
                  storeController.getStoreDetails(
                    context,
                    Store(id: storeId, moduleId: targetModuleId),
                    widget.fromModule,
                    slug: widget.slug,
                  );
                } else {
                  Get.back<void>();
                }
              },
            );
          }

          // 🔧 FIX: Don't call setCategoryList() in build() - it's already called in initDataCall() after store details are loaded
          // Calling it here causes race condition where old store data is used before _store is updated
          // Categories will be set after loadAllStoreDetails() completes in initDataCall()

          // ⚡ INSTANT UI: Render header immediately with displayStore, show shimmer for categories/items
          // Header renders instantly (0ms perceived load), categories/items show shimmer until loaded
          // Categories and items only render when storeController.store is loaded (not just widget.store)
          final storeLoaded = storeController.store != null;

          return (displayStore.name != null)
              ? CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: scrollController,
                  slivers: [
                    ResponsiveHelper.isDesktop(context)
                        ? SliverToBoxAdapter(
                            child: FlattenedStoreHeaderWeb(
                                store:
                                    displayStore), // ⚡ TASK 1: Flattened widget tree
                          )
                        : SliverAppBar(
                            expandedHeight: 300,
                            toolbarHeight: 100,
                            pinned: true,
                            elevation: 0.5,
                            backgroundColor: Theme.of(context).cardColor,
                            leading: IconButton(
                              icon: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).primaryColor),
                                alignment: Alignment.center,
                                child: Icon(Icons.chevron_left,
                                    color: Theme.of(context).cardColor),
                              ),
                              onPressed: () => Get.back<void>(),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              titlePadding: EdgeInsets.zero,
                              centerTitle: true,
                              expandedTitleScale: 1.1,
                              title: SingleChildScrollView(
                                child: CustomizableSpaceBarWidget(
                                  builder: (context, scrollingRate) {
                                    return Container(
                                      height: displayStore!.discount != null
                                          ? 145
                                          : 100,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(
                                                    Dimensions.radiusLarge)),
                                      ),
                                      child: Column(
                                        children: [
                                          displayStore.discount != null
                                              ? Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                    borderRadius: const BorderRadius
                                                        .vertical(
                                                        top: Radius.circular(
                                                            Dimensions
                                                                .radiusLarge)),
                                                  ),
                                                  padding: EdgeInsets.all(Dimensions
                                                          .paddingSizeExtraSmall -
                                                      (GetPlatform.isAndroid
                                                          ? (scrollingRate *
                                                              Dimensions
                                                                  .paddingSizeExtraSmall)
                                                          : 0)),
                                                  child: Text(
                                                    '${displayStore.discount!.discountType == 'percent' ? '${displayStore.discount!.discount}% ${'off'.tr}' : '${PriceConverter.convertPrice(displayStore.discount!.discount)} ${'off'.tr}'} '
                                                    '${'on_all_products'.tr}, ${'after_minimum_purchase'.tr} ${PriceConverter.convertPrice(displayStore.discount!.minPurchase)},'
                                                    ' ${'daily_time'.tr}: ${DateConverter.convertTimeToTime(displayStore.discount!.startTime!)} '
                                                    '- ${DateConverter.convertTimeToTime(displayStore.discount!.endTime!)}',
                                                    style: robotoBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onError,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )
                                              : const SizedBox(),
                                          Container(
                                            color: Theme.of(context)
                                                .cardColor
                                                .withValues(
                                                    alpha: scrollingRate),
                                            padding: EdgeInsets.only(
                                              left: Get.find<
                                                          LocalizationController>()
                                                      .isLtr
                                                  ? 40 * scrollingRate
                                                  : 0,
                                              right: Get.find<
                                                          LocalizationController>()
                                                      .isLtr
                                                  ? 0
                                                  : 40 * scrollingRate,
                                            ),
                                            child: Align(
                                              alignment: Alignment.bottomLeft,
                                              child: Container(
                                                height: 100,
                                                color: Theme.of(context)
                                                    .cardColor
                                                    .withValues(
                                                        alpha:
                                                            scrollingRate == 0.0
                                                                ? 1
                                                                : 0),
                                                padding: EdgeInsets.only(
                                                  left: Get.find<
                                                              LocalizationController>()
                                                          .isLtr
                                                      ? 20
                                                      : 0,
                                                  right: Get.find<
                                                              LocalizationController>()
                                                          .isLtr
                                                      ? 0
                                                      : 20,
                                                ),
                                                child: Row(children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusSmall),
                                                    child: Stack(children: [
                                                      // ✅ FIX: Removed duplicate Hero widget - using SliverAppBar background Hero instead
                                                      CustomImage(
                                                        image: displayStore
                                                                .logoFullUrl ??
                                                            '',
                                                        height: 60 -
                                                            (scrollingRate *
                                                                15),
                                                        width: 70 -
                                                            (scrollingRate *
                                                                15),
                                                      ),
                                                      // ✅ FRONTEND ONLY: Use store.isOpen from API only
                                                      (displayStore.isOpen ==
                                                              true)
                                                          ? const SizedBox()
                                                          : Positioned(
                                                              bottom: 0,
                                                              left: 0,
                                                              right: 0,
                                                              child: Container(
                                                                height: 30,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius: const BorderRadius
                                                                      .vertical(
                                                                      bottom: Radius.circular(
                                                                          Dimensions
                                                                              .radiusSmall)),
                                                                  color: Colors
                                                                      .black
                                                                      .withValues(
                                                                          alpha:
                                                                              0.6),
                                                                ),
                                                                child: Text(
                                                                  'closed_now'
                                                                      .tr,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: robotoRegular.copyWith(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          Dimensions
                                                                              .fontSizeSmall),
                                                                ),
                                                              ),
                                                            ),
                                                    ]),
                                                  ),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall),
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                        Row(children: [
                                                          Expanded(
                                                              child: Text(
                                                            displayStore.name!,
                                                            style: robotoMedium.copyWith(
                                                                fontSize: Dimensions
                                                                        .fontSizeLarge -
                                                                    (scrollingRate *
                                                                        3),
                                                                color: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium!
                                                                    .color),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          )),
                                                          const SizedBox(
                                                              width: Dimensions
                                                                  .paddingSizeSmall),
                                                        ]),
                                                        const SizedBox(
                                                            height: Dimensions
                                                                .paddingSizeExtraSmall),
                                                        Text(
                                                          displayStore
                                                                  .address ??
                                                              '',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: robotoRegular.copyWith(
                                                              fontSize: Dimensions
                                                                      .fontSizeSmall -
                                                                  (scrollingRate *
                                                                      2),
                                                              color: Theme.of(
                                                                      context)
                                                                  .disabledColor),
                                                        ),
                                                        SizedBox(
                                                            height: ResponsiveHelper
                                                                    .isDesktop(
                                                                        context)
                                                                ? Dimensions
                                                                    .paddingSizeExtraSmall
                                                                : 0),
                                                        Row(children: [
                                                          Flexible(
                                                            child: Text(
                                                                'minimum_order'
                                                                    .tr,
                                                                style:
                                                                    robotoRegular
                                                                        .copyWith(
                                                                  fontSize: Dimensions
                                                                          .fontSizeExtraSmall -
                                                                      (scrollingRate *
                                                                          2),
                                                                  color: Theme.of(
                                                                          context)
                                                                      .disabledColor,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis),
                                                          ),
                                                          const SizedBox(
                                                              width: Dimensions
                                                                  .paddingSizeExtraSmall),
                                                          PriceConverter
                                                              .convertPrice2(
                                                            displayStore
                                                                .minimumOrder,
                                                            textStyle: robotoMedium.copyWith(
                                                                fontSize: Dimensions
                                                                        .fontSizeExtraSmall -
                                                                    (scrollingRate *
                                                                        2),
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor),
                                                          ),
                                                        ]),
                                                      ])),
                                                  GetBuilder<
                                                          FavouriteController>(
                                                      builder:
                                                          (favouriteController) {
                                                    final bool isWished =
                                                        favouriteController
                                                            .wishStoreIdList
                                                            .contains(
                                                                displayStore!
                                                                    .id);
                                                    return InkWell(
                                                      onTap: () {
                                                        if (AuthHelper
                                                            .isLoggedIn()) {
                                                          isWished
                                                              ? favouriteController
                                                                  .removeFromFavouriteList(
                                                                      displayStore!
                                                                          .id,
                                                                      true)
                                                              : favouriteController
                                                                  .addToFavouriteList(
                                                                      null,
                                                                      displayStore
                                                                          ?.id,
                                                                      true);
                                                        } else {
                                                          showCustomSnackBar(
                                                              'you_are_not_logged_in'
                                                                  .tr);
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1),
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusDefault),
                                                        ),
                                                        padding: const EdgeInsets
                                                            .all(Dimensions
                                                                .paddingSizeExtraSmall),
                                                        child: Icon(
                                                          isWished
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color: isWished
                                                              ? Theme.of(
                                                                      context)
                                                                  .primaryColor
                                                              : Theme.of(
                                                                      context)
                                                                  .disabledColor,
                                                          size: 24 -
                                                              (scrollingRate *
                                                                  4),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall),
                                                  AppConstants.webHostedUrl
                                                          .isNotEmpty
                                                      ? InkWell(
                                                          onTap: () {
                                                            storeController
                                                                .shareStore();
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      Dimensions
                                                                          .radiusDefault),
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(
                                                                    Dimensions
                                                                        .paddingSizeExtraSmall),
                                                            child: Icon(
                                                              Icons.share,
                                                              size: 24 -
                                                                  (scrollingRate *
                                                                      4),
                                                            ),
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall),
                                                ]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              background: Hero(
                                tag: 'store_image_${displayStore.id}',
                                flightShuttleBuilder: (flightContext,
                                    animation,
                                    flightDirection,
                                    fromHeroContext,
                                    toHeroContext) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      final curvedAnimation = CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutBack,
                                      );
                                      return FadeTransition(
                                        opacity: curvedAnimation,
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                                  begin: 0.9, end: 1.0)
                                              .animate(curvedAnimation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        CustomImage(
                                          image: ((displayStore
                                                      ?.coverPhotoFullUrl
                                                      ?.isNotEmpty ??
                                                  false))
                                              ? (displayStore
                                                      ?.coverPhotoFullUrl ??
                                                  '')
                                              : (displayStore?.logoFullUrl ??
                                                  ''),
                                          height: double.infinity,
                                          width: double.infinity,
                                        ),
                                        BackdropFilter(
                                          filter: ui.ImageFilter.blur(
                                              sigmaX: 20.0, sigmaY: 20.0),
                                          child: Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .scrim
                                                  .withValues(alpha: 0.1)),
                                        ),
                                        Center(
                                          child: CustomImage(
                                            fit: BoxFit.contain,
                                            image: ((displayStore
                                                        ?.coverPhotoFullUrl
                                                        ?.isNotEmpty ??
                                                    false))
                                                ? (displayStore
                                                        ?.coverPhotoFullUrl ??
                                                    '')
                                                : (displayStore?.logoFullUrl ??
                                                    ''),
                                            height: double.infinity,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    CustomImage(
                                      image: ((displayStore.coverPhotoFullUrl
                                                  ?.isNotEmpty ??
                                              false))
                                          ? (displayStore.coverPhotoFullUrl ??
                                              '')
                                          : (displayStore.logoFullUrl ?? ''),
                                      height: double.infinity,
                                      width: double.infinity,
                                    ),
                                    BackdropFilter(
                                      filter: ui.ImageFilter.blur(
                                          sigmaX: 20.0, sigmaY: 20.0),
                                      child: Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .scrim
                                              .withValues(alpha: 0.1)),
                                    ),
                                    Center(
                                      child: CustomImage(
                                        fit: BoxFit.contain,
                                        image: ((displayStore.coverPhotoFullUrl
                                                    ?.isNotEmpty ??
                                                false))
                                            ? (displayStore.coverPhotoFullUrl ??
                                                '')
                                            : (displayStore.logoFullUrl ?? ''),
                                        height: double.infinity,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: const [
                              SizedBox(),
                            ],
                          ),

                    (ResponsiveHelper.isDesktop(context) &&
                            storeController
                                    .recommendedItemModel?.items?.isNotEmpty ==
                                true)
                        ? SliverToBoxAdapter(
                            child: Container(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.10),
                              child: Center(
                                child: SizedBox(
                                  width: Dimensions.webMaxWidth,
                                  height: ResponsiveHelper.isDesktop(context)
                                      ? 325
                                      : 125,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                          height: Dimensions.paddingSizeSmall),
                                      Text('recommended_for_you'.tr,
                                          style: robotoMedium.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(
                                          height:
                                              Dimensions.paddingSizeExtraSmall),
                                      Text('here_is_what_you_might_like'.tr,
                                          style: robotoRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              color: Theme.of(context)
                                                  .disabledColor)),
                                      const SizedBox(
                                          height:
                                              Dimensions.paddingSizeExtraSmall),
                                      SizedBox(
                                        height: 250,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          itemCount: storeController
                                                  .recommendedItemModel
                                                  ?.items
                                                  ?.length ??
                                              0,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: Dimensions
                                                  .paddingSizeExtraSmall),
                                          itemBuilder: (context, index) {
                                            return Container(
                                              width: 225,
                                              padding: const EdgeInsets.only(
                                                  right: Dimensions
                                                      .paddingSizeSmall,
                                                  left: Dimensions
                                                      .paddingSizeExtraSmall),
                                              margin: const EdgeInsets.only(
                                                  right: Dimensions
                                                      .paddingSizeSmall),
                                              child: WebItemWidget(
                                                isStore: false,
                                                item: storeController
                                                    .recommendedItemModel!
                                                    .items![index],
                                                store: null,
                                                index: index,
                                                length: null,
                                                inStore: true,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SliverToBoxAdapter(child: SizedBox()),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: Dimensions.paddingSizeSmall)),

                    ///web view..
                    ResponsiveHelper.isDesktop(context)
                        ? SliverToBoxAdapter(
                            child: FooterView(
                              child: SizedBox(
                                width: Dimensions.webMaxWidth,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: Dimensions.paddingSizeSmall),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 175,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: storeController
                                                        .categoryList?.length ??
                                                    0,
                                                padding: const EdgeInsets.only(
                                                    left: Dimensions
                                                        .paddingSizeSmall),
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemBuilder: (context, index) {
                                                  return InkWell(
                                                    onTap: () {
                                                      storeController
                                                          .setCategoryIndex(
                                                              index,
                                                              itemSearching:
                                                                  storeController
                                                                      .isSearching);
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .only(
                                                          bottom: Dimensions
                                                              .paddingSizeSmall),
                                                      child: Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: Dimensions
                                                                .paddingSizeSmall,
                                                            vertical: Dimensions
                                                                .paddingSizeExtraSmall),
                                                        decoration:
                                                            BoxDecoration(
                                                                gradient: LinearGradient(
                                                                    begin: Alignment
                                                                        .bottomRight,
                                                                    end: Alignment
                                                                        .topLeft,
                                                                    colors: <Color>[
                                                              index ==
                                                                      storeController
                                                                          .categoryIndex
                                                                  ? Theme.of(
                                                                          context)
                                                                      .primaryColor
                                                                      .withValues(
                                                                          alpha:
                                                                              0.50)
                                                                  : Colors
                                                                      .transparent,
                                                              index ==
                                                                      storeController
                                                                          .categoryIndex
                                                                  ? Theme.of(
                                                                          context)
                                                                      .cardColor
                                                                  : Colors
                                                                      .transparent,
                                                            ])),
                                                        child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                storeController
                                                                        .categoryList?[
                                                                            index]
                                                                        .name ??
                                                                    '',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: index ==
                                                                        storeController
                                                                            .categoryIndex
                                                                    ? robotoMedium.copyWith(
                                                                        fontSize:
                                                                            Dimensions
                                                                                .fontSizeSmall,
                                                                        color: Theme.of(context)
                                                                            .primaryColor)
                                                                    : robotoRegular.copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeSmall),
                                                              ),
                                                            ]),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            // ⚡ TASK 3: Browse Complete Catalog button for large stores
                                            if (storeController
                                                .isLargeStore) ...[
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeSmall),
                                              InkWell(
                                                onTap: () {
                                                  final int? storeId =
                                                      displayStore?.id;
                                                  if (storeId == null) {
                                                    showCustomSnackBar(
                                                        'something_went_wrong'
                                                            .tr);
                                                    return;
                                                  }
                                                  Get.toNamed(
                                                    RouteHelper
                                                        .getSearchStoreItemRoute(
                                                            storeId),
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: Dimensions
                                                        .paddingSizeDefault,
                                                    vertical: Dimensions
                                                        .paddingSizeSmall,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Theme.of(context)
                                                            .primaryColor,
                                                        Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.8),
                                                      ],
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.search,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'browse_complete_catalog'
                                                            .tr,
                                                        style: robotoMedium
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeSmall,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                            Container(
                                              height: (storeController
                                                          .categoryList
                                                          ?.length ??
                                                      0) *
                                                  50,
                                              width: 1,
                                              color: Theme.of(context)
                                                  .disabledColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                          width: Dimensions.paddingSizeLarge),
                                      Expanded(
                                          child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                    Dimensions
                                                        .paddingSizeExtraSmall),
                                                height: 45,
                                                width: 430,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .radiusDefault),
                                                  color: Theme.of(context)
                                                      .cardColor,
                                                  border: Border.all(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                              alpha: 0.40)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            _searchController,
                                                        textInputAction:
                                                            TextInputAction
                                                                .search,
                                                        decoration:
                                                            InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(),
                                                          hintText:
                                                              'search_for_items'
                                                                  .tr,
                                                          hintStyle: robotoRegular.copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeSmall,
                                                              color: Theme.of(
                                                                      context)
                                                                  .disabledColor),
                                                          border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      Dimensions
                                                                          .radiusSmall),
                                                              borderSide:
                                                                  BorderSide
                                                                      .none),
                                                          filled: true,
                                                          fillColor:
                                                              Theme.of(context)
                                                                  .cardColor,
                                                          isDense: true,
                                                          prefixIcon: Icon(
                                                              Icons.search,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.50)),
                                                        ),
                                                        onSubmitted:
                                                            (String? value) {
                                                          if (value!
                                                              .isNotEmpty) {
                                                            Get.find<
                                                                    StoreController>()
                                                                .getStoreSearchItemList(
                                                              _searchController
                                                                  .text
                                                                  .trim(),
                                                              (displayStore
                                                                          ?.id ??
                                                                      widget
                                                                          .store
                                                                          ?.id ??
                                                                      storeController
                                                                          .store
                                                                          ?.id ??
                                                                      0)
                                                                  .toString(),
                                                              1,
                                                              storeController
                                                                  .type,
                                                            );
                                                          }
                                                        },
                                                        onChanged:
                                                            (String value) {
                                                          // Live search as user types
                                                          storeController
                                                              .performLiveSearch(
                                                                  value);
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeSmall),
                                                    !storeController.isSearching
                                                        ? CustomButton(
                                                            radius: Dimensions
                                                                .radiusSmall,
                                                            height: 40,
                                                            width: 74,
                                                            buttonText:
                                                                'search'.tr,
                                                            isBold: false,
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            onPressed: () {
                                                              storeController
                                                                  .getStoreSearchItemList(
                                                                _searchController
                                                                    .text
                                                                    .trim(),
                                                                (displayStore
                                                                            ?.id ??
                                                                        widget
                                                                            .store
                                                                            ?.id ??
                                                                        storeController
                                                                            .store
                                                                            ?.id ??
                                                                        0)
                                                                    .toString(),
                                                                1,
                                                                storeController
                                                                    .type,
                                                              );
                                                            },
                                                          )
                                                        : InkWell(
                                                            onTap: () {
                                                              _searchController
                                                                  .text = '';
                                                              storeController
                                                                  .initSearchData();
                                                              storeController
                                                                  .changeSearchStatus();
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColor,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          Dimensions
                                                                              .radiusSmall)),
                                                              padding: const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 3,
                                                                  horizontal:
                                                                      Dimensions
                                                                          .paddingSizeSmall),
                                                              child: const Icon(
                                                                  Icons.clear,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeSmall),

                                              // Live search field (shown when search icon is clicked)
                                              GetBuilder<StoreController>(
                                                builder: (storeController) {
                                                  return storeController
                                                          .isSearchFieldVisible
                                                      ? Container(
                                                          margin: const EdgeInsets
                                                              .only(
                                                              top: Dimensions
                                                                  .paddingSizeSmall),
                                                          padding: const EdgeInsets
                                                              .all(Dimensions
                                                                  .paddingSizeSmall),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    Dimensions
                                                                        .radiusDefault),
                                                            color: Theme.of(
                                                                    context)
                                                                .cardColor,
                                                            border: Border.all(
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.40)),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    TextField(
                                                                  controller:
                                                                      _searchController,
                                                                  textInputAction:
                                                                      TextInputAction
                                                                          .search,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    contentPadding:
                                                                        const EdgeInsets
                                                                            .symmetric(),
                                                                    hintText:
                                                                        'search_for_items'
                                                                            .tr,
                                                                    hintStyle: robotoRegular.copyWith(
                                                                        fontSize:
                                                                            Dimensions
                                                                                .fontSizeSmall,
                                                                        color: Theme.of(context)
                                                                            .disabledColor),
                                                                    border: OutlineInputBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(Dimensions
                                                                                .radiusSmall),
                                                                        borderSide:
                                                                            BorderSide.none),
                                                                    filled:
                                                                        true,
                                                                    fillColor: Theme.of(
                                                                            context)
                                                                        .cardColor,
                                                                    isDense:
                                                                        true,
                                                                    prefixIcon: Icon(
                                                                        Icons
                                                                            .search,
                                                                        color: Theme.of(context)
                                                                            .primaryColor
                                                                            .withValues(alpha: 0.50)),
                                                                  ),
                                                                  onChanged:
                                                                      (String
                                                                          value) {
                                                                    // Live search as user types
                                                                    storeController
                                                                        .performLiveSearch(
                                                                            value);
                                                                  },
                                                                  onSubmitted:
                                                                      (String?
                                                                          value) {
                                                                    if (value!
                                                                        .isNotEmpty) {
                                                                      storeController
                                                                          .performLiveSearch(
                                                                              value);
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: Dimensions
                                                                      .paddingSizeSmall),
                                                              InkWell(
                                                                onTap: () {
                                                                  _searchController
                                                                      .text = '';
                                                                  storeController
                                                                      .clearLiveSearch();
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration: BoxDecoration(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .primaryColor,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              Dimensions.radiusSmall)),
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          3,
                                                                      horizontal:
                                                                          Dimensions
                                                                              .paddingSizeSmall),
                                                                  child: const Icon(
                                                                      Icons
                                                                          .clear,
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : const SizedBox();
                                                },
                                              ),

                                              (Get.find<SplashController>()
                                                          .configModel!
                                                          .moduleConfig!
                                                          .module!
                                                          .vegNonVeg! &&
                                                      Get.find<
                                                              SplashController>()
                                                          .configModel!
                                                          .toggleVegNonVeg!)
                                                  ? SizedBox(
                                                      width: 300,
                                                      height: 30,
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemCount: Get.find<
                                                                ItemController>()
                                                            .itemTypeList
                                                            .length,
                                                        padding: const EdgeInsets
                                                            .only(
                                                            left: Dimensions
                                                                .paddingSizeSmall),
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        itemBuilder:
                                                            (context, index) {
                                                          return Padding(
                                                            padding: const EdgeInsets
                                                                .only(
                                                                right: Dimensions
                                                                    .paddingSizeSmall),
                                                            child:
                                                                CustomCheckBoxWidget(
                                                              title: Get.find<
                                                                      ItemController>()
                                                                  .itemTypeList[
                                                                      index]
                                                                  .tr,
                                                              value: storeController
                                                                      .type ==
                                                                  Get.find<ItemController>()
                                                                          .itemTypeList[
                                                                      index],
                                                              onClick: () {
                                                                if (storeController
                                                                    .isSearching) {
                                                                  storeController
                                                                      .getStoreSearchItemList(
                                                                    storeController
                                                                        .searchText,
                                                                    widget
                                                                        .store!
                                                                        .id
                                                                        .toString(),
                                                                    1,
                                                                    Get.find<ItemController>()
                                                                            .itemTypeList[
                                                                        index],
                                                                  );
                                                                } else {
                                                                  storeController.getStoreItemList(
                                                                      storeController
                                                                          .store!
                                                                          .id,
                                                                      1,
                                                                      Get.find<ItemController>()
                                                                              .itemTypeList[
                                                                          index],
                                                                      true);
                                                                }
                                                              },
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                            ],
                                          ),
                                          const SizedBox(
                                              height:
                                                  Dimensions.paddingSizeSmall),
                                          PaginatedListView(
                                            scrollController: scrollController,
                                            onPaginate: (int? offset) {
                                              if (storeController.isSearching) {
                                                storeController
                                                    .getStoreSearchItemList(
                                                  storeController.searchText,
                                                  widget.store!.id.toString(),
                                                  offset!,
                                                  storeController.type,
                                                );
                                              } else {
                                                storeController
                                                    .getStoreItemList(
                                                  widget.store!.id ??
                                                      storeController.store!.id,
                                                  offset!,
                                                  storeController.type,
                                                  false,
                                                  pageSize: storeController
                                                      .itemsPageSize,
                                                );
                                              }
                                            },
                                            totalSize:
                                                storeController.isSearching
                                                    ? storeController
                                                        .storeSearchItemModel
                                                        ?.totalSize
                                                    : storeController
                                                        .storeItemModel
                                                        ?.totalSize,
                                            offset: storeController.isSearching
                                                ? storeController
                                                    .storeSearchItemModel
                                                    ?.offset
                                                : storeController
                                                    .storeItemModel?.offset,
                                            itemView: WebItemsView(
                                              isStore: false,
                                              stores: null,
                                              fromStore: true,
                                              items: storeController.isSearching
                                                  ? (storeController
                                                          .isLiveSearching
                                                      ? storeController
                                                          .liveSearchResults
                                                      : storeController
                                                          .storeSearchItemModel?.items)
                                                  : (storeLoaded &&
                                                          storeController
                                                                  .categoryList !=
                                                              null &&
                                                          storeController
                                                              .categoryList!
                                                              .isNotEmpty &&
                                                          storeController
                                                                  .storeItemModel !=
                                                              null)
                                                      ? storeController
                                                          .storeItemModel!.items
                                                      : null,
                                              inStorePage: true,
                                            ),
                                          ),
                                        ],
                                      ))
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SliverToBoxAdapter(child: SizedBox()),

                    ///mobile view..
                    ResponsiveHelper.isDesktop(context)
                        ? const SliverToBoxAdapter(child: SizedBox())
                        : SliverToBoxAdapter(
                            child: Center(
                                child: Container(
                            width: Dimensions.webMaxWidth,
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            color: Theme.of(context).cardColor,
                            child: Column(children: [
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox()
                                  : StoreDescriptionViewWidget(
                                      store: displayStore),
                              const SizedBox(
                                  height: Dimensions.paddingSizeSmall),
                              displayStore.announcementActive ?? false
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(
                                            Dimensions.radiusDefault),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.2)),
                                      ),
                                      padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeSmall),
                                      margin: const EdgeInsets.only(
                                          top: Dimensions.paddingSizeSmall),
                                      child: Row(children: [
                                        Image.asset(Images.announcement,
                                            height: 20, width: 20),
                                        const SizedBox(
                                            width: Dimensions.paddingSizeSmall),
                                        Flexible(
                                            child: Text(
                                                displayStore
                                                        .announcementMessage ??
                                                    '',
                                                style: robotoRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall))),
                                      ]),
                                    )
                                  : const SizedBox(),
                              StoreBannerWidget(
                                  storeController: storeController),
                              const SizedBox(
                                  height: Dimensions.paddingSizeLarge),
                              (!ResponsiveHelper.isDesktop(context) &&
                                      storeController.recommendedItemModel
                                              ?.items?.isNotEmpty ==
                                          true)
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('recommended_for_you'.tr,
                                            style: robotoMedium),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraSmall),
                                        SizedBox(
                                          height: ResponsiveHelper.isDesktop(
                                                  context)
                                              ? 150
                                              : 130,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: storeController
                                                    .recommendedItemModel
                                                    ?.items
                                                    ?.length ??
                                                0,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: ResponsiveHelper
                                                        .isDesktop(context)
                                                    ? const EdgeInsets
                                                        .symmetric(vertical: 20)
                                                    : const EdgeInsets
                                                        .symmetric(
                                                        vertical: 10),
                                                child: Container(
                                                  width: ResponsiveHelper
                                                          .isDesktop(context)
                                                      ? 500
                                                      : 300,
                                                  padding: const EdgeInsets
                                                      .only(
                                                      right: Dimensions
                                                          .paddingSizeSmall,
                                                      left: Dimensions
                                                          .paddingSizeExtraSmall),
                                                  margin: const EdgeInsets.only(
                                                      right: Dimensions
                                                          .paddingSizeSmall),
                                                  child: ItemWidget(
                                                    isStore: false,
                                                    item: storeController
                                                        .recommendedItemModel!
                                                        .items![index],
                                                    store: null,
                                                    index: index,
                                                    length: null,
                                                    inStore: true,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox(),
                            ]),
                          ))),

                    ResponsiveHelper.isDesktop(context)
                        ? const SliverToBoxAdapter(child: SizedBox())
                        : (storeController.categoryList?.isNotEmpty == true)
                            ? SliverPersistentHeader(
                                pinned: true,
                                delegate: SliverDelegate(
                                  height: storeController.isSearchFieldVisible
                                      ? 105
                                      : 75,
                                  child: Center(
                                    child: Container(
                                      width: Dimensions.webMaxWidth,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        boxShadow: [
                                          BoxShadow(
                                              color: Theme.of(context)
                                                  .shadowColor
                                                  .withValues(alpha: 0.12),
                                              blurRadius: 5,
                                              spreadRadius: 1)
                                        ],
                                      ),
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left:
                                                    Dimensions.paddingSizeSmall,
                                                right:
                                                    Dimensions.paddingSizeSmall,
                                                top: 2,
                                                bottom: 2),
                                            child: Row(children: [
                                              InkWell(
                                                onTap: () {
                                                  storeController
                                                      .setVerticalItems(
                                                          !storeController
                                                              .isVertical);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                      Dimensions
                                                          .paddingSizeExtraSmall),
                                                  child: Icon(
                                                      storeController.isVertical
                                                          ? Icons.list
                                                          : Icons
                                                              .filter_list_sharp,
                                                      size: 24,
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text('all_products'.tr,
                                                  style: robotoBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeDefault)),

                                              //
                                              const SizedBox(
                                                width: 15,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  storeController.set_Price(
                                                      !storeController
                                                          .isPriceAscending);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault),
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                      Dimensions
                                                          .paddingSizeExtraSmall),
                                                  child: Icon(
                                                      storeController
                                                              .isPriceAscending
                                                          ? Icons
                                                              .trending_down // يوحي بسعر يصعد
                                                          : Icons
                                                              .trending_up, // يوحي بسعر ينخفض
                                                      size: 24,
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ),
                                              ),

                                              //

                                              const Expanded(
                                                child: SizedBox(),
                                              ),
                                              !ResponsiveHelper.isDesktop(
                                                      context)
                                                  ? InkWell(
                                                      onTap: () => Get.toNamed<
                                                              void>(
                                                          RouteHelper
                                                              .getSearchStoreItemRoute(
                                                                  displayStore!
                                                                      .id)),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusDefault),
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1),
                                                        ),
                                                        padding: const EdgeInsets
                                                            .all(Dimensions
                                                                .paddingSizeExtraSmall),
                                                        child: Icon(Icons.tune,
                                                            size: 24,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor),
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                              // Search icon next to filter
                                              !ResponsiveHelper.isDesktop(
                                                      context)
                                                  ? InkWell(
                                                      onTap: () {
                                                        storeController
                                                            .toggleSearchField();
                                                      },
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .radiusDefault),
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1),
                                                        ),
                                                        padding: const EdgeInsets
                                                            .all(Dimensions
                                                                .paddingSizeExtraSmall),
                                                        child: Icon(
                                                            Icons.search,
                                                            size: 24,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor),
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                              storeController.type.isNotEmpty
                                                  ? VegFilterWidget(
                                                      type:
                                                          storeController.type,
                                                      onSelected:
                                                          (String type) {
                                                        storeController
                                                            .getStoreItemList(
                                                                storeController
                                                                    .store!.id,
                                                                1,
                                                                type,
                                                                true);
                                                      },
                                                    )
                                                  : const SizedBox(),
                                            ]),
                                          ),

                                          // Live search field for mobile (shown when search icon is clicked)
                                          GetBuilder<StoreController>(
                                            builder: (storeController) {
                                              return storeController
                                                      .isSearchFieldVisible
                                                  ? Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: Dimensions
                                                              .paddingSizeSmall),
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius
                                                            .circular(Dimensions
                                                                .radiusDefault),
                                                        color: Theme.of(context)
                                                            .cardColor,
                                                        border: Border.all(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.40)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextField(
                                                              controller:
                                                                  _searchController,
                                                              textInputAction:
                                                                  TextInputAction
                                                                      .search,
                                                              style: robotoRegular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          12),
                                                              decoration:
                                                                  InputDecoration(
                                                                contentPadding:
                                                                    const EdgeInsets
                                                                        .symmetric(),
                                                                hintText:
                                                                    'search_for_items'
                                                                        .tr,
                                                                hintStyle: robotoRegular.copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeSmall,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .disabledColor),
                                                                border: OutlineInputBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(Dimensions
                                                                            .radiusSmall),
                                                                    borderSide:
                                                                        BorderSide
                                                                            .none),
                                                                filled: true,
                                                                fillColor: Theme.of(
                                                                        context)
                                                                    .cardColor,
                                                                isDense: true,
                                                                prefixIcon: Icon(
                                                                    Icons
                                                                        .search,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .primaryColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.50)),
                                                              ),
                                                              onChanged: (String
                                                                  value) {
                                                                // Live search as user types
                                                                storeController
                                                                    .performLiveSearch(
                                                                        value);
                                                              },
                                                              onSubmitted:
                                                                  (String?
                                                                      value) {
                                                                if (value!
                                                                    .isNotEmpty) {
                                                                  storeController
                                                                      .performLiveSearch(
                                                                          value);
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          InkWell(
                                                            onTap: () {
                                                              _searchController
                                                                  .text = '';
                                                              storeController
                                                                  .clearLiveSearch();
                                                            },
                                                            child: Container(
                                                              height: 24,
                                                              width: 24,
                                                              decoration: BoxDecoration(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColor,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4)),
                                                              child: const Icon(
                                                                  Icons.clear,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : const SizedBox();
                                            },
                                          ),

                                          SizedBox(
                                            height: 30,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: storeController
                                                      .categoryList?.length ??
                                                  0,
                                              padding: const EdgeInsets.only(
                                                  left: Dimensions
                                                      .paddingSizeSmall),
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemBuilder: (context, index) {
                                                // Load more categories when user scrolls near the end
                                                if (index >=
                                                        (storeController
                                                                    .categoryList
                                                                    ?.length ??
                                                                0) -
                                                            2 &&
                                                    storeController
                                                        .hasMoreCategories &&
                                                    !storeController
                                                        .isLoadingMoreCategories) {
                                                  // Trigger loading more categories in background
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) {
                                                    storeController
                                                        .loadMoreCategories();
                                                  });
                                                }

                                                return InkWell(
                                                  onTap: () => storeController
                                                      .setCategoryIndex(index),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: Dimensions
                                                            .paddingSizeSmall,
                                                        vertical: Dimensions
                                                            .paddingSizeExtraSmall),
                                                    margin: const EdgeInsets
                                                        .only(
                                                        right: Dimensions
                                                            .paddingSizeSmall),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius
                                                          .circular(Dimensions
                                                              .radiusDefault),
                                                      color: index ==
                                                              storeController
                                                                  .categoryIndex
                                                          ? Theme.of(context)
                                                              .primaryColor
                                                              .withValues(
                                                                  alpha: 0.1)
                                                          : Colors.transparent,
                                                    ),
                                                    child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "${storeController.categoryList?[index].name ?? ''} ${index == storeController.categoryIndex && (storeController.categoryList?[index].id ?? -1) != -1 ? storeController.pageSize : ''}",
                                                            style: index ==
                                                                    storeController
                                                                        .categoryIndex
                                                                ? robotoMedium.copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeSmall,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .primaryColor)
                                                                : robotoRegular.copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeSmall),
                                                          ),
                                                        ]),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SliverToBoxAdapter(child: SizedBox()),

                    ResponsiveHelper.isDesktop(context)
                        ? const SliverToBoxAdapter(child: SizedBox())
                        : storeController.subCategoryList != null
                            ? SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        storeController.subCategoryList!.length,
                                    padding: const EdgeInsets.only(
                                        left: Dimensions.paddingSizeSmall),
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: InkWell(
                                          onTap: () => storeController
                                              .setSubCategoryIndex(index),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal:
                                                    Dimensions.paddingSizeSmall,
                                                vertical: Dimensions
                                                    .paddingSizeExtraSmall),
                                            margin: const EdgeInsets.only(
                                                right: Dimensions
                                                    .paddingSizeSmall),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions.radiusDefault),
                                              color: index ==
                                                      storeController
                                                          .subCategoryIndex
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.1)
                                                  : Colors.transparent,
                                            ),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    storeController
                                                        .subCategoryList![index]
                                                        .name!,
                                                    style: index ==
                                                            storeController
                                                                .subCategoryIndex
                                                        ? robotoMedium.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor)
                                                        : robotoRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall),
                                                  ),
                                                ]),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : const SliverToBoxAdapter(child: SizedBox()),

// =======================================================

                    // 🔧 FIX: Store closed banner - show above items
                    // ✅ FRONTEND ONLY: Use store.isOpen from API only (no time calculations)
                    SliverToBoxAdapter(
                      child: GetBuilder<StoreController>(
                        builder: (storeController) {
                          // ✅ FRONTEND ONLY: Get store open status from API only
                          // ❌ NO DateTime calculations, NO schedule checks, NO time logic
                          final bool isStoreOpen = displayStore?.isOpen == true;

                          if (!isStoreOpen) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeSmall,
                                vertical: Dimensions.paddingSizeSmall,
                              ),
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeDefault),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeSmall),
                                  Expanded(
                                    child: Text(
                                      'المتجر مغلق حالياً، يمكنك التصفح فقط',
                                      style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),

                    ResponsiveHelper.isDesktop(context)
                        ? const SliverToBoxAdapter(child: SizedBox())
                        : (storeController
                                        .categoryList?[
                                            storeController.categoryIndex]
                                        .id ??
                                    -1) !=
                                -1
                            ? SliverToBoxAdapter(
                                child: Container(
                                  width: Dimensions.webMaxWidth,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                  child: !(storeController
                                                  .categoryList?.isNotEmpty ==
                                              true &&
                                          storeController.storeItemModel !=
                                              null)
                                      ? const Center(
                                          child: LoadingWidget(),
                                        )
                                      : PaginatedListView(
                                          scrollController: scrollController,
                                          onPaginate: (int? offset) =>
                                              storeController.getStoreItemList(
                                            displayStore?.id ??
                                                widget.store?.id ??
                                                storeController.store?.id ??
                                                0,
                                            offset!,
                                            storeController.type,
                                            false,
                                            pageSize:
                                                storeController.itemsPageSize,
                                          ),
                                          totalSize: storeController
                                              .storeItemModel?.totalSize,
                                          offset: storeController
                                              .storeItemModel?.offset,
                                          itemView: ItemsView(
                                            isStore: false,
                                            stores: null,
                                            items: () {
                                              // ✅ FRONTEND ONLY: Always show items view, even if store is closed
                                              // Items should be displayed for browsing, ordering is disabled separately

                                              if (storeController.isSearching) {
                                                return storeController
                                                        .isLiveSearching
                                                    ? storeController
                                                        .liveSearchResults
                                                    : storeController
                                                        .storeSearchItemModel
                                                        ?.items;
                                              }

                                              // ✅ CRITICAL: Check if items exist (regardless of store.open status)
                                              final hasCategoryList =
                                                  storeController.categoryList
                                                          ?.isNotEmpty ==
                                                      true;
                                              final hasSlimMenu =
                                                  storeController
                                                      .slimMenuLoaded;
                                              final hasVisibleItems =
                                                  storeController
                                                          .visibleItemList !=
                                                      null;
                                              final hasStoreItemModel =
                                                  storeController.storeItemModel
                                                          ?.items !=
                                                      null;

                                              // ✅ DEBUG: Log items availability for troubleshooting

                                              // ✅ FRONTEND ONLY: Show items if available (store.open is ignored for display)
                                              if ((hasCategoryList ||
                                                      hasSlimMenu) &&
                                                  (hasVisibleItems ||
                                                      hasStoreItemModel)) {
                                                // ⚡ TASK 2: Kill "All" category logjam - limit to 50 items for instant speed
                                                final allItems = List<
                                                        Item>.from(storeController
                                                            .visibleItemList ??
                                                        storeController
                                                            .storeItemModel!
                                                            .items!)
                                                    .where((item) =>
                                                        (item.stock ?? 0) > 0)
                                                    .toList();

                                                allItems.sort((a, b) =>
                                                    storeController
                                                            .isPriceAscending
                                                        ? (a.price ?? 0)
                                                            .compareTo(
                                                                b.price ?? 0)
                                                        : (b.price ?? 0)
                                                            .compareTo(
                                                                a.price ?? 0));

                                                // Limit to 50 items if "All" category (index 0) is selected
                                                final itemCount = storeController
                                                            .categoryIndex ==
                                                        0
                                                    ? math.min(
                                                        allItems.length, 50)
                                                    : allItems.length;

                                                return allItems
                                                    .take(itemCount)
                                                    .toList();
                                              } else {
                                                // ✅ DEBUG: Log why items are not available
                                                return null;
                                              }
                                            }(),
                                            inStorePage: true,
                                            verticalItem:
                                                storeController.isVertical,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  Dimensions.paddingSizeSmall,
                                              vertical:
                                                  Dimensions.paddingSizeSmall,
                                            ),
                                          ),
                                        ),
                                ),
                              )
                            : SliverToBoxAdapter(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        ResponsiveHelper.isDesktop(context)
                                            ? 6
                                            : ResponsiveHelper.isMobile(context)
                                                ? 4
                                                : 3,
                                    mainAxisSpacing:
                                        Dimensions.paddingSizeSmall,
                                    crossAxisSpacing:
                                        Dimensions.paddingSizeSmall,
                                  ),
                                  padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeSmall),
                                  itemCount:
                                      storeController.categoryList?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () => storeController
                                          .setCategoryIndex(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.radiusSmall),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Theme.of(context)
                                                    .shadowColor
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 5,
                                                spreadRadius: 1)
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Dimensions.radiusSmall),
                                                child: CustomImage(
                                                  height: 90,
                                                  width: 80,
                                                  image: storeController
                                                          .categoryList?[index]
                                                          .imageFullUrl ??
                                                      '',
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraSmall),
                                              Text(
                                                storeController
                                                        .categoryList?[index]
                                                        .name ??
                                                    '',
                                                textAlign: TextAlign.center,
                                                style: robotoMedium.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ]),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ],
                )
              : const LoadingWidget();
        }),
        floatingActionButton:
            GetBuilder<StoreController>(builder: (storeController) {
          final splashController = Get.find<SplashController>();
          final configModel = splashController.configModel;
          return Visibility(
            visible: storeController.showFavButton &&
                configModel?.moduleConfig?.module?.orderAttachment == true &&
                (storeController.store != null &&
                    (storeController.store?.prescriptionOrder ?? false)) &&
                configModel?.prescriptionStatus == true &&
                AuthHelper.isLoggedIn(),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                boxShadow: [
                  BoxShadow(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(2, 2))
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: storeController.currentState == true
                      ? 0
                      : ResponsiveHelper.isDesktop(context)
                          ? 180
                          : 150,
                  height: 30,
                  child: Center(
                    child: Text(
                      'prescription_order'.tr,
                      textAlign: TextAlign.center,
                      style: robotoMedium.copyWith(
                          color: Theme.of(context).primaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    final storeId = storeController.store?.id;
                    if (storeId != null) {
                      Get.toNamed<void>(
                        RouteHelper.getPrescriptionCheckoutRoute(
                            storeId: storeId),
                        arguments: CheckoutScreen(
                            fromCart: false, cartList: null, storeId: storeId),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Image.asset(Images.prescriptionIcon,
                        height: 25, width: 25),
                  ),
                ),
              ]),
            ),
          );
        }),
        bottomNavigationBar:
            GetBuilder<CartController>(builder: (cartController) {
          return cartController.cartList.isNotEmpty &&
                  !ResponsiveHelper.isDesktop(context)
              ? const BottomCartWidget()
              : const SizedBox();
        }),
      ),
    );
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;

  SliverDelegate({required this.child, this.height = 100});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}

class CategoryProduct {
  CategoryModel category;
  List<Item> products;
  CategoryProduct(this.category, this.products);
}
