import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// شريط فلاتر جديد في صفحة الكاتجوري
/// يحتوي على: عرض (grid/list)، ترتيب، فلاتر متقدمة
class CategoryFilterBar extends StatefulWidget {
  final String categoryID;
  const CategoryFilterBar({super.key, required this.categoryID});

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  String _selectedSort = 'popular';
  String _selectedPriceLabel = 'الكل';
  String _minPrice = '';
  String _maxPrice = '';
  final TextEditingController _productNameController = TextEditingController();

  final Map<String, String> _sortOptions = {
    'الأكثر مبيعًا': 'popular',
    'أ - ي': 'ascending',
    'ي - أ': 'descending',
  };

  final List<Map<String, String>> _priceRanges = [
    {'label': 'الكل', 'min': '0', 'max': '0'},
    {'label': '0 - 10', 'min': '0', 'max': '10'},
    {'label': '20 - 40', 'min': '20', 'max': '40'},
    {'label': '40 - 70', 'min': '40', 'max': '70'},
    {'label': '70 - 100', 'min': '70', 'max': '100'},
    {'label': '150 - 200', 'min': '150', 'max': '200'},
    {'label': '200 - 300', 'min': '200', 'max': '300'},
    {'label': '300 - 500', 'min': '300', 'max': '500'},
    {'label': '500 - 700', 'min': '500', 'max': '700'},
    {'label': '700 - 1000', 'min': '700', 'max': '1000'},
  ];
  void _logFilter(String message) {
    debugPrint('[CAT_FILTER] $message');
    appLogger.debug('[CAT_FILTER] $message');
  }

  @override
  void initState() {
    super.initState();
    final categoryController = Get.find<CategoryController>();
    _selectedSort = categoryController.currentProductArrangement;
    _minPrice = categoryController.currentMinPrice;
    _maxPrice = categoryController.currentMaxPrice;
    _selectedPriceLabel = _priceRanges
        .firstWhere(
          (range) => range['min'] == _minPrice && range['max'] == _maxPrice,
          orElse: () => _priceRanges.first,
        )['label']!;
  }

  void _applyFilters() {
    final categoryController = Get.find<CategoryController>();
    final splashController = Get.find<SplashController>();

    final String rawQuery = _productNameController.text.trim();
    final bool hasQuery = rawQuery.isNotEmpty;
    final bool isEcommerceModule =
        splashController.module?.moduleType == AppConstants.ecommerce ||
            splashController.module?.id == 3;

    // Option 1 (Hyper): when searching by name from category filter,
    // search across all Hyper categories (do not pin to current category).
    final bool shouldSearchAllHyperCategories = isEcommerceModule && hasQuery;
    final String effectiveCategoryId =
        shouldSearchAllHyperCategories ? '' : widget.categoryID;
    final bool shouldUseApiSearch = shouldSearchAllHyperCategories;

    // If we are leaving API-search mode, return to normal category-local mode.
    if (!shouldUseApiSearch && categoryController.isSearching) {
      categoryController.toggleSearch(context);
    }

    final payload = {
      'research_Name': hasQuery ? rawQuery : ' ',
      'product_arrangement': _selectedSort,
      'id_category': effectiveCategoryId,
      'id_stores': '',
      'min': _minPrice,
      'max': _maxPrice,
      'discount': false,
      'fromHome': !shouldUseApiSearch,
      'scope': shouldSearchAllHyperCategories
          ? 'hyper_all_categories'
          : 'current_category',
    };
    _logFilter('_applyFilters payload => $payload');
    categoryController.applyFilters(
      research_Name: payload['research_Name'] as String,
      product_arrangement: payload['product_arrangement'] as String,
      id_category: payload['id_category'] as String,
      id_stores: payload['id_stores'] as String,
      min: payload['min'] as String,
      max: payload['max'] as String,
      discount: payload['discount'] as bool,
      fromHome: payload['fromHome'] as bool,
    );
  }

  void _resetFilters({StateSetter? modalSetState}) {
    _logFilter('_resetFilters: resetting local filter state');
    final updater = modalSetState ?? setState;
    updater(() {
      _productNameController.clear();
      _selectedSort = 'popular';
      _selectedPriceLabel = '????????';
      _minPrice = '';
      _maxPrice = '';
    });
    _applyFilters();
  }


  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        const Color selectedChipColor = Color(0xFFC8E6C9);
        final bool hasActiveFilters =
            _selectedSort != 'popular' ||
            (_minPrice.isNotEmpty && _minPrice != '0') ||
            (_maxPrice.isNotEmpty && _maxPrice != '0') ||
            _productNameController.text.trim().isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeExtraSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // زر العرض (Grid/List)
              InkWell(
                onTap: () {
                  categoryController.setVerticalItems(!categoryController.isVertical);
                },
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    categoryController.isVertical ? Icons.list : Icons.grid_view,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),

