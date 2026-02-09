import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/brands/widgets/brands_view_shimmer_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class BrandsViewWidget extends StatelessWidget {
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
              mainAxisExtent: 104,
            ),
            itemCount: visibleBrands.length,
            itemBuilder: (context, index) {
              final brand = visibleBrands[index];
              return Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusLarge),
                  border: Border.all(
                    color: Theme.of(context)
                        .disabledColor
                        .withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => Get.toNamed<void>(
                      RouteHelper.getBrandsItemScreen(
                          brand.id!,
                          brand.name!)),
                  child: Center(
                    child: SizedBox(
                      height: 80,
                      width: 80,
                      child: ClipOval(
                        child: CustomImage(
                          image: brand.imageFullUrl ?? '',
                          fit: BoxFit.contain,
                        ),
                      ),
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
