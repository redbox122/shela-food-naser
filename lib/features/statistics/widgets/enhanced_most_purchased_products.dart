import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../domain/models/most_purchased_product.dart';
import '../screens/simple_product_deep_dive_screen.dart';

class EnhancedMostPurchasedProducts extends StatefulWidget {
  const EnhancedMostPurchasedProducts({super.key});

  @override
  State<EnhancedMostPurchasedProducts> createState() =>
      _EnhancedMostPurchasedProductsState();
}

class _EnhancedMostPurchasedProductsState
    extends State<EnhancedMostPurchasedProducts> {
  bool _isGridView = true;

  // Helper function to convert Western Arabic numerals to Eastern Arabic numerals
  String _convertToArabicNumerals(String text) {
    const Map<String, String> arabicNumerals = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩'
    };

    return text.split('').map((char) => arabicNumerals[char] ?? char).join();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<AnalyticsController>(
      builder: (controller) {
        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              if (controller.isLoadingProducts)
                _buildLoadingState()
              else if (controller.productsError.isNotEmpty)
                _buildErrorState(controller.productsError,
                    () => controller.loadMostPurchasedProducts())
              else if (controller.mostPurchasedProducts.isEmpty)
                _buildNoDataState()
              else
                _buildProductsList(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AnalyticsController controller) {
    return Row(
      children: [
        const Icon(
          Icons.shopping_cart,
          color: AppColors.greenColor,
          size: 20,
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(
          'most_purchased_products'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.title,
          ),
        ),
        const Spacer(),
        _buildSortDropdown(controller),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        _buildViewToggle(),
      ],
    );
  }

  Widget _buildSortDropdown(AnalyticsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greenColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButton<String>(
        value: controller.currentSortBy,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.greenColor),
        style: const TextStyle(
          color: AppColors.greenColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items:
            controller.availableSortOptions.map((Map<String, String> option) {
          return DropdownMenuItem<String>(
            value: option['key'],
            child: Text(option['label']!),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            controller.sortMostPurchasedProducts(newValue);
          }
        },
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greenColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.grid_view,
            isSelected: _isGridView,
            onTap: () => setState(() => _isGridView = true),
          ),
          _buildToggleButton(
            icon: Icons.list,
            isSelected: !_isGridView,
            onTap: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.wtColor : AppColors.greenColor,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: AppColors.wtColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.greenColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.redColor,
              size: 48,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'failed_to_load_products'.tr,
              style: const TextStyle(
                color: AppColors.redColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.length > 40 ? '${error.substring(0, 40)}...' : error,
              style: TextStyle(
                color: AppColors.gryColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenColor,
                foregroundColor: AppColors.wtColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.gryColor.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'no_products_found'.tr,
              style: TextStyle(
                color: AppColors.gryColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(AnalyticsController controller) {
    if (_isGridView) {
      return _buildGridView(controller);
    } else {
      return _buildListView(controller);
    }
  }

  Widget _buildGridView(AnalyticsController controller) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.mostPurchasedProducts.length,
        itemBuilder: (context, index) {
          final product = controller.mostPurchasedProducts[index];
          return _buildProductCard(product, controller);
        },
      ),
    );
  }

  Widget _buildListView(AnalyticsController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.mostPurchasedProducts.length,
      itemBuilder: (context, index) {
        final product = controller.mostPurchasedProducts[index];
        return _buildProductListItem(product, controller);
      },
    );
  }

  Widget _buildProductCard(
      MostPurchasedProduct product, AnalyticsController controller) {
    return GestureDetector(
      onTap: () => _navigateToProductDeepDive(product, controller),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: AppColors.wtColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.title,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_convertToArabicNumerals(product.priceRange.current.toStringAsFixed(2))} ر.س',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        size: 12,
                        color: AppColors.gryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_convertToArabicNumerals(product.purchaseCount.toString())} ${'times'.tr}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _translateFrequency(product.purchaseFrequency),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.gryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(
      MostPurchasedProduct product, AnalyticsController controller) {
    return GestureDetector(
      onTap: () => _navigateToProductDeepDive(product, controller),
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: AppColors.wtColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildProductImage(product, size: 60),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.title,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_convertToArabicNumerals(product.priceRange.current.toStringAsFixed(2))} ر.س',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        size: 14,
                        color: AppColors.gryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_convertToArabicNumerals(product.purchaseCount.toString())} ${'times'.tr}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _translateFrequency(product.purchaseFrequency),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(MostPurchasedProduct product, {double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: product.image.isNotEmpty
            ? SmartImage(
                url: product.image,
                height: size,
                width: size,
                cacheWidth: 300,
                cacheHeight: 300,
                fit: BoxFit.cover,
                errorWidget: Icon(
                  Icons.image,
                  color: AppColors.gryColor.withValues(alpha: 0.5),
                  size: size * 0.5,
                ),
              )
            : Icon(
                Icons.image,
                color: AppColors.gryColor.withValues(alpha: 0.5),
                size: size * 0.5,
              ),
      ),
    );
  }

  void _navigateToProductDeepDive(
      MostPurchasedProduct product, AnalyticsController controller) {
    Get.to(
      () => SimpleProductDeepDiveScreen(
        product: product,
        controller: controller,
      ),
    );
  }

  String _translateFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'st_daily'.tr;
      case 'weekly':
        return 'st_weekly'.tr;
      case 'monthly':
        return 'st_monthly'.tr;
      case 'yearly':
        return 'st_yearly'.tr;
      default:
        return frequency;
    }
  }
}
