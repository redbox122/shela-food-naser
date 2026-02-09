# 📋 تحليل كود Place Order - Flutter Request Building

## ✅ الملفات المطلوبة

### 1️⃣ CheckoutController.createOrder()
**الموقع:** `lib/features/checkout/controllers/checkout_controller.dart`

```dart
Future<String> createOrder(
  context,
  PlaceOrderBodyModel placeOrderBody,
  List<XFile>? orderAttachment,
) async {
  // 🔐 Guard: منع بدء عملية جديدة إذا كانت قيد التنفيذ
  if (!canStartNewPaymentFlow) {
    debugPrint('⚠️ Payment flow already in progress: $_paymentFlowState');
    return '';
  }

  // CRITICAL: Reset payment state for new order
  resetPaymentState();
  
  // 🥇 Update flow state
  _paymentFlowState = PaymentFlowState.creatingOrder;
  _isLoading = true;
  update(['payment']); // ✅ استخدام ID لتحديث جزئي

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

      // 🥇 Update flow state - جاهز للدفع
      _paymentFlowState = PaymentFlowState.preparingPayment;
      _isLoading = false;
      update();
      return orderID;
    } else {
      // ... error handling ...
    }
  } catch (e) {
    // ... error handling ...
  }
}
```

---

### 2️⃣ CheckoutRepository.placeOrder()
**الموقع:** `lib/features/checkout/domain/repositories/checkout_repository.dart`

