import 'package:get/get.dart';
import '../domain/models/analytics_summary.dart';
import '../domain/models/spending_trend.dart';
import '../domain/models/category_breakdown.dart';
import '../domain/models/most_purchased_product.dart';
import '../domain/models/analytics_insights.dart';
import '../domain/models/product_transaction.dart';
import '../domain/repositories/analytics_repository.dart';
import '../config/analytics_config.dart';

class AnalyticsController extends GetxController {
  final AnalyticsRepository _repository;

  AnalyticsController({required AnalyticsRepository repository})
      : _repository = repository;

  // Loading states
  final RxBool _isLoadingSummary = false.obs;
  final RxBool _isLoadingTrends = false.obs;
  final RxBool _isLoadingCategories = false.obs;
  final RxBool _isLoadingProducts = false.obs;
  final RxBool _isLoadingInsights = false.obs;
  final RxBool _isLoadingTransactionHistory = false.obs;

  // Error states
  final RxString _summaryError = ''.obs;
  final RxString _trendsError = ''.obs;
  final RxString _categoriesError = ''.obs;
  final RxString _productsError = ''.obs;
  final RxString _insightsError = ''.obs;
  final RxString _transactionHistoryError = ''.obs;

  // Data
  final Rx<AnalyticsSummary?> _summary = Rx<AnalyticsSummary?>(null);
  final Rx<SpendingTrendData?> _spendingTrend = Rx<SpendingTrendData?>(null);
  final Rx<CategoryBreakdown?> _categoryBreakdown =
      Rx<CategoryBreakdown?>(null);
  final RxList<MostPurchasedProduct> _mostPurchasedProducts =
      <MostPurchasedProduct>[].obs;
  final Rx<AnalyticsInsights?> _insights = Rx<AnalyticsInsights?>(null);
  final Rx<ProductTransactionHistory?> _transactionHistory =
      Rx<ProductTransactionHistory?>(null);

  // Filters and settings
  final RxString _currentTrendPeriod = 'week'.obs;
  final RxString _currentSortBy = 'frequency'.obs;

  // Getters
  bool get isLoadingSummary => _isLoadingSummary.value;
  bool get isLoadingTrends => _isLoadingTrends.value;
  bool get isLoadingCategories => _isLoadingCategories.value;
  bool get isLoadingProducts => _isLoadingProducts.value;
  bool get isLoadingInsights => _isLoadingInsights.value;
  bool get isLoadingTransactionHistory => _isLoadingTransactionHistory.value;

  // Error getters
  String get summaryError => _summaryError.value;
  String get trendsError => _trendsError.value;
  String get categoriesError => _categoriesError.value;
  String get productsError => _productsError.value;
  String get insightsError => _insightsError.value;
  String get transactionHistoryError => _transactionHistoryError.value;

  AnalyticsSummary? get summary => _summary.value;
  SpendingTrendData? get spendingTrend => _spendingTrend.value;
  CategoryBreakdown? get categoryBreakdown => _categoryBreakdown.value;
  List<MostPurchasedProduct> get mostPurchasedProducts =>
      _mostPurchasedProducts;
  AnalyticsInsights? get insights => _insights.value;
  ProductTransactionHistory? get transactionHistory =>
      _transactionHistory.value;

  String get currentTrendPeriod => _currentTrendPeriod.value;
  String get currentSortBy => _currentSortBy.value;

  // Available options
  List<String> get availableTrendPeriods => ['week', 'month'];
  List<Map<String, String>> get availableSortOptions => [
        {'key': 'frequency', 'label': 'frequency'.tr},
        {'key': 'amount', 'label': 'amount'.tr},
        {'key': 'name', 'label': 'name'.tr},
      ];

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  // Load all analytics data
  Future<void> loadAllData() async {
    await Future.wait([
      loadAnalyticsSummary(),
      loadSpendingTrends(_currentTrendPeriod.value),
      loadCategoryBreakdown(),
      loadMostPurchasedProducts(),
      loadAnalyticsInsights(),
    ]);
  }

