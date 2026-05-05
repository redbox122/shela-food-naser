import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Filter bar for category screen with sort, price range and search controls.
class CategoryFilterBar extends StatefulWidget {
  final String categoryID;
  const CategoryFilterBar({super.key, required this.categoryID});

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  String _selectedSort = 'popular';
  String _selectedPriceKey = 'all';
  String _minPrice = '';
  String _maxPrice = '';
  int _lastFilterResetVersion = 0;
  final TextEditingController _productNameController = TextEditingController();

  final List<Map<String, String>> _sortOptions = [
    {'labelKey': 'popularity', 'value': 'popular'},
    {'labelKey': 'ascending', 'value': 'ascending'},
    {'labelKey': 'descending', 'value': 'descending'},
  ];

  final List<Map<String, String>> _priceRanges = [
    {'key': 'all', 'labelKey': 'all', 'min': '0', 'max': '0'},
    {'key': '0-10', 'label': '0 - 10', 'min': '0', 'max': '10'},
    {'key': '20-40', 'label': '20 - 40', 'min': '20', 'max': '40'},
    {'key': '40-70', 'label': '40 - 70', 'min': '40', 'max': '70'},
    {'key': '70-100', 'label': '70 - 100', 'min': '70', 'max': '100'},
    {'key': '150-200', 'label': '150 - 200', 'min': '150', 'max': '200'},
    {'key': '200-300', 'label': '200 - 300', 'min': '200', 'max': '300'},
    {'key': '300-500', 'label': '300 - 500', 'min': '300', 'max': '500'},
    {'key': '500-700', 'label': '500 - 700', 'min': '500', 'max': '700'},
    {'key': '700-1000', 'label': '700 - 1000', 'min': '700', 'max': '1000'},
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
    _lastFilterResetVersion = categoryController.filterResetVersion;
    _selectedPriceKey = _priceRanges.firstWhere(
      (range) => range['min'] == _minPrice && range['max'] == _maxPrice,
      orElse: () => _priceRanges.first,
    )['key']!;
  }

  void _syncLocalStateIfControllerReset(CategoryController controller) {
    if (_lastFilterResetVersion == controller.filterResetVersion) {
      return;
    }

    _lastFilterResetVersion = controller.filterResetVersion;
    _productNameController.clear();
    _selectedSort = controller.currentProductArrangement;
    _minPrice = controller.currentMinPrice;
    _maxPrice = controller.currentMaxPrice;
    _selectedPriceKey = _priceRanges.firstWhere(
      (range) => range['min'] == _minPrice && range['max'] == _maxPrice,
      orElse: () => _priceRanges.first,
    )['key']!;
  }

  void _applyFilters() {
    final categoryController = Get.find<CategoryController>();

    final String rawQuery = _productNameController.text.trim();
    final bool hasQuery = rawQuery.isNotEmpty;
    final String effectiveCategoryId = widget.categoryID;
    final bool shouldUseApiSearch = hasQuery;
    final String selectedCategoryId = widget.categoryID;
    final String requestCategoryId = effectiveCategoryId;
    _logFilter(
        '[CATEGORY_CONTEXT] screenCategoryId=${widget.categoryID} selectedCategoryId=$selectedCategoryId requestCategoryId=$requestCategoryId');
    if (requestCategoryId.isEmpty) {
      if (hasQuery) {
        _logFilter('[CATEGORY_CONTEXT_CLEARED_BY_USER]');
      } else {
        _logFilter('[CATEGORY_CONTEXT_MISSING] reason=empty_category_id');
      }
    } else {
      _logFilter('[CATEGORY_CONTEXT_APPLIED] category_id=$requestCategoryId');
    }

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
      'scope': 'current_category',
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
      _selectedPriceKey = 'all';
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
        _syncLocalStateIfControllerReset(categoryController);

        final theme = Theme.of(context);
        final tokens = theme.extension<AppColorTokens>()!;
        final Color selectedChipColor = tokens.successSoft;
        final Color selectedChipTextColor = theme.primaryColor;
        final bool hasActiveFilters = _selectedSort != 'popular' ||
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
              InkWell(
                onTap: () {
                  categoryController.setVerticalItems(
                    !categoryController.isVertical,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    categoryController.isVertical
                        ? Icons.list
                        : Icons.grid_view,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              InkWell(
                onTap: () {
                  categoryController.set_Price(
                    !categoryController.isPriceAscending,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
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
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
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
                            ? selectedChipTextColor
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'filter'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: hasActiveFilters
                              ? selectedChipTextColor
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
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
      'sort=$_selectedSort, price=$_selectedPriceKey($_minPrice-$_maxPrice), query="${_productNameController.text}"',
    );

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
          builder: (context, scrollController) => SafeArea(
            top: false,
            bottom: true,
            left: false,
            right: false,
            minimum: EdgeInsets.zero,
            child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        _buildSectionTitle('sort_by'.tr),
                        _buildSortOptions(modalSetState: modalSetState),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildSectionTitle('product_name'.tr),
                        TextField(
                          controller: _productNameController,
                          decoration: InputDecoration(
                            hintText: 'example'.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusDefault,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        _buildSectionTitle('price_range'.tr),
                        _buildPriceRangeChips(modalSetState: modalSetState),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _resetFilters(modalSetState: modalSetState),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeDefault,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeDefault,
                          ),
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
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    final Color selectedChipColor = tokens.successSoft;
    final Color selectedChipTextColor = theme.primaryColor;

    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _sortOptions.map((option) {
        final String value = option['value']!;
        final String label = option['label'] ?? option['labelKey']!.tr;
        final bool isSelected = value == _selectedSort;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: selectedChipTextColor,
          onSelected: (selected) {
            if (selected) {
              final updater = modalSetState ?? setState;
              updater(() {
                _selectedSort = value;
              });
              _logFilter(
                  'sort changed => label="$label", value=$_selectedSort');
            }
          },
          selectedColor: selectedChipColor,
          labelStyle: TextStyle(
            color: isSelected
                ? selectedChipTextColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeChips({StateSetter? modalSetState}) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    final Color selectedChipColor = tokens.successSoft;
    final Color selectedChipTextColor = theme.primaryColor;

    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _priceRanges.map((range) {
        final String label = range['label'] ?? range['labelKey']!.tr;
        final bool isSelected = _selectedPriceKey == range['key'];

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: selectedChipTextColor,
          onSelected: (selected) {
            if (selected) {
              final updater = modalSetState ?? setState;
              updater(() {
                _selectedPriceKey = range['key']!;
                _minPrice = range['min']!;
                _maxPrice = range['max']!;
              });
              _logFilter(
                'price range changed => $_selectedPriceKey ($_minPrice-$_maxPrice)',
              );
            }
          },
          selectedColor: selectedChipColor,
          labelStyle: TextStyle(
            color: isSelected
                ? selectedChipTextColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }
}
