# Networking and Caching Architecture Report
## Parallel, ETag-driven Startup Analysis

---

## 1. ApiClient Interceptors

### File Path
- **Primary**: `lib/api/api_client.dart`
- **Secure Client**: `lib/common/security/secure_http_client.dart`

### Current Implementation

#### ApiClient (Standard HTTP Client)
**Location**: `lib/api/api_client.dart:315-570`

**Key Features**:
- **ETag Support**: ✅ Implemented
  - Lines 355-364: Adds `If-None-Match` header from stored ETag
  - Lines 419-428: Extracts and stores ETag from Dio responses
  - Lines 509-518: Extracts and stores ETag from HTTP responses
  - Lines 430-449: Handles 304 Not Modified responses
  - Lines 520-534: Handles 304 Not Modified for HTTP fallback

**ETag Storage**:
```dart
// Lines 42-43: ETag prefix constant
static const String _etagPrefix = 'etag_';

// Lines 844-867: ETag getter/setter methods
Future<String?> _getStoredEtag(String uri) async {
  final etagKey = '$_etagPrefix${uri.replaceAll('/', '_').replaceAll(':', '_')}';
  return sharedPreferences.getString(etagKey);
}

Future<void> _storeEtag(String uri, String etag) async {
  final etagKey = '$_etagPrefix${uri.replaceAll('/', '_').replaceAll(':', '_')}';
  await sharedPreferences.setString(etagKey, etag);
}
```

**Header Management**:
- Lines 345-350: Merges custom headers with default headers
- Lines 278-297: `updateHeader()` method manages zone IDs, module ID, coordinates
- Lines 366-373: Debug logging for moduleId header validation

**No Custom Interceptors**: 
- ApiClient uses standard `http` package (no Dio interceptors)
- SecureHttpClient (Dio-based) has interceptors (see below)

#### SecureHttpClient (Dio-based with Interceptors)
**Location**: `lib/common/security/secure_http_client.dart:76-221`

**Interceptors Implemented**:
```dart
// Lines 79-220: InterceptorsWrapper with three handlers
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      // 1. Rate limiting check (line 94)
      // 2. Security headers (line 105)
      // 3. Request validation (line 108)
      // 4. Request integrity check (line 119)
    },
    onResponse: (response, handler) async {
      // 1. Response integrity validation (line 155)
      // 2. Response data validation (line 166)
    },
    onError: (error, handler) async {
      // 1. Retry logic for timeouts (line 200-204)
      // 2. Error logging (line 208-212)
    },
  ),
);
```

**304 Status Code Support**:
```dart
// Line 60-62: validateStatus allows 304
validateStatus: (status) {
  return status != null && (status >= 200 && status < 300 || status == 304);
},
```

**Current Limitations**:
- ❌ No ETag handling in SecureHttpClient interceptors (only in ApiClient)
- ❌ No parallel request coordination
- ❌ No request deduplication

---

## 2. Splash Initialization

### File Paths
- **Controller**: `lib/features/splash/controllers/splash_controller.dart`
- **Cached Loader**: `lib/common/cache/cached_splash_loader.dart`
- **Service**: `lib/features/splash/domain/services/app_init_service.dart`

### Current Sequence

#### Phase 1: CachedSplashLoader.loadSplashData()
**Location**: `lib/common/cache/cached_splash_loader.dart:12-63`

**Flow**:
1. Check cache validity (`SplashCacheManager.isSplashCacheValid()`)
2. If valid: Load from cache → Instant startup
3. If invalid: Load from API
4. Background refresh after 2 seconds (if cache was used)

#### Phase 2: SplashController.getConfigData()
**Location**: `lib/features/splash/controllers/splash_controller.dart:109-166`

**Sequence**:
```dart
// Line 121: Check if app-init endpoint is enabled
if (AppConstants.useAppInitEndpoint && source == DataSourceEnum.client) {
  // Line 126: Call _loadWithAppInit()
  await _loadWithAppInit(...);
} else {
  // Legacy: Individual API calls
  response = await splashServiceInterface.getConfigData(...);
}
```

#### Phase 3: _loadWithAppInit()
**Location**: `lib/features/splash/controllers/splash_controller.dart:169-308`

**Exact Sequence**:
```dart
// Line 178: Create AppInitService
final appInitService = AppInitService(apiClient: Get.find<ApiClient>());

// Line 184: Call app-init endpoint
final appInitData = await appInitService.getAppInitData(
  headers: HeaderHelper.featuredHeader(),
  gracefulFallback: true,
);

// Lines 199-201: Store data
_configModel = appInitData.config;
_data = appInitData.config?.toJson();
_moduleList = appInitData.modules;

// Line 205: Update only moduleList listeners (prevents flickering)
update(['moduleList']);

// Lines 217-227: Cache business settings
if (appInitData.businessSettings != null) {
  await Get.find<SharedPreferences>().setString(
    'app_init_business_settings',
    jsonEncode(appInitData.businessSettings!.toJson()),
  );
}
```

