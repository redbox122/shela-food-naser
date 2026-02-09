// ignore_for_file: unnecessary_brace_in_string_interps, use_build_context_synchronously, unused_local_variable, unnecessary_import, non_constant_identifier_names, avoid_print, unrelated_type_equality_checks, unnecessary_string_interpolations

import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfatoorah_flutter/MFApplePayButton.dart';
import 'package:myfatoorah_flutter/MFCardView.dart';
import 'package:myfatoorah_flutter/MFGooglePayButton.dart';
import 'package:myfatoorah_flutter/MFModels.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
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
import 'package:sixam_mart/features/checkout/domain/models/checkout_error_response.dart';
//import 'package:sixam_mart/features/checkout/utils/checkout_data_sanitizer.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:sixam_mart/features/checkout/widgets/order_successfull_dialog.dart';
import 'package:sixam_mart/features/checkout/widgets/partial_pay_dialog_widget.dart';
import 'package:sixam_mart/features/checkout/widgets/in_app_payment_modal.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/payment/domain/services/myfatoorah_service.dart';
import 'package:sixam_mart/features/payment/domain/repositories/myfatoorah_repository.dart';
import 'package:sixam_mart/features/payment/domain/utils/myfatoorah_mapper.dart';
import 'package:get/get_connect/connect.dart';
import '../../my_coupon/controllers/my_coupon_controller.dart';

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

  String? countryDialCode =
      Get.find<AuthController>().getUserCountryCode().isNotEmpty
          ? Get.find<AuthController>().getUserCountryCode()
          : CountryCode.fromCountryCode(
                      Get.find<SplashController>().configModel!.country!)
                  .dialCode ??
              Get.find<LocalizationController>().locale.countryCode;

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

  // Flag to prevent UI flickering during checkout initialization
  // Only show calculated values when this is true
  bool _isCheckoutReady = false;
  bool get isCheckoutReady => _isCheckoutReady;

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
  int? _previousStoreId; // لتتبع تغيير المتجر

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
      debugPrint('💰 [Checkout] Delivery charge updated: $charge');
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
    // Use secure configuration from AppConstants
    final String token = AppConstants.useMyFatoorahTestMode
        ? AppConstants.myFatoorahTestToken
        : AppConstants.myFatoorahLiveToken;

    debugPrint('🔧 MyFatoorah Configuration:');
    debugPrint(
        "   Environment: ${AppConstants.useMyFatoorahTestMode ? 'TEST' : 'LIVE'}");

    // ⚠️ Validation: MyFatoorah Token
    if (token.isEmpty) {
      debugPrint('❌ MyFatoorah token is EMPTY!');
      debugPrint('   ⚠️ This will cause silent payment failures');
      debugPrint('   ⚠️ Please configure either TEST or LIVE token');
    } else {
      debugPrint('   Token: ${token.safeSubstring(20)}');
    }

    await MFSDK.init(
      token,
      MFCountry.SAUDIARABIA,
      AppConstants.useMyFatoorahTestMode
          ? MFEnvironment.TEST
          : MFEnvironment.LIVE,
    );
    // Don't initiate payment here - only initialize the SDK
    // Payment methods will be loaded when user clicks "Digital Payment"
    debugPrint('✅ MyFatoorah SDK initialized successfully');
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
      showCustomSnackBar('مبلغ الدفع غير صحيح - يجب أن يكون أكبر من صفر');
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
              'خطأ في تحميل وسائل الدفع');
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
          showCustomSnackBar('خطأ في تحميل وسائل الدفع');
        }
        update();
      }
    } catch (e) {
      debugPrint('❌ Error loading payment methods from backend: $e');
      paymentMethods = [];
      isSelected = [];
      showCustomSnackBar('خطأ في تحميل وسائل الدفع');
      update();
    }
  }

  Future<bool> Pay(BuildContext context, String amount) async {
    debugPrint(
        'Opening MyFatoorah portal for digital payment - Amount: $amount');

    // CRITICAL: Prevent double payment attempts
    if (_isPaymentInProgress) {
      debugPrint('🚨 Payment already in progress - preventing double payment');
      showCustomSnackBar('عملية دفع جارية بالفعل - يرجى الانتظار');
      return false;
    }

    // CRITICAL: Check if order is already paid
    if (_currentOrderId != null && _isOrderPaid) {
      debugPrint(
          '🚨 Order $_currentOrderId is already paid - preventing double payment');
      showCustomSnackBar('تم دفع هذا الطلب مسبقاً');
      return false;
    }

    // Validate amount before processing
    final double parsedAmount = double.tryParse(amount) ?? 0.0;
    if (parsedAmount <= 0) {
      debugPrint('❌ Invalid payment amount: $amount - Must be greater than 0');
      showCustomSnackBar('مبلغ الدفع غير صحيح - يجب أن يكون أكبر من صفر');
      return false;
    }

    // Set payment in progress flag
    _isPaymentInProgress = true;

    // Check if MyFatoorah is properly initialized
    final String token = AppConstants.useMyFatoorahTestMode
        ? AppConstants.myFatoorahTestToken
        : AppConstants.myFatoorahLiveToken;

    if (token.isEmpty) {
      debugPrint('❌ MyFatoorah token is empty! Cannot process payment.');
      debugPrint(
          '   ⚠️ Environment: ${AppConstants.useMyFatoorahTestMode ? 'TEST' : 'LIVE'}');
      debugPrint(
          '   ⚠️ This will cause silent payment failures and navigation loops');
      // ⛔ Update flow state - فشل
      _paymentFlowState = PaymentFlowState.failed;
      _isPaymentInProgress = false;
      update();
      showCustomSnackBar('خطأ في إعدادات الدفع - يرجى المحاولة لاحقاً');
      return false;
    }

    // Ensure MyFatoorah is properly initialized before proceeding
    try {
      await MFSDK.init(
        token,
        MFCountry.SAUDIARABIA,
        AppConstants.useMyFatoorahTestMode
            ? MFEnvironment.TEST
            : MFEnvironment.LIVE,
      );
      debugPrint('✅ MyFatoorah SDK re-initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to re-initialize MyFatoorah SDK: $e');
      showCustomSnackBar('خطأ في إعدادات الدفع');
      return false;
    }

    // First, initiate payment with the actual amount to set currency correctly
    await initiatePaymentWithAmount(context, amount);

    // Check if payment methods were loaded successfully
    if (paymentMethods.isEmpty) {
      debugPrint('❌ No payment methods available after initiation');
      showCustomSnackBar('لا توجد وسائل دفع متاحة');
      return false;
    }

    // Validate and use the selected payment method ID
    if (select_payment_Methods == null ||
        select_payment_Methods!.paymentMethodId == null) {
      debugPrint('❌ No payment method selected!');
      showCustomSnackBar('يرجى اختيار طريقة الدفع أولاً');
      return false;
    }

    final int paymentMethodId = select_payment_Methods!.paymentMethodId!;
    debugPrint(
        '🎯 Using selected payment method ID: $paymentMethodId (${select_payment_Methods!.paymentMethodAr})');
    debugPrint(
        '🎯 Payment method code: ${select_payment_Methods!.paymentMethodCode}');

    // Validate amount again before executing payment
    final double finalAmount = double.tryParse(amount) ?? 0.0;
    if (finalAmount <= 0) {
      debugPrint(
          '❌ Invalid payment amount for execution: $amount - Must be greater than 0');
      showCustomSnackBar('مبلغ الدفع غير صحيح - يجب أن يكون أكبر من صفر');
      return false;
    }

    final request = MFExecutePaymentRequest(
      paymentMethodId: paymentMethodId,
      invoiceValue: finalAmount,
    );

    try {
      debugPrint('💳 بدء عملية الدفع مع MyFatoorah - Amount: $finalAmount SAR');
      debugPrint('💰 Currency should be SAR (set during initiatePayment)');

      bool paymentSuccess = false;
      String? invoiceId;

      await MFSDK.executePayment(request, MFLanguage.ARABIC,
          (receivedInvoiceId) {
        debugPrint(
            'استلام استجابة من MyFatoorah - Invoice ID: $receivedInvoiceId');

        if (receivedInvoiceId.isNotEmpty) {
          debugPrint(
              'تم إنشاء الفاتورة بنجاح. رقم الفاتورة: $receivedInvoiceId');
          _lastInvoiceId = receivedInvoiceId;
          invoiceId = receivedInvoiceId;
          paymentSuccess = true;
          // Don't show success message here - portal will open asynchronously
        } else {
          debugPrint('لم يتم استلام رقم الفاتورة بعد الدفع.');
          showCustomSnackBar('لم يتم استلام رقم الفاتورة بعد الدفع.');
          paymentSuccess = false;
        }
      });

      // Wait a moment for the callback to complete
      await Future.delayed(const Duration(milliseconds: 500));

      if (paymentSuccess && invoiceId != null) {
        debugPrint('MyFatoorah payment successful, updating order status...');

        // Call backend to process the payment and update order status
        final response = await checkoutServiceInterface.processPayment(
          _currentOrderId!,
          'digital_payment',
          double.tryParse(amount) ?? 0.0,
        );

        if (response.statusCode == 200) {
          debugPrint('Order payment processed successfully on backend');

          // CRITICAL: Mark order as paid and reset payment state
          _isOrderPaid = true;
          _isPaymentInProgress = false;

          return true;
        } else {
          debugPrint(
              'Failed to process payment on backend: ${response.statusCode}');

          // CRITICAL: Reset payment state on failure
          _isPaymentInProgress = false;

          showCustomSnackBar('تم الدفع بنجاح ولكن حدث خطأ في تحديث الطلب');
          return false;
        }
      }

      debugPrint('انتهت عملية الدفع مع MyFatoorah - Success: $paymentSuccess');
      return paymentSuccess;
    } catch (error) {
      debugPrint('خطأ في عملية الدفع: $error');
      debugPrint('❌ Error type: ${error.runtimeType}');

      // CRITICAL: Reset payment state on error
      _isPaymentInProgress = false;

      // Try to get more details from MFError
      if (error.toString().contains('MFError')) {
        try {
          // Cast to MFError to get more details
          final mfError = error as dynamic;
          debugPrint('❌ MFError details: ${mfError.toString()}');
          if (mfError.message != null) {
            debugPrint('❌ MFError message: ${mfError.message}');
          }
          if (mfError.code != null) {
            debugPrint('❌ MFError code: ${mfError.code}');
          }
        } catch (castError) {
          debugPrint('❌ Could not cast to MFError: $castError');
        }
        showCustomSnackBar('خطأ في إعدادات الدفع - يرجى المحاولة لاحقاً');
      } else {
        showCustomSnackBar('فشلت عملية الدفع: ${error.toString()}');
      }
      return false;
    }
  }

  void selectPaymentMethod(int index) {
    if (index >= 0 && index < paymentMethods.length) {
      isSelected = List.generate(isSelected.length, (i) => i == index);
      select_payment_Methods = paymentMethods[index];

      // Set payment method index to 2 (digital payment) when selecting from MyFatoorah methods
      setPaymentMethod(2);

      debugPrint(
          '✅ Selected payment method: ${paymentMethods[index].paymentMethodAr} (ID: ${paymentMethods[index].paymentMethodId})');
      debugPrint(
          '✅ Payment method details - En: ${paymentMethods[index].paymentMethodEn}, Code: ${paymentMethods[index].paymentMethodCode}');
      update();
    } else {
      debugPrint('Invalid payment method index: $index');
    }
  }
