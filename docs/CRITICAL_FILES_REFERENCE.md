# 📂 الملفات الحساسة - مرجع سريع

## 🎯 الهدف

هذا الملف يحتوي على **الملفات الحساسة فقط** التي تحتاجها لفهم:
- من أين يتم استدعاء API
- كيف يتم إعداد Base URL
- كيف يتم إدارة State
- كيف يتم عرض البيانات

---

## ① ملفات الإعداد الأساسية

### 1.1 Base URL Configuration

**📁 `lib/util/environment_config.dart`**

```dart
enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment currentEnvironment = Environment.production;
  
  static const Map<Environment, Map<String, String>> _configs = {
    Environment.production: {
      'baseUrl': 'https://dev.shelafood.com',  // ✅ الحالي
    },
  };
  
  static String get baseUrl => _configs[currentEnvironment]!['baseUrl']!;
}
```

**📁 `lib/util/app_constants.dart`**

```dart
class AppConstants {
  // ✅ Base URL
  static String get baseUrl => EnvironmentConfig.baseUrl;
  
  // ✅ API Endpoints
  static const String categoryUri = '/api/v1/categories';
  static const String storeItemUri = '/api/v1/items/latest';
  static const String storeUri = '/api/v1/stores';
  static const String homeUnifiedUri = '/api/v2/home-unified';
}
```

---

### 1.2 API Client

**📁 `lib/api/api_client.dart`**

```dart
class ApiClient extends GetxService {
  final String appBaseUrl;  // ✅ من AppConstants.baseUrl
  final SharedPreferences sharedPreferences;
  
  String? token;
  late Map<String, String> _mainHeaders;
  late final SecureHttpClient _secureHttpClient;  // ✅ Dio
  
  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    _initializeSecureServices();
    updateHeader(token, zoneIds, areaIds, languageCode, moduleID, latitude, longitude);
  }
  
  // ✅ الطريقة الأساسية
  Future<Response> getData(String uri, {Map<String, String>? headers}) async {
    // يستخدم Dio أو http
  }
  
  // ✅ Headers تلقائياً
  Map<String, String> getHeader() {
    return _mainHeaders;  // moduleId, zoneId, latitude, longitude, token
  }
}
```

**📁 `lib/helper/get_di.dart`** (Dependency Injection)

```dart
Get.lazyPut(() => ApiClient(
  appBaseUrl: AppConstants.baseUrl,  // ✅ https://dev.shelafood.com
  sharedPreferences: Get.find()
));
```

---

## ② الصفحات الرئيسية

### 2.1 الصفحة الرئيسية (Home Screen)

**📁 `lib/features/home/screens/home_screen.dart`**

```dart
class HomeScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        return GetBuilder<HomeController>(
          builder: (homeController) {
            // ✅ عرض البيانات
            return CustomScrollView(
              slivers: [
                // Categories
                GetBuilder<CategoryController>(
                  builder: (categoryController) {
                    return CategoryView(
                      categoryList: categoryController.categoryList,
                    );
                  }
                ),
                // Stores
                GetBuilder<StoreController>(
                  builder: (storeController) {
                    return PopularStoreView(
                      storeList: storeController.popularStoreList,
                    );
                  }
                ),
              ],
            );
          }
        );
      }
    );
  }
}
```

**Controllers المستخدمة:**
- `HomeController` - إدارة بيانات Home
- `CategoryController` - إدارة Categories
- `StoreController` - إدارة Stores
- `BannerController` - إدارة Banners
- `SplashController` - إدارة Config و Module

**API Calls:**
- `/api/v2/home-unified` - جميع بيانات Home في call واحد
- `/api/v1/categories` - Categories
- `/api/v1/stores/popular` - Popular Stores
- `/api/v1/banners` - Banners

---

### 2.2 صفحة قائمة المتاجر (Store List Screen)

**📁 `lib/features/store/screens/all_store_screen.dart`**

```dart
class AllStoreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              // ✅ Refresh البيانات
              await storeController.getPopularStoreList(true, type, false);
            },
            child: ItemsView(
              stores: storeController.popularStoreList,  // ✅ البيانات
            ),
          ),
        );
      }
    );
  }
}
```

**Controller:** `StoreController`

**API Calls:**
- `/api/v1/stores/popular` - Popular Stores
- `/api/v1/stores/latest` - Latest Stores
- `/api/v1/stores/featured` - Featured Stores

**Repository:** `lib/features/store/domain/repositories/store_repository.dart`

```dart
class StoreRepository implements StoreRepositoryInterface {
  final ApiClient apiClient;
  
  Future<StoreModel?> getPopularStoreList(...) async {
    final headers = apiClient.getHeader();
    final response = await apiClient.getData(
      '${AppConstants.storeUri}/popular?store_type=$type&offset=$offset&limit=$limit',
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return StoreModel.fromJson(response.body);
    }
    return null;
  }
}
```

