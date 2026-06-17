import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN (Market): "أشهر العلامات التجارية" — popular brands rail.
///
/// Wired to `GET /api/v2/brands`, scoped to the market (grocery) module via the
/// moduleId header. Each card shows the brand logo and name.
class MarketBrandsSection extends StatefulWidget {
  final int? moduleId;

  const MarketBrandsSection({super.key, this.moduleId});

  /// Brands feed is sourced from module 3 (the grocery module returns none).
  static const int _marketModuleId = 3;

  /// Card design size (209×76) — taller now that it shows store delivery info.
  static const double _cardWidth = 209;
  static const double _cardHeight = 76;

  @override
  State<MarketBrandsSection> createState() => _MarketBrandsSectionState();
}

/// Lightweight model for a row of the `/brands` response. The response now
/// carries the store each brand resolves to (most map to هايبر شلة, id 1).
class _Brand {
  final int? id;
  final String? name;
  final String? image;
  final int? storeId;
  final String? storeName;
  final String? deliveryTime;
  final bool freeDelivery;
  final double deliveryFee;
  final double rating;
  final int ratingCount;

  _Brand({
    this.id,
    this.name,
    this.image,
    this.storeId,
    this.storeName,
    this.deliveryTime,
    this.freeDelivery = false,
    this.deliveryFee = 0,
    this.rating = 0,
    this.ratingCount = 0,
  });

  static double _toDouble(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  factory _Brand.fromJson(Map<String, dynamic> j) => _Brand(
        id: int.tryParse('${j['id']}'),
        name: j['name']?.toString(),
        image: (j['image_full_url'] ?? j['image'])?.toString(),
        storeId: int.tryParse('${j['store_id']}'),
        storeName: j['store_name']?.toString(),
        deliveryTime: j['delivery_time']?.toString(),
        freeDelivery: j['free_delivery'] == true || j['free_delivery'] == 1,
        deliveryFee: _toDouble(j['first_km_fee']),
        rating: _toDouble(j['avg_rating']),
        ratingCount: int.tryParse('${j['rating_count']}') ?? 0,
      );
}

class _MarketBrandsSectionState extends State<MarketBrandsSection> {
  List<_Brand> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      // Market brands are sourced from module 3 (passing the grocery module
      // returns an empty list).
      final response = await Get.find<ApiClient>().getData(
        '/api/v2/brands?module_id=${MarketBrandsSection._marketModuleId}',
        headers: const {
          AppConstants.localizationKey: 'ar',
        },
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['brands'] is List)
              ? body['brands'] as List
              : (body is Map && body['data'] is List)
                  ? body['data'] as List
                  : const [];
      setState(() {
        _items = raw
            .whereType<Map>()
            .map((e) => _Brand.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Text(
              'popular_brands'.tr,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.4,
                color: Color(0xFF121C19),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          // Horizontal scroll with two rows (2 cards stacked per column).
          SizedBox(
            height: MarketBrandsSection._cardHeight * 2 + _rowGap,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              itemCount: _loading ? 3 : (_items.length / 2).ceil(),
              separatorBuilder: (_, __) => const SizedBox(width: _rowGap),
              itemBuilder: (_, col) {
                final int first = col * 2;
                final int second = first + 1;
                return SizedBox(
                  width: MarketBrandsSection._cardWidth,
                  child: Column(
                    children: [
                      _cell(context, first),
                      const SizedBox(height: _rowGap),
                      _cell(context, second),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const double _rowGap = 8;

  Widget _cell(BuildContext context, int index) {
    if (_loading) return _buildSkeletonCard(context);
    if (index >= _items.length) {
      // Keep the column balanced when the last one has a single brand.
      return const SizedBox(height: MarketBrandsSection._cardHeight);
    }
    return SizedBox(
      height: MarketBrandsSection._cardHeight,
      child: _BrandCard(brand: _items[index]),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
      child: Container(
        height: MarketBrandsSection._cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final _Brand brand;

  const _BrandCard({required this.brand});

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    final bool hasStoreInfo = (brand.deliveryTime?.isNotEmpty ?? false) ||
        brand.freeDelivery ||
        brand.deliveryFee > 0;
    return InkWell(
      borderRadius: radius,
      onTap: () => Get.toNamed(
        RouteHelper.getBrandsItemScreen(brand.id ?? 0, brand.name ?? ''),
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: radius,
          border: Border.all(color: const Color(0xFFE6E8EC)),
        ),
        // RTL row: logo square leads on the right, info on the left.
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomImage(
                image: brand.image ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: Images.placeholder,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand name.
                  Text(
                    brand.name ?? '',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.2,
                      color: Color(0xFF121C19),
                    ),
                  ),
                  if (hasStoreInfo) ...[
                    const SizedBox(height: 5),
                    _storeInfoRow(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Delivery fee (or free-delivery) + delivery time, with leading icons.
  Widget _storeInfoRow(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          Images.truck_delivery_v2,
          width: 13,
          height: 13,
          errorBuilder: (_, __, ___) => Icon(
            Icons.delivery_dining,
            size: 13,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          brand.freeDelivery ? 'free_delivery'.tr : _fmt(brand.deliveryFee),
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 27 / 12,
            color: Color(0xFF121C19),
          ),
        ),
        if (brand.deliveryTime?.isNotEmpty ?? false) ...[
          const SizedBox(width: 8),
          Image.asset(
            Images.time_v2,
            width: 13,
            height: 13,
            errorBuilder: (_, __, ___) => Icon(
              Icons.access_time,
              size: 13,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              brand.deliveryTime!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 27 / 12,
                color: Color(0xFF121C19),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
