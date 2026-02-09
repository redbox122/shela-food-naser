# Complete Checkout Flow Documentation

## Overview

This document provides a detailed technical reference for the complete checkout flow from the moment the user clicks "Proceed to Checkout" through order creation, fee calculations, zone validation, and payment processing across all three payment methods.

---

## Table of Contents

1. [User Clicks "Proceed to Checkout"](#user-clicks-proceed-to-checkout)
2. [Checkout Screen Initialization](#checkout-screen-initialization)
3. [Delivery Zone Validation](#delivery-zone-validation)
4. [Distance Calculation](#distance-calculation)
5. [Fee Calculations](#fee-calculations)
6. [Order Creation (Unpaid)](#order-creation-unpaid)
7. [Payment Processing](#payment-processing)
   - [Regular Wallet Payment](#regular-wallet-payment)
   - [Qidha Wallet Payment](#qidha-wallet-payment)
   - [Digital Payment (MyFatoorah)](#digital-payment-myfatoorah)

---

## User Clicks "Proceed to Checkout"

### Location: `lib/features/cart/screens/cart_screen.dart:1738-1813`

**What Happens:**

1. **Minimum Order Validation:**
   ```dart
   double subTotal = cartController.subTotal;
   double minimumOrder = storeController.store?.minimumOrder ?? 0;
   
   if (minimumOrder > 0 && subTotal < minimumOrder) {
     showCustomSnackBar('${'minimum_order_amount_is'.tr} ${PriceConverter.convertPrice(minimumOrder)}');
     return; // Stop checkout
   }
   ```

2. **Location Validation:**
   ```dart
   bool isLocationValid = await _CartScreenState.validateLocationForCheckout();
   if (!isLocationValid) {
     return; // Show location picker dialog
   }
   ```

3. **Pre-calculate Distance:**
   ```dart
   await _CartScreenState._calculateAndSetDistanceBeforeCheckout();
   ```

4. **Navigate to Checkout:**
   ```dart
   Get.toNamed(RouteHelper.getCheckoutRoute('cart', storeId: null));
   ```

**Code Reference:**
- `lib/features/cart/screens/cart_screen.dart:1738-1813`

---

## Checkout Screen Initialization

### Location: `lib/features/checkout/screens/checkout_screen.dart:initState()`

### Step 1: Load User Data (If Logged In)

**API Calls:**

#### 1. Get User Info
**Endpoint:** `GET /api/v1/customer/info`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response:**
```json
{
  "id": 123,
  "f_name": "John",
  "l_name": "Doe",
  "phone": "+966501234567",
  "email": "john@example.com",
  "wallet_balance": 100.0
}
```

**Code:** `lib/features/profile/controllers/profile_controller.dart:getUserInfo()`

#### 2. Get Coupon List
**Endpoint:** `GET /api/v1/customer/coupon/list`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response:**
```json
{
  "coupons": [
    {
      "id": 1,
      "code": "SAVE10",
      "discount": 10.0,
      "discount_type": "percent"
    }
  ]
}
```

**Code:** `lib/features/my_coupon/controllers/my_coupon_controller.dart:getCouponList()`

#### 3. Get Address List
**Endpoint:** `GET /api/v1/customer/address/list`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response:**
```json
{
  "addresses": [
    {
      "id": 1,
      "address": "123 Main Street",
      "latitude": "24.7136",
      "longitude": "46.6753",
      "zone_id": 5,
      "zone_ids": [5],
      "zone_data": [...]
    }
  ]
}
```

**Code:** `lib/features/address/controllers/address_controller.dart:getAddressList()`

#### 4. Get Qidha Wallet Status
**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response:**
```json
{
  "wallet": {
    "id": 123,
    "status": "active",
    "signature_status": 1,
    "available_balance": 5000.0,
    "purchase_limit": 40000.0
  }
}
```

**Code:** `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart:get_Wallet_Kaidh()`

### Step 2: Initialize Checkout Data

**Function:** `checkoutController.initCheckoutData(context, storeId)`

**What It Does:**
1. Loads store information
2. Sets up delivery options
3. Initializes payment methods
4. Prepares cart data

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:initCheckoutData()`

### Step 3: Calculate Distance (If Not Pre-calculated)

**Function:** `checkoutController.getDistanceInKM(origin, destination)`

**What It Does:**
- Calculates distance between user address and store
- Gets extra charge (vehicle charge) based on distance
- Updates UI with delivery fee

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:getDistanceInKM()`

---

## Delivery Zone Validation

### Location: `lib/features/cart/screens/cart_screen.dart:249-288`

### Step 1: Check Current Address

**Function:** `validateLocationForCheckout()`

**What It Checks:**
1. Address exists in SharedPreferences
2. Address has valid latitude/longitude
3. Address is within service zone

**Code:**
```dart
AddressModel? currentAddress = AddressHelper.getUserAddressFromSharedPref();

if (currentAddress == null || 
    currentAddress.latitude == null || 
    currentAddress.longitude == null) {
  showLocationPickerDialog();
  return false;
}
```

### Step 2: Get Zone Information

**Endpoint:** `GET /api/v1/config/get-zone-id?lat={latitude}&lng={longitude}`

**Headers:**
```
Accept: application/json
```

**Request Parameters:**
- `lat`: User's latitude (required)
- `lng`: User's longitude (required)

**Response (200 OK):**
```json
{
  "zone_ids": [5, 6],
  "zone_data": [
    {
      "id": 5,
      "name": "Zone 1",
      "modules": [
        {
          "id": 1,
          "pivot": {
            "zone_id": 5,
            "per_km_shipping_charge": 2.5,
            "minimum_shipping_charge": 5.0,
            "maximum_shipping_charge": 50.0,
            "first_km_fee": 10.0,
            "first_km_distance": 3.0
          }
        }
      ],
      "digital_payment": true,
      "offline_payment": false
    }
  ],
  "area_ids": [1, 2]
}
```

**Response (400/404 - Outside Zone):**
```json
{
  "zone_ids": [],
  "zone_data": [],
  "area_ids": []
}
```

**Code:**
- Repository: `lib/features/location/domain/repositories/location_repository.dart:151-192`
- Controller: `lib/features/location/controllers/location_controller.dart:315-341`

**Caching:**
- Zone data is cached for 30 minutes
- Cache key: `zone_cache_{lat},{lng}`
- Cache time: `zone_cache_time_{lat},{lng}`

### Step 3: Validate Zone Match

**What It Checks:**
```dart
ZoneResponseModel response = await locationController.getZone(
  currentAddress.latitude, 
  currentAddress.longitude, 
  false
);

if (response.isSuccess && response.zoneIds.isNotEmpty) {
  // Location is in service zone
  return true;
} else {
  // Location is outside service zone
  showLocationPickerDialog();
  return false;
}
```

**Code:** `lib/features/cart/screens/cart_screen.dart:269-282`

---

## Distance Calculation

### Location: `lib/features/checkout/controllers/checkout_controller.dart:960-1014`

### Step 1: Calculate Distance

**Endpoint:** `GET /maps/api/distancematrix/json`

**Base URL:** `https://maps.googleapis.com`

**Query Parameters:**
```
origins: {originLat},{originLng}
destinations: {destinationLat},{destinationLng}
mode: driving
key: {GoogleMapsAPIKey}
```

**Example:**
```
GET https://maps.googleapis.com/maps/api/distancematrix/json?origins=24.7136,46.6753&destinations=24.7136,46.6753&mode=driving&key=AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8
```

**Response (200 OK):**
```json
{
  "rows": [
    {
      "elements": [
        {
          "distance": {
            "value": 2500,
            "text": "2.5 km"
          },
          "duration": {
            "value": 300,
            "text": "5 mins"
          },
          "status": "OK"
        }
      ]
    }
  ],
  "status": "OK"
}
```

**Code:**
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:55-73`
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:960-995`

**What Happens:**
1. Call Google Maps Distance Matrix API
2. Extract distance in meters
3. Convert to kilometers
4. Store in `checkoutController.distance`
5. Trigger extra charge calculation

### Step 2: Get Extra Charge (Vehicle Charge)

**Endpoint:** `GET /api/v1/config/vehicle-charge?distance={distance}`

**Headers:**
```
Accept: application/json
```

**Request Parameters:**
- `distance`: Distance in kilometers (required)

**Response (200 OK):**
```json
"5.5"
```

**Response (400 Bad Request):**
```json
"0"
```

**Code:**
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:76-83`
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1010-1014`

**What Happens:**
1. Call vehicle charge API with distance
2. Parse response as double
3. Store in `checkoutController.extraCharge`
4. This is a separate fee (NOT added to delivery charge)

---

## Fee Calculations

### Location: `lib/features/checkout/screens/checkout_screen.dart:1926-2358`

### Step 1: Calculate Items Subtotal

**Formula:**
```dart
double itemsSubTotal = 0;
for (var cartModel in cartList) {
  if (cartModel != null && cartModel.item != null) {
    itemsSubTotal += cartModel.price! * cartModel.quantity!;
  }
}
```

**What It Includes:**
- Item prices (after discounts)
- Item quantities
- **Does NOT include:** Tax, delivery, add-ons, app fees

**Code:** `lib/features/checkout/screens/checkout_screen.dart:2116-2134`

### Step 2: Calculate Add-ons Price

**Formula:**
```dart
double addOns = 0;
for (var cartModel in cartList) {
  for (var addOnId in cartModel.addOnIds!) {
    for (var addOn in cartModel.item!.addOns!) {
      if (addOns.id == addOnId.id) {
        addOns += addOn.price! * addOnId.quantity!;
      }
    }
  }
}
```

**Code:** `lib/features/checkout/screens/checkout_screen.dart:1970-1991`

### Step 3: Calculate Tax

**Formula:**
```dart
double tax = 0;
if (taxIncluded) {
  // Tax is included in prices
  tax = orderAmount * taxPercent / (100 + taxPercent);
} else {
  // Tax is added on top
  tax = orderAmount * taxPercent / 100;
}
```

**Parameters:**
- `taxIncluded`: Whether tax is included in item prices (from store config)
- `taxPercent`: Tax percentage (from store config)
- `orderAmount`: Subtotal (items + add-ons)

**Code:** `lib/features/checkout/screens/checkout_screen.dart:2102-2113`

### Step 4: Calculate Delivery Charge

**Formula:**
```dart
double deliveryCharge = 0;

// Check for tiered pricing (first X km = fixed fee)
if (firstKmFee != null && firstKmFee > 0 && 
    firstKmDistance != null && firstKmDistance > 0) {
  if (distance <= firstKmDistance) {
    deliveryCharge = firstKmFee;
  } else {
    deliveryCharge = distance * perKmCharge;
  }
  
  // Apply maximum charge limit
  if (maximumCharge != null && maximumCharge > 0 && 
      deliveryCharge > maximumCharge) {
    deliveryCharge = maximumCharge;
  }
} else {
  // Fallback: distance × per km rate with min/max
  deliveryCharge = distance * perKmCharge;
  if (deliveryCharge < minimumCharge) {
    deliveryCharge = minimumCharge;
  }
  if (maximumCharge != null && maximumCharge > 0 && 
      deliveryCharge > maximumCharge) {
    deliveryCharge = maximumCharge;
  }
}

// Free delivery conditions
if (orderType == 'take_away' ||
    store.freeDelivery ||
    orderAmount >= config.freeDeliveryOver ||
    coupon.freeDelivery) {
  deliveryCharge = 0;
}
```

**Charge Sources (Priority):**
1. **Self-Delivery:** Use `store.perKmShippingCharge`, `store.minimumShippingCharge`, `store.maximumShippingCharge`
2. **Module-Based:** Use `moduleData.pivot.perKmShippingCharge`, `moduleData.pivot.minimumShippingCharge`, `moduleData.pivot.maximumShippingCharge`

**Code:** `lib/features/checkout/screens/checkout_screen.dart:2136-2332`

### Step 5: Calculate Additional Charge (App Fee)

**Formula:**
```dart
double additionalCharge = 0;
if (config.additionalChargeStatus == 1) {
  additionalCharge = config.additionCharge ?? 0;
}
```

**Source:**
- From `SplashController.configModel.additionCharge`
- Only added if `additionalChargeStatus == 1`

**Code:** `lib/features/checkout/screens/checkout_screen.dart:525-542`

### Step 6: Calculate Total

**Formula:**
```dart
double total = itemsSubTotal +
    deliveryCharge -
    discount -
    couponDiscount +
    (taxIncluded ? 0 : tax) +  // Add tax only if not included
    additionalCharge +
    (orderType != 'take_away' && config.dmTipsStatus == 1 ? tips : 0) +
    extraPackagingCharge;
```

**Components:**
- Items Subtotal (items + add-ons)
- + Delivery Charge
- - Discount (item discounts)
- - Coupon Discount
- + Tax (if not included in prices)
- + Additional Charge (app fee)
- + DM Tips (if delivery and tips enabled)
- + Extra Packaging Charge

**Code:** `lib/features/checkout/screens/checkout_screen.dart:2334-2358`

---

## Order Creation (Unpaid)

### Location: `lib/features/checkout/screens/checkout_screen.dart:1760-1773`

### Step 1: Build Place Order Body

**Model:** `PlaceOrderBodyModel`

**Key Fields:**
```dart
PlaceOrderBodyModel(
  cart: carts,  // Array of cart items
  orderAmount: total,  // Calculated total
  paymentMethod: finalPaymentMethod,  // null at this stage
  orderType: determinedOrderType,  // "delivery" | "take_away"
  storeId: storeId,
  distance: distance,
  address: address,
  latitude: latitude,
  longitude: longitude,
  contactPersonName: contactPersonName,
  contactPersonNumber: contactPersonNumber,
  couponCode: couponCode,
  orderNote: orderNote,
  deliveryInstruction: deliveryInstruction,
  dmTips: tips,
  discountAmount: discount,
  taxAmount: tax,
  couponDiscountAmount: couponDiscount,
  extraPackagingAmount: extraPackagingAmount,
  cutlery: cutlery,
  partialPayment: partialPayment,
  guestId: guestId,
  isBuyNow: isBuyNow
)
```

**Code:** `lib/features/checkout/screens/checkout_screen.dart:1660-1757`

### Step 2: Create Order API Call

**Endpoint:** `POST /api/v1/customer/order/place`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
X-localization: ar
moduleId: {module_id}
zoneId: {zone_id}
Authorization: Bearer {token}
latitude: {latitude}
longitude: {longitude}
```

**Request Body:**
```json
{
  "cart": [
    {
      "item_id": 1,
      "model": "Item",
      "price": "22.5",
      "variant": "none",
      "variation": [],
      "quantity": 2,
      "add_on_ids": [1, 2],
      "add_on_qtys": [1, 2],
      "store_id": 18
    }
  ],
  "order_type": "delivery",
  "store_id": 18,
  "order_amount": 50.0,
  "payment_method": null,  // Will be set during payment processing
  "distance": 2.5,
  "address": "123 Main Street, Riyadh",
  "latitude": "24.7136",
  "longitude": "46.6753",
  "contact_person_name": "John Doe",
  "contact_person_number": "+966501234567",
  "coupon_code": "SAVE10",
  "order_note": "Please call before delivery",
  "delivery_instruction": "Leave at door",
  "dm_tips": "5",
  "discount_amount": 5.0,
  "tax_amount": 5.0,
  "coupon_discount_amount": 10.0,
  "extra_packaging_amount": 2.0,
  "cutlery": 1,
  "partial_payment": 0,
  "guest_id": 0,
  "is_buy_now": 0
}
```

**Response (200 OK):**
```json
{
  "order_id": "12345",
  "user_id": "456",
  "total_ammount": 50.0,
  "status": "pending"
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Validation failed",
  "errors": {
    "cart": ["Cart is empty"],
    "address": ["Address is required"]
  }
}
```

**Code:**
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:86-158`
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1069-1151`

**What Happens:**
1. Order is created with status "pending" (unpaid)
2. `order_id` is returned and stored
3. Order amount is stored for payment processing
4. Payment method is NOT set yet (will be set during payment)

---

## Payment Processing

### Location: `lib/features/checkout/screens/checkout_screen.dart:1778-1801`

### Overview

After order creation, payment is processed immediately using the selected payment method. The flow is:

1. **Order Created** → `order_id` returned
2. **Payment Processed** → Order status updated to "paid"

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:1154-1455`

---

## Regular Wallet Payment

### Location: `lib/features/checkout/controllers/checkout_controller.dart:1297-1362`

### Step 1: Frontend Validations

**Validations:**
```dart
// 1. User info exists
if (profile_Controller.userInfoModel == null) {
  showCustomSnackBar("معلومات المستخدم غير متاحة");
  return "";
}

// 2. Balance check
double availableBalance = double.tryParse(
  profile_Controller.userInfoModel?.walletBalance?.toString() ?? '0'
) ?? 0.0;

if (availableBalance < parsedOrderAmount) {
  showCustomSnackBar(
    "الرصيد غير كافي في المحفظة العادية. الرصيد المتاح: ${availableBalance.toStringAsFixed(2)} ريال"
  );
  return "";
}
```

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:1301-1321`

### Step 2: Process Payment API Call

**Endpoint:** `POST /api/v1/customer/order/process-payment`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Accept-Language: ar
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "order_id": 12345,
  "payment_method": "wallet",
  "amount": 50.0
}
```

**Response (200 OK):**
```json
{
  "message": "Payment processed successfully",
  "order_id": 12345,
  "status": "confirmed",
  "wallet_balance": 50.0
}
```

**Response (400 Bad Request - Insufficient Balance):**
```json
{
  "message": "Insufficient balance in wallet",
  "errors": {
    "balance": ["Available balance: 30.0 SAR, Required: 50.0 SAR"]
  }
}
```

**Code:**
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:227-261`
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1324-1354`

### Step 3: Refresh Wallet Balance

**Function:** `profile_Controller.getUserInfo()`

**Endpoint:** `GET /api/v1/customer/info`

**What Happens:**
1. Wallet balance is debited on backend
2. Frontend refreshes user info to get updated balance
3. UI is updated with new balance

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:1333`

---

## Qidha Wallet Payment

### Location: `lib/features/checkout/controllers/checkout_controller.dart:1197-1296`

### Step 1: Frontend Validations

**Validations:**
```dart
// 1. Wallet exists
if (kaidhaSubController.walletKaidhaModel?.wallet == null) {
  showCustomSnackBar("محفظة قيدها غير متاحة - يرجى المحاولة لاحقًا");
  return "";
}

// 2. Wallet status check
if (wallet.status?.toLowerCase() != 'active') {
  showCustomSnackBar("محفظة قيدها غير نشطة - يرجى تفعيلها أولاً");
  return "";
}

// 3. Signature status check
if (wallet.signatureStatus != 1) {
  showCustomSnackBar("محفظة قيدها غير مفعلة - يرجى إكمال التحقق من الهوية");
  return "";
}

// 4. Balance check
double availableBalance = double.tryParse(
  wallet.availableBalance?.toString() ?? '0'
) ?? 0.0;

if (availableBalance < parsedOrderAmount) {
  showCustomSnackBar(
    "الرصيد غير كافي في محفظة قيدها. الرصيد المتاح: ${availableBalance.toStringAsFixed(2)} ريال"
  );
  return "";
}

// 5. Purchase limit check
double purchaseLimit = double.tryParse(
  wallet.purchaseLimit?.toString() ?? '0'
) ?? 0.0;

if (purchaseLimit > 0 && parsedOrderAmount > purchaseLimit) {
  showCustomSnackBar(
    "تجاوز حد الشراء المسموح. الحد الأقصى: ${purchaseLimit.toStringAsFixed(2)} ريال"
  );
  return "";
}
```

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:1202-1255`

### Step 2: Process Payment API Call

**Endpoint:** `POST /api/v1/customer/order/process-payment`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Accept-Language: ar
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "order_id": 12345,
  "payment_method": "wallet_qidha",
  "amount": 50.0
}
```

**Response (200 OK):**
```json
{
  "message": "Payment processed successfully",
  "order_id": 12345,
  "status": "confirmed",
  "wallet_balance": 4950.0
}
```

**Response (400 Bad Request - Insufficient Balance):**
```json
{
  "message": "Insufficient balance in Qidha wallet",
  "errors": {
    "balance": ["Available balance: 30.0 SAR, Required: 50.0 SAR"]
  }
}
```

**Response (400 Bad Request - Wallet Not Active):**
```json
{
  "message": "Qidha wallet is not active",
  "errors": {
    "wallet_status": ["Wallet must be active to make payments"]
  }
}
```

**Response (400 Bad Request - Purchase Limit Exceeded):**
```json
{
  "message": "Purchase limit exceeded",
  "errors": {
    "purchase_limit": ["Maximum purchase: 40000.0 SAR, Requested: 50000.0 SAR"]
  }
}
```

**Code:**
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:227-261`
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1258-1296`

### Step 3: Refresh Qidha Wallet Balance

**Function:** `kaidhaSubController.get_Wallet_Kaidh()`

**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**What Happens:**
1. Qidha wallet balance is debited on backend
2. Frontend refreshes Qidha wallet to get updated balance
3. UI is updated with new balance

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:1267`

---

## Digital Payment (MyFatoorah)

### Location: `lib/features/checkout/controllers/checkout_controller.dart:1184-1196`

### Step 1: Initialize MyFatoorah SDK

**Function:** `checkoutController.initiate(context)`

**What It Does:**
```dart
await MFSDK.init(
  token,  // MyFatoorah token (test or live)
  MFCountry.SAUDIARABIA,
  environment  // TEST or LIVE
);
```

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:206-227`

### Step 2: Initiate Payment

**Function:** `checkoutController.initiatePaymentWithAmount(context, amount)`

**MyFatoorah SDK Call:**
```dart
var request = MFInitiatePaymentRequest(
  invoiceAmount: parsedAmount,  // Order amount
  currencyIso: MFCurrencyISO.SAUDIARABIA_SAR,
);

var response = await MFSDK.initiatePayment(request, MFLanguage.ARABIC);
paymentMethods = response.paymentMethods ?? [];
```

**Response:**
- Returns list of available payment methods:
  - Mada
  - STC Pay
  - Visa
  - Mastercard
  - Apple Pay
  - Google Pay
  - etc.

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:247-300`

### Step 3: User Selects Payment Method

**What Happens:**
- User sees list of payment methods
- User selects one (e.g., Visa, Mada, Apple Pay)
- Payment method ID is stored

**Code:** `lib/features/checkout/widgets/in_app_payment_modal.dart`

### Step 4: Execute Payment

**Function:** `checkoutController.Pay(context, amount)`

**MyFatoorah SDK Call:**
```dart
await MFSDK.executePayment(
  MFExecutePaymentRequest(
    paymentMethodId: selectedPaymentMethodId,
    invoiceValue: amount,
  ),
  MFLanguage.ARABIC,
  (invoiceId) {
    // Payment successful callback
    // invoiceId contains the MyFatoorah invoice ID
    _lastInvoiceId = invoiceId;
    return true;
  },
);
```

**What Happens:**
1. MyFatoorah payment portal opens
2. User completes payment (card details, authentication, etc.)
3. Payment is processed by MyFatoorah
4. Callback is triggered with `invoiceId` on success
5. Returns `true` if payment successful, `false` otherwise

**Code:** `lib/features/checkout/controllers/checkout_controller.dart:381-473`

### Step 5: Process Payment on Backend

**Endpoint:** `POST /api/v1/customer/order/process-payment`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Accept-Language: ar
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "order_id": 12345,
  "payment_method": "digital_payment",
  "amount": 50.0
}
```

**Response (200 OK):**
```json
{
  "message": "Payment processed successfully",
  "order_id": 12345,
  "status": "confirmed",
  "invoice_id": "INV-2024-001"
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Payment processing failed",
  "errors": {
    "payment": ["Payment gateway error"]
  }
}
```

**Code:**
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:227-261`
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1184-1196`

**What Happens:**
1. Backend verifies payment with MyFatoorah using `invoiceId`
2. Backend updates order status to "paid"
3. Order is confirmed

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────┐
│ User Clicks "Proceed to Checkout"      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 1. Validate Minimum Order              │
│ 2. Validate Location (Zone Check)     │
│ 3. Pre-calculate Distance              │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Navigate to Checkout Screen            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Checkout Screen Initialization:        │
│ - Get User Info (if logged in)         │
│ - Get Coupon List                      │
│ - Get Address List                     │
│ - Get Qidha Wallet Status             │
│ - Initialize Checkout Data             │
│ - Calculate Distance (if needed)       │
│ - Get Extra Charge                     │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Fee Calculations:                      │
│ - Items Subtotal                        │
│ - Add-ons Price                        │
│ - Tax                                   │
│ - Delivery Charge                       │
│ - Additional Charge (App Fee)          │
│ - Total                                 │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ User Reviews & Selects Payment Method  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Step 1: Create Order (Unpaid)          │
│ POST /api/v1/customer/order/place     │
│ Returns: order_id                      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Step 2: Process Payment                │
│ Based on Selected Method:              │
└─────────────────────────────────────────┘
                  ↓
    ┌─────────────┴─────────────┐
    ↓             ↓             ↓
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Regular │  │ Qidha   │  │ Digital │
│ Wallet  │  │ Wallet  │  │ Payment │
└─────────┘  └─────────┘  └─────────┘
    ↓             ↓             ↓
┌─────────────────────────────────────────┐
│ POST /api/v1/customer/order/          │
│       process-payment                  │
│ payment_method: "wallet" |             │
│              "wallet_qidha" |          │
│              "digital_payment"         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Order Status Updated to "paid"         │
│ Refresh Wallet Balance (if applicable) │
│ Show Success Message                   │
└─────────────────────────────────────────┘
```

---

## API Endpoints Summary

### Checkout Flow Endpoints

1. **Get User Info:** `GET /api/v1/customer/info`
2. **Get Coupon List:** `GET /api/v1/customer/coupon/list`
3. **Get Address List:** `GET /api/v1/customer/address/list`
4. **Get Qidha Wallet:** `GET /api/qidha-wallet/get-wallet`
5. **Get Zone:** `GET /api/v1/config/get-zone-id?lat={lat}&lng={lng}`
6. **Get Distance:** `GET /maps/api/distancematrix/json` (Google Maps)
7. **Get Extra Charge:** `GET /api/v1/config/vehicle-charge?distance={distance}`
8. **Place Order:** `POST /api/v1/customer/order/place`
9. **Process Payment:** `POST /api/v1/customer/order/process-payment`

### Payment Method Values

- `"wallet"` - Regular wallet payment
- `"wallet_qidha"` - Qidha wallet payment
- `"digital_payment"` - Digital payment (MyFatoorah)

---

## Code File References

### Checkout Flow
- Cart Screen: `lib/features/cart/screens/cart_screen.dart`
- Checkout Screen: `lib/features/checkout/screens/checkout_screen.dart`
- Checkout Controller: `lib/features/checkout/controllers/checkout_controller.dart`
- Checkout Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart`
- Place Order Model: `lib/features/checkout/domain/models/place_order_body_model.dart`

### Location & Zone
- Location Controller: `lib/features/location/controllers/location_controller.dart`
- Location Repository: `lib/features/location/domain/repositories/location_repository.dart`

### Payment
- MyFatoorah Integration: `lib/features/checkout/controllers/checkout_controller.dart:206-473`
- Payment Modal: `lib/features/checkout/widgets/in_app_payment_modal.dart`

### Wallet
- Qidha Wallet Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart`
- Profile Controller: `lib/features/profile/controllers/profile_controller.dart`

---

## Notes

1. **Order Creation:**
   - Order is created with `payment_method: null` initially
   - Payment method is set during payment processing
   - Order status is "pending" (unpaid) until payment is processed

2. **Distance Calculation:**
   - Uses Google Maps Distance Matrix API
   - Distance is pre-calculated on cart screen to avoid "calculating" state
   - Extra charge (vehicle charge) is calculated separately based on distance

3. **Fee Calculations:**
   - All fees are calculated on frontend before order creation
   - Backend validates and may adjust fees
   - Tax calculation depends on `taxIncluded` flag from store config

4. **Payment Processing:**
   - All three payment methods use the same `/process-payment` endpoint
   - Only the `payment_method` value differs
   - Payment is processed immediately after order creation

5. **Error Handling:**
   - All validations are performed before API calls
   - User-friendly error messages in Arabic
   - Wallet balances are refreshed after successful payments

---

**Last Updated:** 2024-01-01
**Version:** 1.0.0

