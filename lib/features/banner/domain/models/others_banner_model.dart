
import 'package:sixam_mart/common/utils/json_parser.dart';

class ParcelOtherBannerModel {
  String? promotionalBannerUrl;
  String? promotionalBanners3Url;
  List<Banners>? banners;

  ParcelOtherBannerModel({
    this.promotionalBannerUrl,
    this.promotionalBanners3Url,
    this.banners,
  });

  ParcelOtherBannerModel.fromJson(Map<String, dynamic> json) {
    promotionalBannerUrl = json.parseString('promotional_banner_url');
    promotionalBanners3Url = json.parseString('promotional_banner_s3_url');
    final List<Map<String, dynamic>> bannerList = json.parseMapList('banners');
    if (bannerList.isNotEmpty) {
      banners = bannerList.map((Map<String, dynamic> v) => Banners.fromJson(v)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['promotional_banner_url'] = promotionalBannerUrl;
    data['promotional_banner_s3_url'] = promotionalBanners3Url;
    if (banners != null) {
      data['banners'] = banners!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Banners {
  int? id;
  int? moduleId;
  String? key;
  String? imageFullUrl;
  String? type;
  int? status;
  String? createdAt;
  String? updatedAt;

  Banners({
    this.id,
    this.moduleId,
    this.key,
    this.imageFullUrl,
    this.type,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  Banners.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    moduleId = json.parseInt('module_id');
    key = json.parseString('key');
    imageFullUrl = json.parseString('value_full_url');
    type = json.parseString('type');
    status = json.parseInt('status');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_id'] = moduleId;
    data['key'] = key;
    data['value_full_url'] = imageFullUrl;
    data['type'] = type;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
