import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/services/campaign_service_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class CampaignController extends GetxController implements GetxService {
  final CampaignServiceInterface campaignServiceInterface;
  CampaignController({required this.campaignServiceInterface});

  List<BasicCampaignModel>? _basicCampaignList;
  List<BasicCampaignModel>? get basicCampaignList => _basicCampaignList;

  BasicCampaignModel? _basicCampaign;
  BasicCampaignModel? get basicCampaign => _basicCampaign;

  List<Item>? _itemCampaignList;
  List<Item>? get itemCampaignList => _itemCampaignList;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }

  void itemAndBasicCampaignNull() {
    _itemCampaignList = null;
    _basicCampaignList = null;
  }

  Future<List<BasicCampaignModel>?> getBasicCampaignList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    // ✅ تحقق من تفعيل القسم
    if (businessSettings?.campaignsBasicSection?.toString() == '1') {
      if (_basicCampaignList == null || reload || fromRecall) {
        List<BasicCampaignModel>? basicCampaignList;

        if (dataSource == DataSourceEnum.local) {
          basicCampaignList = await campaignServiceInterface.getBasicCampaignList(DataSourceEnum.local);
          _prepareBasicCampaign(basicCampaignList);
          await getBasicCampaignList(false, dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          basicCampaignList = await campaignServiceInterface.getBasicCampaignList(DataSourceEnum.client);
          _prepareBasicCampaign(basicCampaignList);
        }
      }
    }
    return null;
  }

  void _prepareBasicCampaign(List<BasicCampaignModel>? basicCampaignList) {
    if (basicCampaignList != null) {
      _basicCampaignList = [];
      _basicCampaignList!.addAll(basicCampaignList);
    }
    update();
  }

  Future<void> getBasicCampaignDetails(int? campaignID) async {
    _basicCampaign = null;
    final BasicCampaignModel? basicCampaign = await campaignServiceInterface.getCampaignDetails(campaignID.toString());
    if (basicCampaign != null) {
      _basicCampaign = basicCampaign;
    }
    update();
  }

  Future<List<Item>?> getItemCampaignList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    // ✅ التحقق من تفعيل قسم الحملات الأساسية
    if (businessSettings?.campaignsBasicSection?.toString() == '1') {
      //

      if (_itemCampaignList == null || reload || fromRecall) {
        List<Item>? itemCampaignList;
        if (dataSource == DataSourceEnum.local) {
          itemCampaignList = await campaignServiceInterface.getItemCampaignList(DataSourceEnum.local);
          _prepareItemCampaign(itemCampaignList);

          // استدعاء دالة البيانات من السيرفر بعد البيانات المحلية
          await getItemCampaignList(false, dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          itemCampaignList = await campaignServiceInterface.getItemCampaignList(DataSourceEnum.client);
          _prepareItemCampaign(itemCampaignList);
        }
      }
    }
    return null;
  }

  void _prepareItemCampaign(List<Item>? itemCampaignList) {
    if (itemCampaignList != null) {
      _itemCampaignList = [];
      final List<Item> campaign = [];
      campaign.addAll(itemCampaignList);
      for (final c in campaign) {
        if (!(Get.find<SplashController>().getModuleConfig(c.moduleType).newVariation ?? false) ||
            c.variations!.isEmpty ||
            c.foodVariations!.isNotEmpty) {
          _itemCampaignList!.add(c);
        }
      }
    }
    update();
  }

  /// Set basic campaign list from cache (handles both List<BasicCampaignModel> and raw JSON)
  void setBasicCampaignListFromCache(dynamic data) {
    if (data == null) return;
    
    try {
      if (data is List<BasicCampaignModel>) {
        // Already deserialized model objects
        _basicCampaignList = data;
      } else if (data is List) {
        // Raw JSON list from disk cache - deserialize it
        _basicCampaignList = data.map((item) => BasicCampaignModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          appLogger.warning('⚠️ CampaignController: Unexpected data type for basic campaigns: ${data.runtimeType}');
        }
        return;
      }
      update();
      if (kDebugMode) {
        appLogger.info('✅ CampaignController: Loaded ${_basicCampaignList!.length} basic campaigns from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('❌ CampaignController: Error setting basic campaigns from cache: $e', e);
      }
    }
  }

  /// Set item campaign list from cache (handles both List<Item> and raw JSON)
  void setItemCampaignListFromCache(dynamic data) {
    if (data == null) return;
    
    try {
      if (data is List<Item>) {
        // Already deserialized list of items
        _itemCampaignList = data;
      } else if (data is List) {
        // Raw JSON list from disk cache - deserialize it
        _itemCampaignList = data.map((item) => Item.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          appLogger.warning('⚠️ CampaignController: Unexpected data type for item campaigns: ${data.runtimeType}');
        }
        return;
      }
      update();
      if (kDebugMode) {
        appLogger.info('✅ CampaignController: Loaded ${_itemCampaignList?.length ?? 0} item campaigns from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('❌ CampaignController: Error setting item campaigns from cache: $e', e);
      }
    }
  }
}
