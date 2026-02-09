# Global Location Selection with Zone Validation at Checkout

## Overview

This feature allows users from **anywhere in the world** to set their location and browse the app, but **enforces strict zone validation** when they attempt to checkout. This provides a flexible browsing experience while ensuring orders can only be placed within serviceable delivery zones.

---

## Feature Flow

### Phase 1: Global Location Selection (Browsing Mode)

**Users can set their location from anywhere in the world:**

1. **Location Selection Options:**
   - Users can use their current GPS location (anywhere globally)
   - Users can manually select a location on the map (anywhere globally)
   - Users can search for any address worldwide

2. **Zone Validation Bypass:**
   - When setting location for **browsing purposes**, the app uses `skipZoneValidation: true`
   - This allows users to explore the app regardless of their location
   - Location is saved to SharedPreferences for app-wide use

3. **Code Implementation:**
   ```dart
   // Location can be set from anywhere
   Get.find<LocationController>().saveAddressAndNavigate(
     context,
     address,
     fromSignUp,
     route,
     canRoute,
     isDesktop,
     skipZoneValidation: true,  // ⚠️ Allows browsing from anywhere
   );
   ```

**Location:** `lib/features/location/controllers/location_controller.dart:819-830`

---

### Phase 2: Checkout Zone Validation (Strict Mode)

**When user clicks "Proceed to Checkout", zone validation is ALWAYS enforced:**

1. **Pre-Checkout Validation:**
   - Before navigating to checkout screen, location is validated
   - Zone API is called to check if location is within service zone
   - If outside zone, checkout is blocked and location picker dialog is shown

2. **Critical Validation Logic:**
   ```dart
   // ⚠️ CRITICAL: Checkout ALWAYS requires a valid zone, 
   // regardless of skipZoneValidation flag
   // The skipZoneValidation flag is only for browsing the app, not for checkout
   
   ZoneResponseModel response = await locationController.getZone(
     currentAddress.latitude, 
     currentAddress.longitude, 
     false  // ⚠️ Zone validation is NEVER skipped for checkout
   );
   
   if (response.isSuccess && response.zoneIds.isNotEmpty) {
     // Location is in service zone, proceed with checkout
     return true;
   } else {
     // Location is outside service zone, show location picker dialog
     showLocationPickerDialog();
     return false;
   }
   ```

**Location:** `lib/features/cart/screens/cart_screen.dart:249-283`

---

## Out of Service Dialog

When a user's location is outside the service zone at checkout, the **OutOfServiceDialog** is displayed:

### Features:

1. **Saved Addresses List:**
   - Shows all previously saved addresses
   - Each address is validated against service zones
   - User can select any address that's within a service zone

2. **Map Picker Option:**
   - "Choose from Map" button opens interactive map
   - User can select any location on the map
   - Selected location is validated against service zones
   - Only zone-valid locations can proceed to checkout

3. **Zone Validation for Selected Address:**
   ```dart
   // Validate the address is in service zone
   var response = await locationController.getZone(
     address.latitude, 
     address.longitude, 
     false  // Always validate for checkout
   );
   
   if (response.isSuccess && response.zoneIds.isNotEmpty) {
     // Update address with proper zone data
     address.zoneId = response.zoneIds[0];
     address.zoneIds = response.zoneIds;
     address.zoneData = response.zoneData;
     address.areaIds = response.areaIds;
     
     // Pass address directly to checkout (doesn't change global app location)
     Get.toNamed(RouteHelper.getCheckoutRoute('cart', storeId: null),
         arguments: address);
   }
   ```

**Location:** `lib/features/cart/widgets/out_of_service_dialog.dart:45-103`

---

## Zone API

### Endpoint

**GET** `/api/v1/config/get-zone-id?lat={latitude}&lng={longitude}`

### Request Parameters

- `lat`: User's latitude (required)
- `lng`: User's longitude (required)

### Response (Inside Zone - 200 OK)

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

### Response (Outside Zone - 400/404)

```json
{
  "zone_ids": [],
  "zone_data": [],
  "area_ids": []
}
```

**Location:** `lib/features/location/domain/repositories/location_repository.dart:151-192`

---

## Key Implementation Details

### 1. Zone Validation Flag

The `skipZoneValidation` flag has different behaviors:

- **Browsing Mode (`skipZoneValidation: true`):**
  - Allows location to be set from anywhere
  - Used when user is just exploring the app
  - Location saved to SharedPreferences for app-wide use

- **Checkout Mode (`skipZoneValidation: false`):**
  - **ALWAYS enforced** at checkout, regardless of flag value
  - Zone validation is mandatory for order placement
  - Ensures delivery can be fulfilled

### 2. Address Passing to Checkout

When user selects a zone-valid address from OutOfServiceDialog:

