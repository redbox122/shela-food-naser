import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';

/// Proves the checkout totals guard ACTUALLY detects an amount mismatch (the
/// previous guard compared `total` to itself, so its mismatch branch was dead
/// code). Exercises the pure decision function `checkoutTotalsBlockReason`,
/// which is the logic `guardCheckoutTotals` delegates to.
void main() {
  // Helper: the happy-path baseline — a valid 100.00 order.
  String? reason({
    double payableTotal = 100.0,
    double orderAmount = 100.0,
    double productSubtotal = 90.0,
    double couponDiscount = 0.0,
  }) =>
      CheckoutController.checkoutTotalsBlockReason(
        payableTotal: payableTotal,
        orderAmount: orderAmount,
        productSubtotal: productSubtotal,
        couponDiscount: couponDiscount,
      );

  group('checkoutTotalsBlockReason — no false positives', () {
    test('valid totals pass (null = allowed)', () {
      expect(reason(), isNull);
    });

    test('1-cent rounding difference is tolerated', () {
      expect(reason(payableTotal: 100.00, orderAmount: 100.009), isNull);
    });

    test('realistic order with delivery + tax + coupon passes', () {
      // subtotal 80 + delivery 10 + tax 12 - coupon 2 = 100, sent = 100.
      expect(
        reason(
            payableTotal: 100.0,
            orderAmount: 100.0,
            productSubtotal: 80.0,
            couponDiscount: 2.0),
        isNull,
      );
    });
  });

  group('checkoutTotalsBlockReason — POSITIVE detection (must block)', () {
    test('amount sent drifts above displayed total → mismatch', () {
      // The dev-mode "inject a difference" check: a tampered/ drifted amount.
      expect(reason(payableTotal: 100.0, orderAmount: 105.0),
          'order_amount_mismatch');
    });

    test('amount sent drifts below displayed total → mismatch', () {
      expect(reason(payableTotal: 100.0, orderAmount: 95.0),
          'order_amount_mismatch');
    });

    test('difference just over the 1-cent tolerance → mismatch', () {
      expect(reason(payableTotal: 100.0, orderAmount: 100.02),
          'order_amount_mismatch');
    });

    test('NaN / Infinity amounts are blocked', () {
      expect(reason(orderAmount: double.nan), 'order_amount_mismatch');
      expect(reason(orderAmount: double.infinity), 'order_amount_mismatch');
    });

    test('zero / negative payable total is blocked', () {
      expect(reason(payableTotal: 0, orderAmount: 0), 'payable_total_invalid');
      expect(
          reason(payableTotal: -5, orderAmount: -5), 'payable_total_invalid');
    });

    test('negative coupon discount is blocked', () {
      expect(reason(couponDiscount: -1), 'coupon_discount_invalid');
    });

    test('coupon discount exceeding the subtotal is blocked', () {
      expect(reason(productSubtotal: 90, couponDiscount: 91),
          'coupon_discount_exceeds_subtotal');
    });
  });
}
