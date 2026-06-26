// ignore_for_file: constant_identifier_names

// ===========================================
// PRODUCTION CONFIGURATION
// ===========================================
// This app is configured for production deployment
// Base URL: resolved from [EnvironmentConfig] (production: https://shellafood.com)
// Environment: Production
// ===========================================

import 'package:get/get.dart';
import 'package:sixam_mart/common/models/choose_us_model.dart';
import 'package:sixam_mart/features/language/domain/models/language_model.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/environment_config.dart';

class AppConstants {
  static const String appName = 'شله';
  static const double appVersion = 3.7;

  ///Flutter Version: 3.27.4

  static const String fontFamily = 'Roboto';
  static const bool payInWevView = false;
  static const int balanceInputLen = 10;

  // ⚡ Feature Flag: BFF API v2 Unified Endpoint
  // Set to true to use /api/v2/home-unified endpoint (single call for ALL home data)
  // Set to false to use legacy individual API calls (fallback)
  // Benefits: 80% reduction in API calls, 70% smaller payload, faster home screen
  static const bool useBffV2Endpoint =
      true; // ✅ ENABLED: Backend v2 endpoint is ready

  // MyFatoorah Payment Configuration - SECURE
  // Keys are now stored in android/key.properties (not in source code)
  static const bool useMyFatoorahTestMode =
      false; // Set to false for production

  // These will be loaded from secure properties at runtime
  static String? _myFatoorahLiveToken;
  static String? _myFatoorahTestToken;

  // Secure token getters - loaded from properties
  static String get myFatoorahLiveToken => _myFatoorahLiveToken ?? '';
  static String get myFatoorahTestToken => _myFatoorahTestToken ?? '';

  // ── Native Apple Pay (PassKit) ─────────────────────────────────────────────
  // The Apple Pay merchant identifier — must match the entitlement in Xcode
  // (ios/Runner/Runner.entitlements) AND the merchant id registered in the
  // MyFatoorah dashboard. Until BOTH are configured, keep [applePayNativeEnabled]
  // false so checkout transparently uses the existing MyFatoorah WebView flow.
  static const String applePayMerchantId =
      String.fromEnvironment('APPLE_PAY_MERCHANT_ID',
          defaultValue: 'merchant.com.shella.app');
  static const String applePayMerchantName = 'shella';

  // Master switch for the native Apple Pay sheet. OFF by default — flip to true
  // (or pass --dart-define=APPLE_PAY_NATIVE=true) only after the Apple Merchant
  // ID + MyFatoorah Apple Pay activation are both in place.
  static const bool applePayNativeEnabled =
      bool.fromEnvironment('APPLE_PAY_NATIVE', defaultValue: false);

  // ── Embedded (in-app) card payment ─────────────────────────────────────────
  // When true, card payments render MyFatoorah's EMBEDDED card form inside the
  // app (no WebView redirect; the card is tokenized/saved in MyFatoorah). Any
  // failure falls back to the hosted WebView flow. OFF by default until verified
  // on a device — flip with --dart-define=IN_APP_CARD=true.
  static const bool inAppCardPaymentEnabled =
      bool.fromEnvironment('IN_APP_CARD', defaultValue: false);

  // Initialize tokens from secure properties
  static void initializeTokens({
    String? liveToken,
    String? testToken,
  }) {
    _myFatoorahLiveToken = liveToken;
    _myFatoorahTestToken = testToken;
  }

  // Facebook Auth configuration
  // The app ID is stored here as a single source of truth.
  // For production, inject via --dart-define=FACEBOOK_APP_ID=... at build time.
  static const String facebookAppId =
      String.fromEnvironment('FACEBOOK_APP_ID', defaultValue: '380903914182154');

  // Website configuration
  static const bool useReactWebsite = true; // Production website

  // Debug flags (Flutter-only diagnostics, never enabled in production builds)
  // When true, disables CancelToken-based cancellation for /api/v1/items/latest
  static const bool debugDisableItemsCancelToken = false;

  // Verbose logging toggle for development diagnostics
  static const bool enableVerboseLogs = false;

  // Server time offset (milliseconds) stored from Date header
  static const String serverTimeOffsetMs = 'server_time_offset_ms';

