import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/circular_ring_avatar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/brands/widgets/brands_view_shimmer_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class BrandsViewWidget extends StatelessWidget {
  /// Matches category ring size feel on home (inner logo area).
  static const double _brandLogoDiameter = 78;

  const BrandsViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BrandsController>(builder: (brandsController) {
      // ⚡ FIX: Only show shimmer when loading, not when disabled or empty
      // If brandList is null and loading, show shimmer
      // If brandList is null and not loading, show nothing (section might be disabled or no data yet)
      // If brandList is empty, show nothing
      if (brandsController.brandList == null) {
        // Only show shimmer if actively loading
        return brandsController.isLoading 
            ? const BrandViewShimmer()
            : const SizedBox.shrink();
      }
      
      // If we have data, show brands
      if (brandsController.brandList!.isNotEmpty) {
        // ✅ عرض 4 علامات فقط في الصفحة الرئيسية (شبكة 2x2)
        final brands = brandsController.brandList!;
        final visibleBrands = brands.take(8).toList();
        
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(
              title: 'brands'.tr,
              // ✅ زر "رؤية الكل" الوحيد - يفتح صفحة مستقلة
              onTap: () => Get.toNamed<void>(RouteHelper.getBrandsScreen()),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 112,
            ),
            itemCount: visibleBrands.length,
            itemBuilder: (BuildContext context, int index) {
              final brand = visibleBrands[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.toNamed<void>(
                    RouteHelper.getBrandsItemScreen(
                      brand.id!,
                      brand.name!,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: Center(
                    child: CircularRingAvatar(
                      imageUrl: brand.imageFullUrl ?? '',
                      diameter: BrandsViewWidget._brandLogoDiameter,
                      fit: BoxFit.contain,
                      imageBackgroundColor:
                          Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              );
            },
          ),
        ]);
      }
      
      // Empty list - show nothing
      return const SizedBox.shrink();
    });
  }
}
