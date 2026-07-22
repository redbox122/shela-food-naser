import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';

/// Routes a tapped notification to the most relevant screen based on its type
/// (falling back to title/description keywords). Wallet/qidha/loyalty targets
/// don't need an id; order notifications open the orders list (the in-app list
/// payload has no order id — deep order-tracking is handled by the push handler).
class NotificationNavigationHelper {
  const NotificationNavigationHelper._();

  static void open(NotificationModel model) {
    final type = (model.data?.type ?? '').toLowerCase();
    final text =
        '${model.data?.title ?? ''} ${model.data?.description ?? ''}'.trim();
    bool has(List<String> keys) =>
        keys.any((k) => type.contains(k) || text.contains(k));

    if (has(['qidha', 'قيدها'])) {
      Get.toNamed<void>(RouteHelper.getKaidhaWallet());
      return;
    }
    if (has([
      'wallet',
      'fund',
      'credit',
      'debit',
      'loyalty',
      'point',
      'رصيد',
      'محفظ',
      'ولاء',
      'نقاط',
    ])) {
      Get.toNamed<void>(RouteHelper.getWalletRoute(fromNotification: true));
      return;
    }
    if (type == 'order_status' ||
        (model.data?.orderId != null && (model.data?.orderId ?? 0) > 0) ||
        has([
          'order',
          'delivery',
          'confirmed',
          'processing',
          'placed',
          'الطلب',
          'طلب',
          'المندوب',
        ])) {
      final int? orderId = model.data?.orderId;
      if (orderId != null && orderId > 0) {
        // Deep-link straight to the referenced order's details (e.g. tapping
        // "Order 27 is canceled" opens order 27), not just the orders list.
        Get.toNamed<void>(
            RouteHelper.getOrderDetailsRoute(orderId, fromNotification: true));
      } else {
        Get.toNamed<void>(RouteHelper.getOrderRoute());
      }
      return;
    }
    // Unknown type → stay on the notifications screen.
  }
}
