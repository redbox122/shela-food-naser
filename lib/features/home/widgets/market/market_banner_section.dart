import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN (Market): promotional banner rail.
///
/// Wired to `GET /api/v1/offers/active`, scoped to the market (grocery) module
/// via the moduleId header. Shows the active offer banners as a paged rail.
class MarketBannerSection extends StatefulWidget {
  final int? moduleId;

  const MarketBannerSection({super.key, this.moduleId});

  /// The banner/offers feed is sourced from a fixed module (id 3), independent
  /// of the market's grocery module.
  static const int _bannerModuleId = 3;

  // Banner image ratio (width/height); matches the market design spec (322×125).
  static const double _aspectRatio = 322 / 125;

  @override
  State<MarketBannerSection> createState() => _MarketBannerSectionState();
}

class _MarketBannerSectionState extends State<MarketBannerSection> {
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
      // Banners (with images) live in /api/v1/banners — /offers/active returns
      // offers without a banner image. Scope to module 3 via the moduleId
      // header; zoneId/auth come from the client defaults.
      final response = await Get.find<ApiClient>().getData(
        '${AppConstants.bannerUri}?featured=1',
        headers: {
          AppConstants.localizationKey: 'ar',
          AppConstants.moduleId:
              MarketBannerSection._bannerModuleId.toString(),
        },
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      // Merge featured banners + campaigns; tolerate a bare list too.
      final List raw = body is List
          ? body
          : (body is Map)
              ? [
                  ...(body['banners'] is List ? body['banners'] as List : const []),
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
            aspectRatio: MarketBannerSection._aspectRatio,
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Skeletonizer(
        child: Padding(
          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
          child: AspectRatio(
            aspectRatio: MarketBannerSection._aspectRatio,
            // A plain decorated Container is treated by Skeletonizer as a
            // "container" and painted with its real color (no shimmer), so it
            // would be invisible on a white background. `Bone` always paints
            // the shimmer shader, so the banner placeholder is actually visible.
            child: Bone(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