  // Refresh all data
  Future<void> refreshData() async {
    await loadAllData();
  }

  // Load analytics summary
  Future<void> loadAnalyticsSummary() async {
    try {
      _isLoadingSummary.value = true;
      _summaryError.value = ''; // Clear previous error
      AnalyticsConfig.log('Loading analytics summary...');
      final summary = await _repository.getAnalyticsSummary();
      _summary.value = summary;
      AnalyticsConfig.log('Analytics summary loaded successfully');
    } catch (e) {
      _summaryError.value = e.toString();
      _summary.value = null; // Clear data on error
      AnalyticsConfig.log('Error loading analytics summary: $e');
    } finally {
      _isLoadingSummary.value = false;
    }
  }

  // Load product transaction history
  Future<void> loadProductTransactionHistory({
    required int itemId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _isLoadingTransactionHistory.value = true;
      _transactionHistoryError.value = '';
      AnalyticsConfig.log(
          'Loading product transaction history for item $itemId...');
      final result = await _repository.getProductTransactionHistory(
        itemId: itemId,
        limit: limit,
        offset: offset,
      );
      _transactionHistory.value = result;
      AnalyticsConfig.log('Product transaction history loaded successfully');
    } catch (e) {
      _transactionHistoryError.value = e.toString();
      _transactionHistory.value = null;
      AnalyticsConfig.log('Error loading product transaction history: $e');
    } finally {
      _isLoadingTransactionHistory.value = false;
    }
  }

  // Load spending trends
  Future<void> loadSpendingTrends(String period) async {
    try {
      _isLoadingTrends.value = true;
      _trendsError.value = ''; // Clear previous error
      _currentTrendPeriod.value = period;
      AnalyticsConfig.log('Loading spending trends for period: $period');
      final trend = await _repository.getSpendingTrends(period);
      _spendingTrend.value = trend;
      AnalyticsConfig.log('Spending trends loaded successfully');
    } catch (e) {
      _trendsError.value = e.toString();
      _spendingTrend.value = null; // Clear data on error
      AnalyticsConfig.log('Error loading spending trends: $e');
    } finally {
      _isLoadingTrends.value = false;
    }
  }

  // Load category breakdown
  Future<void> loadCategoryBreakdown() async {
    try {
      _isLoadingCategories.value = true;
      _categoriesError.value = ''; // Clear previous error
      AnalyticsConfig.log('Loading category breakdown...');
      final breakdown = await _repository.getCategoryBreakdown();
      _categoryBreakdown.value = breakdown;
      AnalyticsConfig.log('Category breakdown loaded successfully');
    } catch (e) {
      _categoriesError.value = e.toString();
      _categoryBreakdown.value = null; // Clear data on error
      AnalyticsConfig.log('Error loading category breakdown: $e');
    } finally {
      _isLoadingCategories.value = false;
    }
  }

  // Load most purchased products
  Future<void> loadMostPurchasedProducts() async {
    try {
      _isLoadingProducts.value = true;
      _productsError.value = ''; // Clear previous error
      AnalyticsConfig.log('Loading most purchased products...');
      final products = await _repository.getMostPurchasedProducts(
        sortBy: _currentSortBy.value,
      );
      _mostPurchasedProducts.value = products;
      AnalyticsConfig.log(
          'Most purchased products loaded successfully (${products.length} products)');
    } catch (e) {
      _productsError.value = e.toString();
      _mostPurchasedProducts.value = []; // Clear data on error
      AnalyticsConfig.log('Error loading most purchased products: $e');
    } finally {
      _isLoadingProducts.value = false;
    }
  }

  // Load analytics insights
  Future<void> loadAnalyticsInsights() async {
    try {
      _isLoadingInsights.value = true;
      _insightsError.value = ''; // Clear previous error
      AnalyticsConfig.log('Loading analytics insights...');
      final insights = await _repository.getAnalyticsInsights();
      _insights.value = insights;
      AnalyticsConfig.log('Analytics insights loaded successfully');
    } catch (e) {
      _insightsError.value = e.toString();
      _insights.value = null; // Clear data on error
      AnalyticsConfig.log('Error loading analytics insights: $e');
    } finally {
      _isLoadingInsights.value = false;
    }
  }

