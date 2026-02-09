# Qidha Wallet Complete Flow Documentation

## Overview

This document provides a complete technical reference for the entire Qidha wallet lifecycle: from the three-step creation process, waiting for admin approval, having an active wallet, paying with it, to sending funds to other users.

---

## Table of Contents

1. [Three-Step Wallet Creation](#three-step-wallet-creation)
2. [Waiting for Admin Approval](#waiting-for-admin-approval)
3. [Active Wallet Usage](#active-wallet-usage)
4. [Paying with Qidha Wallet](#paying-with-qidha-wallet)
5. [Sending Funds (Wallet Transfer)](#sending-funds-wallet-transfer)
6. [Complete Flow Diagrams](#complete-flow-diagrams)
7. [Error Handling](#error-handling)
8. [Code References](#code-references)

---

## Three-Step Wallet Creation

### Step 1: Personal Information & Contract Review

**Purpose:** Collect user's personal information and save progress.

**Endpoints Used:**

#### 1. Save State (Auto-save on form changes)
**Endpoint:** `POST /api/v1/registration-activity`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "user_id": 123,
  "type": "qidha",
  "status": "in_progress",
  "form_data": {
    "firstname": "محمد",
    "fathername": "علي",
    "grandfathername": "أحمد",
    "last_name": "السالم",
    "birthDate": "1990-01-15",
    "nationality": "1234567890",
    "marital_status": "married",
    "number_of_family_members": "5",
    "identity_card_number": "1234567890",
    "end_date": "2025-12-31",
    "house_type": "apartment",
    "city": "الرياض",
    "neighborhood": "حي النرجس",
    "name_of_employer": "شركة ABC",
    "total_salary": "15000",
    "Installments": "2000",
    "monthlyIncome": "13000",
    "salary_day": "5",
    "photo": "true"
  }
}
```

**Response (200 OK):**
```json
{
  "status": true,
  "message": "State saved successfully"
}
```

**Data Collected:**
- Personal Info: first_name, father_name, grandfather_name, last_name, birth_date, nationality, marital_status, number_of_family_members, identity_card_number, end_date, mobile
- Address Info: house_type, city, neighborhood
- Employment Info: name_of_employer, total_salary, installments, source_of_income, monthly_amount, salary_day

**Code Reference:**
- Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart`
- Service: `lib/features/wallet_kaidha_subscription/domain/services/kaidhaSub_service.dart`

---

### Step 2: Income Verification & Document Upload

**Purpose:** Upload documents and create wallet with pending status.

**Endpoints Used:**

#### 1. Create Wallet
**Endpoint:** `POST /api/qidha-wallet/store`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
Content-Type: multipart/form-data
```

**Request Body (Multipart Form Data):**

**Form Fields:**
```
first_name: "محمد"
grandfather_name: "أحمد"
father_name: "علي"
last_name: "السالم"
birth_date: "1990-01-15"
national_id: "1234567890"  // Uses nationality if available, else identity_card_number
marital_status: "married"
number_of_family_members: "5"
identity_card_number: "1234567890"
end_date: "2025-12-31"
mobile: "0501234567"
house_type: "apartment"  // Default: "apartment" if empty
city: "الرياض"  // Default: "الرياض" if empty
neighborhood: "حي النرجس"  // Uses address from SharedPref if empty
name_of_employer: "شركة ABC"
total_salary: "15000"
Installments: "2000"
source_of_income: "government"  // Mapped from jobSpecification:
                                // "government employee" → "government"
                                // "private sector employee" → "private_sector"
                                // "self-employed" → "freelance_work"
                                // "retired" → "retired"
monthly_amount: "13000"
salary_day: "5"  // Default: "2" if empty
```

**Files (Multipart):**
```
attachments[]: [File 1] (e.g., ID_card.jpg)
attachments[]: [File 2] (e.g., salary_certificate.pdf)
attachments[]: [File 3] (e.g., rental_contract.png)
... (up to 5 files: JPG, PNG, or PDF)
```

**Response (200/201 OK):**
```json
{
  "status": true,
  "message": "Wallet created successfully",
  "data": {
    "wallet_id": 123
  }
}
```

**Response (400 Bad Request - Validation Error):**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": {
    "first_name": ["First name is required"],
    "national_id": ["You already have a Qidha wallet account"]
  }
}
```

**What Happens:**
- Wallet is created with `status: "pending"`
- Wallet has `signature_status: 0` (not signed yet)
- All documents are uploaded and linked to wallet
- User can proceed to Step 3

#### 2. Get Wallet Status (After Creation)
**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response (200 OK):**
```json
{
  "message": "Wallet retrieved successfully",
  "wallet": {
    "id": 123,
    "serial_number": "QIDHA-2024-001",
    "user_id": 456,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "completed_at": null,
    "completed_by": null,
    "credit_limit": "50000.00",
    "minimum_due": "0.00",
    "available_balance": "50000.00",
    "used_balance": "0.00",
    "usage_percentage_limit": 80,
    "status": "pending",  // ⚠️ Status is "pending" at this stage
    "auto_lock_day": null,
    "manual_unlock_expiry_date": null,
    "usage_percentage_limit_by_monthly": 50,
    "signature_path": null,
    "signature_status": 0,  // ⚠️ Not signed yet (0 = not signed, 1 = signed)
    "lock_day": null,
    "minimum_due_limit": "5000.00",
    "purchase_limit": "40000.00",
    "used_percentage": 0,
    "total_avilable_balance": "50000.00"
  }
}
```

#### 3. Initiate Nafath Verification Request
**Endpoint:** `POST /api/qidha-wallet/nafath/initiate`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "national_id": "1234567890"
}
```

**Response (200/201 OK):**
```json
{
  "status": "sent",
  "externalResponse": [
    {
      "random": "123456",  // Verification code to enter in Nafath app
      "transactionId": "TXN-2024-001"
    }
  ]
}
```

**What Happens:**
- Nafath request is sent to backend
- User receives verification code (displayed in UI)
- User must:
  1. Open Nafath app on phone
  2. Find request with same code
  3. Complete authentication in Nafath app
  4. Return to app and click "Verify Authentication"

**Code Reference:**
- Repository: `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:44-80`
- Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart:1227-1351`

---

### Step 3: Contract Review & Signing

**Purpose:** Verify Nafath authentication and sign contract digitally.

**Endpoints Used:**

#### 1. Check Nafath Status (Final Verification)
**Endpoint:** `POST /api/qidha-wallet/nafath/checkStatus`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "national_id": "1234567890"
}
```

**Response (Approved - 200 OK):**
```json
{
  "status": "approved",
  "message": "Nafath verification successful",
  "transactionId": "TXN-2024-001"
}
```

**Response (Pending - 200 OK):**
```json
{
  "status": "pending",
  "message": "Waiting for user verification"
}
```

**Response (Failed/Rejected - 200 OK):**
```json
{
  "status": "failed",
  "message": "Nafath verification failed"
}
```

#### 2. Sign Contract & Submit All Data (FINAL STEP)
**Endpoint:** `POST /api/qidha-wallet/nafath/sign`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "national_id": "1234567890",
  "city": "الرياض",
  "neighborhood": "حي النرجس",
  "house_type": "apartment"
}
```

**Response (Success - 200/201/302):**
```json
{
  "status": true,
  "message": "Contract signed successfully",
  "data": {
    "wallet_id": 123,
    "signature_status": 1
  }
}
```

**What Happens:**
- Contract is digitally signed via Nafath
- Signature is linked to wallet
- Wallet signature_status is updated to 1 (signed)

#### 3. Update Wallet Status to Approved
**Endpoint:** `POST /api/v1/registration-activity`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "user_id": 123,
  "type": "qidha",
  "status": "approved",
  "form_data": {
    // All form data from Step 1 & 2
  }
}
```

**Response (200 OK):**
```json
{
  "status": true,
  "message": "Status updated successfully"
}
```

#### 4. Get Updated Wallet (After Signing)
**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**Response (200 OK):**
```json
{
  "message": "Wallet retrieved successfully",
  "wallet": {
    "id": 123,
    "serial_number": "QIDHA-2024-001",
    "user_id": 456,
    "status": "pending",  // Still pending until admin approval
    "signature_status": 1,  // ✅ Now signed!
    "signature_path": "/signatures/wallet_123_signature.pdf",
    "credit_limit": "50000.00",
    "available_balance": "50000.00",
    "used_balance": "0.00",
    "purchase_limit": "40000.00",
    "minimum_due_limit": "5000.00"
  }
}
```

**Code Reference:**
- Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart:406-600`
- Repository: `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:250-320`

---

## Waiting for Admin Approval

### Wallet Status: Pending

After completing all three steps, the wallet has:
- `status: "pending"` - Waiting for admin approval
- `signature_status: 1` - Contract signed
- All documents uploaded
- All information submitted

### Check Wallet Status

**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response (Pending Status):**
```json
{
  "message": "Wallet retrieved successfully",
  "wallet": {
    "id": 123,
    "status": "pending",  // ⚠️ Still pending
    "signature_status": 1,
    "credit_limit": "50000.00",
    "available_balance": "50000.00",
    "used_balance": "0.00"
  }
}
```

**Response (Approved Status):**
```json
{
  "message": "Wallet retrieved successfully",
  "wallet": {
    "id": 123,
    "status": "active",  // ✅ Approved and active!
    "signature_status": 1,
    "credit_limit": "50000.00",
    "available_balance": "50000.00",
    "used_balance": "0.00",
    "purchase_limit": "40000.00"
  }
}
```

**Response (Rejected Status):**
```json
{
  "message": "Wallet retrieved successfully",
  "wallet": {
    "id": 123,
    "status": "rejected",  // ❌ Rejected by admin
    "signature_status": 1,
    "rejection_reason": "Incomplete documents"
  }
}
```

### Wallet Status Values

- `"pending"` - Wallet created, waiting for admin approval
- `"approved"` - Wallet approved by admin (but may not be active yet)
- `"active"` - Wallet is active and can be used
- `"rejected"` - Wallet rejected by admin
- `"suspended"` - Wallet is suspended

**Code Reference:**
- Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart:200-250`
- Repository: `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:179-200`

---

## Active Wallet Usage

### Get Wallet Information

**Endpoint:** `GET /api/qidha-wallet/get-wallet`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response (200 OK - Active Wallet):**
```json
{
  "message": "Wallet retrieved successfully",
  "wallet": {
    "id": 123,
    "serial_number": "QIDHA-2024-001",
    "user_id": 456,
    "status": "active",  // ✅ Active wallet
    "signature_status": 1,
    "credit_limit": "50000.00",
    "minimum_due": "0.00",
    "available_balance": "45000.00",  // Available credit
    "used_balance": "5000.00",  // Amount used
    "usage_percentage_limit": 80,
    "usage_percentage_limit_by_monthly": 50,
    "minimum_due_limit": "5000.00",
    "purchase_limit": "40000.00",  // Maximum purchase per transaction
    "used_percentage": 10,
    "total_avilable_balance": "50000.00",
    "auto_lock_day": null,
    "manual_unlock_expiry_date": null,
    "lock_day": null,
    "signature_path": "/signatures/wallet_123_signature.pdf"
  }
}
```

**Key Fields:**
- `available_balance`: Available credit for purchases
- `used_balance`: Amount currently used
- `credit_limit`: Total credit limit
- `purchase_limit`: Maximum purchase per transaction
- `minimum_due_limit`: Minimum payment required
- `status`: Must be "active" to use wallet

**Code Reference:**
- Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart:200-250`
- Repository: `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart:179-200`

---

## Paying with Qidha Wallet

### Pre-requisites for Payment

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

### Payment Flow

#### Step 1: Create Order (Unpaid)

**Endpoint:** `POST /api/v1/customer/order/place`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Authorization: Bearer {token}
moduleId: {module_id}
zoneId: {zone_id}
latitude: {latitude}
longitude: {longitude}
```

**Request Body:**
```json
{
  "cart": [...],
  "order_type": "delivery",
  "store_id": 18,
  "order_amount": 50.0,
  "payment_method": "wallet_qidha",
  "distance": 2.5,
  "address": "123 Main Street, Riyadh",
  "latitude": "24.7136",
  "longitude": "46.6753",
  "contact_person_name": "John Doe",
  "contact_person_number": "+966501234567"
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

#### Step 2: Process Payment

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
  "wallet_balance": 44950.0
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

**Response (400/422 - Purchase Limit Exceeded):**
```json
{
  "message": "Purchase limit exceeded",
  "errors": {
    "purchase_limit": ["Maximum purchase: 40000.0 SAR, Requested: 50000.0 SAR"]
  }
}
```

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

**Code Reference:**
- Controller: `lib/features/checkout/controllers/checkout_controller.dart:1197-1296`
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart:227-261`
- Qidha Wallet Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart`

---

## Sending Funds (Wallet Transfer)

### Overview

Users can send funds from either their regular wallet or Qidha wallet to other users using their phone numbers.

### Step 1: Validate Recipient

**Endpoint:** `POST /api/v1/customer/wallet/validate-recipient`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "phone": "+966501234567"
}
```

**Response (200 OK - Valid Recipient):**
```json
{
  "success": true,
  "message": "Recipient validated successfully",
  "user": {
    "id": 789,
    "name": "Ahmed Ali",
    "phone": "+966501234567",
    "image": "https://example.com/user.jpg",
    "status": "active"
  }
}
```

**Response (200 OK - Invalid Recipient):**
```json
{
  "success": false,
  "message": "User not found",
  "error_code": "USER_NOT_FOUND"
}
```

**Phone Number Normalization:**
- Phone numbers are normalized to ensure they start with `+966`
- Formats accepted: `+966501234567`, `966501234567`, `0501234567`, `501234567`
- All formats are converted to: `+966501234567`

**Code Reference:**
- Controller: `lib/features/wallet_transfer/controllers/wallet_transfer_controller.dart:38-71`
- Service: `lib/features/wallet_transfer/domain/services/wallet_transfer_service.dart:17-23`
- Repository: `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:14-19`

---

### Step 2: Execute Transfer

**Endpoint:** `POST /api/v1/customer/wallet/transfer`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "recipient_phone": "+966501234567",
  "amount": 100.0,
  "payment_source": "wallet_qidha",  // "wallet" or "wallet_qidha"
  "save_recipient": false,
  "recipient_nickname": "Ahmed",  // Optional
  "message": "Payment for order"  // Optional
}
```

**Response (200 OK - Success):**
```json
{
  "success": true,
  "message": "Transfer successful",
  "data": {
    "transaction_id": "TXN-2024-001",
    "amount": 100.0,
    "recipient": {
      "name": "Ahmed Ali",
      "phone": "+966501234567"
    },
    "sender_new_balance": 44900.0,
    "payment_source": "wallet_qidha",
    "created_at": "2024-01-15T12:00:00Z"
  }
}
```

**Response (400 Bad Request - Insufficient Balance):**
```json
{
  "success": false,
  "message": "Insufficient balance",
  "error_code": "INSUFFICIENT_BALANCE",
  "available_balance": 30.0,
  "required_amount": 100.0
}
```

**Response (400 Bad Request - Daily Limit Exceeded):**
```json
{
  "success": false,
  "message": "Daily transfer limit exceeded",
  "error_code": "DAILY_LIMIT_EXCEEDED",
  "daily_limit": 5000.0,
  "already_spent": 4900.0,
  "remaining": 100.0,
  "requested_amount": 200.0
}
```

**Response (400 Bad Request - Invalid Recipient):**
```json
{
  "success": false,
  "message": "Recipient not found or invalid",
  "error_code": "USER_NOT_FOUND"
}
```

**What Happens:**
1. Recipient phone number is validated
2. Amount is checked against available balance
3. Daily transfer limits are checked (if applicable)
4. Transfer is processed
5. Sender's wallet balance is debited
6. Recipient's wallet balance is credited
7. Transaction record is created
8. Sender's wallet balance is refreshed

**Code Reference:**
- Controller: `lib/features/wallet_transfer/controllers/wallet_transfer_controller.dart:108-153`
- Service: `lib/features/wallet_transfer/domain/services/wallet_transfer_service.dart:26-32`
- Repository: `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:22-27`

---

### Step 3: Save Recipient (Optional)

**Endpoint:** `POST /api/v1/customer/wallet/saved-recipients`

**Headers:**
```
Content-Type: application/json; charset=UTF-8
Accept: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "recipient_phone": "+966501234567",
  "recipient_name": "Ahmed"  // Optional nickname
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Recipient saved successfully",
  "data": {
    "id": 1,
    "recipient_phone": "+966501234567",
    "recipient_name": "Ahmed",
    "created_at": "2024-01-15T12:00:00Z"
  }
}
```

**Get Saved Recipients:**
**Endpoint:** `GET /api/v1/customer/wallet/saved-recipients`

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "recipient_phone": "+966501234567",
      "recipient_name": "Ahmed",
      "created_at": "2024-01-15T12:00:00Z"
    }
  ]
}
```

**Code Reference:**
- Controller: `lib/features/wallet_transfer/controllers/wallet_transfer_controller.dart`
- Service: `lib/features/wallet_transfer/domain/services/wallet_transfer_service.dart:35-50`
- Repository: `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart:30-48`

---

## Complete Flow Diagrams

### Flow 1: Three-Step Wallet Creation

```
┌─────────────────────────────────────────┐
│ STEP 1: Personal Information           │
├─────────────────────────────────────────┤
│ 1. User fills form                      │
│ 2. Auto-save to SharedPreferences       │
│ 3. POST /api/v1/registration-activity  │
│    (status: "in_progress")              │
│ 4. Navigate to Step 2                   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ STEP 2: Income Verification             │
├─────────────────────────────────────────┤
│ 1. User fills employment details        │
│ 2. User uploads documents (max 5)      │
│ 3. POST /api/qidha-wallet/store         │
│    - Creates wallet (status: "pending") │
│    - Sets signature_status: 0           │
│    - Uploads documents                  │
│ 4. GET /api/qidha-wallet/get-wallet     │
│ 5. POST /api/qidha-wallet/nafath/      │
│    initiate                             │
│ 6. User completes Nafath auth           │
│ 7. Navigate to Step 3                   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ STEP 3: Contract Signing               │
├─────────────────────────────────────────┤
│ 1. POST /api/qidha-wallet/nafath/      │
│    checkStatus                          │
│    - Status must be "approved"          │
│ 2. POST /api/qidha-wallet/nafath/sign  │
│    - Signs contract                     │
│    - Updates signature_status to 1       │
│ 3. POST /api/v1/registration-activity  │
│    (status: "approved")                 │
│ 4. GET /api/qidha-wallet/get-wallet    │
│ 5. Navigate to waiting screen           │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ WAITING FOR ADMIN APPROVAL              │
├─────────────────────────────────────────┤
│ Status: "pending"                       │
│ Signature Status: 1                     │
│ Polling: GET /api/qidha-wallet/        │
│          get-wallet                     │
└─────────────────────────────────────────┘
```

---

### Flow 2: Paying with Qidha Wallet

```
┌─────────────────────────────────────────┐
│ User selects Qidha wallet payment      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Frontend Validations:                   │
│ 1. Wallet exists?                       │
│ 2. Wallet active?                       │
│ 3. Signature complete?                  │
│ 4. Balance sufficient?                 │
│ 5. Within purchase limit?               │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ POST /api/v1/customer/order/place      │
│ payment_method: "wallet_qidha"         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Response: order_id, status: "unpaid"   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ POST /api/v1/customer/order/           │
│       process-payment                   │
│ Body: order_id, payment_method:         │
│       "wallet_qidha", amount            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Backend:                                │
│ 1. Debit Qidha wallet balance          │
│ 2. Update order status to "paid"        │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Response: Payment successful            │
│ Frontend: Refresh wallet balance        │
└─────────────────────────────────────────┘
```

---

### Flow 3: Sending Funds

```
┌─────────────────────────────────────────┐
│ User enters recipient phone number      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ POST /api/v1/customer/wallet/          │
│       validate-recipient                │
│ Body: { "phone": "+966501234567" }     │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Response: Recipient validated          │
│ Shows: Name, Phone, Image               │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ User enters amount and selects source   │
│ (wallet or wallet_qidha)               │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ POST /api/v1/customer/wallet/transfer  │
│ Body: recipient_phone, amount,         │
│       payment_source, message           │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Backend:                                │
│ 1. Validate recipient                   │
│ 2. Check balance                        │
│ 3. Check daily limits                   │
│ 4. Process transfer                     │
│ 5. Update both wallets                  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Response: Transfer successful           │
│ Shows: Transaction ID, New Balance     │
│ Frontend: Refresh wallet balance        │
└─────────────────────────────────────────┘
```

---

## Error Handling

### Wallet Creation Errors

**400 Bad Request - Validation Error:**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": {
    "first_name": ["First name is required"],
    "national_id": ["You already have a Qidha wallet account"]
  }
}
```

**400 Bad Request - Duplicate Wallet:**
```json
{
  "status": false,
  "message": "User already has a Qidha wallet",
  "errors": {
    "national_id": ["You already have a Qidha wallet account"]
  }
}
```

### Nafath Errors

**400 Bad Request - Verification Failed:**
```json
{
  "status": "failed",
  "message": "Nafath verification failed"
}
```

**400 Bad Request - Request Expired:**
```json
{
  "status": "expired",
  "message": "Nafath request expired"
}
```

### Payment Errors

**400 Bad Request - Insufficient Balance:**
```json
{
  "message": "Insufficient balance in Qidha wallet",
  "errors": {
    "balance": ["Available balance: 30.0 SAR, Required: 50.0 SAR"]
  }
}
```

**400 Bad Request - Wallet Not Active:**
```json
{
  "message": "Qidha wallet is not active",
  "errors": {
    "wallet_status": ["Wallet must be active to make payments"]
  }
}
```

**400 Bad Request - Purchase Limit Exceeded:**
```json
{
  "message": "Purchase limit exceeded",
  "errors": {
    "purchase_limit": ["Maximum purchase: 40000.0 SAR, Requested: 50000.0 SAR"]
  }
}
```

### Transfer Errors

**400 Bad Request - Insufficient Balance:**
```json
{
  "success": false,
  "message": "Insufficient balance",
  "error_code": "INSUFFICIENT_BALANCE",
  "available_balance": 30.0,
  "required_amount": 100.0
}
```

**400 Bad Request - Daily Limit Exceeded:**
```json
{
  "success": false,
  "message": "Daily transfer limit exceeded",
  "error_code": "DAILY_LIMIT_EXCEEDED",
  "daily_limit": 5000.0,
  "already_spent": 4900.0,
  "remaining": 100.0,
  "requested_amount": 200.0
}
```

**400 Bad Request - Invalid Recipient:**
```json
{
  "success": false,
  "message": "Recipient not found or invalid",
  "error_code": "USER_NOT_FOUND"
}
```

---

## Constants Reference

**API Endpoints:**
- Get Wallet: `/api/qidha-wallet/get-wallet`
- Create Wallet: `/api/qidha-wallet/store`
- Nafath Initiate: `/api/qidha-wallet/nafath/initiate`
- Nafath Check Status: `/api/qidha-wallet/nafath/checkStatus`
- Nafath Sign: `/api/qidha-wallet/nafath/sign`
- Process Payment: `/api/v1/customer/order/process-payment`
- Validate Recipient: `/api/v1/customer/wallet/validate-recipient`
- Transfer: `/api/v1/customer/wallet/transfer`
- Saved Recipients: `/api/v1/customer/wallet/saved-recipients`

**Wallet Status Values:**
- `"pending"` - Waiting for admin approval
- `"approved"` - Approved by admin
- `"active"` - Active and can be used
- `"rejected"` - Rejected by admin
- `"suspended"` - Suspended

**Signature Status Values:**
- `0` - Not signed
- `1` - Signed

**Payment Source Values:**
- `"wallet"` - Regular wallet
- `"wallet_qidha"` - Qidha wallet

**Code Reference:**
- Constants: `lib/util/app_constants.dart:114-124, 265-266`

---

## Code File References

### Wallet Creation
- Controller: `lib/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart`
- Repository: `lib/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository.dart`
- Service: `lib/features/wallet_kaidha_subscription/domain/services/kaidhaSub_service.dart`

### Payment Processing
- Controller: `lib/features/checkout/controllers/checkout_controller.dart`
- Repository: `lib/features/checkout/domain/repositories/checkout_repository.dart`

### Wallet Transfer
- Controller: `lib/features/wallet_transfer/controllers/wallet_transfer_controller.dart`
- Service: `lib/features/wallet_transfer/domain/services/wallet_transfer_service.dart`
- Repository: `lib/features/wallet_transfer/data/repositories/wallet_transfer_repository.dart`
- Models: `lib/features/wallet_transfer/data/models/`

### Screens
- Wallet Creation: `lib/features/wallet_kaidha_subscription/screen/`
- Send Funds: `lib/features/wallet_transfer/screens/send_funds_screen.dart`
- Choose Receiver: `lib/features/wallet_transfer/screens/choose_receiver_screen.dart`

### Constants
- `lib/util/app_constants.dart`

---

## Notes

1. **Wallet Creation:**
   - Wallet is created with "pending" status after Step 2
   - Contract must be signed (Step 3) before admin can approve
   - Admin approval changes status from "pending" to "active"

2. **Nafath Verification:**
   - Verification code is displayed in UI
   - User must complete authentication in Nafath app
   - Status is checked via polling

3. **Payment Validation:**
   - Wallet must be active (not pending)
   - Signature status must be 1 (signed)
   - Balance must be sufficient
   - Purchase must be within limit

4. **Fund Transfer:**
   - Recipient must be validated first
   - Phone numbers are normalized to +966 format
   - Both regular and Qidha wallets can be used as source
   - Daily transfer limits may apply

5. **State Management:**
   - Form data is saved to SharedPreferences for recovery
   - Nafath requests are cached to avoid duplicates
   - Wallet balance is refreshed after transactions

6. **Error Handling:**
   - All errors are user-friendly in Arabic
   - Validation errors show specific field issues
   - Balance errors show available vs required amounts

---

**Last Updated:** 2024-01-01
**Version:** 1.0.0

