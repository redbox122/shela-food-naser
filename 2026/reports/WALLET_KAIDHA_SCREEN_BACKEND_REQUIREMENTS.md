# Wallet Kaidha Screen - Backend Data Requirements

## Screen Route
**Route:** `/kaidha-allet`  
**Screen File:** `lib/features/wallet_kaidha_subscription/screen/wallet_kaidha_screen.dart`  
**Controller:** `KaidhaSubscription_Controller`

---

## API Endpoint

**Endpoint:** `GET /api/qidha-wallet/get-wallet`  
**Method:** GET  
**Auth Required:** ✅ Yes (Authorization header)  
**Response Format:** JSON

---

## What the User Sees

### 1. **Payment Details Section** (`PaymentDetails` widget)
Displays:
- **Lock Day** (تاريخ انتهاء الشهر): `lock_day`
- **Serial Number** (رقم المسلسل): `serial_number`
- **Status** (حالة المحفظة): `status` → Translated to Arabic (pending/available/closed)
- **Available Balance** (الرصيد المتاح): `credit_limit` (displayed as main balance)
- **Progress Bar**: Shows `used_percentage` (0-100%)
- **Card Limit** (حدد البطاقة): `available_balance` (remaining credit)

**Conditional Display:**
- **Contract Button** (عرض العقد): Only shown if `signature_status == 1` AND `signature_path` is not empty

### 2. **Status Warning** (if wallet is NOT active)
Shown when `status != 'active'`:
- Warning message based on status (pending/in_review/rejected/inactive)
- Description text explaining the status

### 3. **Payment Options** (`PaymentOptions` widget) - Only if status == 'active'
Displays two radio button options:
- **Full Due Amount** (المبلغ المستحق بالكامل): `used_balance`
- **Minimum Due Amount** (المبلغ الأدنى المستحق): `minimum_due_limit`

### 4. **Custom Amount Input** - Only if status == 'active'
- Text field for user to enter custom payment amount
- Validation:
  - Must be >= `minimum_due_limit`
  - Must be <= `used_balance`

### 5. **Payment Methods** - Only if status == 'active'
- Horizontal scrollable list of payment methods
- Loaded separately via `loadQidhaPaymentMethods(maximumDueAmount)` where `maximumDueAmount = used_balance`
- **Note:** Payment methods are loaded from MyFatoorah API, NOT from this endpoint

### 6. **Pay Now Button** (الدفع الآن) - Only if status == 'active'
- Triggers payment process with selected amount

---

## Required Backend Response Structure

### Response Format
```json
{
  "success": true,
  "message": "Wallet retrieved successfully",
  "data": {
    // Wallet object (see below)
  }
}
```

**OR** (backward compatibility - direct wallet object):
```json
{
  // Wallet object directly
}
```

### Wallet Object - EXACT Fields Required

```json
{
  "id": "integer or string",
  "serial_number": "string",
  "user_id": "integer or string",
  "created_at": "string (datetime)",
  "updated_at": "string (datetime)",
  "completed_at": "string (datetime) or null",
  "completed_by": "string or null",
  
  // ⚡ CRITICAL: These fields are displayed to user
  "credit_limit": "number (double)",           // Main available balance shown
  "available_balance": "number (double)",      // Remaining credit limit
  "used_balance": "number (double)",           // Full due amount (payment option 1)
  "minimum_due_limit": "number (double)",      // Minimum due (payment option 2)
  "used_percentage": "number (0-100)",         // For progress bar
  "status": "string",                          // "Active", "Pending", "Rejected", "Inactive", etc.
  "lock_day": "string or number",              // Month end date
  
  // Contract viewing (optional but recommended)
  "signature_status": "integer (0 or 1)",      // 1 = show contract button
  "signature_path": "string or null",          // PDF path if signed
  
  // Additional fields (used internally, not displayed)
  "minimum_due": "number or null",             // Fallback for minimum_due_limit
  "usage_percentage_limit": "number or null",
  "auto_lock_day": "string or null",
  "manual_unlock_expiry_date": "string or null",
  "usage_percentage_limit_by_monthly": "number or null",
  "lock_day": "string or number",
  "purchase_limit": "number or null",
  "total_avilable_balance": "number or null"
}
```

---

## Fields Actually Used by Frontend

### ✅ **REQUIRED** (Displayed to User)
1. `status` - **CRITICAL** - Determines if payment UI is shown
2. `credit_limit` - Main balance display
3. `available_balance` - Card limit display
4. `used_balance` - Full due amount option
5. `minimum_due_limit` - Minimum due option
6. `used_percentage` - Progress bar (0-100)
7. `lock_day` - Month end date
8. `serial_number` - Wallet serial number

### ⚠️ **CONDITIONAL** (Only if signature exists)
9. `signature_status` - Must be `1` to show contract button
10. `signature_path` - Must be non-empty string to show contract button

