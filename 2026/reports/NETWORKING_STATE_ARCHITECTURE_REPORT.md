# Networking and State Architecture Report
## Parallel ETag-Driven Startup Analysis

**Date**: Current State Analysis
**Focus**: ApiClient Interceptors, Splash Sequencing, Hive Storage, Navigation Race Conditions

---

## 1. ApiClient Interceptors & Header Injection

### File: `lib/api/api_client.dart`

### Current Interceptor Architecture

**ApiClient does NOT have direct Dio interceptors**. Instead:
- ApiClient uses `SecureHttpClient` (Dio-based) for secure requests
- `SecureHttpClient` has interceptors in `lib/common/security/secure_http_client.dart`
- ApiClient falls back to standard `http` package for non-secure requests

### SecureHttpClient Interceptors

**Location**: `lib/common/security/secure_http_client.dart:76-221`

```dart
void _addSecurityInterceptors() {
  _dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 1. Request ID generation
        // 2. Rate limiting check
        // 3. Security headers addition
        // 4. Request data validation
        // 5. Request integrity check
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // 1. Response integrity validation
        // 2. Response data validation
        handler.next(response);
      },
      onError: (error, handler) async {
        // 1. Retry logic for timeout errors
        // 2. Security error logging
        handler.next(error);
      },
    ),
  );
}
```

**Current Interceptors**:
- ✅ Request ID generation (`X-Request-ID`)
- ✅ Rate limiting (`_checkRateLimit`)
- ✅ Security headers (`_addSecurityHeaders`)
- ✅ Request validation (`_validateRequestData`)
- ✅ Request integrity check (`_addRequestIntegrity`)
- ✅ Response integrity validation (`_validateResponseIntegrity`)
- ✅ Response data validation (`_validateResponseData`)
- ✅ Error retry logic (`_shouldRetry`, `_retryRequest`)
- ❌ **NO ETag interceptor** (ETags handled in ApiClient.getData())

### Centralized Header Injection

**Location**: `lib/api/api_client.dart:229-297`

**Method**: `updateHeader()` - **This is the centralized place for header injection**

```dart
Map<String, String> updateHeader(
  String? token,
  List<int>? zoneIDs,
  List<int>? operationIds,
  String? languageCode,
  int? moduleID,  // ✅ ModuleId injected here
  String? latitude,
  String? longitude,
  {bool setHeader = true}
) {
  Map<String, String> header = {};
  
  // Zone IDs with fallback
  List<int>? validZoneIDs = zoneIDs ?? [2, 4, 3, 5]; // Default fallback
  
  // Coordinates with fallback
  String? validLatitude = latitude ?? '24.604301879077966';
  String? validLongitude = longitude ?? '46.59593515098095';
  
  // ✅ ModuleId injection (if provided or cached)
  if (moduleID != null || sharedPreferences.getString(AppConstants.cacheModuleId) != null) {
    header.addAll({
      AppConstants.moduleId: '${moduleID ?? ...}'
    });
  }
  
  // Standard headers
  header.addAll({
    'Content-Type': 'application/json; charset=UTF-8',
    AppConstants.zoneId: jsonEncode(validZoneIDs),
    AppConstants.localizationKey: languageCode ?? AppConstants.languages[0].languageCode!,
    AppConstants.latitude: jsonEncode(validLatitude),
    AppConstants.longitude: jsonEncode(validLongitude),
    'Authorization': 'Bearer ${token ?? ''}'
  });
  
  if (setHeader) {
    _mainHeaders = header;  // ✅ Stored for all subsequent requests
  }
  return header;
}
```

### Header Merging in getData()

**Location**: `lib/api/api_client.dart:345-373`

```dart
Future<Response> getData(String uri, {Map<String, String>? headers, ...}) async {
  // ⚠️ CRITICAL: Merge custom headers with default headers
  // Custom headers override defaults, but defaults provide moduleId, zoneId, etc.
  Map<String, String> finalHeaders = Map<String, String>.from(_mainHeaders);  // ✅ Default headers (includes moduleId)
  if (headers != null) {
    finalHeaders.addAll(headers);  // Custom headers override defaults
  }
  
  // ETag support
  if (useEtag && !finalHeaders.containsKey('If-None-Match')) {
    final storedEtag = await _getStoredEtag(uri);
    if (storedEtag != null) {
      finalHeaders['If-None-Match'] = storedEtag;
    }
  }
  
  // Debug: Warn if moduleId missing for data APIs
  if (kDebugMode && !_isConfigApi(uri)) {
    if (!finalHeaders.containsKey(AppConstants.moduleId)) {
      appLogger.warning('moduleId header missing for API: $uri');
    }
  }
}
```

