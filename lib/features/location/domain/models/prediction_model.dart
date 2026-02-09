import 'package:sixam_mart/common/utils/json_parser.dart';

class PredictionModel {
  String? description;
  String? id;
  int? distanceMeters;
  String? placeId;
  String? reference;

  PredictionModel({
    this.description,
    this.id,
    this.distanceMeters,
    this.placeId,
    this.reference,
  });

  PredictionModel.fromJson(Map<String, dynamic> json) {
    description = json['description']?.toString();
    id = json['id']?.toString();
    distanceMeters = json.parseInt('distance_meters');
    placeId = json['place_id']?.toString();
    reference = json['reference']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    data['id'] = id;
    data['distance_meters'] = distanceMeters;
    data['place_id'] = placeId;
    data['reference'] = reference;
    return data;
  }
}
