// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, empty_catches, unnecessary_null_comparison

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/text_button_w.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/available_balance.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import '../../../common/widgets/custom_image.dart';
import '../../../util/app_colors.dart';
import '../widget/payment_details.dart';

// خط Tajawal لشاشة محفظة قيدها
TextStyle _tajawal(double size, FontWeight weight,
    {Color color = const Color(0xFF2D3633)}) {
  return TextStyle(
    fontFamily: 'Tajawal',
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

class WalletKaidhaScreen extends StatefulWidget {
  const WalletKaidhaScreen({super.key});

  @override
  State<WalletKaidhaScreen> createState() => _WalletKaidhaScreenState();
}

class _WalletKaidhaScreenState extends State<WalletKaidhaScreen> {
  final FocusNode _customAmountFocusNode = FocusNode();
  late final VoidCallback _customAmountFocusListener;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('💳 [WalletKaidhaScreen] initState() - QIDHA WALLET SCREEN');
      debugPrint('   📍 Route: /kaidha-allet');
      debugPrint('   ⏰ Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }
    getDate();

    // Listen to focus changes on custom amount field
    _customAmountFocusListener = () {
      final controller = Get.find<KaidhaSubscriptionController>();

      if (_customAmountFocusNode.hasFocus) {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] Custom amount field focused - switching to custom payment option');
        }
        // Select custom payment option when field gains focus
        controller.selectPaymentOption(2);
      } else {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] Custom amount field blurred - validating minimum amount');
        }
        // Validate minimum amount when field loses focus (onBlur)
        controller.validateMinimumAmount();
      }
    };
    _customAmountFocusNode.addListener(_customAmountFocusListener);
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('💳 [WalletKaidhaScreen] dispose() - Cleaning up');
      debugPrint('   ⏰ Screen duration: ${DateTime.now().toIso8601String()}');
    }
    _customAmountFocusNode.removeListener(_customAmountFocusListener);
    _customAmountFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _ensureProfileReady() async {
    final profileController = Get.find<ProfileController>();
    if (profileController.userInfoModel == null) {
      await profileController.getUserInfo();
    }
    return true;
  }

  void getDate() async {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('💳 [WalletKaidhaScreen] getDate() - QIDHA WALLET SCREEN');
      debugPrint('   📍 Route: /kaidha-allet');
      debugPrint('   ⏰ Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Get.find<KaidhaSubscriptionController>();

      // ⚡ TASK 3: SWR Pattern - Show UI instantly with partial data from Profile
      _safeSetState(() {});

      // Reset to default state: Full Amount (option 0) selected by default
      controller.selectedPaymentOption = 0;
      controller.another_amount.text = '0.00';

      if (kDebugMode) {
        debugPrint(
            '💳 [WalletKaidhaScreen] UI shown instantly with existing data');
        debugPrint(
            '   💰 Wallet status: ${controller.walletKaidhaModel?.wallet?.status}');
        debugPrint(
            '   💵 availableBalance: ${controller.walletKaidhaModel?.wallet?.availableBalance}');
      }

      // ⚡ TASK 3: Background fetch full details from lean 500-byte endpoint (non-blocking)
      if (!await _ensureProfileReady()) {
        return;
      }
      controller.get_Wallet_Kaidh(forceRefresh: true).then((_) {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] Background wallet fetch completed');
          debugPrint(
              '   💰 Wallet status: ${controller.walletKaidhaModel?.wallet?.status}');
          debugPrint(
              '   💵 usedBalance: ${controller.walletKaidhaModel?.wallet?.usedBalance}');
          debugPrint(
              '   💵 minimumDueLimit: ${controller.walletKaidhaModel?.wallet?.minimumDueLimit}');
          debugPrint(
              '   💵 availableBalance: ${controller.walletKaidhaModel?.wallet?.availableBalance}');
        }

        if (controller.hasNoWallet &&
            Get.currentRoute != RouteHelper.KiadaWalletSubscription) {
          if (kDebugMode) {
            debugPrint(
                '💳 [WalletKaidhaScreen] No wallet - redirecting to subscription');
          }
          showCustomSnackBar('لا توجد محفظة. الرجاء الاشتراك أولاً.');
          Get.offNamed(RouteHelper.getKiadaWalletSubscription());
          return;
        }

        // ⚡ TASK 4: Payment validation retry - load payment methods after data arrives
        _loadPaymentMethodsWithRetry(controller);

        _safeSetState(() {});
      }).catchError((e) {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] ⚠️ Background wallet fetch failed: $e');
        }
        // Silent fail - user already sees partial data
      });
    });
  }

  /// ⚡ TASK 4: Payment validation retry - loads payment methods with retry logic
  /// If usedBalance is missing/invalid, forces wallet fetch and retries
  Future<void> _loadPaymentMethodsWithRetry(
      KaidhaSubscriptionController controller) async {
    if (controller.hasNoWallet) {
      if (kDebugMode) {
        debugPrint(
            '💳 [WalletKaidhaScreen] No wallet detected - skipping payment methods load');
      }
      return;
    }

    final usedBalanceValue = controller.walletKaidhaModel?.wallet?.usedBalance;

    // Validate usedBalance is a valid number
    final double? maximumDueAmount = usedBalanceValue != null &&
            usedBalanceValue.toString().trim().isNotEmpty
        ? (usedBalanceValue is num
            ? usedBalanceValue.toDouble()
            : double.tryParse(usedBalanceValue.toString()))
        : null;

    if (maximumDueAmount != null && maximumDueAmount >= 0) {
      // Valid usedBalance - proceed with payment methods
      if (maximumDueAmount > 0) {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] Loading payment methods with MAXIMUM due amount');
          debugPrint('   💵 Maximum due amount: $maximumDueAmount SAR');
          debugPrint(
              '   ⚡ Note: Payment methods support up to maximum due - user can pay less if needed');
        }
        await controller.loadQidhaPaymentMethods(maximumDueAmount);
      } else {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] ⚠️ Maximum due amount is 0 - skipping payment methods load');
        }
      }
    } else {
      // ⚡ TASK 2: Invalid usedBalance - use nuclear fetch to bypass all cache
      if (kDebugMode) {
        debugPrint(
            '💳 [WalletKaidhaScreen] ⚠️ Invalid usedBalance - triggering nuclear remote fetch');
        debugPrint(
            '   📊 walletKaidhaModel: ${controller.walletKaidhaModel != null ? "EXISTS" : "NULL"}');
        debugPrint(
            '   📊 wallet: ${controller.walletKaidhaModel?.wallet != null ? "EXISTS" : "NULL"}');
        debugPrint('   💵 usedBalance value: $usedBalanceValue');
      }

      // ⚡ TASK 2: Use nuclear fetch to bypass all ETags and cache
      await controller.nuclearRemoteFetch();

      // Retry payment methods load after fetch
      final retryUsedBalance =
          controller.walletKaidhaModel?.wallet?.usedBalance;
      final retryAmount = retryUsedBalance != null &&
              retryUsedBalance.toString().trim().isNotEmpty
          ? (retryUsedBalance is num
              ? retryUsedBalance.toDouble()
              : double.tryParse(retryUsedBalance.toString()) ?? 0.0)
          : 0.0;

      if (retryAmount > 0) {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] Retry: Loading payment methods after wallet fetch');
          debugPrint('   💵 Retry amount: $retryAmount SAR');
        }
        await controller.loadQidhaPaymentMethods(retryAmount);
      } else {
        if (kDebugMode) {
          debugPrint(
              '💳 [WalletKaidhaScreen] ⚠️ Retry failed - usedBalance still invalid after fetch');
        }
      }
    }
  }

  String _getStatusMessage(String? status) {
    switch (status) {
      case 'pending':
      case 'in_review':
      case 'review':
        return 'طلبك قيد المراجعة';
      case 'inactive':
      case 'disabled':
        return 'الحالة غير نشطة';
      case 'rejected':
        return 'تم رفض الطلب';
      default:
        return 'حالة غير معروفة';
    }
  }

  /// Normalize MyFatoorah image URL - ensure it has https:// prefix
  String _normalizeImageUrl(String url) {
    if (url.isEmpty) return '';

    // If URL already has protocol, return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If URL starts with domain (e.g., sa.myfatoorah.com), add https://
    if (url.contains('myfatoorah.com') || url.contains('myfatoorah')) {
      return 'https://$url';
    }

    // Otherwise return as-is (might be a relative path or already correct)
    return url;
  }

  String _getStatusDescription(String? status) {
    switch (status) {
      case 'pending':
      case 'in_review':
      case 'review':
        return 'يرجى الانتظار حتى يتم مراجعة طلبك من قبل فريقنا المختص';
      case 'inactive':
      case 'disabled':
        return 'محفظة قيدها غير نشطة حالياً. يرجى التواصل مع الدعم الفني';
      case 'rejected':
        return 'تم رفض طلبك. يرجى مراجعة البيانات المقدمة أو التواصل مع الدعم الفني';
      default:
        return 'يرجى التواصل مع الدعم الفني لمزيد من المعلومات';
    }
  }

  /// Build payment method selector UI
  /// Displays available payment methods (VISA, mada, STC Pay, etc.)
  Widget _buildPaymentMethodSelector(KaidhaSubscriptionController controller) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();

    if (controller.isLoadingPaymentMethods) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('جاري تحميل طرق الدفع...'),
          ],
        ),
      );
    }

    if (controller.qidhaPaymentMethods.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens?.surfaceSoft ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens?.outlineSoft ?? theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment,
                size: 40, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(height: 8),
            Text('لا توجد طرق دفع متاحة',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.qidhaPaymentMethods.length,
        itemBuilder: (context, index) {
          final paymentMethod = controller.qidhaPaymentMethods[index];
          final isSelected = controller.qidhaPaymentMethodsSelected[index];

          // Debug: Log image URL for troubleshooting
          if (kDebugMode && index == 0) {
            debugPrint(
                '💳 [WalletKaidhaScreen] Payment method image URL: ${paymentMethod.imageUrl}');
            debugPrint(
                '   - Normalized: ${_normalizeImageUrl(paymentMethod.imageUrl ?? '')}');
          }

          return GestureDetector(
            onTap: () {
              controller.selectQidhaPaymentMethod(index);
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(left: 8, right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEBFEEB)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (tokens?.outlineSoft ??
                          theme.colorScheme.outlineVariant),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ⚡ TASK 1: Use CustomImage for proper caching and error handling
                  // Normalize URL to ensure it has https:// prefix (MyFatoorah URLs may be relative)
                  CustomImage(
                    image: _normalizeImageUrl(paymentMethod.imageUrl ?? ''),
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    placeholder: Images.placeholder,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paymentMethod.paymentMethodAr ?? '',
                    style: _tajawal(
                      12,
                      isSelected ? FontWeight.w700 : FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// هيدر شاشة محفظة قيدها: خلفية بيضاء، العنوان في المنتصف وسهم على اليمين.
  PreferredSizeWidget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
            size: 20, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'kiadha_wallet'.tr,
        style:
            _tajawal(18, FontWeight.w700, color: theme.colorScheme.onSurface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHeader(context),
      body: GetBuilder<KaidhaSubscriptionController>(
          builder: (KaidhaSubController) {
        final wallet = KaidhaSubController.walletKaidhaModel?.wallet;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: KaidhaSubController.isLoading_wallet == true
                ? SizedBox(
                    height: height_media(context) * .7,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : KaidhaSubController.hasNoWallet
                    ? SizedBox(
                        height: height_media(context) * .7,
                        child: _NoWalletState(
                          onSubscribe: () => Get.toNamed(
                              RouteHelper.getKiadaWalletSubscription()),
                        ),
                      )
                    : wallet == null
                        ? const Center(
                            child: PaymentDetailsShimmer(),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //
                              PaymentDetails(wallet: wallet),

                              //

                              const SizedBox(height: 20),

                              //

                              // Show status message if wallet is not active
                              wallet.status?.toString().toLowerCase() !=
                                      'active'
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: tokens?.warningSoft ??
                                                theme.colorScheme.errorContainer
                                                    .withValues(alpha: 0.28),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: (tokens?.warningText ??
                                                        theme.colorScheme.error)
                                                    .withValues(alpha: 0.35)),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: tokens?.warningText ??
                                                    theme.colorScheme.error,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                _getStatusMessage(wallet.status
                                                    ?.toString()
                                                    .toLowerCase()),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: tokens?.warningText ??
                                                      theme.colorScheme.error,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _getStatusDescription(wallet
                                                    .status
                                                    ?.toString()
                                                    .toLowerCase()),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: (tokens?.warningText ??
                                                          theme.colorScheme
                                                              .error)
                                                      .withValues(alpha: 0.92),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        PaymentOptions(wallet: wallet),

                                        //

                                        const SizedBox(height: 20),

                                        // Custom Amount Section - النص خارج بدون كونتنر والحقل كما هو
                                        Text(
                                          'أدخل مبلغ آخر',
                                          style: _tajawal(
                                            16,
                                            FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        CustomTextField(
                                          labelText: '',
                                          controller: KaidhaSubController
                                              .another_amount,
                                          focusNode: _customAmountFocusNode,
                                          suffixChild: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                Images.sar,
                                                width: 20,
                                                height: 20,
                                                cacheWidth: 56,
                                                cacheHeight: 56,
                                              ),
                                            ],
                                          ),
                                          onChanged: (String value) {
                                            // Call controller method which handles validation and selection
                                            KaidhaSubController
                                                .onChange_another_amount(value);
                                          },
                                        ),

                                        // Payment Method Selection
                                        const SizedBox(height: 20),
                                        Text('اختر طريقة الدفع',
                                            style:
                                                _tajawal(14, FontWeight.w700)),
                                        const SizedBox(height: 10),
                                        _buildPaymentMethodSelector(
                                            KaidhaSubController),

                                        const SizedBox(height: 20),

                                        // payment button

                                        GetBuilder<CheckoutController>(
                                            builder: (checkoutController) {
                                          return TextButtonWidget(
                                            text: 'ادفع الآن',
                                            backgroundColor:
                                                AppColors.primaryColor,
                                            textStyle: _tajawal(
                                                16, FontWeight.w700,
                                                color: Colors.white),
                                            height: 60,
                                            width: double.infinity,
                                            radius: 16,
                                            verticalPadd: 0,
                                            horizontalPadd: 0,
                                            onPressed: () async {
                                              // Get the selected payment amount based on option
                                              final double paymentAmount =
                                                  KaidhaSubController
                                                      .getSelectedPaymentAmount();

                                              // Check if there's a valid payment amount
                                              if (paymentAmount <= 0) {
                                                // If custom option is selected but empty
                                                if (KaidhaSubController
                                                        .selectedPaymentOption ==
                                                    2) {
                                                  showCustomSnackBar(
                                                      'يرجى إدخال المبلغ المراد دفعه');
                                                  return;
                                                }
                                                // If full or minimum due is 0
                                                showCustomSnackBar(
                                                    'لا يوجد مبلغ مستحق للدفع');
                                                return;
                                              }

                                              // Validate custom amount is within allowed range
                                              if (KaidhaSubController
                                                      .selectedPaymentOption ==
                                                  2) {
                                                final double fullDueAmount =
                                                    double.tryParse(KaidhaSubController
                                                                .walletKaidhaModel
                                                                ?.wallet
                                                                ?.usedBalance
                                                                ?.toString() ??
                                                            '0') ??
                                                        0.0;

                                                final double minimumDue = double
                                                        .tryParse(KaidhaSubController
                                                                .walletKaidhaModel
                                                                ?.wallet
                                                                ?.minimumDueLimit
                                                                ?.toString() ??
                                                            '0') ??
                                                    0.0;

                                                // Check maximum
                                                if (paymentAmount >
                                                    fullDueAmount) {
                                                  showCustomSnackBar(
                                                      'المبلغ المدخل يتجاوز المبلغ المستحق الكامل');
                                                  return;
                                                }

                                                // Check minimum
                                                if (minimumDue > 0 &&
                                                    paymentAmount <
                                                        minimumDue) {
                                                  showCustomSnackBar(
                                                      'المبلغ المدخل أقل من الحد الأدنى المسموح: ${minimumDue.toStringAsFixed(2)} ريال');
                                                  return;
                                                }
                                              }

                                              await KaidhaSubController
                                                  .Send_Pay_Credit(
                                                context,
                                                paymentAmount,
                                              );
                                            },
                                          );
                                        })
                                      ],
                                    ),
                            ],
                          ),
          ),
        );
      }),
    );
  }
}

