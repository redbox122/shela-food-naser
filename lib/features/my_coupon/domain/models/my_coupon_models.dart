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
  /// Backend module this coupon belongs to (module_id). Null = not module-scoped.
  int? moduleId;
  /// Backend active flag (status). 1 = active. Null = unknown (treat as active).
  int? status;
  String? createdAt;
  String? updatedAt;
  /// Backend: successful order with this coupon by current user (not canceled/refunded).
  bool isUsed;
  int? usedOrderId;
  String? usedOrderStatus;
  String? usedPaymentStatus;
  String? usedAt;
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
    this.moduleId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isUsed = false,
    this.usedOrderId,
    this.usedOrderStatus,
    this.usedPaymentStatus,
    this.usedAt,
    this.store,
    this.toolTip,
  });

  CouponModel.fromJson(Map<String, dynamic> json) : isUsed = false {
    id = json.parseInt('id');
    title = json.parseString('title');
    code = json.parseString('code');
    startDate = json.parseString('start_date') ?? json.parseString('startDate');
    expireDate =
        json.parseString('expire_date') ?? json.parseString('expireDate');
    minPurchase = json.parseDouble('min_purchase');
    maxDiscount = json.parseDouble('max_discount');
    discount = json.parseDouble('discount');
    discountType =
        json.parseString('discount_type') ?? json.parseString('discountType');
    couponType =
        json.parseString('coupon_type') ?? json.parseString('couponType');
    limit = json.parseInt('limit');
    data = json.parseString('data');
    storeId = json.parseInt('store_id');
    moduleId = json.parseInt('module_id') ?? json.parseInt('moduleId');
    status = json.parseInt('status');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    final Map<String, dynamic>? storeMap = json.parseMap('store');
    if (storeMap != null) {
      store = Store.fromJson(storeMap);
    }
    isUsed = _parseJsonBool(json['is_used'] ?? json['isUsed']);
    usedOrderId =
        json.parseInt('used_order_id') ?? json.parseInt('usedOrderId');
    usedOrderStatus = json.parseString('used_order_status') ??
        json.parseString('usedOrderStatus');
    usedPaymentStatus = json.parseString('used_payment_status') ??
        json.parseString('usedPaymentStatus');
    usedAt = json.parseString('used_at') ?? json.parseString('usedAt');
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
    data['module_id'] = moduleId;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_used'] = isUsed;
    data['used_order_id'] = usedOrderId;
    data['used_order_status'] = usedOrderStatus;
    data['used_payment_status'] = usedPaymentStatus;
    data['used_at'] = usedAt;
    return data;
  }
}

bool _parseJsonBool(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String s = value.trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }
  return false;
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
