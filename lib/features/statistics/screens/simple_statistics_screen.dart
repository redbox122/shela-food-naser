import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../common/widgets/appBar.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../analytics_module.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class SimpleStatisticsScreen extends StatelessWidget {
  const SimpleStatisticsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    // Initialize analytics module if not already initialized
    if (!AnalyticsModule.isInitialized) {
      AnalyticsModule.initialize();
    }

    return GetX<AnalyticsController>(
      init: AnalyticsModule.getController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.wtColor,
          appBar: custom_AppBar(context,
              title: 'statistics'.tr,
              icon: Icons.arrow_back_sharp,
              titleIcon: Icons.shopping_bag_outlined),
          body: RefreshIndicator(
            onRefresh: () => controller.refreshData(),
            color: AppColors.primaryColor,
            child: controller.isLoading
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
                          // Simple Summary Cards
                          _buildSummaryCards(controller),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // Simple Most Purchased Products
                          _buildMostPurchasedProducts(controller),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // Simple Insights
                          _buildInsights(controller),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(AnalyticsController controller) {
    if (controller.isLoadingSummary) {
      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            width: 150,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    if (controller.summary == null) {
      return const SizedBox.shrink();
    }

    final summary = controller.summary!;
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            'monthly_spending'.tr,
            '${_convertToArabicNumerals(summary.monthlySpending.toStringAsFixed(2))} ر.س',
            Icons.shopping_cart,
            Colors.blue,
          ),
          _buildSummaryCard(
            'weekly_spending'.tr,
            '${_convertToArabicNumerals(summary.weeklySpending.toStringAsFixed(2))} ر.س',
            Icons.calendar_today,
            Colors.green,
          ),
          _buildSummaryCard(
            'remaining_balance'.tr,
            '${_convertToArabicNumerals(summary.remainingBalance.toStringAsFixed(2))} ر.س',
            Icons.account_balance_wallet,
            Colors.orange,
          ),
          _buildSummaryCard(
            () {
              final String title = 'spending_trend'.tr;
              if (kDebugMode) {
                appLogger.debug('🔍 Spending trend translation: $title');
              }
              return title;
            }(),
            _getTrendText(summary.spendingTrend.trendDirection),
            summary.spendingTrend.trendDirection == 'up' ||
                    summary.spendingTrend.trendDirection == 'increasing'
                ? Icons.trending_up
                : Icons.trending_down,
            summary.spendingTrend.trendDirection == 'up' ||
                    summary.spendingTrend.trendDirection == 'increasing'
                ? Colors.red
                : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostPurchasedProducts(AnalyticsController controller) {
    if (controller.isLoadingProducts) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.mostPurchasedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'st_most_purchased'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...controller.mostPurchasedProducts
            .take(5)
            .map(
              (product) => Container(
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
                      child: const Icon(Icons.image),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_convertToArabicNumerals(product.purchaseCount.toString())} ${'purchases'.tr}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_convertToArabicNumerals(product.totalSpent.toStringAsFixed(2))} ر.س',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            )
            ,
      ],
    );
  }

  Widget _buildInsights(AnalyticsController controller) {
    if (controller.isLoadingInsights) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.insights == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...controller.insights!.insights
            .map(
              (insight) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: insight.severity == 'warning'
                      ? Colors.orange[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: insight.severity == 'warning'
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      insight.severity == 'warning'
                          ? Icons.warning
                          : Icons.info,
                      color: insight.severity == 'warning'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight.message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )
            ,
      ],
    );
  }

  String _getTrendText(String trendDirection) {
    if (kDebugMode) {
      appLogger.debug('🔍 Trend Direction: $trendDirection');
    }
    String result;
    switch (trendDirection.toLowerCase()) {
      case 'increasing':
      case 'up':
        result = 'increasing'.tr;
        if (kDebugMode) {
          appLogger.debug('🔍 Increasing translation: $result');
        }
        return result;
      case 'decreasing':
      case 'down':
        result = 'decreasing'.tr;
        if (kDebugMode) {
          appLogger.debug('🔍 Decreasing translation: $result');
        }
        return result;
      default:
        result = 'stable'.tr;
        if (kDebugMode) {
          appLogger.debug('🔍 Stable translation: $result');
        }
        return result;
    }
  }
}
