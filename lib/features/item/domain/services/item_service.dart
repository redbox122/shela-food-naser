import 'package:get/get.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/features/item/domain/models/common_condition_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/repositories/item_repository_interface.dart';
import 'package:sixam_mart/features/item/domain/services/item_service_interface.dart';
import 'package:sixam_mart/helper/module_helper.dart';

class ItemService implements ItemServiceInterface {
  final ItemRepositoryInterface itemRepositoryInterface;
  ItemService({required this.itemRepositoryInterface});

  @override
  Future<List<Item>?> getPopularItemList(
      String type, DataSourceEnum? source) async {
    final result = await itemRepositoryInterface.getList(
        type: type, isPopularItem: true, source: source);
    return result is List<Item>? ? result : null;
  }

  @override
  Future<ItemModel?> getReviewedItemList(
      String type, DataSourceEnum? source) async {
    final result = await itemRepositoryInterface.getList(
        type: type, isReviewedItem: true, source: source);
    return result is ItemModel? ? result : null;
  }

  @override
  Future<ItemModel?> getFeaturedCategoriesItemList(
      DataSourceEnum? source) async {
    final result = await itemRepositoryInterface.getList(
        isFeaturedCategoryItems: true, source: source);
    return result is ItemModel? ? result : null;
  }

  @override
  Future<List<Item>?> getRecommendedItemList(
      String type, DataSourceEnum? source) async {
    final result = await itemRepositoryInterface.getList(
        type: type, isRecommendedItems: true, source: source);
    return result is List<Item>? ? result : null;
  }

  @override
  Future<List<Item>?> getDiscountedItemList(
      String type, DataSourceEnum? source) async {
    final result = await itemRepositoryInterface.getList(
        isDiscountedItems: true, type: type, source: source);
    return result is List<Item>? ? result : null;
  }

  @override
  Future<Item?> getItemDetails(int? itemID) async {
    final result = await itemRepositoryInterface.get(itemID.toString());
    return result is Item? ? result : null;
  }

  @override
  Future<BasicMedicineModel?> getBasicMedicine(DataSourceEnum source) async {
    final result = await itemRepositoryInterface.getBasicMedicine(source);
    return result;
  }

  @override
  Future<List<CommonConditionModel>?> getCommonConditions() async {
    final result =
        await itemRepositoryInterface.getList(isCommonConditions: true);
    return result is List<CommonConditionModel>? ? result : null;
  }

  @override
  Future<List<Item>?> getConditionsWiseItems(int id) async {
    final result = await itemRepositoryInterface.get(id.toString(),
        isConditionWiseItem: true);
    return result is List<Item>? ? result : null;
  }

  @override
  List<bool> initializeCartAddonActiveList(
      List<AddOn>? addOnIds, List<AddOns>? addOns) {
    if (addOnIds == null ||
        addOnIds.isEmpty ||
        addOns == null ||
        addOns.isEmpty) {
      return <bool>[];
    }
    final List<int?> addOnIdList = [];
    final List<bool> addOnActiveList = [];
    for (final addOnId in addOnIds) {
      addOnIdList.add(addOnId.id);
    }
    for (final addOn in addOns) {
      if (addOnIdList.contains(addOn.id)) {
        addOnActiveList.add(true);
      } else {
        addOnActiveList.add(false);
      }
    }
    return addOnActiveList;
  }

  @override
  List<int?> initializeCartAddonsQtyList(
      List<AddOn>? addOnIds, List<AddOns>? addOns) {
    if (addOnIds == null ||
        addOnIds.isEmpty ||
        addOns == null ||
        addOns.isEmpty) {
      return <int?>[];
    }
    final List<int?> addOnIdList = [];
    final List<int?> addOnQtyList = [];
    for (final addOnId in addOnIds) {
      addOnIdList.add(addOnId.id);
    }
    for (final addOn in addOns) {
      final int index = addOnIdList.indexOf(addOn.id);
      if (index != -1) {
        addOnQtyList.add(addOnIds[index].quantity);
      } else {
        addOnQtyList.add(1);
      }
    }
    return addOnQtyList;
  }

  @override
  List<bool> collapseVariation(List<FoodVariation>? foodVariations) {
    final List<bool> collapseVariation = [];
    // ✅ Null-safe: Handle null foodVariations gracefully
    if (foodVariations != null && foodVariations.isNotEmpty) {
      for (int index = 0; index < foodVariations.length; index++) {
        collapseVariation.add(true);
      }
    }
    return collapseVariation;
  }

