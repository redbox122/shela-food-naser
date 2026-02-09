import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Filter Bottom Sheet
///
/// Displays filter options for restaurants with checkboxes, price range picker, and radio buttons
/// Matches Figma design from filetpage.md
class FilterBottomSheet extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onApply;
  final VoidCallback? onClear;

  const FilterBottomSheet({
    super.key,
    this.onApply,
    this.onClear,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Food type selection (radio behavior)
  String _selectedFilterType = 'all';

  // Checkbox states
  bool _recentlyAdded = false;
  bool _highestRated = false;
  bool _fastestDelivery = false;

  // Price range
  RangeValues _priceRange = const RangeValues(0, 1000);

  // Radio button selection (sort by)
  String? _selectedSortBy;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = screenWidth / 591.0; // Base design width from Figma

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Draggable handle
            Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
              width: 40 * scaleFactor,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),

            // Header: X button (left) and Title (right)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // X button (left in RTL)
                  IconButton(
                    onPressed: () => Get.back<void>(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  // Title (right in RTL)
                  Text(
                    'التصنيفات',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge * 1.37, // ~21.90
                      color: const Color(0xFF5C5D5E),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Food Type section (radio buttons)
                    _buildFoodTypeSection(scaleFactor),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Checkboxes section
                    _buildCheckboxesSection(scaleFactor),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Price range section
                    _buildPriceRangeSection(scaleFactor),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Sort by section
                    _buildSortBySection(scaleFactor),

                    const SizedBox(height: Dimensions.paddingSizeLarge * 2),
                  ],
                ),
              ),
            ),

            // Action buttons (fixed at bottom)
            _buildActionButtons(scaleFactor),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTypeSection(double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الطعام',
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeLarge * 1.43, // ~22.90
            color: const Color(0xFF535456),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _buildFoodTypeRadioOption(
          scaleFactor,
          'الكل',
          'all',
          const Color(0xFF5C5C5C),
          Dimensions.fontSizeLarge * 1.06, // ~17.00
          FontWeight.w300,
        ),
        _buildFoodTypeRadioOption(
          scaleFactor,
          'نباتي',
          'veg',
          const Color(0xFF6F6F6F),
          Dimensions.fontSizeLarge * 1.05, // ~16.80
          FontWeight.w400,
        ),
        _buildFoodTypeRadioOption(
          scaleFactor,
          'غير نباتي',
          'non_veg',
          const Color(0xFF575757),
          Dimensions.fontSizeLarge * 1.05, // ~16.80
          FontWeight.w400,
        ),
      ],
    );
  }

  Widget _buildFoodTypeRadioOption(
    double scaleFactor,
    String text,
    String value,
    Color textColor,
    double fontSize,
    FontWeight fontWeight,
  ) {
    return ListTile(
      title: Text(
        text,
        style: robotoRegular.copyWith(
          fontSize: fontSize,
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
      // ignore: deprecated_member_use
      leading: Radio<String>(
        value: value,
        // ignore: deprecated_member_use
        groupValue: _selectedFilterType,
        // ignore: deprecated_member_use
        onChanged: (String? newValue) {
          setState(() {
            _selectedFilterType = newValue ?? 'all';
          });
        },
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).primaryColor;
          }
          return Theme.of(context).unselectedWidgetColor;
        }),
      ),
    );
  }

  Widget _buildCheckboxesSection(double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckboxOption(
          scaleFactor,
          'أضيف حديثا',
          _recentlyAdded,
          (value) {
            setState(() {
              _recentlyAdded = value ?? false;
            });
          },
          const Color(0xFF696969),
          Dimensions.fontSizeLarge * 1.22, // ~19.50
        ),
        _buildCheckboxOption(
          scaleFactor,
          'الأعلى تقييما 4.5 فما فوق',
          _highestRated,
          (value) {
            setState(() {
              _highestRated = value ?? false;
            });
          },
          const Color(0xFF616161),
          Dimensions.fontSizeLarge * 1.31, // ~20.90
        ),
        _buildCheckboxOption(
          scaleFactor,
          'الأسرع توصيلا حتى 30 دقيقة',
          _fastestDelivery,
          (value) {
            setState(() {
              _fastestDelivery = value ?? false;
            });
          },
          const Color(0xFF666666),
          Dimensions.fontSizeLarge * 1.26, // ~20.10
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(
    double scaleFactor,
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
    Color textColor,
    double fontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          // Text
          Expanded(
            child: Text(
              text,
              style: robotoRegular.copyWith(
                fontSize: fontSize,
                color: value
                    ? Theme.of(context).primaryColor
                    : textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeSection(double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'نطاق السعر ريال سعودي',
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeLarge * 1.54, // ~24.60
            color: const Color(0xFF5C5D5E),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Price range slider
        RangeSlider(
          values: _priceRange,
          max: 1000,
          divisions: 100,
          labels: RangeLabels(
            '${_priceRange.start.round()} ريال',
            '${_priceRange.end.round()} ريال',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),

        // Price display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_priceRange.start.round()} ريال',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: const Color(0xFF787878),
              ),
            ),
            Text(
              '${_priceRange.end.round()} ريال',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: const Color(0xFF787878),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortBySection(double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'فرز حسب',
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeLarge * 1.43, // ~22.90
            color: const Color(0xFF535456),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Radio buttons
        _buildRadioOption(
          scaleFactor,
          'الموصى به',
          'recommended',
          const Color(0xFF5C5C5C),
          Dimensions.fontSizeLarge * 1.06, // ~17
          FontWeight.w300,
        ),
        _buildRadioOption(
          scaleFactor,
          'المسافة',
          'distance',
          const Color(0xFF6F6F6F),
          Dimensions.fontSizeLarge * 1.05, // ~16.80
          FontWeight.w400,
        ),
        _buildRadioOption(
          scaleFactor,
          'التقييمات من الأعلى إلى الأقل',
          'ratings_desc',
          const Color(0xFF575757),
          Dimensions.fontSizeLarge * 1.28, // ~20.50
          FontWeight.w400,
        ),
        _buildRadioOption(
          scaleFactor,
          'وقت التوصيل من الأقل إلى الأعلى',
          'delivery_time_asc',
          const Color(0xFF555555),
          Dimensions.fontSizeLarge * 1.28, // ~20.50
          FontWeight.w400,
        ),
      ],
    );
  }

  Widget _buildRadioOption(
    double scaleFactor,
    String text,
    String value,
    Color textColor,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final isSelected = _selectedSortBy == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          // Radio button
          // ignore: deprecated_member_use
          Radio<String>(
            value: value,
            // ignore: deprecated_member_use
            groupValue: _selectedSortBy,
            // ignore: deprecated_member_use
            onChanged: (String? newValue) {
              setState(() {
                _selectedSortBy = newValue;
              });
            },
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).primaryColor;
              }
              return Theme.of(context).unselectedWidgetColor;
            }),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          // Text
          Expanded(
            child: Text(
              text,
              style: robotoRegular.copyWith(
                fontSize: fontSize,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : textColor,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double scaleFactor) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Apply button
          Expanded(
            child: InkWell(
              onTap: () {
                final filters = {
                  'filterType': _selectedFilterType,
                  'recentlyAdded': _recentlyAdded,
                  'highestRated': _highestRated,
                  'fastestDelivery': _fastestDelivery,
                  'priceRange': {
                    'min': _priceRange.start,
                    'max': _priceRange.end,
                  },
                  'sortBy': _selectedSortBy,
                };
                if (widget.onApply != null) {
                  widget.onApply!(filters);
                }
                Get.back<void>();
              },
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12 * scaleFactor),
                topRight: Radius.circular(7 * scaleFactor),
                bottomLeft: Radius.circular(9 * scaleFactor),
                bottomRight: Radius.circular(6 * scaleFactor),
              ),
              child: Container(
                height: 75 * scaleFactor,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEA00),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12 * scaleFactor),
                    topRight: Radius.circular(7 * scaleFactor),
                    bottomLeft: Radius.circular(9 * scaleFactor),
                    bottomRight: Radius.circular(6 * scaleFactor),
                  ),
                  border: Border.all(
                    color: const Color(0xFFF7EC4F),
                  ),
                ),
                child: Center(
                  child: Text(
                    'تطبيق',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge * 1.24, // ~19.80
                      color: const Color(0xFF51450A),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          // Clear All button
          InkWell(
            onTap: () {
              setState(() {
                _selectedFilterType = 'all';
                _recentlyAdded = false;
                _highestRated = false;
                _fastestDelivery = false;
                _priceRange = const RangeValues(0, 1000);
                _selectedSortBy = null;
              });
              if (widget.onClear != null) {
                widget.onClear!();
              }
            },
            borderRadius: BorderRadius.circular(9 * scaleFactor),
            child: Container(
              width: 197 * scaleFactor,
              height: 75 * scaleFactor,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEBEC),
                borderRadius: BorderRadius.circular(9 * scaleFactor),
              ),
              child: Center(
                child: Text(
                  'مسح الكل',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge * 1.31, // ~20.90
                    color: const Color(0xFFB5BABD),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