  // Sort most purchased products
  Future<void> sortMostPurchasedProducts(String sortBy) async {
    _currentSortBy.value = sortBy;
    await loadMostPurchasedProducts();
  }

  // Get product analytics (for deep dive)
  Future<Map<String, dynamic>?> getProductAnalytics(String itemId,
      {bool forceRefresh = false}) async {
    try {
      AnalyticsConfig.log(
          'Loading product analytics for item: $itemId${forceRefresh ? ' (force refresh)' : ''}');
      final analytics = await _repository.getProductAnalytics(itemId,
          forceRefresh: forceRefresh);
      AnalyticsConfig.log('Product analytics loaded successfully');
      return analytics;
    } catch (e) {
      AnalyticsConfig.log('Error loading product analytics: $e');
      return null;
    }
  }

  // Get all product transactions with pagination (like wallet transactions)
  Future<Map<String, dynamic>?> getAllProductTransactions({
    required int itemId,
    int offset = 1,
    int limit = 10,
  }) async {
    try {
      AnalyticsConfig.log(
          'Loading all product transactions for item: $itemId, offset: $offset');
      final transactions = await _repository.getAllProductTransactions(
        itemId: itemId,
        offset: offset,
        limit: limit,
      );
      AnalyticsConfig.log('All product transactions loaded successfully');
      return transactions;
    } catch (e) {
      AnalyticsConfig.log('Error loading all product transactions: $e');
      return null;
    }
  }

  // Export analytics data
  Future<String?> exportAnalyticsData(String format) async {
    try {
      AnalyticsConfig.log('Exporting analytics data in format: $format');
      final downloadUrl = await _repository.exportAnalyticsData(format: format);
      AnalyticsConfig.log('Analytics data exported successfully');
      return downloadUrl;
    } catch (e) {
      AnalyticsConfig.log('Error exporting analytics data: $e');
      return null;
    }
  }

  // Get insights by priority
  List<Insight> getInsightsByPriority(String priority) {
    if (_insights.value == null) return [];
    return _insights.value!.insights
        .where((insight) => insight.priority == priority)
        .toList();
  }

  // Get high priority insights
  List<Insight> get highPriorityInsights => getInsightsByPriority('high');

  // Get medium priority insights
  List<Insight> get mediumPriorityInsights => getInsightsByPriority('medium');

  // Get low priority insights
  List<Insight> get lowPriorityInsights => getInsightsByPriority('low');

  // Check if data is available
  bool get hasData =>
      _summary.value != null ||
      _spendingTrend.value != null ||
      _categoryBreakdown.value != null ||
      _mostPurchasedProducts.isNotEmpty;

  // Get loading state
  bool get isLoading =>
      _isLoadingSummary.value ||
      _isLoadingTrends.value ||
      _isLoadingCategories.value ||
      _isLoadingProducts.value ||
      _isLoadingInsights.value;

  // Check if any data has errors
  bool get hasErrors =>
      _summaryError.value.isNotEmpty ||
      _trendsError.value.isNotEmpty ||
      _categoriesError.value.isNotEmpty ||
      _productsError.value.isNotEmpty ||
      _insightsError.value.isNotEmpty;

  // Get all error messages
  List<String> get allErrors => [
        if (_summaryError.value.isNotEmpty) _summaryError.value,
        if (_trendsError.value.isNotEmpty) _trendsError.value,
        if (_categoriesError.value.isNotEmpty) _categoriesError.value,
        if (_productsError.value.isNotEmpty) _productsError.value,
        if (_insightsError.value.isNotEmpty) _insightsError.value,
      ];

  // Clear all errors
  void clearAllErrors() {
    _summaryError.value = '';
    _trendsError.value = '';
    _categoriesError.value = '';
    _productsError.value = '';
    _insightsError.value = '';
  }
}
