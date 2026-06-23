// Data models for the Market "Best Offers" / store-category screen.
//
// Loaded from `GET /api/v2/stores/{store_id}/categories/{category_id}`, which
// returns `sub_categories` — each a second-bar tab carrying its own embedded
// products. Normal categories and Best Offers share the same structure; only
// `is_discount_category` differs.

/// Product row returned inside a sub_category:
/// `{ id, name, full_image_url, price, discounted_price, discount_percentage }`.
class OfferProduct {
  final int? id;
  final String? name;
  final String? image;
  final double price;
  final double discountedPrice;
  final double discountPercentage;

  OfferProduct({
    this.id,
    this.name,
    this.image,
    this.price = 0,
    this.discountedPrice = 0,
    this.discountPercentage = 0,
  });

  static double _d(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  factory OfferProduct.fromJson(Map<String, dynamic> j) => OfferProduct(
        // Offers/discount rows may carry the item id under item_id/product_id
        // rather than id; fall back so the product can still be opened.
        id: int.tryParse('${j['id'] ?? j['item_id'] ?? j['product_id']}'),
        name: j['name']?.toString(),
        image: (j['full_image_url'] ?? j['image_full_url'] ?? j['image'])
            ?.toString(),
        price: _d(j['price']),
        discountedPrice: _d(j['discounted_price']),
        discountPercentage: _d(j['discount_percentage']),
      );

  bool get hasDiscount => discountedPrice > 0 && price > discountedPrice;

  double get shownPrice => hasDiscount ? discountedPrice : price;

  /// Discount percentage for the "-X%" badge.
  int get discountPercent {
    if (discountPercentage > 0) return discountPercentage.round();
    if (hasDiscount) return (((price - discountedPrice) / price) * 100).round();
    return 0;
  }
}

/// One second-bar tab = a sub_category with its embedded first page of products.
class SubCat {
  final String id;
  final String name;
  final List<OfferProduct> products;
  final int total;
  final bool hasMore;

  const SubCat({
    required this.id,
    required this.name,
    this.products = const [],
    this.total = 0,
    this.hasMore = false,
  });

  factory SubCat.fromJson(Map<String, dynamic> j) => SubCat(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        products: (j['products'] is List)
            ? (j['products'] as List)
                .whereType<Map>()
                .map((e) => OfferProduct.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        total: int.tryParse('${j['total_products']}') ?? 0,
        hasMore: j['has_more'] == true,
      );
}

/// Top-bar store category: `{ id, name, is_discount_category }` from
/// `GET /api/v2/stores/{store_id}/categories`.
class StoreCat {
  final String id;
  final String name;
  final bool isDiscount;
  const StoreCat({required this.id, required this.name, this.isDiscount = false});

  factory StoreCat.fromJson(Map<String, dynamic> j) => StoreCat(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        isDiscount: j['is_discount_category'] == true,
      );
}
