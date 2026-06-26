import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/home/widgets/market/market_store_filters.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN (Market): "المتاجر" — store cards list.
///
/// Wired to `GET /api/v2/stores?module_id=&limit=&offset=`. Each card shows the
/// cover photo, logo, name, rating and delivery badges.
class MarketStoresSection extends StatefulWidget {
  final int? moduleId;

  /// Category selected from the top rail / filter chip (null = all).
  final int? categoryId;

  /// Reports a category chosen from the in-section "فئة المتاجر" dropdown.
  final ValueChanged<int?>? onCategoryChanged;

  /// Opens tapped stores with the cover-image header (used by أسواق الحي only).
  final bool storeCoverHeader;

  const MarketStoresSection({
    super.key,
    this.moduleId,
    this.categoryId,
    this.onCategoryChanged,
    this.storeCoverHeader = false,
  });

  static const int _limit = 20;

  @override
  State<MarketStoresSection> createState() => _MarketStoresSectionState();
}

/// Lightweight model for a row of the `/stores` response.
class _Store {
  final int? id;
  final String? name;
  final String? logo;
  final String? cover;
  final double rating;
  final bool freeDelivery;
  final String? deliveryTime;
  final double deliveryFee;
  final bool hasOffer;

  /// Distance from the user (METRES, server-computed). 0/absent → unknown, not
  /// shown. The list is already nearest-first (backend orders by distance).
  final double distance;

  /// Discount details (from the `discount` object), used for the
  /// "خصم 45% على 250" badge. discountValue is the amount/percent, minPurchase
  /// the threshold, discountType either 'percent' or 'amount'.
  final double discountValue;
  final double minPurchase;
  final String discountType;

  /// Whether the store supports the Qidha installment system ("نظام قيدها").
  final bool qidha;

  _Store({
    this.id,
    this.name,
    this.logo,
    this.cover,
    this.rating = 0,
    this.freeDelivery = false,
    this.deliveryTime,
    this.deliveryFee = 0,
    this.hasOffer = false,
    this.distance = 0,
    this.discountValue = 0,
    this.minPurchase = 0,
    this.discountType = '',
    this.qidha = false,
  });

