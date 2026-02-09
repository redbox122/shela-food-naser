# أماكن فلترة المنتجات في التطبيق

## نظرة عامة
هذا المستند يوضح جميع الأماكن في التطبيق التي تحتوي على وظائف فلترة المنتجات.

---

## 1. شاشة فلترة المنتجات الرئيسية

### الموقع
```
lib/features/search/widgets/search_Filter_widget.dart
```

### الوصف
شاشة فلترة كاملة للمنتجات تحتوي على جميع خيارات الفلترة المتاحة.

### المميزات
- **الترتيب حسب:**
  - الأكثر مبيعًا (popular)
  - أ - ي (ascending)
  - ي - أ (descending)

- **فلترة حسب الفئة:**
  - اختيار من قائمة الفئات المتاحة
  - عرض جميع الفئات في صف أفقي قابل للتمرير

- **فلترة حسب المتجر:**
  - اختيار من قائمة المتاجر المتاحة
  - عرض جميع المتاجر في صف أفقي قابل للتمرير

- **اسم المنتج:**
  - حقل إدخال للبحث عن منتج معين

- **فلترة حسب الخصم:**
  - مفتاح تبديل (Switch) لعرض المنتجات التي لديها خصم فقط

- **نطاق السعر:**
  - خيارات محددة مسبقًا:
    - الكل
    - 0 - 10
    - 20 - 40
    - 40 - 70
    - 70 - 100
    - 150 - 200
    - 200 - 300
    - 300 - 500
    - 500 - 700
    - 700 - 1000

### الاستخدام
```dart
ProductFilterScreen()
```

### التكامل
- يتكامل مع `Search_Controller` لتطبيق الفلاتر
- يستخدم `StoreController` و `CategoryController` لجلب البيانات

---

## 2. فلترة المنتجات في العروض (Offers)

### الموقع
```
lib/features/offers/controllers/offers_controller.dart
```

### الوظائف الرئيسية

#### `setCategoryIndex(int index, {bool itemSearching = false})`
- يحدد فهرس الفئة المختارة
- يدعم فلترة من الواجهة الأمامية (Frontend) للأداء الأفضل
- يعود إلى API إذا لم تكن هناك بيانات مخزنة مؤقتًا

#### `_filterItemsByCategory(List<Item> items, int categoryIndex)`
- يفلتر المنتجات حسب الفئة المحددة
- يطبق ترتيب السعر بعد الفلترة
- يدعم فئة "الكل" (index = 0)

#### `_applyPriceSorting(List<Item> items)`
- يرتب المنتجات حسب السعر
- يدعم الترتيب تصاعديًا وتنازليًا

#### `resetFilters()`
- يعيد تعيين جميع الفلاتر
- يستعيد القائمة الأصلية للمنتجات

#### `toggleFilterModal()` / `closeFilterModal()`
- يفتح/يغلق نافذة الفلترة

#### `toggleCategorySelection(int categoryId)`
- يضيف/يزيل فئة من الفئات المختارة

#### `applyCategoryFilter()`
- يطبق فلترة الفئات المختارة

#### `_filterItemsByMultipleCategories(List<Item> items, List<int> categoryIds)`
- يفلتر المنتجات حسب عدة فئات في نفس الوقت

### المميزات
- فلترة من الواجهة الأمامية للأداء الأفضل
- دعم فلترة متعددة الفئات
- ترتيب حسب السعر (تصاعدي/تنازلي)
- حفظ البيانات الأصلية للعودة إليها عند إعادة تعيين الفلاتر

---

## 3. مساعد فلترة المتاجر (Store Filter Helper)

### الموقع
```
lib/features/home/utils/store_filter_helper.dart
```

### الوصف
فئة مساعدة تحتوي على منطق فلترة وترتيب قوائم المتاجر. يمكن استخدامها كمرجع لفلترة المنتجات.

### الوظائف الرئيسية

#### `applyFilters({...})`
يطبق جميع الفلاتر النشطة على قائمة المتاجر:

- **فلترة حسب الحالة:**
  - `openNow`: المتاجر المفتوحة فقط
  - `freeDelivery`: التوصيل المجاني
  - `hasDiscount`: وجود خصم
  - `featuredOnly`: المميزة فقط

- **فلترة حسب التقييم:**
  - `minRating`: الحد الأدنى للتقييم (4.0 أو 4.5)

- **فلترة حسب الوقت:**
  - `maxDeliveryTime`: الحد الأقصى لوقت التوصيل

- **فلترة حسب الطلب:**
  - `maxMinOrder`: الحد الأقصى للطلب الأدنى

- **فلترة حسب الفئات:**
  - `categoryIds`: قائمة بمعرفات الفئات

- **الترتيب:**
  - `sortBy`: حسب المسافة، التقييم، وقت التوصيل، أو الحد الأدنى للطلب