  // When true, forces ApiClient to skip the secure HTTP client and use
  // the fallback http client only for /api/v1/items/latest
  static const bool debugItemsUseFallbackOnly = false;

  // PRODUCTION URLS - Using Environment Config
  static String get webHostedUrl => EnvironmentConfig.webHostedUrl;
  static String get baseUrl => EnvironmentConfig.baseUrl;

  static const String categoryUri = '/api/v1/categories';
  static const String business_SettingsUri =
      '/api/v1/business-settings/mobile-app-home-screen-setup';
  static const String bannerUri = '/api/v1/banners';
  static const String storeItemUri = '/api/v1/items/latest';
  static const String popularItemUri = '/api/v1/items/popular';
  static const String reviewedItemUri = '/api/v1/items/most-reviewed';
  static const String searchItemUri = '/api/v1/items/details/';
  static const String subCategoryUri = '/api/v1/categories/childes/';
  static const String categoryItemUri = '/api/v1/categories/items/';
  static const String categoryStoreUri = '/api/v1/categories/stores/';
  static const String configUri = '/api/v1/config';

  /// App-init endpoint - consolidates config, modules, zones, and business settings
  static const String appInitUri = '/api/v1/app-init';

  /// Bootstrap endpoint - consolidates all home screen data into a single call
  static const String bootstrapUri = '/api/v1/bootstrap';

  // ⚡ BFF API v2 Endpoints
  /// Home unified endpoint - single call for ALL home screen data (banners, categories, stores, brands, offers)
  static const String homeUnifiedUri = '/api/v2/home-unified';

  /// Store summary endpoint - minimal store data for checkout (17 fields vs 50+)
  static const String storeSummaryUri = '/api/v2/checkout/store-summary';
  static const String trackUri = '/api/v1/customer/order/track?order_id=';
  static const String messageUri = '/api/v1/customer/message/get';
  static const String forgetPasswordUri = '/api/v1/auth/forgot-password';
  static const String verifyTokenUri = '/api/v1/auth/verify-token';
  static const String resetPasswordUri = '/api/v1/auth/reset-password';
  static const String verifyPhoneUri = '/api/v1/auth/verify-phone';
  static const String checkEmailUri = '/api/v1/auth/check-email';
  static const String verifyEmailUri = '/api/v1/auth/verify-email';
  static const String registerUri = '/api/v1/auth/sign-up';
  static const String resendOtpUri = '/api/v1/auth/send-otp-again';
  static const String loginUri = '/api/v1/auth/customer-login';
  static const String verifyLoginOtpUri = '/api/v1/auth/verify-login-otp';

  // ===== Passwordless auth (v2): phone + OTP =====
  static const String sendOtpV2Uri = '/api/v2/auth/send-otp';
  static const String verifyOtpV2Uri = '/api/v2/auth/verify-otp';
  static const String registerV2Uri = '/api/v2/auth/register';

  static const String tokenUri = '/api/v1/customer/cm-firebase-token';
  static const String placeOrderUri = '/api/v1/customer/order/place';
  static const String processPaymentUri =
      '/api/v1/customer/order/process-payment';
  static const String editOrderAddressUri =
      '/api/v1/customer/order/edit-address';
  static const String store_qidhaUri = '/api/qidha-wallet/store';
  static const String get_walletUri = '/api/qidha-wallet/get-wallet';
  static const String get_delegateUri =
      '/api/v1/customer/delegate/get-delegate-status';
  static const String send_delegateUri = '/api/v1/customer/delegate/store';
  static const String pay_creditUri = '/api/qidha-wallet/credit'; // شحن الرصيد
  static const String pay_debitUri = '/api/qidha-wallet/debit'; // شراء
  static const String nafath_initiateUri = '/api/qidha-wallet/nafath/initiate';
  static const String nafath_checkStatusUri =
      '/api/qidha-wallet/nafath/checkStatus';
  static const String nafath_cancelUri = '/api/qidha-wallet/nafath/cancel';
  static const String nafath_retryUri = '/api/qidha-wallet/nafath/retry';
  static const String nafath_signUri = '/api/qidha-wallet/nafath/sign';
  static const String registration_activityUri =
      '/api/v1/registration-activity';

