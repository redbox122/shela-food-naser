import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/mobile_sticky_cart_positionable.dart';
import 'package:sixam_mart/common/widgets/sticky_cart_bar.dart';

/// Bumps when navigation changes so the overlay recalculates route-based layout.
final ValueNotifier<int> stickyCartRouteTick = ValueNotifier<int>(0);

bool _stickyCartRouteTickPostFrameScheduled = false;

/// Schedules a single tick after the current frame. Direct
/// [stickyCartRouteTick.value++] during build / layout / route callbacks can
/// trigger "widget tree was locked" on [ValueListenableBuilder].
void bumpStickyCartRouteTick() {
  if (_stickyCartRouteTickPostFrameScheduled) {
    return;
  }
  _stickyCartRouteTickPostFrameScheduled = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _stickyCartRouteTickPostFrameScheduled = false;
    stickyCartRouteTick.value++;
  });
}

/// Filled by [_StickyCartNavigatorObserver]. [Get.currentRoute] can lag after a
/// pop (e.g. still `/cart` while the visible page is home), which wrongly hides
/// the sticky bar because [_shouldHideForRoute] matches cart.
class StickyCartNavSession {
  StickyCartNavSession._();

  /// Last pushed opaque page name ([GetPage] / [PageRoute]), excluding sheets.
  static String? lastOpaquePageRoute;

  /// Open **dialog** routes only (not bottom sheets). The sticky cart sits above
  /// the navigator in [main.dart] `Stack`, so sheets can stay visible; center
  /// dialogs should still hide it to avoid overlap.
  static int dialogRouteDepth = 0;

  /// Set from [GetMaterialApp.routingCallback] on every navigation — reflects
  /// the real top route before [Get.currentRoute] catches up after pop.
  static String? lastRoutingCurrent;

  static void syncRoutingCurrentFromGetCallback(String? routeName) {
    final String t = routeName?.trim() ?? '';
    if (t.isEmpty) {
      return;
    }
    if (lastRoutingCurrent != t) {
      lastRoutingCurrent = t;
      bumpStickyCartRouteTick();
    }
  }

  /// From [CartScreen] + [RouteAware] — true only while the cart **page** is the
  /// visible top route. Survives Get `currentRoute` / `routingCallback` lag.
  static bool cartScreenIsVisibleForOverlay = false;

  static void setCartScreenVisibleForOverlay(bool visible) {
    if (cartScreenIsVisibleForOverlay == visible) {
      return;
    }
    cartScreenIsVisibleForOverlay = visible;
    bumpStickyCartRouteTick();
  }
}

/// True for typical blocking dialogs — **not** bottom sheets (item sheet, etc.).
bool _routeIsBlockingStickyDialog(Route<dynamic> route) {
  if (route is DialogRoute) {
    return true;
  }
  if (route is RawDialogRoute) {
    return true;
  }
  final String typeName = route.runtimeType.toString();
  if (typeName == 'GetDialogRoute') {
    return true;
  }
  return false;
}

bool _routeIsBottomSheetRoute(Route<dynamic> route) {
  if (route is ModalBottomSheetRoute) {
    return true;
  }
  final String typeName = route.runtimeType.toString();
  if (typeName == 'GetModalBottomSheetRoute') {
    return true;
  }
  return false;
}

String? _routeNameOrNull(Route<dynamic>? route) {
  if (route == null) {
    return null;
  }
  final Object? name = route.settings.name;
  if (name is String && name.trim().isNotEmpty) {
    return name.trim();
  }
  if (route is GetPageRoute) {
    final String? routeName = route.routeName;
    if (routeName != null && routeName.trim().isNotEmpty) {
      return routeName.trim();
    }
  }
  return null;
}

/// Register on [GetMaterialApp.navigatorObservers].
final NavigatorObserver stickyCartNavigatorObserver =
    _StickyCartNavigatorObserver();

/// Subscribed by [CartScreen] ([RouteAware]) to toggle
/// [StickyCartNavSession.cartScreenIsVisibleForOverlay].
final RouteObserver<PageRoute<dynamic>> cartRouteObserverForStickyOverlay =
    RouteObserver<PageRoute<dynamic>>();

