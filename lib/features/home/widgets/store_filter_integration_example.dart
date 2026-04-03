/// Store Filter Integration Example
/// 
/// This file shows how to integrate all the new filter components
/// Use this as a reference when updating AllStoreFilterWidget and AllRestaurantsView
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/home/widgets/store_filter_bottom_sheet.dart';
import 'package:sixam_mart/features/home/widgets/active_filters_chips.dart';
import 'package:sixam_mart/features/home/widgets/enhanced_filter_button.dart';
import 'package:sixam_mart/features/home/utils/store_filter_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';

/// Example: How to integrate filters in AllStoreFilterWidget
class StoreFilterIntegrationExample extends StatelessWidget {
  const StoreFilterIntegrationExample({super.key});

  void _showFilterBottomSheet(BuildContext context, StoreController controller) {
    // Get current filter state (you'll need to add this to StoreController)
    // Note: Add activeFilters getter to StoreController

    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: StoreFilterBottomSheet(
            storeController: controller,
            onApply: (filters) {
              // Update controller with new filters
              // Note: Add updateFilters method to StoreController
              // Note: updateFilters method needs to be implemented in StoreController
              // controller.updateFilters(filters);
              
              // Apply filters to current store list
              _applyFiltersToStores(controller, filters);
            },
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StoreFilterBottomSheet(
          storeController: controller,
          onApply: (filters) {
            // Update controller with new filters
            // Note: Add updateFilters method to StoreController
            // controller.updateFilters(filters);
            
            // Apply filters to current store list
            _applyFiltersToStores(controller, filters);
          },
        ),
      );
    }
  }

  void _applyFiltersToStores(StoreController controller, Map<String, dynamic> filters) {


    
    // Get current store list based on store type
    // Note: Replace with actual store model type
    dynamic currentStores;
    
    switch (controller.storeType) {
      case 'popular':
        currentStores = controller.popularStoreList;
        break;
      case 'newly_joined':
        currentStores = controller.latestStoreList;
        break;
      default:
        currentStores = controller.storeModel?.stores;
    }

    if (currentStores == null || (currentStores as List).isEmpty) return;

    // Apply filters using helper
    StoreFilterHelper.applyFilters(
      stores: currentStores as List<Store>,
      sortBy: filters['sort'] as String?,
      minRating: filters['minRating'] is num ? (filters['minRating'] as num).toInt() : null,
      openNow: filters['openNow'] is bool ? filters['openNow'] as bool : false,
      freeDelivery: filters['freeDelivery'] is bool ? filters['freeDelivery'] as bool : false,
      hasDiscount: filters['hasDiscount'] is bool ? filters['hasDiscount'] as bool : false,
      featuredOnly: filters['featuredOnly'] is bool ? filters['featuredOnly'] as bool : false,
      maxDeliveryTime: filters['maxDeliveryTime'] is num ? (filters['maxDeliveryTime'] as num).toDouble() : null,
      maxMinOrder: filters['maxMinOrder'] is num ? (filters['maxMinOrder'] as num).toDouble() : null,
      categoryIds: filters['categoryIds'] is List ? (filters['categoryIds'] as List).cast<int>() : null,
    );

    // Update controller with filtered stores
    // You'll need to add a method like setFilteredStores() to StoreController
    // controller.setFilteredStores(filteredStores);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (controller) {
        // Note: Add activeFilters getter to StoreController
        final activeFilters = StoreFilterHelper.getDefaultFilters();
        final activeFilterCount = StoreFilterHelper.getActiveFilterCount(activeFilters);

        return Column(
          children: [
            // Filter Buttons Row (existing store type filters)
            Row(
              children: [
                // Existing filter buttons...
                
                const Spacer(),
                
                // Enhanced Filter Button with badge
                EnhancedFilterButton(
                  activeFilterCount: activeFilterCount,
                  onTap: () => _showFilterBottomSheet(context, controller),
                ),
              ],
            ),

            // Active Filters Chips (shown when filters are active)
            if (StoreFilterHelper.hasActiveFilters(activeFilters))
              ActiveFiltersChips(
                activeFilters: activeFilters,
                onRemoveFilter: (filterKey, value) {
                  // Remove specific filter
                  final updatedFilters = Map<String, dynamic>.from(activeFilters);
                  updatedFilters[filterKey] = value;
                  // Note: Add updateFilters method to StoreController
                  // controller.updateFilters(updatedFilters);
                  
                  // Re-apply filters
                  _applyFiltersToStores(controller, updatedFilters);
                },
                onClearAll: () {
                  // Clear all filters
                  // Note: Add updateFilters method to StoreController
                  // controller.updateFilters(defaultFilters);
                  
                  // Reset to original store list
                  // You'll need to reload the original stores
                },
              ),

            // Store List (filtered results)
            // Your existing store list widget here
          ],
        );
      },
    );
  }
}

/// Required StoreController additions (add these to StoreController):
/// 
/// ```dart
/// Map<String, dynamic> _activeFilters = StoreFilterHelper.getDefaultFilters();
/// Map<String, dynamic> get activeFilters => _activeFilters;
/// 
/// void updateFilters(Map<String, dynamic> filters) {
///   _activeFilters = filters;
///   update();
/// }
/// 
/// void resetFilters() {
///   _activeFilters = StoreFilterHelper.getDefaultFilters();
///   update();
/// }
/// ```








