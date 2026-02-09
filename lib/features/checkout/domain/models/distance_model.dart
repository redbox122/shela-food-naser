import 'package:sixam_mart/common/utils/json_parser.dart';

class DistanceModel {
  List<String>? destinationAddresses;
  List<String>? originAddresses;
  List<Rows>? rows;
  String? status;

  DistanceModel({
    this.destinationAddresses,
    this.originAddresses,
    this.rows,
    this.status,
  });

  DistanceModel.fromJson(Map<String, dynamic> json) {
    destinationAddresses = json.parseList<String>('destination_addresses', (v) => JsonParser.parseStringOrEmpty(v));
    originAddresses = json.parseList<String>('origin_addresses', (v) => JsonParser.parseStringOrEmpty(v));
    rows = json.parseList<Rows>('rows', (v) => Rows.fromJson(v as Map<String, dynamic>));
    status = json.parseString('status');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['destination_addresses'] = destinationAddresses;
    data['origin_addresses'] = originAddresses;
    if (rows != null) {
      data['rows'] = rows!.map((v) => v.toJson()).toList();
    }
    data['status'] = status;
    return data;
  }
}

class Rows {
  List<Elements>? elements;

  Rows({this.elements});

  Rows.fromJson(Map<String, dynamic> json) {
    elements = json.parseList<Elements>('elements', (v) => Elements.fromJson(v as Map<String, dynamic>));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (elements != null) {
      data['elements'] = elements!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Elements {
  Distance? distance;
  Distance? duration;
  String? status;

  Elements({this.distance, this.duration, this.status});

  Elements.fromJson(Map<String, dynamic> json) {
    final distanceMap = json.parseMap('distance');
    distance = distanceMap != null ? Distance.fromJson(distanceMap) : null;
    final durationMap = json.parseMap('duration');
    duration = durationMap != null ? Distance.fromJson(durationMap) : null;
    status = json.parseString('status');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (distance != null) {
      data['distance'] = distance!.toJson();
    }
    if (duration != null) {
      data['duration'] = duration!.toJson();
    }
    data['status'] = status;
    return data;
  }
}

class Distance {
  String? text;
  double? value;

  Distance({this.text, this.value});

  Distance.fromJson(Map<String, dynamic> json) {
    text = json.parseString('text');
    value = json.parseDouble('value') ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    data['value'] = value;
    return data;
  }
}
