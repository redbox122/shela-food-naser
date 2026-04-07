import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Model for the `/api/v1/app-init` endpoint response
/// Combines config, modules, zones, and business settings into one call
class AppInitModel {
  final ConfigModel? config;
  final List<ModuleModel>? modules;
  final int? userZoneId;
  final List<ZoneData>? zones;
  final BusinessSettings? businessSettings;

  AppInitModel({
    this.config,
    this.modules,
    this.userZoneId,
    this.zones,
    this.businessSettings,
  });

  factory AppInitModel.fromJson(Map<String, dynamic> json) {
    return AppInitModel(
      config: json['config'] != null
          ? ConfigModel.fromJson(json['config'] as Map<String, dynamic>)
          : null,
      modules: json['modules'] != null
          ? (json['modules'] as List<dynamic>)
              .map((module) => ModuleModel.fromJson(module as Map<String, dynamic>))
              .toList()
          : null,
      userZoneId: json['user_zone_id'] as int?,
      zones: json['zones'] != null
          ? (json['zones'] as List<dynamic>)
              .map((zone) => ZoneData.fromJson(zone as Map<String, dynamic>))
              .toList()
          : null,
      businessSettings: json['business_settings'] != null
          ? BusinessSettings.fromJson(json['business_settings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'config': config?.toJson(),
      'modules': modules?.map((m) => m.toJson()).toList(),
      'user_zone_id': userZoneId,
      'zones': zones?.map((z) => z.toJson()).toList(),
      'businessSettings': businessSettings?.toJson(),
    };
  }
}

/// Business settings for home screen setup
class BusinessSettings {
  final int? bannerSection;
  final int? categoriesSection;
  final int? bestReviewedStoresSection;
  final int? popularStoresSection;
  final int? newlyOpenedStoresSection;
  final int? popularItemsSection;
  final int? flashSaleSection;
  final int? offersSection;
  final int? topRestaurantsSection;
  final int? allRestaurantsSection;
  final int? allStoresSection;

  BusinessSettings({
    this.bannerSection,
    this.categoriesSection,
    this.bestReviewedStoresSection,
    this.popularStoresSection,
    this.newlyOpenedStoresSection,
    this.popularItemsSection,
    this.flashSaleSection,
    this.offersSection,
    this.topRestaurantsSection,
    this.allRestaurantsSection,
    this.allStoresSection,
  });

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    // #region agent log
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      try {
        final logFile = File(r'c:\Users\pc\Desktop\clone\app-test\.cursor\debug.log');
        logFile.writeAsStringSync('${jsonEncode({"location":"app_init_model.dart:78","message":"BusinessSettings.fromJson entry","data":{"bannerSectionType":json['banner_section'].runtimeType.toString(),"bannerSectionValue":json['banner_section'].toString(),"categoriesSectionType":json['categories_section'].runtimeType.toString(),"categoriesSectionValue":json['categories_section'].toString()},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"A"})}\n', mode: FileMode.append);
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
    }
    // #endregion
    
    // Helper function to safely convert to int?
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    final Map<String, dynamic>? homePageSections =
        json['home_page_sections'] is Map<String, dynamic>
            ? json['home_page_sections'] as Map<String, dynamic>
            : null;
    final int? bannerSectionValue = toInt(
        homePageSections?['bannersSection'] ?? json['banner_section']);
    final int? categoriesSectionValue = toInt(
        homePageSections?['categoriesSection'] ?? json['categories_section']);
    final int? topRestaurantsSectionValue = toInt(
        homePageSections?['topRestaurantsSection'] ??
            homePageSections?['top_restaurants_section'] ??
            json['top_restaurants_section']);
    final int? allRestaurantsSectionValue = toInt(
        homePageSections?['allRestaurantsSection'] ??
            homePageSections?['all_restaurants_section'] ??
            json['all_restaurants_section']);
    final int? allStoresSectionValue = toInt(
        homePageSections?['allStoresSection'] ??
            homePageSections?['all_stores_section'] ??
            json['all_stores_section']);
    return BusinessSettings(
      bannerSection: bannerSectionValue,
      categoriesSection: categoriesSectionValue,
      bestReviewedStoresSection: toInt(json['best_reviewed_stores_section']),
      popularStoresSection: toInt(json['popular_stores_section']),
      newlyOpenedStoresSection: toInt(json['newly_opened_stores_section']),
      popularItemsSection: toInt(json['popular_items_section']),
      flashSaleSection: toInt(json['flash_sale_section']),
      offersSection: toInt(homePageSections?['offersSection'] ?? json['offers_section']),
      topRestaurantsSection: topRestaurantsSectionValue,
      allRestaurantsSection: allRestaurantsSectionValue,
      allStoresSection: allStoresSectionValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'banner_section': bannerSection,
      'categories_section': categoriesSection,
      'best_reviewed_stores_section': bestReviewedStoresSection,
      'popular_stores_section': popularStoresSection,
      'newly_opened_stores_section': newlyOpenedStoresSection,
      'popular_items_section': popularItemsSection,
      'flash_sale_section': flashSaleSection,
      'offers_section': offersSection,
      'top_restaurants_section': topRestaurantsSection,
      'all_restaurants_section': allRestaurantsSection,
      'all_stores_section': allStoresSection,
    };
  }
}
