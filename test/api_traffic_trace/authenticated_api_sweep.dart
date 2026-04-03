// ignore_for_file: avoid_print
/// Broad GET sweep with Bearer token — mirrors most read-only app routes.
///
/// Run (PowerShell):
///   $env:SHELLA_API_TOKEN = "YOUR_JWT"
///   dart run test/api_traffic_trace/authenticated_api_sweep.dart
///
/// Or:
///   dart run test/api_traffic_trace/authenticated_api_sweep.dart --token YOUR_JWT
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_traffic_tracer.dart';

typedef SweepCall = ({String path, Map<String, String>? query, String label});

/// Curated list: public + customer GET-style routes (some may return 405/404 if backend expects POST).
List<SweepCall> buildSweepCalls() {
  return <SweepCall>[
    (path: '/api/v1/app-init', query: null, label: 'app-init'),
    (path: '/api/v1/config', query: null, label: 'config'),
    (path: '/api/v1/module', query: null, label: 'module'),
    (path: '/api/v1/bootstrap', query: null, label: 'bootstrap'),
    (path: '/api/v2/home-unified', query: {'include': 'banners,offers,categories'}, label: 'home-unified-partial'),
    (path: '/api/v2/home-unified', query: {'module_id': '3'}, label: 'home-unified-module3'),
    (path: '/api/v1/categories', query: null, label: 'categories'),
    (path: '/api/v1/banners', query: null, label: 'banners'),
    (path: '/api/v1/offers/active', query: null, label: 'offers-active'),
    (path: '/api/v1/stores/get-stores/all', query: {'store_type': 'all', 'offset': '1', 'limit': '5'}, label: 'stores-all'),
    (path: '/api/v1/stores/details/1', query: null, label: 'store-details-1'),
    (path: '/api/v1/items/latest', query: {'offset': '1', 'limit': '5', 'type': 'all'}, label: 'items-latest'),
    (path: '/api/v1/items/popular', query: {'offset': '1', 'limit': '5'}, label: 'items-popular'),
    (path: '/api/v1/items/discounted', query: {'offset': '1', 'limit': '5'}, label: 'items-discounted'),
    (path: '/api/v1/items/search', query: {'name': 'a', 'offset': '1'}, label: 'items-search'),
    (path: '/api/v1/brand/items', query: {'offset': '1', 'limit': '5'}, label: 'brand-items'),
    (path: '/api/v1/brands', query: null, label: 'brands'),
    (path: '/api/v1/flash-sales', query: null, label: 'flash-sales'),
    (path: '/api/v1/zone/list', query: null, label: 'zone-list'),
    (path: '/api/v1/about-us', query: null, label: 'about-us'),
    (path: '/api/v1/privacy-policy', query: null, label: 'privacy'),
    (path: '/api/v1/terms-and-conditions', query: null, label: 'terms'),
    (path: '/api/v1/flutter-landing-page', query: null, label: 'landing-page'),
    (path: '/api/v1/most-tips', query: null, label: 'most-tips'),
    (path: '/api/v1/advertisement/list', query: null, label: 'advertisement-list'),
    (path: '/api/v1/categories/popular', query: null, label: 'categories-popular'),
    (path: '/api/v1/cashback/list', query: null, label: 'cashback-list'),
    (path: '/api/v1/other-banners', query: null, label: 'other-banners'),
    (path: '/api/v2/checkout/store-summary', query: {'store_id': '1'}, label: 'checkout-store-summary'),
    (path: '/api/v1/customer/info', query: null, label: 'customer-info'),
    (path: '/api/v1/customer/address/list', query: null, label: 'address-list'),
    (path: '/api/v1/customer/cart/list', query: null, label: 'cart-list'),
    (path: '/api/v1/coupon/list', query: null, label: 'coupon-list'),
    (path: '/api/v1/customer/wish-list', query: null, label: 'wish-list'),
    (path: '/api/v1/customer/notifications', query: null, label: 'notifications'),
    (path: '/api/v1/customer/order/list', query: {'limit': '10', 'offset': '1'}, label: 'order-history'),
    (path: '/api/v1/customer/order/running-orders', query: null, label: 'running-orders'),
    (path: '/api/v1/customer/wallet/transactions', query: {'limit': '10'}, label: 'wallet-transactions'),
    (path: '/api/v1/customer/wallet/bonuses', query: null, label: 'wallet-bonuses'),
    (path: '/api/v1/customer/wallet/recipients', query: null, label: 'wallet-recipients'),
    (path: '/api/v1/customer/loyalty-point/transactions', query: {'limit': '10'}, label: 'loyalty-transactions'),
    (path: '/api/v1/customer/visit-again', query: null, label: 'visit-again'),
    (path: '/api/v1/customer/suggested-items', query: null, label: 'suggested-items'),
    (path: '/api/v1/customer/analytics/summary', query: null, label: 'analytics-summary'),
    (path: '/api/v1/customer/analytics/insights', query: null, label: 'analytics-insights'),
    (path: '/api/v1/customer/message/list', query: null, label: 'message-list'),
    (path: '/api/v1/customer/message/search-list', query: {'name': 'a'}, label: 'message-search'),
    (path: '/api/qidha-wallet/get-wallet', query: null, label: 'qidha-get-wallet'),
    (path: '/api/v1/rental/banners', query: null, label: 'rental-banners'),
    (path: '/api/v1/rental/coupon/list', query: null, label: 'rental-coupon-list'),
    (path: '/api/v1/rental/vehicle/top-rated', query: null, label: 'rental-top-rated'),
    (path: '/api/v1/rental/user/cart/get-cart', query: null, label: 'rental-cart'),
    (path: '/api/v1/rental/user/trip/get-trip-list', query: {'offset': '1', 'limit': '5'}, label: 'rental-trip-list'),
    (path: '/api/v1/rental/user/wish-list', query: null, label: 'rental-wish-list'),
    (path: '/api/v1/app/version/check', query: {'version': '3.7'}, label: 'app-version-check'),
  ];
}

