// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'package:sixam_mart/common/performance/page_tracker.dart';
import 'package:sixam_mart/features/add_delegate/screens/add_delegate_screen.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/screens/new_user_setup_screen.dart';
import 'package:sixam_mart/features/auth/screens/succsessflyCreated.dart';
import 'package:sixam_mart/features/brands/screens/brands_product_screen.dart';
import 'package:sixam_mart/features/brands/screens/brands_screen.dart';
import 'package:sixam_mart/features/business/screens/subscription_payment_screen.dart';
import 'package:sixam_mart/features/business/screens/subscription_success_or_failed_screen.dart';
import 'package:sixam_mart/features/chat/domain/models/order_chat_model.dart';
import 'package:sixam_mart/features/location/screens/my_Location.dart';
import 'package:sixam_mart/features/location/screens/select_location_screen.dart';
import 'package:sixam_mart/features/address/screens/address_details_screen.dart';
import 'package:sixam_mart/features/address/screens/delivery_addresses_screen.dart';
import 'package:sixam_mart/features/address/domain/models/check_zone_model.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository_interface.dart';
import 'package:sixam_mart/features/search/domain/services/search_service.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
import 'package:sixam_mart/features/wallet/screens/wallet_screen.dart';
import 'package:sixam_mart/features/wallet_transfer/screens/send_funds_screen.dart';
import 'package:sixam_mart/features/wallet_transfer/screens/choose_receiver_screen.dart';
import 'package:sixam_mart/features/wallet_transfer/screens/transfer_success_screen.dart';
import 'package:sixam_mart/features/wallet_transfer/screens/wallet_transaction_detail_screen.dart';
import 'package:sixam_mart/features/loyalty/screens/loyalty_screen.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/refer_and_earn/screens/refer_and_earn_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/address/screens/add_address_screen.dart';
import 'package:sixam_mart/features/address/screens/address_screen.dart';
import 'package:sixam_mart/features/auth/screens/delivery_man_registration_screen.dart';
// ignore: unused_import
import 'package:sixam_mart/features/auth/screens/sign_in_screen.dart';
import 'package:sixam_mart/features/auth/screens/welcome_screen.dart';
import 'package:sixam_mart/features/auth/screens/phone_login_screen.dart';
import 'package:sixam_mart/features/auth/screens/otp_verification_screen.dart';
import 'package:sixam_mart/features/auth/screens/create_account_screen.dart';
import 'package:sixam_mart/features/auth/screens/sign_up_screen.dart';
import 'package:sixam_mart/features/auth/screens/store_registration_screen.dart';
import 'package:sixam_mart/features/category/screens/category_screen.dart';
import 'package:sixam_mart/features/location/screens/map_screen.dart';
import 'package:sixam_mart/features/store/screens/campaign_screen.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/screen/qr_screen.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/screen/subscription_steps/contract_review_screen.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/screen/main_subscription.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/isLoggedIn_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/html_type.dart';
import 'package:sixam_mart/common/widgets/image_viewer_screen.dart';
import 'package:sixam_mart/common/widgets/not_found.dart';
import 'package:sixam_mart/features/cart/screens/cart_screen.dart';
import 'package:sixam_mart/features/category/screens/category_item_screen.dart';
import 'package:sixam_mart/features/chat/screens/chat_screen.dart';
import 'package:sixam_mart/features/chat/screens/conversation_screen.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/payment/screens/offline_payment_screen.dart';
import 'package:sixam_mart/features/checkout/screens/order_successful_screen.dart';
import 'package:sixam_mart/features/payment/screens/payment_screen.dart';
import 'package:sixam_mart/features/payment/screens/payment_webview_screen.dart';
import 'package:sixam_mart/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/flash_sale/screens/flash_sale_details_screen.dart';
import 'package:sixam_mart/features/item/screens/item_campaign_screen.dart';
import 'package:sixam_mart/features/item/screens/item_details_screen.dart';
import 'package:sixam_mart/features/item/screens/popular_item_screen.dart';
import 'package:sixam_mart/features/verification/screens/forget_pass_screen.dart';
import 'package:sixam_mart/features/verification/screens/new_pass_screen.dart';
import 'package:sixam_mart/features/verification/screens/verification_screen.dart';
import 'package:sixam_mart/features/html/screens/html_viewer_screen.dart';
import 'package:sixam_mart/features/interest/screens/interest_screen.dart';
import 'package:sixam_mart/features/language/screens/language_screen.dart';
// 🔥 SIMPLIFIED FLOW: AccessLocationScreen removed - using PickMapScreen directly
// AccessLocationScreen is now just a redirect, no longer used in routes
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/screens/notification_screen.dart';
import 'package:sixam_mart/features/onboard/screens/onboarding_screen.dart';
import 'package:sixam_mart/features/order/screens/guest_track_order_screen.dart';
import 'package:sixam_mart/features/order/screens/order_details_screen.dart';
import 'package:sixam_mart/features/order/screens/order_screen.dart';
import 'package:sixam_mart/features/order/screens/order_tracking_screen.dart';
import 'package:sixam_mart/features/order/screens/refund_request_screen.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_category_screen.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_location_screen.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_request_screen.dart';
import 'package:sixam_mart/features/profile/screens/profile_screen.dart';
import 'package:sixam_mart/features/profile/screens/update_profile_screen.dart';
import 'package:sixam_mart/features/store/screens/all_store_screen.dart';
import 'package:sixam_mart/features/store/screens/store_item_search_screen.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/features/review/screens/review_screen.dart';
import 'package:sixam_mart/features/search/screens/search_screen.dart';
import 'package:sixam_mart/features/splash/screens/splash_screen.dart';
import 'package:sixam_mart/features/support/screens/support_screen.dart';
import 'package:sixam_mart/features/update/screens/update_screen.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../features/discount/screens/discount_screen.dart';
import '../features/my_coupon/screens/my_coupon_screen.dart';
import '../features/offers/screens/offers_item_screen.dart';
import '../features/statistics/screens/statistics_screen.dart';
import '../features/statistics/screens/statistics_screen_with_toggle.dart';
import '../features/statistics/controllers/analytics_controller.dart';
import '../features/statistics/controllers/qidha_wallet_controller.dart';
import '../features/statistics/data/api/analytics_api_client.dart';
import '../features/statistics/data/api/qidha_wallet_api_client.dart';
import '../features/statistics/data/repositories/analytics_repository_impl.dart';
import '../features/statistics/data/repositories/qidha_wallet_repository_impl.dart';
import '../features/statistics/domain/repositories/analytics_repository.dart';
import '../features/statistics/domain/repositories/qidha_wallet_repository.dart';
import '../features/statistics/data/network_info.dart';
import '../features/wallet_kaidha_subscription/screen/wallet_kaidha_screen.dart';

class RouteHelper {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String language = '/language';
  static const String onBoarding = '/on-boarding';
  static const String welcome = '/welcome';
  static const String phoneLogin = '/phone-login';
  static const String otpVerification = '/otp-verification';
  static const String createAccount = '/create-account';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String verification = '/verification';
  static const String loginOtp = 'login-otp';
  static const String accessLocation = '/access-location';
  static const String pickMap = '/pick-map';
  static const String my_Location = '/my_Location';
  static const String selectLocation = '/select-location';
  static const String addressDetails = '/address-details';
  static const String deliveryAddresses = '/delivery-addresses';

