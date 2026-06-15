import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class HomeBannerView extends StatefulWidget {
  const HomeBannerView({super.key});

  // Banner image ratio (width/height). Match the designed banner ratio so
  // `contain` fills the card with no gaps while showing the full image.
  static const double _aspectRatio = 613 / 289;

  @override
  State<HomeBannerView> createState() => _HomeBannerViewState();
}

class _HomeBannerViewState extends State<HomeBannerView> {
  // viewportFraction < 1 makes the next banner peek on the trailing edge.
  final PageController _controller = PageController(viewportFraction: 0.9);
  int _current = 0;
  // Once banners have shown, suppress the skeleton on later resets/reloads.
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    // Self-load: make sure banners are fetched for the active module even if
    // nothing else triggered the load (otherwise the rail can stay empty).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !Get.isRegistered<BannerController>()) return;
      final bannerController = Get.find<BannerController>();
      final list = bannerController.bannerImageList;
      if (list == null || list.isEmpty) {
        bannerController.getBannerList(true, dataSource: DataSourceEnum.client);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BannerController>()) {
      return const SizedBox.shrink();
    }

    return GetBuilder<BannerController>(
      builder: (bannerController) {
        final List<String?>? rawList = bannerController.bannerImageList;
        if (rawList == null) {
          // Show the skeleton only on the very first load. Later resets (module
          // preload / self-reload) shouldn't flash a second skeleton.
          return _hasLoadedOnce
              ? const SizedBox.shrink()
              : _buildSkeleton(context);
        }
        final images = rawList
            .where((e) => e != null && e.isNotEmpty)
            .cast<String>()
            .toList();
        if (images.isEmpty) {
          return const SizedBox.shrink();
        }
        _hasLoadedOnce = true;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeExtraSmall,
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: HomeBannerView._aspectRatio,
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.only(
                        right: Dimensions.paddingSizeSmall),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomImage(
                        image: images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: Images.placeholder,
                      ),
                    ),
                  ),
                ),
              ),
              if (images.length > 1) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final bool active = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: active ? 16 : 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Theme.of(context).primaryColor
                            : Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    // Mirror the real banner layout (90% main card + peek of the next + dots)
    // so the skeleton → banner transition is a single, jump-free phase.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Shimmer.fromColors(
        baseColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        highlightColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: HomeBannerView._aspectRatio,
              child: Row(
                children: [
                  // Main card (right in RTL) — matches viewportFraction 0.9.
                  Expanded(
                    flex: 9,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          right: Dimensions.paddingSizeSmall),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  // Peek of the next banner (left).
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            // Dots indicator skeleton.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: i == 0 ? 16 : 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
