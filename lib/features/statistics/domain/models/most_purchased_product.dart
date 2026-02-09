import 'package:sixam_mart/common/utils/json_parser.dart';

class MostPurchasedProduct {
  final int itemId;
  final String name;
  final String image;
  final int purchaseCount;
  final double totalSpent;
  final String lastPurchased;
  final PriceRange priceRange;
  final String purchaseFrequency;
  final String category;

  const MostPurchasedProduct({
    required this.itemId,
    required this.name,
    required this.image,
    required this.purchaseCount,
    required this.totalSpent,
    required this.lastPurchased,
    required this.priceRange,
    required this.purchaseFrequency,
    required this.category,
  });

  factory MostPurchasedProduct.fromJson(Map<String, dynamic> json) {
    return MostPurchasedProduct(
      itemId: json.parseInt('item_id') ?? 0,
      name: json.parseString('name') ?? '',
      image: json.parseString('image') ?? '',
      purchaseCount: json.parseInt('purchase_count') ?? 0,
      totalSpent: json.parseDouble('total_spent') ?? 0.0,
      lastPurchased: json.parseString('last_purchased') ?? '',
      priceRange: PriceRange.fromJson(json.parseMap('price_range') ?? {}),
      purchaseFrequency: json.parseString('purchase_frequency') ?? '',
      category: json.parseString('category') ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'name': name,
      'image': image,
      'purchase_count': purchaseCount,
      'total_spent': totalSpent,
      'last_purchased': lastPurchased,
      'price_range': priceRange.toJson(),
      'purchase_frequency': purchaseFrequency,
      'category': category,
    };
  }
}

class PriceRange {
  final double current;
  final double min;
  final double max;

  const PriceRange({
    required this.current,
    required this.min,
    required this.max,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      current: json.parseDouble('current') ?? 0.0,
      min: json.parseDouble('min') ?? 0.0,
      max: json.parseDouble('max') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'min': min,
      'max': max,
    };
  }
}
