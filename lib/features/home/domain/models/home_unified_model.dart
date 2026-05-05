import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart'
    show OffersModel, Datum;
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';
import 'package:sixam_mart/features/banner/domain/models/promotional_banner_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

/// Home Unified Response Model
///
/// ⚡ BFF API v2: Single endpoint that returns ALL home screen data
/// Endpoint: GET /api/v2/home-unified
///
/// This eliminates 5+ API calls and reduces payload size by 70%
class HomeUnifiedModel {
  final List<Banner>? banners;
  final List<BasicCampaignModel>? campaigns;
  final List<CategoryModel>? categories;
  final List<Store>? popularStores;
  final List<BrandModel>? brands;
  final List<OffersModel>? offers;
  final Map<String, dynamic>?
      customer; // ⚡ BFF API v2: Customer data for ProfileController
  final BusinessSettingsModel?
      businessSettings; // ⚡ BFF API v2: Business settings for HomeController
  final PromotionalBanner?
      promotionalBanner; // ⚡ BFF API v2: Promotional banner data
  final HomeUnifiedMeta? meta;

  HomeUnifiedModel({
    this.banners,
    this.campaigns,
    this.categories,
    this.popularStores,
    this.brands,
    this.offers,
    this.customer,
    this.businessSettings,
    this.promotionalBanner,
    this.meta,
  });

