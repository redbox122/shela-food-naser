# Home Screen Migration Plan - HomeController & HomeRepository

**Generated:** 2025-01-27  
**Purpose:** Map HomeController/HomeRepository API calls to `/api/v2/home-unified` Unified Model  
**Status:** 🔍 Audit Complete

---

## Executive Summary

### Current State

`HomeController` exposes **3 API call methods** through `HomeRepository`:

1. ✅ **Business Settings** - Can be migrated to unified endpoint
2. ❌ **Cashback Offer List** - **NOT in unified endpoint** (must remain separate)
3. ❌ **Cashback Data** - **NOT in unified endpoint** (transaction-specific, must remain separate)

### Migration Status

| API Call | Unified Model Field | Migration Status | Action Required |
|----------|---------------------|------------------|-----------------|
| `getBusiness_Settings()` | `HomeUnifiedModel.businessSettings` | ✅ **MIGRATED** | No action - already handled by `HomeUnifiedController` |
| `getCashBackOfferList()` | ❌ **NOT AVAILABLE** | ❌ **NO MIGRATION** | Keep separate API call |
| `getCashBackData(amount)` | ❌ **NOT AVAILABLE** | ❌ **NO MIGRATION** | Keep separate API call (transaction-specific) |

---

## Detailed API Call Analysis

### 1. Business Settings API Call

#### Current Implementation

**Controller Method:**
```dart
// lib/features/home/controllers/home_controller.dart:28-31
Future<BusinessSettingsModel?> getBusiness_Settings() async {
  _business_Settings = await homeServiceInterface.getBusiness_Settings();
  update();
}
```

**Repository Method:**
```dart
// lib/features/home/domain/repositories/home_repository.dart:35-50
@override
Future<BusinessSettingsModel?> getBusiness_Settings() async {
  BusinessSettingsModel? business_Settings;
  Response response = await apiClient.getData(AppConstants.business_SettingsUri);
  // ... parsing logic ...
  return business_Settings;
}
```

**Endpoint:**
- **Old:** `/api/v1/business-settings/mobile-app-home-screen-setup`
- **Constant:** `AppConstants.business_SettingsUri`

#### Unified Model Mapping

**Unified Model Field:**
```dart
// lib/features/home/domain/models/home_unified_model.dart:24
final BusinessSettingsModel? businessSettings;
```

**Distribution Logic:**
```dart
// lib/features/home/controllers/home_unified_controller.dart:556-573
if (Get.isRegistered<HomeController>()) {
  final homeController = Get.find<HomeController>();
  if (data.businessSettings != null) {
    homeController.setBusinessSettingsFromBootstrap(data.businessSettings!);
  } else {
    // Set default BusinessSettings if API returns null
    final defaultSettings = BusinessSettingsModel();
    homeController.setBusinessSettingsFromBootstrap(defaultSettings);
  }
}
```

**New Endpoint:**
- **Unified:** `/api/v2/home-unified?module_id={id}`
- **Field Path:** `response.data.business_settings`

#### Migration Status: ✅ **ALREADY MIGRATED**

**Evidence:**
- ✅ `HomeUnifiedController._distributeDataToControllers()` already distributes `businessSettings` to `HomeController`
- ✅ Uses `homeController.setBusinessSettingsFromBootstrap()` method
- ✅ Fallback to default settings if API returns null

**Special Logic Preserved:**
1. ✅ Cache support: `setBusinessSettingsFromCache()` still available for manual cache injection
2. ✅ Bootstrap support: `setBusinessSettingsFromBootstrap()` used by unified controller
3. ✅ Null handling: Default `BusinessSettingsModel()` created if API returns null

#### Action Required: **NONE**

The migration is **already complete**. When `HomeUnifiedController.loadHomeData()` is called, business settings are automatically distributed to `HomeController`.

**Note:** The old `getBusiness_Settings()` method still exists for backward compatibility but is no longer used when unified endpoint is active.

---

### 2. Cashback Offer List API Call

#### Current Implementation

**Controller Method:**
```dart
// lib/features/home/controllers/home_controller.dart:50-54
Future<void> getCashBackOfferList() async {
  _cashBackOfferList = null;
  _cashBackOfferList = await homeServiceInterface.getCashBackOfferList();
  update();
}
```

