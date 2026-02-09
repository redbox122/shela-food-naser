# 📁 Location Feature - Code Structure Summary

## 🗂️ هيكل المجلد

```
lib/features/location/
├── controllers/          # منطق الأعمال (Business Logic)
├── screens/              # شاشات UI
├── domain/               # نماذج البيانات والـ APIs
│   ├── models/          # Data Models
│   ├── repositories/    # API Calls
│   └── services/        # Service Layer
├── widgets/              # Widgets قابلة لإعادة الاستخدام
└── documentation/       # توثيق
```

---

## 🎮 Controllers (منطق الأعمال)

### `location_controller.dart` (2370 سطر)

**الوظيفة الرئيسية:** إدارة كل منطق الموقع والـ zones

#### الوظائف الأساسية:

1. **`getCurrentLocation(bool fromAddress, ...)`**
   - يجلب الموقع الحالي من GPS
   - يعطي أولوية لـ GPS → Saved Address → Default Location
   - يتحقق من Zone بعد الحصول على الموقع

2. **`getAddressFromGeocode(LatLng latLng)`**
   - يحول LatLng إلى عنوان نصي (Reverse Geocoding)
   - يستخدم Google Geocoding API
   - لديه cache لمنع API calls متكررة

3. **`getZone(String? lat, String? lng, ...)`**
   - يتحقق من Zone للموقع المحدد
   - يستدعي `/api/v1/config/get-zone-id`
   - يرجع `ZoneResponseModel` (inside/outside)

4. **`fetchZonePolygons({bool forceRefresh = false})`**
   - يجلب كل الـ zones من `/api/v1/zone/list`
   - يبني `Polygon` objects للرسم على الخريطة
   - لديه cache و guards لمنع rebuild متكرر
   - **مهم:** يستخدم `forceRefresh: true` في المرة الأولى

5. **`buildZonePolygons(List<ZoneDataModel> zonesList)`**
   - يحول `ZoneDataModel` إلى `Set<Polygon>` للرسم
   - يرسم كل zone بلون أخضر
   - يدعم multiple zones (Zone-agnostic)

6. **`isInsideAnyZone(LatLng point)`**
   - يتحقق إذا كان النقطة داخل أي zone
   - يستخدم Ray Casting Algorithm
   - يرجع `true` إذا داخل أي zone

7. **`findNearestAllowedPoint(LatLng point)`**
   - يجد أقرب نقطة داخل أي zone
   - يستخدم لحساب أقرب نقطة للتحويل التلقائي

8. **`validateZone(LatLng point)`**
   - يتحقق من Zone Status
   - يحدث `_zoneStatus` و `_nearestAllowedPoint`
   - يرجع `ZoneStatus.inside` أو `ZoneStatus.outside`

#### State Variables:

- `_position` - الموقع الحالي
- `_pickPosition` - الموقع المختار على الخريطة
- `_zones` - قائمة الـ zones
- `_zonePolygons` - Polygons للرسم
- `_zoneStatus` - حالة Zone (inside/outside)
- `_nearestAllowedPoint` - أقرب نقطة داخل zone
- `_isRedirecting` - Guard لمنع redirect loops
- `_zonesLoaded` - Flag يشير أن zones تم تحميلها

---

## 🖥️ Screens (شاشات UI)

### 1. `access_location_screen.dart` (1665 سطر)

**الوظيفة:** الشاشة الرئيسية لاختيار الموقع

**المسؤوليات:**
- عرض قائمة العناوين المحفوظة
- عرض خريطة صغيرة (mini-map) مع green zones
- السماح باختيار "Current Location" أو "Saved Addresses"
- Auto-move camera عند الخروج من zone
- تحميل zones أولاً (`forceRefresh: true`)

**الأحداث المهمة:**
- `initState()` - يحمل zones أولاً، ثم الموقع
- `_getCurrentLocation()` - يجلب GPS location أولاً
- `onCameraIdle` - يتحقق من Zone ويحرك الكاميرا إذا خارج

---

### 2. `pick_map_screen.dart` (865 سطر)

**الوظيفة:** شاشة اختيار الموقع على الخريطة الكاملة

**المسؤوليات:**
- عرض خريطة كاملة مع pin قابل للسحب
- عرض green zones على الخريطة
- البحث عن موقع (SearchLocationWidget)
- التحقق من Zone عند اختيار موقع
- حفظ العنوان المختار

**الأحداث المهمة:**
- `onCameraIdle` - يتحقق من Zone عند توقف الكاميرا
- `onPicked` - يحفظ العنوان المختار

---

### 3. `map_screen.dart` (502 سطر)

**الوظيفة:** عرض خريطة لعنوان محدد (للعرض فقط)

**المسؤوليات:**
- عرض خريطة مع marker للعنوان
- عرض معلومات العنوان
- فتح Google Maps عند الضغط على العنوان

---

### 4. `web_landing_page.dart` (681 سطر)

**الوظيفة:** صفحة Landing للـ Web

**المسؤوليات:**
- عرض قائمة Modules (Food, Grocery, etc.)
- البحث عن موقع
- اختيار Module
- Navigation للشاشات التالية

