import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class ReviewModel {
  int? id;
  String? comment;
  int? rating;
  String? itemName;
  String? itemImageFullUrl;
  String? customerName;
  String? createdAt;
  String? updatedAt;
  String? reply;
  Item? item;

  ReviewModel({
    this.id,
    this.comment,
    this.rating,
    this.itemName,
    this.itemImageFullUrl,
    this.customerName,
    this.createdAt,
    this.updatedAt,
    this.reply,
    this.item,
  });

  ReviewModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    comment = json.parseString('comment');
    rating = json.parseInt('rating');
    itemName = json['item_name']?.toString();
    itemImageFullUrl = json['item_image_full_url']?.toString();
    customerName = json['customer_name']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    reply = json['reply']?.toString();
    item = json['item'] != null ? Item.fromJson(json['item'] as Map<String, dynamic>) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['comment'] = comment;
    data['rating'] = rating;
    data['item_name'] = itemName;
    data['item_image_full_url'] = itemImageFullUrl;
    data['customer_name'] = customerName;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['reply'] = reply;
    if (item != null) {
      data['item'] = item!.toJson();
    }
    return data;
  }
}
