import 'package:sixam_mart/common/utils/json_parser.dart';

class AuthResponseModel {
  String? token;
  bool? isPhoneVerified;
  bool? isEmailVerified;
  bool? isPersonalInfo;
  IsExistUser? isExistUser;
  String? loginType;
  String? email;

  AuthResponseModel({
    this.token,
    this.isPhoneVerified,
    this.isEmailVerified,
    this.isPersonalInfo,
    this.isExistUser,
    this.loginType,
    this.email,
  });

  AuthResponseModel.fromJson(Map<String, dynamic> json) {
    token = json.parseString('token');
    isPhoneVerified = json.parseInt('is_phone_verified') == 1;
    isEmailVerified = json.parseInt('is_email_verified') == 1;
    isPersonalInfo = json.parseInt('is_personal_info') == 1;
    final isExistUserMap = json.parseMap('is_exist_user');
    isExistUser = isExistUserMap != null ? IsExistUser.fromJson(isExistUserMap) : null;
    loginType = json.parseString('login_type');
    email = json.parseString('email');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    data['is_phone_verified'] = isPhoneVerified;
    data['is_email_verified'] = isEmailVerified;
    data['is_personal_info'] = isPersonalInfo;
    if (isExistUser != null) {
      data['is_exist_user'] = isExistUser!.toJson();
    }
    data['login_type'] = loginType;
    data['email'] = email;
    return data;
  }
}

class IsExistUser {
  int? id;
  String? name;
  String? image;

  IsExistUser({this.id, this.name, this.image});

  IsExistUser.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json.parseString('name');
    image = json.parseString('image');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    return data;
  }
}
