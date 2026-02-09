# 🔄 تدفق البيانات التفصيلي - Flutter ↔ API ↔ Laravel

## 📍 نظرة عامة

هذا الملف يوضح **تدفق البيانات خطوة بخطوة** من لحظة فتح الصفحة حتى عرض البيانات في UI.

---

## ① مثال كامل: عرض Categories في Home Screen

### الخطوة 1: فتح Home Screen

**الملف:** `lib/features/home/screens/home_screen.dart`

```dart
class HomeScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // ✅ تحميل البيانات عند فتح الصفحة
    HomeScreen.loadData(context, false);
  }
}
```

---

### الخطوة 2: استدعاء Controller

**الملف:** `lib/features/home/screens/home_screen.dart`

```dart
static Future<void> loadData(context, bool reload) async {
  // ✅ استدعاء CategoryController
  if (Get.isRegistered<CategoryController>()) {
    await Get.find<CategoryController>().getCategoryList(reload);
  }
}
```

---

### الخطوة 3: Controller يستدعي Repository

**الملف:** `lib/features/category/controllers/category_controller.dart`

```dart
class CategoryController extends GetxController {
  final CategoryRepositoryInterface categoryRepository;
  List<CategoryModel>? categoryList;
  bool isLoading = false;
  
  Future<void> getCategoryList(bool reload) async {
    isLoading = true;
    update();  // ✅ تحديث UI (عرض Loading)
    
    // ✅ استدعاء Repository
    categoryList = await categoryRepository.getList(
      categoryList: true,
      allCategory: true,
      source: DataSourceEnum.client,  // ✅ Cache أولاً
    );
    
    isLoading = false;
    update();  // ✅ تحديث UI (عرض البيانات)
  }
}
```

---

### الخطوة 4: Repository يستدعي ApiClient

**الملف:** `lib/features/category/domain/reposotories/category_repository.dart`

```dart
class CategoryRepository implements CategoryRepositoryInterface {
  final ApiClient apiClient;
  
  Future<List<CategoryModel>?> getList(...) async {
    // ✅ 1. محاولة Cache أولاً
    final cacheKey = 'categories_${allCategory ? 'all' : 'module'}';
    final cachedData = await LocalClient.get(DataSourceEnum.client, cacheKey);
    
    if (cachedData != null && !reload) {
      // ✅ استخدام Cache
      return CategoryModel.fromJson(jsonDecode(cachedData)).categories;
    }
    
    // ✅ 2. استدعاء API
    final headers = apiClient.getHeader();  // ✅ Headers تلقائياً
    final response = await apiClient.getData(
      AppConstants.categoryUri,  // ✅ /api/v1/categories
      headers: headers,
    );
    
    // ✅ 3. Parse Response
    if (response.statusCode == 200) {
      final categoryModel = CategoryModel.fromJson(response.body);
      
      // ✅ 4. حفظ في Cache
      await LocalClient.organize(
        DataSourceEnum.client,
        cacheKey,
        jsonEncode(response.body),
        headers,
      );
      
      return categoryModel.categories;
    }
    
    return null;
  }
}
```

---

### الخطوة 5: ApiClient يرسل Request إلى Laravel

**الملف:** `lib/api/api_client.dart`

```dart
class ApiClient extends GetxService {
  final String appBaseUrl = 'https://dev.shelafood.com';  // ✅ من EnvironmentConfig
  
  Future<Response> getData(String uri, {Map<String, String>? headers}) async {
    // ✅ بناء URL الكامل
    final fullUrl = '$appBaseUrl$uri';  // ✅ https://dev.shelafood.com/api/v1/categories
    
    // ✅ Headers
    final requestHeaders = headers ?? getHeader();
    // Headers تحتوي على:
    // - moduleId: '6'
    // - zoneId: '[2,4,3,5]'
    // - latitude: '24.7136'
    // - longitude: '46.6753'
    // - X-localization: 'ar'
    // - Authorization: 'Bearer {token}'
    
    // ✅ إرسال Request
    final response = await _secureHttpClient.get(
      fullUrl,
      headers: requestHeaders,
    );
    
    return response;
  }
  
  Map<String, String> getHeader() {
    return _mainHeaders;  // ✅ Headers محدثة تلقائياً
  }
}
```

