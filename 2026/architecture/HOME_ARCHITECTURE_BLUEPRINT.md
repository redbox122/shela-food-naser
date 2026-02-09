# HOME ARCHITECTURE BLUEPRINT
## Full Forensic Audit Report

**Date:** Generated Audit  
**Auditor:** Lead System Architect  
**Scope:** Complete mapping of Lobby (Multi-Module) and Rooms (Module-Specific) architecture

---

## EXECUTIVE SUMMARY

This audit reveals a **two-tier architecture**:

1. **LOBBY** (`MultiModuleHomeScreen`): Multi-module selector showing promotional content from Module 3
2. **ROOMS** (`FoodHomeScreen`, `GroceryHomeScreen`, `PharmacyHomeScreen`, `ShopHomeScreen`): Module-specific home screens

**Key Finding:** The codebase is in a **transitional state** - some screens use unified BFF v2 API (`HomeUnifiedController`), while others use legacy individual API calls. Migration should be **screen-by-screen** to minimize risk.

---

## TASK 1: LOBBY ANALYSIS (MultiModuleHomeScreen)

### Location
- **File:** `lib/features/home/screens/multi_module/multi_module_home_screen.dart`
- **Class:** `MultiModuleHomeScreen` (StatefulWidget)

### API Calls on Load

#### 1. **Banners API**
- **Method:** `_loadBannersForModule3()`
- **Endpoint:** 
  - **Primary:** `/api/v2/home-unified` (via `HomeUnifiedService`)
  - **Fallback:** `/api/v1/banner` (via `BannerController.getFeaturedBanner()`)
- **Module ID:** **Hardcoded to `3`** (eCommerce)
- **Constant:** `MultiModuleHomeScreen.kPromotionalModuleId = 3`
- **Purpose:** Featured promotional banners for multi-module screen
- **Update Strategy:** Silent background update (only updates UI if data changed)

#### 2. **Offers API**
- **Method:** `Get.find<Offers_Controller>().getOffers(specificModuleId: 3)`
- **Endpoint:** `/api/v1/offers` (with module ID 3 in headers)
- **Module ID:** **Hardcoded to `3`** (eCommerce)
- **Purpose:** Featured promotional offers for multi-module screen
- **Optimization:** Skips redundant API call if offers already loaded from unified endpoint

#### 3. **Wallet API** (Conditional)
- **Method:** `Get.find<KaidhaSubscription_Controller>().get_Wallet_Kaidh()`
- **Endpoint:** `AppConstants.get_walletUri`
- **Condition:** Only if `AuthHelper.isLoggedIn() == true`
- **Purpose:** Display wallet balance

### Hardcoded Module ID

**YES - Module ID 3 is hardcoded:**
```dart
static const int kPromotionalModuleId = 3;
```

**Rationale:** Backend design - Module 3 (eCommerce) provides featured promotional content (banners & offers) for the multi-module screen. This is **intentional**, not a bug.

### Data Loading Strategy

1. **Pre-fetch Check:** Checks for pre-fetched data from Splash screen
2. **Cache Check:** Verifies cached promotional content in Hive
3. **Silent Update:** Only updates UI if new data differs from cache
4. **Background Sync:** Loads in background without blocking UI

### Controllers Used

- `BannerController` - For banner data
- `Offers_Controller` - For offers data
- `HomeUnifiedController` - For unified data (v2 endpoint)
- `KaidhaSubscription_Controller` - For wallet data
- `SplashController` - For module list

---

## TASK 2: ROOM ANALYSIS (Module-Specific Screens)

### Overview Table

| Screen Name | File Path | API Calls | Controller Used | Data Loading Strategy |
|-------------|-----------|-----------|-----------------|----------------------|
| **FoodHomeScreen** | `lib/features/home/screens/all_sections/food_home_screen.dart` | `HomeUnifiedController.loadHomeData()` | `HomeUnifiedController` (v2 unified) | SWR pattern: Cache first, background refresh |
| **GroceryHomeScreen** | `lib/features/home/screens/all_sections/grocery_home_screen.dart` | `HomeUnifiedController.loadHomeData()` | `HomeUnifiedController` (v2 unified) | SWR pattern: Cache first, background refresh |
| **PharmacyHomeScreen** | `lib/features/home/screens/all_sections/pharmacy_home_screen.dart` | **None (StatelessWidget)** | Multiple controllers (Banner, Category, Store, Item, Campaign, Advertisement) | Relies on data loaded elsewhere (likely HomeScreen.loadData()) |
| **ShopHomeScreen** | `lib/features/home/screens/all_sections/shop_home_screen.dart` | `HomeUnifiedController.loadHomeData()` | `HomeUnifiedController` (v2 unified) | SWR pattern: Cache first, background refresh |

