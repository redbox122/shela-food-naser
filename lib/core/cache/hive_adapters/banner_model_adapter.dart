import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';

/// Hive TypeAdapter for BannerModel
/// Uses JSON serialization internally to handle complex nested structures
class BannerModelAdapter extends TypeAdapter<BannerModel> {
  @override
  final int typeId = 0;

  @override
  BannerModel read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BannerModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, BannerModel obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}

