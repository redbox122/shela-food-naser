import 'dart:convert';
import 'package:sixam_mart/common/utils/json_parser.dart';

class StoreBodyModel {
  String? translation;
  String? tax;
  String? tax_cal;
  String? minDeliveryTime;
  String? maxDeliveryTime;
  String? lat;
  String? lng;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? zoneId;
  String? moduleId;
  String? deliveryTimeType;
  String? businessPlan;
  String? packageId;
  List<String>? pickUpZoneIds;

  StoreBodyModel({
    this.translation,
    this.tax,
    this.tax_cal,
    this.minDeliveryTime,
    this.maxDeliveryTime,
    this.lat,
    this.lng,
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.password,
    this.zoneId,
    this.moduleId,
    this.deliveryTimeType,
    this.businessPlan,
    this.packageId,
    this.pickUpZoneIds,
  });

  StoreBodyModel.fromJson(Map<String, dynamic> json) {
    translation = json.parseString('translation');
    tax = json.parseString('tax');
    tax_cal = json.parseString('tax_cal');
    minDeliveryTime = json.parseString('min_delivery_time');
    maxDeliveryTime = json.parseString('max_delivery_time');
    lat = json.parseString('lat');
    lng = json.parseString('lng');
    fName = json.parseString('f_name');
    lName = json.parseString('l_name');
    phone = json.parseString('phone');
    email = json.parseString('email');
    password = json.parseString('password');
    zoneId = json.parseString('zone_id');
    moduleId = json.parseString('module_id');
    deliveryTimeType = json.parseString('delivery_time_type');
    businessPlan = json.parseString('business_plan');
    packageId = json.parseString('package_id');
    pickUpZoneIds = json.parseList<String>('pickup_zone_id', (e) => JsonParser.parseStringOrEmpty(e));
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    data['translations'] = translation!;
    data['tax'] = tax!;
    data['tax_cal'] = tax_cal!;
    data['minimum_delivery_time'] = minDeliveryTime!;
    data['maximum_delivery_time'] = maxDeliveryTime!;
    data['latitude'] = lat!;
    data['longitude'] = lng!;
    data['f_name'] = fName!;
    data['l_name'] = lName!;
    data['phone'] = phone!;
    data['email'] = email!;
    data['password'] = password!;
    data['zone_id'] = zoneId!;
    data['module_id'] = moduleId!;
    data['delivery_time_type'] = deliveryTimeType!;
    data['business_plan'] = businessPlan ?? '';
    data['package_id'] = packageId!;
    if (pickUpZoneIds != null) {
      data['pickup_zone_id'] = json.encode(pickUpZoneIds);
    }
    return data;
  }
}
