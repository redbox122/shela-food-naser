# AI Coding Assistant Instructions for 6amMart

## Project Overview

**6amMart** is a multi-vendor Flutter e-commerce platform supporting Food Delivery, Grocery, Pharmacy, E-commerce, and Parcel services. Built with **Clean Architecture**, **GetX state management**, and **Dart/Flutter**.

### Critical Reality vs. Documented Rules

⚠️ **Known Discrepancies**:
- `.cursor/rules/flutter.mdc` specifies Bloc/Riverpod, but codebase uses **GetX exclusively** (4,861 matches)
- GetX is the actual and correct implementation - use it for all state management
- Ignore Bloc/Riverpod rules; they don't match the real architecture

---

## State Management: GetX Pattern

### Architecture Pattern

```
View Layer (GetBuilder/Obx) → GetX Controller → Repository Interface → Data Layer
     (Reactive UI rebuild)      (Business Logic)   (Abstraction)      (API/Cache)
```

### Key Components

**Controllers** extend `GetxController` and live in `features/{feature}/controllers/`:
- Use `Get.lazyPut()` for lazy initialization (preferred - reduces startup overhead)
- Use `Get.put()` only for critical global singletons (AuthController, CartController)
- Register all in `lib/helper/get_di.dart`

**State Management Approach**:
```dart
class ExampleController extends GetxController {
  // Observable state
  final RxBool isLoading = false.obs;
  final Rx<ModelType?> data = Rx<ModelType?>(null);
  
  Future<void> loadData() async {
    isLoading.value = true;
    data.value = await repository.fetch();
    isLoading.value = false;
  }
}

// In UI - GetBuilder for complex rebuilds
GetBuilder<ExampleController>(
  builder: (controller) => controller.isLoading ? Loader() : Content(),
)

// Or Obx for simple reactive variables
Obx(() => Text(controller.data.value?.name ?? ''))
```

### Global Controllers (Singletons)

Located in `lib/helper/get_di.dart` and used across all features:
- **AuthController**: User authentication, guest mode, social login
- **CartController**: Multi-store cart across modules  
- **SplashController**: App initialization, module selection
- **ThemeController**: Dark/light mode, UI configuration
- **LanguageController**: Internationalization state

---

## Architecture & Layers

### Clean Architecture Structure

```
lib/
├── features/           # Feature-first organization
│   ├── auth/          # Each feature has 3 layers:
│   │   ├── data/      #   - Data (repositories, datasources, models)
│   │   ├── domain/    #   - Domain (entities, interfaces, services)
│   │   └── controllers/ #   - Presentation (controllers, screens, widgets)
│   └── home/
├── core/              # Shared foundational code
│   ├── api/           # Network utilities, interceptors
│   ├── cache/         # Hive cache, migrations
│   ├── error/         # Error handling, failures
│   ├── logger/        # App logging system
│   └── navigation/    # Routing logic
├── common/            # Shared UI components & services
│   ├── controllers/   # Global state (theme, locale)
│   ├── models/        # Shared DTOs, error models
│   ├── widgets/       # Reusable UI components
│   └── services/      # Global services (cache manager, token storage)
├── helper/            # Utility helpers
│   ├── get_di.dart   # ⭐ ALL dependency injection setup
│   └── route_helper.dart # ⭐ ALL route definitions
├── api/              # ⭐ API client (Dio, secure HTTP)
├── main.dart         # App entry point
└── theme/            # App theming (light/dark)
```

### Dependency Rule

**Dependencies flow inward only** - Data layer → Domain layer → Presentation layer. Never skip layers or reference data models in UI directly.

---

## Dependency Injection & Routing

### Registration Pattern (`lib/helper/get_di.dart`)

All controllers registered in single centralized file with strict pattern:
```dart
// Global singletons (immediate init)
Get.put(() => AuthController(...), permanent: true);

// Feature controllers (lazy init)
Get.lazyPut(() => FeatureController(...));

// Repositories & Services
Get.put(() => FeatureRepository(...));
```

### Routes (`lib/helper/route_helper.dart`)

All 1300+ routes centralized in single file:
```dart
static const String FEATURE_ROUTE = '/feature-route';
static const String FEATURE_DETAIL_ROUTE = '/feature-detail';

// Navigate
Get.toNamed(RouteHelper.FEATURE_ROUTE);
Get.toNamed(RouteHelper.FEATURE_DETAIL_ROUTE, arguments: {'id': 123});
```

