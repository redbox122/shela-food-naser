class QidhaWalletInfo {
  final double availableBalance;
  final double usedBalance;
  final double creditLimit;
  final String status;
  final int signatureStatus;
  final String createdAt;

  QidhaWalletInfo({
    required this.availableBalance,
    required this.usedBalance,
    required this.creditLimit,
    required this.status,
    required this.signatureStatus,
    required this.createdAt,
  });

  factory QidhaWalletInfo.fromJson(Map<String, dynamic> json) {
    return QidhaWalletInfo(
      availableBalance:
          double.tryParse(json['available_balance'].toString()) ?? 0.0,
      usedBalance: double.tryParse(json['used_balance'].toString()) ?? 0.0,
      creditLimit: double.tryParse(json['credit_limit'].toString()) ?? 0.0,
      status: json['status'] as String? ?? '',
      signatureStatus: (json['signature_status'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class QidhaSpendingAnalytics {
  final double totalSpentThisPeriod;
  final double totalSpentLastPeriod;
  final String spendingTrend;
  final double spendingTrendPercentage;
  final double averageDailySpending;
  final double highestSinglePurchase;
  final double lowestSinglePurchase;

  QidhaSpendingAnalytics({
    required this.totalSpentThisPeriod,
    required this.totalSpentLastPeriod,
    required this.spendingTrend,
    required this.spendingTrendPercentage,
    required this.averageDailySpending,
    required this.highestSinglePurchase,
    required this.lowestSinglePurchase,
  });

  factory QidhaSpendingAnalytics.fromJson(Map<String, dynamic> json) {
    return QidhaSpendingAnalytics(
      totalSpentThisPeriod:
          double.tryParse(json['total_spent_this_period'].toString()) ?? 0.0,
      totalSpentLastPeriod:
          double.tryParse(json['total_spent_last_period'].toString()) ?? 0.0,
      spendingTrend: json['spending_trend'] as String? ?? 'stable',
      spendingTrendPercentage:
          double.tryParse(json['spending_trend_percentage'].toString()) ?? 0.0,
      averageDailySpending:
          double.tryParse(json['average_daily_spending'].toString()) ?? 0.0,
      highestSinglePurchase:
          double.tryParse(json['highest_single_purchase'].toString()) ?? 0.0,
      lowestSinglePurchase:
          double.tryParse(json['lowest_single_purchase'].toString()) ?? 0.0,
    );
  }
}

class QidhaPaymentFrequency {
  final int totalOrdersPaid;
  final int ordersThisPeriod;
  final int ordersLastPeriod;
  final double averageOrdersPerWeek;
  final String mostActiveDay;
  final int mostActiveHour;

  QidhaPaymentFrequency({
    required this.totalOrdersPaid,
    required this.ordersThisPeriod,
    required this.ordersLastPeriod,
    required this.averageOrdersPerWeek,
    required this.mostActiveDay,
    required this.mostActiveHour,
  });

  factory QidhaPaymentFrequency.fromJson(Map<String, dynamic> json) {
    return QidhaPaymentFrequency(
      totalOrdersPaid: (json['total_orders_paid'] as num?)?.toInt() ?? 0,
      ordersThisPeriod: (json['orders_this_period'] as num?)?.toInt() ?? 0,
      ordersLastPeriod: (json['orders_last_period'] as num?)?.toInt() ?? 0,
      averageOrdersPerWeek:
          double.tryParse(json['average_orders_per_week'].toString()) ?? 0.0,
      mostActiveDay: json['most_active_day'] as String? ?? '',
      mostActiveHour: (json['most_active_hour'] as num?)?.toInt() ?? 0,
    );
  }
}

class QidhaDuePayments {
  final double totalDueAmount;
  final int duePaymentsCount;
  final String oldestDueDate;
  final String newestDueDate;
  final int overduePayments;
  final double overdueAmount;

  QidhaDuePayments({
    required this.totalDueAmount,
    required this.duePaymentsCount,
    required this.oldestDueDate,
    required this.newestDueDate,
    required this.overduePayments,
    required this.overdueAmount,
  });

  factory QidhaDuePayments.fromJson(Map<String, dynamic> json) {
    return QidhaDuePayments(
      totalDueAmount:
          double.tryParse(json['total_due_amount'].toString()) ?? 0.0,
      duePaymentsCount: (json['due_payments_count'] as num?)?.toInt() ?? 0,
      oldestDueDate: json['oldest_due_date'] as String? ?? '',
      newestDueDate: json['newest_due_date'] as String? ?? '',
      overduePayments: (json['overdue_payments'] as num?)?.toInt() ?? 0,
      overdueAmount: double.tryParse(json['overdue_amount'].toString()) ?? 0.0,
    );
  }
}

class QidhaRefundAnalytics {
  final double totalRefunds;
  final int refundCount;
  final double averageRefundAmount;
  final double refundRatePercentage;

  QidhaRefundAnalytics({
    required this.totalRefunds,
    required this.refundCount,
    required this.averageRefundAmount,
    required this.refundRatePercentage,
  });

  factory QidhaRefundAnalytics.fromJson(Map<String, dynamic> json) {
    return QidhaRefundAnalytics(
      totalRefunds: double.tryParse(json['total_refunds'].toString()) ?? 0.0,
      refundCount: (json['refund_count'] as num?)?.toInt() ?? 0,
      averageRefundAmount:
          double.tryParse(json['average_refund_amount'].toString()) ?? 0.0,
      refundRatePercentage:
          double.tryParse(json['refund_rate_percentage'].toString()) ?? 0.0,
    );
  }
}

class QidhaSalaryDayInfo {
  final int salaryDay;
  final String nextSalaryDate;
  final int daysUntilSalary;
  final double salaryAmount;
  final double duePaymentsVsSalaryRatio;
  final double totalDueAmount;
  final double minimumDueAmount;
  final String walletStatus;
  final bool isPaymentDue;

  QidhaSalaryDayInfo({
    required this.salaryDay,
    required this.nextSalaryDate,
    required this.daysUntilSalary,
    required this.salaryAmount,
    required this.duePaymentsVsSalaryRatio,
    required this.totalDueAmount,
    required this.minimumDueAmount,
    required this.walletStatus,
    required this.isPaymentDue,
  });

  factory QidhaSalaryDayInfo.fromJson(Map<String, dynamic> json) {
    return QidhaSalaryDayInfo(
      salaryDay: (json['salary_day'] as num?)?.toInt() ?? 1,
      nextSalaryDate: json['next_salary_date'] as String? ?? '',
      daysUntilSalary: (json['days_until_salary'] as num?)?.toInt() ?? 0,
      salaryAmount: double.tryParse(json['salary_amount'].toString()) ?? 0.0,
      duePaymentsVsSalaryRatio:
          double.tryParse(json['due_payments_vs_salary_ratio'].toString()) ??
              0.0,
      totalDueAmount:
          double.tryParse(json['total_due_amount'].toString()) ?? 0.0,
      minimumDueAmount:
          double.tryParse(json['minimum_due_amount'].toString()) ?? 0.0,
      walletStatus: json['wallet_status'] as String? ?? '',
      isPaymentDue: json['is_payment_due'] as bool? ?? false,
    );
  }
}

class QidhaWalletAnalyticsSummary {
  final QidhaWalletInfo walletInfo;
  final QidhaSpendingAnalytics spendingAnalytics;
  final QidhaPaymentFrequency paymentFrequency;
  final QidhaDuePayments duePayments;
  final QidhaRefundAnalytics refundAnalytics;
  final QidhaSalaryDayInfo? salaryDayInfo;

  QidhaWalletAnalyticsSummary({
    required this.walletInfo,
    required this.spendingAnalytics,
    required this.paymentFrequency,
    required this.duePayments,
    required this.refundAnalytics,
    this.salaryDayInfo,
  });

  factory QidhaWalletAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return QidhaWalletAnalyticsSummary(
      walletInfo: QidhaWalletInfo.fromJson(
        json['wallet_info'] as Map<String, dynamic>? ?? {},
      ),
      spendingAnalytics: QidhaSpendingAnalytics.fromJson(
          json['spending_analytics'] as Map<String, dynamic>? ?? {}),
      paymentFrequency: QidhaPaymentFrequency.fromJson(
          json['payment_frequency'] as Map<String, dynamic>? ?? {}),
      duePayments: QidhaDuePayments.fromJson(
          json['due_payments'] as Map<String, dynamic>? ?? {}),
      refundAnalytics: QidhaRefundAnalytics.fromJson(
          json['refund_analytics'] as Map<String, dynamic>? ?? {}),
      salaryDayInfo: json['salary_day_info'] != null
          ? QidhaSalaryDayInfo.fromJson(
              json['something'] as Map<String, dynamic>? ?? {},
            )
          : null,
    );
  }
}

class QidhaTransaction {
  final int id;
  final String transactionId;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final int? orderId;
  final String paymentMethod;
  final String status;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic>? metadata;

  QidhaTransaction({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.orderId,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory QidhaTransaction.fromJson(Map<String, dynamic> json) {
    return QidhaTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      transactionId: json['transaction_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      balanceBefore: double.tryParse(json['balance_before'].toString()) ?? 0.0,
      balanceAfter: double.tryParse(json['balance_after'].toString()) ?? 0.0,
      description: json['description'] as String? ?? '',
      orderId: (json['order_id'] as num?)?.toInt(),
      paymentMethod: json['payment_method'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class QidhaSpendingCategory {
  final int categoryId;
  final String categoryName;
  final String categoryNameAr;
  final double totalSpent;
  final int transactionCount;
  final double percentage;
  final double averageOrderValue;
  final String lastPurchase;
  final String? categoryImageUrl; // Added for category image

  QidhaSpendingCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryNameAr,
    required this.totalSpent,
    required this.transactionCount,
    required this.percentage,
    required this.averageOrderValue,
    required this.lastPurchase,
    this.categoryImageUrl, // Added for category image
  });

  factory QidhaSpendingCategory.fromJson(Map<String, dynamic> json) {
    return QidhaSpendingCategory(
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      categoryName: json['category_name'] as String? ?? '',
      categoryNameAr: json['category_name_ar'] as String? ?? '',
      totalSpent: double.tryParse(json['total_spent'].toString()) ?? 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      averageOrderValue:
          double.tryParse(json['average_order_value'].toString()) ?? 0.0,
      lastPurchase: json['last_purchase'] as String? ?? '',
      categoryImageUrl: json['category_image_url'] as String?,
    );
  }
}

class QidhaMonthlyTrend {
  final String month;
  final String monthName;
  final String monthNameAr;
  final double totalSpent;
  final int transactionCount;
  final double averageOrderValue;
  final double duePaymentsPaid;
  final double refundsReceived;
  final double balanceStart;
  final double balanceEnd;

  QidhaMonthlyTrend({
    required this.month,
    required this.monthName,
    required this.monthNameAr,
    required this.totalSpent,
    required this.transactionCount,
    required this.averageOrderValue,
    required this.duePaymentsPaid,
    required this.refundsReceived,
    required this.balanceStart,
    required this.balanceEnd,
  });

  factory QidhaMonthlyTrend.fromJson(Map<String, dynamic> json) {
    return QidhaMonthlyTrend(
      month: json['month'] as String? ?? '',
      monthName: json['month_name'] as String? ?? '',
      monthNameAr: json['month_name_ar'] as String? ?? '',
      totalSpent: double.tryParse(json['total_spent'].toString()) ?? 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      averageOrderValue:
          double.tryParse(json['average_order_value'].toString()) ?? 0.0,
      duePaymentsPaid:
          double.tryParse(json['due_payments_paid'].toString()) ?? 0.0,
      refundsReceived:
          double.tryParse(json['refunds_received'].toString()) ?? 0.0,
      balanceStart: double.tryParse(json['balance_start'].toString()) ?? 0.0,
      balanceEnd: double.tryParse(json['balance_end'].toString()) ?? 0.0,
    );
  }
}