```dart
@override
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

---

### 3️⃣ PlaceOrderBodyModel.toJsonForApi()
**الموقع:** `lib/features/checkout/domain/models/place_order_body_model.dart`

```dart
/// Convert to JSON format for API calls (returns Map<String, dynamic> instead of Map<String, String>)
/// ⚡ TASK 4: Cleanup cart construction - use use_cart: true instead of mapping cart array
/// ⚠️ NOTE: This requires backend API support for use_cart parameter
Map<String, dynamic> toJsonForApi() {
  final Map<String, dynamic> data = <String, dynamic>{};
  // ⚡ TASK 4: Send use_cart: true instead of mapping cart array
  // The backend should use the cart from the session instead of this array
  // ⚠️ BACKEND VERIFICATION REQUIRED: Ensure API supports use_cart parameter
  if (_cart != null && _cart!.isNotEmpty) {
    // Only send use_cart if cart exists (backend uses session cart)
    data['use_cart'] = true;
    // ⚠️ LEGACY: Keep cart array for backward compatibility until backend confirms use_cart support
    // Remove this line once backend confirms use_cart works
    // data['cart'] = _cart!.map((v) => v.toJson()).toList();
  }
  if (_couponDiscountAmount != null) {
    data['coupon_discount_amount'] = _couponDiscountAmount;
  }
  data['order_amount'] = _orderAmount;
  data['order_type'] = _orderType;
  data['payment_method'] = _paymentMethod;
  if (_orderNote != null && _orderNote!.isNotEmpty) {
    data['order_note'] = _orderNote;
  }
  if (_couponCode != null) {
    data['coupon_code'] = _couponCode;
  }
  if (_storeId != null) {
    data['store_id'] = _storeId;
  }
  data['distance'] = _distance;
  if (_scheduleAt != null) {
    data['schedule_at'] = _scheduleAt;
  }
  data['discount_amount'] = _discountAmount;
  data['tax_amount'] = _taxAmount;
  data['address'] = _address ?? '';
  if (_receiverDetails != null) {
    data['receiver_details'] = _receiverDetails!.toJson();
  }
  data['latitude'] = _latitude ?? '';
  data['longitude'] = _longitude ?? '';
  if (_senderZoneId != null) {
    data['sender_zone_id'] = _senderZoneId;
  }
  data['contact_person_name'] = _contactPersonName;
  data['contact_person_number'] = _contactPersonNumber;
  data['address_type'] = _addressType ?? '';
  if (_parcelCategoryId != null) {
    data['parcel_category_id'] = _parcelCategoryId;
  }
  if (_chargePayer != null) {
    data['charge_payer'] = _chargePayer;
  }
  data['road'] = _streetNumber;
  data['house'] = _house;
  data['floor'] = _floor;
  data['dm_tips'] = _dmTips;
  data['unavailable_item_note'] = _unavailableItemNote;
  data['delivery_instruction'] = _deliveryInstruction;
  if (_cutlery != null) {
    data['cutlery'] = _cutlery;
  }
  data['partial_payment'] = _partialPayment;
  // Always include guest_id field (set to 0 for logged-in users)
  data['guest_id'] = _guestId ?? 0;
  data['is_buy_now'] = _isBuyNow;
  // Remove contact_person_email field as it's not required and causes issues
  // The working PHP test doesn't send this field at all
  // data['contact_person_email'] = _guestEmail?.isNotEmpty == true 
  //     ? _guestEmail! 
  //     : 'user@dev.shelafood.com';
  data['extra_packaging_amount'] = _extraPackagingAmount;
  data['create_new_user'] = _createNewUser;
  if (_password != null) {
    data['password'] = _password;
  }
  // Remove these fields as they cause 500 errors in the API
  // if (_paymentConfirmation != null) {
  //   data['payment_confirmation'] = _paymentConfirmation;
  // }
  // if (_walletQidhaStatus != null) {
  //   data['wallet_qidha_status'] = _walletQidhaStatus;
  // }
  return data;
}
```

---

### 4️⃣ بناء PlaceOrderBodyModel في checkout_screen.dart
**الموقع:** `lib/features/checkout/screens/checkout_screen.dart` (السطر 1778)

```dart
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
  paymentMethod: finalPaymentMethod,
  couponCode:
      (Get.find<CouponController>().discount! > 0 ||
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
  contactPersonName: finalAddress.contactPersonName ??
      '${Get.find<ProfileController>().userInfoModel!.fName} '
          '${Get.find<ProfileController>().userInfoModel!.lName}',
  contactPersonNumber:
      finalAddress.contactPersonNumber ??
          Get.find<ProfileController>().userInfoModel!.phone,
  streetNumber: isGuestLogIn
      ? finalAddress.streetNumber ?? ''
      : checkoutController.streetNumberController.text.trim(),
  house: isGuestLogIn
      ? finalAddress.house ?? ''
      : checkoutController.houseController.text.trim(),
  floor: isGuestLogIn
      ? finalAddress.floor ?? ''
      : checkoutController.floorController.text.trim(),
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
  unavailableItemNote:
      Get.find<CartController>().notAvailableIndex != -1
          ? Get.find<CartController>().notAvailableList[
              Get.find<CartController>().notAvailableIndex]
          : '',
  deliveryInstruction:
      checkoutController.selectedInstruction != -1
          ? AppConstants.deliveryInstructionList[
              checkoutController.selectedInstruction]
          : '',
  partialPayment: checkoutController.isPartialPay ? 1 : 0,
  guestId: isGuestLogIn
      ? int.parse(AuthHelper.getGuestId())
      : 0,
  isBuyNow: widget.fromCart ? 0 : 1,
  guestEmail: isGuestLogIn
      ? finalAddress.email
      : (Get.find<ProfileController>().userInfoModel?.email ?? ''),
  extraPackagingAmount: Get.find<CartController>().needExtraPackage
      ? checkoutController.store!.extraPackagingAmount
      : null,
  createNewUser: isGuestLogIn && checkoutController.isCreateAccount ? 1 : 0,
  password: isGuestLogIn && checkoutController.isCreateAccount
      ? guestPasswordController.text.trim()
      : null,
);
```

---

### 5️⃣ ApiClient.postData()
**الموقع:** `lib/api/api_client.dart`

```dart
Future<Response<dynamic>> postData(String uri, dynamic body,
    {Map<String, String>? headers,
    int? timeoutInSeconds,
    bool handleError = true,
    bool useSecureClient = false,
    Uri? newUri,
    bool changeBaseUrl = false}) async {
  // Implementation details...
  // Uses dio.post() or http.post() internally
  // Converts body to JSON if it's a Map
  // Adds headers
  // Handles errors
}
```

---

## 🔍 ملاحظات مهمة

### ✅ استخدام `use_cart: true`
- في `toJsonForApi()`: يتم إرسال `use_cart: true` بدلاً من `cart` array
- **⚠️ LEGACY:** الكود يحتوي على تعليق يفيد بأن `cart` array معطل مؤقتاً حتى يتم تأكيد دعم الباك إند لـ `use_cart`

### ✅ Headers المرسلة
- `Authorization: Bearer {token}`
- `Content-Type: application/json; charset=UTF-8`
- `Accept: application/json`
- `latitude` (من orderBody)
- `longitude` (من orderBody)
- `moduleId` (من cache أو default: '3')
- `zoneId` (من apiClient.getHeader() أو fallback: '[2,4,3,5]')

### ✅ الحقول المهمة في Request Body
- `use_cart: true` (بدلاً من `cart` array)
- `order_amount`
- `order_type`
- `payment_method`
- `contact_person_name`
- `contact_person_number`
- `guest_id` (0 للمستخدمين المسجلين)
- `is_buy_now` (0 من السلة، 1 من المنتج مباشرة)

### ❌ الحقول المحذوفة (تسبب 500 errors)
- `contact_person_email` (محذوف - لا يُرسل)
- `payment_confirmation` (محذوف)
- `wallet_qidha_status` (محذوف)

---

## 🎯 الخلاصة

1. **Flutter يبني Request Body** عبر `PlaceOrderBodyModel.toJsonForApi()`
2. **يستخدم `use_cart: true`** بدلاً من إرسال `cart` array
3. **يُرسل Headers** مع token و moduleId و zoneId
4. **يستخدم `apiClient.postData()`** لإرسال الطلب
5. **لا يستخدم FormData** - يستخدم JSON فقط

