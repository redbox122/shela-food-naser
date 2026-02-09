class VerificationDataModel {
  String? phone;
  String? email;
  String? verificationType;
  String? otp;
  String? loginType;
  String? guestId;

  VerificationDataModel({
    this.phone,
    this.email,
    this.verificationType,
    this.otp,
    this.loginType,
    this.guestId,
  });

  VerificationDataModel.fromJson(Map<String, dynamic> json) {
    phone = json['phone']?.toString();
    email = json['email']?.toString();
    verificationType = json['verification_type']?.toString();
    otp = json['otp']?.toString();
    loginType = json['login_type']?.toString();
    guestId = json['guest_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (phone != null) {
      data['phone'] = phone;
    }
    if (email != null) {
      data['email'] = email;
    }
    data['verification_type'] = verificationType;
    data['otp'] = otp;
    data['login_type'] = loginType;
    if (guestId != null) {
      data['guest_id'] = guestId;
    }
    return data;
  }
}
