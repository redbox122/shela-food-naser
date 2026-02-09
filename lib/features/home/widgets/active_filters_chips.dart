/// Active Filters Chips Widget
/// 
/// Displays active filters as dismissible chips above the store list
/// Beautiful animations and smooth dismiss actions
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/util/design_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ActiveFiltersChips extends StatelessWidget {
  final Map<String, dynamic> activeFilters;
  final Function(String filterKey, dynamic value)? onRemoveFilter;
  final VoidCallback? onClearAll;

  const ActiveFiltersChips({
    super.key,
    required this.activeFilters,
    this.onRemoveFilter,
    this.onClearAll,
  });

  int get activeFilterCount {
    int count = 0;
    if (activeFilters['sort'] != null) count++;
    if (activeFilters['minRating'] != null) count++;
    if (activeFilters['openNow'] == true) count++;
    if (activeFilters['freeDelivery'] == true) count++;
    if (activeFilters['hasDiscount'] == true) count++;
    if (activeFilters['featuredOnly'] == true) count++;
    if (activeFilters['maxDeliveryTime'] != null) count++;
    if (activeFilters['maxMinOrder'] != null) count++;
    if (activeFilters['categoryIds'] != null && (activeFilters['categoryIds'] as List).isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    if (activeFilterCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'active_filters'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: DesignTokens.textLight,
                ),
              ),
              const Spacer(),
              if (activeFilterCount > 1 && onClearAll != null)
                InkWell(
                  onTap: onClearAll,
                  child: Text(
                    'clear_all'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSmall),
          Wrap(
            spacing: DesignTokens.spaceSmall,
            runSpacing: DesignTokens.spaceSmall,
            children: _buildFilterChips(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final chips = <Widget>[];

    // Sort filter
    if (activeFilters['sort'] != null) {
      chips.add(_buildFilterChip(
        context: context,
        label: _getSortLabel(activeFilters['sort'] as String?),
        icon: Icons.sort_rounded,
        onRemove: () => onRemoveFilter?.call('sort', null),
      ));
    }

    // Rating filter
    if (activeFilters['minRating'] != null) {
      chips.add(_buildFilterChip(
        context: context,
        label: _getRatingLabel(activeFilters['minRating'] as int?),
        icon: Icons.star_rounded,
        onRemove: () => onRemoveFilter?.call('minRating', null),
      ));
    }

    // Open Now
    if (activeFilters['openNow'] == true) {
      chips.add(_buildFilterChip(
        context: context,
        label: 'open_now'.tr,
        icon: Icons.schedule_rounded,
        onRemove: () => onRemoveFilter?.call('openNow', false),
      ));
    }

    // Free Delivery
    if (activeFilters['freeDelivery'] == true) {
      chips.add(_buildFilterChip(
        context: context,
        label: 'free_delivery'.tr,
        icon: Icons.local_shipping_rounded,
        onRemove: () => onRemoveFilter?.call('freeDelivery', false),
      ));
    }

    // Has Discount
    if (activeFilters['hasDiscount'] == true) {
      chips.add(_buildFilterChip(
        context: context,
        label: 'has_discount'.tr,
        icon: Icons.local_offer_rounded,
        onRemove: () => onRemoveFilter?.call('hasDiscount', false),
      ));
    }

    // Featured Only
    if (activeFilters['featuredOnly'] == true) {
      chips.add(_buildFilterChip(
        context: context,
        label: 'featured_only'.tr,
        icon: Icons.star_border_rounded,
        onRemove: () => onRemoveFilter?.call('featuredOnly', false),
      ));
    }

    // Delivery Time
    if (activeFilters['maxDeliveryTime'] != null) {
      chips.add(_buildFilterChip(
        context: context,
        label: _getDeliveryTimeLabel(activeFilters['maxDeliveryTime'] as double?),
        icon: Icons.timer_rounded,
        onRemove: () => onRemoveFilter?.call('maxDeliveryTime', null),
      ));
    }

    // Minimum Order
    if (activeFilters['maxMinOrder'] != null) {
      chips.add(_buildFilterChip(
        context: context,
        label: _getMinOrderLabel(activeFilters['maxMinOrder'] as double?),
        icon: Icons.shopping_bag_rounded,
        onRemove: () => onRemoveFilter?.call('maxMinOrder', null),
      ));
    }

    // Categories
    if (activeFilters['categoryIds'] != null) {
      final categoryIds = activeFilters['categoryIds'] as List<int>;
      if (categoryIds.isNotEmpty) {
        final categoryController = Get.find<CategoryController>();
        final categories = categoryController.categoryList ?? [];
        
        for (final categoryId in categoryIds) {
          final category = categories.firstWhereOrNull((c) => c.id == categoryId);
          if (category != null) {
            chips.add(_buildFilterChip(
              context: context,
              label: category.name ?? '',
              icon: Icons.category_rounded,
              onRemove: () {
                final updatedIds = List<int>.from(categoryIds)..remove(categoryId);
                onRemoveFilter?.call('categoryIds', updatedIds.isEmpty ? null : updatedIds);
              },
            ));
          }
        }
      }
    }

    return chips;
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return AnimatedContainer(
      duration: DesignTokens.animationDefault,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Prevent tap action, only remove button works
          borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceDefault,
              vertical: DesignTokens.spaceSmall,
            ),
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGreenGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
              boxShadow: DesignTokens.shadowMedium,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: DesignTokens.spaceSmall),
                Text(
                  label,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSmall),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String? sort) {
    switch (sort) {
      case 'distance':
        return 'distance'.tr;
      case 'rating':
        return 'rating'.tr;
      case 'delivery_time':
        return 'delivery_time'.tr;
      case 'min_order':
        return 'minimum_order'.tr;
      default:
        return '';
    }
  }

  String _getRatingLabel(int? rating) {
    if (rating == 4) return '4+ ⭐';
    if (rating == 45) return '4.5+ ⭐';
    return '';
  }

  String _getDeliveryTimeLabel(double? time) {
    if (time == 30) return 'under_30_min'.tr;
    if (time == 60) return '30_60_min'.tr;
    return '';
  }

  String _getMinOrderLabel(double? amount) {
    if (amount == 10) return 'under_10'.tr;
    if (amount == 25) return '10_25'.tr;
    if (amount == 50) return '25_50'.tr;
    return '';
  }
}








