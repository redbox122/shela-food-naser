import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class FlashSaleModel {
  int? id;
  int? moduleId;
  String? title;
  int? isPublish;
  int? adminDiscountPercentage;
  int? vendorDiscountPercentage;
  String? startDate;
  String? endDate;
  String? createdAt;
  String? updatedAt;
  List<ActiveProducts>? activeProducts;
  List<Translations>? translations;

  FlashSaleModel({
    this.id,
    this.moduleId,
    this.title,
    this.isPublish,
    this.adminDiscountPercentage,
    this.vendorDiscountPercentage,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.activeProducts,
    this.translations,
  });

  FlashSaleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    moduleId = json['module_id'] as int?;
    title = json['title']?.toString();
    isPublish = json['is_publish'] as int?;
    adminDiscountPercentage = json['admin_discount_percentage'] as int?;
    vendorDiscountPercentage = json['vendor_discount_percentage'] as int?;
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();

    if (json['active_products'] is List) {
      activeProducts = (json['active_products'] as List)
          .map((v) => ActiveProducts.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    if (json['translations'] is List) {
      translations = (json['translations'] as List)
          .map((v) => Translations.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['module_id'] = moduleId;
    data['title'] = title;
    data['is_publish'] = isPublish;
    data['admin_discount_percentage'] = adminDiscountPercentage;
    data['vendor_discount_percentage'] = vendorDiscountPercentage;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (activeProducts != null) {
      data['active_products'] =
          activeProducts!.map((v) => v.toJson()).toList();
    }
    if (translations != null) {
      data['translations'] =
          translations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ActiveProducts {
  int? id;
  int? flashSaleId;
  int? itemId;
  int? stock;
  int? sold;
  int? availableStock;
  String? discountType;
  double? discount;
  double? discountAmount;
  double? price;
  int? status;
  String? createdAt;
  String? updatedAt;
  Item? item;

  ActiveProducts({
    this.id,
    this.flashSaleId,
    this.itemId,
    this.stock,
    this.sold,
    this.availableStock,
    this.discountType,
    this.discount,
    this.discountAmount,
    this.price,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.item,
  });

  ActiveProducts.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    flashSaleId = json['flash_sale_id'] as int?;
    itemId = json['item_id'] as int?;
    stock = json['stock'] as int?;
    sold = json['sold'] as int?;
    availableStock = json['available_stock'] as int?;
    discountType = json['discount_type']?.toString();
    discount = (json['discount'] as num?)?.toDouble();
    discountAmount = (json['discount_amount'] as num?)?.toDouble();
    price = (json['price'] as num?)?.toDouble();
    status = json['status'] as int?;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    item = json['item'] is Map
        ? Item.fromJson(json['item'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['flash_sale_id'] = flashSaleId;
    data['item_id'] = itemId;
    data['stock'] = stock;
    data['sold'] = sold;
    data['available_stock'] = availableStock;
    data['discount_type'] = discountType;
    data['discount'] = discount;
    data['discount_amount'] = discountAmount;
    data['price'] = price;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (item != null) {
      data['item'] = item!.toJson();
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
    position = json['position'] as int?;
    name = json['name']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'name': name,
    };
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
    id = json['id'] as int?;
    translationableType = json['translationable_type']?.toString();
    translationableId = json['translationable_id'] as int?;
    locale = json['locale']?.toString();
    key = json['key']?.toString();
    value = json['value']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'translationable_type': translationableType,
      'translationable_id': translationableId,
      'locale': locale,
      'key': key,
      'value': value,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
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
  List<Translations>? translations;

  Module.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    moduleName = json['module_name']?.toString();
    moduleType = json['module_type']?.toString();
    thumbnail = json['thumbnail']?.toString();
    status = json['status']?.toString();
    storesCount = json['stores_count'] as int? ?? 0;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    icon = json['icon']?.toString();
    themeId = json['theme_id'] as int?;
    description = json['description']?.toString();
    allZoneService = json['all_zone_service'] as int?;

    if (json['translations'] is List) {
      translations = (json['translations'] as List)
          .map((v) => Translations.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_name': moduleName,
      'module_type': moduleType,
      'thumbnail': thumbnail,
      'status': status,
      'stores_count': storesCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'icon': icon,
      'theme_id': themeId,
      'description': description,
      'all_zone_service': allZoneService,
      if (translations != null)
        'translations': translations!.map((v) => v.toJson()).toList(),
    };
  }
}

class Unit {
  int? id;
  String? unit;
  String? createdAt;
  String? updatedAt;

  Unit.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    unit = json['unit']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit': unit,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
