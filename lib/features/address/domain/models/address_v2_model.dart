/// Address as returned by the v2 endpoints (`/api/v2/address/list` and
/// `/api/v2/address/details/{id}`).
///
/// The list response is a lightweight subset (no building details); the details
/// response includes everything. Missing fields simply stay null.
class AddressV2Model {
  final int? id;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? region;
  final String? streetName;
  final String? addressLabel;
  final String? buildingType;
  final String? buildingNumber;
  final String? floorNumber;
  final String? apartmentNumber;
  final String? additionalInfo;

  AddressV2Model({
    this.id,
    this.latitude,
    this.longitude,
    this.city,
    this.region,
    this.streetName,
    this.addressLabel,
    this.buildingType,
    this.buildingNumber,
    this.floorNumber,
    this.apartmentNumber,
    this.additionalInfo,
  });

  factory AddressV2Model.fromJson(Map<String, dynamic> json) {
    return AddressV2Model(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      streetName: json['street_name']?.toString(),
      addressLabel: json['address_label']?.toString(),
      buildingType: json['building_type']?.toString(),
      buildingNumber: json['building_number']?.toString(),
      floorNumber: json['floor_number']?.toString(),
      apartmentNumber: json['apartment_number']?.toString(),
      additionalInfo: json['additional_info']?.toString(),
    );
  }

  /// Compact one-line address for list rows.
  String get displayText => [city, region, streetName]
      .where((e) => e != null && e.isNotEmpty)
      .join('، ');
}
