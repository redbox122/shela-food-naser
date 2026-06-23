/// Response of `POST /api/v2/address/check-zone`.
///
/// One call both validates the map point (delivery coverage) and returns the
/// parsed address parts used to pre-fill the address-details form.
class CheckZoneModel {
  final bool success;
  final bool inZone;
  final int? zoneId;
  final String? zoneName;
  final String? message;
  final CheckZoneAddress? address;

  CheckZoneModel({
    required this.success,
    required this.inZone,
    this.zoneId,
    this.zoneName,
    this.message,
    this.address,
  });

  factory CheckZoneModel.fromJson(Map<String, dynamic> json) {
    return CheckZoneModel(
      success: json['success'] == true,
      inZone: json['in_zone'] == true,
      zoneId: json['zone_id'] != null
          ? int.tryParse(json['zone_id'].toString())
          : null,
      zoneName: json['zone_name']?.toString(),
      message: json['message']?.toString(),
      address: json['address'] is Map<String, dynamic>
          ? CheckZoneAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CheckZoneAddress {
  final String? formattedAddress;
  final String? city;
  final String? region;
  final String? streetName;
  final String? country;

  CheckZoneAddress({
    this.formattedAddress,
    this.city,
    this.region,
    this.streetName,
    this.country,
  });

  factory CheckZoneAddress.fromJson(Map<String, dynamic> json) {
    return CheckZoneAddress(
      formattedAddress: json['formatted_address']?.toString(),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      streetName: json['street_name']?.toString(),
      country: json['country']?.toString(),
    );
  }

  /// Compact text for the map chip / address row when there is no formatted one.
  String get displayText {
    final parts = [city, region, streetName].where((e) => e != null && e.isNotEmpty);
    return formattedAddress?.isNotEmpty == true
        ? formattedAddress!
        : parts.join('، ');
  }
}
