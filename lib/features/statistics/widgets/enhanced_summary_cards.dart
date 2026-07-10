import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../util/app_colors.dart';
import '../controllers/analytics_controller.dart';
import '../domain/models/analytics_summary.dart';

/// Two summary cards (weekly + monthly spending) with a trend badge, matching
/// the redesigned statistics ("عام") tab.
class EnhancedSummaryCards extends StatelessWidget {
  const EnhancedSummaryCards({super.key});

  static const Color _cardColor = Color(0xFFF6F5F8);
  static const Color _titleColor = Color(0xFF2D3633);

  @override
  Widget build(BuildContext context) {
    return GetX<AnalyticsController>(
      builder: (controller) {
        if (controller.isLoadingSummary) {
          return const SizedBox(
            height: 96,
            child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryColor)),
          );
        }
        if (controller.summaryError.isNotEmpty) {
          return _errorState(() => controller.loadAnalyticsSummary());
        }
        final AnalyticsSummary? summary = controller.summary;
        if (summary == null) {
          return const SizedBox.shrink();
        }
        // Cards have a fixed height, so a plain Row is safe inside the
        // vertically-scrolling parent (no stretch / IntrinsicHeight needed).
        return Row(
          children: <Widget>[
            Expanded(
              child: _card(
                title: 'st_weekly_spending'.tr,
                value: summary.weeklySpending,
                change: summary.spendingTrend.weeklyChange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _card(
                title: 'الإنفاق الشهري',
                value: summary.monthlySpending,
                change: summary.spendingTrend.monthlyChange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card({
    required String title,
    required double value,
    required double change,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.only(top: 16, right: 14, bottom: 16, left: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _trendBadge(change),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                '﷼',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value.toStringAsFixed(2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendBadge(double change) {
    final bool up = change >= 0;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Color(0xffEBFEEB),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: Color(0xff000000),
          ),
          const SizedBox(width: 2),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xff000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(VoidCallback onRetry) {
    return Container(
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: onRetry,
        icon:
            const Icon(Icons.refresh, size: 16, color: AppColors.primaryColor),
        label: Text('retry'.tr,
            style: const TextStyle(
                fontFamily: 'Tajawal', color: AppColors.primaryColor)),
      ),
    );
  }
}
