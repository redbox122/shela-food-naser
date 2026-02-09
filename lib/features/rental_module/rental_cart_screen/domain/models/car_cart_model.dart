import 'package:sixam_mart/common/utils/json_parser.dart';

class CarCartModel {
  List<Carts>? carts;

  CarCartModel({this.carts});

  CarCartModel.fromJson(Map<String, dynamic> json) {
    if (json['carts'] != null) {
      carts = <Carts>[];
      json['carts'].forEach((v) {
        carts!.add(Carts.fromJson(v as Map<String, dynamic>));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (carts != null) {
      data['carts'] = carts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Carts {
  int? id;
  int? providerId;
  int? userId;
  int? vehicleId;
  int? moduleId;
  int? quantity;
  int? isGuest;
  String? createdAt;
  String? updatedAt;
  Provider? provider;

  Carts(
      {this.id,
        this.providerId,
        this.userId,
        this.vehicleId,
        this.moduleId,
        this.quantity,
        this.isGuest,
        this.createdAt,
        this.updatedAt,
        this.provider});

  Carts.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    providerId = json.parseInt('provider_id');
    userId = json.parseInt('user_id');
    vehicleId = json.parseInt('vehicle_id');
    moduleId = json.parseInt('module_id');
    quantity = json.parseInt('quantity');
    isGuest = json.parseInt('is_guest');
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    provider = json['provider'] != null
        ? Provider.fromJson(json['provider'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['provider_id'] = providerId;
    data['user_id'] = userId;
    data['vehicle_id'] = vehicleId;
    data['module_id'] = moduleId;
    data['quantity'] = quantity;
    data['is_guest'] = isGuest;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (provider != null) {
      data['provider'] = provider!.toJson();
    }
    return data;
  }
}

// class Vehicles {
//   int? id;
//   String? name;
//   String? description;
//   String? thumbnail;
//   String? images;
//   int? providerId;
//   int? brandId;
//   int? categoryId;
//   String? model;
//   String? type;
//   String? engineCapacity;
//   String? enginePower;
//   String? seatingCapacity;
//   int? airCondition;
//   String? fuelType;
//   String? transmissionType;
//   int? multipleVehicles;
//   int? tripHourly;
//   int? tripDistance;
//   int? hourlyPrice;
//   int? distancePrice;
//   String? discountType;
//   int? discountPrice;
//   String? tag;
//   String? documents;
//   int? status;
//   int? newTag;
//   int? totalTrip;
//   String? avgRating;
//   int? totalReviews;
//   String? createdAt;
//   String? updatedAt;
//   int? zoneId;
//   String? thumbnailFullUrl;
//   List<String>? imagesFullUrl;
//   List<String>? documentsFullUrl;
//
//   Vehicles(
//       {this.id,
//         this.name,
//         this.description,
//         this.thumbnail,
//         this.images,
//         this.providerId,
//         this.brandId,
//         this.categoryId,
//         this.model,
//         this.type,
//         this.engineCapacity,
//         this.enginePower,
//         this.seatingCapacity,
//         this.airCondition,
//         this.fuelType,
//         this.transmissionType,
//         this.multipleVehicles,
//         this.tripHourly,
//         this.tripDistance,
//         this.hourlyPrice,
//         this.distancePrice,
//         this.discountType,
//         this.discountPrice,
//         this.tag,
//         this.documents,
//         this.status,
//         this.newTag,
//         this.totalTrip,
//         this.avgRating,
//         this.totalReviews,
//         this.createdAt,
//         this.updatedAt,
//         this.zoneId,
//         this.thumbnailFullUrl,
//         this.imagesFullUrl,
//         this.documentsFullUrl,
//       });
//
//   Vehicles.fromJson(Map<String, dynamic> json) {
//     id = json['id']?.toString();
//     name = json['name']?.toString();
//     description = json['description']?.toString();
//     thumbnail = json['thumbnail']?.toString();
//     images = json['images']?.toString();
//     providerId = json['provider_id']?.toString();
//     brandId = json['brand_id']?.toString();
//     categoryId = json['category_id']?.toString();
//     model = json['model']?.toString();
//     type = json['type']?.toString();
//     engineCapacity = json['engine_capacity']?.toString();
//     enginePower = json['engine_power']?.toString();
//     seatingCapacity = json['seating_capacity']?.toString();
//     airCondition = json['air_condition']?.toString();
//     fuelType = json['fuel_type']?.toString();
//     transmissionType = json['transmission_type']?.toString();
//     multipleVehicles = json['multiple_vehicles']?.toString();
//     tripHourly = json['trip_hourly']?.toString();
//     tripDistance = json['trip_distance']?.toString();
//     hourlyPrice = json['hourly_price']?.toString();
//     distancePrice = json['distance_price']?.toString();
//     discountType = json['discount_type']?.toString();
//     discountPrice = json['discount_price']?.toString();
//     tag = json['tag']?.toString();
//     documents = json['documents']?.toString();
//     status = json['status']?.toString();
//     newTag = json['new_tag']?.toString();
//     totalTrip = json['total_trip']?.toString();
//     avgRating = json['avg_rating']?.toString();
//     totalReviews = json['total_reviews']?.toString();
//     createdAt = json['created_at']?.toString();
//     updatedAt = json['updated_at']?.toString();
//     zoneId = json['zone_id']?.toString();
//     thumbnailFullUrl = json['thumbnail_full_url']?.toString();
//     imagesFullUrl = json['images_full_url'].cast<String>();
//     documentsFullUrl = json['documents_full_url'].cast<String>();
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['description'] = this.description;
//     data['thumbnail'] = this.thumbnail;
//     data['images'] = this.images;
//     data['provider_id'] = this.providerId;
//     data['brand_id'] = this.brandId;
//     data['category_id'] = this.categoryId;
//     data['model'] = this.model;
//     data['type'] = this.type;
//     data['engine_capacity'] = this.engineCapacity;
//     data['engine_power'] = this.enginePower;
//     data['seating_capacity'] = this.seatingCapacity;
//     data['air_condition'] = this.airCondition;
//     data['fuel_type'] = this.fuelType;
//     data['transmission_type'] = this.transmissionType;
//     data['multiple_vehicles'] = this.multipleVehicles;
//     data['trip_hourly'] = this.tripHourly;
//     data['trip_distance'] = this.tripDistance;
//     data['hourly_price'] = this.hourlyPrice;
//     data['distance_price'] = this.distancePrice;
//     data['discount_type'] = this.discountType;
//     data['discount_price'] = this.discountPrice;
//     data['tag'] = this.tag;
//     data['documents'] = this.documents;
//     data['status'] = this.status;
//     data['new_tag'] = this.newTag;
//     data['total_trip'] = this.totalTrip;
//     data['avg_rating'] = this.avgRating;
//     data['total_reviews'] = this.totalReviews;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['zone_id'] = this.zoneId;
//     data['thumbnail_full_url'] = this.thumbnailFullUrl;
//     data['images_full_url'] = this.imagesFullUrl;
//     data['documents_full_url'] = this.documentsFullUrl;
//     return data;
//   }
// }

class Provider {
  int? id;
  String? name;
  double? tax;
  List<int>? pickupZoneId;
  bool? gstStatus;
  String? gstCode;
  String? logoFullUrl;
  String? coverPhotoFullUrl;
  String? metaImageFullUrl;
  Discount? discount;
  List<Translations>? translations;
  List<Storage>? storage;

  Provider({
    this.id,
    this.name,
    this.tax,
    this.pickupZoneId,
    this.gstStatus,
    this.gstCode,
    this.logoFullUrl,
    this.coverPhotoFullUrl,
    this.metaImageFullUrl,
    this.discount,
    this.translations,
    this.storage,
  });

  Provider.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json['name']?.toString();
    tax = json.parseDouble('tax');
    if(json['pickup_zone_id'] != null){
      json['pickup_zone_id'].forEach((zone) {
        pickupZoneId = [];
        pickupZoneId!.add(int.parse(zone.toString()));
      });
    }
    gstStatus = json.parseBool('gst_status');
    gstCode = json['gst_code']?.toString();
    logoFullUrl = json['logo_full_url']?.toString();
    coverPhotoFullUrl = json['cover_photo_full_url']?.toString();
    metaImageFullUrl = json['meta_image_full_url']?.toString();
    discount = json['discount'] != null
        ? Discount.fromJson(json['discount'] as Map<String, dynamic>)
        : null;
    if (json['translations'] != null) {
      translations = <Translations>[];
      for (var v in (json['translations'] as List)) {
        translations!.add(Translations.fromJson(v as Map<String, dynamic>));
      }
    }
    if (json['storage'] != null) {
      storage = <Storage>[];
      for (var v in (json['storage'] as List)) {
        storage!.add(Storage.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['tax'] = tax;
    data['gst_status'] = gstStatus;
    data['gst_code'] = gstCode;
    data['logo_full_url'] = logoFullUrl;
    data['cover_photo_full_url'] = coverPhotoFullUrl;
    data['meta_image_full_url'] = metaImageFullUrl;
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Discount {
  int? id;
  String? startDate;
  String? endDate;
  String? startTime;
  String? endTime;
  double? minPurchase;
  double? maxDiscount;
  double? discount;
  String? discountType;
  int? storeId;
  String? createdAt;
  String? updatedAt;

  Discount({
    this.id,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.minPurchase,
    this.maxDiscount,
    this.discount,
    this.discountType,
    this.storeId,
    this.createdAt,
    this.updatedAt,
  });

  Discount.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    startDate = json.parseString('start_date');
    endDate = json.parseString('end_date');
    startTime = json.parseString('start_time');
    endTime = json.parseString('end_time');
    minPurchase = json.parseDouble('min_purchase');
    maxDiscount = json.parseDouble('max_discount');
    discount = json.parseDouble('discount');
    discountType = json.parseString('discount_type');
    storeId = json.parseInt('store_id');
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['min_purchase'] = minPurchase;
    data['max_discount'] = maxDiscount;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Translations {
  int? id;
  String? translationableType;
  int? translationableId;
  String? locale;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Translations(
      {this.id,
        this.translationableType,
        this.translationableId,
        this.locale,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Translations.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    translationableType = json.parseString('translationable_type');
    translationableId = json.parseInt('translationable_id');
    locale = json['locale']?.toString();
    key = json['key']?.toString();
    value = json['value']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['translationable_type'] = translationableType;
    data['translationable_id'] = translationableId;
    data['locale'] = locale;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Storage {
  int? id;
  String? dataType;
  String? dataId;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Storage(
      {this.id,
        this.dataType,
        this.dataId,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Storage.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    dataType = json['data_type']?.toString();
    dataId = json['data_id']?.toString();
    key = json['key']?.toString();
    value = json['value']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['data_type'] = dataType;
    data['data_id'] = dataId;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}