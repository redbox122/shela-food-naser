import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';

/// Hive Isolate Helper
/// Performs heavy JSON serialization/deserialization in isolates to avoid blocking main thread
class HiveIsolateHelper {
  /// Serialize categories to JSON string in isolate
  /// Returns JSON string that can be stored in Hive
  static Future<String> serializeCategories(List<CategoryModel> categories) async {
    return await compute(_serializeCategoriesIsolate, categories);
  }

  /// Internal isolate function for category serialization
  static String _serializeCategoriesIsolate(List<CategoryModel> categories) {
    try {
      return jsonEncode(categories.map((c) => c.toJson()).toList());
    } catch (e) {
      throw Exception('Failed to serialize categories: $e');
    }
  }

  /// Deserialize categories from JSON string in isolate
  /// Returns List<CategoryModel> from JSON string stored in Hive
  static Future<List<CategoryModel>> deserializeCategories(String jsonString) async {
    return await compute(_deserializeCategoriesIsolate, jsonString);
  }

  /// Internal isolate function for category deserialization
  static List<CategoryModel> _deserializeCategoriesIsolate(String jsonString) {
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to deserialize categories: $e');
    }
  }

  /// Serialize brands to JSON string in isolate
  /// Returns JSON string that can be stored in Hive
  static Future<String> serializeBrands(List<BrandModel> brands) async {
    return await compute(_serializeBrandsIsolate, brands);
  }

  /// Internal isolate function for brand serialization
  static String _serializeBrandsIsolate(List<BrandModel> brands) {
    try {
      return jsonEncode(brands.map((b) => b.toJson()).toList());
    } catch (e) {
      throw Exception('Failed to serialize brands: $e');
    }
  }

  /// Deserialize brands from JSON string in isolate
  /// Returns List<BrandModel> from JSON string stored in Hive
  static Future<List<BrandModel>> deserializeBrands(String jsonString) async {
    return await compute(_deserializeBrandsIsolate, jsonString);
  }

  /// Internal isolate function for brand deserialization
  static List<BrandModel> _deserializeBrandsIsolate(String jsonString) {
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to deserialize brands: $e');
    }
  }
}