  static const String interest = '/interest';
  static const String main = '/main';
  static const String moduleHome = '/module/:moduleId';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String search = '/search';
  static const String store = '/store';
  static const String orderDetails = '/order-details';
  static const String profile = '/profile';
  static const String updateProfile = '/update-profile';
  static const String coupon = '/coupon';
  static const String notification = '/notification';
  static const String map = '/map';
  static const String address = '/address';
  static const String orderSuccess = '/order-successful';
  static const String payment = '/payment';
  static const String checkout = '/checkout';
  static const String orderTracking = '/track-order';
  static const String basicCampaign = '/basic-campaign';
  static const String html = '/html-page';
  static const String categories = '/categories';
  static const String categoryItem = '/category-item';
  static const String popularItems = '/popular-items';
  static const String itemCampaign = '/item-campaign';
  static const String support = '/help-and-support';
  static const String rateReview = '/rate-and-review';
  static const String offersItemScreen = '/offers-item-screen';
  static const String update = '/update';
  static const String cart = '/cart';
  static const String addAddress = '/add-address';
  static const String editAddress = '/edit-address';
  static const String storeReview = '/store-review';
  static const String allStores = '/stores';
  static const String itemImages = '/item-images';
  static const String parcelCategory = '/parcel-category';
  static const String parcelLocation = '/parcel-location';
  static const String parcelRequest = '/parcel-request';
  static const String searchStoreItem = '/search-store-item';
  static const String order = '/order';
  static const String itemDetails = '/item-details';
  static const String wallet = '/wallet';

  static const String old_wallet = '/old_wallet';

  static const String sendFunds = '/send-funds';
  static const String chooseReceiver = '/choose-receiver';
  static const String transferSuccess = '/transfer-success';

  static const String walletTransactionDetail = '/wallet-transaction-detail';

  static const String loyalty = '/loyalty';
  static const String referAndEarn = '/refer-and-earn';
  static const String messages = '/messages';
  static const String conversation = '/conversation';
  static const String restaurantRegistration = '/store-registration';
  static const String deliveryManRegistration = '/delivery-man-registration';
  static const String refund = '/refund';

  static const String succsessflycreated = '/succsessflycreated';

  static const String offlinePaymentScreen = '/offline-payment-screen';
  static const String flashSaleDetailsScreen = '/flash-sale-details-screen';
  static const String guestTrackOrderScreen = '/guest-track-order-screen';
  static const String favourite = '/favourite';
  static const String brands = '/brands';
  static const String brandsItemScreen = '/brands-item-screen';

  static const String subscriptionSuccess = '/subscription-success';
  static const String subscriptionPayment = '/subscription-payment';
  static const String newUserSetupScreen = '/new-user-setup-screen';
  static const String statistics = '/statistics';

  static const String qr_screen = '/qr';

  static const String add_delegate_screen = '/add_delegate_screen';

  static const String discount = '/discount';

  static const String KiadaWalletSubscription = '/KiadaWallet_Subscription';
  static const String kaidhaWallet = '/kaidha-allet';

  static const String IsLoggedIn_Kiadha_Screen = '/isLoggedIn_kiadha_screen';

  static const String Contract_Review = '/contract_review_screen';

  static String getInitialRoute(
      {bool fromSplash = false, bool skipSplash = false}) {
    // Build route string for fromSplash (backward compatibility)
    // skipSplash is passed via Get.arguments (type-safe) instead of URL parameters
    final route = '$initial?from-splash=$fromSplash';
    return route;
  }

  static String getSplashRoute(NotificationBodyModel? body) {
    String data = 'null';
    if (body != null) {
      final List<int> encoded = utf8.encode(jsonEncode(body.toJson()));
      data = base64Encode(encoded);
    }
    return '$splash?data=$data';
  }

  static String getLanguageRoute(String page) => '$language?page=$page';
  static String getOnBoardingRoute() => onBoarding;
  static String getWelcomeRoute() => welcome;
  static String getPhoneLoginRoute() => phoneLogin;
  static String getOtpVerificationRoute() => otpVerification;
  static String getCreateAccountRoute() => createAccount;
  static String getSignInRoute(String page) => '$signIn?page=$page';
  static String getSignUpRoute() => signUp;

  static String getVerificationRoute(String? number, String? email,
      String? token, String page, String? pass, String loginType,
      {String? session, UpdateUserModel? updateUserModel, String? nextPage}) {
    final List<String> params = ['page=$page'];

    // Add number only if not null and not empty
    if (number != null && number.isNotEmpty) {
      params.add('number=${Uri.encodeQueryComponent(number)}');
    }

    // Add email only if not null and not empty
    if (email != null && email.isNotEmpty) {
      params.add('email=${Uri.encodeQueryComponent(email)}');
    }

    // Add token only if not null and not empty
    if (token != null && token.isNotEmpty) {
      params.add('token=${Uri.encodeQueryComponent(token)}');
    }

    // Add pass only if not null and not empty
    if (pass != null && pass.isNotEmpty) {
      params.add('pass=${Uri.encodeQueryComponent(pass)}');
    }

    // Add login_type only if not empty
    if (loginType.isNotEmpty) {
      params.add('login_type=${Uri.encodeQueryComponent(loginType)}');
    }

    // Add session only if not null
    if (session != null && session.isNotEmpty) {
      final String authSession = base64Url.encode(utf8.encode(session));
      params.add('session=$authSession');
    }

    // Add user_model only if not null
    if (updateUserModel != null) {
      final List<int> encoded =
          utf8.encode(jsonEncode(updateUserModel.toJson()));
      final String userModel = base64Encode(encoded);
      params.add('user_model=$userModel');
    }

    // Add next page only if provided
    if (nextPage != null && nextPage.isNotEmpty) {
      params.add('next=${Uri.encodeQueryComponent(nextPage)}');
    }

    return '$verification?${params.join('&')}';
  }

  static String getLoginOtpRoute(String number, String loginType,
          {String? nextPage}) =>
      getVerificationRoute(number, null, null, loginOtp, null, loginType,
          nextPage: nextPage);

  static String getAccessLocationRoute(String page) =>
      '$accessLocation?page=$page';

  static String getPickMapRoute(String? page, bool canRoute) =>
      '$pickMap?page=$page&route=${canRoute.toString()}';

  static String getSelectLocationRoute({String? page}) =>
      '$selectLocation?page=${page ?? ''}';

  static String getAddressDetailsRoute() => addressDetails;

  static String getDeliveryAddressesRoute() => deliveryAddresses;

  static String getMy_LocationRoute(String? page, bool canRoute) =>
      '$my_Location?page=$page&route=${canRoute.toString()}';

  static String getInterestRoute() => interest;
  static String getMainRoute(String page) => '$main?page=$page';
  static String getModuleHomeRoute(int moduleId) => '/module/$moduleId';

  static String getForgotPassRoute() => forgotPassword;

  static String getResetPasswordRoute(
          String? phone, String token, String page) =>
      '$resetPassword?phone=${Uri.encodeQueryComponent(phone ?? '')}&token=${Uri.encodeQueryComponent(token)}&page=$page';

  static String getSearchRoute({String? queryText}) =>
      '$search?query=${Uri.encodeQueryComponent(queryText ?? '')}';

  static String getStoreRoute({
    required int? id,
    required String page,
    int? categoryId,
    int? itemId,
  }) {
    if (kDebugMode) {
      debugPrint(
          'RouteHelper.getStoreRoute called: id=$id, page=$page, categoryId=$categoryId, itemId=$itemId');
    }

    final StringBuffer route = StringBuffer('$store?id=$id&page=$page');
    if (categoryId != null && categoryId > 0) {
      route.write('&category_id=$categoryId');
    }
    if (itemId != null && itemId > 0) {
      route.write('&item_id=$itemId');
    }
    return route.toString();
  }

  static String getOrderDetailsRoute(int? orderID,
      {bool? fromNotification, bool? fromOffline, String? contactNumber}) {
    return '$orderDetails?id=$orderID&from=${fromNotification.toString()}&from_offline=$fromOffline&contact=${Uri.encodeQueryComponent(contactNumber ?? '')}';
  }

  static String getOrderDetailsRouteBypass(int? orderID,
      {bool? fromNotification, bool? fromOffline, String? contactNumber}) {
    return '$orderDetails?id=$orderID&from=${fromNotification.toString()}&from_offline=$fromOffline&contact=${Uri.encodeQueryComponent(contactNumber ?? '')}&bypass=true';
  }

