// ignore_for_file: unnecessary_null_comparison, deprecated_member_use, non_constant_identifier_names

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfatoorah_flutter/MFModels.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// طريقة الدفع — redesigned inline selector (matches the Shella design):
///  • a "استخدام الرصيد" toggle for the regular wallet (partial payment),
///  • a horizontal row of payment tiles: the MyFatoorah card methods
///    (Mada / Credit / Debit …) followed by the Qidha wallet,
///  • green selected state.
///
/// All the underlying selection logic (Qidha eligibility, wallet/partial flows)
/// is the SAME as before — only the presentation changed, so the place-order
/// button keeps reading `paymentMethodIndex` / `select_payment_Methods`.
class PaymentSection extends StatefulWidget {
  final Widget? partialPayView;
  final Widget? Kaidha_Wallat_PayView;

  final int? storeId;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final double total;
  final bool isOfflinePaymentActive;

  const PaymentSection({
    super.key,
    required this.partialPayView,
    required this.Kaidha_Wallat_PayView,
    this.storeId,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.total,
    required this.isOfflinePaymentActive,
  });

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  static const Color _green = Color(0xFF30913F);
  static const Color _border = Color(0xFFE6E8EC);

  CheckoutController checkoutController = Get.find<CheckoutController>();

  // The MyFatoorah card methods load lazily once the total is known; track it
  // so the inline tiles show a spinner instead of a blank ("معلق") card.
  bool _loadTriggered = false;
  bool _loadingMethods = false;

