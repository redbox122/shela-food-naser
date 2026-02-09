# 🔧 Google Maps Setup & Troubleshooting Guide

## 🔴 المشكلة الحالية

**الأعراض:**
- ❌ Google Map لا تظهر (تبقى Spinner للأبد)
- ❌ لا توجد أخطاء في Console
- ✅ الكود والمنطق صحيح
- ✅ `_mapReady = true` و `_cameraPosition` موجودة

**السبب المحتمل:**
المشكلة من إعدادات Google Maps Platform (API Key / SDK) وليست من الكود.

---

## ✅ Checklist سريع

- [ ] `google_maps_flutter` موجود في `pubspec.yaml`
- [ ] API Key موجود في `AndroidManifest.xml` داخل `<application>`
- [ ] **Maps SDK for Android** مفعّل في Google Cloud Console
- [ ] SHA-1 مضاف في API Key restrictions (لو فيه restrictions)
- [ ] Package name مطابق: `com.food.shala`
- [ ] Clean + Restart تم

---

## 📋 الخطوات التفصيلية

### 1️⃣ التحقق من Dependencies

**الملف:** `pubspec.yaml`

```yaml
dependencies:
  google_maps_flutter: ^2.9.0  # ✅ موجود
```

**إذا غير موجود:**
```bash
flutter pub add google_maps_flutter
flutter pub get
```

---

### 2️⃣ التحقق من AndroidManifest.xml

**الملف:** `android/app/src/main/AndroidManifest.xml`

**المكان الصحيح:** داخل `<application>` tag

```xml
<application ...>
    <!-- ✅ هذا المكان الصحيح -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8"/>
    
    <!-- باقي الكود -->
</application>
```

**⚠️ أخطاء شائعة:**
- ❌ وضع API Key خارج `<application>`
- ❌ وضع API Key في `debug/AndroidManifest.xml` فقط
- ❌ استخدام `com.google.android.maps.v2.API_KEY` (قديم)

**✅ الحل:**
- تأكد أن API Key داخل `<application>` tag
- تأكد أن الملف هو `android/app/src/main/AndroidManifest.xml` (ليس debug)

---

### 3️⃣ تفعيل Maps SDK for Android (الأهم!)

**هذا هو السبب الأكثر شيوعًا للمشكلة!**

#### الخطوات:

1. **افتح Google Cloud Console:**
   - https://console.cloud.google.com/

2. **اختر المشروع الصحيح:**
   - تأكد أنك في المشروع الذي يحتوي على API Key

3. **اذهب إلى APIs & Services → Library:**
   - من القائمة الجانبية: `APIs & Services` → `Library`

4. **ابحث عن "Maps SDK for Android":**
   - في شريط البحث: اكتب `Maps SDK for Android`

5. **فعّل API:**
   - اضغط على `Maps SDK for Android`
   - اضغط `ENABLE` (أو `تفعيل`)

6. **تأكد من تفعيل APIs الأخرى (اختياري لكن مفيد):**
   - ✅ **Maps SDK for Android** (مطلوب)
   - ✅ **Geocoding API** (للعناوين)
   - ✅ **Places API** (للبحث)

**⚠️ بدون Maps SDK for Android → الخريطة تبقى بيضا للأبد!**

---

### 4️⃣ التحقق من API Key Restrictions

**إذا كان API Key فيه restrictions، تأكد من:**

#### Application Restrictions:

1. **اذهب إلى:** APIs & Services → Credentials
2. **اضغط على API Key:** `AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8`
3. **تحقق من Application restrictions:**

**إذا كان "Android apps":**
- ✅ Package name: `com.food.shala`
- ✅ SHA-1 certificate fingerprint: (يجب أن يكون مضاف)

**إذا كان "None":**
- ✅ لا توجد مشكلة من ناحية Application restrictions

#### API Restrictions:

**تأكد من أن API Key مسموح له استخدام:**
- ✅ Maps SDK for Android
- ✅ Geocoding API
- ✅ Places API (إذا مستخدم)

---

### 5️⃣ الحصول على SHA-1 Certificate Fingerprint

**للتطبيقات الموقّعة (Release):**

```bash
cd android
./gradlew signingReport
```

