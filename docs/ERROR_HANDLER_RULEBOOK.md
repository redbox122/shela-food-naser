# 🎯 ErrorHandler Rulebook

## متى نستخدم ErrorHandler في Controllers؟

### ✅ DO: استخدم ErrorHandler عندما:

1. **API Calls** - أي استدعاء API من Controller
   ```dart
   try {
     data = await repository.getData();
   } catch (e, s) {
     ErrorHandler().handleError(e, context: 'ControllerName.methodName', showSnackbar: false);
   }
   ```

2. **Critical Operations** - عمليات مهمة قد تفشل
   ```dart
   try {
     await saveToCache(data);
   } catch (e, s) {
     ErrorHandler().handleError(e, context: 'ControllerName.saveToCache');
   }
   ```

3. **External Dependencies** - أي اعتماد على خدمات خارجية
   ```dart
   try {
     await thirdPartyService.call();
   } catch (e, s) {
     ErrorHandler().handleError(e, context: 'ControllerName.thirdPartyCall');
   }
   ```

---

### ❌ DON'T: لا تستخدم ErrorHandler عندما:

1. **Silent Failures** - أخطاء صامتة متوقعة
   ```dart
   // ❌ لا تستخدم ErrorHandler هنا
   try {
     optionalData = await getOptionalData();
   } catch (e) {
     // Silent fail - expected
     return null;
   }
   ```

2. **UI-only Errors** - أخطاء UI فقط (مثل validation)
   ```dart
   // ❌ لا تستخدم ErrorHandler هنا
   if (input.isEmpty) {
     showSnackBar('Input is required');
     return;
   }
   ```

3. **Expected Business Logic Failures** - فشل منطقي متوقع
   ```dart
   // ❌ لا تستخدم ErrorHandler هنا
   if (balance < amount) {
     return 'Insufficient balance'; // Expected business logic
   }
   ```

---

## 🎯 Pilot Phase Rules (المرحلة الحالية)

### القواعد الأساسية:

1. **Logging Only** - لا UI changes
   ```dart
   ErrorHandler().handleError(
     e,
     context: 'ControllerName.methodName',
     showSnackbar: false, // ✅ Always false in pilot
     logError: true,
   );
   ```

2. **Preserve Behavior** - لا تغير السلوك الحالي
   ```dart
   // ✅ Preserve existing behavior
   catch (e, s) {
     ErrorHandler().handleError(e, context: '...', showSnackbar: false);
     // Keep existing error handling logic
     return null; // or throw, or whatever was there before
   }
   ```

3. **Context Always** - دائماً أضف context
   ```dart
   // ✅ Good
   ErrorHandler().handleError(e, context: 'CategoryController.getCategoryList');
   
   // ❌ Bad
   ErrorHandler().handleError(e);
   ```

---

## 📊 ErrorHandler Usage Matrix

| Scenario | Use ErrorHandler? | showSnackbar | Notes |
|----------|------------------|--------------|-------|
| API Call | ✅ Yes | false (pilot) | Log and preserve behavior |
| Cache Read | ✅ Yes | false | Log but don't break app |
| Validation | ❌ No | - | Use UI feedback only |
| Business Logic | ❌ No | - | Expected failures |
| Network Error | ✅ Yes | false (pilot) | Log for debugging |
| Silent Fail | ❌ No | - | Expected behavior |

---

## 🔄 Migration Path

### Phase 1: Pilot (Current)
- ✅ CategoryController only
- ✅ Logging only (no UI)
- ✅ Preserve all behavior

### Phase 2: Expansion (After Testing)
- Add StoreController
- Add BannerController
- Still no UI changes

### Phase 3: UI Integration (Future)
- Add user-friendly error messages
- Add retry mechanisms
- Add error states in UI

---

## 🧪 Testing Checklist

قبل إضافة ErrorHandler إلى Controller جديد:

- [ ] Controller يعمل بشكل طبيعي
- [ ] ErrorHandler لا يغير السلوك
- [ ] Logs تظهر بشكل صحيح
- [ ] No crashes عند الأخطاء
- [ ] UI لا يتأثر

---

## 📝 Code Template

```dart
// ✅ Standard ErrorHandler usage in Controllers
try {
  // Your code here
  data = await repository.getData();
} catch (e, stackTrace) {
  // 🎯 ERROR HANDLER PILOT: Use unified error handling (logging only, no UI changes)
  ErrorHandler().handleError(
    e,
    context: 'ControllerName.methodName',
    showSnackbar: false, // No UI changes in pilot phase
    logError: true,
  );
  // Preserve existing behavior
  return null; // or throw, or whatever was there before
}
```

---

**آخر تحديث:** 2024
**المرحلة:** Pilot (CategoryController only)

