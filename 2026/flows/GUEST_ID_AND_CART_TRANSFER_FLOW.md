# Guest ID and Cart Transfer Flow - Complete Technical Documentation

## Overview

This document explains the complete guest user system, including how guest IDs are generated, how guests can add items to cart, why login is required for checkout, and how the cart is automatically transferred from guest to logged-in user.

---

## Table of Contents

1. [Guest ID Generation](#guest-id-generation)
2. [Guest Cart Operations](#guest-cart-operations)
3. [Login Requirement for Checkout](#login-requirement-for-checkout)
4. [Cart Transfer on Login](#cart-transfer-on-login)
5. [Backend Technical Details](#backend-technical-details)
6. [Complete Flow Diagrams](#complete-flow-diagrams)
7. [Code References](#code-references)

---

## Guest ID Generation

### Step 1: User Clicks "Continue as Guest"

**Location:** `lib/features/auth/widgets/guest_button_widget.dart:17-25`

**What Happens:**
```dart
authController.guestLogin().then((response) {
  if (response.isSuccess) {
    Get.find<ProfileController>().setForceFullyUserEmpty();
    Navigator.pushReplacementNamed(context, RouteHelper.getInitialRoute());
  }
});
```

### Step 2: Guest Login API Call

**Endpoint:** `POST /api/v1/auth/guest/request`

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "fcm_token": "device_fcm_token_here"
}
```

**Response (200 OK):**
```json
{
  "guest_id": "3954"
}
```

**Response (400 Bad Request):**
```json
{
  "message": "The guest id field is required."
}
```

**Code:**
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:120-145`
- Controller: `lib/features/auth/controllers/auth_controller.dart:guestLogin()`

### Step 3: Store Guest ID

**Storage Location:** SharedPreferences

**Key:** `AppConstants.guestId` (value: `'guest_id'`)

**Code:**
```dart
await saveSharedPrefGuestId(guestId);
```

**What Happens:**
1. Guest ID is received from backend
2. Guest ID is stored in SharedPreferences
3. Guest ID persists across app restarts
4. Guest ID is used for all cart operations

**Code:**
- Helper: `lib/helper/auth_helper.dart:9-11`
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:337-344`

### Step 4: Guest ID Usage

**Check if Guest:**
```dart
bool isGuest = AuthHelper.isGuestLoggedIn();
// Returns true if guest_id exists in SharedPreferences
```

**Get Guest ID:**
```dart
String guestId = AuthHelper.getGuestId();
// Returns guest_id from SharedPreferences or empty string
```

**Code:**
- Helper: `lib/helper/auth_helper.dart`
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:342-344`

---

## Guest Cart Operations

### How Guest ID is Used in Cart API Calls

All cart operations append `guest_id` as a query parameter when the user is not logged in.

### 1. Add to Cart

**Endpoint:** `POST /api/v1/customer/cart/add`

**For Guest Users:**
```
POST /api/v1/customer/cart/add?guest_id=3954
```

**For Logged-In Users:**
```
POST /api/v1/customer/cart/add
Authorization: Bearer {token}
```

**Request Body (Same for Both):**
```json
{
  "item_id": 1,
  "quantity": 2,
  "model": "Item",
  "price": "22.5",
  "variant": "none",
  "variation": [],
  "add_on_ids": [1, 2],
  "add_on_qtys": [1, 2]
}
```

**Code:**
```dart
String url = '${AppConstants.addCartUri}${!AuthHelper.isLoggedIn() ? '?guest_id=${AuthHelper.getGuestId()}' : ''}';
Response response = await apiClient.postData(url, cart.toJson());
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:51-69`

### 2. Get Cart List

**Endpoint:** `GET /api/v1/customer/cart/list`

**For Guest Users:**
```
GET /api/v1/customer/cart/list?guest_id=3954
```

**For Logged-In Users:**
```
GET /api/v1/customer/cart/list
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
[
  {
    "id": 123,
    "item_id": 1,
    "item": {
      "id": 1,
      "name": "Pizza",
      "price": 22.5
    },
    "quantity": 2,
    "price": 22.5,
    "variation": [],
    "add_ons": []
  }
]
```

**Code:**
```dart
String url = '${AppConstants.getCartListUri}${!AuthHelper.isLoggedIn() ? '?guest_id=${AuthHelper.getGuestId()}' : ''}';
Response response = await apiClient.getData(url, headers: header);
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:105-141`

### 3. Update Cart Item

**Endpoint:** `POST /api/v1/customer/cart/update`

**For Guest Users:**
```
POST /api/v1/customer/cart/update?guest_id=3954
```

**For Logged-In Users:**
```
POST /api/v1/customer/cart/update
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "cart_id": 123,
  "quantity": 3,
  "price": "22.5"
}
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart` (update method)

### 4. Remove Cart Item

**Endpoint:** `DELETE /api/v1/customer/cart/remove-item`

**For Guest Users:**
```
DELETE /api/v1/customer/cart/remove-item?cart_id=123&guest_id=3954
```

**For Logged-In Users:**
```
DELETE /api/v1/customer/cart/remove-item?cart_id=123
Authorization: Bearer {token}
```

**Code:**
```dart
String url = '${AppConstants.removeItemCartUri}?cart_id=$cartId${!AuthHelper.isLoggedIn() ? '&guest_id=${AuthHelper.getGuestId()}' : ''}';
Response response = await apiClient.deleteData(url);
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:80-87`

### 5. Clear Cart

**Endpoint:** `DELETE /api/v1/customer/cart/remove`

**For Guest Users:**
```
DELETE /api/v1/customer/cart/remove?guest_id=3954
```

**For Logged-In Users:**
```
DELETE /api/v1/customer/cart/remove
Authorization: Bearer {token}
```

**Code:**
```dart
String url = '${AppConstants.removeAllCartUri}${!AuthHelper.isLoggedIn() ? '?guest_id=${AuthHelper.getGuestId()}' : ''}';
Response response = await apiClient.deleteData(url);
```

**Code Reference:**
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:89-93`

### Local Cart Storage for Guests

**Why:** Guest cart items are stored locally in SharedPreferences to enable cart transfer after login.

**When:** After successful cart operations (add, update, etc.)

**Code:**
```dart
if (AuthHelper.isGuestLoggedIn() && _cartList.isNotEmpty) {
  await cartServiceInterface.addSharedPrefCartList(_cartList);
  debugPrint("💾 Guest cart items stored locally for future transfer");
}
```

**Storage Key:** `AppConstants.cartList` (value: `'cart_list'`)

**Code Reference:**
- Controller: `lib/features/cart/controllers/cart_controller.dart:554-558`
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:21-38`

---

## Login Requirement for Checkout

### Why Guests Must Login

**Reason:** Order placement requires user authentication for:
1. Payment processing (wallet, Qidha wallet)
2. Order tracking
3. Delivery address management
4. User account association

### Checkout Validation

**Location:** `lib/features/cart/screens/cart_screen.dart:1780-1805`

**What Happens:**
```dart
if (!isLoggedIn) {
  // Show login dialog/screen before checkout
  if (ResponsiveHelper.isDesktop(context)) {
    await Get.dialog(
      const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: true)),
      barrierDismissible: false,
    );
  } else {
    await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
  }
  
  // After login, validate location and proceed to checkout
  if (AuthHelper.isLoggedIn()) {
    bool isLocationValid = await _CartScreenState.validateLocationForCheckout();
    if (isLocationValid) {
      await _CartScreenState._calculateAndSetDistanceBeforeCheckout();
      Get.toNamed(RouteHelper.getCheckoutRoute('cart', storeId: null));
    }
  }
}
```

**Flow:**
1. User clicks "Proceed to Checkout"
2. App checks if user is logged in
3. If not logged in, show login screen/dialog
4. After successful login, validate location
5. Proceed to checkout

**Code Reference:**
- Cart Screen: `lib/features/cart/screens/cart_screen.dart:1780-1805`

---

## Cart Transfer on Login

### Overview

When a guest user logs in, their cart items are automatically transferred from the guest cart to the logged-in user's cart. This happens in two ways:

1. **Backend Transfer (Automatic):** Laravel backend transfers cart items when `guest_id` is sent with login request
2. **Frontend Transfer (Fallback):** Frontend transfers local cart items if backend transfer fails

### Step 1: Login with Guest ID

**Endpoint:** `POST /api/v1/auth/login`

**Request Body (with guest_id):**
```json
{
  "email_or_phone": "+966501234567",
  "password": "password123",
  "login_type": "manual",
  "field_type": "phone",
  "guest_id": "3954"
}
```

**What Backend Does:**
1. Validates credentials
2. Creates/retrieves user session
3. **Automatically transfers all cart items from `guest_id=3954` to `user_id={logged_in_user_id}`**
4. Returns auth token

**Code:**
```dart
String guestId = getSharedPrefGuestId();

Map<String, String> data = {
  "email_or_phone": emailOrPhone,
  "password": password,
  "login_type": loginType,
  "field_type": fieldType,
};

if (_shouldAttachGuestId(guestId)) {
  data.addAll({"guest_id": guestId});
}

Response response = await apiClient.postData(AppConstants.loginUri, data);
```

**Code Reference:**
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:59-83`

### Step 2: OTP Login with Guest ID

**Endpoint:** `POST /api/v1/auth/login`

**Request Body (with guest_id):**
```json
{
  "phone": "+966501234567",
  "login_type": "otp",
  "otp": "123456",
  "verified": "true",
  "guest_id": "3954"
}
```

**Code:**
```dart
String guestId = getSharedPrefGuestId();
Map<String, String> data = {
  "phone": phone,
  "login_type": loginType,
};

if (_shouldAttachGuestId(guestId)) {
  data.addAll({"guest_id": guestId});
}

if (otp.isNotEmpty) {
  data.addAll({"otp": otp});
}

Response response = await apiClient.postData(AppConstants.loginUri, data);
```

**Code Reference:**
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:86-107`

### Step 3: Frontend Cart Transfer Process

**Location:** `lib/features/auth/controllers/auth_controller.dart:212-257`

**What Happens:**
```dart
Future<void> _transferGuestCartToUser() async {
  // Prevent duplicate calls
  if (_isTransferringGuestCart) {
    return;
  }

  try {
    _isTransferringGuestCart = true;
    Get.find<CartController>().setTransferringGuestCart(true);
    
    debugPrint("🔄 Starting guest cart cleanup after login...");
    debugPrint("ℹ️ Laravel backend handles cart transfer automatically via guest_id");
    
    // Wait for Laravel to complete the guest cart transfer on the server
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Clear local cache (Laravel already transferred items on server)
    await Get.find<CartController>().clearLocalCacheOnly();
    debugPrint("🧹 Cleared local cart cache (Laravel already transferred items)");
    
    // Wait briefly for database consistency
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Force refresh cart data to get all items from server
    await Get.find<CartController>().getCartDataOnline(forceRefresh: true);
    
    debugPrint("✅ Guest cart cleanup and refresh completed");
  } catch (e) {
    debugPrint("❌ Error in guest cart cleanup: $e");
  } finally {
    _isTransferringGuestCart = false;
    Get.find<CartController>().setTransferringGuestCart(false);
    _isLoading = false;
    update();
  }
}
```

**Steps:**
1. Wait 500ms for backend to complete transfer
2. Clear local cart cache (SharedPreferences)
3. Wait 500ms for database consistency
4. Force refresh cart from server
5. Reset transfer flags

**Code Reference:**
- Controller: `lib/features/auth/controllers/auth_controller.dart:212-257`

### Step 4: Clear Guest ID

**When:** After successful login and cart transfer

**Code:**
```dart
// Clear guest data when user logs in successfully
authServiceInterface.clearSharedPrefGuestId();
```

**What Happens:**
1. Guest ID is removed from SharedPreferences
2. User is now fully authenticated
3. All future cart operations use user's auth token

**Code Reference:**
- Controller: `lib/features/auth/controllers/auth_controller.dart:202`
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:347-349`

### Fallback: Manual Cart Transfer

**Location:** `lib/features/cart/controllers/cart_controller.dart:966-1059`

**When Used:** If backend transfer fails or items are missing

**What It Does:**
```dart
Future<void> transferLocalCartToOnline() async {
  // Get local cart items from SharedPreferences
  List<CartModel> localCartItems = await _getLocalCartItems();
  
  if (localCartItems.isNotEmpty) {
    // Transfer each local item to online cart
    for (CartModel cartItem in localCartItems) {
      OnlineCart onlineCart = OnlineCart(
        cartItem.item!.id,
        null,
        cartItem.price?.toString() ?? '0',
        cartItem.variation!.isNotEmpty ? cartItem.variation![0].type ?? '' : '',
        cartItem.variation,
        null,
        cartItem.quantity,
        addOnIds,
        cartItem.addOns,
        addOnQtys,
        'Item',
        itemType: 'Item',
      );
      
      // Add to online cart
      bool success = await addToCartOnline(onlineCart);
    }
    
    // Clear local cart after transfer
    await _clearLocalCartItems();
  }
}
```

**Code Reference:**
- Controller: `lib/features/cart/controllers/cart_controller.dart:966-1059`

---

## Backend Technical Details

### Database Schema

**Guest Cart Table:**
```sql
CREATE TABLE guest_carts (
    id BIGINT PRIMARY KEY,
    guest_id VARCHAR(255) NOT NULL,
    item_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    variation JSON,
    add_on_ids JSON,
    add_on_qtys JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX idx_guest_id (guest_id)
);
```

**User Cart Table:**
```sql
CREATE TABLE user_carts (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    item_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    variation JSON,
    add_on_ids JSON,
    add_on_qtys JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Backend Cart Transfer Logic

**When:** User logs in with `guest_id` parameter

**Backend Process:**
```php
// Pseudo-code for Laravel backend
public function login(Request $request) {
    // Validate credentials
    $user = User::where('phone', $request->phone)->first();
    
    if (Hash::check($request->password, $user->password)) {
        // If guest_id is provided, transfer cart
        if ($request->has('guest_id')) {
            $guestId = $request->guest_id;
            
            // Get all cart items for this guest
            $guestCartItems = GuestCart::where('guest_id', $guestId)->get();
            
            // Transfer each item to user cart
            foreach ($guestCartItems as $guestItem) {
                // Check if user already has this item in cart
                $existingCart = UserCart::where('user_id', $user->id)
                    ->where('item_id', $guestItem->item_id)
                    ->where('variation', $guestItem->variation)
                    ->first();
                
                if ($existingCart) {
                    // Update quantity
                    $existingCart->quantity += $guestItem->quantity;
                    $existingCart->save();
                } else {
                    // Create new cart item
                    UserCart::create([
                        'user_id' => $user->id,
                        'item_id' => $guestItem->item_id,
                        'quantity' => $guestItem->quantity,
                        'price' => $guestItem->price,
                        'variation' => $guestItem->variation,
                        'add_on_ids' => $guestItem->add_on_ids,
                        'add_on_qtys' => $guestItem->add_on_qtys,
                    ]);
                }
            }
            
            // Delete guest cart items after transfer
            GuestCart::where('guest_id', $guestId)->delete();
        }
        
        // Generate auth token
        $token = $user->createToken('auth_token')->plainTextToken;
        
        return response()->json([
            'token' => $token,
            'user' => $user,
        ]);
    }
}
```

### API Endpoints Behavior

**Cart Endpoints with Guest ID:**

1. **Add to Cart:**
   - Guest: `POST /api/v1/customer/cart/add?guest_id=3954`
   - User: `POST /api/v1/customer/cart/add` (with Authorization header)

2. **Get Cart:**
   - Guest: `GET /api/v1/customer/cart/list?guest_id=3954`
   - User: `GET /api/v1/customer/cart/list` (with Authorization header)

3. **Update Cart:**
   - Guest: `POST /api/v1/customer/cart/update?guest_id=3954`
   - User: `POST /api/v1/customer/cart/update` (with Authorization header)

4. **Remove Item:**
   - Guest: `DELETE /api/v1/customer/cart/remove-item?cart_id=123&guest_id=3954`
   - User: `DELETE /api/v1/customer/cart/remove-item?cart_id=123` (with Authorization header)

5. **Clear Cart:**
   - Guest: `DELETE /api/v1/customer/cart/remove?guest_id=3954`
   - User: `DELETE /api/v1/customer/cart/remove` (with Authorization header)

**Order Endpoints:**

- **Place Order:**
  - Guest: `POST /api/v1/customer/order/place` (with `guest_id` in body)
  - User: `POST /api/v1/customer/order/place` (with Authorization header)

**Request Body for Guest Order:**
```json
{
  "cart": [...],
  "order_amount": 50.0,
  "payment_method": "cash_on_delivery",
  "guest_id": 3954,
  "guest_email": "guest@example.com",
  "contact_person_name": "John Doe",
  "contact_person_number": "+966501234567",
  ...
}
```

---

## Complete Flow Diagrams

### Flow 1: Guest User Journey

```
┌─────────────────────────────────────────┐
│ User Opens App (Not Logged In)         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ User Clicks "Continue as Guest"        │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ POST /api/v1/auth/guest/request        │
│ Body: { "fcm_token": "..." }          │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Response: { "guest_id": "3954" }       │
│ Store in SharedPreferences              │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ User Browses & Adds Items to Cart      │
│ POST /api/v1/customer/cart/add?        │
│       guest_id=3954                     │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Cart Items Stored:                      │
│ - Backend: guest_carts table            │
│ - Frontend: SharedPreferences           │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ User Clicks "Proceed to Checkout"      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ ❌ Login Required - Show Login Screen  │
└─────────────────────────────────────────┘
```

### Flow 2: Cart Transfer on Login

```
┌─────────────────────────────────────────┐
│ User Logs In                            │
│ POST /api/v1/auth/login                 │
│ Body: {                                │
│   "phone": "+966501234567",            │
│   "password": "password123",           │
│   "guest_id": "3954"  ← Guest ID!     │
│ }                                       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Backend:                                │
│ 1. Validate credentials                 │
│ 2. Get guest cart items (guest_id=3954)│
│ 3. Transfer to user cart (user_id=123) │
│ 4. Delete guest cart items              │
│ 5. Return auth token                    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Frontend:                                │
│ 1. Receive auth token                   │
│ 2. Clear guest_id from SharedPrefs     │
│ 3. Wait 500ms for backend transfer      │
│ 4. Clear local cart cache               │
│ 5. Refresh cart from server             │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Cart Now Belongs to Logged-In User     │
│ GET /api/v1/customer/cart/list         │
│ (with Authorization header)             │
└─────────────────────────────────────────┘
```

### Flow 3: Complete Guest to User Flow

```
┌─────────────────────────────────────────┐
│ 1. Guest Login                         │
│    → Get guest_id: "3954"             │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 2. Add Items to Cart (Guest)            │
│    → Backend: guest_carts table        │
│    → Frontend: SharedPreferences       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 3. Try to Checkout                     │
│    → ❌ Login Required                 │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 4. User Logs In                        │
│    → Send guest_id with login request  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 5. Backend Transfers Cart              │
│    → guest_carts → user_carts          │
│    → Delete guest_carts                │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 6. Frontend Cleans Up                  │
│    → Clear guest_id                    │
│    → Clear local cart cache            │
│    → Refresh cart from server          │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 7. User Can Now Checkout               │
│    → Cart belongs to logged-in user    │
└─────────────────────────────────────────┘
```

---

## Code References

### Guest ID Management
- Helper: `lib/helper/auth_helper.dart`
- Controller: `lib/features/auth/controllers/auth_controller.dart:285-295`
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:337-354`

### Guest Login
- Widget: `lib/features/auth/widgets/guest_button_widget.dart`
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:120-145`

### Cart Operations with Guest ID
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart`
  - Add: `51-69`
  - Get: `105-141`
  - Update: (update method)
  - Remove: `80-87`
  - Clear: `89-93`

### Cart Transfer
- Controller: `lib/features/auth/controllers/auth_controller.dart:212-257`
- Fallback: `lib/features/cart/controllers/cart_controller.dart:966-1059`

### Login with Guest ID
- Repository: `lib/features/auth/domain/reposotories/auth_repository.dart:59-107`

### Checkout Validation
- Cart Screen: `lib/features/cart/screens/cart_screen.dart:1780-1805`

### Local Cart Storage
- Repository: `lib/features/cart/domain/repositories/cart_repository.dart:21-38`
- Controller: `lib/features/cart/controllers/cart_controller.dart:554-558`

---

## Key Points

1. **Guest ID Generation:**
   - Generated by backend on "Continue as Guest"
   - Stored in SharedPreferences
   - Persists across app restarts

2. **Cart Operations:**
   - All cart APIs accept `guest_id` as query parameter
   - Guest cart stored in `guest_carts` table
   - User cart stored in `user_carts` table

3. **Login Requirement:**
   - Checkout requires authentication
   - Login screen shown when guest tries to checkout

4. **Cart Transfer:**
   - Automatic on backend when `guest_id` sent with login
   - Frontend clears local cache and refreshes
   - Guest ID is cleared after successful transfer

5. **Backend Behavior:**
   - Transfers all guest cart items to user cart
   - Merges quantities if item already exists
   - Deletes guest cart items after transfer

---

**Last Updated:** 2024-01-01
**Version:** 1.0.0

