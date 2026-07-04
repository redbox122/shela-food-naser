import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/features/wallet/controllers/wallet_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';

class WalletHistoryWidget extends StatelessWidget {
  const WalletHistoryWidget({super.key});

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
    return GetBuilder<WalletController>(builder: (walletController) {
      if (kDebugMode) {
        debugPrint('🔍 [WalletHistoryWidget] build() - Rebuilding UI');
        debugPrint(
            '   - transactionList: ${walletController.transactionList != null ? "NOT NULL" : "NULL"}');
        debugPrint(
            '   - length: ${walletController.transactionList?.length ?? 0}');
        debugPrint('   - isLoading: ${walletController.isLoading}');
      }

      // ==== قائمة خيارات الفلتر (نفس المنطق السابق) ====
      final List<PopupMenuEntry> entryList = [];
      String currentFilterTitle = 'all_transactions'.tr;

      for (int i = 0; i < walletController.walletFilterList.length; i++) {
        final bool isSelected =
            walletController.walletFilterList[i].value == walletController.type;
        entryList.add(PopupMenuItem<int>(
            value: i,
            child: Text(
              walletController.walletFilterList[i].title!.tr,
              style: robotoMedium.copyWith(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium!.color,
              ),
            )));
        if (isSelected) {
          currentFilterTitle = walletController.walletFilterList[i].title!.tr;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: ResponsiveHelper.isDesktop(context)
                    ? Dimensions.paddingSizeExtraSmall
                    : Dimensions.paddingSizeExtraLarge,
                bottom: Dimensions.paddingSizeSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'wallet_history'.tr,
                  style: robotoBold.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                // ==== زر الفلتر بشكل قائمة منسدلة ====
                PopupMenuButton<dynamic>(
                  offset: const Offset(0, 44),
                  itemBuilder: (BuildContext context) => entryList,
                  onSelected: (dynamic value) {
                    walletController.setWalletFilerType(
                        walletController.walletFilterList[value as int].value!);
                    walletController.getWalletTransactionList(
                        '1', false, walletController.type);
                  },
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                        Radius.circular(Dimensions.radiusDefault)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xffF6F5F8),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall, vertical: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        currentFilterTitle,
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff111B18)),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (walletController.hasTransactionError &&
              !walletController.isLoading &&
              (walletController.transactionList == null ||
                  walletController.transactionList!.isEmpty))
            ErrorStateView(
              onRetry: () {
                walletController.getWalletTransactionList(
                    '1', true, walletController.type);
              },
            )
          else if (walletController.transactionList == null)
            WalletShimmer(walletController: walletController)
          else if (walletController.transactionList!.isEmpty)
            const _NoTransactionView()
          else
            ..._buildGrouped(context, walletController.transactionList!),
          walletController.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox(),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  List<Widget> _buildGrouped(BuildContext context, List<Transaction> list) {
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
              fontSize: Dimensions.fontSizeExtraLarge,
              fontWeight: FontWeight.w700,
              color: Color(0xff707784),
            ),
          ),
        ));
      }
      widgets.add(_WalletHistoryRow(transaction: t));
    }
    return widgets;
  }
}

// ==== صف حركة المحفظة ====
class _WalletHistoryRow extends StatelessWidget {
  final Transaction transaction;
  const _WalletHistoryRow({required this.transaction});

  // حركات الدفع (خصم) على الطلب
  bool get _isDebit =>
      transaction.transactionType == 'order_payment' ||
      transaction.transactionType == 'order_place' ||
      transaction.transactionType == 'partial_payment';

  // كل الحركات المرتبطة بطلب (تنقّل + سطر "مكان الطلب")
  bool get _isOrder =>
      _isDebit || transaction.transactionType == 'order_refund';

  // العنوان الملوّن حسب نوع الحركة
  String _title() {
    final String type = transaction.transactionType ?? '';
    switch (type) {
      case 'order_refund':
        return 'order_refund'.tr; // استرداد الطلب
      case 'order_payment':
      case 'order_place':
      case 'partial_payment':
        return 'order_payment'.tr; // دفع الطلب
      case 'add_fund':
        return 'add_fund'.tr;
      case 'loyalty_point':
        return 'converted_from_loyalty_point'.tr;
      case 'referrer':
        return 'earned_by_referral'.tr;
      default:
        return type.tr.isNotEmpty ? type.tr : type;
    }
  }

  // الوصف الثانوي (رمادي)
  String? _subtitle() {
    final String type = transaction.transactionType ?? '';
    if (_isOrder) {
      return '${'order_place'.tr} #${transaction.reference}'; // مكان الطلب #42
    }
    if (type == 'add_fund') {
      final String bonus = (transaction.adminBonus ?? 0) != 0
          ? ' (${'bonus'.tr} = ${transaction.adminBonus})'
          : '';
      return '${'added_via'.tr} ${transaction.reference?.replaceAll('_', ' ') ?? ''}$bonus';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final double net =
        transaction.calculatedAmount + (transaction.adminBonus ?? 0.0);
    final String prefix = net >= 0 ? '+ ' : '- ';
    final Color accent = _isDebit ? Colors.red : Theme.of(context).primaryColor;

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
          color: _isDebit
              ? Colors.red.withValues(alpha: 0.05)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Row(
          children: [
            Image.asset(
              Images.Hands_Coin,
              width: 30,
              height: 30,
            ),
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
                        fontSize: Dimensions.fontSizeLarge,
                        color: Color(0xff111B18)),
                  ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$prefix${net.abs().toStringAsFixed(2)}',
                      style: tajawalMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: const Color(0xff111B18),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Image.asset(
                      Images.sar,
                      width: 20,
                      height: 20,
                      cacheWidth: 60,
                      cacheHeight: 60,
                      color: accent,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // العنوان الملوّن + الوصف الرمادي
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title(),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tajawalMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        fontWeight: FontWeight.w700,
                        color: accent),
                  ),
                  if (_subtitle() != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _subtitle()!,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tajawalMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff111B18)),
                    ),
                  ],
                ],
              ),
            ),
            if (_isOrder) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xff111B18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==== حالة عدم وجود معاملات ====
class _NoTransactionView extends StatelessWidget {
  const _NoTransactionView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.no_transaction,
            width: 161.29,
            height: 168.79,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'wallet_no_transactions_now'.tr,
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
  final WalletController walletController;
  const WalletShimmer({super.key, required this.walletController});

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
            enabled: walletController.transactionList == null,
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
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 10),
                          Container(
                              height: 10,
                              width: 70,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2))),
                        ]),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                              height: 10,
                              width: 50,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 10),
                          Container(
                              height: 10,
                              width: 70,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
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
