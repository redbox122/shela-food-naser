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
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_widget.dart';
import 'package:sixam_mart/common/widgets/web_constrained_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/global_sticky_cart_overlay.dart';
import 'package:sixam_mart/features/cart/widgets/web_cart_items_widget.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
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
  static const green200 =
      Color(0xFFB7E0C2); // primary/200 — light green for the +/- icons
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
      final bool isCartRouteCurrent =
          ModalRoute.of(context)?.isCurrent ?? false;
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
          backgroundColor: CartColors.white,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                                  final int
                                                                      index =
                                                                      entry.key;
                                                                  final CartModel
                                                                      cart =
                                                                      entry
                                                                          .value;
                                                                  final List<
                                                                      AddOns> safeAddOns = index <
                                                                          cartController
                                                                              .addOnsList
                                                                              .length
                                                                      ? cartController
                                                                              .addOnsList[
                                                                          index]
                                                                      : <AddOns>[];
                                                                  final bool safeIsAvailable = index <
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
                                                                        vertical:
                                                                            8),
                                                                    child:
                                                                        _ModernCartItemCard(
                                                                      cart:
                                                                          cart,
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
                                                              .isDesktop(
                                                                  context))
                                                            ExtraPackagingWidget(
                                                                cartController:
                                                                    cartController),

                                                          // Suggested items
                                                          if (!ResponsiveHelper
                                                              .isDesktop(
                                                                  context))
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
                                              child: cartController.cartList
                                                          .isNotEmpty &&
                                                      cartController.cartList[0]
                                                              .item !=
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

                        // Minimal order summary matching the new design:
                        // a minimum-order pill (when below threshold) + total row.
                        if (!ResponsiveHelper.isDesktop(context))
                          GetBuilder<CartController>(
                            id: 'cart_summary',
                            builder: (cartController) {
                              final double effectiveTaxPercent =
                                  _resolveCartTaxPercent(
                                      storeController.store?.tax ??
                                          (cartController.cartList.isNotEmpty
                                              ? cartController
                                                  .cartList.first.item?.tax
                                              : null));
                              final bool taxIncluded =
                                  Get.find<SplashController>()
                                          .configModel!
                                          .taxIncluded ==
                                      1;
                              final double minimumOrder =
                                  storeController.store?.minimumOrder ?? 0;
                              final bool belowMinimum = minimumOrder > 0 &&
                                  cartController.subTotal < minimumOrder;
                              final int itemCount =
                                  cartController.cartList.length;

                              return Container(
                                width: context.width,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 8),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: AlignmentDirectional.topStart,
                                  children: [
                                  // Total row — pushed down so the minimum-order
                                  // pill rests on its top edge (the pill is ~35px
                                  // tall, so this offset keeps it above the bar
                                  // instead of sinking into the total text).
                                  Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.only(
                                        top: belowMinimum ? 28 : 0),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF4F5F5),
                                      // Border only on the right + left sides.
                                      border: Border.symmetric(
                                        vertical: BorderSide(
                                          color: CartColors.divider,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${'cart_grand_total'.tr} ($itemCount)',
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            color: CartColors.dark,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            height: 1.6,
                                          ),
                                        ),
                                        DefaultTextStyle(
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            color: CartColors.dark,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          child: _calculateCartTotal(
                                            context,
                                            subTotal: cartController.subTotal,
                                            taxPercent: effectiveTaxPercent,
                                            taxIncluded: taxIncluded,
                                            cartList: cartController.cartList,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Minimum-order pill: at the start (right in
                                  // RTL), overlapping the total bar's top edge.
                                  if (belowMinimum)
                                    PositionedDirectional(
                                      top: 0,
                                      start: 0,
                                      child: _MinimumOrderPill(
                                          minimumOrder: minimumOrder),
                                    ),
                                ]),
                              );
                            },
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
                            cartController.getCartDataOnline(
                                forceRefresh: true);
                          },
                        );
                      }

                      return _EmptyCartView(isRTL: _isRTL);
                    }
                  });
            }),
          ),
        ),
      ),
    );
  }

  /// Clean white header matching the new design.
  /// Back arrow (leading, only when pushed), centered title, and a red
  /// "Clear cart" text action (only when the cart has items).
  PreferredSizeWidget _buildModernHeader() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: CartColors.white,
      surfaceTintColor: CartColors.white,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      systemOverlayStyle: SystemUiOverlayStyle.dark, // dark status icons
      leading: widget.fromNav
          ? null
          : IconButton(
              icon: Icon(
                _isRTL
                    ? Icons.arrow_back_ios_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: CartColors.dark,
                size: 20,
              ),
              onPressed: _popCartScreen,
              tooltip: _isRTL ? 'رجوع' : 'Back',
            ),
      title: Text(
        _isRTL ? 'السلّة' : 'My Cart',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          color: CartColors.dark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.6,
        ),
      ),
      actions: [
        GetBuilder<CartController>(
          id: 'cart_count',
          builder: (cartController) {
            if (cartController.cartList.isEmpty) {
              return const SizedBox(width: Dimensions.paddingSizeSmall);
            }
            return TextButton(
              onPressed: () => _showClearCartSheet(cartController),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'clear_cart'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: const Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                  fontSize: Dimensions.fontSizeDefault,
                  height: 1.6,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Bottom sheet asking the user to confirm clearing the whole cart.
  void _showClearCartSheet(CartController cartController) {
    if (cartController.cartList.isEmpty) {
      showCustomSnackBar('cart_is_empty'.tr);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CartColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'clear_cart_question'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'clear_cart_warning'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: CartColors.dark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
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
                      Navigator.of(sheetContext).pop();
                      await cartController.clearCartList();
                    },
                    child: Text(
                      'clear_cart_confirm'.tr,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F5F5),
                      foregroundColor: CartColors.dark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(
                      'cancel'.tr,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: CartColors.dark,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.6,
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
        fontFamily: 'Tajawal',
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

  /// Short labels for the item's SELECTED food-variation choices + add-ons,
  /// shown under the name (e.g. "ساندوتش 1/2: بيج تايستي"). Read-only; returns
  /// an empty list when the item has no selections so simple items are unchanged.
  List<String> _selectedChoiceLabels() {
    final out = <String>[];
    // Preferred: labels the server already returned in {name, values} shape
    // (market options sheet / order format).
    final serverLabels = cart.selectedVariationLabels;
    if (serverLabels != null && serverLabels.isNotEmpty) {
      out.addAll(serverLabels);
    }
    // Fallback: reconstruct from food-variation selection flags + definitions.
    final defs = cart.item?.foodVariations;
    final sel = cart.foodVariations;
    if (out.isEmpty && defs != null && sel != null) {
      for (int i = 0; i < defs.length && i < sel.length; i++) {
        final vals = defs[i].variationValues;
        final chosen = <String>[];
        for (int j = 0; j < sel[i].length; j++) {
          if (sel[i][j] == true && vals != null && j < vals.length) {
            final lvl = (vals[j].level ?? '').toString().trim();
            if (lvl.isNotEmpty) chosen.add(lvl);
          }
        }
        final name = (defs[i].name ?? '').toString().trim();
        if (chosen.isNotEmpty) {
          out.add(name.isEmpty
              ? chosen.join('، ')
              : '$name: ${chosen.join('، ')}');
        }
      }
    }
    // Selected add-ons (e.g. "زيادة كاتشب").
    final ids = cart.addOnIds?.map((a) => a.id).toSet() ?? <int?>{};
    final itemAddOns = cart.item?.addOns;
    if (ids.isNotEmpty && itemAddOns != null) {
      for (final a in itemAddOns) {
        if (ids.contains(a.id)) {
          final n = (a.name ?? '').toString().trim();
          if (n.isNotEmpty) out.add('+ $n');
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final item = cart.item;
    final String itemName = (item?.name ?? 'item'.tr).trim();
    final List<String> choiceLabels = _selectedChoiceLabels();
    final String description = (item?.description ?? '').trim();
    final String storeName = (item?.storeName ?? '').trim();
    final String subtitle = description.isNotEmpty ? description : storeName;
    final String? imageUrl = item?.imageFullUrl;
    final int quantity = cart.quantity ?? 1;

    // Original price + discount, using the same rule as the rest of the app so
    // the strikethrough original and the discounted price both render.
    final double? basePrice = item?.price;
    final double? discount =
        (item?.storeDiscount ?? 0) == 0 ? item?.discount : item?.storeDiscount;
    final String? discountType =
        (item?.storeDiscount ?? 0) == 0 ? item?.discountType : 'percent';

    void decrement() {
      if (cart.id != null) {
        if (quantity > 1) {
          cartController.setQuantityById(
              false, cart.id!, cart.stock, cart.quantityLimit);
        } else {
          // When quantity is 1, remove the item completely.
          cartController.removeFromCartById(cart.id!,
              item: cart.item, reason: 'quantity_decrement');
        }
      } else if (quantity > 1) {
        // ignore: deprecated_member_use_from_same_package
        cartController.setQuantity(
            false, cartIndex, cart.stock, cart.quantityLimit);
      } else {
        // ignore: deprecated_member_use_from_same_package
        cartController.removeFromCart(cartIndex, item: cart.item);
      }
    }

    void increment() {
      if (cartController.cartList.isNotEmpty &&
          cartController.cartList[0].item?.moduleId != null) {
        cartController.forcefullySetModule(
            context, cartController.cartList[0].item!.moduleId!);
      }
      if (cart.id != null) {
        cartController.setQuantityById(
            true, cart.id!, cart.stock, cart.quantityLimit);
      } else {
        // ignore: deprecated_member_use_from_same_package
        cartController.setQuantity(
            true, cartIndex, cart.stock, cart.quantityLimit);
      }
    }

    return Container(
      width: double.infinity,
      // Min height keeps simple items at the original size; the card grows when
      // selected choices are shown below the name (instead of a fixed 100).
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: CartColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image — start side (right in RTL), in a bordered box.
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CartColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: SmartImage(
                url: imageUrl ?? '',
                width: 70,
                height: 70,
                cacheWidth: 200,
                cacheHeight: 200,
                fit: BoxFit.cover,
                errorWidget: const Icon(
                  Icons.image_not_supported_outlined,
                  color: CartColors.light,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product details — name at the top (up to 2 lines), price pushed to
          // the bottom so the name has room to show fully.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: CartColors.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: CartColors.light,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                  // Selected choices (mandatory options + add-ons) under the
                  // name, so the customer sees exactly what they configured.
                  if (choiceLabels.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      choiceLabels.join('  •  '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: CartColors.light,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Directionality(
                      // RTL so the SAR symbol sits to the left of the price.
                      textDirection: TextDirection.rtl,
                      child: PriceConverter.convertPrice2(
                        basePrice,
                        discount: discount,
                        discountType: discountType,
                        textStyle: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: CartColors.dark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Quantity stepper — end side (left in RTL), lowered to sit near the
          // bottom (aligned with the price).
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              widthFactor: 1,
              child: _GreenQtyStepper(
                quantity: quantity,
                onMinus: decrement,
                onPlus: increment,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green quantity stepper pill ( −  qty  + ) used on the cart item card.
class _GreenQtyStepper extends StatelessWidget {
  const _GreenQtyStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    // Forced LTR so minus stays on the left and plus on the right regardless
    // of the app's text direction.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 104,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: CartColors.green,
          borderRadius: BorderRadius.circular(74.55),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StepBtn(icon: Icons.remove, onTap: onMinus),
            Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            _StepBtn(icon: Icons.add, onTap: onPlus),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Icon(icon, color: CartColors.green200, size: 22),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.isDesktop(context) ? Dimensions.radiusDefault : 0),
      ),
      child: GetBuilder<StoreController>(builder: (storeController) {
        final double minimumOrder = storeController.store?.minimumOrder ?? 0;
        final bool belowMinimum =
            minimumOrder > 0 && cartController.subTotal < minimumOrder;

        return SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  belowMinimum ? const Color(0xFFE8E8E8) : CartColors.green,
              foregroundColor:
                  belowMinimum ? const Color(0xFF545454) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              // Below the store minimum: keep the button tappable but
              // surface a clear message and block navigation to checkout.
              if (belowMinimum) {
                showCustomSnackBar(
                    '${'minimum_order_amount_is'.tr} ${PriceConverter.convertPrice(minimumOrder)}');
                return;
              }
              if (cartController.cartList.isEmpty) {
                return;
              }

              final firstItem = cartController.cartList.first.item;
              if (firstItem == null) return;

              if (!(firstItem.scheduleOrder ?? false) &&
                  availableList.contains(false)) {
                showCustomSnackBar('one_or_more_product_unavailable'.tr);
              } else {
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
                  Get.find<SplashController>()
                      .setModule(Get.find<SplashController>().moduleList![i]);

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
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: Dimensions.fontSizeDefault,
                height: 1.6,
              ),
            ),
          ),
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

/// Small cream pill warning the user that the cart is below the store's
/// minimum order amount (shown just above the total in the new design).
class _MinimumOrderPill extends StatelessWidget {
  const _MinimumOrderPill({required this.minimumOrder});

  final double minimumOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF4E0),
        // Rounded on the TOP corners only; the flat bottom sits on the bar.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info, color: CartColors.dark, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${'minimum_order_amount_is'.tr} ${PriceConverter.convertPrice(minimumOrder)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: CartColors.dark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty cart placeholder matching the new design: illustration, title and a
/// short hint. Used when the cart has no items.
class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({required this.isRTL});

  final bool isRTL;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              Images.empty_cart,
              width: 254,
              height: 275,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shopping_cart_outlined,
                size: 120,
                color: CartColors.light,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'cart_empty_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: CartColors.dark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'cart_empty_message'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: CartColors.dark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
