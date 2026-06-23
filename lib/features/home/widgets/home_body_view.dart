import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/akhdamni_flow_controller.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/home/screens/web_new_home_screen.dart';
import 'package:sixam_mart/features/home/widgets/akhdamni/akhdamni_flow_section.dart';
import 'package:sixam_mart/features/home/widgets/flattened_module_content.dart';
import 'package:sixam_mart/features/home/widgets/home_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/home_current_offers_section.dart';
import 'package:sixam_mart/features/home/widgets/home_discover_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/home_reorder_section.dart';
import 'package:sixam_mart/features/home/widgets/home_services_grid.dart';
import 'package:sixam_mart/features/home/widgets/home_top_notice_strip.dart';
import 'package:sixam_mart/features/rental_module/home/screens/taxi_home_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';

/// 🧹 REFACTOR / 🎨 REDESIGN: The scrollable home body extracted from
/// `HomeScreen.build`. Hosts the redesign sections (notice / banner / services /
/// offers / reorder) and the (taxi-only) module content, plus pull-to-refresh.
class HomeBodyView extends StatelessWidget {
  final ScrollController scrollController;
  final bool isTaxi;
  final bool showMobileModule;
  final SplashController splashController;

  const HomeBodyView({
    super.key,
    required this.scrollController,
    required this.isTaxi,
    required this.showMobileModule,
    required this.splashController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            ? WebNewHomeScreen(scrollController: scrollController)
            : CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 🎨 REDESIGN: Context-aware notice (join / set address)
                  const SliverToBoxAdapter(child: HomeTopNoticeStrip()),

                  // 🎨 REDESIGN: Promotional banner (≈ 322×152)
                  const SliverToBoxAdapter(child: HomeBannerView()),

                  // 🎨 REDESIGN: "خدماتنا" services bento grid
                  const SliverToBoxAdapter(child: HomeServicesGrid()),

                  // 🎨 REDESIGN: "العروض الحالية" offers rail
                  const SliverToBoxAdapter(child: HomeCurrentOffersSection()),

                  // 🎨 REDESIGN: "اكتشف خدمات أكثر" promo banner (343×96)
                  const SliverToBoxAdapter(child: HomeDiscoverBannerView()),

                  // 🎨 REDESIGN: "أعد طلبك" recent orders
                  const SliverToBoxAdapter(child: HomeReorderSection()),

                  // Module-specific content (taxi only; the legacy multi-module
                  // list and other modules' legacy content are intentionally
                  // hidden in the redesign — navigation lives in
                  // HomeServicesGrid).
                  SliverToBoxAdapter(
                    child: FlattenedModuleContent(
                      moduleWidget: GetBuilder<AkhdamniFlowController>(
                        builder: (akhdamniController) {
                          if (akhdamniController.isFlowActive) {
                            return const AkhdamniFlowSection();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              isTaxi
                                  ? TaxiHomeScreen()
                                  : const SizedBox.shrink(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