### Detailed Analysis

#### 1. FoodHomeScreen

**API Calls:**
- **Single Unified Call:** `HomeUnifiedController.loadHomeData()`
  - Endpoint: `/api/v2/home-unified`
  - Module ID: Current selected module (from `ModuleHelper.getModule()`)
  - Data Included: Banners, Categories, Stores, Brands, Offers, Business Settings

**Sections Displayed:**
1. Categories (`CategoryView`) - if enabled in business_settings
2. Banners (`BannerView`) - if enabled in business_settings
3. Top Restaurants (`TopRestaurantsViewWidget`) - if enabled in business_settings
4. All Restaurants (`AllRestaurantsView`) - if enabled in business_settings

**Data Loading:**
- **initState:** Calls `_loadCachedDataForInstantUI()` - loads from cache synchronously
- **Background:** `_refreshInBackground()` - silent refresh after 100ms delay
- **Strategy:** SWR (Stale-While-Revalidate) pattern

#### 2. GroceryHomeScreen

**API Calls:**
- **Single Unified Call:** `HomeUnifiedController.loadHomeData()`
  - Endpoint: `/api/v2/home-unified`
  - Module ID: Current selected module

**Sections Displayed:**
1. Categories (`CategoryView`) - if enabled in business_settings

**Note:** Most sections are commented out (lines 135-186), only Categories section is active.

**Data Loading:**
- Same SWR pattern as FoodHomeScreen
- `_loadCachedDataForInstantUI()` → `_refreshInBackground()`

#### 3. PharmacyHomeScreen

**API Calls:**
- **NONE** - StatelessWidget with no API calls in the widget itself
- **Relies on:** Controllers populated by `HomeScreen.loadData()` or other initialization

**Sections Displayed:**
1. Categories (`CategoryView`)
2. Banners (`BannerView` with BadWeatherWidget)
3. Visit Again (`VisitAgainView`) - if logged in
4. Product With Categories (`ProductWithCategoriesView`) - Basic Medicine
5. Highlight Widget (`HighlightWidget`) - Advertisements
6. Middle Section Banner (`MiddleSectionBannerView`) - Basic Campaigns
7. Best Store Nearby (`BestStoreNearbyView`) - Featured Stores
8. Just For You (`JustForYouView`) - Item Campaigns
9. Top Offers Near Me (`TopOffersNearMe`)
10. New On Mart (`NewOnMartView`) - Latest Stores
11. Common Condition View (`CommonConditionView`)
12. Promotional Banner (`PromotionalBannerView`)

**Data Sources:**
- `CategoryController.categoryList`
- `BannerController.featuredBannerList` / `bannerImageList`
- `StoreController.visitAgainStoreList` / `featuredStoreList` / `topOfferStoreList` / `latestStoreList`
- `ItemController.basicMedicineModel` / `commonConditions`
- `CampaignController.basicCampaignList` / `itemCampaignList`
- `AdvertisementController.advertisementList`

**Note:** This screen is a **pure presentation layer** - it doesn't load data itself, it displays what's already in controllers.

#### 4. ShopHomeScreen (Ecommerce)

**API Calls:**
- **Single Unified Call:** `HomeUnifiedController.loadHomeData()`
  - Endpoint: `/api/v2/home-unified`
  - Module ID: Current selected module

**Sections Displayed:**
1. Categories (`CategoryView`) - if enabled in business_settings
2. Banners (`BannerView`) - if enabled in business_settings
3. Brands (`BrandsViewWidget`) - if enabled in business_settings
4. Offers (`OffersView`) - if enabled in business_settings (uses `topStoresOffersNearMeSection` flag)
5. Stores (`ProductWithCategoriesView`) - if enabled in business_settings

**Data Loading:**
- Same SWR pattern as FoodHomeScreen and GroceryHomeScreen

### Controller Usage Pattern

**Common Controllers (All Rooms):**
- `HomeController` - Business settings
- `SplashController` - Current module selection
- `CategoryController` - Categories list
- `BannerController` - Banner images
- `StoreController` - Store listings
- `HomeUnifiedController` - Unified data (Food, Grocery, Shop only)

