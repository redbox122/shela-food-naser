import 'package:sixam_mart/common/utils/json_parser.dart';

class CategoryBreakdown {
  final List<CategoryData> categories;
  final double totalSpent;
  final int totalItems;

  const CategoryBreakdown({
    required this.categories,
    required this.totalSpent,
    required this.totalItems,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => CategoryData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalSpent: json.parseDouble('total_spent') ?? 0.0,
      totalItems: json.parseInt('total_items') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((item) => item.toJson()).toList(),
      'total_spent': totalSpent,
      'total_items': totalItems,
    };
  }
}

class CategoryData {
  final String categoryName;
  final double spentAmount;
  final int purchaseCount;
  final double percentage;

  const CategoryData({
    required this.categoryName,
    required this.spentAmount,
    required this.purchaseCount,
    required this.percentage,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      categoryName: json.parseString('category_name') ?? '',
      spentAmount: json.parseDouble('spent_amount') ?? 0.0,
      purchaseCount: json.parseInt('purchase_count') ?? 0,
      percentage: json.parseDouble('percentage') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_name': categoryName,
      'spent_amount': spentAmount,
      'purchase_count': purchaseCount,
      'percentage': percentage,
    };
  }
}
