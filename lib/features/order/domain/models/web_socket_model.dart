/// ✅ موديل WebSocket محلي
class WebSocketServiceModel {
  final int orderId;
  final String status;
  final DateTime timestamp;

  WebSocketServiceModel({
    required this.orderId,
    required this.status,
    required this.timestamp,
  });

  factory WebSocketServiceModel.fromJson(Map<String, dynamic> json) {
    return WebSocketServiceModel(
      orderId: json['order_id'] as int,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'WebSocketServiceModel(orderId: $orderId, status: $status, timestamp: $timestamp)';
}
