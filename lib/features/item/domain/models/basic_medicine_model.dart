import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class BasicMedicineModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Item>? products;
  List<Categories>? categories;

  BasicMedicineModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.products,
    this.categories,
  });

  BasicMedicineModel.fromJson(Map<String, dynamic> json) {
    totalSize = json.parseInt('total_size');
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
    if (json['products'] != null) {
      products = [];
      json['products'].forEach((v) {
        products!.add(Item.fromJson(v as Map<String, dynamic>));
      });
    }
    if (json['categories'] != null) {
      categories = <Categories>[];
      json['categories'].forEach((v) {
        categories!.add(Categories.fromJson(v as Map<String, dynamic>));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CategoryIds {
  String? id;
  int? position;
  String? name;

  CategoryIds({this.id, this.position, this.name});

  CategoryIds.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    position = json.parseInt('position');
    name = json['name']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['position'] = position;
    data['name'] = name;
    return data;
  }
}

class Unit {
  int? id;
  String? unit;
  String? createdAt;
  String? updatedAt;

  Unit({this.id, this.unit, this.createdAt, this.updatedAt});

  Unit.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    unit = json['unit']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['unit'] = unit;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Module {
  int? id;
  String? moduleName;
  String? moduleType;
  String? thumbnail;
  String? status;
  int? storesCount;
  String? createdAt;
  String? updatedAt;
  String? icon;
  int? themeId;
  String? description;
  int? allZoneService;

  Module({
    this.id,
    this.moduleName,
    this.moduleType,
    this.thumbnail,
    this.status,
    this.storesCount,
    this.createdAt,
    this.updatedAt,
    this.icon,
    this.themeId,
    this.description,
    this.allZoneService,
  });

  Module.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    moduleName = json['module_name']?.toString();
    moduleType = json['module_type']?.toString();
    thumbnail = json['thumbnail']?.toString();
    status = json['status']?.toString();
    // ⚠️ CRITICAL: stores_count and items_count are now COMPLETELY OMITTED from JSON
    // Use null-coalescing to handle missing keys (default to 0)
    storesCount = json.parseInt('stores_count') ?? 0;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    icon = json['icon']?.toString();
    themeId = json.parseInt('theme_id');
    description = json['description']?.toString();
    allZoneService = json.parseInt('all_zone_service');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_name'] = moduleName;
    data['module_type'] = moduleType;
    data['thumbnail'] = thumbnail;
    data['status'] = status;
    data['stores_count'] = storesCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['icon'] = icon;
    data['theme_id'] = themeId;
    data['description'] = description;
    data['all_zone_service'] = allZoneService;
    return data;
  }
}

class Categories {
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
  String? slug;
  int? featured;
  int? productsCount;
  int? childesCount;

  Categories({
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
    this.slug,
    this.featured,
    this.productsCount,
    this.childesCount,
  });

  Categories.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json['name']?.toString();
    image = json['image']?.toString();
    parentId = json.parseInt('parent_id');
    position = json.parseInt('position');
    status = json.parseInt('status');
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    priority = json.parseInt('priority');
    moduleId = json.parseInt('module_id');
    slug = json['slug']?.toString();
    featured = json.parseInt('featured');
    productsCount = json.parseInt('products_count');
    childesCount = json.parseInt('childes_count');
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
    data['slug'] = slug;
    data['featured'] = featured;
    data['products_count'] = productsCount;
    data['childes_count'] = childesCount;
    return data;
  }
}