**Module-Specific Controllers:**
- `ItemController` - Products/Items (Pharmacy, Shop)
- `BrandsController` - Brands (Shop only)
- `CampaignController` - Campaigns (Pharmacy)
- `AdvertisementController` - Advertisements (Pharmacy)
- `Offers_Controller` - Offers (Shop, MultiModule)

### Architecture Pattern

**3 out of 4 rooms use unified BFF v2 API:**
- ✅ FoodHomeScreen → `HomeUnifiedController`
- ✅ GroceryHomeScreen → `HomeUnifiedController`
- ❌ PharmacyHomeScreen → **Legacy pattern** (relies on external data loading)
- ✅ ShopHomeScreen → `HomeUnifiedController`

**Conclusion:** PharmacyHomeScreen is the outlier - it uses a legacy presentation-only pattern and relies on data being loaded elsewhere (likely by `HomeScreen.loadData()`).

---

## TASK 3: NAVIGATION FLOW

### Lobby → Room Navigation

#### Step 1: User Taps Module in Lobby

**Location:** `lib/features/home/widgets/modules_view_widget.dart` (lines 84-131)

```dart
onTap: () async {
  // 1. Clear store data
  if (Get.isRegistered<StoreController>()) {
    Get.find<StoreController>().clearStoreData();
  }
  
  // 2. Switch module
  splashController.switchModule(context, index, true);
  
  // 3. Wait for module switch
  await Future.delayed(const Duration(milliseconds: 300));
  
  // 4. Navigate
  Get.offNamedUntil(
    RouteHelper.getInitialRoute(),
    (route) => false,
  );
}
```

#### Step 2: Module Switch Logic

**Location:** `lib/features/splash/controllers/splash_controller.dart` (lines 1168-1249)

```dart
void switchModule(context, int index, bool fromPhone) async {
  // 1. Set module in SplashController
  await Get.find<SplashController>().setModule(moduleToSwitch);
  _module = moduleToSwitch;
  
  // 2. Check cache validity
  bool isCacheValid = await ComprehensiveHomeCacheManager.isCacheValid();
  
  // 3. Clear controllers ONLY if cache invalid
  if (!isCacheValid) {
    await _clearAllControllerData(moduleToSwitch.moduleType.toString());
  }
  
  // 4. Load home data
  HomeScreen.loadData(context, shouldForceRefresh, fromModule: true);
}
```

**Key Behavior:**
- **Cache-aware:** Only clears controllers if cache is invalid
- **Force refresh:** Determined by cache validity check
- **Module-aware:** Cache check is module-specific

#### Step 3: Route Resolution

**Location:** `lib/helper/route_helper.dart` → `getInitialRoute()`

Returns route based on app state, typically:
- `RouteHelper.home` → `DashboardScreen` → `HomeScreen`

#### Step 4: HomeScreen Routing

**Location:** `lib/features/home/screens/home_screen.dart` (lines 954-964)

```dart
// HomeScreen.build() determines which Room to show based on module type
isGrocery ? GroceryHomeScreen()
  : isPharmacy ? PharmacyHomeScreen()
    : isFood ? const FoodHomeScreen()
      : isShop ? ShopHomeScreen()
        : isTaxi ? TaxiHomeScreen()
          : SizedBox()
```

**Module Type Detection:**
```dart
ModuleModel? currentModule = splashController.module ?? splashController.configModel?.module;
bool isGrocery = currentModule?.moduleType.toString() == AppConstants.grocery;
bool isPharmacy = currentModule?.moduleType.toString() == AppConstants.pharmacy;
bool isFood = currentModule?.moduleType.toString() == AppConstants.food;
bool isShop = currentModule?.moduleType.toString() == AppConstants.ecommerce;
```

### Navigation Type

**Uses `Get.offNamedUntil()` - NOT `Get.offAll()`:**
- Clears navigation stack up to matching route
- Uses predicate: `(route) => false` - clears ALL routes
- Results in: Fresh navigation stack starting from `DashboardScreen`

**Why this pattern?**
- Ensures clean state after module switch
- Prevents back navigation to previous module
- Forces full re-initialization of home screen

### Module Switching Sequence Diagram

