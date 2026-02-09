# تحليل دالة placeOrder() وزر الدفع

## 📍 الملفات الرئيسية

- **CheckoutController**: `lib/features/checkout/controllers/checkout_controller.dart`
- **CheckoutRepository**: `lib/features/checkout/domain/repositories/checkout_repository.dart`
- **CheckoutScreen**: `lib/features/checkout/screens/checkout_screen.dart`
- **PlaceOrderBodyModel**: `lib/features/checkout/domain/models/place_order_body_model.dart`

---

## 1️⃣ دالة `placeOrder()` في CheckoutController

**الموقع**: `lib/features/checkout/controllers/checkout_controller.dart:1577-1609`

```dart
Future<String> placeOrder(
  context,
  KaidhaSubscription_Controller kaidhaSubController,
  ProfileController profile_Controller,
  PlaceOrderBodyModel placeOrderBody,
  int? zoneID,
  double amount,
  double? maximumCodOrderAmount,
  bool fromCart,
  bool isCashOnDeliveryActive,
  List<XFile>? orderAttachment, {
  bool isOfflinePay = false,
}) async {
  // Step 1: Create order (unpaid)
  final String orderID =
      await createOrder(context, placeOrderBody, orderAttachment);
  if (orderID.isEmpty) {
    return '';
  }

  // Step 2: Process payment
  return await processPayment(
    context,
    kaidhaSubController,
    profile_Controller,
    zoneID,
    maximumCodOrderAmount,
    fromCart,
    isCashOnDeliveryActive,
    placeOrderBody.contactPersonNumber,
    isOfflinePay: isOfflinePay,
  );
}
```

**ملاحظة**: هذه الدالة تستدعي `createOrder()` ثم `processPayment()`.

---

## 2️⃣ دالة `createOrder()` - التي تستدعي API

**الموقع**: `lib/features/checkout/controllers/checkout_controller.dart:1186-1270`

```dart
Future<String> createOrder(
  context,
  PlaceOrderBodyModel placeOrderBody,
  List<XFile>? orderAttachment,
) async {
  // CRITICAL: Reset payment state for new order
  resetPaymentState();

  _isLoading = true;
  update();

  String orderID = '';
  String userID = '';

  // ============================ تجهيز المرفقات ============================
  final List<MultipartBody> multiParts = [];
  if (orderAttachment != null) {
    for (final XFile file in orderAttachment) {
      multiParts.add(MultipartBody('order_attachment[]', file));
    }
  }

  debugPrint(
      '\x1B[32m📋 Creating Order (Unpaid) - Amount: ${placeOrderBody.orderAmount}\x1B[0m');

  try {
    // Create order with "unpaid" status first (REAL E-COMMERCE FLOW)
    final Response response =
        await checkoutServiceInterface.placeOrder(placeOrderBody, multiParts);

    if (response.statusCode == 200) {
      // 🔧 FIX: Use 'id' instead of 'order_id' (backend returns 'id' field)
      orderID =
          (response.body['id'] ?? response.body['order_id'] ?? '').toString();
      userID = response.body['user_id']?.toString() ?? '';

      debugPrint(
          '\x1B[32m✅ Order created successfully: $orderID (unpaid)\x1B[0m');
      debugPrint(
          "\x1B[32m💰 Amount: ${response.body['total_ammount']}\x1B[0m");
      debugPrint(
          "\x1B[32m📊 Status: ${response.body['status']} (unpaid)\x1B[0m");

      // Store order ID for later payment processing
      _currentOrderId = int.parse(orderID);
      _currentOrderAmount =
          double.tryParse(response.body['total_ammount'].toString()) ?? 0.0;

      _isLoading = false;
      update();
      return orderID;
    } else {
      _isLoading = false;
      update();

      // Log detailed error information for debugging
      debugPrint(
          '❌ Order creation failed with status: ${response.statusCode}');
      debugPrint('❌ Error response body: ${response.body}');
      debugPrint('❌ Error status text: ${response.statusText}');

      // Extract error message from response body
      String errorMessage = 'فشل في إنشاء الطلب';
      if (response.body != null && response.body is Map<String, dynamic>) {
        final errorBody = response.body as Map<String, dynamic>;
        if (errorBody.containsKey('message')) {
          errorMessage = errorBody['message'].toString();
        } else if (errorBody.containsKey('exception')) {
          errorMessage = "خطأ في الخادم: ${errorBody['exception']}";
        }
      } else if (response.body != null && response.body is String) {
        errorMessage = response.body.toString();
      }

      showCustomSnackBar(errorMessage);
      return '';
    }
  } catch (e) {
    _isLoading = false;
    update();
    debugPrint('خطأ أثناء إنشاء الطلب: $e');
    showCustomSnackBar('حدث خطأ أثناء إنشاء الطلب');
    return '';
  }
}
```

