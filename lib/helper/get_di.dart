import 'dart:convert';
import 'package:sixam_mart/features/refer_and_earn/controllers/referral_controller.dart';
import 'package:sixam_mart/features/add_delegate/controllers/delegate_controller.dart';
import 'package:sixam_mart/features/add_delegate/domain/reposotories/delegate_repository.dart';
import 'package:sixam_mart/features/add_delegate/domain/reposotories/delegate_repository_interface.dart';
import 'package:sixam_mart/features/add_delegate/domain/services/delegate_service_interface.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/brands/domain/repositories/brands_repository.dart';
import 'package:sixam_mart/features/brands/domain/repositories/brands_repository_interface.dart';
import 'package:sixam_mart/features/brands/domain/services/brands_service.dart';
import 'package:sixam_mart/features/brands/domain/services/brands_service_interface.dart';
import 'package:sixam_mart/features/business/controllers/business_controller.dart';
import 'package:sixam_mart/features/business/domain/repositories/business_repo.dart';
import 'package:sixam_mart/features/business/domain/repositories/business_repo_interface.dart';
import 'package:sixam_mart/features/business/domain/services/business_service.dart';
import 'package:sixam_mart/features/business/domain/services/business_service_interface.dart';
import 'package:sixam_mart/features/update/controllers/update_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/controllers/akhdamni_flow_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/home/domain/repositories/advertisement_repository.dart';
import 'package:sixam_mart/features/home/domain/repositories/advertisement_repository_interface.dart';
import 'package:sixam_mart/features/home/domain/repositories/home_repository.dart';
import 'package:sixam_mart/features/home/domain/repositories/home_repository_interface.dart';
import 'package:sixam_mart/features/home/domain/services/advertisement_service.dart';
import 'package:sixam_mart/features/home/domain/services/advertisement_service_interface.dart';
import 'package:sixam_mart/features/home/domain/services/home_service.dart';
import 'package:sixam_mart/features/home/domain/services/home_service_interface.dart';
import 'package:sixam_mart/features/home/domain/services/home_unified_service.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/banner/domain/repositories/banner_repository.dart';
import 'package:sixam_mart/features/banner/domain/repositories/banner_repository_interface.dart';
import 'package:sixam_mart/features/banner/domain/services/banner_service.dart';
import 'package:sixam_mart/features/banner/domain/services/banner_service_interface.dart';
import 'package:sixam_mart/features/cart/domain/repositories/cart_repository.dart';
import 'package:sixam_mart/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:sixam_mart/features/cart/domain/services/cart_service.dart';
import 'package:sixam_mart/features/cart/domain/services/cart_service_interface.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/reposotories/category_repository.dart';
import 'package:sixam_mart/features/category/domain/reposotories/category_repository_interface.dart';
import 'package:sixam_mart/features/category/domain/services/category_service.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/features/chat/controllers/chat_controller.dart';
import 'package:sixam_mart/features/chat/domain/repositories/chat_repository.dart';
import 'package:sixam_mart/features/chat/domain/repositories/chat_repository_interface.dart';
import 'package:sixam_mart/features/chat/domain/services/chat_service.dart';
import 'package:sixam_mart/features/chat/domain/services/chat_service_interface.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/favourite/domain/repositories/favourite_repository.dart';
import 'package:sixam_mart/features/favourite/domain/repositories/favourite_repository_interface.dart';
import 'package:sixam_mart/features/favourite/domain/services/favourite_service.dart';
import 'package:sixam_mart/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/flash_sale/domain/repositories/flash_sale_repository.dart';
import 'package:sixam_mart/features/flash_sale/domain/repositories/flash_sale_repository_interface.dart';
import 'package:sixam_mart/features/flash_sale/domain/services/flash_sale_service.dart';
import 'package:sixam_mart/features/flash_sale/domain/services/flash_sale_service_interface.dart';
import 'package:sixam_mart/features/html/controllers/html_controller.dart';
import 'package:sixam_mart/features/html/domain/repositories/html_repository.dart';
import 'package:sixam_mart/features/html/domain/repositories/html_repository_interface.dart';
import 'package:sixam_mart/features/html/domain/services/html_service.dart';
import 'package:sixam_mart/features/html/domain/services/html_service_interface.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/repositories/campaign_repository.dart';
import 'package:sixam_mart/features/item/domain/repositories/campaign_repository_interface.dart';
import 'package:sixam_mart/features/item/domain/repositories/item_repository.dart';
import 'package:sixam_mart/features/item/domain/repositories/item_repository_interface.dart';
import 'package:sixam_mart/features/item/domain/services/campaign_service.dart';
import 'package:sixam_mart/features/item/domain/services/campaign_service_interface.dart';
import 'package:sixam_mart/features/item/domain/services/item_service.dart';
import 'package:sixam_mart/features/item/domain/services/item_service_interface.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/language/domain/repository/language_repository.dart';
import 'package:sixam_mart/features/language/domain/repository/language_repository_interface.dart';
import 'package:sixam_mart/features/language/domain/service/language_service.dart';
import 'package:sixam_mart/features/language/domain/service/language_service_interface.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/repositories/address_repository.dart';
import 'package:sixam_mart/features/address/domain/repositories/address_repository_interface.dart';
import 'package:sixam_mart/features/address/domain/services/address_service.dart';
import 'package:sixam_mart/features/address/domain/services/address_service_interface.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/controllers/deliveryman_registration_controller.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/deliveryman_registration_repository.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/deliveryman_registration_repository_interface.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/store_registration_repository.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/store_registration_repository_interface.dart';
import 'package:sixam_mart/features/auth/domain/services/auth_service.dart';
import 'package:sixam_mart/features/auth/domain/services/auth_service_interface.dart';
import 'package:sixam_mart/features/auth/domain/services/deliveryman_registration_service.dart';
import 'package:sixam_mart/features/auth/domain/services/deliveryman_registration_service_interface.dart';
import 'package:sixam_mart/features/auth/domain/services/store_registration_service.dart';
import 'package:sixam_mart/features/auth/domain/services/store_registration_service_interface.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository_interface.dart';
import 'package:sixam_mart/features/location/domain/services/location_service.dart';
import 'package:sixam_mart/features/location/domain/services/location_service_interface.dart';
import 'package:sixam_mart/features/loyalty/controllers/loyalty_controller.dart';
import 'package:sixam_mart/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:sixam_mart/features/loyalty/domain/repositories/loyalty_repository_interface.dart';
import 'package:sixam_mart/features/loyalty/domain/services/loyalty_service.dart';
import 'package:sixam_mart/features/loyalty/domain/services/loyalty_service_interface.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/notification/domain/repository/notification_repository.dart';
import 'package:sixam_mart/features/notification/domain/repository/notification_repository_interface.dart';
import 'package:sixam_mart/features/notification/domain/service/notification_service.dart';
import 'package:sixam_mart/features/notification/domain/service/notification_service_interface.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/offers/domain/reposotories/offers_repository.dart';
import 'package:sixam_mart/features/offers/domain/reposotories/offers_repository_interface.dart';
import 'package:sixam_mart/features/offers/domain/services/offers_service.dart';
import 'package:sixam_mart/features/offers/domain/services/offers_service_interface.dart';
import 'package:sixam_mart/features/onboard/controllers/onboard_controller.dart';
import 'package:sixam_mart/features/onboard/domain/repository/onboard_repository.dart';
import 'package:sixam_mart/features/onboard/domain/repository/onboard_repository_interface.dart';
import 'package:sixam_mart/features/onboard/domain/service/onboard_service.dart';
import 'package:sixam_mart/features/onboard/domain/service/onboard_service_interface.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/repositories/order_repository.dart';
import 'package:sixam_mart/features/order/domain/repositories/order_repository_interface.dart';
import 'package:sixam_mart/features/order/domain/services/order_service.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/repositories/parcel_repository.dart';
import 'package:sixam_mart/features/parcel/domain/repositories/parcel_repository_interface.dart';
import 'package:sixam_mart/features/parcel/domain/services/parcel_service.dart';
import 'package:sixam_mart/features/parcel/domain/services/parcel_service_interface.dart';
import 'package:sixam_mart/features/payment/controllers/payment_controller.dart';
import 'package:sixam_mart/features/payment/domain/repositories/payement_repository.dart';
import 'package:sixam_mart/features/payment/domain/repositories/payment_repository_interface.dart';
import 'package:sixam_mart/features/payment/domain/services/payment_service.dart';
import 'package:sixam_mart/features/payment/domain/services/payment_service_interface.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/domain/repositories/profile_repository.dart';
import 'package:sixam_mart/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:sixam_mart/features/profile/domain/services/profile_service.dart';
import 'package:sixam_mart/features/profile/domain/services/profile_service_interface.dart';
import 'package:sixam_mart/features/review/controllers/review_controller.dart';
import 'package:sixam_mart/features/review/domain/repositories/review_repository.dart';
import 'package:sixam_mart/features/review/domain/repositories/review_repository_interface.dart';
import 'package:sixam_mart/features/review/domain/services/review_service.dart';
import 'package:sixam_mart/features/review/domain/services/review_service_interface.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository_interface.dart';
import 'package:sixam_mart/features/search/domain/services/search_service.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/splash/domain/repositories/splash_repository.dart';
import 'package:sixam_mart/features/splash/domain/repositories/splash_repository_interface.dart';
import 'package:sixam_mart/features/splash/domain/services/splash_service.dart';
import 'package:sixam_mart/features/splash/domain/services/splash_service_interface.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/repositories/store_repository.dart';
import 'package:sixam_mart/features/store/domain/repositories/store_repository_interface.dart';
import 'package:sixam_mart/features/store/domain/services/store_service.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/domain/repositories/taxi_home_repository.dart';
import 'package:sixam_mart/features/rental_module/home/domain/repositories/taxi_home_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/home/domain/services/taxi_home_service.dart';
import 'package:sixam_mart/features/rental_module/home/domain/services/taxi_home_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/repository/taxi_cart_repository.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/repository/taxi_cart_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/services/taxi_cart_service.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/services/taxi_cart_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/controllers/taxi_favourite_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/domain/repositories/taxi_favourite_repository.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/domain/repositories/taxi_favourite_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/domain/services/taxi_favourite_service.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/domain/services/taxi_favourite_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/domain/repository/taxi_repository.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/domain/repository/taxi_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/domain/services/taxi_location_service.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/domain/services/taxi_location_service_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/repository/taxi_order_repository.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/repository/taxi_order_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/services/taxi_order_service.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/services/taxi_order_service_interface.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/taxi_vendor_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/repositories/taxi_vendor_repository.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/repositories/taxi_vendor_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/services/taxi_vendor_service.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/services/taxi_vendor_service_interface.dart';
import 'package:sixam_mart/features/verification/controllers/verification_controller.dart';
import 'package:sixam_mart/features/verification/domein/reposotories/verification_repository.dart';
import 'package:sixam_mart/features/verification/domein/reposotories/verification_repository_interface.dart';
import 'package:sixam_mart/features/verification/domein/services/verification_service.dart';
import 'package:sixam_mart/features/verification/domein/services/verification_service_interface.dart';
import 'package:sixam_mart/features/wallet/controllers/wallet_controller.dart';
import 'package:sixam_mart/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:sixam_mart/features/wallet/domain/repositories/wallet_repository_interface.dart';
import 'package:sixam_mart/features/wallet/domain/services/wallet_service.dart';
import 'package:sixam_mart/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:sixam_mart/features/wallet_transfer/controllers/wallet_transfer_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart';
import 'package:sixam_mart/features/wallet_transfer/domain/repositories/wallet_transfer_repository_interface.dart';
import 'package:sixam_mart/features/wallet_transfer/domain/services/wallet_transfer_service.dart';
import 'package:sixam_mart/features/wallet_transfer/domain/services/wallet_transfer_service_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/services/kaidhaSub_service.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/services/kaidhaSub_service_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import '../features/add_delegate/domain/services/delegate_service.dart';
import '../features/my_coupon/controllers/my_coupon_controller.dart';
import '../features/my_coupon/domain/repositories/coupon_repository.dart';
import '../features/my_coupon/domain/repositories/coupon_repository_interface.dart';
import '../features/my_coupon/domain/services/coupon_service.dart';
import '../features/my_coupon/domain/services/coupon_service_interface.dart';
import 'package:sixam_mart/common/api/api_call_manager.dart';
import 'package:sixam_mart/common/api/optimized_api_client.dart';
import 'package:sixam_mart/features/statistics/controllers/analytics_controller.dart';
import 'package:sixam_mart/features/statistics/data/api/analytics_api_client.dart';
import 'package:sixam_mart/features/statistics/data/repositories/analytics_repository_impl.dart';
import 'package:sixam_mart/features/statistics/domain/repositories/analytics_repository.dart';
import 'package:sixam_mart/features/statistics/data/network_info.dart';