**Repository Method:**
```dart
// lib/features/home/domain/repositories/home_repository.dart:55-65
@override
Future getList({int? offset}) async {
  List<CashBackModel>? cashBackModelList;
  Response response = await apiClient.getData(AppConstants.cashBackOfferListUri);
  if (response.statusCode == 200) {
    cashBackModelList = [];
    response.body.forEach((data) {
      cashBackModelList!.add(CashBackModel.fromJson(data));
    });
  }
  return cashBackModelList;
}
```

**Endpoint:**
- **Current:** `/api/v1/cashback/list`
- **Constant:** `AppConstants.cashBackOfferListUri`

#### Unified Model Mapping

**Unified Model Field:** ❌ **NOT AVAILABLE**

`HomeUnifiedModel` does **NOT** include cashback fields:
```dart
// lib/features/home/domain/models/home_unified_model.dart:16-25
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
  // ❌ NO cashback fields
}
```

#### Migration Status: ❌ **NO MIGRATION POSSIBLE**

**Reason:** Cashback offer list is **NOT included** in the unified endpoint response.

**Special Logic to Preserve:**
1. ✅ List is cleared before fetching: `_cashBackOfferList = null;` ensures fresh data
2. ✅ Can be forcefully nulled: `forcefullyNullCashBackOffers()` method for manual clearing
3. ✅ List parsing: Handles array response with multiple `CashBackModel` objects

#### Action Required: **KEEP SEPARATE API CALL**

This API call **must remain separate** because:
- ❌ Not included in unified endpoint
- ✅ Used for cashback offers display (separate feature from home screen)
- ✅ May be called independently (not tied to home screen load)

**Recommendation:** Keep `getCashBackOfferList()` as a separate method. It can be called when needed (e.g., when user opens cashback section).

---

### 3. Cashback Data API Call

#### Current Implementation

**Controller Method:**
```dart
// lib/features/home/controllers/home_controller.dart:66-73
Future<void> getCashBackData(double amount) async {
  CashBackModel? cashBackModel =
      await homeServiceInterface.getCashBackData(amount);
  if (cashBackModel != null) {
    _cashBackData = cashBackModel;
  }
  update();
}
```

**Repository Method:**
```dart
// lib/features/home/domain/repositories/home_repository.dart:73-82
@override
Future<CashBackModel?> getCashBackData(double amount) async {
  CashBackModel? cashBackModel;
  Response response = await apiClient.getData('${AppConstants.getCashBackAmountUri}?amount=$amount');
  if (response.statusCode == 200) {
    cashBackModel = CashBackModel.fromJson(response.body);
  }
  return cashBackModel;
}
```

**Endpoint:**
- **Current:** `/api/v1/cashback/getCashback?amount={amount}`
- **Constant:** `AppConstants.getCashBackAmountUri`

#### Unified Model Mapping

**Unified Model Field:** ❌ **NOT AVAILABLE**

Same as cashback offer list - not included in unified endpoint.

#### Migration Status: ❌ **NO MIGRATION POSSIBLE**

**Reason:** 
1. ❌ Not included in unified endpoint
2. ✅ **Transaction-specific**: Requires `amount` parameter (calculated at checkout time)
3. ✅ **On-demand**: Called when user needs cashback calculation for a specific transaction

**Special Logic to Preserve:**
1. ✅ Null check: Only sets `_cashBackData` if response is not null
2. ✅ Amount parameter: Required for cashback calculation
3. ✅ Single object: Returns single `CashBackModel` (not a list)

#### Action Required: **KEEP SEPARATE API CALL**

This API call **must remain separate** because:
- ❌ Not included in unified endpoint
- ✅ Transaction-specific (requires `amount` parameter)
- ✅ Called on-demand during checkout/cart operations
- ✅ Not part of initial home screen data load

**Recommendation:** Keep `getCashBackData(amount)` as a separate method. It should be called when calculating cashback for a specific transaction amount.

---

## Special Logic Preservation Checklist

### Business Settings

| Logic | Status | Location | Notes |
|-------|--------|----------|-------|
| Cache injection | ✅ Preserved | `setBusinessSettingsFromCache()` | Available for manual cache updates |
| Bootstrap injection | ✅ Preserved | `setBusinessSettingsFromBootstrap()` | Used by `HomeUnifiedController` |
| Null handling | ✅ Preserved | `_distributeDataToControllers()` | Default settings created if null |
| Update trigger | ✅ Preserved | `update()` called after setting | Controller notifies listeners |

### Cashback Offer List

