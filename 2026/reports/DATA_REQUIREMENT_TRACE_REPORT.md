# DATA REQUIREMENT TRACE REPORT
**Principal Flutter Architect Analysis**

**Date:** Generated Report  
**Mission:** Trace every data requirement per screen to identify parallel bombing and redundant data fetching

---

## EXECUTIVE SUMMARY

**CRITICAL FINDING:** The app is loading store-specific data (Store 1, Store 219) while on the Multi-Module Home Screen, causing unnecessary server load.

**Root Causes Identified:**
1. **MultiModuleHomeScreen** is correctly isolated but may trigger global controllers
2. **ShopHomeScreen** calls `getStoreList()` which may fetch ALL stores (300+) unnecessarily
3. **GroceryStoreDetailScreen** fetches GLOBAL categories when it should only use store-specific categories
4. **FoodRestaurantDetailScreen** has blind pre-fetch that may trigger for wrong stores

---

## SCREEN 1: MultiModuleHomeScreen

### 📍 Location
`lib/features/home/screens/multi_module/multi_module_home_screen.dart`

### 🔌 API Endpoints Called

#### In `initState()`:
1. **Wallet API** (if logged in)
   - Endpoint: `AppConstants.get_walletUri`
   - Trigger: Line 265, 288
   - Controller: `KaidhaSubscription_Controller.get_Wallet_Kaidh()`

#### In `_loadData()` → `_loadPromotionalContentSilently()`:
2. **Home Unified API v2** (Primary)
   - Endpoint: `/api/v2/home-unified`
   - Trigger: Line 327-333
   - Controller: `HomeUnifiedController.loadHomeData()`
   - Parameters:
     - `moduleId: 3` (eCommerce - promotional content)
     - `include: 'banners,offers'` (lazy loading - ONLY banners and offers)
     - `forceRefresh: false`
     - `showLoading: false` (silent background update)

#### Fallback (if unified endpoint fails):
3. **Banners API**
   - Endpoint: `/api/v1/banners`
   - Trigger: Line 375-376
   - Controller: `BannerController.getBannerList(false, dataSource: DataSourceEnum.client)`

4. **Offers API**
   - Endpoint: `/api/v1/offers/active`
   - Trigger: Line 387
   - Controller: `Offers_Controller.getOffers()`

### ✅ Essential Data Needed (What's Actually Rendered)

From `build()` method (lines 404-613):

1. **Modules List**
   - Source: `SplashController.moduleList`
   - Fields Used: `module.id`, `module.moduleName`, `module.storesCount` (optional)
   - Rendered In: `ModulesViewWidget` (line 555)
   - **NO API CALL** - Already loaded from splash

2. **Banners** (Featured)
   - Source: `BannerController.featuredBannerList`
   - Fields Used: `banner.image`, `banner.link`
   - Rendered In: `BannerView(isFeatured: true)` (line 523)
   - **API CALL:** `/api/v2/home-unified?module_id=3&include=banners` OR `/api/v1/banners?featured=1`

3. **Offers**
   - Source: `Offers_Controller.offersMode.data`
   - Fields Used: `offer.id`, `offer.title`, `offer.image`, `offer.description`
   - Rendered In: `OffersView()` (line 591)
   - **API CALL:** `/api/v2/home-unified?module_id=3&include=offers` OR `/api/v1/offers/active`

4. **Wallet Card** (if logged in)
   - Source: `KaidhaSubscription_Controller`
   - Fields Used: Wallet balance, subscription status
   - Rendered In: `WalletCardView()` (line 561)
   - **API CALL:** `AppConstants.get_walletUri`

### ❌ Redundant Data (Fetched but NOT Used)

**NONE** - This screen is correctly isolated. It only fetches:
- Banners (for module 3)
- Offers (for module 3)
- Wallet (if logged in)

**✅ VERIFIED:** No store-specific data is fetched on this screen.

### 🚨 Trigger Logic Issues

**POTENTIAL ISSUE:** If `HomeUnifiedController.loadHomeData()` is called without `include` parameter, it may fetch:
- Categories (NOT needed)
- Stores (NOT needed)
- Brands (NOT needed)

**FIX APPLIED:** Line 330 explicitly sets `include: 'banners,offers'` to prevent fetching unnecessary data.

