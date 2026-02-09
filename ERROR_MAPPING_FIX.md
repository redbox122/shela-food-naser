# 🔴 إصلاح Error Mapping - المشكلة الحقيقية

## المشكلة المكتشفة

> **الرسالة "المتجر مغلق" التي تظهر ليست ناتجة عن شرط المتجر نفسه، بل هي رسالة مُعاد استخدامها (mapped) لخطأ آخر، والـ UI عم يترجمها غلط.**

### الدليل

من الـ logs:
```text
🏪 STORE STATUS CHECK →
isOpenNow=true,
active=true,
scheduleOrder=false,
isOpen=true
```

**المتجر مفتوح 100%** - لكن الرسالة تظهر "المتجر مغلق"!

---

## السبب الحقيقي

### الحالة 1️⃣: Backend يرجّع error عام → Flutter يترجمه "المتجر مغلق"

**قبل الإصلاح**:
```dart
if (response.statusCode != 200) {
  showCustomSnackBar('store_is_closed'.tr); // ❌ أي خطأ → نفس الرسالة
}
```

### الحالة 2️⃣: errorCode غلط أو مفقود → fallback خاطئ

**قبل الإصلاح**:
```dart
if (errorCode == null) {
  showCustomSnackBar('store_is_closed'.tr); // ❌ fallback خاطئ
}
```

**النتيجة**:
- ❌ فشل validation → "المتجر مغلق"
- ❌ فشل payment → "المتجر مغلق"
- ❌ فشل wallet → "المتجر مغلق"
- ❌ أي خطأ → "المتجر مغلق" 🤦‍♂️

---

## ✅ الحل المطبق

### 1️⃣ Error Mapping الصحيح

**الموقع**: `lib/features/checkout/controllers/checkout_controller.dart:1275-1332`

```dart
// 🧪 DEBUG: عرض الخطأ الحقيقي (مؤقت للتشخيص)
String? realErrorCode;
String? realErrorMessage;
if (response.body != null && response.body is Map<String, dynamic>) {
  final errorBody = response.body as Map<String, dynamic>;
  realErrorCode = errorBody['code']?.toString();
  realErrorMessage = errorBody['message']?.toString() ?? 
                   errorBody['error']?.toString() ??
                   errorBody['error_message']?.toString();
} else if (response.body != null && response.body is String) {
  realErrorMessage = response.body.toString();
}

debugPrint('🔍 DEBUG → Error Code: ${realErrorCode ?? "NULL"}');
debugPrint('🔍 DEBUG → Error Message: ${realErrorMessage ?? response.statusText ?? "UNKNOWN"}');

// ✅ Error Mapping الصحيح - لا نستخدم "المتجر مغلق" إلا للخطأ الحقيقي
if (realErrorCode != null) {
  switch (realErrorCode) {
    case 'STORE_CLOSED':
    case 'STORE_NOT_OPEN':
      errorMessage = 'store_is_closed'.tr; // ✅ فقط هنا!
      break;
    case 'VALIDATION_ERROR':
    case 'CONTACT_NAME_REQUIRED':
    case 'CONTACT_NUMBER_REQUIRED':
      errorMessage = realErrorMessage ?? 'يرجى التحقق من البيانات المدخلة';
      break;
    case 'PAYMENT_FAILED':
    case 'PAYMENT_METHOD_REQUIRED':
      errorMessage = realErrorMessage ?? 'فشل في معالجة الدفع';
      break;
    case 'INSUFFICIENT_BALANCE':
      errorMessage = realErrorMessage ?? 'الرصيد غير كافي';
      break;
    default:
      errorMessage = realErrorMessage ?? 'فشل في إنشاء الطلب';
  }
} else {
  // إذا لم يكن هناك error code، استخدم الرسالة الحقيقية
  errorMessage = realErrorMessage ?? 
                response.statusText ?? 
                'فشل في إنشاء الطلب';
}
```

---

## 🧪 Debug Logging (مؤقت)

تم إضافة debug logging لعرض الخطأ الحقيقي:

```dart
debugPrint('🔍 DEBUG → Error Code: ${realErrorCode ?? "NULL"}');
debugPrint('🔍 DEBUG → Error Message: ${realErrorMessage ?? response.statusText ?? "UNKNOWN"}');
debugPrint('🔍 DEBUG → Final Message: $errorMessage');
```

**الاستخدام**:
عند حدوث خطأ، ستظهر في console:
- Error Code الحقيقي
- Error Message الحقيقي
- الرسالة النهائية المعروضة

---

## 📋 Error Codes المدعومة

| Error Code | الرسالة المعروضة |
|------------|------------------|
| `STORE_CLOSED` | "المتجر مغلق" |
| `STORE_NOT_OPEN` | "المتجر مغلق" |
| `VALIDATION_ERROR` | الرسالة الحقيقية من Backend |
| `CONTACT_NAME_REQUIRED` | "يرجى التحقق من البيانات المدخلة" |
| `CONTACT_NUMBER_REQUIRED` | "يرجى التحقق من البيانات المدخلة" |
| `PAYMENT_FAILED` | "فشل في معالجة الدفع" |
| `PAYMENT_METHOD_REQUIRED` | "فشل في معالجة الدفع" |
| `INSUFFICIENT_BALANCE` | "الرصيد غير كافي" |
| `default` | الرسالة الحقيقية من Backend |

---

## 🎯 النتيجة

### قبل الإصلاح:
- ❌ أي خطأ → "المتجر مغلق"
- ❌ لا يمكن معرفة الخطأ الحقيقي
- ❌ UX سيء

### بعد الإصلاح:
- ✅ كل خطأ له رسالته الخاصة
- ✅ "المتجر مغلق" فقط عند `STORE_CLOSED` أو `STORE_NOT_OPEN`
- ✅ Debug logging يوضح الخطأ الحقيقي
- ✅ UX أفضل

---

## 🔍 كيفية التشخيص

عند حدوث خطأ، ابحث في console عن:

```
🔍 DEBUG → Error Code: ...
🔍 DEBUG → Error Message: ...
🔍 DEBUG → Final Message: ...
```

هذا سيخبرك بالخطأ الحقيقي!

---

## 📝 ملاحظات

1. **Debug Logging مؤقت**: يمكن إزالته بعد التأكد من أن كل شيء يعمل
2. **Error Codes**: إذا كان Backend يستخدم error codes مختلفة، أضفها في `switch` statement
3. **Fallback**: إذا لم يكن هناك error code، يتم استخدام الرسالة الحقيقية من Backend

---

## ✅ الخلاصة

- ❌ المتجر **ليس** مغلق
- ❌ الشرط **ليس** غلط
- ❌ الحساب الزمني **ليس** المشكلة
- ✅ المشكلة: **رسالة واحدة مستخدمة لكل الأخطاء**
- ✅ الحل: **Error Mapping صحيح لكل نوع خطأ**