---

### الخطوة 6: Laravel API يعالج Request

**Backend (Laravel):**

```php
// Route: /api/v1/categories
Route::get('/categories', [CategoryController::class, 'index']);

// Controller: CategoryController@index
class CategoryController extends Controller {
    public function index(Request $request) {
        // ✅ قراءة Headers
        $moduleId = $request->header('moduleId');
        $zoneId = json_decode($request->header('zoneId'));
        $latitude = $request->header('latitude');
        $longitude = $request->header('longitude');
        
        // ✅ Query Database
        $categories = Category::where('module_id', $moduleId)
            ->whereNull('store_id')
            ->orderBy('position')
            ->get();
        
        // ✅ إرجاع Response
        return response()->json([
            'categories' => $categories,
        ]);
    }
}
```

---

### الخطوة 7: ApiClient يستقبل Response

**الملف:** `lib/api/api_client.dart`

```dart
Future<Response> getData(String uri, {Map<String, String>? headers}) async {
  final response = await _secureHttpClient.get(fullUrl, headers: requestHeaders);
  
  // ✅ Response Status: 200
  // ✅ Response Body: {"categories": [...]}
  
  return response;
}
```

---

### الخطوة 8: Repository Parse Response

**الملف:** `lib/features/category/domain/reposotories/category_repository.dart`

```dart
if (response.statusCode == 200) {
  // ✅ Parse JSON
  final json = response.body as Map<String, dynamic>;
  final categoryModel = CategoryModel.fromJson(json);
  
  // ✅ إرجاع List<CategoryModel>
  return categoryModel.categories;
}
```

---

### الخطوة 9: Controller يحدث State

**الملف:** `lib/features/category/controllers/category_controller.dart`

```dart
categoryList = await categoryRepository.getList(...);

// ✅ categoryList الآن يحتوي على البيانات
// ✅ update() يحدث GetBuilder

isLoading = false;
update();  // ✅ تحديث UI
```

---

### الخطوة 10: UI يعرض البيانات

**الملف:** `lib/features/home/screens/home_screen.dart`

```dart
GetBuilder<CategoryController>(
  builder: (categoryController) {
    // ✅ GetBuilder rebuilds تلقائياً بعد update()
    
    if (categoryController.isLoading) {
      return CircularProgressIndicator();  // ✅ Loading
    }
    
    // ✅ عرض البيانات
    return ListView.builder(
      itemCount: categoryController.categoryList?.length ?? 0,
      itemBuilder: (context, index) {
        final category = categoryController.categoryList![index];
        return CategoryWidget(category: category);
      },
    );
  }
)
```

---

## ② مثال كامل: عرض Stores في Store List Screen

### الخطوة 1: فتح Store List Screen

**الملف:** `lib/features/store/screens/all_store_screen.dart`

```dart
class AllStoreScreen extends StatelessWidget {
  @override
  void initState() {
    super.initState();
    // ✅ تحميل البيانات
    Get.find<StoreController>().getPopularStoreList(true, 'all', true);
  }
}
```

---

### الخطوة 2: Controller يستدعي Repository

**الملف:** `lib/features/store/controllers/store_controller.dart`

```dart
class StoreController extends GetxController {
  final StoreRepositoryInterface storeRepository;
  List<Store>? popularStoreList;
  
  Future<void> getPopularStoreList(bool reload, String type, bool notify) async {
    popularStoreList = await storeRepository.getPopularStoreList(
      reload,
      type,
      notify,
    );
    update();  // ✅ تحديث UI
  }
}
```

---

### الخطوة 3: Repository يستدعي ApiClient

