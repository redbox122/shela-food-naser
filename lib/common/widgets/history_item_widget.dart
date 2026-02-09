import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class HistoryItemWidget extends StatelessWidget {
  final int index;
  final bool fromWallet;
  final List<Transaction>? data;
  const HistoryItemWidget(
      {super.key,
      required this.index,
      required this.fromWallet,
      required this.data});

  String _getTransactionTypeDisplayText(String transactionType) {
    switch (transactionType) {
      case 'add_fund':
        return 'add_fund'.tr;
      case 'order_place':
        return 'order_place'.tr;
      case 'order_payment':
        return 'order_payment'.tr;
      case 'partial_payment':
        return 'partial_payment'.tr;
      case 'loyalty_point':
        return 'loyalty_point'.tr;
      case 'referrer':
        return 'referrer'.tr;
      case 'add_fund_by_admin':
        return 'add_fund_by_admin'.tr;
      case 'point_to_wallet':
        return 'point_to_wallet'.tr;
      default:
        // Fallback to original translation or display the raw type
        return transactionType.tr.isNotEmpty
            ? transactionType.tr
            : transactionType;
    }
  }

  /// Calculate and display transaction amount
  /// For wallet: amount = credit - debit (calculatedAmount)
  /// For loyalty: amount field (already calculated by backend)
  Widget _buildAmountDisplay(Transaction transaction) {
    // Calculate the net amount: credit - debit (or use amount field for loyalty)
    // For wallet: credit=0, debit=1 → calculatedAmount = 0 - 1 = -1 ✅
    // For wallet: credit=10, debit=0 → calculatedAmount = 10 - 0 = 10 ✅
    // For loyalty: uses amount field directly (already calculated by backend)
    final netAmount = transaction.calculatedAmount;
    
    // Add admin bonus to the amount
    final totalAmount = netAmount + (transaction.adminBonus ?? 0.0);
    
    // Format the amount with proper sign
    // Positive amounts: show "+ 10.00"
    // Negative amounts: show "- 10.00"
    final prefixText = totalAmount >= 0 ? '+ ' : '- ';
    final displayAmount = totalAmount.abs();
    
    return PriceConverter.convertPrice2(
      displayAmount,
      prefixText: prefixText,
      textStyle: robotoMedium.copyWith(fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is an order payment transaction that can be clicked
    final bool isOrderPayment = data![index].transactionType == 'order_payment' ||
        data![index].transactionType == 'order_place' ||
        data![index].transactionType == 'partial_payment';

    return GestureDetector(
      onTap: isOrderPayment
          ? () {
              // Navigate to order details screen
              Get.toNamed(
                  '/order-details?id=${data![index].reference}&from=true&from_offline=null&contact=null');
            }
          : null,
      child: Container(
        decoration: isOrderPayment
            ? BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              )
            : null,
        padding: isOrderPayment
            ? const EdgeInsets.all(Dimensions.paddingSizeSmall)
            : EdgeInsets.zero,
        child: Row(children: [
          // Left side - Icon and amount
          Row(children: [
            data![index].transactionType == 'order_place' ||
                    data![index].transactionType == 'partial_payment' ||
                    data![index].transactionType == 'order_payment'
                ? Image.asset(Images.walletDebitIcon, height: 15, width: 15)
                : Image.asset(Images.walletCreditIcon, height: 15, width: 15),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateConverter.dateToDateAndTimeAm(data![index].createdAt!),
                  style: robotoRegular.copyWith(
                      fontSize: 8, color: Theme.of(context).hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _buildAmountDisplay(data![index]),
              ],
            ),
          ]),

          const Spacer(),

          // Right side - Transaction type and description
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Transaction type - NOW VISIBLE!
                Text(
                  _getTransactionTypeDisplayText(data![index].transactionType!),
                  style: robotoRegular.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: fromWallet
                          ? data![index].transactionType == 'order_place' ||
                                  data![index].transactionType ==
                                      'partial_payment' ||
                                  data![index].transactionType ==
                                      'order_payment'
                              ? Colors.red
                              : Colors.green
                          : data![index].transactionType == 'point_to_wallet'
                              ? Colors.red
                              : Colors.green),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 2),
                // Description
                Text(
                  data![index].transactionType == 'add_fund'
                      ? '${'added_via'.tr} ${data![index].reference!.replaceAll('_', ' ')} ${data![index].adminBonus != 0 ? '(${'bonus'.tr} = ${data![index].adminBonus})' : ''}'
                      : data![index].transactionType == 'partial_payment'
                          ? '${'spend_on_order'.tr} # ${data![index].reference}'
                          : data![index].transactionType == 'loyalty_point'
                              ? 'converted_from_loyalty_point'.tr
                              : data![index].transactionType == 'referrer'
                                  ? 'earned_by_referral'.tr
                                  : data![index].transactionType ==
                                          'order_place'
                                      ? '${'order_place'.tr} # ${data![index].reference}'
                                      : data![index].transactionType ==
                                              'order_payment'
                                          ? '${'spend_on_order'.tr} # ${data![index].reference}'
                                          : data![index].transactionType!.tr,
                  style: robotoRegular.copyWith(
                      fontSize: 8, color: Theme.of(context).hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
                // Arrow for clickable transactions
                if (isOrderPayment) ...[
                  const SizedBox(height: 2),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 8,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
