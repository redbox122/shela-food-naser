import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class OffersModel {
  final bool? success;
  final List<Datum> data;
  final String? message;

  OffersModel({
    required this.success,
    required this.data,
    required this.message,
  });

  factory OffersModel.fromJson(Map<String, dynamic> json) {
    // 🔧 FIX: Handle both List and Map (empty) data types from API
    // API sometimes returns: { "data": [] } (List) ✅
    // API sometimes returns: { "data": {} } (Map) ❌ → treat as empty
    List<Datum> offersData = [];
    
    final dataField = json['data'];
    if (dataField != null) {
      if (dataField is List) {
        // Normal case: data is a List
        offersData = dataField
            .map((x) => Datum.fromJson(x as Map<String, dynamic>))
            .toList();
      } else if (dataField is Map) {
        // Edge case: data is an empty Map {} → treat as empty list
        offersData = [];
      }
      // If dataField is null, offersData remains empty []
    }
    
    return OffersModel(
      success: json.parseBool('success') ? true : null,
      data: offersData,
      message: json.parseString('message'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((x) => x.toJson()).toList(),
      'message': message,
    };
  }
}

class Datum {
  Datum({
    this.id,
    this.reference,
    this.name,
    this.title,
    this.startDate,
    this.endDate,
    this.discountMax,
    this.banner,
    this.createdAt,
    this.updatedAt,
    this.itemsCount,
    this.active,
    this.status,
  });

  final int? id;
  final String? reference;
  final String? name;
  final String? title; // 🔧 FIX: Add title field mapped from name for widget compatibility
  final dynamic startDate;
  final dynamic endDate;
  final double? discountMax;
  final String? banner;
  final String? createdAt;
  final String? updatedAt;
  final int? itemsCount;
  final bool? active;
  final String? status;

  factory Datum.fromJson(Map<String, dynamic> json) {
    // ⚡ BFF API v2: Prioritize banner_full_url field (backend now provides full URLs)
    // The API now provides banner_full_url as the primary field with complete URLs
    // Also check for nested storage/data keys
    String? bannerUrl = json.parseString('banner_full_url') ?? 
                        json.parseString('banner') ?? 
                        json.parseString('image_full_url') ??
                        (json['storage'] != null && json['storage'] is Map 
                            ? (json['storage'] as Map)['banner']?.toString() 
                            : null) ??
                        (json['data'] != null && json['data'] is Map 
                            ? (json['data'] as Map)['banner']?.toString() 
                            : null);
    
    // If banner is not a full URL, construct it (backward compatibility)
    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      if (!bannerUrl.startsWith('http://') && !bannerUrl.startsWith('https://')) {
        // Relative path - construct full URL using AppConstants
        final cleanedBanner = bannerUrl.startsWith('/') ? bannerUrl.substring(1) : bannerUrl;
        bannerUrl = '${AppConstants.offersBannersStoragePath}/$cleanedBanner';
      }
    }
    
    // 🔧 FIX: Handle key mismatches - check for offer_title vs name, title vs name
    final offerName = json['name'] ?? 
                      json['title'] ?? 
                      json['offer_title'] ?? 
                      '';
    
    return Datum(
      id: json.parseInt('id'),
      reference: json.parseString('reference') ?? '',
      name: offerName is String ? offerName : (offerName?.toString() ?? ''),
      title: offerName is String ? offerName : (offerName?.toString() ?? ''), // 🔧 FIX: Map title from name for widget compatibility
      startDate: json['start_date'] ?? json['startDate'],
      endDate: json['end_date'] ?? json['endDate'],
      discountMax: json.parseDouble('discount_max') ?? 0.0,
      banner: bannerUrl ?? '',
      createdAt: json.parseString('created_at') ?? json.parseString('createdAt') ?? '',
      updatedAt: json.parseString('updated_at') ?? json.parseString('updatedAt') ?? '',
      itemsCount: json.parseInt('items_count') ?? 0,
      active: json.parseBool('active') ? true : null,
      status: json.parseString('status') ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'name': name,
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'discount_max': discountMax,
      'banner': banner,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'items_count': itemsCount,
      'active': active,
      'status': status,
    };
  }
}