**الملف:** `lib/features/store/domain/repositories/store_repository.dart`

```dart
class StoreRepository implements StoreRepositoryInterface {
  final ApiClient apiClient;
  
  Future<StoreModel?> getPopularStoreList(...) async {
    final headers = apiClient.getHeader();
    
    // ✅ بناء URL مع Query Parameters
    final apiUrl = '${AppConstants.storeUri}/popular?store_type=$type&offset=$offset&limit=$limit';
    
    final response = await apiClient.getData(
      apiUrl,  // ✅ /api/v1/stores/popular?store_type=all&offset=1&limit=10
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

### الخطوة 4: ApiClient يرسل Request

**الملف:** `lib/api/api_client.dart`

```dart
// ✅ URL الكامل
final fullUrl = 'https://dev.shelafood.com/api/v1/stores/popular?store_type=all&offset=1&limit=10';

// ✅ Headers
final headers = {
  'moduleId': '6',
  'zoneId': '[2,4,3,5]',
  'latitude': '24.7136',
  'longitude': '46.6753',
  'X-localization': 'ar',
  'Authorization': 'Bearer {token}',
};

// ✅ Request
GET https://dev.shelafood.com/api/v1/stores/popular?store_type=all&offset=1&limit=10
Headers: {moduleId: '6', zoneId: '[2,4,3,5]', ...}
```

---

### الخطوة 5: Laravel API يعالج Request

**Backend (Laravel):**

```php
// Route: /api/v1/stores/popular
Route::get('/stores/popular', [StoreController::class, 'getPopularStores']);

// Controller: StoreController@getPopularStores
class StoreController extends Controller {
    public function getPopularStores(Request $request) {
        $moduleId = $request->header('moduleId');
        $zoneId = json_decode($request->header('zoneId'));
        $storeType = $request->query('store_type');
        $offset = $request->query('offset');
        $limit = $request->query('limit');
        
        // ✅ Query Database
        $stores = Store::where('module_id', $moduleId)
            ->whereIn('zone_id', $zoneId)
            ->where('status', 1)
            ->orderBy('avg_rating', 'desc')
            ->skip(($offset - 1) * $limit)
            ->take($limit)
            ->get();
        
        return response()->json([
            'stores' => $stores,
            'total_size' => $stores->count(),
        ]);
    }
}
```

---

### الخطوة 6: UI يعرض البيانات

**الملف:** `lib/features/store/screens/all_store_screen.dart`

```dart
GetBuilder<StoreController>(
  builder: (storeController) {
    return ItemsView(
      stores: storeController.popularStoreList,  // ✅ البيانات
    );
  }
)
```

---

## ③ مثال كامل: عرض Item Details

### الخطوة 1: فتح Item Details Screen

**الملف:** `lib/features/item/screens/item_details_screen.dart`

```dart
class ItemDetailsScreen extends StatefulWidget {
  final Item? item;  // ✅ Item من الصفحة السابقة
  
  @override
  void initState() {
    super.initState();
    
    // ✅ عرض Item فوراً (من widget.item)
    if (widget.item != null) {
      Get.find<ItemController>().setItemMiniCache(widget.item!);
    }
    
    // ✅ تحميل تفاصيل إضافية في الخلفية
    Get.find<ItemController>().getProductDetails(widget.item!);
  }
}
```

---

### الخطوة 2: Controller يستدعي Repository

**الملف:** `lib/features/item/controllers/item_controller.dart`

```dart
class ItemController extends GetxController {
  final ItemRepositoryInterface itemRepository;
  Item? item;
  
  Future<void> getProductDetails(Item item) async {
    final result = await itemRepository.getProductDetails(item.id!);
    
    if (result != null) {
      this.item = result.items?.first;
      update();  // ✅ تحديث UI
    }
  }
}
```

---

### الخطوة 3: Repository يستدعي ApiClient

**الملف:** `lib/features/item/domain/repositories/item_repository.dart`

```dart
class ItemRepository implements ItemRepositoryInterface {
  final ApiClient apiClient;
  
