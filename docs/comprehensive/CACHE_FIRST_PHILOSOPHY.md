# ⚡ Cache-First + Background Refresh Philosophy

## 🎯 الهدف

> **اعرض ما عندك الآن، وحدّثه عندما تستطيع.**

- التطبيق يفتح فورًا ⚡
- البيانات تظهر مباشرة من الكاش
- التحديث يصير بالخلفية بدون blocking
- ❌ ممنوع إعادة تحميل كل شي كل مرة

---

## 🧠 المبدأ الأساسي

**الكاش هو المصدر الأول للعرض**  
**الـ API فقط للتحديث**

---

## 🧱 الهيكلية المطبقة

### 1️⃣ عند فتح الصفحة (Flow واضح)

#### الخطوة A – قبل أي API (Cache-First)

```dart
// ⚡ STEP A: Load from cache first (0ms)
final cached = await loadCachedDataForInstantUI();

if (cached != null) {
  controller.setData(cached, source: cache);
  // UI renders immediately
}
```

**النتيجة:**
- ✅ UI يرسم فورًا (0ms من memory cache)
- ✅ بدون loading ثقيل
- ✅ تجربة سلسة للمستخدم

#### الخطوة B – بعد أول Frame (Background Refresh)

```dart
// ⚡ STEP B: Background refresh (non-blocking)
WidgetsBinding.instance.addPostFrameCallback((_) {
  controller.refreshInBackground();
  // No await - runs in background
});
```

**النتيجة:**
- ✅ UI ظاهر بالفعل
- ✅ التحديث في الخلفية
- ✅ لا blocking للـ UI

---

### 2️⃣ التحديث بالخلفية (Background Refresh)

```dart
Future<void> refreshInBackground() async {
  if (isRefreshing) return; // Prevent duplicate calls

  final response = await api.fetchHome();

  // ⚡ Deep Equality Check
  if (!deepEqual(response, currentData)) {
    updateUI(response);
    saveToCache(response);
  } else {
    // Data identical - skip update
    print('[API] data identical → skip update');
  }
}
```

**القواعد:**
- ✅ إذا نفس البيانات → ولا حركة
- ✅ إذا تغيرت → update واحد فقط
- ✅ حفظ في الكاش دائماً (لتحديث timestamp)

---

### 3️⃣ المطاعم (Stores) – معالجة خاصة 🔥

#### أول مرة:

```dart
// ⚡ Cache-First: Load page 1 from cache
if (cachedStores != null) {
  showStores(cachedStores); // Instant display
}

// ⚡ Background: Refresh in background
loadStoresInBackground(limit: 8); // Small limit for first load
```

#### عند Scroll (Pagination):

```dart
// Load page 2, 3... on scroll
// ❌ لا تخزين لكل الصفحات (only page 1)
loadStoresPage(page: 2, limit: 12);
```

**النتيجة:**
- ✅ أول تحميل سريع (8 stores فقط)
- ✅ Pagination تدريجي
- ✅ لا تحميل 300+ store دفعة واحدة

---

### 4️⃣ TTL (Time To Live)

```dart
// TTL Configuration
home_unified → 30 دقيقة
stores_page1 → 10 دقائق
brands → 30 دقيقة
categories → 30 دقيقة
offers → 30 دقيقة
```

**السلوك:**
- ✅ إذا منتهي: نعرض الكاش + refresh فورًا
- ✅ إذا صالح: نعرض الكاش + refresh في الخلفية

---

### 5️⃣ Deep Equality Checks

```dart
// ⚡ Check version_hash first (fastest)
if (oldData.versionHash == newData.versionHash) {
  return; // Identical - skip update
}

// ⚡ Deep equality check (if no version_hash)
if (deepEqual(oldData, newData)) {
  return; // Identical - skip update
}

// Data changed - update UI
updateUI(newData);
```

