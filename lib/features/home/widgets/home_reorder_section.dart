import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: "أعد طلبك" — recent orders the user can reorder.
///
/// Wired to `GET /api/v1/customer/order/recent`, which returns a flat list with
/// the store name/logo and the order's module type. Shown for logged-in users
/// only; tapping a row opens the order details.
class HomeReorderSection extends StatefulWidget {
  const HomeReorderSection({super.key});

  static const int _maxRows = 3;

  @override
  State<HomeReorderSection> createState() => _HomeReorderSectionState();
}

/// Lightweight model for a row of the `/order/recent` response.
class _RecentOrder {
  final int? id;
  final String? storeName;
  final String? storeLogo;
  final String? moduleType;
  final String? moduleName;
  final String? orderDate;

  _RecentOrder({
    this.id,
    this.storeName,
    this.storeLogo,
    this.moduleType,
    this.moduleName,
    this.orderDate,
  });

  factory _RecentOrder.fromJson(Map<String, dynamic> j) => _RecentOrder(
        id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}'),
        storeName: j['store_name']?.toString(),
        storeLogo: j['store_logo']?.toString(),
        moduleType: j['module_type']?.toString(),
        moduleName: j['module_name']?.toString(),
        orderDate: j['order_date']?.toString(),
      );
}

class _HomeReorderSectionState extends State<HomeReorderSection> {
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
        // Always parse a fresh 200 body (a 304 returns nothing to parse).
        useEtag: false,
      );
      if (!mounted) return;
      List<_RecentOrder> orders = const [];
      final dynamic body = response.body;
      if (body is Map && body['orders'] is List) {
        orders = (body['orders'] as List)
            .whereType<Map>()
            .map((e) => _RecentOrder.fromJson(Map<String, dynamic>.from(e)))
            .take(HomeReorderSection._maxRows)
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
    // Hidden for guests, while loading, or when there is nothing to show.
    if (!AuthHelper.isLoggedIn() || _loading || _orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reorder_your_order'.tr,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.4,
              color: Color(0xFF121C19),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ..._orders.map((order) => _ReorderRow(order: order)),
        ],
      ),
    );
  }
}

class _ReorderRow extends StatelessWidget {
  final _RecentOrder order;

  const _ReorderRow({required this.order});

  String _type() => (order.moduleType ?? '').trim().toLowerCase();

  String _tagLabel() {
    switch (_type()) {
      case AppConstants.food:
        return 'tag_restaurant'.tr;
      case AppConstants.grocery:
        return 'tag_market'.tr;
      case AppConstants.pharmacy:
        return 'tag_pharmacy'.tr;
      default:
        // ecommerce / anything else: fall back to the module name from the API.
        return order.moduleName ?? '';
    }
  }

  // Tag colours match the "خدماتنا" service tiles.
  Color _tagBg() {
    switch (_type()) {
      case AppConstants.food:
        return const Color(0xFFFFF1E7);
      case AppConstants.grocery:
        return const Color(0xFFE7F7EA);
      case AppConstants.pharmacy:
        return const Color(0xFFE5FFFA);
      default:
        return const Color(0xFFF1ECFF); // ecommerce
    }
  }

  Color _tagFg() {
    switch (_type()) {
      case AppConstants.food:
        return const Color(0xFFD17A2E);
      case AppConstants.grocery:
        return const Color(0xFF1F7A35);
      case AppConstants.pharmacy:
        return const Color(0xFF1F8C7E);
      default:
        return const Color(0xFF6B4FBB); // ecommerce
    }
  }

  String _relativeTime() {
    final date = order.orderDate;
    if (date == null || date.isEmpty) {
      return '';
    }
    final parsed = DateConverter.tryParseDateTimeSafely(date);
    if (parsed == null) {
      return '';
    }
    final int days = DateTime.now().difference(parsed).inDays;
    if (days <= 0) {
      return 'today'.tr;
    }
    if (days == 1) {
      return 'yesterday'.tr;
    }
    return '$days ${'days'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusLarge);
    final String tag = _tagLabel();

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: radius,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.20),
        child: InkWell(
          borderRadius: radius,
          onTap: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(order.id)),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                // Store logo inside a green container — on the right (leading).
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF31A342),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomImage(
                    image: order.storeLogo ?? '',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: Images.placeholder,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                // Name + tag + time, right-aligned next to the logo.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName ?? '',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 27 / 16, // line-height 27px
                          color: Color(0xFF0A0A0A), // hsba(0,0%,4%,1)
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (tag.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _tagBg(),
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall),
                              ),
                              child: Text(
                                tag,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  height: 1.2,
                                  color: _tagFg(),
                                ),
                              ),
                            ),
                          if (tag.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF717885),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _relativeTime(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              height: 16 / 10, // line-height 16px
                              color: Color(0xFF717885),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Icon(Icons.arrow_forward_ios,
                    color: Theme.of(context).hintColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
