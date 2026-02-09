class UpdateProfileResponseModel {
  String? verificationOn;
  String? verificationMedium;
  String? message;

  UpdateProfileResponseModel({this.verificationOn, this.verificationMedium, this.message});

  UpdateProfileResponseModel.fromJson(Map<String, dynamic> json) {
    verificationOn = json['verification_on']?.toString();
    verificationMedium = json['verification_medium']?.toString();
    message = json['message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['verification_on'] = verificationOn;
    data['verification_medium'] = verificationMedium;
    data['message'] = message;
    return data;
  }
}
