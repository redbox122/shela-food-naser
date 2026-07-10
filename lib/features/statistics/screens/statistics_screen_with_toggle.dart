import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../../../util/images.dart';
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
          appBar: AppBar(
            backgroundColor: AppColors.wtColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'إحصائيات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3633),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Color(0xFF2D3633)),
              onPressed: () => Get.back(),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              _tabSegment('قيدها', 1),
              _tabSegment('عام', 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabSegment(String text, int index) {
    final bool selected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => selectedTabIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.wtColor : const Color(0xFF8A9199),
            ),
          ),
        ),
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
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Qidha Wallet main balance card (with balance tiles)
                        _buildQidhaWalletHeader(qidhaController),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

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

  // Qidha Wallet main balance card (built on the card_quidha.jpg background).
  // Renders even with no data yet (shows 0.00) so the empty state matches design.
  Widget _buildQidhaWalletHeader(QidhaWalletController controller) {
    if (controller.isLoadingAnalytics) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final walletInfo = controller.analyticsSummary?.walletInfo;
    final bool active = walletInfo?.status == 'Active';
    final double available = walletInfo?.availableBalance ?? 0.0;
    final double used = walletInfo?.usedBalance ?? 0.0;
    final double creditLimit = walletInfo?.creditLimit ?? 0.0;
    final double total = available + used;

    return Padding(
      // Reserve room for the tiles that overhang the card's bottom edge.
      padding: const EdgeInsets.only(bottom: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            // Extra bottom padding leaves green behind the overhanging tiles.
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 72),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: const DecorationImage(
                image: AssetImage(Images.card_quidha),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xffE8F5E9),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available balance → right side (RTL start).
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'st_available_balance'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          available.toStringAsFixed(2),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          // App-standard SAR icon (matches PriceConverter).
                          child: Image.asset(
                            Images.sar,
                            width: 15,
                            height: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'قد تتغيّر قبل نهاية الدقيقة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // "نشط" badge → left side.
                _qidhaStatusBadge(active),
              ],
            ),
          ),
          // Balance tiles overhanging the card's bottom edge.
          PositionedDirectional(
            start: 14,
            end: 14,
            bottom: -34,
            child: Row(
              children: [
                _qidhaMiniTile('st_total_balance'.tr, total, 'st_overall_balance'.tr),
                const SizedBox(width: 10),
                _qidhaMiniTile(
                    'st_credit_limit'.tr, creditLimit, 'st_max_allowed'.tr),
                const SizedBox(width: 10),
                _qidhaMiniTile(
                    'st_used_balance'.tr, used, 'st_amount_spent_sofar'.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qidhaStatusBadge(bool active) {
    final Color color = active ? AppColors.wtColor : AppColors.redColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xff5FA56B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'نشط' : 'غير نشط',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qidhaMiniTile(String label, double value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xff135017),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              // Force RTL order: amount on the right, SAR icon on the left.
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value.toStringAsFixed(2),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff135017),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                // App-standard SAR icon (matches PriceConverter).
                Image.asset(
                  Images.sar,
                  width: 13,
                  height: 13,
                  color: const Color(0xff135017),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Color(0xff135017),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Qidha Wallet Balance Overview — superseded by the balance tiles inside the
  // main card; kept for reference.
  // ignore: unused_element
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
        Text(
          'st_balance_overview'.tr,
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
                'st_available_balance'.tr,
                '${_convertToArabicNumerals(walletInfo.availableBalance.toStringAsFixed(2))} ر.س',
                Icons.account_balance_wallet,
                Colors.green,
                'st_amount_available_spend'.tr,
              ),
              _buildQidhaBalanceCard(
                'st_used_balance'.tr,
                '${_convertToArabicNumerals(walletInfo.usedBalance.toStringAsFixed(2))} ر.س',
                Icons.shopping_cart,
                Colors.orange,
                'st_amount_spent_sofar'.tr,
              ),
              _buildQidhaBalanceCard(
                'st_credit_limit'.tr,
                '${_convertToArabicNumerals(walletInfo.creditLimit.toStringAsFixed(2))} ر.س',
                Icons.credit_card,
                Colors.blue,
                'st_max_allowed'.tr,
              ),
              _buildQidhaBalanceCard(
                'st_total_balance'.tr,
                '${_convertToArabicNumerals((walletInfo.availableBalance + walletInfo.usedBalance).toStringAsFixed(2))} ر.س',
                Icons.account_balance,
                AppColors.primaryColor,
                'st_overall_balance'.tr,
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
          _amountWithSar(
            value,
            TextStyle(
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
        Text(
          'st_spending_analysis'.tr,
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
                'st_total_spending_month'.tr,
                '${_convertToArabicNumerals(spending.totalSpentThisPeriod.toStringAsFixed(2))} ر.س',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildQidhaAnalyticsCard(
                'st_avg_daily_spending'.tr,
                '${_convertToArabicNumerals(spending.averageDailySpending.toStringAsFixed(2))} ر.س',
                Icons.calendar_today,
                Colors.green,
              ),
              _buildQidhaAnalyticsCard(
                'st_highest_purchase'.tr,
                '${_convertToArabicNumerals(spending.highestSinglePurchase.toStringAsFixed(2))} ر.س',
                Icons.arrow_upward,
                Colors.orange,
              ),
              _buildQidhaAnalyticsCard(
                'st_spending_trend'.tr,
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

  /// Renders a currency value using the app-standard SAR icon instead of the
  /// "ر.س" text. If [value] ends with " ر.س" the suffix is dropped and the
  /// [Images.sar] icon is appended after the number (e.g. "55 ﷼").
  Widget _amountWithSar(String value, TextStyle style) {
    const String suffix = ' ر.س';
    if (!value.endsWith(suffix)) {
      return Text(value, style: style, overflow: TextOverflow.ellipsis);
    }
    final String number = value.substring(0, value.length - suffix.length);
    final double iconSize = (style.fontSize ?? 14) * 0.9;
    return Row(
      // RTL order: amount on the right, SAR icon on the left.
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(number, style: style, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 3),
        Image.asset(
          Images.sar,
          width: iconSize,
          height: iconSize,
          color: style.color,
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
        color: Color(0xffF6F5F8),
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
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 3), // Reduced from 4
          _amountWithSar(
            value,
            const TextStyle(
              fontSize: 18,
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
        Text(
          'st_due_payments'.tr,
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
                'st_total_due'.tr,
                '${_convertToArabicNumerals((summary['total_due_amount'] is num ? (summary['total_due_amount'] as num).toDouble() : 0.0).toStringAsFixed(2))} ر.س',
                Colors.red,
              ),
              _buildDuePaymentItem(
                'st_due_payments_count'.tr,
                _convertToArabicNumerals(
                    ((summary['pending_count'] as int?) ?? 0).toString()),
                Colors.orange,
              ),
              _buildDuePaymentItem(
                'st_overdue'.tr,
                _convertToArabicNumerals(
                    ((summary['overdue_count'] as int?) ?? 0).toString()),
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
            Text(
              'st_transactions_log'.tr,
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
                  : Text(
                      'st_load_more'.tr,
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
            Text(
              'st_spending_categories'.tr,
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: _categoryImageFallback(),
                              ),
                            )
                          : _categoryImageFallback(),
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

  /// Fallback shown when a spending category has no image (or it fails to
  /// load): a placeholder image instead of a static icon.
  Widget _categoryImageFallback() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        Images.placeholder,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildQidhaMonthlyTrends(QidhaWalletController controller) {
    if (controller.isLoadingTrends) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'st_monthly_trends'.tr,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3633),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.monthlyTrends.isEmpty)
          _qidhaEmptyMessage('لا توجد إحصائيات لعرضها حتى الآن')
        else
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: controller.monthlyTrends
                  .map((trend) => _qidhaTrendCard(trend))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _qidhaTrendCard(dynamic trend) {
    return Container(
      width: 141,
      margin: const EdgeInsetsDirectional.only(end: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            trend.monthNameAr as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3633),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '﷼',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                (trend.totalSpent as num).toDouble().toStringAsFixed(2),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${trend.transactionCount} عملية',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Color(0xFF8A9199),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'متوسط ${(trend.averageOrderValue as num).toDouble().toStringAsFixed(2)} ﷼',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Color(0xFF8A9199),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qidhaEmptyMessage(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8A9199),
        ),
      ),
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
            Text(
              'st_payments_log'.tr,
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
                        color: _getPaymentTypeColor(
                                payment['payment_type'] as String)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPaymentTypeIcon(payment['payment_type'] as String),
                        color: _getPaymentTypeColor(
                            payment['payment_type'] as String),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPaymentTypeText(
                                payment['payment_type'] as String),
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
                        color: _getPaymentTypeColor(
                            payment['payment_type'] as String),
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
        return 'st_payment_due'.tr;
      case 'order_payment':
        return 'st_pay_order'.tr;
      case 'refund':
        return 'st_refund'.tr;
      default:
        return 'st_pay'.tr;
    }
  }

  // Qidha Wallet Header using existing wallet data
  // ignore: unused_element
  Widget _buildQidhaWalletHeaderFromExistingData() {
    return GetBuilder<KaidhaSubscriptionController>(
      builder: (kaidhaController) {
        final wallet = kaidhaController.walletKaidhaModel?.wallet;
        if (wallet == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'st_no_qidha_data'.tr,
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
                        Text(
                          'st_qidha_wallet'.tr,
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
    return GetBuilder<KaidhaSubscriptionController>(
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
            Text(
              'st_spending_analysis'.tr,
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
                    'st_total_spending_month'.tr,
                    '${_convertToArabicNumerals(monthlySpending.toStringAsFixed(2))} ر.س',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  _buildQidhaAnalyticsCard(
                    'st_avg_daily_spending'.tr,
                    '${_convertToArabicNumerals(averageDailySpending.toStringAsFixed(2))} ر.س',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                  _buildQidhaAnalyticsCard(
                    'st_usage_ratio'.tr,
                    '${_convertToArabicNumerals(usagePercentage.toStringAsFixed(1))}%',
                    Icons.pie_chart,
                    Colors.orange,
                  ),
                  _buildQidhaAnalyticsCard(
                    'st_weekly_spending'.tr,
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
            'st_transactions_log'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'st_transactions_soon'.tr,
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
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.25)),
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
            'st_monthly_trends'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'st_monthly_trends_soon'.tr,
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
        final String date =
            transaction.createdAt.split('T')[0]; // Get YYYY-MM-DD
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
            Text(
              'st_spending_calendar'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'st_last_30_days'.tr,
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
              'st_less'.tr,
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
              'st_more'.tr,
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
            Text(
              'st_due_payments_schedule'.tr,
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
    final double amount =
        double.tryParse(payment['due_amount'].toString()) ?? 0.0;
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
                        final orderDetails =
                            payment['order_details'] as Map<String, dynamic>?;
                        final storeName = orderDetails != null
                            ? orderDetails['store_name'] as String?
                            : null;
                        return Text(
                          'المتجر: ${storeName ?? 'st_unspecified'.tr}',
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
        height: 160,
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
    final int daysUntilSalary = salaryDayInfo.daysUntilSalary;
    final double salaryAmount = salaryDayInfo.salaryAmount;

    // Calculate total due amount from duePayments data
    final double totalDueAmount = duePaymentsData.totalDueAmount;
    final int overdueCount = duePaymentsData.overduePayments;
    final int pendingCount =
        duePaymentsData.duePaymentsCount - duePaymentsData.overduePayments;

    const Color darkColor = Color(0xFF2D3633);
    const Color subtitleGrey = Color(0xFF8A9199);
    const Color purple = Color(0xFF7B61FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION 1 — Salary day & monthly payments
        const Text(
          'يوم الراتب والمدفوعات الشهرية',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: darkColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.wtColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today,
                    color: purple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'st_payday'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: subtitleGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$userSalaryDay من كل شهر',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 15, color: AppColors.wtColor),
                          const SizedBox(width: 6),
                          Text(
                            'بعد $daysUntilSalary يوم',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.wtColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SECTION 2 — Due payments
        Row(
          children: [
            Expanded(
              child: Text(
                'st_due_payments'.tr,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkColor,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.redColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalDueAmount.toStringAsFixed(2),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.redColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '﷼',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.redColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dueStatCard('st_overdue'.tr, overdueCount,
                  AppColors.redColor, Icons.event_busy_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dueStatCard('st_pending'.tr, pendingCount,
                  const Color(0xFFF5A623), Icons.pending_actions),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'المبلغ المستحق',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: subtitleGrey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${totalDueAmount.toStringAsFixed(2)} ﷼ من أصل ${salaryAmount.toStringAsFixed(2)} ﷼',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3633),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dueStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon on the right (RTL start).
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 6),
                Text('$count',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
