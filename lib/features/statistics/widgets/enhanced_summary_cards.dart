import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../domain/models/analytics_summary.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class EnhancedSummaryCards extends StatelessWidget {
  const EnhancedSummaryCards({super.key});

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
    return GetX<AnalyticsController>(
      builder: (controller) {
        if (controller.isLoadingSummary) {
          return _buildLoadingState();
        }

        if (controller.summaryError.isNotEmpty) {
          return _buildErrorState(
              controller.summaryError, () => controller.loadAnalyticsSummary());
        }

        if (controller.summary == null) {
          return _buildNoDataState();
        }

        return _buildSummaryCards(controller.summary!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: AppColors.wtColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.greenColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.redColor,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              'failed_to_load_data'.tr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.redColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                error.length > 40 ? '${error.substring(0, 40)}...' : error,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 10),
                label: Text('retry'.tr, style: const TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenColor,
                  foregroundColor: AppColors.wtColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      height: 120,
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.gryColor.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'no_data_available'.tr,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gryColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsSummary summary) {
    return Container(
      height: 120,
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            icon: Icons.account_balance_wallet,
            title: 'monthly_spending'.tr,
            value:
                '${_convertToArabicNumerals(summary.monthlySpending.toStringAsFixed(2))} ر.س',
            trend: summary.spendingTrend.monthlyChange,
            color: AppColors.greenColor,
          ),
          _buildSummaryCard(
            icon: Icons.trending_up,
            title: 'weekly_spending'.tr,
            value:
                '${_convertToArabicNumerals(summary.weeklySpending.toStringAsFixed(2))} ر.س',
            trend: summary.spendingTrend.weeklyChange,
            color: AppColors.bluColor,
          ),
          _buildSummaryCard(
            icon: Icons.account_balance,
            title: 'remaining_balance'.tr,
            value:
                '${_convertToArabicNumerals(summary.remainingBalance.toStringAsFixed(2))} ر.س',
            trend: 0.0, // No trend for balance
            color: AppColors.orangeColor,
          ),
          _buildSummaryCard(
            icon: Icons.trending_up,
            title: () {
              final String title = 'spending_trend'.tr;
              if (kDebugMode) {
                appLogger.debug(
                    '🔍 EnhancedSummaryCards - Spending trend translation: $title');
                appLogger.debug('🔍 EnhancedSummaryCards - Current locale: ${Get.locale}');
                appLogger.debug('🔍 EnhancedSummaryCards - Available keys: ${Get.keys}');
                appLogger.debug(
                    '🔍 EnhancedSummaryCards - Test translation: ${'hello'.tr}');
              }

              // Temporary fix: Use hardcoded Arabic translations
              if (title == 'spending_trend' || title.isEmpty) {
                return 'st_spending_trend'.tr;
              }
              return title;
            }(),
            value: _getTrendText(summary.spendingTrend.trendDirection),
            trend: summary.spendingTrend.monthlyChange,
            color: _getTrendColor(summary.spendingTrend.trendDirection),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required double trend,
    required Color color,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const Spacer(),
                if (trend != 0.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getTrendBackgroundColor(trend),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: _getTrendIconColor(trend),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${_convertToArabicNumerals(trend.abs().toStringAsFixed(1))}%',
                          style: TextStyle(
                            color: _getTrendIconColor(trend),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gryColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getTrendText(String trendDirection) {
    if (kDebugMode) {
      appLogger.debug('🔍 EnhancedSummaryCards - Trend Direction: $trendDirection');
    }
    String result;
    switch (trendDirection.toLowerCase()) {
      case 'increasing':
      case 'up':
        result = 'increasing'.tr;
        if (kDebugMode) {
          appLogger.debug('🔍 EnhancedSummaryCards - Increasing translation: $result');
        }
        // Temporary fix: Use hardcoded Arabic translations
        if (result == 'increasing' || result.isEmpty) {
          return 'st_increasing'.tr;
        }
        return result;
      case 'decreasing':
      case 'down':
        result = 'decreasing'.tr;
        if (kDebugMode) {
          appLogger.debug('🔍 EnhancedSummaryCards - Decreasing translation: $result');
        }
        // Temporary fix: Use hardcoded Arabic translations
        if (result == 'decreasing' || result.isEmpty) {
          return 'st_decreasing'.tr;
        }
        return result;
      default:
        result = 'stable'.tr;
        if (kDebugMode) {
          appLogger.debug('🔍 EnhancedSummaryCards - Stable translation: $result');
        }
        // Temporary fix: Use hardcoded Arabic translations
        if (result == 'stable' || result.isEmpty) {
          return 'st_stable'.tr;
        }
        return result;
    }
  }

  Color _getTrendColor(String trendDirection) {
    switch (trendDirection.toLowerCase()) {
      case 'increasing':
      case 'up':
        return AppColors.redColor;
      case 'decreasing':
      case 'down':
        return AppColors.greenColor;
      default:
        return AppColors.gryColor;
    }
  }

  Color _getTrendBackgroundColor(double trend) {
    if (trend > 0) {
      return AppColors.redColor.withValues(alpha: 0.1);
    } else if (trend < 0) {
      return AppColors.greenColor.withValues(alpha: 0.1);
    }
    return AppColors.gryColor.withValues(alpha: 0.1);
  }

  Color _getTrendIconColor(double trend) {
    if (trend > 0) {
      return AppColors.redColor;
    } else if (trend < 0) {
      return AppColors.greenColor;
    }
    return AppColors.gryColor;
  }
}
