// ignore_for_file: avoid_print
/// Quick API Trace - writes results to file for better capture
library;

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://shellafood.com';
const defaultZoneIds = [2, 4, 3, 5];
const defaultLat = '24.604301879077966';
const defaultLng = '46.59593515098095';

final results = StringBuffer();

void log(String msg) {
  print(msg);
  results.writeln(msg);
}

Map<String, String> getHeaders({int? moduleId, String? token}) {
  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'X-localization': 'ar',
    'zoneId': jsonEncode(defaultZoneIds),
    'latitude': jsonEncode(defaultLat),
    'longitude': jsonEncode(defaultLng),
    if (moduleId != null) 'moduleId': '$moduleId',
    if (token != null) 'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };
}

Future<Map<String, dynamic>> trace(String method, String endpoint,
    {int? moduleId, String? token, Map<String, String>? query}) async {
  final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
  final headers = getHeaders(moduleId: moduleId, token: token);

  final sw = Stopwatch()..start();
  try {
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));
    sw.stop();

    return {
      'endpoint': endpoint,
      'status': response.statusCode,
      'latency_ms': sw.elapsedMilliseconds,
      'size_bytes': response.bodyBytes.length,
      'has_etag': response.headers.containsKey('etag'),
    };
  } catch (e) {
    sw.stop();
    return {
      'endpoint': endpoint,
      'status': 0,
      'latency_ms': sw.elapsedMilliseconds,
      'error': e.toString(),
    };
  }
}