  static String getProfileRoute() => profile;
  static String getUpdateProfileRoute() => updateProfile;
  static String getCouponRoute() => coupon;
  static String getNotificationRoute({bool? fromNotification}) =>
      '$notification?from=${fromNotification.toString()}';
  static String getMapRoute(AddressModel addressModel, String page, bool isFood,
      {String? storeName}) {
    final List<int> encoded = utf8.encode(jsonEncode(addressModel.toJson()));
    final String data = base64Encode(encoded);
    return '$map?address=$data&page=$page&module=$isFood&store-name=$storeName';
  }

  static String getAddressRoute() => address;
  static String getOrderSuccessRoute(String orderID, String? contactNumber,
      {bool? createAccount, String guestId = ''}) {
    return '$orderSuccess?id=$orderID&contact_number=${Uri.encodeQueryComponent(contactNumber ?? '')}&create_account=$createAccount&guest_id=${Uri.encodeQueryComponent(guestId)}';
  }

  static String getOffersItemScreen(int? offerId, String? offerName,
          {double? offerDiscount}) =>
      '$offersItemScreen?offerId=$offerId&offerName=${Uri.encodeQueryComponent(offerName ?? '')}&offerDiscount=${offerDiscount ?? ''}';
  static String getStatistics() => statistics;

  static String getQr_screen() => qr_screen;

  static String getAdd_DelegateScreen() => add_delegate_screen;

  static String getDiscount() => discount;
  static String getKiadaWalletSubscription() => KiadaWalletSubscription;
  static String getKaidhaWallet() => kaidhaWallet;

  static String get_isLoggedIn_Kiadha_Screen() => IsLoggedIn_Kiadha_Screen;

  static String getold_wallet() => old_wallet;

  static String getSendFundsRoute() => sendFunds;

  static String getChooseReceiverRoute() => chooseReceiver;

  static String getTransferSuccessRoute() => transferSuccess;

  static String getWalletTransactionDetailRoute() => walletTransactionDetail;

  static String getContract_ReviewRoute() => Contract_Review;

  static String getPaymentRoute(String id, int? user, String? type,
          double amount, bool? codDelivery, String? paymentMethod,
          {required String guestId,
          String? contactNumber,
          String? addFundUrl,
          String? subscriptionUrl,
          int? storeId,
          bool? createAccount,
          int? createUserId}) =>
      '$payment?id=$id&user=$user&type=$type&amount=$amount&cod-delivery=$codDelivery&add-fund-url=${Uri.encodeQueryComponent(addFundUrl ?? '')}&payment-method=${Uri.encodeQueryComponent(paymentMethod ?? '')}&guest-id=${Uri.encodeQueryComponent(guestId)}&number=${Uri.encodeQueryComponent(contactNumber ?? '')}&subscription-url=${Uri.encodeQueryComponent(subscriptionUrl ?? '')}&store_id=$storeId&create_account=$createAccount&create_user_id=$createUserId';

  /// Navigate to checkout screen
  ///
  /// ⚠️ DEPRECATED: Use navigateToCheckout() instead for cart checkout!
  /// This method only returns the route string and does NOT pass cartList.
  /// Using this for cart checkout causes duplicate calculations and bugs.
  ///
  /// Only use this for:
  /// - Prescription checkout (page='prescription')
  /// - Campaign checkout (page='campaign')
  @Deprecated(
      'For cart checkout, use RouteHelper.navigateToCheckout() instead. '
      'This method does not pass cartList and causes duplicate calculations.')
  static String getCheckoutRoute(String page, {int? storeId}) =>
      '$checkout?page=$page&store-id=$storeId';

  /// ✅ Non-deprecated helpers for non-cart checkout flows
  /// Use these for prescription/campaign flows where cartList is not required.
  static String getPrescriptionCheckoutRoute({required int storeId}) =>
      '$checkout?page=prescription&store-id=$storeId';

  static String getCampaignCheckoutRoute() =>
      '$checkout?page=campaign&store-id=null';

  /// ✅ ARCHITECTURAL FIX: Navigate to checkout with cartList passed via arguments
  /// This prevents duplicate cart loading and price calculations
  ///
  /// Usage:
  /// ```dart
  /// RouteHelper.navigateToCheckout(
  ///   cartList: cartController.cartList,
  ///   storeId: storeId,
  /// );
  /// ```
  static void navigateToCheckout({
    required List<dynamic> cartList,
    required int storeId,
  }) {
    final List<dynamic> checkoutCartSnapshot = List<dynamic>.from(cartList);
    debugPrint('🛒 RouteHelper.navigateToCheckout:');
    debugPrint('   - cartList length: ${checkoutCartSnapshot.length}');
    debugPrint('   - storeId: $storeId');

    // ✅ Pass cartList via arguments (type-safe, no URL encoding)
    Get.toNamed(
      '$checkout?page=cart&store-id=$storeId',
      arguments: {
        'cartList': checkoutCartSnapshot,
        'storeId': storeId,
        'fromCart': true,
      },
    );
  }

  static String getOrderTrackingRoute(int? id, String? contactNumber) =>
      '$orderTracking?id=$id&number=${Uri.encodeQueryComponent(contactNumber ?? '')}';
  static String getBasicCampaignRoute(BasicCampaignModel basicCampaignModel) {
    final String data =
        base64Encode(utf8.encode(jsonEncode(basicCampaignModel.toJson())));
    return '$basicCampaign?data=$data';
  }

  static String getHtmlRoute(String page) => '$html?page=$page';
  static String getCategoryRoute() => categories;
  static String getCategoryItemRoute(int? id, String name) {
    final List<int> encoded = utf8.encode(name);
    final String data = base64Encode(encoded);
    return '$categoryItem?id=$id&name=$data';
  }

  static String getPopularItemRoute(bool isPopular, bool isSpecial) =>
      '$popularItems?page=${isPopular ? 'popular' : 'reviewed'}&special=${isSpecial.toString()}';
  static String getItemCampaignRoute({bool isJustForYou = false}) =>
      itemCampaign +
      (isJustForYou ? '?just-for-you=${isJustForYou.toString()}' : '');
  static String getSupportRoute() => support;
  static String getReviewRoute() => rateReview;
  static String getUpdateRoute(bool isUpdate) =>
      '$update?update=${isUpdate.toString()}';
  static String getCartRoute() => cart;
  static String getAddAddressRoute(
          bool fromCheckout, bool fromRide, int? zoneId,
          {bool isNavbar = false}) =>
      '$addAddress?page=${fromCheckout ? 'checkout' : 'address'}&ride=$fromRide&zone_id=$zoneId&navbar=$isNavbar';

  static String getEditAddressRoute(AddressModel? address,
      {bool fromGuest = false}) {
    String data = 'null';
    if (address != null) {
      data = base64Url.encode(utf8.encode(jsonEncode(address.toJson())));
    }
    return '$editAddress?data=$data&from-guest=$fromGuest';
  }

  static String getStoreReviewRoute(
      int? storeID, String? storeName, Store store) {
    final String data =
        base64Url.encode(utf8.encode(jsonEncode(store.toJson())));
    return '$storeReview?storeID=$storeID&storeName=${Uri.encodeQueryComponent(storeName ?? '')}&store=$data';
  }

  static String getAllStoreRoute(String page, {bool isNearbyStore = false}) =>
      '$allStores?page=$page${isNearbyStore ? '&nearby=${isNearbyStore.toString()}' : ''}';
  static String getItemImagesRoute(Item item) {
    final String data =
        base64Url.encode(utf8.encode(jsonEncode(item.toJson())));
    return '$itemImages?item=$data';
  }

  static String getParcelCategoryRoute() => parcelCategory;
  static String getParcelLocationRoute(ParcelCategoryModel category) {
    final String data =
        base64Url.encode(utf8.encode(jsonEncode(category.toJson())));
    return '$parcelLocation?data=$data';
  }

  static String getParcelRequestRoute(ParcelCategoryModel category,
      AddressModel pickupAddress, AddressModel destinationAddress) {
    final String category0 =
        base64Url.encode(utf8.encode(jsonEncode(category.toJson())));
    final String pickedUpAddress =
        base64Url.encode(utf8.encode(jsonEncode(pickupAddress.toJson())));
    final String destinationAddress0 =
        base64Url.encode(utf8.encode(jsonEncode(destinationAddress.toJson())));
    return '$parcelRequest?category=$category0&picked=$pickedUpAddress&destination=$destinationAddress0';
  }

