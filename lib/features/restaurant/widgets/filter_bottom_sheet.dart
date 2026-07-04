import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/restaurant/controllers/restaurant_filter_controller.dart';

/// "عوامل التصفية" bottom sheet. Additive: edits the controller draft and
/// commits on "تطبيق". Chips: selected = black bg + white text, unselected =
/// light grey.
class RestaurantFilterSheet extends StatelessWidget {
  final String moduleType;
  const RestaurantFilterSheet({super.key, required this.moduleType});

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
        child: GetBuilder<RestaurantFilterController>(
          tag: moduleType,
          builder: (ctrl) {
            final d = ctrl.draft;
            return Column(
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
                // Header: centered title + X on the right (RTL).
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          'rf_filters'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section('rf_quick_filters'.tr),
                        _chipsWrap([
                          _Chip('rf_new'.tr, d.isNew, ctrl.toggleIsNew),
                          _Chip('rf_within_30'.tr, d.within30Min,
                              ctrl.toggleWithin30Min),
                          _Chip('rf_free_delivery'.tr, d.freeDelivery,
                              ctrl.toggleFreeDelivery,
                              icon: Icons.delivery_dining),
                        ]),
                        _section('rf_price'.tr),
                        _chipsWrap([
                          _Chip('\$', d.priceRange == '\$',
                              () => ctrl.setPriceRange('\$')),
                          _Chip('\$\$', d.priceRange == '\$\$',
                              () => ctrl.setPriceRange('\$\$')),
                          _Chip('\$\$\$', d.priceRange == '\$\$\$',
                              () => ctrl.setPriceRange('\$\$\$')),
                        ]),
                        _section('rf_savings'.tr),
                        _chipsWrap([
                          _Chip('rf_offers'.tr, d.hasOffers, ctrl.toggleHasOffers,
                              icon: Icons.local_offer_outlined),
                        ]),
                        _section('rf_ratings'.tr),
                        _chipsWrap([
                          _Chip('rf_rating_40'.tr, d.minRating == 4.0,
                              () => ctrl.setMinRating(4.0)),
                          _Chip('rf_rating_45'.tr, d.minRating == 4.5,
                              () => ctrl.setMinRating(4.5)),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Footer: "حذف الكل" (right, grey) + "تطبيق (n)" (left, green).
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: ctrl.clearAllFilters,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.black.withValues(alpha: 0.12)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('rf_clear_all'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF555555))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ctrl.apply();
                            Navigator.of(context).maybePop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            ctrl.draftActiveCount > 0
                                ? '${'rf_apply'.tr} (${ctrl.draftActiveCount})'
                                : 'rf_apply'.tr,
                            style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
              fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );

  Widget _chipsWrap(List<Widget> chips) => Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: chips,
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _Chip(this.label, this.selected, this.onTap, {this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF2D3633),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 6),
              Icon(icon,
                  size: 18, color: selected ? Colors.white : Colors.black54),
            ],
          ],
        ),
      ),
    );
  }
}
