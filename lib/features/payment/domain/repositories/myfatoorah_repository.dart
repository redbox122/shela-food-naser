import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get_connect/connect.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';

class MyFatoorahRepository {
  final ApiClient apiClient;

  MyFatoorahRepository({required this.apiClient});

  /// Get payment methods from backend endpoint
  /// This replaces direct MyFatoorah SDK calls for security
  /// ⚡ CACHING: Caches responses for 304 Not Modified support
  Future<Response> getPaymentMethods({
    required double amount,
    String currency = 'KWD',
  }) async {
    const String uri = '/api/v1/payment/myfatoorah/payment-methods-with-ids';
    
    // Build query parameters - always include amount, conditionally include currency
    final StringBuffer queryBuffer = StringBuffer('amount=${Uri.encodeComponent(amount.toString())}');
    if (currency != 'KWD') {
      queryBuffer.write('&currency=${Uri.encodeComponent(currency)}');
    }

    // Build full URI with query parameters
    final String fullUri = '$uri?$queryBuffer';
    
    // Build cache key (amount and currency determine payment methods)
    final String cacheKey = 'payment_methods_${amount}_$currency';
    
    // Call backend endpoint
    final Response response = await apiClient.getData(fullUri);
    
    // ⚡ CACHING: Cache successful responses for 304 support
    if (response.statusCode == 200 && response.body != null) {
      try {
        await LocalClient.organize(
          DataSourceEnum.client,
          cacheKey,
          jsonEncode(response.body),
          apiClient.getHeader(),
        );
        if (kDebugMode) {
          debugPrint('✅ Cached payment methods for key: $cacheKey');
        }
      } catch (e) {
        // Cache failure shouldn't break the flow
        if (kDebugMode) {
          debugPrint('⚠️ Failed to cache payment methods: $e');
        }
      }
      // Return 200 response immediately
      return response;
    }
    
    // ⚡ 304 HANDLING: If 304 received, load cached data and return as 200
    if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint('🔄 [MyFatoorahRepository] Received 304 Not Modified');
        debugPrint('   📦 Loading cached payment methods for key: $cacheKey');
        debugPrint('   💰 Amount: $amount, Currency: $currency');
      }
      
      // Load cache AFTER receiving 304 (cache should exist from previous 200 response)
      final String? cachedData = await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final Map<String, dynamic> cachedBody = jsonDecode(cachedData) as Map<String, dynamic>;
          if (kDebugMode) {
            debugPrint('✅ [MyFatoorahRepository] Loaded cached payment methods successfully');
            debugPrint('   📊 Cached data keys: ${cachedBody.keys.join(", ")}');
            debugPrint('   ✅ Returning cached data as 200 OK');
          }
          return Response(
            statusCode: 200, // Return as 200 with cached data
            body: cachedBody,
            statusText: 'OK (from cache)',
          );
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ [MyFatoorahRepository] Failed to parse cached payment methods');
            debugPrint('   📋 Error: $e');
            debugPrint('   📋 Stack trace: $stackTrace');
            debugPrint('   📦 Cache data length: ${cachedData.length}');
            debugPrint('   📦 Cache data preview: ${cachedData.substring(0, cachedData.length > 200 ? 200 : cachedData.length)}...');
          }
          // Return 304 as-is if cache parsing fails
          return response;
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ [MyFatoorahRepository] 304 received but no cached payment methods available');
          debugPrint('   🔑 Cache key: $cacheKey');
          debugPrint('   💰 Amount: $amount, Currency: $currency');
          debugPrint('   ⚠️ Cache missing - making fresh request without ETag');
        }
        
        // ⚡ FIX: Cache missing - make fresh request without If-None-Match header
        // This happens when cache was cleared or first time loading
        try {
          if (kDebugMode) {
            debugPrint('🔄 [MyFatoorahRepository] Retrying request without ETag to get fresh data');
          }
          
          // Make fresh request (ApiClient will handle it normally, no ETag sent if cache doesn't exist)
          // Note: We can't easily remove ETag from ApiClient, but if cache doesn't exist,
          // the ETag shouldn't be sent anyway. This retry should get a 200 response.
          final freshResponse = await apiClient.getData(fullUri);
          
          if (freshResponse.statusCode == 200 && freshResponse.body != null) {
            // Cache the fresh response
            try {
              await LocalClient.organize(
                DataSourceEnum.client,
                cacheKey,
                jsonEncode(freshResponse.body),
                apiClient.getHeader(),
              );
              if (kDebugMode) {
                debugPrint('✅ [MyFatoorahRepository] Fresh data received and cached');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Failed to cache fresh payment methods: $e');
              }
            }
            return freshResponse;
          } else {
            if (kDebugMode) {
              debugPrint('❌ [MyFatoorahRepository] Fresh request also failed: ${freshResponse.statusCode}');
            }
            return freshResponse;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ [MyFatoorahRepository] Error making fresh request: $e');
          }
          // Return original 304 if retry fails
          return response;
        }
      }
    }
    
    // Return other status codes as-is (4xx, 5xx, etc.)
    return response;
  }

  /// Process payment via backend (MyFatoorah) and return payment_url
  /// This keeps all secrets on the server side.
  Future<Response> processPayment({
    required int orderId,
    required double amount,
    String currency = 'SAR',
    required int paymentMethodId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  }) async {
    const String uri = '/api/v1/payment/myfatoorah/process';

    final Map<String, dynamic> body = <String, dynamic>{
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'payment_method_id': paymentMethodId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
    };

    return await apiClient.postData(uri, body);
  }

  /// Verify a MyFatoorah payment status via the backend after the WebView
  /// returns. The backend reconciles with the gateway and echoes the order
  /// state, so we call this ONCE instead of polling trackOrder many times.
  ///
  /// Body: { "key_type": "InvoiceId", "key": <invoiceId> }
  Future<Response> checkStatus({
    required String key,
    String keyType = 'InvoiceId',
  }) async {
    const String uri = '/api/v1/payment/myfatoorah/check-status';
    final Map<String, dynamic> body = <String, dynamic>{
      'key_type': keyType,
      'key': key,
    };
    return await apiClient.postData(uri, body);
  }

  /// Process payment without order via backend and return payment_url
  Future<Response> processPaymentWithoutOrder({
    required double amount,
    String currency = 'SAR',
    int? paymentMethodId,
    String? paymentMethodCode,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    String? countryCode,
    String? callbackUrl,
    String? errorUrl,
  }) async {
    const String uri = '/api/v1/payment/myfatoorah/process-without-order';

    final Map<String, dynamic> body = <String, dynamic>{
      'amount': amount,
      'currency': currency,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
    };

    if (paymentMethodCode != null && paymentMethodCode.isNotEmpty) {
      body['payment_method_code'] = paymentMethodCode;
    } else if (paymentMethodId != null) {
      body['payment_method_id'] = paymentMethodId;
    }

    if (countryCode != null && countryCode.isNotEmpty) {
      body['country_code'] = countryCode;
    }
    if (callbackUrl != null && callbackUrl.isNotEmpty) {
      body['callback_url'] = callbackUrl;
    }
    if (errorUrl != null && errorUrl.isNotEmpty) {
      body['error_url'] = errorUrl;
    }

    return await apiClient.postData(uri, body);
  }
}
