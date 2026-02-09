class OrderChatModel {
  String? orderId;
  String? reason;
  String? customMessage;

  OrderChatModel({this.orderId, this.reason, this.customMessage});

  OrderChatModel.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id']?.toString();
    reason = json['reason']?.toString();
    customMessage = json['custom_message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['reason'] = reason;
    data['custom_message'] = customMessage;
    return data;
  }
}