**Summary**:
- ✅ **Centralized header injection**: `updateHeader()` method
- ✅ **Default headers stored**: `_mainHeaders` map
- ✅ **Header merging**: Custom headers override defaults, but defaults always included
- ✅ **ModuleId injection**: Handled in `updateHeader()` and merged in `getData()`
- ❌ **No ETag interceptor in SecureHttpClient**: ETags handled directly in ApiClient.getData()

---

## 2. Splash Sequencing (_loadWithAppInit)

### File: `lib/features/splash/controllers/splash_controller.dart:168-308`

### Current Implementation

```dart
Future<void> _loadWithAppInit(
  context,
  NotificationBodyModel? notificationBody,
  bool loadModuleData,
  bool loadLandingData,
  bool fromMainFunction,
  bool fromDemoReset,
  bool shouldRoute
) async {
  try {
    final appInitService = AppInitService(apiClient: Get.find<ApiClient>());
    
    if (kDebugMode) {
      print('📡 SplashController: Calling app-init endpoint...');
    }
    
    // ❌ BLOCKING: Awaits app-init API call
    final appInitData = await appInitService.getAppInitData(
      headers: HeaderHelper.featuredHeader(),
      gracefulFallback: true,
    );
    
    if (appInitData != null) {
      // Store data
      _configModel = appInitData.config;
      _data = appInitData.config?.toJson();
      _moduleList = appInitData.modules;
      
      // Update UI (only moduleList listeners)
      update(['moduleList']);
      
      // Store business settings in SharedPreferences
      if (appInitData.businessSettings != null) {
        await Get.find<SharedPreferences>().setString(
          'app_init_business_settings',
          jsonEncode(appInitData.businessSettings!.toJson()),
        );
      }
      
      // Set module (if available)
      if (_configModel!.module != null) {
        await setModule(_configModel!.module);  // ❌ BLOCKING
      }
      
      // Load landing data (if needed)
      if (loadLandingData) {
        await getLandingPageData();  // ❌ BLOCKING
      }
      
      // Route to next screen
      if (shouldRoute) {
        route(context, body: notificationBody);  // ❌ BLOCKING - blocks transition
      }
      
      _onRemoveLoader();
    } else {
      // Handle 304 Not Modified or error
      // Uses cached data or falls back to legacy calls
    }
  } catch (e, stackTrace) {
    // Fallback to legacy calls
  }
  
  update();  // Final UI update
}
```

### Blocking Analysis

**Sequence of blocking operations**:
1. ✅ `await appInitService.getAppInitData()` - **BLOCKS** (API call ~2-3 seconds)
2. ✅ `await setModule()` - **BLOCKS** (if module available)
3. ✅ `await getLandingPageData()` - **BLOCKS** (if loadLandingData is true)
4. ✅ `route(context, ...)` - **BLOCKS** transition to MultiModuleHomeScreen

**Impact on MultiModuleHomeScreen**:
- ❌ **BLOCKING**: `_loadWithAppInit()` must complete before routing
- ❌ **No parallel loading**: Cannot load home-unified data in parallel
- ❌ **Sequential execution**: App-init → setModule → route → home-unified (if any)

**Current Flow**:
```
Splash Screen
  ↓
_loadWithAppInit() [BLOCKS ~2-3s]
  ↓
setModule() [BLOCKS ~100ms]
  ↓
route() [BLOCKS - navigates to MultiModuleHomeScreen]
  ↓
MultiModuleHomeScreen.initState()
  ↓
_loadData() [loads home-unified data]
```

**Summary**:
- ❌ **BLOCKING**: `_loadWithAppInit()` blocks transition to MultiModuleHomeScreen
- ❌ **Sequential**: All operations happen sequentially, no parallelization
- ✅ **Graceful fallback**: Handles 304 Not Modified and errors gracefully

---

## 3. Hive Storage for app-init and home-unified

### File: `lib/core/cache/hive_home_cache_service.dart`

### app-init Caching

**Current State**: ❌ **NOT cached in Hive**

**Storage Location**: `lib/features/splash/controllers/splash_controller.dart:219-222`

