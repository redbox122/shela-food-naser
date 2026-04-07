import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/wallet/domain/models/fund_bonus_model.dart';
import 'package:sixam_mart/features/wallet/domain/repositories/wallet_repository_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:universal_html/html.dart' as html;

class WalletRepository implements WalletRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  WalletRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response> addFundToWallet(double amount, String paymentMethod) async {
    final String? hostname = html.window.location.hostname;
    final String protocol = html.window.location.protocol;

    return await apiClient.postData(
        AppConstants.addFundUri,
        {
          'amount': amount,
          'payment_method': paymentMethod,
          'payment_platform': GetPlatform.isWeb ? 'web' : '',
          'callback': '$protocol//$hostname${RouteHelper.wallet}',
        },
        handleError: false);
  }

  @override
  Future<void> setWalletAccessToken(String token) {
    return sharedPreferences.setString(AppConstants.walletAccessToken, token);
  }

  @override
  String getWalletAccessToken() {
    return sharedPreferences.getString(AppConstants.walletAccessToken) ?? '';
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
  Future getList({int? offset, String? sortingType, bool isBonusList = false}) async {
    if (isBonusList) {
      return await _getWalletBonusList();
    } else {
      return await _getWalletTransactionList(offset.toString(), sortingType!);
    }
  }

  Future<TransactionModel?> _getWalletTransactionList(String offset, String sortingType) async {
    final String uri = '${AppConstants.walletTransactionUri}?offset=$offset&limit=10&type=$sortingType';
    final String cacheKey = 'wallet_transactions_${offset}_$sortingType';
    
    final Response response = await apiClient.getData(uri);

    // ⚡ 304 HANDLING: If 304 received, load cached data
    if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint('🔄 [WalletRepository] Received 304 for transactions - loading cache');
      }
      final String? cachedData = await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(cachedData);
          final Map<String, dynamic> cachedBody = decoded is Map<String, dynamic> 
              ? decoded 
              : (decoded as Map).cast<String, dynamic>();
          if (kDebugMode) {
            debugPrint('✅ [WalletRepository] Loaded cached transactions');
          }
          return TransactionModel.fromJson(cachedBody);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [WalletRepository] Failed to parse cached transactions: $e');
          }
          // Cache parsing failed - return null to trigger retry
          return null;
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ [WalletRepository] 304 received but no cache - making fresh request');
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

  Future<List<FundBonusModel>?> _getWalletBonusList() async {
    const String uri = AppConstants.walletBonusUri;
    const String cacheKey = 'wallet_bonuses';
    
    final Response response = await apiClient.getData(uri);

    // ⚡ 304 HANDLING: If 304 received, load cached data
    if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint('🔄 [WalletRepository] Received 304 for bonuses - loading cache');
      }
      final String? cachedData = await LocalClient.organize(DataSourceEnum.local, cacheKey, null, null);
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final List<dynamic> cachedList = jsonDecode(cachedData) as List<dynamic>;
          if (kDebugMode) {
            debugPrint('✅ [WalletRepository] Loaded cached bonuses: ${cachedList.length}');
          }
          final List<FundBonusModel> fundBonusList = [];
          for (final value in cachedList) {
            fundBonusList.add(FundBonusModel.fromJson(Map<String, dynamic>.from(value as Map)));
          }
          return fundBonusList;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [WalletRepository] Failed to parse cached bonuses: $e');
          }
          // Cache parsing failed - return empty list
          return [];
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ [WalletRepository] 304 received but no cache - making fresh request');
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
              debugPrint('⚠️ Failed to cache bonuses: $e');
            }
          }
          final List<FundBonusModel> fundBonusList = [];
          final List<dynamic> bodyList = freshResponse.body as List<dynamic>;
          for (final value in bodyList) {
            fundBonusList.add(FundBonusModel.fromJson(Map<String, dynamic>.from(value as Map)));
          }
          return fundBonusList;
        }
        return [];
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
          debugPrint('⚠️ Failed to cache bonuses: $e');
        }
      }
      
      final List<FundBonusModel> fundBonusList = [];
      final List<dynamic> bodyList = response.body as List<dynamic>;
      for (final value in bodyList) {
        fundBonusList.add(FundBonusModel.fromJson(Map<String, dynamic>.from(value as Map)));
      }
      return fundBonusList;
    }
    
    // Return empty list if no data (not null - empty array is valid)
    return [];
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> requestExchange(String number) async {
    final Response response = await apiClient.postData(AppConstants.requestExchangeWalletMoney, {'userReceiver': number});
    return response;
  }

  @override
  Future<Response> exchangeWallet(String number, String otp, String userOtp, String money) async {
    final Response response = await apiClient.postData(AppConstants.exchangeWalletMoney, {
      'userReceiver': number,
      'otpUser': otp,
      'otpReceiver': userOtp,
      'walletMoney': money,
    });
    return response;
  }
}
