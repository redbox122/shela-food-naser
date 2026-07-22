import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// Home promotional banner rail.
///
/// Self-fetches the *global* featured banners (GET /api/v1/banners?featured=1)
/// using a fixed module (id 3), independent of the currently-selected module —
/// so the rail shows the same promo banners on every module's home, even ones
/// that have no banners configured of their own (e.g. pharmacy).
class HomeBannerView extends StatefulWidget {
  const HomeBannerView({super.key});

  /// Banners live under module 3; the feed is global across modules.
  static const int _bannerModuleId = 3;

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
  List<String> _images = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      // Scope to module 3 via the moduleId header; zoneId/auth come from the
      // client defaults.
      final response = await Get.find<ApiClient>().getData(
        '${AppConstants.bannerUri}?featured=1',
        headers: {
          AppConstants.localizationKey: AppConstants.currentLanguageCode,
          AppConstants.moduleId: HomeBannerView._bannerModuleId.toString(),
        },
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      // Merge banners + campaigns; tolerate a bare list too.
      final List raw = body is List
          ? body
          : (body is Map)
              ? [
                  ...(body['banners'] is List
                      ? body['banners'] as List
                      : const []),
                  ...(body['campaigns'] is List
                      ? body['campaigns'] as List
                      : const []),
                ]
              : const [];
      final images = raw
          .whereType<Map>()
          .map((e) => (e['image_full_url'] ?? e['image'])?.toString())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();
      setState(() {
        _images = images;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton(context);
    if (_images.isEmpty) return const SizedBox.shrink();

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
              itemCount: _images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, index) => Padding(
                padding:
                    const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomImage(
                    image: _images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: Images.placeholder,
                  ),
                ),
              ),
            ),
          ),
          if (_images.length > 1) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_images.length, (i) {
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
