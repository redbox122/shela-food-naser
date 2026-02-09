import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
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

  List<Store> _storesList = [];

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
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    final storeController = Get.find<StoreController>();
    if (storeController.storeModel?.stores != null) {
      setState(() {
        _storesList = storeController.storeModel!.stores!;
      });
    }
  }

  void _applyFilters() {
    final categoryController = Get.find<CategoryController>();
    categoryController.applyFilters(
      research_Name: _productNameController.text.isNotEmpty
          ? _productNameController.text
          : ' ',
      product_arrangement: _selectedSort,
      id_category: widget.categoryID,
      id_stores: _selectedStore == null
          ? ''
          : _selectedStore!.id!.toString(),
      min: _minPrice,
      max: _maxPrice,
      discount: false,
      fromHome: true,
    );
  }

  void _resetFilters({StateSetter? modalSetState}) {
    final updater = modalSetState ?? setState;
    updater(() {
      _productNameController.clear();
      _selectedStore = null;
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
            _selectedStore != null ||
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
                onTap: () => _showFilterBottomSheet(context),
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
              Text(
                '${categoryController.pageSize ?? 0} ${'products'.tr}',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
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
                        // ?????????? ??????
                        _buildSectionTitle('sort_by'.tr),
                        _buildSortOptions(modalSetState: modalSetState),

                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // ??????????????
                        _buildSectionTitle('all_stores'.tr),
                        _buildStoreChips(modalSetState: modalSetState),

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

  Widget _buildStoreChips({StateSetter? modalSetState}) {
    if (_storesList.isEmpty) {
      return Text(
        'غير متاح',
        style: robotoRegular.copyWith(
          color: Theme.of(context).disabledColor,
        ),
      );
    }
    const Color selectedChipColor = Color(0xFFC8E6C9);
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: _storesList.map((store) {
        final isSelected = _selectedStore?.id == store.id;
        return ChoiceChip(
          label: Text(store.name ?? ''),
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: const Color(0xFF1B5E20),
          onSelected: (selected) {
            final updater = modalSetState ?? setState;
            updater(() {
              _selectedStore = selected ? store : null;
            });
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