---

## 3️⃣ دالة `placeOrder()` في CheckoutRepository - ترسل Request

**الموقع**: `lib/features/checkout/domain/repositories/checkout_repository.dart:94-166`

```dart
Future<Response> placeOrder(PlaceOrderBodyModel orderBody, List<MultipartBody>? orderAttachment) async {
  final orderData = orderBody.toJson();

  debugPrint('\x1B[32m📦 placeOrder   rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr  :\x1B[0m');

  orderData.forEach((key, value) {
    debugPrint('\x1B[32m - $key: $value \x1B[0m');
  });

  // Get the best available token for checkout
  final String token = await _getCheckoutToken();
  
  if (token.isEmpty) {
    debugPrint('❌ No valid token available for checkout');
    return const Response(statusCode: 401, statusText: 'Unauthorized: No valid token');
  }
  
  // Log token info
  final tokenPrefix = token.length > 12 ? token.substring(0, 12) : token;
  final hasDot = token.contains('.');
  debugPrint('checkout token: $tokenPrefix..., hasDot=$hasDot');

  // Create headers following the documented API specification
  final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
  headers['Authorization'] = 'Bearer $token';
  headers['Content-Type'] = 'application/json; charset=UTF-8';
  headers['Accept'] = 'application/json';
  
  // Add required headers as per documentation
  if (orderBody.latitude != null) {
    headers['latitude'] = orderBody.latitude!;
  }
  if (orderBody.longitude != null) {
    headers['longitude'] = orderBody.longitude!;
  }
  
  // Add moduleId and zoneId headers as required by the API
  if (sharedPreferences.getString(AppConstants.cacheModuleId) != null) {
    try {
      final moduleId = ModuleModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.cacheModuleId)!) as Map<String, dynamic>).id;
      headers['moduleId'] = moduleId.toString();
    } catch (e) {
      // Fallback to default module ID
      headers['moduleId'] = '3';
    }
  } else {
    headers['moduleId'] = '3'; // Default module ID as per documentation
  }
  
  // Add zoneId header (this should be set by the API client)
  if (headers.containsKey(AppConstants.zoneId) && headers[AppConstants.zoneId]!.isNotEmpty) {
    // zoneId is already set by apiClient.getHeader()
  } else {
    // Fallback zoneId if not set
    headers[AppConstants.zoneId] = '[2,4,3,5]';
  }

  // Convert orderBody to proper JSON format for API
  final Map<String, dynamic> jsonBody = orderBody.toJsonForApi();
  
  // Log the complete request for debugging
  debugPrint('\x1B[33m🔍 Complete API Request:\x1B[0m');
  debugPrint('\x1B[33m - URL: ${AppConstants.placeOrderUri}\x1B[0m');
  debugPrint('\x1B[33m - Headers: $headers\x1B[0m');
  debugPrint('\x1B[33m - Body: $jsonBody\x1B[0m');

  return await apiClient.postData(
    AppConstants.placeOrderUri,
    jsonBody,
    headers: headers,
    handleError: false,
  );
}
```

**Endpoint**: `POST /api/v1/customer/order/place`

---

## 4️⃣ Request Body الكامل (من `toJsonForApi()`)

**الموقع**: `lib/features/checkout/domain/models/place_order_body_model.dart:302-383`

