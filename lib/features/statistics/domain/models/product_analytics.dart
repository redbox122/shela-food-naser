import 'package:sixam_mart/common/utils/json_parser.dart';

class ProductAnalytics {
  final int itemId;
  final String name;
  final ProductAnalyticsData analytics;
  final List<PurchaseHistory> purchaseHistory;

  const ProductAnalytics({
    required this.itemId,
    required this.name,
    required this.analytics,
    required this.purchaseHistory,
  });

  factory ProductAnalytics.fromJson(Map<String, dynamic> json) {
    return ProductAnalytics(
      itemId: json.parseInt('item_id') ?? 0,
      name: json.parseString('name') ?? '',
      analytics: ProductAnalyticsData.fromJson(json.parseMap('analytics') ?? {}),
      purchaseHistory: (json['purchase_history'] as List<dynamic>?)
              ?.map((item) => PurchaseHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'name': name,
      'analytics': analytics.toJson(),
      'purchase_history': purchaseHistory.map((item) => item.toJson()).toList(),
    };
  }
}

class ProductAnalyticsData {
  final int totalPurchases;
  final double totalSpent;
  final double averageOrderValue;
  final String purchaseFrequency;
  final String firstPurchase;
  final String lastPurchase;
  final List<PriceHistory> priceHistory;
  final PurchasePattern purchasePattern;

  const ProductAnalyticsData({
    required this.totalPurchases,
    required this.totalSpent,
    required this.averageOrderValue,
    required this.purchaseFrequency,
    required this.firstPurchase,
    required this.lastPurchase,
    required this.priceHistory,
    required this.purchasePattern,
  });

  factory ProductAnalyticsData.fromJson(Map<String, dynamic> json) {
    return ProductAnalyticsData(
      totalPurchases: json.parseInt('total_purchases') ?? 0,
      totalSpent: json.parseDouble('total_spent') ?? 0.0,
      averageOrderValue: json.parseDouble('average_order_value') ?? 0.0,
      purchaseFrequency: json.parseString('purchase_frequency') ?? '',
      firstPurchase: json.parseString('first_purchase') ?? '',
      lastPurchase: json.parseString('last_purchase') ?? '',
      priceHistory: (json['price_history'] as List<dynamic>?)
              ?.map((item) => PriceHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      purchasePattern: PurchasePattern.fromJson(json.parseMap('purchase_pattern') ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_purchases': totalPurchases,
      'total_spent': totalSpent,
      'average_order_value': averageOrderValue,
      'purchase_frequency': purchaseFrequency,
      'first_purchase': firstPurchase,
      'last_purchase': lastPurchase,
      'price_history': priceHistory.map((item) => item.toJson()).toList(),
      'purchase_pattern': purchasePattern.toJson(),
    };
  }
}

class PriceHistory {
  final String date;
  final double price;

  const PriceHistory({
    required this.date,
    required this.price,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      date: json.parseString('date') ?? '',
      price: json.parseDouble('price') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'price': price,
    };
  }
}

class PurchasePattern {
  final String mostCommonDay;
  final String mostCommonTime;
  final String seasonalTrend;

  const PurchasePattern({
    required this.mostCommonDay,
    required this.mostCommonTime,
    required this.seasonalTrend,
  });

  factory PurchasePattern.fromJson(Map<String, dynamic> json) {
    return PurchasePattern(
      mostCommonDay: json.parseString('most_common_day') ?? '',
      mostCommonTime: json.parseString('most_common_time') ?? '',
      seasonalTrend: json.parseString('seasonal_trend') ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'most_common_day': mostCommonDay,
      'most_common_time': mostCommonTime,
      'seasonal_trend': seasonalTrend,
    };
  }
}

class PurchaseHistory {
  final String date;
  final String invoice;
  final int quantity;
  final double unitPrice;
  final double total;
  final String deliveryStatus;
  final String paymentMethod;

  const PurchaseHistory({
    required this.date,
    required this.invoice,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.deliveryStatus,
    required this.paymentMethod,
  });

  factory PurchaseHistory.fromJson(Map<String, dynamic> json) {
    return PurchaseHistory(
      date: json.parseString('date') ?? '',
      invoice: json.parseString('invoice') ?? '',
      quantity: json.parseInt('quantity') ?? 0,
      unitPrice: json.parseDouble('unit_price') ?? 0.0,
      total: json.parseDouble('total') ?? 0.0,
      deliveryStatus: json.parseString('delivery_status') ?? '',
      paymentMethod: json.parseString('payment_method') ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'invoice': invoice,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'delivery_status': deliveryStatus,
      'payment_method': paymentMethod,
    };
  }
}
