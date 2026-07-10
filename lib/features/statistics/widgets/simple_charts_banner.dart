import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../domain/models/spending_trend.dart';
import '../domain/models/category_breakdown.dart';

class SimpleChartsBanner extends StatefulWidget {
  const SimpleChartsBanner({super.key});

  @override
  State<SimpleChartsBanner> createState() => _SimpleChartsBannerState();
}

class _SimpleChartsBannerState extends State<SimpleChartsBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<AnalyticsController>(
      builder: (controller) {
        return Container(
          height: 320,
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
        Text(
          'analytics_charts'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            color: AppColors.bgColor,
          ),
        ),
        const Spacer(),
        if (_currentPage == 0) _buildPeriodSelector(controller),
      ],
    );
  }

  Widget _buildPeriodSelector(AnalyticsController controller) {
    return Container(
      height: 34,
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButton<String>(
        value: controller.currentTrendPeriod,
        isDense: true,
        isExpanded: true,
        alignment: AlignmentDirectional.centerStart,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(10),
        icon: const Icon(Icons.keyboard_arrow_down,
            size: 18, color: Color(0xFF2D3633)),
        style: const TextStyle(
          fontFamily: 'Tajawal',
          color: Color(0xFF2D3633),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        items: controller.availableTrendPeriods.map((String period) {
          return DropdownMenuItem<String>(
            value: period,
            child:
                Text(period.tr, style: const TextStyle(fontFamily: 'Tajawal')),
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

    if (controller.trendsError.isNotEmpty) {
      return _buildErrorChart(controller.trendsError,
          () => controller.loadSpendingTrends(controller.currentTrendPeriod));
    }

    if (controller.spendingTrend == null ||
        controller.spendingTrend!.data.isEmpty) {
      return _buildNoDataChart();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total badge → right side (RTL start).
                _buildTrendSummary(controller.spendingTrend!),
                const Spacer(),
                // "تحليل الإنفاق" + month → left side.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'st_spending_analysis'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bgColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentMonthYear(),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8A9199),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Expanded(
              child: _buildLineChart(controller.spendingTrend!),
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

    if (controller.categoriesError.isNotEmpty) {
      return _buildErrorChart(
          controller.categoriesError, () => controller.loadCategoryBreakdown());
    }

    if (controller.categoryBreakdown == null ||
        controller.categoryBreakdown!.categories.isEmpty) {
      return _buildNoDataChart();
    }

    // Get top 5 categories only
    final top5Categories =
        controller.categoryBreakdown!.categories.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'st_category_distribution'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'st_top_5'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildPieChart(top5Categories),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    flex: 2,
                    child: _buildCategoryLegend(top5Categories),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currentMonthYear() {
    const List<String> months = <String>[
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final DateTime now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  Widget _buildTrendSummary(SpendingTrendData trendData) {
    final double totalSpent =
        trendData.data.fold(0.0, (sum, point) => sum + point.amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'st_total_spending'.tr,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.greenColor,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '﷼',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenColor,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                totalSpent.toStringAsFixed(2),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(SpendingTrendData trendData) {
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          // Y-axis labels
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _convertToArabicNumerals(
                            '${trendData.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b).toInt()}'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _convertToArabicNumerals(
                            '${(trendData.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 0.75).toInt()}'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _convertToArabicNumerals(
                            '${(trendData.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 0.5).toInt()}'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _convertToArabicNumerals(
                            '${(trendData.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 0.25).toInt()}'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _convertToArabicNumerals('0'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: LineChartPainter(trendData.data),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
          // X-axis labels
          SizedBox(
            height: 20,
            child: Row(
              children: [
                const SizedBox(width: 35),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: trendData.data.map((point) {
                        return SizedBox(
                          width: 50,
                          child: Text(
                            _formatWeekLabel(point.bucket),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<CategoryData> categories) {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: PieChartPainter(categories),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildCategoryLegend(List<CategoryData> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'st_top_5_categories'.tr,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category.categoryName),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.categoryName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildErrorChart(String error, VoidCallback onRetry) {
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
            const Icon(
              Icons.error_outline,
              color: AppColors.redColor,
              size: 48,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'failed_to_load_chart'.tr,
              style: const TextStyle(
                color: AppColors.redColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.length > 30 ? '${error.substring(0, 30)}...' : error,
              style: TextStyle(
                color: AppColors.gryColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenColor,
                foregroundColor: AppColors.wtColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
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
              color: AppColors.gryColor.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'no_data_available'.tr,
              style: TextStyle(
                color: AppColors.gryColor.withValues(alpha: 0.7),
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
                : AppColors.gryColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Color _getCategoryColor(String categoryName) {
    final colors = {
      'Grocery': AppColors.greenColor,
      'Pharmacy': AppColors.bluColor,
      'Electronics': AppColors.orangeColor,
      'Clothing': AppColors.redColor,
      'Books': AppColors.secondaryColor,
      'Food': AppColors.greenColor,
      'Health': AppColors.bluColor,
      'Technology': AppColors.orangeColor,
      'Fashion': AppColors.redColor,
      'Education': AppColors.secondaryColor,
      'st_laundry_supplies'.tr: AppColors.greenColor,
      'st_electronics_devices'.tr: AppColors.bluColor,
      'st_staple_foods'.tr: AppColors.orangeColor,
      'st_electronics_home'.tr: AppColors.redColor,
      'st_rice_pasta_legumes'.tr: AppColors.secondaryColor,
      'st_mobiles_handhelds'.tr: AppColors.primaryColor,
      'st_fresh_food'.tr: Colors.teal,
      'st_perfumes_deodorants'.tr: Colors.pink,
      'st_oral_care'.tr: Colors.cyan,
      'st_school_supplies'.tr: Colors.amber,
      'st_bags'.tr: Colors.brown,
      'st_dairy_eggs'.tr: Colors.lightBlue,
      'st_supermarket'.tr: Colors.deepOrange,
    };
    return colors[categoryName] ?? AppColors.gryColor;
  }

  String _formatWeekLabel(String bucket) {
    // Get current period from controller
    final controller = Get.find<AnalyticsController>();
    final currentPeriod = controller.currentTrendPeriod;

    if (currentPeriod == 'month') {
      // For monthly view, show month numbers 1-12
      return _formatMonthLabel(bucket);
    } else {
      // For weekly view, show day names
      return _formatWeekDayLabel(bucket);
    }
  }

  String _formatMonthLabel(String bucket) {
    // Parse "2025-03" format and extract month number
    try {
      final parts = bucket.split('-');
      if (parts.length >= 2) {
        final monthStr = parts[1];
        final month = int.tryParse(monthStr);

        if (month != null && month >= 1 && month <= 12) {
          // Show the month NAME on the X-axis (not the bare number).
          const List<String> monthNames = <String>[
            'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
            'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
          ];
          return monthNames[month - 1];
        }
      }
    } catch (e) {
      // If parsing fails, return a simplified version
    }

    // Fallback: return a simplified version
    return bucket;
  }

  String _formatWeekDayLabel(String bucket) {
    // Parse "2025-10-13" format and convert to Arabic day name
    try {
      final date = DateTime.parse(bucket);
      final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday

      // Convert to our array index (0=Sunday, 6=Saturday)
      final dayIndex = dayOfWeek == 7 ? 0 : dayOfWeek;

      final arabicDays = [
        'st_sunday'.tr, // Sunday (0)
        'st_monday'.tr, // Monday (1)
        'st_tuesday'.tr, // Tuesday (2)
        'st_wednesday'.tr, // Wednesday (3)
        'st_thursday'.tr, // Thursday (4)
        'st_friday'.tr, // Friday (5)
        'st_saturday'.tr // Saturday (6)
      ];

      return arabicDays[dayIndex];
    } catch (e) {
      // If parsing fails, return the original string
      return bucket;
    }
  }
}

class LineChartPainter extends CustomPainter {
  final List<SpendingDataPoint> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.greenColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxValue = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.amount).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw the line
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      // Distribute points evenly across the available width
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height - ((data[i].amount - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = AppColors.greenColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      // Distribute points evenly across the available width
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height - ((data[i].amount - minValue) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    // Draw area under the curve
    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.greenColor.withValues(alpha: 0.3),
          AppColors.greenColor.withValues(alpha: 0.1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final areaPath = Path();
    areaPath.addPath(path, Offset.zero);
    // Close the area to the bottom of the chart
    if (data.isNotEmpty) {
      final lastX = (data.length - 1) / (data.length - 1) * size.width;
      areaPath.lineTo(lastX, size.height);
      areaPath.lineTo(0, size.height); // First point X position
    }
    areaPath.close();

    canvas.drawPath(areaPath, areaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final List<CategoryData> categories;

  PieChartPainter(this.categories);

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
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 - 10;

    // Calculate total percentage of top 5 categories
    final totalPercentage =
        categories.fold(0.0, (sum, category) => sum + category.percentage);

    // If total is less than 100%, we need to scale the segments to fill the entire pie
    final scaleFactor = totalPercentage < 100 ? 100.0 / totalPercentage : 1.0;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      // Scale the percentage to fill the entire pie
      final scaledPercentage = category.percentage * scaleFactor;
      final sweepAngle = (scaledPercentage / 100) * 2 * 3.14159;

      final paint = Paint()
        ..color = _getCategoryColor(category.categoryName)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw percentage text on each segment
      if (category.percentage > 5) {
        // Only show text for segments > 5%
        final textAngle = startAngle + sweepAngle / 2;
        final textRadius = radius * 0.7;
        final textX = center.dx + textRadius * cos(textAngle);
        final textY = center.dy + textRadius * sin(textAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${_convertToArabicNumerals(category.percentage.toStringAsFixed(0))}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.rtl,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Color _getCategoryColor(String categoryName) {
    final colors = {
      'Grocery': AppColors.greenColor,
      'Pharmacy': AppColors.bluColor,
      'Electronics': AppColors.orangeColor,
      'Clothing': AppColors.redColor,
      'Books': AppColors.secondaryColor,
      'Food': AppColors.greenColor,
      'Health': AppColors.bluColor,
      'Technology': AppColors.orangeColor,
      'Fashion': AppColors.redColor,
      'Education': AppColors.secondaryColor,
      'st_laundry_supplies'.tr: AppColors.greenColor,
      'st_electronics_devices'.tr: AppColors.bluColor,
      'st_staple_foods'.tr: AppColors.orangeColor,
      'st_electronics_home'.tr: AppColors.redColor,
      'st_rice_pasta_legumes'.tr: AppColors.secondaryColor,
      'st_mobiles_handhelds'.tr: AppColors.primaryColor,
      'st_fresh_food'.tr: Colors.teal,
      'st_perfumes_deodorants'.tr: Colors.pink,
      'st_oral_care'.tr: Colors.cyan,
      'st_school_supplies'.tr: Colors.amber,
      'st_bags'.tr: Colors.brown,
      'st_dairy_eggs'.tr: Colors.lightBlue,
      'st_supermarket'.tr: Colors.deepOrange,
    };
    return colors[categoryName] ?? AppColors.gryColor;
  }
}
