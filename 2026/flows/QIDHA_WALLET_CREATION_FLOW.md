# Qidha Wallet Creation - Complete Flow Documentation

## Overview
This document details the complete flow for creating a Qidha wallet, from Step 1 (Personal Information) through Step 3 (Contract Signing) to final wallet creation.

---

## Flow Summary

```
Step 1 (Personal Info) → Step 2 (Income Verification) → Step 3 (Contract Signing)
    ↓                           ↓                              ↓
Form Validation          Wallet Creation              Nafath Verification
    ↓                           ↓                              ↓
Save State              POST /api/qidha-wallet/store   POST /api/qidha-wallet/nafath/sign
    ↓                           ↓                              ↓
Navigate to Step 2      Navigate to Step 3            Update Status & Navigate
```

---

## STEP 1: Personal Information & Contract Review

### What We're Doing
- User fills personal information form
- Validates all required fields
- Saves form state to SharedPreferences
- Sends state to backend (status: "in_progress")
- Navigates to Step 2

### Endpoints Used

#### 1. Save State (Auto-save on form changes)
**Endpoint:** `POST /api/registration-activity`
**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
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

**Response:**
```json
{
  "status": true,
  "message": "State saved successfully"
}
```

### Data Collected in Step 1
- **Personal Info:**
  - `first_name` (First name)
  - `father_name` (Father's name)
  - `grandfather_name` (Grandfather's name)
  - `last_name` (Last name)
  - `birth_date` (Birth date)
  - `nationality` (National ID)
  - `marital_status` (Marital status)
  - `number_of_family_members` (Number of family members)
  - `identity_card_number` (Identity card number)
  - `end_date` (ID expiration date)
  - `mobile` (Phone number - from profile)

- **Address Info:**
  - `house_type` (House type: apartment/villa/etc)
  - `city` (City)
  - `neighborhood` (Neighborhood)

- **Employment Info:**
  - `name_of_employer` (Employer name)
  - `total_salary` (Total salary)
  - `installments` (Installments)
  - `source_of_income` (Job specification: government/private_sector/freelance_work/retired)
  - `monthly_amount` (Monthly income)
  - `salary_day` (Salary day of month)

---

## STEP 2: Income Verification & Document Upload

### What We're Doing
1. User fills employment details (job specification, salary day, monthly income)
2. User uploads documents (max 5 files: JPG, PNG, or PDF)
3. Each document must have a name/description
4. **Creates wallet with pending status** (signature_status = 0)
5. Initiates Nafath verification request
6. Navigates to Step 3

### Endpoints Used

#### 1. Create Wallet (IMMEDIATE - Called when Step 2 is validated)
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
... (up to 5 files)
```

**Response (Success - 200/201):**
```json
{
  "status": true,
  "message": "Wallet created successfully",
  "data": {
    "wallet_id": 123
  }
}
```

**Response (Error - Validation):**
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

---

#### 2. Get Wallet Status (After Creation)
**Endpoint:** `GET /api/qidha-wallet/get-wallet`
**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
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

---

#### 3. Initiate Nafath Verification Request
**Endpoint:** `POST /api/qidha-wallet/nafath/initiate`
**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "national_id": "1234567890"
}
```

**Response (Success - 200/201):**
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

---

#### 4. Check Nafath Status (Polling)
**Endpoint:** `POST /api/qidha-wallet/nafath/checkStatus`
**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "national_id": "1234567890"
}
```

**Response (Pending):**
```json
{
  "status": "pending",
  "message": "Waiting for user verification"
}
```

**Response (Approved):**
```json
{
  "status": "approved",
  "message": "Nafath verification successful",
  "transactionId": "TXN-2024-001"
}
```

**Response (Failed/Rejected):**
```json
{
  "status": "failed",
  "message": "Nafath verification failed"
}
```

---

## STEP 3: Contract Review & Signing

### What We're Doing
1. User reviews contract PDF (optional)
2. User verifies Nafath authentication
3. **Final Nafath verification check**
4. **Signs contract** (submits signature data)
5. **Updates wallet signature status to 1** (signed)
6. Navigates to waiting screen

### Endpoints Used

#### 1. Get Contract PDF (Optional - For Review)
**Endpoint:** `GET /api/qidha-wallet/contract-pdf` (unsigned)
**OR:** `GET /api/qidha-wallet/signed-pdf` (signed - if already signed)

**Headers:**
```
Authorization: Bearer {token}
Accept: application/pdf
```

**Response:**
- Binary PDF file (5 pages if unsigned, 6 pages if signed)

---

#### 2. Final Nafath Verification Check
**Endpoint:** `POST /api/qidha-wallet/nafath/checkStatus`
**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "national_id": "1234567890"
}
```

**Response (Must be "approved" to proceed):**
```json
{
  "status": "approved",
  "message": "Nafath verification successful"
}
```

---

#### 3. Sign Contract & Submit All Data (FINAL STEP)
**Endpoint:** `POST /api/qidha-wallet/nafath/sign`
**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
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

---

#### 4. Update Wallet Status to Approved
**Endpoint:** `POST /api/registration-activity`
**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
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

**Response:**
```json
{
  "status": true,
  "message": "Status updated successfully"
}
```

---

#### 5. Get Updated Wallet (After Signing)
**Endpoint:** `GET /api/qidha-wallet/get-wallet`
**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
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
    // ... other fields
  }
}
```

---

## Complete Flow Sequence

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Personal Information                                │
├─────────────────────────────────────────────────────────────┤
│ 1. User fills form                                           │
│ 2. Auto-save to SharedPreferences (debounced)                │
│ 3. POST /api/registration-activity (status: "in_progress")   │
│ 4. Navigate to Step 2                                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Income Verification                                 │
├─────────────────────────────────────────────────────────────┤
│ 1. User fills employment details                            │
│ 2. User uploads documents (max 5 files)                     │
│ 3. POST /api/qidha-wallet/store                             │
│    - Creates wallet with status: "pending"                  │
│    - Sets signature_status: 0                                │
│    - Uploads all documents                                   │
│ 4. GET /api/qidha-wallet/get-wallet (refresh)              │
│ 5. POST /api/qidha-wallet/nafath/initiate                  │
│    - Gets verification code                                  │
│ 6. User completes Nafath authentication                     │
│ 7. Navigate to Step 3                                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Contract Signing                                   │
├─────────────────────────────────────────────────────────────┤
│ 1. User reviews contract (optional)                          │
│    GET /api/qidha-wallet/contract-pdf                       │
│ 2. User clicks "Verify Authentication"                       │
│    POST /api/qidha-wallet/nafath/checkStatus                │
│    - Status must be "approved"                               │
│ 3. User clicks "Sign Contract"                              │
│    POST /api/qidha-wallet/nafath/sign                       │
│    - Signs contract digitally                                │
│    - Updates signature_status to 1                           │
│ 4. POST /api/registration-activity (status: "approved")     │
│ 5. GET /api/qidha-wallet/get-wallet (refresh)              │
│ 6. Navigate to waiting screen                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Data Mappings

### Job Specification Mapping
| UI Value | Server Value |
|----------|--------------|
| "government employee" | "government" |
| "private sector employee" | "private_sector" |
| "self-employed" | "freelance_work" |
| "retired" | "retired" |

### Wallet Status Values
- `"pending"` - Wallet created, waiting for admin approval
- `"approved"` - Wallet approved by admin
- `"rejected"` - Wallet rejected by admin
- `"active"` - Wallet is active and can be used
- `"suspended"` - Wallet is suspended

### Signature Status Values
- `0` - Not signed (wallet created but contract not signed)
- `1` - Signed (contract digitally signed via Nafath)

---

## Error Handling

### Common Errors

1. **Validation Errors (400)**
   - Missing required fields
   - Invalid data format
   - User already has a wallet

2. **Nafath Errors**
   - Verification failed/rejected
   - Request expired
   - User didn't complete authentication

3. **Server Errors (500)**
   - Internal server error
   - Database error

4. **Unauthorized (401)**
   - Token expired
   - User not logged in

---

## State Management

### SharedPreferences Key: `'qidha'`
Stores form data locally for recovery:
```json
{
  "firstname": "محمد",
  "fathername": "علي",
  "grandfathername": "أحمد",
  "last_name": "السالم",
  "birthDate": "1990-01-15",
  "nationality": "1234567890",
  "marital_status": "married",
  "number_of_family_members": "5",
  "identity_card_number": "1234567890",
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
```

### Nafath Request Caching
- Cached in SharedPreferences with key: `'nafath_request_cache'`
- Cache expires after 1 hour
- Used to avoid duplicate Nafath requests

---

## Final Result

After completing all 3 steps:
- ✅ Wallet created with all user data
- ✅ Documents uploaded and linked
- ✅ Contract digitally signed via Nafath
- ✅ Wallet status: "pending" (waiting for admin approval)
- ✅ Signature status: 1 (signed)
- ✅ User navigated to waiting screen

The wallet will be activated once admin approves it, changing status from "pending" to "approved" or "active".

