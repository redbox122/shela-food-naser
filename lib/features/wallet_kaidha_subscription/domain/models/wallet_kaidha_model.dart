// ignore_for_file: prefer_typing_uninitialized_variables

class WalletKaidhaModel {
  WalletKaidhaModel({
    required this.message,
    required this.wallet,
    this.hasWallet,
  });

  final String? message;
  final Wallet? wallet;
  final bool? hasWallet;

  factory WalletKaidhaModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? walletMap;
    bool? hasWallet;

    if (json['data'] is Map<String, dynamic>) {
      final Map<String, dynamic> data =
          json['data'] as Map<String, dynamic>;
      hasWallet = data['has_wallet'] as bool?;
      walletMap = data;
    } else if (json['wallet'] is Map<String, dynamic>) {
      walletMap = json['wallet'] as Map<String, dynamic>;
    }

    return WalletKaidhaModel(
      message: json['message'] as String?,
      hasWallet: hasWallet,
      wallet: walletMap == null ? null : Wallet.fromJson(walletMap),
    );
  }
}

class Wallet {
  Wallet({
    required this.id,
    required this.serialNumber,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.completedBy,
    required this.creditLimit,
    required this.minimumDue,
    required this.availableBalance,
    required this.usedBalance,
    required this.usagePercentageLimit,
    required this.status,
    required this.autoLockDay,
    required this.manualUnlockExpiryDate,
    required this.usagePercentageLimitByMonthly,
    required this.signaturePath,
    required this.signatureStatus,
    required this.lockDay,
    required this.minimumDueLimit,
    required this.purchaseLimit,
    required this.usedPercentage,
    required this.totalAvilableBalance,
  });

  var id;
  var serialNumber;
  var userId;
  var createdAt;
  var updatedAt;
  var completedAt;
  var completedBy;
  var creditLimit;
  var minimumDue;
  var availableBalance;
  var usedBalance;
  var usagePercentageLimit;
  var status;
  var autoLockDay;
  var manualUnlockExpiryDate;
  var usagePercentageLimitByMonthly;
  var signaturePath;
  var signatureStatus;
  var lockDay;
  var minimumDueLimit;
  var purchaseLimit;
  var usedPercentage;
  var totalAvilableBalance;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    // Handle available_balance as double (API returns it as number)
    final dynamic availableBalanceValue = json['available_balance']?.toString();
    double? availableBalance;
    if (availableBalanceValue != null) {
      if (availableBalanceValue is double) {
        availableBalance = availableBalanceValue;
      } else if (availableBalanceValue is int) {
        availableBalance = availableBalanceValue.toDouble();
      } else if (availableBalanceValue is String) {
        availableBalance = double.tryParse(availableBalanceValue);
      }
    }
    
    return Wallet(
      id: json['id'],
      serialNumber: json['serial_number'],
      userId: json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      completedAt: json['completed_at'],
      completedBy: json['completed_by'],
      creditLimit: json['credit_limit'],
      minimumDue: json['minimum_due'],
      availableBalance: availableBalance,
      usedBalance: json['used_balance'],
      usagePercentageLimit: json['usage_percentage_limit'],
      status: json['status'],
      autoLockDay: json['auto_lock_day'],
      manualUnlockExpiryDate: json['manual_unlock_expiry_date'],
      usagePercentageLimitByMonthly: json['usage_percentage_limit_by_monthly'],
      signaturePath: json['signature_path'],
      signatureStatus: json['signature_status'],
      lockDay: json['lock_day'],
      minimumDueLimit: json['minimum_due_limit'],
      purchaseLimit: json['purchase_limit'],
      usedPercentage: json['used_percentage'],
      totalAvilableBalance: json['total_avilable_balance'],
    );
  }
}
