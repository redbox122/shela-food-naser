import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class RecommendedItemModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Item>? items;

  RecommendedItemModel({this.totalSize, this.limit, this.offset, this.items});

  RecommendedItemModel.fromJson(Map<String, dynamic> json) {
    totalSize = json.parseInt('total_size');
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
    if (json['items'] != null) {
      items = <Item>[];
      json['items'].forEach((v) {
        items!.add(Item.fromJson(v as Map<String, dynamic>));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (items != null) {
      data['products'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