  Future<ItemModel?> getProductDetails(int itemId) async {
    final response = await apiClient.getData(
      '${AppConstants.searchItemUri}$itemId',  // ✅ /api/v1/items/details/123
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

### الخطوة 4: UI يعرض البيانات

**الملف:** `lib/features/item/screens/item_details_screen.dart`

```dart
GetBuilder<ItemController>(
  builder: (itemController) {
    return Column(
      children: [
        ItemImageViewWidget(
          item: itemController.item,  // ✅ البيانات
        ),
        ItemTitleViewWidget(
          item: itemController.item,
        ),
      ],
    );
  }
)
```

---

## ④ مشاكل شائعة وحلولها

### المشكلة 1: البيانات تتأخر

**السبب:**
- Cache غير صالح
- API Call بطيء
- Headers مفقودة

**الحل:**

```dart
// ✅ في Repository
Future<List<CategoryModel>?> getList(...) async {
  // 1. Cache أولاً
  final cached = await LocalClient.get(DataSourceEnum.client, cacheKey);
  if (cached != null && !reload) {
    return CategoryModel.fromJson(jsonDecode(cached)).categories;
  }
  
  // 2. API Call
  final response = await apiClient.getData(
    AppConstants.categoryUri,
    headers: apiClient.getHeader(),  // ✅ Headers تلقائياً
  );
  
  // 3. Parse و Cache
  if (response.statusCode == 200) {
    await LocalClient.organize(DataSourceEnum.client, cacheKey, jsonEncode(response.body), headers);
    return CategoryModel.fromJson(response.body).categories;
  }
  
  return null;
}
```

---

### المشكلة 2: البيانات لا تظهر

**السبب:**
- `update()` مفقود
- Controller غير مسجل
- Response فارغ

**الحل:**

```dart
// ✅ في Controller
Future<void> getCategoryList(bool reload) async {
  try {
    isLoading = true;
    update();  // ✅ Loading
    
    final result = await categoryRepository.getList(categoryList: true);
    
    if (result != null && result.isNotEmpty) {
      categoryList = result;
      isLoading = false;
      update();  // ✅ عرض البيانات
    } else {
      // ✅ معالجة الحالة الفارغة
      categoryList = [];
      isLoading = false;
      update();
    }
  } catch (e) {
    isLoading = false;
    update();
    // ✅ Error Handling
  }
}
```

---

### المشكلة 3: البيانات تظهر غلط

**السبب:**
- Module ID خاطئ
- Zone ID خاطئ
- Parsing خاطئ

**الحل:**

```dart
// ✅ في Repository
Future<List<CategoryModel>?> getList(...) async {
  // ✅ التحقق من Headers
  final headers = apiClient.getHeader();
  assert(headers.containsKey(AppConstants.moduleId), 'Module ID missing!');
  assert(headers.containsKey(AppConstants.zoneId), 'Zone ID missing!');
  
  final response = await apiClient.getData(
    AppConstants.categoryUri,
    headers: headers,
  );
  
  if (response.statusCode == 200) {
    // ✅ Logging
    if (kDebugMode) {
      print('API Response: ${response.body}');
    }
    
    try {
      final json = response.body as Map<String, dynamic>;
      return CategoryModel.fromJson(json).categories;
    } catch (e) {
      print('Parsing Error: $e');
      return null;
    }
  }
  
  return null;
}
```

---

## ⑤ Error Handling Strategy موحدة

### 5.1 المشكلة الحالية

**❌ الوضع الحالي:**
- Error Handling غير موحد
- بعض Controllers: `error = silent fail`
- UI لا يعرف الفرق بين: `empty` / `error` / `no internet`
- لا يوجد ErrorModel موحد

**✅ الحل المطلوب:**
- ErrorModel موحد
- UI يعرف جميع الحالات
- Strategy موحدة للأخطاء

---

### 5.2 ErrorModel الموحد

**الملف المقترح:** `lib/common/models/app_error_model.dart`

```dart
/// ✅ ErrorModel موحد لجميع Controllers
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
  final dynamic originalError;
  
  AppErrorModel({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.originalError,
  });
  
  // ✅ Factory constructors
  factory AppErrorModel.network(String message) {
    return AppErrorModel(
      type: AppErrorType.network,
      message: message,
    );
  }
  
  factory AppErrorModel.server(int statusCode, String message) {
    return AppErrorModel(
      type: AppErrorType.server,
      message: message,
      statusCode: statusCode,
    );
  }
  
  factory AppErrorModel.client(int statusCode, String message, {String? code}) {
    return AppErrorModel(
      type: AppErrorType.client,
      message: message,
      statusCode: statusCode,
      code: code,
    );
  }
  
  factory AppErrorModel.timeout(String message) {
    return AppErrorModel(
      type: AppErrorType.timeout,
      message: message,
    );
  }
  
  factory AppErrorModel.parsing(String message, dynamic error) {
    return AppErrorModel(
      type: AppErrorType.parsing,
      message: message,
      originalError: error,
    );
  }
  
  factory AppErrorModel.empty() {
    return AppErrorModel(
      type: AppErrorType.empty,
      message: 'no_data_available'.tr,
    );
  }
  
  // ✅ Helper methods
  bool get isNetworkError => type == AppErrorType.network;
  bool get isServerError => type == AppErrorType.server;
  bool get isClientError => type == AppErrorType.client;
  bool get isTimeout => type == AppErrorType.timeout;
  bool get isEmpty => type == AppErrorType.empty;
  bool get hasError => type != AppErrorType.empty;
  
  // ✅ User-friendly message
  String get userMessage {
    switch (type) {
      case AppErrorType.network:
        return 'no_internet_connection'.tr;
      case AppErrorType.server:
        return 'server_error_try_again'.tr;
      case AppErrorType.client:
        if (statusCode == 401) {
          return 'unauthorized_please_login'.tr;
        } else if (statusCode == 403) {
          return 'access_denied'.tr;
        } else if (statusCode == 404) {
          return 'resource_not_found'.tr;
        }
        return message;
      case AppErrorType.timeout:
        return 'request_timeout_try_again'.tr;
      case AppErrorType.parsing:
        return 'data_parsing_error'.tr;
      case AppErrorType.empty:
        return 'no_data_available'.tr;
      case AppErrorType.unknown:
        return 'something_went_wrong'.tr;
    }
  }
}
```

---

### 5.3 Controller State موحد

**الملف المقترح:** `lib/common/models/controller_state.dart`

```dart
/// ✅ Controller State موحد
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
  
  ControllerStateModel({
    required this.state,
    this.data,
    this.error,
  });
  
  // ✅ Factory constructors
  factory ControllerStateModel.initial() {
    return ControllerStateModel<T>(
      state: ControllerState.initial,
    );
  }
  
  factory ControllerStateModel.loading() {
    return ControllerStateModel<T>(
      state: ControllerState.loading,
    );
  }
  
  factory ControllerStateModel.success(T data) {
    return ControllerStateModel<T>(
      state: ControllerState.success,
      data: data,
    );
  }
  
  factory ControllerStateModel.error(AppErrorModel error) {
    return ControllerStateModel<T>(
      state: ControllerState.error,
      error: error,
    );
  }
  
  factory ControllerStateModel.empty() {
    return ControllerStateModel<T>(
      state: ControllerState.empty,
      error: AppErrorModel.empty(),
    );
  }
  
  // ✅ Helper methods
  bool get isLoading => state == ControllerState.loading;
  bool get isSuccess => state == ControllerState.success;
  bool get isError => state == ControllerState.error;
  bool get isEmpty => state == ControllerState.empty;
  bool get hasData => state == ControllerState.success && data != null;
}
```

---

### 5.4 Controller Pattern موحد

**مثال:** `CategoryController` مع Error Handling موحد

```dart
class CategoryController extends GetxController {
  final CategoryRepositoryInterface categoryRepository;
  
  // ✅ State موحد
  ControllerStateModel<List<CategoryModel>> _state = 
      ControllerStateModel.initial();
  
  ControllerStateModel<List<CategoryModel>> get state => _state;
  
  // ✅ Getters للراحة
  bool get isLoading => _state.isLoading;
  bool get isError => _state.isError;
  bool get isEmpty => _state.isEmpty;
  bool get hasData => _state.hasData;
  List<CategoryModel>? get categoryList => _state.data;
  AppErrorModel? get error => _state.error;
  
  Future<void> getCategoryList(bool reload) async {
    try {
      // ✅ 1. Loading State
      _state = ControllerStateModel.loading();
      update();
      
      // ✅ 2. API Call
      final result = await categoryRepository.getList(
        categoryList: true,
        allCategory: true,
      );
      
      // ✅ 3. Success State
      if (result != null && result.isNotEmpty) {
        _state = ControllerStateModel.success(result);
      } else {
        // ✅ 4. Empty State (ليس خطأ)
        _state = ControllerStateModel.empty();
      }
      
      update();
    } catch (e) {
      // ✅ 5. Error Handling موحد
      _state = ControllerStateModel.error(
        _mapExceptionToError(e),
      );
      update();
    }
  }
  
  // ✅ Mapping Exceptions إلى AppErrorModel
  AppErrorModel _mapExceptionToError(dynamic exception) {
    if (exception is SocketException || 
        exception.toString().contains('Network')) {
      return AppErrorModel.network('no_internet_connection'.tr);
    }
    
    if (exception is TimeoutException ||
        exception.toString().contains('Timeout')) {
      return AppErrorModel.timeout('request_timeout_try_again'.tr);
    }
    
    if (exception is FormatException ||
        exception.toString().contains('parsing')) {
      return AppErrorModel.parsing('data_parsing_error'.tr, exception);
    }
    
    // ✅ Check if it's an API Response Error
    if (exception is Response) {
      final statusCode = exception.statusCode ?? 0;
      final message = _extractErrorMessage(exception);
      
      if (statusCode >= 500) {
        return AppErrorModel.server(statusCode, message);
      } else if (statusCode >= 400) {
        return AppErrorModel.client(statusCode, message);
      }
    }
    
    return AppErrorModel(
      type: AppErrorType.unknown,
      message: exception.toString(),
      originalError: exception,
    );
  }
  
  String _extractErrorMessage(Response response) {
    try {
      if (response.body is Map<String, dynamic>) {
        final body = response.body as Map<String, dynamic>;
        
        // ✅ Laravel Error Format
        if (body.containsKey('message')) {
          return body['message'].toString();
        }
        
        if (body.containsKey('errors')) {
          final errors = body['errors'];
          if (errors is List && errors.isNotEmpty) {
            return errors[0].toString();
          }
          if (errors is Map && errors.isNotEmpty) {
            return errors.values.first.toString();
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return 'something_went_wrong'.tr;
  }
}
```

---

### 5.5 Repository Pattern موحد

**مثال:** `CategoryRepository` مع Error Handling

```dart
class CategoryRepository implements CategoryRepositoryInterface {
  final ApiClient apiClient;
  
  Future<List<CategoryModel>?> getList(...) async {
    try {
      // ✅ 1. Cache أولاً
      final cached = await LocalClient.get(DataSourceEnum.client, cacheKey);
      if (cached != null && !reload) {
        return CategoryModel.fromJson(jsonDecode(cached)).categories;
      }
      
      // ✅ 2. API Call
      final response = await apiClient.getData(
        AppConstants.categoryUri,
        headers: apiClient.getHeader(),
      );
      
      // ✅ 3. Check Response Status
      if (response.statusCode == 200) {
        // ✅ Parse و Cache
        final categoryModel = CategoryModel.fromJson(response.body);
        await LocalClient.organize(
          DataSourceEnum.client,
          cacheKey,
          jsonEncode(response.body),
          headers,
        );
        return categoryModel.categories;
      } else {
        // ✅ Error Response
        throw response;  // ✅ Throw Response للـ Controller
      }
    } catch (e) {
      // ✅ Re-throw للـ Controller
      rethrow;
    }
  }
}
```

---

### 5.6 UI Pattern موحد

**مثال:** `HomeScreen` مع Error Handling

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        final state = categoryController.state;
        
        // ✅ 1. Loading State
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // ✅ 2. Error State
        if (state.isError) {
          final error = state.error!;
          
          return ErrorWidget(
            error: error,
            onRetry: () => categoryController.getCategoryList(true),
          );
        }
        
        // ✅ 3. Empty State
        if (state.isEmpty) {
          return EmptyWidget(
            message: 'no_categories_available'.tr,
            onRetry: () => categoryController.getCategoryList(true),
          );
        }
        
        // ✅ 4. Success State
        if (state.hasData) {
          return ListView.builder(
            itemCount: state.data!.length,
            itemBuilder: (context, index) {
              return CategoryWidget(category: state.data![index]);
            },
          );
        }
        
        // ✅ 5. Initial State (fallback)
        return const SizedBox();
      }
    );
  }
}
```

---

### 5.7 Error Widget موحد

**الملف المقترح:** `lib/common/widgets/error_widget.dart`

```dart
class ErrorWidget extends StatelessWidget {
  final AppErrorModel error;
  final VoidCallback? onRetry;
  
