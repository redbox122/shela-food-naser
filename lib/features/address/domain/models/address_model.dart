import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';

class AddressModel {
  int? id;
  String? addressType;
  String? contactPersonNumber;
  String? address;
  String? deliveryAddress;
  String? additionalAddress;
  String? latitude;
  String? longitude;
  int? zoneId;
  List<int>? zoneIds;
  String? method;
  String? contactPersonName;
  String? streetNumber;
  String? house;
  String? floor;
  List<ZoneData>? zoneData;
  List<int>? areaIds;
  String? email;

  AddressModel({
    this.id,
    this.addressType,
    this.contactPersonNumber,
    this.address,
    this.deliveryAddress,
    this.additionalAddress,
    this.latitude,
    this.longitude,
    this.zoneId,
    this.zoneIds,
    this.method,
    this.contactPersonName,
    this.streetNumber,
    this.house,
    this.floor,
    this.zoneData,
    this.areaIds,
    this.email,
  });

  AddressModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;

    addressType = json['address_type']?.toString();
    contactPersonNumber = json['contact_person_number']?.toString();
    address = json['address']?.toString();
    deliveryAddress = json['delivery_address']?.toString();
    additionalAddress = json['additional_address']?.toString();

    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();

    zoneId = (json['zone_id'] != null && json['zone_id'].toString() != 'null')
        ? int.tryParse(json['zone_id'].toString())
        : null;

    zoneIds = json['zone_ids'] != null
        ? List<int>.from(json['zone_ids'] as List)
        : null;

    method = json['_method']?.toString();
    contactPersonName = json['contact_person_name']?.toString();
    streetNumber = json['road']?.toString() ??
        json['street_number']?.toString() ??
        json['street']?.toString() ??
        json['streetNumber']?.toString();
    house = json['house']?.toString() ??
        json['house_no']?.toString() ??
        json['house_number']?.toString();
    floor = json['floor']?.toString() ??
        json['floor_number']?.toString();

    if (json['zone_data'] != null && json['zone_data'] is List) {
      zoneData = (json['zone_data'] as List)
          .map((v) => ZoneData.fromJson(v as Map<String, dynamic>))
          .toList();
    }

areaIds = json['area_ids'] != null
    ? List<int>.from(json['area_ids'] as List)
    : null;

    email = json['contact_person_email']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['id'] = id;
    data['address_type'] = addressType;
    data['contact_person_number'] = contactPersonNumber;
    data['address'] = address;
    data['delivery_address'] = deliveryAddress;
    data['additional_address'] = additionalAddress;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['zone_id'] = zoneId;
    data['zone_ids'] = zoneIds;
    data['_method'] = method;
    data['contact_person_name'] = contactPersonName;
    data['road'] = streetNumber;
    data['house'] = house;
    data['floor'] = floor;

    if (zoneData != null) {
      data['zone_data'] = zoneData!.map((v) => v.toJson()).toList();
    }

    data['area_ids'] = areaIds;

    if (email != null) {
      data['contact_person_email'] = email;
    }

    return data;
  }
}
