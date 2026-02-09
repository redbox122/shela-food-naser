import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

/// Hive TypeAdapter for StoreModel
/// Uses JSON serialization internally to handle complex nested structures
class StoreModelAdapter extends TypeAdapter<StoreModel> {
  @override
  final int typeId = 3;

  @override
  StoreModel read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return StoreModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, StoreModel obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}

