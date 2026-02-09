/// Model for recipient validation response
/// Used to verify if a phone number belongs to a registered user
library;
import 'package:sixam_mart/common/utils/json_parser.dart';

class ValidateRecipientResponseModel {
  bool? success;
  ValidatedUser? user;
  String? message;
  String? errorCode;

  ValidateRecipientResponseModel({
    this.success,
    this.user,
    this.message,
    this.errorCode,
  });

  /// Creates instance from JSON response
  ValidateRecipientResponseModel.fromJson(Map<String, dynamic> json) {
    success = json.parseBool('success');
    user = json.parseMap('user') != null ? ValidatedUser.fromJson(json.parseMap('user')!) : null;
    message = json.parseString('message');
    errorCode = json.parseString('error_code');
  }

  /// Converts instance to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['message'] = message;
    data['error_code'] = errorCode;
    return data;
  }
}

/// Validated user information
class ValidatedUser {
  int? id;
  String? name;
  String? phone;
  String? image;
  String? status;

  ValidatedUser({
    this.id,
    this.name,
    this.phone,
    this.image,
    this.status,
  });

  /// Creates instance from JSON response
  ValidatedUser.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json['name']?.toString();
    phone = json['phone']?.toString();
    image = json['image']?.toString();
    status = json['status']?.toString();
  }

  /// Converts instance to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['image'] = image;
    data['status'] = status;
    return data;
  }
}






