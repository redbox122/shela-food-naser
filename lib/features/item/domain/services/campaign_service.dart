import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/domain/repositories/campaign_repository_interface.dart';
import 'package:sixam_mart/features/item/domain/services/campaign_service_interface.dart';

class CampaignService implements CampaignServiceInterface {
  final CampaignRepositoryInterface campaignRepositoryInterface;
  CampaignService({required this.campaignRepositoryInterface});

  @override
  Future<List<BasicCampaignModel>?> getBasicCampaignList(DataSourceEnum source) async {
    final result = await campaignRepositoryInterface.getList(isBasicCampaign: true, source: source);
    return result is List<BasicCampaignModel>? ? result : null;
  }

  @override
  Future<BasicCampaignModel?> getCampaignDetails(String campaignID) async {
    final result = await campaignRepositoryInterface.get(campaignID);
    return result is BasicCampaignModel? ? result : null;
  }

  @override
  Future<List<Item>?> getItemCampaignList(DataSourceEnum dataSource) async {
    final result = await campaignRepositoryInterface.getList(isItemCampaign: true, source: dataSource);
    return result is List<Item>? ? result : null;
  }

}