| Logic | Status | Location | Notes |
|-------|--------|----------|-------|
| List clearing | ✅ Preserved | `_cashBackOfferList = null;` | Ensures fresh data |
| Force clear | ✅ Preserved | `forcefullyNullCashBackOffers()` | Manual clearing method |
| Array parsing | ✅ Preserved | `forEach` loop in repository | Handles multiple cashback offers |
| Null handling | ✅ Preserved | Null check before assignment | Prevents null errors |

### Cashback Data

| Logic | Status | Location | Notes |
|-------|--------|----------|-------|
| Amount parameter | ✅ Preserved | `getCashBackData(double amount)` | Required for calculation |
| Null check | ✅ Preserved | `if (cashBackModel != null)` | Only sets if response exists |
| Single object | ✅ Preserved | Returns `CashBackModel?` | Single cashback calculation result |

---

## Migration Impact Analysis

### Code That Uses HomeController Methods

#### Business Settings

**Current Usage:**
- ✅ Already migrated: `HomeUnifiedController` distributes business settings automatically
- ⚠️ Legacy calls: `HomeController.getBusiness_Settings()` may still be called in fallback paths

**Migration Impact:**
- ✅ **No breaking changes** - unified endpoint already handles this
- ✅ **Backward compatible** - old method still works if unified endpoint fails

#### Cashback Offer List

**Current Usage:**
- Called when user views cashback offers section
- Called when refreshing cashback offers

**Migration Impact:**
- ✅ **No migration needed** - must remain separate
- ✅ **No breaking changes** - continues to work as-is

#### Cashback Data

**Current Usage:**
- Called during checkout when calculating cashback for order
- Called when user wants to see cashback for specific amount

**Migration Impact:**
- ✅ **No migration needed** - transaction-specific, must remain separate
- ✅ **No breaking changes** - continues to work as-is

---

## Recommendations

### ✅ Immediate Actions (No Code Changes)

1. **Document Current State:**
   - ✅ Business settings migration is complete (already handled by `HomeUnifiedController`)
   - ✅ Cashback methods must remain separate (not in unified endpoint)

2. **Verify Business Settings Migration:**
   - Check that `HomeUnifiedController._distributeDataToControllers()` is being called
   - Verify business settings are set correctly in `HomeController`
   - Test that old `getBusiness_Settings()` method is not called when unified endpoint is active

3. **Keep Cashback Methods Separate:**
   - No changes needed for cashback methods
   - They will continue to work independently
   - Document that cashback is intentionally not in unified endpoint

### 🔄 Future Considerations (Optional)

1. **Remove Legacy Business Settings Call (Risky):**
   - ⚠️ **NOT RECOMMENDED** - Keep `getBusiness_Settings()` for fallback scenarios
   - Only remove if unified endpoint is 100% stable for 6+ months
   - Keep as safety net if unified endpoint fails

2. **Add Cashback to Unified Endpoint (Backend Change):**
   - **If backend adds cashback to unified endpoint:**
     - Add `cashbackOffers` field to `HomeUnifiedModel`
     - Update `_distributeDataToControllers()` to distribute cashback data
     - Add `setCashBackOfferListFromUnified()` method to `HomeController`
   - **Note:** Cashback data (with amount) should remain separate (transaction-specific)

---

## Summary Table

| Method | Old Endpoint | Unified Endpoint Field | Migration Status | Action Required |
|--------|--------------|------------------------|------------------|-----------------|
| `getBusiness_Settings()` | `/api/v1/business-settings/mobile-app-home-screen-setup` | `HomeUnifiedModel.businessSettings` | ✅ **MIGRATED** | None - already handled |
| `getCashBackOfferList()` | `/api/v1/cashback/list` | ❌ Not available | ❌ **NO MIGRATION** | Keep separate call |
| `getCashBackData(amount)` | `/api/v1/cashback/getCashback?amount={amount}` | ❌ Not available | ❌ **NO MIGRATION** | Keep separate call |

---

## Final Verdict

### ✅ Migration Status: **PARTIALLY COMPLETE**

1. ✅ **Business Settings:** Already migrated via `HomeUnifiedController`
2. ❌ **Cashback Offer List:** Cannot migrate (not in unified endpoint)
3. ❌ **Cashback Data:** Cannot migrate (transaction-specific, not in unified endpoint)

### Action Items

- ✅ **No immediate code changes required**
- ✅ **Document that business settings migration is complete**
- ✅ **Document that cashback methods must remain separate**
- ⚠️ **Optional:** Monitor for backend changes that add cashback to unified endpoint

---

**End of Migration Plan**