**ابحث عن:**
```
Variant: release
Config: release
Store: /path/to/keystore
Alias: your-key-alias
Valid until: ...
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**للتطبيقات غير الموقّعة (Debug):**

```bash
cd android
./gradlew signingReport
```

**ابحث عن:**
```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**أو:**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**أضف SHA-1 في Google Cloud Console:**
1. APIs & Services → Credentials
2. اضغط على API Key
3. في "Application restrictions" → "Android apps"
4. اضغط "Add an item"
5. أضف Package name: `com.food.shala`
6. أضف SHA-1 certificate fingerprint

---

### 6️⃣ اختبار بدون Restrictions (مؤقت)

**للتأكد من أن المشكلة من Restrictions:**

1. **في Google Cloud Console:**
   - APIs & Services → Credentials
   - اضغط على API Key
   - في "Application restrictions" → اختر "None"
   - احفظ

2. **شغّل التطبيق:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **إذا ظهرت الخريطة:**
   - ✅ المشكلة 100% من Restrictions
   - أعد Restrictions وأضف SHA-1 بشكل صحيح

4. **إذا لم تظهر:**
   - ❌ المشكلة من Maps SDK for Android غير مفعّل
   - راجع الخطوة 3

---

### 7️⃣ Clean & Rebuild

**بعد أي تغيير في AndroidManifest.xml أو build.gradle:**

```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

---

## 🧪 اختبار بسيط

**أضف هذا مؤقتًا في `AccessLocationScreen`:**

```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: const LatLng(24.7136, 46.6753),
    zoom: 14,
  ),
  onMapCreated: (controller) {
    debugPrint('✅ Map created successfully!');
  },
)
```

**إذا:**
- ❌ **ما ظهرت** → المشكلة من API Key / SDK
- ✅ **ظهرت** → المشكلة من منطق الكود (لكن هذا مستبعد)

---

## 🔍 إشارات من Logcat

**افتح Logcat في Android Studio:**

```bash
adb logcat | grep -i "maps\|google\|api"
```

**ابحث عن:**
- ❌ `API key not valid` → API Key غير صحيح
- ❌ `Maps SDK not enabled` → Maps SDK for Android غير مفعّل
- ❌ `SHA-1 mismatch` → SHA-1 غير مطابق
- ✅ `Map initialized` → كل شيء صحيح

---

## 📱 Package Name التحقق

**تأكد من Package Name في:**

1. **AndroidManifest.xml:**
   ```xml
   <manifest package="com.food.shala">
   ```

2. **build.gradle:**
   ```gradle
   applicationId "com.food.shala"
   ```

3. **Google Cloud Console:**
   - في API Key restrictions → Package name: `com.food.shala`

**يجب أن تكون متطابقة!**

---

## 🚨 حلول سريعة

### المشكلة: Spinner دائم

**الحل:**
1. ✅ فعّل Maps SDK for Android
2. ✅ أضف SHA-1 في API Key restrictions
3. ✅ Clean & Rebuild

### المشكلة: "API key not valid"

**الحل:**
1. ✅ تحقق من API Key في AndroidManifest.xml
2. ✅ تحقق من API Key في Google Cloud Console
3. ✅ تأكد من أن API Key مسموح له استخدام Maps SDK for Android

### المشكلة: "SHA-1 mismatch"

**الحل:**
1. ✅ احصل على SHA-1 من `./gradlew signingReport`
2. ✅ أضف SHA-1 في Google Cloud Console
3. ✅ تأكد من Package name مطابق

---

## 📞 الخطوة التالية

**إذا لم تحل المشكلة:**

1. **أرسل Screenshot من:**
   - Google Cloud Console → APIs & Services → Enabled APIs
   - Google Cloud Console → Credentials → API Key → Application restrictions
   - Logcat output

2. **أرسل:**
   - Package name من `build.gradle`
   - SHA-1 من `./gradlew signingReport`

---

## ✅ Checklist نهائي

- [ ] `google_maps_flutter` موجود في `pubspec.yaml`
- [ ] API Key موجود في `AndroidManifest.xml` داخل `<application>`
- [ ] **Maps SDK for Android** مفعّل في Google Cloud Console
- [ ] SHA-1 مضاف في API Key restrictions (لو فيه restrictions)
- [ ] Package name مطابق: `com.food.shala`
- [ ] Clean + Restart تم
- [ ] Logcat لا يظهر أخطاء

---

## 📚 مراجع

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Maps SDK for Android Setup](https://developers.google.com/maps/documentation/android-sdk/start)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)

---

**آخر تحديث:** 2025-01-27