```
User Taps Module
    ↓
ModulesViewWidget.onTap()
    ↓
StoreController.clearStoreData()
    ↓
SplashController.switchModule(index)
    ↓
SplashController.setModule(moduleToSwitch)
    ↓
Check Cache Validity (module-specific)
    ↓
If Cache Invalid:
    ├─ Clear All Controllers
    └─ Set forceRefresh = true
Else:
    └─ Set forceRefresh = false
    ↓
HomeScreen.loadData(context, forceRefresh, fromModule: true)
    ↓
[Data Loading Logic]
    ↓
Get.offNamedUntil(RouteHelper.getInitialRoute(), (route) => false)
    ↓
DashboardScreen (fresh stack)
    ↓
HomeScreen.build()
    ↓
Route to Module-Specific Screen:
    ├─ isGrocery → GroceryHomeScreen
    ├─ isPharmacy → PharmacyHomeScreen
    ├─ isFood → FoodHomeScreen
    ├─ isShop → ShopHomeScreen
    └─ isTaxi → TaxiHomeScreen
```

---

## THE VERDICT: MIGRATION STRATEGY

### Code Quality Assessment

#### ✅ **GOOD: Unified API Pattern (3/4 Rooms)**
- FoodHomeScreen, GroceryHomeScreen, ShopHomeScreen use `HomeUnifiedController`
- Consistent SWR pattern (cache-first, background refresh)
- Single API call instead of multiple

#### ⚠️ **WARNING: Inconsistent Patterns**
- **PharmacyHomeScreen** uses legacy presentation-only pattern
- **MultiModuleHomeScreen** uses mixed approach (v2 for banners, v1 for offers)
- Hardcoded Module ID 3 in MultiModuleHomeScreen (intentional, but tightly coupled)

#### ⚠️ **WARNING: Navigation Complexity**
- Multiple layers: ModulesViewWidget → SplashController → HomeScreen → Module Screen
- Cache-aware logic adds complexity
- Module switching clears navigation stack (good for UX, complex for debugging)

### Migration Recommendation

**RECOMMENDATION: Screen-by-Screen Migration**

#### Phase 1: Standardize MultiModuleHomeScreen
- Migrate offers API to v2 unified endpoint
- Remove hardcoded Module ID 3 (make it configurable via business_settings)
- Implement same SWR pattern as Room screens

#### Phase 2: Migrate PharmacyHomeScreen
- Convert to StatefulWidget (like other rooms)
- Implement `HomeUnifiedController.loadHomeData()` in initState
- Add SWR pattern for cache-first loading
- Remove dependency on external data loading

#### Phase 3: Unify Navigation Flow
- Create `ModuleNavigationHelper` to centralize module switching logic
- Simplify cache-aware navigation
- Add logging/analytics for module switches

### Why Screen-by-Screen?

1. **Risk Mitigation:** Each screen can be tested independently
2. **Incremental Rollback:** If one screen breaks, others remain functional
3. **Pattern Validation:** Learn from each migration, improve next one
4. **Business Continuity:** No disruption to user experience during migration

### Migration Checklist Per Screen

- [ ] Audit current API calls
- [ ] Identify controllers in use
- [ ] Plan data loading strategy (SWR vs. legacy)
- [ ] Update navigation logic
- [ ] Add error handling
- [ ] Implement loading states
- [ ] Add analytics/logging
- [ ] Unit tests
- [ ] Integration tests
- [ ] QA testing
- [ ] Rollout (feature flag?)

---

## ARCHITECTURE SUMMARY

### Current State

```
┌─────────────────────────────────────┐
│     MultiModuleHomeScreen           │
│     (LOBBY)                         │
│                                     │
│  • Hardcoded Module ID 3           │
│  • Mixed API (v2 + v1 fallback)    │
│  • Promotional banners/offers      │
│  • Wallet (if logged in)           │
└──────────────┬──────────────────────┘
               │
               │ User taps module
               ↓
┌─────────────────────────────────────┐
│     ModulesViewWidget               │
│                                     │
│  • switchModule()                   │
│  • Get.offNamedUntil()              │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│     HomeScreen                      │
│                                     │
│  • Routes based on module type      │
│  • loadData() orchestration         │
└──────────────┬──────────────────────┘
               │
       ┌───────┴───────┬───────────┬──────────┐
       ↓               ↓           ↓          ↓
┌─────────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐
│ FoodHome    │ │ Grocery  │ │Pharmacy │ │  Shop  │
│             │ │  Home    │ │  Home   │ │  Home  │
│             │ │          │ │         │ │        │
│ ✅ Unified  │ │ ✅ Unified│ │ ❌ Legacy│ │ ✅ Unified│
│ ✅ SWR      │ │ ✅ SWR    │ │ ❌ None │ │ ✅ SWR  │
└─────────────┘ └──────────┘ └─────────┘ └────────┘
```

### Target State (Post-Migration)

