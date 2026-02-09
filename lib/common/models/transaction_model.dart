class TransactionModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Transaction>? data;

  TransactionModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.data,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'] as int?;
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();

    final List<dynamic>? transactionsList =
        json['transactions'] as List<dynamic>?;
    final List<dynamic>? dataList = json['data'] as List<dynamic>?;

    final List<dynamic>? listToUse = transactionsList ?? dataList;

    data = listToUse
        ?.whereType<Map<String, dynamic>>()
        .map((e) => Transaction.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['total_size'] = totalSize;
    json['limit'] = limit;
    json['offset'] = offset;
    if (data != null) {
      json['data'] = data!.map((v) => v.toJson()).toList();
    }
    return json;
  }
}

class Transaction {
  int? userId;
  String? transactionId;
  double? credit;
  double? debit;
  double? adminBonus;
  double? balance;
  double? amount;
  String? transactionType;
  String? reference;
  DateTime? createdAt;
  DateTime? updatedAt;

  Transaction({
    this.userId,
    this.transactionId,
    this.credit,
    this.debit,
    this.adminBonus,
    this.balance,
    this.amount,
    this.transactionType,
    this.reference,
    this.createdAt,
    this.updatedAt,
  });

  /// Calculated amount
  double get calculatedAmount {
    if (amount != null && amount! > 0) {
      return amount!;
    }
    return (credit ?? 0.0) - (debit ?? 0.0);
  }

  Transaction.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'] as int?;
    transactionId = json['transaction_id']?.toString();
    credit = _parseDouble(json['credit']);
    debit = _parseDouble(json['debit']);
    adminBonus = _parseDouble(json['admin_bonus']);
    balance = _parseDouble(json['balance']);
    amount = _parseDouble(json['amount']);
    transactionType = json['transaction_type']?.toString();
    reference = json['reference']?.toString();
    createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    updatedAt = DateTime.tryParse(json['updated_at']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['user_id'] = userId;
    json['transaction_id'] = transactionId;
    json['credit'] = credit;
    json['debit'] = debit;
    json['admin_bonus'] = adminBonus;
    json['balance'] = balance;
    json['amount'] = amount;
    json['transaction_type'] = transactionType;
    json['reference'] = reference;
    json['created_at'] = createdAt?.toIso8601String();
    json['updated_at'] = updatedAt?.toIso8601String();
    return json;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
