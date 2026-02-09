import 'package:sixam_mart/common/utils/json_parser.dart';

class PopularCategoryModel {
  int? id;
  String? name;
  String? image;
  int? parentId;
  int? position;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? priority;
  int? moduleId;
  int? featured;
  String? imageFullUrl;

  PopularCategoryModel({
    this.id,
    this.name,
    this.image,
    this.parentId,
    this.position,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.priority,
    this.moduleId,
    this.featured,
    this.imageFullUrl,
  });

  PopularCategoryModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json.parseString('name');
    image = json.parseString('image');
    parentId = json.parseInt('parent_id');
    position = json.parseInt('position');
    status = json.parseInt('status');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    priority = json.parseInt('priority');
    moduleId = json.parseInt('module_id');
    featured = json.parseInt('featured');
    imageFullUrl = json['image_full_url']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['parent_id'] = parentId;
    data['position'] = position;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['priority'] = priority;
    data['module_id'] = moduleId;
    data['featured'] = featured;
    data['image_full_url'] = imageFullUrl;
    return data;
  }
}