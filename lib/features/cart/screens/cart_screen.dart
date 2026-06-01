
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/widgets/extra_packaging_widget.dart';
import 'package:sixam_mart/features/cart/widgets/not_available_bottom_sheet_widget.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/cart/widgets/out_of_service_dialog.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_widget.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/web_constrained_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/global_sticky_cart_overlay.dart';
import 'package:sixam_mart/features/cart/widgets/web_cart_items_widget.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import '../../my_coupon/controllers/my_coupon_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart/features/checkout/widgets/checkout_loading_dialog.dart';

// #region agent log helper
void _writeDebugLog(String location, String message, Map<String, dynamic> data,
    String hypothesisId) {
  if (!kDebugMode || !AppConstants.enableVerboseLogs) {
    return;
  }
  unawaited(_writeDebugLogAsync(location, message, data, hypothesisId));
}

Future<void> _writeDebugLogAsync(String location, String message,
    Map<String, dynamic> data, String hypothesisId) async {
  if (!kDebugMode || !AppConstants.enableVerboseLogs) {
    return;
  }
  try {
    const logPath = r'c:\Users\pc\Desktop\clone\app-test\.cursor\debug.log';
    final logFile = File(logPath);
    final logDir = logFile.parent;
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final logEntry = {
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
    };
    await logFile.writeAsString('${jsonEncode(logEntry)}\n',
        mode: FileMode.append);
  } catch (e) {
    // Silently fail - don't break the app
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      debugPrint('Debug log error: $e');
    }
  }
}
// #endregion

bool _isCheckoutFlowInProgress = false;

void _popCartScreen() {
  Get.back<void>();
  scheduleStickyCartOverlayRouteResync();
}

/// Helper function to navigate to checkout with loading dialog
/// Shows engaging animation while preparing checkout data
Future<void> _navigateToCheckoutWithLoading(
  BuildContext context,
  CartController cartController,
) async {
  if (_isCheckoutFlowInProgress || Get.currentRoute.contains('/checkout')) {
    debugPrint('⏳ Checkout flow already in progress - skipping duplicate call');
    return;
  }

  // Freeze cart snapshot to avoid race conditions while async prep is running.
  final List<CartModel> checkoutCartSnapshot =
      List<CartModel>.from(cartController.cartList);
  final storeId = cartController.storeId ??
      (checkoutCartSnapshot.isNotEmpty
          ? checkoutCartSnapshot.first.item?.storeId
          : null);

  if (storeId == null || checkoutCartSnapshot.isEmpty) {
    showCustomSnackBar('invalid_cart_item'.tr);
    return;
  }

  _isCheckoutFlowInProgress = true;
  showCheckoutLoadingDialog(context);

  try {
    await _CartScreenState._calculateAndSetDistanceBeforeCheckout();
    if (!context.mounted) return;

    final checkoutController = Get.find<CheckoutController>();

    await checkoutController.initCheckoutData(
      context,
      storeId,
      preloadedCartList: checkoutCartSnapshot,
      preCalculatedDistance: checkoutController.preCalculatedDistance,
    );
    if (!context.mounted) return;

    dismissCheckoutLoadingDialog();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!context.mounted) return;
    RouteHelper.navigateToCheckout(
      cartList: checkoutCartSnapshot,
      storeId: storeId,
    );
  } catch (e) {
    debugPrint('? [Cart?Checkout] Error during preparation: $e');
    if (context.mounted) {
      showCustomSnackBar('unable_to_proceed_checkout'.tr);
    }
  } finally {
    dismissCheckoutLoadingDialogSafely(context);
    _isCheckoutFlowInProgress = false;
  }
}

/// Modern color palette for the cart screen matching the touese designr
class CartColors {
  static const green = Color(0xFF31A342); // Exact green from touese
  static const dark = Color(0xFF2D3633); // Dark text color
  static const light = Color(0xFF7B8280); // Light text color
  static const divider = Color(0xFFE9ECEB); // Divider color
  static const cardShadow = Color(0x14333333); // Subtle shadow
  static const orange = Color(0xFFFA9D2B); // Orange for prices and buttons
  static const white = Color(0xFFFFFFFF);
}

class CartScreen extends StatefulWidget {
  final bool fromNav;
  const CartScreen({super.key, required this.fromNav});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with RouteAware {
  final ScrollController scrollController = ScrollController();
  bool _isFirstDidChangeDependencies = true;
  bool _isRefreshingCart = false;
  DateTime? _lastCartRefresh;

  @override
  void initState() {
    super.initState();
    initCall();
  }

  @override
  void dispose() {
    cartRouteObserverForStickyOverlay.unsubscribe(this);
    StickyCartNavSession.setCartScreenVisibleForOverlay(false);
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    StickyCartNavSession.setCartScreenVisibleForOverlay(true);
  }

  @override
  void didPopNext() {
    StickyCartNavSession.setCartScreenVisibleForOverlay(true);
  }

  @override
  void didPushNext() {
    StickyCartNavSession.setCartScreenVisibleForOverlay(false);
  }

  @override
  void didPop() {
    StickyCartNavSession.setCartScreenVisibleForOverlay(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute<dynamic>) {
      cartRouteObserverForStickyOverlay.subscribe(this, modalRoute);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final bool isCartRouteCurrent = ModalRoute.of(context)?.isCurrent ?? false;
      StickyCartNavSession.setCartScreenVisibleForOverlay(isCartRouteCurrent);
    });
    // Cart may stay in widget tree while OTP/login routes are on top.
    // Skip cart refresh logic unless cart route is actually active/current.
    final bool isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrentRoute || !Get.currentRoute.contains('/cart')) {
      return;
    }

