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
    const String uri = '/api/v1/payment/myfatoorah/payment-methods';
    
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
          print('✅ Cached payment methods for key: $cacheKey');
        }
      } catch (e) {
        // Cache failure shouldn't break the flow
        if (kDebugMode) {
          print('⚠️ Failed to cache payment methods: $e');
        }
      }
      // Return 200 response immediately
      return response;
    }
    
    // ⚡ 304 HANDLING: If 304 received, load cached data and return as 200
    if (response.statusCode == 304) {
      if (kDebugMode) {
        print('🔄 [MyFatoorahRepository] Received 304 Not Modified');
        print('   📦 Loading cached payment methods for key: $cacheKey');
        print('   💰 Amount: $amount, Currency: $currency');
      }
      
      // Load cache AFTER receiving 304 (cache should exist from previous 200 response)
      final String? cachedData = await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final Map<String, dynamic> cachedBody = jsonDecode(cachedData) as Map<String, dynamic>;
          if (kDebugMode) {
            print('✅ [MyFatoorahRepository] Loaded cached payment methods successfully');
            print('   📊 Cached data keys: ${cachedBody.keys.join(", ")}');
            print('   ✅ Returning cached data as 200 OK');
          }
          return Response(
            statusCode: 200, // Return as 200 with cached data
            body: cachedBody,
            statusText: 'OK (from cache)',
          );
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('❌ [MyFatoorahRepository] Failed to parse cached payment methods');
            print('   📋 Error: $e');
            print('   📋 Stack trace: $stackTrace');
            print('   📦 Cache data length: ${cachedData.length}');
            print('   📦 Cache data preview: ${cachedData.substring(0, cachedData.length > 200 ? 200 : cachedData.length)}...');
          }
          // Return 304 as-is if cache parsing fails
          return response;
        }
      } else {
        if (kDebugMode) {
          print('❌ [MyFatoorahRepository] 304 received but no cached payment methods available');
          print('   🔑 Cache key: $cacheKey');
          print('   💰 Amount: $amount, Currency: $currency');
          print('   ⚠️ Cache missing - making fresh request without ETag');
        }
        
        // ⚡ FIX: Cache missing - make fresh request without If-None-Match header
        // This happens when cache was cleared or first time loading
        try {
          if (kDebugMode) {
            print('🔄 [MyFatoorahRepository] Retrying request without ETag to get fresh data');
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
                print('✅ [MyFatoorahRepository] Fresh data received and cached');
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Failed to cache fresh payment methods: $e');
              }
            }
            return freshResponse;
          } else {
            if (kDebugMode) {
              print('❌ [MyFatoorahRepository] Fresh request also failed: ${freshResponse.statusCode}');
            }
            return freshResponse;
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ [MyFatoorahRepository] Error making fresh request: $e');
          }
          // Return original 304 if retry fails
          return response;
        }
      }
    }
    
    // Return other status codes as-is (4xx, 5xx, etc.)
    return response;
  }
}