### 📦 **OPTIONAL** (Not displayed but may be used)
- `id`, `user_id`, `created_at`, `updated_at` - Metadata
- `completed_at`, `completed_by` - Completion info
- `minimum_due` - Fallback for `minimum_due_limit`
- Other fields - May be used for validation/logic but not displayed

---

## Backend Optimization Recommendations

### ✅ **SEND ONLY WHAT'S NEEDED**

**Minimum Required Response:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "serial_number": "QIDHA-12345",
    "status": "Active",
    "credit_limit": 5000.00,
    "available_balance": 3500.00,
    "used_balance": 1500.00,
    "minimum_due_limit": 500.00,
    "used_percentage": 30.0,
    "lock_day": "2024-12-31",
    "signature_status": 1,
    "signature_path": "/path/to/contract.pdf"
  }
}
```

### ❌ **DON'T SEND**
- Fields that are `null` and not used
- Internal metadata not displayed to user
- Duplicate fields (e.g., both `minimum_due` and `minimum_due_limit` - only need `minimum_due_limit`)

### ⚡ **Performance Notes**
- Response size should be **< 500 bytes** for optimal performance
- Frontend caches response (304 Not Modified supported)
- Payment methods are loaded separately (not from this endpoint)

---

## Status Values & UI Behavior

| Status Value | UI Behavior |
|-------------|-------------|
| `"Active"` | ✅ Shows payment options, custom amount, payment methods, pay button |
| `"Pending"` / `"in_review"` / `"review"` | ⚠️ Shows warning: "طلبك قيد المراجعة" |
| `"Inactive"` / `"disabled"` | ⚠️ Shows warning: "الحالة غير نشطة" |
| `"Rejected"` | ⚠️ Shows warning: "تم رفض الطلب" |
| Any other value | ⚠️ Shows warning: "حالة غير معروفة" |

---

## Payment Flow Data Requirements

When user clicks "الدفع الآن" (Pay Now):

1. **Selected Amount Calculation:**
   - Option 0 (Full): `used_balance`
   - Option 1 (Minimum): `minimum_due_limit`
   - Option 2 (Custom): User input (validated against `minimum_due_limit` and `used_balance`)

2. **Payment Methods:**
   - Loaded via separate API call: `loadQidhaPaymentMethods(maximumDueAmount)`
   - `maximumDueAmount` = `used_balance` (maximum that can be paid)
   - **NOT** included in `/api/qidha-wallet/get-wallet` response

3. **Payment Processing:**
   - Calls `Send_Pay_Credit(context, paymentAmount)`
   - Uses separate payment endpoint (not this one)

---

## Summary: Backend Should Send

### ✅ **MUST HAVE** (8 fields)
1. `status` - String ("Active", "Pending", etc.)
2. `credit_limit` - Number (main balance)
3. `available_balance` - Number (remaining credit)
4. `used_balance` - Number (full due)
5. `minimum_due_limit` - Number (minimum due)
6. `used_percentage` - Number (0-100)
7. `lock_day` - String/Number (month end)
8. `serial_number` - String

### ⚠️ **SHOULD HAVE** (if contract exists)
9. `signature_status` - Integer (0 or 1)
10. `signature_path` - String (non-empty)

### 📦 **NICE TO HAVE** (metadata)
- `id`, `user_id`, `created_at`, `updated_at`

### ❌ **DON'T NEED**
- Fields that are always null
- Duplicate fields
- Internal-only fields not displayed

---

## Example Optimized Response

```json
{
  "success": true,
  "message": "Wallet retrieved successfully",
  "data": {
    "id": 123,
    "serial_number": "QIDHA-2024-001234",
    "status": "Active",
    "credit_limit": 5000.00,
    "available_balance": 3500.00,
    "used_balance": 1500.00,
    "minimum_due_limit": 500.00,
    "used_percentage": 30.0,
    "lock_day": "2024-12-31",
    "signature_status": 1,
    "signature_path": "/storage/contracts/user_123_contract.pdf"
  }
}
```

**Size:** ~350 bytes (optimized) vs ~800+ bytes (with all fields)

---

## Notes for Backend Team

1. **Status is critical** - Must be exact string "Active" (case-sensitive) to show payment UI
2. **Numeric fields** - Can be sent as numbers (double/int) or strings (frontend parses both)
3. **Null handling** - Frontend handles nulls gracefully, but send only non-null values when possible
4. **Response wrapper** - Frontend supports both `{data: {...}}` wrapper and direct wallet object
5. **304 Not Modified** - Frontend supports caching, backend can return 304 if data unchanged
6. **Payment methods** - Loaded separately, NOT from this endpoint

---

**Last Updated:** Based on code analysis of `wallet_kaidha_screen.dart` and related widgets