- Address is **NOT saved** to SharedPreferences (doesn't change global app location)
- Address is passed directly to checkout screen via route arguments
- Checkout uses this address for order placement only
- Global app location remains unchanged (user can still browse from original location)

**Code:**
```dart
// Store the address in a global variable before navigation
Get.put(address, tag: 'passed_address');

// Navigate to checkout screen with the selected address as argument
Get.toNamed(RouteHelper.getCheckoutRoute('cart', storeId: null),
    arguments: address);
```

**Location:** `lib/features/cart/widgets/out_of_service_dialog.dart:82-89`

### 3. Checkout Screen Address Handling

Checkout screen checks for passed address first, then falls back to global address:

```dart
// Check if address was passed from location picker
AddressModel? _passedAddress = Get.arguments as AddressModel?;

if (_passedAddress != null) {
  // Use address passed from pick-map screen
  currentAddress = _passedAddress;
} else {
  // Use global address from shared preferences
  currentAddress = AddressHelper.getUserAddressFromSharedPref();
}
```

**Location:** `lib/features/checkout/screens/checkout_screen.dart:200-215`

---

## User Experience Flow

### Scenario 1: User in Service Zone

1. User sets location (anywhere) → Location saved
2. User browses app → Works normally
3. User adds items to cart → Works normally
4. User clicks "Proceed to Checkout" → Zone validation passes
5. User proceeds to checkout → Order can be placed

### Scenario 2: User Outside Service Zone

1. User sets location (outside zone) → Location saved with `skipZoneValidation: true`
2. User browses app → Works normally (can see products, stores, etc.)
3. User adds items to cart → Works normally
4. User clicks "Proceed to Checkout" → Zone validation fails
5. **OutOfServiceDialog** appears → Shows saved addresses + map picker
6. User selects zone-valid address → Address validated
7. User proceeds to checkout → Order can be placed with selected address
8. **Global app location unchanged** → User can continue browsing from original location

---

## Technical Architecture

### Components Involved

1. **LocationController** (`lib/features/location/controllers/location_controller.dart`)
   - Manages location selection and zone validation
   - Handles `skipZoneValidation` flag
   - Provides `getZone()` method for zone validation

2. **CartScreen** (`lib/features/cart/screens/cart_screen.dart`)
   - Validates location before checkout
   - Shows OutOfServiceDialog when location is invalid
   - Pre-calculates distance for checkout

3. **OutOfServiceDialog** (`lib/features/cart/widgets/out_of_service_dialog.dart`)
   - Displays saved addresses
   - Provides map picker option
   - Validates selected addresses against zones
   - Passes validated address to checkout

4. **CheckoutScreen** (`lib/features/checkout/screens/checkout_screen.dart`)
   - Accepts address from route arguments or SharedPreferences
   - Uses address for order placement
   - Calculates delivery charges based on zone data

5. **LocationRepository** (`lib/features/location/domain/repositories/location_repository.dart`)
   - Makes zone validation API calls
   - Caches zone data for 30 minutes
   - Returns zone information including delivery charges

---

## Zone Data Structure

When a location is validated and found to be within a service zone, the address is enriched with:

- **zoneId**: Primary zone ID
- **zoneIds**: Array of all zone IDs the location belongs to
- **zoneData**: Complete zone information including:
  - Zone name
  - Module configurations
  - Delivery charge rates (per km, minimum, maximum)
  - First km fee and distance
  - Payment method availability
- **areaIds**: Array of area IDs within the zone

This data is used for:
- Delivery charge calculations
- Payment method filtering
- Store availability checks
- Order placement validation

---

## Benefits

1. **Global Accessibility:**
   - Users can explore the app from anywhere
   - No barriers to browsing and discovery
   - Better user engagement

2. **Order Integrity:**
   - Ensures orders can only be placed in serviceable areas
   - Prevents delivery failures
   - Maintains service quality

3. **Flexible Address Selection:**
   - Users can choose delivery address at checkout
   - Multiple saved addresses supported
   - Map picker for precise location selection

4. **Seamless Experience:**
   - No disruption to browsing experience
   - Clear guidance when zone validation is needed
   - Easy address selection process

---

## Code References

### Key Files

- **Location Controller:** `lib/features/location/controllers/location_controller.dart`
- **Cart Screen:** `lib/features/cart/screens/cart_screen.dart:249-283`
- **Out of Service Dialog:** `lib/features/cart/widgets/out_of_service_dialog.dart`
- **Checkout Screen:** `lib/features/checkout/screens/checkout_screen.dart:200-215`
- **Location Repository:** `lib/features/location/domain/repositories/location_repository.dart:151-192`
- **Pick Map Screen:** `lib/features/location/screens/pick_map_screen.dart:425-457`

### Key Methods

- `validateLocationForCheckout()` - Validates location before checkout
- `getZone()` - Validates location against service zones
- `saveAddressAndNavigate()` - Saves location with optional zone validation bypass
- `_selectAddress()` - Handles address selection from OutOfServiceDialog
- `_prepareZoneData()` - Prepares zone data for address

---

## Summary

This feature provides a **flexible browsing experience** while maintaining **strict order validation**. Users can explore the app from anywhere in the world, but must select a location within a service zone to complete checkout. The implementation ensures:

- ✅ Global location selection for browsing
- ✅ Mandatory zone validation at checkout
- ✅ User-friendly address selection dialog
- ✅ Seamless checkout experience
- ✅ Order integrity and delivery feasibility

---

**Last Updated:** 2024-01-01  
**Version:** 1.0.0
