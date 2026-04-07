import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// ⚡ TASK 2: Isolate JSON parsing to prevent main-thread jank
/// Parses ItemModel JSON in a background isolate to keep UI smooth
class JsonIsolateHelper {
  /// Parse ItemModel from JSON string in an isolate
  /// This prevents blocking the main thread when parsing large item lists
  static Future<ItemModel?> parseItemModel(String jsonString) async {
    try {
      // Parse JSON in isolate to avoid blocking main thread
      final parsedJson = await compute(_parseJsonString, jsonString);
      if (parsedJson == null) return null;

      // Create ItemModel from parsed JSON (this is fast, already parsed)
      return ItemModel.fromJson(parsedJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JsonIsolateHelper: Error parsing ItemModel: $e');
      }
      return null;
    }
  }

  /// Parse a list of items from JSON string in an isolate
  /// Optimized for parsing multiple items (20+ items)
  static Future<List<Item>?> parseSlimItemList(String jsonString) async {
    try {
      // Parse JSON in isolate
      final parsedJson = await compute(_parseJsonString, jsonString);
      if (parsedJson == null) return null;

      // Extract items array
      final itemsJson = parsedJson['products'] ?? parsedJson['items'];
      if (itemsJson == null || itemsJson is! List) {
        return [];
      }

      // Parse items in isolate (batch processing)
      final items = await compute(_parseItemsList, itemsJson);
      return items;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JsonIsolateHelper: Error parsing item list: $e');
      }
      return null;
    }
  }

  /// ⚡ NEW API STRUCTURE: Parse slim offers items response (8 fields)
  /// Response structure: { "products_count": 2998, "products": [...] }
  /// Each product has: id, name, image_full_url, price, original_price, discount, discount_type, avg_rating
  static Future<ItemModel?> parseSlimOffersItemModel(String jsonString) async {
    try {
      // Parse JSON in isolate
      final parsedJson = await compute(_parseJsonString, jsonString);
      if (parsedJson == null) return null;

      // Map slim response structure to ItemModel structure
      final productsJson = parsedJson['products'];
      if (productsJson == null || productsJson is! List) {
        final productsCountValue = parsedJson['products_count'];
        final totalSize = productsCountValue is int
            ? productsCountValue
            : (productsCountValue != null
                    ? int.tryParse(productsCountValue.toString())
                    : null) ??
                0;

        final limitValue = parsedJson['limit'];
        final limit = limitValue?.toString() ?? '20';

        final offsetValue = parsedJson['offset'];
        final offset = offsetValue is int
            ? offsetValue
            : (offsetValue != null
                    ? int.tryParse(offsetValue.toString())
                    : null) ??
                0;

        return ItemModel(
          totalSize: totalSize,
          limit: limit,
          offset: offset,
          items: [],
        );
      }

      // Parse slim items in isolate (8 fields per item)
      final items = await compute(_parseSlimItemsList, productsJson);

      // Create ItemModel with mapped structure
      final productsCountValue =
          parsedJson['products_count'] ?? parsedJson['total_size'];
      final totalSize = productsCountValue is int
          ? productsCountValue
          : (productsCountValue != null
                  ? int.tryParse(productsCountValue.toString())
                  : null) ??
              items.length;

      final limitValue =
          parsedJson['limit'] ?? parsedJson['page_products_count'];
      final limit = limitValue?.toString() ?? '20';

      final offsetValue = parsedJson['offset'];
      final offset = offsetValue is int
          ? offsetValue
          : (offsetValue != null
                  ? int.tryParse(offsetValue.toString())
                  : null) ??
              0;

      return ItemModel(
        totalSize: totalSize,
        limit: limit,
        offset: offset,
        items: items,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JsonIsolateHelper: Error parsing slim offers ItemModel: $e');
      }
      return null;
    }
  }

  /// Top-level function for compute - parses JSON string
  static Map<String, dynamic>? _parseJsonString(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JsonIsolateHelper._parseJsonString: Error: $e');
      }
      return null;
    }
  }

  /// Top-level function for compute - parses list of items
  static List<Item> _parseItemsList(List<dynamic> itemsJson) {
    try {
      return itemsJson
          .map((itemJson) {
            try {
              if (itemJson is Map<String, dynamic>) {
                return Item.fromJson(itemJson);
              }
              return null;
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ JsonIsolateHelper: Error parsing single item: $e');
              }
              return null;
            }
          })
          .whereType<Item>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JsonIsolateHelper._parseItemsList: Error: $e');
      }
      return [];
    }
  }

  /// ⚡ NEW API: Parse slim items (8 fields: id, name, image_full_url, price, original_price, discount, discount_type, avg_rating)
  /// Creates minimal Item objects with defaults for missing fields
  static List<Item> _parseSlimItemsList(List<dynamic> itemsJson) {
    try {
      return itemsJson
          .map((itemJson) {
            try {
              if (itemJson is Map<String, dynamic>) {
                // Parse the 8 fields from slim API response
                // ⚡ Backend guarantee: discount and discount_type are always present
                final idValue = itemJson['id'];
                final id = idValue != null
                    ? (idValue is int
                        ? idValue
                        : int.tryParse(idValue.toString()))
                    : null;

                final priceValue = itemJson['price'];
                final price = priceValue != null
                    ? (priceValue is num
                        ? priceValue.toDouble()
                        : double.tryParse(priceValue.toString()) ?? 0.0)
                    : null;

                final originalPriceValue = itemJson['original_price'];
                final originalPrice = originalPriceValue != null
                    ? (originalPriceValue is num
                        ? originalPriceValue.toDouble()
                        : double.tryParse(originalPriceValue.toString()))
                    : null;

                final discountValue = itemJson['discount'];
                double discount = discountValue != null
                    ? (discountValue is num
                        ? discountValue.toDouble()
                        : double.tryParse(discountValue.toString()) ?? 0.0)
                    : 0.0; // Safe default per backend guarantee

                String discountType =
                    itemJson['discount_type']?.toString() ?? 'percent';

                // Fallback: infer discount from original_price if backend discount is missing/zero.
                if (discount <= 0 &&
                    originalPrice != null &&
                    price != null &&
                    originalPrice > 0 &&
                    originalPrice > price) {
                  discount =
                      (((originalPrice - price) / originalPrice) * 100).clamp(0, 100);
                  discountType = 'percent';
                }

                final avgRatingValue = itemJson['avg_rating'];
                final avgRating = avgRatingValue != null
                    ? (avgRatingValue is num
                        ? avgRatingValue.toDouble()
                        : double.tryParse(avgRatingValue.toString()) ?? 0.0)
                    : null;

                final String normalizedImageUrl = _normalizeImageUrl(
                  itemJson['image_full_url']?.toString(),
                  fallbackImage: itemJson['image']?.toString(),
                );

                return Item(
                  id: id,
                  name: itemJson['name']?.toString(),
                  imageFullUrl: normalizedImageUrl.isNotEmpty
                      ? normalizedImageUrl
                      : null,
                  imageStatus: normalizedImageUrl.isNotEmpty ? 'ok' : 'invalid',
                  price: price,
                  originalPrice: originalPrice,
                  discount: discount,
                  discountType: discountType,
                  avgRating: avgRating,
                  // All other fields remain null (handled gracefully by Item model)
                );
              }
              return null;
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ JsonIsolateHelper: Error parsing slim item: $e');
              }
              return null;
            }
          })
          .whereType<Item>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JsonIsolateHelper._parseSlimItemsList: Error: $e');
      }
      return [];
    }
  }

  static String _normalizeImageUrl(String? imageFullUrl, {String? fallbackImage}) {
    String candidate = (imageFullUrl ?? '').trim();
    if (candidate.isEmpty || candidate == 'null') {
      candidate = (fallbackImage ?? '').trim();
    }
    if (candidate.isEmpty || candidate == 'null') return '';

    if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
      return candidate;
    }

    final String base = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;

    if (candidate.startsWith('/')) {
      return '$base$candidate';
    }

    // If backend sends "storage/..." or similar relative path
    if (candidate.startsWith('storage/')) {
      return '$base/$candidate';
    }

    // Last fallback: assume item image file name
    return '$base/storage/item/$candidate';
  }
}
