import '../../domain/models/qidha_wallet_analytics.dart';
import '../../domain/repositories/qidha_wallet_repository.dart';
import '../api/qidha_wallet_api_client.dart';
import '../network_info.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/util/app_constants.dart';

class QidhaWalletRepositoryImpl implements QidhaWalletRepository {
  final QidhaWalletApiClient qidhaWalletApiClient;
  final NetworkInfo networkInfo;

  QidhaWalletRepositoryImpl({
    required this.qidhaWalletApiClient,
    required this.networkInfo,
  });

  @override
  Future<QidhaWalletAnalyticsSummary> getAnalyticsSummary({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await qidhaWalletApiClient.getAnalyticsSummary(
          period: period,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug(
              '🔍 QidhaWalletRepository: Analytics response keys: ${response['data']?.keys.toList()}');
          appLogger.debug(
              '🔍 QidhaWalletRepository: Has salary_day_info: ${response['data']?.containsKey('salary_day_info')}');
        }
        return QidhaWalletAnalyticsSummary.fromJson(response['data'] as Map<String, dynamic>);
      } catch (e) {
        throw Exception('Failed to fetch Qidha wallet analytics summary: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch Qidha wallet analytics summary.');
    }
  }

  @override
  Future<List<QidhaTransaction>> getTransactions({
    int offset = 0,
    int limit = 50,
    String type = 'all',
    String? dateFrom,
    String? dateTo,
    int? orderId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug(
              '🔍 QidhaWalletRepository: Loading transactions with offset=$offset, limit=$limit');
        }
        final response = await qidhaWalletApiClient.getTransactions(
          offset: offset,
          limit: limit,
          type: type,
          dateFrom: dateFrom,
          dateTo: dateTo,
          orderId: orderId,
        );

        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug('🔍 QidhaWalletRepository: Raw API response: $response');
        }

        final List<dynamic> transactionsJson;
        final dynamic transactionsData = response['transactions'];
        if (transactionsData != null && transactionsData is List) {
          transactionsJson = List<dynamic>.from(transactionsData);
        } else {
          transactionsJson = <dynamic>[];
        }

        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug(
              '🔍 QidhaWalletRepository: Found ${transactionsJson.length} transactions');
          appLogger.debug(
              '🔍 QidhaWalletRepository: Transaction IDs: ${transactionsJson.map((t) => t['id']).toList()}');
        }

        return transactionsJson
            .map((json) => QidhaTransaction.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch Qidha wallet transactions: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch Qidha wallet transactions.');
    }
  }

  @override
  Future<List<QidhaSpendingCategory>> getSpendingCategories({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await qidhaWalletApiClient.getSpendingCategories(
          period: period,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );

        final List<dynamic> categoriesJson =
            (response['data'] as Map<String, dynamic>)['categories'] as List<dynamic>? ?? [];
        return categoriesJson
            .map((json) => QidhaSpendingCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch Qidha wallet spending categories: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch Qidha wallet spending categories.');
    }
  }

  @override
  Future<List<QidhaMonthlyTrend>> getMonthlyTrends({
    int months = 6,
    int? year,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await qidhaWalletApiClient.getMonthlyTrends(
          months: months,
          year: year,
        );

        final List<dynamic> trendsJson = (response['data'] as Map<String, dynamic>)['monthly_data'] as List<dynamic>? ?? [];
        return trendsJson
            .map((json) => QidhaMonthlyTrend.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch Qidha wallet monthly trends: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch Qidha wallet monthly trends.');
    }
  }

  @override
  Future<Map<String, dynamic>> getDuePayments({
    String status = 'all',
    int offset = 0,
    int limit = 50,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return await qidhaWalletApiClient.getDuePayments(
          status: status,
          offset: offset,
          limit: limit,
        );
      } catch (e) {
        throw Exception('Failed to fetch Qidha wallet due payments: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch Qidha wallet due payments.');
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentHistory({
    int offset = 0,
    int limit = 50,
    String paymentType = 'all',
    String? dateFrom,
    String? dateTo,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return await qidhaWalletApiClient.getPaymentHistory(
          offset: offset,
          limit: limit,
          paymentType: paymentType,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
      } catch (e) {
        throw Exception('Failed to fetch Qidha wallet payment history: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch Qidha wallet payment history.');
    }
  }

  @override
  Future<Map<String, dynamic>> getSalaryDay() async {
    if (await networkInfo.isConnected) {
      try {
        return await qidhaWalletApiClient.getSalaryDay();
      } catch (e) {
        throw Exception('Failed to fetch Qidha wallet salary day: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch Qidha wallet salary day.');
    }
  }
}
