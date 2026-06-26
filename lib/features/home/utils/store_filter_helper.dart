/// Store Filter Helper Utilities
/// 
/// Contains logic for filtering and sorting store lists
/// Client-side filtering as fallback when backend doesn't support all filters
library;

import 'package:sixam_mart/features/store/domain/models/store_model.dart';

class StoreFilterHelper {
  /// RULE #2 (defence layer): a store is shown only when it has a logo or cover
  /// image. The authoritative enforcement is backend SQL on the original `logo`
  /// column; this stops a stray imageless store from rendering as a grey
  /// placeholder. The store stays in the DB and reappears once an image is added.
  static bool storeHasImage(Store store) =>
      (store.logoFullUrl ?? '').trim().isNotEmpty ||
      (store.coverPhotoFullUrl ?? '').trim().isNotEmpty;

  /// Apply all active filters to a store list
  static List<Store> applyFilters({
    required List<Store> stores,
    String? sortBy,
    int? minRating,
    bool openNow = false,
    bool freeDelivery = false,
    bool hasDiscount = false,
    bool featuredOnly = false,
    double? maxDeliveryTime,
    double? maxMinOrder,
    List<int>? categoryIds,
  }) {
    List<Store> filteredStores = List<Store>.from(stores);

    // RULE #2: always exclude stores with no image (kept in DB, hidden in UI).
    filteredStores = filteredStores.where(storeHasImage).toList();

    // Filter by open now
    if (openNow) {
      filteredStores = filteredStores.where((store) {
        return store.isOpen == true && (store.active ?? false);
      }).toList();
    }

    // Filter by free delivery
    if (freeDelivery) {
      filteredStores = filteredStores.where((store) {
        return store.freeDelivery == true;
      }).toList();
    }

    // Filter by discount
    if (hasDiscount) {
      filteredStores = filteredStores.where((store) {
        return store.discount != null;
      }).toList();
    }

    // Filter by featured
    if (featuredOnly) {
      filteredStores = filteredStores.where((store) {
        return store.featured == 1;
      }).toList();
    }

    // Filter by minimum rating
    if (minRating != null) {
      final minRatingValue = minRating == 45 ? 4.5 : 4.0;
      filteredStores = filteredStores.where((store) {
        return (store.avgRating ?? 0) >= minRatingValue;
      }).toList();
    }

    // Filter by delivery time
    if (maxDeliveryTime != null) {
      filteredStores = filteredStores.where((store) {
        if (store.deliveryTime == null) return false;
        try {
          // ignore: deprecated_member_use
          final timeStr = store.deliveryTime!.replaceAll(RegExp(r'[^0-9]'), '');
          if (timeStr.isEmpty) return false;
          final timeMinutes = int.tryParse(timeStr);
          if (timeMinutes == null) return false;
          return timeMinutes <= maxDeliveryTime.toInt();
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Filter by minimum order
    if (maxMinOrder != null) {
      filteredStores = filteredStores.where((store) {
        return (store.minimumOrder ?? 0) <= maxMinOrder;
      }).toList();
    }

    // Filter by categories
    if (categoryIds != null && categoryIds.isNotEmpty) {
      filteredStores = filteredStores.where((store) {
        if (store.categoryIds == null || store.categoryIds!.isEmpty) return false;
        return categoryIds.any((id) => store.categoryIds!.contains(id));
      }).toList();
    }

    // Apply sorting
    if (sortBy != null) {
      filteredStores = _sortStores(filteredStores, sortBy);
    }

    return filteredStores;
  }

  /// Sort stores by the specified criteria
  static List<Store> _sortStores(List<Store> stores, String sortBy) {
    final sortedStores = List<Store>.from(stores);

    switch (sortBy) {
      case 'distance':
        sortedStores.sort((a, b) {
          if (a.distance == null && b.distance == null) return 0;
          if (a.distance == null) return 1;
          if (b.distance == null) return -1;
          return a.distance!.compareTo(b.distance!);
        });
        break;

      case 'rating':
        sortedStores.sort((a, b) {
          final ratingA = a.avgRating ?? 0;
          final ratingB = b.avgRating ?? 0;
          return ratingB.compareTo(ratingA); // Descending (highest first)
        });
        break;

      case 'delivery_time':
        sortedStores.sort((a, b) {
          final timeA = _parseDeliveryTime(a.deliveryTime);
          final timeB = _parseDeliveryTime(b.deliveryTime);
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeA.compareTo(timeB); // Ascending (fastest first)
        });
        break;

      case 'min_order':
        sortedStores.sort((a, b) {
          final minA = a.minimumOrder ?? 0;
          final minB = b.minimumOrder ?? 0;
          return minA.compareTo(minB); // Ascending (lowest first)
        });
        break;

      default:
        break;
    }

    return sortedStores;
  }

  /// Parse delivery time string to minutes (int)
  static int? _parseDeliveryTime(String? deliveryTime) {
    if (deliveryTime == null || deliveryTime.isEmpty) return null;
    try {
      // ignore: deprecated_member_use
      final timeStr = deliveryTime.replaceAll(RegExp(r'[^0-9]'), '');
      if (timeStr.isEmpty) return null;
      return int.tryParse(timeStr);
    } catch (e) {
      return null;
    }
  }

  /// Get active filter count
  static int getActiveFilterCount(Map<String, dynamic> filters) {
    int count = 0;
    if (filters['sort'] != null) count++;
    if (filters['minRating'] != null) count++;
    if (filters['openNow'] == true) count++;
    if (filters['freeDelivery'] == true) count++;
    if (filters['hasDiscount'] == true) count++;
    if (filters['featuredOnly'] == true) count++;
    if (filters['maxDeliveryTime'] != null) count++;
    if (filters['maxMinOrder'] != null) count++;
    if (filters['categoryIds'] != null && (filters['categoryIds'] as List).isNotEmpty) count++;
    return count;
  }

  /// Check if any filters are active
  static bool hasActiveFilters(Map<String, dynamic> filters) {
    return getActiveFilterCount(filters) > 0;
  }

  /// Reset all filters
  static Map<String, dynamic> getDefaultFilters() {
    return {
      'sort': null,
      'minRating': null,
      'openNow': false,
      'freeDelivery': false,
      'hasDiscount': false,
      'featuredOnly': false,
      'maxDeliveryTime': null,
      'maxMinOrder': null,
      'categoryIds': <int>[],
    };
  }
}








