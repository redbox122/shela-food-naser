import 'package:sixam_mart/common/utils/json_parser.dart';

class SpendingTrendData {
  final List<SpendingDataPoint> data;
  final String period;
  final double totalSpent;
  final int totalOrders;

  const SpendingTrendData({
    required this.data,
    required this.period,
    required this.totalSpent,
    required this.totalOrders,
  });

  factory SpendingTrendData.fromJson(Map<String, dynamic> json) {
    return SpendingTrendData(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => SpendingDataPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      period: json.parseString('period') ?? '',
      totalSpent: json.parseDouble('total_spent') ?? 0.0,
      totalOrders: json.parseInt('total_orders') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'period': period,
      'total_spent': totalSpent,
      'total_orders': totalOrders,
    };
  }
}

class SpendingDataPoint {
  final String bucket;
  final double amount;
  final int orders;
  final String date;

  const SpendingDataPoint({
    required this.bucket,
    required this.amount,
    required this.orders,
    required this.date,
  });

  factory SpendingDataPoint.fromJson(Map<String, dynamic> json) {
    return SpendingDataPoint(
      bucket: json.parseString('bucket') ?? '',
      amount: json.parseDouble('amount') ?? 0.0,
      orders: json.parseInt('orders') ?? 0,
      date: json.parseString('date') ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bucket': bucket,
      'amount': amount,
      'orders': orders,
      'date': date,
    };
  }
}