#### AppInitService.getAppInitData()
**Location**: `lib/features/splash/domain/services/app_init_service.dart:20-87`

**Implementation**:
```dart
// Line 30: Single API call to /api/v1/app-init
final Response response = await apiClient.getData(
  AppConstants.appInitUri,  // '/api/v1/app-init'
  headers: headers,
);

// Lines 41-49: Handle 304 Not Modified
if (response.statusCode == 304) {
  return null; // Caller uses cached data
}

// Lines 52-64: Parse response
if (response.statusCode == 200) {
  final appInitModel = AppInitModel.fromJson(response.body);
  return appInitModel;
}
```

**Current Limitations**:
- ❌ **Sequential Loading**: App-init is called AFTER cache check (not parallel)
- ❌ **No Parallel Calls**: Cannot call app-init and home-unified simultaneously
- ❌ **Single ETag**: Only one ETag stored per endpoint (no versioning)

---

## 3. Hive Implementation

### File Paths
- **Service**: `lib/core/cache/hive_home_cache_service.dart`
- **Config**: `lib/core/cache/hive_cache_config.dart`

### Hive Box Names

#### App-Init Caching
**Location**: `lib/features/splash/controllers/splash_controller.dart:217-227`

**Storage Method**: 
- ❌ **NOT using Hive** - Uses SharedPreferences
- Key: `'app_init_business_settings'`
- Format: JSON string (not TypeAdapter)

```dart
await Get.find<SharedPreferences>().setString(
  'app_init_business_settings',
  jsonEncode(appInitData.businessSettings!.toJson()),
);
```

#### Home-Unified Caching
**Location**: `lib/core/cache/hive_home_cache_service.dart:813-842`

**Box Name Pattern**:
```dart
// Line 822: Module-specific box name
final boxName = HiveCacheConfig.getHomeUnifiedBoxName(moduleId);
// Returns: 'home_unified_module_{moduleId}'
```

**Storage Method**:
- ✅ **Uses Hive LazyBox**
- ✅ **Stores as JSON String** (not TypeAdapter)
- ✅ **Uses Isolate for Encoding** (non-blocking)

```dart
// Lines 825-829: JSON encoding in isolate
final jsonData = data.toJson();
final jsonString = await JsonIsolateHelper.encodeJson(jsonData);
await box.put('home_unified', jsonString);
```

**All Hive Box Names** (from `hive_cache_config.dart`):
```dart
// Module-specific boxes (pattern: {dataType}_module_{moduleId})
'banners_module_{moduleId}'           // Line 44
'categories_module_{moduleId}'        // Line 45
'stores_module_{moduleId}'            // Line 46
'brands_module_{moduleId}'            // Line 47
'offers_module_{moduleId}'            // Line 48
'business_settings_module_{moduleId}' // Line 49
'home_unified_module_{moduleId}'      // Line 61

// Shared boxes
'home_cache_metadata'                 // Line 55 (timestamps)
'multi_module_promotional_cache'      // Line 58 (Module 3 banners/offers)
'store_details'                       // Line 52 (store-specific)
```

**TypeAdapters vs JSON Strings**:
- **TypeAdapters**: ✅ Registered for BannerModel, CategoryModel, StoreModel, BrandModel, OffersModel, BusinessSettingsModel
  - Location: `hive_home_cache_service.dart:49-73`
  - Used for: Individual data types (banners, stores, offers)
  
- **JSON Strings**: ✅ Used for HomeUnifiedModel and Categories/Brands lists
  - Location: `hive_home_cache_service.dart:264-266, 313-314, 827-829`
  - Reason: Complex nested structures, easier to serialize/deserialize

**Current Limitations**:
- ❌ **No App-Init Hive Box**: App-init data stored in SharedPreferences (not Hive)
- ❌ **No ETag Storage in Hive**: ETags stored in SharedPreferences (line 43 in api_client.dart)
- ⚠️ **Mixed Storage**: Some data in Hive, some in SharedPreferences

---

## 4. State Rebuilds

### File Path
- **Controller**: `lib/features/home/controllers/home_unified_controller.dart`

### Update() Calls Analysis

#### Total Update() Calls: 5
1. **Line 92**: After loading cached data for instant UI
2. **Line 134**: When `showLoading = true` (initial load)
3. **Line 179**: After distributing cached data
4. **Line 240**: After API data loaded and distributed
5. **Line 246**: On error state
6. **Line 256**: On exception
7. **Line 495**: After background refresh (if data changed)

### Flickering Prevention Checks