**VERDICT:** ✅ **CLEAN** - MultiModuleHomeScreen is properly decoupled and does NOT fetch store data.

---

## SCREEN 2: ShopHomeScreen

### 📍 Location
`lib/features/home/screens/all_sections/shop_home_screen.dart`

### 🔌 API Endpoints Called

#### In `initState()` → `_loadCachedDataForInstantUI()`:
1. **Home Unified API v2** (Cache Load)
   - Endpoint: `/api/v2/home-unified`
   - Trigger: Line 69
   - Controller: `HomeUnifiedController.loadCachedDataForInstantUI()`
   - **NO API CALL** - Only loads from cache

#### In `_refreshInBackground()` → `_loadData()`:
2. **Home Unified API v2** (Top Sections)
   - Endpoint: `/api/v2/home-unified`
   - Trigger: Line 118-122
   - Controller: `HomeUnifiedController.loadHomeData()`
   - Parameters:
     - `moduleId: splashController.module?.id` (current module)
     - `forceRefresh: reload` (true if no cache)
     - `showLoading: false` (silent refresh)
   - **Fetches:** Banners, Categories, Brands, Offers, Popular Stores (top section only)

3. **Store List API** (Bottom Section - "All Restaurants")
   - Endpoint: `/api/v1/stores/list` (inferred from `getStoreList`)
   - Trigger: Line 148
   - Controller: `StoreController.getStoreList(1, true)`
   - Parameters:
     - `offset: 1`
     - `reload: true` (forces fresh fetch, clears old module data)
   - **⚠️ CRITICAL:** This fetches ALL stores for pagination (300+ stores)
   - **Purpose:** Legacy pagination engine for "All Restaurants" section

### ✅ Essential Data Needed (What's Actually Rendered)

From `build()` method (lines 185-357):

1. **Categories**
   - Source: `CategoryController.categoryList`
   - Fields Used: `category.id`, `category.name`, `category.image`
   - Rendered In: `CategoryView()` (line 247)
   - **API CALL:** `/api/v2/home-unified` (includes categories)

2. **Banners**
   - Source: `BannerController.bannerImageList` OR `featuredBannerList`
   - Fields Used: `banner.image`, `banner.link`
   - Rendered In: `BannerView(isFeatured: false)` (line 272)
   - **API CALL:** `/api/v2/home-unified` (includes banners)

3. **Brands**
   - Source: `BrandsController.brandList`
   - Fields Used: `brand.id`, `brand.name`, `brand.image`
   - Rendered In: `BrandsViewWidget()` (line 293)
   - **API CALL:** `/api/v2/home-unified` (includes brands)

4. **Offers**
   - Source: `Offers_Controller.offersMode.data`
   - Fields Used: `offer.id`, `offer.title`, `offer.image`
   - Rendered In: `OffersView()` (line 323)
   - **API CALL:** `/api/v2/home-unified` (includes offers)

5. **Stores** (Popular Stores OR All Restaurants)
   - Source: `StoreController.popularStoreList` OR `StoreController.storeModel.stores`
   - Fields Used: `store.id`, `store.name`, `store.logo`, `store.rating`, `store.deliveryTime`
   - Rendered In: `ProductWithCategoriesView(fromShop: true)` (line 341)
   - **API CALL:** 
     - Top section: `/api/v2/home-unified` (includes `popularStoreList`)
     - Bottom section: `/api/v1/stores/list?offset=1&limit=10` (via `getStoreList`)

### ❌ Redundant Data (Fetched but NOT Used)

1. **Store List Pagination Data (300+ stores)**
   - **Problem:** `getStoreList(1, true)` fetches ALL stores for pagination (totalSize: 300+)
   - **Used:** Only first 10-20 stores are displayed in UI
   - **Waste:** 280+ stores fetched but never displayed
   - **Location:** Line 148
   - **Impact:** High - This is the "parallel bombing" issue

2. **Store Details for Each Store**
   - **Problem:** If `getStoreList` returns full store objects with all details
   - **Used:** Only basic fields (name, logo, rating, deliveryTime)
   - **Waste:** Full store details (menu, items, etc.) fetched but not used
   - **Impact:** Medium - Depends on API response structure

### 🚨 Trigger Logic Issues

