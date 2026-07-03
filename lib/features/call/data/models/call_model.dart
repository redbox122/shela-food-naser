/// Data returned by `POST /api/v1/call/token` and used to join an Agora channel.
/// Kept intentionally lenient — the backend key names may vary, so every getter
/// falls back across the common variants.
class CallTokenModel {
  final String appId;
  final String token;
  final String channelName;
  final int uid;

  const CallTokenModel({
    required this.appId,
    required this.token,
    required this.channelName,
    required this.uid,
  });

  factory CallTokenModel.fromJson(Map<String, dynamic> json,
      {String fallbackAppId = ''}) {
    return CallTokenModel(
      appId: (json['app_id'] ?? json['appId'] ?? fallbackAppId).toString(),
      token: (json['token'] ?? json['rtc_token'] ?? '').toString(),
      channelName:
          (json['channel_name'] ?? json['channel'] ?? json['channelName'] ?? '')
              .toString(),
      uid: int.tryParse('${json['uid'] ?? 0}') ?? 0,
    );
  }
}

/// Lightweight description of the other party on a call (the captain, from the
/// customer's side). Populated from the order-tracking data or the incoming
/// call push payload.
class CallPeer {
  final String? name;
  final String? imageUrl;
  final String? vehicleNumber;

  const CallPeer({this.name, this.imageUrl, this.vehicleNumber});

  factory CallPeer.fromJson(Map<String, dynamic> json) => CallPeer(
        name: (json['name'] ?? json['driver_name'])?.toString(),
        imageUrl:
            (json['image'] ?? json['image_full_url'] ?? json['photo'])?.toString(),
        vehicleNumber:
            (json['vehicle_number'] ?? json['car_number'] ?? json['plate'])
                ?.toString(),
      );
}

/// Everything an incoming-call push carries so the UI can render before any
/// network call. Parsed from FCM `data`.
class IncomingCallPayload {
  final int? orderId;
  final int? callerId; // the driver
  final CallPeer peer;

  const IncomingCallPayload({this.orderId, this.callerId, required this.peer});

  factory IncomingCallPayload.fromData(Map<String, dynamic> data) {
    return IncomingCallPayload(
      orderId: int.tryParse('${data['order_id'] ?? ''}'),
      callerId: int.tryParse('${data['caller_id'] ?? data['driver_id'] ?? ''}'),
      peer: CallPeer.fromJson(data),
    );
  }

  bool get isCallType =>
      true; // callers already checked data['type']=='incoming_call'
}
