# Global Module Screens Audit Report

**Date:** Generated on audit completion  
**Purpose:** Identify legacy API calls in all module screens for V2 Unified Engine migration  
**Target:** All module screens in `lib/features/home/screens/all_sections/`

---

## Executive Summary

| Screen | V2 Unified Engine | Legacy Controllers | Status |
|--------|-------------------|-------------------|--------|
| **Food** | ✅ YES | ⚠️ Partial | **MIGRATED** (uses V2, but displays legacy data) |
| **Grocery** | ✅ YES | ⚠️ Partial | **MIGRATED** (uses V2, but displays legacy data) |
| **Shop** | ✅ YES | ⚠️ Partial | **MIGRATED** (uses V2, but displays legacy data) |
| **Pharmacy** | ❌ NO | ⚠️ Full Legacy | **NOT MIGRATED** (StatelessWidget, no V2 integration) |

---

## Detailed Audit Results

### 1. Food Home Screen (`food_home_screen.dart`)

#### Data Loading
- **initState:** ✅ Uses `HomeUnifiedController.loadCachedDataForInstantUI()` (V2)
- **Legacy Calls:** ❌ NO direct `Get.find<XController>().getData()` calls
- **Background Refresh:** ✅ Uses `HomeUnifiedController.loadHomeData()` (V2)

#### Refresher
- **RefreshIndicator:** ❌ NOT FOUND in code
- **Pull-to-Refresh:** N/A (no RefreshIndicator implemented)

#### Structure
**Main Widgets:**
- `CategoryView` (wrapped in `GetBuilder<CategoryController>`)
- `BannerView` (wrapped in `GetBuilder<BannerController>`)
- `TopRestaurantsViewWidget` (static widget)
- `AllRestaurantsView` (wrapped in `GetBuilder<StoreController>`)

#### Legacy Controllers Used
| Controller | Purpose | Status |
|------------|---------|--------|
| `HomeUnifiedController` | ✅ V2 Data Loading | **ACTIVE** |
| `HomeController` | ⚠️ Business Settings | **LEGACY** (for settings only) |
| `CategoryController` | ⚠️ Category Data Display | **LEGACY** |
| `BannerController` | ⚠️ Banner Data Display | **LEGACY** |
| `StoreController` | ⚠️ Store Data Display | **LEGACY** |

#### Migration Status
- ✅ **V2 Engine:** Integrated via `HomeUnifiedController`
- ⚠️ **Data Display:** Still uses legacy controllers for UI rendering
- ✅ **No Legacy API Calls:** All data loading goes through V2 unified endpoint

---

### 2. Grocery Home Screen (`grocery_home_screen.dart`)

#### Data Loading
- **initState:** ✅ Uses `HomeUnifiedController.loadCachedDataForInstantUI()` (V2)
- **Legacy Calls:** ❌ NO direct `Get.find<XController>().getData()` calls
- **Background Refresh:** ✅ Uses `HomeUnifiedController.loadHomeData()` (V2)

#### Refresher
- **RefreshIndicator:** ❌ NOT FOUND in code
- **Pull-to-Refresh:** N/A (no RefreshIndicator implemented)

#### Structure
**Main Widgets:**
- `CategoryView` (wrapped in `GetBuilder<CategoryController>`)
- **Note:** Many sections are commented out (lines 135-186)

#### Legacy Controllers Used
| Controller | Purpose | Status |
|------------|---------|--------|
| `HomeUnifiedController` | ✅ V2 Data Loading | **ACTIVE** |
| `HomeController` | ⚠️ Business Settings | **LEGACY** (for settings only) |
| `SplashController` | ⚠️ Module Detection | **LEGACY** (for module type check) |
| `CategoryController` | ⚠️ Category Data Display | **LEGACY** |

#### Migration Status
- ✅ **V2 Engine:** Integrated via `HomeUnifiedController`
- ⚠️ **Data Display:** Still uses legacy controllers for UI rendering
- ✅ **No Legacy API Calls:** All data loading goes through V2 unified endpoint

---

### 3. Shop Home Screen (`shop_home_screen.dart`)

#### Data Loading
- **initState:** ✅ Uses `HomeUnifiedController.loadCachedDataForInstantUI()` (V2)
- **Legacy Calls:** ❌ NO direct `Get.find<XController>().getData()` calls
- **Background Refresh:** ✅ Uses `HomeUnifiedController.loadHomeData()` (V2)

