import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: promotional banner under "العروض الحالية".
///
/// `explor_service.png` (design size 343×96, 16px radius) is the illustration
/// background; the title / subtitle / "زيارة الموقع" button are overlaid on the
/// trailing (RTL right) side. Tapping the banner or the button opens the Shella
/// website.
class HomeDiscoverBannerView extends StatelessWidget {
  const HomeDiscoverBannerView({super.key});

  // Design ratio (343 × 96) — width flexes, height follows.
  static const double _aspectRatio = 343 / 96;

  /// Website opened when the banner / button is tapped.
  static const String _websiteUrl = 'https://www.shellaksa.com';

  // Palette from the mockup.
  static const Color _titleColor = Color(0xFF1B2B27);
  static const Color _brandColor = Color(0xFF30913F);
  static const Color _subtitleColor = Color(0xFF000000);

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_websiteUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignore launch failures (no browser / invalid url).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openWebsite,
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              children: [
                // Illustration background.
                Positioned.fill(
                  child: Image.asset(
                    Images.exploreService,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFEDE7FB),
                    ),
                  ),
                ),
                // Text + button overlay on the trailing (RTL right) side.
                Positioned.fill(
                  child: Padding(
                    // Reserve the leading (RTL left) area for the illustration;
                    // text sits on the trailing (RTL right) side.
                    padding: const EdgeInsetsDirectional.only(
                      start: 14,
                      end: 130,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title — "...عبر موقع" with the brand word in green.
                        Text.rich(
                          TextSpan(
                            text: '${'discover_more_services'.tr} ',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.2,
                              color: _titleColor,
                            ),
                            children: [
                              TextSpan(
                                text: 'shella_brand'.tr,
                                style: const TextStyle(color: _brandColor),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'discover_more_services_subtitle'.tr,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w500,
                            fontSize: 8,
                            height: 1.2,
                            color: _subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _VisitButton(onTap: _openWebsite),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Green "زيارة الموقع" pill with a trailing chevron.
class _VisitButton extends StatelessWidget {
  final VoidCallback onTap;
  const _VisitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF30913F),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'visit_website'.tr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_forward_ios,
                size: 8,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
