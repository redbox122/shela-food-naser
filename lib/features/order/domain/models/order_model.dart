import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class PaginatedOrderModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<OrderModel>? orders;

  PaginatedOrderModel({this.totalSize, this.limit, this.offset, this.orders});

  PaginatedOrderModel.fromJson(Map<String, dynamic> json) {
    totalSize = json.parseInt('total_size');
    limit = json.parseStringOrEmpty('limit');
    offset = json.parseInt('offset');
    orders = json.parseList<OrderModel>('orders', (v) => OrderModel.fromJson(v as Map<String, dynamic>));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (orders != null) {
      data['orders'] = orders!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class OrderModel {
  int? id;
  int? userId;
  double? orderAmount;
  double? couponDiscountAmount;
  String? couponDiscountTitle;
  String? paymentStatus;
  String? orderStatus;
  double? totalTaxAmount;
  String? paymentMethod;
  String? couponCode;
  String? orderNote;
  String? orderType;
  String? createdAt;
  String? updatedAt;
  double? deliveryCharge;
  String? scheduleAt;
  String? otp;
  String? pending;
  String? accepted;
  String? confirmed;
  String? processing;
  String? handover;
  String? pickedUp;
  String? delivered;
  String? canceled;
  String? refundRequested;
  String? refunded;
  int? scheduled;
  double? storeDiscountAmount;
  String? failed;
  int? detailsCount;
  List<String?>? orderAttachmentFullUrl;
  String? chargePayer;
  String? moduleType;
  DeliveryMan? deliveryMan;
  Store? store;
  AddressModel? deliveryAddress;
  AddressModel? receiverDetails;
  ParcelCategoryModel? parcelCategory;
  double? dmTips;
  String? refundCancellationNote;
  String? refundCustomerNote;
  Refund? refund;
  bool? prescriptionOrder;
  bool? taxStatus;
  String? cancellationReason;
  int? processingTime;
  bool? cutlery;
  String? unavailableItemNote;
  String? deliveryInstruction;
  double? taxPercentage;
  double? additionalCharge;
  double? originalDeliveryCharge;
  double? deliveryfeeTax;
  double? partiallyPaidAmount;
  List<Payments>? payments;
  List<String>? orderProofFullUrl;
  OfflinePayment? offlinePayment;
  double? flashAdminDiscountAmount;
  double? flashStoreDiscountAmount;
  double? extraPackagingAmount;
  double? referrerBonusAmount;

  OrderModel({
    this.id,
    this.userId,
    this.orderAmount,
    this.couponDiscountAmount,
    this.couponDiscountTitle,
    this.paymentStatus,
    this.orderStatus,
    this.totalTaxAmount,
    this.paymentMethod,
    this.couponCode,
    this.orderNote,
    this.orderType,
    this.createdAt,
    this.updatedAt,
    this.deliveryCharge,
    this.scheduleAt,
    this.otp,
    this.pending,
    this.accepted,
    this.confirmed,
    this.processing,
    this.handover,
    this.pickedUp,
    this.delivered,
    this.canceled,
    this.refundRequested,
    this.refunded,
    this.scheduled,
    this.storeDiscountAmount,
    this.failed,
    this.detailsCount,
    this.chargePayer,
    this.moduleType,
    this.deliveryMan,
    this.deliveryAddress,
    this.receiverDetails,
    this.parcelCategory,
    this.store,
    this.orderAttachmentFullUrl,
    this.dmTips,
    this.refundCancellationNote,
    this.refundCustomerNote,
    this.refund,
    this.prescriptionOrder,
    this.taxStatus,
    this.cancellationReason,
    this.processingTime,
    this.cutlery,
    this.unavailableItemNote,
    this.deliveryInstruction,
    this.taxPercentage,
    this.additionalCharge,
    this.partiallyPaidAmount,
    this.payments,
    this.orderProofFullUrl,
    this.offlinePayment,
    this.flashAdminDiscountAmount,
    this.flashStoreDiscountAmount,
    this.extraPackagingAmount,
    this.referrerBonusAmount,
  });

  OrderModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    userId = json.parseInt('user_id');
    orderAmount = json.parseDouble('order_amount');
    couponDiscountAmount = json.parseDouble('coupon_discount_amount');
    couponDiscountTitle = json.parseString('coupon_discount_title');
    paymentStatus = json.parseString('payment_status');
    orderStatus = json.parseString('order_status');
    totalTaxAmount = json.parseDouble('total_tax_amount');
    paymentMethod = json.parseString('payment_method');
    couponCode = json.parseString('coupon_code');
    orderNote = json.parseString('order_note');
    orderType = json.parseString('order_type');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    deliveryCharge = json.parseDouble('delivery_charge');
    originalDeliveryCharge = json.parseDouble('original_delivery_charge');
    scheduleAt = json.parseString('schedule_at');
    otp = json.parseString('otp');
    pending = json.parseString('pending');
    accepted = json.parseString('accepted');
    confirmed = json.parseString('confirmed');
    processing = json.parseString('processing');
    handover = json.parseString('handover');
    pickedUp = json.parseString('picked_up');
    delivered = json.parseString('delivered');
    canceled = json.parseString('canceled');
    refundRequested = json.parseString('refund_requested');
    refunded = json.parseString('refunded');
    scheduled = json.parseInt('scheduled');
    storeDiscountAmount = json.parseDouble('store_discount_amount');
    failed = json.parseString('failed');
    detailsCount = json.parseInt('details_count');
    orderAttachmentFullUrl = json.parseList<String>('order_attachment_full_url', (v) => JsonParser.parseStringOrEmpty(v));
    chargePayer = json.parseString('charge_payer');
    moduleType = json.parseString('module_type');
    final deliveryManMap = json.parseMap('delivery_man');
    deliveryMan = deliveryManMap != null ? DeliveryMan.fromJson(deliveryManMap) : null;
    final storeMap = json.parseMap('store');
    store = storeMap != null ? Store.fromJson(storeMap) : null;
    final deliveryAddressMap = json.parseMap('delivery_address');
    deliveryAddress = deliveryAddressMap != null ? AddressModel.fromJson(deliveryAddressMap) : null;
    final receiverDetailsMap = json.parseMap('receiver_details');
    receiverDetails = receiverDetailsMap != null ? AddressModel.fromJson(receiverDetailsMap) : null;
    final parcelCategoryMap = json.parseMap('parcel_category');
    parcelCategory = parcelCategoryMap != null ? ParcelCategoryModel.fromJson(parcelCategoryMap) : null;
    dmTips = json.parseDouble('dm_tips');
    refundCancellationNote = json.parseString('refund_cancellation_note');
    refundCustomerNote = json.parseString('refund_customer_note');
    final refundMap = json.parseMap('refund');
    refund = refundMap != null ? Refund.fromJson(refundMap) : null;
    prescriptionOrder = json.parseBool('prescription_order');
    taxStatus = json.getStringValue('tax_status') == 'included';
    cancellationReason = json.parseString('cancellation_reason');
    processingTime = json.parseInt('processing_time');
    cutlery = json.parseBool('cutlery');
    unavailableItemNote = json.parseString('unavailable_item_note');
    deliveryInstruction = json.parseString('delivery_instruction');
    taxPercentage = json.parseDouble('tax_percentage');
    additionalCharge = json.parseDouble('additional_charge') ?? 0.0;
    deliveryfeeTax = json.parseDouble('deliveryfee_tax');
    partiallyPaidAmount = json.parseDouble('partially_paid_amount');
    payments = json.parseList<Payments>('payments', (v) => Payments.fromJson(v as Map<String, dynamic>));
    orderProofFullUrl = json.parseList<String>('order_proof_full_url', (v) => JsonParser.parseStringOrEmpty(v));
    final offlinePaymentMap = json.parseMap('offline_payment');
    offlinePayment = offlinePaymentMap != null ? OfflinePayment.fromJson(offlinePaymentMap) : null;
    flashAdminDiscountAmount = json.parseDouble('flash_admin_discount_amount');
    flashStoreDiscountAmount = json.parseDouble('flash_store_discount_amount');
    extraPackagingAmount = json.parseDouble('extra_packaging_amount');
    referrerBonusAmount = json.parseDouble('ref_bonus_amount');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['order_amount'] = orderAmount;
    data['coupon_discount_amount'] = couponDiscountAmount;
    data['coupon_discount_title'] = couponDiscountTitle;
    data['payment_status'] = paymentStatus;
    data['order_status'] = orderStatus;
    data['total_tax_amount'] = totalTaxAmount;
    data['payment_method'] = paymentMethod;
    data['coupon_code'] = couponCode;
    data['order_note'] = orderNote;
    data['order_type'] = orderType;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['delivery_charge'] = deliveryCharge;
    data['original_delivery_charge'] = originalDeliveryCharge;
    data['schedule_at'] = scheduleAt;
    data['otp'] = otp;
    data['pending'] = pending;
    data['accepted'] = accepted;
    data['confirmed'] = confirmed;
    data['processing'] = processing;
    data['handover'] = handover;
    data['picked_up'] = pickedUp;
    data['delivered'] = delivered;
    data['canceled'] = canceled;
    data['refund_requested'] = refundRequested;
    data['refunded'] = refunded;
    data['scheduled'] = scheduled;
    data['store_discount_amount'] = storeDiscountAmount;
    data['failed'] = failed;
    data['order_attachment_full_url'] = orderAttachmentFullUrl;
    data['charge_payer'] = chargePayer;
    data['module_type'] = moduleType;
    data['details_count'] = detailsCount;
    if (deliveryMan != null) {
      data['delivery_man'] = deliveryMan!.toJson();
    }
    if (store != null) {
      data['store'] = store!.toJson();
    }
    if (deliveryAddress != null) {
      data['delivery_address'] = deliveryAddress!.toJson();
    }
    if (receiverDetails != null) {
      data['receiver_details'] = receiverDetails!.toJson();
    }
    if (parcelCategory != null) {
      data['parcel_category'] = parcelCategory!.toJson();
    }
    data['dm_tips'] = dmTips;
    data['refund_cancellation_note'] = refundCancellationNote;
    data['refund_customer_note'] = refundCustomerNote;
    if (deliveryAddress != null) {
      data['refund'] = refund!.toJson();
    }
    data['prescription_order'] = prescriptionOrder;
    data['processing_time'] = processingTime;
    data['cutlery'] = cutlery;
    data['unavailable_item_note'] = unavailableItemNote;
    data['delivery_instruction'] = deliveryInstruction;
    data['additional_charge'] = additionalCharge;
    data['deliveryfee_tax'] = deliveryfeeTax;
    data['partially_paid_amount'] = partiallyPaidAmount;
    if (payments != null) {
      data['payments'] = payments!.map((v) => v.toJson()).toList();
    }
    data['order_proof_full_url'] = orderProofFullUrl;
    if (offlinePayment != null) {
      data['offline_payment'] = offlinePayment!.toJson();
    }
    data['offline_payment'] = offlinePayment;
    data['flash_admin_discount_amount'] = flashAdminDiscountAmount;
    data['flash_store_discount_amount'] = flashStoreDiscountAmount;
    data['extra_packaging_amount'] = extraPackagingAmount;
    data['ref_bonus_amount'] = referrerBonusAmount;
    return data;
  }
}

class DeliveryMan {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? imageFullUrl;
  int? zoneId;
  int? active;
  int? available;
  double? avgRating;
  int? ratingCount;
  String? lat;
  String? lng;
  String? location;
  String? vehicleType;

  DeliveryMan({
    this.id,
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.imageFullUrl,
    this.zoneId,
    this.active,
    this.available,
    this.avgRating,
    this.ratingCount,
    this.lat,
    this.lng,
    this.location,
    this.vehicleType,
  });

  DeliveryMan.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    fName = json.parseString('f_name');
    lName = json.parseString('l_name');
    phone = json.parseString('phone');
    email = json.parseString('email');
    imageFullUrl = json.parseString('image_full_url');
    zoneId = json.parseInt('zone_id');
    active = json.parseInt('active');
    available = json.parseInt('available');
    avgRating = json.parseDouble('avg_rating') ?? 0.0;
    ratingCount = json.parseInt('rating_count');
    lat = json['lat']?.toString();
    lng = json['lng']?.toString();
    location = json['location']?.toString();
    vehicleType = json['vehicle_type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['email'] = email;
    data['image_full_url'] = imageFullUrl;
    data['zone_id'] = zoneId;
    data['active'] = active;
    data['available'] = available;
    data['avg_rating'] = avgRating;
    data['rating_count'] = ratingCount;
    data['lat'] = lat;
    data['lng'] = lng;
    data['location'] = location;
    data['vehicle_type'] = vehicleType;
    return data;
  }
}

class Payments {
  int? id;
  int? orderId;
  double? amount;
  String? paymentStatus;
  String? paymentMethod;
  String? createdAt;
  String? updatedAt;

  Payments(
      {this.id,
      this.orderId,
      this.amount,
      this.paymentStatus,
      this.paymentMethod,
      this.createdAt,
      this.updatedAt});

  Payments.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    orderId = json.parseInt('order_id');
    amount = json.parseDouble('amount');
    paymentStatus = json['payment_status']?.toString();
    paymentMethod = json['payment_method']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['amount'] = amount;
    data['payment_status'] = paymentStatus;
    data['payment_method'] = paymentMethod;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class OfflinePayment {
  List<Input>? input;
  Data? data;
  List<MethodFields>? methodFields;

  OfflinePayment({this.input, this.data, this.methodFields});

  OfflinePayment.fromJson(Map<String, dynamic> json) {
    if (json['input'] != null) {
      input = <Input>[];
      for (var v in (json['input'] as List)) {
        input!.add(Input.fromJson(v as Map<String, dynamic>));
      }
    }
    data = json['data'] != null ? Data.fromJson(json['data'] as Map<String, dynamic>) : null;
    if (json['method_fields'] != null) {
      methodFields = <MethodFields>[];
      for (var v in (json['method_fields'] as List)) {
        methodFields!.add(MethodFields.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (input != null) {
      data['input'] = input!.map((v) => v.toJson()).toList();
    }
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (methodFields != null) {
      data['method_fields'] = input!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Input {
  String? userInput;
  String? userData;

  Input({this.userInput, this.userData});

  Input.fromJson(Map<String, dynamic> json) {
    userInput = json['user_input']?.toString();
    userData = json['user_data']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_input'] = userInput;
    data['user_data'] = userData;
    return data;
  }
}

class Data {
  String? status;
  String? methodId;
  String? methodName;
  String? customerNote;

  Data({this.status, this.methodId, this.methodName, this.customerNote});

  Data.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    methodId = json['method_id'].toString();
    methodName = json['method_name']?.toString();
    customerNote = json['customer_note']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['method_id'] = methodId;
    data['method_name'] = methodName;
    data['customer_note'] = customerNote;
    return data;
  }
}

class MethodFields {
  String? inputName;
  String? inputData;

  MethodFields({this.inputName, this.inputData});

  MethodFields.fromJson(Map<String, dynamic> json) {
    inputName = json['input_name']?.toString();
    inputData = json['input_data']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['input_name'] = inputName;
    data['input_data'] = inputData;
    return data;
  }
}