  static String getSearchStoreItemRoute(int? storeID) =>
      '$searchStoreItem?id=$storeID';
  static String getOrderRoute() => order;
  static String getItemDetailsRoute(int? itemID, bool isRestaurant) =>
      '$itemDetails?id=$itemID&page=${isRestaurant ? 'restaurant' : 'item'}';

  static String getWalletRoute(
          {String? fundStatus, String? token, bool fromNotification = false}) =>
      '$wallet?payment_status=$fundStatus&token=$token&from_notification=$fromNotification';

  static String getold_walletRoute(
          {String? fundStatus, String? token, bool fromNotification = false}) =>
      '$old_wallet?payment_status=$fundStatus&token=$token&from_notification=$fromNotification';

  static String getLoyaltyRoute({bool fromNotification = false}) =>
      '$loyalty?from_notification=$fromNotification';
  static String getReferAndEarnRoute() => referAndEarn;
  static String getChatRoute(
      {required NotificationBodyModel? notificationBody,
      User? user,
      int? conversationID,
      int? index,
      bool? fromNotification,
      OrderChatModel? orderChatModel}) {
    String notificationBody0 = 'null';
    if (notificationBody != null) {
      notificationBody0 =
          base64Encode(utf8.encode(jsonEncode(notificationBody.toJson())));
    }
    String orderChat = 'null';
    if (orderChatModel != null) {
      orderChat =
          base64Encode(utf8.encode(jsonEncode(orderChatModel.toJson())));
    }
    String user0 = 'null';
    if (user != null) {
      user0 = base64Encode(utf8.encode(jsonEncode(user.toJson())));
    }
    return '$messages?notification=$notificationBody0&user=$user0&conversation_id=$conversationID&index=$index&from=${fromNotification.toString()}&order-chat=$orderChat';
  }

  static String getConversationRoute() => conversation;
  static String getRestaurantRegistrationRoute() => restaurantRegistration;
  static String getDeliverymanRegistrationRoute() => deliveryManRegistration;
  static String getRefundRequestRoute(String orderID) => '$refund?id=$orderID';

  static String getOfflinePaymentScreen({
    required PlaceOrderBodyModel placeOrderBody,
    required int? zoneId,
    required double total,
    required double? maxCodOrderAmount,
    required bool fromCart,
    required bool? isCodActive,
    required bool forParcel,
  }) {
    final List<int> encoded = utf8.encode(jsonEncode(placeOrderBody.toJson()));
    final String data = base64Encode(encoded);
    return '$offlinePaymentScreen?order_body=$data&zone_id=$zoneId&total=$total&max_cod_amount=$maxCodOrderAmount&from_cart=$fromCart&cod_active=$isCodActive&for_parcel=$forParcel';
  }

  static String getFlashSaleDetailsScreen(int id) =>
      '$flashSaleDetailsScreen?id=$id';
  static String getGuestTrackOrderScreen(String orderId, String number) =>
      '$guestTrackOrderScreen?order_id=$orderId&number=${Uri.encodeQueryComponent(number)}';
  static String getFavouriteScreen() => favourite;
  static String getBrandsScreen() => brands;
  static String getBrandsItemScreen(int brandId, String brandName) =>
      '$brandsItemScreen?brandId=$brandId&brandName=${Uri.encodeQueryComponent(brandName)}';

  static String getSubscriptionSuccessRoute(
          {String? status, required bool fromSubscription, int? storeId}) =>
      '$subscriptionSuccess?flag=$status&from_subscription=$fromSubscription&store_id=$storeId';
  static String getSubscriptionPaymentRoute(
          {required int? storeId, required int? packageId}) =>
      '$subscriptionPayment?store-id=$storeId&package-id=$packageId';

  static String getNewUserSetupScreen(
      {required String name,
      required String loginType,
      required String? phone,
      required String? email}) {
    return '$newUserSetupScreen?name=${Uri.encodeQueryComponent(name)}&login_type=${Uri.encodeQueryComponent(loginType)}&phone=${Uri.encodeQueryComponent(phone ?? '')}&email=${Uri.encodeQueryComponent(email ?? '')}';
  }

  static String getSuccsessfly_createdRoute() => succsessflycreated;

  // static String getNewHomeRoute() => newHome;
  // static String getTaxiModuleLocationRoute(String riderType, AddressModel? addressModel) {
  //   String riderType0 = base64Url.encode(utf8.encode(jsonEncode(riderType)));
  //   String address = 'null';
  //   if(addressModel != null){
  //     address = base64Url.encode(utf8.encode(jsonEncode(addressModel)));
  //   }
  //   return '$taxiModuleLocation?rider_type=$riderType0&address=$address';
  // }
  // static String getTaxiLocationResultRoute() => taxiLocationResult;
  // static String getSelectVehicleRoute({required AddressModel? fromAddress, required AddressModel? toAddress}) {
  //   String fromAddress0 = 'null';
  //   String toAddress0 = 'null';
  //   if(fromAddress != null) {
  //     fromAddress0 = base64Url.encode(utf8.encode(jsonEncode(fromAddress.toJson())));
  //   }
  //   if(toAddress != null) {
  //   toAddress0 = base64Url.encode(utf8.encode(jsonEncode(toAddress.toJson())));
  //   }
  //   return '$selectVehicle?from=$fromAddress0&to=$toAddress0';
  // }
  // static String getSearchVehicleRoute() => searchVehicle;
  // static String getCartVehicleRoute() => cartVehicle;
  // static String getTextCheckoutRoute() => texiCheckout;
  // static String getTaxiOrderPageRoute() => taxiOrderPage;
  // static String getVehicleDetailsPageRoute() => vehicleDetails;
  // static String getVehicleProviderDetailsRoute() => vehicleProviderDetails;
  // static String getReviewDetailsScreenRoute() => reviewDetailsScreen;

