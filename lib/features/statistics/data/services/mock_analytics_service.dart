import 'dart:math';
import '../../domain/models/analytics_summary.dart';
import '../../domain/models/spending_trend.dart';
import '../../domain/models/category_breakdown.dart';
import '../../domain/models/most_purchased_product.dart';
import '../../domain/models/analytics_insights.dart';

class MockAnalyticsService {
  static final Random _random = Random();

  // Mock data for analytics summary
  static Future<AnalyticsSummary> getAnalyticsSummary() async {
    await Future.delayed(
        const Duration(milliseconds: 800)); // Simulate network delay

    return const AnalyticsSummary(
      monthlySpending: 1250.50,
      weeklySpending: 320.75,
      remainingBalance: 450.25,
      spendingTrend: SpendingTrend(
        monthlyChange: 12.5,
        weeklyChange: -5.2,
        trendDirection: 'increasing',
      ),
      periodComparison: PeriodComparison(
        vsLastMonth: 12.5,
        vsLastWeek: -5.2,
      ),
    );
  }

  // Mock data for spending trends
  static Future<SpendingTrendData> getSpendingTrends(String period) async {
    await Future.delayed(const Duration(milliseconds: 600));

    List<SpendingDataPoint> data = [];

    switch (period) {
      case 'day':
        data = _generateDailyData();
        break;
      case 'week':
        data = _generateWeeklyData();
        break;
      case 'month':
        data = _generateMonthlyData();
        break;
      case 'year':
        data = _generateYearlyData();
        break;
      default:
        data = _generateWeeklyData();
    }

    return SpendingTrendData(
      data: data,
      period: period,
      totalSpent: data.fold(0.0, (sum, point) => sum + point.amount),
      totalOrders: data.fold(0, (sum, point) => sum + point.orders),
    );
  }

  // Mock data for category breakdown
  static Future<CategoryBreakdown> getCategoryBreakdown() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final categories = [
      const CategoryData(
        categoryName: 'Grocery',
        spentAmount: 450.25,
        purchaseCount: 12,
        percentage: 35.2,
      ),
      const CategoryData(
        categoryName: 'Pharmacy',
        spentAmount: 320.50,
        purchaseCount: 8,
        percentage: 25.1,
      ),
      const CategoryData(
        categoryName: 'Electronics',
        spentAmount: 280.75,
        purchaseCount: 3,
        percentage: 22.0,
      ),
      const CategoryData(
        categoryName: 'Clothing',
        spentAmount: 150.00,
        purchaseCount: 5,
        percentage: 11.7,
      ),
      const CategoryData(
        categoryName: 'Books',
        spentAmount: 80.00,
        purchaseCount: 4,
        percentage: 6.0,
      ),
    ];