void main() async {
  log('');
  log('╔═══════════════════════════════════════════════════════════════════╗');
  log('║         QUICK API TRAFFIC TRACE                                   ║');
  log('║         ${DateTime.now().toIso8601String()}                            ║');
  log('╚═══════════════════════════════════════════════════════════════════╝');
  log('');

  final allResults = <Map<String, dynamic>>[];

  // ════════════════════════════════════════════════════════════════════
  // 1. SPLASH SCREEN
  // ════════════════════════════════════════════════════════════════════
  log('═══════════════════════════════════════════════════════════════════');
  log('1. SPLASH SCREEN (The Gatekeeper)');
  log('═══════════════════════════════════════════════════════════════════');

  log('📡 /api/v1/app-init...');
  var r = await trace('GET', '/api/v1/app-init');
  allResults.add(r);
  log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

  log('📡 /api/v2/home-unified (banners,offers only)...');
  r = await trace('GET', '/api/v2/home-unified',
      moduleId: 3, query: {'include': 'banners,offers'});
  allResults.add(r);
  log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

  log('📡 /api/v1/auth/guest/request...');
  final guestUri = Uri.parse('$baseUrl/api/v1/auth/guest/request');
  final sw = Stopwatch()..start();
  try {
    final guestResp = await http.post(guestUri, headers: getHeaders());
    sw.stop();
    String? guestId;
    if (guestResp.statusCode == 200) {
      final body = jsonDecode(guestResp.body);
      guestId = body['guest_id']?.toString();
    }
    log('   Status: ${guestResp.statusCode} | Latency: ${sw.elapsedMilliseconds}ms | Guest ID: $guestId');
    allResults.add({
      'endpoint': '/api/v1/auth/guest/request',
      'status': guestResp.statusCode,
      'latency_ms': sw.elapsedMilliseconds,
      'guest_id': guestId
    });
  } catch (e) {
    sw.stop();
    log('   ERROR: $e');
    allResults.add({
      'endpoint': '/api/v1/auth/guest/request',
      'status': 0,
      'error': e.toString()
    });
  }

  log('');

  // ════════════════════════════════════════════════════════════════════
  // 2. MULTI-MODULE HOME
  // ════════════════════════════════════════════════════════════════════
  log('═══════════════════════════════════════════════════════════════════');
  log('2. MULTI-MODULE HOME (The Hub)');
  log('═══════════════════════════════════════════════════════════════════');

  log('📡 /api/v1/module...');
  r = await trace('GET', '/api/v1/module');
  allResults.add(r);
  log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

  log('');

  // ════════════════════════════════════════════════════════════════════
  // 3. MODULE-SPECIFIC HOME (Test all modules)
  // ════════════════════════════════════════════════════════════════════
  log('═══════════════════════════════════════════════════════════════════');
  log('3. MODULE-SPECIFIC HOME');
  log('═══════════════════════════════════════════════════════════════════');

  for (final mod in [
    {'id': 1, 'name': 'Food'},
    {'id': 2, 'name': 'Grocery'},
    {'id': 3, 'name': 'Ecommerce'}
  ]) {
    log('');
    log('── Module ${mod['id']}: ${mod['name']} ──');

    log('📡 /api/v2/home-unified (module ${mod['id']})...');
    r = await trace('GET', '/api/v2/home-unified', moduleId: mod['id'] as int);
    allResults.add(r);
    log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

    log('📡 /api/v1/stores/get-stores/all (module ${mod['id']})...');
    r = await trace('GET', '/api/v1/stores/get-stores/all',
        moduleId: mod['id'] as int,
        query: {'store_type': 'all', 'offset': '1', 'limit': '12'});
    allResults.add(r);
    log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

    log('📡 /api/v1/items/latest (module ${mod['id']})...');
    r = await trace('GET', '/api/v1/items/latest',
        moduleId: mod['id'] as int,
        query: {'offset': '1', 'limit': '12', 'type': 'all'});
    allResults.add(r);
    log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');
  }

  log('');

  // ════════════════════════════════════════════════════════════════════
  // 4. STORE DETAILS (THE BOTTLENECK)
  // ════════════════════════════════════════════════════════════════════
  log('═══════════════════════════════════════════════════════════════════');
  log('4. STORE DETAILS (The Bottleneck) ⚠️');
  log('═══════════════════════════════════════════════════════════════════');

  for (final storeId in [1, 2, 3]) {
    log('');
    log('── Store $storeId ──');

    log('📡 /api/v1/stores/details/$storeId... ⏱️');
    r = await trace('GET', '/api/v1/stores/details/$storeId', moduleId: 3);
    allResults.add(r);
    final latency = r['latency_ms'] as int;
    final latencyStatus = latency > 4000
        ? '❌ STILL 4.4s!'
        : (latency > 2000 ? '⚠️ SLOW' : '✅ OK');
    log('   Status: ${r['status']} | Latency: ${latency}ms $latencyStatus | Size: ${r['size_bytes']} bytes');

    log('📡 /api/v1/items/latest?store_id=$storeId...');
    r = await trace('GET', '/api/v1/items/latest', moduleId: 3, query: {
      'store_id': '$storeId',
      'offset': '1',
      'limit': '20',
      'type': 'all'
    });
    allResults.add(r);
    log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');
  }

  log('');

  // ════════════════════════════════════════════════════════════════════
  // 5. CART & CHECKOUT
  // ════════════════════════════════════════════════════════════════════
  log('═══════════════════════════════════════════════════════════════════');
  log('5. CART & CHECKOUT (The Money)');
  log('═══════════════════════════════════════════════════════════════════');

  log('📡 /api/v1/customer/cart/list...');
  r = await trace('GET', '/api/v1/customer/cart/list', moduleId: 3);
  allResults.add(r);
  log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

  log('📡 /api/v1/coupon/list...');
  r = await trace('GET', '/api/v1/coupon/list', moduleId: 3);
  allResults.add(r);
  log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

  log('📡 /api/v2/checkout/store-summary/1...');
  r = await trace('GET', '/api/v2/checkout/store-summary/1', moduleId: 3);
  allResults.add(r);
  log('   Status: ${r['status']} | Latency: ${r['latency_ms']}ms | Size: ${r['size_bytes']} bytes');

  log('');

  // ════════════════════════════════════════════════════════════════════
  // SUMMARY
  // ════════════════════════════════════════════════════════════════════
  log('╔═══════════════════════════════════════════════════════════════════╗');
  log('║                        SUMMARY REPORT                             ║');
  log('╚═══════════════════════════════════════════════════════════════════╝');
  log('');

  final int totalCalls = allResults.length;
  final int totalLatency =
      allResults.fold(0, (sum, r) => sum + ((r['latency_ms'] as int?) ?? 0));
  final int totalSize =
      allResults.fold(0, (sum, r) => sum + ((r['size_bytes'] as int?) ?? 0));
  final int errors =
      allResults.where((r) => (r['status'] as int?) != 200).length;
  final bottlenecks =
      allResults.where((r) => ((r['latency_ms'] as int?) ?? 0) > 2000).toList();

  log('📊 METRICS:');
  log('   Total API Calls:     $totalCalls');
  log('   Total Latency:       ${totalLatency}ms');
  log('   Total Data Transfer: ${(totalSize / 1024).toStringAsFixed(1)} KB');
  log('   Errors:              $errors');
  log('');

  if (bottlenecks.isNotEmpty) {
    log('⚠️ BOTTLENECKS (>2000ms):');
    for (final b in bottlenecks) {
      log('   🐢 ${b['endpoint']}: ${b['latency_ms']}ms');
    }
    log('');
  }

  final errorCalls = allResults
      .where((r) => (r['status'] as int?) != 200 && (r['status'] as int?) != 0)
      .toList();
  if (errorCalls.isNotEmpty) {
    log('❌ ERRORS:');
    for (final e in errorCalls) {
      log('   ⚠️ ${e['endpoint']}: Status ${e['status']}');
    }
    log('');
  }

  log('═══════════════════════════════════════════════════════════════════');
  log('');

  // Write results to file
  final file = File(
      'test/api_traffic_trace/trace_report_${DateTime.now().millisecondsSinceEpoch}.txt');
  await file.writeAsString(results.toString());
  log('📁 Report saved to: ${file.path}');

  // Also write JSON
  final jsonFile = File(
      'test/api_traffic_trace/trace_results_${DateTime.now().millisecondsSinceEpoch}.json');
  await jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert({
    'timestamp': DateTime.now().toIso8601String(),
    'summary': {
      'total_calls': totalCalls,
      'total_latency_ms': totalLatency,
      'total_size_bytes': totalSize,
      'errors': errors,
    },
    'results': allResults,
  }));
  log('📁 JSON saved to: ${jsonFile.path}');
}