    // Skip the first call (happens right after initState)
    // This prevents duplicate API calls on screen load
    if (_isFirstDidChangeDependencies) {
      _isFirstDidChangeDependencies = false;
      debugPrint(
          '🔄 Cart screen first load - skipping didChangeDependencies refresh');
      return;
    }
    // Only refresh if cart data is stale (older than 30 seconds)
    // This prevents unnecessary API calls when returning to cart
    final cartController = Get.find<CartController>();
    if (cartController.lastSuccessfulCartLoad == null ||
        DateTime.now().difference(cartController.lastSuccessfulCartLoad!) >
            const Duration(seconds: 30)) {
      debugPrint('🔄 Cart screen became visible - refreshing stale cart data');
      _refreshCartData();
    } else {
      debugPrint('💾 Cart screen became visible - using cached data');
    }
  }

  Future<void> _refreshCartData() async {
    if (_isRefreshingCart) {
      debugPrint('⏳ Cart refresh already in progress - skipping');
      return;
    }
    if (_lastCartRefresh != null &&
        DateTime.now().difference(_lastCartRefresh!) <
            const Duration(seconds: 10)) {
      debugPrint('⏳ Cart refresh throttled - too soon after last refresh');
      return;
    }

    _isRefreshingCart = true;
    _lastCartRefresh = DateTime.now();
    try {
      // Use forceRefresh to ensure we get the latest data and trigger stale data detection
      await Get.find<CartController>().getCartDataOnline(forceRefresh: true);
      debugPrint('✅ Cart data refreshed from API');
    } catch (e) {
      debugPrint('❌ Error refreshing cart data: $e');
    } finally {
      _isRefreshingCart = false;
    }
  }

  Future<void> initCall() async {
    // Add delay to allow backend to process any pending updates
    // This is especially important after cart quantity updates
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Load cart data from API with force refresh to get latest data
    debugPrint('🔄 Cart screen init - loading fresh data from API');
    await Get.find<CartController>().getCartDataOnline(forceRefresh: true);
    if (!mounted) {
      return;
    }

    // Force UI update after cart data loads
    Get.find<CartController>().update();

    final cartController = Get.find<CartController>();
    // 🔥 BUG FIX: Guard all cartList[0] access to prevent RangeError
    if (cartController.cartList.isNotEmpty) {
      final firstCartItem = cartController.cartList[0];
      if (firstCartItem.item?.storeId == null) {
        debugPrint(
            '⚠️ initState: First cart item has no storeId, skipping initialization');
        return;
      }

      // Only initialize checkout data once, not on every build
      if (Get.find<CheckoutController>().store == null) {
        Get.find<CheckoutController>()
            .initCheckoutData(context, firstCartItem.item!.storeId ?? 0);
      }

      if (kDebugMode) {
        debugPrint('----cart item : ${firstCartItem.toJson()}');
      }

      if (cartController.addCutlery) {
        cartController.updateCutlery(willUpdate: false);
      }
      if (cartController.needExtraPackage) {
        cartController.toggleExtraPackage(willUpdate: false);
      }
      cartController.setAvailableIndex(-1, willUpdate: false);
      Get.find<StoreController>()
          .getCartStoreSuggestedItemList(firstCartItem.item!.storeId ?? 0);
      // REMOVED: Duplicate getStoreDetails call - initCheckoutData() already loads store details
      // This was causing double API calls and unnecessary rebuilds that recalculated totals/taxes
      // Removed - totals are now calculated automatically via _onCartMutated()
      showReferAndEarnSnackBar();
    }
  }

  /// Helper method to determine if current language is RTL
  bool get _isRTL => Get.locale?.languageCode == 'ar';

  /// Calculate distance and set it in CheckoutController before navigating to checkout
  /// This prevents "calculating" state in checkout screen
  static Future<void> _calculateAndSetDistanceBeforeCheckout() async {
    try {
      // Get current address
      final AddressModel? currentAddress =
          AddressHelper.getUserAddressFromSharedPref();
      if (currentAddress == null ||
          currentAddress.latitude == null ||
          currentAddress.longitude == null) {
        debugPrint('⚠️ No address available for distance calculation');
        return;
      }

      // Get store from cart
      final cartController = Get.find<CartController>();
      // 🔥 BUG FIX: Guard cartList[0] access
      if (cartController.cartList.isEmpty) {
        debugPrint('⚠️ Cart is empty, cannot calculate distance');
        return;
      }

      final firstItem = cartController.cartList[0].item;
      if (firstItem?.storeId == null) {
        debugPrint(
            '⚠️ First cart item has no storeId, cannot calculate distance');
        return;
      }

      final storeId = firstItem!.storeId!;
      final storeController = Get.find<StoreController>();

      // Ensure store is loaded
      Store? store = storeController.store;
      if (store == null || store.id != storeId) {
        debugPrint('🔄 Loading store details for distance calculation...');
        store = await storeController.getStoreDetails(
          Get.context!,
          Store(id: storeId),
          false,
          fromCart: true,
        );
      }

      if (store == null || store.latitude == null || store.longitude == null) {
        debugPrint('⚠️ Store location not available');
        return;
      }

      // 🔎 Pre-distance diagnostics (helps trace null/coordinate issues)
      debugPrint('📊 [Cart] Distance inputs:'
          ' storeId=${store.id},'
          ' storeLat=${store.latitude}, storeLng=${store.longitude},'
          ' addressLat=${currentAddress.latitude},'
          ' addressLng=${currentAddress.longitude}');

      // Calculate distance using Haversine formula (same as checkout)
      final distance = Geolocator.distanceBetween(
            double.parse(currentAddress.latitude!),
            double.parse(currentAddress.longitude!),
            double.parse(store.latitude!),
            double.parse(store.longitude!),
          ) /
          1000;

      debugPrint('📍 [Cart] Pre-calculated distance: $distance km');

      // Set pre-calculated distance in CheckoutController
      await Get.find<CheckoutController>().setPreCalculatedDistance(distance);
      debugPrint('✅ [Cart] Distance set in CheckoutController');
    } catch (e) {
      debugPrint('❌ [Cart] Error calculating distance: $e');
      // Don't block navigation if calculation fails
    }
  }

  /// Validates if current user location is in service zone before checkout
  static Future<bool> validateLocationForCheckout() async {
    try {
      // Get current user address
      final AddressModel? currentAddress =
          AddressHelper.getUserAddressFromSharedPref();

      if (currentAddress == null ||
          currentAddress.latitude == null ||
          currentAddress.longitude == null) {
        // No address set, show location picker
        showLocationPickerDialog();
        return false;
      }

      // Check if location is in service zone
      // ⚠️ CRITICAL: Checkout ALWAYS requires a valid zone, regardless of skipZoneValidation flag
      // The skipZoneValidation flag is only for browsing the app, not for checkout
      final LocationController locationController =
          Get.find<LocationController>();

      final ZoneResponseModel response = await locationController.getZone(
          currentAddress.latitude, currentAddress.longitude, false);

      if (response.isSuccess && response.zoneIds.isNotEmpty) {
        // Location is in service zone, proceed with checkout
        debugPrint('✅ Location validation passed - user is in service zone');
        return true;
      } else {
        // Location is outside service zone, show location picker dialog
        debugPrint(
            '❌ Location validation failed - user is outside service zone');
        showLocationPickerDialog();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error validating location: $e');
      showLocationPickerDialog();
      return false;
    }
  }

  /// Shows enhanced location picker dialog with saved addresses and map option
  static void showLocationPickerDialog() {
    Get.dialog<void>(
      const OutOfServiceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) {
            scheduleStickyCartOverlayRouteResync();
          }
        },
        child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildModernHeader(),
        endDrawerEnableOpenDragGesture: false,
        body: SafeArea(
          top: false,
          bottom: true,
          left: false,
          right: false,
          minimum: EdgeInsets.zero,
          child: GetBuilder<StoreController>(builder: (storeController) {
          // #region agent log
          _writeDebugLog(
              'cart_screen.dart:280',
              'GetBuilder StoreController rebuild',
              {
                'storeId': storeController.store?.id,
                'storeTax': storeController.store?.tax,
                'hasStore': storeController.store != null,
              },
              'C');
          // #endregion
          // 🔥 PHASE 2.2: Split GetBuilder into IDs for partial rebuilds
          // Main GetBuilder for loading state only
          return GetBuilder<CartController>(
              id: 'cart_loading', // Only rebuilds on loading state changes
              builder: (cartController) {
                // Show loading indicator while cart data is being loaded
                if (cartController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (cartController.cartList.isNotEmpty) {
                  return Column(children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: ResponsiveHelper.isDesktop(context)
                            ? const EdgeInsets.only(
                                top: Dimensions.paddingSizeSmall)
                            : const EdgeInsets.fromLTRB(
                                16, 16, 16, 0), // Remove bottom padding
                        child: FooterView(
                          child: SizedBox(
                            width: Dimensions.webMaxWidth,
                            child: Column(children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ResponsiveHelper.isDesktop(context)
                                      ? WebCardItemsWidget(
                                          cartList: cartController.cartList)
                                      : Expanded(
                                          flex: 7,
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                WebConstrainedBox(
                                                  dataLength: cartController
                                                      .cartList.length,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // 🔥 PHASE 2.2: Cart Items Section with ID
                                                      GetBuilder<
                                                          CartController>(
                                                        id: 'cart_items', // Only rebuilds when items change
                                                        builder:
                                                            (cartController) {
                                                          return Column(
                                                            children:
                                                                cartController
                                                                    .cartList
                                                                    .asMap()
                                                                    .entries
                                                            .map(
                                                                        (entry) {
                                                              final int index =
                                                                  entry.key;
                                                              final CartModel
                                                                  cart =
                                                                  entry.value;
                                                              final List<AddOns>
                                                                  safeAddOns =
                                                                  index <
                                                                          cartController
                                                                              .addOnsList
                                                                              .length
                                                                      ? cartController
                                                                              .addOnsList[
                                                                          index]
                                                                      : <AddOns>[];
                                                              final bool
                                                                  safeIsAvailable =
                                                                  index <
                                                                          cartController
                                                                              .availableList
                                                                              .length
                                                                      ? cartController
                                                                              .availableList[
                                                                          index]
                                                                      : true;
                                                              return Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        8),
                                                                child:
                                                                    _ModernCartItemCard(
                                                                  cart: cart,
                                                                  cartIndex:
                                                                      index,
                                                                  addOns:
                                                                      safeAddOns,
                                                                  isAvailable:
                                                                      safeIsAvailable,
                                                                  cartController:
                                                                      cartController,
                                                                ),
                                                              );
                                                            }).toList(),
                                                          );
                                                        },
                                                      ),

                                                      // Removed "add more items" button per request

                                                      // Extra packaging widget
                                                      if (!ResponsiveHelper
                                                          .isDesktop(context))
                                                        ExtraPackagingWidget(
                                                            cartController:
                                                                cartController),

                                                      // Suggested items
                                                      if (!ResponsiveHelper
                                                          .isDesktop(context))
                                                        suggestedItemView(
                                                            cartController
                                                                .cartList),
                                                    ],
                                                  ),
                                                ),
                                              ]),
                                        ),
                                  // Desktop pricing view
                                  ResponsiveHelper.isDesktop(context)
                                      ? Expanded(
                                          flex: 4,
                                          child: cartController
                                                      .cartList.isNotEmpty &&
                                                  cartController
                                                          .cartList[0].item !=
                                                      null
                                              ? pricingView(
                                                  cartController,
                                                  cartController
                                                      .cartList[0].item!)
                                              : const SizedBox())
                                      : const SizedBox(),
                                ],
                              ),
                              // Web suggested items
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox() // WebSuggestedItemViewWidget pending
                                  : const SizedBox(),
                            ]),
                          ),
                        ),
                      ),
                    ),

                    // Order summary from touese design - now static, no expandable
                    if (!ResponsiveHelper.isDesktop(context))
                      Container(
                        width: context.width,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.only(
                              topLeft:
                                  Radius.circular(Dimensions.radiusDefault),
                              topRight:
                                  Radius.circular(Dimensions.radiusDefault)),
                        ),
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.only(
                              left: Dimensions.paddingSizeSmall,
                              right: Dimensions.paddingSizeSmall,
                              top: Dimensions.paddingSizeSmall,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: const BorderRadius.only(
                                  topLeft:
                                      Radius.circular(Dimensions.radiusDefault),
                                  topRight: Radius.circular(
                                      Dimensions.radiusDefault)),
                            ),
                            child: Column(children: [
                              // Promo / applied coupon (rebuilds with CouponController)
                              const _CartPromoSection(),

                              const SizedBox(height: 12),

                              // 🔥 PHASE 2.2: Cart Summary Section with ID
                              // Only rebuilds when totals change (subTotal, tax, etc.)
                              GetBuilder<CartController>(
                                id: 'cart_summary',
                                builder: (cartController) {
                                  final double effectiveTaxPercent =
                                      _resolveCartTaxPercent(storeController
                                              .store?.tax ??
                                          (cartController.cartList.isNotEmpty
                                              ? cartController
                                                  .cartList.first.item?.tax
                                              : null));
                                  final bool taxIncluded =
                                      Get.find<SplashController>()
                                              .configModel!
                                              .taxIncluded ==
                                          1;
                                  return GetBuilder<CouponController>(
                                      builder: (CouponController couponCtrl) {
                                    final double couponDisc =
                                        couponCtrl.discount ?? 0.0;
                                    final bool couponFree =
                                        couponCtrl.freeDelivery;
                                    if (kDebugMode &&
                                        (couponDisc > 0 || couponFree)) {
                                      final double taxPreview =
                                          _calculateCartTaxAmount(
                                        cartController.subTotal,
                                        effectiveTaxPercent,
                                        taxIncluded,
                                      );
                                      final double addCh =
                                          Get.find<SplashController>()
                                                  .configModel!
                                                  .additionalChargeStatus!
                                              ? Get.find<SplashController>()
                                                  .configModel!
                                                  .additionCharge!
                                              : 0;
                                      final double totalBefore = cartController
                                              .subTotal +
                                          (taxIncluded ? 0 : taxPreview) +
                                          addCh;
                                      final double totalAfter = totalBefore -
                                          couponDisc;
                                      debugPrint(
                                        '[Coupon][STATE] appliedCouponCode=${couponCtrl.coupon?.code} '
                                        'couponDiscount=$couponDisc totalBefore=$totalBefore totalAfter=$totalAfter',
                                      );
                                    }
                                    return Column(children: [
                                    // Modern summary rows with actual app price calculations
                                    _ModernSummaryRow(
                                      label: 'subtotal'.tr,
                                      value: PriceConverter.convertPrice2(
                                        cartController.itemPrice,
                                        textStyle: robotoRegular,
                                      ),
                                    ),
                                    const _DividerLine(),

                                    // Taxes row - using proper tax calculation
                                    _ModernSummaryRow(
                                      label:
                                          '${'taxes'.tr} (${_formatPercent(effectiveTaxPercent)})',
                                      value: _calculateCartTax(
                                        cartController.subTotal,
                                        effectiveTaxPercent,
                                        taxIncluded,
                                        cartController.cartList,
                                      ),
                                    ),
                                    const _DividerLine(),

                                    // App fee (service fee) row - shown if enabled
                                    if (Get.find<SplashController>()
                                            .configModel!
                                            .additionalChargeStatus! &&
                                        Get.find<SplashController>()
                                                .configModel!
                                                .additionCharge !=
                                            null &&
                                        Get.find<SplashController>()
                                                .configModel!
                                                .additionCharge! >
                                            0) ...[
                                      _ModernSummaryRow(
                                        label: 'service_fee'.tr,
                                        value: PriceConverter.convertPrice2(
                                          Get.find<SplashController>()
                                              .configModel!
                                              .additionCharge!,
                                          prefixText: '(+) ',
                                          textStyle: robotoRegular,
                                        ),
                                      ),
                                      const _DividerLine(),
                                    ],

                                    if (couponDisc > 0.0001) ...[
                                      _ModernSummaryRow(
                                        label: couponCtrl.coupon
                                                    ?.discountType ==
                                                'percent'
                                            ? '${'coupon_discount'.tr} (${_formatPercent(couponCtrl.coupon?.discount)})'
                                            : 'coupon_discount'.tr,
                                        value: PriceConverter.convertPrice2(
                                          couponDisc,
                                          prefixText: '(-) ',
                                          textStyle: robotoRegular,
                                        ),
                                      ),
                                      const _DividerLine(),
                                    ] else if (couponFree) ...[
                                      _ModernSummaryRow(
                                        label: 'coupon_discount'.tr,
                                        value: Text(
                                          'free_delivery'.tr,
                                          style: robotoRegular,
                                        ),
                                      ),
                                      const _DividerLine(),
                                    ],

                                    // Total row with item count and actual calculations
                                    _ModernSummaryRow(
                                      label: 'total'.tr,
                                      value: _calculateCartTotal(
                                        context,
                                        subTotal: cartController.subTotal,
                                        taxPercent: effectiveTaxPercent,
                                        taxIncluded: taxIncluded,
                                        cartList: cartController.cartList,
                                        couponDiscount: couponDisc,
                                      ),
                                      isTotal: true,
                                    ),

                                    // Minimum order warning
                                    if (storeController.store != null &&
                                        storeController.store!.minimumOrder! >
                                            0 &&
                                        cartController.subTotal <
                                            storeController
                                                .store!.minimumOrder!)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.orange
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Directionality(
                                          textDirection: _isRTL
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.info_outline,
                                                color: Colors.orange,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'minimum_order_amount_is'
                                                          .tr,
                                                      style: robotoRegular
                                                          .copyWith(
                                                        color:
                                                            Colors.orange[700],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Directionality(
                                                      textDirection:
                                                          TextDirection.ltr,
                                                      child: PriceConverter
                                                          .convertPrice2(
                                                        storeController.store!
                                                            .minimumOrder!,
                                                        textStyle: robotoRegular
                                                            .copyWith(
                                                          color: Colors
                                                              .orange[700],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    const SizedBox(
                                        height:
                                            Dimensions.paddingSizeExtraLarge),
                                  ]);
                                  });
                                },
                              ),
                            ]),
                          ),
                        ]),
                      ),

                    // 🔥 PHASE 2.2: Checkout Button with ID
                    // Only rebuilds when totals or checkout-related data changes
                    ResponsiveHelper.isDesktop(context)
                        ? const SizedBox.shrink()
                        : GetBuilder<CartController>(
                            id: 'cart_checkout',
                            builder: (cartController) {
                              return _ModernPaymentButton(
                                cartController: cartController,
                                availableList: cartController.availableList,
                              );
                            },
                          ),
                  ]);
                } else {
                  if (cartController.hasCartError) {
                    return ErrorStateView(
                      onRetry: () {
                        cartController.getCartDataOnline(forceRefresh: true);
                      },
                    );
                  }

                  return NoDataScreen(
                    isCart: true,
                    text: '',
                    subtitle: 'cart_empty_subtitle'.tr,
                    showFooter: true,
                  );
                }
              });
        }),
        ),
        ),
      ),
    );
  }

  /// Modern header matching the touese design exactly
  PreferredSizeWidget _buildModernHeader() {
    return AppBar(
      elevation: 0,
      backgroundColor: CartColors.green,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 80, // Exact height from touese
      systemOverlayStyle: SystemUiOverlayStyle.light, // white status icons
      leading: IconButton(
        icon: Icon(
          _isRTL ? Icons.arrow_back_ios_rounded : Icons.arrow_back_ios_rounded,
          color: CartColors.white,
          size: 20,
        ),
        onPressed: _popCartScreen,
        tooltip: _isRTL ? 'رجوع' : 'Back',
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              color: CartColors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            _isRTL ? 'السلة' : 'My Cart',
            style: const TextStyle(
              color: CartColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
      actions: [
        GetBuilder<CartController>(
          id: 'cart_count',
          builder: (cartController) {
            return IconButton(
              tooltip: _isRTL ? 'افراغ السلة' : 'Clear cart',
              icon: const Icon(Icons.delete_outline, color: CartColors.white),
              onPressed: () {
                if (cartController.cartList.isEmpty) {
                  showCustomSnackBar('cart_is_empty'.tr);
                  return;
                }
                Get.dialog<void>(
                  ConfirmationDialog(
                    icon: Images.warning,
                    description: 'are_you_sure'.tr,
                    onYesPressed: () async {
                      Get.back<void>();
                      await cartController.clearCartList();
                    },
                  ),
                  useSafeArea: false,
                );
              },
            );
          },
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
      ],
    );
  }

  Widget pricingView(CartController cartController, Item item) {
    return Container(
      decoration: ResponsiveHelper.isDesktop(context)
          ? BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                  ResponsiveHelper.isDesktop(context)
                      ? Dimensions.radiusDefault
                      : Dimensions.radiusSmall),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
              ],
            )
          : null,
      child: GetBuilder<StoreController>(builder: (storeController) {
        return Column(children: [
          ResponsiveHelper.isDesktop(context)
              ? ExtraPackagingWidget(cartController: cartController)
              : const SizedBox(),

          ResponsiveHelper.isDesktop(context)
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeSmall),
                    child: Text('order_summary'.tr,
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge)),
                  ),
                )
              : const SizedBox(),

          !ResponsiveHelper.isDesktop(context) &&
                  (Get.find<SplashController>()
                          .getModuleConfig(item.moduleType)
                          .newVariation ??
                      false) &&
                  (storeController.store != null &&
                      storeController.store!.cutlery!)
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall),
                  child: Row(children: [
                    Image.asset(Images.cutlery, height: 18, width: 18),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('add_cutlery'.tr,
                                style: robotoMedium.copyWith(
                                    color: Theme.of(context).primaryColor)),
                            const SizedBox(
                                height: Dimensions.paddingSizeExtraSmall),
                            Text('do_not_have_cutlery'.tr,
                                style: robotoRegular.copyWith(
                                    color: Theme.of(context).disabledColor,
                                    fontSize: Dimensions.fontSizeSmall)),
                          ]),
                    ),
                    Transform.scale(
                      scale: 0.7,
                      child: CupertinoSwitch(
                        value: cartController.addCutlery,
                        activeTrackColor: Theme.of(context).primaryColor,
                        onChanged: (bool? value) {
                          cartController.updateCutlery();
                        },
                        inactiveTrackColor: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.5),
                      ),
                    )
                  ]),
                )
              : const SizedBox(),

          ResponsiveHelper.isDesktop(context)
              ? const SizedBox()
              : Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                        color: Theme.of(context).primaryColor, width: 0.5),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  margin: ResponsiveHelper.isDesktop(context)
                      ? const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSmall)
                      : EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (ResponsiveHelper.isDesktop(context)) {
                            Get.dialog<void>(const Dialog(
                                child: NotAvailableBottomSheetWidget()));
                          } else {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (con) =>
                                  const NotAvailableBottomSheetWidget(),
                            );
                          }
                        },
                        child: Row(children: [
                          Expanded(
                              child: Text('if_any_product_is_not_available'.tr,
                                  style: robotoMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)),
                          const Icon(Icons.arrow_forward_ios_sharp, size: 18),
                        ]),
                      ),
                      cartController.notAvailableIndex != -1
                          ? Row(children: [
                              Text(
                                  cartController
                                      .notAvailableList[
                                          cartController.notAvailableIndex]
                                      .tr,
                                  style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).primaryColor)),
                              IconButton(
                                onPressed: () =>
                                    cartController.setAvailableIndex(-1),
                                icon: const Icon(Icons.clear, size: 18),
                              )
                            ])
                          : const SizedBox(),
                    ],
                  ),
                ),
          ResponsiveHelper.isDesktop(context)
              ? const SizedBox()
              : const SizedBox(height: Dimensions.paddingSizeSmall),

          // Total
          ResponsiveHelper.isDesktop(context)
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('item_price'.tr, style: robotoRegular),
                          PriceConverter.convertAnimationPrice(
                              cartController.itemPrice,
                              textStyle: robotoRegular),
                        ]),
                    SizedBox(
                        height: cartController.variationPrice > 0
                            ? Dimensions.paddingSizeSmall
                            : 0),
                    (Get.find<SplashController>()
                                    .getModuleConfig(item.moduleType)
                                    .newVariation ??
                                false) &&
                            cartController.variationPrice > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('variations'.tr, style: robotoRegular),
                              PriceConverter.convertPrice2(
                                cartController.variationPrice,
                                prefixText: '(+) ',
                                textStyle: robotoRegular,
                              ),
                            ],
                          )
                        : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('discount'.tr, style: robotoRegular),
                          storeController.store != null
                              ? Row(children: [
                                  Text('(-)', style: robotoRegular),
                                  PriceConverter.convertAnimationPrice(
                                      cartController.itemDiscountPrice,
                                      textStyle: robotoRegular),
                                ])
                              : Text('calculating'.tr, style: robotoRegular),
                          // Text('(-) ${PriceConverter.convertPrice(cartController.itemDiscountPrice)}', style: robotoRegular, textDirection: TextDirection.ltr),
                        ]),
                    SizedBox(
                        height: Get.find<SplashController>()
                                .configModel!
                                .moduleConfig!
                                .module!
                                .addOn!
                            ? 10
                            : 0),
                    Get.find<SplashController>()
                            .configModel!
                            .moduleConfig!
                            .module!
                            .addOn!
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('addons'.tr, style: robotoRegular),
                              PriceConverter.convertPrice2(
                                cartController.addOns,
                                prefixText: '(+) ',
                                textStyle: robotoRegular,
                              ),
                            ],
                          )
                        : const SizedBox(),
                  ]),
                )
              : const SizedBox(),

          // 🔥 PHASE 2.2: Desktop Checkout Button with ID
          ResponsiveHelper.isDesktop(context)
              ? GetBuilder<CartController>(
                  id: 'cart_checkout',
                  builder: (cartController) {
                    return Row(
                      children: [
                        CheckoutButton(
                            cartController: cartController,
                            availableList: cartController.availableList),
                      ],
                    );
                  },
                )
              : const SizedBox.shrink(),
        ]);
      }),
    );
  }

  Widget suggestedItemView(List<CartModel> cartList) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GetBuilder<StoreController>(builder: (storeController) {
          List<Item>? suggestedItems;
          if (storeController.cartSuggestItemModel != null) {
            suggestedItems = [];
            final List<int> cartIds = [];
            for (final CartModel cartItem in cartList) {
              cartIds.add(cartItem.item!.id!);
            }
            for (final Item item
                in storeController.cartSuggestItemModel!.items!) {
              if (!cartIds.contains(item.id)) {
                suggestedItems.add(item);
              }
            }
          }
          return storeController.cartSuggestItemModel != null &&
                  suggestedItems!.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeExtraSmall),
                      child: Text('you_may_also_like'.tr,
                          style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault)),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.isDesktop(context) ? 160 : 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestedItems.length,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                            left: ResponsiveHelper.isDesktop(context)
                                ? Dimensions.paddingSizeExtraSmall
                                : Dimensions.paddingSizeDefault),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: ResponsiveHelper.isDesktop(context)
                                ? const EdgeInsets.symmetric(vertical: 20)
                                : const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: ResponsiveHelper.isDesktop(context)
                                  ? 500
                                  : 300,
                              padding: const EdgeInsets.only(
                                  right: Dimensions.paddingSizeSmall,
                                  left: Dimensions.paddingSizeExtraSmall),
                              margin: const EdgeInsets.only(
                                  right: Dimensions.paddingSizeSmall),
                              child: ItemWidget(
                                isStore: false,
                                item: suggestedItems![index],
                                fromCartSuggestion: true,
                                store: null,
                                index: index,
                                length: null,
                                inStore: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const SizedBox();
        }),
      ]),
    );
  }

  Future<void> showReferAndEarnSnackBar() async {
    final String text = 'your_referral_discount_added_on_your_first_order'.tr;
    final userInfo = Get.find<ProfileController>().userInfoModel;
    if (userInfo?.isValidForDiscount == true) {
      showCustomSnackBar(text, isError: false);
    }
  }

  /// Calculate tax for cart display using discounted prices
  Widget _calculateCartTax(double subTotal, double? taxPercent,
      bool taxIncluded, List<CartModel> cartList) {
    // #region agent log
    _writeDebugLog(
        'cart_screen.dart:981',
        '_calculateCartTax called',
        {
          'subTotal': subTotal,
          'taxPercent': taxPercent,
          'taxIncluded': taxIncluded,
          'cartListLength': cartList.length,
        },
        'A');
    // #endregion

    if (taxPercent == null || taxPercent == 0) {
      final result =
          PriceConverter.convertPrice2(0.0, textStyle: robotoRegular);
      // #region agent log
      _writeDebugLog('cart_screen.dart:985',
          '_calculateCartTax returning 0 (no tax)', {}, 'A');
      // #endregion
      return result;
    }

    final calculatedTax = PriceConverter.toFixed(
        _calculateCartTaxAmount(subTotal, taxPercent, taxIncluded));
    // #region agent log
    _writeDebugLog(
        'cart_screen.dart:993',
        '_calculateCartTax calculated value',
        {
          'calculatedTax': calculatedTax,
          'taxIncluded': taxIncluded,
        },
        'A');
    // #endregion

    return PriceConverter.convertPrice2(
      calculatedTax,
      textStyle: robotoRegular,
    );
  }

  double _calculateCartTaxAmount(
      double subTotal, double? taxPercent, bool taxIncluded) {
    final double effectiveTaxPercent = _resolveCartTaxPercent(taxPercent);
    if (effectiveTaxPercent == 0) {
      return 0;
    }
    if (taxIncluded) {
      return subTotal * effectiveTaxPercent / (100 + effectiveTaxPercent);
    }
    return PriceConverter.calculation(
        subTotal, effectiveTaxPercent, 'percent', 1);
  }

  double _resolveCartTaxPercent(double? storeTaxPercent) {
    if (storeTaxPercent == null || storeTaxPercent == 0) {
      return 15;
    }
    return storeTaxPercent;
  }

  String _formatPercent(double? value) {
    if (value == null) return '0%';
    final bool isWhole = value % 1 == 0;
    return isWhole
        ? '${value.toStringAsFixed(0)}%'
        : '${value.toStringAsFixed(2)}%';
  }

  /// Calculate total for cart display using same logic as checkout
  Widget _calculateCartTotal(
    BuildContext context, {
    required double subTotal,
    required double? taxPercent,
    required bool taxIncluded,
    required List<CartModel> cartList,
    double couponDiscount = 0.0,
  }) {
    // #region agent log
    _writeDebugLog(
        'cart_screen.dart:1119',
        '_calculateCartTotal called',
        {
          'subTotal': subTotal,
          'taxPercent': taxPercent,
          'taxIncluded': taxIncluded,
          'cartListLength': cartList.length,
        },
        'B');
    // #endregion

    // Calculate tax using discounted prices (subTotal)
    final double tax =
        _calculateCartTaxAmount(subTotal, taxPercent, taxIncluded);

    // Delivery charge not included in cart total - calculated at checkout based on actual distance
    // Delivery fee row was removed from UI, so it should not be in the total calculation

    // Calculate additional charges (app fee) - shown in cart total
    final double additionalCharge =
        Get.find<SplashController>().configModel!.additionalChargeStatus!
            ? Get.find<SplashController>().configModel!.additionCharge!
            : 0;

    // Calculate total without delivery charge (delivery fee calculated at checkout)
    // App fee is included in total; subtract coupon discount (same base as checkout order line)
    final double totalBeforeCoupon =
        subTotal + (taxIncluded ? 0 : tax) + additionalCharge;
    final double total = totalBeforeCoupon - couponDiscount;

    // #region agent log
    _writeDebugLog(
        'cart_screen.dart:1136',
        '_calculateCartTotal calculated value',
        {
          'total': total,
          'tax': tax,
          'taxIncluded': taxIncluded,
          'couponDiscount': couponDiscount,
        },
        'B');
    // #endregion

    final Color totalColor = Theme.of(context).colorScheme.onSurface;
    return PriceConverter.convertPrice2(
      total,
      textStyle: TextStyle(
        color: totalColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Modern cart item card with clean design from touese
class _ModernCartItemCard extends StatelessWidget {
  final CartModel cart;
  final int cartIndex;
  final List<AddOns> addOns;
  final bool isAvailable;
  final CartController cartController;

  const _ModernCartItemCard({
    required this.cart,
    required this.cartIndex,
    required this.addOns,
    required this.isAvailable,
    required this.cartController,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Get.locale?.languageCode == 'ar';
    final item = cart.item;
    final String itemName = (item?.name ?? 'item'.tr).trim();
    final String storeName = (item?.storeName ?? '').trim();
    final String? imageUrl = item?.imageFullUrl;
    final int quantity = cart.quantity ?? 1;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: CartColors.cardShadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Keep image on the *left* by forcing this Row LTR only
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 90,
                          height: 86,
                          color: const Color(0xFFF6F6F6),
                          child: SmartImage(
                            url: imageUrl ?? '',
                            height: 86,
                            width: 90,
                            cacheWidth: 300,
                            cacheHeight: 300,
                            fit: BoxFit.cover,
                            errorWidget: const Icon(
                              Icons.image_not_supported_outlined,
                              color: CartColors.light,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Directionality(
                          textDirection:
                              isRTL ? TextDirection.rtl : TextDirection.ltr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                itemName.split(' ').take(5).join(' ') +
                                    (itemName.split(' ').length > 5
                                        ? '  ...'
                                        : ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: CartColors.dark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (storeName.isNotEmpty)
                                Text(
                                  storeName,
                                  style: const TextStyle(
                                    color: CartColors.light,
                                    fontSize: 15,
                                    height: 1.2,
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: isRTL
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: PriceConverter.convertPrice2(
                                  cart.price,
                                  textStyle: const TextStyle(
                                    color: CartColors.orange,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Quantity line
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      _RoundMinus(
                        onTap: () {
                          // 🔥 BUG FIX: Use cart_id instead of index (safe, index-independent)
                          if (cart.id != null) {
                            if (quantity > 1) {
                              cartController.setQuantityById(false, cart.id!,
                                  cart.stock, cart.quantityLimit);
                            } else {
                              // When quantity is 1, remove the item completely
                              cartController.removeFromCartById(cart.id!,
                                  item: cart.item,
                                  reason: 'quantity_decrement');
                            }
                          } else {
                            // Fallback for items without cart_id
                            if (cart.quantity! > 1) {
                              // ignore: deprecated_member_use_from_same_package
                              cartController.setQuantity(false, cartIndex,
                                  cart.stock, cart.quantityLimit);
                            } else {
                              // ignore: deprecated_member_use_from_same_package
                              cartController.removeFromCart(cartIndex,
                                  item: cart.item);
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${cart.quantity}',
                        style: const TextStyle(
                          color: CartColors.dark,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _RoundPlus(
                        onTap: () {
                          // 🔥 BUG FIX: Guard cartList[0] access before accessing moduleId
                          if (cartController.cartList.isNotEmpty &&
                              cartController.cartList[0].item?.moduleId !=
                                  null) {
                            cartController.forcefullySetModule(context,
                                cartController.cartList[0].item!.moduleId!);
                          }
                          // 🔥 BUG FIX: Use cart_id instead of index (safe, index-independent)
                          if (cart.id != null) {
                            cartController.setQuantityById(
                                true, cart.id!, cart.stock, cart.quantityLimit);
                          } else {
                            // Fallback for items without cart_id
                            // ignore: deprecated_member_use_from_same_package
                            cartController.setQuantity(true, cartIndex,
                                cart.stock, cart.quantityLimit);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Close button on the (visual) right
        PositionedDirectional(
          top: 10,
          end: 10,
          child: _CloseDot(
            onTap: () {
              // 🔥 BUG FIX: Use cart_id instead of index (safe, index-independent)
              if (cart.id != null) {
                cartController.removeFromCartById(cart.id!,
                    item: cart.item, reason: 'close_button');
              } else {
                // Fallback for items without cart_id
                // ignore: deprecated_member_use_from_same_package
                cartController.removeFromCart(cartIndex, item: cart.item);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Modern minus button from touese design
class _RoundMinus extends StatelessWidget {
  const _RoundMinus({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: CartColors.orange, width: 3),
        ),
        child: const Center(
          child: Icon(Icons.remove, color: CartColors.orange, size: 22),
        ),
      ),
    );
  }
}

/// Modern plus button from touese design
class _RoundPlus extends StatelessWidget {
  const _RoundPlus({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: CartColors.orange,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// Close button from touese design
class _CloseDot extends StatelessWidget {
  const _CloseDot({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: CartColors.divider),
        ),
        child: const Center(
          child: Icon(Icons.close, color: CartColors.dark, size: 18),
        ),
      ),
    );
  }
}

String _formatPercentForCoupon(double? value) {
  if (value == null) {
    return '0%';
  }
  final bool isWhole = value % 1 == 0;
  return isWhole
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(2)}%';
}

/// Promo input or applied-coupon summary (cart السلة).
class _CartPromoSection extends StatefulWidget {
  const _CartPromoSection();

  @override
  State<_CartPromoSection> createState() => _CartPromoSectionState();
}

class _CartPromoSectionState extends State<_CartPromoSection> {
  final TextEditingController _couponInputController = TextEditingController();

  @override
  void dispose() {
    _couponInputController.dispose();
    super.dispose();
  }

  void _executeClearCoupon(CouponController couponController) {
    couponController.removeCouponData(true);
    Get.find<CartController>().update(['cart_summary']);
    if (kDebugMode) {
      debugPrint(
        '[Coupon][UI_REBUILD] inputVisible=true discountRowVisible=false (cart promo cleared)',
      );
    }
  }

  void _applyPromoCode(CouponController couponController) {
    final String entered = _couponInputController.text.trim();
    if (kDebugMode) {
      debugPrint('[Coupon][INPUT] controllerText=$entered');
    }
    if (entered.isEmpty) {
      showCustomSnackBar('enter_a_coupon_code'.tr);
      return;
    }
    final CartController cartController = Get.find<CartController>();
    final double orderAmount = cartController.subTotal;
    couponController
        .applyCoupon(
      entered,
      orderAmount,
      15.0,
      Get.find<StoreController>().store?.id,
    )
        .then((double? _) {
      if (!mounted) {
        return;
      }
      final CouponController cc = Get.find<CouponController>();
      if (cc.hasAppliedCoupon) {
        showCustomSnackBar('coupon_applied_successfully'.tr, isError: false);
        _couponInputController.clear();
        cartController.update(['cart_summary']);
        if (kDebugMode) {
          debugPrint(
            '[Coupon][UI_REBUILD] inputVisible=${!cc.hasAppliedCoupon} discountRowVisible=${cc.hasAppliedCoupon}',
          );
        }
      }
    }).catchError((Object error) {
      if (!mounted) {
        return;
      }
      showCustomSnackBar('coupon_error_invalid_code'.tr);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Get.locale?.languageCode == 'ar';
    return GetBuilder<CouponController>(
      builder: (CouponController couponController) {
        if (couponController.hasAppliedCoupon) {
          return _AppliedCartCouponSummary(
            controller: couponController,
            onClear: () => _executeClearCoupon(couponController),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CartColors.divider),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _couponInputController,
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                    textDirection:
                        isRTL ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: isRTL ? 'برومو كود' : 'promo_code'.tr,
                      hintStyle: const TextStyle(
                        color: CartColors.light,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: InkWell(
                    onTap: () => _applyPromoCode(couponController),
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: CartColors.green,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: couponController.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isRTL ? 'إدخال' : 'apply'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppliedCartCouponSummary extends StatelessWidget {
  const _AppliedCartCouponSummary({
    required this.controller,
    required this.onClear,
  });

  final CouponController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Get.locale?.languageCode == 'ar';
    final String code = controller.coupon?.code ?? '';
    final double discountAmount = controller.discount ?? 0.0;
    final bool isPercent = controller.coupon?.discountType == 'percent';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CartColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: CartColors.green,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'applied_coupon_code_label'.tr}: $code',
                        style: robotoMedium.copyWith(
                          fontSize: 15,
                          color: CartColors.dark,
                        ),
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      ),
                      if (isPercent && controller.coupon?.discount != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${'coupon_discount_percent_label'.tr}: ${_formatPercentForCoupon(controller.coupon?.discount)}',
                          style: robotoRegular.copyWith(
                            fontSize: 14,
                            color: CartColors.light,
                          ),
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        ),
                      ],
                      if (discountAmount > 0.0001) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${'coupon_discount_amount_label'.tr}: (-) ${PriceConverter.convertPrice(discountAmount)}',
                          style: robotoRegular.copyWith(
                            fontSize: 14,
                            color: CartColors.dark,
                          ),
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        ),
                      ] else if (controller.freeDelivery) ...[
                        const SizedBox(height: 6),
                        Text(
                          'free_delivery'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: 14,
                            color: CartColors.green,
                          ),
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onClear,
                  child: Text(
                    'change_coupon_code'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: 13,
                      color: CartColors.green,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text(
                    'remove'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: 13,
                      color: CartColors.light,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Divider line from touese design
class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    final Color lineColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
        : CartColors.divider;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: lineColor, height: 24, thickness: 1),
    );
  }
}

/// Modern summary row from touese design
class _ModernSummaryRow extends StatelessWidget {
  const _ModernSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final Widget value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final labelStyle = TextStyle(
      color: textColor,
      fontSize: isTotal ? 18 : 17,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
    );
    final valueStyle = TextStyle(
      color: textColor,
      fontSize: isTotal ? 18 : 17,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          DefaultTextStyle(
            style: valueStyle,
            child: value,
          ),
        ],
      ),
    );
  }
}

/// Modern payment button from touese design
class _ModernPaymentButton extends StatelessWidget {
  final CartController cartController;
  final List<bool> availableList;

  const _ModernPaymentButton({
    required this.cartController,
    required this.availableList,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Get.locale?.languageCode == 'ar';

    return Container(
      width: Dimensions.webMaxWidth,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.isDesktop(context) ? Dimensions.radiusDefault : 0),
      ),
      child: GetBuilder<StoreController>(builder: (storeController) {
        return Column(
          children: [
            // Primary CTA
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CartColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  if (cartController.cartList.isEmpty) {
                    return;
                  }

                  final firstItem = cartController.cartList.first.item;
                  if (firstItem == null) return;

                  if (!(firstItem.scheduleOrder ?? false) &&
                      availableList.contains(false)) {
                    showCustomSnackBar('one_or_more_product_unavailable'.tr);
                  } else {
                    final double subTotal = cartController.subTotal;
                    final double minimumOrder =
                        storeController.store?.minimumOrder ?? 0;

                    if (minimumOrder > 0 && subTotal < minimumOrder) {
                      showCustomSnackBar(
                          '${'minimum_order_amount_is'.tr} ${PriceConverter.convertPrice(minimumOrder)}');
                      return;
                    }

                    final bool isLocationValid =
                        await _CartScreenState.validateLocationForCheckout();

                    // ✅ إصلاح مشكلة Context Gap
                    if (!context.mounted) return;

                    if (!isLocationValid) {
                      return;
                    }

                    if (Get.find<SplashController>().module == null) {
                      if (cartController.cartList.isEmpty ||
                          cartController.cartList[0].item?.moduleId == null) {
                        return;
                      }

                      int i = 0;
                      for (i = 0;
                          i < Get.find<SplashController>().moduleList!.length;
                          i++) {
                        if (cartController.cartList[0].item!.moduleId ==
                            Get.find<SplashController>().moduleList![i].id) {
                          break;
                        }
                      }
                      Get.find<SplashController>().setModule(
                          Get.find<SplashController>().moduleList![i]);

                      // ✅ إصلاح مشكلة Context Gap هنا أيضاً
                      if (context.mounted) {
                        HomeScreen.loadData(context, true);
                      }
                    }
                    final bool isLoggedIn = AuthHelper.isLoggedIn();

                    if (!isLoggedIn) {
                      if (ResponsiveHelper.isDesktop(context)) {
                        await Get.dialog<void>(
                          const Center(
                              child: AuthDialogWidget(
                                  exitFromApp: false, backFromThis: true)),
                          barrierDismissible: false,
                        );
                        if (!context.mounted) return;
                      } else {
                        // ✅ إضافة <void>
                        await Get.toNamed<void>(
                            RouteHelper.getSignInRoute(Get.currentRoute));
                        if (!context.mounted) return;
                      }
                      return;
                    } else {
                      await _navigateToCheckoutWithLoading(
                        context,
                        cartController,
                      );
                    }
                  }
                },
                child: Text(
                  isRTL ? 'الدفع' : 'confirm_delivery_details'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary CTA
            SizedBox(
              height: 44,
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _popCartScreen,
                child: Text(
                  'complete_shopping'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ✅ IMPROVED: CheckoutButton with proper async checkout flow
class CheckoutButton extends StatelessWidget {
  final CartController cartController;
  final List<bool> availableList;
  const CheckoutButton(
      {super.key, required this.cartController, required this.availableList});

  Future<void> _proceedToCheckout(BuildContext context) async {
    if (_isCheckoutFlowInProgress || Get.currentRoute.contains('/checkout')) {
      debugPrint(
          '⏳ Checkout flow already in progress - skipping duplicate call');
      return;
    }

    try {
      final List<CartModel> checkoutCartSnapshot =
          List<CartModel>.from(cartController.cartList);

      if (checkoutCartSnapshot.isEmpty) {
        showCustomSnackBar('cart_empty'.tr);
        return;
      }

      final firstItem = checkoutCartSnapshot.first;
      if (firstItem.item?.storeId == null || firstItem.item?.moduleId == null) {
        showCustomSnackBar('invalid_cart_item'.tr);
        return;
      }

      final storeId = firstItem.item!.storeId!;
      final moduleId = firstItem.item!.moduleId!;

      if (Get.find<SplashController>().module == null) {
        int moduleIndex = 0;
        for (int i = 0;
            i < Get.find<SplashController>().moduleList!.length;
            i++) {
          if (Get.find<SplashController>().moduleList![i].id == moduleId) {
            moduleIndex = i;
            break;
          }
        }
        Get.find<SplashController>()
            .setModule(Get.find<SplashController>().moduleList![moduleIndex]);
      }

      bool isLoggedIn = AuthHelper.isLoggedIn();
      if (!isLoggedIn) {
        if (ResponsiveHelper.isDesktop(context)) {
          await Get.dialog<void>(
            const Center(
                child:
                    AuthDialogWidget(exitFromApp: false, backFromThis: true)),
            barrierDismissible: false,
          );
          if (!context.mounted) return; // ✅ إصلاح Context Gap
          isLoggedIn = AuthHelper.isLoggedIn();
        } else {
          await Get.toNamed<void>(RouteHelper.getSignInRoute(Get.currentRoute));
          if (!context.mounted) return; // ✅ إصلاح Context Gap
          isLoggedIn = AuthHelper.isLoggedIn();
        }

        return;
      }

      final bool isLocationValid =
          await _CartScreenState.validateLocationForCheckout();
      if (!context.mounted) return; // ✅ إصلاح Context Gap
      if (!isLocationValid) {
        return;
      }

      // ✅ FIX: Show loading dialog while preparing checkout data
      // This ensures all data is loaded before showing checkout screen
      _isCheckoutFlowInProgress = true;
      showCheckoutLoadingDialog(context);

      try {
        // Calculate distance
        await _CartScreenState._calculateAndSetDistanceBeforeCheckout();
        if (!context.mounted) return;

        final checkoutController = Get.find<CheckoutController>();

        // Initialize checkout data (delivery fee calculation)
        await checkoutController.initCheckoutData(
          context,
          storeId,
          preloadedCartList: checkoutCartSnapshot,
          preCalculatedDistance: checkoutController.preCalculatedDistance,
        );
        if (!context.mounted) return;

        // Validate minimum order
        final double subTotal = cartController.subTotal;
        final StoreController storeController = Get.find<StoreController>();
        final double minimumOrder = storeController.store?.minimumOrder ?? 0;

        if (minimumOrder > 0 && subTotal < minimumOrder) {
          showCustomSnackBar(
              '${'minimum_order_amount_is'.tr} ${PriceConverter.convertPrice(minimumOrder)}');
          return;
        }

        if (!cartController.cartList.first.item!.scheduleOrder! &&
            availableList.contains(false)) {
          showCustomSnackBar('one_or_more_product_unavailable'.tr);
          return;
        }

        final finalStoreId = cartController.storeId ?? storeId;

        if (!context.mounted) return;

        // Close loading dialog before pushing checkout route to avoid
        // route stack conflicts where previous route becomes DIALOG.
        dismissCheckoutLoadingDialog();
        await Future<void>.delayed(const Duration(milliseconds: 16));
        if (!context.mounted) return;
        // Navigate to checkout - all data is now ready
        RouteHelper.navigateToCheckout(
          cartList: checkoutCartSnapshot,
          storeId: finalStoreId,
        );
      } catch (e) {
        debugPrint('❌ [Cart→Checkout] Error during preparation: $e');
        if (context.mounted) {
          showCustomSnackBar('unable_to_proceed_checkout'.tr);
        }
      } finally {
        // Always close loading dialog for every early-return/error path.
        dismissCheckoutLoadingDialogSafely(context);
        _isCheckoutFlowInProgress = false;
      }
    } catch (e) {
      debugPrint('❌ [Cart→Checkout] Error: $e');
      dismissCheckoutLoadingDialogSafely(context);
      showCustomSnackBar('unable_to_proceed_checkout'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Get.locale?.languageCode == 'ar';

    return Container(
      width: Dimensions.webMaxWidth,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.isDesktop(context) ? Dimensions.radiusDefault : 0),
      ),
      child: GetBuilder<StoreController>(builder: (storeController) {
        return Column(
          children: [
            SizedBox(
              height: 54,
              width: double.infinity,
              child: CustomButton(
                buttonText: isRTL ? 'الدفع' : 'confirm_delivery_details'.tr,
                fontSize: ResponsiveHelper.isDesktop(context)
                    ? Dimensions.fontSizeSmall
                    : Dimensions.fontSizeLarge,
                isBold: true,
                radius: 14,
                onPressed: () async {
                  await _proceedToCheckout(context);
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _popCartScreen,
                child: Text(
                  'complete_shopping'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
