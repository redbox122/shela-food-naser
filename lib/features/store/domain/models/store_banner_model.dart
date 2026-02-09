import 'package:sixam_mart/common/utils/json_parser.dart';

class StoreBannerModel {
  int? id;
  String? title;
  String? type;
  String? imageFullUrl;
  bool? status;
  int? data;
  String? createdAt;
  String? updatedAt;
  int? zoneId;
  int? moduleId;
  bool? featured;
  String? defaultLink;
  String? createdBy;

  StoreBannerModel({
    this.id,
    this.title,
    this.type,
    this.imageFullUrl,
    this.status,
    this.data,
    this.createdAt,
    this.updatedAt,
    this.zoneId,
    this.moduleId,
    this.featured,
    this.defaultLink,
    this.createdBy,
  });

  StoreBannerModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    title = json.parseString('title');
    type = json.parseString('type');
    imageFullUrl = json.parseString('image_full_url');
    status = json.parseBool('status');
    data = json.parseInt('data');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    zoneId = json.parseInt('zone_id');
    moduleId = json.parseInt('module_id');
    featured = json.parseBool('featured');
    defaultLink = json['default_link']?.toString();
    createdBy = json['created_by']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['type'] = type;
    data['image_full_url'] = imageFullUrl;
    data['status'] = status;
    data['data'] = data;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['zone_id'] = zoneId;
    data['module_id'] = moduleId;
    data['featured'] = featured;
    data['default_link'] = defaultLink;
    data['created_by'] = createdBy;
    return data;
  }
}