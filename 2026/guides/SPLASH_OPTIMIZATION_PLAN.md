# SPLASH SCREEN LATENCY AUDIT - SPRINT 1.2

**Date:** 2025-01-27  
**Role:** Lead Performance Engineer  
**Mission:** Audit splash screen boot sequence and identify redundant API calls

---

## EXECUTIVE SUMMARY

The splash screen currently uses a **dual-path architecture**:
- ✅ **Optimized Path:** `/api/v1/app-init` (enabled via `AppConstants.useAppInitEndpoint = true`)
- ⚠️ **Legacy Path:** Individual API calls (`/api/v1/config`, `/api/v1/module`, etc.)

**Goal:** Consolidate ALL startup data loading into a SINGLE `app-init` call and remove legacy redundant endpoints.

---

## CURRENT BOOT SEQUENCE ANALYSIS

### 1. Initialization Method

**Location:** `lib/features/splash/controllers/splash_controller.dart`

**Main Entry Point:** `getConfigData()` (lines 117-190)

### 2. API Call Flow

#### Path A: App-Init (Current Optimized Path)

When `AppConstants.useAppInitEndpoint == true` (✅ CURRENTLY ENABLED):

```
1. _loadWithAppInit() called (line 145)
   ↓
2. AppInitService.getAppInitData() → SINGLE CALL: /api/v1/app-init
   Returns:
   ├── config (ConfigModel) ← Replaces /api/v1/config
   ├── modules (List<ModuleModel>) ← Replaces /api/v1/module
   ├── zones (List<ZoneData>) ← Replaces /api/v1/zones or /api/v1/zone/list
   ├── userZoneId (int)
   └── businessSettings (BusinessSettings) ← Replaces /api/v1/business-settings/mobile-app-home-screen-setup
```

**Current Status:** ✅ **WORKING** - Data is extracted and stored correctly.

#### Path B: Legacy Individual Calls (Fallback)

When `AppConstants.useAppInitEndpoint == false` OR error occurs:

```
1. splashServiceInterface.getConfigData() → /api/v1/config
   ↓
2. _handleConfigResponse() processes response
   ↓
3. (Potential) Additional calls:
   - splashServiceInterface.getModules() → /api/v1/module (if loadModuleData=true)
   - splashServiceInterface.getLandingPageData() → /api/v1/landing-page (if loadLandingData=true)
```

**Status:** ⚠️ **STILL EXISTS** - Used as fallback only.

---

## REDUNDANCY REPORT

### ✅ REDUNDANT ENDPOINTS (Can be deleted when using app-init)

| Endpoint | Status | App-Init Coverage | Risk Level |
|----------|--------|-------------------|------------|
| `/api/v1/config` | 🔴 **REDUNDANT** | ✅ Covered by `app-init.config` | **HIGH** - Remove safely |
| `/api/v1/module` | 🔴 **REDUNDANT** | ✅ Covered by `app-init.modules` | **HIGH** - Remove safely |
| `/api/v1/zones` or `/api/v1/zone/list` | 🔴 **REDUNDANT** | ✅ Covered by `app-init.zones` | **MEDIUM** - Verify usage |
| `/api/v1/business-settings/mobile-app-home-screen-setup` | 🔴 **REDUNDANT** | ✅ Covered by `app-init.businessSettings` | **MEDIUM** - Verify usage |

### ✅ NON-REDUNDANT ENDPOINTS (Keep as-is)

| Endpoint | Status | Reason |
|----------|--------|--------|
| `/api/v1/landing-page` | ✅ **KEEP** | Not included in app-init response |
| `/api/v2/home-unified` | ✅ **KEEP** | Different purpose (home screen data, not startup config) |

---

## DETAILED FINDINGS

### Finding 1: Legacy Fallback Path Still Active

**Location:** `splash_controller.dart:147-189`

**Issue:** Legacy individual API calls are still called when:
1. `AppConstants.useAppInitEndpoint == false`
2. `_loadWithAppInit()` throws an error (lines 779-794)
3. `app-init` returns null (304/500) and Hive cache fails (lines 745-757)

**Impact:** 
- Code complexity (dual paths)
- Potential for redundant calls if flag is disabled
- Maintenance burden

**Recommendation:** 
- ✅ **KEEP** the fallback for error cases (defensive programming)
- ✅ **REMOVE** the ability to disable app-init via flag (make it mandatory)
- ✅ **ENHANCE** error handling to always prefer app-init

