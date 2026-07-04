import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/restaurant/controllers/restaurant_filter_controller.dart';
import 'package:sixam_mart/features/restaurant/widgets/filter_bottom_sheet.dart';
import 'package:sixam_mart/features/restaurant/widgets/sort_bottom_sheet.dart';

/// Horizontal, scrollable quick-filter bar shown under the search field.
/// Additive & reusable across modules via [moduleType].
class RestaurantFilterBar extends StatelessWidget {
  final String moduleType;
  const RestaurantFilterBar({super.key, required this.moduleType});

  void _openSheet(BuildContext context, Widget sheet) {
    // Snapshot applied → draft once, before the sheet builds (never during build).
    Get.find<RestaurantFilterController>(tag: moduleType).beginEditing();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    return GetBuilder<RestaurantFilterController>(
      tag: moduleType,
      builder: (ctrl) {
        final d = ctrl.applied;
        return SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL: start from the right
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // ☰ opens the filters sheet (badge with active count).
              _IconPill(
                icon: Icons.tune,
                badge: ctrl.activeFiltersCount,
                primary: primary,
                onTap: () => _openSheet(
                    context, RestaurantFilterSheet(moduleType: moduleType)),
              ),
              const SizedBox(width: 8),
              // فرز حسب ▼
              _Pill(
                label: ctrl.applied.isSortDefault
                    ? 'rf_sort_by'.tr
                    : 'rf_sort_by'.tr,
                selected: !ctrl.applied.isSortDefault,
                trailingIcon: Icons.keyboard_arrow_down,
                primary: primary,
                onTap: () => _openSheet(
                    context, SortBottomSheet(moduleType: moduleType)),
              ),
              const SizedBox(width: 8),
              _Pill(
                label: 'rf_free_delivery'.tr,
                icon: Icons.delivery_dining,
                selected: d.freeDelivery,
                primary: primary,
                onTap: ctrl.quickToggleFreeDelivery,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: 'rf_within_30'.tr,
                selected: d.within30Min,
                primary: primary,
                onTap: ctrl.quickToggleWithin30Min,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: 'rf_offers'.tr,
                icon: Icons.local_offer_outlined,
                selected: d.hasOffers,
                primary: primary,
                onTap: ctrl.quickToggleHasOffers,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: 'rf_new'.tr,
                selected: d.isNew,
                primary: primary,
                onTap: ctrl.quickToggleIsNew,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.black : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 18,
                    color: selected ? Colors.white : Colors.black54),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF2D3633),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trailingIcon,
                    size: 18,
                    color: selected ? Colors.white : Colors.black54),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final int badge;
  final Color primary;
  final VoidCallback onTap;
  const _IconPill({
    required this.icon,
    required this.badge,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, size: 20, color: Colors.black87),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
