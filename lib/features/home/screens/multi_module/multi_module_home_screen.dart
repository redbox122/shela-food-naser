import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/home/widgets/custom_appBar_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
// import 'package:sixam_mart/features/home/widgets/shop_home_skeleton.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';

// Widgets
import 'package:sixam_mart/features/home/widgets/modules_view_widget.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/offers/widgets/offers_view.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

const double _sectionRadius = 16;

class MultiModuleHomeScreen extends StatefulWidget {
  final bool showBottomNavigation;

  const MultiModuleHomeScreen({
    super.key,
    this.showBottomNavigation = true,
  });

  // ✅ INTENTIONAL: Module 3 (eCommerce) is used for promotional content on multi-module screen
  // This is by design from backend - Module 3 banners/offers serve as featured content
  static const int kPromotionalModuleId = 3;

  @override
  State<MultiModuleHomeScreen> createState() => _MultiModuleHomeScreenState();
}

class _MultiModuleHomeScreenState extends State<MultiModuleHomeScreen> {
  bool _isPromotionalRetryScheduled = false;
  bool _hasTriggeredPromotionalRecovery = false;
  @override
  void initState() {
    super.initState();
    appLogger.logPageEntry('MultiModuleHomeScreen');
    if (kDebugMode) {
      print(
          '🏗️ [Module-First] MultiModuleHomeScreen: Initialized as dumb screen (UI only)');
    }
    appLogger.info(
        '🏗️ [Module-First] MultiModuleHomeScreen: Initialized - UI only, no business logic');
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      if (!Get.isRegistered<BannerController>() ||
          !Get.isRegistered<SplashController>()) {
        return;
      }
      final BannerController bannerController = Get.find<BannerController>();
      final bool hasBanners =
          (bannerController.featuredBannerList?.isNotEmpty ?? false) ||
              (bannerController.bannerImageList?.isNotEmpty ?? false);
      final bool hasPromotionalBanner = bannerController
              .promotionalBanner?.bottomSectionBannerFullUrl?.isNotEmpty ??
          false;
      if ((!hasBanners || !hasPromotionalBanner) &&
          !bannerController.isLoading &&
          !_hasTriggeredPromotionalRecovery) {
        _hasTriggeredPromotionalRecovery = true;
        final SplashController splashController = Get.find<SplashController>();
        splashController.loadAndCachePromotionalContent();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget mobileHeader = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: GetBuilder<SplashController>(
            id: 'moduleList',
            builder: (splashController) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    child: build_Search(context, false, false),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: build_Address(context, splashController),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context)
          ? const PreferredSize(
              preferredSize: Size.fromHeight(132.0),
              child: WebMenuBar(),
            )
          : null,
      backgroundColor: const Color(0xFFF5F5F5),
      body: GetBuilder<SplashController>(
        builder: (splashController) {
          final modules = splashController.moduleList;
          if (modules == null || modules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // 🔧 CRITICAL FIX: Wrap content with Obx to reactively listen to selectedModule changes
          // This ensures UI rebuilds when module is selected (even if already cached)
          return Obx(() {
            // Access selectedModule to trigger reactive rebuild when it changes
            final _ = splashController.selectedModule.value;
            // 🏗️ MODULE-FIRST ARCHITECTURE: MultiModuleHomeScreen displays promotional content from Module 3
            // Banners and promotional banners are loaded from Module 3 (eCommerce) as featured content
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!ResponsiveHelper.isDesktop(context)) mobileHeader,
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  // 1. Featured Banners (from Module 3) - البنر في الأعلى
                  // 🔧 FIX: Use GetBuilder without id to listen to ALL banner updates
                  // This ensures UI updates immediately when banners are loaded, even on first build
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: GetBuilder<SplashController>(
                      id: 'promotional_content',
                      builder: (splashController) {
                        return GetBuilder<BannerController>(
                          builder: (bannerController) {
                            final hasFeaturedBanners =
                                bannerController.featuredBannerList != null &&
                                    bannerController
                                        .featuredBannerList!.isNotEmpty;
                            final hasRegularBanners =
                                bannerController.bannerImageList != null &&
                                    bannerController
                                        .bannerImageList!.isNotEmpty;
                            final hasData =
                                hasFeaturedBanners || hasRegularBanners;
                            final hasPromotionalBanner = bannerController
                                    .promotionalBanner
                                    ?.bottomSectionBannerFullUrl
                                    ?.isNotEmpty ??
                                false;
                            // Retry in-build only when top banner data is missing.
                            // Do not loop forever when promotional banner endpoint has no URL.
                            if (!hasData &&
                                !bannerController.isLoading &&
                                !_isPromotionalRetryScheduled &&
                                !_hasTriggeredPromotionalRecovery) {
                              _isPromotionalRetryScheduled = true;
                              _hasTriggeredPromotionalRecovery = true;
                              Future.microtask(() async {
                                if (!mounted) {
                                  return;
                                }
                                if (Get.isRegistered<SplashController>()) {
                                  await Get.find<SplashController>()
                                      .loadAndCachePromotionalContent();
                                }
                                if (mounted) {
                                  _isPromotionalRetryScheduled = false;
                                }
                              });
                            }
                            if (!splashController.isPromotionalContentReady &&
                                !hasData &&
                                !hasPromotionalBanner) {
                              return const SizedBox.shrink();
                            }
                            if (!hasData && hasPromotionalBanner) {
                              return const PromotionalBannerView();
                            }
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: ClipRRect(
                                key: const ValueKey('banner'),
                                borderRadius:
                                    BorderRadius.circular(_sectionRadius),
                                child: const BannerView(
                                  isFeatured: false,
                                  forceShow: true,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // 2. Module Grid - اختيار Module
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: GetBuilder<SplashController>(
                      id: 'moduleList',
                      builder: (splashController) {
                        final moduleList = splashController.moduleList;
                        if (moduleList == null || moduleList.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return const _SectionCard(
                          child: ModulesViewWidget(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  // 4. Offers Section (from Module 3) - قسم العروض من Module 3
                  // 🔧 FIX: Always show offers section (with placeholder if empty)
                  // This ensures users know the offers section exists even when no offers are available
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: GetBuilder<Offers_Controller>(
                      builder: (offersController) {
                        return const _SectionCard(
                          child: OffersView(),
                        );
                      },
                    ),
                  ),
                  // 5. Bottom promotional banner (independent from featured banner availability)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: GetBuilder<BannerController>(
                      builder: (bannerController) {
                        final hasPromotionalBanner = bannerController
                                .promotionalBanner
                                ?.bottomSectionBannerFullUrl
                                ?.isNotEmpty ??
                            false;
                        if (!hasPromotionalBanner) {
                          return const SizedBox.shrink();
                        }
                        return const _SectionCard(
                          child: PromotionalBannerView(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                ],
              ),
            );
          });
        },
      ),
      floatingActionButton:
          (!widget.showBottomNavigation || ResponsiveHelper.isDesktop(context))
              ? null
              : FloatingActionButton(
                  heroTag: 'multi_module_cart_fab',
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: const CircleBorder(),
                  onPressed: () {
                    Get.toNamed<dynamic>(RouteHelper.getCartRoute());
                  },
                  child: const CartWidget(color: Colors.white, size: 22),
                ),
      floatingActionButtonLocation: widget.showBottomNavigation
          ? FloatingActionButtonLocation.centerDocked
          : null,
      bottomNavigationBar: (!widget.showBottomNavigation ||
              ResponsiveHelper.isDesktop(context))
          ? null
          : GetBuilder<SplashController>(
              builder: (splashController) {
                final currentModule = splashController.module;
                final bool isParcel = currentModule != null &&
                    currentModule.moduleType.toString() == AppConstants.parcel;
                final iconList = <IconData>[
                  Icons.home_outlined,
                  isParcel ? Icons.location_on_outlined : Icons.favorite_border,
                  Icons.list_alt,
                  Icons.more_horiz,
                ];
                const int navBarIndex = 0;
                return GetBuilder<FavouriteController>(
                    builder: (favController) {
                  final int favCount =
                      (favController.wishItemList?.length ?? 0) +
                          (favController.wishStoreList?.length ?? 0);
                  final String favBadgeText =
                      favCount > 99 ? '99+' : favCount.toString();
                  final bool showFavBadge = !isParcel && favCount > 0;
                  return AnimatedBottomNavigationBar.builder(
                    itemCount: iconList.length,
                    tabBuilder: (index, isActive) {
                      final Color iconColor = isActive
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400;
                      final bool isFavTab = !isParcel && index == 1;
                      return SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: Icon(iconList[index],
                                  size: 28, color: iconColor),
                            ),
                            if (isFavTab && showFavBadge)
                              Positioned.fill(
                                child: Center(
                                  child: Text(
                                    favBadgeText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    activeIndex: navBarIndex,
                    gapLocation: GapLocation.center,
                    notchSmoothness: NotchSmoothness.softEdge,
                    leftCornerRadius: 0,
                    rightCornerRadius: 0,
                    backgroundColor: Colors.white,
                    shadow: BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 12,
                      spreadRadius: 0.5,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    onTap: (index) {
                      if (index == 0) {
                        return;
                      }
                      final int pageIndex = index < 2 ? index : index + 1;
                      Get.offAll<dynamic>(
                        () => DashboardScreen(
                          pageIndex: pageIndex,
                          fromSplash: false,
                        ),
                      );
                    },
                  );
                });
              },
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(_sectionRadius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: child,
    );
  }
}
