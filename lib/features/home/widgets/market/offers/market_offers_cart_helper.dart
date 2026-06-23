import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_models.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Cart helpers for the Market offers screen: read line quantities and
/// add/decrement products while keeping the cart scoped to the right module.

/// Units of [id] currently in the cart.
int offerCartQty(int? id) {
  if (id == null || !Get.isRegistered<CartController>()) return 0;
  int q = 0;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == id) q += c.quantity ?? 0;
  }
  return q;
}

int? offerCartLineId(int? id) {
  if (id == null || !Get.isRegistered<CartController>()) return null;
  for (final c in Get.find<CartController>().cartList) {
    if (c.item?.id == id) return c.id;
  }
  return null;
}

/// Scope the cart to the product's module. The active module may differ
/// (e.g. the app sits on restaurants/6 while browsing the market/3); the cart
/// keys its cache on the *cache* module, so both the request header
/// ([setModuleHeaderOnly]) and the cache module ([setCacheModuleOnly]) must be
/// aligned — otherwise the cart desyncs (saves under the wrong module).
Future<void> ensureModule(int moduleId) async {
  if (!Get.isRegistered<SplashController>()) return;
  final sc = Get.find<SplashController>();
  final list = sc.moduleList;
  if (list == null) return;
  for (final m in list) {
    if (m.id == moduleId) {
      if (sc.module?.id != moduleId) await sc.setModuleHeaderOnly(m);
      await sc.setCacheModuleOnly(m);
      return;
    }
  }
}

Future<void> addOfferToCart(
    OfferProduct p, int? storeId, int moduleId) async {
  if (p.id == null || !Get.isRegistered<CartController>()) return;
  await ensureModule(moduleId);
  final cart = OnlineCart(null, p.id, null, p.shownPrice.toString(), '', [], [],
      1, [], [], [], 'Item',
      storeId: storeId);
  // Silent add: the card's stepper + floating badge reflect the new count.
  await Get.find<CartController>().addToCartOnline(cart);
}

Future<void> decOfferFromCart(OfferProduct p) async {
  final lineId = offerCartLineId(p.id);
  if (lineId == null || !Get.isRegistered<CartController>()) return;
  final cart = Get.find<CartController>();
  if (offerCartQty(p.id) <= 1) {
    await cart.removeFromCartById(lineId);
  } else {
    await cart.setQuantityById(false, lineId, 9999, 0);
  }
}
