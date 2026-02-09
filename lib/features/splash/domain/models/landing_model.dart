import 'package:sixam_mart/common/utils/json_parser.dart';

class LandingModel {
  String? fixedHeaderTitle;
  String? fixedHeaderSubTitle;
  String? fixedHeaderImageFullUrl;
  String? fixedModuleTitle;
  String? fixedModuleSubTitle;
  String? fixedLocationTitle;
  String? joinSellerTitle;
  String? joinSellerSubTitle;
  String? joinSellerButtonName;
  String? joinSellerButtonUrl;
  String? joinDeliveryManTitle;
  String? joinDeliveryManSubTitle;
  String? joinDeliveryManButtonName;
  String? joinDeliveryManButtonUrl;
  String? downloadUserAppTitle;
  String? downloadUserAppSubTitle;
  String? downloadUserAppImageFullUrl;
  List<SpecialCriterias>? specialCriterias;
  DownloadUserAppLinks? downloadUserAppLinks;
  int? availableZoneStatus;
  String? availableZoneTitle;
  String? availableZoneShortDescription;
  String? availableZoneImage;
  String? availableZoneImageFullUrl;
  List<AvailableZoneList>? availableZoneList;
  int? joinSellerStatus;
  int? joinDeliveryManStatus;

  LandingModel({
    this.fixedHeaderTitle,
    this.fixedHeaderSubTitle,
    this.fixedHeaderImageFullUrl,
    this.fixedModuleTitle,
    this.fixedModuleSubTitle,
    this.fixedLocationTitle,
    this.joinSellerTitle,
    this.joinSellerSubTitle,
    this.joinSellerButtonName,
    this.joinSellerButtonUrl,
    this.joinDeliveryManTitle,
    this.joinDeliveryManSubTitle,
    this.joinDeliveryManButtonName,
    this.joinDeliveryManButtonUrl,
    this.downloadUserAppTitle,
    this.downloadUserAppSubTitle,
    this.downloadUserAppImageFullUrl,
    this.specialCriterias,
    this.downloadUserAppLinks,
    this.availableZoneStatus,
    this.availableZoneTitle,
    this.availableZoneShortDescription,
    this.availableZoneImage,
    this.availableZoneImageFullUrl,
    this.availableZoneList,
    this.joinSellerStatus,
    this.joinDeliveryManStatus,
  });