  //

  static const String offersUri = '/api/v1/offers/active';
  static const String offersItemUri = '/api/v1/offers/';
  static const String placePrescriptionOrderUri =
      '/api/v1/customer/order/prescription/place';
  static const String addressListUri = '/api/v1/customer/address/list';
  static const String zoneUri = '/api/v1/config/get-zone-id';
  static const String checkZoneUri = '/api/v1/zone/check';
  // 🎨 REDESIGN: new address flow — validates a map point AND returns the
  // parsed address parts (city / region / street) in one call.
  static const String checkZoneV2Uri = '/api/v2/address/check-zone';
  static const String addAddressV2Uri = '/api/v2/address/add';
  static const String addressListV2Uri = '/api/v2/address/list';
  static const String addressDetailsV2Uri = '/api/v2/address/details/'; // + id
  static const String deleteAddressV2Uri = '/api/v2/address/'; // + id (DELETE)
  static const String updateAddressV2Uri = '/api/v2/address/'; // + id (PUT)
  static const String removeAddressUri =
      '/api/v1/customer/address/delete?address_id=';
  static const String addAddressUri = '/api/v1/customer/address/add';
  static const String updateAddressUri = '/api/v1/customer/address/update/';
  static const String cartMergeUri = '/cart/merge';
  static const String setMenuUri = '/api/v1/items/set-menu';
  static const String customerInfoUri = '/api/v1/customer/info';
  /// Authenticated My Coupons list (user-specific e.g. is_used). Use headers + auth.
  static const String couponUri = '/api/v1/coupon/list';
  /// Public / unauthenticated catalog; not used for My Coupons screen.
  static const String couponListAllUri = '/api/v1/coupon/list/all';
  /// POST JSON body: `{ "code": "<coupon>", "store_id"?: <int> }`
  static const String couponApplyPostUri = '/api/v1/coupon/apply';
  /// Legacy GET: `/api/v1/coupon/apply?code=<encoded>&store_id=<id>`
  static const String couponApplyUri = '/api/v1/coupon/apply?code=';
  static const String runningOrderListUri =
      '/api/v1/customer/order/running-orders';
  static const String historyOrderListUri = '/api/v1/customer/order/list';
  static const String orderCancelUri = '/api/v1/customer/order/cancel';
  static const String codSwitchUri = '/api/v1/customer/order/payment-method';
  static const String orderDetailsUri =
      '/api/v1/customer/order/details?order_id=';
  static const String alternativeStoresUri =
      '/api/v1/customer/order/alternative-stores';
  static const String wishListGetUri = '/api/v1/customer/wish-list';
  static const String addWishListUri = '/api/v1/customer/wish-list/add?';
  static const String removeWishListUri = '/api/v1/customer/wish-list/remove?';
  static const String notificationUri = '/api/v1/customer/notifications';
  static const String updateProfileUri = '/api/v1/customer/update-profile';
  static const String searchUri = '/api/v1/';
  static const String itemSearchUri = '/api/v1/items/search';

  // Analytics API URIs
  static const String analyticsBaseUri = '/api/v1/customer/analytics';
  static const String qidhaWalletBaseUri = '/api/qidha-wallet';
  static const String analyticsSummaryUri =
      '/api/v1/customer/analytics/summary';
  static const String analyticsSpendingTrendsUri =
      '/api/v1/customer/analytics/spending-trends';
  static const String analyticsMostPurchasedProductsUri =
      '/api/v1/customer/analytics/most-purchased-products';
  static const String analyticsProductDetailsUri =
      '/api/v1/customer/analytics/product-details';
  static const String analyticsInsightsUri =
      '/api/v1/customer/analytics/insights';
  static const String analyticsCategoryBreakdownUri =
      '/api/v1/customer/analytics/category-breakdown';
  static const String analyticsProductTransactionHistoryUri =
      '/api/v1/customer/analytics/product-transaction-history';
  static const String analyticsExportUri = '/api/v1/customer/analytics/export';
  static const String requestExchangeWalletMoney =
      '/api/v1/customer/requestExchangeWalletMoney';
  static const String exchangeWalletMoney =
      '/api/v1/customer/ExchangeWalletMoney';
  static const String reviewUri = '/api/v1/items/reviews/submit';
  static const String itemDetailsUri = '/api/v1/items/details/';