---

### 2.3 صفحة تفاصيل المنتج (Item Details Screen)

**📁 `lib/features/item/screens/item_details_screen.dart`**

```dart
class ItemDetailsScreen extends StatefulWidget {
  final Item? item;
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        return GetBuilder<ItemController>(
          builder: (itemController) {
            return Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ItemImageViewWidget(
                      item: itemController.item,  // ✅ البيانات
                    ),
                    ItemTitleViewWidget(
                      item: itemController.item,
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}
```

**Controllers المستخدمة:**
- `ItemController` - إدارة بيانات Item
- `CartController` - إدارة Cart

**API Calls:**
- `/api/v1/items/details/{id}` - تفاصيل المنتج
- `/api/v1/items/similar/{categoryId}` - منتجات مشابهة

**Repository:** `lib/features/item/domain/repositories/item_repository.dart`

```dart
class ItemRepository implements ItemRepositoryInterface {
  final ApiClient apiClient;
  
  Future<ItemModel?> getProductDetails(int itemId) async {
    final response = await apiClient.getData(
      '${AppConstants.searchItemUri}$itemId',
      headers: apiClient.getHeader(),
    );
    
    if (response.statusCode == 200) {
      return ItemModel.fromJson(response.body);
    }
    return null;
  }
}
```

---

## ③ Controllers

### 3.1 CategoryController

**📁 `lib/features/category/controllers/category_controller.dart`**

```dart
class CategoryController extends GetxController {
  List<CategoryModel>? categoryList;
  bool isLoading = false;
  
  Future<void> getCategoryList(bool reload) async {
    isLoading = true;
    update();
    
    categoryList = await categoryRepository.getList(
      categoryList: true,
      allCategory: true,
    );
    
    isLoading = false;
    update();  // ✅ تحديث UI
  }
}
```

**Repository:** `lib/features/category/domain/reposotories/category_repository.dart`

```dart
class CategoryRepository implements CategoryRepositoryInterface {
  final ApiClient apiClient;
  
  Future<List<CategoryModel>?> getList(...) async {
    final response = await apiClient.getData(
      AppConstants.categoryUri,  // ✅ /api/v1/categories
      headers: apiClient.getHeader(),
    );
    
    if (response.statusCode == 200) {
      return CategoryModel.fromJson(response.body).categories;
    }
    return null;
  }
}
```

---

### 3.2 StoreController

**📁 `lib/features/store/controllers/store_controller.dart`**

```dart
class StoreController extends GetxController {
  List<Store>? popularStoreList;
  List<Store>? latestStoreList;
  bool isLoading = false;
  
  Future<void> getPopularStoreList(bool reload, String type, bool notify) async {
    isLoading = true;
    update();
    
    popularStoreList = await storeRepository.getPopularStoreList(
      reload,
      type,
      notify,
    );
    
    isLoading = false;
    update();  // ✅ تحديث UI
  }
}
```

**Repository:** `lib/features/store/domain/repositories/store_repository.dart`

---

### 3.3 ItemController

**📁 `lib/features/item/controllers/item_controller.dart`**

```dart
class ItemController extends GetxController {
  Item? item;
  bool isLoading = false;
  
  Future<void> getProductDetails(Item item) async {
    isLoading = true;
    update();
    
    final result = await itemRepository.getProductDetails(item.id!);
    if (result != null) {
      this.item = result.items?.first;
    }
    
    isLoading = false;
    update();  // ✅ تحديث UI
  }
}
```

**Repository:** `lib/features/item/domain/repositories/item_repository.dart`

---

## ④ Routes

**📁 `lib/helper/route_helper.dart`**

```dart
class RouteHelper {
  static const String main = '/main';
  static const String store = '/store';
  static const String itemDetails = '/item-details';
  
  static List<GetPage> routes = [
    GetPage(
      name: main,
      page: () => DashboardScreen(pageIndex: 0),
    ),
    GetPage(
      name: store,
      page: () => StoreScreen(
        store: Store(id: int.parse(Get.parameters['id']!)),
      ),
    ),
    GetPage(
      name: itemDetails,
      page: () => ItemDetailsScreen(
        item: Item(id: int.parse(Get.parameters['id']!)),
      ),
    ),
  ];
}
```

---

## ⑤ Error Handling Strategy موحدة

### 5.1 المشكلة الحالية

**❌ الوضع الحالي:**
- Error Handling غير موحد
- بعض Controllers: `error = silent fail`
- UI لا يعرف الفرق بين: `empty` / `error` / `no internet`

**✅ الحل المطلوب:**
- ErrorModel موحد (`AppErrorModel`)
- ControllerStateModel موحد (`ControllerStateModel`)
- UI يعرف جميع الحالات

