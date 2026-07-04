import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import '../../../util/app_colors.dart';
import '../../../util/images.dart';
import '../controllers/analytics_controller.dart';
import '../domain/models/most_purchased_product.dart';
import '../screens/simple_product_deep_dive_screen.dart';

/// "المنتجات الأكثر شراء" — the user's most-purchased products, shown as either
/// a 2-column grid or a full-width list (toggled from the header), matching the
/// redesigned statistics ("عام") tab.
class EnhancedMostPurchasedProducts extends StatefulWidget {
  const EnhancedMostPurchasedProducts({super.key});

  @override
  State<EnhancedMostPurchasedProducts> createState() =>
      _EnhancedMostPurchasedProductsState();
}

class _EnhancedMostPurchasedProductsState
    extends State<EnhancedMostPurchasedProducts> {
  static const Color _titleColor = Color(0xFF2D3633);
  static const Color _subtitleColor = Color(0xFF8A9199);

  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return GetX<AnalyticsController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(controller),
            const SizedBox(height: 12),
            if (controller.isLoadingProducts)
              const SizedBox(
                height: 160,
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryColor)),
              )
            else if (controller.productsError.isNotEmpty)
              _stateBox(
                icon: Icons.error_outline,
                text: 'failed_to_load_products'.tr,
                onRetry: () => controller.loadMostPurchasedProducts(),
              )
            else if (controller.mostPurchasedProducts.isEmpty)
              _emptyState()
            else if (_isGridView)
              _grid(controller)
            else
              _list(controller),
          ],
        );
      },
    );
  }

  Widget _header(AnalyticsController controller) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'st_most_purchased'.tr,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
        ),
        // Grid / list view toggle.
        InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => setState(() => _isGridView = !_isGridView),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              size: 18,
              color: _titleColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: controller.sortMostPurchasedProducts,
          itemBuilder: (BuildContext context) => controller
              .availableSortOptions
              .map((Map<String, String> option) => PopupMenuItem<String>(
                    value: option['key'],
                    child: Text(option['label'] ?? '',
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  ))
              .toList(),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _currentSortLabel(controller),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: _titleColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Label of the currently-selected sort option (e.g. "التكرار").
  String _currentSortLabel(AnalyticsController controller) {
    final Map<String, String> option = controller.availableSortOptions
        .firstWhere((Map<String, String> o) => o['key'] == controller.currentSortBy,
            orElse: () => const <String, String>{'label': ''});
    return option['label'] ?? '';
  }

  Widget _grid(AnalyticsController controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: controller.mostPurchasedProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (BuildContext context, int index) {
        return _productCard(controller.mostPurchasedProducts[index], controller);
      },
    );
  }

  Widget _list(AnalyticsController controller) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: controller.mostPurchasedProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        return _listCard(controller.mostPurchasedProducts[index], controller);
      },
    );
  }

  Widget _listCard(
      MostPurchasedProduct product, AnalyticsController controller) {
    final double current = product.priceRange.current;
    final double max = product.priceRange.max;
    final bool hasDiscount = max > current && current > 0;
    final int discount =
        hasDiscount ? (((max - current) / max) * 100).round() : 0;

    return GestureDetector(
      onTap: () => Get.to(() => SimpleProductDeepDiveScreen(
            product: product,
            controller: controller,
          )),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.wtColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Image + discount badge (RTL start / right side).
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: product.image.isNotEmpty
                        ? SmartImage(
                            url: product.image,
                            fit: BoxFit.cover,
                            cacheWidth: 240,
                            cacheHeight: 240,
                            errorWidget: _imgPlaceholder(),
                          )
                        : _imgPlaceholder(),
                  ),
                ),
                if (discount > 0)
                  PositionedDirectional(
                    top: 4,
                    start: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.redColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$discount%',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.wtColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name + price.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '﷼ ${current.toStringAsFixed(0)}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                      if (hasDiscount) ...<Widget>[
                        const SizedBox(width: 6),
                        Text(
                          '﷼ ${max.toStringAsFixed(2)}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            color: _subtitleColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions (favourite + add) on the trailing / left side.
            Column(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border,
                      size: 16, color: AppColors.primaryColor),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: AppColors.wtColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(
      MostPurchasedProduct product, AnalyticsController controller) {
    final double current = product.priceRange.current;
    final double max = product.priceRange.max;
    final bool hasDiscount = max > current && current > 0;
    final int discount =
        hasDiscount ? (((max - current) / max) * 100).round() : 0;

    return GestureDetector(
      onTap: () => Get.to(() => SimpleProductDeepDiveScreen(
            product: product,
            controller: controller,
          )),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.wtColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Image + badges.
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.35,
                    child: product.image.isNotEmpty
                        ? SmartImage(
                            url: product.image,
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                            cacheHeight: 300,
                            errorWidget: _imgPlaceholder(),
                          )
                        : _imgPlaceholder(),
                  ),
                ),
                if (discount > 0)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.redColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$discount%',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.wtColor,
                        ),
                      ),
                    ),
                  ),
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.wtColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        size: 15, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
            // Details.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (hasDiscount)
                                Text(
                                  '﷼ ${max.toStringAsFixed(2)}',
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 10,
                                    color: _subtitleColor,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '﷼ ${current.toStringAsFixed(2)}',
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              size: 18, color: AppColors.wtColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(Icons.image, color: _subtitleColor, size: 30),
    );
  }

  Widget _stateBox({
    required IconData icon,
    required String text,
    VoidCallback? onRetry,
  }) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 34, color: _subtitleColor),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: _subtitleColor,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onRetry,
              child: Text('retry'.tr,
                  style: const TextStyle(
                      fontFamily: 'Tajawal', color: AppColors.primaryColor)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              Images.empty_cart_v1,
              width: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد منتجات للعرض',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
