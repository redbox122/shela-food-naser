import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';

/// Hive TypeAdapter for BrandModel
/// Uses JSON serialization internally to handle complex nested structures
class BrandModelAdapter extends TypeAdapter<BrandModel> {
  @override
  final int typeId = 4;

  @override
  BrandModel read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BrandModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, BrandModel obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}

/// Hive TypeAdapter for List<BrandModel>
class BrandModelListAdapter extends TypeAdapter<List<BrandModel>> {
  @override
  final int typeId = 5;

  @override
  List<BrandModel> read(BinaryReader reader) {
    final jsonString = reader.readString();
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList.map((json) => BrandModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  void write(BinaryWriter writer, List<BrandModel> obj) {
    final jsonList = obj.map((brand) => brand.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    writer.writeString(jsonString);
  }
}


