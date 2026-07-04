import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class StoreModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<Store>? stores;

  StoreModel({this.totalSize, this.limit, this.offset, this.stores});

  StoreModel.fromJson(Map<String, dynamic> json) {
    // ⚡ BFF API v2: Handle both 'popular_stores' object and direct 'stores' array
    // New v2 structure: { popular_stores: { total_size: X, stores: [...] } }
    // Legacy v1 structure: { total_size: X, stores: [...] }
    final popularStoresMap = json.parseMap('popular_stores');
    if (popularStoresMap != null) {
      // v2 API structure: nested popular_stores object
      totalSize = popularStoresMap.parseInt('total_size');
      limit = popularStoresMap.parseStringOrEmpty('limit');
      offset = popularStoresMap.parseInt('offset');
      stores = popularStoresMap.parseList<Store>(
          'stores', (v) => Store.fromJson(v as Map<String, dynamic>));
    } else {
      // Legacy v1 structure: direct fields
      totalSize = json.parseInt('total_size');
      limit = json.parseStringOrEmpty('limit');
      offset = json.parseInt('offset');
      stores = json.parseList<Store>(
          'stores', (v) => Store.fromJson(v as Map<String, dynamic>));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (stores != null) {
      data['stores'] = stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? description;
  String? phone;
  String? email;
  String? logoFullUrl;
  String logoStatus = 'invalid';
  String? latitude;
  String? longitude;
  String? address;
  double? minimumOrder;
  String? currency;
  bool? freeDelivery;
  String? coverPhotoFullUrl;
  String coverPhotoStatus = 'invalid';
  bool? delivery;
  bool? takeAway;
  bool? scheduleOrder;
  double? avgRating;
  double? tax;
  int? ratingCount;
  int? featured;
  int? zoneId;
  int? selfDeliverySystem;
  bool? posSystem;
  double? minimumShippingCharge;
  double? maximumShippingCharge;
  double? perKmShippingCharge;
  double? firstKmFee;
  double? firstKmDistance;
  int? open;
  bool? isOpen;
  bool? isOpenNow;
  bool? active;
  String? deliveryTime;
  List<int>? categoryIds;
  List<CategoryModel>? categoryDetails;
  int? veg;
  int? nonVeg;
  int? moduleId;
  int? orderPlaceToScheduleInterval;
  Discount? discount;
  List<Schedules>? schedules;
  int? vendorId;
  bool? prescriptionOrder;
  bool? cutlery;
  String? slug;
  bool? announcementActive;
  String? announcementMessage;
  int? itemCount;
  List<Items>? items;
  bool? extraPackagingStatus;
  double? extraPackagingAmount;
  List<int>? ratings;
  int? reviewsCommentsCount;
  StoreSubscription? storeSubscription;
  String? storeBusinessModel;
  double? distance;
  String? storeOpeningTime;

  /// ⚡ BFF API v2: Version hash for cache invalidation
  /// MD5 hash of pricing fields (minimum_order, shipping charges, tax, etc.)
  /// When this changes, pricing data has changed and cache should be invalidated
  String? versionHash;
  String? wishlistedAt;

  /// When the user added this store to favourites (null if the API omits it).
  DateTime? get wishlistedAtDate {
    if (wishlistedAt != null && wishlistedAt!.isNotEmpty) {
      return DateTime.tryParse(wishlistedAt!)?.toLocal();
    }
    return null;
  }

  Store({
    this.id,
    this.name,
    this.description,
    this.phone,
    this.email,
    this.logoFullUrl,
    this.logoStatus = 'invalid',
    this.latitude,
    this.longitude,
    this.address,
    this.minimumOrder,
    this.currency,
    this.freeDelivery,
    this.coverPhotoFullUrl,
    this.coverPhotoStatus = 'invalid',
    this.delivery,
    this.takeAway,
    this.scheduleOrder,
    this.avgRating,
    this.tax,
    this.featured,
    this.zoneId,
    this.ratingCount,
    this.selfDeliverySystem,
    this.posSystem,
    this.minimumShippingCharge,
    this.maximumShippingCharge,
    this.perKmShippingCharge,
    this.firstKmFee,
    this.firstKmDistance,
    this.open,
    this.isOpen,
    this.isOpenNow,
    this.active,
    this.deliveryTime,
    this.categoryIds,
    this.categoryDetails,
    this.veg,
    this.nonVeg,
    this.moduleId,
    this.orderPlaceToScheduleInterval,
    this.discount,
    this.schedules,
    this.vendorId,
    this.prescriptionOrder,
    this.cutlery,
    this.slug,
    this.announcementActive,
    this.announcementMessage,
    this.itemCount,
    this.items,
    this.extraPackagingStatus,
    this.extraPackagingAmount,
    this.ratings,
    this.reviewsCommentsCount,
    this.storeSubscription,
    this.storeBusinessModel,
    this.distance,
    this.storeOpeningTime,
    this.versionHash,
  });

  Store.fromJson(Map<String, dynamic> json) {
    // ⚡ BFF API v2: Match Laravel BFF v2 response exactly
    // ⚡ TASK 1: TYPE-SAFE PARSING - Explicit type conversions
    id = json.parseInt('id');
    wishlistedAt = json.parseString('wishlisted_at') ??
        json.parseString('favorited_at') ??
        json.parseString('wishlist_created_at');
    name = json.parseString('name');
    description = json.parseString('description');
    phone = json.parseString('phone');
    email = json.parseString('email');
    // Prefer logo_full_url (complete URL from server) over logo (may be filename-only)
    logoFullUrl =
        json.parseString('logo_full_url') ?? json.parseString('logo') ?? '';
    logoStatus = json.parseString('logo_status') ??
        (logoFullUrl != null && logoFullUrl!.isNotEmpty ? 'ok' : 'invalid');

    // ⚡ FIX 4: Image URL hardening - if URL doesn't start with http, prepend baseUrl + storagePath
    if (logoFullUrl != null && logoFullUrl!.isNotEmpty) {
      if (!logoFullUrl!.startsWith('http://') &&
          !logoFullUrl!.startsWith('https://')) {
        // URL is just a filename - construct full URL
        final baseUrl = AppConstants.baseUrl;
        const storagePath = '/storage/app/public/';
        final cleanedImage = logoFullUrl!.startsWith('/')
            ? logoFullUrl!.substring(1)
            : logoFullUrl!;
        logoFullUrl = '$baseUrl$storagePath$cleanedImage';
      }
    }
    // ⚡ FIX: Safe parsing for latitude/longitude (can be String or double)
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    address = json['address']?.toString();
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    minimumOrder = json['minimum_order'] != null
        ? double.tryParse(json['minimum_order'].toString()) ?? 0.0
        : 0.0;
    currency = json['currency']?.toString();
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    freeDelivery = json['free_delivery'] != null
        ? (json['free_delivery'].toString() == '1' ||
            json['free_delivery'].toString() == 'true')
        : false;
    // Preserve backward compatibility: if cover_photo is null/empty, fallback to cover_photo_full_url.
    final String? coverPhoto = json.parseString('cover_photo');
    final String? coverPhotoFull = json.parseString('cover_photo_full_url');
    coverPhotoFullUrl =
        (coverPhoto != null && coverPhoto.isNotEmpty ? coverPhoto : null) ??
            (coverPhotoFull != null && coverPhotoFull.isNotEmpty
                ? coverPhotoFull
                : null) ??
            json.parseString('cover_photo_url') ??
            json.parseString('logo_full_url') ??
            json.parseString('logo') ??
            '';
    coverPhotoStatus = json.parseString('cover_photo_status') ??
        (coverPhotoFullUrl != null && coverPhotoFullUrl!.isNotEmpty
            ? 'ok'
            : 'invalid');

    // ⚡ FIX 4: Image URL hardening - if URL doesn't start with http, prepend baseUrl + storagePath
    if (coverPhotoFullUrl != null && coverPhotoFullUrl!.isNotEmpty) {
      if (!coverPhotoFullUrl!.startsWith('http://') &&
          !coverPhotoFullUrl!.startsWith('https://')) {
        // URL is just a filename - construct full URL
        final baseUrl = AppConstants.baseUrl;
        const storagePath = '/storage/app/public/';
        final cleanedImage = coverPhotoFullUrl!.startsWith('/')
            ? coverPhotoFullUrl!.substring(1)
            : coverPhotoFullUrl!;
        coverPhotoFullUrl = '$baseUrl$storagePath$cleanedImage';
      }
    }
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    delivery = json.parseBool('delivery');
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    takeAway = json.parseBool('take_away');
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    scheduleOrder = json.parseBool('schedule_order');
    // ⚡ BFF API v2: Match Laravel BFF v2 response exactly
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    avgRating = json.parseDouble('avg_rating') ?? 0.0;
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    tax = json.parseDouble('tax');
    // ⚡ BFF API v2: Handle rating_count as int
    ratingCount = json.parseInt('rating_count') ?? 0;
    selfDeliverySystem = json.parseInt('self_delivery_system');
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    posSystem = json.parseBool('pos_system');
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    minimumShippingCharge = json.parseDouble('minimum_shipping_charge');
    maximumShippingCharge = json['maximum_shipping_charge'] != null
        ? double.tryParse(json['maximum_shipping_charge'].toString()) ?? 0.0
        : null;
    perKmShippingCharge = json['per_km_shipping_charge'] != null
        ? double.tryParse(json['per_km_shipping_charge'].toString()) ?? 0.0
        : 0.0;
    firstKmFee = json['first_km_fee'] != null
        ? double.tryParse(json['first_km_fee'].toString())
        : null;
    firstKmDistance = json['first_km_distance'] != null
        ? double.tryParse(json['first_km_distance'].toString())
        : null;
    // Backend is the single source of truth for open/close status.
    // API now uses only `is_open` (boolean-like).
    final dynamic rawIsOpen = json['is_open'];
    if (rawIsOpen is bool) {
      isOpen = rawIsOpen;
    } else if (rawIsOpen is int) {
      isOpen = rawIsOpen == 1;
    } else if (rawIsOpen is String) {
      isOpen = rawIsOpen == '1' || rawIsOpen.toLowerCase() == 'true';
    } else {
      isOpen = null;
    }
    // Keep compatibility field in sync without reading removed API key.
    isOpenNow = isOpen;

    if (kDebugMode &&
        AppConstants.enableVerboseLogs &&
        json.containsKey('id') &&
        json.containsKey('is_open')) {
      debugPrint(
          '🏪 STORE DEBUG => id: ${json['id']}, isOpen: $isOpen, isOpenNow: $isOpenNow');
      debugPrint(
          '   raw json[is_open]: ${json['is_open']} (type: ${json['is_open'].runtimeType})');
    }
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    active = json['active'] != null
        ? (json['active'].toString() == '1' ||
            json['active'].toString() == 'true')
        : false;
    // ⚡ FIX: Handle null featured field safely
    featured = json['featured'] != null
        ? int.tryParse(json['featured'].toString()) ?? 0
        : 0;
    zoneId = json['zone_id'] != null
        ? int.tryParse(json['zone_id'].toString())
        : null;
    deliveryTime = json['delivery_time']?.toString();
    veg = json['veg'] != null ? int.tryParse(json['veg'].toString()) : null;
    nonVeg = json['non_veg'] != null
        ? int.tryParse(json['non_veg'].toString())
        : null;
    moduleId = json.parseInt('module_id') ??
        json.parseInt('moduleId') ??
        ((json['module'] is Map<String, dynamic>)
            ? (json['module'] as Map<String, dynamic>).parseInt('id')
            : null);
    orderPlaceToScheduleInterval =
        json['order_place_to_schedule_interval'] != null
            ? int.tryParse(json['order_place_to_schedule_interval'].toString())
            : null;
    categoryIds = json['category_ids'] != null
        ? (json['category_ids'] as List?)
                ?.map((e) => int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList()
                .cast<int>() ??
            []
        : [];
    if (json['category_details'] != null) {
      final categoryDetailsData = json['category_details'];
      // 🔧 FIX: Type-safe parsing - handle both List and Map responses
      if (categoryDetailsData is List) {
        categoryDetails = <CategoryModel>[];
        if (kDebugMode) {
          debugPrint(
              '📍 [Store.fromJson] Parsing category_details: ${categoryDetailsData.length} categories (List)');
          // Debug info removed to fix type errors with debugPrint
        }
        for (final dynamic v in categoryDetailsData) {
          if (v is Map<String, dynamic>) {
            try {
              final category = CategoryModel.fromJson(v);
              categoryDetails!.add(category);
              if (kDebugMode && categoryDetails!.length <= 3) {
                debugPrint(
                    '   ✅ Added category ${categoryDetails!.length}: id=${category.id}, name=${category.name}');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ [Store.fromJson] Error parsing category: $e');
              }
            }
          } else if (kDebugMode) {
            debugPrint(
                '⚠️ [Store.fromJson] Skipping invalid category_details item: ${v.runtimeType}');
          }
        }
        if (kDebugMode) {
          debugPrint(
              '   ✅ [Store.fromJson] Successfully parsed ${categoryDetails!.length} categories');
        }
      } else if (categoryDetailsData is Map<String, dynamic>) {
        // Handle Map case - convert to List
        categoryDetails = <CategoryModel>[];
        if (kDebugMode) {
          debugPrint(
              '📍 [Store.fromJson] Parsing category_details: Map format (${(categoryDetailsData as Map).length} entries)');
        }
        for (final dynamic v in (categoryDetailsData as Map).values) {
          if (v is Map<String, dynamic>) {
            categoryDetails!.add(CategoryModel.fromJson(v));
          } else if (kDebugMode) {
            debugPrint(
                '⚠️ [Store.fromJson] Skipping invalid category_details value: ${v.runtimeType}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [Store.fromJson] category_details is neither List nor Map: ${categoryDetailsData.runtimeType}');
        }
        categoryDetails = null;
      }
    }
    discount =
        json['discount'] != null && json['discount'] is Map<String, dynamic>
            ? Discount.fromJson(json['discount'] as Map<String, dynamic>)
            : null;
    if (json['schedules'] != null) {
      final schedulesData = json['schedules'];
      // 🔧 FIX: Type-safe parsing - handle both List and Map responses
      if (schedulesData is List) {
        schedules = <Schedules>[];
        for (final dynamic v in schedulesData) {
          if (v is Map<String, dynamic>) {
            schedules!.add(Schedules.fromJson(v));
          } else if (kDebugMode) {
            debugPrint(
                '⚠️ [Store.fromJson] Skipping invalid schedules item: ${v.runtimeType}');
          }
        }
      } else if (schedulesData is Map<String, dynamic>) {
        schedules = <Schedules>[];
        for (final dynamic v in (schedulesData as Map).values) {
          if (v is Map<String, dynamic>) {
            schedules!.add(Schedules.fromJson(v));
          } else if (kDebugMode) {
            debugPrint(
                '⚠️ [Store.fromJson] Skipping invalid schedules value: ${v.runtimeType}');
          }
        }
      } else if (kDebugMode) {
        debugPrint(
            '⚠️ [Store.fromJson] schedules is neither List nor Map: ${schedulesData.runtimeType}');
      }
    }
    vendorId = json['vendor_id'] != null
        ? int.tryParse(json['vendor_id'].toString())
        : null;
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    prescriptionOrder = json['prescription_order'] != null
        ? (json['prescription_order'].toString() == '1' ||
            json['prescription_order'].toString() == 'true')
        : false;
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    cutlery = json['cutlery'] != null
        ? (json['cutlery'].toString() == '1' ||
            json['cutlery'].toString() == 'true')
        : false;
    slug = json['slug']?.toString();
    announcementActive = json['announcement'] != null
        ? (json['announcement'].toString() == '1' || json['announcement'] == 1)
        : false;
    announcementMessage = json['announcement_message']?.toString();
    itemCount = json['total_items'] != null
        ? int.tryParse(json['total_items'].toString())
        : null;
    if (json['items'] != null) {
      final itemsData = json['items'];
      // 🔧 FIX: Type-safe parsing - handle both List and Map responses
      if (itemsData is List) {
        items = <Items>[];
        for (final dynamic v in itemsData) {
          if (v is Map<String, dynamic>) {
            items!.add(Items.fromJson(v));
          } else if (kDebugMode) {
            debugPrint(
                '⚠️ [Store.fromJson] Skipping invalid items item: ${v.runtimeType}');
          }
        }
      } else if (itemsData is Map<String, dynamic>) {
        items = <Items>[];
        for (final dynamic v in (itemsData as Map).values) {
          if (v is Map<String, dynamic>) {
            items!.add(Items.fromJson(v));
          } else if (kDebugMode) {
            debugPrint(
                '⚠️ [Store.fromJson] Skipping invalid items value: ${v.runtimeType}');
          }
        }
      } else if (kDebugMode) {
        debugPrint(
            '⚠️ [Store.fromJson] items is neither List nor Map: ${itemsData.runtimeType}');
      }
    }
    // ⚡ FIX: Universal boolean parser - handles int, string, and bool types
    extraPackagingStatus = json['extra_packaging_status'] != null
        ? (json['extra_packaging_status'].toString() == '1' ||
            json['extra_packaging_status'].toString() == 'true')
        : false;
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    extraPackagingAmount = json['extra_packaging_amount'] != null
        ? double.tryParse(json['extra_packaging_amount'].toString()) ?? 0.0
        : 0.0;
    if (json['ratings'] != null && json['ratings'] != 0) {
      final ratingsData = json['ratings'];
      // 🔧 FIX: Type-safe parsing - handle both List and Map responses
      if (ratingsData is List) {
        ratings = <int>[];
        for (final dynamic v in ratingsData) {
          final ratingValue = v is int ? v : int.tryParse(v.toString());
          if (ratingValue != null) {
            ratings!.add(ratingValue);
          }
        }
      } else if (ratingsData is Map<String, dynamic>) {
        ratings = <int>[];
        for (final dynamic v in (ratingsData as Map).values) {
          final ratingValue = v is int ? v : int.tryParse(v.toString());
          if (ratingValue != null) {
            ratings!.add(ratingValue);
          }
        }
      } else if (kDebugMode) {
        debugPrint(
            '⚠️ [Store.fromJson] ratings is neither List nor Map: ${ratingsData.runtimeType}');
      }
    }
    reviewsCommentsCount = json['reviews_comments_count'] != null
        ? int.tryParse(json['reviews_comments_count'].toString()) ?? 0
        : 0;
    storeSubscription = json['store_sub'] != null &&
            json['store_sub'] is Map<String, dynamic>
        ? StoreSubscription.fromJson(json['store_sub'] as Map<String, dynamic>)
        : null;
    storeBusinessModel = json['store_business_model']?.toString();
    // Handle both 'distance' and 'distance_in_meters' (meters).
    // Guard unrealistic values (>10,000 km) to keep sorting/UI stable.
    final distanceJson = json['distance'] ?? json['distance_in_meters'];
    if (distanceJson != null) {
      final distanceValue = double.tryParse(distanceJson.toString());
      if (distanceValue == null) {
        distance = 0;
      } else if (distanceValue < 0 || distanceValue > 10000000) {
        distance = 0;
      } else {
        distance = distanceValue;
      }
    } else {
      distance = 0;
    }
    storeOpeningTime =
        (json['current_opening_time'] ?? json['store_opening_time'])
            ?.toString();
    // ⚡ BFF API v2: Parse version_hash for cache invalidation
    versionHash = json['version_hash']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = email;
    // Cache both new and fallback keys to support readers during migration.
    data['logo'] = logoFullUrl?.isNotEmpty == true ? logoFullUrl : null;
    data['logo_full_url'] =
        logoFullUrl?.isNotEmpty == true ? logoFullUrl : null;
    data['logo_status'] = logoStatus;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['address'] = address;
    data['minimum_order'] = minimumOrder;
    data['currency'] = currency;
    data['free_delivery'] = freeDelivery;
    data['cover_photo'] =
        coverPhotoFullUrl?.isNotEmpty == true ? coverPhotoFullUrl : null;
    data['cover_photo_full_url'] =
        coverPhotoFullUrl?.isNotEmpty == true ? coverPhotoFullUrl : null;
    data['cover_photo_status'] = coverPhotoStatus;
    data['delivery'] = delivery;
    data['take_away'] = takeAway;
    data['schedule_order'] = scheduleOrder;
    data['avg_rating'] = avgRating;
    data['tax'] = tax;
    data['rating_count'] = ratingCount;
    data['self_delivery_system'] = selfDeliverySystem;
    data['pos_system'] = posSystem;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['maximum_shipping_charge'] = maximumShippingCharge;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    data['first_km_fee'] = firstKmFee;
    data['first_km_distance'] = firstKmDistance;
    data['is_open'] = isOpen;
    data['is_open_now'] = isOpen;
    data['active'] = active;
    data['veg'] = veg;
    data['featured'] = featured;
    data['zone_id'] = zoneId;
    data['non_veg'] = nonVeg;
    data['module_id'] = moduleId;
    data['moduleId'] = moduleId;
    data['order_place_to_schedule_interval'] = orderPlaceToScheduleInterval;
    data['delivery_time'] = deliveryTime;
    data['category_ids'] = categoryIds;
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (schedules != null) {
      data['schedules'] = schedules!.map((v) => v.toJson()).toList();
    }
    data['vendor_id'] = vendorId;
    data['prescription_order'] = prescriptionOrder;
    data['cutlery'] = cutlery;
    data['slug'] = slug;
    data['announcement'] = announcementActive;
    data['announcement_message'] = announcementMessage;
    data['total_items'] = itemCount;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    data['extra_packaging_status'] = extraPackagingStatus;
    data['extra_packaging_amount'] = extraPackagingAmount;
    data['ratings'] = ratings;
    data['reviews_comments_count'] = reviewsCommentsCount;
    if (storeSubscription != null) {
      data['store_sub'] = storeSubscription!.toJson();
    }
    data['store_business_model'] = storeBusinessModel;
    data['distance'] = distance;
    data['version_hash'] = versionHash;
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
    // ⚡ TASK 1: TYPE-SAFE PARSING - Explicit conversions
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    // ⚡ TASK 2: PREVENT NULL CRASHES - Safe substring with null check
    final startTimeStr = json['start_time']?.toString();
    startTime = startTimeStr != null && startTimeStr.length >= 5
        ? startTimeStr.substring(0, 5)
        : startTimeStr;
    final endTimeStr = json['end_time']?.toString();
    endTime = endTimeStr != null && endTimeStr.length >= 5
        ? endTimeStr.substring(0, 5)
        : endTimeStr;
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    minPurchase = json['min_purchase'] != null
        ? double.tryParse(json['min_purchase'].toString())
        : null;
    maxDiscount = json['max_discount'] != null
        ? double.tryParse(json['max_discount'].toString())
        : null;
    discount = json['discount'] != null
        ? double.tryParse(json['discount'].toString())
        : null;
    discountType = json['discount_type']?.toString();
    storeId = json['store_id'] != null
        ? int.tryParse(json['store_id'].toString())
        : null;
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

class Schedules {
  int? id;
  int? storeId;
  int? day;
  String? openingTime;
  String? closingTime;

  Schedules({
    this.id,
    this.storeId,
    this.day,
    this.openingTime,
    this.closingTime,
  });

  Schedules.fromJson(Map<String, dynamic> json) {
    // ⚡ TASK 1: TYPE-SAFE PARSING - Explicit conversions
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    storeId = json['store_id'] != null
        ? int.tryParse(json['store_id'].toString())
        : null;
    day = json['day'] != null ? int.tryParse(json['day'].toString()) : null;
    // ⚡ TASK 2: PREVENT NULL CRASHES - Safe substring with null check
    final openingTimeStr = json['opening_time']?.toString();
    openingTime = openingTimeStr != null && openingTimeStr.length >= 5
        ? openingTimeStr.substring(0, 5)
        : openingTimeStr;
    final closingTimeStr = json['closing_time']?.toString();
    closingTime = closingTimeStr != null && closingTimeStr.length >= 5
        ? closingTimeStr.substring(0, 5)
        : closingTimeStr;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['day'] = day;
    data['opening_time'] = openingTime;
    data['closing_time'] = closingTime;
    return data;
  }
}

class Refund {
  int? id;
  int? orderId;
  List<String>? imageFullUrl;
  String? customerReason;
  String? customerNote;
  String? adminNote;

  Refund({
    this.id,
    this.orderId,
    this.imageFullUrl,
    this.customerReason,
    this.customerNote,
    this.adminNote,
  });

  Refund.fromJson(Map<String, dynamic> json) {
    // ⚡ TASK 1: TYPE-SAFE PARSING - Explicit conversions
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    orderId = json['order_id'] != null
        ? int.tryParse(json['order_id'].toString())
        : null;
    // ⚡ TASK 2: PREVENT NULL CRASHES - Safe list parsing
    if (json['image_full_url'] != null && json['image_full_url'] is List) {
      imageFullUrl = <String>[];
      for (final v in json['image_full_url'] as List) {
        final str = v?.toString();
        if (str != null && str.isNotEmpty) {
          imageFullUrl!.add(str);
        }
      }
    }
    customerReason = json['customer_reason']?.toString();
    customerNote = json['customer_note']?.toString();
    adminNote = json['admin_note']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['image_full_url'] = imageFullUrl;
    data['customer_reason'] = customerReason;
    data['customer_note'] = customerNote;
    data['admin_note'] = adminNote;
    return data;
  }
}

class Items {
  int? id;
  String? name;
  String? description;
  String? imageFullUrl;
  int? categoryId;
  String? categoryIds;
  String? variations;
  String? addOns;
  String? attributes;
  String? choiceOptions;
  double? price;
  double? tax;
  String? taxType;
  double? discount;
  String? discountType;
  String? availableTimeStarts;
  String? availableTimeEnds;
  int? veg;
  int? status;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  int? orderCount;
  double? avgRating;
  int? ratingCount;
  String? rating;
  int? moduleId;
  int? stock;
  int? unitId;
  List<String>? images;
  String? foodVariations;
  String? slug;
  int? recommended;
  int? organic;
  int? maximumCartQuantity;
  int? isApproved;
  String? unitType;

  Items({
    this.id,
    this.name,
    this.description,
    this.imageFullUrl,
    this.categoryId,
    this.categoryIds,
    this.variations,
    this.addOns,
    this.attributes,
    this.choiceOptions,
    this.price,
    this.tax,
    this.taxType,
    this.discount,
    this.discountType,
    this.availableTimeStarts,
    this.availableTimeEnds,
    this.veg,
    this.status,
    this.storeId,
    this.createdAt,
    this.updatedAt,
    this.orderCount,
    this.avgRating,
    this.ratingCount,
    this.rating,
    this.moduleId,
    this.stock,
    this.unitId,
    this.images,
    this.foodVariations,
    this.slug,
    this.recommended,
    this.organic,
    this.maximumCartQuantity,
    this.isApproved,
    this.unitType,
  });

  Items.fromJson(Map<String, dynamic> json) {
    // ⚡ TASK 1: TYPE-SAFE PARSING - Explicit conversions
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name']?.toString();
    description = json['description']?.toString();
    imageFullUrl = json['image_full_url']?.toString();
    categoryId = json['category_id'] != null
        ? int.tryParse(json['category_id'].toString())
        : null;
    categoryIds = json['category_ids']?.toString();
    variations = json['variations']?.toString();
    addOns = json['add_ons']?.toString();
    attributes = json['attributes']?.toString();
    choiceOptions = json['choice_options']?.toString();
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    price = json['price'] != null
        ? double.tryParse(json['price'].toString())
        : null;
    tax = json['tax'] != null ? double.tryParse(json['tax'].toString()) : null;
    taxType = json['tax_type']?.toString();
    discount = json['discount'] != null
        ? double.tryParse(json['discount'].toString())
        : null;
    discountType = json['discount_type']?.toString();
    availableTimeStarts = json['available_time_starts']?.toString();
    availableTimeEnds = json['available_time_ends']?.toString();
    veg = json['veg'] != null ? int.tryParse(json['veg'].toString()) : null;
    status =
        json['status'] != null ? int.tryParse(json['status'].toString()) : null;
    storeId = json['store_id'] != null
        ? int.tryParse(json['store_id'].toString())
        : null;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    orderCount = json['order_count'] != null
        ? int.tryParse(json['order_count'].toString())
        : null;
    // ⚡ FIX: Safe double parsing - handle both String and Number types
    avgRating = json['avg_rating'] != null
        ? double.tryParse(json['avg_rating'].toString())
        : null;
    ratingCount = json['rating_count'] != null
        ? int.tryParse(json['rating_count'].toString())
        : null;
    rating = json['rating']?.toString();
    moduleId = json.parseInt('module_id') ?? json.parseInt('moduleId');
    stock =
        json['stock'] != null ? int.tryParse(json['stock'].toString()) : null;
    unitId = json['unit_id'] != null
        ? int.tryParse(json['unit_id'].toString())
        : null;
    // ⚡ TASK 2: PREVENT NULL CRASHES - Safe list casting
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList()
          .cast<String>();
    }
    foodVariations = json['food_variations']?.toString();
    slug = json['slug']?.toString();
    recommended = json['recommended'] != null
        ? int.tryParse(json['recommended'].toString())
        : null;
    organic = json['organic'] != null
        ? int.tryParse(json['organic'].toString())
        : null;
    maximumCartQuantity = json['maximum_cart_quantity'] != null
        ? int.tryParse(json['maximum_cart_quantity'].toString())
        : null;
    isApproved = json['is_approved'] != null
        ? int.tryParse(json['is_approved'].toString())
        : null;
    unitType = json['unit_type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['image_full_url'] = imageFullUrl;
    data['category_id'] = categoryId;
    data['category_ids'] = categoryIds;
    data['variations'] = variations;
    data['add_ons'] = addOns;
    data['attributes'] = attributes;
    data['choice_options'] = choiceOptions;
    data['price'] = price;
    data['tax'] = tax;
    data['tax_type'] = taxType;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['available_time_starts'] = availableTimeStarts;
    data['available_time_ends'] = availableTimeEnds;
    data['veg'] = veg;
    data['status'] = status;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['order_count'] = orderCount;
    data['avg_rating'] = avgRating;
    data['rating_count'] = ratingCount;
    data['rating'] = rating;
    data['module_id'] = moduleId;
    data['moduleId'] = moduleId;
    data['stock'] = stock;
    data['unit_id'] = unitId;
    data['images'] = images;
    data['food_variations'] = foodVariations;
    data['slug'] = slug;
    data['recommended'] = recommended;
    data['organic'] = organic;
    data['maximum_cart_quantity'] = maximumCartQuantity;
    data['is_approved'] = isApproved;
    data['unit_type'] = unitType;
    return data;
  }
}

class StoreSubscription {
  int? id;
  int? packageId;
  int? storeId;
  String? expiryDate;
  String? maxOrder;
  String? maxProduct;
  int? pos;
  int? mobileApp;
  int? chat;
  int? review;
  int? selfDelivery;
  int? status;
  int? totalPackageRenewed;
  String? createdAt;
  String? updatedAt;

  StoreSubscription({
    this.id,
    this.packageId,
    this.storeId,
    this.expiryDate,
    this.maxOrder,
    this.maxProduct,
    this.pos,
    this.mobileApp,
    this.chat,
    this.review,
    this.selfDelivery,
    this.status,
    this.totalPackageRenewed,
    this.createdAt,
    this.updatedAt,
  });

  StoreSubscription.fromJson(Map<String, dynamic> json) {
    // ⚡ TASK 1: TYPE-SAFE PARSING - Explicit conversions
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    packageId = json['package_id'] != null
        ? int.tryParse(json['package_id'].toString())
        : null;
    storeId = json['store_id'] != null
        ? int.tryParse(json['store_id'].toString())
        : null;
    expiryDate = json['expiry_date']?.toString();
    maxOrder = json['max_order']?.toString();
    maxProduct = json['max_product']?.toString();
    pos = json['pos'] != null ? int.tryParse(json['pos'].toString()) : null;
    mobileApp = json['mobile_app'] != null
        ? int.tryParse(json['mobile_app'].toString())
        : null;
    // ⚡ TASK 2: PREVENT NULL CRASHES - Safe null handling
    chat = (json['chat'] != null && json['chat'].toString() != 'null')
        ? int.tryParse(json['chat'].toString()) ?? 0
        : 0;
    review = json['review'] != null
        ? int.tryParse(json['review'].toString()) ?? 0
        : 0;
    selfDelivery = json['self_delivery'] != null
        ? int.tryParse(json['self_delivery'].toString())
        : null;
    status =
        json['status'] != null ? int.tryParse(json['status'].toString()) : null;
    totalPackageRenewed = json['total_package_renewed'] != null
        ? int.tryParse(json['total_package_renewed'].toString())
        : null;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['package_id'] = packageId;
    data['store_id'] = storeId;
    data['expiry_date'] = expiryDate;
    data['max_order'] = maxOrder;
    data['max_product'] = maxProduct;
    data['pos'] = pos;
    data['mobile_app'] = mobileApp;
    data['chat'] = chat;
    data['review'] = review;
    data['self_delivery'] = selfDelivery;
    data['status'] = status;
    data['total_package_renewed'] = totalPackageRenewed;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
