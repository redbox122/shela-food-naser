import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Shared model + fetch for "العروض الحالية" (current offers), used by both the
/// home rail ([HomeCurrentOffersSection]) and the full-screen list
/// ([CurrentOffersScreen]). Wired to `GET /api/v2/stores/offers` (cross-module).
class OfferItem {
  /// Backend product id of the discounted item (from `item_id`/`id`). Drives the
  /// quick-add (+) button on the offer card — null when the payload omits it.
  final int? itemId;

  /// True when the item has variations/options (from `has_variations`). The (+)
  /// button opens the product detail page (to complete required options) instead
  /// of adding directly to the cart.
  final bool hasVariations;
  final int? storeId;
  final String? storeName;
  final String? storeLogo;
  final String? offerTitle;
  final String? description;
  final double originalPrice;
  final double discountedPrice;
  final int? moduleId;
  final String? imageUrl;

  /// Discount badge data: `discount_amount` + `discount_type` ('percent' /
  /// 'amount'), e.g. "خصم 45%".
  final double discountAmount;
  final String discountType;

  /// Store rating / delivery info — present only if the offers payload carries
  /// it (defaults are neutral so the UI can hide them when absent).
  final double rating;
  final bool freeDelivery;
  final String? deliveryTime;

  /// Store-category ids this offer belongs to (used by the "فئة المتاجر" filter).
  /// Empty when the payload doesn't carry category info.
  final List<int> categoryIds;

  OfferItem({
    this.itemId,
    this.hasVariations = false,
    this.storeId,
    this.storeName,
    this.storeLogo,
    this.offerTitle,
    this.description,
    this.originalPrice = 0,
    this.discountedPrice = 0,
    this.moduleId,
    this.imageUrl,
    this.discountAmount = 0,
    this.discountType = '',
    this.rating = 0,
    this.freeDelivery = false,
    this.deliveryTime,
    this.categoryIds = const [],
  });

  static double _toDouble(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);
  static int? _toInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());
  static bool _toBool(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';

  /// Parses a category field that may be a list of ids, a list of objects
  /// (`{id, name}`), or a single id — under any of the common payload keys.
  static List<int> _toIntList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      final out = <int>[];
      for (final e in v) {
        final id = e is Map ? int.tryParse('${e['id']}') : int.tryParse('$e');
        if (id != null) out.add(id);
      }
      return out;
    }
    final single = int.tryParse('$v');
    return single != null ? [single] : const [];
  }

  factory OfferItem.fromJson(Map<String, dynamic> j) => OfferItem(
        itemId: _toInt(j['item_id'] ?? j['id'] ?? j['product_id']),
        hasVariations: _toBool(j['has_variations'] ?? j['has_options']),
        storeId: _toInt(j['store_id']),
        storeName: j['store_name']?.toString(),
        storeLogo:
            (j['store_logo_full_url'] ?? j['store_logo_url'])?.toString(),
        offerTitle: j['offer_title']?.toString(),
        description: j['description']?.toString(),
        originalPrice: _toDouble(j['original_price']),
        discountedPrice: _toDouble(j['discounted_price']),
        moduleId: _toInt(j['module_id']),
        imageUrl:
            (j['image_full_url'] ?? j['product_image_full_url'])?.toString(),
        discountAmount: _toDouble(j['discount_amount']),
        discountType: (j['discount_type'] ?? '').toString(),
        rating: _toDouble(
            j['avg_rating'] ?? j['rating'] ?? j['store_rating']),
        freeDelivery: _toBool(j['free_delivery'] ?? j['store_free_delivery']),
        deliveryTime:
            (j['delivery_time'] ?? j['store_delivery_time'])?.toString(),
        categoryIds: _toIntList(j['category_ids'] ??
            j['categories'] ??
            j['category_id'] ??
            j['store_category_id'] ??
            j['store_category_ids']),
      );
}

/// Fetches current offers across every module (each request is module-scoped via
/// the moduleId header) and merges them into one cross-module list.
Future<List<OfferItem>> fetchCurrentOffers({int? moduleId}) async {
  if (!Get.isRegistered<ApiClient>()) return const [];
  final api = Get.find<ApiClient>();

  // Scoped to one module when provided (restaurants/cafés/pharmacy/shops show
  // only their own offers); otherwise aggregate across all modules.
  if (moduleId != null) {
    try {
      return await _fetchForModule(api, moduleId);
    } catch (_) {
      return const [];
    }
  }

  final modules = Get.isRegistered<SplashController>()
      ? Get.find<SplashController>().moduleList
      : null;

  final List<OfferItem> all = [];
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
  return all;
}

/// Opens the offer's store, switching to its module (header-only) first so the
/// store screen loads against the right module.
Future<void> openOfferStore(OfferItem offer) async {
  if (offer.moduleId != null && Get.isRegistered<SplashController>()) {
    final sc = Get.find<SplashController>();
    final modules = sc.moduleList;
    if (modules != null) {
      for (final m in modules) {
        if (m.id == offer.moduleId) {
          if (sc.module?.id != m.id) await sc.setModuleHeaderOnly(m);
          break;
        }
      }
    }
  }
  await Get.toNamed(
    RouteHelper.getStoreRoute(id: offer.storeId, page: 'store'),
  );
}

/// Fetches the offers for a single module (or the active one when null).
Future<List<OfferItem>> _fetchForModule(ApiClient api, int? moduleId) async {
  try {
    final response = await api.getData(
      '/api/v2/stores/offers?limit=50&offset=0',
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
          .map((e) => OfferItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  } catch (_) {}
  return const [];
}
