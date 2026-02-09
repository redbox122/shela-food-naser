import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/helper/price_converter.dart';

/// Enhanced food order option item with prices and bigger sizes
class FoodOrderOptionItem extends StatelessWidget {
  final String label;
  final double? price;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMultiSelect;
  final bool showDivider;

  const FoodOrderOptionItem({
    super.key,
    required this.label,
    this.price,
    required this.isSelected,
    required this.onTap,
    this.isMultiSelect = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final crossAxisAlignment = isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    return Directionality(
      textDirection: textDirection,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: isArabic
                    ? [
                        // RTL Layout: Radio -> Text -> Price (visual: right -> middle -> left)
                        // Radio/Checkbox on visual right (start in RTL)
                        isMultiSelect
                            ? _MinimalCheckbox(isSelected: isSelected)
                            : _MinimalRadio(isSelected: isSelected),
                        const SizedBox(width: 12),
                        // Label text - right aligned
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.right,
                            style: robotoRegular.copyWith(
                              color: isSelected 
                                  ? const Color(0xFF2D3633)  // Dark black when selected
                                  : const Color(0xFF4A4A4B), // Dark grey for better readability
                              fontSize: 20.5,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Price on visual left (end in RTL)
                        if (price != null && price! > 0)
                          Text(
                            '${PriceConverter.convertPrice(price)} ريال',
                            textAlign: TextAlign.left,
                            style: robotoBold.copyWith(
                              color: const Color(0xFF2D3633),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                      ]
                    : [
                        // LTR Layout: Price -> Text -> Radio (visual: left -> middle -> right)
                        // Price on visual left (start in LTR)
                        if (price != null && price! > 0)
                          Text(
                            PriceConverter.convertPrice(price),
                            textAlign: TextAlign.left,
                            style: robotoBold.copyWith(
                              color: const Color(0xFF2D3633),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const SizedBox(width: 12),
                        // Label text - left aligned
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.left,
                            style: robotoRegular.copyWith(
                              color: isSelected 
                                  ? const Color(0xFF2D3633)  // Dark black when selected
                                  : const Color(0xFF4A4A4B), // Dark grey for better readability
                              fontSize: 20.5,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Radio/Checkbox on visual right (end in LTR)
                        isMultiSelect
                            ? _MinimalCheckbox(isSelected: isSelected)
                            : _MinimalRadio(isSelected: isSelected),
                      ],
              ),
            ),
          ),
          // Divider line
          if (showDivider) ...[
            Container(
              width: double.infinity,
              height: 1,
              decoration: const BoxDecoration(
                color: Color(0xFFEAEAEA),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced radio button - 24x24px for better visibility
class _MinimalRadio extends StatelessWidget {
  final bool isSelected;

  const _MinimalRadio({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: isSelected ? const Color(0xFF31A342) : const Color(0xFFE9EDEA),
        ),
      ),
      child: isSelected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF31A342),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// Enhanced checkbox - 24x24px for better visibility
class _MinimalCheckbox extends StatelessWidget {
  final bool isSelected;

  const _MinimalCheckbox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          width: 2,
          color: isSelected ? const Color(0xFF31A342) : const Color(0xFFE9EDEA),
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 14,
              color: Color(0xFF31A342),
            )
          : null,
    );
  }
}