```dart
Map<String, dynamic> toJsonForApi() {
  final Map<String, dynamic> data = <String, dynamic>{};
  
  // Cart handling
  if (_cart != null && _cart!.isNotEmpty) {
    data['use_cart'] = true;
    // Note: cart array is commented out for backward compatibility
    // data['cart'] = _cart!.map((v) => v.toJson()).toList();
  }
  
  // Coupon
  if (_couponDiscountAmount != null) {
    data['coupon_discount_amount'] = _couponDiscountAmount;
  }
  if (_couponCode != null) {
    data['coupon_code'] = _couponCode;
  }
  
  // Order details
  data['order_amount'] = _orderAmount;
  data['order_type'] = _orderType;  // 'delivery' or 'take_away'
  data['payment_method'] = _paymentMethod;  // 'wallet_qidha', 'wallet', 'digital_payment', or null
  data['order_note'] = _orderNote ?? '';
  data['store_id'] = _storeId;
  data['distance'] = _distance;
  
  // Schedule
  if (_scheduleAt != null) {
    data['schedule_at'] = _scheduleAt;
  }
  
  // Pricing
  data['discount_amount'] = _discountAmount;
  data['tax_amount'] = _taxAmount;
  data['extra_packaging_amount'] = _extraPackagingAmount;
  
  // Address
  data['address'] = _address ?? '';
  data['latitude'] = _latitude ?? '';
  data['longitude'] = _longitude ?? '';
  data['address_type'] = _addressType ?? '';
  data['road'] = _streetNumber;
  data['house'] = _house;
  data['floor'] = _floor;
  
  // Contact
  data['contact_person_name'] = _contactPersonName;
  data['contact_person_number'] = _contactPersonNumber;
  
  // Zone
  if (_senderZoneId != null) {
    data['sender_zone_id'] = _senderZoneId;
  }
  
  // Parcel (if applicable)
  if (_parcelCategoryId != null) {
    data['parcel_category_id'] = _parcelCategoryId;
  }
  if (_chargePayer != null) {
    data['charge_payer'] = _chargePayer;
  }
  if (_receiverDetails != null) {
    data['receiver_details'] = _receiverDetails!.toJson();
  }
  
  // Delivery options
  data['dm_tips'] = _dmTips;
  data['delivery_instruction'] = _deliveryInstruction;
  data['unavailable_item_note'] = _unavailableItemNote;
  data['cutlery'] = _cutlery ?? 0;
  
  // Payment
  data['partial_payment'] = _partialPayment;
  
  // Guest
  data['guest_id'] = _guestId ?? 0;
  data['is_buy_now'] = _isBuyNow;
  // Note: contact_person_email is commented out (causes issues)
  
  // Guest account creation
  data['create_new_user'] = _createNewUser;
  if (_password != null) {
    data['password'] = _password;
  }
  
  // Removed fields (cause 500 errors):
  // - payment_confirmation
  // - wallet_qidha_status
  
  return data;
}
```

### مثال على Request Body الكامل:

```json
{
  "use_cart": true,
  "coupon_discount_amount": 0.0,
  "order_amount": 150.50,
  "order_type": "delivery",
  "payment_method": "wallet_qidha",
  "order_note": "",
  "store_id": 123,
  "distance": 5.2,
  "discount_amount": 10.0,
  "tax_amount": 15.0,
  "tax_amount": 15.0,
  "address": "شارع الملك فهد، الرياض",
  "latitude": "24.7136",
  "longitude": "46.6753",
  "address_type": "home",
  "road": "123",
  "house": "45",
  "floor": "2",
  "contact_person_name": "أحمد محمد",
  "contact_person_number": "0501234567",
  "dm_tips": "5.0",
  "delivery_instruction": "اتصل عند الوصول",
  "unavailable_item_note": "",
  "cutlery": 1,
  "partial_payment": 0,
  "guest_id": 0,
  "is_buy_now": 0,
  "extra_packaging_amount": 0.0,
  "create_new_user": 0
}
```

---

## 5️⃣ زر الدفع في UI - `_orderPlaceButton()`

**الموقع**: `lib/features/checkout/screens/checkout_screen.dart:1059-1896`

### البنية الأساسية:

```dart
Widget _orderPlaceButton(...) {
  return Container(
    child: CustomButton(
      isLoading: checkoutController.isLoading,
      buttonText: 'place_order'.tr,
      onPressed: checkoutController.acceptTerms
          ? () async {
              // ... جميع الشروط والتحقق ...
              // ... ثم استدعاء createOrder() و processPayment() ...
            }
          : null,
    ),
  );
}
```

### الشروط في `onPressed`:

#### ✅ 1. قبول الشروط
```dart
onPressed: checkoutController.acceptTerms ? () async { ... } : null
```

#### ✅ 2. حساب المسافة
```dart
if (checkoutController.distance == null) {
  showCustomSnackBar('أنتظر لحظات بيتم حساب التوصيل');
  return;
}
```

#### ✅ 3. التحقق من Guest Login
```dart
if (isGuestLogIn && checkoutController.guestAddress == null && 
    checkoutController.orderType != 'take_away') {
  showCustomSnackBar('please_setup_your_delivery_address_first'.tr);
}
// ... شروط أخرى للـ guest ...
```

#### ✅ 4. Prescription Required
```dart
else if (isPrescriptionRequired && 
         checkoutController.pickedPrescriptions.isEmpty) {
  showCustomSnackBar('you_must_upload_prescription_for_this_order'.tr);
}
```

