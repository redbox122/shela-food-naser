import 'package:sixam_mart/common/utils/json_parser.dart';

class VideoContentModel {
  List<BannerContents>? bannerContents;
  String? sectionTitle;
  String? bannerType;
  String? bannerVideo;
  String? bannerImageFullUrl;
  String? bannerVideoContentFullUrl;

  VideoContentModel({
    this.bannerContents,
    this.sectionTitle,
    this.bannerType,
    this.bannerVideo,
    this.bannerImageFullUrl,
    this.bannerVideoContentFullUrl,
  });

  VideoContentModel.fromJson(Map<String, dynamic> json) {
    if (json['banner_contents'] != null) {
      bannerContents = <BannerContents>[];
      for (var v in (json['banner_contents'] as List)) {
        bannerContents!.add(BannerContents.fromJson(v as Map<String, dynamic>));
      }
    }
    sectionTitle = json['section_title']?.toString();
    bannerType = json['banner_type']?.toString();
    bannerVideo = json['banner_video']?.toString();
    bannerImageFullUrl = json['banner_image_full_url']?.toString();
    bannerVideoContentFullUrl = json['banner_video_content_full_url']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bannerContents != null) {
      data['banner_contents'] = bannerContents!.map((v) => v.toJson()).toList();
    }
    data['section_title'] = sectionTitle;
    data['banner_type'] = bannerType;
    data['banner_video'] = bannerVideo;
    data['banner_image_full_url'] = bannerImageFullUrl;
    data['banner_video_content_full_url'] = bannerVideoContentFullUrl;
    return data;
  }
}

class BannerContents {
  int? id;
  int? moduleId;
  String? key;
  String? value;
  String? type;
  int? status;
  String? createdAt;
  String? updatedAt;
  List<Translations>? translations;

  BannerContents({
    this.id,
    this.moduleId,
    this.key,
    this.value,
    this.type,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.translations,
  });

  BannerContents.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    moduleId = json.parseInt('module_id');
    key = json.parseString('key');
    value = json.parseString('value');
    type = json.parseString('type');
    status = json.parseInt('status');
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    if (json['translations'] != null) {
      translations = <Translations>[];
      for (var v in (json['translations'] as List)) {
        translations!.add(Translations.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_id'] = moduleId;
    data['key'] = key;
    data['value'] = value;
    data['type'] = type;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Translations {
  int? id;
  String? translationableType;
  int? translationableId;
  String? locale;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Translations({
    this.id,
    this.translationableType,
    this.translationableId,
    this.locale,
    this.key,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  Translations.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    translationableType = json.parseString('translationable_type');
    translationableId = json.parseInt('translationable_id');
    locale = json['locale']?.toString();
    key = json['key']?.toString();
    value = json['value']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['translationable_type'] = translationableType;
    data['translationable_id'] = translationableId;
    data['locale'] = locale;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
