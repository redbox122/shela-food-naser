import 'package:flutter/material.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Controls row above the offers product list: product count + filter button
/// (the only toggle with an active/inactive state) + price-sort toggle +
/// grid/list view toggle.
class OffersFilterControlsRow extends StatelessWidget {
  final OffersController controller;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  const OffersFilterControlsRow({
    super.key,
    required this.controller,
    required this.hasActiveFilters,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedChipTextColor = Theme.of(context).primaryColor;
    return Container(
      width: Dimensions.webMaxWidth,
      // Symmetric 16 horizontal padding so the count text + icons align with
      // the product cards (right = left).
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: Dimensions.paddingSizeSmall),
      child: Column(
        children: [
          Row(
            children: [
              // Products count (RTL: right side).
              Expanded(
                child: Text(
                  'المنتجات ${controller.pageSize ?? 0}',
                  style: tajawalBold.copyWith(
                    fontSize: 16,
                    height: 1.0,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              // Filter Categories Button
              InkWell(
                onTap: onFilterTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    // Filter is the only toggle with an active/inactive
                    // background.
                    color: hasActiveFilters
                        ? const Color(0xFFEBFEEB)
                        : const Color(0xFFEBEBEC),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    Images.filter_v2,
                    width: 24,
                    height: 24,
                    // Active → green, inactive → black icon.
                    color: hasActiveFilters
                        ? selectedChipTextColor
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Price Sort Toggle
              InkWell(
                onTap: () => controller.setPrice(!controller.isPriceAscending),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    // Always-on toggle (a sort direction is always selected) →
                    // active color.
                    color: const Color(0xFFEBFEEB),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                      controller.isPriceAscending
                          ? Icons.trending_down
                          : Icons.trending_up,
                      size: 24,
                      color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              // Grid/List Toggle
              InkWell(
                onTap: () =>
                    controller.setVerticalItems(!controller.isVertical),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    // Always-on toggle (a view mode is always selected) →
                    // active color.
                    color: const Color(0xFFEBFEEB),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: controller.isVertical
                      ? Icon(
                          Icons.list,
                          size: 24,
                          color: Theme.of(context).primaryColor,
                        )
                      : Image.asset(
                          Images.grid_2,
                          width: 24,
                          height: 24,
                          color: Theme.of(context).primaryColor,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }
}