  /// Loads the digital payment methods inline the first time the section is
  /// shown with a real total (the old design only loaded them inside a sheet).
  void _maybeLoadMethods(CheckoutController cc) {
    if (_loadTriggered ||
        !widget.isDigitalPaymentActive ||
        widget.total <= 0 ||
        cc.paymentMethods.isNotEmpty) {
      return;
    }
    _loadTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _loadingMethods = true);
      try {
        await cc.initiatePaymentWithAmount(context, widget.total.toString());
      } catch (_) {}
      if (mounted) setState(() => _loadingMethods = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      id: 'payment',
      builder: (checkoutController) {
        _maybeLoadMethods(checkoutController);
        return GetBuilder<KaidhaSubscriptionController>(
          builder: (kaidhaController) {
            return GetBuilder<ProfileController>(
              builder: (profileController) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    !ResponsiveHelper.isDesktop(context)
                        ? const Divider(height: 18)
                        : const SizedBox(height: Dimensions.paddingSizeSmall),

                    // استخدام الرصيد (regular wallet / partial payment).
                    if (widget.isWalletActive)
                      _walletToggle(context, profileController),

                    const SizedBox(height: 14),

                    // Horizontal payment tiles: card methods + Qidha wallet.
                    _methodsScroller(
                        context, checkoutController, kaidhaController,
                        profileController),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context) {
    return Row(
      children: [
        Text(
          widget.storeId != null
              ? 'payment_method'.tr
              : 'choose_payment_method'.tr,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
        ),
        const Spacer(),
        // Decorative affordance matching the design (methods are inline).
        Icon(Icons.add, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: 4),
        Text(
          'add_payment_method'.tr,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  // ── استخدام الرصيد toggle ────────────────────────────────────────────────────
  Widget _walletToggle(
      BuildContext context, ProfileController profileController) {
    final double balance = profileController.userInfoModel?.walletBalance ?? 0.0;
    final bool on = checkoutController.selectedButton == 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: on ? _green.withValues(alpha: 0.06) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: on ? _green : _border),
      ),
      child: Row(
        children: [
          Switch(
            value: on,
            activeColor: _green,
            onChanged: (v) => _onRegularWalletToggle(v, profileController),
          ),
          const SizedBox(width: 6),
          Text(
            _money(balance),
            style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor),
          ),
          const Spacer(),
          Text('use_balance'.tr,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(width: 8),
          const Icon(Icons.account_balance_wallet_outlined,
              size: 20, color: _green),
        ],
      ),
    );
  }

  // ── Tiles row ───────────────────────────────────────────────────────────────
  Widget _methodsScroller(
    BuildContext context,
    CheckoutController checkoutController,
    KaidhaSubscriptionController kaidhaController,
    ProfileController profileController,
  ) {
    final List<MFPaymentMethod> cards = widget.isDigitalPaymentActive
        ? _filterByPlatform(checkoutController.paymentMethods)
        : const [];

    final List<Widget> tiles = [];

    // Card methods (Mada / Credit / Debit …).
    for (final method in cards) {
      final int originalIndex =
          checkoutController.paymentMethods.indexOf(method);
      final bool selected = checkoutController.paymentMethodIndex == 2 &&
          originalIndex >= 0 &&
          originalIndex < checkoutController.isSelected.length &&
          checkoutController.isSelected[originalIndex];
      tiles.add(_cardTile(context, method, originalIndex, selected));
    }

    // Qidha wallet tile.
    final bool qidhaSelected = checkoutController.paymentMethodIndex == 0;
    tiles.add(_qidhaTile(
        context, kaidhaController, profileController, qidhaSelected));

    // Spinner only WHILE the methods are loading — never a perpetual blank.
    if (widget.isDigitalPaymentActive && cards.isEmpty && _loadingMethods) {
      tiles.insert(0, _loadingTile(context));
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => tiles[i],
      ),
    );
  }

  Widget _tileShell({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _green.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? _green : _border, width: selected ? 1.6 : 1),
        ),
        child: child,
      ),
    );
  }

  Widget _cardTile(BuildContext context, MFPaymentMethod method,
      int originalIndex, bool selected) {
    return _tileShell(
      selected: selected,
      onTap: () => _onCardTap(originalIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                height: 26,
                width: 38,
                child: SmartImage(
                  url: method.imageUrl ?? '',
                  height: 26,
                  width: 38,
                  fit: BoxFit.contain,
                  cacheWidth: 200,
                  cacheHeight: 160,
                  errorWidget:
                      const Icon(Icons.credit_card, size: 22, color: _green),
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle, size: 18, color: _green),
            ],
          ),
          Text(
            (method.paymentMethodEn ?? 'card').trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
          Text(
            _money(widget.total),
            style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: _green),
          ),
        ],
      ),
    );
  }

  Widget _qidhaTile(
    BuildContext context,
    KaidhaSubscriptionController kaidhaController,
    ProfileController profileController,
    bool selected,
  ) {
    final double balance = _qidhaBalance(kaidhaController, profileController);
    return _tileShell(
      selected: selected,
      onTap: () => _onQidhaTap(profileController, kaidhaController),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, size: 22, color: _green),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle, size: 18, color: _green),
            ],
          ),
          Text(
            'kiadha_wallet'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
          Text(
            _money(balance),
            style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: _green),
          ),
        ],
      ),
    );
  }

  Widget _loadingTile(BuildContext context) {
    return Container(
      width: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: _green),
      ),
    );
  }

  // ── Selection handlers (state mutations preserved from the old design) ───────

  void _onCardTap(int originalIndex) {
    if (originalIndex < 0) return;
    // selectPaymentMethod sets paymentMethodIndex=2 + select_payment_Methods.
    checkoutController.selectPaymentMethod(originalIndex);
    // Turn off the wallet/Qidha business flags, mirroring the old digital tap.
    if (checkoutController.isKaidhaPay == true) {
      checkoutController.change_Kaidha_Pay();
    }
    if (checkoutController.isMy_Pay == true) {
      checkoutController.change_My_Pay();
    }
    if (checkoutController.isPartialPay == true) {
      checkoutController.changePartialPayment();
    }
    setState(() {});
  }

  void _onRegularWalletToggle(bool on, ProfileController profileController) {
    if (!on) {
      // Deselect the wallet so the user picks another method.
      setState(() {
        checkoutController.selectedButton = -1;
      });
      checkoutController.setPaymentMethod(-1);
      return;
    }

    // Same guard as the old "my_wallet" tap.
    if (profileController.userInfoModel == null ||
        profileController.userInfoModel!.walletBalance == null ||
        profileController.userInfoModel!.walletBalance == 0.0) {
      showCustomSnackBar('المحفظه فارغة من الرصيد');
      return;
    }

    setState(() {
      checkoutController.selectedButton = 2;
      checkoutController.select_payment_Methods = null;
    });

    if (checkoutController.isKaidhaPay == true) {
      checkoutController.change_Kaidha_Pay();
    }

    if (widget.partialPayView != null) {
      if (kDebugMode) {
        debugPrint('[PaymentMethod][BOTTOM_OPEN] partialWallet sheet');
      }
      Get.bottomSheet(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(Dimensions.radiusLarge),
              bottom: Radius.circular(
                  ResponsiveHelper.isDesktop(context) ? Dimensions.radiusLarge : 0),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeLarge,
            vertical: Dimensions.paddingSizeLarge,
          ),
          child: widget.partialPayView,
        ),
      ).then((_) => setState(() {}));
    }
  }

  void _onQidhaTap(ProfileController profileController,
      KaidhaSubscriptionController kaidhaController) {
    debugPrint('[QIDHA_CHECKOUT][SELECTED]');
    final userInfo = profileController.userInfoModel;
    final bool hasWallet = userInfo?.hasQidhaWallet == true;
    final bool isSigned = userInfo?.qidhaWalletSigned == true;
    final bool isActive = userInfo?.qidhaWalletActive == true;
    final double profileBalance = userInfo?.qidhaWalletBalance ?? 0.0;
    final double walletBalance = double.tryParse(
            '${kaidhaController.walletKaidhaModel?.wallet?.availableBalance ?? profileBalance}') ??
        profileBalance;

    if (!hasWallet) {
      _showQidhaSubscriptionRequiredDialog();
      return;
    }
    if (!isSigned) {
      _showQidhaSignatureRequiredDialog();
      return;
    }
    if (!isActive) {
      showCustomSnackBar('محفظة قيدها قيد التفعيل، يرجى المحاولة لاحقًا');
      return;
    }
    if (walletBalance < widget.total) {
      showCustomSnackBar('رصيد قيدها غير كافٍ');
      return;
    }
    if (kaidhaController.walletKaidhaModel == null ||
        kaidhaController.walletKaidhaModel!.wallet == null) {
      showCustomSnackBar('محفظة قيدها غير متاحة - يرجى المحاولة لاحقًا');
      return;
    }

    setState(() {
      checkoutController.selectedButton = 0;
      checkoutController.select_payment_Methods = null;
    });

    checkoutController.setPaymentMethod(0);

    if (checkoutController.isKaidhaPay == false) {
      checkoutController.change_Kaidha_Pay();
    }
    if (checkoutController.isPartialPay == true) {
      checkoutController.changePartialPayment();
    }
    if (checkoutController.isMy_Pay == true) {
      checkoutController.change_My_Pay();
    }

    if (widget.Kaidha_Wallat_PayView != null) {
      Get.bottomSheet(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(Dimensions.radiusLarge),
              bottom: Radius.circular(
                  ResponsiveHelper.isDesktop(context) ? Dimensions.radiusLarge : 0),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeLarge,
            vertical: Dimensions.paddingSizeLarge,
          ),
          child: widget.Kaidha_Wallat_PayView,
        ),
      ).then((_) => setState(() {}));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _money(double v) => '${v.toStringAsFixed(2)} ﷼';

  double _qidhaBalance(KaidhaSubscriptionController kaidhaController,
      ProfileController profileController) {
    final raw = kaidhaController.walletKaidhaModel?.wallet?.availableBalance;
    if (raw != null) {
      return double.tryParse(raw.toString()) ?? 0.0;
    }
    return profileController.userInfoModel?.qidhaWalletBalance ?? 0.0;
  }

  /// iOS hides Google Pay; Android keeps everything (incl. Apple Pay).
  List<MFPaymentMethod> _filterByPlatform(List<MFPaymentMethod> methods) {
    return methods.where((method) {
      final code = method.paymentMethodCode?.toLowerCase() ?? '';
      final en = method.paymentMethodEn?.toLowerCase() ?? '';
      if (Platform.isIOS) {
        return !code.contains('gp') && !en.contains('google');
      }
      return true;
    }).toList();
  }

  Future<void> _showQidhaSubscriptionRequiredDialog() async {
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('الاشتراك في قيدها مطلوب'),
        content: const Text(
          'لاستخدام محفظة قيدها، يجب الاشتراك وتفعيل المحفظة أولًا.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed(RouteHelper.getKiadaWalletSubscription());
            },
            child: const Text('اشترك الآن'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQidhaSignatureRequiredDialog() async {
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('توقيع قيدها مطلوب'),
        content: const Text('يرجى إكمال توقيع اتفاقية قيدها أولًا'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed(RouteHelper.getKiadaWalletSubscription());
            },
            child: const Text('اشترك الآن'),
          ),
        ],
      ),
    );
  }
}
