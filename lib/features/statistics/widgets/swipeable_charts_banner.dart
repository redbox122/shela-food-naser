import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:fl_chart/fl_chart.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
// import '../domain/models/spending_trend.dart';
import '../domain/models/category_breakdown.dart';

class SwipeableChartsBanner extends StatefulWidget {
  const SwipeableChartsBanner({super.key});

  @override
  State<SwipeableChartsBanner> createState() => _SwipeableChartsBannerState();
}

class _SwipeableChartsBannerState extends State<SwipeableChartsBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<AnalyticsController>(
      builder: (controller) {
        return Container(
          height: 250,
          margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault),
          child: Column(
            children: [
              _buildChartHeader(controller),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildSpendingTrendChart(controller),
                    _buildCategoryBreakdownChart(controller),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _buildPageIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartHeader(AnalyticsController controller) {
    return Row(
      children: [
        const Icon(
          Icons.analytics,
          color: AppColors.greenColor,
          size: 20,
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(
          'analytics_charts'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const Spacer(),
        if (_currentPage == 0) _buildPeriodSelector(controller),
      ],
    );
  }

  Widget _buildPeriodSelector(AnalyticsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greenColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButton<String>(
        value: controller.currentTrendPeriod,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.greenColor),
        style: const TextStyle(
          color: AppColors.greenColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: controller.availableTrendPeriods.map((String period) {
          return DropdownMenuItem<String>(
            value: period,
            child: Text(period.tr),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            controller.loadSpendingTrends(newValue);
          }
        },
      ),
    );
  }

  Widget _buildSpendingTrendChart(AnalyticsController controller) {
    if (controller.isLoadingTrends) {
      return _buildLoadingChart();
    }

    if (controller.spendingTrend == null) {
      return _buildNoDataChart();
    }

    return Container(
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
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'spending_trends'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.greenColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        color: AppColors.greenColor,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Spending Trends Chart',
                        style: TextStyle(
                          color: AppColors.greenColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chart temporarily disabled',
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownChart(AnalyticsController controller) {
    if (controller.isLoadingCategories) {
      return _buildLoadingChart();
    }

    if (controller.categoryBreakdown == null) {
      return _buildNoDataChart();
    }

    return Container(
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
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'category_breakdown'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.blueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart,
                        color: AppColors.blueColor,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Category Breakdown Chart',
                        style: TextStyle(
                          color: AppColors.blueColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chart temporarily disabled',
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildCategoryLegend(controller.categoryBreakdown!),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(CategoryBreakdown breakdown) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: breakdown.categories.map((category) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getCategoryColor(category.categoryName),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${category.categoryName} (${category.percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.greyColor,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
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
  }

  Widget _buildNoDataChart() {
    return Container(
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
              color: AppColors.greyColor.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'no_data_available'.tr,
              style: TextStyle(
                color: AppColors.greyColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.greenColor
                : AppColors.greyColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // Chart methods temporarily disabled due to fl_chart import issues
  // List<FlSpot> _getSpendingSpots(SpendingTrendData trendData) {
  //   return trendData.data.asMap().entries.map((entry) {
  //     return FlSpot(entry.key.toDouble(), entry.value.amount);
  //   }).toList();
  // }

  // List<PieChartSectionData> _getCategorySections(CategoryBreakdown breakdown) {
  //   final colors = [
  //     AppColors.greenColor,
  //     AppColors.blueColor,
  //     AppColors.orangeColor,
  //     AppColors.redColor,
  //     AppColors.purpleColor,
  //   ];

  //   return breakdown.categories.asMap().entries.map((entry) {
  //     final category = entry.value;
  //     final color = colors[entry.key % colors.length];

  //     return PieChartSectionData(
  //       color: color,
  //       value: category.percentage,
  //       title: '${category.percentage.toStringAsFixed(1)}%',
  //       radius: 60,
  //       titleStyle: const TextStyle(
  //         fontSize: 10,
  //         fontWeight: FontWeight.bold,
  //         color: AppColors.wtColor,
  //       ),
  //     );
  //   }).toList();
  // }

  Color _getCategoryColor(String categoryName) {
    final colors = {
      'Grocery': AppColors.greenColor,
      'Pharmacy': AppColors.blueColor,
      'Electronics': AppColors.orangeColor,
      'Clothing': AppColors.redColor,
      'Books': AppColors.primaryColor,
    };
    return colors[categoryName] ?? AppColors.greyColor;
  }
}
