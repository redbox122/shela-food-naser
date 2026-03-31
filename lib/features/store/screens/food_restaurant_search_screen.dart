/// Food Restaurant Search Screen - Premium Apple-Luxury Design
/// 
/// Clean, modern search interface for restaurant items
/// Features live search with elegant results display
/// 
/// File: food_restaurant_search_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/widgets/food_restaurant/food_restaurant_menu_item_card.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodRestaurantSearchScreen extends StatefulWidget {
  final int storeId;
  
  const FoodRestaurantSearchScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<FoodRestaurantSearchScreen> createState() => _FoodRestaurantSearchScreenState();
}

class _FoodRestaurantSearchScreenState extends State<FoodRestaurantSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeController = Get.find<StoreController>();
      storeController.clearLiveSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        final bool isLtr = localizationController.isLtr;
        final theme = Theme.of(context);
        final tokens = theme.extension<AppColorTokens>()!;
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isLtr ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                color: theme.textTheme.bodyLarge?.color,
              ),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'search_items'.tr,
              style: robotoBold.copyWith(
                fontSize: 18,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            centerTitle: true,
          ),
          body: GetBuilder<StoreController>(
            builder: (storeController) {
              final searchResults = storeController.liveSearchResults ?? [];
              final isSearching = storeController.isSearching;
              
              return Column(
                children: [
                  // Search Bar Section
                  Container(
                    color: theme.colorScheme.surface,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'search_item_in_store'.tr,
                        hintStyle: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: theme.disabledColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.primaryColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.disabledColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  storeController.clearLiveSearch();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: tokens.surfaceSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: tokens.outlineSoft,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: tokens.outlineSoft,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          storeController.performLiveSearch(value);
                        } else {
                          storeController.clearLiveSearch();
                        }
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          storeController.performLiveSearch(value);
                        }
                      },
                    ),
                  ),
                  
                  // Results Section
                  Expanded(
                    child: _buildSearchResults(
                      context,
                      searchResults,
                      isSearching,
                      _searchController.text,
                      storeController.hasStoreSearchError,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(
      BuildContext context,
      List<dynamic> results, bool isSearching, String searchText, bool hasError) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    // Empty search state
    if (searchText.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: tokens.outlineSoft,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'search_for_items'.tr,
              style: robotoMedium.copyWith(
                fontSize: 16,
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    // Loading state
    if (isSearching) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      );
    }

    // Error state with retry
    if (hasError && searchText.isNotEmpty && results.isEmpty) {
      return ErrorStateView(
        onRetry: () {
          Get.find<StoreController>().performLiveSearch(searchText);
        },
      );
    }

    // No results found
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: tokens.outlineSoft,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'no_items_found'.tr,
              style: robotoMedium.copyWith(
                fontSize: 16,
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    // Display results in list view
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index] as Item;
        return FoodRestaurantMenuItemCard(
          item: item,
          onTap: () {
            Get.find<ItemController>().navigateToItemPage(
              item,
              context,
              inStore: true,
            );
          },
        );
      },
    );
  }
}