**النتيجة:**
- ✅ منع updates غير ضرورية
- ✅ منع flicker في UI
- ✅ حفظ bandwidth

---

### 6️⃣ Logging نظيف

كل عملية تطبع:

```
[Cache] HIT: home_unified_6 (memory - 0ms)
[Cache] MISS: stores_page1_6_2 (expired)
[API] background refresh started
[API] data identical → skip update
[API] data changed → updating UI
```

**القواعد:**
- ✅ Logging واضح ومختصر
- ✅ استخدام `[Cache]` و `[API]` prefixes
- ✅ لا logging مفرط

---

## 📋 قواعد صارمة (لا تفاوض)

### ❌ ممنوع:
- ❌ Fetch بدون سبب
- ❌ API قبل UI
- ❌ Reset controllers عبثي
- ❌ Duplicate API calls
- ❌ Loading spinner طويل

### ✅ مطلوب:
- ✅ Cache-First دائماً
- ✅ Background refresh
- ✅ Deep equality checks
- ✅ TTL management
- ✅ Logging نظيف

---

## 🧩 النتيجة المتوقعة

### Performance Metrics:
- ⚡ First frame: ≤ 300ms (from cache)
- ⚡ Cache hit: 0ms (memory)
- ⚡ Cache miss: < 50ms (disk)
- ⚡ Background refresh: non-blocking

### User Experience:
- ✅ فتح التطبيق = فوري
- ✅ النت الضعيف ما يدمّر التجربة
- ✅ استهلاك API أقل
- ✅ المستخدم يحس التطبيق "ذكي"

---

## 📝 Implementation Examples

### HomeUnifiedController

```dart
// ⚡ Cache-First: Load from cache
Future<bool> loadCachedDataForInstantUI() async {
  // Memory cache first (0ms)
  if (_moduleDataCache.containsKey(moduleId)) {
    _distributeDataToControllers(memoryData);
    print('[Cache] HIT: home_unified_$moduleId (memory)');
    return true;
  }

  // Disk cache (Hive)
  final cached = await _loadFromCache(moduleId);
  if (cached != null) {
    _distributeDataToControllers(cached);
    print('[Cache] HIT: home_unified_$moduleId (disk)');
    return true;
  }

  print('[Cache] MISS: home_unified_$moduleId');
  return false;
}

// ⚡ Background Refresh
Future<void> refreshInBackground() async {
  final apiData = await api.fetch();
  
  // Check if changed
  if (apiData.versionHash == cachedData.versionHash) {
    print('[API] data identical → skip update');
    return;
  }

  // Update UI
  _distributeDataToControllers(apiData);
  await _saveToCache(apiData);
  print('[API] data changed → updating UI');
}
```

### StoreController

```dart
// ⚡ Cache-First: Load page 1 from cache
Future<StoreModel?> getStoreList(int offset, bool reload) async {
  // Load from cache first (if page 1)
  if (offset == 1 && !reload && hasCachedData) {
    print('[Cache] HIT: stores_page1');
    return cachedStores; // Instant display
  }

  // Background refresh
  final stores = await api.fetchStores(offset: offset, limit: 8);
  
  // Check if changed
  if (isDataIdentical(cachedStores, stores)) {
    print('[API] data identical → skip update');
    return cachedStores;
  }

  // Update UI
  print('[API] data changed → updating UI');
  return stores;
}
```

---

## 🎓 الخلاصة

**الفلسفة بجملة واحدة:**

> اعرض ما عندك الآن، وحدّثه عندما تستطيع.

**التطبيق:**
1. Cache-First: دائماً من الكاش أولاً
2. Background Refresh: تحديث في الخلفية
3. Deep Equality: منع updates غير ضرورية
4. TTL: إدارة صلاحية الكاش
5. Logging: نظيف وواضح

**النتيجة:**
- ⚡ تطبيق سريع
- 💾 استهلاك API أقل
- 😊 تجربة مستخدم ممتازة
