import 'package:flutter/foundation.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:get/get.dart';

import '../domain/coupon_list_filters.dart';
import '../domain/models/my_coupon_models.dart';
import '../domain/repositories/coupon_repository.dart';
import '../domain/services/coupon_service_interface.dart';

/// Result of [CouponController.revalidateAppliedCoupon].
enum CouponRevalidationResult {
  /// Coupon still valid and the discount value did not change.
  unchanged,

  /// Coupon still valid but the money discount was recomputed because the cart
  /// subtotal changed (e.g. percent coupon on a smaller/bigger cart).
  recomputed,

  /// Coupon became invalid and was auto-removed (code + discount + model cleared).
  removed,
}

class CouponController extends GetxController implements GetxService {
  final CouponServiceInterface couponServiceInterface;
  CouponController({required this.couponServiceInterface});

  List<CouponModel>? _couponList;
  List<CouponModel>? get couponList => _couponList;

  List<CouponModel>? _taxiCouponList;
  List<CouponModel>? get taxiCouponList => _taxiCouponList;

  CouponModel? _coupon;
  CouponModel? get coupon => _coupon;

  double? _discount = 0.0;
  double? get discount => _discount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  bool _freeDelivery = false;
  bool get freeDelivery => _freeDelivery;

  /// True when a coupon is applied from cart/checkout (discount or free delivery).
  bool get hasAppliedCoupon =>
      _coupon != null &&
      (_freeDelivery || (_discount != null && _discount! > 0.0001));

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }

  Future<void> getCouponList() async {
    _isLoading = true;
    _hasError = false;
    update();
    try {
      final List<CouponModel>? couponList =
          await couponServiceInterface.getCouponList();
      _couponList = <CouponModel>[];
      if (couponList != null) {
        _couponList!.addAll(couponList);
      }
      if (kDebugMode) {
        final int total = _couponList?.length ?? 0;
        debugPrint('[MyCoupons][CONTROLLER_LIST_LEN] $total');
        if (total > 0) {
          debugPrint(
            '[MyCoupons][FILTERED_COUNT] first_tab_not_expired=${countNotExpiredByDateCoupons(_couponList!)} '
            'usable=${countUsableCoupons(_couponList!)} '
            'used_not_expired=${countUsedNotExpiredCoupons(_couponList!)} '
            'expired_by_date=${countExpiredTabCoupons(_couponList!)}',
          );
        }
        if (total == 0) {
          debugPrint(
            '[MyCoupons][EMPTY_REASON] ${couponList == null ? 'repository_returned_null' : 'empty_list_after_fetch'}',
          );
        }
      }
    } catch (e, st) {
      _hasError = true;
      _couponList = <CouponModel>[];
      if (kDebugMode) {
        debugPrint('[MyCoupons][EMPTY_REASON] exception_in_controller e=$e');
        debugPrint('[MyCoupons][STACK] $st');
      }
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> getTaxiCouponList() async {
    final List<CouponModel>? taxiCouponList =
        await couponServiceInterface.getTaxiCouponList();
    if (taxiCouponList != null) {
      _taxiCouponList = [];
      _taxiCouponList!.addAll(taxiCouponList);
    }
    update();
  }

  Future<double?> applyCoupon(
      String coupon, double order, double? deliveryCharge, int? storeID) async {
    final String trimmed = coupon.trim();
    if (kDebugMode) {
      debugPrint(
        '[Coupon][INPUT] controllerText=${coupon.isEmpty ? '<empty>' : coupon} trimmed=$trimmed',
      );
    }
    if (trimmed.isEmpty) {
      showCustomSnackBar('enter_a_coupon_code'.tr);
      return null;
    }
    _isLoading = true;
    _discount = 0;
    update();
    final CouponModel? couponModel =
        await couponServiceInterface.applyCoupon(trimmed, storeID);
    if (couponModel != null) {
      _coupon = couponModel;
      if (_coupon!.couponType == 'free_delivery') {
        _processFreeDeliveryCoupon(deliveryCharge!, order);
      } else {
        _processCoupon(order);
      }
      if (kDebugMode && hasAppliedCoupon) {
        debugPrint(
          '[Coupon][APPLY_SUCCESS] code=${_coupon?.code} discount=$_discount '
          'type=${_coupon?.discountType} couponType=${_coupon?.couponType}',
        );
        debugPrint(
          '[Coupon][STATE] appliedCouponCode=${_coupon?.code} couponDiscount=$_discount '
          'freeDelivery=$_freeDelivery',
        );
        debugPrint(
          '[Coupon][UI_REBUILD] inputVisible=${!hasAppliedCoupon} discountRowVisible=$hasAppliedCoupon',
        );
      }
    } else {
      _coupon = null;
      _discount = 0.0;
      _freeDelivery = false;
      final String? failReason = CouponRepository.applyCouponLastFailureReason;
      if (kDebugMode) {
        debugPrint('[Coupon][APPLY_FAIL] reason=${failReason ?? 'unknown'}');
      }
      if (failReason != '304_empty_body_after_retry') {
        final String snackKey =
            CouponRepository.applyCouponLastMessageKey ?? 'coupon_error_invalid_code';
        showCustomSnackBar(snackKey.tr);
      }
    }
    _isLoading = false;
    update();
    return _discount;
  }

  void _processFreeDeliveryCoupon(double deliveryCharge, double order) {
    if (deliveryCharge > 0) {
      final double? minP = _coupon!.minPurchase;
      final bool passesMin =
          minP == null || minP <= 0 || order >= minP;
      if (passesMin) {
        _discount = 0;
        _freeDelivery = true;
      } else {
        showCustomSnackBar(
            '${'the_minimum_item_purchase_amount_for_this_coupon_is'.tr} '
            '${PriceConverter.convertPrice(minP)} '
            '${'but_you_have'.tr} ${PriceConverter.convertPrice(order)}');

        _coupon = null;
        _discount = 0;
      }
    } else {
      showCustomSnackBar('coupon_error_invalid_code'.tr);
    }
  }

  void _processCoupon(double order) {
    final double? minP = _coupon!.minPurchase;
    final bool passesMin = minP == null || minP <= 0 || order >= minP;
    if (!passesMin) {
      _discount = 0.0;
      showCustomSnackBar(
          '${'the_minimum_item_purchase_amount_for_this_coupon_is'.tr} '
          '${PriceConverter.convertPrice(minP)} '
          '${'but_you_have'.tr} ${PriceConverter.convertPrice(order)}');
      _coupon = null;
      return;
    }
    if (_coupon!.discountType == 'percent') {
      if (_coupon!.maxDiscount != null && _coupon!.maxDiscount! > 0) {
        _discount = (_coupon!.discount! * order / 100) < _coupon!.maxDiscount!
            ? (_coupon!.discount! * order / 100)
            : _coupon!.maxDiscount;
      } else {
        _discount = _coupon!.discount! * order / 100;
      }
    } else {
      _discount = _coupon!.discount;
    }
    if (kDebugMode) {
      debugPrint(
        '[Coupon][DISCOUNT_CALC] subtotalOrder=$order discountValue=${_coupon!.discount} '
        'discountType=${_coupon!.discountType} couponDiscountAmount=$_discount',
      );
    }
  }

  /// Re-validates the currently applied coupon against the latest cart/context.
  ///
  /// - Auto-removes the coupon (clearing code + discount + model, recalculating
  ///   totals via [update]) when it is no longer valid for any of: expire_date
  ///   passed, status inactive, already used, subtotal below min_purchase,
  ///   module_id mismatch, or store_id mismatch (store-specific coupons).
  /// - Otherwise recomputes the money discount against the new subtotal so a
  ///   shrinking/growing cart can never carry a stale amount.
  ///
  /// Backend stays the final source of truth (zone/eligibility/used are also
  /// enforced server-side on /coupon/apply and at place-order).
  CouponRevalidationResult revalidateAppliedCoupon({
    required double cartSubtotal,
    int? currentModuleId,
    int? currentStoreId,
    String reason = '',
  }) {
    if (_coupon == null) {
      return CouponRevalidationResult.unchanged;
    }
    if (kDebugMode) {
      debugPrint(
        '[Coupon][REVALIDATE_START] code=${_coupon?.code} reason=$reason '
        'module=$currentModuleId store=$currentStoreId',
      );
      debugPrint(
        '[Coupon][REVALIDATE_CART_SUBTOTAL] subtotal=$cartSubtotal '
        'minPurchase=${_coupon?.minPurchase} freeDelivery=$_freeDelivery',
      );
    }

    final String? invalidReason = _firstCouponInvalidReason(
      cartSubtotal: cartSubtotal,
      currentModuleId: currentModuleId,
      currentStoreId: currentStoreId,
    );

    if (invalidReason != null) {
      final String removedCode = _coupon?.code ?? '';
      if (kDebugMode) {
        debugPrint(
          '[Coupon][REVALIDATE_INVALID_REASON] reason=$invalidReason code=$removedCode',
        );
      }
      _coupon = null;
      _discount = 0.0;
      _freeDelivery = false;
      if (kDebugMode) {
        debugPrint('[Coupon][AUTO_REMOVED] code=$removedCode reason=$invalidReason');
      }
      update();
      showCustomSnackBar('تم إزالة الكوبون لأنه لم يعد صالحًا');
      return CouponRevalidationResult.removed;
    }

    // Still valid. Free-delivery coupons have no money discount to recompute.
    if (_freeDelivery) {
      return CouponRevalidationResult.unchanged;
    }
    final double previous = _discount ?? 0.0;
    _recomputeDiscountForSubtotal(cartSubtotal);
    final double updated = _discount ?? 0.0;
    if ((updated - previous).abs() > 0.0001) {
      if (kDebugMode) {
        debugPrint(
          '[Coupon][REVALIDATE_RECALC] code=${_coupon?.code} '
          'old=$previous new=$updated subtotal=$cartSubtotal',
        );
      }
      update();
      return CouponRevalidationResult.recomputed;
    }
    return CouponRevalidationResult.unchanged;
  }

  /// Returns the first reason the applied coupon is invalid, or null if valid.
  /// Min purchase is checked against the product subtotal ONLY (no delivery,
  /// tax, tips, app fee, or additional charge).
  String? _firstCouponInvalidReason({
    required double cartSubtotal,
    int? currentModuleId,
    int? currentStoreId,
  }) {
    final CouponModel c = _coupon!;
    if (couponIsExpiredByDate(c)) {
      return 'expire_date_passed';
    }
    if (c.status != null && c.status != 1) {
      return 'status_inactive';
    }
    if (c.isUsed) {
      return 'already_used';
    }
    final double? minP = c.minPurchase;
    if (minP != null && minP > 0 && cartSubtotal < minP) {
      return 'below_min_purchase';
    }
    if (c.moduleId != null &&
        currentModuleId != null &&
        c.moduleId != currentModuleId) {
      return 'module_mismatch';
    }
    // Store-specific coupon (store_id set & > 0) must match the current store.
    if (c.storeId != null &&
        c.storeId! > 0 &&
        currentStoreId != null &&
        c.storeId != currentStoreId) {
      return 'store_mismatch';
    }
    return null;
  }

  void _recomputeDiscountForSubtotal(double subtotal) {
    final CouponModel c = _coupon!;
    if (c.discountType == 'percent') {
      double d = (c.discount ?? 0) * subtotal / 100;
      if (c.maxDiscount != null && c.maxDiscount! > 0 && d > c.maxDiscount!) {
        d = c.maxDiscount!;
      }
      _discount = d;
    } else {
      _discount = c.discount ?? 0;
    }
  }

  Future<double?> applyTaxiCoupon(
      String coupon, double orderAmount, int? providerId) async {
    _isLoading = true;
    _discount = 0;
    update();
    final CouponModel? taxiCouponModel =
        await couponServiceInterface.applyTaxiCoupon(coupon, providerId);
    if (taxiCouponModel != null) {
      _coupon = taxiCouponModel;
      if (_coupon!.minPurchase != null && _coupon!.minPurchase! < orderAmount) {
        if (_coupon!.discountType == 'percent') {
          if (_coupon!.maxDiscount != null && _coupon!.maxDiscount! > 0) {
            _discount =
                (_coupon!.discount! * orderAmount / 100) < _coupon!.maxDiscount!
                    ? (_coupon!.discount! * orderAmount / 100)
                    : _coupon!.maxDiscount;
          } else {
            _discount = _coupon!.discount! * orderAmount / 100;
          }
        } else {
          _discount = _coupon!.discount;
        }
      } else {
        _discount = 0.0;
      }
    }
    _isLoading = false;
    update();
    return _discount;
  }

  void removeCouponData(bool notify) {
    final String? removedCode = _coupon?.code;
    if (kDebugMode) {
      debugPrint('[Coupon][REMOVE] code=$removedCode');
    }
    _coupon = null;
    _isLoading = false;
    _discount = 0.0;
    _freeDelivery = false;
    if (notify) {
      update();
    }
  }
}
