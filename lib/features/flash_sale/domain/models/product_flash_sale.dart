import 'package:sixam_mart/features/flash_sale/domain/models/flash_sale_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class ProductFlashSale {
  int? totalSize;
  int? limit;
  int? offset;
  FlashSaleModel? flashSale;
  List<Products>? products;

  ProductFlashSale({
    this.totalSize,
    this.limit,
    this.offset,
    this.flashSale,
    this.products,
  });

  ProductFlashSale.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'] as int?;
    limit =
        json['limit'] != null ? int.tryParse(json['limit'].toString()) : null;
    offset =
        json['offset'] != null ? int.tryParse(json['offset'].toString()) : null;

    flashSale = json['flash_sale'] != null
        ? FlashSaleModel.fromJson(json['flash_sale'] as Map<String, dynamic>)
        : null;

    if (json['products'] != null) {
      products = <Products>[];
      for (final v in (json['products'] as List)) {
        products!.add(Products.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (flashSale != null) {
      data['flash_sale'] = flashSale!.toJson();
    }
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Products {
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

  Products({
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

  Products.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    flashSaleId = json['flash_sale_id'] as int?;
    itemId = json['item_id'] as int?;
    stock = json['stock'] as int?;
    sold = json['sold'] as int?;
    availableStock = json['available_stock'] as int?;
    discountType = json['discount_type'] as String?;
    discount = (json['discount'] as num?)?.toDouble();
    discountAmount = (json['discount_amount'] as num?)?.toDouble();
    price = (json['price'] as num?)?.toDouble();
    status = json['status'] as int?;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
    item = json['item'] != null
        ? Item.fromJson(json['item'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
    id = json['id'] as String?;
    position = json['position'] as int?;
    name = json['name'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['position'] = position;
    data['name'] = name;
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
  List<Translations>? translations;

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
    this.translations,
  });

  Module.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    moduleName = json['module_name'] as String?;
    moduleType = json['module_type'] as String?;
    thumbnail = json['thumbnail'] as String?;
    status = json['status'] as String?;
    storesCount = json['stores_count'] as int? ?? 0;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
    icon = json['icon'] as String?;
    themeId = json['theme_id'] as int?;
    description = json['description'] as String?;
    allZoneService = json['all_zone_service'] as int?;

    if (json['translations'] != null) {
      translations = <Translations>[];
      for (final v in (json['translations'] as List)) {
        translations!.add(Translations.fromJson(v as Map<String, dynamic>));
      }
    }
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
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
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
    id = json['id'] as int?;
    unit = json['unit'] as String?;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
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
