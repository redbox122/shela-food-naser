import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class BannerModel {
  List<BasicCampaignModel>? campaigns;
  List<Banner>? banners;

  BannerModel({this.campaigns, this.banners});

  BannerModel.fromJson(Map<String, dynamic> json) {
    if (json['campaigns'] != null) {
      campaigns = [];
      for (var v in (json['campaigns'] as List)) {
        campaigns!.add(BasicCampaignModel.fromJson(v as Map<String, dynamic>));
      }
    }
    if (json['banners'] != null) {
      banners = [];
      for (var v in (json['banners'] as List)) {
        banners!.add(Banner.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (campaigns != null) {
      data['campaigns'] = campaigns!.map((v) => v.toJson()).toList();
    }
    if (banners != null) {
      data['banners'] = banners!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Banner {
  int? id;
  String? title;
  String? type;
  String? imageFullUrl;
  String? link;
  Store? store;
  Item? item;

  Banner({
    this.id,
    this.title,
    this.type,
    this.imageFullUrl,
    this.link,
    this.store,
    this.item,
  });

  Banner.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    title = json['title']?.toString();
    type = json['type']?.toString();
    // ⚡ Handle images for BOTH main home screen and landing page
    // Check both 'image_full_url' and 'image' keys
    final String rawImage = (json['image_full_url'] ?? json['image'] ?? '').toString();
    if (rawImage.isNotEmpty && !rawImage.startsWith('http')) {
      // Relative path - prepend base URL
      imageFullUrl = '${AppConstants.baseUrl}/storage/banner/$rawImage';
    } else {
      // Already a full URL or empty
      imageFullUrl = rawImage;
    }
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      appLogger.debug('DEBUG BANNER URL: $imageFullUrl');
    }
    link = json['link']?.toString();
    store = json['store'] != null ? Store.fromJson(json['store'] as Map<String, dynamic>) : null;
    item = json['item'] != null ? Item.fromJson(json['item'] as Map<String, dynamic>) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['type'] = type;
    data['image_full_url'] = imageFullUrl;
    data['link'] = link;
    if (store != null) {
      data['store'] = store!.toJson();
    }
    if (item != null) {
      data['item'] = item!.toJson();
    }
    return data;
  }
}
