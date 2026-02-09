/// ===============================
/// Transfer Response Models (ALL-IN-ONE)
/// Safe for Dart 3 / Null Safety / Weird APIs 😎
/// ===============================
library;

/// ---------- Helpers ----------
bool? _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return null;
}

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// ---------- TransferResponseModel ----------
class TransferResponseModel {
  bool? success;
  String? message;
  TransferData? data;
  String? errorCode;

  // Error-specific fields
  double? availableBalance;
  double? requiredAmount;
  double? dailyLimit;
  double? alreadySpent;
  double? remaining;
  double? requestedAmount;

  TransferResponseModel({
    this.success,
    this.message,
    this.data,
    this.errorCode,
    this.availableBalance,
    this.requiredAmount,
    this.dailyLimit,
    this.alreadySpent,
    this.remaining,
    this.requestedAmount,
  });

  TransferResponseModel.fromJson(Map<String, dynamic> json) {
    success = _parseBool(json['success']);
    message = json['message']?.toString();
    errorCode = json['error_code']?.toString();

    data = json['data'] is Map<String, dynamic>
        ? TransferData.fromJson(json['data'] as Map<String, dynamic>)
        : null;

    availableBalance = _parseDouble(json['available_balance']);
    requiredAmount = _parseDouble(json['required_amount']);
    dailyLimit = _parseDouble(json['daily_limit']);
    alreadySpent = _parseDouble(json['already_spent']);
    remaining = _parseDouble(json['remaining']);
    requestedAmount = _parseDouble(json['requested_amount']);
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
        'error_code': errorCode,
        'available_balance': availableBalance,
        'required_amount': requiredAmount,
        'daily_limit': dailyLimit,
        'already_spent': alreadySpent,
        'remaining': remaining,
        'requested_amount': requestedAmount,
      };
}

/// ---------- TransferData ----------
class TransferData {
  String? transactionId;
  double? amount;
  RecipientInfo? recipient;
  double? senderNewBalance;
  String? paymentSource;
  String? createdAt;

  TransferData({
    this.transactionId,
    this.amount,
    this.recipient,
    this.senderNewBalance,
    this.paymentSource,
    this.createdAt,
  });

  TransferData.fromJson(Map<String, dynamic> json) {
    transactionId = json['transaction_id']?.toString();
    amount = _parseDouble(json['amount']);
    senderNewBalance = _parseDouble(json['sender_new_balance']);
    paymentSource = json['payment_source']?.toString();
    createdAt = json['created_at']?.toString();

    recipient = json['recipient'] is Map<String, dynamic>
        ? RecipientInfo.fromJson(json['recipient'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() => {
        'transaction_id': transactionId,
        'amount': amount,
        'recipient': recipient?.toJson(),
        'sender_new_balance': senderNewBalance,
        'payment_source': paymentSource,
        'created_at': createdAt,
      };
}

/// ---------- RecipientInfo ----------
class RecipientInfo {
  String? name;
  String? phone;

  RecipientInfo({this.name, this.phone});

  RecipientInfo.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    phone = json['phone']?.toString();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };
}
