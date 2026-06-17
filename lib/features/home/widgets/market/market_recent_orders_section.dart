import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN (Market): "الطلبات السابقة" — horizontal rail of the user's
/// recent orders shown as logo cards.
///
/// Wired to `GET /api/v1/customer/order/recent` (logged-in only); tapping a
/// card opens the order details.
class MarketRecentOrdersSection extends StatefulWidget {
  const MarketRecentOrdersSection({super.key});

  static const double _railHeight = 104;
  static const double _cardWidth = 84;

  @override
  State<MarketRecentOrdersSection> createState() =>
      _MarketRecentOrdersSectionState();
}

/// Lightweight model for a row of the `/order/recent` response.
class _RecentOrder {
  final int? id;
  final String? storeName;
  final String? storeLogo;

  _RecentOrder({this.id, this.storeName, this.storeLogo});

  factory _RecentOrder.fromJson(Map<String, dynamic> j) => _RecentOrder(
        id: int.tryParse('${j['id']}'),
        storeName: j['store_name']?.toString(),
        storeLogo: j['store_logo']?.toString(),
      );
}

class _MarketRecentOrdersSectionState extends State<MarketRecentOrdersSection> {
  List<_RecentOrder> _orders = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!AuthHelper.isLoggedIn() || !Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await Get.find<ApiClient>().getData(
        '/api/v1/customer/order/recent',
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      List<_RecentOrder> orders = const [];
      if (body is Map && body['orders'] is List) {
        orders = (body['orders'] as List)
            .whereType<Map>()
            .map((e) => _RecentOrder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hidden for guests or when there is nothing to show.
    if (!AuthHelper.isLoggedIn() || (!_loading && _orders.isEmpty)) {
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
              'previous_orders'.tr,
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
            height: MarketRecentOrdersSection._railHeight,
            child: _loading
                ? _buildSkeleton(context)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _OrderCard(order: _orders[i]),
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
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: MarketRecentOrdersSection._cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _RecentOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusLarge);
    return InkWell(
      borderRadius: radius,
      onTap: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(order.id)),
      child: SizedBox(
        width: MarketRecentOrdersSection._cardWidth,
        child: Column(
          children: [
            CustomImage(
              image: order.storeLogo ?? '',
              width: MarketRecentOrdersSection._cardWidth,
              height: 72,
              fit: BoxFit.contain,
              placeholder: Images.placeholder,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Text(
                order.storeName ?? '',
                textAlign: TextAlign.center,
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
          ],
        ),
      ),
    );
  }
}
