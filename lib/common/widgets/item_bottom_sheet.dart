import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/design_tokens.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/food_order_variation_section.dart';
import 'package:sixam_mart/common/widgets/food_order_option_item.dart';
import 'package:sixam_mart/common/widgets/food_variation_section.dart';
import 'package:sixam_mart/common/widgets/recommended_items_section.dart';
import 'package:sixam_mart/common/widgets/item_presets_section.dart';
import 'package:sixam_mart/common/widgets/nutrition_popup.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Line total for cart rows (unit `discountedPrice` or `price` × quantity).
double _cartLineDisplayTotal(CartModel cartModel) {
  final double unit =
      cartModel.discountedPrice ?? cartModel.price ?? 0.0;
  final int q = cartModel.quantity ?? 1;
  return unit * q;
}

class ItemBottomSheet extends StatefulWidget {
  final Item? item;
  final bool isCampaign;
  final CartModel? cart;
  final int? cartIndex;
  final bool inStorePage;
  const ItemBottomSheet(
      {super.key,
      required this.item,
      this.isCampaign = false,
      this.cart,
      this.cartIndex,
      this.inStorePage = false});

  @override
  State<ItemBottomSheet> createState() => _ItemBottomSheetState();
}

class _ItemBottomSheetState extends State<ItemBottomSheet> {
  bool _isLoading = true;
  Item? _freshItem;
  bool _newVariation = false;
  final TextEditingController _notesController = TextEditingController();
  Preset? _selectedPreset;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _foodVariationSectionKeys = <GlobalKey>[];

  static const int _notesMaxLength = 500;

  void _ensureFoodVariationKeyCount(int count) {
    if (_foodVariationSectionKeys.length == count) {
      return;
    }
    if (_foodVariationSectionKeys.length < count) {
      while (_foodVariationSectionKeys.length < count) {
        _foodVariationSectionKeys.add(GlobalKey());
      }
    } else {
      _foodVariationSectionKeys.length = count;
    }
  }

