# Complete API Endpoints Master List
## Every Single Endpoint Used in the App

**Generated:** 2024-12-19  
**Total Endpoints:** 150+ endpoints documented

---

## Table of Contents

1. [Module-ID Requirements](#module-id-requirements)
2. [Complete Endpoint List by Category](#complete-endpoint-list-by-category)
3. [Header Requirements Matrix](#header-requirements-matrix)
4. [Endpoint Usage by Screen](#endpoint-usage-by-screen)

---

## Module-ID Requirements

### ⚠️ Endpoints that PREFER `module-id` Header (Optional but Recommended)

**Note:** The code includes module-id when available, but these endpoints may work without it (backend may use default module or be lenient).

**Home Data APIs:**
- `/api/v2/home-unified` - ⚠️ PREFERRED (backend may use default)
- `/api/v1/banners` - ⚠️ PREFERRED
- `/api/v1/categories` - ⚠️ PREFERRED (code checks for it, but may work without)
- `/api/v1/brands` - ⚠️ PREFERRED
- `/api/v1/offers/active` - ⚠️ PREFERRED
- `/api/v1/stores/get-stores` - ⚠️ PREFERRED (code includes it, but has "backward compatibility" comments)
- `/api/v1/stores/popular` - ⚠️ PREFERRED
- `/api/v1/stores/latest` - ⚠️ PREFERRED
- `/api/v1/stores/top-offer-near-me` - ⚠️ PREFERRED
- `/api/v1/stores/recommended` - ⚠️ PREFERRED
- `/api/v1/stores/details/{id}` - ⚠️ PREFERRED
- `/api/v1/items/latest` - ⚠️ PREFERRED (uses default headers, may work without)
- `/api/v1/items/details/{id}` - ⚠️ PREFERRED
- `/api/v1/items/popular` - ⚠️ PREFERRED
- `/api/v1/items/recommended` - ⚠️ PREFERRED
- `/api/v1/items/suggested` - ⚠️ PREFERRED
- `/api/v1/items/discounted` - ⚠️ PREFERRED
- `/api/v1/items/most-reviewed` - ⚠️ PREFERRED
- `/api/v1/categories/items/{id}` - ⚠️ PREFERRED
- `/api/v1/categories/stores/{id}` - ⚠️ PREFERRED
- `/api/v1/categories/childes/{id}` - ⚠️ PREFERRED
- `/api/v1/brands/items` - ⚠️ PREFERRED
- `/api/v1/brands/items/search` - ⚠️ PREFERRED
- `/api/v1/brands/items/filter` - ⚠️ PREFERRED
- `/api/v1/campaigns/basic` - ⚠️ PREFERRED
- `/api/v1/campaigns/item` - ⚠️ PREFERRED
- `/api/v1/campaigns/basic-campaign-details` - ⚠️ PREFERRED
- `/api/v1/flash-sales` - ⚠️ PREFERRED
- `/api/v1/flash-sales/items` - ⚠️ PREFERRED
- `/api/v1/categories/featured/items` - ⚠️ PREFERRED

**Evidence from Code:**
- `store_repository.dart:51`: "If moduleId is null, include it (backward compatibility)"
- `api_client.dart:271-277`: module-id only added if `moduleID != null` OR cached module exists
- API calls still execute even when module-id is missing from headers

**Cart & Checkout APIs:**
- `/api/v1/customer/cart/list` - ✅ REQUIRED
- `/api/v1/customer/cart/add` - ✅ REQUIRED
- `/api/v1/customer/cart/update` - ✅ REQUIRED
- `/api/v1/customer/cart/remove` - ✅ REQUIRED
- `/api/v1/customer/cart/remove-item` - ✅ REQUIRED
- `/api/v2/checkout/store-summary` - ✅ REQUIRED
- `/api/v1/coupon/list` - ✅ REQUIRED
- `/api/v1/coupon/apply` - ✅ REQUIRED

**Order APIs:**
- `/api/v1/customer/order/place` - ✅ REQUIRED
- `/api/v1/customer/order/prescription/place` - ✅ REQUIRED
- `/api/v1/customer/order/list` - ✅ REQUIRED
- `/api/v1/customer/order/running-orders` - ✅ REQUIRED
- `/api/v1/customer/order/details` - ✅ REQUIRED
- `/api/v1/customer/order/track` - ✅ REQUIRED
- `/api/v1/customer/order/cancel` - ✅ REQUIRED
- `/api/v1/customer/order/payment-method` - ✅ REQUIRED
- `/api/v1/customer/order/edit-address` - ✅ REQUIRED
- `/api/v1/customer/order/process-payment` - ✅ REQUIRED
- `/api/v1/customer/order/refund-reasons` - ✅ REQUIRED
- `/api/v1/customer/order/refund-request` - ✅ REQUIRED
- `/api/v1/customer/order/cancellation-reasons` - ✅ REQUIRED
- `/api/v1/customer/order/parcel-instructions` - ✅ REQUIRED
- `/api/v1/customer/order/offline-payment` - ✅ REQUIRED
- `/api/v1/customer/order/offline-payment-update` - ✅ REQUIRED

**Search APIs:**
- `/api/v1/items/search` - ✅ REQUIRED
- `/api/v1/stores/search` - ✅ REQUIRED
- `/api/v1/items/item-or-store-search` - ✅ REQUIRED
- `/api/v1/categories/popular` - ✅ REQUIRED

### ❌ Endpoints that DO NOT Require `module-id` Header

**Config & System APIs:**
- `/api/v1/config` - ❌ NOT REQUIRED
- `/api/v1/app-init` - ❌ NOT REQUIRED
- `/api/v1/bootstrap` - ❌ NOT REQUIRED
- `/api/v1/module` - ❌ NOT REQUIRED
- `/api/v1/business-settings` - ❌ NOT REQUIRED
- `/api/v1/app/version/check` - ❌ NOT REQUIRED

**Auth APIs:**
- `/api/v1/auth/login` - ❌ NOT REQUIRED
- `/api/v1/auth/sign-up` - ❌ NOT REQUIRED
- `/api/v1/auth/forgot-password` - ❌ NOT REQUIRED
- `/api/v1/auth/reset-password` - ❌ NOT REQUIRED
- `/api/v1/auth/verify-token` - ❌ NOT REQUIRED
- `/api/v1/auth/verify-phone` - ❌ NOT REQUIRED
- `/api/v1/auth/verify-email` - ❌ NOT REQUIRED
- `/api/v1/auth/check-email` - ❌ NOT REQUIRED
- `/api/v1/auth/send-otp-again` - ❌ NOT REQUIRED
- `/api/v1/auth/social-login` - ❌ NOT REQUIRED
- `/api/v1/auth/social-register` - ❌ NOT REQUIRED
- `/api/v1/auth/firebase-verify-token` - ❌ NOT REQUIRED
- `/api/v1/auth/firebase-reset-password` - ❌ NOT REQUIRED
- `/api/v1/auth/update-info` - ❌ NOT REQUIRED
- `/api/v1/auth/guest/request` - ❌ NOT REQUIRED
- `/api/v1/auth/vendor/register` - ❌ NOT REQUIRED
- `/api/v1/auth/delivery-man/store` - ❌ NOT REQUIRED
- `/api/v1/auth/delivery-man/status` - ❌ NOT REQUIRED

**Location & Zone APIs:**
- `/api/v1/config/get-zone-id` - ❌ NOT REQUIRED
- `/api/v1/zone/check` - ❌ NOT REQUIRED
- `/api/v1/zone/list` - ❌ NOT REQUIRED
- `/api/v1/zones` - ❌ NOT REQUIRED
- `/api/v1/customer/update-zone` - ❌ NOT REQUIRED
- `/api/v1/config/place-api-autocomplete` - ❌ NOT REQUIRED
- `/api/v1/config/place-api-details` - ❌ NOT REQUIRED
- `/api/v1/config/geocode-api` - ❌ NOT REQUIRED
- `/api/v1/config/distance-api` - ❌ NOT REQUIRED
- `/api/v1/config/direction-api` - ❌ NOT REQUIRED

**Customer Profile APIs:**
- `/api/v1/customer/info` - ❌ NOT REQUIRED (but zone-id required)
- `/api/v1/customer/update-profile` - ❌ NOT REQUIRED
- `/api/v1/customer/remove-account` - ❌ NOT REQUIRED
- `/api/v1/customer/update-interest` - ❌ NOT REQUIRED
- `/api/v1/customer/suggested-items` - ❌ NOT REQUIRED

**Address APIs:**
- `/api/v1/customer/address/list` - ❌ NOT REQUIRED
- `/api/v1/customer/address/add` - ❌ NOT REQUIRED
- `/api/v1/customer/address/update/{id}` - ❌ NOT REQUIRED
- `/api/v1/customer/address/delete` - ❌ NOT REQUIRED

**Wallet APIs (Qidha Wallet):**
- `/api/qidha-wallet/get-wallet` - ❌ NOT REQUIRED (but Authorization required)
- `/api/qidha-wallet/store` - ❌ NOT REQUIRED
- `/api/qidha-wallet/credit` - ❌ NOT REQUIRED
- `/api/qidha-wallet/debit` - ❌ NOT REQUIRED
- `/api/qidha-wallet/nafath/initiate` - ❌ NOT REQUIRED
- `/api/qidha-wallet/nafath/checkStatus` - ❌ NOT REQUIRED
- `/api/qidha-wallet/nafath/sign` - ❌ NOT REQUIRED

**Wallet APIs (Regular Wallet):**
- `/api/v1/customer/wallet/transactions` - ❌ NOT REQUIRED
- `/api/v1/customer/wallet/add-fund` - ❌ NOT REQUIRED
- `/api/v1/customer/wallet/bonuses` - ❌ NOT REQUIRED
- `/api/v1/customer/wallet/validate-recipient` - ❌ NOT REQUIRED
- `/api/v1/customer/wallet/transfer` - ❌ NOT REQUIRED
- `/api/v1/customer/wallet/recipients` - ❌ NOT REQUIRED
- `/api/v1/customer/wallet/recipients/add` - ❌ NOT REQUIRED
- `/api/v1/customer/requestExchangeWalletMoney` - ❌ NOT REQUIRED
- `/api/v1/customer/ExchangeWalletMoney` - ❌ NOT REQUIRED

**Loyalty APIs:**
- `/api/v1/customer/loyalty-point/transactions` - ❌ NOT REQUIRED
- `/api/v1/customer/loyalty-point/point-transfer` - ❌ NOT REQUIRED

**Wishlist APIs:**
- `/api/v1/customer/wish-list` - ❌ NOT REQUIRED (but Authorization required)
- `/api/v1/customer/wish-list/add` - ❌ NOT REQUIRED
- `/api/v1/customer/wish-list/remove` - ❌ NOT REQUIRED

**Notification APIs:**
- `/api/v1/customer/notifications` - ❌ NOT REQUIRED (but Authorization required)
- `/api/v1/customer/cm-firebase-token` - ❌ NOT REQUIRED

**Message APIs:**
- `/api/v1/customer/message/list` - ❌ NOT REQUIRED
- `/api/v1/customer/message/search-list` - ❌ NOT REQUIRED
- `/api/v1/customer/message/details` - ❌ NOT REQUIRED
- `/api/v1/customer/message/send` - ❌ NOT REQUIRED
- `/api/v1/customer/message/get` - ❌ NOT REQUIRED
- `/api/v1/customer/automated-message` - ❌ NOT REQUIRED

**Review APIs:**
- `/api/v1/items/reviews/submit` - ❌ NOT REQUIRED
- `/api/v1/stores/reviews` - ❌ NOT REQUIRED
- `/api/v1/delivery-man/reviews/submit` - ❌ NOT REQUIRED

**Delegate APIs:**
- `/api/v1/customer/delegate/get-delegate-status` - ❌ NOT REQUIRED
- `/api/v1/customer/delegate/store` - ❌ NOT REQUIRED

**Content & Policy APIs:**
- `/api/v1/about-us` - ❌ NOT REQUIRED
- `/api/v1/privacy-policy` - ❌ NOT REQUIRED
- `/api/v1/terms-and-conditions` - ❌ NOT REQUIRED
- `/api/v1/shipping-policy` - ❌ NOT REQUIRED
- `/api/v1/refund-policy` - ❌ NOT REQUIRED
- `/api/v1/cancelation` - ❌ NOT REQUIRED
- `/api/v1/newsletter/subscribe` - ❌ NOT REQUIRED
- `/api/v1/flutter-landing-page` - ❌ NOT REQUIRED

**Parcel APIs:**
- `/api/v1/parcel-category` - ❌ NOT REQUIRED
- `/api/v1/other-banners` - ❌ NOT REQUIRED
- `/api/v1/other-banners/why-choose` - ❌ NOT REQUIRED
- `/api/v1/other-banners/video-content` - ❌ NOT REQUIRED

**Taxi/Rental APIs:**
- `/api/v1/banners/taxi` - ❌ NOT REQUIRED
- `/api/v1/coupon/list/taxi` - ❌ NOT REQUIRED
- `/api/v1/vehicles/list` - ❌ NOT REQUIRED
- `/api/v1/vehicles/brand/list` - ❌ NOT REQUIRED
- `/api/v1/vehicles/top-rated/list` - ❌ NOT REQUIRED
- `/api/v1/get-vehicles` - ❌ NOT REQUIRED
- `/api/v1/vehicle/extra_charge` - ❌ NOT REQUIRED
- `/api/v1/trip/place` - ❌ NOT REQUIRED
- `/api/v1/trip/list` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/top-rated` - ❌ NOT REQUIRED
- `/api/v1/rental/banners` - ❌ NOT REQUIRED
- `/api/v1/rental/coupon/list` - ❌ NOT REQUIRED
- `/api/v1/rental/coupon/apply` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/get-vehicle-details` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/category-list` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/search/` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/search/suggestion` - ❌ NOT REQUIRED
- `/api/v1/rental/user/cart/add-to-cart` - ❌ NOT REQUIRED
- `/api/v1/rental/user/cart/update-cart` - ❌ NOT REQUIRED
- `/api/v1/rental/user/cart/remove-vehicle` - ❌ NOT REQUIRED
- `/api/v1/rental/user/cart/get-cart` - ❌ NOT REQUIRED
- `/api/v1/rental/user/cart/remove-cart` - ❌ NOT REQUIRED
- `/api/v1/rental/user/cart/remove-multiple-cart` - ❌ NOT REQUIRED
- `/api/v1/rental/user/cart/update-user-data` - ❌ NOT REQUIRED
- `/api/v1/rental/user/trip/trip-booking` - ❌ NOT REQUIRED
- `/api/v1/rental/user/trip/get-trip-list` - ❌ NOT REQUIRED
- `/api/v1/rental/user/trip/get-trip-details` - ❌ NOT REQUIRED
- `/api/v1/rental/user/trip/cancel-trip` - ❌ NOT REQUIRED
- `/api/v1/rental/user/trip/payment` - ❌ NOT REQUIRED
- `/api/v1/rental/user/wish-list/add` - ❌ NOT REQUIRED
- `/api/v1/rental/user/wish-list/remove` - ❌ NOT REQUIRED
- `/api/v1/rental/user/wish-list` - ❌ NOT REQUIRED
- `/api/v1/rental/user/review/add` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/brand-list` - ❌ NOT REQUIRED
- `/api/v1/rental/provider/get-provider-details` - ❌ NOT REQUIRED
- `/api/v1/rental/provider/get-provider-reviews` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/get-provider-vehicles` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/category-list` - ❌ NOT REQUIRED
- `/api/v1/rental/vehicle/popular-suggestion/` - ❌ NOT REQUIRED

**Analytics APIs:**
- `/api/v1/customer/analytics/summary` - ❌ NOT REQUIRED
- `/api/v1/customer/analytics/spending-trends` - ❌ NOT REQUIRED
- `/api/v1/customer/analytics/most-purchased-products` - ❌ NOT REQUIRED
- `/api/v1/customer/analytics/product-details` - ❌ NOT REQUIRED
- `/api/v1/customer/analytics/insights` - ❌ NOT REQUIRED
- `/api/v1/customer/analytics/category-breakdown` - ❌ NOT REQUIRED
- `/api/v1/customer/analytics/product-transaction-history` - ❌ NOT REQUIRED
- `/api/v1/customer/analytics/export` - ❌ NOT REQUIRED
- `/api/qidha-wallet/transactions` - ❌ NOT REQUIRED
- `/api/qidha-wallet/analytics/summary` - ❌ NOT REQUIRED
- `/api/qidha-wallet/due-payments` - ❌ NOT REQUIRED
- `/api/qidha-wallet/payment-history` - ❌ NOT REQUIRED
- `/api/qidha-wallet/spending-categories` - ❌ NOT REQUIRED
- `/api/qidha-wallet/monthly-trends` - ❌ NOT REQUIRED
- `/api/qidha-wallet/salary-day` - ❌ NOT REQUIRED

**Other APIs:**
- `/api/v1/most-tips` - ❌ NOT REQUIRED
- `/api/v1/customer/visit-again` - ❌ NOT REQUIRED
- `/api/v1/items/basic` - ❌ NOT REQUIRED
- `/api/v1/common-condition` - ❌ NOT REQUIRED
- `/api/v1/common-condition/items/{id}` - ❌ NOT REQUIRED
- `/api/v1/items/set-menu` - ❌ NOT REQUIRED
- `/api/v1/banners/{store_id}` - ❌ NOT REQUIRED
- `/api/v1/offline_payment_method_list` - ❌ NOT REQUIRED
- `/api/v1/registration-activity` - ❌ NOT REQUIRED
- `/api/v1/vendor/business_plan` - ❌ NOT REQUIRED
- `/api/v1/vendor/subscription/payment/api` - ❌ NOT REQUIRED
- `/api/v1/vendor/package-view` - ❌ NOT REQUIRED
- `/api/v1/cashback/list` - ❌ NOT REQUIRED
- `/api/v1/cashback/getCashback` - ❌ NOT REQUIRED
- `/api/v1/advertisement/list` - ❌ NOT REQUIRED
- `/api/v1/stores/{store_id}/categories/{category_id}/subcategories-with-samples` - ❌ NOT REQUIRED

---

## Complete Endpoint List by Category

### 1. Config & System APIs (7 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/config` | GET | ❌ | ❌ | ❌ |
| `/api/v1/app-init` | GET | ❌ | ❌ | ❌ |
| `/api/v1/bootstrap` | GET | ❌ | ❌ | ❌ |
| `/api/v1/module` | GET | ❌ | ❌ | ❌ |
| `/api/v1/business-settings` | GET | ❌ | ❌ | ❌ |
| `/api/v1/app/version/check` | GET | ❌ | ❌ | ❌ |
| `/api/v1/flutter-landing-page` | GET | ❌ | ❌ | ❌ |

### 2. Auth APIs (15 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/auth/login` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/sign-up` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/forgot-password` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/reset-password` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/verify-token` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/verify-phone` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/verify-email` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/check-email` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/send-otp-again` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/social-login` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/social-register` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/firebase-verify-token` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/firebase-reset-password` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/update-info` | POST | ❌ | ❌ | ⚠️ |
| `/api/v1/auth/guest/request` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/vendor/register` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/delivery-man/store` | POST | ❌ | ❌ | ❌ |
| `/api/v1/auth/delivery-man/status` | GET | ❌ | ❌ | ❌ |

### 3. Home Data APIs (30+ endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v2/home-unified` | GET | ✅ | ✅ | ⚠️ |
| `/api/v1/banners` | GET | ✅ | ✅ | ⚠️ |
| `/api/v1/banners/taxi` | GET | ❌ | ❌ | ❌ |
| `/api/v1/banners/{store_id}` | GET | ❌ | ❌ | ❌ |
| `/api/v1/categories` | GET | ✅ | ✅ | ❌ |
| `/api/v1/categories/items/{id}` | GET | ✅ | ✅ | ❌ |
| `/api/v1/categories/stores/{id}` | GET | ✅ | ✅ | ❌ |
| `/api/v1/categories/childes/{id}` | GET | ✅ | ✅ | ❌ |
| `/api/v1/categories/featured/items` | GET | ✅ | ✅ | ❌ |
| `/api/v1/categories/popular` | GET | ✅ | ✅ | ❌ |
| `/api/v1/brands` | GET | ✅ | ✅ | ❌ |
| `/api/v1/brands/items` | GET | ✅ | ✅ | ❌ |
| `/api/v1/brands/items/search` | GET | ✅ | ✅ | ❌ |
| `/api/v1/brands/items/filter` | GET | ✅ | ✅ | ❌ |
| `/api/v1/offers/active` | GET | ✅ | ✅ | ⚠️ |
| `/api/v1/offers/{id}` | GET | ✅ | ✅ | ❌ |
| `/api/v1/offers/{id}/newitems` | GET | ✅ | ✅ | ❌ |
| `/api/v1/offers/{id}/search` | GET | ✅ | ✅ | ❌ |
| `/api/v1/stores/get-stores` | GET | ✅ | ✅ | ⚠️ |
| `/api/v1/stores/popular` | GET | ✅ | ✅ | ❌ |
| `/api/v1/stores/latest` | GET | ✅ | ✅ | ❌ |
| `/api/v1/stores/top-offer-near-me` | GET | ✅ | ✅ | ❌ |
| `/api/v1/stores/recommended` | GET | ✅ | ✅ | ❌ |
| `/api/v1/stores/details/{id}` | GET | ✅ | ✅ | ⚠️ |
| `/api/v1/stores/reviews` | GET | ✅ | ✅ | ❌ |
| `/api/v1/stores/search` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/latest` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/details/{id}` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/popular` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/recommended` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/suggested` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/discounted` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/most-reviewed` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/search` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/item-or-store-search` | GET | ✅ | ✅ | ❌ |
| `/api/v1/items/basic` | GET | ❌ | ❌ | ❌ |
| `/api/v1/items/set-menu` | POST | ❌ | ❌ | ❌ |
| `/api/v1/campaigns/basic` | GET | ✅ | ✅ | ❌ |
| `/api/v1/campaigns/item` | GET | ✅ | ✅ | ❌ |
| `/api/v1/campaigns/basic-campaign-details` | GET | ✅ | ✅ | ❌ |
| `/api/v1/flash-sales` | GET | ✅ | ✅ | ❌ |
| `/api/v1/flash-sales/items` | GET | ✅ | ✅ | ❌ |

### 4. Cart & Checkout APIs (10 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/customer/cart/list` | GET | ✅ | ✅ | ✅ |
| `/api/v1/customer/cart/add` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/cart/update` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/cart/remove` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/cart/remove-item` | POST | ✅ | ✅ | ✅ |
| `/api/v2/checkout/store-summary` | GET | ✅ | ✅ | ✅ |
| `/api/v1/coupon/list` | GET | ✅ | ✅ | ✅ |
| `/api/v1/coupon/apply` | POST | ✅ | ✅ | ✅ |
| `/api/v1/coupon/list/taxi` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/coupon/apply` | POST | ❌ | ❌ | ❌ |

### 5. Order APIs (15 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/customer/order/place` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/prescription/place` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/list` | GET | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/running-orders` | GET | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/details` | GET | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/track` | GET | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/cancel` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/payment-method` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/edit-address` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/process-payment` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/refund-reasons` | GET | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/refund-request` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/cancellation-reasons` | GET | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/parcel-instructions` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/offline-payment` | POST | ✅ | ✅ | ✅ |
| `/api/v1/customer/order/offline-payment-update` | POST | ✅ | ✅ | ✅ |

### 6. Location & Zone APIs (10 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/config/get-zone-id` | GET | ❌ | ❌ | ❌ |
| `/api/v1/zone/check` | GET | ❌ | ❌ | ❌ |
| `/api/v1/zone/list` | GET | ❌ | ❌ | ❌ |
| `/api/v1/zones` | GET | ❌ | ❌ | ❌ |
| `/api/v1/customer/update-zone` | POST | ❌ | ❌ | ⚠️ |
| `/api/v1/config/place-api-autocomplete` | GET | ❌ | ❌ | ❌ |
| `/api/v1/config/place-api-details` | GET | ❌ | ❌ | ❌ |
| `/api/v1/config/geocode-api` | GET | ❌ | ❌ | ❌ |
| `/api/v1/config/distance-api` | GET | ❌ | ❌ | ❌ |
| `/api/v1/config/direction-api` | GET | ❌ | ❌ | ❌ |

### 7. Customer Profile APIs (10 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/customer/info` | GET | ❌ | ✅ | ✅ |
| `/api/v1/customer/update-profile` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/remove-account` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/update-interest` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/suggested-items` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/visit-again` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/cm-firebase-token` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/notifications` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/wish-list` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/wish-list/add` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/wish-list/remove` | POST | ❌ | ❌ | ✅ |

### 8. Address APIs (4 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/customer/address/list` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/address/add` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/address/update/{id}` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/address/delete` | DELETE | ❌ | ❌ | ✅ |

### 9. Wallet APIs (20+ endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/qidha-wallet/get-wallet` | GET | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/store` | POST | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/credit` | POST | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/debit` | POST | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/nafath/initiate` | POST | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/nafath/checkStatus` | POST | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/nafath/sign` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/transactions` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/add-fund` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/bonuses` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/validate-recipient` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/transfer` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/recipients` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/recipients/add` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/wallet/recipients/{id}` | DELETE | ❌ | ❌ | ✅ |
| `/api/v1/customer/requestExchangeWalletMoney` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/ExchangeWalletMoney` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/loyalty-point/transactions` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/loyalty-point/point-transfer` | POST | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/transactions` | GET | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/analytics/summary` | GET | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/due-payments` | GET | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/payment-history` | GET | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/spending-categories` | GET | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/monthly-trends` | GET | ❌ | ❌ | ✅ |
| `/api/qidha-wallet/salary-day` | GET | ❌ | ❌ | ✅ |

### 10. Analytics APIs (9 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/customer/analytics/summary` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/spending-trends` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/most-purchased-products` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/product-details` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/insights` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/category-breakdown` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/product-transaction-history` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/export` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/analytics/health` | GET | ❌ | ❌ | ✅ |

### 11. Message APIs (5 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/customer/message/list` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/message/search-list` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/message/details` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/message/send` | POST | ❌ | ❌ | ✅ |
| `/api/v1/customer/message/get` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/automated-message` | GET | ❌ | ❌ | ✅ |

### 12. Review APIs (3 endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/items/reviews/submit` | POST | ❌ | ❌ | ✅ |
| `/api/v1/stores/reviews` | GET | ❌ | ❌ | ❌ |
| `/api/v1/delivery-man/reviews/submit` | POST | ❌ | ❌ | ✅ |

### 13. Taxi/Rental APIs (30+ endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/rental/vehicle/top-rated` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/banners` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/coupon/list` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/coupon/apply` | POST | ❌ | ❌ | ❌ |
| `/api/v1/rental/vehicle/get-vehicle-details` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/vehicle/category-list` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/vehicle/search/` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/vehicle/search/suggestion` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/user/cart/add-to-cart` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/cart/update-cart` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/cart/remove-vehicle` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/cart/get-cart` | GET | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/cart/remove-cart` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/cart/remove-multiple-cart` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/cart/update-user-data` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/trip/trip-booking` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/trip/get-trip-list` | GET | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/trip/get-trip-details` | GET | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/trip/cancel-trip` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/trip/payment` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/wish-list/add` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/wish-list/remove` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/wish-list` | GET | ❌ | ❌ | ✅ |
| `/api/v1/rental/user/review/add` | POST | ❌ | ❌ | ✅ |
| `/api/v1/rental/vehicle/brand-list` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/provider/get-provider-details` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/provider/get-provider-reviews` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/vehicle/get-provider-vehicles` | GET | ❌ | ❌ | ❌ |
| `/api/v1/rental/vehicle/popular-suggestion/` | GET | ❌ | ❌ | ❌ |

### 14. Other APIs (20+ endpoints)
| Endpoint | Method | Module-ID Required | Zone-ID Required | Auth Required |
|----------|--------|-------------------|------------------|---------------|
| `/api/v1/most-tips` | GET | ❌ | ❌ | ❌ |
| `/api/v1/common-condition` | GET | ❌ | ❌ | ❌ |
| `/api/v1/common-condition/items/{id}` | GET | ❌ | ❌ | ❌ |
| `/api/v1/parcel-category` | GET | ❌ | ❌ | ❌ |
| `/api/v1/other-banners` | GET | ❌ | ❌ | ❌ |
| `/api/v1/other-banners/why-choose` | GET | ❌ | ❌ | ❌ |
| `/api/v1/other-banners/video-content` | GET | ❌ | ❌ | ❌ |
| `/api/v1/offline_payment_method_list` | GET | ❌ | ❌ | ❌ |
| `/api/v1/registration-activity` | POST | ❌ | ❌ | ❌ |
| `/api/v1/vendor/business_plan` | GET | ❌ | ❌ | ❌ |
| `/api/v1/vendor/subscription/payment/api` | POST | ❌ | ❌ | ❌ |
| `/api/v1/vendor/package-view` | GET | ❌ | ❌ | ❌ |
| `/api/v1/cashback/list` | GET | ❌ | ❌ | ❌ |
| `/api/v1/cashback/getCashback` | GET | ❌ | ❌ | ❌ |
| `/api/v1/advertisement/list` | GET | ❌ | ❌ | ❌ |
| `/api/v1/about-us` | GET | ❌ | ❌ | ❌ |
| `/api/v1/privacy-policy` | GET | ❌ | ❌ | ❌ |
| `/api/v1/terms-and-conditions` | GET | ❌ | ❌ | ❌ |
| `/api/v1/shipping-policy` | GET | ❌ | ❌ | ❌ |
| `/api/v1/refund-policy` | GET | ❌ | ❌ | ❌ |
| `/api/v1/cancelation` | GET | ❌ | ❌ | ❌ |
| `/api/v1/newsletter/subscribe` | POST | ❌ | ❌ | ❌ |
| `/api/v1/customer/delegate/get-delegate-status` | GET | ❌ | ❌ | ✅ |
| `/api/v1/customer/delegate/store` | POST | ❌ | ❌ | ✅ |
| `/api/v1/delivery-man/last-location` | GET | ❌ | ❌ | ❌ |
| `/api/v1/stores/{store_id}/categories/{category_id}/subcategories-with-samples` | GET | ❌ | ❌ | ❌ |

---

## Header Requirements Matrix

### Legend
- ✅ = Required
- ⚠️ = Required if logged in
- ❌ = Not required

### Standard Headers
All API calls include these headers (when applicable):
- `Content-Type`: `application/json; charset=UTF-8`
- `X-localization`: Language code (`ar`, `en`, etc.)
- `latitude`: JSON-encoded latitude string
- `longitude`: JSON-encoded longitude string
- `zone-id`: JSON-encoded array of zone IDs (e.g., `[2,4,3,5]`)
- `module-id`: Module ID string (e.g., `"3"`)
- `Authorization`: `Bearer {token}` (if logged in)
- `X-Request-ID`: Unique request identifier for tracing

---

## Summary

**Total Endpoints Documented:** 150+

**Module-ID Preferred (Optional):** ~60 endpoints (Home data, Stores, Items, Categories, Cart, Orders, Checkout)
**Module-ID NOT Required:** ~90 endpoints (Auth, Config, Wallet, Analytics, Taxi, etc.)

**Key Finding:**
- **Stores, Items, Categories PREFER module-id but may work without it**
- Code includes module-id when available (`api_client.dart:271-277`)
- Backend may be lenient and accept requests without module-id (backward compatibility)
- When module-id is missing, backend may use default module or return all modules
- **Recommendation:** Always include module-id when available for correct data filtering

---

**End of Report**

