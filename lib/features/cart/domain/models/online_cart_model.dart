import 'package:sixam_mart/features/item/domain/models/item_model.dart' as product_variation;
import 'package:sixam_mart/common/utils/json_parser.dart';

class OnlineCartModel {
  int? id;
  int? userId;
  int? moduleId;
  int? itemId;
  bool? isGuest;
  List<int>? addOnIds;
  List<int>? addOnQtys;
  String? itemType;
  double? price;
  int? quantity;
  List<Variation>? foodVariation;
  List<product_variation.Variation>? productVariation;
  String? createdAt;
  String? updatedAt;
  product_variation.Item? item;

  OnlineCartModel({
    this.id,
    this.userId,
    this.moduleId,
    this.itemId,
    this.isGuest,
    this.addOnIds,
    this.addOnQtys,
    this.itemType,
    this.price,
    this.quantity,
    this.foodVariation,
    this.createdAt,
    this.updatedAt,
    this.item,
  });

  OnlineCartModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    userId = json.parseInt('user_id');
    moduleId = json.parseInt('module_id');
    itemId = json.parseInt('item_id');
    isGuest = json.parseBool('is_guest');
    addOnIds = json.parseList<int>('add_on_ids', (v) => JsonParser.parseInt(v) ?? 0);
    addOnQtys = json.parseList<int>('add_on_qtys', (v) => JsonParser.parseInt(v) ?? 0);
    itemType = json.parseString('item_type');
    price = json.parseDouble('price');
    quantity = json.parseInt('quantity');
    final variationList = json['variation'];
    if (variationList != null && variationList is List) {
      foodVariation = [];
      productVariation = [];
      for (final v in variationList) {
        if (v is Map<String, dynamic>) {
          if (v['name'] == null) {
            productVariation!.add(product_variation.Variation.fromJson(v));
          } else {
            foodVariation!.add(Variation.fromJson(v));
          }
        }
      }
    }
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    final itemMap = json.parseMap('item');
    item = itemMap != null ? product_variation.Item.fromJson(itemMap) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['module_id'] = moduleId;
    data['item_id'] = itemId;
    data['is_guest'] = isGuest;
    data['add_on_ids'] = addOnIds;
    data['add_on_qtys'] = addOnQtys;
    data['item_type'] = itemType;
    data['price'] = price;
    data['quantity'] = quantity;
    if (foodVariation != null) {
      data['variation'] = foodVariation!.map((v) => v.toJson()).toList();
    }
    if (productVariation != null) {
      data['variation'] = productVariation!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (item != null) {
      data['item'] = item!.toJson();
    }
    return data;
  }
}

class Variation {
  String? name;
  dynamic values;  // Can be Value (old format) or List (new format)

  Variation({this.name, this.values});

  Variation.fromJson(Map<String, dynamic> json) {
    name = json.parseString('name');
    
    // ✅ FIX: Handle both formats from backend
    final valuesData = json['values'];
    if (valuesData != null) {
      if (valuesData is List) {
        // New format: array of {label, optionPrice} objects
        values = valuesData;  // Store as-is
      } else if (valuesData is Map) {
        // Old format: {label: ["option1", "option2"]}
        values = Value.fromJson(valuesData as Map<String, dynamic>);
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (values != null) {
      if (values is Value) {
        data['values'] = (values as Value).toJson();
      } else {
        data['values'] = values;  // Already in correct format
      }
    }
    return data;
  }
}

class Value {
  List<String>? label;

  Value({this.label});

  Value.fromJson(Map<String, dynamic> json) {
    label = json.parseList<String>('label', (v) => JsonParser.parseStringOrEmpty(v));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    return data;
  }
}
