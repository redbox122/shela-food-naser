import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class ZoneDataModel {
  int? id;
  String? name;
  String? slug; // 🔥 Zone slug for filtering allowed zones (e.g., 'riyadh-west')
  Coordinates? coordinates;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? restaurantWiseTopic;
  String? customerWiseTopic;
  String? deliverymanWiseTopic;
  double? minimumShippingCharge;
  double? perKmShippingCharge;
  List<FormatedCoordinates>? formatedCoordinates;

  ZoneDataModel({
    this.id,
    this.name,
    this.slug,
    this.coordinates,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.restaurantWiseTopic,
    this.customerWiseTopic,
    this.deliverymanWiseTopic,
    this.minimumShippingCharge,
    this.perKmShippingCharge,
    this.formatedCoordinates,
  });

  ZoneDataModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json['name']?.toString();
    // 🔥 Zone slug: Use API slug if available, otherwise generate from name
    slug = json['slug']?.toString() ?? _generateSlugFromName(json['name']?.toString());
    coordinates = json['coordinates'] != null ? Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>) : null;
    status = json.parseInt('status');
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    restaurantWiseTopic = json['restaurant_wise_topic']?.toString();
    customerWiseTopic = json['customer_wise_topic']?.toString();
    deliverymanWiseTopic = json['deliveryman_wise_topic']?.toString();
    minimumShippingCharge = json.parseDouble('minimum_shipping_charge');
    perKmShippingCharge = json.parseDouble('per_km_shipping_charge');
    
    // 🔥 FLEXIBLE PARSING: Support formated_coordinates + formatted_coordinates + coordinates
    // Try legacy key first, then corrected key.
    final dynamic formattedCoordinatesRaw =
        json['formated_coordinates'] ?? json['formatted_coordinates'];
    if (formattedCoordinatesRaw != null) {
      formatedCoordinates = <FormatedCoordinates>[];
      final coordsList = formattedCoordinatesRaw;
      if (coordsList is List && coordsList.isNotEmpty) {
        for (var v in coordsList) {
          if (v is Map<String, dynamic>) {
            formatedCoordinates!.add(FormatedCoordinates.fromJson(v));
          }
        }
      }
    }
    // Fallback: Try coordinates if formated_coordinates is null/empty
    else if (json['coordinates'] != null && formatedCoordinates == null) {
      // Try to extract from coordinates structure if available
      final coords = json['coordinates'];
      if (coords is Map && coords['coordinates'] != null) {
        final coordsList = coords['coordinates'];
        if (coordsList is List && coordsList.isNotEmpty) {
          formatedCoordinates = <FormatedCoordinates>[];
          for (final dynamic v in coordsList) {
            if (v is List && v.length >= 2) {
              // Format: [[lng, lat], [lng, lat], ...]
              formatedCoordinates!.add(FormatedCoordinates(
                lat: double.tryParse(v[1].toString()),
                lng: double.tryParse(v[0].toString()),
              ));
            } else if (v is Map<String, dynamic>) {
              // Format: {lat: x, lng: y} or {latitude: x, longitude: y}
              formatedCoordinates!.add(FormatedCoordinates(
                lat: (v['lat'] ?? v['latitude']) != null 
                    ? double.tryParse((v['lat'] ?? v['latitude']).toString())
                    : null,
                lng: (v['lng'] ?? v['longitude']) != null
                    ? double.tryParse((v['lng'] ?? v['longitude']).toString())
                    : null,
              ));
            }
          }
        }
      }
    }
  }

  /// Generate slug from zone name (fallback if API doesn't provide slug)
  /// Example: "غرب الرياض" -> "riyadh-west"
  static String? _generateSlugFromName(String? name) {
    if (name == null || name.isEmpty) return null;
    
    // Simple slug generation: convert Arabic zone names to slugs
    // This is a fallback - backend should provide slug field
    final Map<String, String> nameToSlugMap = {
      'غرب الرياض': 'riyadh-west',
      'شرق الرياض': 'riyadh-east',
      'شمال الرياض': 'riyadh-north',
      'جنوب الرياض': 'riyadh-south',
      'وسط الرياض': 'riyadh-center',
    };
    
    return nameToSlugMap[name] ?? name.toLowerCase().replaceAll(' ', '-');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    if (coordinates != null) {
      data['coordinates'] = coordinates!.toJson();
    }
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['restaurant_wise_topic'] = restaurantWiseTopic;
    data['customer_wise_topic'] = customerWiseTopic;
    data['deliveryman_wise_topic'] = deliverymanWiseTopic;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    if (formatedCoordinates != null) {
      data['formated_coordinates'] = formatedCoordinates!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Coordinates {
  String? type;
  List<LatLng>? coordinates;

  Coordinates({this.type, this.coordinates});

  Coordinates.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    if (json['coordinates'] != null) {
      coordinates = <LatLng>[];
      json['coordinates'][0].forEach((v) {
        coordinates!.add(LatLng(double.parse(v[0].toString()), double.parse(v[1].toString())));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    if (coordinates != null) {
      data['coordinates'] = coordinates!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FormatedCoordinates {
  double? lat;
  double? lng;

  FormatedCoordinates({this.lat, this.lng});

  FormatedCoordinates.fromJson(Map<String, dynamic> json) {
    // 🔥 FLEXIBLE PARSING: Support both lat/lng and latitude/longitude
    lat = json.parseDouble('lat') ?? json.parseDouble('latitude');
    lng = json.parseDouble('lng') ?? json.parseDouble('longitude');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}
