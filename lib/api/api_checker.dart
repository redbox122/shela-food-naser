
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class ApiChecker {
  /// 🔒 GUARD: Prevent infinite refresh loops
  static bool _isRefreshing = false;

  static void checkApi(
    Response<dynamic> response, {
    bool getXSnackBar = false,
    String? uri,
  }) {
    if (response.statusCode == 401) {
      // 🔐 Minimum safety: clear local cart, reload session, block checkout
      unawaited(_handleUnauthorized(uri));

      // 🔧 Prevent panic logouts for non-critical endpoints
      final shouldLogout = _shouldTriggerLogout(uri);

      if (!shouldLogout) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ ApiChecker: 401 received for non-critical endpoint ($uri) - skipping logout',
          );
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '🔒 ApiChecker: 401 received for critical endpoint ($uri) - triggering logout',
        );
        debugPrint(
          '[AuthLogout][REASON] reason=real_401 endpoint=$uri',
        );
      }

      Get.find<AuthController>()
          .clearSharedData(removeToken: false)
          .then((_) {
        Get.find<FavouriteController>().removeFavourite();
        Get.offAllNamed<void>(RouteHelper.getInitialRoute());
      });
    } else {
      if (response.statusText != 'The guest id field is required.') {
        final String cleanMessage =
            response.statusText?.replaceFirst('messages.', '') ?? '';
        if (kDebugMode) {
          final String endpoint =
              uri ?? response.request?.url.toString() ?? 'unknown';
          final String method = response.request?.method ?? '?';
          debugPrint(
            '[API_ERROR][CHECK_API] method=$method endpoint=$endpoint '
            'status=${response.statusCode} requestId=— safeMessage=$cleanMessage',
          );
        }
      }
    }
  }

  /// 🔐 Minimum safety handler for 401 Unauthorized
  static Future<void> _handleUnauthorized(String? uri) async {
    if (kDebugMode) {
      debugPrint('🔐 ApiChecker: Handling 401 Unauthorized for $uri');
    }

    // Clear local cart to avoid corrupted state during auth failure
    try {
      if (Get.isRegistered<CartController>()) {
        final cartController = Get.find<CartController>();
        await cartController.clearLocalCartForUnauthorized();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ ApiChecker: Failed to clear local cart on 401 - $e');
      }
    }

    // Attempt token refresh if not guest
    if (!AuthHelper.isGuestLoggedIn()) {
      try {
        final authController = Get.find<AuthController>();
        await authController.updateToken();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ ApiChecker: Token refresh failed on 401 - $e');
        }
      }
    }
  }

  /// 🔧 Decide whether a 401 should trigger logout
  static bool _shouldTriggerLogout(String? uri) {
    if (uri == null) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ ApiChecker: URI is null - skipping logout to prevent panic',
        );
      }
      return false;
    }

    // A 401 on the login/social-login handshake means bad credentials or an
    // expired OTP — NOT an invalid session. It must show an error, not clear
    // storage and bounce the user to the start route. Only a 401 on an
    // already-authenticated identity call (/customer/info) means the session
    // is truly dead and warrants logout.
    const criticalPaths = <String>[
      '/customer/info',
    ];

    for (final path in criticalPaths) {
      if (uri.contains(path)) {
        return true;
      }
    }

    return false;
  }

  /// Called for the first leg of auth-deferred handling: sync FCM token with
  /// [forAuth001Recovery] so nested POSTs do not enter the retry loop.
  static Future<void> refreshSessionAfterAuthDeferred(String? uri) async {
    if (AuthHelper.isGuestLoggedIn()) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ ApiChecker: Guest user, skipping auth-deferred refresh',
        );
      }
      return;
    }
    if (_isRefreshing) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ ApiChecker: Token refresh already in progress, skipping',
        );
      }
      return;
    }
    _isRefreshing = true;
    try {
      final AuthController authController = Get.find<AuthController>();
      await authController.updateToken(forAuth001Recovery: true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!AuthHelper.isLoggedIn()) {
        if (kDebugMode) {
          debugPrint(
            '❌ ApiChecker: Session invalid after auth-deferred refresh',
          );
        }
        await authController.clearSharedData(removeToken: false);
        Get.find<FavouriteController>().removeFavourite();
        Get.offAllNamed<void>(
          RouteHelper.getSignInRoute(Get.currentRoute),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ApiChecker: Error during auth-deferred refresh: $e');
      }
      // 🔐 FALSE-LOGOUT GUARD: auth_deferred is a transient HTTP 200 handshake,
      // not a real 401. A refresh error (e.g. right after hot restart, before
      // the FCM/device token is ready) must NOT drop a still-valid session.
      if (AuthHelper.isLoggedIn()) {
        if (kDebugMode) {
          debugPrint(
            '[AuthLogout][SKIPPED] reason=auth_deferred_refresh_error endpoint=$uri '
            '— saved token still present, keeping session',
          );
        }
        return;
      }
      try {
        if (kDebugMode) {
          debugPrint(
            '[AuthLogout][REASON] reason=auth_deferred_refresh_error_no_token endpoint=$uri',
          );
        }
        await Get.find<AuthController>().clearSharedData(removeToken: false);
        Get.find<FavouriteController>().removeFavourite();
        Get.offAllNamed<void>(
          RouteHelper.getSignInRoute(Get.currentRoute),
        );
      } catch (logoutError) {
        if (kDebugMode) {
          debugPrint(
            '❌ ApiChecker: Error during logout: $logoutError',
          );
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Second auth-deferred on the retried request: treat session as expired.
  static Future<void> onAuthDeferredRetryExhausted(String? uri) async {
    if (kDebugMode) {
      debugPrint(
        '[AuthRetry] Exhausted auth-deferred retries path=$uri',
      );
    }
    // 🔐 FALSE-LOGOUT GUARD: `auth_deferred` is an HTTP 200 handshake, NOT a real
    // 401/unauthenticated. If a valid saved token still exists (the typical case
    // right after a Hot Restart), keep the user signed in — a genuine
    // invalidation will surface later as a real 401 and be handled by checkApi().
    if (AuthHelper.isLoggedIn()) {
      if (kDebugMode) {
        debugPrint(
          '[AuthLogout][SKIPPED] reason=auth_deferred_exhausted endpoint=$uri '
          '— saved token still present, keeping session',
        );
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[AuthLogout][REASON] reason=auth_deferred_exhausted_no_token endpoint=$uri',
      );
    }
    try {
      showCustomSnackBar('session_time_out'.tr);
    } catch (_) {}
    try {
      await Get.find<AuthController>().clearSharedData(removeToken: false);
      Get.find<FavouriteController>().removeFavourite();
      Get.offAllNamed<void>(
        RouteHelper.getSignInRoute(Get.currentRoute),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ApiChecker: onAuthDeferredRetryExhausted failed: $e');
      }
    }
  }
}