  static double _toDouble(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  static bool _toBool(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';

  factory _Store.fromJson(Map<String, dynamic> j) {
    final discount = j['discount'] is Map
        ? Map<String, dynamic>.from(j['discount'] as Map)
        : const <String, dynamic>{};
    return _Store(
      id: int.tryParse('${j['id']}'),
      name: j['name']?.toString(),
      logo: (j['logo_full_url'] ?? j['logo'])?.toString(),
      cover: (j['cover_photo_full_url'] ?? j['cover_photo'])?.toString(),
      rating: _toDouble(j['avg_rating']),
      freeDelivery: j['free_delivery'] == true || j['free_delivery'] == 1,
      deliveryTime: j['delivery_time']?.toString(),
      deliveryFee: _toDouble(j['first_km_fee']),
      hasOffer: j['has_offer'] == true || j['has_offer'] == 1,
      distance: _toDouble(j['distance']), // metres from the server

      discountValue: _toDouble(discount['discount']),
      minPurchase: _toDouble(discount['min_purchase']),
      discountType: (discount['discount_type'] ?? '').toString(),
      // ⚠️ Best-guess field — confirm the real key from the /stores JSON.
      qidha: _toBool(j['qidha'] ?? j['is_qidha'] ?? j['qidha_status']),
    );
  }
}

class _MarketStoresSectionState extends State<MarketStoresSection> {
  List<_Store> _items = const [];
  bool _loading = true;

  // Active toggle filters driving the query (category comes from widget).
  Set<String> _filters = const {};

  // ── Pagination (load farther stores as the user scrolls) ──────────────────
  int _page = 1; // v2 `offset` = 1-based page number
  int _totalSize = 0; // total stores available for the current query
  bool _loadingMore = false;
  bool get _hasMore => _items.length < _totalSize;

  // The enclosing (home) scroll position — we load the next page near its end.
  ScrollPosition? _parentScroll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to the home's scroll so we can auto-load more near the bottom.
    final ScrollPosition? pos = Scrollable.maybeOf(context)?.position;
    if (pos != _parentScroll) {
      _parentScroll?.removeListener(_onParentScroll);
      _parentScroll = pos;
      _parentScroll?.addListener(_onParentScroll);
    }
  }

  @override
  void dispose() {
    _parentScroll?.removeListener(_onParentScroll);
    super.dispose();
  }

  void _onParentScroll() {
    final pos = _parentScroll;
    if (pos == null || _loading || _loadingMore || !_hasMore) return;
    if (pos.pixels >= pos.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  @override
  void didUpdateWidget(covariant MarketStoresSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch when the externally-selected category changes.
    if (oldWidget.categoryId != widget.categoryId) {
      setState(() => _loading = true);
      _fetch();
    }
  }

  // Forwards a dropdown choice to the parent (single source of truth); the
  // re-fetch happens via didUpdateWidget once widget.categoryId updates.
  void _onCategoryChanged(int? id) => widget.onCategoryChanged?.call(id);

  void _onFiltersChanged(Set<String> filters) {
    setState(() {
      _filters = filters;
      _loading = true;
    });
    _fetch();
  }

  /// Builds the stores query with the active category + toggle filters.
  /// NOTE: filter param names are best-guess pending backend confirmation.
  String _buildUrl() {
    final params = <String>[
      'module_id=${widget.moduleId ?? ''}',
      'limit=${MarketStoresSection._limit}',
      'offset=$_page', // v2 paginates by 1-based page number
    ];
    if (widget.categoryId != null) {
      params.add('category_id=${widget.categoryId}');
    }
    if (_filters.contains('offers')) params.add('offers=1');
    if (_filters.contains('top_rated')) params.add('top_rated=1');
    if (_filters.contains('free_delivery')) params.add('free_delivery=1');
    if (_filters.contains('within_30_minutes')) params.add('delivery_time=30');
    if (_filters.contains('open_now')) params.add('open_now=1');
    return '/api/v2/stores?${params.join('&')}';
  }

  /// The current address's lat/lng as request headers (the V2 stores endpoint
  /// reads `latitude`/`longitude` to compute distance). Empty when no location.
  Map<String, String> _locationHeaders() {
    final addr = AddressHelper.getUserAddressFromSharedPref();
    final String? lat = addr?.latitude;
    final String? lng = addr?.longitude;
    if (lat != null && lat.isNotEmpty && lng != null && lng.isNotEmpty) {
      return {'latitude': lat, 'longitude': lng};
    }
    return const {};
  }

  /// First page (resets pagination). Called on init + category/filter change.
  Future<void> _fetch() async {
    _page = 1;
    await _request(append: false);
  }

  /// Loads the next page and APPENDS farther stores (triggered near scroll end).
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _page += 1;
    await _request(append: true);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _request({required bool append}) async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await Get.find<ApiClient>().getData(
        _buildUrl(),
        headers: {
          AppConstants.localizationKey: 'ar',
          if (widget.moduleId != null)
            AppConstants.moduleId: widget.moduleId.toString(),
          // Send the user's location so the server computes distance + orders
          // nearest-first. Without it the API returns distance = 0 (hidden).
          ..._locationHeaders(),
        },
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['stores'] is List)
              ? body['stores'] as List
              : (body is Map && body['data'] is List)
                  ? body['data'] as List
                  : const [];
      final int total = (body is Map)
          ? (int.tryParse('${body['total_size'] ?? ''}') ?? 0)
          : 0;
      final page = raw
          .whereType<Map>()
          .map((e) => _Store.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _items = append ? [..._items, ...page] : page;
        if (total > 0) _totalSize = total;
        // Fallback when the API omits total_size: a short page = the last one.
        if (total == 0 && page.length < MarketStoresSection._limit) {
          _totalSize = _items.length;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      if (append) _page -= 1; // allow retry of the failed page
    }
  }

  bool get _hasActiveFilter => widget.categoryId != null || _filters.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Hide the whole section only when there is genuinely nothing to show and
    // no filter is applied (a filtered-empty result keeps the chips visible).
    if (!_loading && _items.isEmpty && !_hasActiveFilter) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips lead the stores section (matches the design — no
          // plain "المتاجر" header above them).
          MarketStoreFilters(
            moduleId: widget.moduleId,
            selectedCategoryId: widget.categoryId,
            onCategoryChanged: _onCategoryChanged,
            onChanged: _onFiltersChanged,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (_loading)
            _buildSkeleton(context)
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'no_store_available'.tr,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF717885),
                  ),
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: Dimensions.paddingSizeSmall),
              itemBuilder: (_, i) => _StoreCard(
                store: _items[i],
                coverHeader: widget.storeCoverHeader,
              ),
            ),
            // Spinner while the next (farther) page loads.
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF30913F)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Skeleton bones rendered from the real [_StoreCard] layout with dummy data,
  /// so the loading state matches the live store cards exactly.
  Widget _buildSkeleton(BuildContext context) {
    final _Store dummy = _Store(
      id: 0,
      name: 'اسم المتجر',
      logo: '',
      rating: 4.5,
      freeDelivery: true,
      deliveryTime: '30-40 min',
      deliveryFee: 10,
    );
    return Skeletonizer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: 3,
        separatorBuilder: (_, __) =>
            const SizedBox(height: Dimensions.paddingSizeSmall),
        itemBuilder: (_, __) => _StoreCard(store: dummy),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final _Store store;
  final bool coverHeader;

  const _StoreCard({required this.store, this.coverHeader = false});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusLarge);
    return InkWell(
      borderRadius: radius,
      onTap: () => Get.to<void>(
        () => MarketStoreScreen(
          storeId: store.id,
          name: store.name,
          logo: store.logo,
          cover: store.cover,
          rating: store.rating,
          freeDelivery: store.freeDelivery,
          deliveryTime: store.deliveryTime,
          useCoverHeader: coverHeader,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // RTL row: logo square leads on the right, info on the left.
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImage(
                image: store.logo ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name (own line, right-aligned).
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      store.name ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating + distance badges side by side (distance is shown
                  // as a prominent green pill so it reads clearly).
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rating badge.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE7F7EA),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            textDirection: TextDirection.ltr,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Image.asset(
                                Images.star_v2,
                                width: 12,
                                height: 12,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.star, size: 12),
                              ),
                            ],
                          ),
                        ),
                        // Distance badge — filled Shella-green pill, clearly
                        // visible (e.g. "3.5 كم").
                        if (_distanceText(store.distance) != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF30913F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  _distanceText(store.distance)!,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Delivery time only (no delivery-fee/truck icon) — clean,
                  // clear: ⏱ "20 - 40 دقيقة".
                  if (store.deliveryTime != null &&
                      store.deliveryTime!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Image.asset(
                          Images.time_v2,
                          width: 15,
                          height: 15,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.access_time,
                            size: 15,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${store.deliveryTime!} دقيقة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF717885),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Badges.
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (store.qidha)
                        _Badge(
                          label: 'qidha_system'.tr,
                          bg: const Color(0xFFE7F7EA),
                          fg: const Color(0xFF1F7A35),
                          icon: Icons.verified_user_outlined,
                        ),
                      if (store.freeDelivery)
                        _Badge(
                          label: 'free_delivery'.tr,
                          bg: const Color(0xFFE7F7EA),
                          fg: const Color(0xFF1F7A35),
                        ),
                      if (store.discountValue > 0)
                        _Badge(
                          label: _discountLabel(store),
                          bg: const Color(0xFFF1ECFF),
                          fg: const Color(0xFF6B4FBB),
                        )
                      else if (store.hasOffer)
                        _Badge(
                          label: 'offers'.tr,
                          bg: const Color(0xFFF1ECFF),
                          fg: const Color(0xFF6B4FBB),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Distance label from metres: under 1 km → "800 م", otherwise "1.2 كم".
  /// Returns null when unknown (0 / no coordinates) so nothing is shown.
  String? _distanceText(double metres) {
    if (metres <= 0) return null;
    if (metres < 1000) return '${metres.round()} م';
    return '${(metres / 1000).toStringAsFixed(1)} كم';
  }

  /// "خصم 45% على 250" (percent) or "خصم 45 على 250" (amount). The "على {min}"
  /// part is dropped when there is no minimum purchase.
  String _discountLabel(_Store store) {
    final value = _fmt(store.discountValue);
    final suffix = store.discountType == 'percent' ? '%' : '';
    final base = '${'discount_label'.tr} $value$suffix';
    if (store.minPurchase > 0) {
      return '$base ${'on'.tr} ${_fmt(store.minPurchase)}';
    }
    return base;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