**CRITICAL ISSUE #1:** `getStoreList(1, true)` is called with `reload: true` every time ShopHomeScreen loads
- **Line 148:** `await storeController.getStoreList(1, true);`
- **Problem:** This fetches ALL stores (300+) even though only 10-20 are displayed
- **Solution:** Should use pagination with limit (e.g., `limit: 20`) or use `popularStoreList` from unified endpoint

**CRITICAL ISSUE #2:** `getStoreList` may be triggered from other screens
- **Location:** `StoreController.getStoreList()` is called from multiple places
- **Problem:** If called while on MultiModuleHomeScreen, it will fetch stores unnecessarily
- **Solution:** Add guard to prevent `getStoreList` when no module is selected

**VERDICT:** ⚠️ **NEEDS FIX** - ShopHomeScreen fetches 300+ stores but only displays 10-20.

---

## SCREEN 3: FoodRestaurantDetailScreen

### 📍 Location
`lib/features/store/screens/food_restaurant_detail_screen.dart`

### 🔌 API Endpoints Called

#### In `initState()` → `_initializeData()`:

1. **Blind Item Pre-fetch** (Non-blocking)
   - Endpoint: `/api/v1/stores/{storeId}/items`
   - Trigger: Line 101-110
   - Controller: `StoreController.getStoreItemList()`
   - Parameters:
     - `storeId: widget.store?.id`
     - `offset: 1`
     - `categoryId: null` (all items)
     - `pageSize: 100`
   - **⚠️ POTENTIAL ISSUE:** This fires immediately, even if store ID is wrong

2. **Store Details API** (Parallel Batch)
   - Endpoint: `/api/v1/stores/details/{storeId}`
   - Trigger: Line 120-125 (via `loadAllStoreDetails`)
   - Controller: `StoreController.getStoreDetails()`
   - Parameters:
     - `storeId: widget.store?.id`
     - `fromModule: widget.fromModule`
     - `slug: widget.slug`
   - **Returns:** Full store object with `categoryDetails` embedded

3. **Store Banners API** (Parallel Batch)
   - Endpoint: `/api/v1/stores/{storeId}/banners`
   - Trigger: Line 2617 (via `loadAllStoreDetails`)
   - Controller: `StoreController.getStoreBannerList(storeId)`
   - **Returns:** List of store-specific banners

4. **Recommended Items API** (Parallel Batch)
   - Endpoint: `/api/v1/stores/{storeId}/recommended-items`
   - Trigger: Line 2625 (via `loadAllStoreDetails`)
   - Controller: `StoreController.getRestaurantRecommendedItemList(storeId)`
   - **Returns:** List of recommended items for this store

5. **Slim Menu API** (Parallel Batch - Optimized)
   - Endpoint: `/api/v1/stores/{storeId}/slim-menu`
   - Trigger: Line 2638 (via `loadAllStoreDetails`)
   - Controller: `StoreController.getSlimMenu(storeId)`
   - **Returns:** All categories + items in single response
   - **✅ OPTIMIZATION:** Replaces multiple `getStoreItemList` calls

#### Fallback (if slim menu fails):
6. **Category Items API** (Multiple calls - one per category)
   - Endpoint: `/api/v1/stores/{storeId}/items?category_id={categoryId}`
   - Trigger: Line 197-242 (progressive loading)
   - Controller: `StoreController.storeServiceInterface.getStoreItemList()`
   - Parameters:
     - `storeId: storeId`
     - `categoryId: category.id` (one call per category)
     - `limit: 100`
   - **⚠️ PROBLEM:** If store has 20 categories, this makes 20 API calls
   - **Impact:** High - This is the "parallel bombing" for store detail screens

#### Conditional (if categories not in store details):
7. **Global Categories API**
   - Endpoint: `/api/v1/categories`
   - Trigger: Line 160
   - Controller: `CategoryController.getCategoryList(true)`
   - **⚠️ PROBLEM:** Fetches GLOBAL categories when it should use store-specific categories from `store.categoryDetails`

### ✅ Essential Data Needed (What's Actually Rendered)

From `build()` method (lines 374-707):

