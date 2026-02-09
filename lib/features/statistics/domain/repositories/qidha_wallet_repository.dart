import '../models/qidha_wallet_analytics.dart';

abstract class QidhaWalletRepository {
  Future<QidhaWalletAnalyticsSummary> getAnalyticsSummary({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  });

  Future<List<QidhaTransaction>> getTransactions({
    int offset = 0,
    int limit = 50,
    String type = 'all',
    String? dateFrom,
    String? dateTo,
    int? orderId,
  });

  Future<List<QidhaSpendingCategory>> getSpendingCategories({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  });

  Future<List<QidhaMonthlyTrend>> getMonthlyTrends({
    int months = 6,
    int? year,
  });

  Future<Map<String, dynamic>> getDuePayments({
    String status = 'all',
    int offset = 0,
    int limit = 50,
  });

  Future<Map<String, dynamic>> getPaymentHistory({
    int offset = 0,
    int limit = 50,
    String paymentType = 'all',
    String? dateFrom,
    String? dateTo,
  });

  Future<Map<String, dynamic>> getSalaryDay();
}
