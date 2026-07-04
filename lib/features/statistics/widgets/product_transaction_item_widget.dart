import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ProductTransactionItemWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final int index;
  final VoidCallback? onTap;

  ProductTransactionItemWidget({
    super.key,
    required this.transaction,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = onTap != null;

    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: AppColors.wtColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isClickable ? onTap : null,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Row(
                children: [
                  // Left side - Icon and amount
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: AppColors.greenColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.greenColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),

                  // Center - Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Order ID
                        Text(
                          '${'product_deep_dive.order_id'.tr}: ${transaction['invoice'] ?? 'N/A'}',
                          style: font12Black400W(context).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Date
                        Text(
                          _formatDate((transaction['date'] as String?) ?? ''),
                          style: font10Grey400W(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Quantity and unit price
                        Text(
                          '${transaction['quantity'] ?? 0} ${'product_deep_dive.units'.tr} • ${transaction['unit_price'] ?? 0} ر.س/${'product_deep_dive.units'.tr}',
                          style: font10Grey500W(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Right side - Total amount and arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${transaction['total'] ?? 0} ر.س',
                        style: font14Green500W(context).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isClickable) ...[
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.greenColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