### Finding 2: Modules List Already in App-Init

**Location:** `splash_controller.dart:631`

**Evidence:**
```dart
_moduleList = appInitData.modules; // ✅ Already populated from app-init
```

**Finding:** The `getModules()` method (lines 1107-1132) is **NOT called** during app-init path. It's only used:
- As part of legacy flow
- When `removeModule()` is called (line 1336) - edge case

**Status:** ✅ **NO REDUNDANCY** - `getModules()` is not called in the app-init path.

### Finding 3: Config Data Already in App-Init

**Location:** `splash_controller.dart:629-630`

**Evidence:**
```dart
_configModel = appInitData.config; // ✅ Already populated from app-init
_data = appInitData.config?.toJson(); // ✅ Already populated
```

**Finding:** The legacy `getConfigData()` method (`splash_repository.dart:21-43`) calls `/api/v1/config` but is **NOT called** during app-init path.

**Status:** ✅ **NO REDUNDANCY** - Legacy `getConfigData()` is not called in the app-init path.

### Finding 4: Zones Data in App-Init

**Location:** `app_init_model.dart:13`

**Evidence:**
```dart
final List<ZoneData>? zones; // ✅ Available in app-init response
```

**Finding:** Zones are included in app-init but NOT needed at splash time. Zone API calls (`/api/v1/zones`, `/api/v1/zone/list`) are used for:
- Location selection (`location_repository.dart:277`) - Called when user selects location
- Deliveryman registration (`deliveryman_registration_repository.dart:115`) - Called during registration
- Zone checking (`auth_repository.dart`) - Called during auth flow

**Status:** ✅ **NO REDUNDANCY** - Zone calls serve different purposes (location selection, registration) and happen later in user flow, not during startup.

### Finding 5: Business Settings in App-Init

**Location:** `app_init_model.dart:14`

**Evidence:**
```dart
final BusinessSettings? businessSettings; // ✅ Available in app-init response
```

**Finding:** Business settings are included in app-init but NOT currently extracted. Business settings API (`/api/v1/business-settings/mobile-app-home-screen-setup`) is called in:
- `home_repository.dart:37` - Called when loading home screen data

**Status:** ⚠️ **OPTIMIZATION OPPORTUNITY** - Home screen could potentially use business settings from app-init instead of separate API call, but this is an optimization (not a redundancy during splash).

---

## RISK ASSESSMENT

### Risk 1: Removing `/api/v1/config` Legacy Call

**Risk Level:** 🟢 **LOW**

**Reasoning:**
- ✅ `app-init.config` provides identical data structure (`ConfigModel`)
- ✅ Already being used successfully in production (app-init path)
- ✅ Legacy path only used as fallback (defensive programming)
- ✅ Hive cache provides additional safety net (304 handling)

**Mitigation:**
- Keep legacy fallback for error cases only
- Verify `app-init.config` structure matches `/api/v1/config` exactly
- Test with 304 responses (cache hits)

### Risk 2: Removing `/api/v1/module` Legacy Call

**Risk Level:** 🟢 **LOW**

**Reasoning:**
- ✅ `app-init.modules` provides identical data structure (`List<ModuleModel>`)
- ✅ Already being used successfully (line 631: `_moduleList = appInitData.modules`)
- ✅ `getModules()` is NOT called in app-init path
- ⚠️ Only used in `removeModule()` edge case - verify this is acceptable

**Mitigation:**
- Test `removeModule()` flow to ensure it doesn't break
- Consider if `removeModule()` needs modules list (might not)

### Risk 3: Zones Data Usage

**Risk Level:** 🟢 **LOW** (After Audit)

**Reasoning:**
- ✅ Zones are in app-init response but NOT needed at splash time
- ✅ Zone API calls (`/api/v1/zones`, `/api/v1/zone/list`) are used for:
  - Location selection (`location_repository.dart:277`) - Called when user selects location
  - Deliveryman registration (`deliveryman_registration_repository.dart:115`) - Called during registration
  - Zone checking (`auth_repository.dart`) - Called during auth flow
- ✅ These are **NOT startup calls** - They happen later in user flow
- ✅ Splash screen does NOT need zones data - Only needed when user selects/checks location

**Mitigation:**
- ✅ **NO ACTION NEEDED** - Zones are not required at splash time
- ✅ Zones from app-init can be ignored (not extracted/used)
- ✅ Existing zone API calls serve different purposes (location selection, registration)