  LandingModel.fromJson(Map<String, dynamic> json) {
    fixedHeaderTitle = json['fixed_header_title']?.toString();
    fixedHeaderSubTitle = json['fixed_header_sub_title']?.toString();
    fixedHeaderImageFullUrl = json['fixed_header_image_full_url']?.toString();
    fixedModuleTitle = json['fixed_module_title']?.toString();
    fixedModuleSubTitle = json['fixed_module_sub_title']?.toString();
    fixedLocationTitle = json['fixed_location_title']?.toString();
    joinSellerTitle = json['join_seller_title']?.toString();
    joinSellerSubTitle = json['join_seller_sub_title']?.toString();
    joinSellerButtonName = json['join_seller_button_name']?.toString();
    joinSellerButtonUrl = json['join_seller_button_url']?.toString();
    joinDeliveryManTitle = json['join_delivery_man_title']?.toString();
    joinDeliveryManSubTitle = json['join_delivery_man_sub_title']?.toString();
    joinDeliveryManButtonName = json['join_delivery_man_button_name']?.toString();
    joinDeliveryManButtonUrl = json['join_delivery_man_button_url']?.toString();
    downloadUserAppTitle = json['download_user_app_title']?.toString();
    downloadUserAppSubTitle = json['download_user_app_sub_title']?.toString();
    downloadUserAppImageFullUrl = json['download_user_app_image_full_url']?.toString();
    if (json['special_criterias'] != null) {
      specialCriterias = <SpecialCriterias>[];
      for (var v in (json['special_criterias'] as List)) {
        specialCriterias!.add(SpecialCriterias.fromJson(v as Map<String, dynamic>));
      }
    }
    downloadUserAppLinks = json['download_user_app_links'] != null ? DownloadUserAppLinks.fromJson(json['download_user_app_links'] as Map<String, dynamic>) : null;
    availableZoneStatus = json.parseInt('available_zone_status');
    availableZoneTitle = json['available_zone_title']?.toString();
    availableZoneShortDescription = json['available_zone_short_description']?.toString();
    availableZoneImage = json['available_zone_image']?.toString();
    availableZoneImageFullUrl = json['available_zone_image_full_url']?.toString();
    if (json['available_zone_list'] != null) {
      availableZoneList = <AvailableZoneList>[];
      for (var v in (json['available_zone_list'] as List)) {
        availableZoneList!.add(AvailableZoneList.fromJson(v as Map<String, dynamic>));
      }
    }
    joinSellerStatus = json.parseInt('join_seller_status');
    joinDeliveryManStatus = json.parseInt('join_delivery_man_status');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fixed_header_title'] = fixedHeaderTitle;
    data['fixed_header_sub_title'] = fixedHeaderSubTitle;
    data['fixed_header_image_full_url'] = fixedHeaderImageFullUrl;
    data['fixed_module_title'] = fixedModuleTitle;
    data['fixed_module_sub_title'] = fixedModuleSubTitle;
    data['fixed_location_title'] = fixedLocationTitle;
    data['join_seller_title'] = joinSellerTitle;
    data['join_seller_sub_title'] = joinSellerSubTitle;
    data['join_seller_button_name'] = joinSellerButtonName;
    data['join_seller_button_url'] = joinSellerButtonUrl;
    data['join_delivery_man_title'] = joinDeliveryManTitle;
    data['join_delivery_man_sub_title'] = joinDeliveryManSubTitle;
    data['join_delivery_man_button_name'] = joinDeliveryManButtonName;
    data['join_delivery_man_button_url'] = joinDeliveryManButtonUrl;
    data['download_user_app_title'] = downloadUserAppTitle;
    data['download_user_app_sub_title'] = downloadUserAppSubTitle;
    data['download_user_app_image_full_url'] = downloadUserAppImageFullUrl;
    if (specialCriterias != null) {
      data['special_criterias'] = specialCriterias!.map((v) => v.toJson()).toList();
    }
    if (downloadUserAppLinks != null) {
      data['download_user_app_links'] = downloadUserAppLinks!.toJson();
    }
    data['available_zone_status'] = availableZoneStatus;
    data['available_zone_title'] = availableZoneTitle;
    data['available_zone_short_description'] = availableZoneShortDescription;
    data['available_zone_image'] = availableZoneImage;
    data['available_zone_image_full_url'] = availableZoneImageFullUrl;
    if (availableZoneList != null) {
      data['available_zone_list'] = availableZoneList!.map((v) => v.toJson()).toList();
    }
    data['join_seller_status'] = joinSellerStatus;
    data['join_delivery_man_status'] = joinDeliveryManStatus;
    return data;
  }
}

class SpecialCriterias {
  int? id;
  String? title;
  String? imageFullUrl;
  int? status;
  String? createdAt;
  String? updatedAt;
  List<Translations>? translations;

  SpecialCriterias({
    this.id,
    this.title,
    this.imageFullUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.translations,
  });

  SpecialCriterias.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    title = json['title']?.toString();
    imageFullUrl = json['image_full_url']?.toString();
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
    data['title'] = title;
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

class DownloadUserAppLinks {
  String? playstoreUrlStatus;
  String? playstoreUrl;
  String? appleStoreUrlStatus;
  String? appleStoreUrl;

  DownloadUserAppLinks({
    this.playstoreUrlStatus,
    this.playstoreUrl,
    this.appleStoreUrlStatus,
    this.appleStoreUrl,
  });

  DownloadUserAppLinks.fromJson(Map<String, dynamic> json) {
    playstoreUrlStatus = json['playstore_url_status']?.toString();
    playstoreUrl = json['playstore_url']?.toString();
    appleStoreUrlStatus = json['apple_store_url_status']?.toString();
    appleStoreUrl = json['apple_store_url']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['playstore_url_status'] = playstoreUrlStatus;
    data['playstore_url'] = playstoreUrl;
    data['apple_store_url_status'] = appleStoreUrlStatus;
    data['apple_store_url'] = appleStoreUrl;
    return data;
  }
}

class AvailableZoneList {
  int? id;
  String? name;
  String? displayName;
  List<String>? modules;

  AvailableZoneList({this.id, this.name, this.displayName, this.modules});

  AvailableZoneList.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json['name']?.toString();
    displayName = json['display_name']?.toString();
    modules = (json['modules'] as List?)?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['display_name'] = displayName;
    data['modules'] = modules;
    return data;
  }
}