#### ✅ 5. **طريقة الدفع - الشرط الرئيسي**
```dart
else if (checkoutController.paymentMethodIndex == -1) {
  // Show payment method selection popup
  if (ResponsiveHelper.isDesktop(context)) {
    Get.dialog(const Dialog(
      backgroundColor: Colors.transparent,
      child: PaymentMethodBottomSheet(),
    ));
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentMethodBottomSheet(),
    );
  }
  return; // Stop execution here
}
```

#### ✅ 6. **التحقق من قيدها مفعل**
```dart
else if (checkoutController.paymentMethodIndex == 0 &&
         checkoutController.isKaidhaPay == false) {
  // Show payment method selection popup
  // ... نفس الكود أعلاه ...
  return;
}
```

#### ✅ 7. شروط أخرى
- Minimum order amount
- Tips validation
- Store closed check
- COD maximum amount
- Time slots validation
- Product availability

### الكود الذي يستدعي `createOrder()` و `processPayment()`:

```dart
// بعد اجتياز جميع الشروط...

// بناء PlaceOrderBodyModel
final PlaceOrderBodyModel placeOrderBody = PlaceOrderBodyModel(
  cart: carts,
  couponDiscountAmount: Get.find<CouponController>().discount,
  distance: checkoutController.distance,
  scheduleAt: !checkoutController.store!.scheduleOrder!
      ? null
      : (checkoutController.selectedDateSlot == 0 &&
              checkoutController.selectedTimeSlot == 0)
          ? null
          : DateConverter.dateToDateAndTime(scheduleEndDate),
  orderAmount: total,
  orderNote: checkoutController.noteController.text,
  orderType: determinedOrderType,
  paymentMethod: finalPaymentMethod,  // 'wallet_qidha', 'wallet', 'digital_payment', or null
  couponCode: (Get.find<CouponController>().discount! > 0 ||
          (Get.find<CouponController>().coupon != null &&
              Get.find<CouponController>().freeDelivery))
      ? Get.find<CouponController>().coupon!.code
      : null,
  storeId: _cartList![0]!.item!.storeId,
  address: finalAddress!.address,
  latitude: finalAddress.latitude,
  longitude: finalAddress.longitude,
  senderZoneId: null,
  addressType: finalAddress.addressType,
  contactPersonName: finalAddress.contactPersonName ?? '...',
  contactPersonNumber: finalAddress.contactPersonNumber ?? '...',
  streetNumber: isGuestLogIn ? finalAddress.streetNumber ?? '' : ...,
  house: isGuestLogIn ? finalAddress.house ?? '' : ...,
  floor: isGuestLogIn ? finalAddress.floor ?? '' : ...,
  discountAmount: discount,
  taxAmount: tax,
  receiverDetails: null,
  parcelCategoryId: null,
  chargePayer: null,
  dmTips: (checkoutController.orderType == 'take_away' ||
          checkoutController.tipController.text == 'not_now')
      ? ''
      : checkoutController.tipController.text.trim(),
  cutlery: Get.find<CartController>().addCutlery ? 1 : 0,
  unavailableItemNote: Get.find<CartController>().notAvailableIndex != -1
      ? Get.find<CartController>().notAvailableList[...]
      : '',
  deliveryInstruction: checkoutController.selectedInstruction != -1
      ? AppConstants.deliveryInstructionList[...]
      : '',
  partialPayment: checkoutController.isPartialPay ? 1 : 0,
  guestId: isGuestLogIn ? int.parse(AuthHelper.getGuestId()) : 0,
  isBuyNow: widget.fromCart ? 0 : 1,
  guestEmail: isGuestLogIn ? finalAddress.email : ...,
  extraPackagingAmount: Get.find<CartController>().needExtraPackage
      ? checkoutController.store!.extraPackagingAmount
      : 0,
  createNewUser: checkoutController.isCreateAccount ? 1 : 0,
  password: guestPasswordController.text,
);

// Step 1: Create Order (Unpaid)
debugPrint('\x1B[32m📋 Step 1: Creating Order (Unpaid)...\x1B[0m');

final String orderID = await checkoutController.createOrder(
  context,
  placeOrderBody,
  checkoutController.pickedPrescriptions,
);

if (orderID.isEmpty) {
  showCustomSnackBar('فشل في إنشاء الطلب');
  return;  // ⚠️ هنا يتوقف التنفيذ
}

debugPrint('\x1B[32m✅ Order created successfully: $orderID (unpaid)\x1B[0m');

// Step 2: Process Payment Immediately with Selected Method
debugPrint('\x1B[32m💳 Step 2: Processing Payment with Selected Method...\x1B[0m');

final String paymentResult = await checkoutController.processPayment(
  context,
  Get.find<KaidhaSubscription_Controller>(),
  Get.find<ProfileController>(),
  checkoutController.store!.zoneId,
  maxCodOrderAmount,
  widget.fromCart,
  _isCashOnDeliveryActive!,
  finalAddress.contactPersonName ?? '',
);

if (paymentResult.isNotEmpty) {
  debugPrint('\x1B[32m✅ Payment processed successfully: $paymentResult\x1B[0m');
} else {
  debugPrint('\x1B[33m⚠️ Payment processing failed\x1B[0m');
}
```

