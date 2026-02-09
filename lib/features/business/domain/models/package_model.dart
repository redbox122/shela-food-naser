class PackageModel {
  List<Packages>? packages;

  PackageModel({this.packages});

  PackageModel.fromJson(Map<String, dynamic> json) {
    if (json['packages'] is List) {
      packages = (json['packages'] as List)
          .map((e) => Packages.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (packages != null) {
      data['packages'] = packages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Packages {
  int? id;
  String? packageName;
  double? price;
  int? validity;
  String? maxOrder;
  String? maxProduct;
  int? pos;
  int? mobileApp;
  int? chat;
  int? review;
  int? selfDelivery;
  int? status;
  int? def;
  String? createdAt;
  String? updatedAt;
  String? color;

  Packages({
    this.id,
    this.packageName,
    this.price,
    this.validity,
    this.maxOrder,
    this.maxProduct,
    this.pos,
    this.mobileApp,
    this.chat,
    this.review,
    this.selfDelivery,
    this.status,
    this.def,
    this.createdAt,
    this.updatedAt,
    this.color,
  });

  factory Packages.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'];
    final int? id =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final String? packageName = json['package_name']?.toString();
    final dynamic rawPrice = json['price'];
    final double? price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '');
    final dynamic rawValidity = json['validity'];
    final int? validity = rawValidity is int
        ? rawValidity
        : int.tryParse(rawValidity?.toString() ?? '');
    final String? maxOrder = json['max_order']?.toString();
    final String? maxProduct = json['max_product']?.toString();
    final dynamic rawPos = json['pos'];
    final int? pos =
        rawPos is int ? rawPos : int.tryParse(rawPos?.toString() ?? '');
    final dynamic rawMobileApp = json['mobile_app'];
    final int? mobileApp = rawMobileApp is int
        ? rawMobileApp
        : int.tryParse(rawMobileApp?.toString() ?? '');
    final dynamic rawChat = json['chat'];
    final int? chat =
        rawChat is int ? rawChat : int.tryParse(rawChat?.toString() ?? '');
    final dynamic rawReview = json['review'];
    final int? review = rawReview is int
        ? rawReview
        : int.tryParse(rawReview?.toString() ?? '');
    final dynamic rawSelfDelivery = json['self_delivery'];
    final int? selfDelivery = rawSelfDelivery is int
        ? rawSelfDelivery
        : int.tryParse(rawSelfDelivery?.toString() ?? '');
    final dynamic rawStatus = json['status'];
    final int? status =
        rawStatus is int ? rawStatus : int.tryParse(rawStatus?.toString() ?? '');
    final dynamic rawDefault = json['default'];
    final int? def = rawDefault is int
        ? rawDefault
        : int.tryParse(rawDefault?.toString() ?? '');
    final String? createdAt = json['created_at']?.toString();
    final String? updatedAt = json['updated_at']?.toString();
    final String? color = json['colour']?.toString();
    return Packages(
      id: id,
      packageName: packageName,
      price: price,
      validity: validity,
      maxOrder: maxOrder,
      maxProduct: maxProduct,
      pos: pos,
      mobileApp: mobileApp,
      chat: chat,
      review: review,
      selfDelivery: selfDelivery,
      status: status,
      def: def,
      createdAt: createdAt,
      updatedAt: updatedAt,
      color: color,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['package_name'] = packageName;
    data['price'] = price;
    data['validity'] = validity;
    data['max_order'] = maxOrder;
    data['max_product'] = maxProduct;
    data['pos'] = pos;
    data['mobile_app'] = mobileApp;
    data['chat'] = chat;
    data['review'] = review;
    data['self_delivery'] = selfDelivery;
    data['status'] = status;
    data['default'] = def;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['colour'] = color;
    return data;
  }
}
