
// ❌ DEPRECATED: هذا الملف لم يعد مستخدماً
// تم نقل جميع الفلاتر إلى SearchFilterBar في صفحة نتائج البحث
// يمكن حذف هذا الملف في المستقبل

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart'
    as search;

// @Deprecated('Use SearchFilterBar instead - الفلاتر الآن في شريط الفلاتر في صفحة النتائج')
class ProductFilterScreen extends StatefulWidget {
  const ProductFilterScreen({super.key});

  @override
  State<ProductFilterScreen> createState() => _ProductFilterScreenState();
}

class _ProductFilterScreenState extends State<ProductFilterScreen> {
  // Controllers
  final TextEditingController nameController = TextEditingController();

  // Filters
  bool hasDiscount = false;
  CategoryModel? selectedCategory;
  Store? selectedStore;

  String selectedSort = 'popular';

  String selectedPriceLabel = 'الكل';
  String min = '';
  String max = '';

  // Data
  List<CategoryModel> categoryList = [];
  List<Store> storesList = [];
  bool _isLoading = true;

  final Map<String, String> sortOptions = {
    'الأكثر مبيعًا': 'popular',
    'أ _ ي': 'ascending',
    'ي _ أ': 'descending',
  };

  final List<Map<String, String>> priceRanges = [
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

  @override
  void initState() {
    super.initState();
    selectedSort = sortOptions.values.first;
    selectedPriceLabel = priceRanges[0]['label']!;

    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load stores if not available
      final storeController = Get.find<StoreController>();
      if (storeController.storeModel == null ||
          storeController.storeModel!.stores == null ||
          storeController.storeModel!.stores!.isEmpty) {
        await storeController.getStoreList(1, false);
      }
      storesList = storeController.storeModel?.stores ?? [];

      // Load categories if not available
      final categoryController = Get.find<CategoryController>();
      if (categoryController.categoryList == null ||
          categoryController.categoryList!.isEmpty) {
        await categoryController.getCategoryList(false);
      }
      categoryList = categoryController.categoryList ?? [];

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (categoryList.isNotEmpty) {
            selectedCategory = categoryList.first;
          }
          if (storesList.isNotEmpty) {
            selectedStore = storesList.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void resetFilters() {
    setState(() {
      nameController.clear();
      selectedSort = sortOptions.values.first;
      selectedPriceLabel = priceRanges[0]['label']!;
      selectedCategory = null;
      selectedStore = null;
      hasDiscount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : categoryList.isEmpty || storesList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('loading_filters'.tr),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(title: 'sort_by'.tr),

                        const SizedBox(height: 10),
                        ChoiceChipsRow(
                          options: sortOptions.keys.toList(),
                          selected: sortOptions.entries
                              .firstWhere((e) => e.value == selectedSort,
                                  orElse: () => const MapEntry('', ''))
                              .key,
                          onSelected: (selectedArabicLabel) {
                            setState(() {
                              selectedSort = sortOptions[selectedArabicLabel]!;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Category  ========================================================================

                        Text('all_categories'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),

                        const SizedBox(height: 10),

                        ChoiceCategoryRow<CategoryModel>(
                          options: categoryList,
                          selected: selectedCategory,
                          labelBuilder: (category) => category.name ?? '',
                          onSelected: (value) =>
                              setState(() => selectedCategory = value),
                        ),

                        //  Stores  ========================================================================

                        const SizedBox(height: 20),

                        Text('all_stores'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),

                        const SizedBox(height: 10),
                        ChoiceCategoryRow<Store>(
                          options: storesList,
                          selected: selectedStore,
                          labelBuilder: (store) => store.name ?? '',
                          onSelected: (value) =>
                              setState(() => selectedStore = value),
                        ),

                        //

                        const SizedBox(height: 20),

                        SectionTitle(title: 'product_name'.tr),

                        const SizedBox(height: 10),

                        CustomTextField(
                          controller: nameController,
                          hint: 'example'.tr,
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('want_discount'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Switch(
                              value: hasDiscount,
                              onChanged: (value) =>
                                  setState(() => hasDiscount = value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        SectionTitle(title: 'price_range'.tr),

                        ChoiceChipsRow(
                          options: priceRanges
                              .map((e) => e['label'].toString())
                              .toList(),
                          selected: selectedPriceLabel,
                          onSelected: (value) {
                            final found = priceRanges
                                .firstWhere((e) => e['label'] == value);
                            setState(() {
                              selectedPriceLabel = value;
                              min = found['min']!;
                              max = found['max']!;
                            });
                          },
                        ),

                        const SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: resetFilters,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('reset'.tr,
                                    style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('apply'.tr,
                                    style:
                                        TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                                onPressed: () async {
                                  //

                                  Get.find<search.SearchController>()
                                      .applyFilters(
                                    research_Name:
                                        nameController.text.isNotEmpty
                                            ? nameController.text
                                            : ' ',
                                    product_arrangement: selectedSort,
                                    id_category: selectedCategory == null
                                        ? ''
                                        : selectedCategory!.id!.toString(),
                                    id_stores: selectedStore == null
                                        ? ''
                                        : selectedStore!.id!.toString(),
                                    min: min.toString(),
                                    max: max.toString(),
                                    discount: hasDiscount,
                                    fromHome: true,
                                  );

                                  Get.back<void>();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

/// عنوان قسم
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }
}

/// صف
class ChoiceChipsRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const ChoiceChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        final parts = option.split('-').map((e) => e.trim()).toList();

        return ChoiceChip(
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: tokens.surfaceSoft,
          label: parts.length == 2
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(parts[0],
                        style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(width: 4),
                    Image.asset(
                      Images.sar,
                      width: 12,
                      height: 12,
                      cacheWidth: 36,
                      cacheHeight: 36,
                    ),
                    const SizedBox(width: 6),
                    Text('-',
                        style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(width: 6),
                    Text(parts[1],
                        style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(width: 4),
                    Image.asset(
                      Images.sar,
                      width: 12,
                      height: 12,
                      cacheWidth: 36,
                      cacheHeight: 36,
                    ),
                  ],
                )
              : Text(option,
                  style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface)),
        );
      }).toList(),
    );
  }
}

/// حقل إدخال مخصص
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const CustomTextField(
      {super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).disabledColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Theme.of(context).extension<AppColorTokens>()!.surfaceSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class ChoiceCategoryRow<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;

  const ChoiceCategoryRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                labelBuilder(option),
                style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: tokens.surfaceSoft,
            ),
          );
        }).toList(),
      ),
    );
  }
}