  static List<GetPage> routes = [
    GetPage(
        name: initial,
        page: () {
          // ⚡ TITAN BOARD: Type-safe argument extraction (no string parsing)
          final args = Get.arguments as Map<String, dynamic>?;
          return PageTracker(
            pageName: 'DashboardScreen',
            child: getRoute(DashboardScreen(
              pageIndex: 0,
              fromSplash: Get.parameters['from-splash'] ==
                  'true', // Keep for backward compat
              skipSplash: (args?['skip_splash'] as bool?) ??
                  false, // Type-safe from arguments
              moduleId: args?['module_id'] as int?,
              previousModuleId: args?['prev_module_id'] as int?,
            )),
          );
        }),
    GetPage(name: sendFunds, page: () => const SendFundsScreen()),
    GetPage(name: chooseReceiver, page: () => const ChooseReceiverScreen()),
    GetPage(name: transferSuccess, page: () => const TransferSuccessScreen()),
    GetPage(
        name: walletTransactionDetail,
        page: () => const WalletTransactionDetailScreen()),
    GetPage(
        name: splash,
        page: () {
          NotificationBodyModel? data;
          if (Get.parameters['data'] != 'null') {
            final List<int> decode =
                base64Decode(Get.parameters['data']!.replaceAll(' ', '+'));
            data = NotificationBodyModel.fromJson(
                jsonDecode(utf8.decode(decode)) as Map<String, dynamic>);
          }
          return PageTracker(
            pageName: 'SplashScreen',
            child: SplashScreen(body: data),
          );
        }),
    GetPage(
        name: language,
        page: () =>
            ChooseLanguageScreen(fromMenu: Get.parameters['page'] == 'menu')),
    GetPage(
        name: onBoarding,
        page: () => const PageTracker(
              pageName: 'OnBoardingScreen',
              child: OnBoardingScreen(),
            )),
    GetPage(
        name: welcome,
        page: () => const PageTracker(
              pageName: 'WelcomeScreen',
              child: WelcomeScreen(),
            )),
    GetPage(
        name: phoneLogin,
        page: () => const PageTracker(
              pageName: 'PhoneLoginScreen',
              child: PhoneLoginScreen(),
            )),
    GetPage(
        name: otpVerification,
        page: () {
          final args = Get.arguments;
          final Map<String, dynamic> data =
              args is Map<String, dynamic> ? args : <String, dynamic>{};
          return PageTracker(
            pageName: 'OtpVerificationScreen',
            child: OtpVerificationScreen(
              phone: data['phone']?.toString() ?? '',
              cooldownSeconds: data['cooldown'] is int ? data['cooldown'] as int : 120,
              expiresInSeconds: data['expires'] is int ? data['expires'] as int : 600,
            ),
          );
        }),
    GetPage(
        name: createAccount,
        page: () => const PageTracker(
              pageName: 'CreateAccountScreen',
              child: CreateAccountScreen(),
            )),
    // Passwordless flow: every sign-in entry point now opens the new Welcome
    // screen. The legacy SignInScreen widget is kept for the upcoming cleanup
    // phase but is no longer routed to.
    GetPage(
        name: signIn,
        page: () => const PageTracker(
              pageName: 'WelcomeScreen',
              child: WelcomeScreen(),
            )),

    GetPage(
        name: signUp,
        page: () => const PageTracker(
              pageName: 'SignUpScreen',
              child: SignUpScreen(),
            )),

    GetPage(
        name: verification,
        page: () {
          String? pass;
          if (Get.parameters['pass'] != null &&
              Get.parameters['pass'] != 'null') {
            final List<int> decode =
                base64Decode(Get.parameters['pass']!.replaceAll(' ', '+'));
            pass = utf8.decode(decode);
          }
          String? session;
          if (Get.parameters['session'] != null &&
              Get.parameters['session'] != 'null') {
            session =
                utf8.decode(base64Url.decode(Get.parameters['session'] ?? ''));
          }
          UpdateUserModel? userModel;
          if (Get.parameters['user_model'] != null &&
              Get.parameters['user_model'] != 'null') {
            final List<int> decode = base64Decode(
                Get.parameters['user_model'] != null
                    ? Get.parameters['user_model']!.replaceAll(' ', '+')
                    : '');
            userModel = UpdateUserModel.fromJson(
                jsonDecode(utf8.decode(decode)) as Map<String, dynamic>);
          }
          return VerificationScreen(
            number: Get.parameters['number'] != '' &&
                    Get.parameters['number'] != 'null'
                ? Get.parameters['number']
                : null,
            fromSignUp: Get.parameters['page'] == signUp,
            token: Get.parameters['token'],
            password: pass,
            email: Get.parameters['email'] != '' &&
                    Get.parameters['email'] != 'null'
                ? Get.parameters['email']
                : null,
            loginType: Get.parameters['login_type'] ?? 'manual',
            firebaseSession: session,
            fromForgetPassword: Get.parameters['page'] == forgotPassword,
            fromLogin2fa: Get.parameters['page'] == loginOtp,
            userModel: userModel,
            nextPage:
                Get.parameters['next'] != '' && Get.parameters['next'] != 'null'
                    ? Get.parameters['next']
                    : null,
          );
        }),

    GetPage(
        name: accessLocation,
        page: () => PickMapScreen(
              fromSignUp: Get.parameters['page'] == signUp,
              fromAddAddress: false,
              canRoute: false,
              route: Get.parameters['page'],
            )),
    GetPage(
        name: pickMap,
        page: () {
          final PickMapScreen? pickMapScreen = Get.arguments as PickMapScreen?;
          final bool fromAddress = Get.parameters['page'] == 'add-address';
          return ((Get.parameters['page'] == 'parcel' &&
                      pickMapScreen == null) ||
                  (fromAddress && pickMapScreen == null))
              ? const NotFound()
              : pickMapScreen ??
                  PickMapScreen(
                    fromSignUp: Get.parameters['page'] == signUp,
                    fromAddAddress: fromAddress,
                    route: Get.parameters['page'],
                    canRoute: Get.parameters['route'] == 'true',
                  );
        }),

    GetPage(
        name: selectLocation,
        page: () => SelectLocationScreen(
              route: Get.parameters['page']?.isNotEmpty == true
                  ? Get.parameters['page']
                  : null,
            )),

    GetPage(
        name: deliveryAddresses,
        page: () => const DeliveryAddressesScreen()),

    GetPage(
        name: addressDetails,
        page: () {
          final args = Get.arguments;
          final Map<String, dynamic> data =
              args is Map<String, dynamic> ? args : const {};
          return AddressDetailsScreen(
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
            zone: data['zone'] is CheckZoneModel
                ? data['zone'] as CheckZoneModel
                : null,
            // Present → edit mode (prefilled form + PUT update).
            addressId: (data['addressId'] as num?)?.toInt(),
          );
        }),

    GetPage(
        name: my_Location,
        page: () {
          final PickMapScreen? pickMapScreen = Get.arguments as PickMapScreen?;
          final bool fromAddress = Get.parameters['page'] == 'add-address';
          return ((Get.parameters['page'] == 'parcel' &&
                      pickMapScreen == null) ||
                  (fromAddress && pickMapScreen == null))
              ? const NotFound()
              : pickMapScreen ??
                  My_Location_Screen(
                    fromSignUp: Get.parameters['page'] == signUp,
                    fromAddAddress: fromAddress,
                    route: Get.parameters['page'],
                    canRoute: Get.parameters['route'] == 'true',
                  );
        }),

    //

    GetPage(name: interest, page: () => const InterestScreen()),
    GetPage(
      name: main,
      page: () => getRoute(
        DashboardScreen(
          // 🎨 REDESIGN: 5-tab nav — home / cart / order / discounts / profile
          pageIndex: Get.parameters['page'] == 'home'
              ? 0
              : Get.parameters['page'] == 'cart'
                  ? 1
                  : Get.parameters['page'] == 'order'
                      ? 2
                      : Get.parameters['page'] == 'discounts'
                          ? 3
                          : Get.parameters['page'] == 'profile' ||
                                  Get.parameters['page'] == 'menu'
                              ? 4
                              : 0,
        ),
      ),
    ),
    GetPage(
      name: moduleHome,
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      page: () {
        final int moduleId = int.tryParse(Get.parameters['moduleId'] ?? '') ??
            (Get.find<SplashController>().module?.id ?? 3);
        return getRoute(
          DashboardScreen(
            pageIndex: 0,
            skipSplash: true,
            moduleId: moduleId,
          ),
        );
      },
    ),

    GetPage(name: forgotPassword, page: () => const ForgetPassScreen()),

    GetPage(
        name: resetPassword,
        page: () => NewPassScreen(
              resetToken: Get.parameters['token'],
              number: Get.parameters['phone'],
              fromPasswordChange: Get.parameters['page'] == 'password-change',
            )),

    GetPage(
        name: search,
        page: () {
          final String searchQuery = Get.parameters['query'] ?? '';
          debugPrint(
              '[Search][OPEN] route=${Get.currentRoute} query=$searchQuery');
          return getRoute(SearchScreen(queryText: searchQuery));
        }),

    GetPage(
        name: store,
        page: () {
          // Open every store with the redesigned storefront (sticky category
          // tabs + product rows). Falls back to the legacy StoreScreen only for
          // slug deep links that carry no store id.
          final String? idParam = Get.parameters['id'];
          final int? sid = (idParam != null && idParam != 'null')
              ? int.tryParse(idParam)
              : null;
          final String slug = Get.parameters['slug'] ?? '';
          final Widget screen = (Get.arguments as Widget?) ??
              (sid != null
                  ? MarketStoreScreen(
                      storeId: sid,
                      moduleId: Get.isRegistered<SplashController>()
                          ? (Get.find<SplashController>().module?.id ?? 3)
                          : 3,
                      useCoverHeader: true,
                    )
                  : StoreScreen(
                      store: Store(id: null),
                      fromModule: Get.parameters['page'] == 'module',
                      slug: slug,
                    ));
          return getRoute(screen, byPuss: slug.isNotEmpty);
        }),
    GetPage(
        name: orderDetails,
        page: () {
          return getRoute(
            (Get.arguments as Widget?) ??
                OrderDetailsScreen(
                  orderId: int.parse(Get.parameters['id'] ?? '0'),
                  orderModel: null,
                  fromNotification: Get.parameters['from'] == 'true',
                  fromOfflinePayment: Get.parameters['from_offline'] == 'true',
                  contactNumber: Get.parameters['contact'],
                ),
          );
        }),

    GetPage(
        name: statistics,
        page: () => getRoute(const StatisticsScreenWithToggle())),
    GetPage(
        name: offersItemScreen,
        page: () => OffersItemScreen(
              offerId: int.parse(Get.parameters['offerId']!),
              offerName: Get.parameters['offerName']!,
              offerDiscount: Get.parameters['offerDiscount']?.isNotEmpty == true
                  ? double.tryParse(Get.parameters['offerDiscount']!)
                  : null,
            )),

    GetPage(name: qr_screen, page: () => getRoute(Qr_Screen())),

    GetPage(
        name: add_delegate_screen,
        page: () => getRoute(const Add_DelegateScreen())),

    GetPage(name: discount, page: () => getRoute(const DiscountScreen())),

    GetPage(
        name: KiadaWalletSubscription,
        page: () => getRoute(const KiadaWalletSubscriptionScreen())),

    GetPage(
        name: kaidhaWallet, page: () => getRoute(const WalletKaidhaScreen())),

    GetPage(
        name: IsLoggedIn_Kiadha_Screen,
        page: () => getRoute(const Kiadha_WalletScreen())),

    GetPage(name: coupon, page: () => getRoute(const MyCouponScreen())),

    GetPage(
        name: Contract_Review,
        page: () => getRoute(const Contract_ReviewScreen())),

    GetPage(
        name: old_wallet,
        page: () {
          return getRoute(WalletScreen(
              fundStatus:
                  Get.parameters['flag'] ?? Get.parameters['payment_status'],
              token: Get.parameters['token']));
        }),

    GetPage(name: profile, page: () => getRoute(const ProfileScreen())),
    GetPage(
        name: updateProfile, page: () => getRoute(const UpdateProfileScreen())),
    GetPage(
        name: notification,
        page: () => getRoute(NotificationScreen(
            fromNotification: Get.parameters['from'] == 'true'))),
    GetPage(
        name: map,
        page: () {
          final List<int> decode =
              base64Decode(Get.parameters['address']!.replaceAll(' ', '+'));
          final AddressModel data = AddressModel.fromJson(
              jsonDecode(utf8.decode(decode)) as Map<String, dynamic>);
          return getRoute(MapScreen(
              fromStore: Get.parameters['page'] == 'store',
              address: data,
              isFood: Get.parameters['module'] == 'true',
              storeName: Get.parameters['store-name'] ?? ''));
        }),
    GetPage(name: address, page: () => getRoute(const AddressScreen())),
    GetPage(
        name: orderSuccess,
        page: () => getRoute(
              OrderSuccessfulScreen(
                orderID: Get.parameters['id'],
                contactPersonNumber: Get.parameters['contact_number'] != null &&
                        Get.parameters['contact_number'] != 'null' &&
                        Get.parameters['contact_number']!.isNotEmpty
                    ? Get.parameters['contact_number']
                    : AuthHelper.isGuestLoggedIn()
                        ? Get.find<AuthController>().getGuestNumber()
                        : null,
                createAccount: Get.parameters['create_account'] == 'true',
                guestId: Get.parameters['guest_id'] ?? '',
              ),
            )),
    GetPage(
        name: payment,
        page: () {
          final OrderModel order = OrderModel(
            id: int.parse(Get.parameters['id']!),
            orderType: Get.parameters['type'],
            userId: int.parse(Get.parameters['user']!),
            orderAmount: double.parse(Get.parameters['amount']!),
          );
          final bool isCodActive = Get.parameters['cod-delivery'] == 'true';
          String addFundUrl = '';
          String subscriptionUrl = '';
          final String paymentMethod = Get.parameters['payment-method']!;
          if (Get.parameters['add-fund-url'] != null &&
              Get.parameters['add-fund-url'] != 'null' &&
              Get.parameters['add-fund-url']!.isNotEmpty) {
            addFundUrl = Get.parameters['add-fund-url']!;
          }
          if (Get.parameters['subscription-url'] != null &&
              Get.parameters['subscription-url'] != 'null' &&
              Get.parameters['subscription-url']!.isNotEmpty) {
            subscriptionUrl = Get.parameters['subscription-url']!;
          }
          final String guestId = Get.parameters['guest-id']!;
          final String number = Get.parameters['number']!;
          final int? storeId = (Get.parameters['store_id'] != null &&
                  Get.parameters['store_id'] != 'null')
              ? int.parse(Get.parameters['store_id']!)
              : null;
          final bool createAccount = Get.parameters['create_account'] == 'true';
          final int? createUserId = Get.parameters['create_user_id'] != null &&
                  Get.parameters['create_user_id'] != 'null'
              ? int.parse(Get.parameters['create_user_id']!)
              : null;
          return getRoute(AppConstants.payInWevView
              ? PaymentWebViewScreen(
                  orderModel: order,
                  isCashOnDelivery: isCodActive,
                  addFundUrl: addFundUrl,
                  paymentMethod: paymentMethod,
                  guestId: guestId,
                  contactNumber: number,
                  subscriptionUrl: subscriptionUrl,
                  storeId: storeId,
                  createAccount: createAccount,
                )
              : PaymentScreen(
                  orderModel: order,
                  isCashOnDelivery: isCodActive,
                  addFundUrl: addFundUrl,
                  paymentMethod: paymentMethod,
                  guestId: guestId,
                  contactNumber: number,
                  subscriptionUrl: subscriptionUrl,
                  storeId: storeId,
                  createAccount: createAccount,
                  createUserId: createUserId,
                ));
        }),
    GetPage(
        name: checkout,
        page: () {
          // ⛔ Debug: Log route change details
          debugPrint('🔄 RouteHelper: Building checkout page');
          debugPrint('   - Current route: ${Get.currentRoute}');
          debugPrint('   - Previous route: ${Get.routing.previous}');
          debugPrint('   - Parameters: ${Get.parameters}');

          // ✅ ARCHITECTURAL FIX: Extract cartList from arguments
          final dynamic arguments = Get.arguments;
          List<CartModel?>? cartList;
          CheckoutScreen? checkoutScreen;
          bool fromCart = Get.parameters['page'] == 'cart';
          int? storeId;

          debugPrint(
              '🛒 RouteHelper: Arguments type: ${arguments.runtimeType}');

          // ✅ Priority 1: Check if arguments is a Map with cartList (new flow)
          if (arguments != null && arguments is Map<String, dynamic>) {
            // New flow: cartList passed via navigateToCheckout()
            if (arguments['cartList'] != null) {
              cartList = (arguments['cartList'] as List).cast<CartModel?>();
              debugPrint(
                  '✅ RouteHelper: Got cartList from arguments - ${cartList.length} items');
            }
            if (arguments['storeId'] != null) {
              storeId = arguments['storeId'] as int;
            }
            if (arguments['fromCart'] != null) {
              fromCart = arguments['fromCart'] as bool;
            }
          } else if (arguments != null && arguments is CheckoutScreen) {
            // Legacy: CheckoutScreen passed directly
            checkoutScreen = arguments;
            debugPrint('🛒 RouteHelper: Using CheckoutScreen from arguments');
          } else if (arguments != null && arguments is AddressModel) {
            debugPrint(
                '🛒 RouteHelper: AddressModel passed, will be handled by CheckoutScreen');
          } else {
            debugPrint(
                '⚠️ RouteHelper: No cartList in arguments - will use fallback');
          }

          // Parse storeId from URL if not in arguments
          if (storeId == null) {
            final storeIdParam = Get.parameters['store-id'];
            if (storeIdParam != null &&
                storeIdParam != 'null' &&
                storeIdParam.isNotEmpty) {
              try {
                storeId = int.parse(storeIdParam);
              } catch (e) {
                debugPrint(
                    '❌ Error parsing store-id parameter: $storeIdParam, error: $e');
              }
            }
          }

          // ✅ الحل النهائي: لا نرجع NotFound أبداً لمنع Navigation Loop
          if (!fromCart) {
            debugPrint(
                '⚠️ Checkout opened without fromCart param, defaulting to cart mode');
          }

          return getRoute(checkoutScreen ??
              CheckoutScreen(
                cartList: cartList, // ✅ Now properly passed from arguments!
                fromCart: fromCart,
                storeId: storeId,
              ));
        }),
    GetPage(
        name: orderTracking,
        page: () => getRoute(OrderTrackingScreen(
              orderID: Get.parameters['id'],
              contactNumber: Get.parameters['number'],
            ))),
    GetPage(
        name: basicCampaign,
        page: () {
          final BasicCampaignModel data = BasicCampaignModel.fromJson(
              jsonDecode(utf8.decode(base64Decode(
                      Get.parameters['data']!.replaceAll(' ', '+'))))
                  as Map<String, dynamic>);
          return getRoute(CampaignScreen(campaign: data));
        }),
    GetPage(
        name: html,
        page: () => HtmlViewerScreen(
              htmlType: Get.parameters['page'] == 'terms-and-condition'
                  ? HtmlType.termsAndCondition
                  : Get.parameters['page'] == 'privacy-policy'
                      ? HtmlType.privacyPolicy
                      : Get.parameters['page'] == 'shipping-policy'
                          ? HtmlType.shippingPolicy
                          : Get.parameters['page'] == 'cancellation-policy'
                              ? HtmlType.cancellation
                              : Get.parameters['page'] == 'refund-policy'
                                  ? HtmlType.refund
                                  : HtmlType.aboutUs,
            )),
    GetPage(name: categories, page: () => getRoute(const CategoryScreen())),
    GetPage(
        name: categoryItem,
        page: () {
          final List<int> decode =
              base64Decode(Get.parameters['name']!.replaceAll(' ', '+'));
          final String data = utf8.decode(decode);
          return getRoute(CategoryItemScreen(
              categoryID: Get.parameters['id'], categoryName: data));
        }),
    GetPage(
        name: popularItems,
        page: () => getRoute(PopularItemScreen(
            isPopular: Get.parameters['page'] == 'popular',
            isSpecial: Get.parameters['special'] == 'true'))),
    GetPage(
        name: itemCampaign,
        page: () => getRoute(ItemCampaignScreen(
            isJustForYou: Get.parameters['just-for-you'] == 'true'))),
    GetPage(name: support, page: () => const SupportScreen()),
    GetPage(
        name: update,
        page: () => UpdateScreen(isUpdate: Get.parameters['update'] == 'true')),
    GetPage(name: cart, page: () => getRoute(const CartScreen(fromNav: false))),
    GetPage(
        name: addAddress,
        page: () => getRoute(AddAddressScreen(
              fromCheckout: Get.parameters['page'] == 'checkout',
              fromRide: Get.parameters['ride'] == 'true',
              zoneId: int.parse(Get.parameters['zone_id']!),
              fromNavBar: Get.parameters['navbar'] == 'true',
            ))),
    GetPage(
        name: editAddress,
        page: () {
          AddressModel? data;
          if (Get.parameters['data'] != 'null') {
            data = AddressModel.fromJson(jsonDecode(utf8.decode(base64Url
                    .decode(Get.parameters['data']!.replaceAll(' ', '+'))))
                as Map<String, dynamic>);
          }
          return getRoute(AddAddressScreen(
            fromCheckout: false,
            fromRide: false,
            address: data,
            forGuest: Get.parameters['from-guest'] == 'true',
          ));
        }),
    GetPage(
        name: rateReview,
        page: () => getRoute((Get.arguments as Widget?) ?? const NotFound())),
    GetPage(
        name: storeReview,
        page: () => getRoute(ReviewScreen(
            storeID: Get.parameters['storeID'],
            storeName: Get.parameters['storeName'],
            store: Store.fromJson(jsonDecode(utf8.decode(base64Url
                    .decode(Get.parameters['store']!.replaceAll(' ', '+'))))
                as Map<String, dynamic>)))),
    GetPage(
        name: allStores,
        page: () => getRoute(AllStoreScreen(
              isPopular: Get.parameters['page'] == 'popular',
              isFeatured: Get.parameters['page'] == 'featured',
              isTopOfferStore: Get.parameters['page'] == 'topOffer',
              isNearbyStore: Get.parameters['nearby'] == 'true',
            ))),
    GetPage(
        name: itemImages,
        page: () => getRoute(ImageViewerScreen(
              item: Item.fromJson(jsonDecode(utf8.decode(base64Url
                      .decode(Get.parameters['item']!.replaceAll(' ', '+'))))
                  as Map<String, dynamic>),
            ))),
    GetPage(
        name: parcelCategory,
        page: () => getRoute(const ParcelCategoryScreen())),
    GetPage(
        name: parcelLocation,
        page: () => getRoute(ParcelLocationScreen(
              category: ParcelCategoryModel.fromJson(jsonDecode(utf8.decode(
                      base64Url.decode(
                          Get.parameters['data']!.replaceAll(' ', '+'))))
                  as Map<String, dynamic>),
            ))),
    GetPage(
        name: parcelRequest,
        page: () => getRoute(ParcelRequestScreen(
              parcelCategory: ParcelCategoryModel.fromJson(jsonDecode(
                      utf8.decode(base64Url.decode(
                          Get.parameters['category']!.replaceAll(' ', '+'))))
                  as Map<String, dynamic>),
              pickedUpAddress: AddressModel.fromJson(jsonDecode(utf8.decode(
                      base64Url.decode(
                          Get.parameters['picked']!.replaceAll(' ', '+'))))
                  as Map<String, dynamic>),
              destinationAddress: AddressModel.fromJson(jsonDecode(utf8.decode(
                      base64Url.decode(
                          Get.parameters['destination']!.replaceAll(' ', '+'))))
                  as Map<String, dynamic>),
            ))),
    GetPage(
        name: searchStoreItem,
        page: () =>
            getRoute(StoreItemSearchScreen(storeID: Get.parameters['id']))),
    GetPage(name: order, page: () => getRoute(const OrderScreen())),
    GetPage(
        name: itemDetails,
        page: () => getRoute((Get.arguments as Widget?) ??
            ItemDetailsScreen(
                item: Item(id: int.parse(Get.parameters['id']!)),
                inStorePage: Get.parameters['page'] == 'restaurant'))),

    GetPage(
        name: loyalty,
        page: () => getRoute(LoyaltyScreen(
            fromNotification: Get.parameters['from_notification'] == 'true'))),
    GetPage(
        name: referAndEarn, page: () => getRoute(const ReferAndEarnScreen())),
    GetPage(
        name: messages,
        page: () {
          NotificationBodyModel? notificationBody;
          if (Get.parameters['notification'] != 'null') {
            notificationBody = NotificationBodyModel.fromJson(jsonDecode(
                    utf8.decode(base64Url.decode(
                        Get.parameters['notification']!.replaceAll(' ', '+'))))
                as Map<String, dynamic>);
          }
          OrderChatModel? orderChat;
          if (Get.parameters['order-chat'] != 'null') {
            orderChat = OrderChatModel.fromJson(jsonDecode(utf8.decode(
                    base64Url.decode(
                        Get.parameters['order-chat']!.replaceAll(' ', '+'))))
                as Map<String, dynamic>);
          }
          User? user;
          if (Get.parameters['user'] != 'null') {
            user = User.fromJson(jsonDecode(utf8.decode(base64Url
                    .decode(Get.parameters['user']!.replaceAll(' ', '+'))))
                as Map<String, dynamic>);
          }
          return getRoute(ChatScreen(
            notificationBody: notificationBody,
            user: user,
            index: Get.parameters['index'] != 'null'
                ? int.parse(Get.parameters['index']!)
                : null,
            fromNotification: Get.parameters['from'] == 'true',
            conversationID: (Get.parameters['conversation_id'] != null &&
                    Get.parameters['conversation_id'] != 'null')
                ? int.parse(Get.parameters['conversation_id']!)
                : null,
            orderChatModel: orderChat,
          ));
        }),
    GetPage(name: conversation, page: () => const ConversationScreen()),

    GetPage(name: succsessflycreated, page: () => const Succsessflycreated()),

    GetPage(
        name: restaurantRegistration,
        page: () => const StoreRegistrationScreen()),
    GetPage(
        name: deliveryManRegistration,
        page: () => const DeliveryManRegistrationScreen()),
    GetPage(
        name: refund,
        page: () => RefundRequestScreen(orderId: Get.parameters['id'])),
    GetPage(
      name: offlinePaymentScreen,
      page: () {
        final List<int> decode =
            base64Decode(Get.parameters['order_body']!.replaceAll(' ', '+'));
        final PlaceOrderBodyModel orderBody = PlaceOrderBodyModel.fromJson(
            jsonDecode(utf8.decode(decode)) as Map<String, dynamic>);

        return OfflinePaymentScreen(
          placeOrderBody: orderBody,
          zoneId: int.parse(Get.parameters['zone_id']!),
          total: double.parse(Get.parameters['total']!),
          maxCodOrderAmount: (Get.parameters['max_cod_amount'] != null &&
                  Get.parameters['max_cod_amount'] != 'null')
              ? double.parse(Get.parameters['max_cod_amount']!)
              : null,
          fromCart: Get.parameters['from_cart'] == 'true',
          isCashOnDeliveryActive: Get.parameters['cod_active'] == 'true',
          forParcel: Get.parameters['for_parcel'] == 'true',
        );
      },
    ),
    GetPage(
        name: flashSaleDetailsScreen,
        page: () =>
            FlashSaleDetailsScreen(id: int.parse(Get.parameters['id']!))),
    GetPage(
        name: guestTrackOrderScreen,
        page: () => GuestTrackOrderScreen(
              orderId: Get.parameters['order_id']!,
              number: Get.parameters['number']!,
            )),
    GetPage(name: favourite, page: () => const FavouriteScreen()),
    GetPage(name: brands, page: () => const BrandsScreen()),
    GetPage(
        name: brandsItemScreen,
        page: () => BrandsItemScreen(
              brandId: int.parse(Get.parameters['brandId']!),
              brandName: Get.parameters['brandName']!,
            )),

    GetPage(
        name: subscriptionSuccess,
        page: () => SubscriptionSuccessOrFailedScreen(
            success: Get.parameters['flag'] == 'success',
            fromSubscription: Get.parameters['from_subscription'] == 'true',
            storeId: (Get.parameters['store_id'] != null &&
                    Get.parameters['store_id'] != 'null')
                ? int.parse(Get.parameters['store_id']!)
                : null)),
    GetPage(
        name: subscriptionPayment,
        page: () => SubscriptionPaymentScreen(
            storeId: int.parse(Get.parameters['store-id']!),
            packageId: int.parse(Get.parameters['package-id']!))),
    GetPage(
        name: newUserSetupScreen,
        page: () => NewUserSetupScreen(
              name: Get.parameters['name']!,
              loginType: Get.parameters['login_type']!,
              phone: Get.parameters['phone'] != '' &&
                      Get.parameters['phone'] != 'null'
                  ? Get.parameters['phone']!.replaceAll(' ', '+')
                  : null,
              email: Get.parameters['email'] != '' &&
                      Get.parameters['email'] != 'null'
                  ? Get.parameters['email']!.replaceAll(' ', '+')
                  : null,
            )),
  ];

