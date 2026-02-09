class ReviewBodyModel {
  String? _productId;
  String? _deliveryManId;
  String? _comment;
  String? _rating;
  List<String>? _fileUpload;
  String? _orderId;

  ReviewBodyModel(
      {String? productId,
        String? deliveryManId,
        String? comment,
        String? rating,
        String? orderId,
        List<String>? fileUpload}) {
    _productId = productId;
    _deliveryManId = deliveryManId;
    _comment = comment;
    _rating = rating;
    _orderId = orderId;
    _fileUpload = fileUpload;
  }

  String? get productId => _productId;
  String? get deliveryManId => _deliveryManId;
  String? get comment => _comment;
  String? get orderId => _orderId;
  String? get rating => _rating;
  List<String>? get fileUpload => _fileUpload;

  ReviewBodyModel.fromJson(Map<String, dynamic> json) {
    _productId = json['item_id']?.toString();
    _deliveryManId = json['delivery_man_id']?.toString();
    _comment = json['comment']?.toString();
    _orderId = json['order_id']?.toString();
    _rating = json['rating']?.toString();
    _fileUpload = (json['attachment'] as List?)?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['item_id'] = _productId;
    data['delivery_man_id'] = _deliveryManId;
    data['comment'] = _comment;
    data['order_id'] = _orderId;
    data['rating'] = _rating;
    data['attachment'] = _fileUpload;
    return data;
  }
}