/// Call when leaving the cart screen (e.g. back or "complete shopping").
/// [Get.currentRoute] can still report `/cart` for several frames after a pop;
/// we retry before writing [StickyCartNavSession.lastOpaquePageRoute].
void scheduleStickyCartOverlayRouteResync() {
  void scheduleAttempt(int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String r = Get.currentRoute.trim();
      if (r.isEmpty) {
        final String? obs = StickyCartNavSession.lastOpaquePageRoute;
        if (obs != null &&
            _routePathForStickyOverlay(obs) == RouteHelper.cart) {
          StickyCartNavSession.lastOpaquePageRoute = RouteHelper.initial;
          StickyCartNavSession.lastRoutingCurrent = RouteHelper.initial;
        }
        stickyCartRouteTick.value++;
        return;
      }
      final bool pathIsCart =
          _routePathForStickyOverlay(r) == RouteHelper.cart;
      if (pathIsCart && attempt < 8) {
        scheduleAttempt(attempt + 1);
        return;
      }
      if (r.isNotEmpty && !pathIsCart) {
        StickyCartNavSession.lastOpaquePageRoute = r;
        StickyCartNavSession.lastRoutingCurrent = r;
      } else if (pathIsCart) {
        StickyCartNavSession.lastOpaquePageRoute = RouteHelper.initial;
        StickyCartNavSession.lastRoutingCurrent = RouteHelper.initial;
      }
      stickyCartRouteTick.value++;
    });
  }
  scheduleAttempt(0);
}

/// When Get reports a top route that is not cart, clear [StickyCartNavSession.cartScreenIsVisibleForOverlay].
/// Use with [GetMaterialApp.routingCallback] — covers RouteAware gaps and post-frame races with GetX.
void syncStickyCartOverlayCartRouteFlagFromRouteName(String? routeName) {
  final String t = routeName?.trim() ?? '';
  if (t.isEmpty) {
    return;
  }
  if (_routePathForStickyOverlay(t) != RouteHelper.cart) {
    StickyCartNavSession.setCartScreenVisibleForOverlay(false);
  }
}

void _stickyCartClearOverlayIfRouteWasCart(Route<dynamic>? route) {
  if (route == null) {
    return;
  }
  final String? name = _routeNameOrNull(route);
  if (name == null) {
    return;
  }
  if (_routePathForStickyOverlay(name) == RouteHelper.cart) {
    StickyCartNavSession.setCartScreenVisibleForOverlay(false);
  }
}

class _StickyCartNavigatorObserver extends NavigatorObserver {
  void _bump() {
    bumpStickyCartRouteTick();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_routeIsBlockingStickyDialog(route)) {
      StickyCartNavSession.dialogRouteDepth++;
    } else if (!_routeIsBottomSheetRoute(route)) {
      final String? prevName = _routeNameOrNull(previousRoute);
      final String? name = _routeNameOrNull(route);
      final bool prevWasCart = prevName != null &&
          _routePathForStickyOverlay(prevName) == RouteHelper.cart;
      final bool newIsCart =
          name != null && _routePathForStickyOverlay(name) == RouteHelper.cart;
      if (prevWasCart && !newIsCart) {
        StickyCartNavSession.setCartScreenVisibleForOverlay(false);
      }
      if (name != null) {
        StickyCartNavSession.lastOpaquePageRoute = name;
      }
    }
    _bump();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stickyCartClearOverlayIfRouteWasCart(route);
    if (_routeIsBlockingStickyDialog(route)) {
      if (StickyCartNavSession.dialogRouteDepth > 0) {
        StickyCartNavSession.dialogRouteDepth--;
      }
    } else {
      final String? prevName = _routeNameOrNull(previousRoute);
      if (prevName != null) {
        StickyCartNavSession.lastOpaquePageRoute = prevName;
      }
      final String? poppedName = _routeNameOrNull(route);
      final bool leftCart = poppedName != null &&
          _routePathForStickyOverlay(poppedName) == RouteHelper.cart;
      if (leftCart && prevName == null) {
        StickyCartNavSession.lastOpaquePageRoute = RouteHelper.initial;
      }
      if (leftCart || prevName == null) {
        scheduleStickyCartOverlayRouteResync();
      }
    }
    _bump();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null &&
        !_routeIsBlockingStickyDialog(newRoute) &&
        !_routeIsBottomSheetRoute(newRoute)) {
      final String? name = _routeNameOrNull(newRoute);
      if (name != null) {
        StickyCartNavSession.lastOpaquePageRoute = name;
      }
    }
    _bump();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stickyCartClearOverlayIfRouteWasCart(route);
    if (_routeIsBlockingStickyDialog(route) &&
        StickyCartNavSession.dialogRouteDepth > 0) {
      StickyCartNavSession.dialogRouteDepth--;
    }
    _bump();
  }
}

