# Complete Guest User Flow - Technical Documentation

## Table of Contents
1. [App Launch & Guest ID Generation](#1-app-launch--guest-id-generation)
2. [Location Handling for Guests](#2-location-handling-for-guests)
3. [Browsing & Viewing Content](#3-browsing--viewing-content)
4. [Adding Items to Cart](#4-adding-items-to-cart)
5. [Cart Operations](#5-cart-operations)
6. [Checkout Requirement](#6-checkout-requirement)
7. [Login & Cart Transfer](#7-login--cart-transfer)
8. [Complete API Reference](#8-complete-api-reference)

---

## 1. App Launch & Guest ID Generation

### Step 1.1: User Opens Application (First Time)

**What Happens:**
- Application checks if user has authentication token
- Application checks if user has guest ID stored locally
- If neither exists, application automatically performs guest login

**Flow Logic:**
1. Check for existing authentication token
2. Check for existing guest ID in local storage
3. If token exists → Route to logged-in user flow
4. If guest ID exists → Route to guest user flow
5. If neither exists → Perform guest login automatically

### Step 1.2: Guest Login API Call

**Endpoint:** `POST /api/v1/auth/guest/request`

**Request Headers:**
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

**Implementation Technique:**
1. Send FCM token (for push notifications) to backend
2. Backend generates unique guest ID
3. Store guest ID in local storage (localStorage/sessionStorage)
4. Guest ID persists across application restarts

### Step 1.3: Store Guest ID

**Storage Location:** Local Storage (localStorage/sessionStorage)

**Storage Key:** `guest_id`

**Storage Format:**
```json
{
  "guest_id": "3954"
}
```

**What Happens:**
1. Guest ID received from backend (e.g., "3954")
2. Guest ID stored in local storage
3. Guest ID persists across application restarts
4. Guest ID used for all cart operations

**Retrieval:**
- Check if guest ID exists: `localStorage.getItem('guest_id')`
- Get guest ID: Returns stored value or empty string

---

## 2. Location Handling for Guests

### Step 2.1: Location Picker Screen Access

**When Guest Needs Location:**
- First time opening application (no saved address)
- When browsing stores (to show distance)
- Before checkout (required for delivery)
- When changing delivery location

**Navigation Flow:**
- For non-logged in users, navigate to location picker screen
- Desktop: Show location picker in modal dialog
- Mobile: Navigate to full-screen location picker

### Step 2.2: Location Picker Screen Components

**Key UI Components:**

1. **Google Map Display**
   - Interactive map showing current/default location
   - Displays green zone polygons (service delivery areas)
   - Supports panning and zooming
   - Initial zoom level: 16

2. **Search Location Widget**
   - Text input for searching addresses
   - Google Places autocomplete integration
   - Located at top of screen
   - Shows suggestions as user types

3. **Current Location Button**
   - Floating action button (bottom-right corner)
   - Icon: Location/GPS icon
   - Gets GPS location when clicked
   - Requests location permission if needed

4. **Pick Marker**
   - Center pin/marker showing selected location
   - Stays centered as user pans map
   - Updates position when map moves

5. **Green Zone Polygons**
   - Visual boundaries of service delivery areas
   - Green stroke with semi-transparent fill (20% opacity)
   - Shows where delivery is available
   - Stroke width: 2 pixels

6. **Pick Location Button**
   - Bottom button to confirm selection
   - Disabled if location outside service zone
   - Shows "Service not available in this area" if outside zone
   - Enabled only when location is validated

### Step 2.3: Green Zone Polygons (Service Area Boundaries)

**What Are Zone Polygons:**
- Visual representation of delivery service areas
- Green colored boundaries on the map
- Shows where orders can be delivered
- Created using convex hull algorithm covering all active zones

**How They're Fetched:**

**API Endpoint:**
```
GET /api/v1/config/get-zone-id
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Riyadh Central",
    "status": 1,
    "coordinates": [
      {"lat": 24.6, "lng": 46.5},
      {"lat": 24.7, "lng": 46.6},
      ...
    ],
    "formatedCoordinates": [
      {"lat": 24.6, "lng": 46.5},
      {"lat": 24.7, "lng": 46.6},
      ...
    ]
  }
]
```

**Polygon Building Technique:**
1. Fetch all active zones from API (status = 1)
2. Collect all coordinate points from active zones
3. Compute convex hull of all active zone points
4. Create single polygon covering all service areas
5. Display on map with green stroke and semi-transparent fill

**Polygon Appearance:**
- **Stroke Color:** Primary theme color (typically green)
- **Fill Color:** Primary color with 20% opacity (semi-transparent)
- **Stroke Width:** 2 pixels
- **Shape:** Convex hull covering all active service zones

**Caching Strategy:**
- Load zones from cache first (if available)
- Call API to get full zone data with coordinates
- Preserve existing zones if API fails (don't clear on error)

### Step 2.4: Current Location Button

**Functionality:**
- Gets user's current GPS location
- Requests location permission if needed
- Moves map camera to current location
- Updates pick marker position
- Validates if location is within service zone

**Permission Handling:**
1. Check if location permission already granted
2. If denied, show permission request dialog
3. If denied forever, show settings redirect

**Implementation Flow:**
1. User clicks current location button
2. Check location permission status
3. If denied, request permission
4. Get GPS coordinates using browser Geolocation API
5. Move map camera to current location
6. Update pick marker to current location
7. Reverse geocode coordinates to get address
8. Validate if location is within service zone
9. Update button state (enabled/disabled)

### Step 2.5: Map Selection (Pan & Pick)

**How It Works:**
1. User pans/drags map to desired location
2. Map camera moves, pick marker stays centered
3. When camera stops moving (`onCameraIdle` event):
   - Get coordinates from camera position
   - Reverse geocode to get address
   - Validate zone
   - Update button state

**Update Position Process:**
1. Get coordinates from camera position (lat/lng)
2. Call reverse geocoding API to get address
3. Call zone validation API
4. Update pick address and pick position
5. Enable/disable pick button based on zone validation

**Reverse Geocoding:**
- Use Google Maps Geocoding API or backend endpoint
- Convert coordinates to human-readable address
- Update address display in UI

### Step 2.6: Search Location Widget

**Features:**
- Google Places autocomplete
- Text input for searching addresses
- Shows suggestions as user types
- Moves map to selected address

**API Used:**
```
GET /api/v1/config/place-api-autocomplete?search_text={query}
```

**Response:**
```json
{
  "predictions": [
    {
      "description": "Riyadh, Saudi Arabia",
      "place_id": "ChIJ...",
      "structured_formatting": {
        "main_text": "Riyadh",
        "secondary_text": "Saudi Arabia"
      }
    }
  ]
}
```

**Implementation:**
1. User types in search input
2. Call autocomplete API with search text
3. Display suggestions dropdown
4. When user selects address:
   - Get place details (coordinates)
   - Move map camera to selected location
   - Update pick marker
   - Validate zone

### Step 2.7: Zone Validation

**What Happens:**
- When user selects location, application validates if it's within service zone
- If inside zone: Button enabled, shows "Pick Location"
- If outside zone: Button disabled, shows "Service not available in this area"

**Validation API:**
```
GET /api/v1/config/get-zone-id?lat={latitude}&lng={longitude}
```

**Response (Inside Zone):**
```json
{
  "zone_ids": [1, 2],
  "zone_data": [
    {
      "id": 1,
      "name": "Riyadh Central",
      "status": 1
    }
  ],
  "area_ids": [1]
}
```

**Response (Outside Zone):**
```json
{
  "zone_ids": [],
  "zone_data": [],
  "area_ids": []
}
```

**Validation Logic:**
1. Send coordinates to zone validation API
2. Check if `zone_ids` array is not empty
3. If zones found → Location is valid, enable button
4. If no zones → Location outside service area, disable button

### Step 2.8: Location Confirmation & Storage

**When User Clicks "Pick Location":**

**Process:**
1. Validate that location has valid coordinates
2. Validate that address is not empty
3. Get zone data for selected location
4. Create address object with:
   - Latitude and longitude
   - Address string
   - Zone ID and zone data
   - Area IDs
5. Store address in local storage
6. Navigate to home screen or checkout

**Storage Location:** Local Storage

**Storage Key:** `user_address`

**Address Model Structure:**
```json
{
  "latitude": "24.604301879077966",
  "longitude": "46.59593515098095",
  "addressType": "others",
  "zoneId": 1,
  "zoneIds": [1, 2],
  "address": "Riyadh, Saudi Arabia",
  "zoneData": [
    {
      "id": 1,
      "name": "Riyadh Central",
      "status": 1
    }
  ],
  "areaIds": [1]
}
```

**What Happens:**
1. User selects location on map (via pan, search, or current location)
2. Application validates zone (checks if inside green polygon)
3. Gets zone information from backend
4. Address stored in local storage
5. Location used for:
   - Showing store distances
   - Calculating delivery charges
   - Filtering available stores
   - Checkout delivery address

### Step 2.9: Complete Location Picker Flow

**Flow Diagram:**
```
┌─────────────────────────────────────────┐
│ User Opens Location Picker Screen       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Screen Initialization:                  │
│ 1. Fetch zone polygons (green areas)    │
│ 2. Load saved address (if exists)       │
│ 3. Or use default location              │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Map Displays:                           │
│ - Google Map                            │
│ - Green zone polygons                   │
│ - Pick marker (center pin)              │
│ - Search bar (top)                      │
│ - Current location button (bottom-right)│
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ User Interaction Options:               │
│                                         │
│ Option A: Use Current Location          │
│   → Click current location button       │
│   → Request GPS permission              │
│   → Get GPS coordinates                 │
│   → Move map to current location        │
│                                         │
│ Option B: Search Address                │
│   → Type in search bar                  │
│   → Select from autocomplete            │
│   → Map moves to selected address      │
│                                         │
│ Option C: Pan Map                       │
│   → Drag map to desired location        │
│   → Pick marker stays centered          │
│   → Address updates automatically      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Zone Validation:                        │
│ - App checks if location in green zone  │
│ - Calls zone validation API             │
│ - Updates button state                  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ User Clicks "Pick Location"             │
│ (Button enabled if in zone)             │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Location Saved:                         │
│ - Address stored in local storage       │
│ - Zone data saved                       │
│ - Navigation to home/checkout           │
└─────────────────────────────────────────┘
```

---

## 3. Browsing & Viewing Content

### Step 3.1: Home Screen Access

**Guest Can:**
- ✅ View all stores
- ✅ View all items/products
- ✅ Search stores and items
- ✅ View store details
- ✅ View item details
- ✅ View categories
- ✅ View banners/offers

**No Authentication Required:**
- All browsing operations work without login
- Guest ID is NOT required for viewing content
- Only cart operations require guest ID

### Step 3.2: API Calls for Browsing

**All browsing endpoints work WITHOUT guest_id:**

**Get Stores:**
```
GET /api/v1/stores/?type=latest&offset=0&limit=10
Headers:
  Content-Type: application/json
  X-Module-Id: 3
  X-Zone-Id: 1
  X-Localization: en
```

**Get Store Details:**
```
GET /api/v1/stores/details/123
Headers:
  Content-Type: application/json
  X-Module-Id: 3
  X-Zone-Id: 1
```

**Get Items:**
```
GET /api/v1/items/details/456
Headers:
  Content-Type: application/json
  X-Module-Id: 3
```

**Response Example:**
```json
{
  "id": 123,
  "name": "Pizza Store",
  "distance": 2.5,
  "rating": 4.5,
  "image": "https://...",
  "delivery_time": "30-40 min",
  "delivery_fee": 5.0
}
```

---

## 4. Adding Items to Cart

### Step 4.1: Add to Cart API Call

**Endpoint:** `POST /api/v1/customer/cart/add`

**For Guest Users:**
```
POST /api/v1/customer/cart/add
Content-Type: application/json
```

**Request Body (with guest_id in body):**
```json
{
  "item_id": 1,
  "quantity": 2,
  "model": "Item",
  "price": "22.5",
  "variant": "none",
  "variation": [],
  "add_on_ids": [1, 2],
  "add_on_qtys": [1, 2],
  "guest_id": "3954"
}
```

**For Logged-In Users:**
```
POST /api/v1/customer/cart/add
Content-Type: application/json
Authorization: Bearer {token}
```

**Request Body (without guest_id):**
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

**Implementation Technique:**
1. Check if user is logged in
2. If not logged in, get guest_id from local storage
3. Include guest_id in request body (for POST requests)
4. Send request to backend
5. Backend stores cart in `guest_carts` table (for guests) or `user_carts` table (for users)

**Response (200 OK):**
```json
[
  {
    "id": 123,
    "item_id": 1,
    "item": {
      "id": 1,
      "name": "Pizza",
      "price": 22.5,
      "image": "https://..."
    },
    "quantity": 2,
    "price": 22.5,
    "variation": [],
    "add_ons": [
      {
        "id": 1,
        "name": "Extra Cheese",
        "price": 2.0
      }
    ],
    "discount_on_item": 0,
    "tax_amount": 2.25
  }
]
```

### Step 4.2: Store Cart Locally (For Transfer)

**Why:** Guest cart items stored locally to enable cart transfer after login

**When:** After successful cart operations (add, update, etc.)

**Storage Location:** Local Storage

**Storage Key:** `cart_list`

**Storage Format:**
```json
[
  {
    "item_id": 1,
    "quantity": 2,
    "price": 22.5,
    "variation": [],
    "add_on_ids": [1, 2],
    "add_on_qtys": [1, 2]
  },
  {
    "item_id": 3,
    "quantity": 1,
    "price": 15.0,
    "variation": [],
    "add_on_ids": [],
    "add_on_qtys": []
  }
]
```

**Implementation:**
- After successful cart API call, store cart items in local storage
- Only store if user is guest (has guest_id)
- Used as fallback for cart transfer if backend transfer fails

---

## 5. Cart Operations

### 5.1: Get Cart List

**Endpoint:** `GET /api/v1/customer/cart/list`

**For Guest Users:**
```
GET /api/v1/customer/cart/list?guest_id=3954
Content-Type: application/json
```

**For Logged-In Users:**
```
GET /api/v1/customer/cart/list
Content-Type: application/json
Authorization: Bearer {token}
```

**Implementation:**
- For GET requests, guest_id is sent as query parameter
- For logged-in users, use Authorization header instead

**Response (200 OK):**
```json
[
  {
    "id": 123,
    "item_id": 1,
    "item": {
      "id": 1,
      "name": "Pizza",
      "price": 22.5,
      "image": "https://..."
    },
    "quantity": 2,
    "price": 22.5,
    "variation": [],
    "add_ons": [
      {
        "id": 1,
        "name": "Extra Cheese",
        "price": 2.0
      }
    ],
    "discount_on_item": 0,
    "tax_amount": 2.25,
    "total_price": 47.0
  }
]
```

### 5.2: Update Cart Item

**Endpoint:** `POST /api/v1/customer/cart/update`

**For Guest Users:**
```
POST /api/v1/customer/cart/update
Content-Type: application/json
```

**Request Body:**
```json
{
  "cart_id": 123,
  "quantity": 3,
  "price": "22.5",
  "guest_id": "3954"
}
```

**For Logged-In Users:**
```
POST /api/v1/customer/cart/update
Content-Type: application/json
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

**Implementation:**
- Include guest_id in request body for POST requests
- For logged-in users, guest_id is not needed

### 5.3: Remove Cart Item

**Endpoint:** `DELETE /api/v1/customer/cart/remove-item`

**For Guest Users:**
```
DELETE /api/v1/customer/cart/remove-item?cart_id=123&guest_id=3954
Content-Type: application/json
```

**For Logged-In Users:**
```
DELETE /api/v1/customer/cart/remove-item?cart_id=123
Content-Type: application/json
Authorization: Bearer {token}
```

**Implementation:**
- For DELETE requests, guest_id is sent as query parameter
- HTTP DELETE requests typically don't support request body
- Backend should accept guest_id in query string for DELETE requests

**Response:**
- 200 OK: Successfully deleted
- 404 Not Found: Item already doesn't exist (also treated as success)

### 5.4: Clear Cart

**Endpoint:** `DELETE /api/v1/customer/cart/remove`

**For Guest Users:**
```
DELETE /api/v1/customer/cart/remove?guest_id=3954
Content-Type: application/json
```

**For Logged-In Users:**
```
DELETE /api/v1/customer/cart/remove
Content-Type: application/json
Authorization: Bearer {token}
```

**Implementation:**
- guest_id sent as query parameter for DELETE requests
- Clears all items from cart

---

## 6. Checkout Requirement

### Step 6.1: Checkout Validation

**Why Login Required:**
1. Payment processing (wallet, Qidha wallet, credit cards)
2. Order tracking and history
3. Delivery address management
4. User account association
5. Order notifications

**Flow:**
1. User clicks "Proceed to Checkout"
2. Application checks if user is logged in
3. If not logged in:
   - Show login screen/dialog
   - User logs in
   - Validate location
   - Proceed to checkout
4. If logged in:
   - Validate location
   - Proceed to checkout

**Implementation:**
- Check authentication token before allowing checkout
- Redirect to login screen if not authenticated
- After login, automatically proceed to checkout
- Validate delivery location before checkout

### Step 6.2: Checkout Screen Validation

**Validation Checks:**
- User must be logged in (or guest checkout enabled in config)
- Delivery address must be selected
- Location must be within service zone

**Note:** Guest checkout can be enabled via backend configuration, but typically requires login.

---

## 7. Login & Cart Transfer

### Step 7.1: Login with Guest ID

**Endpoint:** `POST /api/v1/auth/customer-login`

**Request Headers:**
```
Content-Type: application/json
Accept: application/json
```

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

**Implementation Technique:**
1. Before login, check if guest_id exists in local storage
2. If guest_id exists and user has items in cart, include it in login request
3. Backend automatically transfers cart when guest_id is provided

**Response (200 OK):**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 123,
    "f_name": "John",
    "l_name": "Doe",
    "phone": "+966501234567",
    "email": "john@example.com"
  }
}
```

### Step 7.2: Backend Cart Transfer (Automatic)

**What Backend Does:**
1. Validates credentials
2. Creates/retrieves user session
3. **Automatically transfers all cart items from `guest_id=3954` to `user_id=123`**
4. Deletes guest cart items
5. Returns auth token

**Backend Process (Pseudo-code):**
```php
// Laravel backend
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
                    // Update quantity (merge)
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

**Key Points:**
- Cart transfer happens automatically on backend
- Items are merged if user already has same item in cart
- Guest cart is deleted after successful transfer
- No additional API call needed for transfer

### Step 7.3: Frontend Cart Transfer Process

**Steps:**
1. Wait 500ms for backend to complete transfer
2. Clear local cart cache (localStorage)
3. Wait 500ms for database consistency
4. Force refresh cart from server
5. Reset transfer flags

**Implementation:**
- After successful login, wait briefly for backend transfer
- Clear local cart storage (cart_list from localStorage)
- Refresh cart data from server to get transferred items
- Update UI with new cart data

**Why Wait:**
- Backend needs time to complete database operations
- Ensures data consistency before refreshing
- Prevents race conditions

### Step 7.4: Clear Guest ID

**When:** After successful login and cart transfer

**Process:**
1. Remove guest_id from local storage
2. User is now fully authenticated
3. All future cart operations use user's auth token
4. Cart now belongs to logged-in user

**Implementation:**
- Remove `guest_id` from localStorage
- Store authentication token
- Update all API calls to use Authorization header instead of guest_id

---

## 8. Complete API Reference

### 8.1: Guest Login

**Endpoint:** `POST /api/v1/auth/guest/request`

**Request:**
```json
{
  "fcm_token": "device_fcm_token"
}
```

**Response:**
```json
{
  "guest_id": "3954"
}
```

### 8.2: Cart Operations

#### Add to Cart
**Endpoint:** `POST /api/v1/customer/cart/add`

**Guest Request:**
```json
{
  "item_id": 1,
  "quantity": 2,
  "model": "Item",
  "price": "22.5",
  "variant": "none",
  "variation": [],
  "add_on_ids": [1, 2],
  "add_on_qtys": [1, 2],
  "guest_id": "3954"
}
```

**User Request:**
```
Headers: Authorization: Bearer {token}
```
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

#### Get Cart List
**Endpoint:** `GET /api/v1/customer/cart/list`

**Guest:** `GET /api/v1/customer/cart/list?guest_id=3954`

**User:** `GET /api/v1/customer/cart/list` (with Authorization header)

#### Update Cart
**Endpoint:** `POST /api/v1/customer/cart/update`

**Guest Request:**
```json
{
  "cart_id": 123,
  "quantity": 3,
  "price": "22.5",
  "guest_id": "3954"
}
```

**User Request:**
```
Headers: Authorization: Bearer {token}
```
```json
{
  "cart_id": 123,
  "quantity": 3,
  "price": "22.5"
}
```

#### Remove Item
**Endpoint:** `DELETE /api/v1/customer/cart/remove-item`

**Guest:** `DELETE /api/v1/customer/cart/remove-item?cart_id=123&guest_id=3954`

**User:** `DELETE /api/v1/customer/cart/remove-item?cart_id=123` (with Authorization header)

#### Clear Cart
**Endpoint:** `DELETE /api/v1/customer/cart/remove`

**Guest:** `DELETE /api/v1/customer/cart/remove?guest_id=3954`

**User:** `DELETE /api/v1/customer/cart/remove` (with Authorization header)

### 8.3: Login with Guest ID

**Endpoint:** `POST /api/v1/auth/customer-login`

**Request:**
```json
{
  "email_or_phone": "+966501234567",
  "password": "password123",
  "login_type": "manual",
  "field_type": "phone",
  "guest_id": "3954"
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 123,
    "f_name": "John",
    "l_name": "Doe",
    "phone": "+966501234567",
    "email": "john@example.com"
  }
}
```

### 8.4: Place Order

**Endpoint:** `POST /api/v1/customer/order/place`

**Guest Request:**
```json
{
  "cart": [...],
  "order_amount": 50.0,
  "payment_method": "cash_on_delivery",
  "guest_id": 3954,
  "guest_email": "guest@example.com",
  "contact_person_name": "John Doe",
  "contact_person_number": "+966501234567",
  "address": "Riyadh, Saudi Arabia",
  "latitude": "24.604301879077966",
  "longitude": "46.59593515098095",
  "distance": 2.5,
  "tax_amount": 5.0,
  "discount_amount": 0,
  "delivery_charge": 5.0
}
```

**User Request:**
```
Headers: Authorization: Bearer {token}
```
```json
{
  "cart": [...],
  "order_amount": 50.0,
  "payment_method": "cash_on_delivery",
  "address": "Riyadh, Saudi Arabia",
  "latitude": "24.604301879077966",
  "longitude": "46.59593515098095",
  "distance": 2.5,
  "tax_amount": 5.0,
  "discount_amount": 0,
  "delivery_charge": 5.0
}
```

### 8.5: Location APIs

#### Get Zone Polygons
**Endpoint:** `GET /api/v1/config/get-zone-id`

**Response:**
```json
[
  {
    "id": 1,
    "name": "Riyadh Central",
    "status": 1,
    "formatedCoordinates": [
      {"lat": 24.6, "lng": 46.5},
      {"lat": 24.7, "lng": 46.6}
    ]
  }
]
```

#### Validate Zone
**Endpoint:** `GET /api/v1/config/get-zone-id?lat={latitude}&lng={longitude}`

**Response (Inside Zone):**
```json
{
  "zone_ids": [1, 2],
  "zone_data": [
    {
      "id": 1,
      "name": "Riyadh Central",
      "status": 1
    }
  ],
  "area_ids": [1]
}
```

**Response (Outside Zone):**
```json
{
  "zone_ids": [],
  "zone_data": [],
  "area_ids": []
}
```

#### Address Autocomplete
**Endpoint:** `GET /api/v1/config/place-api-autocomplete?search_text={query}`

**Response:**
```json
{
  "predictions": [
    {
      "description": "Riyadh, Saudi Arabia",
      "place_id": "ChIJ...",
      "structured_formatting": {
        "main_text": "Riyadh",
        "secondary_text": "Saudi Arabia"
      }
    }
  ]
}
```

---

## Summary Flow Diagram

```
┌─────────────────────────────────────────┐
│ 1. User Opens Application               │
│    → No token, no guest_id               │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 2. Auto Guest Login                     │
│    POST /api/v1/auth/guest/request      │
│    → Receive guest_id: "3954"           │
│    → Store in local storage              │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 3. Location Selection (if needed)       │
│    → User selects location              │
│    → Store in local storage              │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 4. Browse & View Content                │
│    → View stores, items, categories     │
│    → No authentication required         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 5. Add Items to Cart                    │
│    POST /api/v1/customer/cart/add      │
│    Body: {..., "guest_id": "3954"}     │
│    → Backend: guest_carts table        │
│    → Frontend: local storage            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 6. Try to Checkout                      │
│    → ❌ Login Required                  │
│    → Show login screen                  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 7. User Logs In                         │
│    POST /api/v1/auth/customer-login     │
│    Body: {..., "guest_id": "3954"}     │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 8. Backend Transfers Cart               │
│    → guest_carts → user_carts           │
│    → Delete guest_carts                 │
│    → Return auth token                  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 9. Frontend Cleans Up                   │
│    → Clear guest_id from storage        │
│    → Clear local cart cache             │
│    → Refresh cart from server           │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 10. User Can Now Checkout                │
│     → Cart belongs to logged-in user    │
│     → Place order with auth token       │
└─────────────────────────────────────────┘
```

---

## Key Points

1. **Guest ID Generation:**
   - Generated by backend on first application launch or "Continue as Guest"
   - Stored in local storage (localStorage)
   - Persists across application restarts
   - Used for all cart operations

2. **Location Handling:**
   - Guest can select location via map, search, or GPS
   - Location stored in local storage
   - Zone validation ensures location is within service area
   - Green polygons visualize service boundaries
   - Used for store distances and delivery charges

3. **Browsing:**
   - No authentication required
   - Guest can view all content
   - Guest ID NOT needed for browsing operations

4. **Cart Operations:**
   - All cart APIs accept `guest_id` in request body (POST) or query (GET/DELETE)
   - Guest cart stored in `guest_carts` table on backend
   - User cart stored in `user_carts` table on backend
   - Cart also stored locally for transfer fallback

5. **Checkout Requirement:**
   - Login required for checkout
   - Login screen shown when guest tries to checkout
   - Location must be validated before checkout

6. **Cart Transfer:**
   - Automatic on backend when `guest_id` sent with login request
   - Frontend clears local cache and refreshes
   - Guest ID cleared after successful transfer
   - Items merged if user already has same items in cart

7. **Backend Behavior:**
   - Transfers all guest cart items to user cart
   - Merges quantities if item already exists
   - Deletes guest cart items after transfer
   - Returns authentication token

8. **Location Picker Techniques:**
   - Google Maps integration for map display
   - Zone polygons displayed as green boundaries
   - Convex hull algorithm for polygon creation
   - Reverse geocoding for address lookup
   - Zone validation API for service area checking
   - Google Places autocomplete for address search

---

**Last Updated:** 2025-01-27
**Version:** 3.0.0
