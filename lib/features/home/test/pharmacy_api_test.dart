/// Pharmacy Module API Test Script
/// 
/// This script tests all APIs used by the pharmacy module home screen
/// to verify data loading and identify any issues.
library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class PharmacyApiTest {
  /// Test all pharmacy module APIs
  static Future<Map<String, dynamic>> testAllPharmacyApis() async {
    final results = <String, dynamic>{};
    final splashController = Get.find<SplashController>();
    
    // Verify pharmacy module is selected
    if (splashController.module?.moduleType.toString() != AppConstants.pharmacy) {
      results['error'] = 'Pharmacy module is not selected';
      return results;
    }
    
    results['module_id'] = splashController.module?.id;
    results['module_name'] = splashController.module?.moduleName;
    
    // Test Categories API
    try {
      final categoryController = Get.find<CategoryController>();
      await categoryController.getCategoryList(true, dataSource: DataSourceEnum.client);
      results['categories'] = {
        'success': categoryController.categoryList != null,
        'count': categoryController.categoryList?.length ?? 0,
        'data': categoryController.categoryList != null && categoryController.categoryList!.isNotEmpty,
      };
    } catch (e) {
      results['categories'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Basic Medicine API
    try {
      final itemController = Get.find<ItemController>();
      await itemController.getBasicMedicine(true, true, dataSource: DataSourceEnum.client);
      results['basic_medicine'] = {
        'success': itemController.basicMedicineModel != null,
        'has_categories': itemController.basicMedicineModel?.categories != null && itemController.basicMedicineModel!.categories!.isNotEmpty,
        'has_products': itemController.basicMedicineModel?.products != null && itemController.basicMedicineModel!.products!.isNotEmpty,
        'categories_count': itemController.basicMedicineModel?.categories?.length ?? 0,
        'products_count': itemController.basicMedicineModel?.products?.length ?? 0,
      };
    } catch (e) {
      results['basic_medicine'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Featured Stores API
    try {
      final storeController = Get.find<StoreController>();
      await storeController.getFeaturedStoreList(dataSource: DataSourceEnum.client);
      results['featured_stores'] = {
        'success': storeController.featuredStoreList != null,
        'count': storeController.featuredStoreList?.length ?? 0,
        'data': storeController.featuredStoreList != null && storeController.featuredStoreList!.isNotEmpty,
      };
    } catch (e) {
      results['featured_stores'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Common Conditions API
    try {
      final itemController = Get.find<ItemController>();
      await itemController.getCommonConditions(true);
      results['common_conditions'] = {
        'success': itemController.commonConditions != null,
        'count': itemController.commonConditions?.length ?? 0,
        'data': itemController.commonConditions != null && itemController.commonConditions!.isNotEmpty,
      };
      
      // Test Conditions Wise Items if conditions exist
      if (itemController.commonConditions != null && itemController.commonConditions!.isNotEmpty) {
        await itemController.getConditionsWiseItem(itemController.commonConditions![0].id!, true);
        results['conditions_wise_items'] = {
          'success': itemController.conditionWiseProduct != null,
          'count': itemController.conditionWiseProduct?.length ?? 0,
          'data': itemController.conditionWiseProduct != null && itemController.conditionWiseProduct!.isNotEmpty,
        };
      }
    } catch (e) {
      results['common_conditions'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Latest Stores API
    try {
      final storeController = Get.find<StoreController>();
      await storeController.getLatestStoreList(true, 'all', true, dataSource: DataSourceEnum.client);
      results['latest_stores'] = {
        'success': storeController.latestStoreList != null,
        'count': storeController.latestStoreList?.length ?? 0,
        'data': storeController.latestStoreList != null && storeController.latestStoreList!.isNotEmpty,
      };
    } catch (e) {
      results['latest_stores'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Top Offer Stores API
    try {
      final storeController = Get.find<StoreController>();
      await storeController.getTopOfferStoreList(true, true, dataSource: DataSourceEnum.client);
      results['top_offer_stores'] = {
        'success': storeController.topOfferStoreList != null,
        'count': storeController.topOfferStoreList?.length ?? 0,
        'data': storeController.topOfferStoreList != null && storeController.topOfferStoreList!.isNotEmpty,
      };
    } catch (e) {
      results['top_offer_stores'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Visit Again Stores API
    try {
      final storeController = Get.find<StoreController>();
      await storeController.getVisitAgainStoreList(dataSource: DataSourceEnum.client);
      results['visit_again_stores'] = {
        'success': storeController.visitAgainStoreList != null,
        'count': storeController.visitAgainStoreList?.length ?? 0,
        'data': storeController.visitAgainStoreList != null && storeController.visitAgainStoreList!.isNotEmpty,
      };
    } catch (e) {
      results['visit_again_stores'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Banners API
    try {
      final bannerController = Get.find<BannerController>();
      await bannerController.getBannerList(true, dataSource: DataSourceEnum.client);
      results['banners'] = {
        'success': bannerController.bannerImageList != null,
        'count': bannerController.bannerImageList?.length ?? 0,
        'data': bannerController.bannerImageList != null && bannerController.bannerImageList!.isNotEmpty,
      };
    } catch (e) {
      results['banners'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Promotional Banner API
    try {
      final bannerController = Get.find<BannerController>();
      await bannerController.getPromotionalBannerList(true);
      results['promotional_banner'] = {
        'success': bannerController.promotionalBanner != null,
        'has_bottom_banner': bannerController.promotionalBanner?.bottomSectionBannerFullUrl != null,
      };
    } catch (e) {
      results['promotional_banner'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Basic Campaign API
    try {
      final campaignController = Get.find<CampaignController>();
      await campaignController.getBasicCampaignList(true, dataSource: DataSourceEnum.client);
      results['basic_campaigns'] = {
        'success': campaignController.basicCampaignList != null,
        'count': campaignController.basicCampaignList?.length ?? 0,
        'data': campaignController.basicCampaignList != null && campaignController.basicCampaignList!.isNotEmpty,
      };
    } catch (e) {
      results['basic_campaigns'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Item Campaign API (Just For You)
    try {
      final campaignController = Get.find<CampaignController>();
      await campaignController.getItemCampaignList(true, dataSource: DataSourceEnum.client);
      results['item_campaigns'] = {
        'success': campaignController.itemCampaignList != null,
        'count': campaignController.itemCampaignList?.length ?? 0,
        'data': campaignController.itemCampaignList != null && campaignController.itemCampaignList!.isNotEmpty,
      };
    } catch (e) {
      results['item_campaigns'] = {'success': false, 'error': e.toString()};
    }
    
    // Test Advertisement API (Highlights)
    try {
      final advertisementController = Get.find<AdvertisementController>();
      await advertisementController.getAdvertisementList(dataSource: DataSourceEnum.client);
      results['advertisements'] = {
        'success': advertisementController.advertisementList != null,
        'count': advertisementController.advertisementList?.length ?? 0,
        'data': advertisementController.advertisementList != null && advertisementController.advertisementList!.isNotEmpty,
      };
    } catch (e) {
      results['advertisements'] = {'success': false, 'error': e.toString()};
    }
    
    // Print results
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔬 PHARMACY MODULE API TEST RESULTS');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('Module ID: ${results['module_id']}');
      debugPrint('Module Name: ${results['module_name']}');
      debugPrint('');
      results.forEach((key, value) {
        if (key != 'module_id' && key != 'module_name' && key != 'error') {
          debugPrint('$key: ${(value['success'] as bool?) == true ? '✅' : '❌'} ${value['count'] ?? ''} ${(value['data'] as bool?) == true ? '(HAS DATA)' : (value['data'] as bool?) == false ? '(NO DATA)' : ''}');
          if (value['error'] != null) {
            debugPrint('  Error: ${value['error']}');
          }
        }
      });
      debugPrint('═══════════════════════════════════════════════════════════');
    }
    
    return results;
  }
}

