# 🛡️ Error Handling Strategy موحدة

## 📍 نظرة عامة

هذا الملف يوضح **Error Handling Strategy موحدة** لجميع Controllers في المشروع.

---

## ❌ المشكلة الحالية

1. **Error Handling غير موحد**
   - كل Controller يعالج الأخطاء بطريقة مختلفة
   - بعض Controllers: `error = silent fail`
   - لا يوجد ErrorModel موحد

2. **UI لا يعرف الحالات**
   - UI لا يعرف الفرق بين: `empty` / `error` / `no internet`
   - لا يوجد State Model موحد

3. **User Experience سيء**
   - أخطاء صامتة (silent failures)
   - رسائل خطأ غير واضحة
   - لا يوجد Retry functionality موحد

---

## ✅ الحل المطلوب

### 1. ErrorModel موحد (`AppErrorModel`)
### 2. ControllerStateModel موحد (`ControllerStateModel`)
### 3. Controller Pattern موحد
### 4. UI Widgets موحدة (ErrorWidget, EmptyWidget)

---

## ① AppErrorModel

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

## ② ControllerStateModel

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

## ③ Controller Pattern موحد

**مثال:** `CategoryController`

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

## ④ Repository Pattern موحد

**مثال:** `CategoryRepository`

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
        // ✅ Error Response - Throw للـ Controller
        throw response;
      }
    } catch (e) {
      // ✅ Re-throw للـ Controller
      rethrow;
    }
  }
}
```

---

## ⑤ UI Pattern موحد

**مثال:** `HomeScreen`

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

## ⑥ Error Widget موحد

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

## ⑦ Empty Widget موحد

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

## ⑧ ملخص Implementation

### الخطوات المطلوبة:

1. **إنشاء AppErrorModel**
   - `lib/common/models/app_error_model.dart`

2. **إنشاء ControllerStateModel**
   - `lib/common/models/controller_state.dart`

3. **تحديث Controllers**
   - استخدام `ControllerStateModel` بدلاً من `bool isLoading`
   - استخدام `AppErrorModel` للأخطاء

4. **إنشاء UI Widgets**
   - `lib/common/widgets/error_widget.dart`
   - `lib/common/widgets/empty_widget.dart`

5. **تحديث UI Screens**
   - استخدام `state.isLoading` / `state.isError` / `state.isEmpty`
   - استخدام `ErrorWidget` و `EmptyWidget`

---

## ⑨ الفوائد

### ✅ User Experience
- رسائل خطأ واضحة ومفهومة
- Retry functionality موحد
- No silent failures

### ✅ Developer Experience
- Error Handling موحد
- Code قابل للصيانة
- Testing أسهل

### ✅ UI Consistency
- UI يعرف جميع الحالات
- Widgets موحدة
- Design consistent

---

**تم إنشاء هذا الملف بواسطة AI Assistant**  
**آخر تحديث:** 2025-01-27