---

## Error Handling Strategy

### Unified Error Model

All API responses map to `AppErrorModel`:
```dart
class AppErrorModel {
  final int? code;
  final String message;
  final String type;  // 'network', 'validation', 'server', 'unknown'
  final dynamic originalError;
}
```

### API Error Mapping

[api/api_checker.dart] handles all HTTP error codes with `AppErrorModel.fromResponse()`:
- **Network errors**: No internet → Connection failed
- **401**: Unauthorized → Show login screen
- **422**: Validation errors → Extract field-level messages  
- **5xx**: Server errors → Friendly user message with logging

### Controller State Pattern (Proposed)

Standardize all controllers with `ControllerStateModel<T>`:
```dart
enum ControllerState { initial, loading, success, error, empty }

class MyController extends GetxController {
  ControllerStateModel<List<Item>> _state = ControllerStateModel.initial();
  
  Future<void> loadItems() async {
    _state = ControllerStateModel.loading();
    update();
    
    try {
      final items = await repository.getItems();
      _state = items.isNotEmpty 
        ? ControllerStateModel.success(items)
        : ControllerStateModel.empty();
    } catch(e) {
      _state = ControllerStateModel.error(ErrorHelper.mapError(e));
    }
    update();
  }
  
  bool get isLoading => _state.isLoading;
  bool get isError => _state.isError;
  List<Item>? get items => _state.data;
}
```

---

## API Integration

### API Client (`lib/api/api_client.dart`)

- **HTTP Library**: Dio + custom SecureHttpClient (HTTPS, cert pinning)
- **Token Management**: Secure storage (async) + SharedPreferences (legacy)
- **Caching**: ETag-based conditional requests for performance
- **Interceptors**: Auto-token refresh (401 → refresh → retry)
- **Base URL**: From `AppConstants` + environment config

### Secure HTTP Setup

```dart
// API calls use SecureHttpClient for cert pinning
final response = await _secureHttpClient.get(url);
```

### Response Mapping

Models in `features/{feature}/domain/models/` handle JSON serialization:
```dart
class ItemModel {
  final int id;
  final String name;
  
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
```

---

## Key Files Reference

### Must Read First
- [lib/main.dart](lib/main.dart) - App initialization, logging setup, Firebase, GetX config
- [lib/helper/get_di.dart](lib/helper/get_di.dart) - **All dependency registration** (800+ lines)
- [lib/helper/route_helper.dart](lib/helper/route_helper.dart) - **All 1300+ routes** (1388 lines)
- [lib/api/api_client.dart](lib/api/api_client.dart) - **API communication, security**

### Architecture References
- [lib/documentation/README.md](lib/documentation/README.md) - Overview & feature list
- [.cursor/rules/flutter.mdc](.cursor/rules/flutter.mdc) - Ignored (uses GetX, not Bloc)
- [.cursor/rules/dart.mdc](.cursor/rules/dart.mdc) - **Code style rules** (apply this)

### Critical Cross-Feature Components
- **AuthController** - User session, guest mode, login state
- **CartController** - Multi-store cart, checkout flow
- **SplashController** - Module selection, app config
- **ThemeController** - Light/dark mode, locale changes

### Common Patterns
- Features: See `lib/features/auth/`, `lib/features/home/` for examples
- Models: `lib/common/models/` for shared DTOs
- Widgets: `lib/common/widgets/` for reusable UI
- Services: `lib/common/services/` for platform integrations

---

## Developer Workflows

### Adding a New Feature

1. **Create structure**: `lib/features/my_feature/{data,domain,controllers,screens}`
2. **Define routes**: Add to `lib/helper/route_helper.dart`
3. **Dependency injection**: Register in `lib/helper/get_di.dart`
4. **Controller pattern**: Extend `GetxController`, use `GetBuilder`/`Obx` in UI
5. **Error handling**: Map API errors to `AppErrorModel` in repository

### Modifying Existing Routes

- **Never hardcode routes** - always use `RouteHelper.ROUTE_NAME`
- **Route parameters** pass via `arguments: {key: value}`
- **DeepLink support**: Check route definition for web URL patterns
- **Route guards**: Check auth status in controller before navigate