  //
  static const String lastLocationUri =
      '/api/v1/delivery-man/last-location?order_id=';

  //

  static const String deliveryManReviewUri =
      '/api/v1/delivery-man/reviews/submit';
  static const String storeUri = '/api/v1/stores/get-stores';
  static const String popularStoreUri = '/api/v1/stores/popular';
  static const String latestStoreUri = '/api/v1/stores/latest';
  static const String topOfferStoreUri = '/api/v1/stores/top-offer-near-me';
  static const String storeDetailsUri = '/api/v1/stores/details/';
  static const String basicCampaignUri = '/api/v1/campaigns/basic';
  static const String itemCampaignUri = '/api/v1/campaigns/item';
  static const String basicCampaignDetailsUri =
      '/api/v1/campaigns/basic-campaign-details?basic_campaign_id=';
  static const String interestUri = '/api/v1/customer/update-interest';
  static const String suggestedItemUri = '/api/v1/customer/suggested-items';
  static const String storeReviewUri = '/api/v1/stores/reviews';
  static const String distanceMatrixUri = '/api/v1/config/distance-api';

  // Google Maps API Key - provide via --dart-define=GOOGLE_MAPS_KEY=your_key
  // Note: Set your production Google Maps API key via --dart-define or environment config
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_KEY', defaultValue: '');

  //

  static const String searchLocationUri =
      '/api/v1/config/place-api-autocomplete';

  //
  static const String placeDetailsUri = '/api/v1/config/place-api-details';
  static const String geocodeUri = '/api/v1/config/geocode-api';
  static const String allZonesUri =
      '/api/v1/zone/list'; // Get all active zones with coordinates (CORRECTED: backend endpoint)
  static const String socialLoginUri = '/api/v1/auth/social-login';
  static const String socialRegisterUri = '/api/v1/auth/social-register';
  static const String updateZoneUri = '/api/v1/customer/update-zone';
  static const String moduleUri = '/api/v1/module';
  static const String parcelCategoryUri = '/api/v1/parcel-category';
  static const String aboutUsUri = '/api/v1/about-us';
  static const String privacyPolicyUri = '/api/v1/privacy-policy';
  static const String termsAndConditionUri = '/api/v1/terms-and-conditions';
  static const String shippingPolicyUri = '/api/v1/shipping-policy';
  static const String refundUri = '/api/v1/refund-policy';
  static const String cancellationUri = '/api/v1/cancelation';
  static const String subscriptionUri = '/api/v1/newsletter/subscribe';
  static const String customerRemoveUri = '/api/v1/customer/remove-account';
  static const String walletTransactionUri =
      '/api/v1/customer/wallet/transactions';
  static const String loyaltyTransactionUri =
      '/api/v1/customer/loyalty-point/transactions';
  static const String loyaltyPointTransferUri =
      '/api/v1/customer/loyalty-point/point-transfer';
  static const String zoneListUri = '/api/v1/zone/list';
  static const String storeRegisterUri = '/api/v1/auth/vendor/register';
  static const String dmRegisterUri = '/api/v1/auth/delivery-man/store';
  static const String dmCheckRegistrationUri =
      '/api/v1/auth/delivery-man/check-registration';
  static const String customerDmCheckRegistrationUri =
      '/api/v1/customer/delivery-man/check-registration';
  static const String refundReasonUri = '/api/v1/customer/order/refund-reasons';
  static const String supportReasonUri = '/api/v1/customer/automated-message';
  static const String refundRequestUri =
      '/api/v1/customer/order/refund-request';
  static const String directionUri = '/api/v1/config/direction-api';
  static const String vehicleListUri = '/api/v1/vehicles/list';
  static const String taxiCouponUri = '/api/v1/coupon/list/taxi';
  static const String taxiBannerUri = '/api/v1/banners/taxi';
  static const String topRatedVehiclesListUri =
      '/api/v1/vehicles/top-rated/list';
  static const String bandListUri = '/api/v1/vehicles/brand/list';
  // static const String taxiCouponApplyUri = '/api/v1/coupon/apply/taxi?code=';
  static const String tripPlaceUri = '/api/v1/trip/place';
  static const String runningTripUri = '/api/v1/trip/list';
  static const String vehicleChargeUri = '/api/v1/vehicle/extra_charge';
  static const String vehiclesUri = '/api/v1/get-vehicles';
  static const String statusUri = '/api/v1/auth/delivery-man/status';
  static const String storeRecommendedItemUri = '/api/v1/items/recommended';
  static const String orderCancellationUri =
      '/api/v1/customer/order/cancellation-reasons';
  static const String cartStoreSuggestedItemsUri = '/api/v1/items/suggested';
  static const String landingPageUri = '/api/v1/flutter-landing-page';
  static const String mostTipsUri = '/api/v1/most-tips';
  static const String addFundUri = '/api/v1/customer/wallet/add-fund';
  static const String walletBonusUri = '/api/v1/customer/wallet/bonuses';