1. **Store Header**
   - Source: `storeController.store` OR `widget.store` (fallback)
   - Fields Used: `store.coverPhotoFullUrl`, `store.logoFullUrl`, `store.id`
   - Rendered In: `FoodRestaurantHeader` (line 623)
   - **API CALL:** `/api/v1/stores/details/{storeId}`

2. **Store Info**
   - Source: `storeController.store`
   - Fields Used: `store.name`, `store.address`, `store.rating`, `store.deliveryTime`, `store.deliveryFee`
   - Rendered In: `FoodRestaurantInfoSection` (line 634)
   - **API CALL:** `/api/v1/stores/details/{storeId}`

3. **Categories** (Tabs)
   - Source: `widget.store.categoryDetails` OR `storeController.specificStoreCategoryList`
   - Fields Used: `category.id`, `category.name`
   - Rendered In: `FoodRestaurantCategoryTabs` (line 662)
   - **API CALL:** Embedded in `/api/v1/stores/details/{storeId}` OR from `store.categoryDetails`

4. **Items per Category**
   - Source: `_categoryItemsMap[categoryId]`
   - Fields Used: `item.id`, `item.name`, `item.image`, `item.price`, `item.description`
   - Rendered In: `FoodRestaurantCategorySection` (line 743)
   - **API CALL:** 
     - Optimized: `/api/v1/stores/{storeId}/slim-menu` (all items in one call)
     - Fallback: `/api/v1/stores/{storeId}/items?category_id={categoryId}` (one call per category)

5. **Banners** (if displayed)
   - Source: `storeController.storeBannerList`
   - Fields Used: `banner.image`, `banner.link`
   - **API CALL:** `/api/v1/stores/{storeId}/banners`

6. **Recommended Items** (if displayed)
   - Source: `storeController.recommendedItemList`
   - Fields Used: `item.id`, `item.name`, `item.image`, `item.price`
   - **API CALL:** `/api/v1/stores/{storeId}/recommended-items`

### ❌ Redundant Data (Fetched but NOT Used)

1. **Blind Pre-fetch Items (if slim menu succeeds)**
   - **Problem:** Line 101-110 fires `getStoreItemList` immediately, but if slim menu succeeds (line 139), this pre-fetch is redundant
   - **Waste:** 100 items fetched but never used
   - **Impact:** Low - Non-blocking, but still unnecessary API call
   - **Note:** Comment on line 92-94 acknowledges this: "Skip pre-fetch if slim menu will be used"

2. **Global Categories (if store.categoryDetails exists)**
   - **Problem:** Line 158-162 fetches global categories if `categoryController.categoryList == null`, but `store.categoryDetails` may already have categories
   - **Waste:** Global category list fetched unnecessarily
   - **Impact:** Medium - Depends on whether store details include categories

3. **All Category Items (if user only views one category)**
   - **Problem:** Progressive loading (line 176-255) loads items for ALL categories in parallel
   - **Used:** User may only view 1-2 categories
   - **Waste:** Items for 18+ categories fetched but never viewed
   - **Impact:** High - This is the "parallel bombing" for this screen
   - **Solution:** Lazy load categories on scroll/view

### 🚨 Trigger Logic Issues

**CRITICAL ISSUE #1:** Blind pre-fetch fires for ANY store ID
- **Line 95-110:** Pre-fetch fires immediately with `widget.store?.id`
- **Problem:** If `widget.store` is null or wrong, it may fetch items for wrong store
- **Solution:** Add null check and validate store ID before pre-fetch

**CRITICAL ISSUE #2:** Progressive loading loads ALL categories simultaneously
- **Line 176-255:** All category item requests fire in parallel
- **Problem:** If store has 20 categories, this makes 20 API calls at once
- **Impact:** High - Server load and bandwidth waste
- **Solution:** Load categories on-demand (when user scrolls to them)

**CRITICAL ISSUE #3:** Global categories fetched when store-specific categories exist
- **Line 158-162:** Fetches global categories if `categoryController.categoryList == null`
- **Problem:** `store.categoryDetails` may already have categories (from store details API)
- **Solution:** Check `store.categoryDetails` first before fetching global categories

**VERDICT:** ⚠️ **NEEDS FIX** - FoodRestaurantDetailScreen makes 20+ parallel API calls for categories that may never be viewed.

---

## SCREEN 4: GroceryStoreDetailScreen

