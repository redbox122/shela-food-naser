import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';

/// Hive TypeAdapter for BusinessSettingsModel
/// Uses JSON serialization internally to handle complex nested structures
class BusinessSettingsModelAdapter extends TypeAdapter<BusinessSettingsModel> {
  @override
  final int typeId = 7;

  @override
  BusinessSettingsModel read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BusinessSettingsModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, BusinessSettingsModel obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}