#### ✅ Version Hash Comparison
**Location**: `lib/features/home/controllers/home_unified_controller.dart:229-238`

```dart
// Lines 211-212: Extract version hashes
final String? oldVersionHash = _unifiedData?.meta?.versionHash;
final String? newVersionHash = apiData.meta?.versionHash;

// Lines 229-238: Skip update() if version hash unchanged
if (oldVersionHash != null &&
    newVersionHash != null &&
    oldVersionHash == newVersionHash) {
  print('✅ Skip update() - version hash unchanged');
  return true; // Exit without update()
}
```

#### ✅ Deep Equality Checks
**Location**: `lib/features/home/controllers/home_unified_controller.dart:283-305, 356-380`

**Banners**:
```dart
// Lines 283-295: Compare banner IDs and counts
bool shouldUpdateBanners = true;
if (skipUpdateIfIdentical && _unifiedData != null) {
  final cachedBannerModel = _unifiedData!.toBannerModel();
  if (_areBannersIdentical(cachedBannerModel, bannerModel)) {
    shouldUpdateBanners = false; // Skip update()
  }
}
```

**Offers**:
```dart
// Lines 356-371: Compare offer IDs and counts
bool shouldUpdateOffers = true;
if (skipUpdateIfIdentical && _unifiedData != null) {
  if (_areOffersIdentical(_unifiedData!.offers!.first, data.offers!.first)) {
    shouldUpdateOffers = false; // Skip update()
  }
}
```

#### ✅ Background Refresh Checks
**Location**: `lib/features/home/controllers/home_unified_controller.dart:456-467`

```dart
// Lines 456-467: Check version_hash BEFORE distributing data
if (_unifiedData != null &&
    _unifiedData!.meta?.versionHash != null &&
    apiData.meta?.versionHash != null &&
    _unifiedData!.meta!.versionHash == apiData.meta!.versionHash) {
  print('✅ Background refresh - version_hash matches, returning immediately');
  return; // Exit without update() or distribution
}
```

#### ✅ Request Lock (Prevents Duplicate Calls)
**Location**: `lib/features/home/controllers/home_unified_controller.dart:57-58, 191-198`

```dart
// Line 57: Request lock flag
bool _isFetching = false;

// Lines 191-198: Check lock before API call
if (_isFetching) {
  print('🚫 Already fetching, skipping duplicate call');
  _isLoading = false;
  return false;
}
_isFetching = true;
```

#### ✅ Skip Update Flag in Distribution
**Location**: `lib/features/home/controllers/home_unified_controller.dart:267-268, 484-485`

```dart
// Line 267: Parameter to skip updates if identical
bool _distributeDataToControllers(HomeUnifiedModel data,
    {bool skipUpdateIfIdentical = false}) {

// Line 484: Used in background refresh
final shouldUpdateUI = _distributeDataToControllers(apiData,
    skipUpdateIfIdentical: true);

// Line 492: Only update() if controllers were actually updated
if (shouldUpdateUI) {
  update();
}
```

### Current Limitations
- ⚠️ **No isUpdate Flag**: No explicit flag to prevent UI updates during background refresh
- ⚠️ **Multiple Update() Calls**: 7 total update() calls (could be reduced)
- ✅ **Version Hash Works**: Effectively prevents unnecessary rebuilds
- ✅ **Deep Equality Works**: Prevents flickering for banners/offers

---

## Summary & Recommendations

### Current State
1. ✅ **ETag Support**: Fully implemented in ApiClient
2. ✅ **304 Handling**: Properly handled in both ApiClient and AppInitService
3. ✅ **Hive Caching**: Comprehensive module-aware caching
4. ✅ **Flickering Prevention**: Version hash + deep equality checks
5. ❌ **Sequential Loading**: App-init and home-unified not parallel
6. ❌ **Mixed Storage**: App-init in SharedPreferences, home-unified in Hive
7. ⚠️ **No Request Deduplication**: Multiple simultaneous calls possible

### Recommendations for Parallel, ETag-driven Startup

1. **Parallel API Calls**:
   - Call `/api/v1/app-init` and `/api/v2/home-unified` simultaneously
   - Use `Future.wait()` for coordination

2. **Unified ETag Storage**:
   - Move ETag storage to Hive (currently in SharedPreferences)
   - Store ETags per endpoint with version metadata

3. **Request Deduplication**:
   - Add request queue to prevent duplicate calls
   - Use request IDs for tracking

4. **App-Init Hive Box**:
   - Create dedicated Hive box for app-init data
   - Use TypeAdapter for AppInitModel

5. **Enhanced Update Flags**:
   - Add `_isBackgroundRefresh` flag
   - Skip update() during background refresh unless data changed

---

**Report Generated**: Based on codebase analysis
**Files Analyzed**: 8 core files
**Lines Reviewed**: ~2,500 lines of code

