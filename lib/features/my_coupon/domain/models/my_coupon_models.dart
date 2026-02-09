import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class CouponModel {
  int? id;
  String? title;
  String? code;
  String? startDate;
  String? expireDate;
  double? minPurchase;
  double? maxDiscount;
  double? discount;
  String? discountType;
  String? couponType;
  int? limit;
  String? data;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  Store? store;
  JustTheController? toolTip;

  CouponModel({
    this.id,
    this.title,
    this.code,
    this.startDate,
    this.expireDate,
    this.minPurchase,
    this.maxDiscount,
    this.discount,
    this.discountType,
    this.couponType,
    this.limit,
    this.data,
    this.storeId,
    this.createdAt,
    this.updatedAt,
    this.store,
    this.toolTip,
  });

  CouponModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    title = json.parseString('title');
    code = json.parseString('code');
    startDate = json.parseString('start_date');
    expireDate = json.parseString('expire_date');
    minPurchase = json.parseDouble('min_purchase');
    maxDiscount = json.parseDouble('max_discount');
    discount = json.parseDouble('discount');
    discountType = json.parseString('discount_type');
    couponType = json.parseString('coupon_type');
    limit = json.parseInt('limit');
    data = json.parseString('data');
    storeId = json.parseInt('store_id');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    final Map<String, dynamic>? storeMap = json.parseMap('store');
    if (storeMap != null) {
      store = Store.fromJson(storeMap);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['code'] = code;
    data['start_date'] = startDate;
    data['expire_date'] = expireDate;
    data['min_purchase'] = minPurchase;
    data['max_discount'] = maxDiscount;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['coupon_type'] = couponType;
    data['limit'] = limit;
    data['data'] = this.data;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Store {
  int? id;
  String? name;

  Store({this.id, this.name});

  Store.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json.parseString('name');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}
