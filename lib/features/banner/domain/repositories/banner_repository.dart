import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/others_banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/promotional_banner_model.dart';
import 'package:sixam_mart/features/banner/domain/repositories/banner_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/header_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class BannerRepository implements BannerRepositoryInterface {
  final ApiClient apiClient;
  BannerRepository({required this.apiClient});

  @override
  Future getList(
      {int? offset,
      bool isBanner = false,
      bool isTaxiBanner = false,
      bool isFeaturedBanner = false,
      bool isParcelOtherBanner = false,
      bool isPromotionalBanner = false,
      DataSourceEnum? source}) async {
    if (isBanner) {
      return await _getBannerList(source: source!);
    } else if (isTaxiBanner) {
      return await _getTaxiBannerList();
    } else if (isFeaturedBanner) {
      return await _getFeaturedBannerList();
    } else if (isParcelOtherBanner) {
      return await _getParcelOtherBannerList();
    } else if (isPromotionalBanner) {
      return await _getPromotionalBannerList();
    }
  }

  Future<BannerModel?> _getBannerList({required DataSourceEnum source}) async {
    BannerModel? bannerModel;

    // Safely get module ID - return null if module not set
    final splashController = Get.find<SplashController>();
    final moduleId = splashController.module?.id;

    if (moduleId == null) {
      // Module not set yet (e.g., on multi-module screen)
      // Return null instead of crashing
      return null;
    }

    final String cacheId = '${AppConstants.bannerUri}-$moduleId';

    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient.getData(AppConstants.bannerUri);

        // 🔧 FIX: Handle 304 Not Modified - load from Hive cache immediately with multi-source fallback
        if (response.statusCode == 304) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '✅ Banner_Repository: 304 Not Modified received - loading from Hive cache');
          }

          BannerModel? cachedBanners;
          final cacheService = HiveHomeCacheService();

          try {
            // Fallback 1: Try current module ID
            cachedBanners = await cacheService.loadBanners(moduleId);
            if (cachedBanners != null &&
                ((cachedBanners.banners != null &&
                        cachedBanners.banners!.isNotEmpty) ||
                    (cachedBanners.campaigns != null &&
                        cachedBanners.campaigns!.isNotEmpty))) {
              if (kDebugMode && AppConstants.enableVerboseLogs) {
                appLogger.info(
                    '✅ Banner_Repository: Loaded banners from Hive cache (moduleId: $moduleId)');
              }
              return cachedBanners;
            } else {
              if (kDebugMode && AppConstants.enableVerboseLogs) {
                appLogger.warning(
                    '⚠️ Banner_Repository: No cached banners found for moduleId: $moduleId');
              }
            }

            // Fallback 2: Try moduleId = 3 (eCommerce) if current module failed
            if (moduleId != 3) {
              if (kDebugMode && AppConstants.enableVerboseLogs) {
                appLogger.debug(
                    '🔄 Banner_Repository: Trying fallback to moduleId=3 (eCommerce)');
              }
              final fallbackBanners = await cacheService.loadBanners(3);
              if (fallbackBanners != null &&
                  ((fallbackBanners.banners != null &&
                          fallbackBanners.banners!.isNotEmpty) ||
                      (fallbackBanners.campaigns != null &&
                          fallbackBanners.campaigns!.isNotEmpty))) {
                cachedBanners = fallbackBanners;
                if (kDebugMode && AppConstants.enableVerboseLogs) {
                  appLogger.info(
                      '✅ Banner_Repository: Loaded banners from moduleId=3 cache');
                }
                return cachedBanners;
              }
            }

            // Fallback 3: BannerController exposes URL lists only, not a BannerModel,
            // so no further fallback is possible here.
          } catch (e) {
            if (kDebugMode && AppConstants.enableVerboseLogs) {
              appLogger.error('❌ Banner_Repository: Error loading from cache on 304: $e', e);
            }
          }

          // All fallbacks failed - return null (304 means data unchanged, but cache unavailable)
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.warning(
                '⚠️ Banner_Repository: 304 received but all cache sources failed');
          }
          return null;
        }

        if (response.statusCode == 200) {
          bannerModel = BannerModel.fromJson(response.body as Map<String, dynamic>);
          LocalClient.organize(source, cacheId, jsonEncode(response.body),
              apiClient.getHeader());
        }
        break;
      case DataSourceEnum.local:
        final String? cacheResponseData =
            await LocalClient.organize(source, cacheId, null, null);
        if (cacheResponseData != null) {
          bannerModel = BannerModel.fromJson(jsonDecode(cacheResponseData) as Map<String, dynamic>);
        }
        break;
    }

    return bannerModel;
  }

  Future<BannerModel?> _getTaxiBannerList() async {
    BannerModel? bannerModel;
    final Response response = await apiClient.getData(AppConstants.taxiBannerUri);
    if (response.statusCode == 200) {
      bannerModel = BannerModel.fromJson(response.body as Map<String, dynamic>);
    }
    return bannerModel;
  }

  Future<BannerModel?> _getFeaturedBannerList() async {
    try {
      BannerModel? bannerModel;
      const uri = '${AppConstants.bannerUri}?featured=1';

      if (kDebugMode && AppConstants.enableVerboseLogs) {
        appLogger.debug('🔍 BannerRepository._getFeaturedBannerList: Calling API: $uri');
      }

      final Response response =
          await apiClient.getData(uri, headers: HeaderHelper.featuredHeader());

      if (kDebugMode && AppConstants.enableVerboseLogs) {
        appLogger.debug(
            '📊 BannerRepository._getFeaturedBannerList: Response status: ${response.statusCode}');
      }

      if (response.statusCode == 304) {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.debug(
              '✅ BannerRepository._getFeaturedBannerList: 304 Not Modified - loading from cache');
        }

        final splashController = Get.find<SplashController>();
        // Fall back to promotional module (3) when no module is selected (e.g. MultiModuleHomeScreen)
        final moduleId = splashController.module?.id ?? 3;

        final cacheService = HiveHomeCacheService();
        BannerModel? cachedBanners = await cacheService.loadBanners(moduleId);
        if (cachedBanners != null &&
            ((cachedBanners.banners != null &&
                    cachedBanners.banners!.isNotEmpty) ||
                (cachedBanners.campaigns != null &&
                    cachedBanners.campaigns!.isNotEmpty))) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.info(
                '✅ BannerRepository._getFeaturedBannerList: Loaded banners from cache (moduleId: $moduleId)');
          }
          return cachedBanners;
        }

        if (moduleId != 3) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                '🔄 BannerRepository._getFeaturedBannerList: Trying fallback cache for moduleId=3');
          }
          cachedBanners = await cacheService.loadBanners(3);
          if (cachedBanners != null &&
              ((cachedBanners.banners != null &&
                      cachedBanners.banners!.isNotEmpty) ||
                  (cachedBanners.campaigns != null &&
                      cachedBanners.campaigns!.isNotEmpty))) {
            return cachedBanners;
          }
        }

        return null;
      }

      if (response.statusCode == 200) {
        try {
          bannerModel = BannerModel.fromJson(response.body as Map<String, dynamic>);
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.info(
                '✅ BannerRepository._getFeaturedBannerList: Successfully parsed banner model - campaigns: ${bannerModel.campaigns?.length ?? 0}, banners: ${bannerModel.banners?.length ?? 0}');
          }
        } catch (e, stackTrace) {
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.error(
                '❌ BannerRepository._getFeaturedBannerList: Error parsing banner model: $e', e, stackTrace);
          }
          return null;
        }
      } else {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          appLogger.warning(
              '⚠️ BannerRepository._getFeaturedBannerList: API returned non-200 status: ${response.statusCode}');
          if (response.body != null) {
            appLogger.warning('⚠️ Response body: ${response.body}');
          }
        }
      }
      return bannerModel;
    } catch (e, stackTrace) {
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        appLogger.error(
            '❌ BannerRepository._getFeaturedBannerList: Exception during API call: $e', e, stackTrace);
      }
      return null;
    }
  }

  Future<ParcelOtherBannerModel?> _getParcelOtherBannerList() async {
    ParcelOtherBannerModel? parcelOtherBannerModel;
    final Response response =
        await apiClient.getData(AppConstants.parcelOtherBannerUri);
    if (response.statusCode == 200) {
      parcelOtherBannerModel = ParcelOtherBannerModel.fromJson(response.body as Map<String, dynamic>);
    }
    return parcelOtherBannerModel;
  }

  Future<PromotionalBanner?> _getPromotionalBannerList() async {
    PromotionalBanner? promotionalBanner;
    final Response response =
        await apiClient.getData(AppConstants.promotionalBannerUri);
    if (response.statusCode == 200 && response.body is Map) {
      promotionalBanner = PromotionalBanner.fromJson(response.body as Map<String, dynamic>);
    } else if (response.statusCode == 304) {
      // 304 with no local cache → force a fresh fetch by clearing the ETag and retrying once.
      if (kDebugMode) {
        appLogger.warning(
            '⚠️ BannerRepository._getPromotionalBannerList: 304 received with no local cache — retrying fresh');
      }
      await HiveHomeCacheService().clearETagForUri(AppConstants.promotionalBannerUri);
      final Response retryResponse =
          await apiClient.getData(AppConstants.promotionalBannerUri);
      if (retryResponse.statusCode == 200 && retryResponse.body is Map) {
        promotionalBanner =
            PromotionalBanner.fromJson(retryResponse.body as Map<String, dynamic>);
      }
    }
    return promotionalBanner;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