  @override
  List<int> initializeCartVariationIndexes(
      List<Variation>? variation, List<ChoiceOptions>? choiceOptions) {
    final List<int> variationIndex = [];
    final List<String> variationTypes = [];
    if (variation!.isNotEmpty && variation[0].type != null) {
      variationTypes.addAll(variation[0].type!.split('-'));
    }
    int varIndex = 0;
    for (final choiceOption in choiceOptions!) {
      for (int index = 0; index < choiceOption.options!.length; index++) {
        if (choiceOption.options![index].trim().replaceAll(' ', '') ==
            variationTypes[varIndex].trim()) {
          variationIndex.add(index);
          break;
        }
      }
      varIndex++;
    }
    return variationIndex;
  }

  @override
  List<List<bool?>> initializeSelectedVariation(
      List<FoodVariation>? foodVariations) {
    final List<List<bool?>> selectedVariations = [];
    // ✅ Null-safe: Handle null foodVariations gracefully
    if (foodVariations != null && foodVariations.isNotEmpty) {
      for (int index = 0; index < foodVariations.length; index++) {
        selectedVariations.add([]);
        final variationValues = foodVariations[index].variationValues ?? [];
        for (int i = 0; i < variationValues.length; i++) {
          selectedVariations[index].add(false);
        }
      }
    }
    return selectedVariations;
  }

  @override
  List<bool> initializeCollapseVariation(List<FoodVariation>? foodVariations) {
    final List<bool> collapseVariation = [];
    // ✅ Null-safe: Handle null foodVariations gracefully
    if (foodVariations != null && foodVariations.isNotEmpty) {
      for (int index = 0; index < foodVariations.length; index++) {
        collapseVariation.add(true);
      }
    }
    return collapseVariation;
  }

  @override
  List<int> initializeVariationIndexes(List<ChoiceOptions>? choiceOptions) {
    final List<int> variationIndex = [];
    // ✅ Null-safe: Handle null choiceOptions gracefully
    if (choiceOptions != null && choiceOptions.isNotEmpty) {
      for (int i = 0; i < choiceOptions.length; i++) {
        variationIndex.add(0);
      }
    }
    return variationIndex;
  }

  @override
  List<bool> initializeAddonActiveList(List<AddOns>? addOns) {
    final List<bool> addOnActiveList = [];
    if (addOns == null || addOns.isEmpty) {
      return addOnActiveList;
    }
    for (int i = 0; i < addOns.length; i++) {
      addOnActiveList.add(false);
    }
    return addOnActiveList;
  }

  @override
  List<int> initializeAddonQtyList(List<AddOns>? addOns) {
    final List<int> addOnQtyList = [];
    if (addOns == null || addOns.isEmpty) {
      return addOnQtyList;
    }
    for (int i = 0; i < addOns.length; i++) {
      addOnQtyList.add(1);
    }
    return addOnQtyList;
  }

  @override
  Future<String> prepareVariationType(
      List<ChoiceOptions>? choiceOptions, List<int>? variationIndex) async {
    String variationType = '';
    if (!(ModuleHelper.getModuleConfig(ModuleHelper.getModule() != null
                ? ModuleHelper.getModule()!.moduleType
                : ModuleHelper.getCacheModule()!.moduleType)
            .newVariation ??
        false)) {
      // ✅ Null-safe: Only process if choiceOptions exists (legacy Module 3 system)
      if (choiceOptions != null &&
          choiceOptions.isNotEmpty &&
          variationIndex != null &&
          variationIndex.isNotEmpty) {
        final List<String> variationList = [];
        for (int index = 0; index < choiceOptions.length; index++) {
          if (index < variationIndex.length &&
              choiceOptions[index].options != null &&
              variationIndex[index] < choiceOptions[index].options!.length) {
            variationList.add(choiceOptions[index]
                .options![variationIndex[index]]
                .replaceAll(' ', ''));
          }
        }
        bool isFirst = true;
        for (final variation in variationList) {
          if (isFirst) {
            variationType = '$variationType$variation';
            isFirst = false;
          } else {
            variationType = '$variationType-$variation';
          }
        }
      }
    }
    return variationType;
  }

