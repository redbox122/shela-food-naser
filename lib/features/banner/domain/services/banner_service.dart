import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/others_banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/promotional_banner_model.dart';
import 'package:sixam_mart/features/banner/domain/repositories/banner_repository_interface.dart';
import 'package:sixam_mart/features/banner/domain/services/banner_service_interface.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:flutter/foundation.dart';

class BannerService implements BannerServiceInterface {
  final BannerRepositoryInterface bannerRepositoryInterface;
  BannerService({required this.bannerRepositoryInterface});

  @override
  Future<BannerModel?> getBannerList({required DataSourceEnum source}) async {
    final result = await bannerRepositoryInterface.getList(isBanner: true, source: source);
    return result is BannerModel? ? result : null;
  }

  @override
  Future<BannerModel?> getTaxiBannerList() async {
    final result = await bannerRepositoryInterface.getList(isTaxiBanner: true);
    return result is BannerModel? ? result : null;
  }

  @override
  Future<BannerModel?> getFeaturedBannerList() async {
    if (kDebugMode) {
      debugPrint('📡 BannerService: Fetching featured banners from repository');
    }
    try {
      final result =
          await bannerRepositoryInterface.getList(isFeaturedBanner: true);
      final model = result is BannerModel? ? result : null;
      if (kDebugMode) {
        debugPrint(
            '✅ BannerService: Featured banners fetch completed (campaigns=${model?.campaigns?.length ?? 0}, banners=${model?.banners?.length ?? 0})');
      }
      return model;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BannerService: Error fetching featured banners: $e');
      }
      rethrow;
    }
  }

  @override
  Future<ParcelOtherBannerModel?> getParcelOtherBannerList({required DataSourceEnum source}) async {
    final result = await bannerRepositoryInterface.getList(isParcelOtherBanner: true, source: source);
    return result is ParcelOtherBannerModel? ? result : null;
  }

  @override
  Future<PromotionalBanner?> getPromotionalBannerList() async {
    final result = await bannerRepositoryInterface.getList(isPromotionalBanner: true);
    return result is PromotionalBanner? ? result : null;
  }

  @override
  List<int?> moduleIdList() {
    final List<int?> moduleIdList = [];
    // 🔧 NULL-SAFETY: Use safe null-coalescing to prevent crash
    final addressModel = AddressHelper.getUserAddressFromSharedPref();
    final zoneDataList = addressModel?.zoneData ?? [];
    for (final ZoneData zone in zoneDataList) {
      for (final Modules module in zone.modules ?? []) {
        moduleIdList.add(module.id);
      }
    }
    return moduleIdList;
  }

}