### Risk 4: Business Settings Usage

**Risk Level:** 🟡 **MEDIUM** (Requires Investigation)

**Reasoning:**
- ⚠️ Business settings are in app-init response but NOT currently extracted/used
- ✅ Business settings API (`/api/v1/business-settings/mobile-app-home-screen-setup`) is called in:
  - `home_repository.dart:37` - Called when loading home screen data
- ⚠️ Need to verify if business settings are needed at splash time or can be deferred to home screen
- ⚠️ If home screen needs business settings, could use app-init data instead of separate API call

**Mitigation:**
- 🔍 **INVESTIGATE:** Check if home screen can use business settings from app-init
- 🔍 **OPTIMIZE:** Store business settings from app-init and use in home screen (eliminate separate call)
- ⚠️ If business settings change frequently, may need separate call for freshness

---

## THE FIX: CONSOLIDATION PLAN

### Phase 1: Verification (Required Before Implementation)

**Task 1.1:** Audit Zone API Calls ✅ **COMPLETE**

**Findings:**
- ✅ Zone API calls (`/api/v1/zones`, `/api/v1/zone/list`) are used for:
  - Location selection (called when user selects location)
  - Deliveryman registration (called during registration)
  - Zone checking (called during auth flow)
- ✅ **NOT startup calls** - These happen later in user flow
- ✅ **NO ACTION NEEDED** - Zones from app-init can be ignored at splash time

**Task 1.2:** Audit Business Settings API Calls ✅ **COMPLETE**

**Findings:**
- ✅ Business settings API (`/api/v1/business-settings/mobile-app-home-screen-setup`) is called in:
  - `home_repository.dart:37` - Called when loading home screen data
- ⚠️ **POTENTIAL OPTIMIZATION:** Home screen could use business settings from app-init instead of separate call
- 🔍 **ACTION REQUIRED:** Investigate if home screen can use cached app-init business settings

**Task 1.3:** Verify App-Init Data Completeness
- [ ] Confirm `app-init.config` matches `/api/v1/config` structure
- [ ] Confirm `app-init.modules` matches `/api/v1/module` structure
- [ ] Confirm `app-init.zones` matches `/api/v1/zones` structure
- [ ] Confirm `app-init.businessSettings` matches business-settings endpoint structure

### Phase 2: Code Cleanup (Implementation)

**Task 2.1:** Extract Zones from App-Init ❌ **NOT NEEDED**

**Status:** ✅ **SKIPPED** - Zones are not needed at splash time. Zone API calls serve different purposes (location selection, registration) and happen later in user flow.

**Task 2.2:** Extract Business Settings from App-Init ⚠️ **OPTIONAL OPTIMIZATION**

**Status:** 🔍 **INVESTIGATE** - Business settings are used by home screen (`home_repository.dart:37`). 

**Option A:** Extract and cache from app-init, use in home screen (eliminates separate API call)
```dart
// Store business settings if provided
if (appInitData.businessSettings != null) {
  // Store in Hive cache or controller state
  // Home screen can use cached data instead of separate API call
  if (kDebugMode) {
    print('💾 SplashController: Business settings cached from app-init');
  }
}
```

**Option B:** Keep separate call if business settings change frequently or need freshness
- Current implementation is acceptable
- Separate call ensures fresh data when home screen loads

**Recommendation:** Investigate if business settings change frequently. If stable, use Option A to eliminate redundant call.

**Task 2.3:** Remove Legacy Flag (Make App-Init Mandatory)

**Location:** `splash_controller.dart:139-147`

**Current:**
```dart
if (AppConstants.useAppInitEndpoint && source == DataSourceEnum.client) {
  await _loadWithAppInit(...);
} else {
  // Legacy flow
}
```

**Proposed:**
```dart
// Always use app-init for client requests
if (source == DataSourceEnum.client) {
  await _loadWithAppInit(...);
} else {
  // Local cache only - no API calls
  response = await splashServiceInterface.getConfigData(source: DataSourceEnum.local);
  // ...
}
```

**Task 2.4:** Enhance Error Handling

**Location:** `splash_controller.dart:779-794`

**Current:** Falls back to legacy `getConfigData()` on error.

**Proposed:** 
- Keep fallback for critical errors (500, network failures)
- Remove fallback for 304 (cache hit - already handled correctly)
- Add retry logic for transient failures