  factory HomeUnifiedModel.fromJson(Map<String, dynamic> json) {
    // ⚡ BFF API v2: Response structure is { success: true, data: { ... } }
    // Extract 'data' object if present (v2), otherwise use json directly (v1 fallback)
    final data = json['data'] ?? json;

    // Parse banners
    List<Banner>? bannersList;
    if (data['banners'] != null && data['banners'] is List) {
      final bannersData = data['banners'] as List;
      if (kDebugMode) {
        debugPrint(
            '🔍 HomeUnifiedModel: Parsing banners - length: ${bannersData.length}');
      }
      bannersList = <Banner>[];
      for (final banner in bannersData) {
        try {
          if (banner is Map<String, dynamic>) {
            bannersList.add(Banner.fromJson(banner));
            if (kDebugMode && bannersList.length == 1) {
              appLogger.debug(
                  '   - First banner parsed: ${bannersList.first.imageFullUrl}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('   ⚠️ Error parsing banner: $e');
          }
        }
      }
      if (kDebugMode) {
        debugPrint('   ✅ Parsed ${bannersList.length} banners');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            '🔍 HomeUnifiedModel: No banners in response (data[\'banners\'] is null or not a List)');
      }
    }

    // Parse campaigns
    final List<BasicCampaignModel> campaignsList = <BasicCampaignModel>[];
    if (data['campaigns'] != null && data['campaigns'] is List) {
      final campaignsData = data['campaigns'] as List;
      if (kDebugMode) {
        debugPrint(
            '???? HomeUnifiedModel: Parsing campaigns - length: ${campaignsData.length}');
      }
      for (final campaign in campaignsData) {
        try {
          if (campaign is Map<String, dynamic>) {
            campaignsList.add(BasicCampaignModel.fromJson(campaign));
            if (kDebugMode && campaignsList.length == 1) {
              appLogger.debug(
                  '   - First campaign parsed: ${campaignsList.first.imageFullUrl}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('   ?????? Error parsing campaign: $e');
          }
        }
      }
      if (kDebugMode) {
        debugPrint('   ??? Parsed ${campaignsList.length} campaigns');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            "HomeUnifiedModel: No campaigns in response (data['campaigns'] is null or not a List)");
      }
    }

    // Parse categories
    List<CategoryModel>? categoriesList;
    if (data['categories'] != null && data['categories'] is List) {
      categoriesList = <CategoryModel>[];
      for (final category in (data['categories'] as List)) {
        categoriesList
            .add(CategoryModel.fromJson(category as Map<String, dynamic>));
      }
    }

    // ⚡ BFF API v2: Parse popular stores from nested structure
    // Structure: { popular_stores: { total_size: X, stores: [...] } }
    List<Store>? storesList;
    if (data['popular_stores'] != null) {
      if (data['popular_stores'] is Map) {
        // v2 API structure: nested object with 'stores' array
        final popularStoresData =
            data['popular_stores'] as Map<String, dynamic>;
        if (popularStoresData['stores'] != null &&
            popularStoresData['stores'] is List) {
          storesList = <Store>[];
          for (final store in (popularStoresData['stores'] as List)) {
            storesList.add(Store.fromJson(store as Map<String, dynamic>));
          }
        }
      } else if (data['popular_stores'] is List) {
        // Legacy v1 structure: direct array (fallback)
        storesList = <Store>[];
        for (final store in (data['popular_stores'] as List)) {
          storesList.add(Store.fromJson(store as Map<String, dynamic>));
        }
      }
    }

    // Parse brands
    List<BrandModel>? brandsList;
    if (data['brands'] != null && data['brands'] is List) {
      brandsList = <BrandModel>[];
      for (final brand in (data['brands'] as List)) {
        brandsList.add(BrandModel.fromJson(brand as Map<String, dynamic>));
      }
    }

    // Parse offers
    // 🔧 FIX: V2 API returns offers as direct array of offer objects
    // Each offer object needs to be wrapped in OffersModel structure
    List<OffersModel>? offersList;
    if (data['offers'] != null) {
      offersList = <OffersModel>[];

      if (data['offers'] is List) {
        // V2 structure: { offers: [ { id: 1, name: "...", ... }, ... ] }
        // Each item is a direct offer object (Datum-like), not wrapped in OffersModel
        // ⚡ TASK 3: Removed RAW OFFER debug prints - these were clogging the bridge

        // Collect all offer data items
        final allOfferData = <Datum>[];

        for (final offerItem in (data['offers'] as List)) {
          if (offerItem is Map) {
            // Cast to Map<String, dynamic> for type safety
            final offerMap = Map<String, dynamic>.from(offerItem);
            // Check if it's already wrapped in OffersModel structure
            if (offerMap.containsKey('success') &&
                offerMap.containsKey('data')) {
              // Already wrapped: { success: true, data: [...], message: "..." }
              // 🔧 FIX: Only parse if data is not empty
              final dataList = offerMap['data'];
              if (dataList != null && dataList is List && dataList.isNotEmpty) {
                final wrappedModel = OffersModel.fromJson(offerMap);
                if (wrappedModel.data.isNotEmpty) {
                  allOfferData.addAll(wrappedModel.data);
                  if (kDebugMode) {
                    debugPrint(
                        '✅ Parsed wrapped offer with ${wrappedModel.data.length} items');
                  }
                }
              } else {
                if (kDebugMode) {
                  debugPrint('⚠️ Skipping offer with empty data array: $offerMap');
                }
              }
            } else {
              // Direct offer object: parse it as Datum
              // 🔧 FIX: Check if it has required fields (id and name) before parsing
              if (offerMap.containsKey('id') &&
                  (offerMap.containsKey('name') ||
                      offerMap.containsKey('title'))) {
                try {
                  final datum = Datum.fromJson(offerMap);
                  // Only add if it has valid data
                  if (datum.id != null && (datum.name?.isNotEmpty ?? false)) {
                    allOfferData.add(datum);
                    if (kDebugMode) {
                      debugPrint(
                          '✅ Parsed offer: id=${datum.id}, name=${datum.name}, banner=${datum.banner?.isNotEmpty ?? false}');
                    }
                  } else {
                    if (kDebugMode) {
                      debugPrint(
                          '⚠️ Skipping offer with invalid data: id=${datum.id}, name=${datum.name}');
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('❌ Error parsing offer: $e');
                    debugPrint('   Offer JSON: $offerMap');
                  }
                }
              } else {
                if (kDebugMode) {
                  debugPrint(
                      '⚠️ Skipping offer missing required fields (id/name): $offerMap');
                }
              }
            }
          }
        }

        // Create a single OffersModel with all offer data
        if (allOfferData.isNotEmpty) {
          offersList.add(OffersModel(
            success: true,
            data: allOfferData,
            message: null,
          ));
          if (kDebugMode) {
            debugPrint(
                '✅ Created OffersModel with ${allOfferData.length} offer items');
          }
        }
      } else if (data['offers'] is Map) {
        // Single offer object or wrapped structure
        final offersMap = Map<String, dynamic>.from(data['offers'] as Map);
        if (offersMap['data'] != null && offersMap['data'] is List) {
          // Nested structure: { offers: { data: [...] } }
          final offersData = offersMap['data'] as List;
          for (final offer in offersData) {
            if (offer is Map) {
              final offerMap = Map<String, dynamic>.from(offer);
              if (offerMap.containsKey('success')) {
                offersList.add(OffersModel.fromJson(offerMap));
              } else {
                // Direct offer object, wrap it
                offersList.add(OffersModel(
                  success: true,
                  data: [Datum.fromJson(offerMap)],
                  message: null,
                ));
              }
            }
          }
        } else if (offersMap.containsKey('success')) {
          // Single wrapped OffersModel: { offers: { success: true, data: [...] } }
          offersList.add(OffersModel.fromJson(offersMap));
        } else {
          // Single direct offer object, wrap it
          offersList.add(OffersModel(
            success: true,
            data: [Datum.fromJson(offersMap)],
            message: null,
          ));
        }
      }
    }

    // ⚡ BFF API v2: Parse customer data for ProfileController
    Map<String, dynamic>? customerData;
    if (data['customer'] != null && data['customer'] is Map) {
      customerData = Map<String, dynamic>.from(data['customer'] as Map);
    }

    // ⚡ BFF API v2: Parse business settings for HomeController
    BusinessSettingsModel? businessSettingsData;
    if (data['business_settings'] != null) {
      try {
        if (data['business_settings'] is Map) {
          businessSettingsData = BusinessSettingsModel.fromJson(
              data['business_settings'] as Map<String, dynamic>);
        }
      } catch (e) {
        // If parsing fails, businessSettingsData remains null
      }
    }

    // Parse promotional banner
    PromotionalBanner? promotionalBannerData;
    if (data['promotional_banner'] != null &&
        data['promotional_banner'] is Map) {
      try {
        promotionalBannerData = PromotionalBanner.fromJson(
            data['promotional_banner'] as Map<String, dynamic>);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ HomeUnifiedModel: Error parsing promotional_banner: $e');
        }
      }
    }

    // Parse meta
    HomeUnifiedMeta? meta;
    if (data['meta'] != null && data['meta'] is Map) {
      meta = HomeUnifiedMeta.fromJson(data['meta'] as Map<String, dynamic>);
    }

    return HomeUnifiedModel(
      banners: bannersList,
      campaigns: campaignsList,
      categories: categoriesList,
      popularStores: storesList,
      brands: brandsList,
      offers: offersList,
      customer: customerData,
      businessSettings: businessSettingsData,
      promotionalBanner: promotionalBannerData,
      meta: meta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'banners': banners?.map((b) => b.toJson()).toList(),
      'campaigns': campaigns?.map((c) => c.toJson()).toList(),
      'categories': categories?.map((c) => c.toJson()).toList(),
      'popular_stores': popularStores?.map((s) => s.toJson()).toList(),
      'brands': brands?.map((b) => b.toJson()).toList(),
      'offers': offers?.map((o) => o.toJson()).toList(),
      'customer': customer,
      'business_settings': businessSettings?.toJson(),
      'promotional_banner': promotionalBanner?.toJson(),
      'meta': meta?.toJson(),
    };
  }

  /// Convert to BannerModel for BannerController
  BannerModel toBannerModel() {
    return BannerModel(
      banners: banners,
      campaigns: campaigns,
    );
  }

  /// Check if data is empty
  bool get isEmpty {
    return (banners == null || banners!.isEmpty) &&
        (campaigns == null || campaigns!.isEmpty) &&
        (categories == null || categories!.isEmpty) &&
        (popularStores == null || popularStores!.isEmpty) &&
        (brands == null || brands!.isEmpty) &&
        (offers == null || offers!.isEmpty) &&
        (customer == null || customer!.isEmpty) &&
        businessSettings == null;
  }

  /// Check if data is valid (has at least some content).
  /// Missing `campaigns` alone does not invalidate — other sections may still render.
  bool get isValid {
    if (!isEmpty) {
      return true;
    }
    return promotionalBanner != null;
  }
}

/// Metadata from unified endpoint
class HomeUnifiedMeta {
  final List<int>? zoneIds;
  final int? moduleId;
  final String? timestamp;
  final double? executionTimeMs;
  final bool? cacheHit;
  final String?
      versionHash; // ⚡ BFF API v2: Version hash for cache invalidation

  HomeUnifiedMeta({
    this.zoneIds,
    this.moduleId,
    this.timestamp,
    this.executionTimeMs,
    this.cacheHit,
    this.versionHash,
  });

  factory HomeUnifiedMeta.fromJson(Map<String, dynamic> json) {
    return HomeUnifiedMeta(
      zoneIds: json['zone_ids'] != null && json['zone_ids'] is List
          ? List<int>.from(json['zone_ids'] as List)
          : null,
      moduleId: json.parseInt('module_id'),
      timestamp: json.parseString('timestamp'),
      executionTimeMs: json.parseDouble('execution_time_ms'),
      cacheHit: json.parseBool('cache_hit') ? true : null,
      versionHash: json.parseString(
          'version_hash'), // ⚡ BFF API v2: Parse version_hash from API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zone_ids': zoneIds,
      'module_id': moduleId,
      'timestamp': timestamp,
      'execution_time_ms': executionTimeMs,
      'cache_hit': cacheHit,
      'version_hash': versionHash,
    };
  }
}