---

### 5. `my_Location.dart`

**الوظيفة:** شاشة اختيار الموقع (نسخة بديلة)

---

## 📦 Domain Layer

### Models (نماذج البيانات)

#### `zone_data_model.dart`
- `ZoneDataModel` - نموذج Zone كامل
- `FormatedCoordinates` - إحداثيات Zone (lat, lng)
- `Coordinates` - إحداثيات بديلة (legacy)

**الحقول المهمة:**
- `id` - Zone ID
- `name` - اسم Zone
- `formatedCoordinates` - **مهم جداً** - إحداثيات Polygon
- `status` - حالة Zone (1 = active)

#### `zone_response_model.dart`
- `ZoneResponseModel` - Response من `/api/v1/config/get-zone-id`
- `ZoneData` - بيانات Zone
- `metadata` - توجيهات من Backend (should_redirect, requires_zones_loaded)

#### `zone_model.dart`
- `ZoneModel` - نموذج Zone من app-init cache

#### `prediction_model.dart`
- `PredictionModel` - نتائج البحث عن موقع

---

### Repositories (API Calls)

#### `location_repository.dart`

**الوظائف:**

1. **`getZone(String? lat, String? lng)`**
   - يستدعي `/api/v1/config/get-zone-id?lat=...&lng=...`
   - لديه cache (30 دقيقة)
   - يرجع `ZoneResponseModel`

2. **`getAllZones()`**
   - يستدعي `/api/v1/zone/list`
   - **مهم:** لا يستخدم app-init cache (لا يحتوي على formated_coordinates)
   - يستخدم SharedPreferences cache فقط إذا كان يحتوي على coordinates
   - يرجع `List<ZoneDataModel>`

3. **`getAddressFromGeocode(LatLng latLng)`**
   - يستدعي Google Geocoding API
   - يحول LatLng إلى عنوان نصي

4. **`searchLocation(String text)`**
   - يستدعي Google Places API
   - يبحث عن مواقع بناءً على نص

---

### Services (Service Layer)

#### `location_service.dart`

**الوظائف:**

1. **`getPosition(...)`**
   - يجلب GPS position
   - يتحقق من المسافة من service area
   - لديه timeout (15 ثانية)

2. **`authorizeNavigation(...)`**
   - يتحقق من العناوين
   - يوجه للشاشة المناسبة

3. **`checkLocationPermission(...)`**
   - يتحقق من صلاحيات الموقع
   - يطلب الصلاحيات إذا لزم الأمر

---

## 🧩 Widgets (Widgets قابلة لإعادة الاستخدام)

1. **`serach_location_widget.dart`** - حقل بحث عن موقع
2. **`permission_dialog_widget.dart`** - Dialog لطلب صلاحيات الموقع
3. **`module_dialog_widget.dart`** - Dialog لاختيار Module
4. **`landing_card_widget.dart`** - Card للـ Landing Page
5. **`registration_card_widget.dart`** - Card للتسجيل
6. **`location_search_dialog_widget.dart`** - Dialog للبحث عن موقع
7. **`web_landing_page_shimmer_widget.dart`** - Shimmer loading للـ Landing
8. **`dynamic_text_color.dart`** - Widget لتغيير لون النص ديناميكياً

---

## 🔄 Flow Diagram

### Flow عند فتح AccessLocationScreen:

```
1. initState()
   ↓
2. fetchZonePolygons(forceRefresh: true)
   ↓
3. getAllZones() → API call
   ↓
4. buildZonePolygons() → Create Polygons
   ↓
5. _getCurrentLocation() → GPS first
   ↓
6. getZone() → Validate zone
   ↓
7. If outside → Auto-move camera
```

---

## 🎯 النقاط المهمة للتعديل

### إذا بدك تعدل على:

1. **تحميل Zones:**
   - `location_controller.dart` → `fetchZonePolygons()`
   - `location_repository.dart` → `getAllZones()`

2. **رسم Polygons:**
   - `location_controller.dart` → `buildZonePolygons()`

3. **Zone Validation:**
   - `location_controller.dart` → `validateZone()`, `isInsideAnyZone()`

4. **Auto-move Camera:**
   - `access_location_screen.dart` → `onCameraIdle`

5. **GPS Location:**
   - `access_location_screen.dart` → `_getCurrentLocation()`
   - `location_controller.dart` → `getCurrentLocation()`

---

## 📝 ملاحظات مهمة

1. **Cache Strategy:**
   - Zones: SharedPreferences (30 دقيقة)
   - Geocode: In-memory cache (5 دقائق)
   - Zone validation: Hive + SharedPreferences

2. **Guards:**
   - `_isRedirecting` - يمنع redirect loops
   - `_isAutoMoving` - يمنع auto-move loops
   - `_zonesLoaded` - يمنع validation قبل تحميل zones

3. **Performance:**
   - Polygons تُبنى في isolate
   - Debounce للـ camera events
   - Cache للـ geocode calls

---

**Last Updated:** 2024-01-XX

