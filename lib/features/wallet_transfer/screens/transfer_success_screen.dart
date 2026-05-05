import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Success screen shown after successful transfer
/// Displays transaction details and action buttons
class TransferSuccessScreen extends StatelessWidget {
  const TransferSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? arguments =
        Get.arguments is Map<String, dynamic> ? Get.arguments as Map<String, dynamic> : null;

    final String? transactionId = arguments?['transactionId']?.toString();

    final dynamic amountRaw = arguments?['amount'];
    final double? amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '');

    final String? recipientName = arguments?['recipientName']?.toString();

    final dynamic newBalanceRaw = arguments?['newBalance'];
    final double? newBalance = newBalanceRaw is num
        ? newBalanceRaw.toDouble()
        : double.tryParse(newBalanceRaw?.toString() ?? '');

    final String? paymentSource = arguments?['paymentSource']?.toString();
    final String? createdAt = arguments?['createdAt']?.toString();
    final String transactionType =
        arguments?['transactionType']?.toString() ?? 'wallet_transfer';

    final String sourceText = paymentSource == 'wallet_qidha' ||
            paymentSource == 'qidha_wallet' ||
            paymentSource == 'qidha'
        ? 'qidha_wallet'.tr
        : 'regular_wallet'.tr;

    void openTransactionDetails() {
      debugPrint(
          '[TRANSFER_SUCCESS][VIEW_TRANSACTION_TAP] transactionId=$transactionId');
      Get.toNamed(
        RouteHelper.getWalletTransactionDetailRoute(),
        arguments: <String, dynamic>{
          'transactionId': transactionId,
          'amount': amount,
          'transactionType': transactionType,
          'paymentSource': paymentSource ?? 'wallet',
          'recipientName': recipientName,
          if (createdAt != null && createdAt.isNotEmpty) 'createdAt': createdAt,
          'previousRoute': RouteHelper.transferSuccess,
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success icon
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // Success message
              Text(
                'transfer_successful'.tr,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeOverLarge,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text(
                'money_sent_successfully'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).disabledColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              // Transaction details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'transaction_details'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    _buildDetailRow(context, 'transaction_id'.tr, transactionId ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(
                        context, 'amount'.tr, PriceConverter.convertPrice(amount ?? 0),
                        isHighlight: true),
                    const Divider(),
                    _buildDetailRow(context, 'recipient'.tr, recipientName ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(context, 'payment_source'.tr, sourceText),
                    const Divider(),
                    _buildDetailRow(
                        context, 'your_new_balance'.tr, PriceConverter.convertPrice(newBalance ?? 0)),
                  ],
                ),
              ),

              const Spacer(),

              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: openTransactionDetails,
                      icon: const Icon(Icons.receipt_long),
                      label: Text(
                        'view_transaction'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.offAllNamed(RouteHelper.getInitialRoute()),
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: Text(
                        'done'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds detail row
  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).disabledColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: (isHighlight ? robotoBold : robotoMedium).copyWith(
                fontSize: isHighlight
                    ? Dimensions.fontSizeLarge
                    : Dimensions.fontSizeDefault,
                color: isHighlight
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