```dart
// Store business settings if provided (cache for later use)
if (appInitData.businessSettings != null) {
  // ❌ Stored in SharedPreferences, NOT Hive
  await Get.find<SharedPreferences>().setString(
    'app_init_business_settings',  // Key: 'app_init_business_settings'
    jsonEncode(appInitData.businessSettings!.toJson()),  // Raw JSON string
  );
}
```

**Storage Details**:
- **Location**: SharedPreferences (not Hive)
- **Key**: `'app_init_business_settings'`
- **Format**: Raw JSON string (not TypeAdapter)
- **Data**: Only `BusinessSettings` object (not full `AppInitModel`)

**Hive Box Names**: ❌ **No Hive box for app-init**

### home-unified Caching

**Current State**: ✅ **Cached in Hive**

**Storage Location**: `lib/core/cache/hive_home_cache_service.dart:816-879`

**Hive Box Name**:
```dart
// Location: lib/core/cache/hive_cache_config.dart:61
static String getHomeUnifiedBoxName(int moduleId) => 'home_unified_module_$moduleId';
```

**Example**: `'home_unified_module_3'` for module 3

**Storage Implementation**:

```dart
// Save unified home data
Future<void> saveHomeUnifiedData(int moduleId, HomeUnifiedModel data) async {
  final boxName = HiveCacheConfig.getHomeUnifiedBoxName(moduleId);  // 'home_unified_module_{moduleId}'
  final box = await _getLazyBox(boxName);
  
  // ⚡ Perform JSON encoding in isolate (non-blocking)
  final jsonData = data.toJson();
  final jsonString = await JsonIsolateHelper.encodeJson(jsonData);  // ✅ Raw JSON string
  
  await box.put('home_unified', jsonString);  // Key: 'home_unified'
  await _saveTimestamp(boxName, 'home_unified', DateTime.now());
}

// Load unified home data
Future<HomeUnifiedModel?> loadHomeUnifiedData(int moduleId) async {
  final boxName = HiveCacheConfig.getHomeUnifiedBoxName(moduleId);
  final box = await _getLazyBox(boxName);
  
  final data = await box.get('home_unified');  // ✅ LazyBox.get() is async
  if (data != null && data is String) {
    // ⚡ Perform JSON decoding in isolate (non-blocking)
    final jsonMap = await JsonIsolateHelper.decodeJson(data);
    final model = HomeUnifiedModel.fromJson(jsonMap);  // ✅ Parsed from JSON
    return model;
  }
  return null;
}
```

**Storage Details**:
- **Location**: Hive LazyBox
- **Box Name**: `'home_unified_module_{moduleId}'` (module-specific)
- **Key**: `'home_unified'`
- **Format**: ✅ **Raw JSON string** (not TypeAdapter)
- **Encoding**: JSON encoding/decoding done in isolate (via `JsonIsolateHelper`)
- **Data**: Full `HomeUnifiedModel` object

**Summary**:

| Endpoint | Hive Box | Format | TypeAdapter | Location |
|----------|----------|--------|-------------|----------|
| `/api/v1/app-init` | ❌ None | Raw JSON | ❌ No | SharedPreferences (`'app_init_business_settings'`) |
| `/api/v2/home-unified` | ✅ `'home_unified_module_{moduleId}'` | Raw JSON | ❌ No | Hive LazyBox (`'home_unified'` key) |

**Key Findings**:
- ❌ **app-init NOT in Hive**: Stored in SharedPreferences as raw JSON
- ✅ **home-unified in Hive**: Stored in module-specific Hive box as raw JSON
- ❌ **No TypeAdapters**: Both use raw JSON strings (not TypeAdapters)
- ✅ **Isolate-based encoding**: home-unified uses `JsonIsolateHelper` for non-blocking JSON operations

---

## 4. Navigation Race Condition (switchModule)

### File: `lib/features/splash/controllers/splash_controller.dart:653-734`

### Current Implementation

```dart
void switchModule(context, int index, bool fromPhone) async {
  if (_moduleList != null && index < _moduleList!.length) {
    final moduleToSwitch = _moduleList![index];
    
    // ✅ AWAITS setModule
    await Get.find<SplashController>().setModule(moduleToSwitch);
    _module = moduleToSwitch;
    
    // Load cart data (non-blocking)
    if (cartController.cartList.isEmpty) {
      cartController.getCartDataOnline();  // ❌ NOT awaited
    }
    
    // Check cache validity
    bool isCacheValid = await ComprehensiveHomeCacheManager.isCacheValid();
    
    // Clear controllers if cache invalid
    if (!isCacheValid) {
      await _clearAllControllerData(moduleToSwitch.moduleType.toString());
    }
    
    // Load home data
    HomeScreen.loadData(context, shouldForceRefresh, fromModule: true);  // ❌ NOT awaited
  }
}
```

