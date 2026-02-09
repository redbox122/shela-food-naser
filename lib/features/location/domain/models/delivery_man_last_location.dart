import 'package:sixam_mart/common/utils/json_parser.dart';

class LocationDeliveryModel {
  LocationDeliveryModel({
    required this.id,
    required this.orderId,
    required this.deliveryManId,
    required this.time,
    required this.longitude,
    required this.latitude,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final dynamic orderId;
  final int? deliveryManId;
  final String? time;
  final String? longitude;
  final String? latitude;
  final String? location;
  final String? createdAt;
  final String? updatedAt;

  factory LocationDeliveryModel.fromJson(Map<String, dynamic> json) {
    return LocationDeliveryModel(
      id: json.parseInt('id'),
      orderId: json['order_id'],
      deliveryManId: json.parseInt('delivery_man_id'),
      time: json.parseString('time') ?? '',
      longitude: json.parseString('longitude'),
      latitude: json.parseString('latitude'),
      location: json.parseString('location'),
      createdAt: json.parseString('created_at') ?? '',
      updatedAt: json.parseString('updated_at') ?? '',
    );
  }
}
