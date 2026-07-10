import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:sixam_mart/features/checkout/widgets/mf_embedded_card_sheet.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/distance_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/timeslote_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_flow_state.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:sixam_mart/features/checkout/widgets/order_successfull_dialog.dart';
import 'package:sixam_mart/features/checkout/widgets/partial_pay_dialog_widget.dart';
import 'package:sixam_mart/features/checkout/widgets/in_app_payment_modal.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/payment/screens/myfatoorah_payment_webview_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/payment/domain/services/myfatoorah_service.dart';
import 'package:sixam_mart/features/payment/domain/repositories/myfatoorah_repository.dart';
import 'package:sixam_mart/features/payment/domain/utils/myfatoorah_mapper.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../my_coupon/controllers/my_coupon_controller.dart';

/// Outcome of verifying a MyFatoorah payment via the backend check-status
/// endpoint after the WebView returns.
enum MyFatoorahPaymentResult {
  /// Gateway confirmed and order is paid/confirmed.
  paid,

  /// Invoice is still Pending / transaction InProgress — payment was not
  /// completed. The order stays hidden as payment_pending; the user can retry.
  pending,

  /// Payment failed or was cancelled.
  failed,
}

/// Why [CheckoutController.recoverPendingPaymentIfAny] was invoked. Controls
/// whether automatic recovery (network check-status + user-facing snackbar) is
/// allowed, so a stale context from an unrelated old order never pops a warning
/// during a normal checkout open.
enum PaymentRecoveryTrigger {
  /// Checkout screen opened normally (cart → checkout). NEVER auto-recovers or
  /// shows a pending warning for an unrelated/old order — only TTL cleanup.
  checkoutOpen,

  /// App returned to foreground (e.g. after the MyFatoorah WebView / payment).
  appResume,

  /// Explicit entry from a payment-recovery flow — always allowed to recover.
  explicit,
}

class _CheckoutReadableError {
  final String? code;
  final String message;

  const _CheckoutReadableError({required this.code, required this.message});
}

class CheckoutController extends GetxController implements GetxService {
  final CheckoutServiceInterface checkoutServiceInterface;
  CheckoutController({required this.checkoutServiceInterface});

  final TextEditingController couponController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController tipController = TextEditingController();
  final FocusNode streetNode = FocusNode();
  final FocusNode houseNode = FocusNode();
  final FocusNode floorNode = FocusNode();

  DateTime? selectedDateTime;

  String selected_Now_Scheduled = 'now';

  String? countryDialCode = _resolveCountryDialCode();

  // 🛡️ NULL-SAFE: Resolve the country dial code without crashing when the
  // backend config has no country set (configModel/country can be null).
  // Falls back to the saved user country code, then to the active locale.
  static String? _resolveCountryDialCode() {
    final String userCountryCode =
        Get.find<AuthController>().getUserCountryCode();
    if (userCountryCode.isNotEmpty) {
      return userCountryCode;
    }
    final String? configCountry =
        Get.find<SplashController>().configModel?.country;
    if (configCountry != null && configCountry.isNotEmpty) {
      return CountryCode.fromCountryCode(configCountry).dialCode ??
          Get.find<LocalizationController>().locale.countryCode;
    }
    return Get.find<LocalizationController>().locale.countryCode;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  void setLoading(bool value, {List<String>? ids}) {
    _isLoading = value;
    if (ids != null && ids.isNotEmpty) {
      update(ids);
    } else {
      update();
    }
  }

  bool _placeOrderLocked = false;
  bool tryStartPlaceOrder() {
    if (_placeOrderLocked) {
      return false;
    }
    _placeOrderLocked = true;
    return true;
  }

  void finishPlaceOrder() {
    _placeOrderLocked = false;
  }

  /// Final safety guard run BEFORE any order/payment request is sent — covers
  /// all payment methods (wallet_qidha, wallet, digital_payment/MyFatoorah, and
  /// cash). Returns true when it is safe to proceed; false blocks the order.
  ///
  /// [couponDiscount] is compared against the PRODUCT subtotal only (never
  /// delivery fee, tax, tips, app fee, or additional charge). On a coupon-caused
  /// failure the invalid coupon is removed and totals recalculate through the
  /// CouponController's own update(); existing coupon revalidation is untouched.
  ///
  /// Logs are intentionally limited to numeric totals — no token, address, or
  /// payment credentials are ever logged here.
  /// Pure, side-effect-free totals validation — the decision half of
  /// [guardCheckoutTotals], split out so it can be unit-tested without GetX /
  /// overlay / coupon side-effects. Returns the block reason, or null when the
  /// totals are valid.
  ///
  /// Order of checks:
  /// 1) Coupon discount sanity — measured against the product subtotal only.
  /// 2) Final payable total sanity.
  /// 3) The independently re-derived amount must match the displayed payable
  ///    total. `orderAmount` is recomputed from raw components by the caller
  ///    (NOT a copy of `payableTotal`), so a real mismatch here means the
  ///    displayed total drifted from its parts — block before charging. (1 cent
  ///    tolerance absorbs rounding only.)
  @visibleForTesting
  static String? checkoutTotalsBlockReason({
    required double payableTotal,
    required double orderAmount,
    required double productSubtotal,
    required double couponDiscount,
  }) {
    if (couponDiscount.isNaN ||
        couponDiscount.isInfinite ||
        couponDiscount < 0) {
      return 'coupon_discount_invalid';
    } else if (productSubtotal.isNaN ||
        productSubtotal.isInfinite ||
        productSubtotal < 0) {
      return 'product_subtotal_invalid';
    } else if (couponDiscount > productSubtotal) {
      return 'coupon_discount_exceeds_subtotal';
    } else if (payableTotal.isNaN ||
        payableTotal.isInfinite ||
        payableTotal <= 0) {
      return 'payable_total_invalid';
    } else if (orderAmount.isNaN ||
        orderAmount.isInfinite ||
        (orderAmount - payableTotal).abs() > 0.01) {
      return 'order_amount_mismatch';
    }
    return null;
  }

  bool guardCheckoutTotals({
    required double payableTotal,
    required double orderAmount,
    required double productSubtotal,
    required double couponDiscount,
  }) {
    debugPrint('[Checkout][TOTAL_GUARD_START]');
    debugPrint(
      '[Checkout][TOTAL_GUARD_VALUES] '
      'payableTotal=$payableTotal orderAmount=$orderAmount '
      'productSubtotal=$productSubtotal couponDiscount=$couponDiscount',
    );

    final String? blockReason = checkoutTotalsBlockReason(
      payableTotal: payableTotal,
      orderAmount: orderAmount,
      productSubtotal: productSubtotal,
      couponDiscount: couponDiscount,
    );
    // Coupon-caused reasons clear the coupon; others ask for a cart refresh.
    final bool couponCaused = blockReason == 'coupon_discount_invalid' ||
        blockReason == 'coupon_discount_exceeds_subtotal';

    if (blockReason != null) {
      debugPrint(
        '[Checkout][TOTAL_GUARD_BLOCKED] reason=$blockReason '
        'couponCaused=$couponCaused',
      );
      if (couponCaused) {
        // Clear the invalid coupon; CouponController.update() rebuilds the
        // checkout UI so totals recalculate without the stale discount.
        try {
          if (Get.isRegistered<CouponController>()) {
            Get.find<CouponController>().removeCouponData(true);
          }
        } catch (_) {}
        showCustomSnackBar('pay_coupon_removed'.tr, isError: true);
      } else {
        showCustomSnackBar(
            'pay_total_invalid'.tr,
            isError: true);
      }
      return false;
    }

    debugPrint('[Checkout][TOTAL_GUARD_PASSED]');
    return true;
  }

  // Flag to prevent UI flickering during checkout initialization
  // Only show calculated values when this is true
  bool _isCheckoutReady = false;
  bool get isCheckoutReady => _isCheckoutReady;

  bool _hasCheckoutError = false;
  bool get hasCheckoutError => _hasCheckoutError;

  // Delivery charge readiness flag
  // UI should only show delivery fee/total when this is true
  bool _isDeliveryChargeReady = false;
  bool get isDeliveryChargeReady => _isDeliveryChargeReady;

  void _setDeliveryChargeReady(bool value,
      {bool notify = true, bool forceNotify = false}) {
    final bool valueChanged = _isDeliveryChargeReady != value;
    _isDeliveryChargeReady = value;

    if (forceNotify || (valueChanged && notify)) {
      debugPrint('🔄 [Checkout] Delivery charge ready: $value');

      // تحديث الأجزاء المسؤولة عن المبالغ
      update(['checkout', 'total', 'delivery_fee']);

      // تحديث عام للتأكد من إعادة بناء الواجهة بالكامل
      update();
    }
  }

  void _refreshDeliveryChargeReady(
      {bool notify = true, bool forceNotify = false}) {
    final bool ready = _orderType == 'take_away' ||
        (_distance != null &&
            _distance != -1 &&
            _extraCharge != null &&
            _store != null);
    _setDeliveryChargeReady(ready, notify: notify, forceNotify: forceNotify);
  }

  // 🔥 PERFORMANCE: Guard to prevent unnecessary delivery charge calculations
  // Delivery charge can only be calculated when store and address zone data are available
  // Note: This uses the current address from AddressController, not a stored field
  bool canCalculateDelivery(AddressModel? address) {
    return store != null &&
        address != null &&
        address.zoneData != null &&
        address.zoneData!.isNotEmpty;
  }

  // CRITICAL: Payment state management to prevent double payments
  bool _isPaymentInProgress = false;
  bool _isOrderPaid = false;

  /// While true, suppress "order placed successfully" notifications for unpaid digital orders.
  bool _suppressPendingOrderPlacementNotifications = false;
  bool get suppressPendingOrderPlacementNotifications =>
      _suppressPendingOrderPlacementNotifications;

  bool get isDigitalPaymentSelected =>
      _paymentMethodIndex == 2 || select_payment_Methods != null;

  // 🥇 Anti-loop Guard: Payment Flow State
  PaymentFlowState _paymentFlowState = PaymentFlowState.idle;
  PaymentFlowState get paymentFlowState => _paymentFlowState;

  /// هل العملية قيد التنفيذ؟
  bool get isPaymentFlowInProgress => _paymentFlowState.isInProgress;

  /// هل يمكن بدء عملية جديدة؟
  bool get canStartNewPaymentFlow => _paymentFlowState.canStartNewFlow;

  // 🔥 PERFORMANCE: Guard لمنع فحص حالة المتجر المتكرر
  bool _storeStatusChecked = false;
  bool get storeStatusChecked => _storeStatusChecked;

  void resetPaymentState({bool notify = true}) {
    _paymentFlowState = PaymentFlowState.idle;
    _isPaymentInProgress = false;
    _isOrderPaid = false;
    _suppressPendingOrderPlacementNotifications = false;
    _isLoading = false;
    if (notify) {
      update();
    }
  }

  /// Digital payment: order created ≠ final success — suppress premature success UX.
  void beginDigitalPaymentFlow() {
    _suppressPendingOrderPlacementNotifications = true;
    debugPrint('[Payment][Digital] Suppressing pending-order success notifications');
  }

  void endDigitalPaymentFlow({required bool succeeded}) {
    _suppressPendingOrderPlacementNotifications = false;
    debugPrint(
        '[Payment][Digital] End flow succeeded=$succeeded suppress=$_suppressPendingOrderPlacementNotifications');
  }

  Future<void> _refreshRunningOrdersFromServer() async {
    if (!Get.isRegistered<OrderController>()) {
      return;
    }
    try {
      await Get.find<OrderController>().getRunningOrders(1, isUpdate: true);
    } catch (e) {
      debugPrint('[Payment][Digital] getRunningOrders refresh failed: $e');
    }
  }

  /// Message to show for the next digital-payment failure. Lets [Pay]
  /// distinguish "not completed yet (pending/InProgress)" from a hard
  /// failure/cancel while reusing the shared cleanup below. Consumed once.
  String? _digitalFailureMessage;

  /// The gateway's actual failure reason (e.g. "card declined") captured from
  /// the last check-status response, so a real decline shows WHY instead of a
  /// generic message — distinct from a network drop (treated as pending).
  String? _lastGatewayFailureReason;

  /// Pulls a human failure reason out of a MyFatoorah check-status body, trying
  /// the common shapes. Returns null when none is present (→ generic fallback).
  String? _extractGatewayFailureReason(Map<String, dynamic> body, dynamic data) {
    String? pick(dynamic v) {
      final s = v?.toString().trim();
      return (s != null && s.isNotEmpty) ? s : null;
    }

    if (data is Map<String, dynamic>) {
      final direct = pick(data['Error']) ??
          pick(data['error']) ??
          pick(data['ErrorMessage']) ??
          pick(data['TransactionStatusDescription']);
      if (direct != null) return direct;
      final txns = data['InvoiceTransactions'];
      if (txns is List && txns.isNotEmpty && txns.last is Map) {
        final last = txns.last as Map;
        final t = pick(last['Error']) ?? pick(last['ErrorCode']);
        if (t != null) return t;
      }
    }
    return pick(body['message']) ?? pick(body['error']);
  }

  Future<void> handleDigitalPaymentFailure() async {
    _paymentFlowState = PaymentFlowState.failed;
    _isLoading = false;
    _isPaymentInProgress = false;
    _isOrderPaid = false;
    endDigitalPaymentFlow(succeeded: false);
    update(['payment']);
    final int? pendingOrderId = _currentOrderId;
    if (pendingOrderId != null && Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().removeRunningOrderLocally(pendingOrderId);
    }
    await _refreshRunningOrdersFromServer();
    final String message =
        _digitalFailureMessage ?? 'pay_op_failed'.tr;
    _digitalFailureMessage = null;
    showCustomSnackBar(message);
  }

  void clearCartOnPaymentConfirmed() {
    try {
      Get.find<CartController>().clearCartList();
    } catch (e) {
      if (kDebugMode) debugPrint('$e');
    }
    resetPaymentState();
  }

  // ==========================================================================
  // PENDING PAYMENT RECOVERY (MyFatoorah / digital)
  // --------------------------------------------------------------------------
  // Persists a NON-sensitive payment context so a MyFatoorah/digital payment
  // can be re-verified after the app is backgrounded, killed, network-dropped,
  // or the user backs out — instead of wrongly treating the order as lost or
  // failed. NEVER stores card data, tokens, or full address.
  // ==========================================================================

  bool _recoveringPendingPayment = false;

  Future<void> storePendingPaymentContext({
    required int orderId,
    String? invoiceId,
    required String paymentMethod,
  }) async {
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      final Map<String, dynamic> ctx = <String, dynamic>{
        'order_id': orderId,
        'invoice_id': (invoiceId != null && invoiceId.isNotEmpty)
            ? invoiceId
            : null,
        'payment_method': paymentMethod,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(
          AppConstants.pendingPaymentContext, jsonEncode(ctx));
      debugPrint(
          '[PaymentRecovery][STORE_PENDING] orderId=$orderId '
          'hasInvoice=${invoiceId != null && invoiceId.isNotEmpty} '
          'method=$paymentMethod');
    } catch (e) {
      debugPrint('[PaymentRecovery][STORE_PENDING] failed: $e');
    }
  }

  Map<String, dynamic>? _readPendingPaymentContext() {
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      final String? raw =
          prefs.getString(AppConstants.pendingPaymentContext);
      if (raw == null || raw.isEmpty) return null;
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (e) {
      debugPrint('[PaymentRecovery] read pending context failed: $e');
      return null;
    }
  }

  Future<void> clearPendingPaymentContext({String reason = ''}) async {
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      await prefs.remove(AppConstants.pendingPaymentContext);
      debugPrint('[PaymentRecovery][CLEAR_PENDING] reason=$reason');
    } catch (e) {
      debugPrint('[PaymentRecovery][CLEAR_PENDING] failed: $e');
    }
  }