---

## 6️⃣ ملخص كيف تسير الأمور حالياً

### Flow الحالي:

```
1. المستخدم يضغط زر "Place Order"
   ↓
2. التحقق من جميع الشروط:
   - acceptTerms ✓
   - distance != null ✓
   - paymentMethodIndex != -1 ✓ (إذا كان -1 يعرض popup)
   - paymentMethodIndex == 0 && isKaidhaPay == false ✓ (يعرض popup)
   - ... شروط أخرى ...
   ↓
3. بناء PlaceOrderBodyModel
   - paymentMethod: null (في هذه المرحلة!)
   ↓
4. استدعاء createOrder()
   - ترسل Request إلى API مع payment_method: null
   - API يرجع order_id
   ↓
5. إذا orderID.isEmpty → return (يتوقف)
   ↓
6. استدعاء processPayment()
   - تعالج الدفع حسب paymentMethodIndex
   - wallet_qidha, wallet, digital_payment, أو COD
   ↓
7. إذا نجح الدفع → callback() (يعرض success screen)
```

### ملاحظات مهمة:

1. **`paymentMethod` في Request Body**: 
   - يتم إرساله كـ `null` عند إنشاء الطلب
   - الدفع يتم لاحقاً عبر `processPayment()`

2. **لا يوجد `Get.back()` مباشرة**:
   - التنقل يتم عبر `callback()` في `processPayment()`

3. **التحقق من طريقة الدفع**:
   - `paymentMethodIndex == -1` → يعرض popup
   - `paymentMethodIndex == 0 && isKaidhaPay == false` → يعرض popup
   - لا يوجد `if(paymentMethod == null)` مباشر

4. **الـ Request Body**:
   - `payment_method` يُرسل كـ `null` أو كقيمة ('wallet_qidha', 'wallet', 'digital_payment')
   - `use_cart: true` بدلاً من إرسال cart array

5. **Headers**:
   - `Authorization: Bearer {token}`
   - `Content-Type: application/json; charset=UTF-8`
   - `Accept: application/json`
   - `latitude`, `longitude` (إذا متوفرة)
   - `moduleId` (default: '3')
   - `zoneId` (من apiClient.getHeader())

---

## 7️⃣ نقاط مهمة للتحليل

### ✅ ما يعمل حالياً:
- إنشاء الطلب مع `payment_method: null`
- معالجة الدفع لاحقاً عبر `processPayment()`
- التحقق من طريقة الدفع قبل المتابعة
- عرض popup إذا لم يتم اختيار طريقة الدفع

### ⚠️ نقاط تحتاج مراجعة:
1. **`payment_method` في Request**: يُرسل كـ `null` - هل هذا متوقع من Backend؟
2. **Flow الدفع**: منفصل عن إنشاء الطلب - هل هذا هو السلوك المطلوب؟
3. **Error Handling**: إذا فشل `createOrder()` → `return` مباشرة (لا يوجد retry)
4. **`Get.back()`**: لا يوجد في الكود - التنقل عبر `callback()`

---

## 8️⃣ الخلاصة

الكود الحالي:
- ✅ يتحقق من طريقة الدفع قبل المتابعة
- ✅ يعرض popup إذا لم يتم اختيار طريقة الدفع
- ✅ ينشئ الطلب أولاً ثم يعالج الدفع
- ⚠️ يرسل `payment_method: null` عند إنشاء الطلب
- ⚠️ لا يوجد `Get.back()` مباشرة بعد `placeOrder()`
- ⚠️ لا يوجد `if(paymentMethod == null)` مباشر (يستخدم `paymentMethodIndex == -1`)

**القرار متروك لك بناءً على متطلبات Backend والسلوك المطلوب.**