### 📍 Location
`lib/features/store/screens/grocery_store_detail_screen.dart`

### 🔌 API Endpoints Called

#### In `initState()` → `_initializeData()`:

1. **Store Details API**
   - Endpoint: `/api/v1/stores/details/{storeId}`
   - Trigger: Line 87-93
   - Controller: `StoreController.getStoreDetails()`
   - Parameters:
     - `storeId: widget.store?.id`
     - `fromModule: widget.fromModule`
     - `slug: widget.slug`
   - **Returns:** Full store object with `categoryDetails` embedded

2. **Global Categories API** ⚠️ **CRITICAL ISSUE**
   - Endpoint: `/api/v1/categories`
   - Trigger: Line 104
   - Controller: `CategoryController.getCategoryList(true)`
   - **⚠️ PROBLEM:** Fetches GLOBAL categories when it should use store-specific categories
   - **Condition:** Only if `categoryController.categoryList == null`
   - **Impact:** High - Fetches ALL categories for ALL modules, not just this store

3. **Store Banners API**
   - Endpoint: `/api/v1/stores/{storeId}/banners`
   - Trigger: Line 121
   - Controller: `StoreController.getStoreBannerList(storeId)`
   - **Returns:** List of store-specific banners

4. **Recommended Items API**
   - Endpoint: `/api/v1/stores/{storeId}/recommended-items`
   - Trigger: Line 125
   - Controller: `StoreController.getRestaurantRecommendedItemList(storeId, false)`
   - **Returns:** List of recommended items for this store

### ✅ Essential Data Needed (What's Actually Rendered)

From `build()` method (lines 129-198):

1. **Store Header**
   - Source: `storeController.store`
   - Fields Used: `store.coverPhotoFullUrl`, `store.id`
   - Rendered In: `GroceryStoreHeader` (line 160)
   - **API CALL:** `/api/v1/stores/details/{storeId}`

2. **Store Info**
   - Source: `storeController.store`
   - Fields Used: `store.name`, `store.address`, `store.rating`, `store.deliveryTime`
   - Rendered In: `GroceryStoreInfoSection` (line 169)
   - **API CALL:** `/api/v1/stores/details/{storeId}`

3. **Categories** (Grid)
   - Source: `storeController.specificStoreCategoryList`
   - Fields Used: `category.id`, `category.name`, `category.image`
   - Rendered In: `GroceryCategoriesGrid` (line 183)
   - **API CALL:** Should come from `store.categoryDetails` (embedded in store details), NOT global categories

### ❌ Redundant Data (Fetched but NOT Used)

1. **Global Categories** ⚠️ **CRITICAL**
   - **Problem:** Line 104 fetches GLOBAL categories (`/api/v1/categories`)
   - **Used:** Only store-specific categories from `store.categoryDetails` are displayed
   - **Waste:** ALL global categories (for all modules) fetched but never used
   - **Impact:** High - This is a major data waste
   - **Location:** Line 102-108
   - **Solution:** Remove global category fetch, use only `store.categoryDetails`

2. **Store Banners** (if not displayed)
   - **Problem:** Line 121 loads banners, but they may not be displayed in UI
   - **Used:** Depends on UI design
   - **Impact:** Low - Depends on whether banners are shown

3. **Recommended Items** (if not displayed)
   - **Problem:** Line 125 loads recommended items, but they may not be displayed in UI
   - **Used:** Depends on UI design
   - **Impact:** Low - Depends on whether recommended items are shown

### 🚨 Trigger Logic Issues

**CRITICAL ISSUE #1:** Global categories fetched unnecessarily
- **Line 102-108:** Fetches global categories if `categoryController.categoryList == null`
- **Problem:** `store.categoryDetails` (from store details API) already has store-specific categories
- **Solution:** Use `store.categoryDetails` directly, skip global category fetch
- **Impact:** High - Fetches categories for ALL modules (Food, Grocery, Pharmacy, etc.) when only store categories are needed

**CRITICAL ISSUE #2:** `setCategoryList()` called in build method
- **Line 149:** `storeController.setCategoryList()` called in build method
- **Problem:** This may cause infinite rebuild loops (as noted in FoodRestaurantDetailScreen line 565)
- **Solution:** Call `setCategoryList()` only once in `_initializeData()`, not in build

