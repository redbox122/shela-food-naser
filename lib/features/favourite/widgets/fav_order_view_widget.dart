import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Favourites → "Orders" tab. Shows the user's order history grouped by the
/// day the order was placed (Today / Yesterday / explicit date).
class FavOrderViewWidget extends StatefulWidget {
  const FavOrderViewWidget({super.key});

  @override
  State<FavOrderViewWidget> createState() => _FavOrderViewWidgetState();
}

class _FavOrderViewWidgetState extends State<FavOrderViewWidget> {
  @override
  void initState() {
    super.initState();
    if (AuthHelper.isLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<OrderController>().getHistoryOrders(1, isUpdate: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: GetBuilder<OrderController>(builder: (orderController) {
        final List<OrderModel>? completed =
            orderController.historyOrderModel?.orders;
        final List<OrderModel>? canceled =
            orderController.canceledOrderModel?.orders;
        final bool isLoading = completed == null && canceled == null;
        final List<OrderModel> orders = [...?completed, ...?canceled];
        // Newest first across both completed and cancelled orders.
        orders.sort((a, b) {
          final DateTime da =
              DateTime.tryParse(a.createdAt ?? '') ?? DateTime(0);
          final DateTime db =
              DateTime.tryParse(b.createdAt ?? '') ?? DateTime(0);
          return db.compareTo(da);
        });

        return RefreshIndicator(
          onRefresh: () async {
            await orderController.getHistoryOrders(1, isUpdate: true);
          },
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
                  ? _buildEmpty(context)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _OrdersGroupedList(orders: orders),
                    ),
        );
      }),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Image.asset(
          Images.no_favourit,
          width: 211,
          height: 210.32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Icon(
            Icons.favorite_border_rounded,
            size: 96,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Text(
          'no_favorites_yet'.tr,
          style: tajawalBold.copyWith(
            fontSize: 18,
            height: 1.6,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OrdersGroupedList extends StatelessWidget {
  final List<OrderModel> orders;
  const _OrdersGroupedList({required this.orders});

  Map<DateTime?, List<OrderModel>> _grouped() {
    final LinkedHashMap<DateTime?, List<OrderModel>> groups = LinkedHashMap();
    for (final order in orders) {
      final DateTime? date = order.createdAt != null
          ? DateTime.tryParse(order.createdAt!)?.toLocal()
          : null;
      final DateTime? key =
          date == null ? null : DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(key, () => <OrderModel>[]).add(order);
    }
    return groups;
  }

  String _sectionLabel(DateTime? day) {
    if (day == null) return '';
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int diff = today.difference(day).inDays;
    if (diff == 0) return 'today'.tr;
    if (diff == 1) return 'yesterday'.tr;
    final String locale =
        Get.find<LocalizationController>().locale.languageCode;
    return DateFormat('d MMMM، yyyy', locale).format(day);
  }

  @override
  Widget build(BuildContext context) {
    final Map<DateTime?, List<OrderModel>> groups = _grouped();
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in groups.entries) ...[
            if (entry.key != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                ),
                child: Text(
                  _sectionLabel(entry.key),
                  textAlign: TextAlign.right,
                  style: tajawalBold.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                    letterSpacing: 0,
                    // Text/disable-input — hsba(219, 15%, 52%).
                    color: const Color(0xFF717885),
                  ),
                ),
              ),
            ...entry.value.map((order) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    0,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeSmall,
                  ),
                  child: _FavouriteOrderCard(order: order),
                )),
          ],
        ],
      ),
    );
  }
}

class _FavouriteOrderCard extends StatelessWidget {
  final OrderModel order;
  const _FavouriteOrderCard({required this.order});

  /// Localized status label + text colour + pill background colour based on the
  /// raw order status. Completed → green pill; cancelled/expired → #FFDCDC pill.
  (String label, Color fg, Color bg) _status(BuildContext context) {
    final String raw = (order.orderStatus ?? '').toLowerCase();
    const Set<String> done = {'delivered', 'completed'};
    const Set<String> cancelled = {
      'canceled',
      'cancelled',
      'failed',
      'refunded',
      'expired',
    };
    final Color primary = Theme.of(context).primaryColor;
    if (cancelled.contains(raw)) {
      return (raw.tr, const Color(0xFFE53935), const Color(0xFFFFDCDC));
    }
    if (done.contains(raw)) {
      return ('completed'.tr, primary, primary.withValues(alpha: 0.12));
    }
    return (
      raw.isEmpty ? '' : raw.tr,
      Theme.of(context).hintColor,
      Theme.of(context).hintColor.withValues(alpha: 0.12),
    );
  }

  String _time() {
    if (order.createdAt == null) return '';
    final DateTime? date = DateTime.tryParse(order.createdAt!)?.toLocal();
    if (date == null) return '';
    final String locale =
        Get.find<LocalizationController>().locale.languageCode;
    return DateFormat('h:mm a', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(order.id)),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImage(
                image: order.store?.logoFullUrl ?? '',
                imageStatus: order.store?.logoStatus ?? 'ok',
                height: 103,
                width: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _buildInfo(context)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            SizedBox(
              height: 103,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.favorite, size: 18, color: primary),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Icon(
                    Get.find<LocalizationController>().isLtr
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_forward_ios,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final Color black =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final TextStyle base = tajawalBold.copyWith(
        fontSize: 14, fontWeight: FontWeight.w700, color: black);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                order.store?.name ?? '',
                style: base,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Text(
              '#${order.id ?? ''}',
              style: tajawalBold.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: black,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Builder(builder: (context) {
          final (label, fg, bg) = _status(context);
          if (label.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            child: Text(
              label,
              style: tajawalBold.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xff000000),
              ),
            ),
          );
        }),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: black),
            const SizedBox(width: 4),
            Text('${'order_date'.tr} ${_time()}', style: base),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text('${'total_cost'.tr} ', style: base),
            Text(
              PriceConverter.convertPrice(order.orderAmount ?? 0),
              style: base,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    );
  }
}
