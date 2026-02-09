import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';

/// Hive TypeAdapter for OffersModel
/// Uses JSON serialization internally to handle complex nested structures
class OffersModelAdapter extends TypeAdapter<OffersModel> {
  @override
  final int typeId = 6;

  @override
  OffersModel read(BinaryReader reader) {
    final jsonString = reader.readString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return OffersModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, OffersModel obj) {
    final jsonString = jsonEncode(obj.toJson());
    writer.writeString(jsonString);
  }
}


