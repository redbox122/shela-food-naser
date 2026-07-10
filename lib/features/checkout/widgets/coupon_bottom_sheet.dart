import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

import '../../my_coupon/controllers/my_coupon_controller.dart';
import '../../my_coupon/domain/models/my_coupon_models.dart';

/// 🎨 Professional coupons sheet: opens from the checkout "الكوبونات" button and
/// lists the customer's own coupons (from their profile / [CouponController]).
/// Tapping "استخدام" fills the coupon field and closes the sheet.
class CouponBottomSheet extends StatefulWidget {
  final int? storeId;
  final CheckoutController checkoutController;
  const CouponBottomSheet(
      {super.key, required this.storeId, required this.checkoutController});

  @override
  State<CouponBottomSheet> createState() => _CouponBottomSheetState();
}

class _CouponBottomSheetState extends State<CouponBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Fetch the customer's coupons the first time the sheet opens.
    final CouponController c = Get.find<CouponController>();
    if (c.couponList == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => c.getCouponList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: Dimensions.webMaxWidth,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      margin: EdgeInsets.only(top: GetPlatform.isWeb ? 0 : 30),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ResponsiveHelper.isDesktop(context))
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFDDE0E6),
                  borderRadius: BorderRadius.circular(2)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(children: [
              Expanded(
                child: Text('coupons'.tr,
                    style: tajawalBold.copyWith(
                        fontSize: 18, color: const Color(0xFF121C19))),
              ),
              InkWell(
                onTap: () => Get.back<void>(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 22)),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEFF2)),
          Flexible(
            child: GetBuilder<CouponController>(builder: (couponController) {
              final List<CouponModel>? all = couponController.couponList;
              if (all == null) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Keep coupons valid for this store (matches the old filter).
              final List<CouponModel> list = all
                  .where((coupon) =>
                      coupon.storeId == null ||
                      (coupon.couponType != 'store_wise' &&
                          coupon.couponType != 'default' &&
                          coupon.couponType != 'free_delivery') ||
                      coupon.storeId == widget.storeId)
                  .toList();
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.confirmation_number_outlined,
                        size: 56, color: Color(0xFFBFC6CF)),
                    const SizedBox(height: 12),
                    Text('no_promo_available'.tr,
                        style: tajawalBold.copyWith(
                            fontSize: 15, color: const Color(0xFF8A8F99))),
                  ]),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _CouponCard(
                  coupon: list[i],
                  onUse: () {
                    if (list[i].code != null) {
                      widget.checkoutController.couponController.text =
                          list[i].code!;
                    }
                    Get.back<void>();
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// A single professional coupon card: green discount badge + code chip + title,
/// min-purchase / expiry hints, and a green "استخدام" button.
class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onUse;
  const _CouponCard({required this.coupon, required this.onUse});

  static const Color _green = Color(0xFF30913F);

  @override
  Widget build(BuildContext context) {
    final bool isPercent = coupon.discountType == 'percent' ||
        coupon.discountType == 'percentage';
    final String discountText = isPercent
        ? '${(coupon.discount ?? 0).toStringAsFixed(0)}%'
        : PriceConverter.convertPrice(coupon.discount ?? 0);
    final String expiry = (coupon.expireDate ?? '').split('T').first;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(children: [
          // Discount badge (physical right in RTL).
          Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: const BoxDecoration(color: _green),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('خصم',
                    style: tajawalMedium.copyWith(
                        fontSize: 12, color: Colors.white)),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(discountText,
                      style: tajawalBold.copyWith(
                          fontSize: 20, height: 1.0, color: Colors.white)),
                ),
              ],
            ),
          ),
          // Details.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(coupon.title ?? coupon.code ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tajawalBold.copyWith(
                          fontSize: 15, color: const Color(0xFF121C19))),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEBFEEB),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(coupon.code ?? '',
                        style: tajawalBold.copyWith(
                            fontSize: 12, color: const Color(0xFF1F7A35))),
                  ),
                  if ((coupon.minPurchase ?? 0) > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                        'الحد الأدنى للطلب: ${PriceConverter.convertPrice(coupon.minPurchase ?? 0)}',
                        style: tajawalRegular.copyWith(
                            fontSize: 11, color: const Color(0xFF8A8F99))),
                  ],
                  if (expiry.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('صالح حتى: $expiry',
                        style: tajawalRegular.copyWith(
                            fontSize: 11, color: const Color(0xFF8A8F99))),
                  ],
                ],
              ),
            ),
          ),
          // Use button (physical left in RTL).
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: TextButton(
              onPressed: onUse,
              style: TextButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('استخدام',
                  style: tajawalBold.copyWith(
                      fontSize: 13, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}
