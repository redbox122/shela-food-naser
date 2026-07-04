import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/restaurant/controllers/restaurant_filter_controller.dart';

/// "فرز حسب" bottom sheet — single-select radio list.
/// Additive: opened from [RestaurantFilterBar]; edits the controller draft and
/// applies on selection.
class SortBottomSheet extends StatelessWidget {
  final String moduleType;
  const SortBottomSheet({super.key, required this.moduleType});

  static const List<List<String>> _options = <List<String>>[
    // [value, translationKey]
    ['recommended', 'rf_sort_recommended'],
    ['distance', 'rf_sort_distance'],
    ['time', 'rf_sort_time'],
    ['discount', 'rf_sort_discount'],
    ['rating', 'rf_sort_rating'],
  ];

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header: X on the left, centered title.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      'rf_sort_by'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            GetBuilder<RestaurantFilterController>(
              tag: moduleType,
              builder: (ctrl) => Column(
                children: _options.map((opt) {
                  final bool selected = ctrl.draft.sortBy == opt[0];
                  return InkWell(
                    onTap: () {
                      ctrl.setSort(opt[0]);
                      ctrl.apply();
                      Navigator.of(context).maybePop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected ? primary : Colors.grey,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              opt[1].tr,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
