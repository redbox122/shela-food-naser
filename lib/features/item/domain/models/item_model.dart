import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

void _logVerbose(String message) {
  if (kDebugMode && AppConstants.enableVerboseLogs) {
    debugPrint(message);
  }
}

class ItemModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<Item>? items;
  List<Categories>? categories;

  // New fields for category counting fix
  int? directCount;
  int? recursiveCount;
  bool? includeChildren;

  ItemModel(
      {this.totalSize,
      this.limit,
      this.offset,
      this.items,
      this.categories,
      this.directCount,
      this.recursiveCount,
      this.includeChildren});

  ItemModel.fromJson(Map<String, dynamic> json) {
    totalSize = json.parseInt('total_size') ?? json.parseInt('products_count');
    limit = json.parseStringOrEmpty('limit');
    offset = json.parseInt('offset');

    // Parse new fields for category counting fix
    directCount = json.parseInt('direct_count');
    recursiveCount = json.parseInt('recursive_count');
    includeChildren = json.parseBool('include_children');
    
    items = json.parseList<Item>('products', (v) => Item.fromJson(v as Map<String, dynamic>));
    
    // Handle items array with module type filtering
final itemsList = json.parseList<Map<String, dynamic>>(
  'items',
  (v) => v as Map<String, dynamic>,
);
    if (itemsList != null && itemsList.isNotEmpty) {
      items = [];
      for (final v in itemsList) {
        final moduleType = JsonParser.toStringValue(v['module_type']);
        if (moduleType == null ||
            !(Get.find<SplashController>()
                    .getModuleConfig(moduleType)
                    .newVariation ??
                false) ||
            v['variations'] == null ||
            (v['variations'] as List).isEmpty ||
            (v['food_variations'] != null && (v['food_variations'] as List).isNotEmpty)) {
          items!.add(Item.fromJson(v));
        }
      }
    }
    
    categories = json.parseList<Categories>('categories', (v) => Categories.fromJson(v as Map<String, dynamic>));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (items != null) {
      data['products'] = items!.map((v) => v.toJson()).toList();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Item {
  int? id;
  String? name;
  String? description;
  String? imageFullUrl;
  List<String>? imagesFullUrl;
  String imageStatus = 'invalid';
  int? categoryId;
  List<CategoryIds>? categoryIds;
  List<Variation>? variations;
  List<FoodVariation>? foodVariations;
  List<AddOns>? addOns;
  List<ChoiceOptions>? choiceOptions;
  double? price;
  double? originalPrice;
  double? tax;
  double? discount;
  String? discountType;
  String? availableTimeStarts;
  String? availableTimeEnds;
  int? storeId;
  String? storeName;
  int? zoneId;
  double? storeDiscount;
  bool? scheduleOrder;
  double? avgRating;
  int? ratingCount;
  int? veg;
  int? moduleId;
  String? moduleType;
  String? unitType;
  int? stock;
  String? itemCode;
  String? availableDateStarts;
  int? organic;
  int? quantityLimit;
  int? flashSale;
  bool? isStoreHalalActive;
  bool? isHalalItem;
  bool? isPrescriptionRequired;
  List<String>? nutritionsName;
  List<String>? allergiesName;
  List<String>? genericName;
  List<Item>? recommendedItems;
  List<Preset>? presets;
  Nutrition? nutrition;
  String? wishlistedAt;

  /// When the user added this item to favourites (null if the API omits it).
  DateTime? get wishlistedAtDate {
    if (wishlistedAt != null && wishlistedAt!.isNotEmpty) {
      return DateTime.tryParse(wishlistedAt!)?.toLocal();
    }
    return null;
  }

  Item({
    this.id,
    this.name,
    this.description,
    this.imageFullUrl,
    this.imagesFullUrl,
    this.imageStatus = 'invalid',
    this.categoryId,
    this.categoryIds,
    this.variations,
    this.foodVariations,
    this.addOns,
    this.choiceOptions,
    this.price,
    this.originalPrice,
    this.tax,
    this.discount,
    this.discountType,
    this.availableTimeStarts,
    this.availableTimeEnds,
    this.storeId,
    this.storeName,
    this.zoneId,
    this.storeDiscount,
    this.scheduleOrder,
    this.avgRating,
    this.ratingCount,
    this.veg,
    this.moduleId,
    this.moduleType,
    this.unitType,
    this.stock,
    this.itemCode,
    this.availableDateStarts,
    this.organic,
    this.quantityLimit,
    this.flashSale,
    this.isStoreHalalActive,
    this.isHalalItem,
    this.isPrescriptionRequired,
    this.nutritionsName,
    this.allergiesName,
    this.genericName,
    this.recommendedItems,
    this.presets,
    this.nutrition,
  });

  Item.fromJson(Map<String, dynamic> json) {
    // 🧪 DEBUG: Temporary logs to inspect image fields
    const bool logEnabled = kDebugMode && AppConstants.enableVerboseLogs;
    if (logEnabled) {
      _logVerbose('🧪 ITEM → id=${json['id']} | name=${json['name']}');
      _logVerbose('🧪 IMAGE RAW → ${json['image']}');
      _logVerbose('🧪 IMAGE FULL → ${json['image_full_url']}');
      _logVerbose('🧪 IMAGES FULL URL → ${json['images_full_url']}');
    }
    
    id = json.parseInt('id');
    wishlistedAt = json.parseString('wishlisted_at') ??
        json.parseString('favorited_at') ??
        json.parseString('wishlist_created_at');
    name = json.parseString('name');
    description = json.parseString('description');
    // 🎯 TASK 3: Ensure JPEG format in image URLs (backend forces JPEG to prevent decode crashes)
    final rawImageUrl = json.parseStringOrEmpty('image_full_url');
    final fallbackImageUrl = json.parseStringOrEmpty('image');
    final resolvedImageUrl =
        rawImageUrl.isNotEmpty ? rawImageUrl : fallbackImageUrl;
    imageFullUrl = resolvedImageUrl.isNotEmpty
        ? resolvedImageUrl.replaceAll('format=auto', 'format=jpg')
        : null;
    imageStatus = json.parseString('image_status') ??
        (imageFullUrl != null && imageFullUrl!.isNotEmpty ? 'ok' : 'invalid');
    imagesFullUrl = json.parseList<String>('images_full_url', (v) {
      final url = JsonParser.parseStringOrEmpty(v);
      return url.replaceAll('format=auto', 'format=jpg');
    })?.where((url) => !url.contains('img2.jpg')).toList();
    categoryId = json.parseInt('category_id');
    categoryIds = json.parseList<CategoryIds>('category_ids', (v) => CategoryIds.fromJson(v as Map<String, dynamic>));
    variations = [];
    if (json['variations'] != null) {
      for (var v in (json['variations'] as List)) {
        variations!.add(Variation.fromJson(v as Map<String, dynamic>));
      }
    }
    foodVariations = [];
    if (json['food_variations'] != null &&
        json['food_variations'] is List &&
        (json['food_variations'] as List).isNotEmpty) {
      // 🔍 DEBUG: Log raw food_variations data
      if (logEnabled) {
        _logVerbose(
            '🔍 [Item.fromJson] Parsing ${json['food_variations'].length} food_variations');
      }
      for (var v in (json['food_variations'] as List)) {
        try {
          final variation = FoodVariation.fromJson(v as Map<String, dynamic>);
          foodVariations!.add(variation);
          // ✅ Debug: Log variation details to understand duplicates
          if (logEnabled) {
            _logVerbose('🔍 [Item.fromJson] Parsed variation:');
            _logVerbose('   - ID: ${variation.id}');
            _logVerbose('   - Name: ${variation.name}');
            _logVerbose(
                '   - Type: ${variation.multiSelect == true ? "multi" : "single"}');
            _logVerbose(
                '   - Values count: ${variation.variationValues?.length ?? 0}');
          }
        } catch (e) {
          if (logEnabled) {
            _logVerbose('❌ [Item.fromJson] Error parsing food_variation: $e');
            _logVerbose('❌ [Item.fromJson] Variation data: $v');
          }
        }
      }
      if (logEnabled) {
        _logVerbose(
            '🔍 [Item.fromJson] Successfully parsed ${foodVariations!.length} food_variations');
      }

      // ✅ Debug: Check for duplicate variation names
      if (logEnabled && foodVariations!.length > 1) {
        final nameCounts = <String, int>{};
        for (final v in foodVariations!) {
          final name = v.name ?? 'unnamed';
          nameCounts[name] = (nameCounts[name] ?? 0) + 1;
        }
        final duplicates =
            nameCounts.entries.where((e) => e.value > 1).toList();
        if (duplicates.isNotEmpty) {
          if (logEnabled) {
            _logVerbose(
                '⚠️ [Item.fromJson] Found ${duplicates.length} duplicate variation name(s):');
          }
          for (final dup in duplicates) {
            if (logEnabled) {
              _logVerbose('   - "${dup.key}": appears ${dup.value} times');
            }
          }
          if (logEnabled) {
            _logVerbose(
                '   💡 This may be a backend data issue - consider merging or renaming variations');
          }
        }
      }
    } else {
      // 🔍 DEBUG: Log why food_variations weren't parsed
      if (logEnabled) {
        if (json['food_variations'] == null) {
          _logVerbose('🔍 [Item.fromJson] food_variations is null');
        } else if (json['food_variations'] is! List) {
          _logVerbose(
              '🔍 [Item.fromJson] food_variations is not a List, type: ${json['food_variations'].runtimeType}');
        } else if ((json['food_variations'] as List).isEmpty) {
          _logVerbose('🔍 [Item.fromJson] food_variations is empty list');
        }
      }
    }
    if (json['add_ons'] != null || json['addons'] != null) {
      addOns = [];
      final dynamic rawAddOns = json['add_ons'] ?? json['addons'];
      if (rawAddOns is List) {
        if (rawAddOns.isNotEmpty && rawAddOns.first != '[') {
          for (final v in rawAddOns) {
            if (v is Map<String, dynamic>) {
              addOns!.add(AddOns.fromJson(v));
            }
          }
        }
      } else if (rawAddOns is String) {
        final String stringValue = rawAddOns.trim();
        if (stringValue.isNotEmpty && stringValue != '[]') {
          try {
            final dynamic decoded = jsonDecode(stringValue);
            if (decoded is List) {
              for (final v in decoded) {
                if (v is Map<String, dynamic>) {
                  addOns!.add(AddOns.fromJson(v));
                }
              }
            }
          } catch (_) {
            if (logEnabled) {
              _logVerbose(
                  '⚠️ [Item.fromJson] add_ons is invalid JSON string: $stringValue');
            }
          }
        }
      }
    }
    // ✅ FIX: Handle choice_options with defensive type checking
    // Backend sometimes returns String ("", "[]") instead of List
    // This handles all cases: List, Map, String (empty or JSON), null
    choiceOptions = [];
    if (json['choice_options'] != null) {
      try {
        final rawChoiceOptions = json['choice_options'];
        
        // Case 1: Already a List (standard case)
        if (rawChoiceOptions is List) {
          for (final v in rawChoiceOptions) {
            try {
              if (v != null && v is Map) {
                choiceOptions!
                    .add(ChoiceOptions.fromJson(v as Map<String, dynamic>));
              }
            } catch (e) {
              if (logEnabled) {
                _logVerbose(
                    '⚠️ [Item.fromJson] Error parsing choice_option: $e');
              }
              // Skip this choice option but continue
            }
          }
        }
        // Case 2: Map (unexpected but handle gracefully)
        else if (rawChoiceOptions is Map) {
          (rawChoiceOptions).forEach((key, value) {
            try {
              if (value != null && value is Map) {
                choiceOptions!
                    .add(ChoiceOptions.fromJson(value as Map<String, dynamic>));
              }
            } catch (e) {
              if (logEnabled) {
                _logVerbose(
                    '⚠️ [Item.fromJson] Error parsing choice_option from Map: $e');
              }
              // Skip this choice option but continue
            }
          });
        }
        // Case 3: String (empty string or JSON string) - decode to List
        else if (rawChoiceOptions is String) {
          final stringValue = rawChoiceOptions.trim();
          if (stringValue.isEmpty || stringValue == 'null') {
            // Empty string or "null" string → empty list
            choiceOptions = [];
          } else {
            // Try to decode JSON string to List
            try {
              final decoded = jsonDecode(stringValue);
              if (decoded is List) {
                for (final v in decoded) {
                  try {
                    if (v != null && v is Map) {
                      choiceOptions!
                          .add(ChoiceOptions.fromJson(v as Map<String, dynamic>));
                    }
                  } catch (e) {
                    if (logEnabled) {
                      _logVerbose(
                          '⚠️ [Item.fromJson] Error parsing choice_option from decoded String: $e');
                    }
                    // Skip this choice option but continue
                  }
                }
              } else {
                // Decoded but not a List → empty list
                if (logEnabled) {
                  _logVerbose(
                      '⚠️ [Item.fromJson] choice_options String decoded but not a List: ${decoded.runtimeType}');
                }
                choiceOptions = [];
              }
            } catch (e) {
              // JSON decode failed → empty list (silent, no log spam)
              choiceOptions = [];
            }
          }
        }
        // Case 4: Unexpected type → empty list (silent)
        else {
          // Silent fallback - no log spam for unexpected types
          choiceOptions = [];
        }
      } catch (e, stackTrace) {
        // ✅ CRITICAL: If choice_options parsing fails completely, just use empty list
        // Don't let choice_options parsing errors break item parsing
        _logVerbose(
            '❌ [Item.fromJson] Critical error parsing choice_options: $e');
        _logVerbose('   - Stack trace: $stackTrace');
        choiceOptions = [];
      }
    }
    price = json.parseDouble('price');
    originalPrice = json.parseDouble('original_price');
    tax = json.parseDouble('tax');
    discount = json.parseDouble('discount');
    discountType = json.parseString('discount_type');
    availableTimeStarts = json.parseString('available_time_starts');
    availableTimeEnds = json.parseString('available_time_ends');
    storeId = json.parseInt('store_id');
    storeName = json.parseString('store_name');
    zoneId = json.parseInt('zone_id');
    storeDiscount = json.parseDouble('store_discount');
    scheduleOrder = json.parseBool('schedule_order');
    avgRating = json.parseDouble('avg_rating');
    ratingCount = json.parseInt('rating_count');
    moduleId = json.parseInt('module_id');
    moduleType = json.parseString('module_type') ??
        JsonParser.toStringValue(
            (json['module'] as Map<String, dynamic>?)?['module_type']) ??
        AppConstants.food;
    veg = json.parseInt('veg') ?? 0;
    stock = json.parseInt('stock');
    itemCode = json.parseString('item_code');
    unitType = json.parseString('unit_type');
    availableDateStarts = json.parseString('available_date_starts');
    organic = json.parseInt('organic');
    quantityLimit = json.parseInt('maximum_cart_quantity');
    flashSale = json.parseInt('flash_sale');
    isStoreHalalActive = json.parseInt('halal_tag_status') == 1;
    isHalalItem = json.parseInt('is_halal') == 1;
    isPrescriptionRequired = json.parseInt('is_prescription_required') == 1;
    nutritionsName = json.parseList<String>('nutritions_name', (v) => JsonParser.parseStringOrEmpty(v));
    allergiesName = json.parseList<String>('allergies_name', (v) => JsonParser.parseStringOrEmpty(v));
    genericName = json.parseList<String>('generic_name', (v) => JsonParser.parseStringOrEmpty(v));

    // Parse nutrition object
    final nutritionMap = json.parseMap('nutrition');
    if (nutritionMap != null) {
      try {
        nutrition = Nutrition.fromJson(nutritionMap);
      } catch (e) {
        if (logEnabled) {
          _logVerbose('⚠️ [Item.fromJson] Error parsing nutrition: $e');
        }
        nutrition = null;
      }
    }

    // Parse recommended_items array
    recommendedItems = json.parseList<Item>('recommended_items', (v) {
      if (v is Map<String, dynamic>) {
        return Item.fromJson(v);
      }
      throw const FormatException('Invalid recommended item format');
    });
    if (recommendedItems != null && recommendedItems!.isEmpty) {
      recommendedItems = null;
    }

    // Parse presets array - ✅ Wrap entire section in try-catch to prevent breaking item parsing
    presets = [];
    try {
      if (logEnabled) {
        _logVerbose('🔍 [Item.fromJson] Checking presets field...');
        _logVerbose('   - presets exists: ${json['presets'] != null}');
        _logVerbose('   - presets type: ${json['presets']?.runtimeType}');
      }

      // ✅ Handle null presets gracefully
      if (json['presets'] == null) {
        if (logEnabled) {
          _logVerbose('   - presets is null, using empty array');
        }
        presets = [];
      } else if (json['presets'] is String) {
        final String rawPresets = (json['presets'] as String).trim();
        if (rawPresets.isEmpty) {
          if (logEnabled) {
            _logVerbose('   - presets is empty string, using empty array');
          }
          presets = [];
        } else {
          try {
            final dynamic decoded = jsonDecode(rawPresets);
            if (decoded is List) {
              final presetsList = decoded;
              if (logEnabled) {
                _logVerbose('   - presets count: ${presetsList.length}');
              }
              if (presetsList.isNotEmpty) {
                if (logEnabled) {
                  _logVerbose('🔍 [Item.fromJson] Parsing ${presetsList.length} presets');
                }
                for (final presetJson in presetsList) {
                  if (presetJson != null && presetJson is Map<String, dynamic>) {
                    presets!.add(Preset.fromJson(presetJson));
                  }
                }
                if (logEnabled) {
                  _logVerbose(
                      '✅ [Item.fromJson] Successfully parsed ${presets!.length} presets');
                }
              } else {
                if (logEnabled) {
                  _logVerbose('   - presets list is empty');
                }
                presets = [];
              }
            } else {
              if (logEnabled) {
                _logVerbose('⚠️ [Item.fromJson] presets string decoded to non-list');
              }
              presets = [];
            }
          } catch (_) {
            if (logEnabled) {
              _logVerbose('❌ [Item.fromJson] Error decoding presets string');
            }
            presets = [];
          }
        }
      } else if (json['presets'] is List) {
        final presetsList = json['presets'] as List;
        if (logEnabled) {
          _logVerbose('   - presets count: ${presetsList.length}');
        }

        if (presetsList.isNotEmpty) {
          if (logEnabled) {
            _logVerbose('🔍 [Item.fromJson] Parsing ${presetsList.length} presets');
          }
          for (final presetJson in presetsList) {
            if (presetJson != null) {
              try {
                if (logEnabled) {
                  _logVerbose(
                      '   📦 Parsing preset: ${presetJson['name'] ?? presetJson['name_ar'] ?? 'unnamed'}');
                  _logVerbose('      - name: ${presetJson['name']}');
                  _logVerbose('      - name_ar: ${presetJson['name_ar']}');
                  _logVerbose('      - name_en: ${presetJson['name_en']}');
                  _logVerbose('      - price: ${presetJson['price']}');
                }
                if (presetJson is Map &&
                    presetJson['preset_data'] != null &&
                    presetJson['preset_data'] is Map &&
                    presetJson['preset_data']['choice_groups'] != null) {
                  if (logEnabled) {
                    _logVerbose(
                        '      - choice_groups count: ${(presetJson['preset_data']['choice_groups'] as List).length}');
                  }
                }
                // ✅ Ensure presetJson is a Map before parsing
                if (presetJson is Map<String, dynamic>) {
                  presets!.add(Preset.fromJson(presetJson));
                } else {
                  if (logEnabled) {
                    _logVerbose(
                        '⚠️ [Item.fromJson] Preset is not a Map, skipping: ${presetJson.runtimeType}');
                  }
                }
              } catch (e, stackTrace) {
                if (logEnabled) {
                  _logVerbose('❌ [Item.fromJson] Error parsing preset: $e');
                  _logVerbose('   - Stack trace: $stackTrace');
                }
                // Skip this preset but continue parsing others
              }
            }
          }
          if (logEnabled) {
            _logVerbose(
                '✅ [Item.fromJson] Successfully parsed ${presets!.length} presets');
          }
        } else {
          if (logEnabled) {
            _logVerbose('   - presets list is empty');
          }
          presets = [];
        }
      } else {
        if (logEnabled) {
          _logVerbose(
              '⚠️ [Item.fromJson] presets is not a List, type: ${json['presets'].runtimeType}');
        }
        presets = [];
      }
    } catch (e, stackTrace) {
      // ✅ CRITICAL: If preset parsing fails completely, just use empty array
      // Don't let preset parsing errors break item parsing
      if (logEnabled) {
        _logVerbose(
            '❌ [Item.fromJson] Critical error in preset parsing, using empty array: $e');
        _logVerbose('   - Stack trace: $stackTrace');
      }
      presets = [];
    }

    // ✅ FIX: Keep presets as empty array (never null) - Backend always returns [] when empty
    // Backend requirement: Always return presets: [] (never null)
    // This prevents null check operator crashes
    if (presets!.isEmpty) {
      presets = []; // Keep as empty array, don't set to null
      if (logEnabled) {
        _logVerbose(
            '🔍 [Item.fromJson] presets is empty, keeping as empty array (not null)');
      }
    }
  }

  /// 🎯 FIX: Get display image URL with fallback priority
  /// Prevents ImageDecoder crashes by ensuring we always have a valid URL or null
  String? get displayImage {
    // Priority: imageFullUrl → first image from imagesFullUrl → null
    if (imageFullUrl != null && imageFullUrl!.isNotEmpty && imageFullUrl != 'null') {
      return imageFullUrl;
    }
    if (imagesFullUrl != null && imagesFullUrl!.isNotEmpty) {
      final firstImage = imagesFullUrl!.first;
      if (firstImage.isNotEmpty &&
          firstImage != 'null' &&
          !firstImage.contains('img2.jpg')) {
        return firstImage;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['image_full_url'] = imageFullUrl;
    data['images_full_url'] = imagesFullUrl;
    data['image_status'] = imageStatus;
    data['category_id'] = categoryId;
    if (categoryIds != null) {
      data['category_ids'] = categoryIds!.map((v) => v.toJson()).toList();
    }
    if (variations != null) {
      data['variations'] = variations!.map((v) => v.toJson()).toList();
    }
    if (foodVariations != null) {
      data['food_variations'] = foodVariations!.map((v) => v.toJson()).toList();
    }
    if (addOns != null) {
      data['add_ons'] = addOns!.map((v) => v.toJson()).toList();
    }
    if (choiceOptions != null) {
      data['choice_options'] = choiceOptions!.map((v) => v.toJson()).toList();
    }
    data['price'] = price;
    data['original_price'] = originalPrice;
    data['tax'] = tax;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['available_time_starts'] = availableTimeStarts;
    data['available_time_ends'] = availableTimeEnds;
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['zone_id'] = zoneId;
    data['store_discount'] = storeDiscount;
    data['schedule_order'] = scheduleOrder;
    data['avg_rating'] = avgRating;
    data['rating_count'] = ratingCount;
    data['veg'] = veg;
    data['module_id'] = moduleId;
    data['module_type'] = moduleType;
    data['stock'] = stock;
    data['item_code'] = itemCode;
    data['unit_type'] = unitType;
    data['available_date_starts'] = availableDateStarts;
    data['organic'] = organic;
    data['maximum_cart_quantity'] = quantityLimit;
    data['flash_sale'] = flashSale;
    data['halal_tag_status'] = isStoreHalalActive;
    data['is_halal'] = isHalalItem;
    data['is_prescription_required'] = isPrescriptionRequired;
    data['nutritions_name'] = nutritionsName;
    data['allergies_name'] = allergiesName;
    data['generic_name'] = genericName;
    if (nutrition != null) {
      data['nutrition'] = nutrition!.toJson();
    }
    return data;
  }
}

/// Nutrition model for item nutrition values
class Nutrition {
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final bool? nutritionPer100g;
  final String? nutritionSource;

  Nutrition({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.nutritionPer100g,
    this.nutritionSource,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json.parseInt('calories'),
      protein: json.parseDouble('protein'),
      carbs: json.parseDouble('carbs'),
      fat: json.parseDouble('fat'),
      fiber: json.parseDouble('fiber'),
      nutritionPer100g: json.parseBool('nutrition_per_100g'),
      nutritionSource: json.parseString('nutrition_source'),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['calories'] = calories;
    data['protein'] = protein;
    data['carbs'] = carbs;
    data['fat'] = fat;
    data['fiber'] = fiber;
    data['nutrition_per_100g'] = nutritionPer100g == true ? 1 : 0;
    data['nutrition_source'] = nutritionSource;
    return data;
  }
}

class CategoryIds {
  int? id;
  int? position;
  String? name;

  CategoryIds({this.id, this.position, this.name});

  CategoryIds.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id') ?? 0;
    position = json.parseInt('position') ?? 0;
    name = json.parseString('name');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['position'] = position;
    data['name'] = name;
    return data;
  }
}

class Variation {
  String? type;
  double? price;
  int? stock;

  Variation({this.type, this.price, this.stock});

  Variation.fromJson(Map<String, dynamic> json) {
    type = json.parseString('type');
    price = json.parseDouble('price');
    stock = json.parseInt('stock') ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['price'] = price;
    data['stock'] = stock;
    return data;
  }
}

class AddOns {
  int? id;
  String? name;
  double? price;

  AddOns({
    this.id,
    this.name,
    this.price,
  });

  AddOns.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json.parseString('name');
    price = json.parseDouble('price') ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['price'] = price;
    return data;
  }
}

class ChoiceOptions {
  String? name;
  String? title;
  List<String>? options;

  ChoiceOptions({this.name, this.title, this.options});

  ChoiceOptions.fromJson(Map<String, dynamic> json) {
    name = json.parseString('name');
    title = json.parseString('title');
    options = json.parseList<String>('options', (v) => JsonParser.parseStringOrEmpty(v));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['title'] = title;
    data['options'] = options;
    return data;
  }
}

class FoodVariation {
  int? id;
  String? name;
  bool? multiSelect;
  int? min;
  int? max;
  bool? required;
  List<VariationValue>? variationValues;

  FoodVariation(
      {this.id,
      this.name,
      this.multiSelect,
      this.min,
      this.max,
      this.required,
      this.variationValues});

  FoodVariation.fromJson(Map<String, dynamic> json) {
    // Parse ID if available (for matching with presets)
    id = json.parseInt('id');
    // ✅ FIX: Parse even if max is null (use default values)
    name = json.parseString('name');
    multiSelect = json.getStringValue('type') == 'multi';

    // Handle min field
    final minValue = json.parseInt('min');
    if (minValue != null) {
      min = multiSelect == true ? minValue : 0;
    } else {
      min = multiSelect == true ? 1 : 0; // Default min = 1 for multi, 0 for single
    }

    // Handle max field
    final maxValue = json.parseInt('max');
    if (maxValue != null) {
      max = multiSelect == true ? maxValue : 0;
    } else {
      max = multiSelect == true ? 1 : 0; // Default max = 1 for multi, 0 for single
    }

    // Handle required field - support both string "on" and boolean true
    required = json.parseBool('required');

    // ✅ FIX: Support both "options" (backend format) and "values" (legacy format)
    dynamic optionsData = json['options'] ??
        json['values'] ??
        json['variationValues'] ??
        json['variation_values'];
    if (optionsData is String && optionsData.trim().isNotEmpty) {
      try {
        optionsData = jsonDecode(optionsData);
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
    }
    if (optionsData != null && optionsData is List) {
      variationValues = [];
      _logVerbose(
          '🔍 [FoodVariation.fromJson] Found ${optionsData.length} options/values for variation: ${json['name']}');
      for (final v in optionsData) {
        try {
          if (v is Map<String, dynamic>) {
            variationValues!.add(VariationValue.fromJson(v));
          }
        } catch (e) {
          // Log parsing error but continue with other values
          _logVerbose('❌ [FoodVariation.fromJson] Error parsing variation value: $e');
          _logVerbose('❌ [FoodVariation.fromJson] Value data: $v');
        }
      }
      _logVerbose(
          '🔍 [FoodVariation.fromJson] Successfully parsed ${variationValues!.length} variation values');
    } else {
      _logVerbose(
          '⚠️ [FoodVariation.fromJson] No options/values found for variation: ${json['name']}');
      _logVerbose(
          '⚠️ [FoodVariation.fromJson] optionsData: $optionsData, type: ${optionsData?.runtimeType}');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['type'] = multiSelect;
    data['min'] = min;
    data['max'] = max;
    data['required'] = required;
    if (variationValues != null) {
      data['values'] = variationValues!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VariationValue {
  int? id;
  String? level;
  double? optionPrice;
  bool? isSelected;

  VariationValue({
    this.id,
    this.level,
    this.optionPrice,
    this.isSelected,
  });

  VariationValue.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');

    level = json.parseString('label')
        ?? json.parseString('level')
        ?? json.parseString('value')
        ?? json.parseString('name')
        ?? json.parseString('name_ar')
        ?? json.parseString('name_en')
        ?? '';

    optionPrice = json.parseDouble('optionPrice')
        ?? json.parseDouble('option_price')
        ?? json.parseDouble('extra_price')
        ?? json.parseDouble('price')
        ?? 0.0;

    isSelected = json.parseBool('isSelected');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': level,
      'option_price': optionPrice,
      'isSelected': isSelected,
    };
  }
}

/// Preset model for item presets (popular combinations)
class Preset {
  final int id;
  final String? externalPresetId;
  final String? name;
  final String? nameAr;
  final String? nameEn;
  final double? price;
  final int status;
  final PresetData? presetData;

  Preset({
    required this.id,
    this.externalPresetId,
    this.name,
    this.nameAr,
    this.nameEn,
    this.price,
    required this.status,
    this.presetData,
  });

  factory Preset.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Handle preset_data as either Map or JSON string
    // Wrap entire parsing in try-catch to prevent breaking item parsing
    PresetData? presetData;
    if (json['preset_data'] != null) {
      try {
        final dynamic presetDataValue = json['preset_data'];

        // Handle different types of preset_data
        if (presetDataValue is Map<String, dynamic>) {
          // Already a Map - use directly
          presetData = PresetData.fromJson(presetDataValue);
        } else if (presetDataValue is String) {
          // JSON string - decode first
          try {
            final decoded = jsonDecode(presetDataValue) as Map<String, dynamic>;
            presetData = PresetData.fromJson(decoded);
          } catch (decodeError) {
            _logVerbose(
                '⚠️ [Preset.fromJson] Error decoding JSON string: $decodeError');
            presetData = null;
          }
        } else {
          // Try to cast to Map
          try {
            presetData =
                PresetData.fromJson(presetDataValue as Map<String, dynamic>);
          } catch (castError) {
            _logVerbose(
                '⚠️ [Preset.fromJson] Error casting to Map: $castError');
            _logVerbose(
                '   - preset_data type: ${presetDataValue.runtimeType}');
            presetData = null;
          }
        }
      } catch (e, stackTrace) {
        _logVerbose('⚠️ [Preset.fromJson] Error parsing preset_data: $e');
        _logVerbose(
            '   - preset_data type: ${json['preset_data']?.runtimeType}');
        _logVerbose('   - Stack trace: $stackTrace');
        presetData = null;
      }
    }

    return Preset(
      id: json.parseInt('id') ?? 0,
      externalPresetId: json.parseString('external_preset_id'),
      name: json.parseString('name'),
      nameAr: json.parseString('name_ar'),
      nameEn: json.parseString('name_en'),
      price: json.parseDouble('price'),
      status: json.parseInt('status') ?? 0,
      presetData: presetData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['external_preset_id'] = externalPresetId;
    data['name'] = name;
    data['name_ar'] = nameAr;
    data['name_en'] = nameEn;
    data['price'] = price;
    data['status'] = status;
    if (presetData != null) {
      data['preset_data'] = presetData!.toJson();
    }
    return data;
  }
}

/// Preset data containing choice groups
class PresetData {
  final List<PresetChoiceGroup>? choiceGroups;

  PresetData({this.choiceGroups});

  factory PresetData.fromJson(Map<String, dynamic> json) {
    try {
      List<PresetChoiceGroup>? choiceGroups;
      if (json['choice_groups'] != null) {
        try {
          final dynamic rawGroups = json['choice_groups'];
          List<dynamic>? groupsList;
          if (rawGroups is List) {
            groupsList = rawGroups;
          } else if (rawGroups is String && rawGroups.trim().isNotEmpty) {
            final dynamic decoded = jsonDecode(rawGroups);
            if (decoded is List) {
              groupsList = decoded;
            }
          }
          if (groupsList != null) {
            choiceGroups = groupsList
                .map((e) {
                  try {
                    if (e is Map<String, dynamic>) {
                      return PresetChoiceGroup.fromJson(e);
                    } else {
                      _logVerbose(
                          '⚠️ [PresetData.fromJson] Invalid choice group type: ${e.runtimeType}');
                      return null;
                    }
                  } catch (e) {
                    _logVerbose(
                        '⚠️ [PresetData.fromJson] Error parsing choice group: $e');
                    return null;
                  }
                })
                .whereType<PresetChoiceGroup>()
                .toList();
          } else {
            _logVerbose(
                '⚠️ [PresetData.fromJson] choice_groups is not a List: ${rawGroups.runtimeType}');
            choiceGroups = null;
          }
        } catch (e) {
          _logVerbose(
              '⚠️ [PresetData.fromJson] Error parsing choice_groups: $e');
          choiceGroups = null;
        }
      }

      return PresetData(choiceGroups: choiceGroups);
    } catch (e, stackTrace) {
      _logVerbose('⚠️ [PresetData.fromJson] Error parsing PresetData: $e');
      _logVerbose('   - Stack trace: $stackTrace');
      return PresetData();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (choiceGroups != null) {
      data['choice_groups'] = choiceGroups!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// Choice group within preset data
class PresetChoiceGroup {
  final int id;
  final List<PresetChoice> choices;

  PresetChoiceGroup({
    required this.id,
    required this.choices,
  });

  factory PresetChoiceGroup.fromJson(Map<String, dynamic> json) {
    try {
      List<PresetChoice> choices = [];
      if (json['choices'] != null && json['choices'] is List) {
        try {
          final choicesList = json['choices'] as List;
          choices = choicesList
              .map((e) {
                try {
                  if (e is Map<String, dynamic>) {
                    return PresetChoice.fromJson(e);
                  } else {
                    _logVerbose(
                        '⚠️ [PresetChoiceGroup.fromJson] Invalid choice type: ${e.runtimeType}');
                    return null;
                  }
                } catch (e) {
                  _logVerbose(
                      '⚠️ [PresetChoiceGroup.fromJson] Error parsing choice: $e');
                  return null;
                }
              })
              .whereType<PresetChoice>()
              .toList();
        } catch (e) {
          _logVerbose(
              '⚠️ [PresetChoiceGroup.fromJson] Error parsing choices list: $e');
          choices = [];
        }
      }

      return PresetChoiceGroup(
        id: json['id'] as int,
        choices: choices,
      );
    } catch (e, stackTrace) {
      _logVerbose('❌ [PresetChoiceGroup.fromJson] Critical error: $e');
      _logVerbose('   - Stack trace: $stackTrace');
      // Return empty choices if parsing fails
      return PresetChoiceGroup(
        id: (json['id'] as int?) ?? 0,
        choices: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['choices'] = choices.map((v) => v.toJson()).toList();
    return data;
  }
}

/// Individual choice within a preset choice group
class PresetChoice {
  final int id;
  final String? name;
  final String? nameAr;
  final String? nameEn;

  PresetChoice({
    required this.id,
    this.name,
    this.nameAr,
    this.nameEn,
  });

  factory PresetChoice.fromJson(Map<String, dynamic> json) {
    return PresetChoice(
      id: json.parseInt('id') ?? 0,
      name: json.parseString('name'),
      nameAr: json.parseString('name_ar'),
      nameEn: json.parseString('name_en'),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['name_ar'] = nameAr;
    data['name_en'] = nameEn;
    return data;
  }
}