### setModule() Implementation

**Location**: `lib/features/splash/controllers/splash_controller.dart:486-532`

```dart
Future<void> setModule(ModuleModel? module, {bool notify = true}) async {
  _module = module;
  await splashServiceInterface.setModule(module);  // ✅ AWAITED
  
  if (module != null) {
    // Update module config from _data
    // ... (synchronous operations)
    
    _cacheModule = await splashServiceInterface.setCacheModule(module);  // ✅ AWAITED
    
    // Load cart data if logged in
    if ((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) && cacheModule != null) {
      // ... (cart loading)
    }
  }
}
```

### updateHeader() Call

**Location**: `lib/features/splash/controllers/splash_controller.dart:951, 1007`

```dart
// Called in various places, but NOT in setModule() or switchModule()
apiClient.updateHeader(
  apiClient.token,
  addressModel?.zoneIds,
  addressModel?.areaIds,
  languageCode,
  moduleID,  // ✅ ModuleId passed here
  addressModel?.latitude,
  addressModel?.longitude,
);
```

**Critical Finding**: ❌ **setModule() does NOT call updateHeader()**

### Race Condition Analysis

**Problem**: `switchModule()` → `setModule()` → `HomeScreen.loadData()`

1. ✅ `setModule()` is awaited - module is set in SplashController
2. ❌ **updateHeader() is NOT called** - ApiClient headers still have old moduleId
3. ❌ `HomeScreen.loadData()` is NOT awaited - starts immediately
4. ❌ **Race condition**: HomeScreen.loadData() may use old moduleId in headers

**Sequence**:
```
switchModule()
  ↓
await setModule()  [Module set in SplashController]
  ↓
HomeScreen.loadData()  [Starts immediately, may use OLD moduleId in ApiClient headers]
  ↓
ApiClient.getData()  [Uses _mainHeaders which still has OLD moduleId]
```

**Evidence**:
- `setModule()` does NOT call `apiClient.updateHeader()`
- `switchModule()` does NOT call `apiClient.updateHeader()`
- `HomeScreen.loadData()` uses `ApiClient.getData()` which uses `_mainHeaders`
- `_mainHeaders` is only updated when `updateHeader()` is explicitly called

**Summary**:
- ❌ **Race Condition EXISTS**: `setModule()` doesn't update ApiClient headers
- ❌ **Headers not synchronized**: Module set in SplashController but not in ApiClient
- ❌ **HomeScreen.loadData() not awaited**: May start before headers are updated
- ⚠️ **Potential fix**: Call `apiClient.updateHeader()` in `setModule()` or `switchModule()`

---

## Summary & Recommendations

### 1. ApiClient Interceptors
- ✅ **Centralized header injection**: `updateHeader()` method
- ✅ **Header merging**: Default headers always included
- ❌ **No ETag interceptor in SecureHttpClient**: ETags handled in ApiClient.getData()
- **Recommendation**: Add ETag interceptor to SecureHttpClient for consistency

### 2. Splash Sequencing
- ❌ **BLOCKING**: `_loadWithAppInit()` blocks transition to MultiModuleHomeScreen
- ❌ **Sequential execution**: No parallel loading
- **Recommendation**: Use `Future.wait()` to parallelize app-init and home-unified loading

### 3. Hive Storage
- ❌ **app-init NOT in Hive**: Stored in SharedPreferences
- ✅ **home-unified in Hive**: Module-specific boxes with raw JSON
- ❌ **No TypeAdapters**: Both use raw JSON strings
- **Recommendation**: Migrate app-init to Hive with TypeAdapter for structured storage

### 4. Navigation Race Condition
- ❌ **Race condition EXISTS**: `setModule()` doesn't update ApiClient headers
- ❌ **Headers not synchronized**: Module set but headers not updated
- **Recommendation**: Call `apiClient.updateHeader()` in `setModule()` or ensure headers are updated before `HomeScreen.loadData()`

---

**Report Complete**: All four points analyzed with file paths and code snippets.

