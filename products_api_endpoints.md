# API Endpoints للمنتجات في Flutter

## 📋 نظرة عامة
هذا المستند يحتوي على جميع API endpoints التي يستخدمها Flutter لجلب المنتجات، بالإضافة إلى ملف Repository/Controller الرئيسي.

---

## 🔗 API Endpoints للمنتجات

### 1. أحدث المنتجات (Latest Items)
```
GET /api/v1/items/latest
```
**الاستخدام:**
- جلب أحدث المنتجات
- يمكن إضافة query parameters:
  - `store_id`: جلب منتجات متجر معين
  - `category_id`: جلب منتجات فئة معينة
  - `offset`: رقم الصفحة
  - `limit`: عدد المنتجات
  - `type`: نوع المنتجات (all, veg, non_veg)

**مثال:**
```
GET /api/v1/items/latest?store_id=123&category_id=0&offset=1&limit=50&type=all
```

---

### 2. المنتجات الشائعة (Popular Items)
```
GET /api/v1/items/popular
```
**الاستخدام:**
- جلب المنتجات الأكثر شعبية
- Query parameters:
  - `type`: نوع المنتجات (all, veg, non_veg)

**مثال:**
```
GET /api/v1/items/popular?type=all
```

---

### 3. تفاصيل منتج معين (Item Details)
```
GET /api/v1/items/details/{item_id}
```
**الاستخدام:**
- جلب تفاصيل منتج معين
- Path parameter: `item_id` - معرف المنتج

**مثال:**
```
GET /api/v1/items/details/456
```

---

### 4. المنتجات الأكثر تقييمًا (Most Reviewed)
```
GET /api/v1/items/most-reviewed
```
**الاستخدام:**
- جلب المنتجات التي حصلت على أكبر عدد من التقييمات
- Query parameters:
  - `type`: نوع المنتجات

**مثال:**
```
GET /api/v1/items/most-reviewed?type=all
```

---

### 5. منتجات فئة معينة (Category Items)
```
GET /api/v1/categories/items/{category_id}
```
**الاستخدام:**
- جلب جميع المنتجات في فئة معينة
- Path parameter: `category_id` - معرف الفئة
- Query parameters:
  - `offset`: رقم الصفحة
  - `limit`: عدد المنتجات
  - `type`: نوع المنتجات

**مثال:**
```
GET /api/v1/categories/items/5?limit=10&offset=1&type=all
```

---

### 6. البحث عن منتجات (Search Items)
```
GET /api/v1/items/search
```
**الاستخدام:**
- البحث عن منتجات بالاسم
- Query parameters:
  - `name`: نص البحث
  - `store_id`: (اختياري) البحث في متجر معين
  - `category_id`: (اختياري) البحث في فئة معينة
  - `offset`: رقم الصفحة
  - `limit`: عدد النتائج
  - `type`: نوع المنتجات

**مثال:**
```
GET /api/v1/items/search?name=apple&limit=20&offset=1
```

---

### 7. المنتجات الموصى بها (Recommended Items)
```
GET /api/v1/items/recommended?{type}&limit=30
```
**الاستخدام:**
- جلب المنتجات الموصى بها للمستخدم
- Query parameters:
  - `type`: نوع المنتجات
  - `limit`: عدد المنتجات

**مثال:**
```
GET /api/v1/items/recommended?type=all&limit=30
```

---

### 8. المنتجات المخفضة (Discounted Items)
```
GET /api/v1/items/discounted
```
**الاستخدام:**
- جلب المنتجات التي لديها خصم
- Query parameters:
  - `type`: نوع المنتجات
  - `offset`: رقم الصفحة
  - `limit`: عدد المنتجات

**مثال:**
```
GET /api/v1/items/discounted?type=all&offset=1&limit=50
```

---

### 9. منتجات الفئات المميزة (Featured Categories Items)
```
GET /api/v1/items/featured-categories?limit=30&offset=1
```
**الاستخدام:**
- جلب منتجات من الفئات المميزة
- Query parameters:
  - `limit`: عدد المنتجات
  - `offset`: رقم الصفحة

**مثال:**
```
GET /api/v1/items/featured-categories?limit=30&offset=1
```

---

### 10. منتجات حسب الحالة (Condition Wise Items)
```
GET /api/v1/items/condition-wise/{condition_id}?limit=15&offset=1
```
**الاستخدام:**
- جلب منتجات مرتبطة بحالة طبية معينة (للصيدليات)
- Path parameter: `condition_id` - معرف الحالة
- Query parameters:
  - `limit`: عدد المنتجات
  - `offset`: رقم الصفحة

**مثال:**
```
GET /api/v1/items/condition-wise/10?limit=15&offset=1
```

---

## 📁 ملف Repository الرئيسي

### الموقع
```
lib/features/item/domain/repositories/item_repository.dart
```

### الوصف
هذا هو الملف الرئيسي الذي يحتوي على جميع استدعاءات API لجلب المنتجات. يستخدم `ApiClient` الذي بدوره يستخدم `Dio.get()` للاتصال بالـ API.

---

## 🔍 تفاصيل الملف

### الكلاس الرئيسي
```dart
class ItemRepository implements ItemRepositoryInterface {
  final ApiClient apiClient;
  ItemRepository({required this.apiClient});
}
```

### الوظائف الرئيسية

#### 1. جلب تفاصيل منتج
```dart
Future<Item?> _getItemDetails(int? itemID) async {
  final Response response = await apiClient.getData('${AppConstants.itemDetailsUri}$itemID');
  // AppConstants.itemDetailsUri = '/api/v1/items/details/'
}
```
**API Endpoint:** `/api/v1/items/details/{item_id}`

---

