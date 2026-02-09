# Complete User Journey API Report
## From Menu Screen to Login, Wallet, Transactions, Orders & Guest Cart

**Generated:** $(date)  
**Scope:** Complete API endpoints, headers, and responses for user journey from menu screen through login, wallet operations, transactions, orders, and guest cart functionality.

---

## Table of Contents

1. [Menu Screen APIs](#1-menu-screen-apis)
2. [Authentication & Login APIs](#2-authentication--login-apis)
3. [Guest Cart APIs](#3-guest-cart-apis)
4. [Cart Transfer After Login](#4-cart-transfer-after-login)
5. [Wallet APIs - Qidha Wallet](#5-wallet-apis---qidha-wallet)
6. [Wallet APIs - Regular Wallet](#6-wallet-apis---regular-wallet)
7. [Wallet Transfer APIs](#7-wallet-transfer-apis)
8. [Transaction History APIs](#8-transaction-history-apis)
9. [Order APIs](#9-order-apis)
10. [Common Headers](#10-common-headers)
11. [Error Responses](#11-error-responses)

---

## 1. Menu Screen APIs

### 1.1 Get Qidha Wallet Status
**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar"
}
```

**Request:** No body required

**Expected Response (200 OK):**
```json
{
  "wallet": {
    "id": 123,
    "user_id": 456,
    "status": "active",
    "balance": 500.00,
    "credit_limit": 1000.00,
    "due_amount": 0.00,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Wallet retrieved successfully"
}
```

**Error Response (401 Unauthorized):**
```json
{
  "errors": [
    {
      "code": "unauthenticated",
      "message": "Unauthenticated."
    }
  ]
}
```

**Error Response (500 Internal Server Error):**
```json
{
  "message": "Internal server error"
}
```

**Usage Location:** `lib/features/menu/screens/menu_screen.dart:57`

---

### 1.2 Get User Profile
**Endpoint:** `GET /api/v1/customer/info`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar"
}
```

**Request:** No body required

**Expected Response (200 OK):**
```json
{
  "id": 456,
  "f_name": "John",
  "l_name": "Doe",
  "email": "john@example.com",
  "phone": "+966501234567",
  "image": "https://example.com/image.jpg",
  "wallet_balance": 250.50,
  "loyalty_point": 1500,
  "is_phone_verified": 1,
  "is_email_verified": 1
}
```

**Usage Location:** `lib/features/menu/screens/menu_screen.dart:68`

---

### 1.3 Get Delegate Status
**Endpoint:** `GET /api/v1/customer/delegate/get-delegate-status`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Expected Response (200 OK):**
```json
{
  "status": "active",
  "delegate_id": 789,
  "delegate_name": "Delegate Name"
}
```

**Usage Location:** `lib/features/menu/screens/menu_screen.dart:75`

---

### 1.4 Get Delivery Man Status
**Endpoint:** `GET /api/v1/auth/delivery-man/status`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json"
}
```

**Expected Response (200 OK):**
```json
{
  "status": "active",
  "delivery_man_id": 123
}
```

---

### 1.5 Get Zone List
**Endpoint:** `GET /api/v1/zone/list`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json"
}
```

**Expected Response (200 OK):**
```json
{
  "zones": [
    {
      "id": 1,
      "name": "Zone 1",
      "coordinates": "..."
    }
  ]
}
```

**Usage Location:** `lib/features/menu/screens/menu_screen.dart:77`

---

## 2. Authentication & Login APIs

### 2.1 Guest Login (Initial Guest Session)
**Endpoint:** `POST /api/v1/auth/guest/request`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "fcm_token": "firebase_device_token_here"
}
```

**Expected Response (200 OK):**
```json
{
  "guest_id": "guest_1234567890",
  "message": "Guest session created"
}
```

**Usage Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:124`

---

### 2.2 User Login (Email/Phone + Password)
**Endpoint:** `POST /api/v1/auth/login`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "email_or_phone": "user@example.com",
  "password": "password123",
  "login_type": "email",
  "field_type": "email",
  "guest_id": "guest_1234567890"  // Optional: Only if guest has cart items
}
```

**Expected Response (200 OK):**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "user": {
    "id": 456,
    "f_name": "John",
    "l_name": "Doe",
    "email": "user@example.com",
    "phone": "+966501234567",
    "is_phone_verified": 1,
    "is_personal_info": 1
  },
  "is_phone_verified": 1,
  "is_personal_info": 1
}
```

**Error Response (401 Unauthorized):**
```json
{
  "errors": [
    {
      "code": "invalid_credentials",
      "message": "Invalid email or password"
    }
  ]
}
```

**Usage Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:59`

**Important Notes:**
- If guest has cart items, `guest_id` is automatically attached to request
- Backend automatically transfers guest cart to user account upon successful login
- Token is saved immediately to API client headers for subsequent requests

---

### 2.3 OTP Login
**Endpoint:** `POST /api/v1/auth/login`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body (Initial - Request OTP):**
```json
{
  "phone": "+966501234567",
  "login_type": "phone",
  "guest_id": "guest_1234567890"  // Optional: Only if guest has cart items
}
```

**Request Body (Verify OTP):**
```json
{
  "phone": "+966501234567",
  "login_type": "phone",
  "otp": "123456",
  "verified": "1",
  "guest_id": "guest_1234567890"  // Optional: Only if guest has cart items
}
```

**Expected Response (200 OK):**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "user": {
    "id": 456,
    "phone": "+966501234567",
    "is_phone_verified": 1
  },
  "is_phone_verified": 1
}
```

**Usage Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:86`

---

### 2.4 Resend OTP
**Endpoint:** `POST /api/v1/auth/send-otp-again`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "phone": "+966501234567"
}
```

**Expected Response (200 OK):**
```json
{
  "message": "OTP sent successfully"
}
```

**Usage Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:110`

---

### 2.5 Update Firebase Token
**Endpoint:** `POST /api/v1/customer/cm-firebase-token`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "_method": "put",
  "cm_firebase_token": "firebase_device_token_here"
}
```

**Expected Response (200 OK):**
```json
{
  "message": "Token updated successfully"
}
```

**Usage Location:** `lib/features/auth/domain/reposotories/auth_repository.dart:243`

---

## 3. Guest Cart APIs

### 3.1 Add Item to Cart (Guest)
**Endpoint:** `POST /api/v1/customer/cart/add?guest_id={guest_id}`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar",
  "moduleId": "3",
  "zone-id": "[1,2,3]"
}
```

**Request Body:**
```json
{
  "item_id": 123,
  "price": "50.00",
  "variant": "large",
  "variation": [
    {
      "type": "size",
      "price": 10.00
    }
  ],
  "quantity": 2,
  "add_on_ids": [1, 2],
  "add_ons": [
    {
      "id": 1,
      "name": "Extra Cheese"
    }
  ],
  "add_on_qtys": [1, 1],
  "model": "Item",
  "item_type": "Item"
}
```

**Expected Response (200 OK):**
```json
[
  {
    "id": 456,
    "item_id": 123,
    "item": {
      "id": 123,
      "name": "Pizza",
      "price": 50.00
    },
    "quantity": 2,
    "price": 100.00,
    "variation": [
      {
        "type": "size",
        "price": 10.00
      }
    ],
    "add_ons": [
      {
        "id": 1,
        "name": "Extra Cheese",
        "price": 5.00
      }
    ]
  }
]
```

**Usage Location:** `lib/features/cart/domain/repositories/cart_repository.dart:54`

**Important Notes:**
- Guest cart items are stored locally in SharedPreferences for transfer after login
- Backend associates cart with `guest_id` for later transfer

---

### 3.2 Get Cart List (Guest)
**Endpoint:** `GET /api/v1/customer/cart/list?guest_id={guest_id}`

**Headers:**
```json
{
  "Content-Type": "application/json; charset=UTF-8",
  "X-localization": "ar",
  "moduleId": "3",
  "Cache-Control": "no-cache, no-store, must-revalidate",
  "Pragma": "no-cache",
  "Expires": "0",
  "X-Requested-With": "XMLHttpRequest"
}
```

**Expected Response (200 OK):**
```json
[
  {
    "id": 456,
    "item_id": 123,
    "item": {
      "id": 123,
      "name": "Pizza",
      "price": 50.00
    },
    "quantity": 2,
    "price": 100.00,
    "variation": [],
    "add_ons": []
  }
]
```

**Usage Location:** `lib/features/cart/domain/repositories/cart_repository.dart:105`

---

### 3.3 Update Cart Item (Guest)
**Endpoint:** `POST /api/v1/customer/cart/update?guest_id={guest_id}`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar",
  "moduleId": "3"
}
```

**Request Body:**
```json
{
  "cart_id": 456,
  "price": 50.00,
  "quantity": 3
}
```

**Expected Response (200 OK):**
```json
[
  {
    "id": 456,
    "quantity": 3,
    "price": 150.00
  }
]
```

**Usage Location:** `lib/features/cart/domain/repositories/cart_repository.dart:176`

---

### 3.4 Remove Cart Item (Guest)
**Endpoint:** `DELETE /api/v1/customer/cart/remove-item?cart_id={cart_id}&guest_id={guest_id}`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Expected Response (200 OK or 404):**
- 200: Item removed successfully
- 404: Item already doesn't exist (treated as success)

**Usage Location:** `lib/features/cart/domain/repositories/cart_repository.dart:80`

---

### 3.5 Clear All Cart (Guest)
**Endpoint:** `DELETE /api/v1/customer/cart/remove?guest_id={guest_id}`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Expected Response (200 OK):**
```json
{
  "message": "Cart cleared successfully"
}
```

**Usage Location:** `lib/features/cart/domain/repositories/cart_repository.dart:89`

---

## 4. Cart Transfer After Login

### 4.1 Automatic Cart Transfer (Backend)
**Process:** When user logs in with `guest_id` in request body, backend automatically transfers all guest cart items to user's account.

**Endpoint:** `POST /api/v1/auth/login` (with `guest_id`)

**Request Body:**
```json
{
  "email_or_phone": "user@example.com",
  "password": "password123",
  "login_type": "email",
  "field_type": "email",
  "guest_id": "guest_1234567890"
}
```

**Backend Behavior:**
1. Authenticates user
2. Finds all cart items associated with `guest_id`
3. Transfers cart items to authenticated user's account
4. Clears guest cart
5. Returns user token and data

**Expected Response (200 OK):**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "user": {
    "id": 456,
    "f_name": "John",
    "l_name": "Doe"
  },
  "cart_transferred": true,
  "items_transferred": 3
}
```

**Usage Location:** `lib/features/auth/controllers/auth_controller.dart:190`

**Client-Side Process:**
1. After successful login, client waits 500ms for backend to complete transfer
2. Clears local cart cache
3. Refreshes cart data from server
4. All guest cart items now appear in user's cart

**Code Reference:** `lib/features/auth/controllers/auth_controller.dart:218`

---

## 5. Wallet APIs - Qidha Wallet

### 5.1 Get Qidha Wallet
**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar"
}
```

**Expected Response (200 OK):**
```json
{
  "wallet": {
    "id": 123,
    "user_id": 456,
    "status": "active",
    "balance": 500.00,
    "credit_limit": 1000.00,
    "due_amount": 0.00,
    "available_balance": 500.00,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "message": "Unauthenticated"
}
```

**Error Response (500 Internal Server Error):**
```json
{
  "message": "Internal server error"
}
```

**Usage Location:** `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:179`

---

### 5.2 Create/Store Qidha Wallet
**Endpoint:** `POST /api/qidha-wallet/store`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "national_id": "1234567890",
  "full_name": "John Doe",
  "phone": "+966501234567",
  "email": "john@example.com",
  "address": "123 Main St"
}
```

**Expected Response (200 OK):**
```json
{
  "wallet": {
    "id": 123,
    "user_id": 456,
    "status": "pending",
    "balance": 0.00,
    "credit_limit": 0.00
  },
  "message": "Wallet created successfully"
}
```

**Usage Location:** `lib/util/app_constants.dart:113`

---

### 5.3 Qidha Wallet Credit (Add Funds)
**Endpoint:** `POST /api/qidha-wallet/credit`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "amount": 500.00,
  "payment_method": "myfatoorah"
}
```

**Expected Response (200 OK):**
```json
{
  "transaction_id": 789,
  "amount": 500.00,
  "new_balance": 500.00,
  "message": "Funds added successfully"
}
```

**Usage Location:** `lib/util/app_constants.dart:118`

---

### 5.4 Qidha Wallet Debit (Purchase)
**Endpoint:** `POST /api/qidha-wallet/debit`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "amount": 100.00,
  "order_id": 456,
  "description": "Order payment"
}
```

**Expected Response (200 OK):**
```json
{
  "transaction_id": 790,
  "amount": 100.00,
  "new_balance": 400.00,
  "message": "Payment processed successfully"
}
```

**Usage Location:** `lib/util/app_constants.dart:119`

---

### 5.5 Get Qidha Wallet Transactions
**Endpoint:** `GET /api/qidha-wallet/transactions`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `offset` (int, default: 0)
- `limit` (int, default: 50)
- `type` (string, default: 'all') - Options: 'all', 'credit', 'debit'
- `date_from` (string, optional) - Format: YYYY-MM-DD
- `date_to` (string, optional) - Format: YYYY-MM-DD
- `order_id` (int, optional)

**Expected Response (200 OK):**
```json
{
  "transactions": [
    {
      "id": 1,
      "type": "credit",
      "amount": 500.00,
      "balance_after": 500.00,
      "description": "Funds added",
      "order_id": null,
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "type": "debit",
      "amount": 100.00,
      "balance_after": 400.00,
      "description": "Order payment",
      "order_id": 456,
      "created_at": "2024-01-02T00:00:00Z"
    }
  ],
  "total": 2,
  "offset": 0,
  "limit": 50
}
```

**Usage Location:** `lib/features/statistics/data/api/qidha_wallet_api_client.dart:10`

---

### 5.6 Get Qidha Wallet Analytics Summary
**Endpoint:** `GET /api/qidha-wallet/analytics/summary`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `period` (string, default: 'month') - Options: 'week', 'month', 'year'
- `date_from` (string, optional)
- `date_to` (string, optional)

**Expected Response (200 OK):**
```json
{
  "total_spent": 1500.00,
  "total_orders": 25,
  "average_order_value": 60.00,
  "payment_frequency": {
    "total_orders_paid": 25,
    "average_days_between_payments": 3
  },
  "salary_day_info": {
    "day": 15,
    "amount": 2000.00
  }
}
```

**Usage Location:** `lib/features/statistics/data/api/qidha_wallet_api_client.dart:48`

---

## 6. Wallet APIs - Regular Wallet

### 6.1 Get Regular Wallet Transactions
**Endpoint:** `GET /api/v1/customer/wallet/transactions`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `offset` (int, default: 1)
- `limit` (int, default: 10)
- `type` (string, default: 'all') - Options: 'all', 'order', 'loyalty_point', 'add_fund', 'referrer', 'CashBack'

**Expected Response (200 OK):**
```json
{
  "total_size": 50,
  "limit": 10,
  "offset": 1,
  "transactions": [
    {
      "id": 1,
      "transaction_type": "order",
      "debit": 100.00,
      "credit": 0.00,
      "balance": 400.00,
      "transaction_id": "TXN123",
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "transaction_type": "add_fund",
      "debit": 0.00,
      "credit": 500.00,
      "balance": 500.00,
      "transaction_id": "TXN124",
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}
```

**Usage Location:** `lib/features/wallet/domain/repositories/wallet_repository.dart:66`

---

### 6.2 Add Funds to Regular Wallet
**Endpoint:** `POST /api/v1/customer/wallet/add-fund`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "amount": 500.00,
  "payment_method": "myfatoorah",
  "payment_platform": "web",
  "callback": "https://shellafood.com/wallet"
}
```

**Expected Response (200 OK):**
```json
{
  "transaction_id": "TXN125",
  "amount": 500.00,
  "payment_url": "https://payment-gateway.com/pay/...",
  "message": "Payment initiated"
}
```

**Usage Location:** `lib/features/wallet/domain/repositories/wallet_repository.dart:17`

---

### 6.3 Get Wallet Bonuses
**Endpoint:** `GET /api/v1/customer/wallet/bonuses`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Expected Response (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Welcome Bonus",
    "amount": 50.00,
    "description": "Get 50 SAR on your first deposit",
    "valid_until": "2024-12-31T00:00:00Z"
  }
]
```

**Usage Location:** `lib/features/wallet/domain/repositories/wallet_repository.dart:76`

---

## 7. Wallet Transfer APIs

### 7.1 Validate Recipient
**Endpoint:** `POST /api/v1/customer/wallet/validate-recipient`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "phone": "+966501234567"
}
```

**Expected Response (200 OK):**
```json
{
  "valid": true,
  "recipient_name": "John Doe",
  "recipient_id": 789,
  "message": "Recipient validated"
}
```

**Error Response (400 Bad Request):**
```json
{
  "valid": false,
  "message": "Recipient not found or invalid"
}
```

**Usage Location:** `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:14`

---

### 7.2 Execute Wallet Transfer
**Endpoint:** `POST /api/v1/customer/wallet/transfer`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "recipient_phone": "+966501234567",
  "amount": 100.00,
  "payment_source": "wallet",  // Options: "wallet" or "wallet_qidha"
  "save_recipient": false,
  "recipient_nickname": "John",  // Optional
  "message": "Thanks for the help!"  // Optional
}
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "transaction_id": "TXN126",
  "data": {
    "sender_new_balance": 400.00,
    "recipient_new_balance": 600.00,
    "amount": 100.00,
    "transfer_fee": 0.00
  },
  "message": "Transfer completed successfully"
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "error_code": "INSUFFICIENT_BALANCE",
  "message": "Insufficient balance in wallet",
  "data": {
    "current_balance": 50.00,
    "required_balance": 100.00
  }
}
```

**Usage Location:** `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:22`

**Important Notes:**
- `payment_source` can be either `"wallet"` (regular wallet) or `"wallet_qidha"` (Qidha wallet)
- After successful transfer, client automatically refreshes wallet balance
- Phone number is normalized to include country code (+966)

---

### 7.3 Get Saved Recipients
**Endpoint:** `GET /api/v1/customer/wallet/recipients`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Expected Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "recipient_phone": "+966501234567",
      "recipient_name": "John Doe",
      "recipient_nickname": "John",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

**Usage Location:** `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:30`

---

### 7.4 Add Saved Recipient
**Endpoint:** `POST /api/v1/customer/wallet/recipients/add`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "recipient_phone": "+966501234567",
  "recipient_name": "John"  // Optional
}
```

**Expected Response (200 OK or 201 Created):**
```json
{
  "data": {
    "id": 1,
    "recipient_phone": "+966501234567",
    "recipient_name": "John",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "message": "Recipient saved successfully"
}
```

**Usage Location:** `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:35`

---

### 7.5 Delete Saved Recipient
**Endpoint:** `DELETE /api/v1/customer/wallet/recipients/{recipient_id}`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Expected Response (200 OK):**
```json
{
  "message": "Recipient deleted successfully"
}
```

**Usage Location:** `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:44`

---

## 8. Transaction History APIs

### 8.1 Get Qidha Wallet Transactions (Detailed)
**Endpoint:** `GET /api/qidha-wallet/transactions`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `offset` (int, default: 0)
- `limit` (int, default: 50)
- `type` (string, default: 'all') - Options: 'all', 'credit', 'debit'
- `date_from` (string, optional) - Format: YYYY-MM-DD
- `date_to` (string, optional) - Format: YYYY-MM-DD
- `order_id` (int, optional)

**Expected Response (200 OK):**
```json
{
  "transactions": [
    {
      "id": 1,
      "type": "credit",
      "amount": 500.00,
      "balance_after": 500.00,
      "description": "Funds added via MyFatoorah",
      "order_id": null,
      "payment_method": "myfatoorah",
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "type": "debit",
      "amount": 100.00,
      "balance_after": 400.00,
      "description": "Order #456 payment",
      "order_id": 456,
      "payment_method": "qidha_wallet",
      "created_at": "2024-01-02T00:00:00Z"
    }
  ],
  "total": 2,
  "offset": 0,
  "limit": 50
}
```

**Usage Location:** `lib/features/statistics/data/api/qidha_wallet_api_client.dart:10`

---

### 8.2 Get Regular Wallet Transactions
**Endpoint:** `GET /api/v1/customer/wallet/transactions`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `offset` (int, default: 1)
- `limit` (int, default: 10)
- `type` (string, default: 'all') - Options: 'all', 'order', 'loyalty_point', 'add_fund', 'referrer', 'CashBack'

**Expected Response (200 OK):**
```json
{
  "total_size": 50,
  "limit": 10,
  "offset": 1,
  "transactions": [
    {
      "id": 1,
      "transaction_type": "order",
      "debit": 100.00,
      "credit": 0.00,
      "balance": 400.00,
      "transaction_id": "TXN123",
      "reference": "Order #456",
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "transaction_type": "add_fund",
      "debit": 0.00,
      "credit": 500.00,
      "balance": 500.00,
      "transaction_id": "TXN124",
      "reference": "Payment via MyFatoorah",
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}
```

**Usage Location:** `lib/features/wallet/domain/repositories/wallet_repository.dart:66`

---

## 9. Order APIs

### 9.1 Place Order
**Endpoint:** `POST /api/v1/customer/order/place`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json; charset=UTF-8",
  "Accept": "application/json",
  "latitude": "24.7136",
  "longitude": "46.6753",
  "moduleId": "3",
  "zone-id": "[1,2,3]",
  "X-localization": "ar"
}
```

**Request Body:**
```json
{
  "cart": [
    {
      "item_id": 123,
      "item_campaign_id": null,
      "price": 50.00,
      "variant": "large",
      "variation": [
        {
          "type": "size",
          "price": 10.00
        }
      ],
      "quantity": 2,
      "add_on_ids": [1, 2],
      "add_ons": [
        {
          "id": 1,
          "name": "Extra Cheese"
        }
      ],
      "add_on_qtys": [1, 1],
      "model": "Item",
      "item_type": "Item"
    }
  ],
  "coupon_code": "SAVE10",
  "distance": 5.2,
  "address_id": 123,
  "address": "123 Main St",
  "latitude": "24.7136",
  "longitude": "46.6753",
  "contact_person_name": "John Doe",
  "contact_person_number": "+966501234567",
  "payment_method": "cash_on_delivery",
  "order_note": "Please deliver to front door",
  "delivery_instruction": "deliver_to_front_door",
  "dm_tips": 10.00,
  "schedule_at": null,
  "cutlery": 1,
  "module_id": 3
}
```

**Expected Response (200 OK):**
```json
{
  "order_id": 456,
  "order_amount": 110.00,
  "delivery_fee": 10.00,
  "tax": 5.00,
  "discount": 10.00,
  "coupon_discount": 10.00,
  "total_amount": 110.00,
  "payment_status": "unpaid",
  "order_status": "pending",
  "message": "Order placed successfully"
}
```

**Error Response (400 Bad Request):**
```json
{
  "errors": [
    {
      "code": "insufficient_balance",
      "message": "Insufficient balance in wallet"
    }
  ]
}
```

**Usage Location:** `lib/features/checkout/domain/repositories/checkout_repository.dart:86`

---

### 9.2 Get Running Orders
**Endpoint:** `GET /api/v1/customer/order/running-orders`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `offset` (int, default: 0)
- `limit` (int, default: 10) - Can be 50 for dashboard

**Expected Response (200 OK):**
```json
{
  "total_size": 5,
  "limit": 10,
  "offset": 0,
  "orders": [
    {
      "id": 456,
      "order_status": "accepted",
      "order_amount": 110.00,
      "restaurant": {
        "id": 789,
        "name": "Restaurant Name"
      },
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

**Usage Location:** `lib/features/order/domain/repositories/order_repository.dart:103`

---

### 9.3 Get Order History
**Endpoint:** `GET /api/v1/customer/order/list`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `offset` (int, default: 0)
- `limit` (int, default: 10)

**Expected Response (200 OK):**
```json
{
  "total_size": 50,
  "limit": 10,
  "offset": 0,
  "orders": [
    {
      "id": 455,
      "order_status": "delivered",
      "order_amount": 110.00,
      "restaurant": {
        "id": 789,
        "name": "Restaurant Name"
      },
      "created_at": "2023-12-31T00:00:00Z"
    }
  ]
}
```

**Usage Location:** `lib/features/order/domain/repositories/order_repository.dart:112`

---

### 9.4 Get Order Details
**Endpoint:** `GET /api/v1/customer/order/details?order_id={order_id}`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `order_id` (int, required)
- `guest_id` (string, optional) - For guest orders

**Expected Response (200 OK):**
```json
[
  {
    "id": 456,
    "order_id": 456,
    "item_id": 123,
    "item": {
      "id": 123,
      "name": "Pizza",
      "price": 50.00
    },
    "quantity": 2,
    "price": 100.00,
    "variation": [],
    "add_ons": [],
    "order_status": "accepted",
    "order_amount": 110.00,
    "delivery_address": "123 Main St",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

**Usage Location:** `lib/features/order/domain/repositories/order_repository.dart:69`

---

### 9.5 Track Order
**Endpoint:** `GET /api/v1/customer/order/track?order_id={order_id}`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Query Parameters:**
- `order_id` (int, required)
- `guest_id` (string, optional) - For guest orders
- `contact_number` (string, optional) - For guest tracking

**Expected Response (200 OK):**
```json
{
  "order_id": 456,
  "order_status": "accepted",
  "order_amount": 110.00,
  "delivery_man": {
    "id": 123,
    "name": "Delivery Man",
    "phone": "+966501234567",
    "vehicle": "Motorcycle"
  },
  "estimated_delivery_time": "30 minutes",
  "tracking_history": [
    {
      "status": "pending",
      "timestamp": "2024-01-01T00:00:00Z"
    },
    {
      "status": "accepted",
      "timestamp": "2024-01-01T00:05:00Z"
    }
  ]
}
```

**Usage Location:** `lib/features/order/domain/repositories/order_repository.dart:33`

---

### 9.6 Cancel Order
**Endpoint:** `POST /api/v1/customer/order/cancel`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "_method": "put",
  "order_id": "456",
  "reason": "Changed my mind",
  "guest_id": "guest_1234567890"  // Optional: For guest orders
}
```

**Expected Response (200 OK):**
```json
{
  "message": "Order cancelled successfully",
  "order_id": 456,
  "refund_amount": 110.00,
  "refund_method": "wallet"
}
```

**Usage Location:** `lib/features/order/domain/repositories/order_repository.dart:50`

---

### 9.7 Switch Payment Method to COD
**Endpoint:** `POST /api/v1/customer/order/payment-method`

**Headers:**
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "_method": "put",
  "order_id": "456",
  "guest_id": "guest_1234567890"  // Optional: For guest orders
}
```

**Expected Response (200 OK):**
```json
{
  "message": "Payment method switched to COD",
  "order_id": 456
}
```

**Usage Location:** `lib/features/order/domain/repositories/order_repository.dart:41`

---

## 10. Common Headers

### 10.1 Standard Headers (All Requests)
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar"  // or "en"
}
```

### 10.2 Authenticated Requests
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar"
}
```

### 10.3 Location-Based Requests
```json
{
  "Authorization": "Bearer {token}",
  "Content-Type": "application/json",
  "Accept": "application/json",
  "X-localization": "ar",
  "moduleId": "3",
  "zone-id": "[1,2,3]",  // JSON-encoded array
  "latitude": "24.7136",
  "longitude": "46.6753"
}
```

### 10.4 Cart Requests
```json
{
  "Authorization": "Bearer {token}",  // Optional for guest
  "Content-Type": "application/json; charset=UTF-8",
  "X-localization": "ar",
  "moduleId": "3",
  "Cache-Control": "no-cache, no-store, must-revalidate",
  "Pragma": "no-cache",
  "Expires": "0",
  "X-Requested-With": "XMLHttpRequest"
}
```

---

## 11. Error Responses

### 11.1 Authentication Errors

**401 Unauthorized:**
```json
{
  "errors": [
    {
      "code": "unauthenticated",
      "message": "Unauthenticated."
    }
  ]
}
```

**Action:** Clear token and redirect to login

---

### 11.2 Validation Errors

**422 Unprocessable Entity:**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": [
      "The email field is required."
    ],
    "password": [
      "The password must be at least 6 characters."
    ]
  }
}
```

---

### 11.3 Business Logic Errors

**400 Bad Request:**
```json
{
  "success": false,
  "error_code": "INSUFFICIENT_BALANCE",
  "message": "Insufficient balance in wallet",
  "data": {
    "current_balance": 50.00,
    "required_balance": 100.00
  }
}
```

---

### 11.4 Server Errors

**500 Internal Server Error:**
```json
{
  "message": "Internal server error"
}
```

---

## 12. Guest Cart Transfer Flow

### 12.1 Complete Flow Diagram

```
1. Guest adds items to cart
   ↓
   POST /api/v1/customer/cart/add?guest_id={guest_id}
   ↓
   Items stored on server with guest_id
   ↓
   Items also stored locally in SharedPreferences

2. Guest decides to login
   ↓
   POST /api/v1/auth/login
   Body: {
     "email_or_phone": "...",
     "password": "...",
     "guest_id": "guest_1234567890"  // Automatically attached if local cart exists
   }
   ↓
   Backend transfers all guest cart items to user account
   ↓
   Returns user token

3. Client-side cleanup (after 500ms delay)
   ↓
   Clear local cart cache
   ↓
   GET /api/v1/customer/cart/list (force refresh)
   ↓
   All guest items now appear in user's cart
```

### 12.2 Key Implementation Details

**Automatic Guest ID Attachment:**
- Location: `lib/features/auth/domain/reposotories/auth_repository.dart:30`
- Logic: Checks if guest has local cart items, then attaches `guest_id` to login request

**Backend Cart Transfer:**
- Backend automatically finds all cart items with `guest_id`
- Transfers them to authenticated user's account
- Clears guest cart on server

**Client-Side Cleanup:**
- Location: `lib/features/auth/controllers/auth_controller.dart:218`
- Waits 500ms for backend to complete transfer
- Clears local SharedPreferences cart cache
- Forces refresh of cart data from server

---

## 13. Summary of All Endpoints

### Authentication (5 endpoints)
1. `POST /api/v1/auth/guest/request` - Guest login
2. `POST /api/v1/auth/login` - User login (email/phone + password)
3. `POST /api/v1/auth/login` - OTP login
4. `POST /api/v1/auth/send-otp-again` - Resend OTP
5. `POST /api/v1/customer/cm-firebase-token` - Update FCM token

### Cart (5 endpoints)
1. `POST /api/v1/customer/cart/add` - Add to cart
2. `GET /api/v1/customer/cart/list` - Get cart list
3. `POST /api/v1/customer/cart/update` - Update cart item
4. `DELETE /api/v1/customer/cart/remove-item` - Remove cart item
5. `DELETE /api/v1/customer/cart/remove` - Clear all cart

### Qidha Wallet (7 endpoints)
1. `GET /api/qidha-wallet/get-wallet` - Get wallet status
2. `POST /api/qidha-wallet/store` - Create wallet
3. `POST /api/qidha-wallet/credit` - Add funds
4. `POST /api/qidha-wallet/debit` - Purchase/payment
5. `GET /api/qidha-wallet/transactions` - Get transactions
6. `GET /api/qidha-wallet/analytics/summary` - Get analytics
7. `GET /api/qidha-wallet/due-payments` - Get due payments

### Regular Wallet (3 endpoints)
1. `GET /api/v1/customer/wallet/transactions` - Get transactions
2. `POST /api/v1/customer/wallet/add-fund` - Add funds
3. `GET /api/v1/customer/wallet/bonuses` - Get bonuses

### Wallet Transfer (5 endpoints)
1. `POST /api/v1/customer/wallet/validate-recipient` - Validate recipient
2. `POST /api/v1/customer/wallet/transfer` - Execute transfer
3. `GET /api/v1/customer/wallet/recipients` - Get saved recipients
4. `POST /api/v1/customer/wallet/recipients/add` - Add saved recipient
5. `DELETE /api/v1/customer/wallet/recipients/{id}` - Delete saved recipient

### Orders (7 endpoints)
1. `POST /api/v1/customer/order/place` - Place order
2. `GET /api/v1/customer/order/running-orders` - Get running orders
3. `GET /api/v1/customer/order/list` - Get order history
4. `GET /api/v1/customer/order/details` - Get order details
5. `GET /api/v1/customer/order/track` - Track order
6. `POST /api/v1/customer/order/cancel` - Cancel order
7. `POST /api/v1/customer/order/payment-method` - Switch to COD

### Menu Screen (5 endpoints)
1. `GET /api/qidha-wallet/get-wallet` - Get Qidha wallet
2. `GET /api/v1/customer/info` - Get user profile
3. `GET /api/v1/customer/delegate/get-delegate-status` - Get delegate status
4. `GET /api/v1/auth/delivery-man/status` - Get delivery man status
5. `GET /api/v1/zone/list` - Get zone list

**Total: 37 endpoints**

---

## 14. Important Notes

1. **Guest Cart Transfer:** Backend automatically handles cart transfer when `guest_id` is included in login request. Client only needs to clear local cache and refresh.

2. **Token Management:** Token is immediately updated in API client headers upon successful login, ensuring subsequent requests are authenticated.

3. **Wallet Types:** There are two separate wallet systems:
   - **Regular Wallet:** `/api/v1/customer/wallet/*`
   - **Qidha Wallet:** `/api/qidha-wallet/*`

4. **Payment Sources:** Wallet transfers can use either `"wallet"` (regular) or `"wallet_qidha"` (Qidha) as payment source.

5. **Headers:** Most requests require `moduleId` and `zone-id` headers for location-based filtering.

6. **Error Handling:** 401 errors trigger automatic logout and redirect to login screen.

7. **Cart Caching:** Cart requests include cache-busting headers to ensure fresh data.

---

**End of Report**

