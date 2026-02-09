import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';

/// Model for the `/api/v1/bootstrap` endpoint response
/// Consolidates all home screen data into a single response
class BootstrapModel {
  final BusinessSettingsModel? businessSettings;
  final BannerModel? banners;
  final BannerModel? promotionalBanners;
  final List<CategoryModel>? categories;
  final StoreModel? stores;
  final StoreModel? storesPopular;
  final StoreModel? storesLatest;
  final List<BrandModel>? brands;
  final OffersModel? offers;
  final dynamic flashSales;
  final List<dynamic>? itemsPopular;
  final List<dynamic>? itemsDiscounted;
  final BootstrapMeta? meta;

  BootstrapModel({
    this.businessSettings,
    this.banners,
    this.promotionalBanners,
    this.categories,
    this.stores,
    this.storesPopular,
    this.storesLatest,
    this.brands,
    this.offers,
    this.flashSales,
    this.itemsPopular,
    this.itemsDiscounted,
    this.meta,
  });

  factory BootstrapModel.fromJson(Map<String, dynamic> json) {
    // Handle case where json might be the data directly
    final data = json['data'] ?? json;

    // Ensure data is a Map, not a List
    if (data is! Map<String, dynamic>) {
      throw FormatException(
        'BootstrapModel.fromJson: Expected Map but got ${data.runtimeType}. '
        'JSON structure: ${json.keys}',
      );
    }

    return BootstrapModel(
      businessSettings:
          data['business_settings'] != null && data['business_settings'] is Map
              ? BusinessSettingsModel.fromJson(
                  data['business_settings'] as Map<String, dynamic>)
              : null,
      banners: data['banners'] != null && data['banners'] is Map
          ? BannerModel.fromJson(data['banners'] as Map<String, dynamic>)
          : null,
      promotionalBanners: data['promotional_banners'] != null &&
              data['promotional_banners'] is Map
          ? BannerModel.fromJson(
              data['promotional_banners'] as Map<String, dynamic>)
          : null,
      categories: data['categories'] != null && data['categories'] is List
          ? (data['categories'] as List)
              .map((category) =>
                  CategoryModel.fromJson(category as Map<String, dynamic>))
              .toList()
          : null,
      stores: data['stores'] != null && data['stores'] is Map
          ? StoreModel.fromJson(data['stores'] as Map<String, dynamic>)
          : null,
      storesPopular: data['stores_popular'] != null &&
              data['stores_popular'] is Map
          ? StoreModel.fromJson(data['stores_popular'] as Map<String, dynamic>)
          : null,
      storesLatest: data['stores_latest'] != null &&
              data['stores_latest'] is Map
          ? StoreModel.fromJson(data['stores_latest'] as Map<String, dynamic>)
          : null,
      brands: data['brands'] != null && data['brands'] is List
          ? (data['brands'] as List)
              .map(
                  (brand) => BrandModel.fromJson(brand as Map<String, dynamic>))
              .toList()
          : null,
      offers: data['offers'] != null
          ? OffersModel.fromJson(data['offers'] is List
              ? {'success': true, 'data': data['offers'], 'message': null}
              : data['offers'] is Map
                  ? data['offers'] as Map<String, dynamic>
                  : {
                      'success': false,
                      'data': <dynamic>[],
                      'message': 'Invalid offers format'
                    } as Map<String, dynamic>)
          : null,
      flashSales: data['flash_sales'],
      itemsPopular: data['items_popular'] != null
          ? (data['items_popular'] as List)
          : null,
      itemsDiscounted: data['items_discounted'] != null
          ? (data['items_discounted'] as List)
          : null,
      meta: json['meta'] != null && json['meta'] is Map
          ? BootstrapMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'business_settings': businessSettings?.toJson(),
        'banners': banners?.toJson(),
        'promotional_banners': promotionalBanners?.toJson(),
        'categories': categories?.map((c) => c.toJson()).toList(),
        'stores': stores?.toJson(),
        'stores_popular': storesPopular?.toJson(),
        'stores_latest': storesLatest?.toJson(),
        'brands': brands?.map((b) => b.toJson()).toList(),
        'offers': offers?.toJson(),
        'flash_sales': flashSales,
        'items_popular': itemsPopular,
        'items_discounted': itemsDiscounted,
      },
      'meta': meta?.toJson(),
    };
  }

  /// Check if critical sections are available
  bool hasCriticalSections() {
    return businessSettings != null ||
        banners != null ||
        (categories != null && categories!.isNotEmpty) ||
        (storesPopular != null &&
            storesPopular!.stores != null &&
            storesPopular!.stores!.isNotEmpty);
  }

  /// Check if secondary sections are available
  bool hasSecondarySections() {
    return stores != null ||
        (brands != null && brands!.isNotEmpty) ||
        (offers != null && offers!.data.isNotEmpty);
  }
}

/// Metadata about the bootstrap response
class BootstrapMeta {
  final bool? cacheHit;
  final int? responseTimeMs;
  final String? timestamp;
  final int? moduleId;
  final List<int>? zoneIds;

  BootstrapMeta({
    this.cacheHit,
    this.responseTimeMs,
    this.timestamp,
    this.moduleId,
    this.zoneIds,
  });

  factory BootstrapMeta.fromJson(Map<String, dynamic> json) {
    // Handle response_time_ms which can be double or int from backend
    int? responseTimeMs;
    if (json['response_time_ms'] != null) {
      if (json['response_time_ms'] is double) {
        responseTimeMs = (json['response_time_ms'] as double).toInt();
      } else if (json['response_time_ms'] is int) {
        responseTimeMs = json['response_time_ms'] as int;
      }
    }

    // Handle module_id which can be double or int from backend
    int? moduleId;
    if (json['module_id'] != null) {
      if (json['module_id'] is double) {
        moduleId = (json['module_id'] as double).toInt();
      } else if (json['module_id'] is int) {
        moduleId = json['module_id'] as int;
      }
    }

    return BootstrapMeta(
      cacheHit: json['cache_hit'] as bool?,
      responseTimeMs: responseTimeMs,
      timestamp: json['timestamp'] as String?,
      moduleId: moduleId,
      zoneIds: json['zone_ids'] != null
          ? (json['zone_ids'] as List).map((e) {
              if (e is double) return e.toInt();
              return e as int;
            }).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cache_hit': cacheHit,
      'response_time_ms': responseTimeMs,
      'timestamp': timestamp,
      'module_id': moduleId,
      'zone_ids': zoneIds,
    };
  }
}