#### 2. جلب المنتجات الشائعة
```dart
Future<List<Item>?> _getPopularItemList(String type, {required DataSourceEnum source}) async {
  final Response response = await apiClient.getData('${AppConstants.popularItemUri}?type=$type');
  // AppConstants.popularItemUri = '/api/v1/items/popular'
}
```
**API Endpoint:** `/api/v1/items/popular?type={type}`

---

#### 3. جلب المنتجات الأكثر تقييمًا
```dart
Future<ItemModel?> _getReviewedItemList(String type, {required DataSourceEnum source}) async {
  final Response response = await apiClient.getData('${AppConstants.reviewedItemUri}?type=$type');
  // AppConstants.reviewedItemUri = '/api/v1/items/most-reviewed'
}
```
**API Endpoint:** `/api/v1/items/most-reviewed?type={type}`

---

#### 4. جلب منتجات فئة معينة
```dart
Future<ItemModel?> _getCategoryItemList(String? categoryID, int offset, String type) async {
  final Response response = await apiClient.getData('${AppConstants.categoryItemUri}$categoryID?limit=10&offset=$offset&type=$type');
  // AppConstants.categoryItemUri = '/api/v1/categories/items/'
}
```
**API Endpoint:** `/api/v1/categories/items/{category_id}?limit=10&offset={offset}&type={type}`

---

#### 5. جلب المنتجات الموصى بها
```dart
Future<List<Item>?> _getRecommendedItemList(String type, {required DataSourceEnum source}) async {
  final Response response = await apiClient.getData('${AppConstants.recommendedItemsUri}$type&limit=30');
  // AppConstants.recommendedItemsUri = '/api/v1/items/recommended?'
}
```
**API Endpoint:** `/api/v1/items/recommended?{type}&limit=30`

---

#### 6. جلب المنتجات المخفضة
```dart
Future<List<Item>?> _getDiscountedItemList(String type, {required DataSourceEnum source}) async {
  final Response response = await apiClient.getData('${AppConstants.discountedItemsUri}?type=$type&offset=1&limit=50');
  // AppConstants.discountedItemsUri = '/api/v1/items/discounted'
}
```
**API Endpoint:** `/api/v1/items/discounted?type={type}&offset=1&limit=50`

---

#### 7. جلب منتجات الفئات المميزة
```dart
Future<ItemModel?> _getFeaturedCategoriesItemList({required DataSourceEnum source}) async {
  final Response response = await apiClient.getData('${AppConstants.featuredCategoriesItemsUri}?limit=30&offset=1');
  // AppConstants.featuredCategoriesItemsUri = '/api/v1/items/featured-categories'
}
```
**API Endpoint:** `/api/v1/items/featured-categories?limit=30&offset=1`

---

#### 8. جلب منتجات حسب الحالة
```dart
Future<List<Item>?> _getConditionsWiseItems(int id) async {
  final Response response = await apiClient.getData('${AppConstants.conditionWiseItemUri}$id?limit=15&offset=1');
  // AppConstants.conditionWiseItemUri = '/api/v1/items/condition-wise/'
}
```
**API Endpoint:** `/api/v1/items/condition-wise/{condition_id}?limit=15&offset=1`

---

## 🔧 كيف يعمل ApiClient

`ItemRepository` يستخدم `ApiClient.getData()` الذي بدوره يستخدم `Dio.get()`:

```dart
// في ApiClient
final response = await _secureHttpClient.dio.get<dynamic>(
  uri,
  queryParameters: query,
  options: Options(
    headers: finalHeaders,
    receiveTimeout: secureReceiveTimeoutOverride,
    // ... المزيد من الخيارات
  ),
  cancelToken: cancelToken,
);
```

---

## 📝 ملاحظات مهمة

1. **Headers المطلوبة:**
   - `module-id`: معرف الوحدة (Module ID)
   - `zone-id`: معرف المنطقة (Zone ID)
   - `X-localization`: اللغة (ar, en, etc.)
   - `Authorization`: (اختياري) للطلبات التي تتطلب مصادقة

2. **Caching:**
   - يتم حفظ البيانات في `LocalClient` للاستخدام المحلي
   - يدعم `DataSourceEnum.client` (من API) و `DataSourceEnum.local` (من الكاش)

3. **Error Handling:**
   - جميع الاستدعاءات تتحقق من `response.statusCode == 200`
   - في حالة الخطأ، يتم إرجاع `null` أو قائمة فارغة

4. **Pagination:**
   - معظم الـ endpoints تدعم `offset` و `limit` للترقيم

---

## 📊 ملخص API Endpoints

| Endpoint | Method | الوظيفة |
|----------|--------|---------|
| `/api/v1/items/latest` | GET | أحدث المنتجات |
| `/api/v1/items/popular` | GET | المنتجات الشائعة |
| `/api/v1/items/details/{id}` | GET | تفاصيل منتج |
| `/api/v1/items/most-reviewed` | GET | الأكثر تقييمًا |
| `/api/v1/categories/items/{id}` | GET | منتجات فئة |
| `/api/v1/items/search` | GET | بحث عن منتجات |
| `/api/v1/items/recommended` | GET | المنتجات الموصى بها |
| `/api/v1/items/discounted` | GET | المنتجات المخفضة |
| `/api/v1/items/featured-categories` | GET | منتجات فئات مميزة |
| `/api/v1/items/condition-wise/{id}` | GET | منتجات حسب الحالة |

---

## 📍 الملفات ذات الصلة

- **Repository:** `lib/features/item/domain/repositories/item_repository.dart`
- **API Client:** `lib/api/api_client.dart`
- **Constants:** `lib/util/app_constants.dart` (يحتوي على جميع الـ URIs)
- **Models:** `lib/features/item/domain/models/item_model.dart`

---

## تاريخ الإنشاء
تم إنشاء هذا المستند في: {{ تاريخ اليوم }}

