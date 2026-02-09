# 🛡️ Mouse Tracker Assertion Fix

## 🔴 المشكلة

```
Failed assertion: '!_debugDuringDeviceUpdate'
package:flutter/src/rendering/mouse_tracker.dart:199
```

**السبب:**
Flutter يحدث Mouse/Pointer state وبنفس اللحظة يصير rebuild/setState/navigation → Flutter يقول: "ستوب ✋"

**يظهر غالبًا على:**
- Web
- Desktop
- Emulator مع mouse simulation
- نادر جدًا على موبايل production

---

## ✅ الحلول المطبقة

### 1️⃣ Fix في `map_screen.dart`

**المشكلة:**
```dart
MouseRegion(
  onEnter: (event) => onEntered(true),  // ❌ setState مباشرة
  onExit: (event) => onEntered(false),  // ❌ setState مباشرة
)
```

**الحل:**
```dart
MouseRegion(
  onEnter: (event) {
    // 🔥 FIX: Defer setState to prevent mouse_tracker assertion error
    Future.microtask(() => onEntered(true));
  },
  onExit: (event) {
    // 🔥 FIX: Defer setState to prevent mouse_tracker assertion error
    Future.microtask(() => onEntered(false));
  },
)
```

**وفي `onEntered`:**
```dart
void onEntered(bool isHovered) {
  // 🔥 FIX: Use Future.microtask to prevent setState during mouse tracking
  Future.microtask(() {
    if (mounted) {
      setState(() {
        this.isHovered = isHovered;
      });
    }
  });
}
```

---

### 2️⃣ Fix في `web_landing_page.dart`

**المشكلة:**
```dart
MouseRegion(
  onEnter: (_) => splashController.setHover(index, true),   // ❌ update() مباشرة
  onExit: (_) => splashController.setHover(index, false),   // ❌ update() مباشرة
)
```

**الحل:**
```dart
MouseRegion(
  onEnter: (_) {
    // 🔥 FIX: Defer setState to prevent mouse_tracker assertion error
    Future.microtask(() => splashController.setHover(index, true));
  },
  onExit: (_) {
    // 🔥 FIX: Defer setState to prevent mouse_tracker assertion error
    Future.microtask(() => splashController.setHover(index, false));
  },
)
```

---

### 3️⃣ Fix في `splash_controller.dart`

**المشكلة:**
```dart
void setHover(int index, bool state) {
  hoverStates[index] = state;
  update();  // ❌ update() مباشرة
}
```

**الحل:**
```dart
void setHover(int index, bool state) {
  hoverStates[index] = state;
  // 🔥 FIX: Use Future.microtask to prevent setState during mouse tracking
  Future.microtask(() => update());
}
```

---

## 📊 القاعدة الذهبية

### ❌ ممنوع

```dart
MouseRegion(
  onEnter: (_) => controller.update(),        // ❌
  onEnter: (_) => setState(() {}),           // ❌
  onEnter: (_) => Get.toNamed('/home'),      // ❌
)
```

### ✅ مسموح

```dart
MouseRegion(
  onEnter: (_) {
    Future.microtask(() => controller.update());  // ✅
  },
  onEnter: (_) {
    Future.microtask(() {
      if (mounted) {
        setState(() {});  // ✅
      }
    });
  },
  onEnter: (_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed('/home');  // ✅
    });
  },
)
```

---

## 🎯 متى تستخدم Future.microtask vs addPostFrameCallback?

### Future.microtask
- ✅ للـ setState/update في callbacks
- ✅ للـ mouse events
- ✅ للـ gesture events
- ✅ سريع (microtask queue)

### addPostFrameCallback
- ✅ للـ navigation
- ✅ للـ dialogs
- ✅ للـ operations بعد build
- ✅ أبطأ قليلاً (بعد frame)

---

## 🧪 Testing

بعد التعديلات:

1. ✅ Test على Web
2. ✅ Test على Desktop
3. ✅ Test على Emulator
4. ✅ Test hover events
5. ✅ Test mouse enter/exit

**Expected:**
- ❌ لا `Failed assertion: '!_debugDuringDeviceUpdate'`
- ✅ Smooth hover animations
- ✅ No crashes

---

## 📝 Notes

- **User interactions (onTap, onChanged):** عادية - لا تحتاج Future.microtask
- **Mouse events (onEnter, onExit, onHover):** تحتاج Future.microtask
- **Navigation:** تحتاج addPostFrameCallback
- **Build method:** ممنوع أي setState/update/navigation

---

**Last Updated:** 2024-01-XX

