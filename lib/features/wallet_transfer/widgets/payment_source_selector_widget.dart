import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'dart:ui';

/// Widget for selecting payment source (Regular Wallet or Qidha Wallet)
/// Shows balance and availability for each option
class PaymentSourceSelectorWidget extends StatefulWidget {
  final String selectedSource;
  final Function(String) onSourceChanged;

  const PaymentSourceSelectorWidget({
    super.key,
    required this.selectedSource,
    required this.onSourceChanged,
  });

  @override
  State<PaymentSourceSelectorWidget> createState() => _PaymentSourceSelectorWidgetState();
}

class _PaymentSourceSelectorWidgetState extends State<PaymentSourceSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment_source'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: const Color(0xFF31A342),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        
        // Regular Wallet Option
        GetBuilder<ProfileController>(
          builder: (profileController) {
            final double balance = profileController.userInfoModel?.walletBalance ?? 0;
            
            return _buildPaymentOption(
              context,
              title: 'regular_wallet'.tr,
              subtitle: PriceConverter.convertPrice(balance),
              value: 'wallet',
              isSelected: widget.selectedSource == 'wallet',
              isEnabled: true,
              icon: Icons.account_balance_wallet,
            );
          },
        ),
        
        const SizedBox(height: Dimensions.paddingSizeSmall),
        
        // Qidha Wallet Option
        GetBuilder<KaidhaSubscriptionController>(
          builder: (kaidhaController) {
            final bool hasQidhaWallet = kaidhaController.walletKaidhaModel?.wallet != null &&
                kaidhaController.walletKaidhaModel!.wallet!.signatureStatus == 1 &&
                kaidhaController.walletKaidhaModel!.wallet!.status == 'Active';
            
            double availableBalance = 0;
            double creditLimit = 0;
            
if (hasQidhaWallet) {
  final wallet = kaidhaController.walletKaidhaModel?.wallet;

  availableBalance = wallet?.availableBalance is num
      ? (wallet!.availableBalance as num).toDouble()
      : double.tryParse(wallet?.availableBalance?.toString() ?? '0') ?? 0;

  creditLimit = wallet?.creditLimit is num
      ? (wallet!.creditLimit as num).toDouble()
      : double.tryParse(wallet?.creditLimit?.toString() ?? '0') ?? 0;
}

            final String subtitle = hasQidhaWallet
                ? '${'available_balance'.tr}: ${PriceConverter.convertPrice(availableBalance)} | ${'balance'.tr}: ${PriceConverter.convertPrice(creditLimit)}'
                : 'qidha_wallet_not_active'.tr;

            return _buildPaymentOption(
              context,
              title: 'qidha_wallet'.tr,
              subtitle: subtitle,
              value: 'wallet_qidha',
              isSelected: widget.selectedSource == 'wallet_qidha',
              isEnabled: hasQidhaWallet,
              icon: Icons.credit_card,
            );
          },
        ),
      ],
    );
  }

  /// Builds individual payment option with premium styling
  Widget _buildPaymentOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
    required bool isEnabled,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: isEnabled ? () {
        widget.onSourceChanged(value);
        HapticFeedback.selectionClick();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected && isEnabled
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                gradient: isSelected && isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withValues(alpha: 0.15),
                          Colors.teal.withValues(alpha: 0.15),
                        ],
                      )
                    : null,
                color: isEnabled
                    ? (isSelected ? null : Colors.white)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected && isEnabled
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isEnabled && isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF31A342), Color(0xFFFA9D2B)],
                            )
                          : null,
                      color: isEnabled && !isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isEnabled && isSelected
                          ? Colors.white
                          : (isEnabled ? Theme.of(context).primaryColor : Colors.grey),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeLarge),
                  
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: isEnabled
                                ? Theme.of(context).textTheme.bodyLarge!.color
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: isSelected && isEnabled
                                ? const Color(0xFF31A342)
                                : Theme.of(context).disabledColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Animated checkmark instead of radio
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: isSelected && isEnabled
                          ? const LinearGradient(
                              colors: [Color(0xFF31A342), Color(0xFFFA9D2B)],
                            )
                          : null,
                      border: Border.all(
                        color: isEnabled
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: isSelected && isEnabled
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

