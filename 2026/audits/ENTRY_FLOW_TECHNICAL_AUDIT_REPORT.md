# Full Technical Audit: Entry Flow (Splash & Landing Page)

**Date**: Generated from codebase analysis  
**Objective**: Comprehensive report on data flow and API dependencies for initial app sequence to ensure 100% alignment with Laravel backend

---

## 1. Splash Screen Audit

### 1.1 Bootstrap/Config API Calls

The app uses **TWO different bootstrap strategies** based on `AppConstants.useAppInitEndpoint`:

#### **Strategy A: App-Init Endpoint (Preferred - Phase 2)**
- **Endpoint**: `/api/v1/app-init`
- **Method**: `GET`
- **Location**: `lib/features/splash/domain/services/app_init_service.dart:30`
- **Headers**: Uses `HeaderHelper.featuredHeader()` (no moduleId required)
- **Response Model**: `AppInitModel` containing:
  - `config`: `ConfigModel` (same as legacy config endpoint)
  - `modules`: `List<ModuleModel>` (all available modules)
  - `zones`: `List<ZoneModel>` (available zones)
  - `userZoneId`: `int?` (user's current zone)
  - `businessSettings`: `BusinessSettingsModel?`

**Status Codes Handled**:
- `200`: Success - parse and use data
- `304`: Not Modified - use cached data from Hive (treated as success)
- `500`: Server Error - fallback to Hive cache (no error dialog)

#### **Strategy B: Legacy Individual Calls (Fallback)**
- **Primary Endpoint**: `/api/v1/config`
- **Method**: `GET`
- **Location**: `lib/features/splash/domain/repositories/splash_repository.dart:27`
- **Headers**: Standard headers (no moduleId required for config)
- **Response**: Full `ConfigModel` JSON

**Additional Legacy Calls** (if `loadModuleData=true`):
- **Modules Endpoint**: `/api/v1/module`
- **Method**: `GET`
- **Headers**: Optional custom headers (no moduleId required)
- **Response**: Array of `ModuleModel` objects

**Additional Legacy Calls** (if `loadLandingData=true`):
- **Landing Page Endpoint**: `/api/v1/landing-page`
- **Method**: `GET`
- **Headers**: Standard headers (no moduleId required)
- **Response**: `LandingModel` JSON

### 1.2 Local Cache Storage (SharedPreferences & Hive)

#### **SharedPreferences Keys Stored During Splash**:

| Key | Type | Source | Description |
|-----|------|--------|-------------|
| `AppConstants.moduleId` | `String` (JSON) | `splash_repository.dart:215` | Current selected module (ModuleModel serialized) |
| `AppConstants.cacheModuleId` | `String` (JSON) | `splash_repository.dart:225` | Cached module for fallback |
| `AppConstants.theme` | `bool` | `splash_repository.dart:86` | Dark/light theme preference |
| `AppConstants.countryCode` | `String` | `splash_repository.dart:89` | User's country code |
| `AppConstants.languageCode` | `String` | `splash_repository.dart:93` | User's language code (e.g., "ar", "en") |
| `AppConstants.cartList` | `List<String>` | `splash_repository.dart:97` | Cart items list |
| `AppConstants.searchHistory` | `List<String>` | `splash_repository.dart:100` | Search history |
| `AppConstants.notification` | `bool` | `splash_repository.dart:103` | Notification enabled flag |
| `AppConstants.intro` | `bool` | `splash_repository.dart:106` | Intro/onboarding shown flag |
| `AppConstants.notificationCount` | `int` | `splash_repository.dart:109` | Unread notification count |
| `AppConstants.suggestedLocation` | `bool` | `splash_repository.dart:112` | Suggested location shown flag |
| `AppConstants.referBottomSheet` | `bool` | `splash_repository.dart:115` | Refer bottom sheet shown flag |
| `AppConstants.userAddress` | `String` (JSON) | `address_helper.dart` | User's saved address (AddressModel) |
| `AppConstants.token` | `String` | `auth_helper.dart` | Authentication token |
| `app_install_timestamp` | `int` | `splash_repository.dart:79` | First install timestamp |

#### **Hive Cache Boxes**:

| Box Name | Purpose | Location |
|----------|---------|----------|
| `app_config` | App-init data (config, modules, zones) | `hive_home_cache_service.dart` |
| `promotional_content` | Module 3 banners & offers | `hive_home_cache_service.dart` |
| `home_unified_{moduleId}` | Module-specific home data | `hive_home_cache_service.dart` |

#### **LocalClient Cache** (Legacy):
- Caches responses from:
  - `/api/v1/config` → `AppConstants.configUri`
  - `/api/v1/module` → `AppConstants.moduleUri`
  - `/api/v1/landing-page` → `AppConstants.landingPageUri`

---

## 2. Landing Page (Multi-Module Home) Audit

### 2.1 Screen Structure

**File**: `lib/features/home/screens/multi_module/multi_module_home_screen.dart`

The landing page displays **3 sections in order**:

1. **Banners Section** (Featured banners from Module 3)
2. **Modules Section** (Grid of available modules)
3. **Offers Section** (Active offers from Module 3)

### 2.2 API Calls for Landing Page Sections

#### **Section 1: Banners**

**Primary Endpoint (v2 - Preferred)**:
- **URL**: `/api/v2/home-unified`
- **Method**: `GET`
- **Location**: `multi_module_home_screen.dart:508`
- **Query Parameters**:
  - `zone_ids`: JSON array of zone IDs (from user address)
  - `module_id`: `3` (hardcoded - eCommerce module)
  - `latitude`: User's latitude
  - `longitude`: User's longitude
  - `language_code`: User's language (e.g., "ar")
  - `limit`: `10`
  - `offset`: `1`
  - `type`: `"all"`
  - `featured`: `1` (request featured banners only)
- **Headers**: 
  - `module-id`: `3` (temporarily set before call)
  - `zone-id`: JSON array of zone IDs
  - `X-localization`: Language code
  - `Authorization`: Bearer token (if logged in)
- **Response**: `HomeUnifiedModel` containing:
  - `banners`: Array of banner objects
  - `campaigns`: Array of campaign objects (also displayed as banners)

**Fallback Endpoint (v1)**:
- **URL**: `/api/v1/banners`
- **Method**: `GET`
- **Location**: `banner_controller.dart:77`
- **Query Parameters**: None (uses headers for filtering)
- **Headers**:
  - `module-id`: `3` (hardcoded for promotional content)
  - `zone-id`: JSON array of zone IDs
  - `X-localization`: Language code
- **Response**: `BannerModel` containing:
  - `campaigns`: Array of campaign objects
  - `banners`: Array of banner objects

**⚠️ CRITICAL**: Banners are **ALWAYS loaded with moduleId=3** (eCommerce) for the multi-module landing page, regardless of user's selected module. This is intentional design.

#### **Section 2: Modules**

**Data Source**: Already loaded during splash screen
- **No additional API call** on landing page
- **Source**: `SplashController.moduleList` (populated from `/api/v1/module` or `/api/v1/app-init`)
- **Location**: `multi_module_home_screen.dart:629`

**Module Model Structure**:
```json
{
  "id": 1,
  "module_name": "Food",
  "module_type": "food",
  "thumbnail_full_url": "https://...",
  "icon_full_url": "https://...",
  "theme_id": 1,
  "description": "...",
  "stores_count": 150,
  "created_at": "...",
  "updated_at": "...",
  "zones": [...]
}
```

#### **Section 3: Offers**

**Endpoint**:
- **URL**: `/api/v1/offers/active`
- **Method**: `GET`
- **Location**: `offers_controller.dart:202`
- **Query Parameters**: None (uses headers for filtering)
- **Headers**:
  - `module-id`: `3` (hardcoded for promotional content)
  - `zone-id`: JSON array of zone IDs
  - `X-localization`: Language code
  - `Authorization`: Bearer token (if logged in)
- **Response**: `OffersModel` containing:
  ```json
  {
    "success": true,
    "message": "...",
    "data": [
      {
        "id": 1,
        "title": "Offer Name",
        "image": "...",
        "description": "...",
        "start_date": "...",
        "end_date": "...",
        ...
      }
    ]
  }
  ```

**⚠️ CRITICAL**: Offers are **ALWAYS loaded with moduleId=3** (eCommerce) for the multi-module landing page, regardless of user's selected module. This is intentional design.

### 2.3 Headers Sent During Landing Page API Calls

**Standard Headers** (injected via `ApiClient.updateHeader()`):
- `Content-Type`: `application/json; charset=UTF-8`
- `zone-id`: JSON-encoded array of zone IDs (e.g., `[2,4,3,5]`)
- `X-localization`: Language code (e.g., `"ar"`, `"en"`)
- `latitude`: JSON-encoded latitude string
- `longitude`: JSON-encoded longitude string
- `Authorization`: `Bearer {token}` (if user is logged in)
- `module-id`: **Module ID (if module is selected)**

**⚠️ IMPORTANT**: 
- For **Banners** and **Offers** on landing page: `module-id` is **hardcoded to `3`** (eCommerce)
- For **Modules** endpoint: `module-id` is **NOT sent** (not required)
- For **Config/App-Init** endpoints: `module-id` is **NOT sent** (not required)

---

## 3. Redirection Logic (Module Selection)

### 3.1 Global State Variables Updated

When a user selects a module from the landing page:

**1. SplashController State**:
- `_module`: Updated to selected `ModuleModel`
- `_moduleIndex`: Updated to selected index
- `_selectedModuleIndex`: Updated to selected index
- **Location**: `splash_controller.dart:707` (`setModule()` method)

**2. SharedPreferences**:
- `AppConstants.moduleId`: Updated with selected module JSON
- `AppConstants.cacheModuleId`: Updated with selected module JSON
- **Location**: `splash_repository.dart:215, 225`

**3. ApiClient Headers**:
- `module-id`: Updated to selected module's ID
- **Location**: `splash_controller.dart:727` (`apiClient.updateHeader()`)
- **Also updated in**: `splash_repository.dart:205` (legacy path)

**4. Module Config**:
- `_configModel.moduleConfig.module`: Updated from `_data['module_config'][moduleType]`
- **Location**: `splash_controller.dart:764`

### 3.2 ModuleId Header Injection Flow

**Centralized Header Update**:
- **Method**: `ApiClient.updateHeader()`
- **Location**: `lib/api/api_client.dart:229-297`
- **Called from**:
  1. `SplashController.setModule()` → `splash_controller.dart:727`
  2. `SplashRepository.setModule()` → `splash_repository.dart:205`
  3. `MultiModuleHomeScreen._loadPromotionalContentSilently()` → `multi_module_home_screen.dart:282`

**Header Injection Logic**:
```dart
apiClient.updateHeader(
  apiClient.token,                    // Auth token
  addressModel?.zoneIds,              // Zone IDs array
  addressModel?.areaIds,              // Area IDs array
  sharedPreferences.getString(AppConstants.languageCode), // Language
  module.id,                          // ✅ Module ID injected here
  addressModel?.latitude,             // Latitude
  addressModel?.longitude,            // Longitude
);
```

**Subsequent API Calls**:
- All API calls via `ApiClient.getData()` automatically include `module-id` in headers
- **Location**: `api_client.dart:348` (merges `_mainHeaders` with custom headers)
- **Verification**: `api_client.dart:358` (logs moduleId presence for debugging)

**⚠️ CRITICAL**: After `setModule()` is called, **ALL subsequent API calls** will include the new `module-id` in headers, including:
- Home screen data (`/api/v2/home-unified`)
- Store lists
- Item lists
- Category lists
- Cart operations
- etc.

---

## 4. Constraints & Issues

### 4.1 Hardcoded Logic

#### **Issue 1: Module 3 (eCommerce) Hardcoded for Promotional Content**
- **Location**: `multi_module_home_screen.dart:36`
- **Constant**: `kPromotionalModuleId = 3`
- **Impact**: 
  - Banners on landing page always use moduleId=3
  - Offers on landing page always use moduleId=3
  - Cannot be changed without code modification
- **Rationale**: Backend designates Module 3 as "featured promotional content" for multi-module screen

#### **Issue 2: Taxi Module Filtered on Web**
- **Location**: `splash_controller.dart:868`
- **Logic**: Taxi module (`AppConstants.taxi`) is excluded from module list on web platform
- **Impact**: Web users cannot see/select taxi module

#### **Issue 3: Featured Banners Only on Landing Page**
- **Location**: `multi_module_home_screen.dart:521`
- **Logic**: Landing page requests `featured=1` for banners
- **Impact**: Only featured banners are shown, not all banners

### 4.2 API Call Failures & Fallbacks

#### **App-Init Endpoint Fallback**:
- **On 304/500/null**: Falls back to Hive `app_config` box
- **On error**: Falls back to legacy `/api/v1/config` endpoint
- **Location**: `splash_controller.dart:428-526`

#### **Banner Endpoint Fallback**:
- **v2 failure**: Falls back to v1 `/api/v1/banners`
- **Location**: `multi_module_home_screen.dart:548`

#### **Offers Endpoint**:
- **Timeout**: 10 seconds (reduced from 30s)
- **On timeout**: Returns empty offers model
- **Location**: `offers_controller.dart:202`

### 4.3 Mock Data / Placeholder Data

**No mock data detected** - all endpoints call real APIs. However:
- **Cache-first strategy**: App loads from cache first, then refreshes from API
- **Empty state handling**: Controllers initialize with empty arrays to prevent null errors

### 4.4 Missing Headers / Optional Headers

**Endpoints that DO NOT require moduleId**:
- `/api/v1/config` - Config data (no moduleId)
- `/api/v1/app-init` - Bootstrap data (no moduleId)
- `/api/v1/module` - Module list (no moduleId)
- `/api/v1/landing-page` - Landing page data (no moduleId)

**Endpoints that REQUIRE moduleId**:
- `/api/v1/banners` - Banners (moduleId in headers)
- `/api/v1/offers/active` - Offers (moduleId in headers)
- `/api/v2/home-unified` - Unified home data (moduleId in query params AND headers)

---

## 5. Endpoint Summary for Laravel Team

### 5.1 Required Endpoints

| Endpoint | Method | Headers Required | Query Params | Response Model |
|----------|--------|------------------|--------------|----------------|
| `/api/v1/config` | GET | None (standard headers only) | None | `ConfigModel` |
| `/api/v1/app-init` | GET | None (standard headers only) | None | `AppInitModel` |
| `/api/v1/module` | GET | None (standard headers only) | None | `Array<ModuleModel>` |
| `/api/v1/landing-page` | GET | None (standard headers only) | None | `LandingModel` |
| `/api/v1/banners` | GET | `module-id`, `zone-id`, `X-localization` | None | `BannerModel` |
| `/api/v1/offers/active` | GET | `module-id`, `zone-id`, `X-localization` | None | `OffersModel` |
| `/api/v2/home-unified` | GET | `module-id`, `zone-id`, `X-localization` | `zone_ids`, `module_id`, `latitude`, `longitude`, `language_code`, `limit`, `offset`, `type`, `featured` | `HomeUnifiedModel` |

### 5.2 JSON Keys Required

#### **ConfigModel** (`/api/v1/config`):
```json
{
  "module": {...},
  "module_config": {
    "food": {...},
    "grocery": {...},
    "ecommerce": {...}
  },
  "business_settings": {...},
  ...
}
```

#### **AppInitModel** (`/api/v1/app-init`):
```json
{
  "config": {...},  // Same as ConfigModel
  "modules": [...],  // Array of ModuleModel
  "zones": [...],    // Array of ZoneModel
  "user_zone_id": 1,
  "business_settings": {...}
}
```

#### **ModuleModel** (`/api/v1/module`):
```json
[
  {
    "id": 1,
    "module_name": "Food",
    "module_type": "food",
    "thumbnail_full_url": "https://...",
    "icon_full_url": "https://...",
    "theme_id": 1,
    "description": "...",
    "stores_count": 150,
    "created_at": "...",
    "updated_at": "...",
    "zones": [...]
  }
]
```

#### **BannerModel** (`/api/v1/banners`):
```json
{
  "campaigns": [
    {
      "id": 1,
      "image_full_url": "https://...",
      "title": "...",
      ...
    }
  ],
  "banners": [
    {
      "id": 1,
      "image_full_url": "https://...",
      "type": "default",
      "link": "...",
      "item": {...},  // If banner links to item
      "store": {...}, // If banner links to store
      ...
    }
  ]
}
```

#### **OffersModel** (`/api/v1/offers/active`):
```json
{
  "success": true,
  "message": "...",
  "data": [
    {
      "id": 1,
      "title": "Offer Name",
      "image": "https://...",
      "description": "...",
      "start_date": "...",
      "end_date": "...",
      ...
    }
  ]
}
```

### 5.3 Header Requirements

**Standard Headers** (sent with all requests):
- `Content-Type`: `application/json; charset=UTF-8`
- `zone-id`: JSON-encoded array (e.g., `"[2,4,3,5]"`)
- `X-localization`: Language code (e.g., `"ar"`, `"en"`)
- `latitude`: JSON-encoded string (e.g., `"\"24.604301879077966\""`)
- `longitude`: JSON-encoded string (e.g., `"\"46.59593515098095\""`)
- `Authorization`: `Bearer {token}` (if user logged in)

**Module-Specific Headers** (sent with data requests):
- `module-id`: Module ID as string (e.g., `"3"`)

**⚠️ CRITICAL FOR LARAVEL TEAM**:
1. **Config/App-Init/Module endpoints**: Do NOT require `module-id` header
2. **Banners/Offers endpoints**: REQUIRE `module-id` header
3. **Module 3 (eCommerce)**: Used as "promotional content" for multi-module landing page
4. **Zone IDs**: Always sent as JSON-encoded array, even for single zone
5. **Coordinates**: Always sent as JSON-encoded strings (double-encoded)

---

## 6. Recommendations

### 6.1 For Backend Team

1. **Ensure `/api/v1/app-init` returns consistent structure** with legacy `/api/v1/config` + `/api/v1/module` combined
2. **Support 304 Not Modified** for app-init endpoint (currently handled)
3. **Validate module-id header** on banners/offers endpoints (return 400 if missing)
4. **Document Module 3 as "promotional content"** for multi-module screen
5. **Ensure `/api/v2/home-unified` supports `featured=1` parameter** for featured banners

### 6.2 For Frontend Team

1. **Remove hardcoded Module 3** - make it configurable via backend
2. **Add error handling** for missing module-id in API responses
3. **Document module selection flow** for future developers
4. **Consider making promotional module configurable** via business settings

---

## 7. Testing Checklist

- [ ] Splash screen loads config/app-init successfully
- [ ] Modules list loads and displays correctly
- [ ] Landing page shows banners (Module 3)
- [ ] Landing page shows modules grid
- [ ] Landing page shows offers (Module 3)
- [ ] Module selection updates global state
- [ ] Module selection updates API headers
- [ ] Subsequent API calls include correct module-id
- [ ] Fallback to cache works when API fails
- [ ] 304 Not Modified handled correctly
- [ ] 500 errors fallback gracefully (no error dialogs)

---

**End of Report**

