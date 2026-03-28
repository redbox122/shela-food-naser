import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/common_condition_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet.dart';
import 'package:sixam_mart/features/item/screens/item_details_screen.dart';
import 'package:sixam_mart/features/item/domain/services/item_service_interface.dart';

class ItemDetailsViewData {
  final int stock;
  final CartModel? cartModel;
  final OnlineCart? cart;
  final double priceWithAddons;

  const ItemDetailsViewData({
    required this.stock,
    required this.cartModel,
    required this.cart,
    required this.priceWithAddons,
  });
}

class ItemController extends GetxController implements GetxService {
  final ItemServiceInterface itemServiceInterface;
  ItemController({required this.itemServiceInterface});

  final Map<int, DateTime> _directAddCooldowns = <int, DateTime>{};
  final Duration _directAddCooldown = const Duration(milliseconds: 350);
  DateTime? _lastItemNavigationAt;
  int? _lastNavigatedItemId;
  static const Duration _itemNavigationDebounce =
      Duration(milliseconds: 700);

  List<Item>? _popularItemList;
  List<Item>? get popularItemList => _popularItemList;

  List<Item>? _reviewedItemList;
  List<Item>? get reviewedItemList => _reviewedItemList;

  List<Item>? _recommendedItemList;
  List<Item>? get recommendedItemList => _recommendedItemList;

  List<Item>? _discountedItemList;
  List<Item>? get discountedItemList => _discountedItemList;

  List<Item>? _similarProductsList;
  List<Item>? get similarProductsList => _similarProductsList;

  List<Categories>? _reviewedCategoriesList;
  List<Categories>? get reviewedCategoriesList => _reviewedCategoriesList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<int>? _variationIndex;
  List<int>? get variationIndex => _variationIndex;

  List<List<bool?>> _selectedVariations = [];
  List<List<bool?>> get selectedVariations => _selectedVariations;

  int? _quantity = 1;
  int? get quantity => _quantity;

  List<bool> _addOnActiveList = [];
  List<bool> get addOnActiveList => _addOnActiveList;

  List<int?> _addOnQtyList = [];
  List<int?> get addOnQtyList => _addOnQtyList;

  String _popularType = 'all';
  String get popularType => _popularType;

  String _reviewedType = 'all';
  String get reviewType => _reviewedType;

  String _discountedType = 'all';
  String get discountedType => _discountedType;

  static final List<String> _itemTypeList = ['all', 'veg', 'non_veg'];
  List<String> get itemTypeList => _itemTypeList;

  int _imageIndex = 0;
  int get imageIndex => _imageIndex;

  int _cartIndex = -1;
  int get cartIndex => _cartIndex;

  ItemDetailsViewData _detailsViewData = const ItemDetailsViewData(
      stock: 0, cartModel: null, cart: null, priceWithAddons: 0);
  ItemDetailsViewData get detailsViewData => _detailsViewData;

  Item? _item;
  Item? get item => _item;

  int _productSelect = 0;
  int get productSelect => _productSelect;

  int _imageSliderIndex = 0;
  int get imageSliderIndex => _imageSliderIndex;

  List<bool> _collapseVariation = [];
  List<bool> get collapseVariation => _collapseVariation;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _isReadMore = false;
  bool get isReadMore => _isReadMore;

  BasicMedicineModel? _basicMedicineModel;
  BasicMedicineModel? get basicMedicineModel => _basicMedicineModel;

  List<CommonConditionModel>? _commonConditions;
  List<CommonConditionModel>? get commonConditions => _commonConditions;

  int _selectedCommonCondition = 0;
  int get selectedCommonCondition => _selectedCommonCondition;

  List<Item>? _conditionWiseProduct;
  List<Item>? get conditionWiseProduct => _conditionWiseProduct;

  ItemModel? _featuredCategoriesItem;
  ItemModel? get featuredCategoriesItem => _featuredCategoriesItem;

  int _selectedCategory = 0;
  int get selectedCategory => _selectedCategory;

  void selectCategory(int index) {
    _selectedCategory = index;
    update();
  }

  void selectCommonCondition(int index) {
    _selectedCommonCondition = index;
    getConditionsWiseItem(_commonConditions![index].id!, true);
    update();
  }

  void changeReadMore() {
    _isReadMore = !_isReadMore;
    update();
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }

  void clearItemLists() {
    _popularItemList = null;
    _reviewedItemList = null;
    _discountedItemList = null;
    _featuredCategoriesItem = null;
    _recommendedItemList = null;
  }

