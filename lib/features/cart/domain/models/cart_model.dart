import 'dart:convert';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class CartModel {
  int? id;
  int? storeId;
  double? price;
  double? discountedPrice;
  List<Variation>? variation;
  List<List<bool?>>? foodVariations;
  List<dynamic>? rawFoodVariations;

  /// Display labels for food-variation choices returned in the `{name, values}`
  /// shape (the market options sheet / order format), e.g. "ساندوتش 1/2: بيج
  /// تايستي". Populated only when the server sends that format; null otherwise.
  List<String>? selectedVariationLabels;
  double? discountAmount;
  int? quantity;
  List<AddOn>? addOnIds;
  List<AddOns>? addOns;
  bool? isCampaign;
  int? stock;
  Item? item;
  int? quantityLimit;
  bool isLoading;

  CartModel({
    this.id,
    this.storeId,
    this.price,
    this.discountedPrice,
    this.variation,
    this.foodVariations,
    this.rawFoodVariations,
    this.selectedVariationLabels,
    this.discountAmount,
    this.quantity,
    this.addOnIds,
    this.addOns,
    this.isCampaign,
    this.stock,
    this.item,
    this.quantityLimit,
    this.isLoading = false,
  });

  CartModel.fromJson(Map<String, dynamic> json) : isLoading = false {
    id = _parseInt(json['cart_id']);
    storeId = _parseInt(json['store_id']);
    price = _parseDouble(json['price']) ?? 0.0;
    discountedPrice = price;

    // variation — may arrive as a List, or (for double-encoded rows) a JSON
    // String like "[{...}]". Decode the string first so the choices still parse.
    dynamic variationRaw = json['variation'];
    if (variationRaw is String) {
      try {
        variationRaw = jsonDecode(variationRaw);
      } catch (_) {
        variationRaw = null;
      }
    }
    if (variationRaw is List) {
      variation = variationRaw
          .whereType<Map<String, dynamic>>()
          .map((v) => Variation.fromJson(v))
          .toList();

      // Food-variation choices arrive as {name, values:[{label,..}]} (or the
      // older {name, values:{label:[...]}}). The Variation model above only
      // captures type/price, so extract readable labels here for the cart UI.
      final labels = <String>[];
      for (final v in variationRaw) {
        if (v is! Map || v['name'] == null || v['values'] == null) continue;
        final chosen = <String>[];
        final dynamic vals = v['values'];
        if (vals is List) {
          for (final o in vals) {
            if (o is Map && o['label'] != null) {
              chosen.add(o['label'].toString());
            }
          }
        } else if (vals is Map && vals['label'] != null) {
          final dynamic lab = vals['label'];
          if (lab is List) {
            chosen.addAll(lab.map((e) => e.toString()));
          } else {
            chosen.add(lab.toString());
          }
        }
        if (chosen.isNotEmpty) {
          labels.add('${v['name']}: ${chosen.join('، ')}');
        }
      }
      if (labels.isNotEmpty) selectedVariationLabels = labels;
    }

    // food variations
    if (json['food_variations'] is List) {
      foodVariations = [];
      for (var outer in (json['food_variations'] as List)) {
        if (outer is List) {
          foodVariations!.add(
            outer.map((e) => e == null ? null : e == true).toList(),
          );
        }
      }
    }

    discountAmount = _parseDouble(json['discount_amount']);
    quantity = _parseInt(json['quantity']);
    stock = _parseInt(json['stock']);

    // add_on_ids
    if (json['add_on_ids'] is List) {
      addOnIds = (json['add_on_ids'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => AddOn.fromJson(v))
          .toList();
    }

    // add_ons
    if (json['add_ons'] is List) {
      addOns = (json['add_ons'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => AddOns.fromJson(v))
          .toList();
    }

    isCampaign = _parseBool(json['is_campaign']);

    if (json['item'] is Map<String, dynamic>) {
      item = Item.fromJson(json['item'] as Map<String, dynamic>);
    }
    storeId ??= item?.storeId;

    quantityLimit = _parseInt(json['quantity_limit']);
    isLoading = _parseBool(json['is_loading']) ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': id,
      'store_id': storeId,
      'price': price,
      'discounted_price': discountedPrice,
      'variation': variation?.map((v) => v.toJson()).toList(),
      'food_variations': foodVariations,
      'discount_amount': discountAmount,
      'quantity': quantity,
      'add_on_ids': addOnIds?.map((v) => v.toJson()).toList(),
      'add_ons': addOns?.map((v) => v.toJson()).toList(),
      'is_campaign': isCampaign,
      'stock': stock,
      'item': item?.toJson(),
      'quantity_limit': quantityLimit,
    };
  }
}

class AddOn {
  int? id;
  int? quantity;

  AddOn({this.id, this.quantity});

  AddOn.fromJson(Map<String, dynamic> json) {
    id = _parseInt(json['id']);
    quantity = _parseInt(json['quantity']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
    };
  }
}

//
// 🔧 Helpers (Dart 2 style – آمنة)
//

int? _parseInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value == 1;
  return value.toString().toLowerCase() == 'true';
}
