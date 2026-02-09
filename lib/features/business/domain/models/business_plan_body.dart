class BusinessPlanBody {
  String? businessPlan;
  String? storeId;
  String? packageId;
  String? payment;
  String? paymentGateway;
  String? callBack;
  String? paymentPlatform;
  String? type;

  BusinessPlanBody({
    this.businessPlan,
    this.storeId,
    this.packageId,
    this.payment,
    this.paymentGateway,
    this.callBack,
    this.paymentPlatform,
    this.type,
  });

  BusinessPlanBody.fromJson(Map<String, dynamic> json) {
    businessPlan = json['business_plan']?.toString();
    storeId = json['store_id']?.toString();
    packageId = json['package_id']?.toString();
    payment = json['payment']?.toString();
    paymentGateway = json['payment_gateway']?.toString();
    callBack = json['callback']?.toString();
    paymentPlatform = json['payment_platform']?.toString();
    type = json['type']?.toString();
  }

  Map<String, String?> toJson() {
    final Map<String, String?> data = <String, String?>{};
    data['business_plan'] = businessPlan;
    data['store_id'] = storeId;
    data['package_id'] = packageId;
    data['payment'] = payment;
    data['payment_gateway'] = paymentGateway;
    data['callback'] = callBack;
    data['payment_platform'] = paymentPlatform;
    data['type'] = type;
    return data;
  }
}
