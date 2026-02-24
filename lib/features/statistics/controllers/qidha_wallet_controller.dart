import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/qidha_wallet_analytics.dart';
import '../domain/repositories/qidha_wallet_repository.dart';
import '../../category/domain/models/category_model.dart';
import '../../category/controllers/category_controller.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class QidhaWalletController extends GetxController {
  final QidhaWalletRepository _repository;

  QidhaWalletController({required QidhaWalletRepository repository})
      : _repository = repository;

  // Loading states
  final RxBool _isLoadingAnalytics = false.obs;
  final RxBool _isLoadingTransactions = false.obs;
  final RxBool _isLoadingCategories = false.obs;
  final RxBool _isLoadingTrends = false.obs;
  final RxBool _isLoadingDuePayments = false.obs;
  final RxBool _isLoadingPaymentHistory = false.obs;

  // Error states
  final RxString _analyticsError = ''.obs;
  final RxString _transactionsError = ''.obs;
  final RxString _categoriesError = ''.obs;
  final RxString _trendsError = ''.obs;
  final RxString _duePaymentsError = ''.obs;
  final RxString _paymentHistoryError = ''.obs;

  // Data
  final Rx<QidhaWalletAnalyticsSummary?> _analyticsSummary =
      Rx<QidhaWalletAnalyticsSummary?>(null);
  final RxList<QidhaTransaction> _transactions = <QidhaTransaction>[].obs;
  final RxList<QidhaSpendingCategory> _spendingCategories =
      <QidhaSpendingCategory>[].obs;
  final RxList<QidhaMonthlyTrend> _monthlyTrends = <QidhaMonthlyTrend>[].obs;
  final Rx<Map<String, dynamic>?> _duePayments =
      Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> _paymentHistory =
      Rx<Map<String, dynamic>?>(null);

  // Getters
  bool get isLoadingAnalytics => _isLoadingAnalytics.value;
  bool get isLoadingTransactions => _isLoadingTransactions.value;
  bool get isLoadingCategories => _isLoadingCategories.value;
  bool get isLoadingTrends => _isLoadingTrends.value;
  bool get isLoadingDuePayments => _isLoadingDuePayments.value;
  bool get isLoadingPaymentHistory => _isLoadingPaymentHistory.value;

  String get analyticsError => _analyticsError.value;
  String get transactionsError => _transactionsError.value;
  String get categoriesError => _categoriesError.value;
  String get trendsError => _trendsError.value;
  String get duePaymentsError => _duePaymentsError.value;
  String get paymentHistoryError => _paymentHistoryError.value;

  QidhaWalletAnalyticsSummary? get analyticsSummary => _analyticsSummary.value;
  List<QidhaTransaction> get transactions => _transactions;
  List<QidhaSpendingCategory> get spendingCategories => _spendingCategories;
  List<QidhaMonthlyTrend> get monthlyTrends => _monthlyTrends;
  Map<String, dynamic>? get duePayments => _duePayments.value;
  Map<String, dynamic>? get paymentHistory => _paymentHistory.value;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  // Load all Qidha wallet data
  Future<void> loadAllData() async {
    await Future.wait([
      loadAnalyticsSummary(),
      loadAllTransactions(), // Load all transactions
      loadSpendingCategories(),
      loadMonthlyTrends(),
      loadDuePayments(),
    ]);
  }

  // Load all transactions by making multiple API calls if needed
  Future<void> loadAllTransactions() async {
    _isLoadingTransactions.value = true;
    _transactionsError.value = '';
    _transactions.clear();

    try {
      if (kDebugMode) {
        appLogger.debug('🔍 QidhaWalletController: Loading ALL transactions...');
      }

      // First, get the analytics summary to know how many orders were paid
      final summary = await _repository.getAnalyticsSummary();
      final totalOrdersPaid = summary.paymentFrequency.totalOrdersPaid;

      if (kDebugMode) {
        appLogger.debug(
            '🔍 QidhaWalletController: Total orders paid according to analytics: $totalOrdersPaid');
      }

      // Load transactions in batches
      int offset = 0;
      const int batchSize = 50;
      bool hasMoreData = true;

      while (hasMoreData) {
        if (kDebugMode) {
          appLogger.debug(
              '🔍 QidhaWalletController: Loading batch starting at offset $offset');
        }

        final batch = await _repository.getTransactions(
          offset: offset,
        );

        if (kDebugMode) {
          appLogger.debug(
              '🔍 QidhaWalletController: Loaded ${batch.length} transactions in this batch');
        }

        if (batch.isEmpty) {
          hasMoreData = false;
        } else {
          _transactions.addAll(batch);
          offset += batchSize;

          // Stop if we've loaded enough transactions or if batch is smaller than batch size
          if (batch.length < batchSize ||
              _transactions.length >= totalOrdersPaid) {
            hasMoreData = false;
          }
        }
      }

      if (kDebugMode) {
        appLogger.info(
            '🔍 QidhaWalletController: Finished loading. Total transactions loaded: ${_transactions.length}');
      }
    } catch (e) {
      _transactionsError.value = e.toString();
      if (kDebugMode) {
        appLogger.error('🔍 QidhaWalletController: Error loading all transactions: $e', e);
      }
    } finally {
      _isLoadingTransactions.value = false;
    }
  }

  // Load analytics summary
  Future<void> loadAnalyticsSummary({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  }) async {
    _isLoadingAnalytics.value = true;
    _analyticsError.value = '';

    try {
      final summary = await _repository.getAnalyticsSummary(
        period: period,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      if (kDebugMode) {
        appLogger.debug(
            '🔍 QidhaWalletController: Analytics summary loaded, salaryDayInfo: ${summary.salaryDayInfo != null}');
      }
      _analyticsSummary.value = summary;
    } catch (e) {
      _analyticsError.value = e.toString();
    } finally {
      _isLoadingAnalytics.value = false;
    }
  }

  // Load transactions
  Future<void> loadTransactions({
    int offset = 0,
    int limit = 50,
    String type = 'all',
    String? dateFrom,
    String? dateTo,
    int? orderId,
    bool loadMore = false,
  }) async {
    _isLoadingTransactions.value = true;
    _transactionsError.value = '';

    try {
      if (kDebugMode) {
        appLogger.debug(
            '🔍 QidhaWalletController: Loading transactions with offset=$offset, limit=$limit, loadMore=$loadMore');
      }
      final transactions = await _repository.getTransactions(
        offset: offset,
        limit: limit,
        type: type,
        dateFrom: dateFrom,
        dateTo: dateTo,
        orderId: orderId,
      );

      if (kDebugMode) {
        appLogger.debug(
            '🔍 QidhaWalletController: Received ${transactions.length} transactions');
        appLogger.debug(
            '🔍 QidhaWalletController: Transaction order IDs: ${transactions.map((t) => t.orderId).toList()}');
      }

      if (loadMore) {
        _transactions.addAll(transactions);
        if (kDebugMode) {
          appLogger.debug(
              '🔍 QidhaWalletController: Added to existing list. Total transactions: ${_transactions.length}');
        }
      } else {
        _transactions.assignAll(transactions);
        if (kDebugMode) {
          appLogger.debug(
              '🔍 QidhaWalletController: Replaced list. Total transactions: ${_transactions.length}');
        }
      }
    } catch (e) {
      _transactionsError.value = e.toString();
      if (kDebugMode) {
        appLogger.error('🔍 QidhaWalletController: Error loading transactions: $e', e);
      }
    } finally {
      _isLoadingTransactions.value = false;
    }
  }

  // Load spending categories
  Future<void> loadSpendingCategories({
    String period = 'month',
    String? dateFrom,
    String? dateTo,
  }) async {
    _isLoadingCategories.value = true;
    _categoriesError.value = '';

    try {
      final categories = await _repository.getSpendingCategories(
        period: period,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      _spendingCategories.assignAll(categories);

      // Update categories with images after loading
      updateSpendingCategoriesWithImages();
    } catch (e) {
      _categoriesError.value = e.toString();
    } finally {
      _isLoadingCategories.value = false;
    }
  }

  // Load monthly trends
  Future<void> loadMonthlyTrends({
    int months = 6,
    int? year,
  }) async {
    _isLoadingTrends.value = true;
    _trendsError.value = '';

    try {
      final trends = await _repository.getMonthlyTrends(
        months: months,
        year: year,
      );
      _monthlyTrends.assignAll(trends);
    } catch (e) {
      _trendsError.value = e.toString();
    } finally {
      _isLoadingTrends.value = false;
    }
  }

  // Load due payments
  Future<void> loadDuePayments({
    String status = 'all',
    int offset = 0,
    int limit = 50,
  }) async {
    _isLoadingDuePayments.value = true;
    _duePaymentsError.value = '';

    try {
      final duePayments = await _repository.getDuePayments(
        status: status,
        offset: offset,
        limit: limit,
      );
      _duePayments.value = duePayments;
    } catch (e) {
      _duePaymentsError.value = e.toString();
    } finally {
      _isLoadingDuePayments.value = false;
    }
  }

  // Load payment history
  Future<void> loadPaymentHistory({
    int offset = 0,
    int limit = 50,
    String paymentType = 'all',
    String? dateFrom,
    String? dateTo,
  }) async {
    _isLoadingPaymentHistory.value = true;
    _paymentHistoryError.value = '';

    try {
      final paymentHistory = await _repository.getPaymentHistory(
        offset: offset,
        limit: limit,
        paymentType: paymentType,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      _paymentHistory.value = paymentHistory;
    } catch (e) {
      _paymentHistoryError.value = e.toString();
    } finally {
      _isLoadingPaymentHistory.value = false;
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await loadAllData();
  }

  // Clear all data
  void clearData() {
    _analyticsSummary.value = null;
    _transactions.clear();
    _spendingCategories.clear();
    _monthlyTrends.clear();
    _duePayments.value = null;
    _paymentHistory.value = null;
  }

  // Get category image by ID
  String? getCategoryImageById(int categoryId) {
    try {
      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        if (kDebugMode) {
          appLogger.debug(
              'CategoryController found, categoryList length: ${categoryController.categoryList?.length ?? 0}');
        }

        if (categoryController.categoryList != null &&
            categoryController.categoryList!.isNotEmpty) {
          final category = categoryController.categoryList!.firstWhere(
            (cat) => cat.id == categoryId,
            orElse: () => CategoryModel(),
          );

          if (category.id != null) {
            if (kDebugMode) {
              appLogger.debug(
                  'Found category: ${category.name}, Image: ${category.imageFullUrl}');
            }
            return category.imageFullUrl;
          } else {
            if (kDebugMode) {
              appLogger.debug('Category with ID $categoryId not found in categoryList');
              // Print available category IDs for debugging
              final availableIds =
                  categoryController.categoryList!.map((cat) => cat.id).toList();
              appLogger.debug('Available category IDs: $availableIds');
            }
          }
        } else {
          if (kDebugMode) {
            appLogger.debug('CategoryList is null or empty');
          }
        }
      } else {
        if (kDebugMode) {
          appLogger.debug('CategoryController not registered');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('Error getting category image for ID $categoryId: $e', e);
      }
    }
    return null;
  }

  // Update spending categories with images
  void updateSpendingCategoriesWithImages() async {
    // Ensure CategoryController is loaded and categories are fetched
    if (Get.isRegistered<CategoryController>()) {
      final categoryController = Get.find<CategoryController>();

      // Load categories if not already loaded
      if (categoryController.categoryList == null ||
          categoryController.categoryList!.isEmpty) {
        if (kDebugMode) {
          appLogger.debug('Loading categories...');
        }
        await categoryController.getCategoryList(true);
      }

      // Wait a bit more to ensure categories are fully loaded
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedCategories = _spendingCategories.map((category) {
        final imageUrl = getCategoryImageById(category.categoryId);
        if (kDebugMode) {
          appLogger.debug('Category ID: ${category.categoryId}, Image URL: $imageUrl');
        }
        return QidhaSpendingCategory(
          categoryId: category.categoryId,
          categoryName: category.categoryName,
          categoryNameAr: category.categoryNameAr,
          totalSpent: category.totalSpent,
          transactionCount: category.transactionCount,
          percentage: category.percentage,
          averageOrderValue: category.averageOrderValue,
          lastPurchase: category.lastPurchase,
          categoryImageUrl: imageUrl,
        );
      }).toList();

      _spendingCategories.value = updatedCategories;
    } else {
      if (kDebugMode) {
        appLogger.debug('CategoryController not registered, cannot load category images');
      }
    }
  }
}