### 5.2 ErrorModel الموحد

**الملف المقترح:** `lib/common/models/app_error_model.dart`

```dart
enum AppErrorType {
  network,      // No Internet
  server,      // 500, 502, 503
  client,       // 400, 401, 403, 404
  timeout,      // Request Timeout
  parsing,      // JSON Parsing Error
  unknown,      // Unknown Error
  empty,        // Empty Data (not an error, but a state)
}

class AppErrorModel {
  final AppErrorType type;
  final String message;
  final String? code;
  final int? statusCode;
  
  bool get isNetworkError => type == AppErrorType.network;
  bool get isEmpty => type == AppErrorType.empty;
  String get userMessage { /* User-friendly message */ }
}
```

### 5.3 ControllerStateModel الموحد

**الملف المقترح:** `lib/common/models/controller_state.dart`

```dart
enum ControllerState {
  initial,    // لم يتم تحميل البيانات بعد
  loading,    // جاري التحميل
  success,    // نجح التحميل
  error,      // حدث خطأ
  empty,      // البيانات فارغة (ليس خطأ)
}

class ControllerStateModel<T> {
  final ControllerState state;
  final T? data;
  final AppErrorModel? error;
  
  bool get isLoading => state == ControllerState.loading;
  bool get isError => state == ControllerState.error;
  bool get isEmpty => state == ControllerState.empty;
  bool get hasData => state == ControllerState.success && data != null;
}
```

### 5.4 Controller Pattern موحد

```dart
class CategoryController extends GetxController {
  ControllerStateModel<List<CategoryModel>> _state = 
      ControllerStateModel.initial();
  
  Future<void> getCategoryList(bool reload) async {
    try {
      _state = ControllerStateModel.loading();
      update();
      
      final result = await categoryRepository.getList(...);
      
      if (result != null && result.isNotEmpty) {
        _state = ControllerStateModel.success(result);
      } else {
        _state = ControllerStateModel.empty();
      }
      
      update();
    } catch (e) {
      _state = ControllerStateModel.error(_mapExceptionToError(e));
      update();
    }
  }
}
```

**📖 للتفاصيل الكاملة:** راجع `DATA_FLOW_DETAILED.md` - القسم ⑤

---

## ⑥ State Management Pattern

### 6.1 GetBuilder Pattern

```dart
// ✅ في Screen
GetBuilder<CategoryController>(
  builder: (controller) {
    if (controller.isLoading) {
      return CircularProgressIndicator();
    }
    return ListView(
      children: controller.categoryList?.map((category) {
        return CategoryWidget(category: category);
      }).toList() ?? [],
    );
  }
)

// ✅ في Controller
class CategoryController extends GetxController {
  List<CategoryModel>? categoryList;
  bool isLoading = false;
  
  Future<void> loadData() async {
    isLoading = true;
    update();  // ✅ تحديث UI
    
    categoryList = await repository.getList();
    
    isLoading = false;
    update();  // ✅ تحديث UI
  }
}
```

---

## ⑥ ملخص الملفات الحساسة

### 6.1 الإعدادات

| الملف | الوظيفة |
|------|---------|
| `lib/util/environment_config.dart` | ✅ Base URL Configuration |
| `lib/util/app_constants.dart` | ✅ API Endpoints |
| `lib/api/api_client.dart` | ✅ HTTP Client |
| `lib/helper/get_di.dart` | ✅ Dependency Injection |

### 6.2 الصفحات

| الملف | Controller | API Endpoint |
|------|-----------|-------------|
| `lib/features/home/screens/home_screen.dart` | `HomeController` | `/api/v2/home-unified` |
| `lib/features/store/screens/all_store_screen.dart` | `StoreController` | `/api/v1/stores/popular` |
| `lib/features/item/screens/item_details_screen.dart` | `ItemController` | `/api/v1/items/details/{id}` |

### 6.3 Controllers

| Controller | Repository | Model |
|-----------|-----------|-------|
| `CategoryController` | `CategoryRepository` | `CategoryModel` |
| `StoreController` | `StoreRepository` | `StoreModel` |
| `ItemController` | `ItemRepository` | `ItemModel` |

---

## 🎯 الخلاصة

1. **Base URL**: `https://dev.shelafood.com` (من `EnvironmentConfig`)
2. **API Client**: `ApiClient` في `lib/api/api_client.dart`
3. **State Management**: `GetBuilder` مع `update()`
4. **الصفحات**: `HomeScreen`, `AllStoreScreen`, `ItemDetailsScreen`
5. **Controllers**: `CategoryController`, `StoreController`, `ItemController`

---

**تم إنشاء هذا الملف بواسطة AI Assistant**  
**آخر تحديث:** 2025-01-27

