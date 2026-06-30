import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/card_design/store_list_card.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
import 'package:sixam_mart/features/home/widgets/market/market_store_filters.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';

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
    // Unified store card — one design shared across the whole app.
    return StoreListCard(
      name: store.name,
      logo: store.logo,
      rating: store.rating,
      distanceMetres: store.distance,
      deliveryTime: store.deliveryTime,
      freeDelivery: store.freeDelivery,
      qidha: store.qidha,
      hasOffer: store.hasOffer,
      discountValue: store.discountValue,
      discountType: store.discountType,
      minPurchase: store.minPurchase,
      onTap: () => Get.to<void>(
        () => MarketStoreScreen(
          storeId: store.id,
          name: store.name,
          logo: store.logo,
          cover: store.cover,
          rating: store.rating,
          freeDelivery: store.freeDelivery,
          deliveryTime: store.deliveryTime,
          distance: store.distance,
          useCoverHeader: coverHeader,
        ),
      ),
    );
  }
}