  void _scrollToFoodVariationIndex(int index) {
    if (index < 0 || index >= _foodVariationSectionKeys.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? targetContext =
          _foodVariationSectionKeys[index].currentContext;
      if (targetContext != null && mounted) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  /// Cart row index for [sheetItem] with current sheet selections only.
  /// Never use [ItemController.cartIndex] here: adding a suggested item calls
  /// [ItemController.setExistInCart] for *that* product and overwrites cartIndex,
  /// which would hide the suggestion from the footer until the next cart change.
  int _indexOfSheetItemInCart(
    CartController cartController,
    ItemController itemController,
    Item? sheetItem,
  ) {
    final int? itemId = sheetItem?.id;
    if (itemId == null) {
      return -1;
    }
    final List<CartModel> cartList = cartController.cartList;
    final List<List<bool?>> variations = itemController.selectedVariations;
    final bool useFoodMatch = sheetItem?.foodVariations != null &&
        sheetItem!.foodVariations!.isNotEmpty;
    if (useFoodMatch) {
      for (int index = 0; index < cartList.length; index++) {
        if (cartList[index].item?.id != itemId) {
          continue;
        }
        if (variations.isNotEmpty) {
          if (cartList[index].foodVariations == null ||
              cartList[index].foodVariations!.isEmpty) {
            continue;
          }
          if (variations.length != cartList[index].foodVariations!.length) {
            continue;
          }
          bool same = false;
          for (int i = 0; i < variations.length; i++) {
            if (cartList[index].foodVariations![i].length !=
                variations[i].length) {
              same = false;
              break;
            }
            for (int j = 0; j < variations[i].length; j++) {
              if (variations[i][j] ==
                  cartList[index].foodVariations![i][j]) {
                same = true;
              } else {
                same = false;
                break;
              }
            }
            if (!same) {
              break;
            }
          }
          if (same) {
            return index;
          }
        } else {
          return index;
        }
      }
      return -1;
    }
    return cartController.isExistInCart(itemId, '', false, null);
  }

  /// Cart lines to show in the sheet footer (excludes the sheet product row only).
  List<CartModel> _otherCartLinesForPreview(
    CartController cartController,
    ItemController itemController,
    Item? sheetItem,
  ) {
    final int? editingCartId = widget.cart?.id;
    if (editingCartId != null) {
      return cartController.cartList
          .where((CartModel c) => c.id != editingCartId)
          .toList(growable: false);
    }
    final int idx = _indexOfSheetItemInCart(
      cartController,
      itemController,
      sheetItem,
    );
    if (idx >= 0 && idx < cartController.cartList.length) {
      final List<CartModel> out = <CartModel>[];
      for (int i = 0; i < cartController.cartList.length; i++) {
        if (i != idx) {
          out.add(cartController.cartList[i]);
        }
      }
      return out;
    }
    return List<CartModel>.from(cartController.cartList);
  }

  /// Apply preset selections to variations
  void _applyPreset(Preset preset) {
    if (preset.presetData?.choiceGroups == null) {
      debugPrint('⚠️ [_applyPreset] Preset has no choice groups');
      return;
    }

    final itemController = Get.find<ItemController>();
    final item = _freshItem ?? widget.item;

    if (item?.foodVariations == null || item!.foodVariations!.isEmpty) {
      debugPrint('⚠️ [_applyPreset] Item has no food variations');
      return;
    }

    debugPrint('🎯 [_applyPreset] Applying preset: ${preset.name}');
    debugPrint(
        '   - Preset choice groups: ${preset.presetData!.choiceGroups!.length}');
    debugPrint('   - Item food variations: ${item.foodVariations!.length}');

    // Clear existing selections
    for (int i = 0; i < itemController.selectedVariations.length; i++) {
      for (int j = 0; j < itemController.selectedVariations[i].length; j++) {
        itemController.selectedVariations[i][j] = false;
      }
    }

    final isArabic = Get.locale?.languageCode == 'ar';
    int matchedCount = 0;
    int totalChoices = 0;

    // Apply preset selections
    for (final presetGroup in preset.presetData!.choiceGroups!) {
      debugPrint(
          '🔍 [_applyPreset] Processing preset group ID: ${presetGroup.id}');
      debugPrint('   - Choices in group: ${presetGroup.choices.length}');

      // Find matching food variation by ID
      int? variationIndex;
      for (int i = 0; i < item.foodVariations!.length; i++) {
        final variation = item.foodVariations![i];
        if (variation.id != null && variation.id == presetGroup.id) {
          variationIndex = i;
          debugPrint(
              '   ✅ Found variation by ID: ${variation.name} (index: $i)');
          break;
        }
      }

      // ✅ FIX: If not found by ID, try matching variation group by name
      if (variationIndex == null) {
        debugPrint(
            '   ⚠️ No variation found by ID ${presetGroup.id}, trying name match...');

        // Get preset group name (use the first choice's name as a hint)
        if (presetGroup.choices.isNotEmpty) {
          final firstChoiceName = isArabic
              ? (presetGroup.choices[0].nameAr ??
                  presetGroup.choices[0].name ??
                  '')
              : (presetGroup.choices[0].nameEn ??
                  presetGroup.choices[0].name ??
                  '');

          debugPrint(
              '   🔍 Looking for variation containing choice: "$firstChoiceName"');

          // Try to find which variation group contains this choice
          for (int i = 0; i < item.foodVariations!.length; i++) {
            final variation = item.foodVariations![i];
            if (variation.variationValues != null) {
              for (final value in variation.variationValues!) {
                final valueLabel = value.level ?? '';

                // Check if this variation contains the preset choice
                if (valueLabel.toLowerCase().trim() ==
                        firstChoiceName.toLowerCase().trim() ||
                    valueLabel
                        .toLowerCase()
                        .contains(firstChoiceName.toLowerCase()) ||
                    firstChoiceName
                        .toLowerCase()
                        .contains(valueLabel.toLowerCase())) {
                  variationIndex = i;
                  debugPrint(
                      '   ✅ Found variation by name match: ${variation.name} (index: $i)');
                  break;
                }
              }
            }
            if (variationIndex != null) break;
          }
        }
      }

      if (variationIndex == null) {
        debugPrint(
            '   ❌ No matching variation found for preset group ID: ${presetGroup.id}');
        continue;
      }

      final variation = item.foodVariations![variationIndex];
      final variationValues = variation.variationValues;

      if (variationValues == null || variationValues.isEmpty) {
        debugPrint('   ⚠️ Variation has no values: ${variation.name}');
        continue;
      }

      debugPrint('   - Variation values available: ${variationValues.length}');

      // Apply choices for this variation group
      for (final presetChoice in presetGroup.choices) {
        totalChoices++;
        final presetChoiceName = isArabic
            ? (presetChoice.nameAr ?? presetChoice.name ?? '')
            : (presetChoice.nameEn ?? presetChoice.name ?? '');

        debugPrint(
            '   🔍 Looking for choice: "$presetChoiceName" (ID: ${presetChoice.id})');

        bool found = false;

        // Try matching by ID first
        for (int j = 0; j < variationValues.length; j++) {
          final variationValue = variationValues[j];
          if (variationValue.id != null &&
              variationValue.id == presetChoice.id) {
            // Ensure selectedVariations array is large enough
            while (itemController.selectedVariations.length <= variationIndex) {
              itemController.selectedVariations.add([]);
            }
            while (
                itemController.selectedVariations[variationIndex].length <= j) {
              itemController.selectedVariations[variationIndex].add(false);
            }
            itemController.selectedVariations[variationIndex][j] = true;
            matchedCount++;
            found = true;
            debugPrint(
                '      ✅ Matched by ID: "${variationValue.level}" (index: $j)');
            break;
          }
        }

        // If not found by ID, try matching by name
        if (!found) {
          debugPrint('      ⚠️ Not found by ID, trying name match...');
          for (int j = 0; j < variationValues.length; j++) {
            final variationValue = variationValues[j];
            final variationLabel = variationValue.level ?? '';

            // Try matching with preset choice name (all languages)
            final matchNames = <String>[
              presetChoiceName,
              presetChoice.name ?? '',
              presetChoice.nameAr ?? '',
              presetChoice.nameEn ?? '',
            ].where((n) => n.isNotEmpty).toList();

            bool nameMatches = false;
            for (final matchName in matchNames) {
              if (variationLabel.toLowerCase().trim() ==
                      matchName.toLowerCase().trim() ||
                  variationLabel
                      .toLowerCase()
                      .contains(matchName.toLowerCase()) ||
                  matchName
                      .toLowerCase()
                      .contains(variationLabel.toLowerCase())) {
                nameMatches = true;
                break;
              }
            }

            if (nameMatches) {
              // Ensure selectedVariations array is large enough
              while (
                  itemController.selectedVariations.length <= variationIndex) {
                itemController.selectedVariations.add([]);
              }
              while (itemController.selectedVariations[variationIndex].length <=
                  j) {
                itemController.selectedVariations[variationIndex].add(false);
              }
              itemController.selectedVariations[variationIndex][j] = true;
              matchedCount++;
              found = true;
              debugPrint(
                  '      ✅ Matched by name: "$variationLabel" (index: $j)');
              break;
            }
          }
        }

        if (!found) {
          debugPrint('      ❌ No match found for choice: "$presetChoiceName"');
        }
      }
    }

    debugPrint('📊 [_applyPreset] Summary:');
    debugPrint('   - Total preset choices: $totalChoices');
    debugPrint('   - Successfully matched: $matchedCount');
    debugPrint('   - Failed to match: ${totalChoices - matchedCount}');

    // ✅ FIX: Force array reassignment to trigger proper rebuild
    // Create new array references to ensure Flutter detects the change
    final updatedVariations = List<List<bool?>>.from(itemController
        .selectedVariations
        .map((inner) => List<bool?>.from(inner)));
    itemController.selectedVariations.clear();
    itemController.selectedVariations.addAll(updatedVariations);

    debugPrint('🔄 [_applyPreset] Force rebuilding UI with updated selections');

    // Update UI
    itemController.update();
    setState(() {});
  }

  /// Handle preset selection
  void _onPresetSelected(Preset preset) {
    debugPrint('👆 [_onPresetSelected] Preset tapped: ${preset.name}');
    setState(() {
      _selectedPreset = preset;
    });
    _applyPreset(preset);
  }

  @override
  void initState() {
    super.initState();

    if (Get.find<SplashController>().module == null) {
      if (Get.find<SplashController>().cacheModule != null) {
        Get.find<SplashController>()
            .setCacheConfigModule(Get.find<SplashController>().cacheModule);
      }
    }
    _newVariation = Get.find<SplashController>()
            .getModuleConfig(widget.item!.moduleType)
            .newVariation ??
        false;

    // Fetch fresh item details from API
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch fresh item details from API
      final itemController = Get.find<ItemController>();
      final freshItem = await itemController.itemServiceInterface
          .getItemDetails(widget.item!.id);

      appLogger.debug('🔍 [_loadItemDetails] Item fetched from API:');
      appLogger.debug('   - Item ID: ${freshItem?.id}');
      appLogger.debug('   - Item name: ${freshItem?.name}');
      appLogger.debug('   - Has presets: ${freshItem?.presets != null}');
      appLogger.debug('   - Presets count: ${freshItem?.presets?.length ?? 0}');
      if (freshItem?.presets != null && freshItem!.presets!.isNotEmpty) {
        appLogger.debug('   - First preset: ${freshItem.presets![0].name}');
      }

      if (freshItem != null) {
        _freshItem = freshItem;
        // If item has food variations, ensure newVariation is enabled
        if (freshItem.foodVariations != null &&
            freshItem.foodVariations!.isNotEmpty) {
          _newVariation = true;
        }
        // Initialize with fresh data
        itemController.initData(_freshItem, widget.cart);
        itemController.resetQuantityForIncrementalAdd(notify: false);
      } else {
        // Fallback to existing item data if API fails
        _freshItem = widget.item;
        // If item has food variations, ensure newVariation is enabled
        if (widget.item?.foodVariations != null &&
            widget.item!.foodVariations!.isNotEmpty) {
          _newVariation = true;
        }
        itemController.initData(widget.item, widget.cart);
        itemController.resetQuantityForIncrementalAdd(notify: false);
      }
    } catch (e) {
      debugPrint('Error loading item details: $e');
      // Fallback to existing item data
      _freshItem = widget.item;
      Get.find<ItemController>().initData(widget.item, widget.cart);
      Get.find<ItemController>()
          .resetQuantityForIncrementalAdd(notify: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Show nutrition popup when "تنبيهات" is clicked
  /// Check if nutrition data has meaningful values (not null and not zero)
  bool _hasMeaningfulNutritionData(Nutrition? nutrition) {
    if (nutrition == null) return false;
    return (nutrition.calories != null && nutrition.calories! > 0) ||
        (nutrition.protein != null && nutrition.protein! > 0) ||
        (nutrition.carbs != null && nutrition.carbs! > 0) ||
        (nutrition.fat != null && nutrition.fat! > 0) ||
        (nutrition.fiber != null && nutrition.fiber! > 0);
  }

  void _showNutritionPopup(BuildContext context, Nutrition nutrition) {
    NutritionPopup.show(context, nutrition);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching item details
    if (_isLoading) {
      return Container(
        width: 550,
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: GetPlatform.isWeb
              ? const BorderRadius.all(
                  Radius.circular(Dimensions.radiusDefault))
              : const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Use fresh item data
    final item = _freshItem ?? widget.item!;
    _ensureFoodVariationKeyCount(item.foodVariations?.length ?? 0);

    return Container(
      width: 550,
      margin: EdgeInsets.only(top: GetPlatform.isWeb ? 0 : 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: GetPlatform.isWeb
            ? const BorderRadius.all(Radius.circular(16))
            : const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 45,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: GetBuilder<ItemController>(builder: (itemController) {
        final isArabic = Get.locale?.languageCode == 'ar';
        final String resolvedModuleType =
            (item.moduleType ??
                    Get.find<SplashController>()
                        .selectedModule
                        .value
                        ?.moduleType ??
                    '')
                .toLowerCase();
        final String selectedModuleName = (Get.find<SplashController>()
                    .selectedModule
                    .value
                    ?.moduleName ??
                '')
            .toLowerCase();
        final bool isCafeModule = selectedModuleName.contains('مقاه') ||
            selectedModuleName.contains('cafe');
        final bool showAdditionalNoteSection = resolvedModuleType == 'food';
        final String additionalNoteHint =
            isCafeModule ? 'cafe_notes_hint'.tr : 'restaurant_notes_hint'.tr;
        // Variables for potential price range display (future use)

        // Decide base price strategy
        // For new-variation modules, the backend already returns the FINAL discounted price in item.price
        // so we should NOT re-apply any discount in the client.
        // For legacy modules, we still use originalPrice (if available) to calculate discount locally.
        final bool isNewVariationModule = _newVariation;
        double? price = isNewVariationModule
            ? item.price
            : (item.originalPrice ?? item.price);
        double variationPrice = 0;
        Variation? variation;
        // initialDiscount calculated for potential future use
        // double? initialDiscount =
        //     (widget.isCampaign || item.storeDiscount == 0) ? item.discount : item.storeDiscount;
        double? discount = (widget.isCampaign || item.storeDiscount == 0)
            ? item.discount
            : item.storeDiscount;
        String? discountType = (widget.isCampaign || item.storeDiscount == 0)
            ? item.discountType
            : 'percent';
        int? stock = item.stock ?? 0;

        if (discountType == 'amount') {
          discount = (discount ?? 0) * (itemController.quantity ?? 1);
        }

        // Calculate variation price - prefer food variations if they exist
        if (item.foodVariations != null && item.foodVariations!.isNotEmpty) {
          for (int index = 0; index < item.foodVariations!.length; index++) {
            for (int i = 0;
                i < item.foodVariations![index].variationValues!.length;
                i++) {
              if (itemController.selectedVariations.length > index &&
                  itemController.selectedVariations[index].length > i &&
                  itemController.selectedVariations[index][i] == true) {
                variationPrice += item.foodVariations![index]
                        .variationValues![i].optionPrice ??
                    0;
              }
            }
          }
        } else if (item.choiceOptions != null &&
            item.choiceOptions!.isNotEmpty) {
          final List<String> variationList = [];
          for (int index = 0;
              index < (item.choiceOptions?.length ?? 0);
              index++) {
            variationList.add(item.choiceOptions![index]
                .options![itemController.variationIndex![index]]
                .replaceAll(' ', ''));
          }
          String variationType = '';
          bool isFirst = true;
          for (final variation in variationList) {
            if (isFirst) {
              variationType = '$variationType$variation';
              isFirst = false;
            } else {
              variationType = '$variationType-$variation';
            }
          }

          for (final Variation variations in item.variations!) {
            if (variations.type == variationType) {
              price = variations.price;
              variation = variations;
              stock = variations.stock;
              break;
            }
          }
        }

        // Add preset price if preset is selected
        // For new-variation module (module 6), preset.price already reflects
        // the same choices whose optionPrice we sum into variationPrice,
        // so we MUST NOT add preset.price again or we double-charge.
        final double presetPrice =
            isNewVariationModule ? 0.0 : (_selectedPreset?.price ?? 0.0);

        // Debug: Check what prices we're getting from backend
        appLogger.debug('🔍 [Price Calculation] Item: ${item.name}');
        appLogger.debug('   💰 item.price (from API): ${item.price}');
        appLogger.debug('   💰 item.originalPrice (from API): ${item.originalPrice}');
        appLogger.debug('   ➕ Variation price: $variationPrice');

        // Combine base price with variation price
        price = (price ?? 0) + variationPrice;
        appLogger.debug('   💵 Total price (base + variations): $price');

        // For new-variation modules, price from backend is already discounted,
        // and variation/preset prices are final amounts. Do NOT re-apply discount.
        double priceWithDiscount;
        if (isNewVariationModule) {
          priceWithDiscount = price;
          discount = 0;
          discountType = null;
        } else {
            priceWithDiscount =
              PriceConverter.convertWithDiscount(price, discount, discountType) ??
                price;
        }
        double addonsCost = 0;
        final List<AddOn> addOnIdList = [];
        final List<AddOns> addOnsList = [];
        for (int index = 0; index < (item.addOns?.length ?? 0); index++) {
          if (itemController.addOnActiveList[index]) {
            addonsCost = addonsCost +
                (item.addOns![index].price! *
                    itemController.addOnQtyList[index]!);
            addOnIdList.add(AddOn(
                id: item.addOns![index].id,
                quantity: itemController.addOnQtyList[index]));
            addOnsList.add(item.addOns![index]);
          }
        }
        // Add preset price to total
        final double priceWithDiscountAndAddons =
            (priceWithDiscount + addonsCost + presetPrice);
        appLogger.debug('   🎫 Discount: $discount ($discountType)');
        appLogger.debug('   💳 Price after discount: $priceWithDiscount');
        appLogger.debug('   🎁 Addons cost: $addonsCost');
        appLogger.debug('   ✅ Final total: $priceWithDiscountAndAddons');
        final bool isAvailable = DateConverter.isAvailable(
            item.availableTimeStarts, item.availableTimeEnds);
        final bool showStickyBottomBar =
            !(item.scheduleOrder ?? false) && isAvailable;
        // Reserve space for fixed footer (price breakdown + qty + CTA) so
        // content e.g. recommended items is not clipped behind it.
        final double scrollBottomPadding = MediaQuery.paddingOf(context).bottom +
            (showStickyBottomBar ? 400 : 24);

        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              // Scrollable content area
              SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsetsDirectional.only(
                  top: 80, // Space for fixed header
                  start: 20,
                  end: 20,
                  bottom: scrollBottomPadding,
                ),
                child: Directionality(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Item Image - scrolls away completely
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomImage(
                          image: item.displayImage ?? '',
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Item Name with larger font
                      Text(
                        item.name!,
                        style: robotoBold.copyWith(
                          fontSize: 26.8,
                          color: const Color(0xFF2D3633),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 8),

                      // Badges Row (Discount and Most Sold)
                      Row(
                        mainAxisAlignment: isArabic
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          // Discount Badge
                          if ((discount ?? 0) > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF1F53),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFFF90F3E),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    discountType == 'percent'
                                        ? '${(discount ?? 0).toInt()}%'
                                        : PriceConverter.convertPrice(discount),
                                    style: robotoRegular.copyWith(
                                      fontSize: 15.2,
                                      color: const Color(0xFFF490AB),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.local_offer,
                                    size: 18,
                                    color: Color(0xFFF490AB),
                                  ),
                                ],
                              ),
                            ),
                          // Most Sold Badge (show if rating count is high or item is popular)
                          if (item.ratingCount != null &&
                              item.ratingCount! > 50)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F5EA),
                                  borderRadius: BorderRadius.circular(8.75),
                                  border: Border.all(
                                    color: const Color(0xFFEDF8F1),
                                    width: 5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'most_popular_items'.tr,
                                      style: robotoRegular.copyWith(
                                        fontSize: 14.8,
                                        color: const Color(0xFF69B585),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.emoji_events,
                                      size: 18,
                                      color: Color(0xFF69B585),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Item Description
                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          style: robotoMedium.copyWith(
                            fontSize: 15,
                            color: const Color(0xFF4A4A4B),
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                          textAlign:
                              isArabic ? TextAlign.right : TextAlign.left,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        const SizedBox(height: 12),

                      // Divider
                      Container(
                        width: double.infinity,
                        height: 3,
                        color: const Color(0xFFEAEAEA),
                      ),
                      const SizedBox(height: 12),

                      // Calories and Notes Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: isArabic
                            ? [
                                // RTL: Calories on right, Notes on left
                                // Calories (right side in RTL)
                                if (item.nutrition != null &&
                                    item.nutrition!.calories != null &&
                                    item.nutrition!.calories! > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 22,
                                        color: Color(0xFF4A4A4B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.nutrition!.calories} ${'calories'.tr}',
                                        style: robotoMedium.copyWith(
                                          fontSize: 18.6,
                                          color: const Color(0xFF4A4A4B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                                // Notes/تنبيهات (left side in RTL)
                                if (_hasMeaningfulNutritionData(item.nutrition))
                                  InkWell(
                                    onTap: () => _showNutritionPopup(
                                        context, item.nutrition!),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 22,
                                          color: Color(0xFF4A4A4B),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'nutrition_notes'.tr,
                                          style: robotoMedium.copyWith(
                                            fontSize: 17.1,
                                            color: const Color(0xFF4A4A4B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ]
                            : [
                                // LTR: Notes on left, Calories on right
                                // Notes/تنبيهات (left side in LTR)
                                if (_hasMeaningfulNutritionData(item.nutrition))
                                  InkWell(
                                    onTap: () => _showNutritionPopup(
                                        context, item.nutrition!),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 22,
                                          color: Color(0xFF4A4A4B),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'nutrition_notes'.tr,
                                          style: robotoMedium.copyWith(
                                            fontSize: 17.1,
                                            color: const Color(0xFF4A4A4B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                // Calories (right side in LTR)
                                if (item.nutrition != null &&
                                    item.nutrition!.calories != null &&
                                    item.nutrition!.calories! > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 22,
                                        color: Color(0xFF4A4A4B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.nutrition!.calories} ${'calories'.tr}',
                                        style: robotoMedium.copyWith(
                                          fontSize: 18.6,
                                          color: const Color(0xFF4A4A4B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                      ),
                      const SizedBox(height: 12),

                      // Presets Section (FIRST - before variations)
                        Builder(builder: (context) {
                        appLogger.debug(
                          '🔍 [UI] Checking if presets should display:');
                        appLogger.debug(
                          '   - _freshItem is null: ${_freshItem == null}');
                        appLogger.debug(
                          '   - _freshItem?.presets is null: ${_freshItem?.presets == null}');
                        appLogger.debug(
                          '   - _freshItem?.presets count: ${_freshItem?.presets?.length ?? 0}');

                        // ✅ Null-safe: Check if presets exist and are not empty
                        // Backend always returns presets: [] (never null), so we check isNotEmpty
                        if (_freshItem?.presets != null &&
                            _freshItem!.presets!.isNotEmpty) {
                            appLogger.debug(
                              '✅ [UI] Displaying ${_freshItem!.presets!.length} presets');
                          return Column(
                            children: [
                              ItemPresetsSection(
                                presets: _freshItem!.presets!,
                                selectedPreset: _selectedPreset,
                                onPresetSelected: _onPresetSelected,
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        } else {
                            appLogger.debug(
                              '⚠️ [UI] Not displaying presets - empty or null');
                          return const SizedBox.shrink();
                        }
                      }),

                      // Food Variations (Always Expanded Sections)
                      // Show food variations if they exist (prefer food variations over old choice options)
                      if (item.foodVariations != null &&
                          item.foodVariations!.isNotEmpty)
                        FoodVariationSection(
                          foodVariations: item.foodVariations!,
                          item: item,
                          selectedVariations: itemController.selectedVariations,
                          variationSectionKeys:
                              _foodVariationSectionKeys.length ==
                                      item.foodVariations!.length
                                  ? _foodVariationSectionKeys
                                  : null,
                          onVariationSelected: (variationIndex, optionIndex) {
                            itemController.setNewCartVariationIndex(
                                variationIndex, optionIndex, item);
                          },
                        ),

                      // Old Variations (for backward compatibility - only show if food variations don't exist)
                      if ((item.foodVariations == null ||
                              item.foodVariations!.isEmpty) &&
                          item.choiceOptions != null &&
                          item.choiceOptions!.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: item.choiceOptions!.length,
                          itemBuilder: (context, index) {
                            return FoodOrderVariationSection(
                              title: item.choiceOptions![index].title!,
                              subtitle: 'choose_one'.tr,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    item.choiceOptions![index].options!.length,
                                itemBuilder: (context, i) {
                                  return FoodOrderOptionItem(
                                    label:
                                        item.choiceOptions![index].options![i],
                                    isSelected:
                                        itemController.variationIndex![index] ==
                                            i,
                                    onTap: () {
                                      itemController.setCartVariationIndex(
                                          index, i, widget.item);
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),

                      // Addons Section
                      if (Get.find<SplashController>()
                              .configModel!
                              .moduleConfig!
                              .module!
                              .addOn! &&
                          (item.addOns?.isNotEmpty ?? false))
                        FoodOrderVariationSection(
                          title: 'addons'.tr,
                          subtitle: 'optional'.tr,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: item.addOns?.length ?? 0,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    // Quantity controls for selected addons
                                    if (itemController.addOnActiveList[index])
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFFE0E0E0)),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => itemController
                                                  .setAddOnQuantity(
                                                      false, index),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(Icons.remove,
                                                    size: 16,
                                                    color: Color(0xFF00C853)),
                                              ),
                                            ),
                                            Text(
                                              itemController.addOnQtyList[index]
                                                  .toString(),
                                              style: robotoMedium.copyWith(
                                                  fontSize: 12),
                                            ),
                                            InkWell(
                                              onTap: () => itemController
                                                  .setAddOnQuantity(
                                                      true, index),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(Icons.add,
                                                    size: 16,
                                                    color: Color(0xFF00C853)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 60),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: FoodOrderOptionItem(
                                        label: item.addOns![index].name!,
                                        price: item.addOns![index].price,
                                        isSelected: itemController
                                            .addOnActiveList[index],
                                        onTap: () {
                                          itemController.addAddOn(
                                            !itemController
                                                .addOnActiveList[index],
                                            index,
                                          );
                                        },
                                        isMultiSelect: true,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Customer Notes (food modules only)
                      if (showAdditionalNoteSection) ...[
                        FoodOrderVariationSection(
                          title: 'additional_note'.tr,
                          subtitle: 'optional'.tr,
                          child: TextField(
                            controller: _notesController,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: _notesMaxLength,
                            textInputAction: TextInputAction.newline,
                            buildCounter: (
                              BuildContext fieldContext, {
                              required int currentLength,
                              required bool isFocused,
                              required int? maxLength,
                            }) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Text(
                                    '$currentLength/${maxLength ?? _notesMaxLength}',
                                    style: robotoRegular.copyWith(
                                      fontSize: 11,
                                      color: Theme.of(fieldContext)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: additionalNoteHint,
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.45),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.2,
                                ),
                              ),
                              counterText: '',
                            ),
                            onChanged: (String value) {
                              if (kDebugMode && AppConstants.enableVerboseLogs) {
                                appLogger.debug(
                                  '📝 [ItemBottomSheet] note_updated itemId=${item.id} length=${value.trim().length}',
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Recommended Items Section
                      if (_freshItem?.recommendedItems != null &&
                          _freshItem!.recommendedItems!.isNotEmpty)
                        RecommendedItemsSection(
                          recommendedItems: _freshItem!.recommendedItems!,
                          onOpenItem: (Item openItem) {
                            Get.back<void>();
                            Future<void>.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                Get.bottomSheet<void>(
                                  ItemBottomSheet(
                                    item: openItem,
                                    inStorePage: widget.inStorePage,
                                    isCampaign: widget.isCampaign,
                                  ),
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  isDismissible: true,
                                  enableDrag: true,
                                  persistent: false,
                                );
                              },
                            );
                          },
                        ),

                      const SizedBox(
                          height: 16), // Bottom padding for safe scrolling
                    ],
                  ),
                ),
              ),

              // Fixed Header at Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsetsDirectional.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    start: 16,
                    end: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Directionality(
                    textDirection:
                        isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Return button
                        InkWell(
                          onTap: () => Get.back<void>(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              boxShadow: DesignTokens.shadowStrong,
                            ),
                            child: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_back_rounded,
                              size: 24,
                              color: DesignTokens.textDark,
                            ),
                          ),
                        ),
                        // Item name (centered)
                        Expanded(
                          child: Text(
                            item.name!,
                            textAlign:
                                isArabic ? TextAlign.right : TextAlign.center,
                            style: robotoBold.copyWith(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Heart icon button
                        if (!widget.isCampaign)
                          GetBuilder<FavouriteController>(
                              builder: (favouriteController) {
                            final bool isFavorite = favouriteController
                                .wishItemIdList
                                .contains(item.id);
                            return InkWell(
                              onTap: () {
                                if (AuthHelper.isLoggedIn()) {
                                  if (isFavorite) {
                                    favouriteController.removeFromFavouriteList(
                                        item.id, false,
                                        getXSnackBar: true);
                                  } else {
                                    favouriteController.addToFavouriteList(
                                        item, null, false,
                                        getXSnackBar: true);
                                  }
                                } else {
                                  showCustomSnackBar('you_are_not_logged_in'.tr,
                                      getXSnackBar: true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isFavorite
                                      ? Colors.red.shade50
                                      : Theme.of(context).cardColor,
                                  shape: BoxShape.circle,
                                  boxShadow: isFavorite
                                      ? DesignTokens.glowShadow(Colors.red)
                                      : DesignTokens.shadowStrong,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            );
                          })
                        else
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // Fixed Bottom Bar
              if (!(item.scheduleOrder ?? false) && isAvailable)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 45,
                          offset: Offset(0, -4),
                        ),
                      ],
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    padding: EdgeInsetsDirectional.only(
                      top: 12,
                      bottom: MediaQuery.of(context).padding.bottom + 12,
                      start: 20,
                      end: 20,
                    ),
                    child: GetBuilder<CartController>(
                        id: 'cart_items',
                        builder: (cartController) {
                      // ✅ FRONTEND ONLY: Check if store is open from API only (no time calculations)
                      bool canOrder = true;
                      if (widget.inStorePage && item.storeId != null) {
                        try {
                          final storeController = Get.find<StoreController>();
                          final store = storeController.store;
                          if (store != null) {
                      // ✅ FRONTEND ONLY: Use store.isOpen from API only
                      // ❌ NO DateTime, NO schedule checks, NO time logic
                      canOrder = store.isOpen == true;
                          }
                        } catch (e) {
                          // StoreController not found or error - allow order
                          canOrder = true;
                        }
                      }
                      
                      final bool moduleStockEnabled = Get.find<SplashController>()
                              .configModel
                              ?.moduleConfig
                              ?.module
                              ?.stock ==
                          true;
                      final int effectiveStock = stock ?? 0;
                      final bool isOutOfStock =
                          moduleStockEnabled && effectiveStock <= 0;
                      final bool isUpdatingExisting =
                          widget.cart != null || itemController.cartIndex != -1;
                      final int selectedQuantity = itemController.quantity ?? 1;
                      int existingCartQuantity = widget.cart?.quantity ?? 0;
                      if (existingCartQuantity <= 0 &&
                          itemController.cartIndex >= 0 &&
                          itemController.cartIndex <
                              cartController.cartList.length) {
                        existingCartQuantity = cartController
                                .cartList[itemController.cartIndex].quantity ??
                            0;
                      }
                      String helperText;
                      if (!canOrder) {
                        helperText = 'store_closed'.tr;
                      } else if (isOutOfStock) {
                        helperText = 'out_of_stock'.tr;
                      } else if (isUpdatingExisting && existingCartQuantity > 0) {
                        helperText =
                            'In cart: $existingCartQuantity  |  +$selectedQuantity';
                      } else {
                        helperText = '${'quantity'.tr}: $selectedQuantity';
                      }

                      final double totalPrice = priceWithDiscountAndAddons *
                          (itemController.quantity ?? 1);
                      final int qty = itemController.quantity ?? 1;
                      final double optionsExtraPerUnit = variationPrice +
                          (isNewVariationModule
                              ? 0.0
                              : (_selectedPreset?.price ?? 0.0));
                      final TextStyle? detailStyle = Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          );
                      final List<Widget> priceDetailRows = <Widget>[];
                      if (optionsExtraPerUnit > 0.001) {
                        priceDetailRows.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'item_sheet_options_fee'.tr,
                                    style: detailStyle,
                                  ),
                                ),
                                Text(
                                  PriceConverter.convertPrice(
                                      optionsExtraPerUnit * qty),
                                  style: detailStyle,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (addonsCost > 0.001) {
                        priceDetailRows.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'addons'.tr,
                                    style: detailStyle,
                                  ),
                                ),
                                Text(
                                  PriceConverter.convertPrice(addonsCost * qty),
                                  style: detailStyle,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      priceDetailRows.add(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'item_sheet_price_per_item'.tr,
                                style: detailStyle,
                              ),
                            ),
                            Text(
                              PriceConverter.convertPrice(
                                  priceWithDiscountAndAddons),
                              style: detailStyle?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                      final List<CartModel> otherCartLines =
                          _otherCartLinesForPreview(
                        cartController,
                        itemController,
                        item,
                      );
                      final double othersSum = otherCartLines.fold<double>(
                        0.0,
                        (double sum, CartModel c) =>
                            sum + _cartLineDisplayTotal(c),
                      );
                      final double grandTotal = totalPrice + othersSum;
                      return _UnifiedBottomBar(
                        quantity: itemController.quantity!,
                        currentLineTotal: totalPrice,
                        grandTotal: grandTotal,
                        priceDetailRows: priceDetailRows,
                        itemName: item.name ?? '',
                        otherCartLines: otherCartLines,
                        helperText: helperText,
                        helperIsWarning: !canOrder || isOutOfStock,
                        buttonText: (!canOrder)
                            ? 'store_closed'.tr
                            : isOutOfStock
                                ? 'out_of_stock'.tr
                                : widget.isCampaign
                                    ? 'order_now'.tr
                                    : 'add_to_cart'.tr,
                        isLoading: cartController.isLoading,
                        isEnabled: canOrder && !isOutOfStock,
                        onDecrease: () {
                          if (itemController.quantity! > 1) {
                            itemController.setQuantity(
                                false, stock, item.quantityLimit,
                                getxSnackBar: true);
                          }
                        },
                        onIncrease: () {
                          itemController.setQuantity(
                              true, stock, item.quantityLimit,
                              getxSnackBar: true);
                        },
                        onPressed: (!canOrder || isOutOfStock)
                            ? null
                            : () async {
                                String? invalid;
                                int? invalidFoodVariationIndex;
                                if (_newVariation &&
                                    item.foodVariations != null &&
                                    item.foodVariations!.isNotEmpty) {
                                  for (int index = 0;
                                      index < item.foodVariations!.length;
                                      index++) {
                                    if (itemController
                                            .selectedVariations.length <=
                                        index) {
                                      invalid =
                                          '${'choose_a_variation_from'.tr} ${item.foodVariations![index].name}';
                                      invalidFoodVariationIndex = index;
                                      break;
                                    }

                                    if (!item.foodVariations![index]
                                            .multiSelect! &&
                                        item.foodVariations![index].required! &&
                                        !itemController.selectedVariations[
                                                index]
                                            .contains(true)) {
                                      invalid =
                                          '${'choose_a_variation_from'.tr} ${item.foodVariations![index].name}';
                                      invalidFoodVariationIndex = index;
                                      break;
                                    } else if (item.foodVariations![index]
                                            .multiSelect! &&
                                        (item.foodVariations![index]
                                                .required! ||
                                            itemController.selectedVariations[
                                                    index]
                                                .contains(true)) &&
                                        item.foodVariations![index].min! >
                                            itemController
                                                .selectedVariationLength(
                                                    itemController
                                                        .selectedVariations,
                                                    index)) {
                                      invalid =
                                          '${'select_minimum'.tr} ${item.foodVariations![index].min} '
                                          '${'and_up_to'.tr} ${item.foodVariations![index].max} ${'options_from'.tr}'
                                          ' ${item.foodVariations![index].name} ${'variation'.tr}';
                                      invalidFoodVariationIndex = index;
                                      break;
                                    }
                                  }
                                }

                                if (Get.find<SplashController>().moduleList !=
                                    null) {
                                  for (final ModuleModel module
                                      in Get.find<SplashController>()
                                          .moduleList!) {
                                    if (module.id == item.moduleId) {
                                      Get.find<SplashController>()
                                          .setModule(module);
                                      break;
                                    }
                                  }
                                }

                                if (invalid != null) {
                                  showCustomSnackBar(invalid,
                                      getXSnackBar: true);
                                  if (invalidFoodVariationIndex != null) {
                                    _scrollToFoodVariationIndex(
                                        invalidFoodVariationIndex);
                                  }
                                } else {
                                  // Calculate discount amount for cart line
                                  // For new-variation modules, backend has already applied the item-level discount
                                  // to item.price, so we derive discountAmount from originalPrice vs discounted price
                                  // and DO NOT call convertWithDiscount again with a null discountType.
                                  final int quantityForDiscount =
                                      itemController.quantity ?? 1;
                                  double discountAmount;
                                  if (isNewVariationModule) {
                                    final double originalBase =
                                        item.originalPrice ?? item.price ?? 0;
                                    final double discountedBase =
                                        item.price ?? 0;
                                    discountAmount =
                                        (originalBase - discountedBase) *
                                            quantityForDiscount;
                                  } else {
                                    final double discounted =
                                        PriceConverter.convertWithDiscount(
                                            price, discount, discountType)!;
                                    discountAmount = (price! - discounted) *
                                        quantityForDiscount;
                                  }

                                  // 🔧 FIX: Get storeId from multiple sources to ensure it's never null
                                  // Priority: item.storeId > StoreController.store.id > null
                                  int? effectiveStoreId =
                                      widget.inStorePage &&
                                              Get.isRegistered<StoreController>()
                                          ? Get.find<StoreController>().store?.id
                                          : widget.item?.storeId;
                                  effectiveStoreId ??= widget.item?.storeId;
                                  if (effectiveStoreId == null &&
                                      Get.isRegistered<StoreController>()) {
                                    effectiveStoreId =
                                        Get.find<StoreController>().store?.id;
                                    if (effectiveStoreId != null) {
                                      debugPrint(
                                          '🔧 ItemBottomSheet: storeId was null, using StoreController.store.id: $effectiveStoreId');
                                    }
                                  }

                                  final CartModel cartModel = CartModel(
                                    id: null,
                                    // 🔧 FIX: Explicitly set storeId to enable different-store detection
                                    storeId: effectiveStoreId,
                                    price: price ?? 0.0,
                                    discountedPrice: priceWithDiscountAndAddons,
                                    variation:
                                        variation != null ? [variation] : [],
                                    foodVariations:
                                        itemController.selectedVariations,
                                    discountAmount: discountAmount,
                                    quantity: itemController.quantity,
                                    addOnIds: addOnIdList,
                                    addOns: addOnsList,
                                    isCampaign: widget.isCampaign,
                                    stock: stock,
                                    item: widget.item,
                                    quantityLimit: widget.item?.quantityLimit,
                                  );

                                  final List<OrderVariation> variations =
                                      _getSelectedVariations(
                                    // ✅ FIX: Always true if item has food variations (don't rely on config)
                                    isFoodVariation:
                                        item.foodVariations != null &&
                                            item.foodVariations!.isNotEmpty,
                                    foodVariations: item.foodVariations!,
                                    selectedVariations:
                                        itemController.selectedVariations,
                                  );

                                  // 🔍 DEBUG: Check what variations were collected
                                  debugPrint(
                                      '🔍 [Add to Cart] Collected variations:');
                                  debugPrint(
                                      '   - variations.length: ${variations.length}');
                                  for (final v in variations) {
                                    debugPrint(
                                        '   - ${v.name}: ${v.values?.options?.length ?? 0} options');
                                  }

                                  final List<int?> listOfAddOnId =
                                      _getSelectedAddonIds(
                                          addOnIdList: addOnIdList);
                                  final List<int?> listOfAddOnQty =
                                      _getSelectedAddonQtnList(
                                          addOnIdList: addOnIdList);

                                  // 🔍 DEBUG: Check what we're passing to OnlineCart
                                  final variationsToPass =
                                      (item.foodVariations != null &&
                                              item.foodVariations!.isNotEmpty)
                                          ? variations
                                          : null;
                                  debugPrint(
                                      '🔍 [Add to Cart] Passing to OnlineCart:');
                                  debugPrint(
                                      '   - variationsToPass is null: ${variationsToPass == null}');
                                  debugPrint(
                                      '   - variationsToPass length: ${variationsToPass?.length ?? 0}');

                                  final OnlineCart onlineCart = OnlineCart(
                                    null,
                                    widget.isCampaign ? null : item.id,
                                    widget.isCampaign ? item.id : null,
                                    priceWithDiscountAndAddons.toString(),
                                    _notesController.text
                                        .trim(), // Add notes here
                                    variation != null ? [variation] : null,
                                    // ✅ FIX: Always pass variations if they exist (don't rely on config check)
                                    variationsToPass,
                                    itemController.quantity,
                                    listOfAddOnId,
                                    addOnsList,
                                    listOfAddOnQty,
                                    'Item',
                                    itemType: 'Item',
                                    storeId: effectiveStoreId,
                                  );

                                  if (widget.isCampaign) {
                                    Get.toNamed<void>(
                                        RouteHelper.getCampaignCheckoutRoute(),
                                        arguments: CheckoutScreen(
                                          storeId: null,
                                          fromCart: false,
                                          cartList: [cartModel],
                                        ));
                                  } else {
                                    if (Get.find<CartController>()
                                        .existAnotherStoreItem(
                                      effectiveStoreId,
                                      Get.find<SplashController>().module !=
                                              null
                                          ? Get.find<SplashController>()
                                              .module!
                                              .id
                                          : Get.find<SplashController>()
                                              .cacheModule!
                                              .id,
                                    )) {
                                        Get.dialog<void>(
                                          ConfirmationDialog(
                                            icon: Images.warning,
                                            title: 'are_you_sure_to_reset'.tr,
                                            description: Get.find<
                                                        SplashController>()
                                                    .configModel!
                                                    .moduleConfig!
                                                    .module!
                                                    .showRestaurantText!
                                                ? 'if_you_continue'.tr
                                                : 'if_you_continue_without_another_store'
                                                    .tr,
                                            onYesPressed: () {
                                              Get.back<void>();
                                              Get.find<CartController>()
                                                  .clearCartOnline()
                                                  .then((success) async {
                                                if (success) {
                                                  await Get.find<
                                                          CartController>()
                                                      .addToCartOnline(
                                                          onlineCart);
                                                  Get.back<void>();
                                                }
                                              });
                                            },
                                          ),
                                          barrierDismissible: false);
                                    } else {
                                      final bool preSynced = await cartController
                                          .syncLocalCartRowsWithoutServerId();
                                      if (!preSynced) {
                                        showCustomSnackBar(
                                          'please_try_again'.tr,
                                          getXSnackBar: true,
                                        );
                                        return;
                                      }
                                      await cartController
                                          .addToCartOnline(onlineCart)
                                          .then((bool success) {
                                        if (success) {
                                          Get.back<void>();
                                        } else {
                                          showCustomSnackBar(
                                              'Failed to add item to cart.',
                                              getXSnackBar: true);
                                        }
                                      });
                                    }
                                  }
                                }
                              },
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  List<OrderVariation> _getSelectedVariations(
      {required bool isFoodVariation,
      required List<FoodVariation>? foodVariations,
      required List<List<bool?>> selectedVariations}) {
    final List<OrderVariation> variations = [];
    if (isFoodVariation) {
      for (int i = 0; i < foodVariations!.length; i++) {
        // Guard against RangeError: ensure selectedVariations is properly initialized
        if (selectedVariations.length <= i) {
          continue; // Skip if selectedVariations is not initialized for this index
        }
        if (selectedVariations[i].contains(true)) {
          // ✅ FIX: Collect option objects with labels AND prices
          final List<VariationOption> options = [];
          for (int j = 0; j < foodVariations[i].variationValues!.length; j++) {
            // Guard against RangeError: ensure selectedVariations[i] has enough elements
            if (selectedVariations[i].length > j &&
                selectedVariations[i][j] == true) {
              options.add(VariationOption(
                label: foodVariations[i].variationValues![j].level,
                optionPrice:
                    foodVariations[i].variationValues![j].optionPrice ?? 0.0,
              ));
            }
          }
          // ✅ FIX: Add variation with options (label + price)
          variations.add(OrderVariation(
              name: foodVariations[i].name,
              values: OrderVariationValue(options: options)));
        }
      }
    }
    return variations;
  }

  List<int?> _getSelectedAddonIds({required List<AddOn> addOnIdList}) {
    final List<int?> listOfAddOnId = [];
    for (final addOn in addOnIdList) {
      listOfAddOnId.add(addOn.id);
    }
    return listOfAddOnId;
  }

  List<int?> _getSelectedAddonQtnList({required List<AddOn> addOnIdList}) {
    final List<int?> listOfAddOnQty = [];
    for (final addOn in addOnIdList) {
      listOfAddOnQty.add(addOn.quantity);
    }
    return listOfAddOnQty;
  }
}

// ==================== MODERN 3D UI COMPONENTS ====================

/// Compact bottom bar: order summary (this line + other cart lines) + qty + CTA.
class _UnifiedBottomBar extends StatelessWidget {
  final int quantity;
  final double currentLineTotal;
  final double grandTotal;
  final String itemName;
  final List<CartModel> otherCartLines;
  final String buttonText;
  final String helperText;
  final bool helperIsWarning;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback? onPressed;
  final List<Widget> priceDetailRows;

  const _UnifiedBottomBar({
    required this.quantity,
    required this.currentLineTotal,
    required this.grandTotal,
    required this.itemName,
    required this.otherCartLines,
    required this.buttonText,
    required this.helperText,
    required this.helperIsWarning,
    required this.isLoading,
    required this.isEnabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onPressed,
    this.priceDetailRows = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final String grandTotalLabel = PriceConverter.convertPrice(grandTotal);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool showCartTotalRow = otherCartLines.isNotEmpty;
    final String mainLabel = itemName.isEmpty
        ? '—'
        : '$quantity× ${itemName.trim()}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'item_sheet_order_preview'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: 12,
                        color: scheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      mainLabel,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(
                        fontSize: 13,
                        color: scheme.onSurface,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    PriceConverter.convertPrice(currentLineTotal),
                    style: robotoBold.copyWith(
                      fontSize: 13,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              if (priceDetailRows.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: priceDetailRows,
                  ),
                ),
              ],
              ...otherCartLines.map((CartModel c) {
                final int q = c.quantity ?? 1;
                final String name = c.item?.name?.trim() ?? '—';
                final String lineLabel = '$q× $name';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          lineLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: robotoBold.copyWith(
                            fontSize: 13,
                            color: scheme.onSurface,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PriceConverter.convertPrice(_cartLineDisplayTotal(c)),
                        style: robotoBold.copyWith(
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (showCartTotalRow) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'total'.tr,
                      style: robotoBold.copyWith(
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      grandTotalLabel,
                      style: robotoBold.copyWith(
                        fontSize: 14,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CompactQuantityPill(
              quantity: quantity,
              onDecrease: onDecrease,
              onIncrease: onIncrease,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                button: true,
                enabled: isEnabled && !isLoading,
                label:
                    '$buttonText $grandTotalLabel ${itemName.isEmpty ? '' : itemName}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled && !isLoading ? onPressed : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient:
                            isEnabled ? DesignTokens.primaryGreenGradient : null,
                        color: isEnabled ? null : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isEnabled
                            ? DesignTokens.shadowSubtle
                            : null,
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        buttonText,
                                        maxLines: 1,
                                        style: robotoBold.copyWith(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          '·',
                                          style: robotoBold.copyWith(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        grandTotalLabel,
                                        maxLines: 1,
                                        style: robotoBold.copyWith(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          helperText,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(
            fontSize: 11,
            height: 1.25,
            color: helperIsWarning
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CompactQuantityPill extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CompactQuantityPill({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Theme.of(context).dividerColor;
    final Color fillColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.55);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactQtyIconButton(
            icon: Icons.remove_rounded,
            onTap: onDecrease,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              quantity.toString(),
              style: robotoMedium.copyWith(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          _CompactQtyIconButton(
            icon: Icons.add_rounded,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _CompactQtyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CompactQtyIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: DesignTokens.primaryGreen,
          ),
        ),
      ),
    );
  }
}




