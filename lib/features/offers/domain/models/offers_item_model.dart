import 'package:sixam_mart/common/utils/json_parser.dart';

class OffersItemsResponse {
  Map<String, List<OffersItemModel>>? items;

  OffersItemsResponse({this.items});

  factory OffersItemsResponse.fromJson(Map<String, dynamic> json) {
    return OffersItemsResponse(
      items: json['items'] != null
          ? (json['items'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
          key,
          (value as List)
              .map((e) => OffersItemModel.fromJson((e ?? {}) as Map<String, dynamic>))
              .toList(),
        ),
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items?.map(
            (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
    };
  }
}

class OffersItemModel {
  int? id;
  String? name;
  String? description;
  String? image;
  int? categoryId;
  int? brandId;
  String? categoryIds;
  String? variations;
  String? addOns;
  String? attributes;
  String? choiceOptions;
  double? pMargin;
  double? cost;
  double? price;
  bool? catExclude;
  bool? storeExclude;
  double? tax;
  int? taxClassId;
  int? profitClassId;
  String? taxCal;
  String? taxType;
  double? discount;
  String? discountType;
  String? availableTimeStarts;
  String? availableTimeEnds;
  int? veg;
  int? status;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  int? orderCount;
  double? avgRating;
  int? ratingCount;
  double? rating;
  int? moduleId;
  String? itemSiteId;
  int? stock;
  int? unitId;
  List<ImageData>? images;
  String? foodVariations;
  String? slug;
  int? recommended;
  int? organic;
  int? maximumCartQuantity;
  int? isApproved;
  int? isHalal;
  String? itemCode;
  String? storeSiteId;
  String? unitType;
  String? imageFullUrl;
  List<String>? imagesFullUrl;
  OffersCategory? category;
  List<StorageData>? storage;
  List<dynamic>? translations;
  Pivot? pivot;
  OffersUnit? unit;

  OffersItemModel({
    this.id,
    this.name,
    this.description,
    this.image,
    this.categoryId,
    this.brandId,
    this.categoryIds,
    this.variations,
    this.addOns,
    this.attributes,
    this.choiceOptions,
    this.pMargin,
    this.cost,
    this.price,
    this.catExclude,
    this.storeExclude,
    this.tax,
    this.taxClassId,
    this.profitClassId,
    this.taxCal,
    this.taxType,
    this.discount,
    this.discountType,
    this.availableTimeStarts,
    this.availableTimeEnds,
    this.veg,
    this.status,
    this.storeId,
    this.createdAt,
    this.updatedAt,
    this.orderCount,
    this.avgRating,
    this.ratingCount,
    this.rating,
    this.moduleId,
    this.itemSiteId,
    this.stock,
    this.unitId,
    this.images,
    this.foodVariations,
    this.slug,
    this.recommended,
    this.organic,
    this.maximumCartQuantity,
    this.isApproved,
    this.isHalal,
    this.itemCode,
    this.storeSiteId,
    this.unitType,
    this.imageFullUrl,
    this.imagesFullUrl,
    this.category,
    this.storage,
    this.translations,
    this.pivot,
    this.unit,
  });

  factory OffersItemModel.fromJson(Map<String, dynamic> json) {
    return OffersItemModel(
      id: json.parseInt('id'),
      name: json.parseString('name'),
      description: json.parseString('description'),
      image: json.parseString('image'),
      categoryId: json.parseInt('category_id'),
      brandId: json.parseInt('brand_id'),
      categoryIds: json.parseString('category_ids'),
      variations: json.parseString('variations'),
      addOns: json.parseString('add_ons'),
      attributes: json.parseString('attributes'),
      choiceOptions: json.parseString('choice_options'),
      pMargin: json.parseDouble('p_margin'),
      cost: json.parseDouble('cost'),
      price: json.parseDouble('price'),
      catExclude: json.parseBool('cat_exclude') ? true : null,
      storeExclude: json.parseBool('store_exclude') ? true : null,
      tax: json.parseDouble('tax'),
      taxClassId: json.parseInt('tax_class_id'),
      profitClassId: json.parseInt('profit_class_id'),
      taxCal: json.parseString('tax_cal'),
      taxType: json.parseString('tax_type'),
      discount: json.parseDouble('discount'),
      discountType: json.parseString('discount_type'),
      availableTimeStarts: json.parseString('available_time_starts'),
      availableTimeEnds: json.parseString('available_time_ends'),
      veg: json.parseInt('veg'),
      status: json.parseInt('status'),
      storeId: json.parseInt('store_id'),
      createdAt: json.parseString('created_at'),
      updatedAt: json.parseString('updated_at'),
      orderCount: json.parseInt('order_count'),
      avgRating: json.parseDouble('avg_rating'),
      ratingCount: json.parseInt('rating_count'),
      rating: json.parseDouble('rating'),
      moduleId: json.parseInt('module_id'),
      itemSiteId: json.parseString('item_site_id'),
      stock: json.parseInt('stock'),
      unitId: json.parseInt('unit_id'),
      images: (json['images'] as List?)
          ?.map((e) => ImageData.fromJson((e ?? {}) as Map<String, dynamic>))
          .toList(),
      foodVariations: json.parseString('food_variations'),
      slug: json.parseString('slug'),
      recommended: json.parseInt('recommended'),
      organic: json.parseInt('organic'),
      maximumCartQuantity: json.parseInt('maximum_cart_quantity'),
      isApproved: json.parseInt('is_approved'),
      isHalal: json.parseInt('is_halal'),
      itemCode: json.parseString('item_code'),
      storeSiteId: json.parseString('store_site_id'),
      unitType: json.parseString('unit_type'),
      imageFullUrl: json.parseString('image_full_url'),
      imagesFullUrl:
      (json['images_full_url'] as List?)?.map((e) => e.toString()).toList(),
      category: json['category'] != null
          ? OffersCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      storage: (json['storage'] as List?)
          ?.map((e) => StorageData.fromJson((e ?? {}) as Map<String, dynamic>))
          .toList(),
      translations: json['translations'] as List<dynamic>?,
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot'] as Map<String, dynamic>) : null,
      unit: json['unit'] != null ? OffersUnit.fromJson(json['unit'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'category_id': categoryId,
      'brand_id': brandId,
      'category_ids': categoryIds,
      'variations': variations,
      'add_ons': addOns,
      'attributes': attributes,
      'choice_options': choiceOptions,
      'p_margin': pMargin,
      'cost': cost,
      'price': price,
      'cat_exclude': catExclude,
      'store_exclude': storeExclude,
      'tax': tax,
      'tax_class_id': taxClassId,
      'profit_class_id': profitClassId,
      'tax_cal': taxCal,
      'tax_type': taxType,
      'discount': discount,
      'discount_type': discountType,
      'available_time_starts': availableTimeStarts,
      'available_time_ends': availableTimeEnds,
      'veg': veg,
      'status': status,
      'store_id': storeId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'order_count': orderCount,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
      'rating': rating,
      'module_id': moduleId,
      'item_site_id': itemSiteId,
      'stock': stock,
      'unit_id': unitId,
      'images': images?.map((e) => e.toJson()).toList(),
      'food_variations': foodVariations,
      'slug': slug,
      'recommended': recommended,
      'organic': organic,
      'maximum_cart_quantity': maximumCartQuantity,
      'is_approved': isApproved,
      'is_halal': isHalal,
      'item_code': itemCode,
      'store_site_id': storeSiteId,
      'unit_type': unitType,
      'image_full_url': imageFullUrl,
      'images_full_url': imagesFullUrl,
      'category': category?.toJson(),
      'storage': storage?.map((e) => e.toJson()).toList(),
      'translations': translations,
      'pivot': pivot?.toJson(),
      'unit': unit?.toJson(),
    };
  }
}

class ImageData {
  String? img;
  String? storage;

  ImageData({this.img, this.storage});

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      img: json.parseString('img'),
      storage: json.parseString('storage'),
    );
  }

  Map<String, dynamic> toJson() => {
    'img': img,
    'storage': storage,
  };
}

class OffersCategory {
  int? id;
  int? storeId;
  String? name;
  String? image;
  int? parentId;
  int? position;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? priority;
  int? moduleId;
  String? catSiteId;
  String? slug;
  int? featured;
  String? imageFullUrl;
  List<StorageData>? storage;
  List<dynamic>? translations;

  OffersCategory({
    this.id,
    this.storeId,
    this.name,
    this.image,
    this.parentId,
    this.position,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.priority,
    this.moduleId,
    this.catSiteId,
    this.slug,
    this.featured,
    this.imageFullUrl,
    this.storage,
    this.translations,
  });

  factory OffersCategory.fromJson(Map<String, dynamic> json) {
    return OffersCategory(
      id: json.parseInt('id'),
      storeId: json.parseInt('store_id'),
      name: json.parseString('name'),
      image: json.parseString('image'),
      parentId: json.parseInt('parent_id'),
      position: json.parseInt('position'),
      status: json.parseInt('status'),
      createdAt: json.parseString('created_at'),
      updatedAt: json.parseString('updated_at'),
      priority: json.parseInt('priority'),
      moduleId: json.parseInt('module_id'),
      catSiteId: json.parseString('cat_site_id'),
      slug: json.parseString('slug'),
      featured: json.parseInt('featured'),
      imageFullUrl: json.parseString('image_full_url'),
      storage: (json['storage'] as List?)
          ?.map((e) => StorageData.fromJson((e ?? {}) as Map<String, dynamic>))
          .toList(),
      translations: json['translations'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'store_id': storeId,
    'name': name,
    'image': image,
    'parent_id': parentId,
    'position': position,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'priority': priority,
    'module_id': moduleId,
    'cat_site_id': catSiteId,
    'slug': slug,
    'featured': featured,
    'image_full_url': imageFullUrl,
    'storage': storage?.map((e) => e.toJson()).toList(),
    'translations': translations,
  };
}

class StorageData {
  int? id;
  String? dataType;
  String? dataId;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  StorageData({
    this.id,
    this.dataType,
    this.dataId,
    this.key,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  factory StorageData.fromJson(Map<String, dynamic> json) {
    return StorageData(
      id: json.parseInt('id'),
      dataType: json.parseString('data_type'),
      dataId: json.parseString('data_id'),
      key: json.parseString('key'),
      value: json.parseString('value'),
      createdAt: json.parseString('created_at'),
      updatedAt: json.parseString('updated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'data_type': dataType,
    'data_id': dataId,
    'key': key,
    'value': value,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class Pivot {
  int? offerId;
  int? itemId;
  String? createdAt;
  String? updatedAt;

  Pivot({this.offerId, this.itemId, this.createdAt, this.updatedAt});

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      offerId: json.parseInt('offer_id'),
      itemId: json.parseInt('item_id'),
      createdAt: json.parseString('created_at'),
      updatedAt: json.parseString('updated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'offer_id': offerId,
    'item_id': itemId,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class OffersUnit {
  int? id;
  String? unit;
  String? createdAt;
  String? updatedAt;
  List<dynamic>? translations;

  OffersUnit({this.id, this.unit, this.createdAt, this.updatedAt, this.translations});

  factory OffersUnit.fromJson(Map<String, dynamic> json) {
    return OffersUnit(
      id: json.parseInt('id'),
      unit: json.parseString('unit'),
      createdAt: json.parseString('created_at'),
      updatedAt: json.parseString('updated_at'),
      translations: json['translations'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'unit': unit,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'translations': translations,
  };
}
