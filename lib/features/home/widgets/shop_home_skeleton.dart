import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

class ShopHomeSkeleton extends StatelessWidget {
  const ShopHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      children: const [
        _ShimmerBlock(height: 160),
        SizedBox(height: Dimensions.paddingSizeDefault),
        _ShimmerRow(count: 4, height: 64),
        SizedBox(height: Dimensions.paddingSizeDefault),
        _ShimmerRow(count: 2, height: 80),
        SizedBox(height: Dimensions.paddingSizeDefault),
        _ShimmerGrid(count: 6, itemHeight: 120),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double height;
  const _ShimmerBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).shadowColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final int count;
  final double height;
  const _ShimmerRow({required this.count, required this.height});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count * 2 - 1, (index) {
        if (index.isOdd) {
          return const SizedBox(width: Dimensions.paddingSizeSmall);
        }
        return Expanded(
          child: _ShimmerBlock(height: height),
        );
      }),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  final int count;
  final double itemHeight;
  const _ShimmerGrid({required this.count, required this.itemHeight});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Dimensions.paddingSizeSmall,
        crossAxisSpacing: Dimensions.paddingSizeSmall,
        mainAxisExtent: 120,
      ),
      itemBuilder: (context, index) {
        return _ShimmerBlock(height: itemHeight);
      },
    );
  }
}
