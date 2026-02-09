import 'dart:convert';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';

class ZoneModel {
  List<int>? zoneIds;
  List<ZoneData>? zoneData;

  ZoneModel({this.zoneIds, this.zoneData});

  ZoneModel.fromJson(Map<String, dynamic> json) {
    zoneIds = [];
    for (var v in (jsonDecode(json['zone_id'] as String) as List)) {
      zoneIds!.add(v as int);
    }
    if (json['zone_data'] != null) {
      zoneData = <ZoneData>[];
      for (var v in (json['zone_data'] as List)) {
        zoneData!.add(ZoneData.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['zone_id'] = zoneIds;
    if (zoneData != null) {
      data['zone_data'] = zoneData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