  static bool _shouldBypassAddressCheck() {
    // Check if we're navigating to order details with bypass parameter
    return Get.parameters['bypass'] == 'true';
  }

  static Widget getRoute(Widget navigateTo,
      {PickMapScreen? locationScreen, bool byPuss = false}) {
    double? minimumVersion = 0;
    if (GetPlatform.isAndroid) {
      minimumVersion =
          Get.find<SplashController>().configModel!.appMinimumVersionAndroid;
    } else if (GetPlatform.isIOS) {
      minimumVersion =
          Get.find<SplashController>().configModel!.appMinimumVersionIos;
    }

    // ✅ تسجيل Search dependencies فقط إذا كانت الشاشة SearchScreen
    if (navigateTo is SearchScreen &&
        !Get.isRegistered<SearchServiceInterface>()) {
      Get.lazyPut<SearchRepositoryInterface>(() => SearchRepository(
          apiClient: Get.find(), sharedPreferences: Get.find()));

      Get.lazyPut<SearchServiceInterface>(
          () => SearchService(searchRepositoryInterface: Get.find()));

      Get.lazyPut(() => SearchController(
            searchServiceInterface: Get.find(),
          ));
    }

    // ✅ تسجيل Analytics dependencies فقط إذا كانت الشاشة StatisticsScreen أو StatisticsScreenWithToggle
    if ((navigateTo is StatisticsScreen ||
            navigateTo is StatisticsScreenWithToggle) &&
        !Get.isRegistered<AnalyticsController>()) {
      Get.lazyPut<NetworkInfo>(() => NetworkInfo());
      Get.lazyPut<AnalyticsApiClient>(
          () => AnalyticsApiClient(apiClient: Get.find()));
      Get.lazyPut<QidhaWalletApiClient>(
          () => QidhaWalletApiClient(apiClient: Get.find()));
      Get.lazyPut<AnalyticsRepository>(() => AnalyticsRepositoryImpl(
            analyticsApiClient: Get.find<AnalyticsApiClient>(),
            networkInfo: Get.find<NetworkInfo>(),
          ));
      Get.lazyPut<QidhaWalletRepository>(() => QidhaWalletRepositoryImpl(
            qidhaWalletApiClient: Get.find<QidhaWalletApiClient>(),
            networkInfo: Get.find<NetworkInfo>(),
          ));
      Get.lazyPut<AnalyticsController>(() =>
          AnalyticsController(repository: Get.find<AnalyticsRepository>()));
      Get.lazyPut<QidhaWalletController>(() =>
          QidhaWalletController(repository: Get.find<QidhaWalletRepository>()));
    }

    // Check if we have a valid location (either saved in SharedPreferences or in LocationController)
    bool hasValidLocation = false;

    // First check SharedPreferences
    final AddressModel? savedAddress =
        AddressHelper.getUserAddressFromSharedPref();
    if (savedAddress != null &&
        savedAddress.latitude != null &&
        savedAddress.longitude != null &&
        savedAddress.latitude!.isNotEmpty &&
        savedAddress.longitude!.isNotEmpty) {
      try {
        final double lat = double.parse(savedAddress.latitude!);
        final double lng = double.parse(savedAddress.longitude!);
        // Check if coordinates are valid (not 0.0, 0.0)
        if (lat != 0.0 || lng != 0.0) {
          hasValidLocation = true;
        }
      } catch (e) {
        // Invalid saved address, continue checking LocationController
      }
    }

    // If no saved address, check LocationController position
    if (!hasValidLocation && Get.isRegistered<LocationController>()) {
      try {
        final locationController = Get.find<LocationController>();
        final position = locationController.position;
        // Check if position is valid (not 0.0, 0.0)
        if (position.latitude != 0.0 || position.longitude != 0.0) {
          hasValidLocation = true;
        }
      } catch (e) {
        // LocationController not available or error, continue
      }
    }

    return (AppConstants.appVersion < (minimumVersion ?? 0.0) &&
            !GetPlatform.isWeb)
        ? const UpdateScreen(isUpdate: true)
        : Get.find<SplashController>().configModel!.maintenanceMode!
            ? const UpdateScreen(isUpdate: false)
            : (!hasValidLocation && !byPuss && !_shouldBypassAddressCheck())
                ? PickMapScreen(
                    fromSignUp: false,
                    fromAddAddress: false,
                    canRoute: false,
                    route: Get.currentRoute,
                  )
                : navigateTo;
  }
}