  // Wallet Transfer (Peer-to-Peer) URIs
  static const String validateRecipientUri =
      '/api/v1/customer/wallet/validate-recipient';
  static const String walletTransferUri = '/api/v1/customer/wallet/transfer';
  static const String savedRecipientsUri = '/api/v1/customer/wallet/recipients';
  static const String addRecipientUri =
      '/api/v1/customer/wallet/recipients/add';

  static const String guestLoginUri = '/api/v1/auth/guest/request';
  static const String offlineMethodListUri =
      '/api/v1/offline_payment_method_list';
  static const String offlinePaymentSaveInfoUri =
      '/api/v1/customer/order/offline-payment';
  static const String offlinePaymentUpdateInfoUri =
      '/api/v1/customer/order/offline-payment-update';
  static const String storeBannersUri = '/api/v1/banners/';
  static const String recommendedItemsUri = '/api/v1/items/recommended?filter=';
  static const String visitAgainStoreUri = '/api/v1/customer/visit-again';
  static const String discountedItemsUri = '/api/v1/items/discounted';
  static const String parcelOtherBannerUri = '/api/v1/other-banners';
  static const String whyChooseUri = '/api/v1/other-banners/why-choose';
  static const String videoContentUri = '/api/v1/other-banners/video-content';
  static const String promotionalBannerUri = '/api/v1/other-banners';
  static const String basicMedicineUri = '/api/v1/items/basic';
  static const String commonConditionUri = '/api/v1/common-condition';
  static const String conditionWiseItemUri = '/api/v1/common-condition/items/';
  static const String flashSaleUri = '/api/v1/flash-sales';
  static const String flashSaleProductsUri = '/api/v1/flash-sales/items';
  static const String featuredCategoriesItemsUri =
      '/api/v1/categories/featured/items';
  static const String recommendedStoreUri = '/api/v1/stores/recommended';
  static const String parcelInstructionUri =
      '/api/v1/customer/order/parcel-instructions';
  static const String cashBackOfferListUri = '/api/v1/cashback/list';
  static const String getCashBackAmountUri = '/api/v1/cashback/getCashback';
  static const String brandListUri = '/api/v1/brands';
  static const String brandItemUri = '/api/v1/brand/items';
  static const String brandSearchItemUri = '/api/v1/brand/items/search';
  static const String brandFilterItemUri = '/api/v1/brand/items/filter';
  static const String advertisementListUri = '/api/v1/advertisement/list';
  static const String searchSuggestionsUri =
      '/api/v1/items/item-or-store-search';
  static const String searchPopularCategoriesUri = '/api/v1/categories/popular';
  static const String firebaseAuthVerify = '/api/v1/auth/firebase-verify-token';
  static const String personalInformationUri = '/api/v1/auth/update-info';
  static const String firebaseResetPassword =
      '/api/v1/auth/firebase-reset-password';
  static const String appVersionCheckUri = '/api/v1/app/version/check';

  ///Subscription
  static const String businessPlanUri = '/api/v1/vendor/business_plan';
  static const String businessPlanPaymentUri =
      '/api/v1/vendor/subscription/payment/api';
  static const String storePackagesUri = '/api/v1/vendor/package-view';

