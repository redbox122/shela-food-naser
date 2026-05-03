// ignore_for_file: prefer_const_literals_to_create_immutables, non_constant_identifier_names, deprecated_member_use, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifecycle_controller/lifecycle_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/LifecycleKaidhaController.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/screen/show_pdf_screen.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/screen/subscription_steps/step1_screen.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/screen/subscription_steps/step2_screen.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/screen/subscription_steps/step3_screen.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/stages_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import '../../../common/widgets/appBar.dart';
import '../../../util/app_colors.dart';

class KiadaWalletSubscriptionScreen extends StatefulWidget {
  const KiadaWalletSubscriptionScreen({super.key});

  @override
  State<KiadaWalletSubscriptionScreen> createState() =>
      _KiadaWalletSubscriptionScreenState();
}

class _KiadaWalletSubscriptionScreenState
    extends State<KiadaWalletSubscriptionScreen> {
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('[QidhaSub][OPEN] screen opened');
    getDate();
  }

  Future<void> getDate() async {
    final KaidhaSubController = Get.find<KaidhaSubscriptionController>();
    final profileController = Get.find<ProfileController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure profile data is loaded
      if (profileController.userInfoModel == null) {
        await profileController.getUserInfo();
      }
      final userInfo = profileController.userInfoModel;
      final profilePhone = userInfo?.phone?.toString().trim();
      final authPhone = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>().getUserNumber().trim()
          : '';
      final phone = (profilePhone != null && profilePhone.isNotEmpty)
          ? profilePhone
          : authPhone;

      // Do NOT show validation errors on screen open.
      // Phone validation only runs when user presses a submit/next button.
      if (userInfo == null || userInfo.id == null || phone.isEmpty) {
        debugPrint('[QidhaSub][OPEN] user/phone not ready yet: '
            'userInfo=${userInfo != null} userId=${userInfo?.id} phoneEmpty=${phone.isEmpty}. '
            'Skipping wallet fetch - form will validate on Next press.');
        return;
      }

      if (KaidhaSubController.hasNoWallet) {
        debugPrint(
            'ℹ️ No wallet already detected - skipping wallet fetch in subscription screen');
        return;
      }

      // Force refresh wallet data to get latest status
      await KaidhaSubController.get_Wallet_Kaidh(forceRefresh: true);

      // Check if wallet exists and has a valid status
      final wallet = KaidhaSubController.walletKaidhaModel?.wallet;
      if (wallet != null) {
        debugPrint('✅ Wallet found with status: ${wallet.status}');
        KaidhaSubController.clearState_kaidha_SharedPre();

        // Only load PDF when wallet is pending/approved and signed
        final status = wallet.status?.toString().toLowerCase();
        final signatureStatus = wallet.signatureStatus;
        final isSigned = signatureStatus == 1 || signatureStatus == true;
        final isPendingOrApproved = status == 'pending' || status == 'approved';
        if (isSigned && isPendingOrApproved) {
          await KaidhaSubController.get_Pdf();
        }
      } else {
        debugPrint('ℹ️ No wallet found, starting new application');
        try {
          await KaidhaSubController.SendState_kaidha(
              'started'); //  ارسال الحاله
        } catch (e) {
          debugPrint('SendState_kaidha failed: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LifecycleScope.create(
      create: () => LifecycleKaidhaController(),
      builder: (context) {
        return GetBuilder<KaidhaSubscriptionController>(
          builder: (KaidhaSubController) {
            // ✅ تمرير لأعلى فقط عند الوصول إلى المرحلة 2
            if (KaidhaSubController.currentStage == 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
              });
            }

            return Scaffold(
              backgroundColor: AppColors.wtColor,
              appBar: custom_AppBar(
                context,
                title: 'KiadaWallet_Subscription'.tr,
                icon: Icons.arrow_back_sharp,
                img_icon: Images.KiadaWalletSubscription,
                onPressed: () {
                  if (KaidhaSubController.currentStage == 1) {
                    Get.back();
                  } else {
                    KaidhaSubController.nextStage(context, isNext: false);
                  }
                },
              ),
              body: KaidhaSubController.isLoading_Show_Pdf
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: (KaidhaSubController.walletKaidhaModel?.wallet !=
                                  null &&
                              (KaidhaSubController
                                          .walletKaidhaModel!.wallet!.status ==
                                      'Pending' ||
                                  KaidhaSubController
                                          .walletKaidhaModel!.wallet!.status ==
                                      'pending' ||
                                  KaidhaSubController
                                          .walletKaidhaModel!.wallet!.status ==
                                      'Approved' ||
                                  KaidhaSubController
                                          .walletKaidhaModel!.wallet!.status ==
                                      'approved') &&
                              // Only show pending screen when Step 3 is completed (signature_status = 1)
                              (KaidhaSubController.walletKaidhaModel!.wallet!
                                          .signatureStatus ==
                                      1 ||
                                  KaidhaSubController.walletKaidhaModel!.wallet!
                                          .signatureStatus ==
                                      true))
                          ? const ShowPdfScreen()
                          : Column(
                              children: [
                                const StagesWidget(),
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Column(
                                      children: [
                                        KaidhaSubController.currentStage == 1
                                            ? const Step_1_Screen()
                                            : KaidhaSubController
                                                        .currentStage ==
                                                    2
                                                ? const Step2Screen()
                                                : KaidhaSubController
                                                            .currentStage ==
                                                        3
                                                    ? SizedBox(
                                                        height: height_media(
                                                                context) /
                                                            1.5,
                                                        child:
                                                            const Step3Screen(),
                                                      )
                                                    : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
            );
          },
        );
      },
    );
  }
}