Future<Map<String, Map<String, String>>> init() async {
  /// Core
  final sharedPreferences = await SharedPreferences.getInstance();
  Get.lazyPut(() => sharedPreferences);
  Get.lazyPut(() => ApiClient(
      appBaseUrl: AppConstants.baseUrl, sharedPreferences: Get.find()));

  // Initialize optimized API client
  Get.lazyPut(() => OptimizedApiClient(
      appBaseUrl: AppConstants.baseUrl, sharedPreferences: Get.find()));

  // Initialize API call manager
  Get.lazyPut(() => ApiCallManager());

  // Initialize token from secure storage
  await Get.find<ApiClient>().initializeTokenFromSecureStorage();

// ====================================

  /// Repository interface
  final AuthRepositoryInterface authRepositoryInterface =
      AuthRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => authRepositoryInterface);

  final CheckoutRepositoryInterface checkoutRepositoryInterface =
      CheckoutRepository(
          apiClient: Get.find(),
          sharedPreferences: Get.find(),
          authRepositoryInterface: Get.find());
  Get.lazyPut(() => checkoutRepositoryInterface);

  final LocationRepositoryInterface locationRepositoryInterface =
      LocationRepository(apiClient: Get.find());
  Get.lazyPut(() => locationRepositoryInterface);

  final DeliverymanRegistrationRepositoryInterface
      deliverymanRegistrationRepositoryInterface =
      DeliverymanRegistrationRepository(
          apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => deliverymanRegistrationRepositoryInterface);

  final StoreRegistrationRepositoryInterface
      storeRegistrationRepositoryInterface =
      StoreRegistrationRepository(apiClient: Get.find());
  Get.lazyPut(() => storeRegistrationRepositoryInterface);

  final ParcelRepositoryInterface parcelRepositoryInterface =
      ParcelRepository(apiClient: Get.find());
  Get.lazyPut(() => parcelRepositoryInterface);

  Get.lazyPut<AddressRepositoryInterface<AddressModel>>(
      () => AddressRepository(apiClient: Get.find()));

  final OrderRepositoryInterface orderRepositoryInterface =
      OrderRepository(apiClient: Get.find());
  Get.lazyPut(() => orderRepositoryInterface);

  final PaymentRepositoryInterface paymentRepositoryInterface =
      PaymentRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => paymentRepositoryInterface);

  final CampaignRepositoryInterface campaignRepositoryInterface =
      CampaignRepository(apiClient: Get.find());
  Get.lazyPut(() => campaignRepositoryInterface);

  final ChatRepositoryInterface chatRepositoryInterface =
      ChatRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => chatRepositoryInterface);

  final CouponRepositoryInterface couponRepositoryInterface =
      CouponRepository(apiClient: Get.find());
  Get.lazyPut(() => couponRepositoryInterface);

  final FavouriteRepositoryInterface favouriteRepositoryInterface =
      FavouriteRepository(apiClient: Get.find());
  Get.lazyPut(() => favouriteRepositoryInterface);

  final FlashSaleRepositoryInterface flashSaleRepositoryInterface =
      FlashSaleRepository(apiClient: Get.find());
  Get.lazyPut(() => flashSaleRepositoryInterface);

  final HomeRepositoryInterface homeRepositoryInterface =
      HomeRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => homeRepositoryInterface);

  final BannerRepositoryInterface bannerRepositoryInterface =
      BannerRepository(apiClient: Get.find());
  Get.lazyPut(() => bannerRepositoryInterface);

  final HtmlRepositoryInterface htmlRepositoryInterface =
      HtmlRepository(apiClient: Get.find());
  Get.lazyPut(() => htmlRepositoryInterface);

  final LanguageRepositoryInterface languageRepositoryInterface =
      LanguageRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => languageRepositoryInterface);

  final NotificationRepositoryInterface notificationRepositoryInterface =
      NotificationRepository(
          sharedPreferences: Get.find(), apiClient: Get.find());
  Get.lazyPut(() => notificationRepositoryInterface);

  final OnboardRepositoryInterface onboardRepositoryInterface =
      OnboardRepository();
  Get.lazyPut(() => onboardRepositoryInterface);

  final ProfileRepositoryInterface profileRepositoryInterface =
      ProfileRepository(apiClient: Get.find());
  Get.lazyPut(() => profileRepositoryInterface);

  final SearchRepositoryInterface searchRepositoryInterface =
      SearchRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => searchRepositoryInterface);

  final SplashRepositoryInterface splashRepositoryInterface =
      SplashRepository(sharedPreferences: Get.find(), apiClient: Get.find());
  Get.lazyPut(() => splashRepositoryInterface);

  final ReviewRepositoryInterface reviewRepositoryInterface =
      ReviewRepository(apiClient: Get.find());
  Get.lazyPut(() => reviewRepositoryInterface);

  final StoreRepositoryInterface storeRepositoryInterface =
      StoreRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => storeRepositoryInterface);

  final WalletRepositoryInterface walletRepositoryInterface =
      WalletRepository(sharedPreferences: Get.find(), apiClient: Get.find());
  Get.lazyPut(() => walletRepositoryInterface);

  final ItemRepositoryInterface itemRepositoryInterface =
      ItemRepository(apiClient: Get.find());
  Get.lazyPut(() => itemRepositoryInterface);

  final CategoryRepositoryInterface categoryRepositoryInterface =
      CategoryRepository(apiClient: Get.find());
  Get.lazyPut(() => categoryRepositoryInterface);

  final LoyaltyRepositoryInterface loyaltyRepositoryInterface =
      LoyaltyRepository(apiClient: Get.find());
  Get.lazyPut(() => loyaltyRepositoryInterface);

  final CartRepositoryInterface cartRepositoryInterface =
      CartRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => cartRepositoryInterface);

  final VerificationRepositoryInterface verificationRepositoryInterface =
      VerificationRepository(
          apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => verificationRepositoryInterface);

  final BrandsRepositoryInterface brandsRepositoryInterface =
      BrandsRepository(apiClient: Get.find());
  Get.lazyPut(() => brandsRepositoryInterface);

  final BusinessRepoInterface businessRepoInterface =
      BusinessRepo(apiClient: Get.find());
  Get.lazyPut(() => businessRepoInterface);

  final AdvertisementRepositoryInterface advertisementRepositoryInterface =
      AdvertisementRepository(apiClient: Get.find());
  Get.lazyPut(() => advertisementRepositoryInterface);

  // Analytics Dependencies
  Get.lazyPut<NetworkInfo>(() => NetworkInfo());
  Get.lazyPut<AnalyticsApiClient>(
      () => AnalyticsApiClient(apiClient: Get.find()));
  Get.lazyPut<AnalyticsRepository>(() => AnalyticsRepositoryImpl(
        analyticsApiClient: Get.find<AnalyticsApiClient>(),
        networkInfo: Get.find<NetworkInfo>(),
      ));

  final TaxiRepositoryInterface taxiRepositoryInterface =
      TaxiRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => taxiRepositoryInterface);

  final TaxiHomeRepositoryInterface taxiHomeRepositoryInterface =
      TaxiHomeRepository(apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => taxiHomeRepositoryInterface);

  final TaxiCartRepositoryInterface taxiCartRepositoryInterface =
      TaxiCartRepository(apiClient: Get.find());
  Get.lazyPut(() => taxiCartRepositoryInterface);

  final TaxiVendorRepositoryInterface taxiVendorRepositoryInterface =
      TaxiVendorRepository(apiClient: Get.find());
  Get.lazyPut(() => taxiVendorRepositoryInterface);

  final TaxiOrderRepositoryInterface taxiOrderRepositoryInterface =
      TaxiOrderRepository(apiClient: Get.find());
  Get.lazyPut(() => taxiOrderRepositoryInterface);

  final TaxiFavouriteRepositoryInterface taxiFavouriteRepositoryInterface =
      TaxiFavouriteRepository(
          apiClient: Get.find(), sharedPreferences: Get.find());
  Get.lazyPut(() => taxiFavouriteRepositoryInterface);

  /// Service Interface
  final CheckoutServiceInterface checkoutServiceInterface =
      CheckoutService(checkoutRepositoryInterface: Get.find());
  Get.lazyPut(() => checkoutServiceInterface, fenix: true);

  final AuthServiceInterface authServiceInterface =
      AuthService(authRepositoryInterface: Get.find());
  Get.lazyPut(() => authServiceInterface);

  final LocationServiceInterface locationServiceInterface =
      LocationService(locationRepoInterface: Get.find());

  final DeliverymanRegistrationServiceInterface
      deliverymanRegistrationServiceInterface = DeliverymanRegistrationService(
          deliverymanRegistrationRepoInterface: Get.find(),
          authRepositoryInterface: Get.find());
  Get.lazyPut(() => deliverymanRegistrationServiceInterface);

  final StoreRegistrationServiceInterface storeRegistrationServiceInterface =
      StoreRegistrationService(
          deliverymanRegistrationRepositoryInterface: Get.find(),
          storeRegistrationRepoInterface: Get.find());
  Get.lazyPut(() => storeRegistrationServiceInterface);

  final ParcelServiceInterface parcelServiceInterface = ParcelService(
      parcelRepositoryInterface: Get.find(),
      checkoutRepositoryInterface: Get.find());
  Get.lazyPut(() => parcelServiceInterface);

  final AddressServiceInterface addressServiceInterface = AddressService(
      addressRepoInterface:
          Get.find<AddressRepositoryInterface<AddressModel>>());
  Get.lazyPut(() => addressServiceInterface);

  final OrderServiceInterface orderServiceInterface =
      OrderService(orderRepositoryInterface: Get.find());
  Get.lazyPut(() => orderServiceInterface);

  final PaymentServiceInterface paymentServiceInterface =
      PaymentService(paymentRepositoryInterface: Get.find());
  Get.lazyPut(() => paymentServiceInterface);

  // ⚡ FIX: Register CampaignServiceInterface with fenix: true
  // This ensures the service is always available and can be revived if deleted during module switching
  // Prevents "CampaignServiceInterface not found" errors in PharmacyHomeScreen and other modules
  final CampaignServiceInterface campaignServiceInterface =
      CampaignService(campaignRepositoryInterface: Get.find());
  Get.lazyPut(() => campaignServiceInterface, fenix: true);

  final ChatServiceInterface chatServiceInterface =
      ChatService(chatRepositoryInterface: Get.find());
  Get.lazyPut(() => chatServiceInterface);

  final CouponServiceInterface couponServiceInterface =
      CouponService(couponRepositoryInterface: Get.find());
  Get.lazyPut(() => couponServiceInterface);

  final FavouriteServiceInterface favouriteServiceInterface =
      FavouriteService(favouriteRepositoryInterface: Get.find());
  Get.lazyPut(() => favouriteServiceInterface);

  final HomeServiceInterface homeServiceInterface =
      HomeService(homeRepositoryInterface: Get.find());
  Get.lazyPut(() => homeServiceInterface);

  final FlashSaleServiceInterface flashSaleServiceInterface =
      FlashSaleService(flashSaleRepositoryInterface: Get.find());
  Get.lazyPut(() => flashSaleServiceInterface);

  final BannerServiceInterface bannerServiceInterface =
      BannerService(bannerRepositoryInterface: Get.find());
  Get.lazyPut(() => bannerServiceInterface);

  final HtmlServiceInterface htmlServiceInterface =
      HtmlService(htmlRepositoryInterface: Get.find());
  Get.lazyPut(() => htmlServiceInterface);

  final LanguageServiceInterface languageServiceInterface =
      LanguageService(languageRepositoryInterface: Get.find());
  Get.lazyPut(() => languageServiceInterface);

  final NotificationServiceInterface notificationServiceInterface =
      NotificationService(notificationRepositoryInterface: Get.find());
  Get.lazyPut(() => notificationServiceInterface);

  final OnboardServiceInterface onboardServiceInterface =
      OnboardService(onboardRepositoryInterface: Get.find());
  Get.lazyPut(() => onboardServiceInterface);

  final ProfileServiceInterface profileServiceInterface =
      ProfileService(profileRepositoryInterface: Get.find());
  Get.lazyPut(() => profileServiceInterface);

  final SearchServiceInterface searchServiceInterface =
      SearchService(searchRepositoryInterface: Get.find());
  Get.lazyPut(() => searchServiceInterface);

  final SplashServiceInterface splashServiceInterface =
      SplashService(splashRepositoryInterface: Get.find());
  Get.lazyPut(() => splashServiceInterface);

  final ReviewServiceInterface reviewServiceInterface =
      ReviewService(reviewRepositoryInterface: Get.find());
  Get.lazyPut(() => reviewServiceInterface);

  final StoreServiceInterface storeServiceInterface =
      StoreService(storeRepositoryInterface: Get.find());
  Get.lazyPut(() => storeServiceInterface);

  final WalletServiceInterface walletServiceInterface =
      WalletService(walletRepositoryInterface: Get.find());
  Get.lazyPut(() => walletServiceInterface);

  final ItemServiceInterface itemServiceInterface =
      ItemService(itemRepositoryInterface: Get.find());
  Get.lazyPut(() => itemServiceInterface);

  final CategoryServiceInterface categoryServiceInterface =
      CategoryService(categoryRepositoryInterface: Get.find());
  Get.lazyPut(() => categoryServiceInterface);

  final LoyaltyServiceInterface loyaltyServiceInterface =
      LoyaltyService(loyaltyRepositoryInterface: Get.find());
  Get.lazyPut(() => loyaltyServiceInterface);

  final CartServiceInterface cartServiceInterface =
      CartService(cartRepositoryInterface: Get.find());
  Get.lazyPut(() => cartServiceInterface);

  final VerificationServiceInterface verificationServiceInterface =
      VerificationService(
          verificationRepoInterface: Get.find(), authRepoInterface: Get.find());
  Get.lazyPut(() => verificationServiceInterface);

  final BrandsServiceInterface brandsServiceInterface =
      BrandsService(brandsRepositoryInterface: Get.find());
  Get.lazyPut(() => brandsServiceInterface);

  final BusinessServiceInterface businessServiceInterface =
      BusinessService(businessRepoInterface: Get.find());
  Get.lazyPut(() => businessServiceInterface);

  final AdvertisementServiceInterface advertisementServiceInterface =
      AdvertisementService(advertisementRepositoryInterface: Get.find());
  Get.lazyPut(() => advertisementServiceInterface);

  // Analytics Service (using repository directly as service)
  // AnalyticsRepositoryInterface is already registered above

  final TaxiLocationServiceInterface taxiLocationServiceInterface =
      TaxiLocationService(taxiRepositoryInterface: Get.find());
  Get.lazyPut(() => taxiLocationServiceInterface);

  final TaxiHomeServiceInterface taxiHomeServiceInterface =
      TaxiHomeService(taxiHomeRepositoryInterface: Get.find());
  Get.lazyPut(() => taxiHomeServiceInterface);

  final TaxiCartServiceInterface taxiCartServiceInterface =
      TaxiCartService(taxiCartRepositoryInterface: Get.find());
  Get.lazyPut(() => taxiCartServiceInterface);

  final TaxiVendorServiceInterface taxiVendorServiceInterface =
      TaxiVendorService(taxiVendorRepositoryInterface: Get.find());
  Get.lazyPut(() => taxiVendorServiceInterface);

  final TaxiOrderServiceInterface taxiOrderServiceInterface =
      TaxiOrderService(taxiOrderRepositoryInterface: Get.find());
  Get.lazyPut(() => taxiOrderServiceInterface);

  final TaxiFavouriteServiceInterface taxiFavouriteServiceInterface =
      TaxiFavouriteService(taxiFavouriteRepositoryInterface: Get.find());
  Get.lazyPut(() => taxiFavouriteServiceInterface);

  /// Controller
  Get.lazyPut(() => ThemeController(sharedPreferences: Get.find()));
  Get.lazyPut(() => SplashController(splashServiceInterface: Get.find()));
  Get.lazyPut(() => AddressController(addressServiceInterface: Get.find()));

  Get.lazyPut(() =>
      LocationController(locationServiceInterface: locationServiceInterface));

  Get.lazyPut(
      () => LocalizationController(languageServiceInterface: Get.find()));
  Get.lazyPut(() => OnBoardingController(onboardServiceInterface: Get.find()));
  Get.lazyPut(() => AuthController(authServiceInterface: Get.find()));
  Get.lazyPut(() => DeliverymanRegistrationController(
      deliverymanRegistrationServiceInterface: Get.find()));
  Get.lazyPut(() => StoreRegistrationController(
      storeRegistrationServiceInterface: Get.find(),
      locationServiceInterface: locationServiceInterface));
  Get.lazyPut(() => ProfileController(profileServiceInterface: Get.find()));
  // ✅ Keep BannerController alive across route/module changes (global banners)
  Get.put(
    BannerController(bannerServiceInterface: Get.find()),
    permanent: true,
  );
  // ⚡ SINGLETON FIX: CategoryController must be permanent singleton to prevent multiple instances
  // This prevents race conditions and stale state when navigating between category screens
  Get.put<CategoryController>(
    CategoryController(
      categoryServiceInterface: Get.find(),
      searchServiceInterface: Get.find(),
    ),
    permanent: true,
  );
  Get.lazyPut(() => ItemController(itemServiceInterface: Get.find()),
      fenix: true);
  Get.lazyPut(() => CartController(cartServiceInterface: Get.find()));

  Get.lazyPut(() => StoreController(storeServiceInterface: Get.find()));

  Get.lazyPut(() => FavouriteController(favouriteServiceInterface: Get.find()));
  Get.lazyPut(() => HomeController(homeServiceInterface: Get.find()),
      fenix: true);
  Get.lazyPut(() => AkhdamniFlowController(), fenix: true);
  // ⚡ BFF API v2: Home Unified Controller (for /api/v2/home-unified endpoint)
  // ⚡ TITAN BOARD: Permanent singleton to survive route flushes during module switching
  // This ensures loadHomeData() calls don't fail when Get.offAllNamed() executes
  // Note: Get.put() with permanent: true ensures controller survives route navigation
  Get.put(
      HomeUnifiedController(
          homeUnifiedService: HomeUnifiedService(apiClient: Get.find())),
      permanent: true);
  Get.lazyPut(() => SearchController(
        searchServiceInterface: Get.find(),
      ));
  Get.lazyPut(() => CouponController(couponServiceInterface: Get.find()));
  Get.lazyPut(() => OrderController(orderServiceInterface: Get.find()));
  Get.lazyPut(
      () => NotificationController(notificationServiceInterface: Get.find()));
  // ⚡ Cache-First Fix: Register CampaignController with fenix: true
  // This ensures controller is always available and can be revived if deleted
  Get.lazyPut(() => CampaignController(campaignServiceInterface: Get.find()),
      fenix: true);
  Get.lazyPut(() => ParcelController(parcelServiceInterface: Get.find()));
  Get.lazyPut(() => ChatController(chatServiceInterface: Get.find()));
  Get.lazyPut(() => FlashSaleController(flashSaleServiceInterface: Get.find()));
  Get.lazyPut(() => CheckoutController(checkoutServiceInterface: Get.find()),
      fenix: true);
  Get.lazyPut(() => PaymentController(paymentServiceInterface: Get.find()));
  Get.lazyPut(() => HtmlController(htmlServiceInterface: Get.find()));
  Get.lazyPut(() => ReviewController(reviewServiceInterface: Get.find()));
  Get.lazyPut(() => LoyaltyController(loyaltyServiceInterface: Get.find()));
  Get.lazyPut(
      () => VerificationController(verificationServiceInterface: Get.find()),
      fenix: true);
  Get.lazyPut(() => BrandsController(
        brandsServiceInterface: Get.find(),
        itemRepository: Get.find(),
      ));
  Get.lazyPut(() => BusinessController(businessServiceInterface: Get.find()));
  Get.lazyPut(
      () => AdvertisementController(advertisementServiceInterface: Get.find()));

  // Analytics Controller
  Get.lazyPut<AnalyticsController>(
      () => AnalyticsController(repository: Get.find<AnalyticsRepository>()));

  Get.lazyPut(
      () => TaxiLocationController(taxiLocationServiceInterface: Get.find()));

  Get.lazyPut(() => TaxiHomeController(taxiHomeServiceInterface: Get.find()));
  Get.lazyPut(() => TaxiCartController(taxiCartServiceInterface: Get.find()));
  Get.lazyPut(
      () => TaxiVendorController(taxiVendorServiceInterface: Get.find()));
  Get.lazyPut(() => TaxiOrderController(taxiOrderServiceInterface: Get.find()));
  Get.lazyPut(
      () => TaxiFavouriteController(taxiFavouriteServiceInterface: Get.find()));

  // -------

  // تسجيل DelegateRepositoryInterface أولاً
  Get.lazyPut<DelegateRepositoryInterface>(
      () => DelegateRepository(apiClient: Get.find()));

  // ثم تسجيل Delegate_ServiceInterface بناءً على الـ Repository المسجل
  Get.lazyPut<Delegate_ServiceInterface>(
      () => DelegateService(delegateRepositoryinterface: Get.find()));

  // وأخيرًا تسجيل Delegate_Controller
  Get.lazyPut(() => Delegate_Controller(delegateServiceInterface: Get.find()));

  // ======================================================================================================================

  // ⚡ FIX: Register the full Qidha (Kaidha) chain with fenix: true so it can be
  // revived after Get.offAllNamed() flushes non-permanent dependencies during
  // module switching. Without fenix, opening /checkout directly (cart → checkout)
  // threw "KaidhaSubscriptionController not found" because the registration had
  // been flushed and could not be recreated. See also CheckoutController/Campaign.
  // تسجيل KaidhaSubRepositoryInterface أولاً
  Get.lazyPut<KaidhaSubRepositoryInterface>(
      () => KaidhaSubRepository(apiClient: Get.find()),
      fenix: true);

  // ثم تسجيل kaidhaSub_ServiceInterface بناءً على الـ Repository المسجل
  Get.lazyPut<kaidhaSub_ServiceInterface>(
      () => KaidhaSubService(
          kaidhaSubRepositoryinterface:
              Get.find<KaidhaSubRepositoryInterface>()),
      fenix: true);

  // وأخيرًا تسجيل KaidhaSubscriptionController
  Get.lazyPut(
      () => KaidhaSubscriptionController(kaidhaSubServiceInterface: Get.find()),
      fenix: true);

  // محفظه قديمة

  Get.lazyPut(() => WalletController(walletServiceInterface: Get.find()));

  // Wallet Transfer (Peer-to-Peer)
  Get.lazyPut<WalletTransferRepositoryInterface>(
      () => WalletTransferRepository(apiClient: Get.find()));
  Get.lazyPut<WalletTransferServiceInterface>(() =>
      WalletTransferService(walletTransferRepositoryInterface: Get.find()));
  Get.lazyPut(() =>
      WalletTransferController(walletTransferServiceInterface: Get.find()));

  // Offers  ======================================================================================================================

  // تسجيل OffersRepositoryInterface أولاً
  Get.lazyPut<OffersRepositoryInterface>(
      () => OffersRepository(apiClient: Get.find()));

  // ثم تسجيل Offers_ServiceInterface بناءً على الـ Repository المسجل
  Get.lazyPut<Offers_ServiceInterface>(
      () => OffersService(offersRepositoryinterface: Get.find()));

  // وأخيرًا تسجيل Offersscription_Controller
  Get.lazyPut(() => OffersController(
        offersServiceInterface: Get.find(),
        itemRepository: Get.find(),
      ));

  // Update Controller
  Get.lazyPut(() => ReferralController(apiClient: Get.find()));
  Get.lazyPut(() => UpdateController());

  // ======================================================================================================================

  /// Retrieving localized data
  /// NOTE: Load all configured languages so runtime language switch works.
  final Map<String, Map<String, String>> languages = {};

  for (final languageModel in AppConstants.languages) {
    try {
      final String jsonStringValues = await rootBundle
          .loadString('assets/language/${languageModel.languageCode}.json');
      final mappedJson = jsonDecode(jsonStringValues) as Map<String, dynamic>;

      final Map<String, String> json = {};
      mappedJson.forEach((key, value) {
        json[key] = value.toString();
      });

      final String key =
          '${languageModel.languageCode}_${languageModel.countryCode}';
      languages[key] = json;

      if (kDebugMode) {
        appLogger.debug('🔍 Loaded ${json.length} translations for $key');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error(
            '🔍 Error loading language ${languageModel.languageCode}_${languageModel.countryCode}: $e',
            e);
      }
    }
  }

  if (languages.isEmpty) {
    try {
      final fallbackLang = AppConstants.languages[0];
      final String jsonStringValues = await rootBundle
          .loadString('assets/language/${fallbackLang.languageCode}.json');
      final mappedJson = jsonDecode(jsonStringValues) as Map<String, dynamic>;
      final Map<String, String> json = {};
      mappedJson.forEach((key, value) {
        json[key] = value.toString();
      });
      final String key =
          '${fallbackLang.languageCode}_${fallbackLang.countryCode}';
      languages[key] = json;
      if (kDebugMode) {
        appLogger.debug('🔍 Loaded fallback language: $key');
      }
    } catch (fallbackError) {
      if (kDebugMode) {
        appLogger.error('🔍 Error loading fallback language: $fallbackError',
            fallbackError);
      }
    }
  }

  if (kDebugMode) {
    appLogger.debug('🔍 Total languages loaded: ${languages.keys}');
  }
  return languages;
}
