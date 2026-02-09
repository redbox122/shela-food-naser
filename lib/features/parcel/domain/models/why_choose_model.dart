import 'package:sixam_mart/common/utils/json_parser.dart';

class WhyChooseModel {
  String? whyChooseUrl;
  String? whyChooses3Url;
  List<Banners>? banners;

  WhyChooseModel({
    this.whyChooseUrl,
    this.whyChooses3Url,
    this.banners,
  });

  WhyChooseModel.fromJson(Map<String, dynamic> json) {
    whyChooseUrl = json['why_choose_url']?.toString();
    whyChooses3Url = json['why_choose_s3_url']?.toString();
    if (json['banners'] != null) {
      banners = <Banners>[];
      for (var v in (json['banners'] as List)) {
        banners!.add(Banners.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['why_choose_url'] = whyChooseUrl;
    data['why_choose_s3_url'] = whyChooses3Url;
    if (banners != null) {
      data['banners'] = banners!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Banners {
  int? id;
  int? moduleId;
  String? title;
  String? shortDescription;
  String? imageFullUrl;
  int? status;
  String? createdAt;
  String? updatedAt;
  List<Translations>? translations;

  Banners({
    this.id,
    this.moduleId,
    this.title,
    this.shortDescription,
    this.imageFullUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.translations,
  });

  Banners.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    moduleId = json.parseInt('module_id');
    title = json.parseString('title');
    shortDescription = json.parseString('short_description');
    imageFullUrl = json.parseString('image_full_url');
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
    data['title'] = title;
    data['short_description'] = shortDescription;
    data['image_full_url'] = imageFullUrl;
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