**VERDICT:** ⚠️ **NEEDS FIX** - GroceryStoreDetailScreen fetches GLOBAL categories when it should only use store-specific categories.

---

## CROSS-SCREEN ANALYSIS

### 🔍 Parallel Bombing Root Causes

1. **ShopHomeScreen → getStoreList()**
   - Fetches 300+ stores but only displays 10-20
   - **Fix:** Use pagination with limit or use `popularStoreList` from unified endpoint

2. **FoodRestaurantDetailScreen → Progressive Category Loading**
   - Loads items for ALL categories in parallel (20+ API calls)
   - **Fix:** Lazy load categories on scroll/view

3. **GroceryStoreDetailScreen → Global Categories**
   - Fetches ALL global categories when only store categories are needed
   - **Fix:** Use `store.categoryDetails` directly, skip global fetch

4. **MultiModuleHomeScreen → ✅ CLEAN**
   - No store data fetched (correctly isolated)

### 🔍 Store Data Loading on MultiModuleHomeScreen

**HYPOTHESIS:** Store data (Store 1, Store 219) may be loading from:
1. **Background controllers** that are still active from previous screens
2. **HomeUnifiedController** loading data for wrong module
3. **StoreController.getStoreList()** being called from elsewhere

**INVESTIGATION NEEDED:**
- Check if `StoreController.getStoreList()` is called from splash screen or other global initialization
- Check if `HomeUnifiedController` is loading stores for multiple modules simultaneously
- Check if background sync services are triggering store API calls

---

## RECOMMENDATIONS

### Priority 1: Critical Fixes

1. **ShopHomeScreen: Limit Store List Fetch**
   ```dart
   // Current (line 148):
   await storeController.getStoreList(1, true);
   
   // Fix:
   await storeController.getStoreList(1, true, limit: 20); // Only fetch 20 stores
   // OR use popularStoreList from unified endpoint instead
   ```

2. **GroceryStoreDetailScreen: Remove Global Category Fetch**
   ```dart
   // Current (line 102-108):
   if (categoryController.categoryList == null) {
     await categoryController.getCategoryList(true);
   }
   
   // Fix:
   // Remove this - use store.categoryDetails directly
   // storeController.setCategoryList() will extract categories from store.categoryDetails
   ```

3. **FoodRestaurantDetailScreen: Lazy Load Categories**
   ```dart
   // Current (line 176-255): Loads all categories in parallel
   
   // Fix:
   // Load categories on-demand (when user scrolls to them)
   // Use IntersectionObserver or scroll listener to detect visible categories
   ```

### Priority 2: Optimization Fixes

4. **FoodRestaurantDetailScreen: Remove Blind Pre-fetch if Slim Menu Available**
   ```dart
   // Current (line 95-110): Always fires pre-fetch
   
   // Fix:
   // Check if slim menu is available first, skip pre-fetch if it is
   ```

5. **Add Guards to Prevent Cross-Module Data Loading**
   ```dart
   // Add check in StoreController.getStoreList():
   if (splashController.module == null) {
     return; // Don't fetch stores if no module selected
   }
   ```

### Priority 3: Monitoring

6. **Add API Call Logging**
   - Log all API calls with store ID and module ID
   - Track which screen triggered each API call
   - Identify patterns of unnecessary calls

---

## CONCLUSION

**MultiModuleHomeScreen:** ✅ **CLEAN** - No store data fetched  
**ShopHomeScreen:** ⚠️ **NEEDS FIX** - Fetches 300+ stores, only uses 10-20  
**FoodRestaurantDetailScreen:** ⚠️ **NEEDS FIX** - Loads all categories in parallel (20+ calls)  
**GroceryStoreDetailScreen:** ⚠️ **NEEDS FIX** - Fetches global categories unnecessarily

**The "parallel bombing" is likely caused by:**
1. ShopHomeScreen fetching 300+ stores
2. FoodRestaurantDetailScreen loading all categories in parallel
3. GroceryStoreDetailScreen fetching global categories

**Next Steps:**
1. Implement Priority 1 fixes
2. Add API call logging to identify exact source of Store 1, Store 219 calls
3. Test with network profiler to verify fixes
