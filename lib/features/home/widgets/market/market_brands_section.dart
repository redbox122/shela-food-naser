import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/screens/market_store_screen.dart';
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

  /// Logo-only design: each brand is a circular logo chip in a single row.
  static const double _logoSize = 64;

  @override
  State<MarketBrandsSection> createState() => _MarketBrandsSectionState();
}

/// Lightweight model for a row of the `/brands` response. The response now
/// carries the store each brand resolves to (most map to هايبر شله, id 1).
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
      // Brands are scoped to the screen's module; only the market family has
      // brands, so non-market modules (restaurants/cafés/pharmacy) return an
      // empty list and the section hides itself.
      final int brandModuleId =
          widget.moduleId ?? MarketBrandsSection._marketModuleId;
      final response = await Get.find<ApiClient>().getData(
        '/api/v2/brands?module_id=$brandModuleId',
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
          // Single horizontal row of circular brand logos — all brands, scroll.
          // While loading, Skeletonizer bones dummy logo chips.
          Skeletonizer(
            enabled: _loading,
            child: SizedBox(
              height: MarketBrandsSection._logoSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: _loading
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault),
                itemCount: _loading ? 6 : _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: _rowGap),
                itemBuilder: (_, index) =>
                    _BrandLogo(brand: _loading ? _dummyBrand : _items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _rowGap = 12;

  /// Placeholder brand used to render skeleton logo chips.
  static final _Brand _dummyBrand = _Brand(id: 0, name: 'علامة', image: '');
}

/// Logo-only brand chip: a circular logo inside a bordered container. Tapping
/// opens the brand's store storefront (falling back to its items list).
class _BrandLogo extends StatelessWidget {
  final _Brand brand;

  const _BrandLogo({required this.brand});

  void _open() {
    final int? storeId = brand.storeId;
    if (storeId == null) {
      Get.toNamed(
        RouteHelper.getBrandsItemScreen(brand.id ?? 0, brand.name ?? ''),
      );
      return;
    }
    Get.to<void>(
      () => MarketStoreScreen(
        storeId: storeId,
        name: brand.storeName ?? brand.name,
        logo: brand.image,
        rating: brand.rating,
        freeDelivery: brand.freeDelivery,
        deliveryTime: brand.deliveryTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double size = MarketBrandsSection._logoSize;
    return InkWell(
      borderRadius: BorderRadius.circular(size / 2),
      onTap: _open,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE6E8EC)),
        ),
        child: ClipOval(
          child: CustomImage(
            image: brand.image ?? '',
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: Images.placeholder,
          ),
        ),
      ),
    );
  }
}
