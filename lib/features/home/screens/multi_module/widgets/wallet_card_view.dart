import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class WalletCardView extends StatelessWidget {
  const WalletCardView({super.key});

  static DateTime? _lastWalletTapAt;

  void _openKaidhaWallet() {
    final now = DateTime.now();
    if (_lastWalletTapAt != null &&
        now.difference(_lastWalletTapAt!).inMilliseconds < 500) {
      return;
    }
    _lastWalletTapAt = now;

    final route = RouteHelper.getKaidhaWallet();
    if (Get.currentRoute == route) {
      return;
    }
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthHelper.isLoggedIn()) {
      return const SizedBox.shrink();
    }

    return GetBuilder<KaidhaSubscriptionController>(
      builder: (kaidhaController) {
        final wallet = kaidhaController.walletKaidhaModel?.wallet;
        final isLoading = kaidhaController.isLoading_wallet;
        final hasError = kaidhaController.hasWalletError;
        final hasNoWallet = kaidhaController.hasNoWallet;

        if (isLoading) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }

        // 🔧 FIX: Show error/refresh state instead of BNPL placeholder on 401/500 errors
        if (hasError) {
          return Container(
            margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildErrorCard(context, kaidhaController),
          );
        }

        return Container(
          margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: wallet != null
              ? _buildBalanceCard(context, wallet)
              : hasNoWallet
                  ? _buildRegisterWalletCard(context, kaidhaController)
                  : _buildPromotionCard(context),
        );
      },
    );
  }

  Widget _buildBalanceCard(BuildContext context, dynamic wallet) {
    final availableBalance = double.tryParse(wallet.availableBalance?.toString() ?? '0') ?? 0.0;
    final creditLimit = double.tryParse(wallet.creditLimit?.toString() ?? '0') ?? 0.0;
    final usedPercentage = double.tryParse(wallet.usedPercentage?.toString() ?? '0') ?? 0.0;

    return InkWell(
      onTap: _openKaidhaWallet, // Go directly to wallet page
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ... (Content from original file)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الرصيد المتاح', style: robotoRegular.copyWith(color: Colors.white70)),
                Row(
                  children: [
                    PriceConverter.convertPrice2(availableBalance, textStyle: robotoBold.copyWith(fontSize: 24, color: Colors.white)),
                    const Spacer(),
                    Text('من ${PriceConverter.convertPrice(creditLimit)}', style: robotoRegular.copyWith(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: usedPercentage / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.getKiadaWalletSubscription()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Buy Now, Pay Later', style: robotoBold.copyWith(color: Colors.white, fontSize: 16)),
                  Text('With Qidha wallet', style: robotoRegular.copyWith(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('Activate'.tr, style: robotoBold.copyWith(color: AppColors.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 FIX: Build error card with refresh option instead of showing BNPL placeholder
  Widget _buildErrorCard(BuildContext context, KaidhaSubscriptionController controller) {
    return InkWell(
      onTap: () {
        // Tap to refresh wallet data
        controller.get_Wallet_Kaidh(forceRefresh: true);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tap to refresh', style: robotoBold.copyWith(color: Colors.white, fontSize: 16)),
                  Text('Wallet data unavailable', style: robotoRegular.copyWith(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('Refresh'.tr, style: robotoBold.copyWith(color: AppColors.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 FIX: Build register wallet card when hasNoWallet is true
  /// Shows "Register Wallet" button or "Reload" icon instead of confusing 0 balance
  Widget _buildRegisterWalletCard(BuildContext context, KaidhaSubscriptionController controller) {
    return InkWell(
      onTap: () {
        // Navigate to wallet registration/subscription page
        Get.toNamed(RouteHelper.getKiadaWalletSubscription());
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Register Wallet', style: robotoBold.copyWith(color: Colors.white, fontSize: 16)),
                  Text('Create your Qidha wallet', style: robotoRegular.copyWith(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('Register'.tr, style: robotoBold.copyWith(color: AppColors.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }
}
