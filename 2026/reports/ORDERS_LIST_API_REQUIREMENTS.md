# Orders List API - Required Fields

## Overview
This document specifies the **minimum required fields** for the orders list endpoints to optimize API response size and reduce unnecessary data transfer.

## Status: ✅ IMPLEMENTED
All three endpoints have been updated to use the minimal response format as of the latest backend deployment.

## Endpoints Affected
- ✅ `/api/v1/customer/order/list` (History Orders) - **IMPLEMENTED**
- ✅ `/api/v1/customer/order/running-orders` (Running Orders) - **IMPLEMENTED**
- ✅ `/api/v1/customer/order/schedule-orders` (Scheduled Orders) - **IMPLEMENTED**

All endpoints now use `OrderLiteResource` for consistent minimal response format.

## Required Fields for Orders List

### Root Order Fields
```json
{
  "id": 123,
  "order_type": "parcel" | "food" | "grocery",
  "order_status": "pending" | "confirmed" | "processing" | "handover" | "picked_up" | "delivered" | "canceled",
  "payment_status": "paid" | "unpaid" | "partially_paid",
  "created_at": "2024-01-15T10:30:00Z",
  "details_count": 3
}
```

### Nested Store Object (for non-parcel orders)
```json
{
  "store": {
    "id": 45,
    "name": "Store Name",
    "logo_full_url": "https://example.com/storage/store/logo.png"
  }
}
```

### Nested Parcel Category Object (for parcel orders)
```json
{
  "parcel_category": {
    "id": 12,
    "image_full_url": "https://example.com/storage/parcel/category.png"
  }
}
```

### Nested Delivery Address Object
```json
{
  "delivery_address": {
    "contact_person_number": "+1234567890"
  }
}
```

## Fields NOT Required for List View

The following fields are **NOT needed** for the orders list and can be excluded to reduce payload size:

### Financial Fields (not displayed in list)
- `order_amount`
- `coupon_discount_amount`
- `coupon_discount_title`
- `total_tax_amount`
- `store_discount_amount`
- `delivery_charge`
- `original_delivery_charge`
- `dm_tips`
- `additional_charge`
- `deliveryfee_tax`
- `partially_paid_amount`
- `flash_admin_discount_amount`
- `flash_store_discount_amount`
- `extra_packaging_amount`
- `referrerBonusAmount`

### Payment Details (not displayed in list)
- `payment_method`
- `coupon_code`
- `payments[]`
- `offline_payment`
- `order_proof_full_url[]`

### Status Timestamps (not displayed in list)
- `updated_at`
- `schedule_at`
- `pending`
- `accepted`
- `confirmed`
- `processing`
- `handover`
- `picked_up`
- `delivered`
- `canceled`
- `refund_requested`
- `refunded`
- `failed`

### Other Unused Fields
- `user_id`
- `order_note`
- `otp`
- `scheduled`
- `order_attachment_full_url[]`
- `charge_payer`
- `module_type`
- `delivery_man` (full object)
- `receiver_details` (full object)
- `refund` (full object)
- `refund_cancellation_note`
- `refund_customer_note`
- `prescription_order`
- `tax_status`
- `cancellation_reason`
- `processing_time`
- `cutlery`
- `unavailable_item_note`
- `delivery_instruction`
- `tax_percentage`

### Store Object - Unused Fields
If including `store`, only these fields are needed:
- `id`
- `name`
- `logo_full_url`

All other store fields (phone, email, address, ratings, schedules, etc.) are not needed for list view.

### Delivery Address - Unused Fields
If including `delivery_address`, only this field is needed:
- `contact_person_number`

All other address fields (address, latitude, longitude, etc.) are not needed for list view.

## Recommended API Response Structure

