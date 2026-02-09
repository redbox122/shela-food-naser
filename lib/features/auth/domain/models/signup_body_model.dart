import 'package:sixam_mart/common/utils/json_parser.dart';

class SignUpBodyModel {
  String? name;
  String? phone;
  String? password;

  SignUpBodyModel({
    this.name,
    this.phone,
    this.password,
  });

  SignUpBodyModel.fromJson(Map<String, dynamic> json) {
    name = json.parseString('name');
    phone = json.parseString('phone');
    password = json.parseString('password');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['phone'] = phone;
    data['password'] = password;
    return data;
  }
}
