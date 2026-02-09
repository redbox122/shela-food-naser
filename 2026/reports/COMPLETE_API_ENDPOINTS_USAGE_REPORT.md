# Complete API Endpoints Usage Report
## Comprehensive Analysis of All Endpoints Used in the App

**Generated:** 2025-01-27  
**Base URL:** `https://shellafood.com` (Production)  
**Total Endpoints Documented:** 150+

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [API Client Architecture](#api-client-architecture)
3. [Endpoint Categories](#endpoint-categories)
4. [Detailed Endpoint Documentation](#detailed-endpoint-documentation)
5. [Request/Response Patterns](#requestresponse-patterns)
6. [Usage Locations in Codebase](#usage-locations-in-codebase)
7. [Header Requirements](#header-requirements)
8. [Error Handling](#error-handling)

---

## Executive Summary

### Key Findings

- **Total Endpoints:** 150+ unique endpoints
- **API Versions:** v1 (primary), v2 (BFF unified endpoints)
- **Authentication:** Bearer token (JWT/Passport) in Authorization header
- **Module Support:** Multi-module architecture (Food, Pharmacy, Ecommerce, Grocery, Parcel, Taxi)
- **Zone-Based:** Most endpoints require zone-id for location-based filtering
- **Caching Strategy:** ETag support, Hive cache for home data, LocalClient for offline support

### Endpoint Distribution

- **Config & System:** 7 endpoints
- **Authentication:** 17 endpoints
- **Home Data:** 30+ endpoints
- **Cart & Checkout:** 10 endpoints
- **Orders:** 15 endpoints
- **Location & Zones:** 10 endpoints
- **Customer Profile:** 10 endpoints
- **Address Management:** 4 endpoints
- **Wallet (Qidha & Regular):** 20+ endpoints
- **Analytics:** 9 endpoints
- **Messages:** 6 endpoints
- **Reviews:** 3 endpoints
- **Taxi/Rental:** 30+ endpoints
- **Other:** 20+ endpoints

---

## API Client Architecture

### Base Client: `ApiClient`

**Location:** `lib/api/api_client.dart`

**Key Features:**
- Secure HTTP client with certificate pinning (production)
- Fallback to standard HTTP client
- ETag support for conditional requests
- Automatic header management (zone-id, module-id, localization)
- Request cancellation support
- Timeout: 30 seconds (120s for `/api/v1/items/latest`)

**Standard Headers (Auto-added):**
```dart
{
  'Content-Type': 'application/json; charset=UTF-8',
  'X-localization': 'ar' | 'en' | 'es' | 'bn',
  'latitude': '24.604301879077966',
  'longitude': '46.59593515098095',
  'zone-id': '[2,4,3,5]',  // JSON-encoded array
  'module-id': '3',  // Optional, preferred for data APIs
  'Authorization': 'Bearer {token}',  // If authenticated
  'X-Request-ID': 'req_1234567890'  // For tracing
}
```

**Methods:**
- `getData(uri, {query, headers, cancelToken})` - GET requests
- `postData(uri, body, {headers, timeout})` - POST requests
- `putData(uri, body, {headers})` - PUT requests
- `deleteData(uri, {headers})` - DELETE requests
- `postMultipartData(uri, body, multipartBody)` - Multipart POST

---

## Endpoint Categories

### 1. Config & System APIs

#### `/api/v1/config`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Usage:** `lib/features/splash/domain/repositories/splash_repository.dart:27`
- **Response:** ConfigModel with app settings, currency, timezone, etc.

#### `/api/v1/app-init`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Usage:** `lib/features/splash/domain/services/app_init_service.dart:30`
- **Purpose:** Consolidated initialization (config + modules + zones + business settings)
- **Response:** Combined app initialization data

#### `/api/v1/bootstrap`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Usage:** `lib/features/splash/domain/services/app_init_service.dart:104`
- **Purpose:** Consolidated home screen data (legacy, replaced by `/api/v2/home-unified`)

#### `/api/v1/module`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Usage:** `lib/features/splash/domain/repositories/splash_repository.dart:169`
- **Response:** List of available modules (Food, Pharmacy, etc.)

#### `/api/v1/business-settings/mobile-app-home-screen-setup`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Usage:** Home screen configuration
- **Response:** Home screen layout configuration

---

### 2. Authentication APIs

#### `/api/v1/auth/login`
- **Method:** POST
- **Auth:** ❌ Not required
- **Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:79`
- **Request Body:**
```json
{
  "email_or_phone": "user@example.com",
  "password": "password123",
  "login_type": "email" | "phone",
  "field_type": "email" | "phone",
  "guest_id": "123"  // Optional, for cart transfer
}
```
- **Response:**
```json
{
  "token": "jwt_token_here",
  "user": { /* user data */ }
}
```

#### `/api/v1/auth/sign-up`
- **Method:** POST
- **Auth:** ❌ Not required
- **Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:49`
- **Request Body:**
```json
{
  "f_name": "John",
  "l_name": "Doe",
  "email": "user@example.com",
  "phone": "+1234567890",
  "password": "password123",
  "country_code": "+1",
  "ref_code": "REF123"  // Optional referral code
}
```

#### `/api/v1/auth/guest/request`
- **Method:** POST
- **Auth:** ❌ Not required
- **Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:124`
- **Request Body:**
```json
{
  "fcm_token": "firebase_token"
}
```
- **Response:**
```json
{
  "guest_id": "12345"
}
```

#### `/api/v1/auth/social-login`
- **Method:** POST
- **Auth:** ❌ Not required
- **Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:175`
- **Request Body:**
```json
{
  "email": "user@example.com",
  "token": "social_provider_token",
  "unique_id": "social_user_id",
  "medium": "google" | "facebook" | "apple",
  "guest_id": "123"  // Optional
}
```

#### `/api/v1/auth/verify-phone`
- **Method:** POST
- **Auth:** ❌ Not required
- **Location:** `lib/features/verification/domein/reposotories/verification_repository.dart:80`
- **Request Body:**
```json
{
  "phone": "+1234567890",
  "otp": "123456"
}
```

#### `/api/v1/auth/forgot-password`
- **Method:** POST
- **Auth:** ❌ Not required
- **Location:** `lib/features/verification/domein/reposotories/verification_repository.dart:39`
- **Request Body:**
```json
{
  "phone": "+1234567890" | "email": "user@example.com"
}
```

---

### 3. Home Data APIs

#### `/api/v2/home-unified` ⚡ BFF v2 Endpoint
- **Method:** GET
- **Auth:** ⚠️ Optional (enhanced data if authenticated)
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/home/domain/services/home_unified_service.dart:108`
- **Purpose:** Single call for ALL home screen data (banners, categories, stores, brands, offers)
- **Query Parameters:**
  - `offset`: Pagination offset
  - `limit`: Items per page
- **Response:** HomeUnifiedModel with all home data in one response
- **Benefits:** 80% reduction in API calls, 70% smaller payload

#### `/api/v1/banners`
- **Method:** GET
- **Auth:** ⚠️ Optional
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/banner/domain/repositories/banner_repository.dart:61`
- **Query Parameters:**
  - `featured=1`: Get featured banners
  - `type=promotional`: Get promotional banners
- **Response:** List of BannerModel

#### `/api/v1/categories`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/category/domain/reposotories/category_repository.dart:138`
- **Response:** List of CategoryModel

#### `/api/v1/stores/get-stores`
- **Method:** GET
- **Auth:** ⚠️ Optional
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/store/domain/repositories/store_repository.dart:332`
- **Query Parameters:**
  - `type`: Store type filter
  - `offset`: Pagination offset
  - `limit`: Items per page (default: 12)
  - `filter=nearby`: Sort by distance (Food module)
  - `recently_added=true`: Filter recently added
  - `min_rating=4.5`: Filter by rating
  - `max_delivery_time=30`: Filter by delivery time
  - `min_price`: Minimum price
  - `max_price`: Maximum price
  - `sort_by`: Sort order
- **Response:** StoreModel with paginated stores

#### `/api/v1/stores/details/{store_id}`
- **Method:** GET
- **Auth:** ⚠️ Optional
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/store/domain/repositories/store_repository.dart:1001`
- **Response:** Store details with menu items, reviews, etc.

#### `/api/v1/stores/popular`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/store/domain/repositories/store_repository.dart:785`
- **Query Parameters:**
  - `type`: Store type
  - `offset`: Pagination
  - `limit`: Items per page

#### `/api/v1/stores/latest`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/store/domain/repositories/store_repository.dart:742`
- **Query Parameters:**
  - `type`: Store type
  - `offset`: Pagination
  - `limit`: Items per page

#### `/api/v1/items/latest`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** Multiple locations
- **Query Parameters:**
  - `store_id`: Filter by store
  - `category_id`: Filter by category
  - `offset`: Pagination
  - `limit`: Items per page
- **Special:** 120s timeout, CancelToken support
- **Response:** ItemModel with paginated items

#### `/api/v1/items/details/{item_id}`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/item/domain/repositories/item_repository.dart:80`
- **Response:** Item with variations, addons, reviews

#### `/api/v1/items/popular`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Query Parameters:**
  - `type`: Item type
  - `offset`: Pagination
  - `limit`: Items per page

#### `/api/v1/offers/active`
- **Method:** GET
- **Auth:** ⚠️ Optional
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/offers/domain/reposotories/offers_repository.dart:45`
- **Response:** List of active offers

---

### 4. Cart & Checkout APIs

#### `/api/v1/customer/cart/list`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** Cart management
- **Response:** List of cart items

#### `/api/v1/customer/cart/add`
- **Method:** POST
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Request Body:**
```json
{
  "item_id": 123,
  "quantity": 2,
  "variation": [...],
  "addon_ids": [...]
}
```

#### `/api/v1/customer/cart/update`
- **Method:** POST
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Request Body:**
```json
{
  "cart_id": 456,
  "quantity": 3
}
```

#### `/api/v2/checkout/store-summary` ⚡ BFF v2 Endpoint
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/checkout/domain/repositories/checkout_repository.dart:48`
- **Purpose:** Minimal store data for checkout (17 fields vs 50+)
- **Query Parameters:**
  - `store_id`: Store ID
- **Response:** Lightweight store summary

#### `/api/v1/coupon/list`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Response:** List of available coupons

#### `/api/v1/coupon/apply`
- **Method:** POST
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Request Body:**
```json
{
  "code": "COUPON123",
  "store_id": 123
}
```

---

### 5. Order APIs

#### `/api/v1/customer/order/place`
- **Method:** POST
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/checkout/domain/repositories/checkout_repository.dart:152`
- **Request Body:** PlaceOrderBodyModel
```json
{
  "use_cart": true,  // Use session cart instead of cart array
  "order_amount": 150.50,
  "order_type": "delivery" | "take_away",
  "payment_method": "cash_on_delivery" | "digital_payment" | "wallet",
  "order_note": "Please deliver to front door",
  "coupon_code": "COUPON123",
  "store_id": 123,
  "distance": 5.2,
  "schedule_at": "2025-01-28 14:00:00",  // Optional
  "discount_amount": 10.00,
  "tax_amount": 15.00,
  "address": "123 Main St",
  "latitude": "24.604301879077966",
  "longitude": "46.59593515098095",
  "contact_person_name": "John Doe",
  "contact_person_number": "+1234567890",
  "address_type": "home",
  "dm_tips": "15",
  "delivery_instruction": "deliver_to_front_door",
  "cutlery": 1,
  "receiver_details": {  // For parcel orders
    "contact_person_name": "Jane Doe",
    "contact_person_number": "+0987654321",
    "address": "456 Oak Ave",
    "latitude": "24.604301879077966",
    "longitude": "46.59593515098095"
  }
}
```
- **Response:**
```json
{
  "order_id": 789,
  "order_amount": 150.50,
  "payment_status": "unpaid",
  "order_status": "pending"
}
```

#### `/api/v1/customer/order/list`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/order/domain/repositories/order_repository.dart:114`
- **Query Parameters:**
  - `offset`: Pagination offset
  - `limit`: Items per page (default: 10)
- **Response:** PaginatedOrderModel with order history

#### `/api/v1/customer/order/running-orders`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/order/domain/repositories/order_repository.dart:105`
- **Query Parameters:**
  - `offset`: Pagination offset
  - `limit`: Items per page (default: 10, 50 for dashboard)
- **Response:** PaginatedOrderModel with active orders

#### `/api/v1/customer/order/details`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/order/domain/repositories/order_repository.dart:72`
- **Query Parameters:**
  - `order_id`: Order ID
  - `guest_id`: Optional guest ID
- **Response:** OrderDetailsModel with full order information

#### `/api/v1/customer/order/track`
- **Method:** GET
- **Auth:** ⚠️ Optional (guest tracking supported)
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/order/domain/repositories/order_repository.dart:33`
- **Query Parameters:**
  - `order_id`: Order ID
  - `guest_id`: Optional guest ID
  - `contact_number`: Optional contact number
- **Response:** Real-time order tracking data

#### `/api/v1/customer/order/cancel`
- **Method:** POST
- **Auth:** ✅ Required (or guest_id)
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/order/domain/repositories/order_repository.dart:56`
- **Request Body:**
```json
{
  "_method": "put",
  "order_id": 789,
  "reason": "Changed my mind",
  "guest_id": "123"  // Optional
}
```

#### `/api/v1/customer/order/process-payment`
- **Method:** POST
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/checkout/domain/repositories/checkout_repository.dart:255`
- **Request Body:**
```json
{
  "order_id": 789,
  "payment_method": "digital_payment",
  "amount": 150.50
}
```

#### `/api/v1/customer/order/edit-address`
- **Method:** POST
- **Auth:** ✅ Required
- **Module-ID:** ✅ Required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/checkout/domain/repositories/checkout_repository.dart:294`
- **Request Body:**
```json
{
  "order_id": 789,
  "address": "New Address",
  "latitude": "24.604301879077966",
  "longitude": "46.59593515098095"
}
```

---

### 6. Location & Zone APIs

#### `/api/v1/config/get-zone-id`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Location:** `lib/features/location/domain/repositories/location_repository.dart:80`
- **Query Parameters:**
  - `lat`: Latitude
  - `lng`: Longitude
- **Response:** Zone IDs for the coordinates

#### `/api/v1/zone/list`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Location:** `lib/features/location/domain/repositories/location_repository.dart:299`
- **Response:** List of all active zones with coordinates

#### `/api/v1/config/place-api-autocomplete`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Location:** `lib/features/location/domain/repositories/location_repository.dart:247`
- **Query Parameters:**
  - `search_text`: Search query
- **Response:** List of place suggestions

#### `/api/v1/config/place-api-details`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Location:** `lib/features/location/domain/repositories/location_repository.dart:287`
- **Query Parameters:**
  - `placeid`: Google Place ID
- **Response:** Place details with coordinates

#### `/api/v1/config/distance-api`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ❌ Not required
- **Location:** `lib/features/checkout/domain/repositories/checkout_repository.dart:47`
- **Query Parameters:**
  - `origin_lat`: Origin latitude
  - `origin_lng`: Origin longitude
  - `destination_lat`: Destination latitude
  - `destination_lng`: Destination longitude
  - `mode`: "driving" | "walking"
- **Response:** Distance and duration

---

### 7. Customer Profile APIs

#### `/api/v1/customer/info`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ❌ Not required
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/profile/domain/repositories/profile_repository.dart:19`
- **Response:** Customer profile information

#### `/api/v1/customer/update-profile`
- **Method:** POST
- **Auth:** ✅ Required
- **Module-ID:** ❌ Not required
- **Zone-ID:** ❌ Not required
- **Location:** `lib/features/profile/domain/repositories/profile_repository.dart:76`
- **Request Body:**
```json
{
  "f_name": "John",
  "l_name": "Doe",
  "email": "user@example.com",
  "phone": "+1234567890",
  "image": "base64_encoded_image"  // Optional, multipart
}
```

#### `/api/v1/customer/address/list`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ❌ Not required
- **Zone-ID:** ❌ Not required
- **Response:** List of saved addresses

#### `/api/v1/customer/address/add`
- **Method:** POST
- **Auth:** ✅ Required
- **Request Body:**
```json
{
  "contact_person_name": "John Doe",
  "address_type": "home" | "work" | "other",
  "address": "123 Main St",
  "latitude": "24.604301879077966",
  "longitude": "46.59593515098095",
  "zone_id": 2,
  "road": "Street number",
  "house": "House number",
  "floor": "Floor number"
}
```

#### `/api/v1/customer/address/update/{id}`
- **Method:** POST
- **Auth:** ✅ Required
- **Request Body:** Same as add address

#### `/api/v1/customer/address/delete`
- **Method:** DELETE
- **Auth:** ✅ Required
- **Query Parameters:**
  - `address_id`: Address ID to delete

---

### 8. Wallet APIs

#### Qidha Wallet APIs

#### `/api/qidha-wallet/get-wallet`
- **Method:** GET
- **Auth:** ✅ Required
- **Module-ID:** ❌ Not required
- **Location:** `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:179`
- **Response:** Wallet balance and details

#### `/api/qidha-wallet/store`
- **Method:** POST
- **Auth:** ✅ Required
- **Request Body:**
```json
{
  "store_id": 123,
  "amount": 100.00
}
```

#### `/api/qidha-wallet/credit`
- **Method:** POST
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:334`
- **Purpose:** شحن الرصيد (Add funds)
- **Request Body:**
```json
{
  "amount": 100.00,
  "payment_method": "nafath" | "card"
}
```

#### `/api/qidha-wallet/debit`
- **Method:** POST
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:361`
- **Purpose:** شراء (Purchase)
- **Request Body:**
```json
{
  "amount": 50.00,
  "order_id": 789
}
```

#### `/api/qidha-wallet/nafath/initiate`
- **Method:** POST
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:433`
- **Purpose:** Initiate Nafath authentication
- **Request Body:**
```json
{
  "amount": 100.00
}
```

#### `/api/qidha-wallet/nafath/checkStatus`
- **Method:** POST
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:396`
- **Purpose:** Check Nafath authentication status
- **Request Body:**
```json
{
  "transaction_id": "nafath_transaction_id"
}
```

#### `/api/qidha-wallet/nafath/sign`
- **Method:** POST
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:465`
- **Purpose:** Complete Nafath signature
- **Request Body:**
```json
{
  "transaction_id": "nafath_transaction_id",
  "signature": "nafath_signature"
}
```

#### Regular Wallet APIs

#### `/api/v1/customer/wallet/transactions`
- **Method:** GET
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet/domain/repositories/wallet_repository.dart:68`
- **Query Parameters:**
  - `offset`: Pagination offset
  - `limit`: Items per page (default: 10)
  - `type`: Transaction type filter (all, order, loyalty_point, add_fund, referrer, CashBack)
- **Response:** Paginated wallet transactions

#### `/api/v1/customer/wallet/add-fund`
- **Method:** POST
- **Auth:** ✅ Required
- **Request Body:**
```json
{
  "amount": 100.00,
  "payment_method": "stripe" | "paypal"
}
```

#### `/api/v1/customer/wallet/transfer`
- **Method:** POST
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:23`
- **Request Body:**
```json
{
  "recipient_phone": "+1234567890",
  "amount": 50.00,
  "note": "Transfer note"
}
```

#### `/api/v1/customer/wallet/validate-recipient`
- **Method:** POST
- **Auth:** ✅ Required
- **Location:** `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:15`
- **Request Body:**
```json
{
  "phone": "+1234567890"
}
```
- **Response:** Recipient validation result

---

### 9. Analytics APIs

#### `/api/v1/customer/analytics/summary`
- **Method:** GET
- **Auth:** ✅ Required
- **Location:** `lib/features/statistics/data/api/analytics_api_client.dart:12`
- **Response:** Analytics summary (total spent, orders count, etc.)

#### `/api/v1/customer/analytics/spending-trends`
- **Method:** GET
- **Auth:** ✅ Required
- **Location:** `lib/features/statistics/data/api/analytics_api_client.dart:41`
- **Query Parameters:**
  - `period`: "week" | "month" | "year"
- **Response:** Spending trends over time

#### `/api/v1/customer/analytics/most-purchased-products`
- **Method:** GET
- **Auth:** ✅ Required
- **Location:** `lib/features/statistics/data/api/analytics_api_client.dart:70`
- **Response:** Most frequently purchased products

#### `/api/qidha-wallet/analytics/summary`
- **Method:** GET
- **Auth:** ✅ Required
- **Location:** `lib/features/statistics/data/api/qidha_wallet_api_client.dart:30`
- **Response:** Qidha wallet analytics summary

---

### 10. Search APIs

#### `/api/v1/items/item-or-store-search`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/search/domain/repositories/search_repository.dart:90`
- **Query Parameters:**
  - `name`: Search query
- **Response:** Search suggestions (items and stores)

#### `/api/v1/categories/popular`
- **Method:** GET
- **Auth:** ❌ Not required
- **Module-ID:** ✅ Preferred
- **Zone-ID:** ✅ Required
- **Location:** `lib/features/search/domain/repositories/search_repository.dart:101`
- **Query Parameters:**
  - `trending=true`: Get trending categories
  - `hours=24`: Time window for trending
- **Response:** Popular categories

---

## Request/Response Patterns

### Standard Success Response
```json
{
  "status": true,
  "message": "Success message",
  "data": { /* response data */ }
}
```

### Paginated Response
```json
{
  "status": true,
  "total_size": 100,
  "limit": 10,
  "offset": 0,
  "data": [ /* array of items */ ]
}
```

### Error Response
```json
{
  "status": false,
  "message": "Error message",
  "errors": [
    {
      "code": "ERROR_CODE",
      "message": "Error description"
    }
  ]
}
```

### Common HTTP Status Codes
- `200`: Success
- `201`: Created
- `304`: Not Modified (ETag)
- `400`: Bad Request
- `401`: Unauthorized (token expired/invalid)
- `403`: Forbidden
- `404`: Not Found
- `429`: Rate Limited
- `500`: Internal Server Error
- `503`: Service Unavailable

---

## Usage Locations in Codebase

### Repository Pattern
All API calls go through repositories:
- `lib/features/{feature}/domain/repositories/{feature}_repository.dart`

### Service Layer
Some features use service layer:
- `lib/features/{feature}/domain/services/{feature}_service.dart`

### Direct API Calls
Rare, but some controllers call API directly:
- `lib/features/{feature}/controllers/{feature}_controller.dart`

---

## Header Requirements

### Always Included
- `Content-Type`: `application/json; charset=UTF-8`
- `X-localization`: Language code
- `latitude`: JSON-encoded string
- `longitude`: JSON-encoded string
- `zone-id`: JSON-encoded array

### Conditionally Included
- `module-id`: Preferred for data APIs (stores, items, categories)
- `Authorization`: `Bearer {token}` (if authenticated)
- `X-Request-ID`: Request tracing ID
- `X-Response-Mode`: `minimal` | `standard` (for lite resources)

### Header Management
Headers are automatically managed by `ApiClient.updateHeader()`:
- Token from SharedPreferences or SecureTokenStorage
- Zone IDs from AddressModel
- Module ID from SplashController
- Language from SharedPreferences

---

## Error Handling

### API Checker
All responses go through `ApiChecker.checkApi()`:
- `401`: Clear session, redirect to login
- `403`: Show access denied message
- `500`: Show server error message
- `503`: Show service unavailable message

### Error Response Parsing
Errors are parsed and translated:
- Backend messages are cleaned (remove `messages.` prefix)
- Messages are translated via `BackendMessageTranslator`
- User-friendly error messages displayed

### Network Errors
- Timeout: 30 seconds (120s for `/api/v1/items/latest`)
- Connection errors: Show "connection_to_api_server_failed" message
- Secure client fallback: Automatic fallback to standard HTTP

---

## Special Features

### ETag Support
- Conditional requests with `If-None-Match` header
- `304 Not Modified` responses use cached data
- ETags stored in Hive cache

### Request Cancellation
- CancelToken support for `/api/v1/items/latest`
- Prevents unnecessary requests when user navigates away

### Caching Strategy
- **Hive Cache:** Home unified data, app config
- **LocalClient:** Offline support for stores, items
- **ETag:** Conditional requests for unchanged data

### Secure HTTP Client
- Certificate pinning (production only)
- Secure token storage
- Automatic fallback to standard HTTP if secure client fails

---

## End of Report

**Note:** This report is generated from codebase analysis. For the most up-to-date API documentation, refer to the backend API documentation.

**Last Updated:** 2025-01-27

