import '../models/analytics_summary.dart';
import '../models/spending_trend.dart';
import '../models/category_breakdown.dart';
import '../models/most_purchased_product.dart';
import '../models/analytics_insights.dart';
import '../models/product_transaction.dart';

abstract class AnalyticsRepository {
  // Analytics summary
  Future<AnalyticsSummary> getAnalyticsSummary();

  // Spending trends
  Future<SpendingTrendData> getSpendingTrends(String period);

  // Category breakdown
  Future<CategoryBreakdown> getCategoryBreakdown();

  // Most purchased products
  Future<List<MostPurchasedProduct>> getMostPurchasedProducts({
    String sortBy = 'frequency',
    int limit = 10,
  });

  // Product analytics (deep dive)
  Future<Map<String, dynamic>> getProductAnalytics(String itemId,
      {bool forceRefresh = false});

  // Analytics insights
  Future<AnalyticsInsights> getAnalyticsInsights();

  // Export analytics data
  Future<String> exportAnalyticsData({
    required String format,
    String? startDate,
    String? endDate,
  });

  // Health check
  Future<Map<String, dynamic>> getAnalyticsHealth();

  // Product transaction history
  Future<ProductTransactionHistory> getProductTransactionHistory({
    required int itemId,
    int limit = 50,
    int offset = 0,
  });

  // Get all product transactions with pagination (like wallet transactions)
  Future<Map<String, dynamic>> getAllProductTransactions({
    required int itemId,
    int offset = 1,
    int limit = 10,
  });
}
