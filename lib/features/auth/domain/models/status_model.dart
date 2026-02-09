import 'package:sixam_mart/common/utils/json_parser.dart';

class StatusModel {
  StatusModel({
    required this.success,
    required this.message,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
  });

  final bool? success;
  final String? message;
  final String? name;
  final String? phone;
  final String? email;
  final String? status;

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      success: json.parseBool('success'),
      message: json.parseString('message'),
      name: json.parseString('name'),
      phone: json.parseString('phone'),
      email: json.parseString('email'),
      status: json.parseString('status'),
    );
  }
}
