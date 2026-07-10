// ignore_for_file: unused_element_parameter, unused_element
part of 'market_store_screen.dart';

/// App bottom navigation bar shown on the store screen. Tapping a tab jumps to
/// the matching dashboard page (replacing the navigation stack).
class _StoreBottomNav extends StatelessWidget {
  const _StoreBottomNav();

  static const List<String> _pages = [
    'home',
    'cart',
    'discounts',
    'order',
    'profile'
  ];

  @override
  Widget build(BuildContext context) {
    final items = <HomeNavBarItem>[
      HomeNavBarItem(
          icon: Images.home_v2,
          activeIcon: Images.home_v2_active,
          label: 'nav_home'.tr),
      HomeNavBarItem(
          icon: Images.bag_v2,
          activeIcon: Images.bag_v2_active,
          label: 'nav_cart'.tr,
          isCart: true),
      HomeNavBarItem(
          icon: Images.discount_shape_v2,
          activeIcon: Images.discount_shape_v2_active,
          label: 'nav_discounts'.tr),
      HomeNavBarItem(
          icon: Images.receipt_ext_v2,
          activeIcon: Images.receipt_ext_v2_active,
          label: 'nav_orders'.tr),
      HomeNavBarItem(
          icon: Images.profile_v2,
          activeIcon: Images.profile_v2_active,
          label: 'nav_profile'.tr),
    ];
    return HomeBottomNavBar(
      items: items,
      currentIndex: 0,
      onTap: (i) => Get.offAllNamed(RouteHelper.getMainRoute(_pages[i])),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

/// Banner-style top header: back chevron (RTL right), centered store title, and
/// a search icon (RTL left) — replaces the cover/logo/rating header.
class _MarketTopHeader extends StatelessWidget {
  final String title;

  /// Store/module the search should be scoped to (search only this store).
  final int? storeId;
  final int? moduleId;
  const _MarketTopHeader({required this.title, this.storeId, this.moduleId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: Row(
          children: [
            _iconBtn(Images.arrow_back_ios_new, () => Get.back<void>(),
                boxed: false),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.2,
                  color: Color(0xFF121C19),
                ),
              ),
            ),
            _iconBtn(
                Images.search_v2,
                () => Get.to<void>(() =>
                    HomeSearchScreen(storeId: storeId, moduleId: moduleId))),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(String image, VoidCallback onTap, {bool boxed = true}) {
    final icon = Image.asset(image,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        color: const Color(0xFF121C19));
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: boxed
            ? Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: icon,
              )
            : SizedBox(
                width: 30,
                height: 30,
                child: Center(child: icon),
              ),
      ),
    );
  }
}

/// Cover-image header (logo + rating + delivery pills). Kept for later reuse;
/// the store screen now uses [_MarketTopHeader] + notice + banner instead.
class _StoreHeader extends StatelessWidget {
  final String? name;
  final String? logo;
  final String? cover;
  final String? description;
  final double rating;
  final bool freeDelivery;
  final String? deliveryTime;
  final double? distance;

  /// Store + module — so the header's search is scoped to THIS store's products.
  final int? storeId;
  final int? moduleId;

  const _StoreHeader({
    required this.name,
    required this.logo,
    required this.cover,
    required this.description,
    required this.rating,
    required this.freeDelivery,
    required this.deliveryTime,
    this.distance,
    this.storeId,
    this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CustomImage(
              image: cover ?? '',
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              placeholder: Images.placeholder,
            ),
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
                      _CircleIconButton(
                        image: Images.arrow_back_ios_new,
                        onTap: () => Get.back<void>(),
                      ),
                      const Spacer(),
                      _CircleIconButton(
                        image: Images.search_v2,
                        onTap: () => Get.to<void>(() => HomeSearchScreen(
                            storeId: storeId, moduleId: moduleId)),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      _CircleIconButton(
                        image: Images.heart_v2,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Delivery + time pills clustered toward the logo side (RTL right)
            // at the bottom of the cover — kept clear of the logo box.
            Positioned(
              left: 0,
              right: 0,
              bottom: Dimensions.paddingSizeSmall,
              child: Padding(
                // Right inset clears the protruding logo (72 wide + side gutter).
                padding: const EdgeInsets.only(
                  right: 100,
                  left: Dimensions.paddingSizeSmall,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Free-delivery stores show the free pill; the rest fall
                    // back to a "توصيل سريع" (fast delivery) pill.
                    _CoverPill(
                      image: Images.truck_delivery_v2,
                      label: freeDelivery
                          ? 'free_delivery'.tr
                          : 'fast_delivery'.tr,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    if (deliveryTime != null && deliveryTime!.isNotEmpty)
                      _CoverPill(
                        image: Images.time_v2,
                        label: deliveryTime!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              Transform.translate(
                offset: const Offset(0, -36),
                child: Container(
                  width: 72,
                  height: 81,
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
                    width: 72,
                    height: 81,
                    fit: BoxFit.cover,
                    placeholder: Images.placeholder,
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
                    if ((description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
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
              // Rating + distance badges stacked on the left (RTL).
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RatingBadge(rating: rating),
                  if (distance != null && distance! > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF31A342),
                        borderRadius:
                            BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            distance! < 1000
                                ? '${distance!.round()} م'
                                : '${(distance! / 1000).toStringAsFixed(1)} كم',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              height: 1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Cover panel (scrollable) ─────────────────────────────────────────────────

/// Scrollable portion of a cover-header store: cover image + store details row.
/// The nav bar (back button, store name, search) stays fixed in [_MarketTopHeader]
/// above — so those controls are NOT repeated here.
class _StoreCoverPanel extends StatelessWidget {
  final String? logo;
  final String? cover;
  final String? description;
  final double rating;
  final bool freeDelivery;
  final String? deliveryTime;
  final double? distance;

  const _StoreCoverPanel({
    this.logo,
    this.cover,
    this.description,
    this.rating = 0,
    this.freeDelivery = false,
    this.deliveryTime,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image — 180 px tall with delivery pills overlaid at bottom.
        Stack(
          clipBehavior: Clip.none,
          children: [
            CustomImage(
              image: cover ?? '',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: Images.placeholder,
            ),
            // Delivery + time pills at bottom-left of cover.
            Positioned(
              left: 0,
              right: 0,
              bottom: Dimensions.paddingSizeSmall,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 100,
                  left: Dimensions.paddingSizeSmall,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _CoverPill(
                      image: Images.truck_delivery_v2,
                      label: freeDelivery ? 'free_delivery'.tr : 'fast_delivery'.tr,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    if (deliveryTime != null && deliveryTime!.isNotEmpty)
                      _CoverPill(
                        image: Images.time_v2,
                        label: deliveryTime!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Store info row: logo + description + rating + distance.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store logo card floating up over the cover.
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  width: 64,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 3),
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
                    width: 64,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: Images.placeholder,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((description ?? '').isNotEmpty)
                      Text(
                        description!,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF717885),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RatingBadge(rating: rating),
                  if (distance != null && distance! > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF31A342),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 11, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            distance! < 1000
                                ? '${distance!.round()} م'
                                : '${(distance! / 1000).toStringAsFixed(1)} كم',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              height: 1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