#### `_sortStores(List<Store> stores, String sortBy)`
يرتب المتاجر حسب المعيار المحدد:
- `distance`: حسب المسافة
- `rating`: حسب التقييم (تنازلي)
- `delivery_time`: حسب وقت التوصيل (تصاعدي)
- `min_order`: حسب الحد الأدنى للطلب (تصاعدي)

#### `getActiveFilterCount(Map<String, dynamic> filters)`
يحسب عدد الفلاتر النشطة

#### `hasActiveFilters(Map<String, dynamic> filters)`
يتحقق من وجود فلاتر نشطة

#### `getDefaultFilters()`
يعيد الفلاتر الافتراضية (جميعها فارغة/مغلقة)

---

## 4. Bottom Sheet للفلترة

### الموقع
```
lib/features/home/widgets/filter_bottom_sheet.dart
```

### الوصف
نافذة منبثقة من الأسفل (Bottom Sheet) تعرض خيارات الفلترة للمطاعم/المتاجر.

### المميزات

#### نوع الطعام (Radio Buttons)
- الكل
- نباتي
- غير نباتي

#### خيارات (Checkboxes)
- أضيف حديثًا
- الأعلى تقييمًا 4.5 فما فوق
- الأسرع توصيلًا حتى 30 دقيقة

#### نطاق السعر
- شريط تمرير (Range Slider) من 0 إلى 1000 ريال
- عرض القيم الحالية

#### الترتيب حسب (Radio Buttons)
- الموصى به
- المسافة
- التقييمات من الأعلى إلى الأقل
- وقت التوصيل من الأقل إلى الأعلى

### الأزرار
- **تطبيق**: يطبق الفلاتر المختارة
- **مسح الكل**: يعيد تعيين جميع الفلاتر

### الاستخدام
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => FilterBottomSheet(
    onApply: (filters) {
      // تطبيق الفلاتر
    },
    onClear: () {
      // مسح الفلاتر
    },
  ),
);
```

---

## 5. فلترة المنتجات في العلامات التجارية (Brands)

### الموقع
```
lib/features/brands/screens/brands_product_screen.dart
```

### الوصف
شاشة عرض منتجات العلامة التجارية مع إمكانيات الفلترة.

### المميزات
- شريط بحث
- أزرار فلترة
- نافذة فلترة منبثقة (Filter Modal)
- عرض المنتجات مع إمكانية التمرير

---

## 6. ملفات فلترة أخرى

### ملفات Widgets
- `lib/features/home/widgets/all_store_filter_widget.dart`
- `lib/features/category/widgets/search_filter.dart`
- `lib/features/store/widgets/store_search_Filter_widget.dart`
- `lib/features/search/widgets/filter_widget.dart`
- `lib/features/home/widgets/filter_view.dart`
- `lib/features/home/widgets/active_filters_chips.dart`
- `lib/features/home/widgets/store_filter_bottom_sheet.dart`
- `lib/features/home/widgets/enhanced_filter_button.dart`
- `lib/features/home/widgets/store_filter_button_widget.dart`

### ملفات Models
- `lib/features/search/domain/models/search_filter_model.dart`
- `lib/features/wallet/domain/models/wallet_filter_body_model.dart`

### ملفات أخرى
- `lib/common/widgets/veg_filter_widget.dart`: فلترة نباتي/غير نباتي
- `lib/features/home/widgets/store_filter_integration_example.dart`: مثال على التكامل

---

## ملخص الملفات الرئيسية

| الملف | الوظيفة | الموقع |
|------|---------|--------|
| `search_Filter_widget.dart` | شاشة فلترة المنتجات الرئيسية | `lib/features/search/widgets/` |
| `offers_controller.dart` | Controller فلترة المنتجات في العروض | `lib/features/offers/controllers/` |
| `store_filter_helper.dart` | Helper للفلترة والترتيب | `lib/features/home/utils/` |
| `filter_bottom_sheet.dart` | Bottom Sheet للفلترة | `lib/features/home/widgets/` |
| `brands_product_screen.dart` | فلترة منتجات العلامات التجارية | `lib/features/brands/screens/` |

---

## ملاحظات مهمة

1. **فلترة من الواجهة الأمامية**: معظم الفلاتر تعمل على الواجهة الأمامية للأداء الأفضل، مع إمكانية العودة إلى API عند الحاجة.

2. **حفظ البيانات الأصلية**: يتم حفظ القوائم الأصلية للعودة إليها عند إعادة تعيين الفلاتر.

3. **ترتيب السعر**: معظم الفلاتر تدعم ترتيب المنتجات حسب السعر (تصاعدي/تنازلي).

4. **دعم RTL**: جميع الواجهات تدعم الاتجاه من اليمين لليسار (RTL) للغة العربية.

5. **التكامل مع Controllers**: الفلاتر تتكامل مع Controllers المختلفة مثل:
   - `Search_Controller`
   - `StoreController`
   - `CategoryController`
   - `OffersController`
   - `BrandsController`

---

## تاريخ الإنشاء
تم إنشاء هذا المستند في: {{ تاريخ اليوم }}

