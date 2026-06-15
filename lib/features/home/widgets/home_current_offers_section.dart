import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 REDESIGN: "العروض الحالية" — horizontal rail of current offers.
///
/// Wired to `GET /api/v2/stores/offers` (cross-module). Each card shows the
/// offer image, store logo, store name, offer description, and the original
/// (struck) + discounted price.
class HomeCurrentOffersSection extends StatefulWidget {
  const HomeCurrentOffersSection({super.key});

  static const double _railHeight = 178;
  static const double _cardWidth = 151;

  @override
  State<HomeCurrentOffersSection> createState() =>
      _HomeCurrentOffersSectionState();
}

/// Lightweight model for a row of the `/stores/offers` response.
class _Offer {
  final int? storeId;
  final String? storeName;
  final String? storeLogo;
  final String? offerTitle;
  final String? description;
  final double originalPrice;
  final double discountedPrice;
  final int? moduleId;
  final String? imageUrl;

  _Offer({
    this.storeId,
    this.storeName,
    this.storeLogo,
    this.offerTitle,
    this.description,
    this.originalPrice = 0,
    this.discountedPrice = 0,
    this.moduleId,
    this.imageUrl,
  });

  static double _toDouble(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);
  static int? _toInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());

  factory _Offer.fromJson(Map<String, dynamic> j) => _Offer(
        storeId: _toInt(j['store_id']),
        storeName: j['store_name']?.toString(),
        storeLogo: j['store_logo_full_url']?.toString(),
        offerTitle: j['offer_title']?.toString(),
        description: j['description']?.toString(),
        originalPrice: _toDouble(j['original_price']),
        discountedPrice: _toDouble(j['discounted_price']),
        moduleId: _toInt(j['module_id']),
        imageUrl: j['image_full_url']?.toString(),
      );
}

class _HomeCurrentOffersSectionState extends State<HomeCurrentOffersSection> {
  List<_Offer> _offers = const [];
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
    final api = Get.find<ApiClient>();

    // The endpoint is module-scoped via the moduleId header. Fetch offers for
    // every module (each with a valid header) and merge → cross-module rail.
    final modules = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>().moduleList
        : null;

    final List<_Offer> all = [];
    try {
      if (modules != null && modules.isNotEmpty) {
        final results = await Future.wait(
          modules.map((m) => _fetchForModule(api, m.id)),
        );
        for (final list in results) {
          all.addAll(list);
        }
      } else {
        all.addAll(await _fetchForModule(api, null));
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _offers = all;
      _loading = false;
    });
  }

  /// Fetches the offers for a single module (or the active one when null).
  Future<List<_Offer>> _fetchForModule(ApiClient api, int? moduleId) async {
    try {
      final response = await api.getData(
        '/api/v2/stores/offers?limit=10&offset=0',
        headers: {
          AppConstants.localizationKey: 'ar',
          if (moduleId != null) AppConstants.moduleId: moduleId.toString(),
        },
        useEtag: false,
      );
      final dynamic body = response.body;
      if (body is Map && body['offers'] is List) {
        return (body['offers'] as List)
            .whereType<Map>()
            .map((e) => _Offer.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _offers.isEmpty) {
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
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: Text(
              'current_offers'.tr,
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
          SizedBox(
            height: HomeCurrentOffersSection._railHeight,
            child: _loading
                ? _buildSkeleton(context)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    itemCount: _offers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) =>
                        _OfferCard(offer: _offers[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: 3,
        separatorBuilder: (_, __) =>
            const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (_, __) => Container(
          width: HomeCurrentOffersSection._cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _Offer offer;

  const _OfferCard({required this.offer});

  // Height of the top offer image; the logo straddles its bottom edge.
  static const double _imageHeight = 78;
  static const double _logoWidth = 40;
  static const double _logoHeight = 46;

  String get _description {
    final desc = (offer.description ?? '').trim();
    if (desc.isNotEmpty) return desc;
    final title = (offer.offerTitle ?? '').trim();
    return title.isNotEmpty ? title : 'special_offer'.tr;
  }

  /// Opens the offer's store, switching to its module first so it loads.
  Future<void> _open() async {
    if (offer.moduleId != null && Get.isRegistered<SplashController>()) {
      final sc = Get.find<SplashController>();
      final modules = sc.moduleList;
      if (modules != null) {
        for (final m in modules) {
          if (m.id == offer.moduleId) {
            // Header-only switch → instant nav; the store screen shows its own
            // loading while fetching.
            if (sc.module?.id != m.id) await sc.setModuleHeaderOnly(m);
            break;
          }
        }
      }
    }
    await Get.toNamed(
        RouteHelper.getStoreRoute(id: offer.storeId, page: 'store'));
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return InkWell(
      borderRadius: radius,
      onTap: _open,
      child: Container(
        width: HomeCurrentOffersSection._cardWidth,
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top: the offer image.
                CustomImage(
                  image: offer.imageUrl ?? '',
                  width: HomeCurrentOffersSection._cardWidth,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                  placeholder: Images.placeholder,
                ),
                // Bottom: info section.
                Expanded(
                  child: Container(
                    color: const Color(0xFFF6F5F8),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store name — sits beside the logo on the right.
                            Padding(
                              padding: const EdgeInsets.only(right: 50),
                              child: Text(
                                offer.storeName ?? '',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.2,
                                  color: Color(0xFF121C19),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Offer description.
                            Text(
                              _description,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                                height: 1.2,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                        // Discounted price + original (struck) price.
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _priceWidget(context, offer.discountedPrice),
                              if (offer.originalPrice >
                                  offer.discountedPrice) ...[
                                const SizedBox(width: 4),
                                _priceWidget(context, offer.originalPrice,
                                    struck: true),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Store logo straddling the image / info boundary, on the right.
            Positioned(
              right: Dimensions.paddingSizeSmall,
              top: _imageHeight - (_logoHeight / 2),
              child: Container(
                width: _logoWidth,
                height: _logoHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomImage(
                  image: offer.storeLogo ?? '',
                  width: _logoWidth,
                  height: _logoHeight,
                  fit: BoxFit.cover,
                  placeholder: Images.placeholder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Widget _priceWidget(BuildContext context, double value,
      {bool struck = false}) {
    final Color color =
        struck ? const Color(0xFF717885) : const Color(0xFF121C19);
    final Widget row = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.sar,
            width: struck ? 13 : 14,
            height: struck ? 13 : 14,
            color: color,
            errorBuilder: (_, __, ___) => Text('﷼',
                style: robotoBold.copyWith(fontSize: 12, color: color)),
          ),
          const SizedBox(width: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: struck ? FontWeight.w500 : FontWeight.w700,
              fontSize: 15,
              height: 1.2,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (!struck) return row;
    // Strike the whole old price (symbol + number) with one red line.
    return Stack(
      alignment: Alignment.center,
      children: [
        row,
        const Positioned.fill(
          child: Center(
            child: Divider(
              color: Color(0xFFE53935),
              thickness: 1.5,
              height: 0,
            ),
          ),
        ),
      ],
    );
  }
}