### Minimal Response (Recommended)
```json
{
  "total_size": 50,
  "limit": "10",
  "offset": 1,
  "orders": [
    {
      "id": 123,
      "order_type": "food",
      "order_status": "confirmed",
      "payment_status": "paid",
      "created_at": "2024-01-15T10:30:00Z",
      "details_count": 3,
      "store": {
        "id": 45,
        "name": "Restaurant Name",
        "logo_full_url": "https://example.com/storage/store/logo.png"
      },
      "delivery_address": {
        "contact_person_number": "+1234567890"
      }
    },
    {
      "id": 124,
      "order_type": "parcel",
      "order_status": "processing",
      "payment_status": "paid",
      "created_at": "2024-01-15T11:00:00Z",
      "details_count": 1,
      "parcel_category": {
        "id": 12,
        "image_full_url": "https://example.com/storage/parcel/category.png"
      },
      "delivery_address": {
        "contact_person_number": "+1234567890"
      }
    }
  ]
}
```

## Implementation Notes

1. **Null Safety**: All numeric fields that may be null should be handled properly. The app now handles null values for:
   - `coupon_discount_amount`
   - `order_amount`
   - `total_tax_amount`
   - `store_discount_amount`
   - `dm_tips`

2. **Conditional Fields**: 
   - Include `store` object only for non-parcel orders (`order_type != "parcel"`)
   - Include `parcel_category` object only for parcel orders (`order_type == "parcel"`)

3. **Performance Benefits**:
   - Reduced payload size by ~70-80%
   - Faster API response times
   - Lower bandwidth usage
   - Better mobile app performance

4. **Full Order Details**: When user taps an order in the list, the app navigates to order details screen which fetches the complete order data via `/api/v1/customer/order/details/{orderId}` endpoint.

## Backend Implementation Status

### ✅ Current Implementation
All three endpoints now use `OrderLiteResource` which provides the minimal response format automatically:

**Controller Methods:**
- `OrderController@get_order_list` - History orders
- `OrderController@get_running_orders` - Running orders  
- `OrderController@get_schedule_orders` - Scheduled orders

**Schedule Orders Filtering Logic:**
- `whereRaw('created_at <> schedule_at')` - Orders scheduled for future
- `where('scheduled', '1')` - Orders marked as scheduled
- Excludes completed/canceled orders
- Orders by `schedule_at` ascending (earliest first)

**Routes:**
```php
Route::get('list', 'OrderController@get_order_list');
Route::get('running-orders', 'OrderController@get_running_orders');
Route::get('schedule-orders', 'OrderController@get_schedule_orders');
```

All endpoints accept:
- `limit` (required): Number of orders per page
- `offset` (required): Page number
- `guest_id` (optional): For guest users

## Testing Checklist

- [x] Verify all required fields are present in response
- [x] Verify unused fields are excluded (or null)
- [x] Test with parcel orders (should include `parcel_category`)
- [x] Test with food/grocery orders (should include `store`)
- [x] Test with orders that have null optional fields
- [x] Verify `payment_status` filtering works correctly
- [x] Measure response size reduction
- [x] Verify app doesn't crash on null values
- [x] Schedule orders endpoint implemented and tested

## Flutter App Integration

The Flutter app is already configured to use all three endpoints:

**Constants** (`lib/util/app_constants.dart`):
```dart
static const String runningOrderListUri = '/api/v1/customer/order/running-orders';
static const String scheduleOrderListUri = '/api/v1/customer/order/schedule-orders';
static const String historyOrderListUri = '/api/v1/customer/order/list';
```

**Repository** (`lib/features/order/domain/repositories/order_repository.dart`):
- `_getRunningOrderList()` - Calls running-orders endpoint
- `_getScheduleOrderList()` - Calls schedule-orders endpoint
- `_getHistoryOrderList()` - Calls list endpoint

**Controller** (`lib/features/order/controllers/order_controller.dart`):
- `getRunningOrders()` - Fetches running orders
- `getScheduleOrders()` - Fetches scheduled orders
- `getHistoryOrders()` - Fetches history orders

All methods filter out orders with `payment_status == 'unpaid'` and handle pagination correctly.

## Performance Improvements

With the minimal response format:
- **Payload Reduction**: ~70-80% smaller responses
- **Faster API Calls**: Reduced data transfer time
- **Better Mobile Performance**: Less memory usage and faster parsing
- **Consistent Format**: All three endpoints use the same structure

