# Order Tracking Complete Flow Documentation

## Overview

This document provides a complete technical reference for order tracking functionality, including authenticated user tracking, guest tracking, real-time updates, and order status management.

---

## Table of Contents

1. [Order Tracking API](#order-tracking-api)
2. [Order Status Flow](#order-status-flow)
3. [Tracking Screens](#tracking-screens)
4. [Real-Time Updates](#real-time-updates)
5. [Guest Tracking](#guest-tracking)
6. [Order Model Structure](#order-model-structure)
7. [Tracking Stepper Widget](#tracking-stepper-widget)
8. [Error Handling](#error-handling)
9. [Code References](#code-references)

---

## Order Tracking API

### Track Order Endpoint

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

## Order Status Flow

### Order Status Values

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

### Status Timestamps

Each status change is recorded with a timestamp:
- `pending`: When order is placed
- `accepted`: When store accepts order
- `confirmed`: When order is confirmed
- `processing`: When store starts preparing
- `handover`: When order is ready for handover
- `picked_up`: When delivery man picks up order
- `delivered`: When order is delivered
- `canceled`: When order is canceled

### Status Flow Diagram

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

## Tracking Screens

### 1. Order Tracking Screen (Authenticated Users)

**Route:** `/track-order`

**File:** `lib/features/order/screens/order_tracking_screen.dart`

**Parameters:**
- `orderID`: Order ID (string, required)
- `contactNumber`: Contact phone number (string, optional)

**Features:**
- Real-time order status tracking
- Google Maps integration for delivery tracking
- Delivery man location tracking
- Order status stepper
- Chat functionality (if enabled)
- Auto-refresh every 10 seconds

**Code Reference:**
- Screen: `lib/features/order/screens/order_tracking_screen.dart`
- Route: `lib/helper/route_helper.dart:361-362`

### 2. Guest Track Order Screen

**Route:** `/guest-track-order-screen`

**File:** `lib/features/order/screens/guest_track_order_screen.dart`

**Parameters:**
- `order_id`: Order ID (string, required)
- `number`: Contact phone number (string, required)

**Features:**
- Guest order tracking without authentication
- Order status stepper
- Delivery man contact (if available)
- View order details button

**Code Reference:**
- Screen: `lib/features/order/screens/guest_track_order_screen.dart`
- Route: `lib/helper/route_helper.dart:493-494`

### 3. Guest Track Order Input Screen

**Route:** `/order`

**File:** `lib/features/order/widgets/guest_track_order_input_view_widget.dart`

**Features:**
- Input form for order ID and contact number
- Supports both order and trip tracking
- Validates input before tracking

**Code Reference:**
- Widget: `lib/features/order/widgets/guest_track_order_input_view_widget.dart`

---

## Real-Time Updates

### Auto-Refresh Mechanism

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

**Code Reference:**
- Order Tracking Screen: `lib/features/order/screens/order_tracking_screen.dart:91-96`
- Order Details Screen: `lib/features/order/screens/order_details_screen.dart:77-84`
- Controller: `lib/features/order/controllers/order_controller.dart:384-402`

### WebSocket Support (Future)

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

## Guest Tracking

### Guest Tracking Flow

1. **Input Screen:**
   - User enters order ID and contact number
   - Validates input format

2. **Track Order:**
   - Calls `/api/v1/customer/order/track` with `order_id` and `contact_number`
   - No authentication required

3. **Display Status:**
   - Shows order status stepper
   - Displays order information
   - Shows delivery man contact (if available)

**Code Reference:**
- Guest Input Widget: `lib/features/order/widgets/guest_track_order_input_view_widget.dart:118-120`
- Guest Tracking Screen: `lib/features/order/screens/guest_track_order_screen.dart:34`

### Guest Tracking API Call

**Request:**
```
GET /api/v1/customer/order/track?order_id=12345&contact_number=+966501234567
```

**Response:** Same as authenticated user tracking

**Code Reference:**
- Repository: `lib/features/order/domain/repositories/order_repository.dart:33-38`

---

## Order Model Structure

### Key Fields

**Order Information:**
- `id`: Order ID
- `userId`: User ID
- `orderAmount`: Total order amount
- `orderStatus`: Current order status
- `paymentStatus`: Payment status (paid/unpaid)
- `paymentMethod`: Payment method used
- `orderType`: Order type (delivery/take_away/parcel)

**Timestamps:**
- `createdAt`: Order creation time
- `updatedAt`: Last update time
- `pending`: Pending status timestamp
- `accepted`: Accepted status timestamp
- `confirmed`: Confirmed status timestamp
- `processing`: Processing status timestamp
- `handover`: Handover status timestamp
- `pickedUp`: Picked up status timestamp
- `delivered`: Delivered status timestamp
- `canceled`: Canceled status timestamp

**Delivery Information:**
- `deliveryMan`: Delivery man details (name, phone, location)
- `deliveryAddress`: Delivery address
- `deliveryCharge`: Delivery charge
- `dmTips`: Delivery man tips

**Store Information:**
- `store`: Store details (name, phone, address, location)

**Payment Information:**
- `paymentMethod`: Payment method
- `paymentStatus`: Payment status
- `offlinePayment`: Offline payment details (if applicable)
- `partiallyPaidAmount`: Partial payment amount

**Code Reference:**
- Model: `lib/features/order/domain/models/order_model.dart`

---

## Tracking Stepper Widget

### Tracking Stepper States

The tracking stepper displays 5 main states:

1. **Order Placed** (`pending`)
   - Icon: `Images.trackOrderPlace`
   - State: `state = 0`

2. **Order Confirmed** (`accepted` or `confirmed`)
   - Icon: `Images.trackOrderAccept`
   - State: `state = 1`

3. **Preparing Item** (`processing`)
   - Icon: `Images.trackOrderPreparing`
   - State: `state = 2`

4. **On The Way / Ready for Handover**
   - For delivery: "Delivery on the way" (`handover` or `picked_up`)
   - For takeaway: "Ready for handover" (`handover`)
   - Icon: `Images.trackOrderOnTheWay`
   - State: `state = 3`

5. **Delivered** (`delivered`)
   - Icon: `Images.trackOrderDelivered`
   - State: `state = 4`

### State Calculation Logic

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

## Error Handling

### API Errors

**404 Not Found:**
```json
{
  "message": "Order not found",
  "errors": {
    "order_id": ["The selected order id is invalid."]
  }
}
```

**400 Bad Request:**
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

### Frontend Error Handling

**Order Not Found:**
- Shows error message to user
- Allows retry or navigation back

**Network Error:**
- Shows network error message
- Allows retry

**Invalid Order ID:**
- Validates format before API call
- Shows validation error

**Code Reference:**
- Controller: `lib/features/order/controllers/order_controller.dart:342-380`

---

## Order Details Integration

### Get Order Details

**Endpoint:** `GET /api/v1/customer/order/details?order_id={id}`

**Query Parameters:**
- `order_id`: Order ID (required)
- `guest_id`: Guest ID (optional, for guest users)

**Response:**
Returns detailed order information including order items, prices, and quantities.

**Code Reference:**
- Repository: `lib/features/order/domain/repositories/order_repository.dart:69-78`
- Constants: `lib/util/app_constants.dart:150-151`

---

## Chat Functionality

### Chat Permission

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

## Map Integration

### Delivery Man Tracking

The tracking screen displays a Google Map showing:
- Store location
- Delivery address
- Delivery man location (if available)
- Route between locations

**Code Reference:**
- Map Widget: `lib/features/order/widgets/traking_map_widget.dart`
- Order Tracking Screen: `lib/features/order/screens/order_tracking_screen.dart:187-228`

---

## Order Types

### Delivery Orders

- Shows delivery address
- Tracks delivery man location
- Displays "Delivery on the way" status
- Shows delivery charge

### Take Away Orders

- Shows "Ready for handover" status
- No delivery man tracking
- No delivery charge (usually)

### Parcel Orders

- Similar to delivery orders
- May have different status flow
- Includes parcel category information

**Code Reference:**
- Order Model: `lib/features/order/domain/models/order_model.dart:49`
- Tracking Stepper: `lib/features/order/widgets/tracking_stepper_widget.dart:8-9`

---

## Constants Reference

**API Endpoints:**
- Track Order: `/api/v1/customer/order/track?order_id=`
- Order Details: `/api/v1/customer/order/details?order_id=`

**Order Status Constants:**
- `pending`: "pending"
- `accepted`: "accepted"
- `confirmed`: "confirmed"
- `processing`: "processing"
- `handover`: "handover"
- `pickedUp`: "picked_up"
- `delivered`: "delivered"
- `canceled`: "canceled"

**Code Reference:**
- Constants: `lib/util/app_constants.dart:97, 459-465`

---

## Complete Flow Diagram

```
┌─────────────────────┐
│ User opens tracking │
│      screen         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ GET /order/track    │
│ ?order_id={id}      │
│ [+guest_id]         │
│ [+contact_number]   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Response: OrderModel│
│ with status, timestamps│
│ delivery_man, store │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Display Status      │
│ Stepper             │
│ - Order Placed      │
│ - Order Confirmed   │
│ - Preparing Item    │
│ - On The Way        │
│ - Delivered         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Start Timer         │
│ (10 seconds)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Timer triggers      │
│ timerTrackOrder()   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ GET /order/track    │
│ (refresh)           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Update UI if        │
│ status changed      │
└─────────────────────┘
```

---

## Code File References

### Controllers
- `lib/features/order/controllers/order_controller.dart`
  - `trackOrder()`: Main tracking method
  - `timerTrackOrder()`: Auto-refresh method
  - `setTrackModel()`: Set tracking model

### Screens
- `lib/features/order/screens/order_tracking_screen.dart`: Authenticated tracking screen
- `lib/features/order/screens/guest_track_order_screen.dart`: Guest tracking screen
- `lib/features/order/screens/order_details_screen.dart`: Order details with tracking

### Widgets
- `lib/features/order/widgets/tracking_stepper_widget.dart`: Status stepper
- `lib/features/order/widgets/guest_custom_stepper_widget.dart`: Guest status stepper
- `lib/features/order/widgets/traking_map_widget.dart`: Map widget
- `lib/features/order/widgets/guest_track_order_input_view_widget.dart`: Guest input form

### Repositories
- `lib/features/order/domain/repositories/order_repository.dart`: API calls
- `lib/features/order/domain/repositories/order_repository_interface.dart`: Interface

### Services
- `lib/features/order/domain/services/order_service.dart`: Service layer
- `lib/features/order/domain/services/order_service_interface.dart`: Interface

### Models
- `lib/features/order/domain/models/order_model.dart`: Order model
- `lib/features/order/domain/models/order_details_model.dart`: Order details model

### Constants
- `lib/util/app_constants.dart`: API endpoints and status constants
- `lib/util/images.dart`: Status images

### Routes
- `lib/helper/route_helper.dart`: Route definitions

---

## Notes

1. **Auto-Refresh:**
   - Tracking screen refreshes every 10 seconds
   - Timer is canceled when screen is disposed
   - Manual refresh is also available

2. **Guest Tracking:**
   - No authentication required
   - Requires order ID and contact number
   - Same API endpoint as authenticated users

3. **Order Status:**
   - Status changes are timestamped
   - Each status has a corresponding timestamp field
   - Status determines stepper state

4. **Delivery Man Tracking:**
   - Only available for delivery orders
   - Shows on map when delivery man is assigned
   - Contact information available when assigned

5. **Chat Functionality:**
   - Available based on store settings
   - Requires specific business model or subscription
   - Not available for all order types

6. **WebSocket Support:**
   - WebSocket connection available for real-time updates
   - Currently implemented but may not be fully utilized
   - Connection URL: `wss://shalafood.net/order/updates?type=user&id={userId}`

7. **Error Handling:**
   - Network errors are handled gracefully
   - Invalid order IDs are validated before API call
   - User-friendly error messages displayed

---

**Last Updated:** 2024-01-01
**Version:** 1.0.0

