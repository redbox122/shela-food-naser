import 'package:sixam_mart/common/utils/json_parser.dart';

class ProductTransaction {
  final String orderId;
  final String purchaseDate;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final String status;
  final String? storeName;
  final String? deliveryDate;
  final String? paymentMethod;
  final String? notes;

  ProductTransaction({
    required this.orderId,
    required this.purchaseDate,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.status,
    this.storeName,
    this.deliveryDate,
    this.paymentMethod,
    this.notes,
  });

  factory ProductTransaction.fromJson(Map<String, dynamic> json) {
    return ProductTransaction(
      orderId: json.parseString('order_id') ?? 'N/A',
      purchaseDate: json.parseString('purchase_date') ?? 'N/A',
      quantity: json.parseInt('quantity') ?? 0,
      pricePerUnit: json.parseDouble('price_per_unit') ?? 0.0,
      totalPrice: json.parseDouble('total_price') ?? 0.0,
      status: json.parseString('status') ?? 'completed',
      storeName: json.parseString('store_name'),
      deliveryDate: json.parseString('delivery_date'),
      paymentMethod: json.parseString('payment_method'),
      notes: json.parseString('notes'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'purchase_date': purchaseDate,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
      'status': status,
      'store_name': storeName,
      'delivery_date': deliveryDate,
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }
}

class ProductTransactionHistory {
  final List<ProductTransaction> transactions;
  final int totalTransactions;
  final double totalSpent;
  final double averageQuantity;
  final String lastPurchaseDate;
  final int purchaseFrequencyDays;
  final double priceRangeMin;
  final double priceRangeMax;
  final String trend;

  ProductTransactionHistory({
    required this.transactions,
    required this.totalTransactions,
    required this.totalSpent,
    required this.averageQuantity,
    required this.lastPurchaseDate,
    required this.purchaseFrequencyDays,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.trend,
  });

  factory ProductTransactionHistory.fromJson(Map<String, dynamic> json) {
    final transactionsList = json['transactions'] as List?;
    final List<ProductTransaction> parsedTransactions =
        transactionsList?.map((i) => ProductTransaction.fromJson(i as Map<String, dynamic>)).toList() ??
            [];

    return ProductTransactionHistory(
      transactions: parsedTransactions,
      totalTransactions: json.parseInt('total_transactions') ?? 0,
      totalSpent: json.parseDouble('total_spent') ?? 0.0,
      averageQuantity: json.parseDouble('average_quantity') ?? 0.0,
      lastPurchaseDate: json.parseString('last_purchase_date') ?? 'N/A',
      purchaseFrequencyDays: json.parseInt('purchase_frequency_days') ?? 0,
      priceRangeMin: json.parseDouble('price_range_min') ?? 0.0,
      priceRangeMax: json.parseDouble('price_range_max') ?? 0.0,
      trend: json.parseString('trend') ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((x) => x.toJson()).toList(),
      'total_transactions': totalTransactions,
      'total_spent': totalSpent,
      'average_quantity': averageQuantity,
      'last_purchase_date': lastPurchaseDate,
      'purchase_frequency_days': purchaseFrequencyDays,
      'price_range_min': priceRangeMin,
      'price_range_max': priceRangeMax,
      'trend': trend,
    };
  }
}
