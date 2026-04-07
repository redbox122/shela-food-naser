
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/appBar.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/analytics_controller.dart';
import '../widgets/enhanced_summary_cards.dart';
import '../widgets/simple_charts_banner.dart';
import '../widgets/enhanced_most_purchased_products.dart';
import '../controllers/qidha_wallet_controller.dart';
import '../domain/repositories/qidha_wallet_repository.dart';
import '../data/repositories/qidha_wallet_repository_impl.dart';
import '../data/api/qidha_wallet_api_client.dart';
import '../data/network_info.dart';
import '../../wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import '../../../common/widgets/history_item_widget.dart';
import '../../../common/models/transaction_model.dart';
import '../../../common/widgets/smart_image.dart';

class StatisticsScreenWithToggle extends StatefulWidget {
  const StatisticsScreenWithToggle({super.key});

  @override
  StatisticsScreenWithToggleState createState() =>
      StatisticsScreenWithToggleState();
}

class StatisticsScreenWithToggleState extends State<StatisticsScreenWithToggle>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late int selectedTabIndex;

  @override
  void initState() {
    super.initState();
    selectedTabIndex = 0;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<AnalyticsController>(
      init: Get.find<AnalyticsController>(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.wtColor,
          appBar: custom_AppBar(context,
              title: 'statistics'.tr,
              icon: Icons.arrow_back_sharp,
              titleIcon: Icons.shopping_bag_outlined),
          body: Column(
            children: [
              _buildStyledTabBar(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEnhancedView(controller),
                    _buildSimpleView(controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyledTabBar(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3.0,
            color: AppColors.primaryColor,
          ),
          insets: EdgeInsets.symmetric(horizontal: 50),
        ),
        tabs: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('general'.tr, style: robotoBold),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('qidha'.tr, style: robotoBold),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedView(AnalyticsController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      color: AppColors.primaryColor,
      child: controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Summary Cards
                    EnhancedSummaryCards(),
                    SizedBox(height: Dimensions.paddingSizeLarge),

                    // Simple Charts
                    SimpleChartsBanner(),
                    SizedBox(height: Dimensions.paddingSizeLarge),

                    // Enhanced Most Purchased Products
                    EnhancedMostPurchasedProducts(),
                    SizedBox(height: Dimensions.paddingSizeLarge),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSimpleView(AnalyticsController controller) {
    // Ensure QidhaWalletRepository is registered first
    if (!Get.isRegistered<QidhaWalletRepository>()) {
      Get.lazyPut<NetworkInfo>(() => NetworkInfo());
      Get.lazyPut<QidhaWalletApiClient>(
          () => QidhaWalletApiClient(apiClient: Get.find()));
      Get.lazyPut<QidhaWalletRepository>(() => QidhaWalletRepositoryImpl(
            qidhaWalletApiClient: Get.find<QidhaWalletApiClient>(),
            networkInfo: Get.find<NetworkInfo>(),
          ));
    }

    // Ensure QidhaWalletController is registered
    if (!Get.isRegistered<QidhaWalletController>()) {
      Get.lazyPut<QidhaWalletController>(() => QidhaWalletController(
            repository: Get.find<QidhaWalletRepository>(),
          ));
    }

    return GetX<QidhaWalletController>(
      builder: (qidhaController) {
        return RefreshIndicator(
          onRefresh: () async {
            await qidhaController.refreshData();
          },
          color: AppColors.primaryColor,
          child: qidhaController.isLoadingAnalytics
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Qidha Wallet Header (using API data)
                        _buildQidhaWalletHeader(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Qidha Wallet Balance Overview (using API data)
                        _buildQidhaBalanceOverview(qidhaController),
                        const SizedBox(
                            height: Dimensions
                                .paddingSizeDefault), // Reduced from Large

                        // Qidha Wallet Spending Analytics (using API data)
                        _buildQidhaSpendingAnalytics(qidhaController),
                        const SizedBox(
                            height: Dimensions
                                .paddingSizeDefault), // Reduced from Large

                        // Qidha Wallet Due Payments (using real API)
                        _buildQidhaDuePayments(qidhaController),
                        const SizedBox(
                            height: Dimensions
                                .paddingSizeDefault), // Reduced from Large

                        // Qidha Wallet Transaction History (using real API)
                        _buildQidhaTransactionHistory(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Qidha Wallet Spending Categories (using real API)
                        _buildQidhaSpendingCategories(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Qidha Wallet Monthly Trends (using real API)
                        _buildQidhaMonthlyTrends(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Qidha Wallet Payment History (using real API)
                        _buildQidhaPaymentHistory(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Qidha Wallet Spending Calendar Heatmap (using real API)
                        _buildQidhaSpendingCalendar(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Qidha Wallet Due Payments Timeline (using real API)
                        _buildQidhaDuePaymentsTimeline(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Salary Day & Due Payments Overview
                        _buildQidhaSalaryDayOverview(qidhaController),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // Helper function to convert Western Arabic numerals to Eastern Arabic numerals
  String _convertToArabicNumerals(String text) {
    const Map<String, String> arabicNumerals = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩'
    };

    return text.split('').map((char) => arabicNumerals[char] ?? char).join();
  }



  String _getTrendText(String trendDirection) {
    switch (trendDirection.toLowerCase()) {
      case 'increasing':
      case 'up':
        return 'increasing'.tr;
      case 'decreasing':
      case 'down':
        return 'decreasing'.tr;
      default:
        return 'stable'.tr;
    }
  }

  // Qidha Wallet Header
  Widget _buildQidhaWalletHeader(QidhaWalletController controller) {
    if (controller.isLoadingAnalytics) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.analyticsSummary == null) {
      return const SizedBox.shrink();
    }

    final walletInfo = controller.analyticsSummary!.walletInfo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'محفظة قيدها',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'الحالة: ${walletInfo.status == 'Active' ? 'نشط' : 'غير نشط'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      walletInfo.status == 'Active' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  walletInfo.status == 'Active' ? 'نشط' : 'غير نشط',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Qidha Wallet Balance Overview
  Widget _buildQidhaBalanceOverview(QidhaWalletController controller) {
    if (controller.isLoadingAnalytics) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.analyticsSummary == null) {
      return const SizedBox.shrink();
    }

    final walletInfo = controller.analyticsSummary!.walletInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نظرة عامة على الرصيد',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12), // Reduced from 16
        SizedBox(
          height: 140, // Reduced from 200
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQidhaBalanceCard(
                'الرصيد المتاح',
                '${_convertToArabicNumerals(walletInfo.availableBalance.toStringAsFixed(2))} ر.س',
                Icons.account_balance_wallet,
                Colors.green,
                'المبلغ المتاح للإنفاق',
              ),
              _buildQidhaBalanceCard(
                'الرصيد المستخدم',
                '${_convertToArabicNumerals(walletInfo.usedBalance.toStringAsFixed(2))} ر.س',
                Icons.shopping_cart,
                Colors.orange,
                'المبلغ المنفق حتى الآن',
              ),
              _buildQidhaBalanceCard(
                'الحد الائتماني',
                '${_convertToArabicNumerals(walletInfo.creditLimit.toStringAsFixed(2))} ر.س',
                Icons.credit_card,
                Colors.blue,
                'الحد الأقصى المسموح',
              ),
              _buildQidhaBalanceCard(
                'إجمالي الرصيد',
                '${_convertToArabicNumerals((walletInfo.availableBalance + walletInfo.usedBalance).toStringAsFixed(2))} ر.س',
                Icons.account_balance,
                AppColors.primaryColor,
                'الرصيد الإجمالي',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQidhaBalanceCard(String title, String value, IconData icon,
      Color color, String description) {
    return Container(
      width: 140, // Reduced from 180
      margin: const EdgeInsets.only(right: 8), // Reduced from 12
      padding: const EdgeInsets.all(12), // Reduced from 20
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(12), // Reduced from 16
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            spreadRadius: 1, // Reduced from 2
            blurRadius: 4, // Reduced from 8
            offset: const Offset(0, 2), // Reduced from 4
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6), // Reduced from 8
                ),
                child: Icon(icon, color: color, size: 18), // Reduced from 24
              ),
              const Spacer(),
              Container(
                width: 6, // Reduced from 8
                height: 6, // Reduced from 8
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Reduced from 16
          Text(
            title,
            style: const TextStyle(
              fontSize: 12, // Reduced from 14
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4), // Reduced from 8
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Reduced from 20
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4), // Reduced from 8
          Text(
            description,
            style: const TextStyle(
              fontSize: 10, // Reduced from 12
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQidhaSpendingAnalytics(QidhaWalletController controller) {
    if (controller.isLoadingAnalytics) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.analyticsSummary == null) {
      return const SizedBox.shrink();
    }

    final spending = controller.analyticsSummary!.spendingAnalytics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تحليل الإنفاق',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12), // Reduced from 16
        SizedBox(
          height: 120, // Reduced from 200
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQidhaAnalyticsCard(
                'إجمالي الإنفاق هذا الشهر',
                '${_convertToArabicNumerals(spending.totalSpentThisPeriod.toStringAsFixed(2))} ر.س',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildQidhaAnalyticsCard(
                'متوسط الإنفاق اليومي',
                '${_convertToArabicNumerals(spending.averageDailySpending.toStringAsFixed(2))} ر.س',
                Icons.calendar_today,
                Colors.green,
              ),
              _buildQidhaAnalyticsCard(
                'أعلى عملية شراء',
                '${_convertToArabicNumerals(spending.highestSinglePurchase.toStringAsFixed(2))} ر.س',
                Icons.arrow_upward,
                Colors.orange,
              ),
              _buildQidhaAnalyticsCard(
                'اتجاه الإنفاق',
                _getTrendText(spending.spendingTrend),
                spending.spendingTrend == 'increasing'
                    ? Icons.trending_up
                    : Icons.trending_down,
                spending.spendingTrend == 'increasing'
                    ? Colors.red
                    : Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQidhaAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 120, // Reduced from 150
      margin: const EdgeInsets.only(right: 6), // Reduced from 8
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20), // Reduced from 24
          const SizedBox(height: 6), // Reduced from 8
          Text(
            title,
            style: const TextStyle(
              fontSize: 10, // Reduced from 12
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 3), // Reduced from 4
          Text(
            value,
            style: const TextStyle(
              fontSize: 14, // Reduced from 16
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQidhaDuePayments(QidhaWalletController controller) {
    if (controller.isLoadingDuePayments) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.duePayments == null) {
      return const SizedBox.shrink();
    }

    final summary = controller.duePayments!['summary'];
    if (summary == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المدفوعات المستحقة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.wtColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDuePaymentItem(
                'إجمالي المستحق',
                '${_convertToArabicNumerals((summary['total_due_amount'] is num ? (summary['total_due_amount'] as num).toDouble() : 0.0).toStringAsFixed(2))} ر.س',
                Colors.red,
              ),
              _buildDuePaymentItem(
                'عدد المدفوعات المستحقة',
                _convertToArabicNumerals(((summary['pending_count'] as int?) ?? 0).toString()),
                Colors.orange,
              ),
              _buildDuePaymentItem(
                'المتأخرة',
                _convertToArabicNumerals(((summary['overdue_count'] as int?) ?? 0).toString()),
                Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuePaymentItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQidhaTransactionHistory(QidhaWalletController controller) {
    if (controller.isLoadingTransactions) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert Qidha transactions to Transaction model format for HistoryItemWidget
    final List<Transaction> convertedTransactions = controller.transactions
        .map((qidhaTransaction) => Transaction(
              transactionId: qidhaTransaction.transactionId,
              transactionType:
                  _convertQidhaTransactionType(qidhaTransaction.type),
              debit: qidhaTransaction.type == 'debit'
                  ? qidhaTransaction.amount
                  : 0.0,
              credit: qidhaTransaction.type == 'credit'
                  ? qidhaTransaction.amount
                  : 0.0,
              adminBonus: 0.0,
              reference: qidhaTransaction.orderId?.toString() ??
                  qidhaTransaction.transactionId,
              createdAt: DateTime.tryParse(qidhaTransaction.createdAt),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'سجل المعاملات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_convertToArabicNumerals(convertedTransactions.length.toString())} معاملة',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400, // Fixed height to enable scrolling
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: convertedTransactions.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: HistoryItemWidget(
                  index: index,
                  fromWallet: true,
                  data: convertedTransactions,
                ),
              );
            },
          ),
        ),
        // Load more button if there are more transactions to load
        if (convertedTransactions.length >=
            50) // Assuming 50 is the limit per page
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: () {
                // Load more transactions
                controller.loadTransactions(
                  offset: convertedTransactions.length,
                  loadMore: true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: controller.isLoadingTransactions
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'تحميل المزيد',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  // Convert Qidha transaction types to wallet transaction types
  String _convertQidhaTransactionType(String qidhaType) {
    switch (qidhaType) {
      case 'debit':
        return 'order_payment'; // Make it clickable
      case 'credit':
        return 'add_fund';
      case 'refund':
        return 'add_fund';
      case 'payment':
        return 'order_payment'; // Make it clickable
      case 'initialcharge':
        return 'add_fund';
      case 'loyaltycredit':
        return 'loyalty_point';
      case 'referralcode':
        return 'referrer';
      default:
        return qidhaType;
    }
  }

  Widget _buildQidhaSpendingCategories(QidhaWalletController controller) {
    if (controller.isLoadingCategories) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.spendingCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'فئات الإنفاق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_convertToArabicNumerals(controller.spendingCategories.length.toString())} فئة',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300, // Fixed height to enable scrolling
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.spendingCategories.length,
            itemBuilder: (context, index) {
              final category = controller.spendingCategories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.wtColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: category.categoryImageUrl != null &&
                              category.categoryImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SmartImage(
                                url: category.categoryImageUrl!,
                                width: 40,
                                height: 40,
                                cacheWidth: 300,
                                cacheHeight: 300,
                                fit: BoxFit.cover,
                                placeholderWidget: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: const Icon(Icons.category),
                              ),
                            )
                          : const Icon(Icons.category),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.categoryNameAr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_convertToArabicNumerals(category.transactionCount.toString())} عملية شراء',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_convertToArabicNumerals(category.totalSpent.toStringAsFixed(2))} ر.س',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${_convertToArabicNumerals(category.percentage.toStringAsFixed(1))}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQidhaMonthlyTrends(QidhaWalletController controller) {
    if (controller.isLoadingTrends) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.monthlyTrends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الاتجاهات الشهرية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_convertToArabicNumerals(controller.monthlyTrends.length.toString())} شهر',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            children: controller.monthlyTrends
                .map(
                  (trend) => Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.wtColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trend.monthNameAr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_convertToArabicNumerals(trend.totalSpent.toStringAsFixed(2))} ر.س',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_convertToArabicNumerals(trend.transactionCount.toString())} عملية',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'متوسط: ${_convertToArabicNumerals(trend.averageOrderValue.toStringAsFixed(2))} ر.س',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQidhaPaymentHistory(QidhaWalletController controller) {
    if (controller.isLoadingPaymentHistory) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.paymentHistory == null) {
      return const SizedBox.shrink();
    }

    final payments = controller.paymentHistory!['payments'] as List<dynamic>?;
    if (payments == null || payments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'سجل المدفوعات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_convertToArabicNumerals(payments.length.toString())} دفعة',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300, // Fixed height to enable scrolling
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.wtColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPaymentTypeColor(payment['payment_type'] as String)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPaymentTypeIcon(payment['payment_type'] as String),
                        color: _getPaymentTypeColor(payment['payment_type'] as String),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPaymentTypeText(payment['payment_type'] as String),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            (payment['paid_at'] as String?) ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_convertToArabicNumerals((payment['amount'] is num ? (payment['amount'] as num).toDouble() : 0.0).toStringAsFixed(2))} ر.س',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getPaymentTypeColor(payment['payment_type'] as String),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType) {
      case 'due_payment':
        return Colors.orange;
      case 'order_payment':
        return Colors.blue;
      case 'refund':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentTypeIcon(String paymentType) {
    switch (paymentType) {
      case 'due_payment':
        return Icons.payment;
      case 'order_payment':
        return Icons.shopping_cart;
      case 'refund':
        return Icons.undo;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentTypeText(String paymentType) {
    switch (paymentType) {
      case 'due_payment':
        return 'دفع مستحق';
      case 'order_payment':
        return 'دفع طلب';
      case 'refund':
        return 'استرداد';
      default:
        return 'دفع';
    }
  }

  // Qidha Wallet Header using existing wallet data
  // ignore: unused_element
  Widget _buildQidhaWalletHeaderFromExistingData() {
    return GetBuilder<KaidhaSubscription_Controller>(
      builder: (kaidhaController) {
        final wallet = kaidhaController.walletKaidhaModel?.wallet;
        if (wallet == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'لا توجد بيانات محفظة قيدها',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withValues(alpha: 0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'محفظة قيدها',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'الحالة: ${wallet.status == 'Active' ? 'نشط' : 'غير نشط'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          wallet.status == 'Active' ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      wallet.status == 'Active' ? 'نشط' : 'غير نشط',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Qidha Wallet Spending Analytics using existing data
  // ignore: unused_element
  Widget _buildQidhaSpendingAnalyticsFromExistingData(
      AnalyticsController controller) {
    return GetBuilder<KaidhaSubscription_Controller>(
      builder: (kaidhaController) {
        final wallet = kaidhaController.walletKaidhaModel?.wallet;
        if (wallet == null) {
          return const SizedBox.shrink();
        }

        final monthlySpending = controller.summary?.monthlySpending ?? 0.0;
        final weeklySpending = controller.summary?.weeklySpending ?? 0.0;
        final averageDailySpending = monthlySpending / 30;

        final usedBalance =
            double.tryParse(wallet.usedBalance?.toString() ?? '0') ?? 0.0;
        final creditLimit =
            double.tryParse(wallet.creditLimit?.toString() ?? '1') ?? 1.0;
        final usagePercentage = (usedBalance / creditLimit) * 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تحليل الإنفاق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12), // Reduced from 16
            SizedBox(
              height: 120, // Reduced from 200
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQidhaAnalyticsCard(
                    'إجمالي الإنفاق هذا الشهر',
                    '${_convertToArabicNumerals(monthlySpending.toStringAsFixed(2))} ر.س',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  _buildQidhaAnalyticsCard(
                    'متوسط الإنفاق اليومي',
                    '${_convertToArabicNumerals(averageDailySpending.toStringAsFixed(2))} ر.س',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                  _buildQidhaAnalyticsCard(
                    'نسبة الاستخدام',
                    '${_convertToArabicNumerals(usagePercentage.toStringAsFixed(1))}%',
                    Icons.pie_chart,
                    Colors.orange,
                  ),
                  _buildQidhaAnalyticsCard(
                    'الإنفاق الأسبوعي',
                    '${_convertToArabicNumerals(weeklySpending.toStringAsFixed(2))} ر.س',
                    Icons.trending_up,
                    AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildQidhaTransactionHistoryPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.history, color: Colors.blue[400], size: 48),
          const SizedBox(height: 12),
          Text(
            'سجل المعاملات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض سجل المعاملات قريباً',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildQidhaMonthlyTrendsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            color: AppColors.primaryColor.withValues(alpha: 0.75),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'الاتجاهات الشهرية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض الاتجاهات الشهرية قريباً',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryColor.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Qidha Wallet Spending Calendar Heatmap
  Widget _buildQidhaSpendingCalendar(QidhaWalletController controller) {
    if (controller.isLoadingTransactions) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group transactions by date
    final Map<String, double> dailySpending = {};
    for (final transaction in controller.transactions) {
      if (transaction.type == 'debit') {
        final String date = transaction.createdAt.split('T')[0]; // Get YYYY-MM-DD
        dailySpending[date] = (dailySpending[date] ?? 0) + transaction.amount;
      }
    }

    // Get the last 30 days
    final DateTime now = DateTime.now();
    final List<DateTime> last30Days =
        List.generate(30, (index) => now.subtract(Duration(days: index)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'تقويم الإنفاق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'آخر 30 يوم',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.wtColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Calendar grid
              _buildCalendarGrid(last30Days, dailySpending),
              const SizedBox(height: 16),
              // Legend
              _buildCalendarLegend(dailySpending),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
      List<DateTime> days, Map<String, double> dailySpending) {
    // Find max spending for intensity calculation
    final double maxSpending = dailySpending.values.isNotEmpty
        ? dailySpending.values.reduce((a, b) => a > b ? a : b)
        : 0;

    // Sort days chronologically (oldest first)
    final List<DateTime> sortedDays = List.from(days)..sort();

    // Find the first day of the week for the first date
    final DateTime firstDay = sortedDays.first;
    final int firstDayOfWeek =
        firstDay.weekday % 7; // Convert to 0=Sunday, 1=Monday, etc.

    // Create calendar grid with proper day-of-week alignment
    final List<Widget> calendarCells = [];

    // Add empty cells for days before the first date
    for (int i = 0; i < firstDayOfWeek; i++) {
      calendarCells.add(Container()); // Empty cell
    }

    // Add actual days
    for (final DateTime day in sortedDays) {
      final String dateKey = day.toIso8601String().split('T')[0];
      final double spending = dailySpending[dateKey] ?? 0;
      final double intensity = maxSpending > 0 ? spending / maxSpending : 0;

      calendarCells.add(Container(
        decoration: BoxDecoration(
          color: _getHeatmapColor(intensity),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: intensity > 0.5 ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (spending > 0)
                Text(
                  _convertToArabicNumerals(spending.toStringAsFixed(0)),
                  style: TextStyle(
                    fontSize: 8,
                    color: intensity > 0.5 ? Colors.white : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    return Column(
      children: [
        // Day headers
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 3,
          children: ['أحد', 'اثن', 'ثلث', 'أرب', 'خمس', 'جمعة', 'سبت']
              .map<Widget>((day) => Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days with proper alignment
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.2,
          children: calendarCells,
        ),
      ],
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 0) return Colors.grey[50]!;
    if (intensity <= 0.2) return Colors.green[100]!;
    if (intensity <= 0.4) return Colors.lightGreen[300]!;
    if (intensity <= 0.6) return Colors.yellow[300]!;
    if (intensity <= 0.8) return Colors.orange[400]!;
    return Colors.red[500]!;
  }

  Widget _buildCalendarLegend(Map<String, double> dailySpending) {
    final double maxSpending = dailySpending.values.isNotEmpty
        ? dailySpending.values.reduce((a, b) => a > b ? a : b)
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'أقل',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.lightGreen[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.yellow[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.orange[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red[500],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'أكثر',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (maxSpending > 0)
          Text(
            'أعلى إنفاق: ${_convertToArabicNumerals(maxSpending.toStringAsFixed(0))} ر.س',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  // Qidha Wallet Due Payments Timeline
  Widget _buildQidhaDuePaymentsTimeline(QidhaWalletController controller) {
    if (controller.isLoadingDuePayments) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.duePayments == null ||
        controller.duePayments!['due_payments'] == null) {
      return const SizedBox.shrink();
    }

    final List<dynamic> duePayments =
        controller.duePayments!['due_payments'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'جدول المدفوعات المستحقة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_convertToArabicNumerals(duePayments.length.toString())} مدفوعات',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: duePayments.length,
            itemBuilder: (context, index) {
              final payment = duePayments[index] as Map<String, dynamic>;
              return _buildTimelineItem(
                  payment, index == duePayments.length - 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> payment, bool isLast) {
    final String dueDate = (payment['due_date'] as String?) ?? '';
    final String status = (payment['status'] as String?) ?? '';
    final double amount = double.tryParse(payment['due_amount'].toString()) ?? 0.0;
    final int daysOverdue = (payment['days_overdue'] as int?) ?? 0;

    // Parse due date
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dueDate);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    // Determine status color
    Color statusColor;
    IconData statusIcon;
    if (status == 'overdue') {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (status == 'due_soon') {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: 8,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(top: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Payment details
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.wtColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'طلب #${payment['order_id'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_convertToArabicNumerals(amount.toStringAsFixed(2))} ر.س',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تاريخ الاستحقاق: ${_formatDate(parsedDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (daysOverdue > 0)
                    Text(
                      'متأخر $daysOverdue يوم',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (payment['order_details'] != null)
                    Builder(
                      builder: (context) {
                        final orderDetails = payment['order_details'] as Map<String, dynamic>?;
                        final storeName = orderDetails != null ? orderDetails['store_name'] as String? : null;
                        return Text(
                          'المتجر: ${storeName ?? 'غير محدد'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_convertToArabicNumerals(date.day.toString())}/${_convertToArabicNumerals(date.month.toString())}/${_convertToArabicNumerals(date.year.toString())}';
  }

  // Qidha Wallet Salary Day & Due Payments Overview
  Widget _buildQidhaSalaryDayOverview(QidhaWalletController controller) {
    debugPrint(
        '🔍 Salary Day Widget - isLoadingAnalytics: ${controller.isLoadingAnalytics}');
    debugPrint(
        '🔍 Salary Day Widget - analyticsSummary: ${controller.analyticsSummary != null}');
    debugPrint(
        '🔍 Salary Day Widget - salaryDayInfo: ${controller.analyticsSummary?.salaryDayInfo != null}');

    if (controller.isLoadingAnalytics) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.analyticsSummary?.salaryDayInfo == null) {
      debugPrint(
          '🔍 Salary Day Widget - Hiding widget because salaryDayInfo is null');
      return const SizedBox.shrink();
    }

    final salaryDayInfo = controller.analyticsSummary!.salaryDayInfo!;
    final duePaymentsData = controller.analyticsSummary!.duePayments;

    // Get salary day data from analytics summary
    final int userSalaryDay = salaryDayInfo.salaryDay;
    final String nextSalaryDate = salaryDayInfo.nextSalaryDate;
    final int daysUntilSalary = salaryDayInfo.daysUntilSalary;
    final double salaryAmount = salaryDayInfo.salaryAmount;
    final double duePaymentsRatio = salaryDayInfo.duePaymentsVsSalaryRatio;
    final bool isPaymentDue = salaryDayInfo.isPaymentDue;

    // Calculate total due amount from duePayments data
    final double totalDueAmount = duePaymentsData.totalDueAmount;
    final int overdueCount = duePaymentsData.overduePayments;
    final int pendingCount =
        duePaymentsData.duePaymentsCount - duePaymentsData.overduePayments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Professional Header with 3D Effect
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'يوم الراتب والمدفوعات المستحقة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  shadows: [
                    Shadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Salary Day Card with 3D Effect
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 3D Icon Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'يوم الراتب',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_convertToArabicNumerals(userSalaryDay.toString())} من كل شهر',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[400]!, Colors.green[600]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'بعد ${_convertToArabicNumerals(daysUntilSalary.toString())} يوم',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextSalaryDate.isNotEmpty
                              ? nextSalaryDate
                              : 'غير محدد',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Due Payments Summary with 3D Effect
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[400]!, Colors.red[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'المدفوعات المستحقة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[400]!, Colors.red[600]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_convertToArabicNumerals(totalDueAmount.toStringAsFixed(2))} ر.س',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Cards with 3D Effects
              Row(
                children: [
                  Expanded(
                    child: _buildDuePaymentStat3D(
                      'المعلقة',
                      pendingCount.toString(),
                      Colors.orange,
                      Icons.pending_actions,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDuePaymentStat3D(
                      'المتأخرة',
                      overdueCount.toString(),
                      Colors.red,
                      Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Enhanced Progress Bar with 3D Effect
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: duePaymentsRatio.round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPaymentDue
                                ? [Colors.red[400]!, Colors.red[600]!]
                                : [Colors.orange[400]!, Colors.orange[600]!],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: (isPaymentDue ? Colors.red : Colors.orange)
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 100 - duePaymentsRatio.round(),
                      child: Container(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'المبلغ المستحق: ${_convertToArabicNumerals(totalDueAmount.toStringAsFixed(2))} ر.س من أصل ${_convertToArabicNumerals(salaryAmount.toStringAsFixed(0))} ر.س',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (isPaymentDue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'مدفوع مستحق',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced 3D version of due payment stat
  Widget _buildDuePaymentStat3D(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _convertToArabicNumerals(value),
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