              const SizedBox(width: Dimensions.paddingSizeSmall),

              // زر ترتيب السعر
              InkWell(
                onTap: () {
                  categoryController.set_Price(!categoryController.isPriceAscending);
                },
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: categoryController.isPriceAscending
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : selectedChipColor,
                  ),
                  child: Icon(
                    categoryController.isPriceAscending
                        ? Icons.trending_down
                        : Icons.trending_up,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),

              const SizedBox(width: Dimensions.paddingSizeSmall),

              // زر الفلاتر المتقدمة
              InkWell(
                onTap: () {
                  _logFilter(
                      'filter button tapped (categoryID=${widget.categoryID})');
                  _showFilterBottomSheet(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: hasActiveFilters
                        ? selectedChipColor
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 20,
                        color: hasActiveFilters
                            ? const Color(0xFF1B5E20)
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'filter'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: hasActiveFilters
                              ? const Color(0xFF1B5E20)
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // عدد المنتجات
              Builder(
                builder: (_) {
                  final bool isSearching = categoryController.isSearching;
                  final bool loadingItems = !categoryController.isStore &&
                      categoryController.isLoading &&
                      ((isSearching
                                  ? categoryController.searchItemList
                                  : categoryController.categoryItemList) ==
                              null);
                  final bool loadingStores = categoryController.isStore &&
                      categoryController.isLoading &&
                      ((isSearching
                                  ? categoryController.searchStoreList
                                  : categoryController.categoryStoreList) ==
                              null);

                  final String countText = (loadingItems || loadingStores)
                      ? '...'
                      : categoryController.isStore
                          ? '${(isSearching ? categoryController.searchStoreList?.length : categoryController.categoryStoreList?.length) ?? 0}'
                          : '${(isSearching ? categoryController.searchItemList?.length : categoryController.categoryItemList?.length) ?? 0}';

                  final bool showRestaurantsText =
                      Get.isRegistered<SplashController>() &&
                          (Get.find<SplashController>()
                                  .configModel
                                  ?.moduleConfig
                                  ?.module
                                  ?.showRestaurantText ??
                              false);
                  final String labelText = categoryController.isStore
                      ? (showRestaurantsText ? 'restaurants'.tr : 'stores'.tr)
                      : 'products'.tr;

                  return Text(
                    '$countText $labelText',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    _logFilter(
        '_showFilterBottomSheet open with state => '
        'sort=$_selectedSort, price=$_selectedPriceLabel($_minPrice-$_maxPrice), query="${_productNameController.text}"');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'filter'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        _logFilter('bottom sheet closed from X');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ?????????? ??????
                        _buildSectionTitle('sort_by'.tr),
                        _buildSortOptions(modalSetState: modalSetState),

                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // ?????? ????????????
                        _buildSectionTitle('product_name'.tr),
                        TextField(
                          controller: _productNameController,
                          decoration: InputDecoration(
                            hintText: 'example'.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                          ),
                        ),

                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // ???????? ??????????
                        _buildSectionTitle('price_range'.tr),
                        _buildPriceRangeChips(modalSetState: modalSetState),

                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _resetFilters(modalSetState: modalSetState),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                        ),
                        child: Text('reset'.tr),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _logFilter('apply tapped in bottom sheet');
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          'apply'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Text(
        title,
        style: robotoBold.copyWith(
          fontSize: Dimensions.fontSizeDefault,
        ),
      ),
    );
  }

  Widget _buildSortOptions({StateSetter? modalSetState}) {
    const Color selectedChipColor = Color(0xFFC8E6C9);
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _sortOptions.keys.map((label) {
        final isSelected = _sortOptions[label] == _selectedSort;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: const Color(0xFF1B5E20),
          onSelected: (selected) {
            if (selected) {
              final updater = modalSetState ?? setState;
              updater(() {
                _selectedSort = _sortOptions[label]!;
              });
              _logFilter('sort changed => label="$label", value=$_selectedSort');
            }
          },
          selectedColor: selectedChipColor,
          labelStyle: TextStyle(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeChips({StateSetter? modalSetState}) {
    const Color selectedChipColor = Color(0xFFC8E6C9);
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _priceRanges.map((range) {
        final isSelected = _selectedPriceLabel == range['label'];
        return ChoiceChip(
          label: Text(range['label']!),
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: const Color(0xFF1B5E20),
          onSelected: (selected) {
            if (selected) {
              final updater = modalSetState ?? setState;
              updater(() {
                _selectedPriceLabel = range['label']!;
                _minPrice = range['min']!;
                _maxPrice = range['max']!;
              });
              _logFilter(
                  'price range changed => $_selectedPriceLabel ($_minPrice-$_maxPrice)');
            }
          },
          selectedColor: selectedChipColor,
          labelStyle: TextStyle(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }
}


