import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

class QidhaWalletApiClient {
  final ApiClient apiClient;

  QidhaWalletApiClient({required this.apiClient});

  // Get transaction history
  Future<Map<String, dynamic>> getTransactions({
    int offset = 0,
    int limit = 50,
    String type = 'all',
    String? dateFrom,
    String? dateTo,
    int? orderId,
  }) async {
    try {
      const String url = '${AppConstants.qidhaWalletBaseUri}/transactions';
      final Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
        'type': type,
      };

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (orderId != null) queryParams['order_id'] = orderId;

      final response = await apiClient.getData(
        url,
        headers: _getHeaders(),
        query: queryParams,
        useEtag: false,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch Qidha wallet transactions: $e');
    }
  }

  // Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      const String url = '${AppConstants.qidhaWalletBaseUri}/analytics/summary';
      final Map<String, dynamic> queryParams = {'period': period};

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await apiClient.getData(
        url,
        headers: _getHeaders(),
        query: queryParams,
        useEtag: false,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch Qidha wallet analytics summary: $e');
    }
  }

  // Get due payments
  Future<Map<String, dynamic>> getDuePayments({
    String status = 'all',
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      const String url = '${AppConstants.qidhaWalletBaseUri}/due-payments';
      final Map<String, dynamic> queryParams = {
        'status': status,
        'offset': offset,
        'limit': limit,
      };

      final response = await apiClient.getData(
        url,
        headers: _getHeaders(),
        query: queryParams,
        useEtag: false,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch Qidha wallet due payments: $e');
    }
  }

  // Get payment history
  Future<Map<String, dynamic>> getPaymentHistory({
    int offset = 0,
    int limit = 50,
    String paymentType = 'all',
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      const String url = '${AppConstants.qidhaWalletBaseUri}/payment-history';
      final Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
        'payment_type': paymentType,
      };

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await apiClient.getData(
        url,
        headers: _getHeaders(),
        query: queryParams,
        useEtag: false,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch Qidha wallet payment history: $e');
    }
  }

  // Get spending categories
  Future<Map<String, dynamic>> getSpendingCategories({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      const String url =
          '${AppConstants.qidhaWalletBaseUri}/spending-categories';
      final Map<String, dynamic> queryParams = {'period': period};

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await apiClient.getData(
        url,
        headers: _getHeaders(),
        query: queryParams,
        useEtag: false,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch Qidha wallet spending categories: $e');
    }
  }

  // Get monthly trends
  Future<Map<String, dynamic>> getMonthlyTrends({
    int months = 6,
    int? year,
  }) async {
    try {
      const String url = '${AppConstants.qidhaWalletBaseUri}/monthly-trends';
      final Map<String, dynamic> queryParams = {'months': months};

      if (year != null) queryParams['year'] = year;

      final response = await apiClient.getData(
        url,
        headers: _getHeaders(),
        query: queryParams,
        useEtag: false,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch Qidha wallet monthly trends: $e');
    }
  }

  // Get salary day information
  Future<Map<String, dynamic>> getSalaryDay() async {
    try {
      const String url = '${AppConstants.qidhaWalletBaseUri}/salary-day';

      final response = await apiClient.getData(
        url,
        headers: _getHeaders(),
        useEtag: false,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error ${response.statusCode}: ${response.statusText}');
      }

      return response.body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch Qidha wallet salary day: $e');
    }
  }

  // Get headers with authentication
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${apiClient.token}',
      'X-localization': 'ar',
    };
  }
}