#### Refresher
- **RefreshIndicator:** ❌ NOT FOUND in code
- **Pull-to-Refresh:** N/A (no RefreshIndicator implemented)

#### Structure
**Main Widgets:**
- `CategoryView` (wrapped in `GetBuilder<CategoryController>`)
- `BannerView` (wrapped in `GetBuilder<BannerController>`)
- `BrandsViewWidget` (wrapped in `GetBuilder<BrandsController>`)
- `OffersView` (wrapped in `GetBuilder<Offers_Controller>`)
- `ProductWithCategoriesView` (wrapped in `GetBuilder<StoreController>`)

#### Legacy Controllers Used
| Controller | Purpose | Status |
|------------|---------|--------|
| `HomeUnifiedController` | ✅ V2 Data Loading | **ACTIVE** |
| `HomeController` | ⚠️ Business Settings | **LEGACY** (for settings only) |
| `SplashController` | ⚠️ Module Detection | **LEGACY** (for module type check) |
| `CategoryController` | ⚠️ Category Data Display | **LEGACY** |
| `BannerController` | ⚠️ Banner Data Display | **LEGACY** |
| `BrandsController` | ⚠️ Brand Data Display | **LEGACY** |
| `Offers_Controller` | ⚠️ Offers Data Display | **LEGACY** |
| `StoreController` | ⚠️ Store Data Display | **LEGACY** |

#### Migration Status
- ✅ **V2 Engine:** Integrated via `HomeUnifiedController`
- ⚠️ **Data Display:** Still uses legacy controllers for UI rendering
- ✅ **No Legacy API Calls:** All data loading goes through V2 unified endpoint

---

### 4. Pharmacy Home Screen (`pharmacy_home_screen.dart`)

#### Data Loading
- **initState:** ❌ NOT FOUND (StatelessWidget - no initState)
- **Legacy Calls:** ❌ NO direct `Get.find<XController>().getData()` calls in build
- **Background Refresh:** ❌ NOT IMPLEMENTED

#### Refresher
- **RefreshIndicator:** ❌ NOT FOUND in code
- **Pull-to-Refresh:** N/A (no RefreshIndicator implemented)

#### Structure
**Main Widgets:**
- `CategoryView` (wrapped in `GetBuilder<CategoryController>`)
- `BannerView` (wrapped in `GetBuilder<BannerController>`)
- `BadWeatherWidget` (static widget)
- `VisitAgainView` (wrapped in `GetBuilder<StoreController>`)
- `ProductWithCategoriesView` (wrapped in `GetBuilder<ItemController>`)
- `HighlightWidget` (wrapped in `GetBuilder<AdvertisementController>`)
- `MiddleSectionBannerView` (wrapped in `GetBuilder<CampaignController>`)
- `BestStoreNearbyView` (wrapped in `GetBuilder<StoreController>`)
- `JustForYouView` (wrapped in `GetBuilder<CampaignController>`)
- `TopOffersNearMe` (wrapped in `GetBuilder<StoreController>`)
- `NewOnMartView` (wrapped in `GetBuilder<StoreController>`)
- `CommonConditionView` (wrapped in `GetBuilder<ItemController>`)
- `PromotionalBannerView` (wrapped in `GetBuilder<BannerController>`)

#### Legacy Controllers Used
| Controller | Purpose | Status |
|------------|---------|--------|
| `HomeUnifiedController` | ❌ NOT USED | **MISSING** |
| `HomeController` | ⚠️ Business Settings | **LEGACY** |
| `CategoryController` | ⚠️ Category Data Display | **LEGACY** |
| `BannerController` | ⚠️ Banner Data Display | **LEGACY** |
| `StoreController` | ⚠️ Store Data Display | **LEGACY** |
| `ItemController` | ⚠️ Item Data Display | **LEGACY** |
| `CampaignController` | ⚠️ Campaign Data Display | **LEGACY** |
| `AdvertisementController` | ⚠️ Advertisement Data Display | **LEGACY** |

#### Migration Status
- ❌ **V2 Engine:** NOT INTEGRATED
- ⚠️ **Data Display:** Uses ONLY legacy controllers
- ⚠️ **No Data Loading:** StatelessWidget with no initState - relies on parent screen for data loading
- 🚨 **CRITICAL:** This screen needs full migration to V2 Unified Engine

