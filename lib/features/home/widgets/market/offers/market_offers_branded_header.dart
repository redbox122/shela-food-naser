import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// Branded header for the offers screen when it is opened from a store/section
/// "see more" or logo tap (as opposed to a category tile). Layout (matches the
/// design):
///  • Cover band — full width × 155, rounded top corners (8px). A real cover
///    image when available, otherwise a solid brand-accent band.
///  • Favourite / search icons (RTL left) + back (RTL right) over the band.
///  • A row below the band: the logo box on the RIGHT, and the store name +
///    slogan stacked on its LEFT (RTL).
/// There is NO categories top bar — only the sub-category strip below (rendered
/// by the screen).
class MarketOffersBrandedHeader extends StatelessWidget {
  /// Brand accent — fills the band when there is no cover image.
  final Color accent;
  final String? cover;
  final String? logo;
  final String? name;
  final String? slogan;
  final VoidCallback onBack;
  final VoidCallback onSearch;

  const MarketOffersBrandedHeader({
    super.key,
    required this.accent,
    required this.onBack,
    required this.onSearch,
    this.cover,
    this.logo,
    this.name,
    this.slogan,
  });

  bool get _hasCover => (cover ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover band: real cover image, or a solid brand-accent band.
        // Design: full width × 155, rounded top corners (8px).
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: _hasCover
                  ? CustomImage(
                      image: cover!,
                      width: double.infinity,
                      height: 155,
                      fit: BoxFit.cover,
                      placeholder: Images.placeholder,
                    )
                  : Container(height: 155, color: accent),
            ),
            // Top icon row: back (RTL right) + favourite & search (RTL left).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: Row(
                    children: [
                      _circleIcon(Images.arrow_back_ios_new, onBack),
                      const Spacer(),
                      _circleIcon(Images.heart_v2, () {}),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      _circleIcon(Images.search_v2, onSearch),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Row below the band: logo on the RIGHT, name + slogan on its LEFT (RTL).
        // The logo is translated up so it straddles the cover's bottom edge.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            0,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The logo straddles the cover's bottom edge, but we reserve only
              // the portion that sits *below* the band (≈45px) instead of its
              // full height — otherwise the unused part leaves a big empty gap
              // before the category chips. OverflowBox lets it draw full size
              // while overflowing upward into the cover.
              SizedBox(
                width: 71.43,
                height: 45,
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  maxHeight: 80.61,
                  child: Container(
                    width: 71.43,
                    height: 80.61,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomImage(
                      image: logo ?? '',
                      width: 71.43,
                      height: 80.61,
                      fit: BoxFit.cover,
                      placeholder: Images.placeholder,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.3,
                        color: Color(0xFF121C19),
                      ),
                    ),
                    if ((slogan ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      // Design: Tajawal 700 / 16px / 140% / --Text-Headline.
                      Text(
                        slogan!,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.4,
                          color: Color(0xFF121C19),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleIcon(String image, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            image,
            width: 18,
            height: 18,
            color: const Color(0xFF121C19),
          ),
        ),
      ),
    );
  }
}