  /// MESSAGING
  static const String conversationListUri = '/api/v1/customer/message/list';
  static const String searchConversationListUri =
      '/api/v1/customer/message/search-list';
  static const String messageListUri = '/api/v1/customer/message/details';
  static const String sendMessageUri = '/api/v1/customer/message/send';

  /// Cart
  static const String getCartListUri = '/api/v1/customer/cart/list';
  static const String addCartUri = '/api/v1/customer/cart/add';
  static const String updateCartUri = '/api/v1/customer/cart/update';
  static const String removeAllCartUri = '/api/v1/customer/cart/remove';
  static const String removeItemCartUri = '/api/v1/customer/cart/remove-item';

  /// Cart v2 — used ONLY for the Market module (module 3). The v2 payload is a
  /// flat, lightweight item shape (no variations/add-ons), so restaurants and
  /// other modules keep using the v1 endpoints above. See [CartRepository].
  static const int marketModuleId = 3;
  static const String getCartListV2Uri = '/api/v2/cart';
  static const String addCartV2Uri = '/api/v2/cart/add';
  static const String updateCartV2Uri = '/api/v2/cart/update';
  static const String removeItemCartV2Uri = '/api/v2/cart/item';
  static const String clearCartV2Uri = '/api/v2/cart/clear';

  ///taxi
  static const String getTopRatedCarsUri = '/api/v1/rental/vehicle/top-rated';
  static const String getTaxiBannerUri = '/api/v1/rental/banners';
  static const String getTaxiCouponUri = '/api/v1/rental/coupon/list';
  static const String taxiCouponApplyUri = '/api/v1/rental/coupon/apply';
  static const String getVehicleDetailsUri =
      '/api/v1/rental/vehicle/get-vehicle-details';
  static const String getVehicleCategoriesUri =
      '/api/v1/rental/vehicle/category-list';
  static const String getSelectVehiclesUri = '/api/v1/rental/vehicle/search/';
  static const String getSearchVehicleSuggestionUri =
      '/api/v1/rental/vehicle/search/suggestion';
  static const String addToCarCartUri = '/api/v1/rental/user/cart/add-to-cart';
  static const String updateCarCartUri = '/api/v1/rental/user/cart/update-cart';
  static const String removeCarCartUri =
      '/api/v1/rental/user/cart/remove-vehicle';
  static const String getCarCartListUri = '/api/v1/rental/user/cart/get-cart';
  static const String tripBookingUri = '/api/v1/rental/user/trip/trip-booking';
  static const String tripUpdateUserDataUri =
      '/api/v1/rental/user/cart/update-user-data';
  static const String removeAllCarCartUri =
      '/api/v1/rental/user/cart/remove-cart';
  static const String removeMultipleCarCartUri =
      '/api/v1/rental/user/cart/remove-multiple-cart';
  static const String tripListUri = '/api/v1/rental/user/trip/get-trip-list';
  static const String tripDetailsUri =
      '/api/v1/rental/user/trip/get-trip-details';
  static const String tripCancelUri = '/api/v1/rental/user/trip/cancel-trip';
  static const String getProviderDetailsUri =
      '/api/v1/rental/provider/get-provider-details';
  static const String getProviderVehicleListUri =
      '/api/v1/rental/vehicle/get-provider-vehicles';
  static const String getProviderVehicleCategoryListUri =
      '/api/v1/rental/vehicle/category-list';
  static const String tripPaymentUri = '/api/v1/rental/user/trip/payment';
  static const String addTaxiWishListUri = '/api/v1/rental/user/wish-list/add';
  static const String removeTaxiWishListUri =
      '/api/v1/rental/user/wish-list/remove';
  static const String getTaxiWishListUri = '/api/v1/rental/user/wish-list';
  static const String getTaxiBrandListUri = '/api/v1/rental/vehicle/brand-list';
  static const String getTaxiProviderReviewUri =
      '/api/v1/rental/provider/get-provider-reviews';
  static const String addTaxiReviewUri = '/api/v1/rental/user/review/add';
  static const String getPopularTaxiSuggestionUri =
      '/api/v1/rental/vehicle/popular-suggestion/';
  static const String getProviderBannerUri = '/api/v1/rental/banners';
  static const String store_infoUri = '/api/qidha-wallet/store';

