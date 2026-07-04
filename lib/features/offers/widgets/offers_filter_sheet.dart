import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Filter bottom sheet for the offers list: sort, item category, and price
/// range. Sort and price-range selections are reported back to the screen
/// (the source of truth for client-side filtering) through [onSortSelected]
/// and [onPriceRangeSelected]; category toggles go straight to the controller.
/// Pressing "done" applies the controller-level filters and closes the sheet.
class OffersFilterSheet extends StatefulWidget {
  final OffersController controller;
  final List<Map<String, String>> priceRanges;
  final String initialSort;
  final String initialPriceLabel;
  final void Function(String sort) onSortSelected;
  final void Function(String label, String min, String max) onPriceRangeSelected;

  const OffersFilterSheet({
    super.key,
    required this.controller,
    required this.priceRanges,
    required this.initialSort,
    required this.initialPriceLabel,
    required this.onSortSelected,
    required this.onPriceRangeSelected,
  });

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required OffersController controller,
    required List<Map<String, String>> priceRanges,
    required String initialSort,
    required String initialPriceLabel,
    required void Function(String sort) onSortSelected,
    required void Function(String label, String min, String max)
        onPriceRangeSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OffersFilterSheet(
        controller: controller,
        priceRanges: priceRanges,
        initialSort: initialSort,
        initialPriceLabel: initialPriceLabel,
        onSortSelected: onSortSelected,
        onPriceRangeSelected: onPriceRangeSelected,
      ),
    );
  }

  @override
  State<OffersFilterSheet> createState() => _OffersFilterSheetState();
}

class _OffersFilterSheetState extends State<OffersFilterSheet> {
  late String _selectedSort;
  late String _selectedPriceLabel;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
    _selectedPriceLabel = widget.initialPriceLabel;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: title centered, close button pinned to the left.
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Text(
                    'filter'.tr,
                    textAlign: TextAlign.center,
                    style: tajawalBold.copyWith(
                      fontSize: 18,
                      height: 1.6, // line-height 160%
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('sort_by'.tr),
                      _sortChips(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _sectionTitle('item'.tr),
                      _categoryChips(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _sectionTitle('price_range'.tr),
                      _priceRangeChips(),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ],
                  ),
                ),
              ),
              // Single full-width "تم" button (image-2 design).
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onDone,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'done'.tr,
                    textAlign: TextAlign.center,
                    style: tajawalBold.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault, // body
                      height: 1.6, // line-height 160%
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDone() {
    if (_selectedSort == 'ascending') {
      widget.controller.setPrice(true);
    } else if (_selectedSort == 'descending') {
      widget.controller.setPrice(false);
    }
    widget.controller.clearLiveSearch();
    widget.controller.applyCategoryFilter();
    Navigator.pop(context);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: tajawalBold.copyWith(
          fontSize: 18,
          height: 1.6, // line-height 160%
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _sortChips() {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    final Color selectedChipColor = tokens.successSoft;
    final Color selectedChipTextColor = theme.primaryColor;
    const values = <String>['popular', 'ascending', 'descending'];
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: values.map((value) {
        final bool isSelected = _selectedSort == value;
        final String label = value == 'popular'
            ? 'popular'.tr
            : value == 'ascending'
                ? 'ascending'.tr
                : 'descending'.tr;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (selected) {
            if (!selected) return;
            setState(() => _selectedSort = value);
            widget.onSortSelected(value);
          },
          selectedColor: selectedChipColor,
          // Unselected: light grey fill. No border in either state.
          backgroundColor: const Color(0xFFF6F5F8),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: tajawalMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.6, // line-height 160%
            letterSpacing: 0,
            color: isSelected
                ? selectedChipTextColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _priceRangeChips() {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    final Color selectedChipColor = tokens.successSoft;
    final Color selectedChipTextColor = theme.primaryColor;
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: widget.priceRanges.map((range) {
        final bool isSelected = _selectedPriceLabel == range['label'];
        final String label =
            range['label'] == 'all' ? 'all'.tr : range['label']!;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (selected) {
            if (!selected) return;
            setState(() => _selectedPriceLabel = range['label']!);
            widget.onPriceRangeSelected(
                range['label']!, range['min']!, range['max']!);
          },
          selectedColor: selectedChipColor,
          // Unselected: light grey fill. No border in either state.
          backgroundColor: const Color(0xFFF6F5F8),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: tajawalMedium.copyWith(
            fontSize: 14,
            height: 1.6, // line-height 160%
            letterSpacing: 0,
            color: isSelected
                ? selectedChipTextColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _categoryChips() {
    final controller = widget.controller;
    if (controller.categoryList == null || controller.categoryList!.isEmpty) {
      return Text(
        'no_categories_available'.tr,
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Theme.of(context).disabledColor,
        ),
      );
    }

    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    final Color selectedChipColor = tokens.successSoft;
    final Color selectedChipTextColor = theme.primaryColor;
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: controller.categoryList!.map((category) {
        final int categoryId = category.id ?? 0;
        final bool isSelected =
            controller.selectedCategoryIds.contains(categoryId);
        return ChoiceChip(
          label: Text(category.name ?? ''),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) {
            controller.toggleCategorySelection(categoryId);
            setState(() {});
          },
          selectedColor: selectedChipColor,
          // Unselected: light grey fill. No border in either state.
          backgroundColor: const Color(0xFFF6F5F8),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: tajawalMedium.copyWith(
            fontSize: 14,
            height: 1.6, // line-height 160%
            letterSpacing: 0,
            color: isSelected
                ? selectedChipTextColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }
}
