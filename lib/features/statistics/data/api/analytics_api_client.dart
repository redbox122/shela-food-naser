import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AnalyticsApiClient {
  final ApiClient apiClient;

  AnalyticsApiClient({required this.apiClient});

  // Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final response = await apiClient.getData(
        AppConstants.analyticsSummaryUri,
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch analytics summary: $e');
    }
  }

  // Get spending trends
  Future<Map<String, dynamic>> getSpendingTrends({
    required String period,
    required int range,
  }) async {
    try {
      // Convert period to API expected format
      String apiPeriod = period;
      if (period == 'week') apiPeriod = 'weekly';
      if (period == 'month') apiPeriod = 'month';
      if (period == 'day') apiPeriod = 'daily';

      final response = await apiClient.getData(
        '${AppConstants.analyticsSpendingTrendsUri}?period=$apiPeriod&range=$range',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch spending trends: $e');
    }
  }

  // Get most purchased products
  Future<Map<String, dynamic>> getMostPurchasedProducts({
    required String period,
    int limit = 10,
  }) async {
    try {
      // Convert period to API expected format (month, 3m, 6m, year, all)
      String apiPeriod = period;
      if (period == 'week') apiPeriod = 'month'; // Default to month for week
      if (period == 'month') apiPeriod = 'month';
      if (period == 'day') apiPeriod = 'month'; // Default to month for day

      final response = await apiClient.getData(
        '${AppConstants.analyticsMostPurchasedProductsUri}?period=$apiPeriod&limit=$limit',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch most purchased products: $e');
    }
  }

  // Get product details
  Future<Map<String, dynamic>> getProductDetails({
    required int itemId,
    required String period,
    bool forceRefresh = false,
  }) async {
    try {
      // Convert period to API expected format
      String apiPeriod = period;
      if (period == 'week') apiPeriod = 'weekly';
      if (period == 'month') apiPeriod = 'month';
      if (period == 'day') apiPeriod = 'daily';

      // ⚡ PERFORMANCE: Removed cache-busting parameters - now relying on HTTP cache headers
      // Use forceRefresh parameter with ApiClient's clearEtag() if needed
      final response = await apiClient.getData(
        '${AppConstants.analyticsProductDetailsUri}/$itemId?period=$apiPeriod',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch product details: $e');
    }
  }

  // Get all product transactions with pagination
  Future<Map<String, dynamic>> getAllProductTransactions({
    required int itemId,
    int offset = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiClient.getData(
        '${AppConstants.analyticsProductDetailsUri}/$itemId/transactions?offset=$offset&limit=$limit',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch product transactions: $e');
    }
  }

  // Get insights
  Future<Map<String, dynamic>> getInsights() async {
    try {
      final response = await apiClient.getData(
        AppConstants.analyticsInsightsUri,
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch insights: $e');
    }
  }

  // Get category breakdown
  Future<Map<String, dynamic>> getCategoryBreakdown({
    required String period,
  }) async {
    try {
      // Convert period to API expected format (week, month, 3m, 6m, year)
      String apiPeriod = period;
      if (period == 'week') apiPeriod = 'week';
      if (period == 'month') apiPeriod = 'month';
      if (period == 'day') apiPeriod = 'week'; // Default to week for day

      final response = await apiClient.getData(
        '${AppConstants.analyticsCategoryBreakdownUri}?period=$apiPeriod',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch category breakdown: $e');
    }
  }

  // Export analytics data
  Future<String> exportAnalyticsData({
    required String format,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await apiClient.getData(
        '${AppConstants.analyticsExportUri}?format=$format${startDate != null ? '&start_date=$startDate' : ''}${endDate != null ? '&end_date=$endDate' : ''}',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body['download_url'] as String;
    } catch (e) {
      throw Exception('Failed to export analytics data: $e');
    }
  }

  // Get product transaction history
  Future<Map<String, dynamic>> getProductTransactionHistory({
    required int itemId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.getData(
        '${AppConstants.analyticsProductTransactionHistoryUri}/$itemId?limit=$limit&offset=$offset',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch product transaction history: $e');
    }
  }

  // Get analytics health
  Future<Map<String, dynamic>> getAnalyticsHealth() async {
    try {
      final response = await apiClient.getData(
        '${AppConstants.analyticsBaseUri}/health',
        headers: _getHeaders(),
        useEtag: false,
      );

      // Check if the response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch analytics health: $e');
    }
  }

  // Get headers with authentication
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${apiClient.token}',
    };
  }
}
