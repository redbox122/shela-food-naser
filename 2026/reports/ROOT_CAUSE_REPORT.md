# ROOT CAUSE AUDIT REPORT
**Date:** Generated on audit request  
**Focus:** Ghost Load (2-second delay) + N/A Distance Issues

---

## EXECUTIVE SUMMARY

Three critical issues identified:
1. **Parser Verdict:** ⚠️ **MISSING FIELD** - `HomeUnifiedModel` does NOT parse `promotional_banner` (not a crash, but silent failure)
2. **Distance Logic:** ✅ **SERVER-SIDE** - Distance comes from API, shows "N/A" when `store.distance` is null/999999
3. **Race Condition:** ❌ **CONFIRMED** - `loadHomeData` called WITHOUT awaiting location service

---

## TASK 1: PARSER AUDIT (The 2-Second Delay)

### File: `lib/features/home/domain/models/home_unified_model.dart`

### Findings:

**CRITICAL DISCOVERY:** `HomeUnifiedModel.fromJson` does **NOT** parse `promotional_banner` field at all.

#### Current Model Structure:
```dart
class HomeUnifiedModel {
  final List<Banner>? banners;
  final List<BasicCampaignModel>? campaigns;
  final List<CategoryModel>? categories;
  final List<Store>? popularStores;
  final List<BrandModel>? brands;
  final List<OffersModel>? offers;
  final Map<String, dynamic>? customer;
  final BusinessSettingsModel? businessSettings;
  final HomeUnifiedMeta? meta;
  // ❌ NO promotionalBanner field!
}
```

#### Parser Analysis (lines 39-260):
- ✅ Parses: `banners`, `campaigns`, `categories`, `popular_stores`, `brands`, `offers`, `customer`, `business_settings`, `meta`
- ❌ **MISSING:** `promotional_banner` parsing logic

#### Error Log Context:
The error `type '_Map<String, dynamic>' is not a subtype of type 'PromotionalBanner?'` suggests:
- API returns `promotional_banner` as a Map
- Some code expects `PromotionalBanner` object
- But `HomeUnifiedModel` doesn't handle this field

#### Verdict: **MISSING FIELD (NOT A CRASH)**
- **Status:** ⚠️ **UNSAFE** - Field is silently ignored
- **Impact:** If API returns `promotional_banner`, it's completely ignored
- **Root Cause:** Model doesn't include `promotionalBanner` field or parsing logic
- **Note:** There IS a `PromotionalBanner` model at `lib/features/banner/domain/models/promotional_banner_model.dart`, but it's not used in `HomeUnifiedModel`

#### Recommendation:
1. Add `promotionalBanner` field to `HomeUnifiedModel`
2. Add parsing logic in `fromJson`:
   ```dart
   PromotionalBanner? promotionalBanner;
   if (data['promotional_banner'] != null && data['promotional_banner'] is Map) {
     promotionalBanner = PromotionalBanner.fromJson(data['promotional_banner'] as Map<String, dynamic>);
   }
   ```

---

## TASK 2: DISTANCE DISPLAY AUDIT (The N/A Issue)

### Files Analyzed:
- `lib/common/widgets/card_design/store_card_with_distance.dart` (lines 43-56)
- `lib/features/store/widgets/food_restaurant/food_restaurant_info_section.dart` (lines 125-127)
- `lib/features/store/widgets/grocery_store/grocery_store_info_section.dart` (lines 193-195)

### Findings:

#### Distance Logic (SERVER-SIDE):
```dart
// From store_card_with_distance.dart:43-56
double? distanceKm;
if (store.distance != null && store.distance! > 0 && store.distance! < 100000) {
  distanceKm = store.distance! / 1000; // Convert meters to km
} else if (store.distance == 999999 || store.distance == null || store.distance! <= 0) {
  // Backend default 999999 means no GPS - show "Distance N/A"
  distanceKm = null;
} else if (store.latitude != null && store.longitude != null && store.distance! > 100000) {
  // Fallback to local calculation if API distance is invalid (> 100km)
  distanceKm = Get.find<StoreController>().getRestaurantDistance(...);
}
```

#### Display Logic:
```dart
// Line 568-570
Text(
  distanceKm != null
    ? '${distanceKm! > 100 ? '100+' : distanceKm!.toStringAsFixed(1)} ${'km'.tr}'
    : 'Distance N/A',
)
```

#### Verdict: **SERVER-SIDE CALCULATION**
- **Status:** ✅ **CORRECT** - Distance comes from API response
- **Logic:** 
  - Primary: Uses `store.distance` from API (in meters)
  - Fallback: Client-side calculation if API distance > 100km
  - Default: Shows "Distance N/A" if `store.distance` is null, 0, or 999999
