//import 'dart:io';
//import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
//import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart'as online_cart;
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_flow_state.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_method_bottom_sheet.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/widgets/bottom_section.dart';
import 'package:sixam_mart/features/checkout/widgets/top_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/widgets/loading/loading.dart';
import '../../my_coupon/controllers/my_coupon_controller.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartModel?>? cartList;
  final bool fromCart;
  final int? storeId;
  const CheckoutScreen(
      {super.key,
      required this.fromCart,
      required this.cartList,
      required this.storeId});

  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  final ScrollController _scrollController = ScrollController();
  final JustTheController tooltipController1 = JustTheController();
  final JustTheController tooltipController2 = JustTheController();
  final JustTheController tooltipController3 = JustTheController();

  double? _taxPercent = 0;
  bool? _isCashOnDeliveryActive = false; // COD disabled
  bool? _isDigitalPaymentActive = false;
  bool _isOfflinePaymentActive = false;
  List<CartModel?>? _cartList;
  bool _isWalletActive = false;
  String _deliveryChargeForView = '';

  List<AddressModel> address = [];
  bool canCheckSmall = false;
  double? _payableAmount = 0;
  double badWeatherChargeForToolTip = 0;
  double extraChargeForToolTip = 0;
  bool isPassedVariationPrice = false;

  bool allIsLogged = false;

  // Store the passed address from pick-map screen
  AddressModel? _passedAddress;

  /// Get the current address - either passed from pick-map or from global state
  AddressModel? get currentAddress {
    return _passedAddress ?? AddressHelper.getUserAddressFromSharedPref();
  }

  AddressModel? _resolveChargeAddress(
      AddressModel? current, List<AddressModel> available) {
    if (current != null &&
        current.zoneData != null &&
        current.zoneData!.isNotEmpty) {
      return current;
    }
    for (final address in available) {
      if (address.zoneData != null && address.zoneData!.isNotEmpty) {
        return address;
      }
    }
    return current ?? (available.isNotEmpty ? available.first : null);
  }

  final TextEditingController guestContactPersonNameController =
      TextEditingController();
  final TextEditingController guestContactPersonNumberController =
      TextEditingController();
  final TextEditingController guestEmailController = TextEditingController();
  final TextEditingController guestPasswordController = TextEditingController();
  final TextEditingController guestConfirmPasswordController =
      TextEditingController();
  final FocusNode guestNumberNode = FocusNode();
  final FocusNode guestEmailNode = FocusNode();
  final FocusNode guestPasswordNode = FocusNode();
  final FocusNode guestConfirmPasswordNode = FocusNode();

  bool _firstTimeCheckPayment = false;
  bool _paymentMethodInitialized = false;
  double? _lastSetTotalAmount;
  bool _paymentMethodsPreloadTriggered = false;

  // ✅ FIX: Preserve storeId and cartList from Get.arguments as fallback
  int? _resolvedStoreId;
  List<CartModel?>? _resolvedCartList;
  bool _dataResolved = false;
  bool _initCallCompleted = false;

  /// Get the effective storeId - prioritizes resolved > widget > arguments
  int? get effectiveStoreId => _resolvedStoreId ?? widget.storeId;

  /// Get the effective cartList - prioritizes resolved > widget
  List<CartModel?>? get effectiveCartList =>
      _resolvedCartList ?? widget.cartList;

  @override
  void initState() {
    super.initState();

    // ✅ FIX: Resolve data from arguments ONCE (survives rebuilds)
    _resolveDataFromArguments();

    initCall();
  }

  /// Resolve storeId and cartList from Get.arguments if widget values are null
  /// This is called ONCE in initState and the values are preserved
  void _resolveDataFromArguments() {
    if (_dataResolved) return; // Only resolve once
    _dataResolved = true;

    // Resolve storeId
    if (widget.storeId != null) {
      _resolvedStoreId = widget.storeId;
    } else {
      final dynamic args = Get.arguments;
      if (args is Map) {
        final dynamic argStoreId = args['storeId'];
        if (argStoreId is int && argStoreId > 0) {
          _resolvedStoreId = argStoreId;
          debugPrint(
              '🛒 CheckoutScreen: Resolved storeId from arguments: $_resolvedStoreId');
        }
      }
    }

    // Resolve cartList
    if (widget.cartList != null && widget.cartList!.isNotEmpty) {
      _resolvedCartList = widget.cartList;
    } else {
      final dynamic args = Get.arguments;
      if (args is Map && args['cartList'] != null) {
        try {
          _resolvedCartList = (args['cartList'] as List).cast<CartModel?>();
          debugPrint(
              '🛒 CheckoutScreen: Resolved cartList from arguments: ${_resolvedCartList!.length} items');
        } catch (e) {
          debugPrint('❌ CheckoutScreen: Failed to resolve cartList: $e');
        }
      }
    }
  }

  /// Preload MyFatoorah payment methods when checkout page opens
  /// This ensures payment methods appear instantly when user clicks "Digital Payment"
  Future<void> _preloadPaymentMethods() async {
    try {
      debugPrint('🔄 Preloading MyFatoorah payment methods...');

      // Add safety check to prevent crashes
      if (!mounted) {
        debugPrint('⚠️ Widget not mounted, skipping payment methods preload');
        return;
      }

      final checkoutController = Get.find<CheckoutController>();

      // Only preload payment methods if we have a valid total amount
      // This prevents the 0.0 amount validation error
      if (checkoutController.viewTotalPrice != null &&
          checkoutController.viewTotalPrice! > 0) {
        try {
          if (!mounted) {
            return;
          }
          await checkoutController.initiatePaymentWithAmount(
              context, checkoutController.viewTotalPrice.toString());
          debugPrint(
              '✅ Payment methods preloaded: ${checkoutController.paymentMethods.length} methods');
        } catch (e) {
          debugPrint('❌ Error preloading payment methods: $e');
        }
      } else {
        debugPrint(
            '⏳ Total amount not calculated yet, skipping payment methods preload');
        // Payment methods will be loaded when user actually clicks "Digital Payment"
      }

      debugPrint('✅ MyFatoorah preload process completed');
    } catch (e) {
      debugPrint('❌ Error in payment methods preload: $e');
      // Don't show error to user, just log it
      // Payment methods will be loaded when user actually clicks "Digital Payment"
    }
  }

  Future<void> initCall() async {
    allIsLogged = true;
    setState(() {});

    // Debug logging for store ID
    appLogger.debug('🛒 CheckoutScreen initCall:');
    appLogger.debug(
        '   - widget.storeId: ${widget.storeId}, effectiveStoreId: $effectiveStoreId');
    appLogger.debug('   - widget.fromCart: ${widget.fromCart}');
    appLogger
        .debug('   - widget.cartList length: ${widget.cartList?.length ?? 0}');

    // Check if context is still mounted before using it
    if (!mounted) {
      appLogger
          .debug('❌ CheckoutScreen: Widget not mounted, skipping initCall');
      return;
    }

    await Get.find<CheckoutController>().initiate(context);
    if (!mounted) {
      return;
    }

    // Ensure no default payment method is selected for cart checkout
    if (Get.parameters['page'] == 'cart' || widget.fromCart == true) {
      Get.find<CheckoutController>().setPaymentMethod(-1, isUpdate: false);
    }

    // Defer MyFatoorah initialization to avoid memory pressure during screen load
    // This prevents crashes caused by simultaneous heavy operations
    Future.delayed(const Duration(milliseconds: 1000), () {
      _preloadPaymentMethods();
    });

    // Check if an address was passed as an argument (from pick-map screen)
    debugPrint(
        '🛒 CheckoutScreen: Get.arguments type: ${Get.arguments.runtimeType}');
    debugPrint('🛒 CheckoutScreen: Get.arguments: ${Get.arguments}');

    // ✅ FIX: Only extract address if not already set (guards against re-init with null arguments)
    if (_passedAddress == null) {
      final dynamic args = Get.arguments;
      if (args is Map) {
        final dynamic argAddress = args['address'];
        if (argAddress is AddressModel) {
          _passedAddress = argAddress;
        }
      }
      if (_passedAddress == null) {
        // Try to get from global variable (set by route helper)
        try {
          _passedAddress = Get.find<AddressModel>(tag: 'passed_address');
          debugPrint('🛒 CheckoutScreen: Got address from global variable');
        } catch (e) {
          debugPrint('🛒 CheckoutScreen: No address in global variable: $e');
        }
      }
    }

    if (_passedAddress != null) {
      debugPrint(
          '🛒 CheckoutScreen: Using address passed from pick-map screen');
      debugPrint('   - Address: ${_passedAddress!.address}');
      debugPrint(
          '   - Lat/Lng: ${_passedAddress!.latitude}, ${_passedAddress!.longitude}');
    } else {
      debugPrint(
          '🛒 CheckoutScreen: Using global address from shared preferences');
      debugPrint('   - Global address: ${currentAddress?.address}');
      debugPrint(
          '   - Global Lat/Lng: ${currentAddress?.latitude}, ${currentAddress?.longitude}');
    }

    final bool isLoggedIn = AuthHelper.isLoggedIn();
    // Get.find<CheckoutController>().setGuestAddress(null, isUpdate: false);
    Get.find<CheckoutController>().streetNumberController.text =
        currentAddress?.streetNumber ?? '';
    Get.find<CheckoutController>().houseController.text =
        currentAddress?.house ?? '';
    Get.find<CheckoutController>().floorController.text =
        currentAddress?.floor ?? '';
    Get.find<CheckoutController>().couponController.text = '';

    // Defer non-critical API calls to reduce memory pressure during initialization
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.find<CheckoutController>().getDmTipMostTapped();
      Get.find<CheckoutController>()
          .setPreferenceTimeForView('', isUpdate: false);
      Get.find<CheckoutController>().getOfflineMethodList();
    });

    if (Get.find<CheckoutController>().isCreateAccount) {
      Get.find<CheckoutController>().toggleCreateAccount(willUpdate: false);
    }

    if (Get.find<CheckoutController>().isPartialPay) {
      Get.find<CheckoutController>().changePartialPayment(isUpdate: false);
    }

    if (isLoggedIn) {
      if (Get.find<ProfileController>().userInfoModel == null) {
        await Get.find<ProfileController>().getUserInfo();
      }

      await Get.find<CouponController>().getCouponList();

      if (Get.find<AddressController>().addressList == null) {
        await Get.find<AddressController>().getAddressList();
      }

      // Load Qidha wallet data immediately and wait for completion
      debugPrint('🔄 Loading Qidha wallet data immediately...');
      await Get.find<KaidhaSubscriptionController>().get_Wallet_Kaidh();
      debugPrint('✅ Qidha wallet data loaded successfully');
    }

    // ✅ FIX: Only initialize cart data ONCE (guards against multiple initCall)
    if (_initCallCompleted && _cartList != null && _cartList!.isNotEmpty) {
      appLogger.debug(
          '🛒 CheckoutScreen: Cart already initialized (${_cartList!.length} items), skipping re-init');
    } else {
      _cartList = [];

      if (effectiveCartList == null || effectiveCartList!.isEmpty) {
        appLogger
            .error('❌ CheckoutScreen: No cartList available - cannot proceed');
        return;
      }

      _cartList!.addAll(effectiveCartList!);
      _initCallCompleted = true;
      debugPrint(
          '✅ CheckoutScreen: Initialized cartList - ${_cartList!.length} items');
    }

    // Initialize checkout data
    if (!mounted) {
      appLogger.debug(
          '❌ CheckoutScreen: Widget not mounted, skipping checkout data init');
      return;
    }

    // ✅ FIX: Use effectiveStoreId which includes fallback from Get.arguments
    if (effectiveStoreId != null) {
      appLogger.debug('🛒 Using effectiveStoreId: $effectiveStoreId');
      final checkoutController = Get.find<CheckoutController>();
      // Pass existing distance to avoid resetting state
      await checkoutController.initCheckoutData(
        context,
        effectiveStoreId!,
        preloadedCartList: _cartList?.whereType<CartModel>().toList(),
        preCalculatedDistance: checkoutController.distance,
      );
      if (!mounted) {
        return;
      }
      Get.find<CouponController>().removeCouponData(false);
    } else {
      appLogger
          .error('❌ CRITICAL: No storeId available from widget or arguments');
    }

    // CRITICAL FIX: Calculate distance using the selected address (not current GPS location)
    // This will be called after the store is loaded in initCheckoutData
    // BUT: Skip if distance is already pre-calculated from cart page (no "calculating" state!)
    if (currentAddress != null &&
        Get.find<CheckoutController>().store != null) {
      // Check if distance is already calculated (from cart page)
      if (Get.find<CheckoutController>().distance != null &&
          Get.find<CheckoutController>().distance != -1 &&
          Get.find<CheckoutController>().distance! > 0) {
        debugPrint(
            '✅ CheckoutScreen: Distance already pre-calculated: ${Get.find<CheckoutController>().distance} km');
        debugPrint(
            "   - Skipping distance calculation (no 'calculating' state!)");
      } else {
        debugPrint(
            '🛒 CheckoutScreen: Calculating distance using selected address');
        debugPrint(
            '   - From: ${currentAddress!.latitude}, ${currentAddress!.longitude}');
        debugPrint(
            '   - To: ${Get.find<CheckoutController>().store!.latitude}, ${Get.find<CheckoutController>().store!.longitude}');

        // Calculate distance using the selected address
        Get.find<CheckoutController>().getDistanceInKM(
          LatLng(
            double.parse(currentAddress!.latitude!),
            double.parse(currentAddress!.longitude!),
          ),
          LatLng(
            double.parse(Get.find<CheckoutController>().store!.latitude!),
            double.parse(Get.find<CheckoutController>().store!.longitude!),
          ),
        );
      }
    }

    Get.find<CheckoutController>()
        .pickPrescriptionImage(isRemove: true, isCamera: false);
    _isWalletActive =
        Get.find<SplashController>().configModel!.customerWalletStatus == 1;
    Get.find<CheckoutController>().updateTips(
      Get.find<CheckoutController>().getSharedPrefDmTipIndex().isNotEmpty
          ? int.parse(Get.find<CheckoutController>().getSharedPrefDmTipIndex())
          : 0,
      notify: false,
    );
    Get.find<CheckoutController>().tipController.text =
        Get.find<CheckoutController>().selectedTips != -1
            ? AppConstants.tips[Get.find<CheckoutController>().selectedTips]
            : '';

    // Ensure first-frame UI reflects latest delivery charge state.
    // This avoids missing updates if controller state was set before the builder mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<CheckoutController>()
          .update(['checkout', 'total', 'delivery_fee']);
    });

    //

    allIsLogged = false;
    setState(() {});
  }

  void _setSinglePaymentActive() {
    if ((!_firstTimeCheckPayment &&
            !_isCashOnDeliveryActive! &&
            _isDigitalPaymentActive! &&
            Get.find<SplashController>()
                    .configModel!
                    .activePaymentMethodList!
                    .length ==
                1) &&
        ((!_isWalletActive && AuthHelper.isLoggedIn()) ||
            !AuthHelper.isLoggedIn())) {
      Future.delayed(const Duration(milliseconds: 600), () {
        Get.find<CheckoutController>().setPaymentMethod(2, isUpdate: false);
        Get.find<CheckoutController>().changeDigitalPaymentName(
            Get.find<SplashController>()
                .configModel!
                .activePaymentMethodList![0]
                .getWay!,
            willUpdate: false);
        _firstTimeCheckPayment = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    guestContactPersonNameController.dispose();
    guestContactPersonNumberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Module? module =
        Get.find<SplashController>().configModel!.moduleConfig!.module;
    final bool guestCheckoutPermission = AuthHelper.isGuestLoggedIn() &&
        Get.find<SplashController>().configModel!.guestCheckoutStatus!;
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    final KaidhaSubscriptionController kaidhaSubController =
        Get.find<KaidhaSubscriptionController>();

    return Scaffold(
      appBar: CustomAppBar(title: 'checkout'.tr),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: currentAddress == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'no_address_selected'.tr,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'please_select_delivery_address'.tr,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back<void>(),
                    child: Text('go_back'.tr),
                  ),
                ],
              ),
            )
          : (guestCheckoutPermission || AuthHelper.isLoggedIn())
              ? GetBuilder<CheckoutController>(
                  id: 'checkout', // Use targeted ID for partial rebuild.
                  builder: (checkoutController) {
                    if (checkoutController.hasCheckoutError &&
                        !checkoutController.isCheckoutReady &&
                        checkoutController.store == null) {
                      return ErrorStateView(
                        onRetry: () {
                          if (effectiveStoreId != null && effectiveStoreId! > 0) {
                            checkoutController.initCheckoutData(
                              context,
                              effectiveStoreId!,
                              preloadedCartList: _cartList?.whereType<CartModel>().toList(),
                              preCalculatedDistance: checkoutController.distance,
                            );
                          } else {
                            initCall();
                          }
                        },
                      );
                    }
                    // 🔒 CRITICAL GUARD: Prevent calculations if cart is empty or null
                    // ✅ FIX: Show error UI instead of throwing exception
                    if (_cartList == null || _cartList!.isEmpty) {
                      if (!_initCallCompleted) {
                        return const Center(child: LoadingWidget());
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text('cart_is_empty'.tr,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Get.back<void>(),
                              child: Text('go_back'.tr),
                            ),
                          ],
                        ),
                      );
                    }

                    final List<DropdownItem<int>> addressList =
                        _getDropdownAddressList(
                      context: context,
                      addressList: Get.find<AddressController>().addressList,
                      store: checkoutController.store,
                    );

                    //
                    address = _getAddressList(
                        addressList: Get.find<AddressController>().addressList,
                        store: checkoutController.store);

                    bool todayClosed = false;
                    bool tomorrowClosed = false;
                    final Pivot? moduleData =
                        _getModuleData(store: checkoutController.store);
                    _isCashOnDeliveryActive =
                        _checkCODActive(store: checkoutController.store);
                    _isDigitalPaymentActive = _checkDigitalPaymentActive(
                        store: checkoutController.store);
                    _isOfflinePaymentActive = Get.find<SplashController>()
                            .configModel!
                            .offlinePaymentStatus! &&
                        _checkZoneOfflinePaymentOnOff(
                            addressModel: currentAddress,
                            checkoutController: checkoutController);
                    if (checkoutController.store != null) {
                      // ✅ FRONTEND ONLY: Use store.isOpen from API only
                      // Backend already calculated isOpen based on schedules/time
                      // Flutter just displays what backend says
                      final bool isStoreOpen =
                          checkoutController.store!.isOpen == true;
                      todayClosed =
                          !isStoreOpen; // If isOpen == false, it's closed
                      tomorrowClosed =
                          !isStoreOpen; // Use same status for tomorrow (backend decides)
                      _taxPercent =
                          _resolveTaxPercent(checkoutController.store?.tax);
                    }
                    return GetBuilder<CouponController>(
                        builder: (couponController) {
                      double? maxCodOrderAmount;

                      if (moduleData != null) {
                        maxCodOrderAmount = moduleData.maximumCodOrderAmount;
                      }
                      final double price = _calculatePrice(
                          store: checkoutController.store, cartList: _cartList);
                      final double addOns = _calculateAddonsPrice(
                          store: checkoutController.store, cartList: _cartList);
                      final double variations = _calculateVariationPrice(
                          store: checkoutController.store,
                          cartList: _cartList,
                          calculateWithoutDiscount: true);
                      final double discount = _calculateDiscount(
                        store: checkoutController.store,
                        cartList: _cartList,
                        price: price,
                        addOns: addOns,
                      );
                      // 🔒 SAFE NULL HANDLING: Use null-coalescing instead of null check operator
                      final double couponDiscount = PriceConverter.toFixed(
                          couponController.discount ?? 0.0);
                      final bool taxIncluded = Get.find<SplashController>()
                              .configModel!
                              .taxIncluded ==
                          1;

                      // Calculate subtotal as items prices only (without tax) - same as cart screen
                      final double subTotal =
                          _calculateItemsSubtotal(cartList: _cartList);

                      final double referralDiscount =
                          _calculateReferralDiscount(
                              subTotal, discount, couponDiscount);

                      final double orderAmount = _calculateOrderAmount(
                        price: price,
                        variations: variations,
                        discount: discount,
                        addOns: addOns,
                        couponDiscount: couponDiscount,
                        cartList: _cartList,
                        referralDiscount: referralDiscount,
                      );

                      // Calculate tax on discounted prices (subTotal) - same as cart screen
                      final double tax = _calculateTax(
                        taxIncluded: taxIncluded,
                        orderAmount: subTotal,
                        taxPercent: _taxPercent,
                      );

                      final double additionalCharge =
                          Get.find<SplashController>()
                                  .configModel!
                                  .additionalChargeStatus!
                              ? Get.find<SplashController>()
                                  .configModel!
                                  .additionCharge!
                              : 0;

                      // Debug logging for additional charge
                      debugPrint('💰 Checkout additionalCharge calculation:');
                      debugPrint(
                          '   - additionalChargeStatus: ${Get.find<SplashController>().configModel!.additionalChargeStatus}');
                      debugPrint(
                          '   - additionalChargeName: ${Get.find<SplashController>().configModel!.additionalChargeName}');
                      debugPrint(
                          '   - additionCharge (raw): ${Get.find<SplashController>().configModel!.additionCharge}');
                      debugPrint(
                          '   - Calculated additionalCharge: $additionalCharge');
                      final AddressModel? effectiveAddress =
                          _resolveChargeAddress(currentAddress, address);

                      final bool isDeliveryChargePending =
                          checkoutController.orderType != 'take_away' &&
                              (effectiveAddress == null ||
                                  checkoutController.distance == null ||
                                  checkoutController.distance == -1 ||
                                  checkoutController.store == null);

                      final double originalCharge = effectiveAddress == null
                          ? 0.0
                          : _calculateOriginalDeliveryCharge(
                              store: checkoutController.store,
                              address: effectiveAddress,
                              distance: checkoutController.distance,
                              extraCharge: checkoutController.extraCharge,
                            );

                      final double? deliveryCharge = isDeliveryChargePending
                          ? null
                          : _calculateDeliveryCharge(
                              store: checkoutController.store,
                              address: effectiveAddress!,
                              distance: checkoutController.distance,
                              extraCharge: checkoutController.extraCharge,
                              orderType: checkoutController.orderType!,
                              orderAmount: 10,
                            );

                      // ✅ Update controller's delivery charge for reactive UI
                      if (deliveryCharge != null) {
                        final double displayDeliveryCharge =
                            checkoutController.orderType == 'take_away'
                                ? 0.0
                                : (originalCharge > 0
                                    ? originalCharge
                                    : (deliveryCharge < 0
                                        ? 0.0
                                        : deliveryCharge));
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          checkoutController.setCalculatedDeliveryCharge(
                              displayDeliveryCharge);
                        });
                      }

                      if (checkoutController.orderType != 'take_away' &&
                          checkoutController.store != null) {
                        // Debug logging for UI display logic
                        debugPrint(
                            '🎨 [UI Display Logic] Delivery Charge Display:');
                        debugPrint(
                            '   - store loaded: ${checkoutController.store != null}');
                        debugPrint(
                            '   - store.freeDelivery: ${checkoutController.store!.freeDelivery}');
                        debugPrint(
                            '   - distance: ${checkoutController.distance}');
                        debugPrint('   - originalCharge: $originalCharge');
                        debugPrint('   - deliveryCharge: $deliveryCharge');

                        // FIXED: Check conditions in correct order (as per backend team feedback)
                        // 1. First check if distance is still being calculated
                        if (isDeliveryChargePending) {
                          _deliveryChargeForView = 'calculating'.tr;
                          debugPrint(
                              '   ✅ Set to: calculating (distance is null or -1)');
                        }
                        // 2. Then check if we have a valid calculated charge (prioritize showing the fee)
                        else if (originalCharge != -1 && originalCharge > 0) {
                          // Show calculated delivery charge - this is the actual fee
                          // Backend confirmed: store.freeDelivery = false, so we should show the fee
                          _deliveryChargeForView =
                              PriceConverter.convertPrice(originalCharge)
                                  .toString();
                          debugPrint(
                              '   ✅ Set to: $_deliveryChargeForView (calculated charge)');
                        }
                        // 3. Only show "free" if deliveryCharge is actually 0 AND freeDelivery is true
                        // Backend confirmed: store.freeDelivery = false, so this should rarely execute
                        else if (deliveryCharge == 0 &&
                            checkoutController.orderType == 'delivery' &&
                            checkoutController.store!.freeDelivery == true) {
                          _deliveryChargeForView = 'free'.tr;
                          debugPrint(
                              '   ✅ Set to: free (charge is 0 AND freeDelivery is true)');
                        }
                        // 4. ✅ BACKEND CONTRACT: If calculation fails, show calculating - backend must provide correct data
                        else {
                          _deliveryChargeForView = 'calculating'.tr;
                          debugPrint(
                              '   ⚠️ Set to: calculating (charge calculation issue - backend must provide correct store/zone data)');
                        }
                      } else if (checkoutController.orderType != 'take_away' &&
                          checkoutController.store == null) {
                        // ✅ BACKEND CONTRACT: Store must be provided - no fallbacks
                        _deliveryChargeForView = 'calculating'.tr;
                        debugPrint(
                            '   ⚠️ Set to: calculating (store is null - backend must provide store data)');
                      }

                      final double extraPackagingCharge =
                          _calculateExtraPackagingCharge(checkoutController);

                      // Ensure delivery charge is not negative for total calculation
                      // Prefer originalCharge (actual calculated fee) when available
                      final double validDeliveryCharge =
                          checkoutController.orderType == 'take_away'
                              ? 0.0
                              : (originalCharge > 0
                                  ? originalCharge
                                  : (deliveryCharge == null
                                      ? 0.0
                                      : (deliveryCharge < 0
                                          ? 0.0
                                          : deliveryCharge)));

                      // If checkout is opened from cart page, use simplified total formula
                      // total = subtotal + delivery + service fee
                      final bool useSimpleCartTotal =
                          Get.parameters['page'] == 'cart' ||
                              widget.fromCart == true;

                      double total = useSimpleCartTotal
                          ? PriceConverter.toFixed(
                              subTotal +
                                  validDeliveryCharge +
                                  additionalCharge +
                                  (taxIncluded ? 0 : tax),
                            )
                          : _calculateTotal(
                              subTotal: subTotal,
                              deliveryCharge: validDeliveryCharge,
                              discount: discount,
                              couponDiscount: couponDiscount,
                              taxIncluded: taxIncluded,
                              tax: tax,
                              orderType: checkoutController.orderType!,
                              tips: checkoutController.tips,
                              additionalCharge: additionalCharge,
                              extraPackagingCharge: extraPackagingCharge,
                            );

                      final bool isPrescriptionRequired =
                          checkoutController.hasPrescriptionRequiredItems;

                      total = total - referralDiscount;

                      // ✅ FIX: Only set payment method ONCE on first build
                      if (effectiveStoreId != null &&
                          !_paymentMethodInitialized) {
                        _paymentMethodInitialized = true;
                        // Do not auto-select payment method for cart checkout
                        if (!(Get.parameters['page'] == 'cart' ||
                            widget.fromCart == true)) {
                          checkoutController.setPaymentMethod(0,
                              isUpdate: false);
                        }
                      }

                      // ✅ FIX: Only update total if value actually changed (prevents rebuild loop)
                      final double newTotal = total -
                          (checkoutController.isPartialPay
                              ? Get.find<ProfileController>()
                                  .userInfoModel!
                                  .walletBalance!
                              : 0);
                      if (_lastSetTotalAmount != newTotal) {
                        _lastSetTotalAmount = newTotal;
                        Future.microtask(() {
                          if (mounted) {
                            checkoutController.setTotalAmount(newTotal);
                          }
                        });
                      }

                      // ✅ FIX: Only trigger preload ONCE (prevents repeated calls on rebuild)
                      if (total > 0 &&
                          checkoutController.paymentMethods.isEmpty &&
                          !_paymentMethodsPreloadTriggered) {
                        _paymentMethodsPreloadTriggered = true;
                        _preloadPaymentMethods();
                      }

                      if (_payableAmount != checkoutController.viewTotalPrice &&
                          checkoutController.distance != null &&
                          isLoggedIn) {
                        _payableAmount = checkoutController.viewTotalPrice;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showCashBackSnackBar();
                        });
                      }

                      _setSinglePaymentActive();

                      // ✅ BACKEND CONTRACT: Store must be provided by backend - no fallbacks
                      return (checkoutController.store != null &&
                              checkoutController.isCheckoutReady &&
                              allIsLogged == false)
                          ? Column(
                              mainAxisSize: MainAxisSize
                                  .min, // Keep compact column size to avoid overflow.
                              children: [
                                //

                                ResponsiveHelper.isDesktop(context)
                                    ? Container(
                                        height: 64,
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.10),
                                        child: Center(
                                            child: Text('checkout'.tr,
                                                style: robotoMedium)),
                                      )
                                    : const SizedBox(),
                                Expanded(
                                    child: SingleChildScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  child: FooterView(
                                      child: SizedBox(
                                    width: Dimensions.webMaxWidth,
                                    child: ResponsiveHelper.isDesktop(context)
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                top: Dimensions
                                                    .paddingSizeLarge),
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      flex: 6,
                                                      child: TopSection(
                                                        checkoutController:
                                                            checkoutController,
                                                        charge: originalCharge,
                                                        deliveryCharge:
                                                            validDeliveryCharge,
                                                        addressList:
                                                            addressList,
                                                        tomorrowClosed:
                                                            tomorrowClosed,
                                                        todayClosed:
                                                            todayClosed,
                                                        module: module,
                                                        price: price,
                                                        discount: discount,
                                                        addOns: addOns,
                                                        isPrescriptionRequired:
                                                            isPrescriptionRequired,
                                                        address: address,
                                                        cartList: _cartList,
                                                        isCashOnDeliveryActive:
                                                            _isCashOnDeliveryActive!,
                                                        isDigitalPaymentActive:
                                                            _isDigitalPaymentActive!,
                                                        isWalletActive:
                                                            _isWalletActive,
                                                        storeId:
                                                            effectiveStoreId ??
                                                                0,
                                                        total: total,
                                                        isOfflinePaymentActive:
                                                            _isOfflinePaymentActive,
                                                        guestNameTextEditingController:
                                                            guestContactPersonNameController,
                                                        guestNumberTextEditingController:
                                                            guestContactPersonNumberController,
                                                        guestNumberNode:
                                                            guestNumberNode,
                                                        guestEmailController:
                                                            guestEmailController,
                                                        guestEmailNode:
                                                            guestEmailNode,
                                                        tooltipController1:
                                                            tooltipController1,
                                                        tooltipController2:
                                                            tooltipController2,
                                                        dmTipsTooltipController:
                                                            tooltipController3,
                                                        guestPasswordController:
                                                            guestPasswordController,
                                                        guestConfirmPasswordController:
                                                            guestConfirmPasswordController,
                                                        guestPasswordNode:
                                                            guestPasswordNode,
                                                        guestConfirmPasswordNode:
                                                            guestConfirmPasswordNode,
                                                        variationPrice:
                                                            isPassedVariationPrice
                                                                ? variations
                                                                : 0,
                                                        deliveryChargeForView:
                                                            _deliveryChargeForView,
                                                        badWeatherCharge:
                                                            badWeatherChargeForToolTip,
                                                        extraChargeForToolTip:
                                                            extraChargeForToolTip,
                                                      )),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeLarge),
                                                  Expanded(
                                                      flex: 4,
                                                      child: BottomSection(
                                                        checkoutController:
                                                            checkoutController,
                                                        total: total,
                                                        module: module!,
                                                        subTotal: subTotal,
                                                        discount: discount,
                                                        couponController:
                                                            couponController,
                                                        taxIncluded:
                                                            taxIncluded,
                                                        tax: tax,
                                                        deliveryCharge:
                                                            validDeliveryCharge,
                                                        todayClosed:
                                                            todayClosed,
                                                        tomorrowClosed:
                                                            tomorrowClosed,
                                                        orderAmount:
                                                            orderAmount,
                                                        maxCodOrderAmount:
                                                            maxCodOrderAmount,
                                                        storeId:
                                                            effectiveStoreId ??
                                                                0,
                                                        taxPercent: _taxPercent,
                                                        price: price,
                                                        addOns: addOns,
                                                        isPrescriptionRequired:
                                                            isPrescriptionRequired,
                                                        checkoutButton:
                                                            _orderPlaceButton(
                                                          kaidhaSubController,
                                                          checkoutController,
                                                          todayClosed,
                                                          tomorrowClosed,
                                                          orderAmount,
                                                          validDeliveryCharge,
                                                          tax,
                                                          discount,
                                                          total,
                                                          maxCodOrderAmount,
                                                          isPrescriptionRequired,
                                                        ),
                                                        referralDiscount:
                                                            referralDiscount,
                                                        variationPrice:
                                                            isPassedVariationPrice
                                                                ? variations
                                                                : 0,
                                                      )),
                                                ]),
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize
                                                .min, // Keep compact column size to avoid overflow.
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                                TopSection(
                                                  checkoutController:
                                                      checkoutController,
                                                  charge: originalCharge,
                                                  deliveryCharge:
                                                      validDeliveryCharge,
                                                  addressList: addressList,
                                                  tomorrowClosed:
                                                      tomorrowClosed,
                                                  todayClosed: todayClosed,
                                                  module: module,
                                                  price: price,
                                                  discount: discount,
                                                  addOns: addOns,
                                                  isPrescriptionRequired:
                                                      isPrescriptionRequired,
                                                  address: address,
                                                  cartList: _cartList,
                                                  isCashOnDeliveryActive:
                                                      _isCashOnDeliveryActive!,
                                                  isDigitalPaymentActive:
                                                      _isDigitalPaymentActive!,
                                                  isWalletActive:
                                                      _isWalletActive,
                                                  storeId:
                                                      effectiveStoreId ?? 0,
                                                  total: total,
                                                  isOfflinePaymentActive:
                                                      _isOfflinePaymentActive,
                                                  guestNameTextEditingController:
                                                      guestContactPersonNameController,
                                                  guestNumberTextEditingController:
                                                      guestContactPersonNumberController,
                                                  guestNumberNode:
                                                      guestNumberNode,
                                                  guestEmailController:
                                                      guestEmailController,
                                                  guestEmailNode:
                                                      guestEmailNode,
                                                  tooltipController1:
                                                      tooltipController1,
                                                  tooltipController2:
                                                      tooltipController2,
                                                  dmTipsTooltipController:
                                                      tooltipController3,
                                                  guestPasswordController:
                                                      guestPasswordController,
                                                  guestConfirmPasswordController:
                                                      guestConfirmPasswordController,
                                                  guestPasswordNode:
                                                      guestPasswordNode,
                                                  guestConfirmPasswordNode:
                                                      guestConfirmPasswordNode,
                                                  variationPrice:
                                                      isPassedVariationPrice
                                                          ? variations
                                                          : 0,
                                                  deliveryChargeForView:
                                                      _deliveryChargeForView,
                                                  badWeatherCharge:
                                                      badWeatherChargeForToolTip,
                                                  extraChargeForToolTip:
                                                      extraChargeForToolTip,
                                                ),
                                                BottomSection(
                                                  checkoutController:
                                                      checkoutController,
                                                  total: total,
                                                  module: module!,
                                                  subTotal: subTotal,
                                                  discount: discount,
                                                  couponController:
                                                      couponController,
                                                  taxIncluded: taxIncluded,
                                                  tax: tax,
                                                  deliveryCharge:
                                                      validDeliveryCharge,
                                                  todayClosed: todayClosed,
                                                  tomorrowClosed:
                                                      tomorrowClosed,
                                                  orderAmount: orderAmount,
                                                  maxCodOrderAmount:
                                                      maxCodOrderAmount,
                                                  storeId:
                                                      effectiveStoreId ?? 0,
                                                  taxPercent: _taxPercent,
                                                  price: price,
                                                  addOns: addOns,
                                                  isPrescriptionRequired:
                                                      isPrescriptionRequired,
                                                  checkoutButton:
                                                      _orderPlaceButton(
                                                    kaidhaSubController,
                                                    checkoutController,
                                                    todayClosed,
                                                    tomorrowClosed,
                                                    orderAmount,
                                                    validDeliveryCharge,
                                                    tax,
                                                    discount,
                                                    total,
                                                    maxCodOrderAmount,
                                                    isPrescriptionRequired,
                                                  ),
                                                  referralDiscount:
                                                      referralDiscount,
                                                  variationPrice:
                                                      isPassedVariationPrice
                                                          ? variations
                                                          : 0,
                                                )
                                              ]),
                                  )),
                                )),

                                ResponsiveHelper.isDesktop(context)
                                    ? const SizedBox()
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 10)
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize
                                              .min, // Keep compact column size to avoid overflow.
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: Dimensions
                                                      .paddingSizeLarge,
                                                  vertical: Dimensions
                                                      .paddingSizeExtraSmall),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      checkoutController
                                                              .isPartialPay
                                                          ? 'due_payment'.tr
                                                          : 'total_amount'.tr,
                                                      style: robotoMedium.copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeLarge,
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryColor),
                                                    ),
                                                    GetBuilder<
                                                        CheckoutController>(
                                                      id: 'total',
                                                      builder: (controller) {
                                                        return PriceConverter
                                                            .convertPrice2(
                                                          controller
                                                                  .viewTotalPrice ??
                                                              0.0,
                                                          textStyle:
                                                              robotoMedium
                                                                  .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontSize: Dimensions
                                                                .fontSizeLarge,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ]),
                                            ),
                                            _orderPlaceButton(
                                              kaidhaSubController,
                                              checkoutController,
                                              todayClosed,
                                              tomorrowClosed,
                                              orderAmount,
                                              validDeliveryCharge,
                                              tax,
                                              discount,
                                              total,
                                              maxCodOrderAmount,
                                              isPrescriptionRequired,
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            )
                          : const Center(
                              child: SizedBox(
                                  width: Dimensions.webMaxWidth,
                                  child: LoadingWidget()));
                    });
                  })
              : NotLoggedInScreen(callBack: (value) {
                  initCall();
                  setState(() {});
                }),
      ),
    );
  }

  Widget _orderPlaceButton(
      KaidhaSubscriptionController kaidhaSubController,
      CheckoutController checkoutController,
      bool todayClosed,
      bool tomorrowClosed,
      double orderAmount,
      double? deliveryCharge,
      double tax,
      double? discount,
      double total,
      double? maxCodOrderAmount,
      bool isPrescriptionRequired) {
    return Container(
      width: Dimensions.webMaxWidth,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeSmall,
          horizontal: Dimensions.paddingSizeLarge),
      child: GetBuilder<CheckoutController>(
        id: 'payment',
        builder: (controller) => SafeArea(
          child: CustomButton(
              isLoading: controller.isLoading,
              buttonText: 'place_order'.tr,
              onPressed: controller.acceptTerms && !controller.isLoading
                  ? () async {
                      if (!controller.tryStartPlaceOrder()) {
                        return;
                      }
                      HapticFeedback.lightImpact();
                      if (controller.isPaymentFlowInProgress) {
                        // Recover from stale flow state after failed/aborted attempts.
                        if (!controller.isLoading) {
                          controller.resetPaymentState();
                        } else {
                          showCustomSnackBar(
                              'جاري تنفيذ الطلب، الرجاء الانتظار...');
                          controller.finishPlaceOrder();
                          return;
                        }
                      }
                      controller.setLoading(true, ids: ['payment']);
                      try {
                        final bool isGuestLogIn = AuthHelper.isGuestLoggedIn();

                        // Street/house/address description are optional now.
                        // Keep only location/address presence validation in delivery flow.

                        // 1) Define balances and selected payment method.
                        double qidhaBalance = double.tryParse(
                                kaidhaSubController.walletKaidhaModel?.wallet
                                        ?.availableBalance
                                        ?.toString() ??
                                    '0') ??
                            0.0;
                        double myWalletBalance = Get.find<ProfileController>()
                                .userInfoModel
                                ?.walletBalance ??
                            0.0;
                        int selectedPaymentIndex =
                            checkoutController.paymentMethodIndex;

                        // Require payment method selection.
                        if (selectedPaymentIndex == -1) {
                          showCustomSnackBar('يرجى اختيار طريقة الدفع',
                              isError: true);
                          controller.setLoading(false, ids: ['payment']);
                          return;
                        }

                        // 2) Strict balance checks before continuing.
                        // If Qidha wallet is selected (index 0) and balance is insufficient.
                        if (selectedPaymentIndex == 0) {
                          if (qidhaBalance < total) {
                            showCustomSnackBar(
                                'عفوًا، رصيد "قيدها" (${PriceConverter.convertPrice(qidhaBalance)}) غير كافٍ لإتمام الطلب (${PriceConverter.convertPrice(total)})',
                                isError: true);
                            return; // Stop immediately and do not continue.
                          }
                        }
                        // If regular wallet is selected (index 1) and balance is insufficient.
                        else if (selectedPaymentIndex == 1) {
                          if (myWalletBalance < total) {
                            showCustomSnackBar(
                                'عفوًا، رصيد المحفظة (${PriceConverter.convertPrice(myWalletBalance)}) غير كافٍ لإتمام الطلب',
                                isError: true);
                            return; // Stop immediately and do not continue.
                          }
                        }

                        // 3) Prevent duplicate payment flows.
                        if (checkoutController.isPaymentFlowInProgress &&
                            checkoutController.paymentFlowState !=
                                PaymentFlowState.preparingPayment) {
                          if (!checkoutController.isLoading) {
                            checkoutController.resetPaymentState();
                          } else {
                            showCustomSnackBar(
                                'Please wait, processing previous request...');
                            return;
                          }
                        }

                        if (checkoutController.paymentFlowState ==
                            PaymentFlowState.failed) {
                          checkoutController.resetPaymentState();
                        }

                        if (checkoutController.distance == null) {
                          showCustomSnackBar('انتظر لحظات، يتم حساب التوصيل');
                          return;
                        }

                        // Remaining validation (time slots / guest fields) stays unchanged.
                        bool isAvailable = true;
                        DateTime scheduleStartDate = DateTime.now();
                        DateTime scheduleEndDate = DateTime.now();

                        if (checkoutController.store!.scheduleOrder! &&
                            (checkoutController.timeSlots == null ||
                                checkoutController.timeSlots!.isEmpty)) {
                          isAvailable = false;
                        } else if (checkoutController.store!.scheduleOrder! &&
                            checkoutController.timeSlots != null &&
                            checkoutController.timeSlots!.isNotEmpty) {
                          final DateTime date =
                              checkoutController.selectedDateSlot == 0
                                  ? DateTime.now()
                                  : DateTime.now().add(const Duration(days: 1));
                          final DateTime startTime = checkoutController
                              .timeSlots![checkoutController.selectedTimeSlot]
                              .startTime!;
                          final DateTime endTime = checkoutController
                              .timeSlots![checkoutController.selectedTimeSlot]
                              .endTime!;
                          scheduleStartDate = DateTime(date.year, date.month,
                              date.day, startTime.hour, startTime.minute + 1);
                          scheduleEndDate = DateTime(date.year, date.month,
                              date.day, endTime.hour, endTime.minute + 1);
                          if (_cartList != null) {
                            for (final CartModel? cart in _cartList!) {
                              if (!DateConverter.isAvailable(
                                    cart!.item!.availableTimeStarts,
                                    cart.item!.availableTimeEnds,
                                    time:
                                        checkoutController.store!.scheduleOrder!
                                            ? scheduleStartDate
                                            : null,
                                  ) &&
                                  !DateConverter.isAvailable(
                                    cart.item!.availableTimeStarts,
                                    cart.item!.availableTimeEnds,
                                    time:
                                        checkoutController.store!.scheduleOrder!
                                            ? scheduleEndDate
                                            : null,
                                  )) {
                                isAvailable = false;
                                break;
                              }
                            }
                          }
                        }

                        if (isGuestLogIn &&
                            checkoutController.guestAddress == null &&
                            checkoutController.orderType != 'take_away') {
                          showCustomSnackBar(
                              'please_setup_your_delivery_address_first'.tr);
                        } else if (isGuestLogIn &&
                            checkoutController.orderType == 'take_away' &&
                            guestContactPersonNameController.text.isEmpty) {
                          showCustomSnackBar(
                              'please_enter_contact_person_name'.tr);
                        } else if (isGuestLogIn &&
                            checkoutController.orderType == 'take_away' &&
                            guestContactPersonNumberController.text.isEmpty) {
                          showCustomSnackBar(
                              'please_enter_contact_person_number'.tr);
                        } else if (isGuestLogIn &&
                            checkoutController.orderType == 'take_away' &&
                            guestEmailController.text.isEmpty) {
                          showCustomSnackBar(
                              'please_enter_contact_person_email'.tr);
                        } else if (isGuestLogIn &&
                            checkoutController.isCreateAccount &&
                            guestPasswordController.text.isEmpty) {
                          showCustomSnackBar('enter_password'.tr);
                        } else if (isGuestLogIn &&
                            checkoutController.isCreateAccount &&
                            guestConfirmPasswordController.text.isEmpty) {
                          showCustomSnackBar('enter_confirm_password'.tr);
                        } else if (isGuestLogIn &&
                            checkoutController.isCreateAccount &&
                            (guestPasswordController.text !=
                                guestConfirmPasswordController.text)) {
                          showCustomSnackBar(
                              'confirm_password_does_not_matched'.tr);
                        } else if (isPrescriptionRequired &&
                            checkoutController.pickedPrescriptions.isEmpty) {
                          showCustomSnackBar(
                              'you_must_upload_prescription_for_this_order'.tr);
                        }

                        // 4) If no payment method was chosen, open payment selector.
                        else if (selectedPaymentIndex == -1) {
                          if (ResponsiveHelper.isDesktop(context)) {
                            Get.dialog<void>(const Dialog(
                              backgroundColor: Colors.transparent,
                              child: PaymentMethodBottomSheet(),
                            ));
                          } else {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  const PaymentMethodBottomSheet(),
                            );
                          }
                          return;
                        }

                        if (orderAmount <
                                checkoutController.store!.minimumOrder! &&
                            effectiveStoreId == null) {
                          showCustomSnackBar(
                              '${'minimum_order_amount_is'.tr} ${checkoutController.store!.minimumOrder}');
                        } else if (checkoutController
                                .tipController.text.isNotEmpty &&
                            checkoutController.tipController.text !=
                                'not_now' &&
                            double.parse(checkoutController.tipController.text
                                    .trim()) <
                                0) {
                          showCustomSnackBar('tips_can_not_be_negative'.tr);
                        } else if (checkoutController.paymentMethodIndex == 0 &&
                            _isCashOnDeliveryActive! &&
                            maxCodOrderAmount != null &&
                            maxCodOrderAmount != 0 &&
                            (total > maxCodOrderAmount) &&
                            effectiveStoreId == null) {
                          showCustomSnackBar(
                              '${'you_cant_order_more_then'.tr} ${PriceConverter.convertPrice2(maxCodOrderAmount)} ${'in_cash_on_delivery'.tr}');
                        } else if (checkoutController.store!.scheduleOrder! &&
                            (checkoutController.timeSlots == null ||
                                checkoutController.timeSlots!.isEmpty)) {
                          showCustomSnackBar('select_a_time'.tr);
                        } else if (!isAvailable) {
                          showCustomSnackBar(
                              'one_or_more_products_are_not_available_for_this_selected_time'
                                  .tr);
                        } else if (checkoutController.orderType !=
                                'take_away' &&
                            checkoutController.distance == -1 &&
                            deliveryCharge == -1) {
                          showCustomSnackBar('delivery_fee_not_set_yet'.tr);
                        } else if (isPrescriptionRequired &&
                            checkoutController.pickedPrescriptions.isEmpty) {
                          showCustomSnackBar(
                              'please_upload_your_prescription_images'.tr);
                        } else if (!checkoutController.acceptTerms) {
                          showCustomSnackBar(
                              'please_accept_privacy_policy_trams_conditions_refund_policy_first'
                                  .tr);
                        } else {
                          AddressModel? finalAddress = isGuestLogIn
                              ? checkoutController.guestAddress
                              : address[checkoutController.addressIndex!];

                          if (isGuestLogIn &&
                              checkoutController.orderType == 'take_away') {
                            final String number =
                                checkoutController.countryDialCode! +
                                    guestContactPersonNumberController.text;
                            finalAddress = AddressModel(
                              contactPersonName:
                                  guestContactPersonNameController.text,
                              contactPersonNumber: number,
                              address: currentAddress!.address!,
                              latitude: currentAddress!.latitude,
                              longitude: currentAddress!.longitude,
                              zoneId: currentAddress!.zoneId,
                              email: guestEmailController.text,
                            );
                          }

                          if (!isGuestLogIn &&
                              finalAddress != null &&
                              finalAddress.contactPersonNumber == 'null') {
                            finalAddress.contactPersonNumber =
                                Get.find<ProfileController>()
                                    .userInfoModel!
                                    .phone;
                          }

                          final AddressModel payloadAddress = finalAddress ??
                              currentAddress ??
                              AddressModel(
                                address: '',
                                latitude: '',
                                longitude: '',
                              );

                          final bool usePrescriptionFlow =
                              isPrescriptionRequired ||
                                  checkoutController
                                      .pickedPrescriptions.isNotEmpty;

                          if (effectiveStoreId == null ||
                              !usePrescriptionFlow) {
                            final List<OnlineCart> carts = [];
                            for (int index = 0;
                                index < _cartList!.length;
                                index++) {
                              final CartModel cart = _cartList![index]!;
                              final List<int?> addOnIdList = [];
                              final List<int?> addOnQtyList = [];
                              for (final addOn in cart.addOnIds!) {
                                addOnIdList.add(addOn.id);
                                addOnQtyList.add(addOn.quantity);
                              }

                              final List<OrderVariation> variations = [];
                              // Variations logic remains the same as before.

                              carts.add(OnlineCart(
                                cart.id,
                                cart.item!.id,
                                cart.isCampaign! ? cart.item!.id : null,
                                cart.discountedPrice.toString(),
                                '',
                                (variations.isEmpty &&
                                        cart.variation != null &&
                                        cart.variation!.isNotEmpty)
                                    ? cart.variation
                                    : null,
                                variations.isNotEmpty ? variations : null,
                                cart.quantity,
                                addOnIdList,
                                cart.addOns,
                                addOnQtyList,
                                'Item',
                                itemType: !widget.fromCart
                                    ? 'AppModelsItemCampaign'
                                    : null,
                                storeId: cart.item!.storeId,
                              ));
                            }

                            // 5) Send the exact selected payment method to backend.
                            final String? finalPaymentMethod =
                                selectedPaymentIndex == 0
                                    ? 'wallet_qidha'
                                    : selectedPaymentIndex == 1
                                        ? 'wallet'
                                        : selectedPaymentIndex == 2
                                            ? 'digital_payment'
                                            : null;

                            debugPrint(
                                '🔍 Final Payment Method: $finalPaymentMethod (Index: $selectedPaymentIndex)');

                            final String determinedOrderType =
                                checkoutController.orderType ?? 'delivery';

                            if (finalAddress == null &&
                                determinedOrderType != 'take_away') {
                              showCustomSnackBar(
                                  'please_select_your_location'.tr);
                              return;
                            }

                            final bool hasValidLocation =
                                finalAddress != null &&
                                    finalAddress.latitude != null &&
                                    finalAddress.longitude != null &&
                                    finalAddress.latitude!.trim().isNotEmpty &&
                                    finalAddress.longitude!.trim().isNotEmpty;
                            if (determinedOrderType != 'take_away' &&
                                !hasValidLocation) {
                              showCustomSnackBar(
                                  'please_select_your_location'.tr);
                              return;
                            }

                            final PlaceOrderBodyModel placeOrderBody =
                                PlaceOrderBodyModel(
                              cart: carts,
                              couponDiscountAmount:
                                  Get.find<CouponController>().discount,
                              distance: checkoutController.distance,
                              scheduleAt: !checkoutController
                                      .store!.scheduleOrder!
                                  ? null
                                  : (checkoutController.selectedDateSlot == 0 &&
                                          checkoutController.selectedTimeSlot ==
                                              0)
                                      ? null
                                      : DateConverter.dateToDateAndTime(
                                          scheduleEndDate),
                              orderAmount: total,
                              orderNote: checkoutController.noteController.text,
                              orderType: determinedOrderType,

                              // Use the resolved payment method value.
                              paymentMethod: finalPaymentMethod,

                              couponCode: (Get.find<CouponController>()
                                              .discount! >
                                          0 ||
                                      (Get.find<CouponController>().coupon !=
                                              null &&
                                          Get.find<CouponController>()
                                              .freeDelivery))
                                  ? Get.find<CouponController>().coupon!.code
                                  : null,
                              storeId: _cartList![0]!.item!.storeId,
                              branchId: _cartList![0]!.item!.storeId,
                              address: payloadAddress.address ?? '',
                              latitude: payloadAddress.latitude ?? '',
                              longitude: payloadAddress.longitude ?? '',
                              senderZoneId: null,
                              addressType: payloadAddress.addressType,
                              contactPersonName: payloadAddress
                                      .contactPersonName ??
                                  '${Get.find<ProfileController>().userInfoModel!.fName} '
                                      '${Get.find<ProfileController>().userInfoModel!.lName}',
                              contactPersonNumber:
                                  payloadAddress.contactPersonNumber ??
                                      Get.find<ProfileController>()
                                          .userInfoModel!
                                          .phone,
                              streetNumber: isGuestLogIn
                                  ? payloadAddress.streetNumber ?? ''
                                  : checkoutController
                                      .streetNumberController.text
                                      .trim(),
                              house: isGuestLogIn
                                  ? payloadAddress.house ?? ''
                                  : checkoutController.houseController.text
                                      .trim(),
                              floor: isGuestLogIn
                                  ? payloadAddress.floor ?? ''
                                  : checkoutController.floorController.text
                                      .trim(),
                              discountAmount: discount,
                              taxAmount: tax,
                              receiverDetails: null,
                              parcelCategoryId: null,
                              chargePayer: null,
                              dmTips: (checkoutController.orderType ==
                                          'take_away' ||
                                      checkoutController.tipController.text ==
                                          'not_now')
                                  ? ''
                                  : checkoutController.tipController.text
                                      .trim(),
                              cutlery:
                                  Get.find<CartController>().addCutlery ? 1 : 0,
                              unavailableItemNote: Get.find<CartController>()
                                          .notAvailableIndex !=
                                      -1
                                  ? Get.find<CartController>().notAvailableList[
                                      Get.find<CartController>()
                                          .notAvailableIndex]
                                  : '',
                              deliveryInstruction:
                                  checkoutController.selectedInstruction != -1
                                      ? AppConstants.deliveryInstructionList[
                                          checkoutController
                                              .selectedInstruction]
                                      : '',
                              partialPayment:
                                  checkoutController.isPartialPay ? 1 : 0,
                              guestId: isGuestLogIn
                                  ? int.parse(AuthHelper.getGuestId())
                                  : 0,
                              isBuyNow: widget.fromCart ? 0 : 1,
                              guestEmail: isGuestLogIn
                                  ? payloadAddress.email
                                  : (Get.find<ProfileController>()
                                          .userInfoModel
                                          ?.email ??
                                      ''),
                              extraPackagingAmount:
                                  Get.find<CartController>().needExtraPackage
                                      ? checkoutController
                                          .store!.extraPackagingAmount
                                      : 0,
                              createNewUser:
                                  checkoutController.isCreateAccount ? 1 : 0,
                              password: guestPasswordController.text,
                            );

                            // Step 1: Create Order
                            debugPrint(
                                '\x1B[32m📋 Step 1: Creating Order (Unpaid)...\x1B[0m');

                            final String orderID =
                                await checkoutController.createOrder(
                              context,
                              placeOrderBody,
                              checkoutController.pickedPrescriptions,
                            );

                            if (!mounted) {
                              return;
                            }

                            if (orderID.isEmpty) {
                              showCustomSnackBar('فشل في إنشاء الطلب');
                              return;
                            }

                            // Step 2: Process Payment
                            final String paymentResult =
                                await checkoutController.processPayment(
                              context,
                              Get.find<KaidhaSubscriptionController>(),
                              Get.find<ProfileController>(),
                              checkoutController.store!.zoneId,
                              maxCodOrderAmount,
                              widget.fromCart,
                              _isCashOnDeliveryActive!,
                              payloadAddress.contactPersonNumber ?? '',
                            );
                            if (paymentResult.isEmpty) {
                              debugPrint(
                                  '❌ Payment Process Result: FAILED (empty orderId returned)');
                            } else {
                              debugPrint(
                                  '✅ Payment Process Result: SUCCESS (orderId=$paymentResult)');
                            }
                          } else {
                            // Prescription Logic remains the same
                            checkoutController.placePrescriptionOrder(
                                context,
                                effectiveStoreId,
                                checkoutController.store!.zoneId,
                                checkoutController.distance,
                                payloadAddress.address ?? '',
                                payloadAddress.longitude ?? '',
                                payloadAddress.latitude ?? '',
                                checkoutController.noteController.text,
                                checkoutController.pickedPrescriptions,
                                (checkoutController.orderType == 'take_away' ||
                                        checkoutController.tipController.text ==
                                            'not_now')
                                    ? ''
                                    : checkoutController.tipController.text
                                        .trim(),
                                checkoutController.selectedInstruction != -1
                                    ? AppConstants.deliveryInstructionList[
                                        checkoutController.selectedInstruction]
                                    : '',
                                0,
                                0,
                                widget.fromCart,
                                _isCashOnDeliveryActive!);
                          }
                        }
                      } finally {
                        if (!controller.isPaymentFlowInProgress) {
                          controller.setLoading(false, ids: ['payment']);
                        }
                        controller.finishPlaceOrder();
                      }
                    }
                  : null),
        ),
      ),
    );
  }

  List<AddressModel> _getZoneMatchedAddresses({
    required List<AddressModel>? addressList,
    required Store? store,
  }) {
    final List<AddressModel> filtered = [];
    if (addressList != null && store != null) {
      for (final model in addressList) {
        if (model.zoneIds?.contains(store.zoneId) ?? false) {
          filtered.add(model);
        }
      }
    }
    return filtered;
  }

  List<DropdownItem<int>> _getDropdownAddressList(
      {required BuildContext context,
      required List<AddressModel>? addressList,
      required Store? store}) {
    final List<DropdownItem<int>> dropDownAddressList = [];
    final List<AddressModel> filteredAddresses =
        _getZoneMatchedAddresses(addressList: addressList, store: store);

    if (filteredAddresses.isNotEmpty) {
      for (int index = 0; index < filteredAddresses.length; index++) {
        dropDownAddressList.add(DropdownItem<int>(
            value: index + 1,
            child: SizedBox(
              width: context.width > Dimensions.webMaxWidth
                  ? Dimensions.webMaxWidth - 50
                  : context.width - 50,
              child: AddressWidget(
                address: filteredAddresses[index],
                fromAddress: false,
                fromCheckout: true,
              ),
            )));
      }
    } else {
      dropDownAddressList.add(DropdownItem<int>(
          value: 0,
          child: SizedBox(
            width: context.width > Dimensions.webMaxWidth
                ? Dimensions.webMaxWidth - 50
                : context.width - 50,
            child: AddressWidget(
              address: currentAddress,
              fromAddress: false,
              fromCheckout: true,
            ),
          )));
    }
    return dropDownAddressList;
  }

  List<AddressModel> _getAddressList(
      {required List<AddressModel>? addressList, required Store? store}) {
    final List<AddressModel> filteredAddresses =
        _getZoneMatchedAddresses(addressList: addressList, store: store);
    if (filteredAddresses.isNotEmpty) {
      return filteredAddresses;
    }
    return currentAddress != null ? [currentAddress!] : [];
  }

  Pivot? _getModuleData({required Store? store}) {
    Pivot? moduleData;
    if (store != null && currentAddress?.zoneData != null) {
      for (final ZoneData zData in currentAddress!.zoneData!) {
        for (final Modules m in zData.modules!) {
          if (m.id == Get.find<SplashController>().module!.id &&
              m.pivot!.zoneId == store.zoneId) {
            moduleData = m.pivot;
            break;
          }
        }
      }
    }
    return moduleData;
  }

  /// Store-open validation rules:
  /// 1. Store is administratively active (active == true).
  /// 2. Store status is open (status == 1), if available.
  /// 3. Store is currently open (isOpenNow == true) from backend.
  ///
  /// Note: scheduleOrder == true does not mean store is closed;
  /// it means scheduled orders are allowed.

  bool _checkCODActive({required Store? store}) {
    // COD disabled - always return false
    return false;
  }

  bool _checkDigitalPaymentActive({required Store? store}) {
    bool isDigitalPaymentActive = false;
    if (store != null && currentAddress?.zoneData != null) {
      for (final ZoneData zData in currentAddress!.zoneData!) {
        if (zData.id == store.zoneId) {
          isDigitalPaymentActive = zData.digitalPayment! &&
              Get.find<SplashController>().configModel!.digitalPayment!;
        }
      }
    }
    return isDigitalPaymentActive;
  }

  double _calculatePrice(
      {required Store? store, required List<CartModel?>? cartList}) {
    double price = 0;
    appLogger.debug(
        '💰 _calculatePrice: cartList length = ${cartList?.length ?? 0}');

    // RELEASE MODE FIX: If cartList is null or empty, try to get it from CartController
    if (cartList == null || cartList.isEmpty) {
      appLogger.debug(
          '💰 RELEASE MODE FIX: CartList is null/empty, trying CartController');
      cartList = Get.find<CartController>().cartList;
      appLogger.debug(
          '💰 RELEASE MODE FIX: Got cart from CartController - ${cartList.length} items');
    }

    if (cartList.isNotEmpty) {
      for (final cartModel in cartList) {
        if (cartModel != null && cartModel.item != null) {
          appLogger.debug(
              '💰 Item: ${cartModel.item!.name} - Price: ${cartModel.price} - Qty: ${cartModel.quantity}');

          // 🔒 SAFE NULL HANDLING: Use null-coalescing for price and quantity
          final itemPrice =
              (cartModel.price ?? 0.0) * (cartModel.quantity ?? 0);

          if ((Get.find<SplashController>()
                  .getModuleConfig(cartModel.item!.moduleType)
                  .newVariation ??
              false)) {
            // Use the discounted price from cart, not the original item price
            price = price + itemPrice;
            appLogger.debug('💰 Added item price: $itemPrice (new variation)');
          } else {
            // Use the discounted price from cart for variations too
            price = price + itemPrice;
            appLogger.debug('💰 Added item price: $itemPrice (variation)');
          }
        }
      }
    } else {
      appLogger
          .error('❌ CRITICAL: CartList is still null or empty after fallback!');
    }

    appLogger.debug('💰 Final calculated price: $price');
    return PriceConverter.toFixed(price);
  }

  double _calculateAddonsPrice(
      {required Store? store, required List<CartModel?>? cartList}) {
    double addOns = 0;
    if (store != null && cartList != null) {
      for (final cartModel in cartList) {
        final List<AddOns> addOnList = [];
        for (final addOnId in cartModel!.addOnIds!) {
          for (final AddOns addOns in cartModel.item!.addOns!) {
            if (addOns.id == addOnId.id) {
              addOnList.add(addOns);
              break;
            }
          }
        }
        for (int index = 0; index < addOnList.length; index++) {
          addOns = addOns +
              (addOnList[index].price! * cartModel.addOnIds![index].quantity!);
        }
      }
    }
    return PriceConverter.toFixed(addOns);
  }

  double _calculateVariationPrice(
      {required Store? store,
      required List<CartModel?>? cartList,
      bool calculateDiscount = false,
      bool calculateWithoutDiscount = false}) {
    double variationPrice = 0;
    double variationDiscount = 0;
    if (store != null && cartList != null) {
      for (final cartModel in cartList) {
        if (cartModel?.item == null) {
          continue;
        }
        final item = cartModel!.item!;
        final double? discount =
            item.storeDiscount == 0 ? item.discount : item.storeDiscount;
        final String? discountType =
            item.storeDiscount == 0 ? item.discountType : 'percent';

        if ((Get.find<SplashController>()
                .getModuleConfig(item.moduleType)
                .newVariation ??
            false)) {
          isPassedVariationPrice = true;
          if (item.foodVariations == null ||
              item.foodVariations!.isEmpty ||
              cartModel.foodVariations == null) {
            continue;
          }
          for (int index = 0; index < item.foodVariations!.length; index++) {
            if (index >= cartModel.foodVariations!.length) {
              break;
            }
            for (int i = 0;
                i < item.foodVariations![index].variationValues!.length;
                i++) {
              if (i < cartModel.foodVariations![index].length &&
                  cartModel.foodVariations![index][i] == true) {
                final optionPrice = item
                    .foodVariations![index].variationValues![i].optionPrice!;
                variationPrice += (PriceConverter.convertWithDiscount(
                        optionPrice, discount, discountType,
                        isFoodVariation: true)! *
                    (cartModel.quantity ?? 0));
                variationDiscount += (optionPrice * (cartModel.quantity ?? 0));
              }
            }
          }
        } else {
          String variationType = '';
          if (cartModel.variation == null || cartModel.variation!.isEmpty) {
            continue;
          }
          for (int i = 0; i < cartModel.variation!.length; i++) {
            variationType = cartModel.variation![i].type ?? '';
          }

          if (item.variations != null && item.variations!.isNotEmpty) {
            for (final Variation variation in item.variations!) {
              if (variation.type == variationType) {
                variationPrice +=
                    (variation.price! * (cartModel.quantity ?? 0));
                break;
              }
            }
          } else {
            variationDiscount += (PriceConverter.convertWithDiscount(
                    item.price!, discount, discountType)! *
                (cartModel.quantity ?? 0));
            variationPrice += (item.price! * (cartModel.quantity ?? 0));
          }
        }
      }
    }
    if (calculateDiscount) {
      return (variationDiscount - variationPrice);
    } else if (calculateWithoutDiscount) {
      return variationDiscount;
    } else {
      return variationPrice;
    }
  }

  double _calculateDiscount(
      {required Store? store,
      required List<CartModel?>? cartList,
      required double price,
      required double addOns}) {
    // Since we're using discounted prices from cart, no additional discount calculation needed
    // The discount shown should only be for promo codes, not item discounts
    return 0.0;
  }

  double _calculateOrderAmount(
      {required double price,
      required double variations,
      required double? discount,
      required double addOns,
      required double couponDiscount,
      required List<CartModel?>? cartList,
      required double referralDiscount}) {
    double orderAmount = 0;
    double variationPrice = 0;
    if (cartList != null &&
        cartList.isNotEmpty &&
        (Get.find<SplashController>()
                .getModuleConfig(cartList[0]?.item?.moduleType)
                .newVariation ??
            false)) {
      variationPrice = variations;
    }
    orderAmount = (price + variationPrice - (discount ?? 0.0)) +
        addOns -
        couponDiscount -
        referralDiscount;
    return PriceConverter.toFixed(orderAmount);
  }

  double _calculateTax(
      {required bool taxIncluded,
      required double orderAmount,
      required double? taxPercent}) {
    double tax = 0;
    // 🔒 SAFE NULL HANDLING: Use null-coalescing instead of null check operator
    final safeTaxPercent = taxPercent ?? 0.0;
    if (taxIncluded && safeTaxPercent > 0) {
      tax = orderAmount * safeTaxPercent / (100 + safeTaxPercent);
    } else if (safeTaxPercent > 0) {
      tax =
          PriceConverter.calculation(orderAmount, safeTaxPercent, 'percent', 1);
    }
    return PriceConverter.toFixed(tax);
  }

  double _resolveTaxPercent(double? storeTaxPercent) {
    if (storeTaxPercent == null || storeTaxPercent <= 0) {
      return 15.0;
    }
    return storeTaxPercent;
  }

  /// Calculate items subtotal (prices only, no tax) - same as cart screen itemPrice
  double _calculateItemsSubtotal({
    required List<CartModel?>? cartList,
  }) {
    if (cartList == null || cartList.isEmpty) {
      return 0.0;
    }

    // Calculate subtotal from cart items (discounted prices) - same as cartController.itemPrice
    // 🔒 SAFE NULL HANDLING: Use null-coalescing for price and quantity
    double itemsSubTotal = 0;
    for (final cartModel in cartList) {
      if (cartModel != null && cartModel.item != null) {
        itemsSubTotal += (cartModel.price ?? 0.0) * (cartModel.quantity ?? 0);
      }
    }

    appLogger.debug('🛒 Items Subtotal (no tax): $itemsSubTotal');

    return PriceConverter.toFixed(itemsSubTotal);
  }

  double _calculateOriginalDeliveryCharge(
      {required Store? store,
      required AddressModel address,
      required double? distance,
      required double? extraCharge}) {
    // ✅ BACKEND CONTRACT: Store and address.zoneData must be provided by backend
    // No fallbacks - backend is source of truth
    if (store == null) {
      debugPrint(
          '❌ _calculateOriginalDeliveryCharge: Store is null - backend must provide store data');
      return 0.0;
    }
    if (address.zoneData == null || address.zoneData!.isEmpty) {
      debugPrint(
          '❌ _calculateOriginalDeliveryCharge: address.zoneData is null or empty - backend must provide zone data');
      return 0.0;
    }

    double deliveryCharge = -1;

    Pivot? moduleData;
    ZoneData? zoneData;

    // 🔥 PERFORMANCE: Only log in debug mode and when data is actually available
    if (kDebugMode) {
      debugPrint('🔍 [_calculateOriginalDeliveryCharge] Zone matching:');
      debugPrint('   - Store zoneId: ${store.zoneId}');
      debugPrint('   - Address zoneData count: ${address.zoneData!.length}');
      debugPrint('   - Module ID: ${Get.find<SplashController>().module?.id}');
    }

    for (final ZoneData zData in address.zoneData!) {
      if (kDebugMode) {
        debugPrint('   - Checking zone: id=${zData.id}');
      }

      if (zData.modules != null) {
        for (final Modules m in zData.modules!) {
          if (m.id == Get.find<SplashController>().module!.id &&
              m.pivot!.zoneId == store.zoneId) {
            moduleData = m.pivot;
            if (kDebugMode) {
              debugPrint(
                  '   ✅ Found matching module data for zone: ${zData.id}');
              if (moduleData != null) {
                debugPrint('   📊 ModuleData (Pivot) values:');
                debugPrint(
                    '      - perKmShippingCharge: ${moduleData.perKmShippingCharge}');
                debugPrint(
                    '      - firstKmFee: ${moduleData.firstKmFee}');
                debugPrint(
                    '      - firstKmDistance: ${moduleData.firstKmDistance}');
                debugPrint(
                    '      - minimumShippingCharge: ${moduleData.minimumShippingCharge}');
                debugPrint(
                    '      - maximumShippingCharge: ${moduleData.maximumShippingCharge}');
              }
            }
            break;
          }
        }
      }

      if (zData.id == store.zoneId) {
        zoneData = zData;
        if (kDebugMode) {
          debugPrint('   ✅ Found matching zoneData: id=${zData.id}');
        }
      }
    }

    if (zoneData == null && kDebugMode) {
      debugPrint(
          '   ⚠️ No matching zoneData found for store zoneId: ${store.zoneId}');
      debugPrint(
          '   - Available zone IDs: ${address.zoneData!.map((z) => z.id).toList()}');
    }
    double perKmCharge = 0;
    double minimumCharge = 0;
    double? maximumCharge = 0;
    double? firstKmFee;
    double? firstKmDistance;
    String chargeSource = 'none';

    // After early return, store and distance are guaranteed to be non-null
    if (distance != null && distance != -1 && store.selfDeliverySystem == 1) {
      // Self-delivery: use store values
      perKmCharge = store.perKmShippingCharge ?? 0.0;
      minimumCharge = store.minimumShippingCharge ?? 0.0;
      maximumCharge = store.maximumShippingCharge;
      firstKmFee = store.firstKmFee;
      firstKmDistance = store.firstKmDistance;
      chargeSource = 'store (self-delivery)';
    } else if (distance != null && distance != -1 && moduleData != null) {
      // Module-based delivery: use moduleData (pivot) values
      final pivot = moduleData; // Already checked for null above
      perKmCharge = pivot.perKmShippingCharge ?? 0.0;
      minimumCharge = pivot.minimumShippingCharge ?? 0.0;
      maximumCharge = pivot.maximumShippingCharge;
      firstKmFee = pivot.firstKmFee;
      firstKmDistance = pivot.firstKmDistance;
      chargeSource = 'moduleData (pivot)';
    }

    // 🔥 PERFORMANCE: Only log in debug mode to reduce log noise
    // After early return, store and distance are guaranteed to be non-null
    if (kDebugMode && distance != null && distance != -1) {
      debugPrint('💰 Delivery Charge Source: $chargeSource');
      debugPrint('   - perKmCharge: $perKmCharge');
      debugPrint('   - minimumCharge: $minimumCharge');
      debugPrint('   - maximumCharge: $maximumCharge');
      debugPrint('   - firstKmFee: $firstKmFee');
      debugPrint('   - firstKmDistance: $firstKmDistance');
      debugPrint('   - distance: $distance km');
    }

    // After early return, store and distance are guaranteed to be non-null
    if (distance != null) {
      // Check for tiered pricing (first X km = fixed fee, then simple multiplication)
      if (firstKmFee != null &&
          firstKmFee > 0 &&
          firstKmDistance != null &&
          firstKmDistance > 0) {
        // Backend logic: if distance <= firstKmDistance, use firstKmFee
        // If distance > firstKmDistance, use simple multiplication (distance x perKm).
        if (distance <= firstKmDistance) {
          deliveryCharge = firstKmFee;
          if (kDebugMode) {
            debugPrint(
                'Delivery: distance ($distance km) <= first tier ($firstKmDistance km) = $firstKmFee SAR');
          }
        } else {
          // CORRECT: Simple multiplication when distance > firstKmDistance (matches backend)
          deliveryCharge = distance * perKmCharge;
          if (kDebugMode) {
            debugPrint(
                'Delivery: $distance km x $perKmCharge = $deliveryCharge SAR');
          }
        }

        // Apply maximum charge limit if set
        if (maximumCharge != null &&
            maximumCharge > 0 &&
            deliveryCharge > maximumCharge) {
          deliveryCharge = maximumCharge;
          if (kDebugMode) {
            debugPrint('Delivery capped to maximum: $maximumCharge SAR');
          }
        }
      } else {
        // Fallback to old calculation (distance x per-km rate with min/max).
        deliveryCharge = distance * perKmCharge;
        if (kDebugMode) {
          debugPrint(
              'Standard Delivery: $distance km x $perKmCharge = $deliveryCharge SAR');
        }

        if (deliveryCharge < minimumCharge) {
          deliveryCharge = minimumCharge;
          if (kDebugMode) {
            debugPrint('Delivery applied minimum: $minimumCharge SAR');
          }
        } else if (maximumCharge != null &&
            maximumCharge > 0 &&
            deliveryCharge > maximumCharge) {
          deliveryCharge = maximumCharge;
          if (kDebugMode) {
            debugPrint('Delivery applied maximum: $maximumCharge SAR');
          }
        }
      }
    }

    // Store extraCharge for tooltip display, but DON'T add it to delivery charge
    // Delivery charge should only show the distance-based calculation (14.15 SAR)
    // ExtraCharge is a separate fee that should be shown separately
    // After early return, store is guaranteed to be non-null
    if (store.selfDeliverySystem == 0 && extraCharge != null) {
      extraChargeForToolTip = extraCharge;
      // REMOVED: deliveryCharge = deliveryCharge + extraCharge;
      // ExtraCharge should NOT be added to delivery charge - it's a separate fee
    }

    // After early return, store is guaranteed to be non-null
    if (store.selfDeliverySystem == 0 &&
        zoneData != null &&
        zoneData.increaseDeliveryFeeStatus == 1) {
      badWeatherChargeForToolTip =
          (deliveryCharge * (zoneData.increaseDeliveryFee! / 100));
      deliveryCharge = deliveryCharge +
          (deliveryCharge * (zoneData.increaseDeliveryFee! / 100));
    }

    return deliveryCharge;
  }

  double _calculateDeliveryCharge(
      {required Store? store,
      required AddressModel address,
      required double? distance,
      required double? extraCharge,
      required double orderAmount,
      required String orderType}) {
    double deliveryCharge = _calculateOriginalDeliveryCharge(
        store: store,
        address: address,
        distance: distance,
        extraCharge: extraCharge);

    if (orderType == 'take_away' ||
        (store != null && store.freeDelivery!) ||
        (Get.find<SplashController>().configModel!.freeDeliveryOver != null &&
            orderAmount >=
                Get.find<SplashController>().configModel!.freeDeliveryOver!) ||
        Get.find<CouponController>().freeDelivery ||
        (AuthHelper.isGuestLoggedIn() &&
            (Get.find<CheckoutController>().guestAddress == null &&
                Get.find<CheckoutController>().orderType != 'take_away'))) {
      deliveryCharge = 0;
    }

    return PriceConverter.toFixed(deliveryCharge);
  }

  double _calculateTotal({
    required double subTotal,
    required double deliveryCharge,
    required double? discount,
    required double couponDiscount,
    required bool taxIncluded,
    required double tax,
    required String orderType,
    required double tips,
    required double additionalCharge,
    required double extraPackagingCharge,
  }) {
    // Subtotal is now items prices only (no tax), so add tax if not included
    return PriceConverter.toFixed(subTotal +
        deliveryCharge -
        (discount ?? 0.0) -
        couponDiscount +
        (taxIncluded ? 0 : tax) + // Add tax only if not included in prices
        additionalCharge +
        ((orderType != 'take_away' &&
                Get.find<SplashController>().configModel!.dmTipsStatus == 1)
            ? tips
            : 0) +
        extraPackagingCharge);
  }

  bool _checkZoneOfflinePaymentOnOff(
      {required AddressModel? addressModel,
      required CheckoutController checkoutController}) {
    bool? status = false;
    ZoneData? zoneData;
    for (final data in addressModel!.zoneData!) {
      if (data.id == checkoutController.store?.zoneId) {
        zoneData = data;
        break;
      }
    }
    status = zoneData?.offlinePayment ?? false;
    return status;
  }

  double _calculateExtraPackagingCharge(CheckoutController checkoutController) {
    if ((checkoutController.store?.extraPackagingStatus ?? true) &&
        (Get.find<CartController>().needExtraPackage)) {
      return checkoutController.store?.extraPackagingAmount ?? 0;
    }
    return 0;
  }

  double _calculateReferralDiscount(
      double subTotal, double? discount, double couponDiscount) {
    double referralDiscount = 0;

    // 🔒 SAFE NULL HANDLING: Remove all null check operators
    final profileController = Get.find<ProfileController>();
    final userInfoModel = profileController.userInfoModel;

    if (userInfoModel != null && (userInfoModel.isValidForDiscount ?? false)) {
      final discountAmountType = userInfoModel.discountAmountType ?? 'fixed';
      final discountAmount = userInfoModel.discountAmount ?? 0.0;

      if (discountAmountType == 'percentage') {
        referralDiscount = (discountAmount / 100) *
            (subTotal - (discount ?? 0.0) - couponDiscount);
      } else {
        referralDiscount = discountAmount;
      }
    }

    return PriceConverter.toFixed(referralDiscount);
  }

  Future<void> showCashBackSnackBar() async {
    await Get.find<HomeController>().getCashBackData(_payableAmount!);
    final double cashBackAmount =
        Get.find<HomeController>().cashBackData?.cashbackAmount ?? 0.0;
    final String cashBackType =
        Get.find<HomeController>().cashBackData?.cashbackType ?? '';

    final String text =
        '${'you_will_get'.tr} ${cashBackType == 'amount' ? PriceConverter.convertPrice2(cashBackAmount) : '${cashBackAmount.toStringAsFixed(0)}%'} ${'cash_back_after_completing_order'.tr}';

    if (cashBackAmount > 0) {
      showCustomSnackBar(text, isError: false);
    }
  }
}

