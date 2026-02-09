import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class SlimMenuResponse {
  final bool success;
  final int totalCategories;
  final int totalItems;
  final List<SlimMenuCategory> categories;

  bool get isLargeStore => totalItems >= 2000;
  bool get isCompleteMenu => totalItems < 2000;

  SlimMenuResponse({
    required this.success,
    required this.totalCategories,
    required this.totalItems,
    required this.categories,
  });

  factory SlimMenuResponse.fromJson(Map<String, dynamic> json) {
    return SlimMenuResponse(
      success: json['success'] == true,
      totalCategories: int.tryParse(json['total_categories']?.toString() ?? '0') ?? 0,
      totalItems: int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      categories: json['categories'] is List
          ? (json['categories'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => SlimMenuCategory.fromJson(e))
              .toList()
          : [],
    );
  }

  List<SlimMenuItem> getAllItems() {
    final allItems = <SlimMenuItem>[];
    for (final category in categories) {
      allItems.addAll(category.items);
    }
    return allItems;
  }

  List<SlimMenuItem> getItemsForCategory(int categoryId) {
    return categories
        .firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => SlimMenuCategory(id: -1, name: '', items: []),
        )
        .items;
  }
}

class SlimMenuCategory {
  final int id;
  final String name;
  final List<SlimMenuItem> items;

  SlimMenuCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  factory SlimMenuCategory.fromJson(Map<String, dynamic> json) {
    return SlimMenuCategory(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      items: json['items'] is List
          ? (json['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => SlimMenuItem.fromJson(e))
              .toList()
          : [],
    );
  }
}

class SlimMenuItem {
  final int id;
  final String name;
  final String? image;
  final double price;
  final double discount;

  SlimMenuItem({
    required this.id,
    required this.name,
    this.image,
    required this.price,
    required this.discount,
  });

  factory SlimMenuItem.fromJson(Map<String, dynamic> json) {
    return SlimMenuItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
    );
  }

  double get originalPrice => price + discount;
  bool get hasDiscount => discount > 0;

  Item toItem() {
    final sanitizedImageUrl = image != null && image!.isNotEmpty
        ? image!.replaceAll('format=auto', 'format=jpg')
        : null;

    return Item(
      id: id,
      name: name,
      imageFullUrl: sanitizedImageUrl,
      price: price,
      originalPrice: originalPrice,
      discount: discount,
    );
  }
}
