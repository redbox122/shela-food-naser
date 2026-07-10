// 🎨 REDESIGN: Order-details template ("طلباتي → تفاصيل الطلب").
//
// Terminal states (completed / cancelled) share one clean layout per the new
// designs: an optional state banner, the order details, payment, address, date
// and a "أعد طلب الأوردر" reorder button. Active states (preparing / on-the-way)
// keep the earlier illustration-hero layout until their own designs land.
//
// All the fee/total math is done by the parent (OrderDetailsScreen) and passed
// in pre-computed so this widget stays purely presentational (except the
// reorder action, which re-adds the order's items to the cart).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class OrderDetailsRedesignView extends StatelessWidget {
  final OrderModel order;
  final List<OrderDetailsModel> orderDetails;
  final bool parcel;
  final bool taxIncluded;
  final double itemsPrice;
  final double addOns;
  final double deliveryCharge;
  final double additionalCharge;
  final double extraPackagingCharge;
  final double discount;
  final double couponDiscount;
  final double referrerBonusAmount;
  final double tax;
  final double dmTips;
  final double total;

  const OrderDetailsRedesignView({
    super.key,
    required this.order,
    required this.orderDetails,
    required this.parcel,
    required this.taxIncluded,
    required this.itemsPrice,
    required this.addOns,
    required this.deliveryCharge,
    required this.additionalCharge,
    required this.extraPackagingCharge,
    required this.discount,
    required this.couponDiscount,
    required this.referrerBonusAmount,
    required this.tax,
    required this.dmTips,
    required this.total,
  });

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF121C19);
  static const Color _muted = Color(0xFF8A8A8A);
  static const Color _border = Color(0xFFEDEFF1);
  static const Color _summaryBg = Color(0xFFF7F8FA);
  static const Color _green = Color(0xFF1FA64A);
  static const Color _red = Color(0xFFE5484D);

  /// 'completed' | 'cancelled' | 'active'
  String get _statusGroup {
    switch ((order.orderStatus ?? '').toLowerCase().trim()) {
      case 'delivered':
        return 'completed';
      case 'canceled':
      case 'cancelled':
      case 'failed':
      case 'expired':
      case 'refund_requested':
      case 'refunded':
      case 'refund_request_canceled':
        return 'cancelled';
      default:
        return 'active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String group = _statusGroup;
    if (group == 'active') return _activeLayout();
    return _terminalLayout(cancelled: group == 'cancelled');
  }

  // ════════════════════════════════════════════════════════════════════════
  // Terminal layout (completed / cancelled)
  // ════════════════════════════════════════════════════════════════════════
  Widget _terminalLayout({required bool cancelled}) {
    final Color accent = cancelled ? _red : _green;
    final double subTotal = itemsPrice + addOns;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cancelled) ...[
            _cancelledBanner(),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
          _sectionTitle('ord_order_details'.tr, accent: accent),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          if (!parcel && order.store != null) ...[
            _storeCard(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
          if (!parcel && orderDetails.isNotEmpty) ...[
            _itemsCard(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
          _summaryCard(subTotal),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _paymentBlock(),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          if (!parcel && (order.deliveryAddress?.address ?? '').isNotEmpty) ...[
            _detailBlock('ord_delivery_address'.tr, order.deliveryAddress!.address!),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
          if ((order.createdAt ?? '').isNotEmpty) ...[
            _detailBlock('ord_order_date'.tr,
                DateConverter.dateTimeStringToDateTime(order.createdAt!)),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
          _reorderButton(),
        ],
      ),
    );
  }

  /// Red strip shown for cancelled/failed/expired orders.
  Widget _cancelledBanner() {
    final String date = (order.createdAt ?? '').isNotEmpty
        ? DateConverter.dateTimeStringToDateOnly(order.createdAt!)
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall + 2,
      ),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              date.isEmpty ? 'ord_order_cancelled'.tr : 'تم إلغاء الطلب بتاريخ $date',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _red,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          const Icon(Icons.error_outline, size: 20, color: _red),
        ],
      ),
    );
  }

  /// Green "أعد طلب الأوردر" button: re-adds the order's items to the cart and
  /// opens the cart.
  Widget _reorderButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _confirmReorder,
        child: Text(
          'ord_reorder'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Confirmation bottom sheet shown before reordering.
  void _confirmReorder() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeExtraLarge,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DCE1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(
              'ord_reorder_confirm'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.4,
                color: _ink,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Get.back<void>();
                  _reorder();
                },
                child: Text(
                  'ord_yes_reorder'.tr,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F3F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Get.back<void>(),
                child: Text(
                  'ord_cancel'.tr,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: false,
    );
  }

  Future<void> _reorder() async {
    if (!Get.isRegistered<CartController>() || orderDetails.isEmpty) return;
    final CartController cart = Get.find<CartController>();
    try {
      for (final OrderDetailsModel d in orderDetails) {
        if (d.itemId == null) continue;
        final double unit = (d.price ?? 0) - (d.discountOnItem ?? 0);
        final OnlineCart online = OnlineCart(
          null,
          d.itemId,
          null,
          unit.toString(),
          '',
          [],
          [],
          d.quantity ?? 1,
          [],
          [],
          [],
          'Item',
          storeId: order.store?.id,
        );
        await cart.addToCartOnline(online);
      }
      Get.toNamed(RouteHelper.getCartRoute());
    } catch (_) {
      // Best-effort reorder; surface nothing on failure.
    }
  }

  // ── Payment (card-style chip) ─────────────────────────────────────────────
  Widget _paymentBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockLabel('ord_payment_method'.tr),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall + 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card_rounded, size: 22, color: _ink),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  _paymentLabel(),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A right-aligned label with its value below (address / date).
  Widget _detailBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _blockLabel(label),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.5,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _blockLabel(String text) => Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.6,
          color: _ink,
        ),
      );

  /// Readable labels for the customer's chosen options on an order item
  /// (food-variation choices + add-ons), shown under the item name.
  List<String> _orderChoiceLabels(OrderDetailsModel d) {
    final List<String> out = <String>[];
    final foodVars = d.foodVariation;
    if (foodVars != null) {
      for (final v in foodVars) {
        final List<String> chosen = <String>[];
        final vals = v.variationValues;
        if (vals != null) {
          for (final val in vals) {
            final String lvl = (val.level ?? '').trim();
            if (lvl.isNotEmpty) chosen.add(lvl);
          }
        }
        final String name = (v.name ?? '').trim();
        if (chosen.isNotEmpty) {
          out.add(name.isEmpty ? chosen.join('، ') : '$name: ${chosen.join('، ')}');
        }
      }
    }
    final addOns = d.addOns;
    if (addOns != null) {
      for (final a in addOns) {
        final String n = (a.name ?? '').trim();
        if (n.isNotEmpty) out.add('+ $n');
      }
    }
    return out;
  }

  // ── Store card ────────────────────────────────────────────────────────────
  Widget _storeCard() {
    return _card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomImage(
              image: order.store?.logoFullUrl ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: Image.asset(Images.placeholder,
                  width: 48, height: 48, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.store?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _ink,
                  ),
                ),
                if ((order.store?.address ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    order.store!.address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: _muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Items card ────────────────────────────────────────────────────────────
  Widget _itemsCard() {
    return _card(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Column(
        children: List<Widget>.generate(orderDetails.length, (int index) {
          final OrderDetailsModel detail = orderDetails[index];
          final int quantity = detail.quantity ?? 1;
          final double original = (detail.price ?? 0) * quantity;
          final double discounted =
              ((detail.price ?? 0) - (detail.discountOnItem ?? 0)) * quantity;
          final bool hasDiscount = discounted < original;
          final String? desc = detail.itemDetails?.description;
          final List<String> choiceLabels = _orderChoiceLabels(detail);
          return Padding(
            padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Solid green index circle with a white number.
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.itemDetails?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _ink,
                        ),
                      ),
                      if ((desc ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          desc!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: _muted,
                          ),
                        ),
                      ],
                      // Customer's chosen options under the item name.
                      if (choiceLabels.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          choiceLabels.join('  •  '),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            height: 1.35,
                            color: _muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        textDirection: TextDirection.ltr,
                        children: [
                          Text(
                            PriceConverter.convertPrice(discounted),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _green,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Text(
                              PriceConverter.convertPrice(original),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                color: _muted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: _red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _summaryCard(double subTotal) {
    final double totalDiscount = discount + referrerBonusAmount;
    final double shipping = deliveryCharge + additionalCharge;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: _summaryBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow('ord_items_total'.tr, subTotal),
          if (shipping > 0) _summaryRow('ord_shipping_fees'.tr, shipping),
          if (extraPackagingCharge > 0)
            _summaryRow('ord_packing_fee'.tr, extraPackagingCharge),
          if (!taxIncluded && tax > 0) _summaryRow('ord_tax'.tr, tax),
          if (dmTips > 0) _summaryRow('ord_driver_tip'.tr, dmTips),
          if (totalDiscount > 0)
            _summaryRow('ord_discount'.tr, totalDiscount, negative: true),
          if (couponDiscount > 0)
            _summaryRow('ord_coupon_code'.tr, couponDiscount, negative: true),
          const Padding(
            padding:
                EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: Divider(height: 1, color: _border),
          ),
          Row(
            children: [
              Text(
                'ord_order_total'.tr,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _ink,
                ),
              ),
              const Spacer(),
              Text(
                PriceConverter.convertPrice(total),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool negative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.6,
              color: _ink,
            ),
          ),
          const Spacer(),
          Text(
            '${negative ? '- ' : ''}${PriceConverter.convertPrice(value)}',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.6,
              color: negative ? _green : _ink,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared bits ───────────────────────────────────────────────────────────
  Widget _sectionTitle(String text, {Color accent = _green}) {
    return Row(
      children: [
        Icon(Icons.bookmark, size: 20, color: accent),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(
          text,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 1.6,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  String _paymentLabel() {
    switch (order.paymentMethod) {
      case 'cash_on_delivery':
        return 'cash'.tr;
      case 'wallet':
        return 'wallet'.tr;
      case 'partial_payment':
        return 'partial_payment'.tr;
      case 'wallet_qidha':
        return 'ord_qidha'.tr;
      case 'offline_payment':
        return 'offline_payment'.tr;
      case 'digital_payment':
        return 'Credit Card';
      default:
        return (order.paymentMethod ?? '').tr;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // Active layout (preparing / on-the-way) — earlier illustration-hero design,
  // kept until those states get their own designs.
  // ════════════════════════════════════════════════════════════════════════
  Widget _activeLayout() {
    final _StatusVisual status = _StatusVisual.fromStatus(order.orderStatus);
    final double subTotal = itemsPrice + addOns;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusHeader(status),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _sectionTitle('ord_order_details'.tr),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (!parcel && order.store != null) ...[
            _storeCard(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
          if (!parcel && orderDetails.isNotEmpty) ...[
            _itemsCard(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
          _summaryCard(subTotal),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _paymentBlock(),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          if (!parcel && (order.deliveryAddress?.address ?? '').isNotEmpty) ...[
            _detailBlock('ord_delivery_address'.tr, order.deliveryAddress!.address!),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
          if ((order.createdAt ?? '').isNotEmpty)
            _detailBlock('ord_order_date'.tr,
                DateConverter.dateTimeStringToDateTime(order.createdAt!)),
        ],
      ),
    );
  }

  Widget _statusHeader(_StatusVisual status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeLarge,
        horizontal: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: status.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 141,
            child: Image.asset(
              status.illustration,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                Images.shella_bag,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            status.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.4,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${'order_id'.tr} #${order.id}',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _ink,
              ),
            ),
          ),
          if ((order.otp ?? '').isNotEmpty &&
              (order.orderType ?? '') != 'take_away') ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _deliveryOtpCard(status),
          ],
        ],
      ),
    );
  }

  // رمز التسليم — يظهر للعميل ليعطيه للسائق عند الاستلام (تحقّق التوصيل)
  Widget _deliveryOtpCard(_StatusVisual status) {
    final String code = order.otp ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeDefault,
        horizontal: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock_outlined, size: 18, color: status.accent),
              const SizedBox(width: 6),
              Text(
                'ord_delivery_code'.tr,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // الأرقام تُعرض LTR دائماً حتى لا تنعكس خاناتها في واجهة RTL (3769 لا 9673)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: code.split('').map((d) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 44,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: status.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: status.accent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  d,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: status.accent,
                  ),
                ),
              );
            }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ord_give_code_driver'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xff71807a),
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps a raw order status into the active-state hero: title, illustration and
/// accent colour.
class _StatusVisual {
  final String title;
  final String illustration;
  final Color accent;

  const _StatusVisual({
    required this.title,
    required this.illustration,
    required this.accent,
  });

  factory _StatusVisual.fromStatus(String? status) {
    switch ((status ?? '').toLowerCase().trim()) {
      case 'handover':
      case 'picked_up':
      case 'out_for_delivery':
        return _StatusVisual(
          title: 'ord_on_the_way'.tr,
          illustration: Images.onTheWayImage,
          accent: Color(0xFF1FA64A),
        );
      default:
        // pending / accepted / confirmed / processing
        return _StatusVisual(
          title: 'ord_being_prepared'.tr,
          illustration: Images.orderProccedImage,
          accent: Color(0xFF6B4EFF),
        );
    }
  }
}
