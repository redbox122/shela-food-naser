import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class OrderDetailsModel {
  int? id;
  int? itemId;
  int? orderId;
  double? price;
  Item? itemDetails;
  List<Variation>? variation;
  List<FoodVariation>? foodVariation;
  List<AddOn>? addOns;
  double? discountOnItem;
  String? discountType;
  int? quantity;
  double? taxAmount;
  String? variant;
  String? createdAt;
  String? updatedAt;
  int? itemCampaignId;
  double? totalAddOnPrice;
  String? imageFullUrl;
  int? isGuest;

  OrderDetailsModel({
    this.id,
    this.itemId,
    this.orderId,
    this.price,
    this.itemDetails,
    this.variation,
    this.foodVariation,
    this.addOns,
    this.discountOnItem,
    this.discountType,
    this.quantity,
    this.taxAmount,
    this.variant,
    this.createdAt,
    this.updatedAt,
    this.itemCampaignId,
    this.totalAddOnPrice,
    this.imageFullUrl,
    this.isGuest,
  });

  OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    itemId = json.parseInt('item_id');
    orderId = json.parseInt('order_id');
    price = json.parseDouble('price');
    itemDetails = json['item_details'] != null
        ? Item.fromJson(json['item_details'] as Map<String, dynamic>)
        : null;
    variation = [];
    foodVariation = [];

    // ✅ FIXED: Handle empty arrays [] from backend instead of 'none' string
    // Backend now returns [] for items without variations instead of 'none'
    if (json['variation'] != null) {
      // Check if it's a non-empty array
      if (json['variation'] is List && (json['variation'] as List).isNotEmpty) {
        final variationList = json['variation'] as List;
        
        // 🔍 DEBUG: Log variation data structure
        if (kDebugMode) {
          debugPrint('🔍 [OrderDetailsModel] Parsing variations: ${variationList.length} items');
          if (variationList.isNotEmpty && variationList[0] is Map) {
            debugPrint('🔍 [OrderDetailsModel] First variation keys: ${(variationList[0] as Map).keys}');
          }
        }

        // Check if it's food variations format - look for 'values' or 'options' field
        bool isFoodVariation = false;
        if (variationList[0] is Map) {
          final firstVar = variationList[0] as Map<String, dynamic>;
          // Check for food variation indicators: 'values', 'options', 'variationValues'
          isFoodVariation = firstVar.containsKey('values') ||
              firstVar.containsKey('options') ||
              firstVar.containsKey('variationValues') ||
              (firstVar.containsKey('name') && !firstVar.containsKey('type'));
        }

        if (kDebugMode) {
          debugPrint('🔍 [OrderDetailsModel] Is food variation format: $isFoodVariation');
        }

        if (isFoodVariation) {
          for (final v in variationList) {
            try {
              foodVariation!.add(FoodVariation.fromJson(v as Map<String, dynamic>));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ [OrderDetailsModel] Error parsing food variation: $e');
                debugPrint('❌ [OrderDetailsModel] Variation data: $v');
              }
            }
          }
          if (kDebugMode) {
            debugPrint('✅ [OrderDetailsModel] Parsed ${foodVariation!.length} food variations');
          }
        } else {
          for (final v in variationList) {
            try {
              variation!.add(Variation.fromJson(v as Map<String, dynamic>));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ [OrderDetailsModel] Error parsing variation: $e');
                debugPrint('❌ [OrderDetailsModel] Variation data: $v');
              }
            }
          }
          if (kDebugMode) {
            debugPrint('✅ [OrderDetailsModel] Parsed ${variation!.length} old variations');
          }
        }
      } else {
        // Empty array [] - no variations (this is the new backend format)
        if (kDebugMode) {
          debugPrint('🔍 [OrderDetailsModel] Empty variations array [] - item has no variations');
        }
      }
    } else {
      // null or missing - no variations
      if (kDebugMode) {
        debugPrint('🔍 [OrderDetailsModel] No variation field in order details');
      }
    }
    if (json['add_ons'] != null) {
      addOns = [];
      json['add_ons'].forEach((v) {
        addOns!.add(AddOn.fromJson(v as Map<String, dynamic>));
      });
    }
    discountOnItem = json.parseDouble('discount_on_item');
    discountType = json.parseString('discount_type');
    quantity = json.parseInt('quantity');
    taxAmount = json.parseDouble('tax_amount');
    variant = json.parseString('variant');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    itemCampaignId = json.parseInt('item_campaign_id');
    totalAddOnPrice = json.parseDouble('total_add_on_price');
    imageFullUrl = json.parseString('image_full_url');
    isGuest = json.parseInt('is_guest');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['item_id'] = itemId;
    data['order_id'] = orderId;
    data['price'] = price;
    if (itemDetails != null) {
      data['item_details'] = itemDetails!.toJson();
    }
    if (variation != null) {
      data['variation'] = variation!.map((v) => v.toJson()).toList();
    } else if (foodVariation != null) {
      data['variation'] = foodVariation!.map((v) => v.toJson()).toList();
    }
    if (addOns != null) {
      data['add_ons'] = addOns!.map((v) => v.toJson()).toList();
    }
    data['discount_on_item'] = discountOnItem;
    data['discount_type'] = discountType;
    data['quantity'] = quantity;
    data['tax_amount'] = taxAmount;
    data['variant'] = variant;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['item_campaign_id'] = itemCampaignId;
    data['total_add_on_price'] = totalAddOnPrice;
    data['image_full_url'] = imageFullUrl;
    data['is_guest'] = isGuest;
    return data;
  }
}

class AddOn {
  String? name;
  double? price;
  int? quantity;

  AddOn({
    this.name,
    this.price,
    this.quantity,
  });

  AddOn.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    price = json.parseDouble('price');
    quantity = int.parse(json['quantity'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['quantity'] = quantity;
    return data;
  }
}
