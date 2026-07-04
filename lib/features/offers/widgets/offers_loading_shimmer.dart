import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Skeleton loader that mirrors the real product layout (grid vs list), so the
/// placeholder matches whichever view mode the user is in.
class OffersLoadingShimmer extends StatelessWidget {
  final bool isListView;

  const OffersLoadingShimmer({super.key, required this.isListView});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: isListView
            ? ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                itemBuilder: (context, index) => const _ListSkeletonCard(),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 167 / 195,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const _GridSkeletonCard(),
              ),
      ),
    );
  }
}

Widget _skeletonBox(double width, double height, {double radius = 4}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

Widget _skeletonCircle(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.grey,
      shape: BoxShape.circle,
    ),
  );
}

/// Mirrors [GroceryProductGrid] grid card: image area (flex 3) + text/price
/// area (flex 4).
class _GridSkeletonCard extends StatelessWidget {
  const _GridSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _skeletonBox(double.infinity, double.infinity, radius: 8),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _skeletonBox(double.infinity, 14),
                  const SizedBox(height: 6),
                  _skeletonBox(70, 12),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _skeletonBox(60, 16)),
                      _skeletonCircle(35),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors [GroceryProductGrid] list card: image (right) + text/price (middle)
/// + fav/add column (left).
class _ListSkeletonCard extends StatelessWidget {
  const _ListSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _skeletonBox(84, 84, radius: 8),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _skeletonBox(double.infinity, 14),
                const SizedBox(height: 6),
                _skeletonBox(60, 11),
                const SizedBox(height: 10),
                _skeletonBox(80, 16),
              ],
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            height: 108,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _skeletonCircle(35),
                _skeletonCircle(35),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