/// Approximate height of [AnimatedBottomNavigationBar] + internal padding
/// (dashboard only). Tuned to sit above the bar without overlapping it.
const double _kDashboardBottomNavSlotHeight = 64;

/// Collapsed [ExpandableBottomSheet] strip for running orders — keep in sync
/// with [DashboardScreen] `persistentContentHeight` (Android / iOS).
const double _kRunningOrderStripHeightAndroid = 100;
const double _kRunningOrderStripHeightIos = 110;

/// Breathing room between running-order strip and sticky cart.
const double _kStickyCartGapAboveRunningOrders = 8;

double _runningOrderStripHeightForPlatform() {
  return GetPlatform.isIOS
      ? _kRunningOrderStripHeightIos
      : _kRunningOrderStripHeightAndroid;
}

/// Extra bottom inset when the dashboard running-order bar is shown (same
/// conditions as [DashboardScreen] expandable content, except temporary hide).
double _dashboardRunningOrdersStripPad(
  String currentRoute,
  OrderController? orderController,
) {
  if (!_isDashboardWithBottomNav(currentRoute) || orderController == null) {
    return 0;
  }
  if (!AuthHelper.isLoggedIn()) {
    return 0;
  }
  final List<OrderModel>? orders = orderController.runningOrderModel?.orders;
  if (orders == null || orders.isEmpty) {
    return 0;
  }
  if (!orderController.showBottomSheet) {
    return 0;
  }
  return _runningOrderStripHeightForPlatform() + _kStickyCartGapAboveRunningOrders;
}

/// Exact path for overlay rules: strip query/hash only (no `.contains()` on route).
String _routePathForStickyOverlay(String route) {
  String path = route.trim();
  if (path.isEmpty) {
    return '';
  }
  final int query = path.indexOf('?');
  if (query >= 0) {
    path = path.substring(0, query);
  }
  final int hash = path.indexOf('#');
  if (hash >= 0) {
    path = path.substring(0, hash);
  }
  if (!path.startsWith('/')) {
    path = '/$path';
  }
  return path;
}

bool _isDashboardWithBottomNav(String route) {
  final String path = _routePathForStickyOverlay(route);
  if (path == RouteHelper.main || path == RouteHelper.initial) {
    return true;
  }
  // [RouteHelper.moduleHome] resolves to /module/:moduleId — still [DashboardScreen].
  if (path.startsWith('/module/')) {
    return true;
  }
  return false;
}

/// Profile / payment only. **Cart** visibility uses
/// [StickyCartNavSession.cartScreenIsVisibleForOverlay] (RouteAware), not strings.
/// **Dialogs** use [StickyCartNavSession.dialogRouteDepth].
bool _shouldHideForRoute(String route) {
  final String path = _routePathForStickyOverlay(route);
  const Set<String> hiddenPaths = <String>{
    RouteHelper.profile,
    RouteHelper.updateProfile,
    RouteHelper.payment,
    // Passwordless auth flow — no cart bubble on these screens.
    RouteHelper.welcome,
    RouteHelper.phoneLogin,
    RouteHelper.otpVerification,
    RouteHelper.createAccount,
    RouteHelper.signIn,
    RouteHelper.signUp,
  };
  return hiddenPaths.contains(path);
}

String _resolveRouteForOverlay(BuildContext context) {
  final String fromRouting =
      StickyCartNavSession.lastRoutingCurrent?.trim() ?? '';
  if (fromRouting.isNotEmpty) {
    return fromRouting;
  }
  final String fromGet = Get.currentRoute.trim();
  final String observed =
      StickyCartNavSession.lastOpaquePageRoute?.trim() ?? '';
  final bool getIsCart = fromGet.isNotEmpty &&
      _routePathForStickyOverlay(fromGet) == RouteHelper.cart;
  final bool observedIsCart = observed.isNotEmpty &&
      _routePathForStickyOverlay(observed) == RouteHelper.cart;
  if (getIsCart && observed.isNotEmpty && !observedIsCart) {
    return observed;
  }
  if (observedIsCart && fromGet.isNotEmpty && !getIsCart) {
    return fromGet;
  }
  if (fromGet.isNotEmpty) {
    return fromGet;
  }
  if (observed.isNotEmpty) {
    return observed;
  }
  final ModalRoute<Object?>? modal = ModalRoute.of(context);
  final Object? name = modal?.settings.name;
  if (name is String && name.trim().isNotEmpty) {
    return name.trim();
  }
  return fromGet;
}

