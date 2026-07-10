import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/loyalty/controllers/loyalty_controller.dart';
import 'package:sixam_mart/features/loyalty/widgets/loyalty_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/loyalty/widgets/loyalty_card_widget.dart';
import 'package:sixam_mart/features/loyalty/widgets/loyalty_history_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';

class LoyaltyScreen extends StatefulWidget {
  final bool fromNotification;
  const LoyaltyScreen({super.key, required this.fromNotification});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final ScrollController scrollController = ScrollController();
  final tooltipController = JustTheController();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🎁 [LoyaltyScreen] initState() - LOYALTY POINTS SCREEN');
      debugPrint('   📍 Route: /loyalty');
      debugPrint('   📊 fromNotification: ${widget.fromNotification}');
      debugPrint('   ⏰ Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }
    initCall();
  }

  void initCall() {
    if (kDebugMode) {
      debugPrint('🎁 [LoyaltyScreen] initCall() - Starting initialization');
      debugPrint('   🔐 isLoggedIn: ${AuthHelper.isLoggedIn()}');
    }

    if (AuthHelper.isLoggedIn()) {
      final profileController = Get.find<ProfileController>();
      final loyaltyController = Get.find<LoyaltyController>();

      if (kDebugMode) {
        debugPrint('🎁 [LoyaltyScreen] Loading user profile...');
      }
      profileController.getUserInfo();

      if (kDebugMode) {
        debugPrint(
            '🎁 [LoyaltyScreen] Loading loyalty transactions (offset=1)...');
      }
      loyaltyController.getLoyaltyTransactionList('1', false);

      loyaltyController.setOffset(1);
      if (kDebugMode) {
        debugPrint('🎁 [LoyaltyScreen] Initialization complete');
        debugPrint('   📄 Offset: 1');
      }

      scrollController.addListener(() {
        final loyaltyController = Get.find<LoyaltyController>();
        if (scrollController.position.pixels ==
                scrollController.position.maxScrollExtent &&
            loyaltyController.transactionList != null &&
            !loyaltyController.isLoading) {
          final int pageSize = (loyaltyController.popularPageSize! / 10).ceil();
          if (loyaltyController.offset < pageSize) {
            final newOffset = loyaltyController.offset + 1;
            if (kDebugMode) {
              debugPrint(
                  '🎁 [LoyaltyScreen] Scrolled to bottom - loading page $newOffset');
              debugPrint(
                  '   📊 Current transactions: ${loyaltyController.transactionList?.length ?? 0}');
              debugPrint('   📄 Total pages: $pageSize');
            }
            loyaltyController.setOffset(newOffset);
            loyaltyController.showBottomLoader();
            loyaltyController.getLoyaltyTransactionList(
                newOffset.toString(), false);
          } else {
            if (kDebugMode) {
              debugPrint(
                  '🎁 [LoyaltyScreen] Reached last page - no more transactions to load');
            }
          }
        }
      });
    } else {
      if (kDebugMode) {
        debugPrint(
            '🎁 [LoyaltyScreen] User not logged in - skipping initialization');
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('🎁 [LoyaltyScreen] dispose() - Cleaning up');
      debugPrint('   ⏰ Screen duration: ${DateTime.now().toIso8601String()}');
    }
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();

    if (kDebugMode) {
      debugPrint('🎁 [LoyaltyScreen] build() - Rebuilding UI');
      debugPrint('   🔐 isLoggedIn: $isLoggedIn');
    }

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (widget.fromNotification) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            'loyalty_points'.tr,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xff000000),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2D3633),
                size: 20),
            onPressed: () {
              if (widget.fromNotification) {
                Get.offAllNamed(RouteHelper.getInitialRoute());
              } else {
                Get.back();
              }
            },
          ),
        ),
        bottomNavigationBar:
            (isLoggedIn && !ResponsiveHelper.isDesktop(context))
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Get.dialog(
                              Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: LoyaltyBottomSheetWidget(
                                    amount: Get.find<ProfileController>()
                                                .userInfoModel!
                                                .loyaltyPoint ==
                                            null
                                        ? '0'
                                        : Get.find<ProfileController>()
                                            .userInfoModel!
                                            .loyaltyPoint
                                            .toString(),
                                  )),
                            );
                          },
                          child: Text(
                            'convert_to_wallet_money'.tr,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
        body: GetBuilder<ProfileController>(builder: (profileController) {
          return isLoggedIn
              ? profileController.userInfoModel != null
                  ? SafeArea(
                      top: false,
                      bottom: true,
                      left: false,
                      right: false,
                      minimum: EdgeInsets.zero,
                      child: RefreshIndicator(
                        onRefresh: () async {
                          if (kDebugMode) {
                            debugPrint(
                                '🎁 [LoyaltyScreen] Pull to refresh triggered');
                          }
                          final loyaltyController =
                              Get.find<LoyaltyController>();
                          final profileController =
                              Get.find<ProfileController>();
                          loyaltyController.getLoyaltyTransactionList(
                              '1', true);
                          profileController.getUserInfo();
                          if (kDebugMode) {
                            debugPrint('🎁 [LoyaltyScreen] Refresh complete');
                          }
                        },
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            children: [
                              WebScreenTitleWidget(title: 'loyalty_points'.tr),
                              FooterView(
                                child: SizedBox(
                                  width: Dimensions.webMaxWidth,
                                  child: GetBuilder<LoyaltyController>(
                                      builder: (loyaltyController) {
                                    return ResponsiveHelper.isDesktop(context)
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                top: Dimensions
                                                    .paddingSizeDefault),
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      flex: 4,
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            decoration: ResponsiveHelper
                                                                    .isDesktop(
                                                                        context)
                                                                ? BoxDecoration(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .cardColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            Dimensions.radiusSmall),
                                                                    boxShadow: const [
                                                                      BoxShadow(
                                                                          color: Colors
                                                                              .black12,
                                                                          blurRadius:
                                                                              5,
                                                                          spreadRadius:
                                                                              1)
                                                                    ],
                                                                  )
                                                                : null,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(
                                                                    Dimensions
                                                                        .paddingSizeLarge),
                                                            child: LoyaltyCardWidget(
                                                                tooltipController:
                                                                    tooltipController),
                                                          ),
                                                        ],
                                                      )),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeDefault),
                                                  Expanded(
                                                      flex: 6,
                                                      child: Column(children: [
                                                        Container(
                                                          decoration:
                                                              ResponsiveHelper
                                                                      .isDesktop(
                                                                          context)
                                                                  ? BoxDecoration(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .cardColor,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              Dimensions.radiusSmall),
                                                                      boxShadow: const [
                                                                        BoxShadow(
                                                                            color: Colors
                                                                                .black12,
                                                                            blurRadius:
                                                                                5,
                                                                            spreadRadius:
                                                                                1)
                                                                      ],
                                                                    )
                                                                  : null,
                                                          padding: const EdgeInsets
                                                              .all(Dimensions
                                                                  .paddingSizeLarge),
                                                          child:
                                                              const LoyaltyHistoryWidget(),
                                                        ),
                                                      ])),
                                                ]),
                                          )
                                        : Column(children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: Dimensions
                                                      .paddingSizeDefault,
                                                  left: Dimensions
                                                      .paddingSizeDefault,
                                                  right: Dimensions
                                                      .paddingSizeDefault),
                                              child: LoyaltyCardWidget(
                                                  tooltipController:
                                                      tooltipController),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: Dimensions
                                                      .paddingSizeLarge),
                                              child: LoyaltyHistoryWidget(),
                                            )
                                          ]);
                                  }),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : profileController.hasProfileError
                      ? ErrorStateView(
                          onRetry: () {
                            profileController.getUserInfo();
                            Get.find<LoyaltyController>()
                                .getLoyaltyTransactionList('1', true);
                          },
                        )
                      : const Center(child: CircularProgressIndicator())
              : NotLoggedInScreen(callBack: (value) {
                  initCall();
                  setState(() {});
                });
        }),
      ),
    );
  }
}