  const ErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Icon حسب نوع الخطأ
          Icon(
            _getErrorIcon(),
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          
          // ✅ Error Message
          Text(
            error.userMessage,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          
          // ✅ Retry Button
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('retry'.tr),
            ),
          ],
        ],
      ),
    );
  }
  
  IconData _getErrorIcon() {
    switch (error.type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.server:
        return Icons.error_outline;
      case AppErrorType.client:
        return Icons.info_outline;
      case AppErrorType.timeout:
        return Icons.timer_off;
      case AppErrorType.parsing:
        return Icons.broken_image;
      case AppErrorType.empty:
        return Icons.inbox;
      case AppErrorType.unknown:
        return Icons.help_outline;
    }
  }
}
```

---

### 5.8 Empty Widget موحد

**الملف المقترح:** `lib/common/widgets/empty_widget.dart`

```dart
class EmptyWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const EmptyWidget({
    super.key,
    required this.message,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('refresh'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

### 5.9 ملخص Error Handling Strategy

**✅ المكونات المطلوبة:**

1. **AppErrorModel** - Error Model موحد
2. **ControllerStateModel** - State Model موحد
3. **Controller Pattern** - Pattern موحد للـ Controllers
4. **Repository Pattern** - Pattern موحد للـ Repositories
5. **UI Widgets** - ErrorWidget و EmptyWidget موحدين

**✅ الفوائد:**

- ✅ UI يعرف جميع الحالات: `loading` / `success` / `error` / `empty`
- ✅ Error Handling موحد في جميع Controllers
- ✅ User-friendly error messages
- ✅ Retry functionality موحد
- ✅ No silent failures

---

## ⑥ ملخص تدفق البيانات

```
User Action
    ↓
Screen initState()
    ↓
Controller Method
    ↓
Repository Method
    ↓
ApiClient.getData()
    ↓
Laravel API
    ↓
ApiClient Response
    ↓
Repository Parse
    ↓
Controller Update State (ControllerStateModel)
    ↓
GetBuilder Rebuild
    ↓
UI Display (مع Error Handling)
```

---

**تم إنشاء هذا الملف بواسطة AI Assistant**  
**آخر تحديث:** 2025-01-27