```
┌─────────────────────────────────────┐
│     MultiModuleHomeScreen           │
│     (LOBBY)                         │
│                                     │
│  • Configurable promotional module  │
│  • Unified v2 API only             │
│  • SWR pattern                     │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│     ModuleNavigationHelper          │
│     (Centralized)                   │
│                                     │
│  • switchModule()                   │
│  • Cache management                 │
│  • Navigation orchestration         │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│     HomeScreen                      │
│                                     │
│  • Simple routing logic             │
│  • Delegate to ModuleNavigationHelper│
└──────────────┬──────────────────────┘
               │
       ┌───────┴───────┬───────────┬──────────┐
       ↓               ↓           ↓          ↓
┌─────────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐
│ FoodHome    │ │ Grocery  │ │Pharmacy │ │  Shop  │
│             │ │  Home    │ │  Home   │ │  Home  │
│             │ │          │ │         │ │        │
│ ✅ Unified  │ │ ✅ Unified│ │ ✅ Unified│ │ ✅ Unified│
│ ✅ SWR      │ │ ✅ SWR    │ │ ✅ SWR  │ │ ✅ SWR  │
│ ✅ Consistent│ │ ✅ Consistent│ │ ✅ Consistent│ │ ✅ Consistent│
└─────────────┘ └──────────┘ └─────────┘ └────────┘
```

---

## KEY FINDINGS

### Critical Issues

1. **PharmacyHomeScreen Architecture Mismatch**
   - Uses StatelessWidget with no data loading
   - Relies on external data loading (fragile dependency)
   - Should be migrated to unified pattern

2. **Hardcoded Module ID in MultiModuleHomeScreen**
   - Module ID 3 is hardcoded (intentional, but not flexible)
   - Should be configurable via business_settings or config

3. **Mixed API Versions**
   - MultiModuleHomeScreen uses both v2 (banners) and v1 (offers)
   - Should standardize on v2 unified endpoint

### Positive Patterns

1. **SWR Pattern Implementation**
   - Food, Grocery, Shop screens use cache-first, background refresh
   - Excellent UX (instant display, silent updates)

2. **Unified API Adoption**
   - 3/4 rooms use `HomeUnifiedController`
   - Single API call reduces latency
   - Consistent data structure

3. **Cache-Aware Navigation**
   - Module switching checks cache validity
   - Only clears controllers if cache invalid
   - Instant display when cache is valid

---

## RECOMMENDATIONS

### Immediate Actions

1. **Document Module ID 3 Hardcoding**
   - Add JSDoc/comment explaining backend design decision
   - Consider making it configurable in future

2. **Audit PharmacyHomeScreen Data Loading**
   - Trace where data is loaded (likely `HomeScreen.loadData()`)
   - Document dependency chain

3. **Add Integration Tests**
   - Test module switching flow end-to-end
   - Test cache behavior during module switches
   - Test API fallback scenarios

### Short-Term (1-2 Sprints)

1. **Migrate PharmacyHomeScreen to Unified Pattern**
   - Convert to StatefulWidget
   - Implement `HomeUnifiedController.loadHomeData()`
   - Add SWR pattern

2. **Standardize MultiModuleHomeScreen**
   - Migrate offers to v2 unified endpoint
   - Remove v1 fallback (or make it optional)

### Long-Term (3-6 Months)

1. **Create ModuleNavigationHelper**
   - Centralize module switching logic
   - Simplify navigation flow
   - Add analytics/logging

2. **Make Promotional Module Configurable**
   - Move Module ID 3 to business_settings
   - Allow backend to configure promotional module per deployment

3. **Performance Optimization**
   - Pre-load module data during splash
   - Implement module data cache with TTL
   - Add predictive pre-loading

---

## APPENDIX: API Endpoints Reference

### Unified BFF v2 API
- **Endpoint:** `/api/v2/home-unified`
- **Method:** GET
- **Headers:** `module-id`, `zone-ids`, `area-ids`, `language-code`
- **Returns:** `HomeUnifiedModel` (banners, categories, stores, brands, offers, business_settings)

### Legacy v1 APIs
- **Banners:** `/api/v1/banner` (via `BannerController`)
- **Offers:** `/api/v1/offers` (via `Offers_Controller`)
- **Categories:** `/api/v1/categories` (via `CategoryController`)
- **Stores:** `/api/v1/stores` (via `StoreController`)
- **Brands:** `/api/v1/brands` (via `BrandsController`)

---

**END OF AUDIT REPORT**

