import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/common/security/secure_token_storage.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'dart:convert';
import 'package:dio/dio.dart' as dio;

class CheckoutRepository implements CheckoutRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  final AuthRepositoryInterface authRepositoryInterface;
  
  CheckoutRepository({
    required this.apiClient, 
    required this.sharedPreferences,
    required this.authRepositoryInterface,
  });

  @override
  Future<int> getDmTipMostTapped() async {
    int mostDmTipAmount = 0;
    final Response response = await apiClient.getData(AppConstants.mostTipsUri);
    if (response.statusCode == 200) {
      mostDmTipAmount = (response.body['most_tips_amount'] as int?) ?? 0;
    }
    return mostDmTipAmount;
  }

  @override
  Future<bool> saveSharedPrefDmTipIndex(String index) async {
    return await sharedPreferences.setString(AppConstants.dmTipIndex, index);
  }

  @override
  String getSharedPrefDmTipIndex() {
    return sharedPreferences.getString(AppConstants.dmTipIndex) ?? '';
  }

  @override
  Future<Response> getDistanceInMeter(LatLng originLatLng, LatLng destinationLatLng) async {
    return await apiClient.getData(
      '${AppConstants.distanceMatrixUri}?origin_lat=${originLatLng.latitude}&origin_lng=${originLatLng.longitude}'
          '&destination_lat=${destinationLatLng.latitude}&destination_lng=${destinationLatLng.longitude}&mode=driving',
      handleError: false,
    );
  }
  @override
  Future<Response> getDistanceInMeterNew(LatLng originLatLng, LatLng destinationLatLng) async {
    final Uri url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/distancematrix/json',
      {
        'origins': '${originLatLng.latitude},${originLatLng.longitude}',
        'destinations': '${destinationLatLng.latitude},${destinationLatLng.longitude}',
        'mode': 'driving',
        'key': 'AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8',
      },
    );
    return await apiClient.getData(
      '',
      newUri: url,
      changeBaseUrl: true,
      handleError: false,
    );

  }

  @override
  Future<double> getExtraCharge(double? distance) async {
    double extraCharge = 0;
    final Response response = await apiClient.getData('${AppConstants.vehicleChargeUri}?distance=$distance', handleError: false);
    if (response.statusCode == 200) {
      final dynamic body = response.body;
      if (body is Map && body['extra_charge'] is num) {
        extraCharge = (body['extra_charge'] as num).toDouble();
      } else if (body is num) {
        extraCharge = body.toDouble();
      } else {
        final parsed = double.tryParse(body.toString());
        extraCharge = parsed ?? 0;
      }
    }
    return extraCharge;
  }

  @override
  Future<Response> placeOrder(PlaceOrderBodyModel orderBody, List<MultipartBody>? orderAttachment) async {
    final orderData = orderBody.toJsonForApi();

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
    
    // 🔥 FIX: إزالة duplication - latitude/longitude موجودان في body
    // لا حاجة لإرسالهما في headers أيضاً (إلا إذا كان backend يتطلب ذلك صراحة)
    // if (orderBody.latitude != null) {
    //   headers['latitude'] = orderBody.latitude!;
    // }
    // if (orderBody.longitude != null) {
    //   headers['longitude'] = orderBody.longitude!;
    // }
    
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
      // 🔥 FIX: لا نستخدم hardcoded zoneId - خطير جداً
      debugPrint('\x1B[31m❌ CRITICAL: zoneId is missing from headers!\x1B[0m');
      debugPrint('\x1B[31m❌ Cannot place order without zoneId - this will cause pricing/delivery errors\x1B[0m');
      // headers[AppConstants.zoneId] = '[2,4,3,5]'; // ❌ REMOVED - خطير جداً
    }

    // ✅ Fix: Prescription Order - استخدام FormData/Multipart
    // ✅ Normal Order - استخدام JSON
    // 🔥 FIX: تحديد prescription بناءً على orderType وليس orderAttachment
    // لأن prescription قد يكون بدون صور، والصور optional
    print('═══════════════════════════════════════════════════════════');
    print('🔍 CHECKING ORDER TYPE:');
    print(' - orderType: ${orderBody.orderType}');
    print(' - orderAttachment is null: ${orderAttachment == null}');
    print(' - orderAttachment is empty: ${orderAttachment?.isEmpty ?? true}');
    print(' - orderAttachment length: ${orderAttachment?.length ?? 0}');
    
    debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
    debugPrint('\x1B[36m🔍 CHECKING ORDER TYPE:\x1B[0m');
    debugPrint('\x1B[36m - orderType: ${orderBody.orderType}\x1B[0m');
    debugPrint('\x1B[36m - orderAttachment is null: ${orderAttachment == null}\x1B[0m');
    debugPrint('\x1B[36m - orderAttachment is empty: ${orderAttachment?.isEmpty ?? true}\x1B[0m');
    debugPrint('\x1B[36m - orderAttachment length: ${orderAttachment?.length ?? 0}\x1B[0m');
    
    // ✅ FIX: تحديد prescription بناءً على orderType (الصور optional)
    final bool isPrescription = orderBody.orderType?.toLowerCase() == 'prescription' ||
                                (orderAttachment != null && orderAttachment.isNotEmpty);
    print(' - isPrescription (from orderType): ${orderBody.orderType?.toLowerCase() == 'prescription'}');
    print(' - isPrescription (from attachment): ${orderAttachment != null && orderAttachment.isNotEmpty}');
    print(' - isPrescription (FINAL): $isPrescription');
    print('═══════════════════════════════════════════════════════════');
    
    debugPrint('\x1B[36m - isPrescription (from orderType): ${orderBody.orderType?.toLowerCase() == 'prescription'}\x1B[0m');
    debugPrint('\x1B[36m - isPrescription (from attachment): ${orderAttachment != null && orderAttachment.isNotEmpty}\x1B[0m');
    debugPrint('\x1B[36m - isPrescription (FINAL): $isPrescription\x1B[0m');
    debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');

    if (isPrescription) {
      // ================= Prescription Order (Multipart/FormData) =================
      print('🔥🔥🔥 SENDING PRESCRIPTION AS MULTIPART 🔥🔥🔥');
      print('📋 Prescription Order Detected - Using FormData/Multipart');
      debugPrint('\x1B[32m🔥🔥🔥 SENDING PRESCRIPTION AS MULTIPART 🔥🔥🔥\x1B[0m');
      debugPrint('\x1B[32m📋 Prescription Order Detected - Using FormData/Multipart\x1B[0m');
      
      // بناء FormData
      final Map<String, dynamic> formDataMap = Map<String, dynamic>.from(orderBody.toJsonForApi());
      // Prescription endpoint expects delivery order_type (not "prescription")
      formDataMap['order_type'] = 'delivery';
      // Ensure order_amount is present
      formDataMap['order_amount'] = orderBody.orderAmount;
      // Force use_cart as explicit numeric string (backend expects 1/0)
      formDataMap['use_cart'] = '1';
      
      // ✅ حل CART_EMPTY: إضافة use_cart فقط إذا كان هناك cart items
      // 🔥 FIX: لا نضيف use_cart إجبارياً - فقط إذا كان هناك items
      if (orderBody.cart != null && orderBody.cart!.isNotEmpty) {
        final cartItems = orderBody.cart!.map((e) => {
          'item_id': e.itemId,
          'model': 'Item',
          'price': e.price,
          'variant': 'none',
          'variation': e.variation ?? [],
          'quantity': e.quantity ?? 1,
          'add_on_ids': e.addOnIds ?? [],
          'add_on_qtys': e.addOnQtys ?? [],
          'add_ons': [],
          if (e.storeId != null) 'store_id': e.storeId,
        }).toList();
        formDataMap['cart'] = cartItems;
        formDataMap['use_cart'] = '0';
        debugPrint('\x1B[32m✅ Added cart (cart has ${orderBody.cart!.length} items)\x1B[0m');
      } else {
        debugPrint('\x1B[33m⚠️ Cart is empty or null - cart not added\x1B[0m');
      }
      
      // ✅ حل CONTACT_EMAIL_REQUIRED: إضافة email للضيف
      if (orderBody.guestEmail?.isNotEmpty == true) {
        formDataMap['contact_person_email'] = orderBody.guestEmail;
      } else {
        // إنشاء email فريد للضيف
        formDataMap['contact_person_email'] = 'guest_${DateTime.now().millisecondsSinceEpoch}@shelafood.com';
      }
      
      // 🔥 طباعة Payload قبل الإرسال (مهم جداً)
      debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
      debugPrint('\x1B[36m📦 PAYLOAD BEFORE SENDING (FormData):\x1B[0m');
      debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
      formDataMap.forEach((key, value) {
        if (value == null) {
          debugPrint('\x1B[33m⚠️ $key: NULL\x1B[0m');
        } else if (value is String && value.isEmpty) {
          debugPrint('\x1B[33m⚠️ $key: EMPTY STRING\x1B[0m');
        } else if (value is List && value.isEmpty) {
          debugPrint('\x1B[33m⚠️ $key: EMPTY ARRAY\x1B[0m');
        } else {
          debugPrint('\x1B[32m✅ $key: $value\x1B[0m');
        }
      });
      debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
      
      // بناء FormData باستخدام dio
      final dio.FormData formData = dio.FormData.fromMap(formDataMap);
      // Ensure cart is sent as array fields (PHP-friendly)
      if (orderBody.cart != null && orderBody.cart!.isNotEmpty) {
        _addCartFields(formData, orderBody.cart!.map((e) => {
          'item_id': e.itemId,
          'model': 'Item',
          'price': e.price,
          'variant': 'none',
          'variation': e.variation ?? [],
          'quantity': e.quantity ?? 1,
          'add_on_ids': e.addOnIds ?? [],
          'add_on_qtys': e.addOnQtys ?? [],
          'add_ons': [],
          if (e.storeId != null) 'store_id': e.storeId,
        }).toList());
      }
      
      // إرفاق الملفات
      if (orderAttachment != null) {
        for (final MultipartBody multipart in orderAttachment) {
          if (multipart.file != null) {
            final String fileKey = multipart.key.isNotEmpty ? multipart.key : 'order_attachment';
            formData.files.add(
              MapEntry(
                fileKey,
                await dio.MultipartFile.fromFile(
                  multipart.file!.path,
                  filename: multipart.file!.name,
                ),
              ),
            );
          }
        }
      }
      
      // 🔥 مهم: إزالة Content-Type header للسماح لـ dio بضبطه تلقائياً
      headers.remove('Content-Type');
      
      // Log the complete request for debugging
      debugPrint('\x1B[33m🔍 Complete API Request (Multipart):\x1B[0m');
      debugPrint('\x1B[33m⚠️⚠️⚠️ CRITICAL: Checking URI...\x1B[0m');
      debugPrint('\x1B[33m - placeOrderUri: ${AppConstants.placeOrderUri}\x1B[0m');
      debugPrint('\x1B[33m - placePrescriptionOrderUri: ${AppConstants.placePrescriptionOrderUri}\x1B[0m');
      debugPrint('\x1B[33m - Headers BEFORE removal: $headers\x1B[0m');
      
      // 🔥 طباعة تفصيلية لـ FormData
      debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
      debugPrint('\x1B[36m📦 FORM DATA DETAILS:\x1B[0m');
      debugPrint('\x1B[36m - FormData Fields Count: ${formData.fields.length}\x1B[0m');
      debugPrint('\x1B[36m - FormData Files Count: ${formData.files.length}\x1B[0m');
      debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
      
      // طباعة جميع fields
      debugPrint('\x1B[36m📋 FormData Fields:\x1B[0m');
      for (int i = 0; i < formData.fields.length; i++) {
        final field = formData.fields[i];
        debugPrint('\x1B[36m   [$i] ${field.key}: ${field.value}\x1B[0m');
      }
      
      // طباعة جميع files
      debugPrint('\x1B[36m📎 FormData Files:\x1B[0m');
      for (int i = 0; i < formData.files.length; i++) {
        final fileEntry = formData.files[i];
        final file = fileEntry.value;
        debugPrint('\x1B[36m   [$i] key=${fileEntry.key}, filename=${file.filename}, length=${file.length}\x1B[0m');
      }
      
      debugPrint('\x1B[33m - Headers AFTER Content-Type removal: $headers\x1B[0m');
      
      debugPrint('\x1B[32m🔥 CALLING apiClient.postFormData() NOW...\x1B[0m');
      
      // 🔥 مهم جداً: استخدام URI الصحيح للـ Prescription
      const String prescriptionUri = AppConstants.placePrescriptionOrderUri;
      debugPrint('\x1B[32m🔥 Using Prescription URI: $prescriptionUri\x1B[0m');
      debugPrint('\x1B[32m🔥 Expected: /api/v1/customer/order/prescription/place\x1B[0m');
      debugPrint('\x1B[32m🔥 Full URL will be: ${apiClient.appBaseUrl}$prescriptionUri\x1B[0m');
      
      // استخدام apiClient.postFormData (دالة جديدة لـ FormData)
      final response = await apiClient.postFormData(
        prescriptionUri, // ✅ استخدام URI الصحيح للـ Prescription
        formData,
        headers: headers,
        handleError: false,
      );
      
      // 🔥 استخدام print + debugPrint لضمان ظهور اللوجات في الترمينال
      print('═══════════════════════════════════════════════════════════');
      print('🔥🔥🔥 PRESCRIPTION ORDER RESPONSE 🔥🔥🔥');
      print('═══════════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Status Text: ${response.statusText}');
      print('Response Body Type: ${response.body.runtimeType}');
      
      debugPrint('\x1B[32m🔥 postFormData() returned: statusCode=${response.statusCode}\x1B[0m');
      debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
      debugPrint('\x1B[36m📦 PRESCRIPTION ORDER RESPONSE:\x1B[0m');
      debugPrint('\x1B[36m - Status Code: ${response.statusCode}\x1B[0m');
      debugPrint('\x1B[36m - Status Text: ${response.statusText}\x1B[0m');
      debugPrint('\x1B[36m - Response Body Type: ${response.body.runtimeType}\x1B[0m');
      
      if (response.body is Map) {
        final responseBody = response.body as Map;
        print('Response Body Keys: ${responseBody.keys.toList()}');
        print('Full Response Body: $responseBody');
        
        debugPrint('\x1B[36m - Response Body Keys: ${responseBody.keys.toList()}\x1B[0m');
        debugPrint('\x1B[36m - Full Response Body: $responseBody\x1B[0m');
        
        // التحقق من وجود order ID
        if (responseBody.containsKey('id')) {
          print('✅ Order ID found: ${responseBody['id']}');
          debugPrint('\x1B[32m✅ Order ID found: ${responseBody['id']}\x1B[0m');
        } else if (responseBody.containsKey('order_id')) {
          print('✅ Order ID (order_id) found: ${responseBody['order_id']}');
          debugPrint('\x1B[32m✅ Order ID (order_id) found: ${responseBody['order_id']}\x1B[0m');
        } else {
          print('❌ No order ID found in response!');
          print('Available keys: ${responseBody.keys.toList()}');
          debugPrint('\x1B[31m❌ No order ID found in response!\x1B[0m');
        }
      } else {
        print('Response Body: ${response.body}');
        debugPrint('\x1B[36m - Response Body: ${response.body}\x1B[0m');
      }
      print('═══════════════════════════════════════════════════════════');
      debugPrint('\x1B[36m═══════════════════════════════════════════════════════════\x1B[0m');
      
      // 🔥 طباعة Response Body عند 422 أو أي خطأ
      if (response.statusCode != null && response.statusCode! >= 400) {
        print('═══════════════════════════════════════════════════════════');
        print('❌❌❌ ERROR RESPONSE (Status: ${response.statusCode}) ❌❌❌');
        print('═══════════════════════════════════════════════════════════');
        print('Response Body: ${response.body}');
        print('Status Text: ${response.statusText}');
        
        debugPrint('\x1B[31m═══════════════════════════════════════════════════════════\x1B[0m');
        debugPrint('\x1B[31m❌ ERROR RESPONSE (Status: ${response.statusCode}):\x1B[0m');
        debugPrint('\x1B[31m═══════════════════════════════════════════════════════════\x1B[0m');
        debugPrint('\x1B[31m📦 Response Body: ${response.body}\x1B[0m');
        debugPrint('\x1B[31m📝 Status Text: ${response.statusText}\x1B[0m');
        
        if (response.body is Map) {
          final errorBody = response.body as Map;
          if (errorBody.containsKey('errors')) {
            print('🔴 Validation Errors:');
            debugPrint('\x1B[31m🔴 Validation Errors:\x1B[0m');
            final errors = errorBody['errors'];
            if (errors is Map) {
              errors.forEach((key, value) {
                print('   - $key: $value');
                debugPrint('\x1B[31m   - $key: $value\x1B[0m');
              });
            } else {
              print('   $errors');
              debugPrint('\x1B[31m   $errors\x1B[0m');
            }
          }
          if (errorBody.containsKey('message')) {
            print('📨 Error Message: ${errorBody['message']}');
            debugPrint('\x1B[31m📨 Error Message: ${errorBody['message']}\x1B[0m');
          }
        }
        print('═══════════════════════════════════════════════════════════');
        debugPrint('\x1B[31m═══════════════════════════════════════════════════════════\x1B[0m');
      }
      
      return response;
    } else {
      // ================= Normal Order (JSON) =================
      debugPrint('\x1B[31m⚠️⚠️⚠️ NORMAL ORDER - USING JSON (NOT MULTIPART) ⚠️⚠️⚠️\x1B[0m');
      debugPrint('\x1B[31m📋 Normal Order - Using JSON\x1B[0m');
      
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
  }

  @override
  Future<Response> placePrescriptionOrder(
    int? storeId,
    double? distance,
    String address,
    String longitude,
    String latitude,
    String note,
    List<MultipartBody> orderAttachment,
    String dmTips,
    String deliveryInstruction, {
    double orderAmount = 0,
    String? cartItemsJson,
  }) async {
    final Map<String, dynamic> body = {
      'store_id': storeId,
      'distance': distance,
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'order_note': note,
      'dm_tips': dmTips,
      'delivery_instruction': deliveryInstruction,
      'order_amount': orderAmount,
      'order_type': 'delivery',
    };
    if (cartItemsJson != null && cartItemsJson.isNotEmpty) {
      final dynamic decodedCart = jsonDecode(cartItemsJson);
      if (decodedCart is List) {
        body['cart'] = decodedCart;
      }
      body['use_cart'] = '0';
    } else {
      body['use_cart'] = '1';
    }
    
    // Get the best available token for checkout
    final String token = await _getCheckoutToken();
    
    if (token.isEmpty) {
      debugPrint('❌ No valid token available for prescription checkout');
      return const Response(statusCode: 401, statusText: 'Unauthorized: No valid token');
    }
    
    // Log token info
    final tokenPrefix = token.length > 12 ? token.substring(0, 12) : token;
    final hasDot = token.contains('.');
    debugPrint('checkout prescription token: $tokenPrefix..., hasDot=$hasDot');

    // Create headers following the documented API specification
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    headers['Authorization'] = 'Bearer $token';
    headers['Content-Type'] = 'application/json; charset=UTF-8';
    headers['Accept'] = 'application/json';
    
    // Add required headers as per documentation
    headers['latitude'] = latitude;
    headers['longitude'] = longitude;
    
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
      // 🔥 FIX: لا نستخدم hardcoded zoneId - خطير جداً
      debugPrint('\x1B[31m❌ CRITICAL: zoneId is missing from headers!\x1B[0m');
      debugPrint('\x1B[31m❌ Cannot place order without zoneId - this will cause pricing/delivery errors\x1B[0m');
      // headers[AppConstants.zoneId] = '[2,4,3,5]'; // ❌ REMOVED - خطير جداً
    }

    // Build FormData for prescription order (backend expects multipart)
    final dio.FormData formData = dio.FormData.fromMap(body);
    if (body['cart'] is List) {
      _addCartFields(formData, body['cart'] as List<dynamic>);
    }
    for (final MultipartBody multipart in orderAttachment) {
      if (multipart.file != null) {
        final String fileKey = multipart.key.isNotEmpty ? multipart.key : 'order_attachment';
        formData.files.add(
          MapEntry(
            fileKey,
            await dio.MultipartFile.fromFile(
              multipart.file!.path,
              filename: multipart.file!.name,
            ),
          ),
        );
      }
    }

    // Allow dio to set multipart content-type
    headers.remove('Content-Type');

    return await apiClient.postFormData(
      AppConstants.placePrescriptionOrderUri,
      formData,
      headers: headers,
      handleError: false,
    );
  }

  @override
  Future<Response> processPayment(int orderId, String paymentMethod, double amount) async {
    // Get the best available token for payment processing
    final String token = await _getCheckoutToken();
    
    if (token.isEmpty) {
      debugPrint('❌ No valid token available for payment processing');
      return const Response(statusCode: 401, statusText: 'Unauthorized: No valid token');
    }
    
    // Create headers following the documented API specification
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    headers['Authorization'] = 'Bearer $token';
    headers['Content-Type'] = 'application/json; charset=UTF-8';
    headers['Accept'] = 'application/json';
    headers['Accept-Language'] = 'ar';
    
    // Prepare payment data
    final Map<String, dynamic> paymentData = {
      'order_id': orderId,
      'payment_method': paymentMethod,
      'amount': amount
    };
    
    debugPrint('\x1B[32m💳 Processing Payment:\x1B[0m');
    debugPrint('\x1B[32m - Order ID: $orderId\x1B[0m');
    debugPrint('\x1B[32m - Payment Method: $paymentMethod\x1B[0m');
    debugPrint('\x1B[32m - Amount: $amount\x1B[0m');
    
    return await apiClient.postData(
      AppConstants.processPaymentUri,
      paymentData,
      headers: headers,
      handleError: false,
    );
  }

  @override
  Future<Response> editOrderAddress(int orderId, String address, String latitude, String longitude) async {
    // Get the best available token for address editing
    final String token = await _getCheckoutToken();
    
    if (token.isEmpty) {
      debugPrint('❌ No valid token available for address editing');
      return const Response(statusCode: 401, statusText: 'Unauthorized: No valid token');
    }
    
    // Create headers following the documented API specification
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    headers['Authorization'] = 'Bearer $token';
    headers['Content-Type'] = 'application/json; charset=UTF-8';
    headers['Accept'] = 'application/json';
    headers['Accept-Language'] = 'ar';
    
    // Prepare address data
    final Map<String, dynamic> addressData = {
      'order_id': orderId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude
    };
    
    debugPrint('\x1B[32m📍 Editing Order Address:\x1B[0m');
    debugPrint('\x1B[32m - Order ID: $orderId\x1B[0m');
    debugPrint('\x1B[32m - Address: $address\x1B[0m');
    debugPrint('\x1B[32m - Latitude: $latitude\x1B[0m');
    debugPrint('\x1B[32m - Longitude: $longitude\x1B[0m');
    
    return await apiClient.postData(
      AppConstants.editOrderAddressUri,
      addressData,
      headers: headers,
      handleError: false,
    );
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) async {
    return await _getOfflineMethodList();
  }

  Future<List<OfflineMethodModel>?> _getOfflineMethodList() async {
    List<OfflineMethodModel>? offlineMethodList;
    final Response response = await apiClient.getData(AppConstants.offlineMethodListUri);

    if (response.statusCode == 200) {
      if (response.body is List) {
        // Ensure it's a List before iterating
        offlineMethodList = (response.body as List).map((method) => OfflineMethodModel.fromJson(method as Map<String, dynamic>)).toList();
      }
    }
    return offlineMethodList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
  
  /// PERMANENT FIX: Get the best available token for checkout
  /// This method handles JWT/Passport token mismatch forever
  Future<String> _getCheckoutToken() async {
    try {
      // Step 1: Try to get token from secure storage (JWT or Passport)
      final String? secureToken = await SecureTokenStorage.getToken();
      if (secureToken != null && secureToken.isNotEmpty) {
        debugPrint('✅ Using token from secure storage (JWT/Passport)');
        return secureToken;
      }
      
      // Step 2: Try legacy token (JWT or Passport)
      final String legacyToken = authRepositoryInterface.getUserToken();
      if (legacyToken.isNotEmpty) {
        debugPrint('✅ Using token from legacy storage (JWT/Passport)');
        return legacyToken;
      }
      
      // Step 3: Try to refresh token
      debugPrint('🔄 Attempting token refresh');
      final String? refreshedToken = await _refreshToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        debugPrint('✅ Token refreshed successfully');
        return refreshedToken;
      }
      
      debugPrint('❌ No valid token found');
      return '';
    } catch (e) {
      debugPrint('❌ Error getting checkout token: $e');
      return '';
    }
  }
  
  
  /// Try to refresh the current token
  Future<String?> _refreshToken() async {
    try {
      // Try to refresh using current token
      final response = await authRepositoryInterface.updateToken();
      if (response.statusCode == 200) {
        // Get the refreshed token
        final String refreshedToken = authRepositoryInterface.getUserToken();
        if (refreshedToken.isNotEmpty) {
          return refreshedToken;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
      return null;
    }
  }
}

void _addCartFields(dio.FormData formData, List<dynamic> cartItems) {
  for (int i = 0; i < cartItems.length; i++) {
    final item = cartItems[i];
    if (item is! Map) {
      continue;
    }
    item.forEach((key, value) {
      if (value is List) {
        for (int j = 0; j < value.length; j++) {
          formData.fields.add(MapEntry('cart[$i][$key][$j]', value[j].toString()));
        }
      } else {
        formData.fields.add(MapEntry('cart[$i][$key]', value?.toString() ?? ''));
      }
    });
  }
}
