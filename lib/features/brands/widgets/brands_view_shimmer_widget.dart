import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';

class BrandViewShimmer extends StatelessWidget {
  const BrandViewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: TitleWidget(
          title: 'brands'.tr,
          onTap: () => null,
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
        itemCount: 8,
        itemBuilder: (BuildContext context, int index) {
          return Shimmer(
            duration: const Duration(seconds: 2),
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: ColoredBox(
                      color: Theme.of(context)
                          .disabledColor
                          .withValues(alpha: 0.08),
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
}