/// Full-width cart strip above bottom safe area, or above dashboard bottom nav.
///
/// Directly subscribes to [stickyCartRouteTick], [CartController],
/// [OrderController], and [SplashController] via [addListener] so that **all**
/// signals (route changes, cart mutations, order updates, config refreshes)
/// trigger a rebuild without [GetBuilder] barriers blocking propagation.
class GlobalStickyCartOverlay extends StatefulWidget {
  const GlobalStickyCartOverlay({super.key});

  @override
  State<GlobalStickyCartOverlay> createState() =>
      _GlobalStickyCartOverlayState();
}

class _GlobalStickyCartOverlayState extends State<GlobalStickyCartOverlay> {
  final Set<Type> _subscribed = <Type>{};
  final List<VoidCallback> _controllerDisposers = <VoidCallback>[];

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    stickyCartRouteTick.addListener(_scheduleRebuild);
    _bindControllers();
  }

  @override
  void dispose() {
    stickyCartRouteTick.removeListener(_scheduleRebuild);
    for (final VoidCallback d in _controllerDisposers) {
      d();
    }
    _controllerDisposers.clear();
    _subscribed.clear();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Controller subscriptions
  // ------------------------------------------------------------------

  void _scheduleRebuild() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _bindControllers() {
    _bind<CartController>();
    _bind<OrderController>();
    _bind<SplashController>();
  }

  void _bind<T extends GetxController>() {
    if (_subscribed.contains(T) || !Get.isRegistered<T>()) {
      return;
    }
    try {
      final T c = Get.find<T>();
      c.addListener(_scheduleRebuild);
      _subscribed.add(T);
      _controllerDisposers.add(() {
        try {
          c.removeListener(_scheduleRebuild);
        } catch (e) { if (kDebugMode) debugPrint('$e'); }
      });
    } catch (e) { if (kDebugMode) debugPrint('$e'); }
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Retry for controllers registered after initState (lazy init).
    _bindControllers();

    if (!Get.isRegistered<CartController>()) {
      return const SizedBox.shrink();
    }

    final CartController cartController = Get.find<CartController>();
    final OrderController? orderController = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : null;

    return _globalStickyCartLayer(
      context: context,
      cartController: cartController,
      orderController: orderController,
    );
  }
}

Widget _globalStickyCartLayer({
  required BuildContext context,
  required CartController cartController,
  required OrderController? orderController,
}) {
  final MediaQueryData mq = MediaQuery.of(context);
  final String currentRoute = _resolveRouteForOverlay(context);
  final bool hideForRoute = _shouldHideForRoute(currentRoute) ||
      StickyCartNavSession.cartScreenIsVisibleForOverlay;
  final bool hideForModalOverlay =
      StickyCartNavSession.dialogRouteDepth > 0;
  final int cartLength = cartController.cartList.length;
  if (kDebugMode) {
    debugPrint(
      '[StickyCartOverlay] route="$currentRoute" '
      'path="${_routePathForStickyOverlay(currentRoute)}" hideRoute=$hideForRoute '
      'cartRouteVisible=${StickyCartNavSession.cartScreenIsVisibleForOverlay} '
      'routingCur="${StickyCartNavSession.lastRoutingCurrent}" '
      'dialogDepth=${StickyCartNavSession.dialogRouteDepth} '
      'cartLen=$cartLength',
    );
  }
  if (hideForRoute || hideForModalOverlay) {
    return const SizedBox.shrink();
  }
  final double runningStripPad =
      _dashboardRunningOrdersStripPad(currentRoute, orderController);
  final double bottomPad = mq.padding.bottom +
      (_isDashboardWithBottomNav(currentRoute)
          ? _kDashboardBottomNavSlotHeight + runningStripPad
          : 0);
  final bool useEdgeBubble = ResponsiveHelper.isMobile(context);
  final Widget cart = StickyCartBar(
    isEnabled: true,
    cartController: cartController,
  );
  if (useEdgeBubble) {
    final TextDirection dir = Directionality.of(context);
    final double startSafe =
        dir == TextDirection.rtl ? mq.padding.right : mq.padding.left;
    return MobileStickyCartPositionable(
      bottomPad: bottomPad,
      startSafe: startSafe,
      textDirection: dir,
      child: cart,
    );
  }
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: cart,
    ),
  );
}