  @override
  int setAddOnQuantity(bool isIncrement, int addOnQty) {
    int qty = addOnQty;
    if (isIncrement) {
      qty = qty + 1;
    } else {
      qty = qty - 1;
    }
    return qty;
  }

  @override
  Future<int> setQuantity(bool isIncrement, bool moduleStock, int? stock,
      int qty, int? quantityLimit,
      {bool getxSnackBar = false}) async {
    int quantity = qty;
    if (isIncrement) {
      if (moduleStock && quantity >= stock!) {
        showCustomSnackBar('out_of_stock'.tr);
      } else {
        if (quantityLimit != null) {
          if (quantity >= quantityLimit && quantityLimit != 0) {
            showCustomSnackBar('${'maximum_quantity_limit'.tr} $quantityLimit',
                getXSnackBar: getxSnackBar);
          } else {
            quantity = quantity + 1;
          }
        } else {
          quantity = quantity + 1;
        }
      }
    } else {
      quantity = quantity - 1;
    }
    return quantity;
  }

  @override
  List<List<bool?>> setNewCartVariationIndex(
      int index,
      int i,
      List<FoodVariation>? foodVariations,
      List<List<bool?>> selectedVariations) {
    final List<List<bool?>> resultVariations = selectedVariations;
    // ✅ Null-safe: Return early if foodVariations is null or empty, or index is out of bounds
    if (foodVariations == null ||
        foodVariations.isEmpty ||
        index >= foodVariations.length) {
      return resultVariations;
    }
    final variation = foodVariations[index];
    if (variation.multiSelect != true) {
      for (int j = 0; j < resultVariations[index].length; j++) {
        if (variation.required == true) {
          resultVariations[index][j] = j == i;
        } else {
          if (resultVariations[index][j] == true) {
            resultVariations[index][j] = false;
          } else {
            resultVariations[index][j] = j == i;
          }
        }
      }
    } else {
      final maxValue = variation.max ?? 0;
      if (resultVariations[index][i] != true &&
          selectedVariationLength(resultVariations, index) >= maxValue) {
        showCustomSnackBar(
          '${'maximum_variation_for'.tr} ${variation.name ?? ''} ${'is'.tr} $maxValue',
          getXSnackBar: true,
        );
      } else {
        resultVariations[index][i] = resultVariations[index][i] != true;
      }
    }
    return resultVariations;
  }

  @override
  int selectedVariationLength(List<List<bool?>> selectedVariations, int index) {
    int length = 0;
    for (final bool? isSelected in selectedVariations[index]) {
      if (isSelected!) {
        length++;
      }
    }
    return length;
  }

  @override
  double? getStartingPrice(Item item) {
    double? startingPrice = 0;
    if (item.choiceOptions != null && item.choiceOptions!.isNotEmpty) {
      final List<double?> priceList = [];
      for (final variation in item.variations!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
    } else {
      startingPrice = item.price;
    }
    return startingPrice;
  }

  @override
  Future<int> isExistInCartForBottomSheet(List<CartModel> cartList, int? itemId,
      int? cartIndex, List<List<bool?>>? variations) async {
    for (int index = 0; index < cartList.length; index++) {
      if (cartList[index].item!.id == itemId) {
        if ((index == cartIndex)) {
          return -1;
        } else {
          if (variations != null && variations.isNotEmpty) {
            // Guard against null or mismatched foodVariations from older cart entries
            if (cartList[index].foodVariations == null ||
                cartList[index].foodVariations!.isEmpty) {
              continue;
            }
            if (variations.length != cartList[index].foodVariations!.length) {
              // Different schema/selection length → definitely not the same cart line
              continue;
            }
            bool same = false;
            for (int i = 0; i < variations.length; i++) {
              // Extra safety: guard against per-row length mismatch
              if (cartList[index].foodVariations![i].length !=
                  variations[i].length) {
                same = false;
                break;
              }
              for (int j = 0; j < variations[i].length; j++) {
                if (variations[i][j] == cartList[index].foodVariations![i][j]) {
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
            if (!same) {
              continue;
            }
            if (same) {
              return index;
            } else {
              return -1;
            }
          } else {
            return index;
          }
        }
      }
    }
    return -1;
  }

  @override
  Future<ItemModel?> getCategoryItemList(
      String? categoryID, int offset, String type) async {
    final result = await itemRepositoryInterface.getList(
        id: categoryID, offset: offset, type: type, isCategory: true);
    return result is ItemModel? ? result : null;
  }
}
