import '../network_info.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/models/analytics_summary.dart';
import '../../domain/models/spending_trend.dart';
import '../../domain/models/category_breakdown.dart';
import '../../domain/models/most_purchased_product.dart';
import '../../domain/models/analytics_insights.dart';
import '../../domain/models/product_transaction.dart';
import '../api/analytics_api_client.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsApiClient analyticsApiClient;
  final NetworkInfo networkInfo;

  AnalyticsRepositoryImpl({
    required this.analyticsApiClient,
    required this.networkInfo,
  });

  @override
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await analyticsApiClient.getAnalyticsSummary();
        return AnalyticsSummary.fromJson(response);
      } catch (e) {
        // If API is not available, return mock data for development
        if (e.toString().contains('404') ||
            e.toString().contains('route could not be found')) {
          return const AnalyticsSummary(
            monthlySpending: 0.0,
            weeklySpending: 0.0,
            remainingBalance: 19554.87,
            spendingTrend: SpendingTrend(
              monthlyChange: 0.0,
              weeklyChange: 0.0,
              trendDirection: 'stable',
            ),
            periodComparison: PeriodComparison(
              vsLastMonth: 0.0,
              vsLastWeek: 0.0,
            ),
          );
        }
        throw Exception('Failed to fetch analytics summary: $e');
      }
    } else {
      throw Exception('No internet connection. Cannot fetch analytics data.');
    }
  }

  @override
  Future<SpendingTrendData> getSpendingTrends(String period) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await analyticsApiClient.getSpendingTrends(
          period: period,
          range: 8,
        );
        return SpendingTrendData.fromJson(response);
      } catch (e) {
        // If API is not available, return mock data for development
        if (e.toString().contains('404') ||
            e.toString().contains('route could not be found')) {
          return SpendingTrendData(
            period: period,
            data: List.generate(
                8,
                (index) => SpendingDataPoint(
                      bucket: 'day_${index + 1}',
                      amount: 0.0,
                      orders: 0,
                      date: DateTime.now()
                          .subtract(Duration(days: 7 - index))
                          .toIso8601String(),
                    )),
            totalSpent: 0.0,
            totalOrders: 0,
          );
        }
        throw Exception('Failed to fetch spending trends: $e');
      }
    } else {
      throw Exception('No internet connection. Cannot fetch spending trends.');
    }
  }

  @override
  Future<CategoryBreakdown> getCategoryBreakdown() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await analyticsApiClient.getCategoryBreakdown(
          period: 'month',
        );
        return CategoryBreakdown.fromJson(response);
      } catch (e) {
        // If API is not available, return mock data for development
        if (e.toString().contains('404') ||
            e.toString().contains('route could not be found')) {
          return const CategoryBreakdown(
            categories: [],
            totalSpent: 0.0,
            totalItems: 0,
          );
        }
        throw Exception('Failed to fetch category breakdown: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch category breakdown.');
    }
  }

  @override
  Future<List<MostPurchasedProduct>> getMostPurchasedProducts({
    String sortBy = 'frequency',
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await analyticsApiClient.getMostPurchasedProducts(
          period: 'month',
          limit: limit,
        );
        final dynamic productsRaw = response['products'];
        final dynamic dataRaw = response['data'];

        List<dynamic> productsJson = <dynamic>[];
        if (productsRaw is List) {
          productsJson = productsRaw;
        } else if (productsRaw is Map<String, dynamic>) {
          final dynamic nestedProducts = productsRaw['products'] ??
              productsRaw['items'] ??
              productsRaw['data'] ??
              productsRaw['list'];
          if (nestedProducts is List) {
            productsJson = nestedProducts;
          }
        } else if (dataRaw is List) {
          productsJson = dataRaw;
        } else if (dataRaw is Map<String, dynamic>) {
          final dynamic nestedProducts =
              dataRaw['products'] ?? dataRaw['items'] ?? dataRaw['list'];
          if (nestedProducts is List) {
            productsJson = nestedProducts;
          }
        }

        final products = productsJson
            .whereType<Map<String, dynamic>>()
            .map(MostPurchasedProduct.fromJson)
            .toList();
        return products;
      } catch (e) {
        throw Exception('Failed to fetch most purchased products: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch most purchased products.');
    }
  }

  @override
  Future<Map<String, dynamic>> getProductAnalytics(String itemId,
      {bool forceRefresh = false}) async {
    if (await networkInfo.isConnected) {
      try {
        return await analyticsApiClient.getProductDetails(
          itemId: int.parse(itemId),
          period: 'month',
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        throw Exception('Failed to fetch product analytics: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch product analytics.');
    }
  }

  @override
  Future<AnalyticsInsights> getAnalyticsInsights() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await analyticsApiClient.getInsights();
        return AnalyticsInsights.fromJson(response);
      } catch (e) {
        // If API is not available, return mock data for development
        if (e.toString().contains('404') ||
            e.toString().contains('route could not be found')) {
          return AnalyticsInsights(
            insights: [],
            smartTips: [],
            generatedAt: DateTime.now().toIso8601String(),
          );
        }
        throw Exception('Failed to fetch analytics insights: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch analytics insights.');
    }
  }

  @override
  Future<String> exportAnalyticsData({
    required String format,
    String? startDate,
    String? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return await analyticsApiClient.exportAnalyticsData(
          format: format,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (e) {
        throw Exception('Failed to export analytics data: $e');
      }
    } else {
      throw Exception('No internet connection. Cannot export data.');
    }
  }

  @override
  Future<Map<String, dynamic>> getAnalyticsHealth() async {
    if (await networkInfo.isConnected) {
      try {
        return await analyticsApiClient.getAnalyticsHealth();
      } catch (e) {
        return {
          'status': 'error',
          'message': 'Analytics service unavailable: $e',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } else {
      return {
        'status': 'offline',
        'message': 'No internet connection',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<ProductTransactionHistory> getProductTransactionHistory({
    required int itemId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await analyticsApiClient.getProductTransactionHistory(
          itemId: itemId,
          limit: limit,
          offset: offset,
        );
        return ProductTransactionHistory.fromJson(response);
      } catch (e) {
        // If API is not available, return mock data for development
        if (e.toString().contains('404') ||
            e.toString().contains('route could not be found')) {
          return ProductTransactionHistory(
            transactions: [],
            totalTransactions: 0,
            totalSpent: 0.0,
            averageQuantity: 0.0,
            lastPurchaseDate: '',
            purchaseFrequencyDays: 0,
            priceRangeMin: 0.0,
            priceRangeMax: 0.0,
            trend: 'stable',
          );
        }
        throw Exception('Failed to fetch product transaction history: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch product transaction history.');
    }
  }

  // Get all product transactions with pagination (like wallet transactions)
  @override
  Future<Map<String, dynamic>> getAllProductTransactions({
    required int itemId,
    int offset = 1,
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return await analyticsApiClient.getAllProductTransactions(
          itemId: itemId,
          offset: offset,
          limit: limit,
        );
      } catch (e) {
        throw Exception('Failed to fetch all product transactions: $e');
      }
    } else {
      throw Exception(
          'No internet connection. Cannot fetch product transactions.');
    }
  }
}