  /// Store categories + samples
  /// GET /api/v1/stores/{store_id}/categories/{category_id}/subcategories-with-samples
  static const String storeSubcategoriesWithSamplesBaseUri = '/api/v1/stores';

  /// Shared Key
  static const String theme = '6ammart_theme';
  static const String token = '6ammart_token';
  static const String countryCode = '6ammart_country_code';
  static const String languageCode = '6ammart_language_code';
  static const String cacheCountryCode = 'cache_country_code';
  static const String cacheLanguageCode = 'cache_language_code';
  static const String cartList = '6ammart_cart_list';

  /// v3: default position reset; prefs only apply after 4s-hold + drag.
  static const String stickyCartBubbleNudgeDx =
      '6ammart_sticky_cart_bubble_dx_v3';
  static const String stickyCartBubbleNudgeDy =
      '6ammart_sticky_cart_bubble_dy_v3';
  static const String stickyCartBubbleAlignStart =
      '6ammart_sticky_cart_bubble_align_start_v3';
  static const String userPassword = '6ammart_user_password';
  static const String userAddress = '6ammart_user_address';
  static const String userNumber = '6ammart_user_number';
  static const String userCountryCode = '6ammart_user_country_code';
  static const String notification = '6ammart_notification';
  static const String notificationIdList = 'notification_id_list';
  static const String searchHistory = '6ammart_search_history';
  static const String intro = '6ammart_intro';
  static const String notificationCount = '6ammart_notification_count';
  static const String latestNotificationForPopup =
      '6ammart_latest_notification_popup';
  static const String hasUnshownNotificationPopup =
      '6ammart_has_unshown_notification_popup';
  static const String localNotificationLogList =
      '6ammart_local_notification_log_list';
  static const String dmTipIndex = '6ammart_dm_tip_index';
  static const String earnPoint = '6ammart_earn_point';
  static const String acceptCookies = '6ammart_accept_cookies';
  static const String suggestedLocation = '6ammart_suggested_location';
  static const String walletAccessToken = '6ammart_wallet_access_token';
  static const String guestId = 'guest_id';
  static const String guestNumber = 'guest_number';
  /// Play Install Referrer store-QR token (customer sign-up only; not ref_code).
  static const String qrReferralInstallToken = '6ammart_qr_referral_install_token';
  static const String referBottomSheet = '6ammart_reffer_bottomsheet_show';
  static const String dmRegisterSuccess = '6ammart_dm_registration_success';
  static const String isRestaurantRegister = '6ammart_store_registration';

  ///taxi
  static const String taxiSearchHistory = '6ammart_taxi_search_history';
  static const String taxiSearchAddressHistory =
      '6ammart_taxi_search_address_history';
  static const String topic = 'all_zone_customer';
  static const String zoneId = 'zoneId';
  static const String operationAreaId = 'operationAreaId';
  static const String moduleId = 'moduleId';
  static const String cacheModuleId = 'cacheModuleId';
  // Non-sensitive pending payment context (order_id / invoice_id / method /
  // timestamp) used to recover a MyFatoorah/digital payment after the app is
  // backgrounded, killed, network-dropped, or the user backs out. Never stores
  // card data, tokens, or address.
  static const String pendingPaymentContext = 'pending_payment_context';
  static const String localizationKey = 'X-localization';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String cookiesManagement = 'cookies_management';

  // Response Mode header constants for Lite Resources
  static const String responseModeHeader = 'X-Response-Mode';
  static const String responseModeMinimal = 'minimal';
  static const String responseModeStandard = 'standard';

  ///Refer & Earn work flow list..
  static final dataList = [
    'invite_your_friends_and_business'.tr,
    '${'they_register'.tr} ${AppConstants.appName} ${'with_special_offer'.tr}',
    'you_made_your_earning'.tr,
  ];

  /// Delivery Tips
  static List<String> tips = ['0', '15', '10', '20', '40', 'custom'];