- **Root Cause of N/A:** API returns `null` or `999999` when GPS/location is unavailable

#### Why N/A Appears:
1. API request sent with `lat: null` or `long: null` (location not ready)
2. Backend returns `distance: 999999` or `distance: null`
3. Widget displays "Distance N/A" as designed

---

## TASK 3: RACE CONDITION AUDIT (Location Not Ready)

### File: `lib/features/splash/controllers/splash_controller.dart`

### Findings:

#### Location Check in `_loadWithAppInit` (lines 253-279):
```dart
// Line 256: Checks if address exists in SharedPreferences
final hasAddress = AddressHelper.getUserAddressFromSharedPref() != null;
final isFreshInstall = !hasAddress;

// Line 263-279: Calls loadHomeData WITHOUT awaiting location
final homeUnifiedFuture = !isFreshInstall && Get.isRegistered<HomeUnifiedController>()
    ? Get.find<HomeUnifiedController>().loadHomeData(
        moduleId: 3,
        showLoading: false,
        include: 'banners,offers',
      )
    : Future.value(false);
```

#### Header Update in `setModule` (lines 1075-1090):
```dart
// Line 1079: Gets address from SharedPreferences (NOT from LocationController)
final addressModel = AddressHelper.getUserAddressFromSharedPref();

apiClient.updateHeader(
  apiClient.token,
  addressModel?.zoneIds,
  addressModel?.areaIds,
  sharedPreferences.getString(AppConstants.languageCode),
  module.id,
  addressModel?.latitude,  // ⚠️ Could be null if location not ready
  addressModel?.longitude,  // ⚠️ Could be null if location not ready
);
```

#### Verdict: **RACE CONDITION CONFIRMED** ❌
- **Status:** ❌ **CONFIRMED** - Location service is NOT awaited before API call
- **Root Cause:** 
  1. `_loadWithAppInit` checks `AddressHelper.getUserAddressFromSharedPref()` (static check)
  2. Does NOT await `LocationController().getUserAddress()` (async location fetch)
  3. API headers set with potentially null lat/long
  4. Backend receives `lat: null, long: null` → returns `distance: 999999` or `null`
  5. UI displays "Distance N/A"

#### Evidence:
- Line 256: Only checks SharedPreferences, not location service readiness
- Line 263-279: `loadHomeData` called immediately without location await
- Line 1079: `getUserAddressFromSharedPref()` used instead of `LocationController().getUserAddress()`
- No `await Get.find<LocationController>().getUserAddress()` before `loadHomeData`

#### Recommendation:
1. In `_loadWithAppInit`, await location before calling `loadHomeData`:
   ```dart
   // Ensure location is ready before API call
   if (!isFreshInstall && Get.isRegistered<LocationController>()) {
     await Get.find<LocationController>().getUserAddress();
   }
   ```
2. Or check location readiness before setting headers:
   ```dart
   final locationController = Get.find<LocationController>();
   if (locationController.isLocationReady) {
     // Proceed with API call
   }
   ```

---

## SUMMARY TABLE

| Issue | Verdict | Status | Root Cause |
|-------|---------|--------|------------|
| **Parser (2-sec delay)** | Missing Field | ⚠️ UNSAFE | `HomeUnifiedModel` doesn't parse `promotional_banner` |
| **Distance Logic** | Server-Side | ✅ CORRECT | Uses `store.distance` from API, shows N/A when null/999999 |
| **Race Condition** | Confirmed | ❌ CONFIRMED | `loadHomeData` called without awaiting location service |

---

## RECOMMENDED FIXES

### Fix 1: Add Promotional Banner Parsing
**File:** `lib/features/home/domain/models/home_unified_model.dart`

Add to model:
```dart
final PromotionalBanner? promotionalBanner;
```

Add to `fromJson`:
```dart
PromotionalBanner? promotionalBannerData;
if (data['promotional_banner'] != null && data['promotional_banner'] is Map) {
  try {
    promotionalBannerData = PromotionalBanner.fromJson(
      data['promotional_banner'] as Map<String, dynamic>
    );
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ HomeUnifiedModel: Error parsing promotional_banner: $e');
    }
  }
}
```

### Fix 2: Await Location Before API Call
**File:** `lib/features/splash/controllers/splash_controller.dart`

In `_loadWithAppInit` method (around line 256):
```dart
// Ensure location is ready before API call
if (!isFreshInstall && Get.isRegistered<LocationController>()) {
  try {
    await Get.find<LocationController>().getUserAddress();
    if (kDebugMode) {
      debugPrint('✅ SplashController: Location ready before home-unified call');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ SplashController: Location fetch failed: $e');
    }
    // Continue anyway - API will handle null location gracefully
  }
}
```

---

## END OF REPORT
