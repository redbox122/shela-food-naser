import 'dart:convert';

import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/domain/repositories/campaign_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class CampaignRepository implements CampaignRepositoryInterface {
  final ApiClient apiClient;
  CampaignRepository({required this.apiClient});

  @override
  Future getList(
      {int? offset,
      bool isBasicCampaign = false,
      bool isItemCampaign = false,
      DataSourceEnum source = DataSourceEnum.client}) async {
    if (isBasicCampaign) {
      return await _getBasicCampaignList(source);
    } else if (isItemCampaign) {
      return await _getItemCampaignList(source);
    }
  }

  Future<List<BasicCampaignModel>?> _getBasicCampaignList(
      DataSourceEnum source) async {
    List<BasicCampaignModel>? basicCampaignList;
    final String cacheId =
        '${AppConstants.basicCampaignUri}-banner-${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.basicCampaignUri);
        if (response.statusCode == 200) {
          basicCampaignList = [];
          for (var campaign in (response.body as List)) {
            basicCampaignList.add(BasicCampaignModel.fromJson(campaign as Map<String, dynamic>));
          }
          LocalClient.organize(source, cacheId, jsonEncode(response.body),
              apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData =
            await LocalClient.organize(source, cacheId, null, null);
        if (cacheResponseData != null) {
          basicCampaignList = [];
          for (var campaign in (jsonDecode(cacheResponseData) as List)) {
            basicCampaignList.add(BasicCampaignModel.fromJson(campaign as Map<String, dynamic>));
          }
        }
    }

    return basicCampaignList;
  }

  Future<List<Item>?> _getItemCampaignList(DataSourceEnum source) async {
    List<Item>? itemCampaignList;
    final String cacheId =
        '${AppConstants.basicCampaignUri}-${Get.find<SplashController>().module!.id!}';

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.itemCampaignUri);
        if (response.statusCode == 200) {
          itemCampaignList = [];
          for (var camp in (response.body as List)) {
            itemCampaignList.add(Item.fromJson(camp as Map<String, dynamic>));
          }
          LocalClient.organize(source, cacheId, jsonEncode(response.body),
              apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData =
            await LocalClient.organize(source, cacheId, null, null);
        if (cacheResponseData != null) {
          itemCampaignList = [];
          for (var camp in (jsonDecode(cacheResponseData) as List)) {
            itemCampaignList.add(Item.fromJson(camp as Map<String, dynamic>));
          }
        }
    }

    return itemCampaignList;
  }

  @override
  Future<BasicCampaignModel?> get(String? id) async {
    BasicCampaignModel? basicCampaign;
    final Response response =
        await apiClient.getData('${AppConstants.basicCampaignDetailsUri}$id');
    if (response.statusCode == 200) {
      basicCampaign = BasicCampaignModel.fromJson(response.body as Map<String, dynamic>);
    }
    return basicCampaign;
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
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