class _NoWalletState extends StatelessWidget {
  final VoidCallback onSubscribe;
  const _NoWalletState({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Images.noDataFound,
            width: MediaQuery.of(context).size.height * 0.18,
            height: MediaQuery.of(context).size.height * 0.18,
          ),
          const SizedBox(height: 16),
          Text(
            'no_data_found'.tr,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'kiadha_wallet'.tr,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: onSubscribe,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                color: Theme.of(context).primaryColor,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 22,
              ),
              child: Text(
                'KiadaWallet_Subscription'.tr,
                style: robotoMedium.copyWith(
                  color: Theme.of(context).cardColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

 

// ||
//                     KaidhaSubController.walletKaidhaModel!.wallet == null ||
//                     KaidhaSubController.walletKaidhaModel == null


// void showCustomSnackBar(String message, {bool isError = true, int? showDuration}) {

//   Get.dialog(
//     Center(
//       child: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Container(
//           height: 250,
//           // width: 400,
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(isError ? Icons.error : Icons.check_circle, color: isError ? Colors.red : Colors.green, size: 50),
//               const SizedBox(height: 20),
//               Text(message, style: TextStyle(color: Colors.black, fontSize: 16), textAlign: TextAlign.center),
//             ],
//           ),
//         ),
//       ),
//     ),
//     barrierDismissible: false,
//   );

//   Future.delayed(Duration(seconds: showDuration ?? 1), () {
//     if (Get.isDialogOpen ?? false) {
//       Get.back();
//     }
//   });
// }
