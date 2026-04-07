import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get_connect.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/loyalty/domain/repositories/loyalty_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class LoyaltyRepository implements LoyaltyRepositoryInterface {
  final ApiClient apiClient;
  LoyaltyRepository({required this.apiClient});

  @override
  Future<Response> pointToWallet({int? point}) async {
    return await apiClient.postData(AppConstants.loyaltyPointTransferUri, {'point': point});
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
    return await _getLoyaltyTransactionList(offset);
  }

  Future<TransactionModel?> _getLoyaltyTransactionList(int? offset) async {
    final String uri = '${AppConstants.loyaltyTransactionUri}?offset=$offset&limit=10';
    final String cacheKey = 'loyalty_transactions_$offset';
    
    final Response response = await apiClient.getData(uri);

    // ⚡ 304 HANDLING: If 304 received, load cached data
    if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint('🔄 [LoyaltyRepository] Received 304 for transactions - loading cache');
      }
      final String? cachedData = await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(cachedData);
          final Map<String, dynamic> cachedBody = decoded is Map<String, dynamic> 
              ? decoded 
              : (decoded as Map).cast<String, dynamic>();
          if (kDebugMode) {
            debugPrint('✅ [LoyaltyRepository] Loaded cached transactions');
          }
          return TransactionModel.fromJson(cachedBody);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [LoyaltyRepository] Failed to parse cached transactions: $e');
          }
          // Cache parsing failed - return null to trigger retry
          return null;
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ [LoyaltyRepository] 304 received but no cache - making fresh request');
        }
        // Cache missing - make fresh request (retry without ETag)
        final freshResponse = await apiClient.getData(uri);
        if (freshResponse.statusCode == 200 && freshResponse.body != null) {
          // Cache the fresh response
          try {
            await LocalClient.organize(
              DataSourceEnum.client,
              cacheKey,
              jsonEncode(freshResponse.body),
              apiClient.getHeader(),
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Failed to cache transactions: $e');
            }
          }
          final dynamic body = freshResponse.body;
          final Map<String, dynamic> bodyMap = body is Map ? Map<String, dynamic>.from(body) : body as Map<String, dynamic>;
          return TransactionModel.fromJson(bodyMap);
        }
        return null;
      }
    }

    // ⚡ CACHING: Cache successful responses
    if (response.statusCode == 200 && response.body != null) {
      try {
        await LocalClient.organize(
          DataSourceEnum.client,
          cacheKey,
          jsonEncode(response.body),
          apiClient.getHeader(),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to cache transactions: $e');
        }
      }
      final dynamic body = response.body;
      final Map<String, dynamic> bodyMap = body is Map ? Map<String, dynamic>.from(body) : body as Map<String, dynamic>;
      return TransactionModel.fromJson(bodyMap);
    }
    
    return null;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}