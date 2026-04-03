import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart' as search;
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// شريط فلاتر جديد في صفحة نتائج البحث
/// يحتوي على: عرض (grid/list)، ترتيب، فلاتر متقدمة
class SearchFilterBar extends StatefulWidget {
  final bool isStore;
  const SearchFilterBar({super.key, required this.isStore});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  bool _hasDiscount = false;
  CategoryModel? _selectedCategory;
  Store? _selectedStore;
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

  List<CategoryModel> _categoryList = [];
  List<Store> _storesList = [];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    final categoryController = Get.find<CategoryController>();
    if (categoryController.categoryList != null) {
      _categoryList = categoryController.categoryList!;
    }

    final storeController = Get.find<StoreController>();
    if (storeController.storeModel?.stores != null) {
      _storesList = storeController.storeModel!.stores!;
    }
  }

  void _applyFilters() {
    final searchController = Get.find<search.SearchController>();
    searchController.applyFilters(
      research_Name: _productNameController.text.isNotEmpty
          ? _productNameController.text
          : ' ',
      product_arrangement: _selectedSort,
      id_category: _selectedCategory == null
          ? ''
          : _selectedCategory!.id!.toString(),
      id_stores: _selectedStore == null
          ? ''
          : _selectedStore!.id!.toString(),
      discount: _hasDiscount,
      min: _minPrice,
      max: _maxPrice,
      fromHome: false,
    );
  }

  void _resetFilters() {
    setState(() {
      _productNameController.clear();
      _hasDiscount = false;
      _selectedCategory = null;
      _selectedStore = null;
      _selectedSort = 'popular';
      _selectedPriceLabel = 'الكل';
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر العرض (Grid/List)
          GetBuilder<search.SearchController>(
            builder: (searchController) {
              return InkWell(
                onTap: () {
                  searchController.setVertical(!searchController.isVertical);
                },
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    searchController.isVertical ? Icons.list : Icons.grid_view,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: Dimensions.paddingSizeSmall),

          // زر ترتيب السعر (موجود بالفعل)
          GetBuilder<search.SearchController>(
            builder: (searchController) {
              return InkWell(
                onTap: () {
                  searchController.set_Price(!searchController.isPriceAscending);
                },
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    searchController.isPriceAscending
                        ? Icons.trending_down
                        : Icons.trending_up,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: Dimensions.paddingSizeSmall),

          // زر الفلاتر المتقدمة
          InkWell(
            onTap: () => _showFilterBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeExtraSmall,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'filter'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // عدد النتائج
          GetBuilder<search.SearchController>(
            builder: (searchController) {
              final length = widget.isStore
                  ? (searchController.searchStoreList?.length ?? 0)
                  : (searchController.searchItemList?.length ?? 0);
              return Text(
                '$length ${'results_found'.tr}',
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
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                    onPressed: () => Navigator.pop(context),
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
                      // ترتيب حسب
                      _buildSectionTitle('sort_by'.tr),
                      _buildSortOptions(),

                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // الفئات
                      _buildSectionTitle('all_categories'.tr),
                      _buildCategoryChips(),

                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // المتاجر
                      _buildSectionTitle('all_stores'.tr),
                      _buildStoreChips(),

                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // اسم المنتج
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

                      // الخصم
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'want_discount'.tr,
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                          Switch(
                            value: _hasDiscount,
                            onChanged: (value) {
                              setState(() {
                                _hasDiscount = value;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // نطاق السعر
                      _buildSectionTitle('price_range'.tr),
                      _buildPriceRangeChips(),

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
                      onPressed: _resetFilters,
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
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text(
                        'apply'.tr,
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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

  Widget _buildSortOptions() {
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _sortOptions.keys.map((label) {
        final isSelected = _sortOptions[label] == _selectedSort;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedSort = _sortOptions[label]!;
              });
            }
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips() {
    if (_categoryList.isEmpty) {
      return Text(
        'no_categories_available'.tr,
        style: robotoRegular.copyWith(
          color: Theme.of(context).disabledColor,
        ),
      );
    }
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _categoryList.map((category) {
        final isSelected = _selectedCategory?.id == category.id;
        return ChoiceChip(
          label: Text(category.name ?? ''),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = selected ? category : null;
            });
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStoreChips() {
    if (_storesList.isEmpty) {
      return Text(
        'no_stores_available'.tr,
        style: robotoRegular.copyWith(
          color: Theme.of(context).disabledColor,
        ),
      );
    }
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _storesList.map((store) {
        final isSelected = _selectedStore?.id == store.id;
        return ChoiceChip(
          label: Text(store.name ?? ''),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedStore = selected ? store : null;
            });
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeChips() {
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _priceRanges.map((range) {
        final isSelected = _selectedPriceLabel == range['label'];
        return ChoiceChip(
          label: Text(range['label']!),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedPriceLabel = range['label']!;
                _minPrice = range['min']!;
                _maxPrice = range['max']!;
              });
            }
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }).toList(),
    );
  }
}

