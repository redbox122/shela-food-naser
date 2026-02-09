import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';

/// Model for handling list of zones with their coordinate data
/// Used for displaying zone polygons on maps
class ZoneListModel {
  final List<ZoneDataModel>? zones;

  ZoneListModel({this.zones});

  factory ZoneListModel.fromJson(Map<String, dynamic> json) {
    List<ZoneDataModel>? zonesList;

    if (json['zones'] != null) {
      zonesList = <ZoneDataModel>[];
      json['zones'].forEach((v) {
        zonesList!.add(ZoneDataModel.fromJson(v as Map<String, dynamic>));
      });
    }

    return ZoneListModel(zones: zonesList);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (zones != null) {
      data['zones'] = zones!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
