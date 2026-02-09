// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';

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
      }

      Get.find<AuthController>()
          .clearSharedData(removeToken: false)
          .then((_) {
        Get.find<FavouriteController>().removeFavourite();
        Get.offAllNamed<void>(RouteHelper.getInitialRoute());
      });
    } else {
      if (response.statusText != 'The guest id field is required.') {
        final cleanMessage =
            response.statusText?.replaceFirst('messages.', '') ?? '';
        debugPrint(
          '\x1B[32mcheckApi >>>>>>>>>>>>>>   $cleanMessage\x1B[0m',
        );
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

    const criticalPaths = <String>[
      '/customer/info',
      '/auth/login',
      '/auth/social-login',
    ];

    for (final path in criticalPaths) {
      if (uri.contains(path)) {
        return true;
      }
    }

    return false;
  }

  /// 🔐 Handle auth-001 error with safe token refresh
  static Future<void> handleAuth001Error(
    Response<dynamic> response,
    String? uri,
  ) async {
    if (_isRefreshing) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ ApiChecker: Token refresh already in progress, skipping',
        );
      }
      return;
    }

    if (AuthHelper.isGuestLoggedIn()) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ ApiChecker: Guest user, skipping token refresh',
        );
      }
      return;
    }

    _isRefreshing = true;

    try {
      final authController = Get.find<AuthController>();

      await authController.updateToken();

      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      );

      if (AuthHelper.isLoggedIn()) {
        if (kDebugMode) {
          debugPrint(
            '✅ ApiChecker: Token refreshed successfully',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '❌ ApiChecker: Token refresh failed, logging out',
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
        debugPrint(
          '❌ ApiChecker: Error during token refresh: $e',
        );
      }

      try {
        await Get.find<AuthController>()
            .clearSharedData(removeToken: false);
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
}