### API Call Flow

1. Controller calls `repository.method()`
2. Repository calls `apiClient.get/post(...)`
3. `ApiClient` handles auth headers, timeouts (30s), cert pinning
4. Response mapped to Model via `fromJson()`
5. Error caught and mapped to `AppErrorModel`
6. Controller updates state and calls `update()` to rebuild UI

---

## Code Style & Conventions

### Dart/Flutter Standards

- **PascalCase**: Classes, enums
- **camelCase**: Variables, methods, parameters
- **snake_case**: Files, directories
- **UPPERCASE**: Constants/environment variables
- **Verbs for methods**: `fetchData()`, `validateEmail()`, `saveUser()`
- **Booleans**: `isLoading`, `hasError`, `canDelete`

### File Headers & Documentation

Every file requires header comment (per `.cursor/rules/general.mdc`):
```dart
/// Purpose: Handles user authentication flows
/// Role in project: Manages login/signup/social auth state
///
import 'package:...';

class AuthController extends GetxController {
  /// Authenticates user with email/password
  /// Returns: true if successful
  Future<bool> loginWithEmail(String email, String password) async {
    // Implementation with inline comments for non-obvious logic
  }
}
```

### Import Organization

```dart
import 'dart:async';                           // Dart imports first
import 'package:flutter/material.dart';        // Flutter imports
import 'package:get/get.dart';                 // Third-party imports
import 'package:sixam_mart/...';               // Project imports organized by layer
```

---

## Performance & Memory Management

### Lazy Initialization Strategy

```dart
// ✅ GOOD: Lazy init (controller created on first Get.find())
Get.lazyPut(() => StoreController(...));

// ⚠️ CAREFUL: Eager init (controller created immediately)
Get.put(() => AuthController(...), permanent: true);
```

**Impact**: Lazy controllers save ~30MB RAM at startup by deferring instantiation until needed.

### Caching Strategy

- **ETag caching**: API client caches responses with conditional requests
- **Hive local cache**: Persistent data via `HiveHomeCacheService`
- **In-memory cache**: Controllers hold data in memory during session
- **Cache invalidation**: Manually trigger reload or time-based expiry

---

## Common Pitfalls to Avoid

1. **Direct API calls in UI** - Always use repository pattern (inject in controller)
2. **Hardcoded routes** - Use `RouteHelper.ROUTE_NAME` constants
3. **setState() calls** - Use GetX `update()` or `.obs` reactivity instead
4. **Skipping Clean Architecture layers** - Never access data models directly in UI
5. **Forgetting error handling** - All API calls must handle `AppErrorModel`
6. **Missing dependency injection** - Register all controllers in `get_di.dart`
7. **Uncontrolled controller growth** - Keep controllers focused; split if >400 lines
8. **Mixing state patterns** - Use either GetBuilder OR Obx per widget, not both

---

## Testing & Debugging

### Logging

```dart
import 'package:sixam_mart/common/utils/app_logger.dart';

appLogger.info('User logged in: ${user.name}');
appLogger.warning('Low disk space');
appLogger.error('API failed', error: e);
```

### Debug Output

- **Verbose logs**: Controlled by `AppConstants.enableVerboseLogs`
- **API trace**: See `lib/api/api_client.dart` for request/response logging
- **EGL filtering**: Main.dart filters noisy EGL_emulation logs automatically

### Hot Reload Considerations

- Controllers persist across hot reload
- Tokens reloaded from secure storage on app restart
- Be aware of stale state if manually testing auth flows

---

## Important Notes

- **16+ MB APK size** - Multi-vendor complexity; watch for bloat
- **~45+ features** - Extensive coverage; check existing patterns before new code
- **Multi-module support** - Some features work across Food/Grocery/Pharmacy modes
- **Internationalization** - Use `'key'.tr` for all UI strings (LanguageController)
- **Platform-specific code** - Android/iOS/Web handled via conditional imports and `GetPlatform.isWeb`

---

**Last Updated**: January 28, 2026  
**Architecture**: Clean Architecture + GetX (Feature-First)  
**State Management**: GetX Controllers (4,861+ matches)  
**HTTP Client**: Dio with Secure HTTP Client (Cert Pinning)
