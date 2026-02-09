import 'package:sixam_mart/common/utils/json_parser.dart';

class DeliveryManBody {
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? identityType;
  String? drivingLicenseImage;
  String? driverLicenseImage;
  String? identityNumber;
  String? earning;
  String? zoneId;
  String? vehicleId;

  DeliveryManBody({
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.password,
    this.identityType,
    this.identityNumber,
    this.earning,
    this.zoneId,
    this.driverLicenseImage,
    this.drivingLicenseImage,
    this.vehicleId,
  });

  DeliveryManBody.fromJson(Map<String, dynamic> json) {
    fName = json.parseString('f_name');
    lName = json.parseString('l_name');
    phone = json.parseString('phone');
    email = json.parseString('email');
    password = json.parseString('password');
    identityType = json.parseString('identity_type');
    drivingLicenseImage = json.parseString('driving_license_image');
    driverLicenseImage = json.parseString('driver_license_image');
    identityNumber = json.parseString('identity_number');
    earning = json.parseString('earning');
    zoneId = json.parseString('zone_id');
    vehicleId = json.parseString('vehicle_id');
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    data['f_name'] = fName!;
    data['l_name'] = lName!;
    data['phone'] = phone!;
    data['email'] = email!;
    data['password'] = password!;
    data['identity_type'] = identityType!;
    data['driver_license_image'] = driverLicenseImage!;
    data['driving_license_image'] = drivingLicenseImage!;
    data['identity_number'] = identityNumber!;
    data['earning'] = earning!;
    data['zone_id'] = zoneId!;
    data['vehicle_id'] = vehicleId!;
    return data;
  }
}
