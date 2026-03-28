import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/widgets/food_order_variation_section.dart';
import 'package:sixam_mart/common/widgets/food_order_option_item.dart';

/// Reusable widget for rendering food variations (Coffee, Food modules)
/// Extracted from item_bottom_sheet.dart for use in both bottom sheet and detail screen
class FoodVariationSection extends StatelessWidget {
  final List<FoodVariation> foodVariations;
  final Item item;
  final Function(int variationIndex, int optionIndex) onVariationSelected;
  final List<List<bool?>> selectedVariations;
  /// When non-null and length matches [foodVariations], used to scroll to invalid sections.
  final List<GlobalKey>? variationSectionKeys;

  const FoodVariationSection({
    super.key,
    required this.foodVariations,
    required this.item,
    required this.onVariationSelected,
    required this.selectedVariations,
    this.variationSectionKeys,
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 PERFORMANCE: Calculate variation titles ONCE before ListView.builder
    // Prevents O(n²) loops inside itemBuilder (calculating sameNameCount for each item)
    final List<String> variationTitles = _calculateVariationTitles(foodVariations);
    final List<String> variationSubtitles = _calculateVariationSubtitles(foodVariations);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: foodVariations.length,
      itemBuilder: (context, index) {
        final foodVariation = foodVariations[index];
        final String variationTitle = variationTitles[index];
        final String subtitle = variationSubtitles[index];

        final GlobalKey? sectionKey =
            variationSectionKeys != null && index < variationSectionKeys!.length
                ? variationSectionKeys![index]
                : null;
        return KeyedSubtree(
          key: sectionKey ?? ValueKey<String>('food_variation_$index'),
          child: FoodOrderVariationSection(
            title: variationTitle,
            subtitle: subtitle,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foodVariation.variationValues!.length,
              itemBuilder: (context, i) {
                bool isSelected = false;
                if (selectedVariations.length > index &&
                    selectedVariations[index].length > i) {
                  isSelected = selectedVariations[index][i] ?? false;
                }

                return FoodOrderOptionItem(
                  label: foodVariation.variationValues![i].level!,
                  price: foodVariation.variationValues![i].optionPrice,
                  isSelected: isSelected,
                  onTap: () {
                    onVariationSelected(index, i);
                  },
                  isMultiSelect: foodVariation.multiSelect ?? false,
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  /// 🎯 PERFORMANCE: Pre-calculate variation titles to avoid O(n²) in itemBuilder
  List<String> _calculateVariationTitles(List<FoodVariation> variations) {
    // Count occurrences of each name (single pass)
    final Map<String, int> nameCountMap = {};
    for (final v in variations) {
      final name = v.name ?? '';
      nameCountMap[name] = (nameCountMap[name] ?? 0) + 1;
    }
    
    // Calculate position for each variation (single pass with tracking)
    final Map<String, int> namePositionMap = {};
    final List<String> titles = [];
    
    for (final v in variations) {
      final name = v.name ?? '';
      final sameNameCount = nameCountMap[name] ?? 1;
      
      if (sameNameCount > 1) {
        namePositionMap[name] = (namePositionMap[name] ?? 0) + 1;
        titles.add('$name ${namePositionMap[name]}');
      } else {
        titles.add(name);
      }
    }
    
    return titles;
  }
  
  /// 🎯 PERFORMANCE: Pre-calculate subtitles to avoid calculations in itemBuilder
  List<String> _calculateVariationSubtitles(List<FoodVariation> variations) {
    return variations.map((v) {
      if (v.multiSelect == true) {
        return 'اختيارات حتى ${v.max ?? v.variationValues!.length}';
      } else {
        return 'اختيار واحد';
      }
    }).toList();
  }
}

