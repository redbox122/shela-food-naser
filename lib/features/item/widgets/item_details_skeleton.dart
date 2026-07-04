import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Shimmer placeholder shown while the item details are loading.
class ItemDetailsSkeleton extends StatelessWidget {
  const ItemDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: Shimmer(
            duration: const Duration(seconds: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(height: 220),
                const SizedBox(height: 16),
                _skeletonBox(height: 20, width: 220),
                const SizedBox(height: 8),
                _skeletonBox(height: 16, width: 140),
                const SizedBox(height: 16),
                _skeletonBox(height: 60),
                const SizedBox(height: 16),
                _skeletonBox(height: 16, width: 180),
                const SizedBox(height: 8),
                _skeletonBox(height: 16, width: 200),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _skeletonBox(height: 44)),
                    const SizedBox(width: 12),
                    Expanded(child: _skeletonBox(height: 44)),
                  ],
                ),
                const SizedBox(height: 16),
                _skeletonBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
    );
  }
}