//تعديل اضافي لاحل تصليح مشكلة  الدفع من محفظتي فقط
// =========================================================
  // ✅ أضف هذا الكود الجديد هنا داخل CheckoutController
  // =========================================================

  void selectMyWalletPayment() {
    // 1. إجبار النظام على فهم أننا اخترنا الدفع بالمحفظة (الرقم 1)
    _paymentMethodIndex = 1;

    // 2. تفعيل متغير المحفظة
    _isMy_Pay = true;

    // 3. إلغاء أي طرق دفع أخرى لتجنب التداخل
    _isKaidhaPay = false;
    _isPartialPay = false;

    // 4. مسح أي اختيار سابق للفيزا أو الماستر كارد (مهم جداً لحل مشكلة ظهور الفيزا)
    select_payment_Methods = null;

    // 5. تصفير حالة الدفع للتأكد من عدم وجود عملية معلقة
    resetPaymentState();

    print('✅ تم اختيار المحفظة بنجاح: Index=1');

    // 6. تحديث الشاشة لتلوين الزر وإزالة الظلام
    update();
  }

  // Clear payment state when needed
  void clearPaymentState() {
    _lastInvoiceId = '';
    // ✅ payment_method is intentionally null here
    // Payment method will be selected by user and processed after order creation
    select_payment_Methods = null;
    isSelected = List.filled(paymentMethods.length, false);
    // ✅ Fix: إعادة تعيين paymentFlowState عند مسح حالة الدفع
    resetPaymentState();
    update(['payment']);
  }

  // Handle payment completion
  void handlePaymentCompletion(String invoiceId) {
    _lastInvoiceId = invoiceId;
    debugPrint('Payment completed successfully with invoice ID: $invoiceId');
    update();
  }

  // Handle payment cancellation
  void handlePaymentCancellation() {
    debugPrint('Payment was cancelled by user');
    showCustomSnackBar('تم إلغاء عملية الدفع');
    clearPaymentState();
  }

  // Handle payment failure
  void handlePaymentFailure(String error) {
    debugPrint('Payment failed: $error');
    showCustomSnackBar('فشلت عملية الدفع: $error');
    clearPaymentState();
  }

  // Validate payment method selection
  bool isPaymentMethodSelected() {
    return select_payment_Methods != null &&
        select_payment_Methods!.paymentMethodId != null &&
        select_payment_Methods!.paymentMethodId! > 0;
  }

  // Get selected payment method name
  String getSelectedPaymentMethodName() {
    if (select_payment_Methods != null) {
      return select_payment_Methods!.paymentMethodAr ?? 'Unknown';
    }
    return 'No payment method selected';
  }

  // Clear cart when payment is confirmed as paid
  void clearCartOnPaymentConfirmed(String orderId) async {
    debugPrint(
        '\x1B[32m🧹 Payment confirmed as PAID for order $orderId - clearing cart\x1B[0m');
    await Get.find<CartController>().clearCartList();

    // Force refresh to ensure cart is completely empty
    await Get.find<CartController>().forceRefreshCart();
  }

  // CRITICAL: Reset payment state for new orders
  /// 🥇 Reset payment state - يستخدم PaymentFlowState
  void resetPaymentState() {
    _paymentFlowState = PaymentFlowState.idle;
    debugPrint('🔄 Resetting payment state for new order');
    _isPaymentInProgress = false;
    _isOrderPaid = false;
    _currentOrderId = null;
    _lastInvoiceId = '';
  }

  // ==========================================================================================================
  // IN-APP PAYMENT PROCESSING METHODS
  // ==========================================================================================================

  /// Process digital wallet payments (Apple Pay, Google Pay)
  /// This method handles payments that don't require card details
  Future<bool> processDigitalWalletPayment(
      MFPaymentMethod paymentMethod, String amount) async {
    try {
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
          showCustomSnackBar('تمت عملية الدفع بنجاح', isError: false);
          update();
        } else {
          debugPrint('No invoice ID received for digital wallet payment.');
          showCustomSnackBar('لم يتم استلام رقم الفاتورة بعد الدفع.');
        }
      });

      return paymentSuccess;
    } catch (error) {
      debugPrint('Digital wallet payment error: $error');
      showCustomSnackBar('فشلت عملية الدفع: ${error.toString()}');
      return false;
    }
  }

  /// Process direct card payments
  /// This method handles card payments with the collected card information
  Future<bool> processDirectPayment(MFPaymentMethod paymentMethod,
      String amount, Map<String, String> cardData) async {
    try {
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
          showCustomSnackBar('تمت عملية الدفع بنجاح', isError: false);
          update();
        } else {
          debugPrint('No invoice ID received for card payment.');
          showCustomSnackBar('لم يتم استلام رقم الفاتورة بعد الدفع.');
        }
      });

      return paymentSuccess;
    } catch (error) {
      debugPrint('Card payment error: $error');
      showCustomSnackBar('فشلت عملية الدفع: ${error.toString()}');
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
    _paymentMethodIndex = index;

    // ✅ Fix: إعادة تعيين paymentFlowState عند تغيير طريقة الدفع
    // هذا يسمح للمستخدم بالمحاولة مرة أخرى بعد فشل سابق
    if (_paymentFlowState == PaymentFlowState.failed) {
      resetPaymentState();
    }

    if (isUpdate) {
      update();
    }
    // ❌ تم إزالة print(_paymentMethodIndex) - كان يطبع 0 ويسبب confusion في اللوج
  }

  void changeDigitalPaymentName(String name, {bool willUpdate = true}) {
    _digitalPaymentName = name;
    if (willUpdate) {
      update();
    }
  }

  void setOrderType(String? type, {bool notify = true}) {
    _orderType = type;
    _refreshDeliveryChargeReady(notify: false);
    if (notify) {
      update();
    }
  }

  void changePartialPayment({bool isUpdate = true}) {
    _isPartialPay = !_isPartialPay;
    if (isUpdate) {
      update();
    }
  }

  void change_My_Pay({bool isUpdate = true}) {
    _isMy_Pay = !_isMy_Pay;
    if (isUpdate) {
      update();
    }
  }

  void change_Kaidha_Pay({bool isUpdate = true}) {
    _isKaidhaPay = !_isKaidhaPay;
    if (isUpdate) {
      update();
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
    _timeSlots = await checkoutServiceInterface.initializeTimeSlot(store,
        Get.find<SplashController>().configModel!.scheduleOrderSlotDuration!);
    _allTimeSlots = await checkoutServiceInterface.initializeTimeSlot(store,
        Get.find<SplashController>().configModel!.scheduleOrderSlotDuration!);

    _validateSlot(_allTimeSlots!, 0, store.orderPlaceToScheduleInterval,
        notify: false);
  }

  void _validateSlot(List<TimeSlotModel> slots, int dateIndex, int? interval,
      {bool notify = true}) {
    final orderPlaceToScheduleInterval = Get.find<SplashController>()
        .configModel!
        .moduleConfig!
        .module!
        .orderPlaceToScheduleInterval;
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
      print('بدا ياخذالبيانات');
      final Response response = await checkoutServiceInterface
          .getDistanceInMeterNew(originLatLng, destinationLatLng);
      print('كمل ياخذالبيانات');
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
    String userID = '';

    // ============================ تجهيز المرفقات ============================
    final List<MultipartBody> multiParts = [];
    if (orderAttachment != null) {
      for (final XFile file in orderAttachment) {
        multiParts.add(MultipartBody('order_attachment', file));
      }
    }

    debugPrint(
        '\x1B[32m📋 Creating Order (Unpaid) - Amount: ${placeOrderBody.orderAmount}\x1B[0m');

    try {
      // Create order with "unpaid" status first (REAL E-COMMERCE FLOW)
      print('═══════════════════════════════════════════════════════════');
      print('📋 Calling placeOrder() - START');
      print(' - orderType: ${placeOrderBody.orderType}');
      print(' - multiParts length: ${multiParts.length}');
      print('═══════════════════════════════════════════════════════════');

      debugPrint('\x1B[32m📋 Calling placeOrder() - START\x1B[0m');
      debugPrint('\x1B[32m - orderType: ${placeOrderBody.orderType}\x1B[0m');
      debugPrint('\x1B[32m - multiParts length: ${multiParts.length}\x1B[0m');

      final Response response =
          await checkoutServiceInterface.placeOrder(placeOrderBody, multiParts);

      print('═══════════════════════════════════════════════════════════');
      print('📋 placeOrder() returned - END');
      print(' - statusCode: ${response.statusCode}');
      print(' - body type: ${response.body.runtimeType}');
      print('═══════════════════════════════════════════════════════════');

      debugPrint('\x1B[32m📋 placeOrder() returned - END\x1B[0m');
      debugPrint('\x1B[32m - statusCode: ${response.statusCode}\x1B[0m');
      debugPrint('\x1B[32m - body type: ${response.body.runtimeType}\x1B[0m');

      // ✅ FIX: قبول 200 أو 201 كـ success (لا نعتمد على success field)
      // لأن prescription endpoint قد لا يرجع success: true
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔧 FIX: Use 'id' instead of 'order_id' (backend returns 'id' field)
        orderID =
            (response.body['id'] ?? response.body['order_id'] ?? '').toString();
        userID = response.body['user_id']?.toString() ?? '';

        debugPrint(
            '\x1B[32m✅ Order created successfully: $orderID (unpaid)\x1B[0m');
        debugPrint(
            "\x1B[32m💰 Amount: ${response.body['total_ammount'] ?? response.body['total_amount'] ?? 'N/A'}\x1B[0m");
        debugPrint(
            "\x1B[32m📊 Status: ${response.body['status'] ?? 'N/A'} (unpaid)\x1B[0m");
        debugPrint(
            "\x1B[32m📦 Response Body Keys: ${response.body is Map ? (response.body as Map).keys.toList() : 'N/A'}\x1B[0m");

        // Store order ID for later payment processing
        if (orderID.isNotEmpty) {
          _currentOrderId = int.tryParse(orderID);
          _currentOrderAmount = double.tryParse(
                  (response.body['total_ammount'] ??
                          response.body['total_amount'] ??
                          '0')
                      .toString()) ??
              0.0;

          // 🥇 Update flow state - جاهز للدفع
          _paymentFlowState = PaymentFlowState.preparingPayment;
          _isLoading = false;
          update();
          return orderID;
        } else {
          debugPrint('\x1B[31m❌ Order ID is empty in response!\x1B[0m');
          debugPrint('\x1B[31m📦 Full Response: ${response.body}\x1B[0m');
          _paymentFlowState = PaymentFlowState.failed;
          _isLoading = false;
          update();
          showCustomSnackBar('فشل في إنشاء الطلب - لم يتم إرجاع رقم الطلب');
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

        // Extract error message from response
        String errorMessage = response.statusText ?? 'Unknown error';
        String? errorCode;

        if (response.body is Map<String, dynamic>) {
          final errorBody = response.body as Map<String, dynamic>;
          debugPrint('🔍 Error Body Keys: ${errorBody.keys.toList()}');

          // Try to extract error message from common fields
          if (errorBody.containsKey('message')) {
            errorMessage = errorBody['message'].toString();
            debugPrint('📨 Error Message (from body): $errorMessage');
          }
          if (errorBody.containsKey('error')) {
            errorMessage = errorBody['error'].toString();
            debugPrint('📨 Error (from body): $errorMessage');
          }
          if (errorBody.containsKey('errors')) {
            debugPrint('📨 Errors (from body): ${errorBody['errors']}');
            if (errorBody['errors'] is Map) {
              final errors = errorBody['errors'] as Map;
              errorMessage = errors.values.first.toString();
            }
          }
          if (errorBody.containsKey('code')) {
            errorCode = errorBody['code'].toString();
            debugPrint('🔢 Error Code: $errorCode');
          }
        } else if (response.body is String) {
          debugPrint('📨 Error Response (String): ${response.body}');
          errorMessage = response.body as String;
        }

        debugPrint(
            '═══════════════════════════════════════════════════════════');
        debugPrint('🎯 FINAL ERROR MESSAGE: $errorMessage');
        if (errorCode != null) {
          debugPrint('🎯 ERROR CODE: $errorCode');
        }
        debugPrint(
            '═══════════════════════════════════════════════════════════');

        // 🥇 Extract error using CheckoutErrorResponse
        final CheckoutErrorResponse? errorResponse =
            extractCheckoutError(response.body);
        String finalErrorMessage;

        // ✅ Error Mapping الصحيح - لا نستخدم "المتجر مغلق" إلا للخطأ الحقيقي
        if (errorCode != null) {
          switch (errorCode) {
            case 'STORE_CLOSED':
            case 'STORE_NOT_OPEN':
              finalErrorMessage = Get.find<SplashController>()
                      .configModel!
                      .moduleConfig!
                      .module!
                      .showRestaurantText!
                  ? 'restaurant_is_closed'.tr
                  : 'store_is_closed'.tr;
              break;
            case 'VALIDATION_ERROR':
            case 'CONTACT_NAME_REQUIRED':
            case 'CONTACT_NUMBER_REQUIRED':
              finalErrorMessage = errorMessage != 'Unknown error'
                  ? errorMessage
                  : (errorResponse?.userFriendlyMessage ??
                      'يرجى التحقق من البيانات المدخلة');
              break;
            case 'PAYMENT_FAILED':
            case 'PAYMENT_METHOD_REQUIRED':
              finalErrorMessage = errorMessage != 'Unknown error'
                  ? errorMessage
                  : (errorResponse?.userFriendlyMessage ??
                      'فشل في معالجة الدفع');
              break;
            case 'INSUFFICIENT_BALANCE':
              finalErrorMessage = errorMessage != 'Unknown error'
                  ? errorMessage
                  : (errorResponse?.userFriendlyMessage ?? 'الرصيد غير كافي');
              break;
            default:
              finalErrorMessage = errorMessage != 'Unknown error'
                  ? errorMessage
                  : (errorResponse?.userFriendlyMessage ??
                      'فشل في إنشاء الطلب');
          }
        } else {
          // إذا لم يكن هناك error code، استخدم الرسالة الحقيقية
          // ✅ تمييز فشل الدفع عن فشل المتجر (حتى بدون code)
          // إذا كان هناك محاولة دفع سابقة، قد يكون الخطأ متعلق بالدفع
          if (_paymentFlowState == PaymentFlowState.preparingPayment ||
              _paymentFlowState == PaymentFlowState.processingPayment) {
            // محاولة دفع فشلت
            finalErrorMessage = errorMessage != 'Unknown error'
                ? errorMessage
                : (errorResponse?.userFriendlyMessage ??
                    'فشل في عملية الدفع، يرجى المحاولة لاحقًا');
          } else {
            // خطأ في إنشاء الطلب
            finalErrorMessage = errorMessage != 'Unknown error'
                ? errorMessage
                : (errorResponse?.userFriendlyMessage ??
                    response.statusText ??
                    'فشل في إنشاء الطلب');
          }
        }

        // 🧪 DEBUG: عرض الرسالة النهائية (مؤقت)
        debugPrint('🔍 DEBUG → Final Message: $finalErrorMessage');

        // ❌ لا Navigation - فقط عرض الرسالة
        showCustomSnackBar(finalErrorMessage);
        return '';
      }
    } catch (e) {
      // 🥇 Update flow state - فشل
      _paymentFlowState = PaymentFlowState.failed;
      _isLoading = false;
      update(['payment']); // ✅ استخدام ID لتحديث جزئي
      debugPrint('خطأ أثناء إنشاء الطلب: $e');

      // ❌ لا Navigation - فقط عرض الرسالة
      // ✅ UX: عرض رسالة واضحة مع تفاصيل الخطأ
      final String errorMessage = e.toString().contains('timeout')
          ? 'انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى'
          : 'حدث خطأ أثناء إنشاء الطلب: ${e.toString()}';
      showCustomSnackBar(errorMessage);
      return '';
    }
  }

  // Step 2: Process Payment - Called after user chooses payment method
  // 🥇 Anti-loop Guard: يستخدم PaymentFlowState لمنع أي navigation تلقائي
  Future<String> processPayment(
    context,
    KaidhaSubscription_Controller kaidhaSubController,
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
      showCustomSnackBar('فشلت العملية السابقة. يرجى المحاولة مرة أخرى');
      return '';
    }

    if (_currentOrderId == null) {
      _paymentFlowState = PaymentFlowState.failed;
      showCustomSnackBar('لا يوجد طلب للدفع');
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
        '\x1B[32m💳 Processing Payment for Order: $_currentOrderId - Amount: $parsedOrderAmount\x1B[0m');
    debugPrint(
        '\x1B[32m💰 Frontend Total: $_viewTotalPrice, Backend Amount: $_currentOrderAmount\x1B[0m');

    try {
      if (_paymentMethodIndex == 2) {
        // Digital Payment (MyFatoorah)
        debugPrint('\x1B[32m💳 Processing Digital Payment...\x1B[0m');
        paymentSucceeded =
            await Pay(context as BuildContext, '$parsedOrderAmount');
        if (!paymentSucceeded) {
          _isLoading = false;
          update();
          showCustomSnackBar('فشلت العملية قم بالمحاوله في وقت اخر');
          return '';
        } else {
          // Payment successful
          showCustomSnackBar('تم الدفع بنجاح!', isError: false);
        }
      } else if (_paymentMethodIndex == 0 && isKaidhaPay == true) {
        // Qidha Wallet Payment - Use the new API
        debugPrint('\x1B[32m[   قيدها  ]  معالجة الدفع...\x1B[0m');

        // Enhanced validation for Qidha wallet
        if (kaidhaSubController.walletKaidhaModel?.wallet == null) {
          _isLoading = false;
          update();
          showCustomSnackBar('محفظة قيدها غير متاحة - يرجى المحاولة لاحقًا');
          return '';
        }

        // Check wallet status
        if (kaidhaSubController.walletKaidhaModel!.wallet!.status
                ?.toLowerCase() !=
            'active') {
          _isLoading = false;
          update();
          showCustomSnackBar('محفظة قيدها غير نشطة - يرجى تفعيلها أولاً');
          return '';
        }

        // Check signature status (handle bool/string/int)
        final dynamic signatureStatusRaw =
            kaidhaSubController.walletKaidhaModel!.wallet!.signatureStatus;
        final int? signatureStatus = signatureStatusRaw is bool
            ? (signatureStatusRaw ? 1 : 0)
            : signatureStatusRaw is int
                ? signatureStatusRaw
                : int.tryParse(signatureStatusRaw?.toString() ?? '');
        if (signatureStatus != 1) {
          _isLoading = false;
          update();
          showCustomSnackBar(
              'محفظة قيدها غير مفعلة - يرجى إكمال التحقق من الهوية');
          return '';
        }

        // Check balance first
        final double availableBalance = double.tryParse(kaidhaSubController
                    .walletKaidhaModel?.wallet?.availableBalance
                    ?.toString() ??
                '0') ??
            0.0;
        if (availableBalance < parsedOrderAmount) {
          _isLoading = false;
          update();
          showCustomSnackBar(
              'الرصيد غير كافي في محفظة قيدها. الرصيد المتاح: ${availableBalance.toStringAsFixed(2)} ريال');
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
          showCustomSnackBar(
              'تجاوز حد الشراء المسموح. الحد الأقصى: ${purchaseLimit.toStringAsFixed(2)} ريال');
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
                '\x1B[32m✅ Qidha payment processed successfully for order: $_currentOrderId\x1B[0m');
            paymentSucceeded = true;
            await kaidhaSubController.get_Wallet_Kaidh(); // Refresh balance
          } else {
            debugPrint('\x1B[33m⚠️ Qidha payment failed: $statusCode\x1B[0m');
            debugPrint(
                '\x1B[33m⚠️ Error response: ${paymentResponse.body}\x1B[0m');

            _isLoading = false;
            update();

            // Enhanced error handling
            String errorMessage = 'فشل في معالجة الدفع من محفظة قيدها';
            if (paymentResponse.body != null &&
                paymentResponse.body is Map<String, dynamic>) {
              final errorBody = paymentResponse.body as Map<String, dynamic>;
              if (errorBody.containsKey('message')) {
                errorMessage = errorBody['message'].toString();
              }
            }
            showCustomSnackBar(errorMessage);
            return '';
          }
        } catch (e) {
          _isLoading = false;
          update();
          debugPrint('❌ Qidha payment error: $e');
          showCustomSnackBar(
              'خطأ في معالجة الدفع من محفظة قيدها. يرجى المحاولة لاحقًا');
          return '';
        }
      } else if (_paymentMethodIndex == 1 && isMy_Pay == true) {
        // Regular Wallet Payment - Use the new API
        debugPrint('\x1B[32m[   محفظتي  ]  معالجة الدفع...\x1B[0m');

        // Enhanced validation for regular wallet
        if (profile_Controller.userInfoModel == null) {
          _isLoading = false;
          update();
          showCustomSnackBar(
              'معلومات المستخدم غير متاحة - يرجى تسجيل الدخول مرة أخرى');
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
          showCustomSnackBar(
              'الرصيد غير كافي في المحفظة العادية. الرصيد المتاح: ${availableBalance.toStringAsFixed(2)} ريال');
          return '';
        }

        // Process regular wallet payment using the new API with real order ID
        try {
          final Response paymentResponse = await checkoutServiceInterface
              .processPayment(_currentOrderId!, 'wallet', parsedOrderAmount);

          final int statusCode = paymentResponse.statusCode ?? 0;
          if (statusCode >= 200 && statusCode < 300) {
            debugPrint(
                '\x1B[32m✅ Regular wallet payment processed successfully for order: $_currentOrderId\x1B[0m');
            paymentSucceeded = true;
            // Refresh user info to get updated wallet balance
            await profile_Controller.getUserInfo();
          } else {
            debugPrint(
                '\x1B[33m⚠️ Regular wallet payment failed: $statusCode\x1B[0m');
            debugPrint(
                '\x1B[33m⚠️ Error response: ${paymentResponse.body}\x1B[0m');

            _isLoading = false;
            update();

            // Enhanced error handling
            String errorMessage = 'فشل في معالجة الدفع من المحفظة العادية';
            if (paymentResponse.body != null &&
                paymentResponse.body is Map<String, dynamic>) {
              final errorBody = paymentResponse.body as Map<String, dynamic>;
              if (errorBody.containsKey('message')) {
                errorMessage = errorBody['message'].toString();
              }
            }
            showCustomSnackBar(errorMessage);
            return '';
          }
        } catch (e) {
          _isLoading = false;
          update();
          debugPrint('❌ Regular wallet payment error: $e');
          showCustomSnackBar(
              'خطأ في معالجة الدفع من المحفظة العادية. يرجى المحاولة لاحقًا');
          return '';
        }
      } else {
        // Cash on Delivery - No payment processing needed
        debugPrint(
            '\x1B[32m💰 Cash on Delivery - No payment processing needed\x1B[0m');
        paymentSucceeded = true;
      }

      // ============================ عرض النتيجة النهائية ============================
      if (paymentSucceeded) {
        debugPrint('\x1B[32m✅ Order $_currentOrderId is now PAID\x1B[0m');

        // 🥇 Update flow state - نجحت العملية
        _paymentFlowState = PaymentFlowState.success;

        // Show success message
        Future.delayed(const Duration(seconds: 1), () {
          showCustomSnackBar('تمت عملية الدفع والطلب بنجاح', isError: false);
        });

        // Store order ID before clearing it
        final String orderIdString = _currentOrderId.toString();
        resultOrderId = orderIdString;

        // Call success callback
        if (!isOfflinePay) {
          callback(
            context,
            true,
            'تم إنشاء الطلب بنجاح',
            orderIdString,
            zoneID,
            parsedOrderAmount,
            maximumCodOrderAmount,
            fromCart,
            isCashOnDeliveryActive,
            contactNumber,
          );
        }

        // Don't refresh cart data here - it will be cleared after payment verification
        // Get.find<CartController>().getCartDataOnline();
        _orderAttachment = null;
        _rawAttachment = null;

        if (kDebugMode) {
          print('-------- Order placed successfully $orderIdString ----------');
        }

        // Clear current order data
        _currentOrderId = null;
        _currentOrderAmount = 0.0;
      } else {
        // 🥇 Update flow state - فشل
        _paymentFlowState = PaymentFlowState.failed;
        _isLoading = false;
        update(['payment']);

        // ❌ لا Navigation - فقط عرض الرسالة
        // ⛔ لا نستدعي callback عند الفشل لمنع Navigation Loop
        // ✅ UX: عرض رسالة واضحة للمستخدم
        showCustomSnackBar('فشل في معالجة الدفع، الرجاء المحاولة لاحقًا');
        // ❌ تم إزالة callback عند الفشل لمنع Navigation Loop
      }
    } catch (e) {
      // 🥇 Update flow state - فشل
      _paymentFlowState = PaymentFlowState.failed;
      _isLoading = false;
      update(['payment']);
      debugPrint('خطأ أثناء معالجة الدفع: $e');

      // ❌ لا Navigation - فقط عرض الرسالة
      // ⛔ لا نستدعي callback عند الفشل لمنع Navigation Loop
      // ✅ UX: عرض رسالة واضحة مع تفاصيل الخطأ
      final String errorMessage = e.toString().contains('timeout')
          ? 'انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى'
          : 'حدث خطأ أثناء معالجة الدفع: ${e.toString()}';
      showCustomSnackBar(errorMessage);
      // ❌ تم إزالة callback عند الفشل لمنع Navigation Loop
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
    KaidhaSubscription_Controller kaidhaSubController,
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
        print('-------- Order placed successfully $orderID ----------');
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
    String? contactNumber,
  ) async {
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
      if (!Get.find<OrderController>().showBottomSheet) {
        Get.find<OrderController>().showRunningOrders(canUpdate: false);
      }
      if (isDmTipSave) {
        saveSharedPrefDmTipIndex(selectedTips.toString());
      }
      stopLoader(canUpdate: false);
      // Don't reload home data after order creation - go directly to order details
      // HomeScreen.loadData(context, true);
      if (paymentMethodIndex == 2) {
        // For digital payments (MyFatoorah), redirect directly to order success page
        // since payment is already processed
        debugPrint(
            '🎉 Digital payment completed successfully, redirecting to order success page');
        Get.offNamed(RouteHelper.getOrderSuccessRoute(
            orderID, contactNumber ?? '',
            createAccount: isCreateAccount, guestId: AuthHelper.getGuestId()));
      } else {
        final double total = ((amount / 100) *
            Get.find<SplashController>()
                .configModel!
                .loyaltyPointItemPurchasePoint!);
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
              showCustomSnackBar('خطأ في رقم الطلب - يرجى المحاولة لاحقاً');
            }
          } else {
            debugPrint('❌ Empty or invalid order ID: $orderID');
            showCustomSnackBar('خطأ في رقم الطلب - يرجى المحاولة لاحقاً');
          }
        }
      }
      clearPrevData();
      Get.find<CouponController>().removeCouponData(false);
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
}
