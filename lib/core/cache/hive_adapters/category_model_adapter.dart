import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';

/// Hive TypeAdapter for CategoryModel
/// Uses JSON serialization internally to handle complex nested structures
class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CategoryModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}

/// Hive TypeAdapter for List<CategoryModel>
class CategoryModelListAdapter extends TypeAdapter<List<CategoryModel>> {
  @override
  final int typeId = 2;

  @override
  List<CategoryModel> read(BinaryReader reader) {
    final jsonString = reader.readString();
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  void write(BinaryWriter writer, List<CategoryModel> obj) {
    final jsonList = obj.map((category) => category.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    writer.writeString(jsonString);
  }
}


