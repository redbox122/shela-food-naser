/// ===============================
/// Saved Recipient Model (FIXED)
/// Safe for Dart 3 / Null Safety
/// ===============================
library;

/// ---------- Helpers ----------
int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// ---------- Model ----------
class SavedRecipientModel {
  int? id;
  String? recipientPhone;
  String? recipientName;
  String? recipientFullName;
  String? recipientImage;
  String? recipientStatus;
  double? lastTransferAmount;
  String? lastTransferDate;
  int? totalTransfers;
  String? createdAt;

  SavedRecipientModel({
    this.id,
    this.recipientPhone,
    this.recipientName,
    this.recipientFullName,
    this.recipientImage,
    this.recipientStatus,
    this.lastTransferAmount,
    this.lastTransferDate,
    this.totalTransfers,
    this.createdAt,
  });

  SavedRecipientModel.fromJson(Map<String, dynamic> json) {
    id = _parseInt(json['id']);
    recipientPhone = json['recipient_phone']?.toString();
    recipientName = json['recipient_name']?.toString();
    recipientFullName = json['recipient_full_name']?.toString();
    recipientImage = json['recipient_image']?.toString();
    recipientStatus = json['recipient_status']?.toString();
    lastTransferAmount = _parseDouble(json['last_transfer_amount']);
    lastTransferDate = json['last_transfer_date']?.toString();
    totalTransfers = _parseInt(json['total_transfers']);
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient_phone': recipientPhone,
        'recipient_name': recipientName,
        'recipient_full_name': recipientFullName,
        'recipient_image': recipientImage,
        'recipient_status': recipientStatus,
        'last_transfer_amount': lastTransferAmount,
        'last_transfer_date': lastTransferDate,
        'total_transfers': totalTransfers,
        'created_at': createdAt,
      };

  /// Display name priority
  String get displayName =>
      recipientName ?? recipientFullName ?? recipientPhone ?? '';
}