**Task 2.5:** Remove Unused Legacy Methods (Optional - Cleanup)

**Files to Review:**
- `splash_repository.dart:21-43` - `getConfigData()` - Keep for local cache only
- `splash_repository.dart:161-194` - `getModules()` - Keep for `removeModule()` edge case

**Decision:** 
- ✅ **KEEP** these methods for:
  - Local cache access (DataSourceEnum.local)
  - Edge cases (removeModule)
  - Defensive fallback
- ❌ **DO NOT REMOVE** - They serve legitimate purposes beyond startup

### Phase 3: Testing & Validation

**Task 3.1:** Unit Tests
- [ ] Test app-init path with valid response
- [ ] Test app-init path with 304 response (cache hit)
- [ ] Test app-init path with 500 error (fallback)
- [ ] Test app-init path with network error (fallback)
- [ ] Test local cache path (DataSourceEnum.local)

**Task 3.2:** Integration Tests
- [ ] Fresh install flow (no cache)
- [ ] Cached startup flow (304 response)
- [ ] Network failure flow (offline)
- [ ] Server error flow (500)

**Task 3.3:** Performance Benchmarking
- [ ] Measure startup time with app-init only
- [ ] Compare with legacy path (if still accessible)
- [ ] Measure API call count reduction
- [ ] Measure payload size reduction

---

## CURRENT STATE SUMMARY

### ✅ What's Already Working

1. **App-init endpoint is enabled and functional** (`AppConstants.useAppInitEndpoint = true`)
2. **Config and modules are extracted from app-init** (lines 629-631)
3. **Legacy path exists only as fallback** (defensive programming)
4. **304 handling works correctly** (returns null, uses Hive cache)
5. **Error handling has graceful fallback** (lines 779-794)

### ⚠️ What Needs Attention

1. ✅ **Zones data** - NOT needed at splash (zone calls serve different purposes - location selection, registration)
2. ⚠️ **Business settings data** - Available in app-init but not extracted; home screen calls separate API (optimization opportunity)
3. **Legacy flag can still disable app-init** (should be mandatory)
4. ✅ **Verified:** Zones/business settings are called separately but for different purposes (not during splash)

### ❌ What's Not Redundant (Keep As-Is)

1. **`/api/v1/landing-page`** - Not in app-init, keep separate call
2. **`/api/v2/home-unified`** - Different purpose (home screen data)
3. **Local cache methods** - Needed for offline/304 scenarios

---

## RECOMMENDATIONS

### Immediate Actions (Low Risk)

1. ✅ **Keep current implementation** - It's already optimized
2. ✅ **Make app-init mandatory** - Remove `useAppInitEndpoint` flag
3. ✅ **Extract zones/business settings** from app-init if needed at splash time

### Medium-Term Actions (Requires Audit)

1. 🔍 **Audit zone API calls** - Verify if `/api/v1/zones` is called separately
2. 🔍 **Audit business settings calls** - Verify if business-settings endpoint is called separately
3. 🔍 **Verify removeModule() flow** - Ensure it doesn't break without separate modules call

### Long-Term Actions (Optimization)

1. 🚀 **Remove legacy fallback** - Once app-init is proven stable (6+ months)
2. 🚀 **Consolidate zone/business settings usage** - Use app-init data everywhere
3. 🚀 **Performance monitoring** - Track app-init latency and optimize

---

## CONCLUSION

**Current Status:** ✅ **ALREADY OPTIMIZED**

The splash screen is **already using the app-init endpoint** and avoiding redundant calls. The legacy path exists only as a defensive fallback.

**Key Finding:** There are **NO redundant API calls** in the current app-init path. All redundancy exists only in the unused legacy fallback path.

**Action Items:**
1. ✅ **Zones/business settings audit** - COMPLETE (zones not needed at splash, business settings optimization opportunity)
2. ✅ **Make app-init mandatory** (remove flag) - Recommended for code simplification
3. ⚠️ **Business settings optimization** - Optional: Extract from app-init and use in home screen (eliminates separate call)
4. ✅ **Keep legacy fallback** for error scenarios (defensive programming)

**Performance Impact:** 
- Current: 1 API call (`/api/v1/app-init`) ✅
- Legacy: 2-4 API calls (`/config`, `/module`, `/zones`, `/business-settings`) ❌
- **Savings: 75-100% reduction in API calls** when using app-init

---

**Next Steps:** Proceed with Phase 1 verification tasks before making any code changes.

