import 'package:sixam_mart/common/utils/json_parser.dart';

class AnalyticsSummary {
  final double monthlySpending;
  final double weeklySpending;
  final double remainingBalance;
  final SpendingTrend spendingTrend;
  final PeriodComparison periodComparison;

  const AnalyticsSummary({
    required this.monthlySpending,
    required this.weeklySpending,
    required this.remainingBalance,
    required this.spendingTrend,
    required this.periodComparison,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      monthlySpending: json.parseDouble('monthly_spending') ?? 0.0,
      weeklySpending: json.parseDouble('weekly_spending') ?? 0.0,
      remainingBalance: json.parseDouble('remaining_balance') ?? 0.0,
      spendingTrend: SpendingTrend.fromJson(json.parseMap('spending_trend') ?? {}),
      periodComparison: PeriodComparison.fromJson(json.parseMap('period_comparison') ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly_spending': monthlySpending,
      'weekly_spending': weeklySpending,
      'remaining_balance': remainingBalance,
      'spending_trend': spendingTrend.toJson(),
      'period_comparison': periodComparison.toJson(),
    };
  }
}

class PeriodComparison {
  final double vsLastMonth;
  final double vsLastWeek;

  const PeriodComparison({
    required this.vsLastMonth,
    required this.vsLastWeek,
  });

  factory PeriodComparison.fromJson(Map<String, dynamic> json) {
    return PeriodComparison(
      vsLastMonth: json.parseDouble('vs_last_month') ?? 0.0,
      vsLastWeek: json.parseDouble('vs_last_week') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vs_last_month': vsLastMonth,
      'vs_last_week': vsLastWeek,
    };
  }
}

class SpendingTrend {
  final double monthlyChange;
  final double weeklyChange;
  final String trendDirection;

  const SpendingTrend({
    required this.monthlyChange,
    required this.weeklyChange,
    required this.trendDirection,
  });

  factory SpendingTrend.fromJson(Map<String, dynamic> json) {
    return SpendingTrend(
      monthlyChange: json.parseDouble('monthly_change') ?? 0.0,
      weeklyChange: json.parseDouble('weekly_change') ?? 0.0,
      trendDirection: json.parseString('trend_direction') ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly_change': monthlyChange,
      'weekly_change': weeklyChange,
      'trend_direction': trendDirection,
    };
  }
}
