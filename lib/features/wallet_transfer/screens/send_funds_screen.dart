import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/controllers/wallet_transfer_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/transfer_request_model.dart';
import 'package:sixam_mart/features/wallet_transfer/widgets/send_fund_bottom_sheet.dart';
import 'package:sixam_mart/features/wallet/controllers/wallet_controller.dart';
import 'package:sixam_mart/features/wallet/widgets/add_fund_dialogue_widget.dart';
import 'package:sixam_mart/common/widgets/history_item_widget.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Main screen for wallet transfer operations
/// Features 4 action buttons: Add Fund, Send, Cards, More
class SendFundsScreen extends StatefulWidget {
  const SendFundsScreen({super.key});

  @override
  State<SendFundsScreen> createState() => _SendFundsScreenState();
}

class _SendFundsScreenState extends State<SendFundsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<WalletTransferController>().getSavedRecipients();
      // Load wallet transactions
      Get.find<WalletController>().getWalletTransactionList('1', true, 'all');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'send_funds'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: Theme.of(context).primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<WalletTransferController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet balance cards
                _buildWalletCards(),

                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                // Action buttons
                _buildActionButtons(),

                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                // Transaction history
                _buildTransactionHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds wallet balance cards
  Widget _buildWalletCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'your_wallets'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Row(
          children: [
            // Regular Wallet
            Expanded(
              child: GetBuilder<ProfileController>(
                builder: (profileController) {
                  final double balance =
                      profileController.userInfoModel?.walletBalance ?? 0;

                  return _buildWalletCard(
                    title: 'regular_wallet'.tr,
                    balance: balance,
                    icon: Icons.account_balance_wallet,
                    color: Theme.of(context).primaryColor,
                  );
                },
              ),
            ),

            const SizedBox(width: Dimensions.paddingSizeDefault),

            // Qidha Wallet
            Expanded(
              child: GetBuilder<KaidhaSubscriptionController>(
                builder: (kaidhaController) {
                  final bool hasQidhaWallet =
                      kaidhaController.walletKaidhaModel?.wallet != null &&
                          kaidhaController
                                  .walletKaidhaModel!.wallet!.signatureStatus ==
                              1 &&
                          kaidhaController.walletKaidhaModel!.wallet!.status ==
                              'Active';

                  double availableBalance = 0;

if (hasQidhaWallet) {
  final rawBalance =
      kaidhaController.walletKaidhaModel?.wallet?.availableBalance;

  availableBalance = rawBalance is num
      ? rawBalance.toDouble()
      : double.tryParse(rawBalance?.toString() ?? '0') ?? 0;
}


                  return _buildWalletCard(
                    title: 'qidha_wallet'.tr,
                    balance: availableBalance,
                    icon: Icons.credit_card,
                    color: const Color(0xFFFA9D2B),
                    isInactive: !hasQidhaWallet,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds wallet card
  Widget _buildWalletCard({
    required String title,
    required double balance,
    required IconData icon,
    required Color color,
    bool isInactive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: isInactive ? Colors.grey.shade300 : color,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            title,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isInactive ? 'غير نشط' : PriceConverter.convertPrice(balance),
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds action buttons in horizontal row layout
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                iconPath: Images.addFundIcon,
                label: 'add_fund'.tr,
                onTap: _handleAddFund,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: _buildActionButton(
                iconPath: Images.sendFundsIcon,
                label: 'send'.tr,
                onTap: _handleSend,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: _buildActionButton(
                iconPath: Images.cardsIcon,
                label: 'cards'.tr,
                onTap: _handleCards,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: _buildActionButton(
                iconPath: Images.moreIcon,
                label: 'more'.tr,
                onTap: _handleMore,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds individual action button with custom icon
  Widget _buildActionButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeDefault,
          horizontal: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final iconSize = (constraints.maxWidth * 0.5).clamp(50.0, 75.0);
                return Image.asset(
                  iconPath,
                  width: iconSize,
                  height: iconSize * (76 / 75),
                  fit: BoxFit.contain,
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              label,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: const Color(0xFF9FA3A6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Handles Add Fund button tap
  void _handleAddFund() {
    Get.dialog(const AddFundDialogueWidget());
  }

  /// Handles Send button tap
  void _handleSend() {
    Get.toNamed(RouteHelper.getChooseReceiverRoute())?.then((result) {
      if (result != null && result is Map) {
        final recipientName = result['name'] as String? ?? '';
        final recipientPhone = result['phone'] as String? ?? '';

        if (recipientName.isNotEmpty && recipientPhone.isNotEmpty) {
          _showSendFundBottomSheet(recipientName, recipientPhone);
        }
      }
    });
  }

  /// Handles Cards button tap (placeholder)
  void _handleCards() {
    Get.snackbar(
      'coming_soon'.tr,
      'cards_feature_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Handles More button tap (placeholder)
  void _handleMore() {
    Get.snackbar(
      'coming_soon'.tr,
      'more_features_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Builds transaction history section
  Widget _buildTransactionHistory() {
    return GetBuilder<WalletController>(
      builder: (walletController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'transaction_history'.tr,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            walletController.transactionList != null
                ? walletController.transactionList!.isNotEmpty
                    ? ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: walletController.transactionList!.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          return HistoryItemWidget(
                            index: index,
                            fromWallet: true,
                            data: walletController.transactionList,
                          );
                        },
                      )
                    : NoDataScreen(text: 'no_data_found'.tr)
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                      child: CircularProgressIndicator(),
                    ),
                  ),
            if (walletController.isLoading)
              const Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  /// Shows send fund bottom sheet
  void _showSendFundBottomSheet(String recipientName, String recipientPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendFundBottomSheet(
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        onChangeReceiver: () {
          Get.back(); // Close current bottom sheet
          _handleSend(); // Reopen choose receiver
        },
        onSend: (paymentSource, amount, message) async {
          final amountValue = double.tryParse(amount);
          if (amountValue == null || amountValue <= 0) {
            Get.snackbar('error'.tr, 'invalid_amount'.tr);
            return;
          }

          final controller = Get.find<WalletTransferController>();

          // Validate recipient first
          final isValid = await controller.validateRecipient(recipientPhone);
          if (!isValid) {
            Get.snackbar('error'.tr, 'please_validate_recipient_first'.tr);
            return;
          }

          final request = TransferRequestModel(
            recipientPhone: recipientPhone,
            amount: amountValue,
            paymentSource: paymentSource,
            message: message,
          );

          final response = await controller.executeTransfer(request);

          if (response != null && response.success == true) {
            Get.back(); // Close bottom sheet
            Get.offNamed(
              RouteHelper.getTransferSuccessRoute(),
              arguments: <String, dynamic>{
                'transactionId': response.data?.transactionId,
                'amount': amountValue,
                'recipientName': recipientName,
                'newBalance': response.data?.senderNewBalance,
                'paymentSource': paymentSource,
                'createdAt': response.data?.createdAt,
                'transactionType': 'wallet_transfer',
              },
            );
          }
        },
      ),
    );
  }
}
