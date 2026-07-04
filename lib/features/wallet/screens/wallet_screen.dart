import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet/controllers/wallet_controller.dart';
import 'package:sixam_mart/features/wallet/widgets/bonus_banner_widget.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/wallet/widgets/wallet_card_widget.dart';
import 'package:sixam_mart/features/wallet/widgets/wallet_history_widget.dart';
import 'package:sixam_mart/features/wallet/widgets/web_bonus_banner_widget.dart';
import 'package:sixam_mart/features/wallet/widgets/add_fund_dialogue_widget.dart';
import 'package:sixam_mart/util/styles.dart';
import '../widgets/balance_container_widget.dart';

class WalletScreen extends StatefulWidget {
  final String? fundStatus;
  final String? token;
  const WalletScreen({super.key, this.fundStatus, this.token});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController scrollController = ScrollController();
  final tooltipController = JustTheController();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('💰 [WalletScreen] initState() - OLD WALLET SCREEN');
      debugPrint('   📍 Route: /old_wallet');
      debugPrint('   📊 fundStatus: ${widget.fundStatus}');
      debugPrint('   🔑 token: ${widget.token != null ? "provided" : "null"}');
      debugPrint('   ⏰ Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }
    initCall();
  }

  void initCall() {
    if (kDebugMode) {
      debugPrint('💰 [WalletScreen] initCall() - Starting initialization');
      debugPrint('   🔐 isLoggedIn: ${AuthHelper.isLoggedIn()}');
    }
    
    if (AuthHelper.isLoggedIn()) {
      final walletController = Get.find<WalletController>();
      final profileController = Get.find<ProfileController>();
      
      if (kDebugMode) {
        debugPrint('💰 [WalletScreen] Setting up wallet filters...');
      }
      walletController.insertFilterList();
      walletController.setWalletFilerType('all', isUpdate: false);

      if ((widget.fundStatus == 'success' || widget.fundStatus == 'fail' || widget.fundStatus == 'cancel') &&
          walletController.getWalletAccessToken() != widget.token) {
        if (kDebugMode) {
          debugPrint('💰 [WalletScreen] Payment callback detected');
          debugPrint('   📊 fundStatus: ${widget.fundStatus}');
          debugPrint('   🔑 token match: ${walletController.getWalletAccessToken() == widget.token}');
          debugPrint('   ⏳ Will show snackbar in 2 seconds...');
        }
        Future.delayed(const Duration(seconds: 2), () {
          if (kDebugMode) {
            debugPrint('💰 [WalletScreen] Showing payment status snackbar: ${widget.fundStatus}');
          }
          Get.showSnackbar(GetSnackBar(
            backgroundColor: widget.fundStatus == 'fail' || widget.fundStatus == 'cancel' ? Colors.red : Colors.green,
            message: widget.fundStatus == 'success' ? 'fund_successfully_added_to_wallet'.tr : 'fund_not_added_to_wallet'.tr,
            maxWidth: 500,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge),
            borderRadius: Dimensions.radiusExtraLarge,
            dismissDirection: DismissDirection.horizontal,
          ));
        }).then((value) {
          walletController.setWalletAccessToken(widget.token ?? '');
          if (kDebugMode) {
            debugPrint('💰 [WalletScreen] Wallet access token saved');
          }
        });
      }
      
      if (kDebugMode) {
        debugPrint('💰 [WalletScreen] Loading user profile...');
      }
      profileController.getUserInfo();

      if (kDebugMode) {
        debugPrint('💰 [WalletScreen] Loading wallet bonus list...');
      }
      walletController.getWalletBonusList(isUpdate: false);

      if (kDebugMode) {
        debugPrint('💰 [WalletScreen] Loading wallet transactions (offset=1, type=${walletController.type})...');
      }
      walletController.getWalletTransactionList('1', false, walletController.type);

      walletController.setOffset(1);
      if (kDebugMode) {
        debugPrint('💰 [WalletScreen] Initialization complete');
        debugPrint('   📊 Filter type: ${walletController.type}');
        debugPrint('   📄 Offset: 1');
      }

      scrollController.addListener(() {
        final walletController = Get.find<WalletController>();
        if (scrollController.position.pixels == scrollController.position.maxScrollExtent &&
            walletController.transactionList != null &&
            !walletController.isLoading) {
          final int pageSize = (walletController.popularPageSize! / 10).ceil();
          if (walletController.offset < pageSize) {
            final newOffset = walletController.offset + 1;
            if (kDebugMode) {
              debugPrint('💰 [WalletScreen] Scrolled to bottom - loading page $newOffset');
              debugPrint('   📊 Current transactions: ${walletController.transactionList?.length ?? 0}');
              debugPrint('   📄 Total pages: $pageSize');
            }
            walletController.setOffset(newOffset);
            walletController.showBottomLoader();
            walletController.getWalletTransactionList(newOffset.toString(), false, walletController.type);
          } else {
            if (kDebugMode) {
              debugPrint('💰 [WalletScreen] Reached last page - no more transactions to load');
            }
          }
        }
      });
    } else {
      if (kDebugMode) {
        debugPrint('💰 [WalletScreen] User not logged in - skipping initialization');
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('💰 [WalletScreen] dispose() - Cleaning up');
      debugPrint('   ⏰ Screen duration: ${DateTime.now().toIso8601String()}');
    }
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    
    if (kDebugMode) {
      debugPrint('💰 [WalletScreen] build() - Rebuilding UI');
      debugPrint('   🔐 isLoggedIn: $isLoggedIn');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'my_wallet'.tr,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3633),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF2D3633), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: (isLoggedIn && !ResponsiveHelper.isDesktop(context))
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
                        const Dialog(
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          child: SizedBox(
                            width: 500,
                            child: SingleChildScrollView(
                                child: AddFundDialogueWidget()),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'wallet_add_fund'.tr,
                      style: robotoBold.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeLarge),
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
                          debugPrint('💰 [WalletScreen] Pull to refresh triggered');
                        }
                        final walletController = Get.find<WalletController>();
                        final profileController = Get.find<ProfileController>();
                        walletController.setWalletFilerType('all');
                        walletController.getWalletTransactionList('1', true, 'all');
                        profileController.getUserInfo();
                        if (kDebugMode) {
                          debugPrint('💰 [WalletScreen] Refresh complete');
                        }
                      },
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            WebScreenTitleWidget(title: 'wallet'.tr),

                            //

                            FooterView(
                              child: SizedBox(
                                width: Dimensions.webMaxWidth,
                                child: GetBuilder<WalletController>(builder: (walletController) {
                                  return ResponsiveHelper.isDesktop(context)
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Expanded(
                                                flex: 4,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                        decoration: ResponsiveHelper.isDesktop(context)
                                                            ? BoxDecoration(
                                                                color: Theme.of(context).cardColor,
                                                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                                boxShadow: const [
                                                                  BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
                                                                ],
                                                              )
                                                            : null,
                                                        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                                        child: WalletCardWidget(tooltipController: tooltipController)),
                                                  ],
                                                )),
                                            const SizedBox(width: Dimensions.paddingSizeDefault),
                                            Expanded(
                                                flex: 6,
                                                child: Column(children: [
                                                  const WebBonusBannerWidget(),
                                                  Container(
                                                    decoration: ResponsiveHelper.isDesktop(context)
                                                        ? BoxDecoration(
                                                            color: Theme.of(context).cardColor,
                                                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                            boxShadow: const [
                                                              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
                                                            ],
                                                          )
                                                        : null,
                                                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                                    child: const WalletHistoryWidget(),
                                                  ),
                                                ])),
                                          ]),
                                        )
                                      : const Column(
                                          children: [
                                            // Padding(
                                            //   padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                                            //   child: WalletCardWidget(tooltipController: tooltipController),
                                            // ),

                                            BalanceContainerWidget(),

                                            //

                                            BonusBannerWidget(),

                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                                              child: WalletHistoryWidget(),
                                            )
                                          ],
                                        );
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
                          final walletController = Get.find<WalletController>();
                          walletController.getWalletTransactionList(
                              '1', true, walletController.type);
                        },
                      )
                    : const Center(child: CircularProgressIndicator())
            : NotLoggedInScreen(callBack: (value) {
                initCall();
              });
      }),
    );
  }
}
