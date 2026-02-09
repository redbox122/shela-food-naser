import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:sixam_mart/common/models/app_init_model.dart';

/// Hive TypeAdapter for AppInitModel
/// Uses JSON serialization internally to handle complex nested structures
/// ⚡ TASK 3: Created for Hive migration of app-init data
class AppInitModelAdapter extends TypeAdapter<AppInitModel> {
  @override
  final int typeId = 10;  // ✅ Unique typeId (check other adapters to ensure no conflicts)

  @override
  AppInitModel read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppInitModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AppInitModel obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}

