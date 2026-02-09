/// Store subcategory samples model
/// 
/// Represents the response from:
/// GET /api/v1/stores/{store_id}/categories/{category_id}/subcategories-with-samples
/// 
/// This is used to show subcategories with a small set of sample items per subcategory.
library;
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class StoreSubcategorySamplesModel {
  final int totalSize;
  final int limit;
  final int offset;
  final List<StoreSubcategorySample> subcategories;

  StoreSubcategorySamplesModel({
    required this.totalSize,
    required this.limit,
    required this.offset,
    required this.subcategories,
  });

  factory StoreSubcategorySamplesModel.fromJson(Map<String, dynamic> json) {
    final int totalSize =
        json['total_size'] is int ? json['total_size'] as int : int.tryParse('${json['total_size']}') ?? 0;
    final int limit =
        json['limit'] is int ? json['limit'] as int : int.tryParse('${json['limit']}') ?? 0;
    final int offset =
        json['offset'] is int ? json['offset'] as int : int.tryParse('${json['offset']}') ?? 0;

    final List<dynamic> rawSubcategories = (json['subcategories'] as List?) ?? <dynamic>[];
    final List<StoreSubcategorySample> subcategories = rawSubcategories
        .whereType<Map<String, dynamic>>()
        .map((dynamic v) => StoreSubcategorySample.fromJson(v as Map<String, dynamic>))
        .toList();

    return StoreSubcategorySamplesModel(
      totalSize: totalSize,
      limit: limit,
      offset: offset,
      subcategories: subcategories,
    );
  }
}

class StoreSubcategorySample {
  final int id;
  final String? name;
  final String? image;
  final int productsCount;
  final List<Item> sampleItems;

  StoreSubcategorySample({
    required this.id,
    required this.name,
    required this.image,
    required this.productsCount,
    required this.sampleItems,
  });

  factory StoreSubcategorySample.fromJson(Map<String, dynamic> json) {
    final int id = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;
    final String? name = json['name']?.toString();
    final String? image = json['image']?.toString();
    final int productsCount = json['products_count'] is int
        ? json['products_count'] as int
        : int.tryParse('${json['products_count']}') ?? 0;

    final List<dynamic> rawItems = (json['sample_items'] as List?) ?? <dynamic>[];
    final List<Item> items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((dynamic v) => Item.fromJson(v as Map<String, dynamic>))
        .toList();

    return StoreSubcategorySample(
      id: id,
      name: name,
      image: image,
      productsCount: productsCount,
      sampleItems: items,
    );
  }
}



