/// Model for transfer request payload
/// Contains all data needed to execute a money transfer
class TransferRequestModel {
  String recipientPhone;
  double amount;
  String paymentSource; // 'wallet' or 'wallet_qidha'
  bool saveRecipient;
  String? recipientNickname;
  String? message;

  TransferRequestModel({
    required this.recipientPhone,
    required this.amount,
    required this.paymentSource,
    this.saveRecipient = false,
    this.recipientNickname,
    this.message,
  });

  /// Converts instance to JSON for API request payload
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['recipient_phone'] = recipientPhone;
    data['amount'] = amount;
    data['payment_source'] = paymentSource;
    data['save_recipient'] = saveRecipient;
    if (recipientNickname != null && recipientNickname!.isNotEmpty) {
      data['recipient_nickname'] = recipientNickname;
    }
    if (message != null && message!.isNotEmpty) {
      data['message'] = message;
    }
    return data;
  }
}