  /// Max age of a stored pending-payment context. Older contexts are treated as
  /// expired and cleared instead of being recovered (prevents a long-dead order
  /// from popping a warning on a future checkout).
  static const Duration _pendingPaymentContextTtl = Duration(minutes: 30);

  /// Re-checks a previously-started MyFatoorah/digital payment exactly once.
  ///
  /// [trigger] gates whether automatic recovery is allowed:
  ///  • [PaymentRecoveryTrigger.checkoutOpen] → NEVER auto-recovers a stale/old
  ///    order; only does TTL cleanup, so a normal cart→checkout open can't show
  ///    a pending warning that belongs to a previous order.
  ///  • [PaymentRecoveryTrigger.appResume] → recovers only when the stored
  ///    context belongs to THIS session's order (e.g. returning after the
  ///    MyFatoorah WebView).
  ///  • [PaymentRecoveryTrigger.explicit] → always recovers (came from a
  ///    payment-recovery flow).
  ///
  /// Never marks an unconfirmed order as failed — pending/InProgress stays
  /// pending and the context is kept for a later re-check. Reuses the existing
  /// check-status logic; does not change any backend contract.
  Future<void> recoverPendingPaymentIfAny({
    PaymentRecoveryTrigger trigger = PaymentRecoveryTrigger.appResume,
  }) async {
    if (_recoveringPendingPayment) return;

    // Never interfere with a payment that is actively running in this session;
    // that flow verifies itself when the WebView returns.
    if (_isPaymentInProgress || isPaymentFlowInProgress) return;

    final Map<String, dynamic>? ctx = _readPendingPaymentContext();
    if (ctx == null) return;

    final int? orderId = ctx['order_id'] is int
        ? ctx['order_id'] as int
        : int.tryParse('${ctx['order_id']}');
    final String? invoiceId = (ctx['invoice_id'] as String?)?.trim();

    // 1) TTL: drop a context that is older than the allowed window.
    final int ts = ctx['timestamp'] is int
        ? ctx['timestamp'] as int
        : int.tryParse('${ctx['timestamp']}') ?? 0;
    final int ageMs = DateTime.now().millisecondsSinceEpoch - ts;
    if (ts <= 0 || ageMs > _pendingPaymentContextTtl.inMilliseconds) {
      debugPrint(
          '[PaymentRecovery][EXPIRED_CONTEXT] orderId=$orderId '
          'ageMin=${(ageMs / 60000).floor()} ttlMin=${_pendingPaymentContextTtl.inMinutes}');
      await clearPendingPaymentContext(reason: 'expired_context');
      return;
    }

    // 2) Normal checkout open must NOT auto-recover an unrelated/old order. Keep
    // the (non-expired) context silently; a real resume/explicit trigger or a
    // new payment will handle it.
    if (trigger == PaymentRecoveryTrigger.checkoutOpen) {
      debugPrint(
          '[PaymentRecovery][SKIP_CHECKOUT_OPEN] contextOrderId=$orderId '
          'currentOrderId=$_currentOrderId');
      return;
    }

    // 3) Relevance: outside an explicit recovery flow, only recover when the
    // stored context belongs to THIS checkout session's order. This blocks a
    // stale context (e.g. old order 448) from showing a warning on app resume
    // while the user is on an unrelated new checkout.
    final bool sessionMatches =
        _currentOrderId != null && orderId != null && orderId == _currentOrderId;
    if (trigger != PaymentRecoveryTrigger.explicit && !sessionMatches) {
      debugPrint(
          '[PaymentRecovery][SKIP_STALE_CONTEXT] contextOrderId=$orderId '
          'currentOrderId=$_currentOrderId trigger=$trigger');
      return;
    }

    _recoveringPendingPayment = true;
    try {
      debugPrint(
          '[PaymentRecovery][CHECK_START] orderId=$orderId '
          'hasInvoice=${invoiceId != null && invoiceId.isNotEmpty} '
          'trigger=$trigger');

      MyFatoorahPaymentResult result;
      if (invoiceId != null && invoiceId.isNotEmpty) {
        result = await _checkMyFatoorahStatus(invoiceId);
      } else if (orderId != null) {
        final bool confirmed = await _confirmMyFatoorahPayment(orderId);
        result = confirmed
            ? MyFatoorahPaymentResult.paid
            : MyFatoorahPaymentResult.pending;
      } else {
        await clearPendingPaymentContext(reason: 'no_identifiers');
        return;
      }

      debugPrint('[PaymentRecovery][CHECK_RESULT] result=$result');

      switch (result) {
        case MyFatoorahPaymentResult.paid:
          await clearPendingPaymentContext(reason: 'paid');
          clearCartOnPaymentConfirmed();
          showCustomSnackBar('pay_order_confirmed'.tr, isError: false);
          if (orderId != null) {
            Get.toNamed(RouteHelper.getOrderDetailsRoute(orderId));
          } else {
            Get.toNamed(RouteHelper.getOrderRoute());
          }
          break;
        case MyFatoorahPaymentResult.pending:
          // Keep the context so a later resume can confirm. NOT a failure.
          showCustomSnackBar(
              'pay_not_complete_orders'.tr);
          break;
        case MyFatoorahPaymentResult.failed:
          await clearPendingPaymentContext(reason: 'failed');
          showCustomSnackBar(
              'pay_failed_no_charge'.tr);
          break;
      }
    } finally {
      _recoveringPendingPayment = false;
    }
  }

  /// Returns the stored gateway invoice id ONLY if the pending context belongs
  /// to [orderId]; otherwise null. Lets an explicit per-order check reuse the
  /// real MyFatoorah invoice saved when the payment was started.
  String? pendingInvoiceIdForOrder(int orderId) {
    final Map<String, dynamic>? ctx = _readPendingPaymentContext();
    if (ctx == null) return null;
    final int? ctxOrderId = ctx['order_id'] is int
        ? ctx['order_id'] as int
        : int.tryParse('${ctx['order_id']}');
    if (ctxOrderId != orderId) return null;
    final String? invoiceId = (ctx['invoice_id'] as String?)?.trim();
    return (invoiceId != null && invoiceId.isNotEmpty) ? invoiceId : null;
  }

  /// Clears the stored pending-payment context ONLY if it belongs to [orderId],
  /// so an explicit check on one order never wipes another order's context.
  Future<void> _clearPendingContextIfMatches(int orderId,
      {String reason = ''}) async {
    final Map<String, dynamic>? ctx = _readPendingPaymentContext();
    if (ctx == null) return;
    final int? ctxOrderId = ctx['order_id'] is int
        ? ctx['order_id'] as int
        : int.tryParse('${ctx['order_id']}');
    if (ctxOrderId == orderId) {
      await clearPendingPaymentContext(reason: reason);
    }
  }

  /// Explicit, user-initiated payment status check for ONE specific
  /// digital/MyFatoorah order — triggered from Orders / Order Details, never
  /// from checkout open. Safe: it only inspects the given [orderId], never shows
  /// a checkout snackbar, and does not touch wallet_qidha / wallet / COD flows
  /// (the caller gates on payment_method == 'digital_payment').
  ///
  /// Uses the order's invoice id when available; otherwise falls back to the
  /// existing trackOrder status check. Returns the resolved result so the caller
  /// can refresh its own UI. Does not change any backend contract.
  Future<MyFatoorahPaymentResult> checkOrderPaymentStatusExplicit(
    int orderId, {
    String? invoiceId,
    String? contactNumber,
  }) async {
    // Invoice id source priority:
    //  1) stored pending_payment_context invoice id (only if it matches THIS
    //     order) — the real gateway invoice saved when the payment started,
    //  2) invoice id passed in from the order data (if the order model carries
    //     one), then
    //  3) no invoice id → fall back to the trackOrder status check below.
    final String? contextInvoiceId = pendingInvoiceIdForOrder(orderId);
    final String? resolvedInvoiceId =
        (contextInvoiceId != null && contextInvoiceId.isNotEmpty)
            ? contextInvoiceId
            : ((invoiceId != null && invoiceId.isNotEmpty) ? invoiceId : null);

    debugPrint(
        '[PaymentRecovery][EXPLICIT_ORDER_CHECK_START] orderId=$orderId '
        'invoiceSource=${contextInvoiceId != null && contextInvoiceId.isNotEmpty ? 'context' : ((invoiceId != null && invoiceId.isNotEmpty) ? 'order' : 'trackOrder')}');

    MyFatoorahPaymentResult result;
    try {
      if (resolvedInvoiceId != null && resolvedInvoiceId.isNotEmpty) {
        result = await _checkMyFatoorahStatus(resolvedInvoiceId);
      } else {
        // No gateway invoice id on the order — use the order status / trackOrder
        // check (single read, not a long poll).
        final OrderController orderController = Get.find<OrderController>();
        await orderController.trackOrder(
          orderId.toString(),
          null,
          false,
          contactNumber: contactNumber,
          preserveTrackModel: true,
        );
        final String paymentStatus =
            orderController.trackModel?.paymentStatus?.toLowerCase() ?? '';
        final String orderStatus =
            orderController.trackModel?.orderStatus?.toLowerCase() ?? '';
        if (paymentStatus == 'paid' || paymentStatus == 'partially_paid') {
          result = MyFatoorahPaymentResult.paid;
        } else if (paymentStatus == 'failed' ||
            paymentStatus == 'canceled' ||
            paymentStatus == 'cancelled' ||
            orderStatus == 'failed' ||
            orderStatus == 'canceled' ||
            orderStatus == 'cancelled') {
          result = MyFatoorahPaymentResult.failed;
        } else {
          result = MyFatoorahPaymentResult.pending;
        }
      }
    } catch (e) {
      debugPrint('[PaymentRecovery][EXPLICIT_ORDER_CHECK] exception: $e');
      // Never wrongly mark as failed — treat as pending so the user can retry.
      result = MyFatoorahPaymentResult.pending;
    }

    debugPrint(
        '[PaymentRecovery][EXPLICIT_ORDER_CHECK_RESULT] orderId=$orderId '
        'result=$result');

    switch (result) {
      case MyFatoorahPaymentResult.paid:
        await _clearPendingContextIfMatches(orderId, reason: 'explicit_paid');
        showCustomSnackBar('pay_order_confirmed'.tr, isError: false);
        break;
      case MyFatoorahPaymentResult.pending:
        showCustomSnackBar(
            'pay_not_complete_retry'.tr);
        break;
      case MyFatoorahPaymentResult.failed:
        await _clearPendingContextIfMatches(orderId, reason: 'explicit_failed');
        showCustomSnackBar(
            'pay_failed_cancelled'.tr);
        break;
    }
    return result;
  }

  void selectPaymentMethod(int index) {
    if (index < 0 || index >= paymentMethods.length) {
      return;
    }
    // Mark digital payment as selected
    _paymentMethodIndex = 2;
    selectedButton = 1;
    isSelected = List<bool>.filled(paymentMethods.length, false);
    isSelected[index] = true;
    select_payment_Methods = paymentMethods[index];
    update(['payment', 'checkout']);
  }

  AddressModel? _guestAddress;
  AddressModel? get guestAddress => _guestAddress;

  int? _mostDmTipAmount;
  int? get mostDmTipAmount => _mostDmTipAmount;

  String _preferableTime = '';
  String get preferableTime => _preferableTime;

  List<OfflineMethodModel>? _offlineMethodList;
  List<OfflineMethodModel>? get offlineMethodList => _offlineMethodList;

  bool _isPartialPay = false;
  bool get isPartialPay => _isPartialPay;

  bool _isMy_Pay = false;
  bool get isMy_Pay => _isMy_Pay;

  bool _isKaidhaPay = false;
  bool get isKaidhaPay => _isKaidhaPay;

  double _tips = 0.0;
  double get tips => _tips;

  int _selectedTips = 0;
  int get selectedTips => _selectedTips;

  Store? _store;
  Store? get store => _store;

  int? _addressIndex = 0;
  int? get addressIndex => _addressIndex;

  XFile? _orderAttachment;
  XFile? get orderAttachment => _orderAttachment;

  Uint8List? _rawAttachment;
  Uint8List? get rawAttachment => _rawAttachment;

  bool _acceptTerms = true;
  bool get acceptTerms => _acceptTerms;

  int _paymentMethodIndex = -1;
  int get paymentMethodIndex => _paymentMethodIndex;

  // Ported from the old app's payment section: a transient "no payment method
  // selected" validation flag the payment cards read to show their red outline.
  bool _payMethodError = false;
  bool get payMethodError => _payMethodError;
  set payMethodError(bool value) {
    _payMethodError = value;
    update(['payment']);
  }

  int _selectedDateSlot = 0;
  int get selectedDateSlot => _selectedDateSlot;

  int _selectedTimeSlot = 0;
  int get selectedTimeSlot => _selectedTimeSlot;

  double? _distance;
  double? get distance => _distance;

  // ✅ NEW: Store pre-calculated distance from cart screen
  double? preCalculatedDistance;

  List<TimeSlotModel>? _timeSlots;
  List<TimeSlotModel>? get timeSlots => _timeSlots;

  List<TimeSlotModel>? _allTimeSlots;
  List<TimeSlotModel>? get allTimeSlots => _allTimeSlots;

  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  bool get hasPrescriptionRequiredItems {
    final cartController = Get.find<CartController>();
    return cartController.cartList.any((cart) {
      return cart.item?.isPrescriptionRequired == true &&
          cart.item?.moduleType == AppConstants.pharmacy;
    });
  }

  double? _extraCharge;
  double? get extraCharge => _extraCharge;

  // ✅ NEW: Reactive delivery charge - updates automatically when distance/store changes
  double _calculatedDeliveryCharge = 0.0;
  double get calculatedDeliveryCharge => _calculatedDeliveryCharge;

  /// Set the calculated delivery charge and notify UI
  void setCalculatedDeliveryCharge(double charge) {
    if (_calculatedDeliveryCharge != charge) {
      _calculatedDeliveryCharge = charge;
      debugPrint('[Checkout] Delivery charge updated: $charge');
      update(['checkout', 'total', 'delivery_charge']);
    }
  }

  // ⚡ OPTIMIZATION: Track last extra_charge call to prevent duplicate API calls
  double? _lastExtraChargeDistance;
  DateTime? _lastExtraChargeTime;
  static const Duration _extraChargeCacheTTL =
      Duration(minutes: 10); // Cache for 10 minutes

  String? _orderType = 'delivery';
  String? get orderType => _orderType;

  double _viewTotalPrice = 0;
  double? get viewTotalPrice => _viewTotalPrice;

  int _selectedOfflineBankIndex = 0;
  int get selectedOfflineBankIndex => _selectedOfflineBankIndex;

  int _selectedInstruction = -1;
  int get selectedInstruction => _selectedInstruction;

  bool _isDmTipSave = false;
  bool get isDmTipSave => _isDmTipSave;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  bool _canShowTipsField = false;
  bool get canShowTipsField => _canShowTipsField;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  bool _isExpand = false;
  bool get isExpand => _isExpand;

  // Payment
  // ===========================================================================================

  String? sessionId; // 🔹 تعريف sessionId كمتغير عام

  List<MFPaymentMethod> paymentMethods = [];

  List<bool> isSelected = [];
  MFPaymentMethod? select_payment_Methods;
  String _lastInvoiceId = '';

  String get lastInvoiceId => _lastInvoiceId;

  MFCardPaymentView? mfCardView;
  MFApplePayButton mfApplePayButton = MFApplePayButton();
  MFGooglePayButton mfGooglePayButton = const MFGooglePayButton();
  bool _isMyFatoorahSdkInitialized = false;

  int selectedButton = -1; //  تعني أنه لا يوجد زر مختار

  // Static payment method selection
  Map<String, dynamic>? _selectedStaticPaymentMethod;
  Map<String, dynamic>? get selectedStaticPaymentMethod =>
      _selectedStaticPaymentMethod;

  void setSelectedPaymentMethod(Map<String, dynamic> paymentMethod) {
    _selectedStaticPaymentMethod = paymentMethod;
    debugPrint("🎯 Static payment method set: ${paymentMethod['name']}");
    update();
  }

