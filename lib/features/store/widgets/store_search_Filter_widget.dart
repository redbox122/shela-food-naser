// ignore_for_file: file_names, avoid_print, camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/images.dart';

class Store_Search_Filter_Widget extends StatefulWidget {
  final String storeID;

  const Store_Search_Filter_Widget({super.key, required this.storeID});

  @override
  State<Store_Search_Filter_Widget> createState() =>
      _Store_Search_Filter_WidgetState();
}

class _Store_Search_Filter_WidgetState
    extends State<Store_Search_Filter_Widget> {
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
  late List<CategoryModel> categoryList;
  late List<Store> storesList;

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

    storesList = Get.find<StoreController>().storeModel!.stores!;

    categoryList = Get.find<CategoryController>().categoryList!;
    if (categoryList.isNotEmpty) {
      selectedCategory = categoryList.first;
    }

    storesList = Get.find<StoreController>().storeModel!.stores!;
    if (storesList.isNotEmpty) {
      selectedStore = storesList.first;
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
      child:
          //

          categoryList.isEmpty || storesList.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: 'البحث حسب'),

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

                        const Text('الفئة',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),

                        const SizedBox(height: 10),

                        Choice_Category_Row<CategoryModel>(
                          options: categoryList,
                          selected: selectedCategory,
                          labelBuilder: (category) => category.name ?? '',
                          onSelected: (value) =>
                              setState(() => selectedCategory = value),
                        ),

                        //

                        const SizedBox(height: 20),

                        const SectionTitle(title: 'اسم المنتج'),

                        const SizedBox(height: 10),

                        CustomTextField(
                            controller: nameController, hint: 'مثال: شامبو'),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('هل تريد خصم؟',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Switch(
                              value: hasDiscount,
                              onChanged: (value) =>
                                  setState(() => hasDiscount = value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const SectionTitle(title: 'نطاق السعر'),

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
                                child: const Text('إعادة تعيين',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('تطبيق',
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () async {
                                  //

                                  Get.find<StoreController>().applyFilters(
                                    research_Name:
                                        nameController.text.isNotEmpty
                                            ? nameController.text
                                            : ' ',
                                    product_arrangement: selectedSort,
                                    id_category: selectedCategory == null
                                        ? ''
                                        : selectedCategory!.id!.toString(),
                                    id_stores: widget.storeID,
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
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        final parts = option.split('-').map((e) => e.trim()).toList();

        return ChoiceChip(
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: Colors.green,
          backgroundColor: Colors.grey[300],
          label: parts.length == 2
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(parts[0],
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black)),
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
                            color: isSelected ? Colors.white : Colors.black)),
                    const SizedBox(width: 6),
                    Text(parts[1],
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black)),
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
                      color: isSelected ? Colors.white : Colors.black)),
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
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: const Color(0xFFE8F5E9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
      ),
    );
  }
}

class Choice_Category_Row<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;

  const Choice_Category_Row({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
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
                style:
                    TextStyle(color: isSelected ? Colors.white : Colors.black),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: Colors.green,
              backgroundColor: Colors.grey[300],
            ),
          );
        }).toList(),
      ),
    );
  }
}
