import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/features/loyalty/controllers/loyalty_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

class LoyaltyHistoryWidget extends StatelessWidget {
  const LoyaltyHistoryWidget({super.key});

  String _dayLabel(DateTime? d) {
    if (d == null) return '';
    final DateTime now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'today'.tr;
    }
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'yesterday'.tr;
    }
    return DateConverter.dateToReadableDate(d);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoyaltyController>(builder: (loyaltyController) {
      final List<Transaction>? list = loyaltyController.transactionList;
      final bool hasError = loyaltyController.hasTransactionError &&
          !loyaltyController.isLoading &&
          (list == null || list.isEmpty);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: ResponsiveHelper.isDesktop(context)
                    ? Dimensions.paddingSizeExtraSmall
                    : Dimensions.paddingSizeExtraLarge,
                bottom: Dimensions.paddingSizeSmall),
            child: Text(
              'points_history'.tr,
              style: tajawalBold.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xff111B18),
              ),
            ),
          ),
          if (hasError)
            ErrorStateView(
              onRetry: () =>
                  loyaltyController.getLoyaltyTransactionList('1', true),
            )
          else if (list == null)
            WalletShimmer(loyaltyController: loyaltyController)
          else if (list.isEmpty)
            const _NoPointsView()
          else
            ..._buildGrouped(context, list, loyaltyController),
          loyaltyController.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox(),
          const SizedBox(height: 90),
        ],
      );
    });
  }

  List<Widget> _buildGrouped(
      BuildContext context, List<Transaction> list, LoyaltyController c) {
    final List<Widget> widgets = [];
    String? currentLabel;
    for (int i = 0; i < list.length; i++) {
      final Transaction t = list[i];
      final String label = _dayLabel(t.createdAt);
      if (label != currentLabel) {
        currentLabel = label;
        widgets.add(Padding(
          padding: EdgeInsets.only(
              top: widgets.isEmpty ? 4 : Dimensions.paddingSizeDefault,
              bottom: Dimensions.paddingSizeSmall),
          child: Text(
            label,
            style: tajawalBold.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: Dimensions.fontSizeExtraLarge,
                color: Color(0xff707784)),
          ),
        ));
      }
      widgets.add(_PointHistoryRow(transaction: t));
    }
    return widgets;
  }
}

// ==== صف عملية النقاط ====
class _PointHistoryRow extends StatelessWidget {
  final Transaction transaction;
  const _PointHistoryRow({required this.transaction});

  bool get _isOrder =>
      transaction.transactionType == 'order_payment' ||
      transaction.transactionType == 'order_place' ||
      transaction.transactionType == 'partial_payment';

  String _typeLabel() {
    final String type = transaction.transactionType ?? '';
    switch (type) {
      case 'order_place':
        return '${'order_place'.tr} #${transaction.reference}';
      case 'order_payment':
      case 'partial_payment':
        return '${'spend_on_order'.tr} #${transaction.reference}';
      case 'loyalty_point':
        return 'converted_from_loyalty_point'.tr;
      case 'referrer':
        return 'earned_by_referral'.tr;
      case 'point_to_wallet':
        return 'point_to_wallet'.tr;
      default:
        return type.tr.isNotEmpty ? type.tr : type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double net =
        transaction.calculatedAmount + (transaction.adminBonus ?? 0.0);
    final String prefix = net >= 0 ? '+ ' : '- ';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xff111B18);
    final Color amountColor = isDark ? Colors.white : const Color(0xff020202);

    return GestureDetector(
      onTap: _isOrder
          ? () => Get.toNamed(
              '/order-details?id=${transaction.reference}&from=true&from_offline=null&contact=null')
          : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: isDark
              ? Border.all(color: const Color(0xFF334155), width: 1)
              : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Image.asset(Images.Hands_Coin, width: 30, height: 30),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            // المبلغ + الوقت
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (transaction.createdAt != null)
                  Text(
                    DateConverter.dateToTimeOnly(transaction.createdAt!),
                    style: tajawalMedium.copyWith(
                        fontSize: Dimensions.fontSizeMedim,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                  ),
                const SizedBox(height: 2),
                PriceConverter.convertPrice2(
                  net.abs(),
                  prefixText: prefix,
                  symbolColor: amountColor,
                  textStyle: tajawalMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: textColor),
                ),
              ],
            ),
            const Spacer(),
            // تفاصيل العملية
            Flexible(
              child: Text(
                _typeLabel(),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tajawalMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault),
              ),
            ),
            if (_isOrder) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: textColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==== حالة عدم وجود نقاط ====
class _NoPointsView extends StatelessWidget {
  const _NoPointsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Images.no_points, height: 110, width: 110),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'no_points_yet'.tr,
            textAlign: TextAlign.center,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
        ],
      ),
    );
  }
}

class WalletShimmer extends StatelessWidget {
  final LoyaltyController loyaltyController;
  const WalletShimmer({super.key, required this.loyaltyController});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: UniqueKey(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 50,
        mainAxisSpacing: ResponsiveHelper.isDesktop(context)
            ? Dimensions.paddingSizeLarge
            : 0.01,
        childAspectRatio: ResponsiveHelper.isDesktop(context) ? 5 : 3.8,
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 1,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 10,
      padding:
          EdgeInsets.only(top: ResponsiveHelper.isDesktop(context) ? 28 : 25),
      itemBuilder: (context, index) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: loyaltyController.transactionList == null,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 10,
                              width: 50,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).shadowColor,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 10),
                          Container(
                              height: 10,
                              width: 70,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).shadowColor,
                                  borderRadius: BorderRadius.circular(2))),
                        ]),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                              height: 10,
                              width: 50,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).shadowColor,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 10),
                          Container(
                              height: 10,
                              width: 70,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).shadowColor,
                                  borderRadius: BorderRadius.circular(2))),
                        ]),
                  ],
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                    child: Divider(color: Theme.of(context).disabledColor)),
              ],
            ),
          ),
        );
      },
    );
  }
}
