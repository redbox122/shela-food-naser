import 'package:sixam_mart/common/utils/json_parser.dart';

class SocialLogInBody {
  String? email;
  String? token;
  String? uniqueId;
  String? medium;
  String? phone;
  String? deviceToken;
  int? accessToken;        // int?
  String? loginType;
  String? verified;        // String?
  String? guestId;
  String? platform;

  SocialLogInBody({
    this.email,
    this.token,
    this.uniqueId,
    this.medium,
    this.phone,
    this.deviceToken,
    this.accessToken,
    this.loginType,
    this.verified,
    this.guestId,
    this.platform,
  });

  SocialLogInBody.fromJson(Map<String, dynamic> json) {
    email = json.parseString('email');
    token = json.parseString('token');
    uniqueId = json.parseString('unique_id');
    medium = json.parseString('medium');
    phone = json.parseString('phone');
    deviceToken = json.parseString('cm_firebase_token');
    accessToken = json.parseInt('access_token');
    loginType = json.parseString('login_type');
    verified = json.parseString('verified');
    guestId = json.parseString('guest_id');
    platform = json.parseString('platform');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['token'] = token;
    data['unique_id'] = uniqueId;
    data['medium'] = medium;
    data['phone'] = phone;
    data['cm_firebase_token'] = deviceToken;
    if (accessToken != null) data['access_token'] = accessToken;
    data['login_type'] = loginType;
    if (verified != null) data['verified'] = verified;
    if (guestId != null) data['guest_id'] = guestId;
    if (platform != null) data['platform'] = platform;
    return data;
  }
}