  /// 🔧 TASK 2: Reset controller to default state without deleting instance
  /// Used during module switching to preserve controller in memory
  Future<void> resetToDefault() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 ItemController: Resetting to default state');
      }

      // Clear all lists
      clearItemLists();
      _similarProductsList = null;
      _reviewedCategoriesList = null;
      _conditionWiseProduct = null;

      // Reset item
      _item = null;

      // Reset state flags
      _isLoading = false;
      _productSelect = 0;
      _imageSliderIndex = 0;
      _currentIndex = 0;
      _isReadMore = false;
      _selectedCommonCondition = 0;
      _selectedCategory = 0;
      _cartIndex = -1;
      _imageIndex = 0;

      // Reset variation and add-on selections
      _variationIndex = null;
      _selectedVariations = [];
      _addOnActiveList = [];
      _addOnQtyList = [];
      _quantity = 1;
      _collapseVariation = [];

      // Reset filters
      _popularType = 'all';
      _reviewedType = 'all';
      _discountedType = 'all';

      // Reset models
      _basicMedicineModel = null;
      _commonConditions = null;

      if (kDebugMode) {
        debugPrint('✅ ItemController: Reset to default state completed');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ ItemController.resetToDefault: Error - $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  Future<List<Item>?> getPopularItemList(bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    if (businessSettings?.popularProductsSection?.toString() == '1') {
      _popularType = type;

      if (reload) {
        _popularItemList = null;
      }

      if (notify) {
        update();
      }

      if (_popularItemList == null || reload || fromRecall) {
        List<Item>? items;

        if (dataSource == DataSourceEnum.local) {
          items =
              await itemServiceInterface.getPopularItemList(type, dataSource);
          _preparePopularItems(items);
          await getPopularItemList(false, type, notify,
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          items =
              await itemServiceInterface.getPopularItemList(type, dataSource);
          _preparePopularItems(items);
        }
      }

      update();
    }
    return _popularItemList;
  }

  void _preparePopularItems(List<Item>? items) {
    if (items != null) {
      _popularItemList = [];

      // تصفية العناصر ذات stock > 0 وترتيبها حسب السعر من الأقل إلى الأعلى
      final filteredItems = items
          .where((item) => (item.stock ?? 0) != 0)
          .toList()
        ..sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));

      _popularItemList!.addAll(filteredItems);
      _isLoading = false;
    }
    update();
  }

  Future<void> getSimilarProducts(String? categoryId) async {
    _similarProductsList = null;
    // ✅ Null check: Return early if item is not loaded yet (prevents race condition)
    // This can happen if getSimilarProducts is called before getProductDetails completes
    if (_item == null) {
      _similarProductsList = [];
      update();
      return;
    }
    final ItemModel? categoryItem =
        await itemServiceInterface.getCategoryItemList(categoryId, 1, 'all');
    if (categoryItem != null) {
      _similarProductsList ??= [];
      if (categoryItem.items != null) {
        final all = categoryItem.items!.where((test) {
          if (test.id == _item!.id) return false;
          if (test.name == null ||
              _item!.name == null ||
              test.price == null ||
              _item!.price == null) {
            return false;
          }
          final bool nameSimilar =
              test.name!.toLowerCase().contains(_item!.name!.toLowerCase());
          final bool priceSimilar = (test.price! - _item!.price!).abs() <= 10;
          return nameSimilar || priceSimilar;
        }).toList();
        if (all.isNotEmpty) {
          _similarProductsList!.addAll(all);
        } else {
          final all = categoryItem.items!.where((test) {
            if (test.id == _item!.id) return false;
            return true;
          }).toList();
          _similarProductsList!.addAll(all);
        }
      } else {
        _similarProductsList = [];
      }
    } else {
      _similarProductsList = [];
    }
    update();
  }

  Future<List<Item>?> getReviewedItemList(bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    // ✅ التحقق من تفعيل قسم المنتجات الأكثر تقييماً
    if (businessSettings?.mostReviewedProductsSection?.toString() == '1') {
      _reviewedType = type;

      if (reload) {
        _reviewedItemList = null;
      }

      if (notify) {
        update();
      }

      if (_reviewedItemList == null || reload || fromRecall) {
        ItemModel? itemModel;

        if (dataSource == DataSourceEnum.local) {
          itemModel =
              await itemServiceInterface.getReviewedItemList(type, dataSource);
          _preparedReviewedItems(itemModel);

          // ✅ استدعاء من السيرفر بعد البيانات المحلية
          await getReviewedItemList(false, type, notify,
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          itemModel =
              await itemServiceInterface.getReviewedItemList(type, dataSource);
          _preparedReviewedItems(itemModel);
        }
      }
    }
    return _reviewedItemList;
  }

  void _preparedReviewedItems(ItemModel? itemModel) {
    if (itemModel != null) {
      _reviewedItemList = [];
      _reviewedCategoriesList = [];
      _reviewedItemList!.addAll(itemModel.items!);
      _reviewedCategoriesList!.addAll(itemModel.categories!);
      _isLoading = false;
    }
    update();
  }

  Future<List<Item>?> getDiscountedItemList(
      bool reload, bool notify, String type,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    // ✅ تحقق من تفعيل قسم المنتجات المخفضة
    if (businessSettings?.discountedProductsSection?.toString() == '1') {
      _discountedType = type;

      if (reload) {
        _discountedItemList = null;
      }

      if (notify) {
        update();
      }

      if (_discountedItemList == null || reload || fromRecall) {
        List<Item>? items;

        if (dataSource == DataSourceEnum.local) {
          items = await itemServiceInterface.getDiscountedItemList(
              type, dataSource);

          _discountedItemList = [];
          if (items != null) {
            _discountedItemList!.addAll(items);
          }
          _isLoading = false;

          update();

          // ✅ استدعاء من المصدر الأساسي (السيرفر) بعد المصدر المحلي
          await getDiscountedItemList(false, notify, type,
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          items = await itemServiceInterface.getDiscountedItemList(
              type, dataSource);

          _discountedItemList = [];
          if (items != null) {
            _discountedItemList!.addAll(items);
          }
          _isLoading = false;

          update();
        }
      }
    }
    return _discountedItemList;
  }

  Future<ItemModel?> getFeaturedCategoriesItemList(bool reload, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    // ✅ تحقق من تفعيل قسم المنتجات المميزة
    if (businessSettings?.featuredProductsSection?.toString() == '1') {
      if (reload) {
        _featuredCategoriesItem = null;
      }
      if (notify) {
        update();
      }
      if (_featuredCategoriesItem == null || reload || fromRecall) {
        if (dataSource == DataSourceEnum.local) {
          _featuredCategoriesItem = await itemServiceInterface
              .getFeaturedCategoriesItemList(dataSource);
          update();
          await getFeaturedCategoriesItemList(false, notify,
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          _featuredCategoriesItem = await itemServiceInterface
              .getFeaturedCategoriesItemList(dataSource);
          update();
        }
      }
    }
    return _featuredCategoriesItem;
  }

  /// Set item data from cache (handles both ItemModel and raw JSON for various item types)
  void setItemDataFromCache(String type, dynamic data) {
    if (data == null) return;

    try {
      ItemModel? itemModel;

      if (data is ItemModel) {
        // Already deserialized model object
        itemModel = data;
      } else if (data is Map<String, dynamic>) {
        // Raw JSON from disk cache - deserialize it
        itemModel = ItemModel.fromJson(data);
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ ItemController: Unexpected data type for $type: ${data.runtimeType}');
        }
        return;
      }

      // Set the appropriate list based on type
      switch (type) {
        case 'featured':
          if (itemModel.items != null) {
            _featuredCategoriesItem = itemModel;
          }
          break;
        case 'discounted':
          if (itemModel.items != null) {
            _discountedItemList = itemModel.items;
          }
          break;
        case 'popular':
          if (itemModel.items != null) {
            _popularItemList = itemModel.items;
          }
          break;
        case 'reviewed':
          if (itemModel.items != null) {
            _reviewedItemList = itemModel.items;
          }
          break;
        case 'recommended':
          if (itemModel.items != null) {
            _recommendedItemList = itemModel.items;
          }
          break;
        default:
          if (kDebugMode) {
            debugPrint('⚠️ ItemController: Unknown type: $type');
          }
          return;
      }

      update();
      if (kDebugMode) {
        debugPrint(
            '✅ ItemController: Loaded ${itemModel.items?.length ?? 0} $type items from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ItemController: Error setting $type items from cache: $e');
      }
    }
  }

  Future<List<Item>?> getRecommendedItemList(
      bool reload, String type, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    // ✅ تحقق من تفعيل قسم المنتجات المقترحة
    if (businessSettings?.popularStoresSection?.toString() == '1') {
      if (reload) {
        _recommendedItemList = null;
      }
      if (notify) {
        update();
      }
      if (_recommendedItemList == null || reload || fromRecall) {
        List<Item>? items;
        if (dataSource == DataSourceEnum.local) {
          items = await itemServiceInterface.getRecommendedItemList(
              type, dataSource);
          _prepareRecommendedItems(items);
          await getRecommendedItemList(false, type, notify,
              dataSource: DataSourceEnum.client, fromRecall: true);
        } else {
          items = await itemServiceInterface.getRecommendedItemList(
              type, dataSource);
          _prepareRecommendedItems(items);
        }
      }
    }
    return _recommendedItemList;
  }

  void _prepareRecommendedItems(List<Item>? items) {
    if (items != null) {
      _recommendedItemList = [];
      _recommendedItemList!.addAll(items);
      _isLoading = false;
    }
    update();
  }

  Future<void> getBasicMedicine(bool reload, bool notify,
      {DataSourceEnum dataSource = DataSourceEnum.local,
      bool fromRecall = false}) async {
    final businessSettings = Get.find<HomeController>().business_Settings;

    // ✅ التحقق من تفعيل قسم الأدوية الأساسية
    if (businessSettings?.mostReviewedProductsSection?.toString() == '1') {
      if (reload) {
        _basicMedicineModel = null;
      }

      if (notify) {
        update();
      }

      if (_basicMedicineModel == null || reload || fromRecall) {
        if (dataSource == DataSourceEnum.local) {
          _basicMedicineModel =
              await itemServiceInterface.getBasicMedicine(DataSourceEnum.local);
          _isLoading = false;
          update();

          // ✅ جلب البيانات من السيرفر بعد المحلية
          await getBasicMedicine(false, notify,
              fromRecall: true, dataSource: DataSourceEnum.client);
        } else {
          _basicMedicineModel = await itemServiceInterface
              .getBasicMedicine(DataSourceEnum.client);
          _isLoading = false;
          update();
        }
      }
    }
  }

  Future<void> getConditionsWiseItem(int id, bool notify) async {
    _conditionWiseProduct = null;
    if (notify) {
      update();
    }
    final List<Item>? items =
        await itemServiceInterface.getConditionsWiseItems(id);
    if (items != null) {
      _conditionWiseProduct = [];
      _conditionWiseProduct!.addAll(items);
      _isLoading = false;
    }
    update();
  }

  Future<void> getCommonConditions(bool notify) async {
    _commonConditions = [];
    if (notify) {
      update();
    }
    final List<CommonConditionModel>? conditions =
        await itemServiceInterface.getCommonConditions();
    if (conditions != null) {
      _commonConditions!.addAll(conditions);
      _isLoading = false;
    }
    update();
  }

  /// ⚡ SILICON VALLEY WAY: Set mini-cache for instant UI display
  /// Uses basic item data (name, image, price, etc.) immediately for 0ms perceived load
  /// Includes all fields needed for instant header/title display
  void setItemMiniCache(Item item) {
    if (item.id == null) return;

    final newItemId = item.id;
    const bool logEnabled = kDebugMode && AppConstants.enableVerboseLogs;
    // Only update if we're switching to a different item or item is null
    if (_item?.id != newItemId) {
      _quantity = 1;
      _cartIndex = -1;
      _variationIndex = null;
      _selectedVariations = [];
      _addOnActiveList = [];
      _addOnQtyList = [];
      _item = Item(
        id: newItemId,
        name: item.name,
        imageFullUrl: item.imageFullUrl,
        imagesFullUrl: item.imagesFullUrl,
        price: item.price,
        originalPrice: item.originalPrice,
        discount: item.discount,
        discountType: item.discountType,
        storeDiscount: item.storeDiscount,
        avgRating: item.avgRating,
        ratingCount: item.ratingCount,
        description: item.description,
        categoryId: item.categoryId,
        categoryIds: item.categoryIds,
        storeId: item.storeId,
        storeName: item.storeName,
        moduleType: item.moduleType,
        moduleId: item.moduleId,
        variations: item.variations,
        foodVariations: item.foodVariations,
        isStoreHalalActive: item.isStoreHalalActive,
        isHalalItem: item.isHalalItem,
        availableDateStarts: item.availableDateStarts,
        stock: item.stock,
        // Preserve other fields from existing _item if same ID
      );
      if (logEnabled) {
        debugPrint(
            '⚡ [ItemController] SILICON VALLEY WAY: Mini-cache set for item $newItemId - header visible instantly (0ms)');
        debugPrint(
            '   📋 Cached fields: name, image, price, rating, discount, variations, stock');
      }
      _recalculateDetailsViewData();
      update(); // Update UI immediately with mini-cache data
    }
  }

  Future<void> getProductDetails(Item item) async {
    // ⚡ SILICON VALLEY WAY: Don't clear _item if it already has basic data
    // This prevents flicker when fetching additional details
    final hasBasicData = _item?.name != null || _item?.imageFullUrl != null;
    if (!hasBasicData) {
      _item = null;
    }

    // ✅ ALWAYS fetch fresh item details from API to ensure complete data
    // Category list items might have incomplete data (missing food_variations, presets, etc.)
    // The item details endpoint returns full data with all relationships
    final fullItem = await itemServiceInterface.getItemDetails(item.id);

    // Merge full item data with existing mini-cache (preserve UI state)
    if (fullItem != null) {
      _item = fullItem;
    } else {
      _item ??= item;
    }
    if (_item != null) {
      initData(_item, null);
      setExistInCart(_item, _selectedVariations);
    }
    _recalculateDetailsViewData();
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  void initData(Item? item, CartModel? cart) {
    // Early return if item is null
    if (item == null) {
      return;
    }

    _variationIndex = [];
    _addOnQtyList = [];
    _addOnActiveList = [];
    _selectedVariations = [];
    _collapseVariation = [];
    if (cart != null) {
      _quantity = cart.quantity;
      _addOnActiveList.addAll(itemServiceInterface
          .initializeCartAddonActiveList(cart.addOnIds, item.addOns));
      _addOnQtyList.addAll(itemServiceInterface.initializeCartAddonsQtyList(
          cart.addOnIds, item.addOns));

      // Check if new variation format should be used (module config OR presence of food variations)
      final hasFoodVariations =
          item.foodVariations != null && item.foodVariations!.isNotEmpty;
      final useNewVariation =
          ModuleHelper.getModuleConfig(item.moduleType).newVariation ??
              false || hasFoodVariations;

      if (useNewVariation) {
        // ✅ Null-safe: Use empty list if foodVariations is null
        final cartFoodVariations = cart.foodVariations ?? [];
        _selectedVariations.addAll(cartFoodVariations);
        // ✅ Null-safe: Use empty list if item.foodVariations is null
        final itemFoodVariations = item.foodVariations ?? [];
        // If selectedVariations is empty (no cart data), initialize from item
        if (_selectedVariations.isEmpty && itemFoodVariations.isNotEmpty) {
          _selectedVariations.addAll(itemServiceInterface
              .initializeSelectedVariation(itemFoodVariations));
        }
        _collapseVariation
            .addAll(itemServiceInterface.collapseVariation(itemFoodVariations));
      } else {
        _variationIndex = itemServiceInterface.initializeCartVariationIndexes(
            cart.variation, item.choiceOptions);
      }
    } else {
      // Check if new variation format should be used (module config OR presence of food variations)
      final hasFoodVariations =
          item.foodVariations != null && item.foodVariations!.isNotEmpty;
      final useNewVariation =
          ModuleHelper.getModuleConfig(item.moduleType).newVariation ??
              false || hasFoodVariations;

      if (useNewVariation) {
        // ✅ Null-safe: Use empty list if foodVariations is null
        final itemFoodVariations = item.foodVariations ?? [];
        _selectedVariations.addAll(itemServiceInterface
            .initializeSelectedVariation(itemFoodVariations));
        _collapseVariation.addAll(itemServiceInterface
            .initializeCollapseVariation(itemFoodVariations));
      } else {
        _variationIndex =
            itemServiceInterface.initializeVariationIndexes(item.choiceOptions);
      }
      _quantity = 1;
      _addOnActiveList
          .addAll(itemServiceInterface.initializeAddonActiveList(item.addOns));
      _addOnQtyList
          .addAll(itemServiceInterface.initializeAddonQtyList(item.addOns));

      setExistInCart(item, _selectedVariations, notify: true);
    }
    _recalculateDetailsViewData();
  }

  void cartIndexSet() {
    _cartIndex = -1;
  }

  /// Bottom sheet add mode: always start from 1 as delta quantity to add.
  void resetQuantityForIncrementalAdd({bool notify = true}) {
    _quantity = 1;
    _recalculateDetailsViewData();
    if (notify) {
      update();
    }
  }

  Future<int> setExistInCart(Item? item, List<List<bool?>>? selectedVariations,
      {bool notify = false}) async {
    // Early return if item is null
    if (item == null) {
      return -1;
    }

    // ✅ Check if using new variation system (Module 6 with food_variations)
    final hasFoodVariations =
        item.foodVariations != null && item.foodVariations!.isNotEmpty;
    final useNewVariation = (ModuleHelper.getModuleConfig(
                    ModuleHelper.getModule() != null
                        ? ModuleHelper.getModule()!.moduleType
                        : ModuleHelper.getCacheModule()!.moduleType)
                .newVariation ??
            false) ||
        hasFoodVariations;

    String variationType = '';
    // ✅ Only prepare variation type for legacy system (Module 3)
    if (!useNewVariation) {
      variationType = await itemServiceInterface.prepareVariationType(
          item.choiceOptions, _variationIndex);
    }

    if (useNewVariation) {
      _cartIndex = await itemServiceInterface.isExistInCartForBottomSheet(
          Get.find<CartController>().cartList,
          item.id,
          null,
          selectedVariations);
    } else {
      _cartIndex = Get.find<CartController>()
          .isExistInCart(item.id, variationType, false, null);
    }

    if (_cartIndex != -1) {
      _quantity = Get.find<CartController>().cartList[_cartIndex].quantity;
      _addOnActiveList = itemServiceInterface.initializeCartAddonActiveList(
          Get.find<CartController>().cartList[_cartIndex].addOnIds,
          item.addOns);
      _addOnQtyList = itemServiceInterface.initializeCartAddonsQtyList(
          Get.find<CartController>().cartList[_cartIndex].addOnIds,
          item.addOns);
    } else {
      _quantity = 1;
    }
    if (notify) {
      update();
    }
    _recalculateDetailsViewData();
    return _cartIndex;
  }

  void setAddOnQuantity(bool isIncrement, int index) {
    _addOnQtyList[index] = itemServiceInterface.setAddOnQuantity(
        isIncrement, _addOnQtyList[index]!);
    _recalculateDetailsViewData();
    update();
  }

  Future<void> setQuantity(bool isIncrement, int? stock, int? quantityLimit,
      {bool getxSnackBar = false}) async {
    // TEMP: ignore server stock for quantity controls.
    _quantity = await itemServiceInterface.setQuantity(
        isIncrement, false, stock, _quantity!, quantityLimit,
        getxSnackBar: getxSnackBar);
    _recalculateDetailsViewData();
    update();
  }

  void setCartVariationIndex(int index, int i, Item? item) {
    _variationIndex![index] = i;
    _quantity = 1;
    setExistInCart(item, _selectedVariations);
    _recalculateDetailsViewData();
    update();
  }

  void showMoreSpecificSection(int index) {
    _collapseVariation[index] = !_collapseVariation[index];
    update();
  }

  void setNewCartVariationIndex(int index, int i, Item item) {
    // ✅ Null-safe: Use empty list if foodVariations is null
    final foodVariations = item.foodVariations ?? [];
    _selectedVariations = itemServiceInterface.setNewCartVariationIndex(
        index, i, foodVariations, _selectedVariations);
    setExistInCart(item, _selectedVariations);
    _recalculateDetailsViewData();
    // if(!item.foodVariations![index].multiSelect!) {
    //   for(int j = 0; j < _selectedVariations[index].length; j++) {
    //     if(item.foodVariations![index].required!){
    //       _selectedVariations[index][j] = j == i;
    //     }else{
    //       if(_selectedVariations[index][j]!){
    //         _selectedVariations[index][j] = false;
    //       }else{
    //         _selectedVariations[index][j] = j == i;
    //       }
    //     }
    //   }
    // } else {
    //   if(!_selectedVariations[index][i]! && selectedVariationLength(_selectedVariations, index) >= item.foodVariations![index].max!) {
    //     showCustomSnackBar(
    //       '${'maximum_variation_for'.tr} ${item.foodVariations![index].name} ${'is'.tr} ${item.foodVariations![index].max}',
    //       getXSnackBar: true,
    //     );
    //   }else {
    //     _selectedVariations[index][i] = !_selectedVariations[index][i]!;
    //   }
    // }
    update();
  }

  int selectedVariationLength(List<List<bool?>> selectedVariations, int index) {
    return itemServiceInterface.selectedVariationLength(
        selectedVariations, index);
  }

  void addAddOn(bool isAdd, int index) {
    _addOnActiveList[index] = isAdd;
    _recalculateDetailsViewData();
    update();
  }

  bool ensureRequiredVariationsSelected() {
    final item = _item;
    if (item == null) return true;
    final foodVariations = item.foodVariations ?? [];
    if (foodVariations.isEmpty) {
      return true;
    }
    for (int i = 0; i < foodVariations.length; i++) {
      final variation = foodVariations[i];
      if (variation.required == true) {
        final minRequired = variation.min ?? 1;
        final int selectedCount =
            selectedVariationLength(_selectedVariations, i);
        if (selectedCount < minRequired) {
          showCustomSnackBar('please_select_an_option'.tr, getXSnackBar: true);
          return false;
        }
      }
    }
    return true;
  }

  void _recalculateDetailsViewData() {
    final item = _item;
    if (item == null) {
      _detailsViewData = const ItemDetailsViewData(
          stock: 0, cartModel: null, cart: null, priceWithAddons: 0);
      return;
    }

    int stock = item.stock ?? 0;
    CartModel? cartModel;
    OnlineCart? cart;
    double priceWithAddons = 0;

    if (item.choiceOptions != null &&
        item.choiceOptions!.isNotEmpty &&
        _variationIndex != null) {
      final List<String> variationList = [];
      for (int index = 0; index < item.choiceOptions!.length; index++) {
        if (index < _variationIndex!.length &&
            item.choiceOptions![index].options != null &&
            _variationIndex![index] <
                item.choiceOptions![index].options!.length) {
          variationList.add(item
              .choiceOptions![index].options![_variationIndex![index]]
              .replaceAll(' ', ''));
        }
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

      double? price = item.price;
      Variation? variation;
      stock = item.stock ?? 0;
      if (item.variations != null && item.variations!.isNotEmpty) {
        for (final Variation v in item.variations!) {
          if (v.type == variationType) {
            price = v.price;
            variation = v;
            stock = v.stock ?? stock;
            break;
          }
        }
      }

      final double priceWithDiscount = price ?? 0;
      final double priceWithQuantity = priceWithDiscount * (_quantity ?? 1);
      double addonsCost = 0;
      final List<AddOn> addOnIdList = [];
      final List<AddOns> addOnsList = [];
      if (item.addOns != null && item.addOns!.isNotEmpty) {
        for (int index = 0; index < item.addOns!.length; index++) {
          if (index < _addOnActiveList.length && _addOnActiveList[index]) {
            addonsCost = addonsCost +
                (item.addOns![index].price! * _addOnQtyList[index]!);
            addOnIdList.add(AddOn(
                id: item.addOns![index].id, quantity: _addOnQtyList[index]));
            addOnsList.add(item.addOns![index]);
          }
        }
      }

      final double originalPrice = item.originalPrice ?? priceWithDiscount;
      final double discountAmount = originalPrice - priceWithDiscount;

      // 🔧 FIX: Get storeId from multiple sources to ensure it's never null
      int? effectiveStoreId = item.storeId;
      if (effectiveStoreId == null && Get.isRegistered<StoreController>()) {
        effectiveStoreId = Get.find<StoreController>().store?.id;
      }

      cartModel = CartModel(
        id: null,
        // 🔧 FIX: Explicitly set storeId to enable different-store detection
        storeId: effectiveStoreId,
        price: price,
        discountedPrice: priceWithDiscount,
        variation: variation != null ? [variation] : [],
        foodVariations: [],
        discountAmount: discountAmount,
        quantity: _quantity,
        addOnIds: addOnIdList,
        addOns: addOnsList,
        isCampaign: item.availableDateStarts != null,
        stock: stock,
        item: item,
        quantityLimit: item.quantityLimit,
      );

      final List<int?> listOfAddOnId =
          _getSelectedAddonIds(addOnIdList: addOnIdList);
      final List<int?> listOfAddOnQty =
          _getSelectedAddonQtnList(addOnIdList: addOnIdList);

      final int quantity = _quantity ?? 1;
      cart = OnlineCart(
        Get.find<CartController>().getCartIdByItemId(item.id!),
        item.id,
        null,
        priceWithDiscount.toString(),
        '',
        variation != null ? [variation] : [],
        null,
        quantity,
        listOfAddOnId,
        addOnsList,
        listOfAddOnQty,
        'Item',
      );

      priceWithAddons = priceWithQuantity +
          (Get.find<SplashController>()
                  .configModel!
                  .moduleConfig!
                  .module!
                  .addOn!
              ? addonsCost
              : 0);
    }

    if (cartModel == null) {
      final double? price = item.price;
      final double priceWithDiscount = price ?? 0.0;
      final double priceWithQuantity = priceWithDiscount * (_quantity ?? 1);
      double addonsCost = 0;
      final List<AddOn> addOnIdList = [];
      final List<AddOns> addOnsList = [];

      if (item.addOns != null && item.addOns!.isNotEmpty) {
        for (int index = 0; index < item.addOns!.length; index++) {
          if (index < _addOnActiveList.length && _addOnActiveList[index]) {
            addonsCost = addonsCost +
                (item.addOns![index].price! * _addOnQtyList[index]!);
            addOnIdList.add(AddOn(
                id: item.addOns![index].id, quantity: _addOnQtyList[index]));
            addOnsList.add(item.addOns![index]);
          }
        }
      }

      final double originalPrice = item.originalPrice ?? priceWithDiscount;
      final double discountAmount = originalPrice - priceWithDiscount;

      // 🔧 FIX: Get storeId from multiple sources to ensure it's never null
      int? effectiveStoreId2 = item.storeId;
      if (effectiveStoreId2 == null && Get.isRegistered<StoreController>()) {
        effectiveStoreId2 = Get.find<StoreController>().store?.id;
      }

      cartModel = CartModel(
        id: null,
        // 🔧 FIX: Explicitly set storeId to enable different-store detection
        storeId: effectiveStoreId2,
        price: price ?? 0.0,
        discountedPrice: priceWithDiscount,
        variation: [],
        foodVariations: [],
        discountAmount: discountAmount,
        quantity: _quantity,
        addOnIds: addOnIdList,
        addOns: addOnsList,
        isCampaign: item.availableDateStarts != null,
        stock: stock,
        item: item,
        quantityLimit: item.quantityLimit,
      );

      final List<int?> listOfAddOnId =
          _getSelectedAddonIds(addOnIdList: addOnIdList);
      final List<int?> listOfAddOnQty =
          _getSelectedAddonQtnList(addOnIdList: addOnIdList);

      final int quantity = _quantity ?? 1;
      cart = OnlineCart(
        Get.find<CartController>().getCartIdByItemId(item.id!),
        item.id,
        null,
        priceWithDiscount.toString(),
        '',
        [],
        null,
        quantity,
        listOfAddOnId,
        addOnsList,
        listOfAddOnQty,
        'Item',
      );

      priceWithAddons = priceWithQuantity +
          (Get.find<SplashController>()
                  .configModel!
                  .moduleConfig!
                  .module!
                  .addOn!
              ? addonsCost
              : 0);
    }

    _detailsViewData = ItemDetailsViewData(
      stock: stock,
      cartModel: cartModel,
      cart: cart,
      priceWithAddons: priceWithAddons,
    );
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

  void setImageIndex(int index, bool notify) {
    _imageIndex = index;
    if (notify) {
      update();
    }
  }

  void setSelect(int select, bool notify) {
    _productSelect = select;
    if (notify) {
      update();
    }
  }

  void setImageSliderIndex(int index) {
    _imageSliderIndex = index;
    update();
  }

  double? getStartingPrice(Item item) {
    return itemServiceInterface.getStartingPrice(item);
  }

  bool isAvailable(Item item) {
    // TEMP: force all products as available.
    return true;
  }

  double? getDiscount(Item item) =>
      item.storeDiscount == 0 ? item.discount : item.storeDiscount;

  String? getDiscountType(Item item) =>
      item.storeDiscount == 0 ? item.discountType : 'percent';

  /// Check if item has variations/choices that require ItemBottomSheet
  bool _hasVariations(Item item) {
    const bool logEnabled = kDebugMode && AppConstants.enableVerboseLogs;
    // Check for new food variations format
    if (item.foodVariations != null && item.foodVariations!.isNotEmpty) {
      if (logEnabled) {
        debugPrint(
            '✅ [_hasVariations] Item has ${item.foodVariations!.length} foodVariations');
      }
      return true;
    }
    // Check for old choice options format
    if (item.choiceOptions != null && item.choiceOptions!.isNotEmpty) {
      if (logEnabled) {
        debugPrint(
            '✅ [_hasVariations] Item has ${item.choiceOptions!.length} choiceOptions');
      }
      return true;
    }
    // Check for old variations format
    if (item.variations != null && item.variations!.isNotEmpty) {
      if (logEnabled) {
        debugPrint(
            '✅ [_hasVariations] Item has ${item.variations!.length} variations');
      }
      return true;
    }
    // Some food items expose customizations only via add_ons.
    if (item.addOns != null && item.addOns!.isNotEmpty) {
      if (logEnabled) {
        debugPrint('✅ [_hasVariations] Item has ${item.addOns!.length} addOns');
      }
      return true;
    }
    if (logEnabled) {
      debugPrint('❌ [_hasVariations] Item has NO variations');
      debugPrint('   - foodVariations: ${item.foodVariations?.length ?? 0}');
      debugPrint('   - choiceOptions: ${item.choiceOptions?.length ?? 0}');
      debugPrint('   - variations: ${item.variations?.length ?? 0}');
      debugPrint('   - addOns: ${item.addOns?.length ?? 0}');
    }
    return false;
  }

  void navigateToItemPage(Item? item, BuildContext context,
      {bool inStore = false, bool isCampaign = false}) async {
    if (item == null) return;
    final DateTime now = DateTime.now();
    if (_lastNavigatedItemId == item.id &&
        _lastItemNavigationAt != null &&
        now.difference(_lastItemNavigationAt!) < _itemNavigationDebounce) {
      if (kDebugMode) {
        debugPrint(
            '⏭️ [navigateToItemPage] Double tap blocked for item: ${item.id}');
      }
      return;
    }
    _lastNavigatedItemId = item.id;
    _lastItemNavigationAt = now;

    const bool logEnabled = kDebugMode && AppConstants.enableVerboseLogs;
    if (logEnabled) {
      debugPrint(
          '🔍 [navigateToItemPage] Starting navigation for item: ${item.id}');
      debugPrint('   - Item name: ${item.name}');
      debugPrint(
          '   - Item foodVariations count: ${item.foodVariations?.length ?? 0}');
      debugPrint(
          '   - Item choiceOptions count: ${item.choiceOptions?.length ?? 0}');
      debugPrint('   - Item variations count: ${item.variations?.length ?? 0}');
    }

    // Check if it's food module
    final isFoodModule = Get.find<SplashController>()
            .configModel!
            .moduleConfig!
            .module!
            .showRestaurantText! ||
        (item.moduleType ?? AppConstants.food) == AppConstants.food;

    if (logEnabled) {
      debugPrint('   - isFoodModule: $isFoodModule');
      debugPrint('   - item.moduleType: ${item.moduleType}');
    }

    // ItemBottomSheet does the detail fetch for food items.
    // Keep a single request path to avoid duplicate item/details calls.
    final Item fullItem = item;

    if (!context.mounted) {
      return;
    }

    // For food module: always open ItemBottomSheet (same UX as restaurant app style)
    if (isFoodModule) {
      final Item itemToOpen = fullItem;
      if (logEnabled) {
        debugPrint(
            '✅ [navigateToItemPage] Opening ItemBottomSheet for food item');
      }
      ResponsiveHelper.isMobile(context)
          ? Get.bottomSheet<void>(
              ItemBottomSheet(
                  item: itemToOpen,
                  inStorePage: inStore,
                  isCampaign: isCampaign),
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              isDismissible: true,
              enableDrag: true,
              persistent: false,
            )
          : Get.dialog<void>(
              Dialog(
                  child: ItemBottomSheet(
                      item: itemToOpen,
                      inStorePage: inStore,
                      isCampaign: isCampaign)),
            );
    } else {
      if (logEnabled) {
        debugPrint('📄 [navigateToItemPage] Navigating to ItemDetailsScreen');
        debugPrint('   - isFoodModule: $isFoodModule');
        debugPrint('   - fullItem is null: false');
        debugPrint('   - hasVariations: ${_hasVariations(fullItem)}');
      }
      // Navigate to ItemDetailsScreen (for ecommerce or food items without variations)
      // ✅ Use original item if fullItem is null (fallback)
      final itemToNavigate = fullItem;
      final List<Item> allItems = [];
      Get.toNamed<void>(
          RouteHelper.getItemDetailsRoute(itemToNavigate.id, inStore),
          arguments: ItemDetailsScreen(
            item: itemToNavigate,
            inStorePage: inStore,
            isCampaign: isCampaign,
            itemList: allItems,
          ));
    }
  }

  void itemDirectlyAddToCart(Item? item, BuildContext context,
      {bool inStore = false, bool isCampaign = false}) {
    // ✅ Null-safe: Check if item is null first
    if (item == null) {
      return;
    }
    final int? itemId = item.id;
    if (itemId != null) {
      final DateTime? lastTap = _directAddCooldowns[itemId];
      if (lastTap != null &&
          DateTime.now().difference(lastTap) < _directAddCooldown) {
        return;
      }
      _directAddCooldowns[itemId] = DateTime.now();
    }

    // For food items without variations, navigate to detail page instead
    final isFoodModule = Get.find<SplashController>()
            .configModel!
            .moduleConfig!
            .module!
            .showRestaurantText! ||
        item.moduleType == AppConstants.food;

    if (isFoodModule && !_hasVariations(item)) {
      // Navigate to ItemDetailsScreen for food items without variations
      Get.toNamed<void>(RouteHelper.getItemDetailsRoute(item.id, inStore),
          arguments: ItemDetailsScreen(item: item, inStorePage: inStore));
      return;
    }

    // ✅ Treat null variations as "no variations" so we can add directly.
    final bool hasNoFoodVariations =
        item.foodVariations == null || item.foodVariations!.isEmpty;
    final bool hasNoAddOns = item.addOns == null || item.addOns!.isEmpty;
    final bool hasNoVariations =
        item.variations == null || item.variations!.isEmpty;
    if ((hasNoFoodVariations &&
            hasNoAddOns &&
            item.moduleType == AppConstants.food) ||
        (hasNoVariations && item.moduleType != AppConstants.food)) {
      // ✅ Backend already calculated discount - price is ALREADY discounted!
      final double discountedPrice = item.price!;
      final double originalPrice = item.originalPrice ?? item.price!;
      final double discountAmount = originalPrice - discountedPrice;

      // In store page context, trust current store first to avoid false
      // "different store" prompts when item.storeId is inconsistent.
      int? effectiveStoreId3;
      if (inStore && Get.isRegistered<StoreController>()) {
        effectiveStoreId3 = Get.find<StoreController>().store?.id;
      }
      effectiveStoreId3 ??= item.storeId;
      if (effectiveStoreId3 == null && Get.isRegistered<StoreController>()) {
        effectiveStoreId3 = Get.find<StoreController>().store?.id;
      }

      final CartModel cartModel = CartModel(
        id: null,
        // 🔧 FIX: Explicitly set storeId to enable different-store detection
        storeId: effectiveStoreId3,
        price: originalPrice,
        discountedPrice: discountedPrice,
        variation: [],
        foodVariations: [],
        discountAmount: discountAmount,
        quantity: 1,
        addOnIds: [],
        addOns: [],
        isCampaign: isCampaign,
        stock: item.stock,
        item: item,
        quantityLimit: item.quantityLimit,
      );

      final OnlineCart onlineCart = OnlineCart(
        null,
        isCampaign ? null : item.id,
        isCampaign ? item.id : null,
        discountedPrice.toString(), // Use discounted price from backend
        '',
        null,
        (ModuleHelper.getModuleConfig(item.moduleType).newVariation ?? false)
            ? []
            : null,
        1,
        [],
        [],
        [],
        'Item',
      );
      // TEMP: stock gate is intentionally disabled to allow add-to-cart
      // even when backend returns zero stock.
      if (Get.find<CartController>().existAnotherStoreItem(
          effectiveStoreId3,
          ModuleHelper.getModule() != null
              ? ModuleHelper.getModule()?.id
              : ModuleHelper.getCacheModule()?.id)) {
        Get.dialog<void>(
            ConfirmationDialog(
              icon: Images.warning,
              title: 'are_you_sure_to_reset'.tr,
              description: Get.find<SplashController>()
                      .configModel!
                      .moduleConfig!
                      .module!
                      .showRestaurantText!
                  ? 'if_you_continue'.tr
                  : 'if_you_continue_without_another_store'.tr,
              onYesPressed: () {
                Get.find<CartController>()
                    .clearCartOnline()
                    .then((success) async {
                  if (success) {
                    await Get.find<CartController>().addToCartWithFallback(
                      cartModel: cartModel,
                      onlineCart: onlineCart,
                    );
                    Get.back<void>();
                    if (!context.mounted) {
                      return;
                    }
                    showCartSnackBar(context);
                  }
                });
              },
            ),
            barrierDismissible: false);
      } else {
        Get.find<CartController>().addToCartWithFallback(
          cartModel: cartModel,
          onlineCart: onlineCart,
        );
        showCartSnackBar(context);
      }
    } else if (Get.find<SplashController>()
            .configModel!
            .moduleConfig!
            .module!
            .showRestaurantText! ||
        item.moduleType == AppConstants.food) {
      ResponsiveHelper.isMobile(context)
          ? Get.bottomSheet<void>(
              ItemBottomSheet(
                  item: item, inStorePage: inStore, isCampaign: isCampaign),
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              isDismissible: true,
              enableDrag: true,
              persistent: false,
            )
          : Get.dialog<void>(
              Dialog(
                  child: ItemBottomSheet(
                      item: item,
                      inStorePage: inStore,
                      isCampaign: isCampaign)),
            );
    } else {
      Get.toNamed<void>(RouteHelper.getItemDetailsRoute(item.id, inStore),
          arguments: ItemDetailsScreen(item: item, inStorePage: inStore));
    }
  }
}