---

## Legacy Controller Usage Matrix

| Controller | Food | Grocery | Shop | Pharmacy |
|------------|------|---------|------|----------|
| `HomeUnifiedController` | ✅ | ✅ | ✅ | ❌ |
| `HomeController` | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| `CategoryController` | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| `BannerController` | ⚠️ | ❌ | ⚠️ | ⚠️ |
| `StoreController` | ⚠️ | ❌ | ⚠️ | ⚠️ |
| `BrandsController` | ❌ | ❌ | ⚠️ | ❌ |
| `Offers_Controller` | ❌ | ❌ | ⚠️ | ❌ |
| `ItemController` | ❌ | ❌ | ❌ | ⚠️ |
| `CampaignController` | ❌ | ❌ | ❌ | ⚠️ |
| `AdvertisementController` | ❌ | ❌ | ❌ | ⚠️ |
| `SplashController` | ❌ | ⚠️ | ⚠️ | ❌ |

**Legend:**
- ✅ = V2 Unified Engine (data loading)
- ⚠️ = Legacy Controller (data display/configuration)
- ❌ = Not Used

---

## Key Findings

### ✅ Positive Findings
1. **Food, Grocery, Shop:** All three screens have integrated `HomeUnifiedController` for V2 data loading
2. **No Legacy API Calls:** None of the screens call `Get.find<XController>().getData()` directly in initState
3. **SWR Pattern:** Food, Grocery, and Shop implement the SWR (stale-while-revalidate) pattern with cached data loading

### ⚠️ Areas of Concern
1. **Pharmacy Screen:** Complete absence of V2 Unified Engine integration
2. **Legacy Controllers:** All screens still use legacy controllers for data display (even though data is loaded via V2)
3. **No RefreshIndicator:** None of the screens implement pull-to-refresh functionality
4. **Data Display Layer:** Controllers are used for UI rendering, but data comes from V2 - potential disconnect

### 🚨 Critical Issues
1. **Pharmacy Home Screen:**
   - StatelessWidget with no data loading mechanism
   - No V2 Unified Engine integration
   - Relies entirely on legacy controllers
   - **PRIORITY:** Requires full migration to match other screens

---

## Migration Recommendations

### Priority 1: Pharmacy Home Screen
1. Convert `StatelessWidget` to `StatefulWidget`
2. Add `initState` with `HomeUnifiedController` integration
3. Implement SWR pattern (cached data + background refresh)
4. Update all `GetBuilder` widgets to use V2 data source

### Priority 2: Remove Legacy Controller Dependencies
1. **For All Screens:** Replace `GetBuilder<XController>` with direct data access from `HomeUnifiedController`
2. **Data Flow:** Ensure all data comes from V2 unified endpoint, not individual controller APIs
3. **Business Settings:** Keep `HomeController` only for business settings (not data)

### Priority 3: Add RefreshIndicator
1. Wrap all screens' content in `RefreshIndicator`
2. On refresh, call `HomeUnifiedController.loadHomeData(forceRefresh: true)`
3. Ensure refresh works with V2 unified endpoint

---

## Confirmation: HomeUnifiedController Usage

| Screen | HomeUnifiedController Used | Method |
|--------|---------------------------|--------|
| **Food** | ✅ YES | `loadCachedDataForInstantUI()`, `loadHomeData()` |
| **Grocery** | ✅ YES | `loadCachedDataForInstantUI()`, `loadHomeData()` |
| **Shop** | ✅ YES | `loadCachedDataForInstantUI()`, `loadHomeData()` |
| **Pharmacy** | ❌ NO | **NOT IMPLEMENTED** |

**Conclusion:** `HomeUnifiedController` is used in 3 out of 4 screens. Pharmacy screen requires immediate migration.

---

## Next Steps

1. ✅ **Audit Complete:** All module screens audited
2. 🚨 **Action Required:** Migrate Pharmacy Home Screen to V2
3. 🔄 **Refactor:** Remove legacy controller dependencies from data display layer
4. ➕ **Enhancement:** Add RefreshIndicator to all screens
5. 🧪 **Testing:** Verify all screens work with V2 unified endpoint only

---

**Report Generated:** Complete audit of all module screens  
**Status:** Ready for migration planning

