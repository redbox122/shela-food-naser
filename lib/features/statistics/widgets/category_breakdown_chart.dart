import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/dimensions.dart';
import '../domain/models/category_breakdown.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final List<CategoryData> data;
  final bool isLoading;

  const CategoryBreakdownChart({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        Expanded(
          child: _buildSimpleChart(context),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _buildSummary(context),
      ],
    );
  }

  Widget _buildSimpleChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.gryColor_3,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pie_chart,
            size: 48,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Custom_Text(
            context,
            text: 'Category Breakdown Chart',
            style: font14Black400W(context).copyWith(
              color: AppColors.bgColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Custom_Text(
            context,
            text: 'Chart will be implemented with fl_chart',
            style: font12Black400W(context).copyWith(
              color: AppColors.gryColor_2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pie_chart,
            size: 48,
            color: AppColors.gryColor_2,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Custom_Text(
            context,
            text: 'No category data available',
            style: font14Black400W(context).copyWith(
              color: AppColors.gryColor_2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final totalSpent =
        data.fold(0.0, (sum, category) => sum + category.spentAmount);
    final totalItems =
        data.fold(0, (sum, category) => sum + category.purchaseCount);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.gryColor_3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            'Total Spent',
            '${totalSpent.toStringAsFixed(2)} رس',
            AppColors.primaryColor,
          ),
          _buildSummaryItem(
            context,
            'Categories',
            '${data.length}',
            AppColors.gryColor_2,
          ),
          _buildSummaryItem(
            context,
            'Total Items',
            '$totalItems',
            AppColors.gryColor_2,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Custom_Text(
          context,
          text: value,
          style: font14Black400W(context).copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Custom_Text(
          context,
          text: label,
          style: font10Black400W(context).copyWith(
            color: AppColors.gryColor_2,
          ),
        ),
      ],
    );
  }
}