  // 🔥 Zone Filtering Configuration
  // List of allowed zone slugs for location selection
  // Currently: Only Riyadh West is allowed
  // Future: Add more zones by simply adding their slugs here
  // Example: ['riyadh-west', 'riyadh-north', 'jeddah-central']
  static const List<String> allowedZoneSlugs = [
    'riyadh-west', // غرب الرياض
  ];

  // 🔥 Geographic Location Filtering Configuration
  // Strict validation: Only West Riyadh city is allowed
  // This ensures locations outside Riyadh (Jeddah, Mecca, etc.) are rejected
  // Future: Add more allowed cities/regions by extending these configs

  /// Allowed city name (must match geocode address)
  static const String allowedCity = 'Riyadh';
  static const String allowedCityArabic = 'الرياض';

  /// West Riyadh geographic bounds (longitude range)
  /// These bounds define the western part of Riyadh city
  // 🗑️ REMOVED: Client-side geographic validation constants
  // All zone validation is now handled by backend API (/api/v1/config/get-zone-id)
  // Backend is the single source of truth for zone boundaries

  static List<String> deliveryInstructionList = [
    'deliver_to_front_door'.tr,
    'deliver_the_reception_desk'.tr,
    'avoid_calling_phone'.tr,
    'come_with_no_sound'.tr,
  ];

  static List<ChooseUsModel> whyChooseUsList = [
    ChooseUsModel(
        icon: Images.landingTrusted,
        title: 'trusted_by_customers_and_store_owners'),
    ChooseUsModel(icon: Images.landingStores, title: 'thousands_of_stores'),
    ChooseUsModel(
        icon: Images.landingExcellent, title: 'excellent_shopping_experience'),
    ChooseUsModel(
        icon: Images.landingCheckout,
        title: 'easy_checkout_and_payment_system'),
  ];

  /// order status..
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String processing = 'processing';
  static const String confirmed = 'confirmed';
  static const String handover = 'handover';
  static const String pickedUp = 'picked_up';
  static const String delivered = 'delivered';

  ///modules..
  static const String pharmacy = 'pharmacy';
  static const String food = 'food';
  static const String parcel = 'parcel';
  static const String ecommerce = 'ecommerce';
  static const String grocery = 'grocery';
  static const String taxi = 'rental';

  static List<LanguageModel> languages = [
    LanguageModel(
        imageUrl: Images.arabic,
        languageName: 'عربى',
        countryCode: 'SA',
        languageCode: 'ar'),
    LanguageModel(
        imageUrl: Images.english,
        languageName: 'English',
        countryCode: 'US',
        languageCode: 'en'),
  ];

  static List<String> joinDropdown = [
    'join_us',
    'become_a_seller',
    'become_a_delivery_man'
  ];

  static final List<Map<String, String>> walletTransactionSortingList = [
    {'title': 'all_transactions', 'value': 'all'},
    {'title': 'order_transactions', 'value': 'order'},
    {'title': 'converted_from_loyalty_point', 'value': 'loyalty_point'},
    {'title': 'added_via_payment_method', 'value': 'add_fund'},
    {'title': 'earned_by_referral', 'value': 'referrer'},
    {'title': 'cash_back_transactions', 'value': 'CashBack'},
  ];

  //taxi seats..
  static List<String> seats = ['1-4', '5-8', '9-13', '14+'];

  // Storage and Asset URLs - Dynamically built from EnvironmentConfig
  /// Storage base URL for offers banners and other storage assets
  static String get storageBaseUrl => '${EnvironmentConfig.baseUrl}/storage';

  /// Offers banners storage path
  static String get offersBannersStoragePath =>
      '$storageBaseUrl/offers-banners';

  /// External URLs (moved from hardcoded strings)
  static const String investorJoinUrl = 'https://app.shelafood.com/';
  static const String qaydhaWebsiteUrl = 'https://app.shelafood.com/';

  /// Placeholder image URLs (for fallback only - should be replaced with local assets)
  static const String placeholderImageUrl = 'https://via.placeholder.com/100';
  static const String placeholderImageUrl60 = 'https://via.placeholder.com/60';
}
