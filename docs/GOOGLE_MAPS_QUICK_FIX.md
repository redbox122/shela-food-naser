# 🚀 Google Maps Quick Fix

## المشكلة
Google Map لا تظهر (تبقى Spinner للأبد)

## الحل السريع (5 دقائق)

### 1️⃣ فعّل Maps SDK for Android (الأهم!)

1. افتح: https://console.cloud.google.com/
2. APIs & Services → Library
3. ابحث: `Maps SDK for Android`
4. اضغط: **ENABLE** ✅

**هذا هو السبب الأكثر شيوعًا!**

---

### 2️⃣ أضف SHA-1 في API Key Restrictions

**احصل على SHA-1:**
```bash
cd android
./gradlew signingReport
```

**ابحث عن:**
```
SHA1: XX:XX:XX:...
```

**أضف في Google Cloud Console:**
1. APIs & Services → Credentials
2. اضغط على API Key: `AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8`
3. Application restrictions → Android apps
4. Package name: `com.food.shala`
5. SHA-1: (الصق القيمة من signingReport)
6. Save

---

### 3️⃣ Clean & Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ Checklist

- [ ] Maps SDK for Android مفعّل
- [ ] SHA-1 مضاف في API Key restrictions
- [ ] Package name: `com.food.shala`
- [ ] Clean + Rebuild تم

---

## 🆘 إذا لم تحل المشكلة

راجع: `docs/GOOGLE_MAPS_SETUP_TROUBLESHOOTING.md`

