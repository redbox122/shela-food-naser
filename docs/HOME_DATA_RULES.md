# 🎯 Home Data Loading Rules

## القواعد الأساسية (Golden Rules)

### 1️⃣ HomeScreen NEVER calls APIs directly

❌ **ممنوع:**
```dart
// في HomeScreen
Get.find<CategoryController>().getCategoryList(true);
Get.find<StoreController>().getStoreList(1, true);
Get.find<BannerController>().getBannerList(true);
```

✅ **الصحيح:**
```dart
// في HomeScreen
Get.find<HomeController>().loadHomeData();
```

---

### 2️⃣ HomeController decides unified vs partial

`HomeController` هو **المصدر الوحيد** لقرار تحميل البيانات:

- **unified endpoint** (`/api/v2/home-unified`) = المصدر الافتراضي
- **partial endpoints** (individual APIs) = fallback فقط

```dart
// HomeController يقرر تلقائيًا
await homeController.loadHomeData();

// أو فرض partial (للاختبار)
await homeController.loadHomeData(forcePartial: true);
```

---

### 3️⃣ Other Controllers only expose setters

Controllers الأخرى (Category, Store, Banner) **لا تحمل تلقائيًا**:

❌ **ممنوع في Controllers:**
```dart
@override
void onInit() {
  super.onInit();
  getCategoryList(false); // ❌ لا تحميل تلقائي
}
```

✅ **الصحيح:**
```dart
// Controllers تعرض setters آمنة فقط
void setFromUnified(List<CategoryModel> data) {
  categoryList = data;
  update();
}
```

---

## 🏗️ Architecture Flow

```
HomeScreen
  ↓
HomeController.loadHomeData()
  ↓
  ├─→ Try unified endpoint (HomeUnifiedController)
  │     ↓
  │     Success? → Distribute to Controllers via setters
  │     │
  │     └─→ CategoryController.setFromUnified()
  │     └─→ StoreController.setFromUnified()
  │     └─→ BannerController.setFromUnified()
  │
  └─→ Fallback to partial endpoints
        ↓
        └─→ CategoryController.getCategoryList()
        └─→ StoreController.getStoreList()
        └─→ BannerController.getBannerList()
```

---

## 🛡️ Guard Rails (منع التخريب)

### ✅ DO:
- استخدم `HomeController.loadHomeData()` فقط من HomeScreen
- استخدم `setFromUnified()` في Controllers عند استقبال بيانات من unified endpoint
- استخدم fallback endpoints فقط عند فشل unified endpoint

### ❌ DON'T:
- لا تستدعي APIs مباشرة من HomeScreen
- لا تحمل تلقائيًا في `onInit()` للـ Controllers
- لا تخلط unified و partial endpoints في نفس الوقت

---

## 🧪 Testing

### اختبار Unified Endpoint:
```dart
// في HomeScreen
await Get.find<HomeController>().loadHomeData(forceRefresh: true);
// يجب أن يستخدم unified endpoint
```

### اختبار Fallback:
```dart
// في HomeScreen
await Get.find<HomeController>().loadHomeData(forcePartial: true);
// يجب أن يستخدم partial endpoints
```

### اختبار Error Handling:
```dart
// عطّل unified endpoint في Backend
// يجب أن يتحول تلقائيًا إلى partial endpoints بدون crash
```

---

## 📝 Notes

- **HomeController** هو الوحيد الذي يقرر مصدر البيانات
- **Controllers الأخرى** passive - تستقبل البيانات فقط
- **HomeScreen** لا يعرف ولا يهتم من أين أتت البيانات
- **Unified endpoint** هو المصدر الافتراضي
- **Partial endpoints** fallback فقط

---

## 🔄 Migration Guide

إذا كنت تضيف feature جديد:

1. **لا تضيف API call مباشر في HomeScreen**
2. **أضف setter في Controller الخاص بك:**
   ```dart
   void setFromUnified(YourDataType data) {
     _yourData = data;
     update();
   }
   ```
3. **أضف distribution في HomeController._loadUnifiedHome():**
   ```dart
   Get.find<YourController>().setFromUnified(result.yourData);
   ```
4. **أضف fallback في HomeController._loadPartialHome():**
   ```dart
   Get.find<YourController>().getYourData();
   ```

---

**آخر تحديث:** 2024
**المسؤول:** HomeController Architecture Team