Map<String, String> authHeaders(String token, {int moduleId = 3}) {
  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'X-localization': 'ar',
    'zoneId': jsonEncode(TraceConfig.defaultZoneIds),
    'latitude': jsonEncode(TraceConfig.defaultLatitude),
    'longitude': jsonEncode(TraceConfig.defaultLongitude),
    'moduleId': '$moduleId',
    'Authorization': 'Bearer $token',
  };
}

Future<void> main(List<String> args) async {
  String? token;
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--token' && i + 1 < args.length) {
      token = args[i + 1];
    }
  }
  token ??= Platform.environment['SHELLA_API_TOKEN'];
  if (token == null || token.trim().isEmpty) {
    stderr.writeln('');
    stderr.writeln('Missing token. Set environment variable SHELLA_API_TOKEN or run:');
    stderr.writeln('  dart run test/api_traffic_trace/authenticated_api_sweep.dart --token YOUR_JWT');
    stderr.writeln('');
    exitCode = 1;
    return;
  }
  token = token.trim();

  final calls = buildSweepCalls();
  final headers = authHeaders(token);
  const String base = TraceConfig.baseUrl;
  final results = <Map<String, Object?>>[];

  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║  AUTHENTICATED API SWEEP (GET)                                    ║');
  print('║  Base: $base');
  print('║  Calls: ${calls.length}');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  print('');

  for (final c in calls) {
    final uri = Uri.parse('$base${c.path}').replace(queryParameters: c.query);
    final sw = Stopwatch()..start();
    try {
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 45));
      sw.stop();
      final int code = response.statusCode;
      final bool ok = code >= 200 && code < 300;
      results.add({
        'label': c.label,
        'path': c.path,
        'status': code,
        'latency_ms': sw.elapsedMilliseconds,
        'ok': ok,
        'bytes': response.bodyBytes.length,
      });
      final String mark = ok ? '✅' : (code == 404 || code == 405 ? '⚠️' : '❌');
      print('$mark ${c.label.padRight(28)} $code  ${sw.elapsedMilliseconds}ms  ${response.bodyBytes.length}b  ${uri.path}');
    } catch (e) {
      sw.stop();
      results.add({
        'label': c.label,
        'path': c.path,
        'status': 0,
        'latency_ms': sw.elapsedMilliseconds,
        'ok': false,
        'error': e.toString(),
      });
      print('💥 ${c.label.padRight(28)} ERROR ${sw.elapsedMilliseconds}ms  $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }

  final int okCount = results.where((Map<String, Object?> r) => r['ok'] == true).length;
  final int failCount = results.length - okCount;
  final List<Map<String, Object?>> hardFails = results
      .where((Map<String, Object?> r) =>
          r['ok'] != true &&
          r['status'] != 404 &&
          r['status'] != 405 &&
          r['status'] != 304 &&
          r['error'] == null)
      .toList();
  final List<Map<String, Object?>> clientErr = results
      .where((Map<String, Object?> r) {
        final Object? s = r['status'];
        if (s is! int) {
          return false;
        }
        return s >= 400 && s < 500 && s != 404 && s != 405;
      })
      .toList();

  print('');
  print('═══════════════════════════════════════════════════════════════════');
  print('SUMMARY');
  print('═══════════════════════════════════════════════════════════════════');
  print('Total: ${results.length}  |  2xx OK: $okCount  |  Other: $failCount');
  if (clientErr.isNotEmpty) {
    print('');
    print('❌ Client errors (4xx, excluding 404/405):');
    for (final Map<String, Object?> r in clientErr) {
      print('   ${r['status']}  ${r['label']}  ${r['path']}');
    }
  }
  if (hardFails.isNotEmpty) {
    print('');
    print('⚠️ Non-2xx (includes 404/405/5xx — may be expected for wrong method or missing id):');
    for (final Map<String, Object?> r in hardFails) {
      print('   ${r['status']}  ${r['label']}');
    }
  }

  final out = File(
    'test/api_traffic_trace/auth_sweep_${DateTime.now().millisecondsSinceEpoch}.json',
  );
  await out.writeAsString(const JsonEncoder.withIndent('  ').convert(results));
  print('');
  print('📁 JSON: ${out.path}');
  print('');

  if (clientErr.isEmpty && results.every((Map<String, Object?> r) => r['error'] == null)) {
    print('✅ No hard 401/403/422-style failures in this sweep (check JSON for 404/405).');
  } else if (results.any((Map<String, Object?> r) => r['error'] != null)) {
    print('❌ Network errors occurred — see JSON.');
    exitCode = 1;
  } else if (clientErr.isNotEmpty) {
    print('❌ Some authenticated routes returned 4xx — review list above.');
    exitCode = 1;
  } else {
    print('✅ Sweep finished — all calls returned 2xx or benign 304/404/405.');
  }
}