    return CategoryBreakdown(
      categories: categories,
      totalSpent: categories.fold(0.0, (sum, cat) => sum + cat.spentAmount),
      totalItems: categories.fold(0, (sum, cat) => sum + cat.purchaseCount),
    );
  }

  // Mock data for most purchased products
  static Future<List<MostPurchasedProduct>> getMostPurchasedProducts({
    String sortBy = 'frequency',
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final products = [
      const MostPurchasedProduct(
        itemId: 1,
        name: 'Fresh Milk 1L',
        image: 'assets/image/milk.png',
        purchaseCount: 15,
        totalSpent: 187.50,
        lastPurchased: '2024-01-15',
        purchaseFrequency: 'Weekly',
        priceRange: PriceRange(current: 12.50, min: 10.00, max: 15.00),
        category: 'Dairy',
      ),
      const MostPurchasedProduct(
        itemId: 2,
        name: 'Bread Loaf',
        image: 'assets/image/bread.png',
        purchaseCount: 12,
        totalSpent: 96.00,
        lastPurchased: '2024-01-14',
        purchaseFrequency: 'Weekly',
        priceRange: PriceRange(current: 8.00, min: 6.00, max: 10.00),
        category: 'Bakery',
      ),
      const MostPurchasedProduct(
        itemId: 3,
        name: 'Chicken Breast 500g',
        image: 'assets/image/chicken.png',
        purchaseCount: 8,
        totalSpent: 200.00,
        lastPurchased: '2024-01-12',
        purchaseFrequency: 'Bi-weekly',
        priceRange: PriceRange(current: 25.00, min: 20.00, max: 30.00),
        category: 'Meat',
      ),
      const MostPurchasedProduct(
        itemId: 4,
        name: 'Bananas 1kg',
        image: 'assets/image/bananas.png',
        purchaseCount: 10,
        totalSpent: 65.00,
        lastPurchased: '2024-01-13',
        purchaseFrequency: 'Weekly',
        priceRange: PriceRange(current: 6.50, min: 5.00, max: 8.00),
        category: 'Fruits',
      ),
      const MostPurchasedProduct(
        itemId: 5,
        name: 'Rice 5kg',
        image: 'assets/image/rice.png',
        purchaseCount: 6,
        totalSpent: 270.00,
        lastPurchased: '2024-01-10',
        purchaseFrequency: 'Monthly',
        priceRange: PriceRange(current: 45.00, min: 40.00, max: 50.00),
        category: 'Grains',
      ),
      const MostPurchasedProduct(
        itemId: 6,
        name: 'Eggs 12 pieces',
        image: 'assets/image/eggs.png',
        purchaseCount: 9,
        totalSpent: 162.00,
        lastPurchased: '2024-01-14',
        purchaseFrequency: 'Weekly',
        priceRange: PriceRange(current: 18.00, min: 15.00, max: 22.00),
        category: 'Dairy',
      ),
    ];

    // Sort based on sortBy parameter
    switch (sortBy) {
      case 'frequency':
        products.sort((a, b) => b.purchaseCount.compareTo(a.purchaseCount));
        break;
      case 'amount':
        products.sort(
            (a, b) => b.priceRange.current.compareTo(a.priceRange.current));
        break;
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return products.take(limit).toList();
  }

  // Mock data for analytics insights
  static Future<AnalyticsInsights> getAnalyticsInsights() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final insights = [
      const Insight(
        type: 'spending',
        title: 'High Grocery Spending',
        message: 'Your grocery spending is 25% higher than last month. Consider buying in bulk for better savings.',
        severity: 'warning',
        description: 'Your grocery spending is 25% higher than last month. Consider buying in bulk for better savings.',
        priority: 'high',
        metadata: {'category': 'Grocery', 'increase_percentage': 25.0},
      ),
      const Insight(
        type: 'savings',
        title: 'Weekly Budget Alert',
        message: 'You\'ve spent 80% of your weekly budget. Consider reducing non-essential purchases.',
        severity: 'warning',
        description: 'You\'ve spent 80% of your weekly budget. Consider reducing non-essential purchases.',
        priority: 'medium',
        metadata: {'budget_used': 80.0, 'remaining': 20.0},
      ),
      const Insight(
        type: 'recommendation',
        title: 'Try New Categories',
        message: 'You haven\'t purchased from Electronics in 2 weeks. Check out our latest deals!',
        severity: 'info',
        description: 'You haven\'t purchased from Electronics in 2 weeks. Check out our latest deals!',
        priority: 'low',
        metadata: {'category': 'Electronics', 'last_purchase_days': 14},
      ),
    ];

    return AnalyticsInsights(
      insights: insights,
      smartTips: [
        'You save 10% when buying in bulk',
        'Your favorite store has a 20% discount on weekends',
        'Consider setting a monthly budget to track spending',
      ],
      generatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Helper methods to generate mock data
  static List<SpendingDataPoint> _generateDailyData() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return SpendingDataPoint(
        bucket: _getDayName(date.weekday),
        amount: 50.0 + _random.nextDouble() * 100,
        orders: 1 + _random.nextInt(5),
        date: date.toIso8601String().split('T')[0],
      );
    });
  }

  static List<SpendingDataPoint> _generateWeeklyData() {
    final now = DateTime.now();
    return List.generate(4, (index) {
      final weekStart = now.subtract(Duration(days: (3 - index) * 7));
      return SpendingDataPoint(
        bucket: 'Week ${4 - index}',
        amount: 200.0 + _random.nextDouble() * 300,
        orders: 5 + _random.nextInt(15),
        date: weekStart.toIso8601String().split('T')[0],
      );
    });
  }

  static List<SpendingDataPoint> _generateMonthlyData() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final month = now.subtract(Duration(days: (5 - index) * 30));
      return SpendingDataPoint(
        bucket: _getMonthName(month.month),
        amount: 800.0 + _random.nextDouble() * 500,
        orders: 20 + _random.nextInt(30),
        date: month.toIso8601String().split('T')[0],
      );
    });
  }

  static List<SpendingDataPoint> _generateYearlyData() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final month = now.subtract(Duration(days: (11 - index) * 30));
      return SpendingDataPoint(
        bucket: _getMonthName(month.month),
        amount: 1000.0 + _random.nextDouble() * 800,
        orders: 50 + _random.nextInt(100),
        date: month.toIso8601String().split('T')[0],
      );
    });
  }

  static String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