  // ------ تهيئة عملية الدفع بالكامل ------

  Future<void> initiate(BuildContext context) async {
    // Backend-driven MyFatoorah: SDK is disabled for checkout
    debugPrint('✅ MyFatoorah (checkout) uses backend-driven flow only');
  }

  Future<void> initiatePayment(BuildContext context) async {
    // Use backend endpoint instead of direct SDK call
    await _loadPaymentMethodsFromBackend(0.0, 'SAR');
  }

  Future<void> initiatePaymentWithAmount(
      BuildContext context, String amount) async {
    // Validate amount before processing
    final double parsedAmount = double.tryParse(amount) ?? 0.0;
    if (parsedAmount <= 0) {
      debugPrint('❌ Invalid payment amount: $amount - Must be greater than 0');
      showCustomSnackBar('pay_amount_invalid'.tr);
      return;
    }

    // Use backend endpoint instead of direct SDK call
    await _loadPaymentMethodsFromBackend(parsedAmount, 'SAR');
  }

  /// Load payment methods from backend endpoint
  /// This replaces direct MyFatoorah SDK calls for security
  Future<void> _loadPaymentMethodsFromBackend(
    double amount,
    String currency,
  ) async {
    try {
      debugPrint(
          '🔄 Loading payment methods from backend - Amount: $amount $currency');

      // Create service instance
      final apiClient = Get.find<ApiClient>();
      final repository = MyFatoorahRepository(apiClient: apiClient);
      final service = MyFatoorahService(repository: repository);

      // Call backend endpoint
      final Response response = await service.getPaymentMethods(
        amount: amount,
        currency: currency,
      );

      // ⚡ FIX: Handle 304 Not Modified - repository now returns cached data as 200
      // The repository handles 304 by returning cached data with statusCode 200
      // So we don't need special 304 handling here - just process as normal 200

      // Check response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            response.body as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          // Map backend response to MFPaymentMethod objects
          final List<dynamic> backendMethods =
              responseData['data'] as List<dynamic>;
          paymentMethods = MyFatoorahMapper.mapBackendResponseToPaymentMethods(
              backendMethods);
          isSelected = List.filled(paymentMethods.length, false);

          if (paymentMethods.isEmpty) {
            debugPrint(
                '⚠️ WARNING: Backend returned empty payment methods array for checkout');
            debugPrint('   Amount: $amount $currency');
            debugPrint('   Response: ${responseData.toString()}');
            debugPrint(
                '   Backend returned success=true but data array is empty');
            debugPrint(
                '   ⚠️ This may indicate a MyFatoorah API issue - check Laravel logs');
          } else {
            debugPrint(
                '✅ Loaded ${paymentMethods.length} payment methods from backend');
            _precachePaymentMethodImages();
          }
          update();
        } else {
          debugPrint(
              "❌ Backend response indicates failure: ${responseData['message']}");
          debugPrint('   Amount: $amount $currency');
          debugPrint('   Full response: ${responseData.toString()}');
          paymentMethods = [];
          isSelected = [];
          showCustomSnackBar((responseData['message'] as String?) ??
              'pay_load_methods_error2'.tr);
          update();
        }
      } else {
        // Only treat 4xx and 5xx as errors (304 is already handled above)
        debugPrint(
            '❌ Backend request failed with status: ${response.statusCode}');
        paymentMethods = [];
        isSelected = [];

        // Handle validation errors
        if (response.statusCode == 422) {
          final Map<String, dynamic>? errorData = response.body is Map
              ? response.body as Map<String, dynamic>
              : null;
          final String errorMessage =
              (errorData?['message'] as String?) ?? 'خطأ في البيانات المرسلة';
          showCustomSnackBar(errorMessage);
        } else {
          showCustomSnackBar('pay_load_methods_error2'.tr);
        }
        update();
      }
    } catch (e) {
      debugPrint('❌ Error loading payment methods from backend: $e');
      paymentMethods = [];
      isSelected = [];
      showCustomSnackBar('pay_load_methods_error2'.tr);
      update();
    }
  }

  /// Precache payment method images so they display instantly in the bottom sheet.
  /// Uses fire-and-forget downloads via DefaultCacheManager (same cache CachedNetworkImage uses).
  void _precachePaymentMethodImages() {
    final cacheManager = DefaultCacheManager();
    const headers = {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    };
    for (final method in paymentMethods) {
      final url = method.imageUrl;
      if (url != null && url.isNotEmpty && url.startsWith('http')) {
        cacheManager.downloadFile(url, authHeaders: headers).then((_) {
          debugPrint('📦 Precached payment icon: ${method.paymentMethodEn}');
        }).catchError((e) {
          // Ignore precaching errors - images will load on demand
        });
      }
    }
  }

  Future<bool> Pay(BuildContext context, String amount,
      {String? contactNumber}) async {
    debugPrint('Opening MyFatoorah payment (backend-driven) - Amount: $amount');
    debugPrint(
        '[Pay][Start] orderId=$_currentOrderId inProgress=$_isPaymentInProgress isOrderPaid=$_isOrderPaid selectedMethod=${select_payment_Methods?.paymentMethodAr} methodId=${select_payment_Methods?.paymentMethodId}');

    // CRITICAL: Prevent double payment attempts
    if (_isPaymentInProgress) {
      debugPrint('?? Payment already in progress - preventing double payment');
      showCustomSnackBar('pay_in_progress'.tr);
      return false;
    }

    // CRITICAL: Check if order is already paid
    if (_currentOrderId != null && _isOrderPaid) {
      debugPrint(
          '?? Order $_currentOrderId is already paid - preventing double payment');
      showCustomSnackBar('pay_prepaid'.tr);
      return false;
    }

    final int? orderId = _currentOrderId;
    if (orderId == null) {
      showCustomSnackBar('pay_no_order'.tr);
      return false;
    }

    // Validate amount before processing
    final double parsedAmount = double.tryParse(amount) ?? 0.0;
    if (parsedAmount <= 0) {
      debugPrint('? Invalid payment amount: $amount - Must be greater than 0');
      showCustomSnackBar('pay_amount_invalid'.tr);
      return false;
    }

    // Set payment in progress flag
    _isPaymentInProgress = true;

    // Ensure payment methods are loaded from backend
    if (paymentMethods.isEmpty) {
      await initiatePaymentWithAmount(context, amount);
      debugPrint(
          '[Pay][InitMethods] loadedCount=${paymentMethods.length} amount=$parsedAmount');
    }

    if (paymentMethods.isEmpty) {
      debugPrint('? No payment methods available after initiation');
      showCustomSnackBar('pay_no_methods2'.tr);
      _isPaymentInProgress = false;
      return false;
    }

    if (select_payment_Methods == null ||
        select_payment_Methods!.paymentMethodId == null) {
      debugPrint('? No payment method selected!');
      showCustomSnackBar('pay_please_choose'.tr);
      _isPaymentInProgress = false;
      return false;
    }

    final int paymentMethodId = select_payment_Methods!.paymentMethodId!;
    debugPrint(
        '?? Using selected payment method ID: $paymentMethodId (${select_payment_Methods!.paymentMethodAr})');

    // ── Native Apple Pay (PassKit) ───────────────────────────────────────────
    // When the chosen method is Apple Pay on iOS and the feature is enabled,
    // open the SYSTEM Apple Pay sheet instead of the hosted MyFatoorah WebView.
    // On confirmed success we verify with the server (which updates the order)
    // and finish; otherwise we fall through to the hosted flow as a safety net.
    final String selEn =
        (select_payment_Methods!.paymentMethodEn ?? '').toLowerCase();
    final String selCode =
        (select_payment_Methods!.paymentMethodCode ?? '').toLowerCase();
    final bool isApplePay = selEn.contains('apple') || selCode == 'ap';
    if (isApplePay && (!kIsWeb && Platform.isIOS) && AppConstants.applePayNativeEnabled) {
      final bool nativeOk =
          await processNativeApplePay(amount, customerReference: orderId.toString());
      if (nativeOk) {
        final MyFatoorahPaymentResult res = _lastInvoiceId.isNotEmpty
            ? await _checkMyFatoorahStatus(_lastInvoiceId)
            : MyFatoorahPaymentResult.paid;
        if (res == MyFatoorahPaymentResult.paid) {
          _isPaymentInProgress = false;
          _isOrderPaid = true;
          await clearPendingPaymentContext(reason: 'apple_pay_native');
          return true;
        }
        // Not confirmed yet → continue to the hosted flow below.
      }
      debugPrint('[ApplePay][native] unavailable/declined → hosted WebView flow');
    }

    // ── Embedded (in-app) card payment ───────────────────────────────────────
    // For card methods (not Apple/Google/STC), pay via MyFatoorah's EMBEDDED
    // card form INSIDE the app instead of redirecting to the hosted WebView.
    // Any failure/cancel falls through to the hosted flow below.
    final bool isCardMethod = !isApplePay &&
        !selEn.contains('google') &&
        !selCode.contains('gp') &&
        !selEn.contains('stc') &&
        !selCode.contains('stc');
    if (AppConstants.inAppCardPaymentEnabled && isCardMethod) {
      final bool cardOk =
          await payWithEmbeddedCard(amount, customerReference: orderId.toString());
      if (cardOk) {
        _isPaymentInProgress = false;
        _isOrderPaid = true;
        await clearPendingPaymentContext(reason: 'embedded_card');
        return true;
      }
      debugPrint('[MF][embedded] card unavailable/declined → hosted WebView flow');
    }

    try {
      final apiClient = Get.find<ApiClient>();
      final repository = MyFatoorahRepository(apiClient: apiClient);
      final service = MyFatoorahService(repository: repository);

      final profileController = Get.find<ProfileController>();
      final String customerName = profileController.userInfoModel?.fName
                  ?.trim()
                  .isNotEmpty ==
              true
          ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'
              .trim()
          : ((profileController.userInfoModel?.lName ?? '').trim().isNotEmpty
              ? (profileController.userInfoModel?.lName ?? '').trim()
              : 'Customer');
      final String customerPhone = (contactNumber != null &&
              contactNumber.trim().isNotEmpty)
          ? contactNumber.trim()
          : (profileController.userInfoModel?.phone?.trim().isNotEmpty == true
              ? profileController.userInfoModel!.phone!.trim()
              : '');
      final String customerEmail =
          profileController.userInfoModel?.email?.trim().isNotEmpty == true
              ? profileController.userInfoModel!.email!.trim()
              : 'no-reply@shelafood.com';
      debugPrint(
          '[Pay][Customer] name="$customerName" phone="$customerPhone" email="$customerEmail"');

      if (customerPhone.isEmpty) {
        _isPaymentInProgress = false;
        showCustomSnackBar('pay_phone_required'.tr);
        return false;
      }

      final Response response = await service.processPayment(
        orderId: orderId,
        amount: parsedAmount,
        currency: 'SAR',
        paymentMethodId: paymentMethodId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );
      debugPrint(
          '[Pay][ProcessPayment] status=${response.statusCode} statusText=${response.statusText}');
      if (response.body is Map) {
        final Map<String, dynamic> m = response.body as Map<String, dynamic>;
        debugPrint(
            '[Pay][ProcessPayment] bodyKeys=${m.keys.toList()} success=${m['success']} message=${m['message']}');
      } else {
        debugPrint(
            '[Pay][ProcessPayment] nonMapBodyType=${response.body.runtimeType}');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
            '? MyFatoorah process failed: ${response.statusCode} ${response.statusText}');
        _isPaymentInProgress = false;
        showCustomSnackBar('pay_start_failed_data'.tr);
        return false;
      }

      final Map<String, dynamic> body = response.body is Map<String, dynamic>
          ? response.body as Map<String, dynamic>
          : <String, dynamic>{};
      final dynamic data = body['data'];
      final String? paymentUrl =
          data is Map<String, dynamic> ? data['payment_url']?.toString() : null;
      // Capture the MyFatoorah invoice id so we can verify the payment via the
      // dedicated check-status endpoint (key_type=InvoiceId) after the WebView
      // returns — instead of polling trackOrder many times.
      final String? invoiceId = data is Map<String, dynamic>
          ? (data['invoice_id'] ??
                  data['InvoiceId'] ??
                  data['invoiceId'] ??
                  body['invoice_id'] ??
                  body['InvoiceId'])
              ?.toString()
          : (body['invoice_id'] ?? body['InvoiceId'])?.toString();
      debugPrint(
          '[Pay][PaymentUrl] hasUrl=${paymentUrl != null && paymentUrl.isNotEmpty} url=${paymentUrl ?? ''} invoiceId=${invoiceId ?? ''}');

      if (paymentUrl == null || paymentUrl.isEmpty) {
        debugPrint('? MyFatoorah process returned no payment_url');
        _isPaymentInProgress = false;
        showCustomSnackBar('pay_start_failed_link'.tr);
        return false;
      }

      final String successUrl =
          '${AppConstants.baseUrl}/api/v1/payment/myfatoorah/success';
      final String errorUrl =
          '${AppConstants.baseUrl}/api/v1/payment/myfatoorah/error';

      // ✅ LOADING FIX: Stop the checkout button loader BEFORE opening the
      // MyFatoorah webview. Otherwise the spinner sits stuck under the webview
      // and stays active across the whole payment + confirmation window.
      debugPrint('[Pay][PaymentUrl] payment_url found — preparing to open MyFatoorah');
      _isLoading = false;
      update(['payment']);
      debugPrint('[Pay][Loading] loading OFF before navigating to MyFatoorah');
      debugPrint('[Pay][Navigate] navigating to MyFatoorah webview');

      // 💾 Persist a NON-sensitive recovery context BEFORE opening the WebView,
      // so a kill / background / network drop / back-out can be re-verified
      // later instead of being treated as a lost or failed order.
      await storePendingPaymentContext(
        orderId: orderId,
        invoiceId: invoiceId,
        paymentMethod: 'digital_payment',
      );

      final String? webResult = await Get.to(
        () => MyFatoorahPaymentWebViewScreen(
          initialUrl: paymentUrl,
          successUrlContains: successUrl,
          errorUrlContains: errorUrl,
        ),
      );

      debugPrint('[Pay][Return] payment screen returned result=$webResult');

      // Show a short "checking payment" loader ONLY while we call check-status.
      // It is cleared below in every path, so it can never become a stuck overlay.
      _isLoading = true;
      update(['payment']);

      // ✅ Verify with the backend check-status endpoint (single call) instead
      // of polling trackOrder up to 30 times. Fall back to a short trackOrder
      // check only if the gateway invoice id is unavailable.
      MyFatoorahPaymentResult result;
      if (invoiceId != null && invoiceId.isNotEmpty) {
        result = await _checkMyFatoorahStatus(invoiceId);
      } else {
        debugPrint(
            '[Pay][CheckStatus] no invoice_id available — falling back to limited trackOrder check');
        final bool confirmed = await _confirmMyFatoorahPayment(
          orderId,
          contactNumber: contactNumber,
        );
        result = confirmed
            ? MyFatoorahPaymentResult.paid
            : MyFatoorahPaymentResult.pending;
      }
      debugPrint(
          '[Pay][CheckStatus] result=$result webResult=$webResult orderId=$orderId');

      _isPaymentInProgress = false;
      // ✅ Always clear the checking loader so returning from MyFatoorah never
      // leaves the screen stuck on a spinner.
      _isLoading = false;
      update(['payment']);

      switch (result) {
        case MyFatoorahPaymentResult.paid:
          _isOrderPaid = true;
          // Confirmed paid — recovery context is no longer needed.
          await clearPendingPaymentContext(reason: 'paid_in_flow');
          return true;
        case MyFatoorahPaymentResult.pending:
          // Payment not completed yet — keep order hidden as payment_pending and
          // let the user retry. KEEP the recovery context so a later app
          // resume / checkout re-open can re-verify the real status.
          _isOrderPaid = false;
          _digitalFailureMessage =
              'pay_not_complete_orders'.tr;
          // If the user explicitly chose "go to my orders" from the back
          // dialog, take them there.
          if (webResult == 'go_to_orders') {
            Get.toNamed(RouteHelper.getOrderRoute());
          }
          return false;
        case MyFatoorahPaymentResult.failed:
          _isOrderPaid = false;
          // Show the gateway's real reason (e.g. card declined) when available.
          _digitalFailureMessage =
              (_lastGatewayFailureReason?.trim().isNotEmpty ?? false)
                  ? _lastGatewayFailureReason!.trim()
                  : 'pay_failed_cancelled'.tr;
          _lastGatewayFailureReason = null;
          await clearPendingPaymentContext(reason: 'failed_in_flow');
          return false;
      }
    } catch (error) {
      debugPrint('? MyFatoorah payment error: $error');
      debugPrint('[Pay][Exception] type=${error.runtimeType}');
      _isPaymentInProgress = false;
      return false;
    }
  }

  /// Verify a MyFatoorah payment via the backend check-status endpoint.
  ///
  /// Single call — no 30× polling. Maps the response to a [MyFatoorahPaymentResult]:
  ///  • paid      → order.payment_status == 'paid' (and order_status confirmed)
  ///  • pending   → data.InvoiceStatus Pending / transaction InProgress, or the
  ///                order is still unpaid / payment_pending (NOT a failure)
  ///  • failed    → anything else (failed / cancelled / HTTP error)
  Future<MyFatoorahPaymentResult> _checkMyFatoorahStatus(
    String invoiceId,
  ) async {
    try {
      final apiClient = Get.find<ApiClient>();
      final repository = MyFatoorahRepository(apiClient: apiClient);
      final service = MyFatoorahService(repository: repository);

      final Response response = await service.checkStatus(
        key: invoiceId,
        keyType: 'InvoiceId',
      );
      debugPrint(
          '[Pay][CheckStatus] status=${response.statusCode} body=${response.body}');

      final Map<String, dynamic> body = response.body is Map<String, dynamic>
          ? response.body as Map<String, dynamic>
          : <String, dynamic>{};
      final dynamic data = body['data'];
      final dynamic order = body['order'];

      final String invoiceStatus = (data is Map<String, dynamic>
              ? (data['InvoiceStatus'] ??
                  data['TransactionStatus'] ??
                  data['transaction_status'] ??
                  '')
              : '')
          .toString()
          .toLowerCase();
      final String paymentStatus = (order is Map<String, dynamic>
              ? (order['payment_status'] ?? '')
              : (body['payment_status'] ?? ''))
          .toString()
          .toLowerCase();
      final String orderStatus = (order is Map<String, dynamic>
              ? (order['order_status'] ?? '')
              : (body['order_status'] ?? ''))
          .toString()
          .toLowerCase();

      debugPrint(
          '[Pay][CheckStatus] invoiceStatus="$invoiceStatus" payment_status="$paymentStatus" order_status="$orderStatus"');

      // 1) Real gateway confirmation → success (money captured).
      if (paymentStatus == 'paid' || paymentStatus == 'partially_paid') {
        return MyFatoorahPaymentResult.paid;
      }

      // 2) Not completed yet — Pending / InProgress / still unpaid. Do NOT poll;
      // keep the order hidden as payment_pending and let the user retry.
      if (invoiceStatus == 'pending' ||
          invoiceStatus == 'inprogress' ||
          invoiceStatus == 'in progress' ||
          paymentStatus == 'unpaid' ||
          orderStatus == 'payment_pending') {
        return MyFatoorahPaymentResult.pending;
      }

      // 3) Anything else → failed / cancelled. Capture the gateway's reason so
      // the user sees WHY (e.g. card declined) rather than a generic message.
      _lastGatewayFailureReason = _extractGatewayFailureReason(body, data);
      return MyFatoorahPaymentResult.failed;
    } catch (e) {
      debugPrint('[Pay][CheckStatus] exception: $e');
      // Treat as pending (not a hard failure) so the user can simply retry and
      // we never wrongly mark an unconfirmed order as failed.
      return MyFatoorahPaymentResult.pending;
    }
  }

  Future<bool> _confirmMyFatoorahPayment(
    int orderId, {
    String? contactNumber,
  }) async {
    final OrderController orderController = Get.find<OrderController>();
    // Fallback only (no gateway invoice id). Kept short — NOT a 30× poll.
    const int maxTries = 5;

    for (int i = 0; i < maxTries; i++) {
      debugPrint('[Pay][Confirm] try=${i + 1}/$maxTries orderId=$orderId');
      await orderController.trackOrder(
        orderId.toString(),
        null,
        false,
        contactNumber: contactNumber,
        preserveTrackModel: true,
      );

      final String paymentStatus =
          orderController.trackModel?.paymentStatus?.toLowerCase() ?? '';
      final String orderStatus =
          orderController.trackModel?.orderStatus?.toLowerCase() ?? '';
      debugPrint(
          '[Pay][Confirm] paymentStatus="$paymentStatus" orderStatus="$orderStatus"');

      if (paymentStatus == 'paid' || paymentStatus == 'partially_paid') {
        return true;
      }

      if (paymentStatus == 'failed' ||
          paymentStatus == 'canceled' ||
          paymentStatus == 'cancelled' ||
          orderStatus == 'failed' ||
          orderStatus == 'canceled' ||
          orderStatus == 'cancelled') {
        return false;
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    debugPrint('[Pay][Confirm] timeout after $maxTries tries orderId=$orderId');
    return false;
  }

  // IN-APP PAYMENT PROCESSING METHODS

  // ==========================================================================================================

  String _mfReadableErrorMessage(Object error) {
    final List<String?> candidates = <String?>[
      _safeDynamicField(error, 'message'),
      _safeDynamicField(error, 'errorMessage'),
      _safeDynamicField(error, 'reason'),
      _safeDynamicField(error, 'details'),
      _safeDynamicField(error, 'statusMessage'),
      error.toString(),
    ];
    for (final String? candidate in candidates) {
      final String value = (candidate ?? '').trim();
      if (value.isNotEmpty && value != "Instance of 'MFError'") {
        return value;
      }
    }
    return error.toString();
  }

  String _safeDynamicField(Object error, String fieldName) {
    final dynamic e = error;
    try {
      switch (fieldName) {
        case 'message':
          return e.message?.toString() ?? '';
        case 'errorMessage':
          return e.errorMessage?.toString() ?? '';
        case 'reason':
          return e.reason?.toString() ?? '';
        case 'details':
          return e.details?.toString() ?? '';
        case 'statusMessage':
          return e.statusMessage?.toString() ?? '';
        case 'code':
          return e.code?.toString() ?? '';
        case 'statusCode':
          return e.statusCode?.toString() ?? '';
        case 'response':
          return e.response?.toString() ?? '';
        default:
          return '';
      }
    } catch (_) {
      return '';
    }
  }

  void _logMyFatoorahError({
    required String stage,
    required Object error,
    required StackTrace stackTrace,
    MFPaymentMethod? method,
    String? amount,
  }) {
    final String methodName =
        method?.paymentMethodEn ?? method?.paymentMethodAr ?? 'unknown';
    final dynamic methodId = method?.paymentMethodId;

    final List<String> details = <String>[
      'type=${error.runtimeType}',
      'raw=${error.toString()}',
      'message=${_safeDynamicField(error, 'message')}',
      'errorMessage=${_safeDynamicField(error, 'errorMessage')}',
      'statusMessage=${_safeDynamicField(error, 'statusMessage')}',
      'code=${_safeDynamicField(error, 'code')}',
      'statusCode=${_safeDynamicField(error, 'statusCode')}',
      'reason=${_safeDynamicField(error, 'reason')}',
      'details=${_safeDynamicField(error, 'details')}',
      'response=${_safeDynamicField(error, 'response')}',
      'stage=$stage',
      'method=$methodName',
      'methodId=$methodId',
      'amount=${amount ?? ''}',
    ];

    final String shortStack =
        stackTrace.toString().split('\n').take(5).join(' | ');

    debugPrint(
        '\x1B[31m[MyFatoorah][ERROR] ${details.join(' ; ')} ; stack=$shortStack\x1B[0m');
  }

  Future<bool> _ensureMyFatoorahSdkInitialized() async {
    if (_isMyFatoorahSdkInitialized) {
      return true;
    }
    try {
      final String token = AppConstants.useMyFatoorahTestMode
          ? AppConstants.myFatoorahTestToken
          : AppConstants.myFatoorahLiveToken;

      if (token.isEmpty) {
        debugPrint(
            '\x1B[31m[MyFatoorah][ERROR] SDK token is empty. Check AppConstants.setMyFatoorahTokens() and env config.\x1B[0m');
        return false;
      }

      await MFSDK.init(
        token,
        MFCountry.SAUDIARABIA,
        AppConstants.useMyFatoorahTestMode
            ? MFEnvironment.TEST
            : MFEnvironment.LIVE,
      );
      _isMyFatoorahSdkInitialized = true;
      debugPrint('[MyFatoorah] SDK initialized for direct executePayment flow');
      return true;
    } catch (e, st) {
      debugPrint(
          '\x1B[31m[MyFatoorah][ERROR] SDK init failed: $e ; stack=${st.toString().split('\n').take(4).join(' | ')}\x1B[0m');
      return false;
    }
  }

  /// Process digital wallet payments (Apple Pay, Google Pay)
  /// This method handles payments that don't require card details
  Future<bool> processDigitalWalletPayment(
      MFPaymentMethod paymentMethod, String amount) async {
    try {
      // Apple Pay → try the NATIVE PassKit sheet first (no WebView). Returns
      // false instantly when off/unsupported, so we transparently fall back to
      // the hosted flow below. (Feature-flagged: AppConstants.applePayNativeEnabled.)
      final String mEn = (paymentMethod.paymentMethodEn ?? '').toLowerCase();
      final String mCode = (paymentMethod.paymentMethodCode ?? '').toLowerCase();
      final bool isApplePay = mEn.contains('apple') || mCode == 'ap';
      if (isApplePay) {
        final bool nativeOk = await processNativeApplePay(
          amount,
          customerReference: _currentOrderId?.toString(),
        );
        if (nativeOk) return true;
      }

      final bool sdkReady = await _ensureMyFatoorahSdkInitialized();
      if (!sdkReady) {
        showCustomSnackBar('pay_init_failed_key'.tr);
        return false;
      }

      debugPrint(
          'Processing digital wallet payment: ${paymentMethod.paymentMethodEn}');

      final request = MFExecutePaymentRequest(
        paymentMethodId: paymentMethod.paymentMethodId!,
        invoiceValue: double.tryParse(amount) ?? 0.0,
      );

      bool paymentSuccess = false;

      await MFSDK.executePayment(request, MFLanguage.ARABIC, (invoiceId) {
        debugPrint('Digital wallet payment response - Invoice ID: $invoiceId');

        if (invoiceId.isNotEmpty) {
          debugPrint(
              'Digital wallet payment successful. Invoice ID: $invoiceId');
          _lastInvoiceId = invoiceId;
          paymentSuccess = true;
          showCustomSnackBar('pay_process_success'.tr, isError: false);
          update();
        } else {
          debugPrint('No invoice ID received for digital wallet payment.');
          showCustomSnackBar('pay_no_invoice'.tr);
        }
      });

      return paymentSuccess;
    } catch (error, stackTrace) {
      _logMyFatoorahError(
        stage: 'processDigitalWalletPayment',
        error: error,
        stackTrace: stackTrace,
        method: paymentMethod,
        amount: amount,
      );
      showCustomSnackBar('فشلت عملية الدفع: ${_mfReadableErrorMessage(error)}');
      return false;
    }
  }

  /// Native Apple Pay (PassKit) — opens the system Apple Pay sheet directly
  /// (NOT the MyFatoorah WebView) and executes the payment via the MyFatoorah
  /// Apple Pay SDK. The amount must already be the SERVER-approved total
  /// (see the totals guard / order-derived amount, rule #3).
  ///
  /// Requires: iOS, Apple Pay capability + merchant id in entitlements, and the
  /// merchant id activated in the MyFatoorah dashboard. Returns false when not
  /// available so the caller can fall back to the WebView flow.
  Future<bool> processNativeApplePay(String amount,
      {String? customerReference}) async {
    if (!(!kIsWeb && Platform.isIOS) || !AppConstants.applePayNativeEnabled) {
      return false; // caller falls back to the WebView flow
    }
    try {
      final bool sdkReady = await _ensureMyFatoorahSdkInitialized();
      if (!sdkReady) return false;

      final double value = double.tryParse(amount) ?? 0.0;
      if (value <= 0) return false;

      // 1) Session for the embedded Apple Pay flow.
      final MFInitiateSessionResponse session =
          await MFSDK.initiateSession(MFInitiateSessionRequest(), null);

      // 2) Build the request — SAR, server-approved amount, order reference.
      final MFExecutePaymentRequest request = MFExecutePaymentRequest(
        invoiceValue: value,
        displayCurrencyIso: 'SAR',
        customerReference: customerReference,
      );

      // 3) Configure the native sheet with the merchant name "shella".
      final bool setup = await MFApplepay.setupApplePay(
        session,
        request,
        MFLanguage.ARABIC,
        merchantName: AppConstants.applePayMerchantName,
      );
      if (!setup) {
        debugPrint('[ApplePay][native] setup failed → fallback to WebView');
        return false;
      }

      // 4) Present the system Apple Pay sheet (Face ID / side button confirm).
      final MFCallbackResponse sheet = await MFApplepay.openPaymentSheet();
      debugPrint('[ApplePay][native] sheet response=${sheet.toJson()}');

      // 5) Execute via MyFatoorah and read the resulting invoice status.
      final MFGetPaymentStatusResponse status =
          await MFApplepay.executeApplePayPayment(
        request: request,
        onInvoiceCreated: (invoiceId) {
          if (invoiceId.isNotEmpty) _lastInvoiceId = invoiceId;
        },
      );
      if ((status.invoiceId ?? 0) != 0) {
        _lastInvoiceId = status.invoiceId.toString();
      }
      final String st = (status.invoiceStatus ?? '').toLowerCase();
      final bool paid = st == 'paid' || st == 'success';
      debugPrint(
          '[ApplePay][native] status=$st invoiceId=${status.invoiceId} paid=$paid');
      return paid;
    } catch (e, stackTrace) {
      _logMyFatoorahError(
        stage: 'processNativeApplePay',
        error: e,
        stackTrace: stackTrace,
        method: null,
        amount: amount,
      );
      // Any failure → let the caller fall back to the WebView flow.
      return false;
    }
  }

  /// Embedded (in-app) card payment — opens MyFatoorah's PCI card form INSIDE
  /// the app (no WebView redirect) and charges it; the card is tokenized/saved
  /// in MyFatoorah. Verifies the result with the server before returning true.
  /// Returns false (→ caller falls back to the hosted flow) when disabled,
  /// the SDK isn't ready, the sheet is cancelled, or the charge isn't confirmed.
  Future<bool> payWithEmbeddedCard(String amount,
      {String? customerReference}) async {
    if (!AppConstants.inAppCardPaymentEnabled) return false;
    try {
      final bool sdkReady = await _ensureMyFatoorahSdkInitialized();
      if (!sdkReady) return false;
      final double value = double.tryParse(amount) ?? 0.0;
      if (value <= 0) return false;

      final String? invoiceId = await Get.bottomSheet<String?>(
        MFEmbeddedCardSheet(amount: value, customerReference: customerReference),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
      if (invoiceId == null || invoiceId.isEmpty) return false;

      _lastInvoiceId = invoiceId;
      // Server-side confirmation (also updates the order).
      final MyFatoorahPaymentResult res =
          await _checkMyFatoorahStatus(invoiceId);
      return res == MyFatoorahPaymentResult.paid;
    } catch (e, st) {
      _logMyFatoorahError(
        stage: 'payWithEmbeddedCard',
        error: e,
        stackTrace: st,
        method: null,
        amount: amount,
      );
      return false;
    }
  }

  /// Process direct card payments
  /// This method handles card payments with the collected card information
  Future<bool> processDirectPayment(MFPaymentMethod paymentMethod,
      String amount, Map<String, String> cardData) async {
    try {
      final bool sdkReady = await _ensureMyFatoorahSdkInitialized();
      if (!sdkReady) {
        showCustomSnackBar('pay_init_failed_key'.tr);
        return false;
      }

      debugPrint(
          'Processing direct card payment: ${paymentMethod.paymentMethodEn}');
      debugPrint(
          "Card details - Number: ${cardData['cardNumber']}, Expiry: ${cardData['expiryMonth']}/${cardData['expiryYear']}");

      // For now, use the existing executePayment method
      // This will be updated when direct payment API is properly configured
      final request = MFExecutePaymentRequest(
        paymentMethodId: paymentMethod.paymentMethodId!,
        invoiceValue: double.tryParse(amount) ?? 0.0,
      );

      bool paymentSuccess = false;

      await MFSDK.executePayment(request, MFLanguage.ARABIC, (invoiceId) {
        debugPrint('Card payment response - Invoice ID: $invoiceId');

        if (invoiceId.isNotEmpty) {
          debugPrint('Card payment successful. Invoice ID: $invoiceId');
          _lastInvoiceId = invoiceId;
          paymentSuccess = true;
          showCustomSnackBar('pay_process_success'.tr, isError: false);
          update();
        } else {
          debugPrint('No invoice ID received for card payment.');
          showCustomSnackBar('pay_no_invoice'.tr);
        }
      });

      return paymentSuccess;
    } catch (error, stackTrace) {
      _logMyFatoorahError(
        stage: 'processDirectPayment',
        error: error,
        stackTrace: stackTrace,
        method: paymentMethod,
        amount: amount,
      );
      showCustomSnackBar('فشلت عملية الدفع: ${_mfReadableErrorMessage(error)}');
      return false;
    }
  }

  /// Show in-app payment modal
  /// This method displays the elegant in-app payment modal
  Future<void> showInAppPaymentModal(
    BuildContext context,
    double amount, {
    Function(String invoiceId)? onPaymentSuccess,
    Function(String error)? onPaymentError,
    VoidCallback? onCancel,
  }) async {
    try {
      // Ensure payment methods are loaded
      if (paymentMethods.isEmpty) {
        await initiatePayment(context);
      }

      // Show the in-app payment modal
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder: (context) => InAppPaymentModal(
          amount: amount,
          onPaymentSuccess: onPaymentSuccess,
          onPaymentError: onPaymentError,
          onCancel: onCancel,
        ),
      );
    } catch (error) {
      debugPrint('Error showing in-app payment modal: $error');
      showCustomSnackBar('خطأ في عرض نافذة الدفع: ${error.toString()}');
    }
  }

  /// Validate card information before processing
  bool validateCardInfo(Map<String, String> cardData) {
    // Validate card number (basic check)
    final cardNumber = cardData['cardNumber'] ?? '';
    if (cardNumber.isEmpty || cardNumber.replaceAll(' ', '').length < 13) {
      return false;
    }

    // Validate expiry month
    final expiryMonth = cardData['expiryMonth'] ?? '';
    final month = int.tryParse(expiryMonth);
    if (month == null || month < 1 || month > 12) {
      return false;
    }

    // Validate expiry year
    final expiryYear = cardData['expiryYear'] ?? '';
    final year = int.tryParse(expiryYear);
    if (year == null || year < DateTime.now().year % 100) {
      return false;
    }

    // Validate CVV
    final cvv = cardData['cvv'] ?? '';
    if (cvv.isEmpty || cvv.length < 3 || cvv.length > 4) {
      return false;
    }

    return true;
  }

  /// Get payment method by name
  MFPaymentMethod? getPaymentMethodByName(String name) {
    try {
      return paymentMethods.firstWhere(
        (method) =>
            method.paymentMethodEn
                ?.toLowerCase()
                .contains(name.toLowerCase()) ??
            false,
      );
    } catch (e) {
      debugPrint('Payment method not found: $name');
      return null;
    }
  }

  /// Check if payment method is digital wallet
  bool isDigitalWalletPayment(MFPaymentMethod paymentMethod) {
    final name = paymentMethod.paymentMethodEn?.toLowerCase() ?? '';
    return name.contains('apple') ||
        name.contains('google') ||
        name.contains('pay') ||
        name.contains('wallet');
  }

  /// Check if payment method requires card details
  bool requiresCardDetails(MFPaymentMethod paymentMethod) {
    return !isDigitalWalletPayment(paymentMethod);
  }

  // ==========================================================================================================

  // ============================================================================
  // ✅ NEW: Initialize checkout data with optional preloaded data from cart
  // ============================================================================

  /// Initialize checkout data with optional preloaded data from cart
  ///
  /// This method loads all data needed for checkout:
  /// - Store details
  /// - Cart items (or uses preloaded)
  /// - Delivery distance (or uses pre-calculated)
  /// - Address and payment methods
  ///
  /// ✅ KEY: Only marks isDeliveryChargeReady = true AFTER data loads
  /// ✅ KEY: Accepts preloaded data to avoid duplicate calculations
  /// ✅ KEY: Sets state flag AFTER loading, not before
  Future<void> initCheckoutData(
    BuildContext context,
    int storeId, {
    List<CartModel>? preloadedCartList,
    double? preCalculatedDistance,
  }) async {
    try {
      _hasCheckoutError = false;
      debugPrint('📦 [Checkout] Initializing checkout data...');

      // 1. Check if we already have a valid distance in the controller state
      bool hasExistingDistance = _distance != null && _distance! > 0;

      // 2. Determine the effective distance (Argument > Existing State)
      double? effectiveDistance =
          preCalculatedDistance ?? (hasExistingDistance ? _distance : null);

      // ✅ FIX: Only reset ready state if we truly don't have distance data
      if (preloadedCartList == null && effectiveDistance == null) {
        debugPrint(
            '📦 [Checkout] Fresh start (No distance) - resetting delivery charge state');
        _setDeliveryChargeReady(false, notify: false);
      } else {
        debugPrint(
            '📦 [Checkout] Data available (Dist: $effectiveDistance) - keeping state');
      }

      // Step 1: Load store details
      final storeController = Get.find<StoreController>();
      if (storeController.store == null ||
          storeController.store!.id != storeId) {
        await storeController.getStoreDetails(
          context,
          Store(id: storeId),
          false,
          fromCart: true,
        );
      }
      _store = storeController.store;
      await _hydrateStoreAddressFromStoreSummary(storeId);

      // Step 2: Initialize time slots
      if (_store != null) {
        await initializeTimeSlot(_store!);
      }

      // Step 3: Handle Distance & Delivery Charge
      if (effectiveDistance != null && effectiveDistance > 0) {
        _distance = effectiveDistance;
        debugPrint('✅ [Checkout] Using effective distance: ${_distance}km');

        // Force calculation immediately
        await _getExtraCharge(_distance);

        // ✅ CRITICAL: Force ready state to TRUE and ALWAYS notify UI
        // forceNotify ensures UI updates even if already true (fixes race condition)
        _setDeliveryChargeReady(true, notify: true, forceNotify: true);
      } else {
        debugPrint(
            '📏 [Checkout] No distance found, waiting for map calculation');
      }

      // ✅ FINAL: Update UI
      _isCheckoutReady = true;
      update();
    } catch (e) {
      debugPrint('❌ [Checkout] Error in initCheckoutData: $e');
      _hasCheckoutError = true;
      _isCheckoutReady = false;
      update();
    }
  }

  /// ✅ NEW: Debug checkout state for troubleshooting
  void debugCheckoutState(String tag) {
    if (!kDebugMode) return;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📦 CHECKOUT STATE [$tag]');
    debugPrint('   isDeliveryChargeReady: $isDeliveryChargeReady');
    debugPrint('   isCheckoutReady: $isCheckoutReady');
    debugPrint('   distance: $_distance km');
    debugPrint('   preCalculatedDistance: $preCalculatedDistance km');
    debugPrint('   store: ${_store?.name}');
    debugPrint('   extraCharge: $_extraCharge');
    debugPrint('═══════════════════════════════════════════════════════');
  }

  /// ✅ NEW: Validate checkout state for debugging
  bool validateCheckoutState() {
    bool isValid = true;

    if (_store == null) {
      debugPrint('⚠️ [Checkout] Store not loaded');
      isValid = false;
    }

    if (_distance == null &&
        isDeliveryChargeReady &&
        orderType != 'take_away') {
      debugPrint(
          '⚠️ [Checkout] Distance is null but delivery charge marked ready');
      isValid = false;
    }

    if (_distance != null && _distance! <= 0 && orderType != 'take_away') {
      debugPrint('⚠️ [Checkout] Invalid distance value: $_distance');
      isValid = false;
    }

    if (isValid) {
      debugPrint('✅ [Checkout] State validation passed');
    }

    return isValid;
  }

  void showTipsField() {
    _canShowTipsField = !_canShowTipsField;
    update();
  }

  Future<void> addTips(double tips) async {
    _tips = tips;
    update();
  }

  void expandedUpdate(bool status) {
    _isExpanded = status;
    update();
  }

  void setPaymentMethod(int index, {bool isUpdate = true}) {
    if (kDebugMode) {
      debugPrint(
        '[PaymentMethod][SET] before paymentMethodIndex=$_paymentMethodIndex '
        'selectedButton=$selectedButton indexArg=$index',
      );
    }
    _paymentMethodIndex = index;

    // Keep payment card UI state in sync with the business payment state.
    if (index == 0) {
      selectedButton = 0;
      select_payment_Methods = null;
      if (isSelected.isNotEmpty) {
        isSelected = List<bool>.filled(isSelected.length, false);
      }
    } else if (index == 1) {
      selectedButton = 2;
      select_payment_Methods = null;
      if (isSelected.isNotEmpty) {
        isSelected = List<bool>.filled(isSelected.length, false);
      }
    } else if (index == 2) {
      selectedButton = 1;
    } else {
      selectedButton = -1;
      select_payment_Methods = null;
      if (isSelected.isNotEmpty) {
        isSelected = List<bool>.filled(isSelected.length, false);
      }
    }

    // ✅ Fix: إعادة تعيين paymentFlowState عند تغيير طريقة الدفع
    // هذا يسمح للمستخدم بالمحاولة مرة أخرى بعد فشل سابق
    if (_paymentFlowState == PaymentFlowState.failed) {
      resetPaymentState();
    }

    if (isUpdate) {
      // GetBuilder(id: 'payment' | 'checkout') only listens to update([id]); bare update() skips them.
      update(['payment', 'checkout']);
    }
    if (kDebugMode) {
      debugPrint(
        '[PaymentMethod][SET] after paymentMethodIndex=$_paymentMethodIndex '
        'selectedButton=$selectedButton digital=${select_payment_Methods?.paymentMethodEn}',
      );
      debugPrint(
        '[PaymentMethod][CHECKOUT_REBUILD] paymentMethodIndex=$_paymentMethodIndex '
        'selectedButton=$selectedButton isMyPay=$_isMy_Pay isPartialPay=$_isPartialPay',
      );
    }
  }

  void changeDigitalPaymentName(String name, {bool willUpdate = true}) {
    _digitalPaymentName = name;
    if (willUpdate) {
      update();
    }
  }

  void setOrderType(String? type, {bool notify = true}) {
    _orderType = type;
    if (_orderType == 'take_away') {
      // Takeaway must always have zero delivery fee in UI and totals.
      _calculatedDeliveryCharge = 0.0;
      final int? targetStoreId =
          _store?.id ?? Get.find<CartController>().storeId;
      if (targetStoreId != null && targetStoreId > 0) {
        _hydrateStoreAddressFromStoreSummary(targetStoreId);
      }
    }
    _refreshDeliveryChargeReady(notify: false);
    if (notify) {
      update(['checkout', 'total', 'delivery_charge', 'payment']);
    }
  }

  Future<void> _hydrateStoreAddressFromStoreSummary(int storeId) async {
    try {
      final String currentAddress = (_store?.address ?? '').trim();
      if (currentAddress.isNotEmpty) return;

      final Response response = await Get.find<ApiClient>().getData(
        '${AppConstants.storeSummaryUri}?store_id=$storeId',
        handleError: false,
      );

      if (response.statusCode != 200 || response.body == null) {
        debugPrint(
            '📍 [CheckoutStoreAddress] store-summary request failed: status=${response.statusCode}');
        return;
      }

      final dynamic body = response.body;
      Map<String, dynamic>? data;
      Map<String, dynamic>? nestedStore;

      if (body is Map<String, dynamic>) {
        final dynamic nestedData = body['data'];
        if (nestedData is Map<String, dynamic>) {
          data = nestedData;
          final dynamic storeInData = nestedData['store'];
          if (storeInData is Map<String, dynamic>) {
            nestedStore = storeInData;
          }
        } else {
          data = body;
        }

        final dynamic storeTop = body['store'];
        if (nestedStore == null && storeTop is Map<String, dynamic>) {
          nestedStore = storeTop;
        }
      }

      final String resolvedAddress = [
        data?['address']?.toString(),
        nestedStore?['address']?.toString(),
      ].whereType<String>().map((v) => v.trim()).firstWhere(
            (v) => v.isNotEmpty,
            orElse: () => '',
          );

      if (resolvedAddress.isNotEmpty) {
        if (_store == null) {
          _store = Store(id: storeId, address: resolvedAddress);
        } else {
          _store!.address = resolvedAddress;
        }
        debugPrint(
            '📍 [CheckoutStoreAddress] hydrated from store-summary: storeId=$storeId, address="$resolvedAddress"');
        update(['checkout']);
      } else {
        debugPrint(
            '📍 [CheckoutStoreAddress] store-summary returned empty address for storeId=$storeId');
      }
    } catch (e) {
      debugPrint('📍 [CheckoutStoreAddress] hydration error: $e');
    }
  }

  void changePartialPayment({bool isUpdate = true}) {
    _isPartialPay = !_isPartialPay;
    if (isUpdate) {
      update(['payment', 'checkout']);
    }
  }

  void change_My_Pay({bool isUpdate = true}) {
    _isMy_Pay = !_isMy_Pay;
    if (isUpdate) {
      update(['payment', 'checkout']);
    }
  }

  void change_Kaidha_Pay({bool isUpdate = true}) {
    _isKaidhaPay = !_isKaidhaPay;
    if (isUpdate) {
      update(['payment', 'checkout']);
    }
  }

  void setAddressIndex(int? index) {
    _addressIndex = index;
    update();
  }

  void setGuestAddress(AddressModel? address, {bool isUpdate = true}) {
    _guestAddress = address;
    if (isUpdate) {
      update();
    }
  }

  Future<void> getDmTipMostTapped() async {
    _mostDmTipAmount = await checkoutServiceInterface.getDmTipMostTapped();
    update();
  }

  void setPreferenceTimeForView(String time, {bool isUpdate = true}) {
    _preferableTime = time;
    if (isUpdate) {
      update();
    }
  }

  Future<void> getOfflineMethodList() async {
    _offlineMethodList = null;
    _offlineMethodList = await checkoutServiceInterface.getOfflineMethodList();
    update();
  }

  void updateTips(int index, {bool notify = true}) {
    _selectedTips = index;
    if (_selectedTips == 0 || _selectedTips == 5) {
      _tips = 0;
    } else {
      _tips = double.parse(AppConstants.tips[index]);
    }
    if (notify) {
      update();
    }
  }

  void saveSharedPrefDmTipIndex(String i) {
    checkoutServiceInterface.saveSharedPrefDmTipIndex(i);
  }

  String getSharedPrefDmTipIndex() {
    return checkoutServiceInterface.getSharedPrefDmTipIndex();
  }

  void setTotalAmount(double amount) {
    _viewTotalPrice = amount;
    // ✅ Fix: تحديث UI عند تغيير المبلغ الإجمالي - استخدام ID محدد لتجنب rebuild loop
    // لا نستخدم 'checkout' لأن هذا يسبب rebuild كامل ويستدعي _calculatePrice مرة أخرى
    update(['total']);
  }

  void clearPrevData() {
    _addressIndex = 0;
    _acceptTerms = true;
    _paymentMethodIndex = -1;
    selectedButton = -1;
    select_payment_Methods = null;
    if (isSelected.isNotEmpty) {
      isSelected = List<bool>.filled(isSelected.length, false);
    }
    _selectedDateSlot = 0;
    _selectedTimeSlot = 0;
    // ✅ PRESERVE pre-calculated delivery data from cart page:
    // - _distance: Only clear if it's null, -1, or 0 (not yet calculated)
    // - _extraCharge: Intentionally NOT cleared (preserved for pre-calculation)
    // - _lastExtraChargeDistance/_lastExtraChargeTime: Preserved for caching
    if (_distance == null || _distance == -1 || _distance == 0) {
      _distance = null;
    }
    // Otherwise, keep the pre-calculated distance and extraCharge
    _orderAttachment = null;
    _rawAttachment = null;
  }

  Future<void> initializeTimeSlot(Store store) async {
    // 🛡️ NULL-SAFE: configModel/scheduleOrderSlotDuration can be null when the
    // backend config is incomplete. Fall back to a 30-min slot instead of
    // crashing the whole checkout preparation.
    final int slotDuration =
        Get.find<SplashController>().configModel?.scheduleOrderSlotDuration ??
            30;
    _timeSlots =
        await checkoutServiceInterface.initializeTimeSlot(store, slotDuration);
    _allTimeSlots =
        await checkoutServiceInterface.initializeTimeSlot(store, slotDuration);

    _validateSlot(_allTimeSlots!, 0, store.orderPlaceToScheduleInterval,
        notify: false);
  }

  void _validateSlot(List<TimeSlotModel> slots, int dateIndex, int? interval,
      {bool notify = true}) {
    // 🛡️ NULL-SAFE: any link in config → moduleConfig → module can be null
    // when the backend config is incomplete; avoid crashing slot validation.
    final orderPlaceToScheduleInterval = Get.find<SplashController>()
        .configModel
        ?.moduleConfig
        ?.module
        ?.orderPlaceToScheduleInterval;
    _timeSlots = checkoutServiceInterface.validateTimeSlot(
        slots,
        dateIndex,
        interval,
        orderPlaceToScheduleInterval != null &&
            orderPlaceToScheduleInterval > 0);

    if (notify) {
      update();
    }
  }

  void pickPrescriptionImage(
      {required bool isRemove, required bool isCamera}) async {
    if (isRemove) {
      _pickedPrescriptions = [];
    } else {
      final XFile? xFile = await ImagePicker().pickImage(
          source: isCamera ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 50);
      if (xFile != null) {
        _pickedPrescriptions.add(xFile);
      }
      update();
    }
  }

  void removePrescriptionImage(int index) {
    _pickedPrescriptions.removeAt(index);
    update();
  }

  /// ❌ DEPRECATED: Use isOpenNow(Store? store) instead
  @Deprecated(
      'Use isOpenNow(Store? store) instead - backend decides open/close status')
  bool isStoreClosed(bool today, bool active, List<Schedules>? schedules) {
    // ⚠️ DEPRECATED: Backend already calculated isOpen
    // Use store.isOpen from API instead
    return false; // Don't block - backend decides
  }

  /// ❌ DEPRECATED: Use isOpenNow(Store? store) instead
  @Deprecated(
      'Use isOpenNow(Store? store) instead - backend decides open/close status')
  bool isStoreOpenNow(bool active, List<Schedules>? schedules) {
    // ⚠️ DEPRECATED: Backend already calculated isOpen
    // Use store.isOpen from API instead
    return true; // Don't block - backend decides
  }

  /// ✅ FRONTEND ONLY: Get store open status from API only
  /// 🔥 PERFORMANCE: يفحص مرة واحدة فقط عند initCheckoutData
  bool isOpenNow(Store? store) {
    // ⛔ Guard: منع فحص متكرر - استخدام ID بدل object reference
    if (_storeStatusChecked && store?.id == _store?.id) {
      return _store?.isOpen == true;
    }

    // فحص أول مرة فقط
    _storeStatusChecked = true;
    return Get.find<StoreController>().isOpenNow(store);
  }

  /// Reset store status check (عند تغيير المتجر)
  void resetStoreStatusCheck() {
    _storeStatusChecked = false;
  }

  Future<double?> getDistanceInKM(LatLng originLatLng, LatLng destinationLatLng,
      {bool isDuration = false, bool fromDashboard = false}) async {
    if (!isDuration) {
      _setDeliveryChargeReady(false, notify: false);
    }
    if (isDuration) {
      // For duration, still use Google Maps API to get actual driving time
      _distance = -1;
      debugPrint('📏 getDistanceInKM: fetching duration data');
      final Response response = await checkoutServiceInterface
          .getDistanceInMeterNew(originLatLng, destinationLatLng);
      debugPrint('📏 getDistanceInKM: duration data received');
      try {
        if (response.statusCode == 200 && response.body['status'] == 'OK') {
          _distance =
              DistanceModel.fromJson(response.body as Map<String, dynamic>)
                      .rows![0]
                      .elements![0]
                      .duration!
                      .value! /
                  3600;
          // ✅ Fix: تحديث UI بعد حساب distance
          update(['checkout']);
        }
      } catch (e) {
        // Duration calculation failed, return null
        _distance = null;
      }
    } else {
      // For distance, use straight-line distance (Haversine formula)
      // This is more accurate for delivery fee calculation
      // Calculate immediately (synchronous operation)
      _distance = Geolocator.distanceBetween(
            originLatLng.latitude,
            originLatLng.longitude,
            destinationLatLng.latitude,
            destinationLatLng.longitude,
          ) /
          1000;
      debugPrint('📍 Distance calculated: $_distance km');
    }
    if (!fromDashboard) {
      await _getExtraCharge(_distance);
    }
    // ✅ Ready: update UI after final delivery inputs are ready
    // forceNotify ensures UI updates even if state was already ready
    _refreshDeliveryChargeReady(forceNotify: true);
    update(['total']);
    return _distance;
  }

  // Set pre-calculated distance (used when distance is calculated in cart page)
  Future<void> setPreCalculatedDistance(double distance) async {
    _setDeliveryChargeReady(false, notify: false);
    _distance = distance;
    debugPrint('📍 Pre-calculated distance set: $_distance km');
    await _getExtraCharge(_distance);
    // ✅ Ready: update UI after final delivery inputs are ready
    // forceNotify ensures UI updates even if state was already ready
    _refreshDeliveryChargeReady(forceNotify: true);
    update(['checkout', 'total', 'delivery_fee']);
  }

  /// ⚡ OPTIMIZATION: Check if extra_charge API call is needed
  /// Returns true if:
  /// - No previous call
  /// - Distance changed significantly (>0.1 km)
  /// - Cache expired (>10 minutes)
  bool shouldFetchExtraCharge(double? distance) {
    if (distance == null) return true;
    if (_lastExtraChargeDistance == null) return true;
    if (_lastExtraChargeTime == null) return true;

    final distanceDiff = (_lastExtraChargeDistance! - distance).abs();
    final age = DateTime.now().difference(_lastExtraChargeTime!);

    final shouldFetch = distanceDiff > 0.1 || age > _extraChargeCacheTTL;

    if (kDebugMode && !shouldFetch) {
      debugPrint(
          '⏭️ CheckoutController: Skipping extra_charge API (cached: distance=${distanceDiff.toStringAsFixed(2)}km diff, age=${age.inMinutes}min)');
    }

    return shouldFetch;
  }

  Future<double?> _getExtraCharge(double? distance) async {
    // ⚡ OPTIMIZATION: Guard to prevent duplicate API calls
    if (distance != null && !shouldFetchExtraCharge(distance)) {
      // Use cached value - don't call API
      debugPrint(
          '✅ _getExtraCharge: Using cached extraCharge=$_extraCharge (distance=$distance)');
      return _extraCharge;
    }
    debugPrint('🔄 _getExtraCharge: Fetching from API (distance=$distance)');

    try {
      _extraCharge = null;
      _extraCharge = await checkoutServiceInterface.getExtraCharge(distance);

      // ⚡ OPTIMIZATION: Update cache tracking
      if (distance != null && _extraCharge != null) {
        _lastExtraChargeDistance = distance;
        _lastExtraChargeTime = DateTime.now();
      }

      return _extraCharge;
    } catch (e) {
      // 🛡️ FALLBACK UX: Set to 0 on error (don't break checkout)
      if (kDebugMode) {
        debugPrint(
            '⚠️ CheckoutController: Error fetching extra_charge - using fallback (0): $e');
      }
      _extraCharge = 0;
      return _extraCharge;
    }
  }

  Future<bool> checkBalanceStatus(double totalPrice, double discount) async {
    totalPrice = (totalPrice - discount);
    if (isPartialPay) {
      changePartialPayment();
    }
    setPaymentMethod(-1);
    if ((Get.find<ProfileController>().userInfoModel!.walletBalance! <
            totalPrice) &&
        (Get.find<ProfileController>().userInfoModel!.walletBalance! != 0.0)) {
      Get.dialog(
        PartialPayDialogWidget(isPartialPay: true, totalPrice: totalPrice),
        useSafeArea: false,
      );
    } else {
      Get.dialog(
        PartialPayDialogWidget(isPartialPay: false, totalPrice: totalPrice),
        useSafeArea: false,
      );
    }
    update();
    return true;
  }

  void selectOfflineBank(int index, {bool canUpdate = true}) {
    _selectedOfflineBankIndex = index;
    if (canUpdate) {
      update();
    }
  }

  void setInstruction(int index) {
    if (_selectedInstruction == index) {
      _selectedInstruction = -1;
    } else {
      _selectedInstruction = index;
    }
    update();
  }

  void toggleDmTipSave() {
    _isDmTipSave = !_isDmTipSave;
    update();
  }

  void stopLoader({bool canUpdate = true}) {
    _isLoading = false;
    if (canUpdate) {
      update();
    }
  }

  // ============================ REAL E-COMMERCE FLOW ============================
  // Step 1: Create Order (Unpaid) - Called when user clicks "Proceed to Payment"
  // 🥇 Anti-loop Guard: يستخدم PaymentFlowState لمنع أي navigation تلقائي
  Future<String> createOrder(
    context,
    PlaceOrderBodyModel placeOrderBody,
    List<XFile>? orderAttachment,
  ) async {
    // 🔐 Guard: منع بدء عملية جديدة إذا كانت قيد التنفيذ
    if (!canStartNewPaymentFlow) {
      debugPrint('⚠️ Payment flow already in progress: $_paymentFlowState');
      return '';
    }

    // CRITICAL: Reset payment state for new order
    resetPaymentState();

    // 🥇 Update flow state
    _paymentFlowState = PaymentFlowState.creatingOrder;
    _isLoading = true;
    update(['payment']); // ✅ استخدام ID لتحديث جزئي

    String orderID = '';

    // ============================ تجهيز المرفقات ============================
    final List<MultipartBody> multiParts = [];
    if (orderAttachment != null) {
      for (final XFile file in orderAttachment) {
        multiParts.add(MultipartBody('order_attachment', file));
      }
    }

    debugPrint(
        '\x1B[32m[CreateOrder] START (unpaid) amount=${placeOrderBody.orderAmount}\x1B[0m');

    try {
      // Create order with "unpaid" status first (REAL E-COMMERCE FLOW)
      debugPrint('\x1B[32m[CreateOrder] Calling placeOrder()...\x1B[0m');
      debugPrint(
          '\x1B[32m[CreateOrder] orderType=${placeOrderBody.orderType}\x1B[0m');
      debugPrint(
          '\x1B[32m[CreateOrder] multiParts=${multiParts.length}\x1B[0m');

      final Map<String, dynamic> orderPayloadForLog =
          placeOrderBody.toJsonForApi();
      final double couponAmt = placeOrderBody.couponDiscountAmount ?? 0.0;
      final double finalAmt = placeOrderBody.orderAmount ?? 0.0;
      final double approxCartBeforeCoupon = couponAmt + finalAmt;
      final double cartSubTotal = Get.find<CartController>().subTotal;
      debugPrint(
        '[OrderCoupon][CREATE_REQUEST]\n'
        'couponCode=${placeOrderBody.couponCode}\n'
        'couponDiscountAmount=${placeOrderBody.couponDiscountAmount}\n'
        'couponDiscountTitle=${placeOrderBody.couponDiscountTitle}\n'
        'couponCreatedBy=${placeOrderBody.couponCreatedBy}\n'
        'cartSubTotal=$cartSubTotal\n'
        'cartTotalBeforeCoupon≈$approxCartBeforeCoupon\n'
        'cartTotalAfterCoupon=$finalAmt\n'
        'checkoutTotal=$finalAmt\n'
        'finalOrderAmount=$finalAmt\n'
        'payload=${jsonEncode(orderPayloadForLog)}',
      );

      final Response response =
          await checkoutServiceInterface.placeOrder(placeOrderBody, multiParts);

      debugPrint('\x1B[32m[CreateOrder] placeOrder() returned\x1B[0m');
      debugPrint(
          '\x1B[32m[CreateOrder] statusCode=${response.statusCode}\x1B[0m');
      debugPrint(
          '\x1B[32m[CreateOrder] bodyType=${response.body.runtimeType}\x1B[0m');

      // Parse the body once (placeOrder uses handleError:false, so non-2xx
      // responses still carry the decoded JSON map).
      final dynamic responseBody = response.body;
      final Map<String, dynamic>? bodyMap =
          responseBody is Map<String, dynamic> ? responseBody : null;

      // 🔧 Order id can arrive under several field names (order_id, orderId, id).
      orderID = (bodyMap?['order_id'] ??
              bodyMap?['orderId'] ??
              bodyMap?['id'] ??
              '')
          .toString();

      // 🔁 DIGITAL PAYMENT pending-order detection.
      // The backend intentionally creates the digital-payment order as
      // payment_status=unpaid / order_status=payment_pending. When its
      // duplicate-prevention kicks in — often right after an internal backend
      // 403 such as the "$txDuration" bug — it replies with
      // duplicate_prevented=true and the SAME existing order_id. That is a
      // usable existing pending order, NOT a failure: reuse it and continue to
      // MyFatoorah instead of showing a scary "Failed to create order" error.
      final bool duplicatePrevented = bodyMap?['duplicate_prevented'] == true;
      final String orderStatusStr =
          (bodyMap?['status'] ?? bodyMap?['order_status'] ?? '')
              .toString()
              .toLowerCase();
      final String paymentStatusStr =
          (bodyMap?['payment_status'] ?? '').toString().toLowerCase();
      final bool isPendingPaymentState =
          orderStatusStr == 'payment_pending' || paymentStatusStr == 'unpaid';

      final bool isHttpSuccess =
          response.statusCode == 200 || response.statusCode == 201;
      // Treat a returned order id together with duplicate_prevented OR a
      // payment_pending/unpaid state as a valid existing order even when the
      // HTTP status itself was not 2xx (e.g. the backend 403 $txDuration case).
      final bool isUsablePendingOrder =
          orderID.isNotEmpty && (duplicatePrevented || isPendingPaymentState);

      // ✅ FIX: قبول 200 أو 201 كـ success (لا نعتمد على success field)
      // لأن prescription endpoint قد لا يرجع success: true
      if (isHttpSuccess || isUsablePendingOrder) {
        if (duplicatePrevented) {
          debugPrint(
              '\x1B[33m♻️ [CreateOrder] duplicate_prevented=true → reusing existing pending order: $orderID\x1B[0m');
        }
        debugPrint(
            '[CreateOrder][RAW] order_id=${bodyMap?['order_id']} orderId=${bodyMap?['orderId']} id=${bodyMap?['id']} success=${bodyMap?['success']} message=${bodyMap?['message']} duplicate_prevented=$duplicatePrevented signatureStatus=${bodyMap?['signatureStatus'] ?? bodyMap?['signature_status']}');
        debugPrint(
            '\x1B[32m✅ Order ready: $orderID (statusCode=${response.statusCode}, status=$orderStatusStr, payment_status=$paymentStatusStr)\x1B[0m');
        debugPrint(
            "\x1B[32m[CreateOrder] amount=${bodyMap?['total_ammount'] ?? bodyMap?['total_amount'] ?? 'N/A'}\x1B[0m");
        debugPrint(
            "\x1B[32m[CreateOrder] keys=${bodyMap?.keys.toList() ?? 'N/A'}\x1B[0m");

        // Store order ID for later payment processing
        if (orderID.isNotEmpty) {
          _currentOrderId = int.tryParse(orderID);
          _currentOrderAmount = double.tryParse(
                  (bodyMap?['total_ammount'] ??
                          bodyMap?['total_amount'] ??
                          '0')
                      .toString()) ??
              0.0;

          // 🥇 Update flow state - جاهز للدفع
          // NOTE: payment_pending + unpaid is the expected pre-payment state
          // for digital payment. We do NOT show a success notification and do
          // NOT navigate to order details here — that only happens after the
          // payment is actually confirmed.
          _paymentFlowState = PaymentFlowState.preparingPayment;
          _isLoading = false;
          update();
          return orderID;
        } else {
          debugPrint('\x1B[31m❌ Order ID is empty in response!\x1B[0m');
          debugPrint(
              '\x1B[31m[CreateOrder] fullResponse=${response.body}\x1B[0m');
          _paymentFlowState = PaymentFlowState.failed;
          _isLoading = false;
          update();
          showCustomSnackBar('pay_create_failed_id'.tr);
          return '';
        }
      } else {
        // 🥇 Update flow state - فشل
        _paymentFlowState = PaymentFlowState.failed;
        _isLoading = false;
        update();

        // 🔍 DEBUG: Log detailed error information to identify if it's backend or frontend issue
        debugPrint(
            '═══════════════════════════════════════════════════════════');
        debugPrint('❌ ORDER CREATION FAILED - DIAGNOSTIC INFO');
        debugPrint(
            '═══════════════════════════════════════════════════════════');
        debugPrint('📊 Status Code: ${response.statusCode}');
        debugPrint('📝 Status Text: ${response.statusText}');
        debugPrint('📦 Response Body Type: ${response.body.runtimeType}');
        debugPrint('📦 Response Body: ${response.body}');

        final _CheckoutReadableError extracted =
            _extractOrderReadableError(response);
        final String errorMessage = extracted.message;
        final String? errorCode = extracted.code;

        debugPrint(
            '═══════════════════════════════════════════════════════════');
        debugPrint('🎯 FINAL ERROR MESSAGE: $errorMessage');
        if (errorCode != null) {
          debugPrint('🎯 ERROR CODE: $errorCode');
        }
        debugPrint(
            '═══════════════════════════════════════════════════════════');

        final String finalErrorMessage =
            _mapOrderErrorToFriendlyMessage(errorCode, errorMessage);

        // 🧪 DEBUG: عرض الرسالة النهائية (مؤقت)
        debugPrint('🔍 DEBUG → Final Message: $finalErrorMessage');

        // Keep loader locked until after message is shown.
        showCustomSnackBar(finalErrorMessage);
        _isLoading = false;
        update(['payment']);
        return '';
      }
    } catch (e) {
      // 🥇 Update flow state - فشل
      _paymentFlowState = PaymentFlowState.failed;
      debugPrint('خطأ أثناء إنشاء الطلب: $e');

      // ❌ لا Navigation - فقط عرض الرسالة
      // ✅ UX: عرض رسالة واضحة مع تفاصيل الخطأ
      final String errorMessage = e.toString().contains('timeout')
          ? 'pay_timeout'.tr
          : 'حدث خطأ أثناء إنشاء الطلب: ${e.toString()}';
      showCustomSnackBar(errorMessage);
      _isLoading = false;
      update(['payment']);
      return '';
    }
  }

  _CheckoutReadableError _extractOrderReadableError(
      Response<dynamic> response) {
    String message = response.statusText?.toString().trim() ?? '';
    String? code;
    final dynamic body = response.body;
    if (body is Map<String, dynamic>) {
      final dynamic errors = body['errors'];
      if (errors is List && errors.isNotEmpty && errors.first is Map) {
        final Map firstError = errors.first as Map;
        final dynamic codeValue = firstError['code'];
        final dynamic messageValue = firstError['message'];
        if (codeValue != null && codeValue.toString().trim().isNotEmpty) {
          code = codeValue.toString().trim();
        }
        if (messageValue != null && messageValue.toString().trim().isNotEmpty) {
          message = messageValue.toString().trim();
        }
      }
      final dynamic bodyCode = body['code'];
      if ((code == null || code.isEmpty) &&
          bodyCode != null &&
          bodyCode.toString().trim().isNotEmpty) {
        code = bodyCode.toString().trim();
      }
      final dynamic bodyMessage = body['message'];
      if (message.isEmpty &&
          bodyMessage != null &&
          bodyMessage.toString().trim().isNotEmpty) {
        message = bodyMessage.toString().trim();
      }
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    if (message.isEmpty) {
      message = 'Order could not be placed';
    }
    return _CheckoutReadableError(code: code?.toLowerCase(), message: message);
  }

  String _mapOrderErrorToFriendlyMessage(String? code, String backendMessage) {
    final String normalizedCode = (code ?? '').toLowerCase();
    final bool isArabic = Get.locale?.languageCode.toLowerCase() == 'ar';
    if (normalizedCode == 'order_time') {
      return isArabic
          ? 'pay_store_closed_now'.tr
          : 'The store is closed now, so the order cannot be placed at this time. Please try during working hours or choose another store.';
    }
    if (backendMessage.trim().isNotEmpty &&
        backendMessage.trim().toLowerCase() != 'unknown error') {
      return backendMessage.trim();
    }
    return isArabic ? 'تعذر إنشاء الطلب' : 'Order could not be placed';
  }

  String _extractReadableApiMessage(dynamic body, {required String fallback}) {
    String message = fallback;

    if (body is Map<String, dynamic>) {
      if ((body['message'] as String?)?.isNotEmpty == true) {
        message = body['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      } else if (body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
        message = (body['errors'] as Map).values.first.toString();
      } else if (body['errors'] is List &&
          (body['errors'] as List).isNotEmpty) {
        message = (body['errors'] as List).first.toString();
      }
    } else if (body is String && body.trim().isNotEmpty) {
      message = body;
    }

    return _decodePotentialMojibake(message.trim()).isEmpty
        ? fallback
        : _decodePotentialMojibake(message.trim());
  }

  String _decodePotentialMojibake(String input) {
    final bool looksBroken = input.contains('�') ||
        input.contains('�') ||
        input.contains('�') ||
        input.contains('�') ||
        input.contains('�') ||
        input.contains('ï»¿');
    if (!looksBroken) {
      return input;
    }

    try {
      String candidate = input;
      for (int i = 0; i < 2; i++) {
        final List<int> bytes = latin1.encode(candidate);
        final String decoded = utf8.decode(bytes, allowMalformed: false);
        final bool stillBroken = decoded.contains('�') ||
            decoded.contains('�') ||
            decoded.contains('�') ||
            decoded.contains('�') ||
            decoded.contains('�') ||
            decoded.contains('ï»¿');
        if (!stillBroken && decoded.isNotEmpty) {
          return decoded;
        }
        candidate = decoded;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('$e');
    }

    return input;
  }

  // Step 2: Process Payment - Called after user chooses payment method
  // 🥇 Anti-loop Guard: يستخدم PaymentFlowState لمنع أي navigation تلقائي
  Future<String> processPayment(
    context,
    KaidhaSubscriptionController kaidhaSubController,
    ProfileController profile_Controller,
    int? zoneID,
    double? maximumCodOrderAmount,
    bool fromCart,
    bool isCashOnDeliveryActive,
    String? contactNumber, {
    bool isOfflinePay = false,
  }) async {
    // ⛔ Guard 1: منع بدء عملية جديدة إذا كانت قيد التنفيذ
    if (isPaymentFlowInProgress &&
        _paymentFlowState != PaymentFlowState.preparingPayment) {
      // If we're not actually loading, the flow is stale ? reset and continue.
      if (!_isLoading) {
        debugPrint('?? Stale payment flow detected - resetting state');
        resetPaymentState();
      } else {
        debugPrint(
            '? Payment flow already in progress: $_paymentFlowState - skipping');
        return '';
      }
    }

    // ⛔ Guard 2: منع إعادة المحاولة إذا كانت العملية فشلت (يحتاج reset)
    if (_paymentFlowState == PaymentFlowState.failed) {
      debugPrint(
          '⛔ Payment flow failed previously - reset required before retry');
      showCustomSnackBar('pay_prev_failed'.tr);
      return '';
    }

    if (_currentOrderId == null) {
      _paymentFlowState = PaymentFlowState.failed;
      showCustomSnackBar('pay_no_order'.tr);
      return '';
    }

    // 🥇 Update flow state - Lock حقيقي
    _paymentFlowState = PaymentFlowState.processingPayment;
    _isLoading = true;
    update(['payment']); // ✅ استخدام ID لتحديث جزئي

    // Use the frontend-calculated total amount instead of backend response
    final double parsedOrderAmount =
        _viewTotalPrice > 0 ? _viewTotalPrice : _currentOrderAmount;
    bool paymentSucceeded = false;
    String resultOrderId = '';

    debugPrint(
        '\x1B[32m[Payment] Processing order=$_currentOrderId amount=$parsedOrderAmount\x1B[0m');
    debugPrint(
        '\x1B[32m[Payment] totals frontend=$_viewTotalPrice backend=$_currentOrderAmount\x1B[0m');

    try {
      if (_paymentMethodIndex == 2 || select_payment_Methods != null) {
        // Digital Payment (MyFatoorah)
        debugPrint('\x1B[32m[Payment][Digital] processing...\x1B[0m');
        paymentSucceeded = await Pay(
          context as BuildContext,
          '$parsedOrderAmount',
          contactNumber: contactNumber,
        );
        if (!paymentSucceeded) {
          await handleDigitalPaymentFailure();
          return '';
        }
      } else if (_paymentMethodIndex == 0 && isKaidhaPay == true) {
        // Qidha Wallet Payment - Use the new API
        debugPrint('\x1B[32m[Payment][Qidha] processing...\x1B[0m');

        // Always refresh wallet state before Qidha checks to avoid stale cached values.
        try {
          await kaidhaSubController.get_Wallet_Kaidh(forceRefresh: true);
          debugPrint(
              '[Payment][Qidha] wallet refreshed: status=${kaidhaSubController.walletKaidhaModel?.wallet?.status}, signature=${kaidhaSubController.walletKaidhaModel?.wallet?.signatureStatus}');
        } catch (e) {
          debugPrint('[Payment][Qidha] wallet refresh failed: $e');
        }

        // Enhanced validation for Qidha wallet
        if (kaidhaSubController.walletKaidhaModel?.wallet == null) {
          _isLoading = false;
          update();
          debugPrint('[Payment][Qidha] blocked: wallet is null');
          showCustomSnackBar('Qidha wallet is not available right now.');
          return '';
        }

        // NOTE: wallet.status / signatureStatus are validated at the UI layer
        // (payment_section.dart + submit button) BEFORE createOrder is called.
        // At this point the order is already created – only balance/limit checks remain.
        debugPrint(
            '[Payment][Qidha] ▶ orderId=$_currentOrderId amount=$parsedOrderAmount'
            ' status=${kaidhaSubController.walletKaidhaModel?.wallet?.status}'
            ' sig=${kaidhaSubController.walletKaidhaModel?.wallet?.signatureStatus}'
            ' balance=${kaidhaSubController.walletKaidhaModel?.wallet?.availableBalance}');

        // Check balance first
        final double availableBalance = double.tryParse(kaidhaSubController
                    .walletKaidhaModel?.wallet?.availableBalance
                    ?.toString() ??
                '0') ??
            0.0;
        if (availableBalance < parsedOrderAmount) {
          _isLoading = false;
          update();
          debugPrint(
              '[Payment][Qidha] blocked: insufficient balance available=$availableBalance required=$parsedOrderAmount');
          showCustomSnackBar(
              'Insufficient Qidha balance. Available: ${availableBalance.toStringAsFixed(2)} SAR.');
          return '';
        }

        // Check purchase limit
        final double purchaseLimit = double.tryParse(kaidhaSubController
                    .walletKaidhaModel?.wallet?.purchaseLimit
                    ?.toString() ??
                '0') ??
            0.0;
        if (purchaseLimit > 0 && parsedOrderAmount > purchaseLimit) {
          _isLoading = false;
          update();
          debugPrint(
              '[Payment][Qidha] blocked: purchase limit exceeded limit=$purchaseLimit amount=$parsedOrderAmount');
          showCustomSnackBar(
              'Purchase limit exceeded. Max allowed: ${purchaseLimit.toStringAsFixed(2)} SAR.');
          return '';
        }

        // Process Qidha payment using the new API with real order ID
        try {
          final Response paymentResponse =
              await checkoutServiceInterface.processPayment(
                  _currentOrderId!, 'wallet_qidha', parsedOrderAmount);

          final int statusCode = paymentResponse.statusCode ?? 0;
          if (statusCode >= 200 && statusCode < 300) {
            debugPrint(
                '\x1B[32m[Payment][Qidha] success order=$_currentOrderId\x1B[0m');
            paymentSucceeded = true;
            // forceRefresh: true bypasses the "full wallet already set" cache
            // guard so the new usedBalance/availableBalance is fetched and the
            // Menu/Profile Qidha badge updates immediately (no need to open the
            // Qidha screen and come back). get_Wallet_Kaidh() ends with an
            // update() that rebuilds the menu's GetBuilder<KaidhaSubscriptionController>.
            await kaidhaSubController.get_Wallet_Kaidh(
                forceRefresh: true); // Refresh balance from API
          } else {
            debugPrint(
                '\x1B[33m[Payment][Qidha] failed status=$statusCode\x1B[0m');
            debugPrint(
                '\x1B[33m[Payment][Qidha] response=${paymentResponse.body}\x1B[0m');

            _isLoading = false;
            update();

            final String errorMessage = _extractReadableApiMessage(
              paymentResponse.body,
              fallback: 'فشل في معالجة الدفع من محفظة قيدها',
            );
            showCustomSnackBar(errorMessage);
            return '';
          }
        } catch (e) {
          _isLoading = false;
          update();
          debugPrint('[Payment][Qidha] exception: $e');
          showCustomSnackBar('Qidha payment error. Please try again later.');
          return '';
        }
      } else if (_paymentMethodIndex == 1 && isMy_Pay == true) {
        // Regular Wallet Payment - Use the new API
        debugPrint('\x1B[32m[Payment][Wallet] processing...\x1B[0m');

        // Enhanced validation for regular wallet
        if (profile_Controller.userInfoModel == null) {
          _isLoading = false;
          update();
          debugPrint('[Payment][Wallet] blocked: userInfo is null');
          showCustomSnackBar(
              'User information is unavailable. Please login again.');
          return '';
        }

        // Check balance first
        final double availableBalance = double.tryParse(
                profile_Controller.userInfoModel?.walletBalance?.toString() ??
                    '0') ??
            0.0;
        if (availableBalance < parsedOrderAmount) {
          _isLoading = false;
          update();
          debugPrint(
              '[Payment][Wallet] blocked: insufficient balance available=$availableBalance required=$parsedOrderAmount');
          showCustomSnackBar(
              'Insufficient wallet balance. Available: ${availableBalance.toStringAsFixed(2)} SAR.');
          return '';
        }

        // Process regular wallet payment using the new API with real order ID
        try {
          final Response paymentResponse = await checkoutServiceInterface
              .processPayment(_currentOrderId!, 'wallet', parsedOrderAmount);

          final int statusCode = paymentResponse.statusCode ?? 0;
          if (statusCode >= 200 && statusCode < 300) {
            debugPrint(
                '\x1B[32m[Payment][Wallet] success order=$_currentOrderId\x1B[0m');
            paymentSucceeded = true;
            // Refresh user info to get updated wallet balance (force: skip ETag).
            await profile_Controller.getUserInfo(forceRefresh: true);
          } else {
            debugPrint(
                '\x1B[33m[Payment][Wallet] failed status=$statusCode\x1B[0m');
            debugPrint(
                '\x1B[33m[Payment][Wallet] response=${paymentResponse.body}\x1B[0m');

            _isLoading = false;
            update();

            final String errorMessage = _extractReadableApiMessage(
              paymentResponse.body,
              fallback: 'فشل في معالجة الدفع من المحفظة العادية',
            );
            showCustomSnackBar(errorMessage);
            return '';
          }
        } catch (e) {
          _isLoading = false;
          update();
          debugPrint('[Payment][Wallet] exception: $e');
          showCustomSnackBar('Wallet payment error. Please try again later.');
          return '';
        }
      } else {
        // Cash on Delivery - No payment processing needed
        debugPrint(
            '\x1B[32m[Payment][COD] no payment processing needed\x1B[0m');
        paymentSucceeded = true;
      }

      // ============================ عرض النتيجة النهائية ============================
      if (paymentSucceeded) {
        debugPrint(
            '\x1B[32m[Payment] order=$_currentOrderId marked paid\x1B[0m');

        // 🥇 Update flow state - نجحت العملية
        _paymentFlowState = PaymentFlowState.success;

        final bool isDigitalPayment = isDigitalPaymentSelected;
        final String successMessage = isDigitalPayment
            ? 'pay_success'.tr
            : 'تم انشاء الطلب وتم الدفع بنجاح';

        if (isDigitalPayment) {
          endDigitalPaymentFlow(succeeded: true);
        }

        // Show success message only after full successful flow (not after createOrder).
        Future.delayed(const Duration(seconds: 1), () {
          showCustomSnackBar(successMessage, isError: false);
        });

        // Store order ID before clearing it
        final String orderIdString = _currentOrderId.toString();
        resultOrderId = orderIdString;

        // Call success callback
        if (!isOfflinePay) {
          callback(
            context,
            true,
            successMessage,
            orderIdString,
            zoneID,
            parsedOrderAmount,
            maximumCodOrderAmount,
            fromCart,
            isCashOnDeliveryActive,
            contactNumber,
            isDigitalPayment: isDigitalPayment,
          );
        }

        // Don't refresh cart data here - it will be cleared after payment verification
        // Get.find<CartController>().getCartDataOnline();
        _orderAttachment = null;
        _rawAttachment = null;

        if (kDebugMode) {
          debugPrint(
              '-------- Order placed successfully $orderIdString ----------');
        }

        // Clear current order data
        _currentOrderId = null;
        _currentOrderAmount = 0.0;
      } else {
        if (isDigitalPaymentSelected) {
          await handleDigitalPaymentFailure();
        } else {
          _paymentFlowState = PaymentFlowState.failed;
          _isLoading = false;
          update(['payment']);
          showCustomSnackBar('payment_failed'.tr);
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء معالجة الدفع: $e');
      if (isDigitalPaymentSelected) {
        await handleDigitalPaymentFailure();
      } else {
        _paymentFlowState = PaymentFlowState.failed;
        _isLoading = false;
        update(['payment']);
        final String errorMessage = e.toString().contains('timeout')
            ? 'connection_to_api_server_failed'.tr
            : '${'payment_failed'.tr}: ${e.toString()}';
        showCustomSnackBar(errorMessage);
      }
    }

    // Reset payment method selection after payment flow completes
    _paymentMethodIndex = -1;
    selectedButton = -1;
    _isLoading = false;
    update();
    return resultOrderId;
  }

  // ============================ LEGACY METHOD (for backward compatibility) ============================
  Future<String> placeOrder(
    context,
    KaidhaSubscriptionController kaidhaSubController,
    ProfileController profile_Controller,
    PlaceOrderBodyModel placeOrderBody,
    int? zoneID,
    double amount,
    double? maximumCodOrderAmount,
    bool fromCart,
    bool isCashOnDeliveryActive,
    List<XFile>? orderAttachment, {
    bool isOfflinePay = false,
  }) async {
    // Step 1: Create order (unpaid)
    final String orderID =
        await createOrder(context, placeOrderBody, orderAttachment);
    if (orderID.isEmpty) {
      return '';
    }

    // Step 2: Process payment
    return await processPayment(
      context,
      kaidhaSubController,
      profile_Controller,
      zoneID,
      maximumCodOrderAmount,
      fromCart,
      isCashOnDeliveryActive,
      placeOrderBody.contactPersonNumber,
      isOfflinePay: isOfflinePay,
    );
  }

  // =================================================================

  Future<void> placePrescriptionOrder(
      context,
      int? storeId,
      int? zoneID,
      double? distance,
      String address,
      String longitude,
      String latitude,
      String note,
      List<XFile> orderAttachment,
      String dmTips,
      String deliveryInstruction,
      double orderAmount,
      double maxCodAmount,
      bool fromCart,
      bool isCashOnDeliveryActive) async {
    final List<MultipartBody> multiParts = [];
    for (final XFile file in orderAttachment) {
      multiParts.add(MultipartBody('order_attachment', file));
    }
    String? cartItemsJson;
    final cartController = Get.find<CartController>();
    if (cartController.cartList.isNotEmpty) {
      cartItemsJson = jsonEncode(cartController.cartList.map((cart) {
        final addOnIds = cart.addOnIds?.map((a) => a.id).toList() ?? <int?>[];
        final addOnQtys =
            cart.addOnIds?.map((a) => a.quantity).toList() ?? <int?>[];
        return {
          'item_id': cart.item?.id,
          'model': 'Item',
          'price': cart.price ?? cart.item?.price ?? 0,
          'variant': 'none',
          'variation': cart.variation?.map((v) => v.toJson()).toList() ?? [],
          'quantity': cart.quantity ?? 1,
          'add_on_ids': addOnIds,
          'add_on_qtys': addOnQtys,
          'add_ons': [],
          if (cart.item?.storeId != null) 'store_id': cart.item?.storeId,
        };
      }).toList());
    }
    _isLoading = true;
    update();
    final Response response =
        await checkoutServiceInterface.placePrescriptionOrder(
            storeId,
            distance,
            address,
            longitude,
            latitude,
            note,
            multiParts,
            dmTips,
            deliveryInstruction,
            orderAmount: orderAmount,
            cartItemsJson: cartItemsJson);
    _isLoading = false;
    if (response.statusCode == 200) {
      final String? message =
          (response.body as Map<String, dynamic>)['message'] as String?;
      // 🔧 FIX: Use 'id' instead of 'order_id' (backend returns 'id' field)
      final String orderID = ((response.body as Map<String, dynamic>)['id'] ??
              (response.body as Map<String, dynamic>)['order_id'] ??
              '')
          .toString();
      callback(context, true, message, orderID, zoneID, orderAmount,
          maxCodAmount, fromCart, isCashOnDeliveryActive, null);
      _orderAttachment = null;
      _rawAttachment = null;
      if (kDebugMode) {
        debugPrint('-------- Order placed successfully $orderID ----------');
      }
    } else {
      String errorMessage = response.statusText ?? '';
      if (response.body is Map<String, dynamic>) {
        final Map<String, dynamic> errorBody =
            response.body as Map<String, dynamic>;
        if ((errorBody['message'] as String?)?.isNotEmpty == true) {
          errorMessage = errorBody['message'] as String;
        } else if (errorBody['errors'] != null) {
          errorMessage = errorBody['errors'].toString();
        }
      }
      if (kDebugMode) {
        debugPrint(
            '❌ Prescription order failed: status=${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        debugPrint('❌ Error message: $errorMessage');
      }
      callback(context, false, errorMessage, '-1', zoneID, orderAmount,
          maxCodAmount, fromCart, isCashOnDeliveryActive, null);
    }
    update();
  }

  void callback(
    context,
    bool isSuccess,
    String? message,
    String orderID,
    int? zoneID,
    double amount,
    double? maximumCodOrderAmount,
    bool fromCart,
    bool isCashOnDeliveryActive,
    String? contactNumber, {
    bool isDigitalPayment = false,
  }) async {
    // ⛔ Guard 1: لا Navigation إلا عند success صريح
    if (!isSuccess) {
      debugPrint(
          '⛔ Callback called with isSuccess=false - blocking navigation to prevent loop');
      // ❌ لا Navigation - فقط عرض الرسالة (إذا لم تكن معروضة بالفعل)
      if (message != null && message.isNotEmpty && message != '-1') {
        showCustomSnackBar(message);
      }
      // Reset state للسماح بالمحاولة مرة أخرى
      _paymentFlowState = PaymentFlowState.failed;
      update();
      return;
    }

    // ⛔ Guard 2: منع navigation إذا كنا بالفعل في checkout (إضافي للأمان)
    final currentRoute = Get.currentRoute;
    if (currentRoute.contains('/checkout') && !isSuccess) {
      debugPrint(
          '⛔ Already on checkout route ($currentRoute) - blocking navigation from callback');
      if (message != null && message.isNotEmpty && message != '-1') {
        showCustomSnackBar(message);
      }
      _paymentFlowState = PaymentFlowState.failed;
      update();
      return;
    }

    // ✅ فقط عند success صريح - Navigation مسموح
    if (isSuccess) {
      // Clear cart for all confirmed paid orders (including digital payments)
      if (fromCart) {
        debugPrint(
            '\x1B[32m🧹 Clearing cart for confirmed paid order: $orderID\x1B[0m');
        Get.find<CartController>().clearCartList();
      }
      setGuestAddress(null);
      if (!isDigitalPayment &&
          !Get.find<OrderController>().showBottomSheet) {
        Get.find<OrderController>().showRunningOrders(canUpdate: false);
      }
      if (isDmTipSave) {
        saveSharedPrefDmTipIndex(selectedTips.toString());
      }
      stopLoader(canUpdate: false);
      if (isDigitalPayment) {
        debugPrint(
            '🎉 Digital payment confirmed — navigating to order success (not after unpaid createOrder)');
        unawaited(_refreshRunningOrdersFromServer());
        Get.offNamed(RouteHelper.getOrderSuccessRoute(
            orderID, contactNumber ?? '',
            createAccount: isCreateAccount, guestId: AuthHelper.getGuestId()));
      } else {
        final double loyaltyPointRate = Get.find<SplashController>()
                .configModel?.loyaltyPointItemPurchasePoint ??
            0;
        final double total = (amount / 100) * loyaltyPointRate;
        if (AuthHelper.isLoggedIn()) {
          Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
        }
        if (Get.context != null &&
            ResponsiveHelper.isDesktop(Get.context!) &&
            AuthHelper.isLoggedIn()) {
          Get.offNamed(RouteHelper.getInitialRoute());
          Future.delayed(
              const Duration(seconds: 2),
              () => Get.dialog(Center(
                  child: SizedBox(
                      height: 350,
                      width: 500,
                      child: OrderSuccessfulDialog(orderID: orderID)))));
        } else {
          // Validate orderID before navigation
          if (orderID.isNotEmpty && orderID != '-1') {
            final int? parsedOrderId = int.tryParse(orderID);
            if (parsedOrderId != null) {
              // Use bypass route to avoid address validation after order creation
              await Get.toNamed(
                RouteHelper.getOrderDetailsRouteBypass(parsedOrderId,
                    fromNotification: true),
              );
            } else {
              debugPrint('❌ Invalid order ID format: $orderID');
              showCustomSnackBar('transaction_failed'.tr);
            }
          } else {
            debugPrint('❌ Empty or invalid order ID: $orderID');
            showCustomSnackBar('transaction_failed'.tr);
          }
        }
      }
      clearPrevData();
      Get.find<CouponController>().removeCouponData(true);
      updateTips(
        getSharedPrefDmTipIndex().isNotEmpty
            ? int.parse(getSharedPrefDmTipIndex())
            : 0,
        notify: false,
      );
      // ✅ Reset payment flow state بعد success
      _paymentFlowState = PaymentFlowState.success;
      update();
    }
    // ❌ تم إزالة else block - لا Navigation عند الفشل (تم التعامل معه في بداية الدالة)
  }

  void toggleExpand() {
    _isExpand = !_isExpand;
    update();
  }

  void updateTimeSlot(int index) {
    _selectedTimeSlot = index;
    update();
  }

  void updateDateSlot(int index, int? interval) {
    _selectedDateSlot = index;
    if (_allTimeSlots != null) {
      validateSlot(_allTimeSlots!, index, interval);
    }
    update();
  }

  void validateSlot(List<TimeSlotModel> slots, int dateIndex, int? interval,
      {bool notify = true}) {
    _timeSlots = [];
    DateTime now = DateTime.now();

    final intervalValue = Get.find<SplashController>()
        .configModel
        ?.moduleConfig
        ?.module
        ?.orderPlaceToScheduleInterval;

    if (intervalValue != null && intervalValue > 0) {
      now = now.add(Duration(minutes: interval!));
    }

    int day = 0;

    if (dateIndex == 0) {
      day = DateTime.now().weekday;
    } else {
      day = DateTime.now().add(const Duration(days: 1)).weekday;
    }
    if (day == 7) {
      day = 0;
    }
    for (final slot in slots) {
      if (day == slot.day &&
          (dateIndex == 0 ? slot.endTime!.isAfter(now) : true)) {
        _timeSlots!.add(slot);
      }
    }
    if (notify) {
      update();
    }
  }

  bool _isCreateAccount = false;
  bool get isCreateAccount => _isCreateAccount;

  void toggleCreateAccount({bool willUpdate = true}) {
    _isCreateAccount = !_isCreateAccount;
    if (willUpdate) {
      update();
    }
  }

  // ============================ REAL E-COMMERCE FLOW VARIABLES ============================
  int? _currentOrderId;
  int? get currentOrderId => _currentOrderId;

  double _currentOrderAmount = 0.0;
  double get currentOrderAmount => _currentOrderAmount;

  // Check if there's an unpaid order
  bool get hasUnpaidOrder => _currentOrderId != null;

  // Clear current order data
  void clearCurrentOrder() {
    _currentOrderId = null;
    _currentOrderAmount = 0.0;
    update();
  }

  // Edit order address if changed during checkout
  Future<bool> editOrderAddressIfChanged(
      AddressModel originalAddress, AddressModel currentAddress) async {
    if (_currentOrderId == null) {
      debugPrint('❌ No current order to edit address');
      return false;
    }

    // Check if address has changed
    final bool addressChanged =
        originalAddress.address != currentAddress.address ||
            originalAddress.latitude != currentAddress.latitude ||
            originalAddress.longitude != currentAddress.longitude;

    if (!addressChanged) {
      debugPrint('📍 Address unchanged, no need to edit order address');
      return true;
    }

    debugPrint('📍 Address changed, updating order $_currentOrderId address');

    try {
      final Response response = await checkoutServiceInterface.editOrderAddress(
        _currentOrderId!,
        currentAddress.address!,
        currentAddress.latitude!,
        currentAddress.longitude!,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Order address updated successfully');
        return true;
      } else {
        debugPrint('❌ Failed to update order address: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating order address: $e');
      return false;
    }
  }

  @override
  void onClose() {
    couponController.dispose();
    noteController.dispose();
    streetNumberController.dispose();
    houseController.dispose();
    floorController.dispose();
    tipController.dispose();
    streetNode.dispose();
    houseNode.dispose();
    floorNode.dispose();
    super.onClose();
  }
}
