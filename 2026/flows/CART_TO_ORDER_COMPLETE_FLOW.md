# Complete Cart to Order Tracking Flow Documentation

## Overview

This document provides a **complete end-to-end technical reference** for the entire user journey from adding items to cart through placing order, paying with all payment methods, and tracking the order until delivery. It covers:

- **Cart Operations**: Add, update, remove, and retrieve cart items (authenticated and guest users)
- **Order Placement**: Creating orders with all validations and fee calculations
- **Payment Processing**: All three payment methods (Digital Payment, Qidha Wallet, Regular Wallet)
- **Order Tracking**: Real-time order status tracking with maps, delivery man location, and status updates
- **Data Flow**: Complete data passed between pages, screens, and API calls
- **All Endpoints**: Every API endpoint called in the complete flow
- **Error Handling**: All error cases and validation flows

---

## Table of Contents

1. [Cart Operations](#cart-operations)
   - [Add Item to Cart](#1-add-item-to-cart)
   - [Update Cart Item](#2-update-cart-item)
   - [Remove Cart Item](#3-remove-cart-item)
   - [Get Cart List](#4-get-cart-list)
   - [Guest Cart Operations](#guest-cart-operations)
2. [Order Placement](#order-placement)
   - [Pre-Checkout Validations](#pre-checkout-validations)
   - [Checkout Screen Initialization](#checkout-screen-initialization)
   - [Fee Calculations](#fee-calculations)
   - [Create Order (Unpaid)](#create-order-step-1)
3. [Payment Processing](#payment-processing)
   - [Digital Payment (MyFatoorah)](#digital-payment-myfatoorah)
   - [Qidha Wallet Payment](#qidha-wallet-payment)
   - [Regular Wallet Payment](#regular-wallet-payment)
   - [Payment Success Navigation](#payment-success-navigation)
4. [Order Tracking](#order-tracking)
   - [Track Order API](#track-order-api)
   - [Order Status Flow](#order-status-flow)
   - [Tracking Screens](#tracking-screens)
   - [Real-Time Updates](#real-time-updates)
   - [Delivery Man Tracking](#delivery-man-tracking)
   - [Guest Tracking](#guest-tracking)
5. [Complete Flow Diagrams](#complete-flow-diagrams)
   - [End-to-End Flow](#end-to-end-complete-flow)
   - [Payment Method Flows](#payment-method-flows)
6. [Data Passed Between Pages](#data-passed-between-pages)
7. [Error Handling](#error-handling)
8. [All API Endpoints Summary](#all-api-endpoints-summary)

---

## Cart Operations

### 1. Add Item to Cart

**Endpoint:** `POST /api/v1/customer/cart/add`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
X-localization: ar (or en)
moduleId: {module_id}
zoneId: {zone_id}
Authorization: Bearer {auth_token}
```

**Query Parameters (for guest users):**
- `guest_id`: Guest ID string (if not authenticated)

**Request Body:**
```json
{
  "item_id": 1,
  "quantity": 2,
  "model": "Item",  // Required: "Item" or "ItemCampaign"
  "price": 22.5,    // Required: Get from item details endpoint first
  "variant": "none", // Always "none" (backend expects this field)
  "variation": [],  // Array of variations (optional)
  "add_on_ids": [], // Array of add-on IDs (optional)
  "add_on_qtys": [] // Array of add-on quantities (optional)
}
```

**Variation Format (Food Variations - New Format):**
```json
{
  "variation": [
    {
      "name": "Size",
      "values": [
        {
          "label": "Large",
          "optionPrice": 5.0
        },
        {
          "label": "Medium",
          "optionPrice": 2.0
        }
      ]
    }
  ]
}
```

**Variation Format (Product Variations - Old Format):**
```json
{
  "variation": [
    {
      "type": "Size",
      "price": 5.0
    }
  ]
}
```

**Response (200 OK):**
```json
[
  {
    "id": 123,
    "user_id": 456,
    "module_id": 3,
    "item_id": 1,
    "is_guest": false,
    "add_on_ids": [1, 2],
    "add_on_qtys": [1, 2],
    "item_type": "item",
    "price": 22.5,
    "quantity": 2,
    "variation": [],
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z",
    "item": {
      "id": 1,
      "name": "Item Name",
      "price": 22.5,
      ...
    }
  }
]
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:51-69`
- Controller: `lib/features/cart/controllers/cart_controller.dart:527-569`
- Model: `lib/features/checkout/domain/models/place_order_body_model.dart:365-504`

---

### 2. Update Cart Item

**Endpoint:** `POST /api/v1/customer/cart/update`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
X-localization: ar
moduleId: {module_id}
zoneId: {zone_id}
Authorization: Bearer {auth_token}
```

**Query Parameters (for guest users):**
- `guest_id`: Guest ID string (if not authenticated)

**Request Body:**
```json
{
  "cart_id": 123,
  "quantity": 3,
  "price": 22.5
}
```

**Response (200 OK):**
```json
[
  {
    "id": 123,
    "quantity": 3,
    "price": 22.5,
    ...
  }
]
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:190-216`

---

### 3. Remove Cart Item

**Endpoint:** `DELETE /api/v1/customer/cart/remove-item`

**Headers:**
```
Accept: application/json
X-localization: ar
moduleId: {module_id}
zoneId: {zone_id}
Authorization: Bearer {auth_token}
```

**Query Parameters:**
- `cart_id`: Cart item ID (integer, required)
- `guest_id`: Guest ID string (if not authenticated, optional)

**Response:**
- `200 OK`: Item removed successfully
- `404 Not Found`: Item already doesn't exist (treated as success)

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:80-87`

---

### 4. Get Cart List

**Endpoint:** `GET /api/v1/customer/cart/list`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
X-localization: ar
moduleId: {module_id}
zoneId: {zone_id}
Authorization: Bearer {auth_token}
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
X-Requested-With: XMLHttpRequest
```

**Query Parameters (for guest users):**
- `guest_id`: Guest ID string (if not authenticated)

**Response (200 OK):**
```json
[
  {
    "id": 123,
    "user_id": 456,
    "module_id": 3,
    "item_id": 1,
    "is_guest": false,
    "add_on_ids": [1, 2],
    "add_on_qtys": [1, 2],
    "item_type": "item",
    "price": 22.5,
    "quantity": 2,
    "variation": [],
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z",
    "item": {
      "id": 1,
      "name": "Item Name",
      "price": 22.5,
      ...
    }
  }
]
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:105-164`

---

## Order Placement

### Create Order (Step 1)

**Endpoint:** `POST /api/v1/customer/order/place`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
X-localization: ar
moduleId: {module_id}
zoneId: {zone_id}
Authorization: Bearer {auth_token}
latitude: {latitude}  // Optional but recommended
longitude: {longitude} // Optional but recommended
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
  "order_type": "delivery",  // "delivery" | "take_away" | "parcel"
  "store_id": 18,
  "order_amount": 50.0,
  "payment_method": "cash_on_delivery",  // Will be changed during payment processing
  "distance": 2.5,
  "address": "123 Main Street, Riyadh",
  "latitude": "24.7136",
  "longitude": "46.6753",
  "contact_person_name": "John Doe",
  "contact_person_number": "+966501234567",
  "coupon_code": "",
  "order_note": "",
  "delivery_instruction": "",
  "dm_tips": "0",
  "discount_amount": 0.0,
  "tax_amount": 5.0,
  "coupon_discount_amount": 0.0,
  "cutlery": 0,
  "partial_payment": 0,
  "guest_id": 0,
  "is_buy_now": 0,
  "extra_packaging_amount": 0.0,
  "create_new_user": 0,
  "road": "",
  "house": "",
  "floor": "",
  "unavailable_item_note": "",
  "schedule_at": null
}
```

**Required Fields:**
- `cart`: Array with at least 1 item (required)
- `order_type`: "delivery" | "take_away" | "parcel" (required)
- `store_id`: Store ID (required, unless order_type is "parcel")
- `order_amount`: Total order amount (required)
- `payment_method`: Payment method string (required, but will be processed separately)
- `distance`: Distance in km (required for delivery)
- `address`: Delivery address (required for delivery)
- `latitude`: Latitude (required for delivery)
- `longitude`: Longitude (required for delivery)
- `contact_person_name`: Contact name (required)
- `contact_person_number`: Contact phone (required)

**Response (200 OK):**
```json
{
  "order_id": "12345",
  "user_id": "456",
  "total_ammount": 50.0,
  "status": "pending",
  "message": "Order placed successfully"
}
```

**Code Reference:**
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:86-158`
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1069-1151`
- Model: `lib/features/checkout/domain/models/place_order_body_model.dart`

---

## Payment Processing

### Overview

After creating an order (unpaid status), the payment is processed separately using the `/api/v1/customer/order/process-payment` endpoint. The flow follows this pattern:

1. **Create Order** → Returns `order_id` with status "unpaid"
2. **Process Payment** → Updates order status to "paid" based on payment method

---

### Digital Payment (MyFatoorah)

#### Step 1: Initialize Payment Methods

**MyFatoorah SDK Call:**
```dart
await MFSDK.initiatePayment(
  MFInitiatePaymentRequest(
    invoiceAmount: amount,
    currencyIso: MFCurrencyISO.SAUDIARABIA_SAR,
  ),
  MFLanguage.ARABIC,
);
```

**Response:**
- Returns list of available payment methods (Mada, STC Pay, Visa, Mastercard, Apple Pay, etc.)

#### Step 2: Execute Payment

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
  },
);
```

#### Step 3: Process Payment on Backend

**Endpoint:** `POST /api/v1/customer/order/process-payment`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Accept-Language: ar
Authorization: Bearer {auth_token}
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
  "status": "confirmed"
}
```

**Code Reference:**
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:381-473`
- Payment Processing: `lib/features/checkout/controllers/checkout_controller.dart:1184-1196`
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:227-261`

**Flow:**
1. User selects digital payment method
2. MyFatoorah SDK initializes payment methods
3. User selects specific payment method (Mada, STC Pay, etc.)
4. MyFatoorah SDK executes payment (opens payment portal)
5. User completes payment in MyFatoorah portal
6. MyFatoorah returns invoice ID via callback
7. App calls `/api/v1/customer/order/process-payment` with `payment_method: "digital_payment"`
8. Backend updates order status to "paid"

---

### Qidha Wallet Payment

#### Pre-requisites

Before processing Qidha wallet payment, the following validations are performed:

1. **Wallet Exists Check:**
   - `walletKaidhaModel?.wallet != null`

2. **Wallet Status Check:**
   - `wallet.status.toLowerCase() == 'active'`

3. **Signature Status Check:**
   - `wallet.signatureStatus == 1` (Identity verification completed)

4. **Balance Check:**
   - `availableBalance >= orderAmount`

5. **Purchase Limit Check:**
   - If `purchaseLimit > 0`, then `orderAmount <= purchaseLimit`

#### Process Payment

**Endpoint:** `POST /api/v1/customer/order/process-payment`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Accept-Language: ar
Authorization: Bearer {auth_token}
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
  "wallet_balance": 450.0
}
```

**Response (400/422 - Insufficient Balance):**
```json
{
  "message": "Insufficient balance in Qidha wallet",
  "errors": {
    "balance": ["Available balance: 30.0 SAR, Required: 50.0 SAR"]
  }
}
```

**Response (400/422 - Wallet Not Active):**
```json
{
  "message": "Qidha wallet is not active",
  "errors": {
    "wallet_status": ["Wallet must be active to make payments"]
  }
}
```

**Code Reference:**
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1197-1296`
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:227-261`
- Qidha Wallet Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart`

**Flow:**
1. User selects Qidha wallet payment method
2. Frontend validates wallet status, signature status, balance, and purchase limit
3. If validation passes, call `/api/v1/customer/order/process-payment` with `payment_method: "wallet_qidha"`
4. Backend debits Qidha wallet balance
5. Backend updates order status to "paid"
6. Frontend refreshes Qidha wallet balance via `get_Wallet_Kaidh()`

**Validation Errors (Frontend):**
- "محفظة قيدها غير متاحة - يرجى المحاولة لاحقًا" (Wallet not available)
- "محفظة قيدها غير نشطة - يرجى تفعيلها أولاً" (Wallet not active)
- "محفظة قيدها غير مفعلة - يرجى إكمال التحقق من الهوية" (Identity verification incomplete)
- "الرصيد غير كافي في محفظة قيدها. الرصيد المتاح: {balance} ريال" (Insufficient balance)
- "تجاوز حد الشراء المسموح. الحد الأقصى: {limit} ريال" (Purchase limit exceeded)

---

### Regular Wallet Payment

#### Pre-requisites

Before processing regular wallet payment, the following validations are performed:

1. **User Info Check:**
   - `userInfoModel != null`

2. **Balance Check:**
   - `walletBalance >= orderAmount`

#### Process Payment

**Endpoint:** `POST /api/v1/customer/order/process-payment`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Accept-Language: ar
Authorization: Bearer {auth_token}
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
  "wallet_balance": 450.0
}
```

**Response (400/422 - Insufficient Balance):**
```json
{
  "message": "Insufficient wallet balance",
  "errors": {
    "balance": ["Available balance: 30.0 SAR, Required: 50.0 SAR"]
  }
}
```

**Code Reference:**
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1297-1362`
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:227-261`
- Profile Controller: `lib/features/profile/controllers/profile_controller.dart`

**Flow:**
1. User selects regular wallet payment method
2. Frontend validates user info and wallet balance
3. If validation passes, call `/api/v1/customer/order/process-payment` with `payment_method: "wallet"`
4. Backend debits regular wallet balance
5. Backend updates order status to "paid"
6. Frontend refreshes user info via `getUserInfo()` to get updated wallet balance

**Validation Errors (Frontend):**
- "معلومات المستخدم غير متاحة - يرجى تسجيل الدخول مرة أخرى" (User info not available)
- "الرصيد غير كافي في المحفظة العادية. الرصيد المتاح: {balance} ريال" (Insufficient balance)

---

## Order Tracking

### Overview

After successful payment, users can track their order in real-time. The tracking system provides:

- Order status updates (pending → accepted → confirmed → processing → handover/picked_up → delivered)
- Delivery man location tracking (for delivery orders)
- Google Maps integration showing store, delivery address, and delivery man location
- Real-time auto-refresh every 10 seconds
- Chat functionality with store/delivery man (based on permissions)
- Guest tracking (without authentication)

---

### Track Order API

**Endpoint:** `GET /api/v1/customer/order/track`

**Headers:**
```
Accept: application/json
X-localization: ar (or en)
Authorization: Bearer {auth_token}  // Optional for guest users
```

**Query Parameters:**
- `order_id`: Order ID (integer, required)
- `guest_id`: Guest ID (string, optional - for guest users)
- `contact_number`: Contact phone number (string, optional - for guest tracking)

**URL Examples:**
```
// Authenticated user
GET /api/v1/customer/order/track?order_id=12345

// Guest user with guest_id
GET /api/v1/customer/order/track?order_id=12345&guest_id=abc123

// Guest user with contact number
GET /api/v1/customer/order/track?order_id=12345&contact_number=+966501234567
```

**Response (200 OK):**
```json
{
  "id": 12345,
  "user_id": 456,
  "order_amount": 50.0,
  "coupon_discount_amount": 0.0,
  "coupon_discount_title": null,
  "payment_status": "paid",
  "order_status": "processing",
  "total_tax_amount": 5.0,
  "payment_method": "wallet_qidha",
  "coupon_code": null,
  "order_note": "Please deliver quickly",
  "order_type": "delivery",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:30:00Z",
  "delivery_charge": 10.0,
  "original_delivery_charge": 10.0,
  "schedule_at": null,
  "otp": "1234",
  "pending": "2024-01-01T12:00:00Z",
  "accepted": "2024-01-01T12:05:00Z",
  "confirmed": "2024-01-01T12:05:00Z",
  "processing": "2024-01-01T12:10:00Z",
  "handover": null,
  "picked_up": null,
  "delivered": null,
  "canceled": null,
  "refund_requested": null,
  "refunded": null,
  "scheduled": 0,
  "store_discount_amount": 0.0,
  "failed": null,
  "details_count": 2,
  "charge_payer": "sender",
  "module_type": "food",
  "delivery_man": {
    "id": 789,
    "f_name": "Ahmed",
    "l_name": "Ali",
    "phone": "+966501234567",
    "email": "ahmed@example.com",
    "image": "https://example.com/delivery-man.jpg",
    "latitude": "24.7136",
    "longitude": "46.6753",
    "location": "Riyadh, Saudi Arabia",
    "zone_id": 1
  },
  "store": {
    "id": 18,
    "name": "Restaurant Name",
    "phone": "+966501234567",
    "email": "restaurant@example.com",
    "logo": "https://example.com/logo.jpg",
    "latitude": "24.7136",
    "longitude": "46.6753",
    "address": "Store Address",
    "store_business_model": "commission",
    "store_subscription": {
      "chat": 1
    }
  },
  "delivery_address": {
    "id": 123,
    "address": "123 Main Street",
    "latitude": "24.7136",
    "longitude": "46.6753",
    "address_type": "home",
    "contact_person_name": "John Doe",
    "contact_person_number": "+966501234567"
  },
  "receiver_details": null,
  "parcel_category": null,
  "dm_tips": 5.0,
  "refund_cancellation_note": null,
  "refund_customer_note": null,
  "refund": null,
  "prescription_order": false,
  "tax_status": true,
  "cancellation_reason": null,
  "processing_time": 30,
  "cutlery": true,
  "unavailable_item_note": null,
  "delivery_instruction": "Ring the doorbell",
  "tax_percentage": 15.0,
  "additional_charge": 0.0,
  "deliveryfee_tax": 1.5,
  "partially_paid_amount": 0.0,
  "payments": [],
  "order_proof_full_url": [],
  "offline_payment": null,
  "flash_admin_discount_amount": 0.0,
  "flash_store_discount_amount": 0.0,
  "extra_packaging_amount": 0.0,
  "referrer_bonus_amount": 0.0,
  "order_attachment_full_url": []
}
```

**Code Reference:**
- Repository: `lib/features/order/domain/repositories/order_repository.dart:33-38`
- Service: `lib/features/order/domain/services/order_service.dart`
- Controller: `lib/features/order/controllers/order_controller.dart:342-380`
- Constants: `lib/util/app_constants.dart:97`

---

### Order Status Flow

**Order Status Values:**

The order progresses through the following statuses:

1. **`pending`** - Order placed, waiting for store confirmation
2. **`accepted`** - Store accepted the order
3. **`confirmed`** - Order confirmed by store
4. **`processing`** - Store is preparing the order
5. **`handover`** - Order ready for pickup/delivery (for take_away orders)
6. **`picked_up`** - Delivery man picked up the order (for delivery orders)
7. **`delivered`** - Order delivered to customer
8. **`canceled`** - Order canceled
9. **`refund_requested`** - Refund requested
10. **`refunded`** - Refund processed
11. **`failed`** - Order failed

**Status Timestamps:**

Each status change is recorded with a timestamp:
- `pending`: When order is placed
- `accepted`: When store accepts order
- `confirmed`: When order is confirmed
- `processing`: When store starts preparing
- `handover`: When order is ready for handover
- `picked_up`: When delivery man picks up order
- `delivered`: When order is delivered
- `canceled`: When order is canceled

**Status Flow Diagram:**

```
┌──────────┐
│  pending │  ← Order placed
└────┬─────┘
     │
     ▼
┌──────────┐
│ accepted │  ← Store accepts
└────┬─────┘
     │
     ▼
┌──────────┐
│confirmed │  ← Order confirmed
└────┬─────┘
     │
     ▼
┌──────────┐
│processing│  ← Store preparing
└────┬─────┘
     │
     ├─────────────────┐
     │                 │
     ▼                 ▼
┌──────────┐    ┌──────────┐
│ handover │    │picked_up│  ← Ready/Taken
│(takeaway)│    │(delivery)│
└────┬─────┘    └────┬─────┘
     │                │
     │                │
     └────────┬───────┘
              │
              ▼
        ┌──────────┐
        │delivered │  ← Order completed
        └──────────┘
```

**Code Reference:**
- Constants: `lib/util/app_constants.dart:459-465`
- Tracking Stepper: `lib/features/order/widgets/tracking_stepper_widget.dart:14-26`

---

### Tracking Screens

#### 1. Order Tracking Screen (Authenticated Users)

**Route:** `/track-order`

**Navigation:**
```dart
Get.toNamed(
  RouteHelper.getTrackOrderRoute(orderID.toString()),
  arguments: {
    'orderID': orderID.toString(),
    'contactNumber': contactNumber, // Optional
  },
);
```

**File:** `lib/features/order/screens/order_tracking_screen.dart`

**Parameters:**
- `orderID`: Order ID (string, required)
- `contactNumber`: Contact phone number (string, optional)

**Features:**
- Real-time order status tracking
- Google Maps integration for delivery tracking
- Delivery man location tracking
- Order status stepper (5 states)
- Chat functionality (if enabled)
- Auto-refresh every 10 seconds
- Store contact information
- Delivery man contact information

**Initialization:**
```dart
@override
void initState() {
  super.initState();
  Get.find<OrderController>().timerTrackOrder(
    widget.orderID.toString(),
    contactNumber: widget.contactNumber,
  );
}
```

**Code Reference:**
- Screen: `lib/features/order/screens/order_tracking_screen.dart`
- Route: `lib/helper/route_helper.dart:361-362`

#### 2. Guest Track Order Screen

**Route:** `/guest-track-order-screen`

**Navigation:**
```dart
Get.toNamed(
  RouteHelper.getGuestTrackOrderRoute(),
  arguments: {
    'order_id': orderID.toString(),
    'number': contactNumber,
  },
);
```

**File:** `lib/features/order/screens/guest_track_order_screen.dart`

**Parameters:**
- `order_id`: Order ID (string, required)
- `number`: Contact phone number (string, required)

**Features:**
- Guest order tracking without authentication
- Order status stepper
- Delivery man contact (if available)
- View order details button
- No real-time map tracking (limited functionality)

**Code Reference:**
- Screen: `lib/features/order/screens/guest_track_order_screen.dart`
- Route: `lib/helper/route_helper.dart:493-494`

#### 3. Guest Track Order Input Screen

**Route:** `/order`

**File:** `lib/features/order/widgets/guest_track_order_input_view_widget.dart`

**Features:**
- Input form for order ID and contact number
- Supports both order and trip tracking
- Validates input before tracking
- Navigates to guest tracking screen on submit

**Code Reference:**
- Widget: `lib/features/order/widgets/guest_track_order_input_view_widget.dart`

---

### Real-Time Updates

**Auto-Refresh Mechanism:**

The tracking screen automatically refreshes order status every 10 seconds using a `Timer`.

**Implementation:**
```dart
Timer.periodic(const Duration(seconds: 10), (timer) {
  Get.find<OrderController>().timerTrackOrder(
    orderID.toString(),
    contactNumber: contactNumber
  );
});
```

**What Happens:**
1. Timer triggers every 10 seconds
2. Calls `timerTrackOrder()` method
3. Fetches latest order status from API
4. Updates UI if status changed
5. Updates delivery man location on map (if available)
6. Timer is canceled when screen is disposed

**Code Reference:**
- Order Tracking Screen: `lib/features/order/screens/order_tracking_screen.dart:91-96`
- Order Details Screen: `lib/features/order/screens/order_details_screen.dart:77-84`
- Controller: `lib/features/order/controllers/order_controller.dart:384-402`

**WebSocket Support (Future):**

The repository includes WebSocket support for real-time order updates:

**WebSocket Connection:**
```dart
Future<Stream?> connectToOrderWebSocket(String userId) async {
  final url = Uri.parse('wss://shalafood.net/order/updates?type=user&id=$userId');
  _channel = WebSocketChannel.connect(url);
  _stream = _channel!.stream.asBroadcastStream();
  return _stream;
}
```

**Code Reference:**
- Repository: `lib/features/order/domain/repositories/order_repository.dart:164-176`

---

### Delivery Man Tracking

**Map Integration:**

The tracking screen displays a Google Map showing:
- **Store location** (marker)
- **Delivery address** (marker)
- **Delivery man location** (marker, if assigned and available)
- **Route between locations** (polyline)

**When Delivery Man Appears:**
- Order status is `picked_up` or `handover`
- Delivery man is assigned to the order
- Delivery man location is available in API response

**Map Widget:**
```dart
TrakingMapWidget(
  deliveryManModel: trackModel?.deliveryMan,
  orderModel: trackModel,
  orderType: trackModel?.orderType,
)
```

**Code Reference:**
- Map Widget: `lib/features/order/widgets/traking_map_widget.dart`
- Order Tracking Screen: `lib/features/order/screens/order_tracking_screen.dart:187-228`

---

### Tracking Stepper Widget

**Tracking Stepper States:**

The tracking stepper displays 5 main states:

1. **Order Placed** (`pending`)
   - Icon: `Images.trackOrderPlace`
   - State: `state = 0`
   - Status: "تم وضع الطلب"

2. **Order Confirmed** (`accepted` or `confirmed`)
   - Icon: `Images.trackOrderAccept`
   - State: `state = 1`
   - Status: "تم تأكيد الطلب"

3. **Preparing Item** (`processing`)
   - Icon: `Images.trackOrderPreparing`
   - State: `state = 2`
   - Status: "جارٍ إعداد الطلب"

4. **On The Way / Ready for Handover**
   - For delivery: "Delivery on the way" (`handover` or `picked_up`)
   - For takeaway: "Ready for handover" (`handover`)
   - Icon: `Images.trackOrderOnTheWay`
   - State: `state = 3`
   - Status: "في الطريق" / "جاهز للاستلام"

5. **Delivered** (`delivered`)
   - Icon: `Images.trackOrderDelivered`
   - State: `state = 4`
   - Status: "تم التسليم"

**State Calculation Logic:**

```dart
int state = -1;
if (status == 'pending') {
  state = 0;
} else if (status == 'accepted' || status == 'confirmed') {
  state = 1;
} else if (status == 'processing') {
  state = 2;
} else if (status == 'handover') {
  state = takeAway ? 3 : 2;
} else if (status == 'picked_up') {
  state = 3;
} else if (status == 'delivered') {
  state = 4;
}
```

**Code Reference:**
- Widget: `lib/features/order/widgets/tracking_stepper_widget.dart`
- Guest Stepper: `lib/features/order/widgets/guest_custom_stepper_widget.dart`

---

### Guest Tracking

**Guest Tracking Flow:**

1. **Input Screen:**
   - User enters order ID and contact number
   - Validates input format
   - Supports guest tracking without authentication

2. **Track Order:**
   - Calls `/api/v1/customer/order/track` with `order_id` and `contact_number`
   - No authentication required
   - Same API endpoint as authenticated users

3. **Display Status:**
   - Shows order status stepper
   - Displays order information
   - Shows delivery man contact (if available)
   - Limited functionality (no real-time map updates)

**Code Reference:**
- Guest Input Widget: `lib/features/order/widgets/guest_track_order_input_view_widget.dart:118-120`
- Guest Tracking Screen: `lib/features/order/screens/guest_track_order_screen.dart:34`

---

### Chat Functionality

**Chat Permission:**

Chat functionality is available based on:
- Order type (not available for parcel orders without login)
- Store business model (commission vs subscription)
- Store subscription settings (if subscription model)

**Permission Logic:**
```dart
if (order.orderType != 'parcel') {
  if (order.store.storeBusinessModel == 'commission') {
    showChatPermission = true;
  } else if (order.store.storeSubscription != null && 
             order.store.storeBusinessModel == 'subscription') {
    showChatPermission = order.store.storeSubscription!.chat == 1;
  } else {
    showChatPermission = false;
  }
} else {
  showChatPermission = AuthHelper.isLoggedIn();
}
```

**Code Reference:**
- Order Tracking Screen: `lib/features/order/screens/order_tracking_screen.dart:129-139`

---

### Order Types in Tracking

**Delivery Orders:**
- Shows delivery address
- Tracks delivery man location
- Displays "Delivery on the way" status
- Shows delivery charge
- Full map tracking with delivery man location

**Take Away Orders:**
- Shows "Ready for handover" status
- No delivery man tracking
- No delivery charge (usually)
- Store location only on map

**Parcel Orders:**
- Similar to delivery orders
- May have different status flow
- Includes parcel category information
- Full tracking capabilities

**Code Reference:**
- Order Model: `lib/features/order/domain/models/order_model.dart:49`
- Tracking Stepper: `lib/features/order/widgets/tracking_stepper_widget.dart:8-9`

---

## Complete Flow Diagrams

### Flow 1: Add to Cart → Place Order → Digital Payment

```
┌─────────────────┐
│  User adds item │
│     to cart     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /cart/add          │
│ Headers: Authorization, │
│         moduleId,       │
│         zoneId          │
│ Body: item_id, quantity,│
│       model, price,     │
│       variation, etc.   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Response: Updated cart   │
│          list            │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ User proceeds to        │
│ checkout                 │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /order/place        │
│ Headers: Authorization, │
│         moduleId,       │
│         zoneId,         │
│         latitude,       │
│         longitude       │
│ Body: cart, order_type, │
│       payment_method,   │
│       address, etc.     │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Response: order_id,      │
│          status: unpaid  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ MyFatoorah SDK:         │
│ initiatePayment()        │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ User selects payment     │
│ method (Mada, STC, etc.)│
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ MyFatoorah SDK:         │
│ executePayment()         │
│ → Opens payment portal  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ User completes payment  │
│ in MyFatoorah portal    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ MyFatoorah callback:     │
│ invoiceId received       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /order/process-     │
│       payment            │
│ Body: order_id,          │
│       payment_method:    │
│       "digital_payment", │
│       amount             │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Response: Order status  │
│          updated to paid │
└─────────────────────────┘
```

---

### Flow 2: Add to Cart → Place Order → Qidha Wallet Payment

```
┌─────────────────┐
│  User adds item │
│     to cart     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /cart/add          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ User proceeds to        │
│ checkout                 │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /order/place        │
│ payment_method:          │
│ "wallet_qidha"           │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Response: order_id,      │
│          status: unpaid  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Frontend Validations:    │
│ 1. Wallet exists?       │
│ 2. Wallet active?       │
│ 3. Signature complete? │
│ 4. Balance sufficient?  │
│ 5. Within purchase limit?│
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /order/process-     │
│       payment            │
│ Body: order_id,          │
│       payment_method:    │
│       "wallet_qidha",    │
│       amount             │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Backend:                 │
│ 1. Debit Qidha wallet    │
│ 2. Update order status  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Response: Order paid    │
│ Frontend: Refresh       │
│          wallet balance │
└─────────────────────────┘
```

---

### Flow 4: End-to-End Complete Flow (Add to Cart → Payment → Tracking)

```
┌─────────────────────────────────────────┐
│ User Adds Item to Cart                 │
│ POST /api/v1/customer/cart/add         │
│ [+guest_id for guests]                 │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ User Views Cart                        │
│ GET /api/v1/customer/cart/list         │
│ [+guest_id for guests]                 │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ User Clicks "Proceed to Checkout"      │
│ Validations:                           │
│ - Minimum order amount                 │
│ - Location/zone validation             │
│ - Login required (if guest)            │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Navigate to Checkout Screen            │
│ Loads:                                 │
│ - User info                            │
│ - Address list                         │
│ - Coupon list                          │
│ - Qidha wallet status                  │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Calculate Fees:                        │
│ - Items subtotal                       │
│ - Add-ons                              │
│ - Tax                                  │
│ - Delivery charge                      │
│ - Additional charge                    │
│ - Total                                │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ User Selects Payment Method &          │
│ Reviews Order Details                  │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Step 1: Create Order (Unpaid)          │
│ POST /api/v1/customer/order/place      │
│ Returns: order_id                      │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Step 2: Process Payment                │
│ Based on Selected Method:              │
└────────┬────────────────────────────────┘
         │
    ┌────┴────┬──────────────┬────────────┐
    │         │              │            │
    ▼         ▼              ▼            ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│ Regular │ │ Qidha   │ │ Digital │ │   COD   │
│ Wallet  │ │ Wallet  │ │ Payment │ │         │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
    │         │              │            │
    └─────────┴──────────────┴────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ POST /api/v1/customer/order/          │
│       process-payment                  │
│ Payment Method: wallet | wallet_qidha |│
│              digital_payment | cod     │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Payment Success                        │
│ - Order status: "paid"                 │
│ - Clear cart                           │
│ - Refresh wallet balance (if wallet)   │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Navigate to Order Success Screen       │
│ Shows:                                 │
│ - Order ID                             │
│ - Order summary                        │
│ - "Track Order" button                 │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ User Clicks "Track Order"              │
│ Navigate to Order Tracking Screen      │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ GET /api/v1/customer/order/track       │
│ ?order_id={id}                         │
│ [+guest_id or contact_number for guest]│
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Display Order Tracking:                │
│ - Status stepper (5 states)            │
│ - Google Maps (store, address, DM)     │
│ - Delivery man info (if assigned)      │
│ - Store contact                        │
│ - Chat button (if enabled)             │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Start Auto-Refresh Timer               │
│ (Every 10 seconds)                     │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Order Status Updates:                  │
│ pending → accepted → confirmed →       │
│ processing → handover/picked_up →      │
│ delivered                              │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Order Delivered                        │
│ - Show delivery confirmation           │
│ - Order complete                       │
│ - Rate order option                    │
└─────────────────────────────────────────┘
```

---

### Flow 3: Add to Cart → Place Order → Regular Wallet Payment

```
┌─────────────────┐
│  User adds item │
│     to cart     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /cart/add          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ User proceeds to        │
│ checkout                 │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /order/place        │
│ payment_method: "wallet" │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Response: order_id,      │
│          status: unpaid  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Frontend Validations:    │
│ 1. User info exists?     │
│ 2. Balance sufficient?   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ POST /order/process-     │
│       payment            │
│ Body: order_id,          │
│       payment_method:    │
│       "wallet",          │
│       amount             │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Backend:                 │
│ 1. Debit regular wallet  │
│ 2. Update order status  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Response: Order paid    │
│ Frontend: Refresh user  │
│          info (balance)  │
└─────────────────────────┘
```

---

## Data Passed Between Pages

### Cart Screen → Checkout Screen

**Navigation:**
```dart
Get.toNamed(
  RouteHelper.getCheckoutRoute('cart', storeId: null)
);
```

**Data Passed:**
- Route parameter: `'cart'` (order type source)
- Store ID: `null` (if not from specific store)
- **Cart data**: Retrieved from `CartController` via GetX
- **Distance**: Pre-calculated and stored in `CartController`
- **Location data**: Retrieved from `AddressHelper.getUserAddressFromSharedPref()`

**Code Reference:**
- Cart Screen: `lib/features/cart/screens/cart_screen.dart:1805`
- Route: `lib/helper/route_helper.dart:getCheckoutRoute()`

---

### Checkout Screen → Order Success Screen

**Navigation:**
```dart
Get.offAllNamed(
  RouteHelper.getOrderSuccessRoute(orderID),
  arguments: orderID,
);
```

**Data Passed:**
- Route parameter: `orderID` (string)
- Route arguments: `orderID` (string)
- **Order ID**: From payment success response
- **Order amount**: Stored in `CheckoutController._currentOrderAmount`

**Code Reference:**
- Checkout Controller: `lib/features/checkout/controllers/checkout_controller.dart:1455-1489`
- Route: `lib/helper/route_helper.dart:getOrderSuccessRoute()`

---

### Order Success Screen → Order Tracking Screen

**Navigation:**
```dart
Get.toNamed(
  RouteHelper.getTrackOrderRoute(orderID),
  arguments: {
    'orderID': orderID,
    'contactNumber': contactNumber, // Optional
  },
);
```

**Data Passed:**
- Route parameter: `orderID` (string)
- Route arguments:
  - `orderID`: Order ID (string, required)
  - `contactNumber`: Contact phone number (string, optional)

**Code Reference:**
- Order Success Screen: `lib/features/order/screens/order_success_screen.dart`
- Route: `lib/helper/route_helper.dart:361-362`

---

### Order Details Screen → Order Tracking Screen

**Navigation:**
```dart
Get.toNamed(
  RouteHelper.getTrackOrderRoute(orderID.toString()),
  arguments: {
    'orderID': orderID.toString(),
    'contactNumber': contactNumber,
  },
);
```

**Data Passed:**
- Route parameter: `orderID` (string)
- Route arguments:
  - `orderID`: Order ID (string)
  - `contactNumber`: Contact phone number (string)

**Code Reference:**
- Order Details Screen: `lib/features/order/screens/order_details_screen.dart`
- Route: `lib/helper/route_helper.dart:361-362`

---

### Guest Track Order Input → Guest Track Order Screen

**Navigation:**
```dart
Get.toNamed(
  RouteHelper.getGuestTrackOrderRoute(),
  arguments: {
    'order_id': orderIDController.text,
    'number': phoneNumberController.text,
  },
);
```

**Data Passed:**
- Route arguments:
  - `order_id`: Order ID (string, required)
  - `number`: Contact phone number (string, required)

**Code Reference:**
- Guest Input Widget: `lib/features/order/widgets/guest_track_order_input_view_widget.dart`
- Route: `lib/helper/route_helper.dart:493-494`

---

## Error Handling

### Cart Errors

**400 Bad Request:**
```json
{
  "errors": {
    "item_id": ["The item id field is required."],
    "quantity": ["The quantity must be at least 1."],
    "price": ["The price field is required."]
  }
}
```

**404 Not Found:**
```json
{
  "message": "Item not found"
}
```

**422 Unprocessable Entity:**
```json
{
  "errors": {
    "quantity": ["Insufficient stock available."]
  }
}
```

### Order Placement Errors

**400 Bad Request:**
```json
{
  "errors": {
    "cart": ["The cart must contain at least one item."],
    "order_type": ["The selected order type is invalid."],
    "store_id": ["The store id field is required."]
  }
}
```

**422 Unprocessable Entity:**
```json
{
  "errors": {
    "distance": ["Delivery distance exceeds maximum allowed."],
    "order_amount": ["Order amount below minimum order value."]
  }
}
```

### Payment Processing Errors

**400 Bad Request - Order Not Found:**
```json
{
  "message": "Order not found",
  "errors": {
    "order_id": ["The selected order id is invalid."]
  }
}
```

**402 Payment Required - Insufficient Balance:**
```json
{
  "message": "Insufficient balance",
  "errors": {
    "balance": ["Available balance: 30.0 SAR, Required: 50.0 SAR"]
  }
}
```

**422 Unprocessable Entity - Invalid Payment Method:**
```json
{
  "message": "Payment method not available",
  "errors": {
    "payment_method": ["The selected payment method is invalid."]
  }
}
```

**MyFatoorah Payment Errors:**
- User cancellation: Returns `false` from `executePayment()`
- Payment failure: Returns error via callback
- Network errors: Caught in try-catch block
- Backend processing failure: Returns error response from `/process-payment`

---

### Order Tracking Errors

**404 Not Found - Order Not Found:**
```json
{
  "message": "Order not found",
  "errors": {
    "order_id": ["The selected order id is invalid."]
  }
}
```

**400 Bad Request - Invalid Parameters:**
```json
{
  "message": "Invalid request",
  "errors": {
    "order_id": ["The order id field is required."]
  }
}
```

**401 Unauthorized (for authenticated endpoints):**
```json
{
  "message": "Unauthenticated"
}
```

**Guest Tracking Validation:**
- Invalid order ID format: Validated before API call
- Missing contact number: Required for guest tracking
- Order not found for contact number: Shows error message

---

### Payment Processing Errors

**400 Bad Request:**
```json
{
  "message": "Order not found",
  "errors": {
    "order_id": ["The selected order id is invalid."]
  }
}
```

**402 Payment Required:**
```json
{
  "message": "Insufficient balance",
  "errors": {
    "balance": ["Available balance: 30.0 SAR, Required: 50.0 SAR"]
  }
}
```

**422 Unprocessable Entity:**
```json
{
  "message": "Payment method not available",
  "errors": {
    "payment_method": ["The selected payment method is invalid."]
  }
}
```

---

## All API Endpoints Summary

### Cart Operations

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/api/v1/customer/cart/add` | POST | Add item to cart | Optional (guest_id for guests) |
| `/api/v1/customer/cart/update` | POST | Update cart item quantity | Optional (guest_id for guests) |
| `/api/v1/customer/cart/remove-item` | DELETE | Remove item from cart | Optional (guest_id for guests) |
| `/api/v1/customer/cart/remove` | DELETE | Clear entire cart | Optional (guest_id for guests) |
| `/api/v1/customer/cart/list` | GET | Get cart items | Optional (guest_id for guests) |

### Checkout & Order Placement

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/api/v1/customer/info` | GET | Get user info (wallet balance) | Yes |
| `/api/v1/customer/coupon/list` | GET | Get available coupons | Yes |
| `/api/v1/customer/address/list` | GET | Get user addresses | Yes |
| `/api/qidha-wallet/get-wallet` | GET | Get Qidha wallet status | Yes |
| `/api/v1/config/get-zone-id` | GET | Get zone by lat/lng | No |
| `/maps/api/distancematrix/json` | GET | Calculate distance (Google Maps) | No |
| `/api/v1/config/vehicle-charge` | GET | Get extra charge by distance | No |
| `/api/v1/customer/order/place` | POST | Create order (unpaid) | Yes |
| `/api/v1/customer/order/process-payment` | POST | Process payment | Yes |

### Payment Processing

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| MyFatoorah SDK: `initiatePayment()` | SDK | Initialize payment methods | N/A |
| MyFatoorah SDK: `executePayment()` | SDK | Execute payment | N/A |
| `/api/v1/customer/order/process-payment` | POST | Process payment on backend | Yes |

### Order Tracking

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/api/v1/customer/order/track` | GET | Track order status | Optional (guest_id/contact_number for guests) |
| `/api/v1/customer/order/details` | GET | Get order details | Optional (guest_id for guests) |
| WebSocket: `wss://shalafood.net/order/updates` | WS | Real-time order updates | Yes |

### Payment Method Values

| Method | Value | Description |
|--------|-------|-------------|
| Digital Payment | `"digital_payment"` | MyFatoorah payment gateway |
| Qidha Wallet | `"wallet_qidha"` | Qidha wallet payment |
| Regular Wallet | `"wallet"` | Regular wallet payment |
| Cash on Delivery | `"cash_on_delivery"` | COD payment |

### Order Status Constants

| Status | Value | Description |
|--------|-------|-------------|
| Pending | `"pending"` | Order placed, waiting confirmation |
| Accepted | `"accepted"` | Store accepted order |
| Confirmed | `"confirmed"` | Order confirmed by store |
| Processing | `"processing"` | Store preparing order |
| Handover | `"handover"` | Ready for pickup/handover |
| Picked Up | `"picked_up"` | Delivery man picked up |
| Delivered | `"delivered"` | Order delivered |
| Canceled | `"canceled"` | Order canceled |
| Refund Requested | `"refund_requested"` | Refund requested |
| Refunded | `"refunded"` | Refund processed |
| Failed | `"failed"` | Order failed |

**Code Reference:**
- Constants: `lib/util/app_constants.dart:97, 109-111, 325-329, 459-465`

---

## Notes

1. **Order Creation Flow:**
   - Orders are created with "unpaid" status first
   - Payment is processed separately after order creation
   - This follows a real e-commerce flow pattern

2. **Guest Users:**
   - Guest users can add items to cart using `guest_id` parameter
   - Guest cart is transferred to user account after login
   - `guest_id` is included in all cart operations for guest users

3. **Variations:**
   - Food variations use new format: `{name, values: [{label, optionPrice}]}`
   - Product variations use old format: `{type, price}`
   - Backend handles both formats

4. **Payment Method Selection:**
   - Payment method index: 0 = Qidha Wallet, 1 = Regular Wallet, 2 = Digital Payment
   - Payment method is set in `checkout_controller` before processing

5. **Token Management:**
   - All endpoints require `Authorization: Bearer {token}` header
   - Token is obtained from secure storage or legacy storage
   - Token refresh is attempted if token is invalid

6. **Headers:**
   - `moduleId` and `zoneId` are required for most endpoints
   - `latitude` and `longitude` are recommended for order placement
   - `X-localization` determines response language

---

## Code File References

### Cart Operations
- `lib/features/cart/domain/repositories/cart_repository.dart`
- `lib/features/cart/controllers/cart_controller.dart`
- `lib/features/cart/domain/models/online_cart_model.dart`

### Order Placement
- `lib/features/checkout/domain/repositories/checkout_repository.dart`
- `lib/features/checkout/controllers/checkout_controller.dart`
- `lib/features/checkout/domain/models/place_order_body_model.dart`

### Payment Processing
- `lib/features/checkout/controllers/checkout_controller.dart` (processPayment method)
- `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart` (Qidha wallet)
- `lib/features/wallet/controllers/wallet_controller.dart` (MyFatoorah integration)

### Order Tracking
- `lib/features/order/controllers/order_controller.dart` (trackOrder, timerTrackOrder)
- `lib/features/order/screens/order_tracking_screen.dart` (Authenticated tracking)
- `lib/features/order/screens/guest_track_order_screen.dart` (Guest tracking)
- `lib/features/order/widgets/tracking_stepper_widget.dart` (Status stepper)
- `lib/features/order/widgets/traking_map_widget.dart` (Map widget)
- `lib/features/order/domain/repositories/order_repository.dart` (API calls)

### Constants
- `lib/util/app_constants.dart` (Endpoints, status constants)

---

---

## Key Points Summary

### Cart Operations
1. **Guest Support:** All cart operations support guest users via `guest_id` query parameter
2. **Local Storage:** Guest cart items stored locally for transfer after login
3. **Cart Transfer:** Automatic transfer from guest to user cart on login

### Order Placement
1. **Two-Step Process:** Order created first (unpaid), then payment processed separately
2. **Validations:** Minimum order, location/zone, payment method availability
3. **Fee Calculations:** All fees calculated on frontend before order creation

### Payment Processing
1. **Three Methods:** Digital Payment (MyFatoorah), Qidha Wallet, Regular Wallet
2. **Validations:** Balance checks, wallet status, purchase limits
3. **Error Handling:** Comprehensive error messages in Arabic
4. **Balance Refresh:** Wallet balances refreshed after successful payments

### Order Tracking
1. **Real-Time Updates:** Auto-refresh every 10 seconds
2. **Guest Support:** Guest users can track orders with order ID and contact number
3. **Map Integration:** Google Maps shows store, delivery address, and delivery man location
4. **Status Stepper:** Visual 5-state stepper showing order progress
5. **Chat Support:** Chat available based on store settings and order type

### Data Flow
1. **GetX State Management:** Controllers shared across screens via GetX
2. **Route Parameters:** Order IDs and contact numbers passed via routes
3. **Shared Preferences:** Guest ID, cart items, addresses stored locally
4. **API Consistency:** Same endpoints with optional auth for guest support

---

**Last Updated:** 2024-01-01
**Version:** 2.0.0 (Added Order Tracking Section)

