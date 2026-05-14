// ignore_for_file: avoid_print
/// API Traffic Tracer
///
/// Core class for tracing live API traffic during session tests.
/// Records endpoints, latency, cache status, and response details.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Configuration for different environments
class TraceConfig {
  static const String baseUrl = 'https://shellafood.com';

  // Module IDs from the app
  static const int foodModuleId = 1;
  static const int ecommerceModuleId = 3;
  static const int groceryModuleId = 2;
  static const int pharmacyModuleId = 4;

  // Test user token (User 431)
  static String? userToken;

  // Guest ID for guest session
  static String? guestId;

  // Default zone IDs (Riyadh)
  static const List<int> defaultZoneIds = [2, 4, 3, 5];

  // Default coordinates (Riyadh)
  static const String defaultLatitude = '24.604301879077966';
  static const String defaultLongitude = '46.59593515098095';
}

/// API Call Result
class ApiTraceResult {
  final String endpoint;
  final String method;
  final int statusCode;
  final int latencyMs;
  final String cacheStatus; // HIT, MISS, 304_LOOP, ERROR
  final Map<String, dynamic>? responseBody;
  final Map<String, String>? responseHeaders;
  final String? errorMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, dynamic>? queryParams;

  ApiTraceResult({
    required this.endpoint,
    required this.method,
    required this.statusCode,
    required this.latencyMs,
    required this.cacheStatus,
    this.responseBody,
    this.responseHeaders,
    this.errorMessage,
    required this.timestamp,
    this.requestHeaders,
    this.queryParams,
  });

  Map<String, dynamic> toJson() => {
        'endpoint': endpoint,
        'method': method,
        'statusCode': statusCode,
        'latencyMs': latencyMs,
        'cacheStatus': cacheStatus,
        'errorMessage': errorMessage,
        'timestamp': timestamp.toIso8601String(),
        'queryParams': queryParams,
      };

  @override
  String toString() {
    return '''
┌─────────────────────────────────────────────────────────────────
│ ENDPOINT: $endpoint
│ METHOD: $method
│ STATUS: $statusCode | LATENCY: ${latencyMs}ms | CACHE: $cacheStatus
│ TIME: $timestamp
${errorMessage != null ? '│ ERROR: $errorMessage\n' : ''}└─────────────────────────────────────────────────────────────────''';
  }
}

/// Screen Trace Report
class ScreenTraceReport {
  final String screenName;
  final String description;
  final List<ApiTraceResult> apiCalls;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> logicChecks;

  ScreenTraceReport({
    required this.screenName,
    required this.description,
    required this.apiCalls,
    required this.startTime,
    required this.endTime,
    required this.logicChecks,
  });

  int get totalLatencyMs =>
      apiCalls.fold(0, (sum, call) => sum + call.latencyMs);
  int get cacheHits => apiCalls.where((c) => c.cacheStatus == 'HIT').length;
  int get cacheMisses => apiCalls.where((c) => c.cacheStatus == 'MISS').length;
  int get errors => apiCalls.where((c) => c.statusCode >= 400).length;

  String toReport() {
    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln(
        '═══════════════════════════════════════════════════════════════════');
    buffer.writeln('📱 $screenName');
    buffer.writeln('   $description');
    buffer.writeln(
        '═══════════════════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('📊 SUMMARY:');
    buffer.writeln('   - Total API Calls: ${apiCalls.length}');
    buffer.writeln('   - Total Latency: ${totalLatencyMs}ms');
    buffer.writeln('   - Cache Hits: $cacheHits | Misses: $cacheMisses');
    buffer.writeln('   - Errors: $errors');
    buffer.writeln(
        '   - Duration: ${endTime.difference(startTime).inMilliseconds}ms');
    buffer.writeln();
    buffer.writeln('📡 ENDPOINTS CALLED:');
    for (final call in apiCalls) {
      final icon = call.statusCode >= 400
          ? '❌'
          : (call.cacheStatus == 'HIT' ? '✅' : '🔄');
      buffer.writeln('   $icon ${call.method} ${call.endpoint}');
      buffer.writeln(
          '      └─ Status: ${call.statusCode} | Latency: ${call.latencyMs}ms | Cache: ${call.cacheStatus}');
    }
    buffer.writeln();
    buffer.writeln('🔍 LOGIC CHECKS:');
    logicChecks.forEach((key, value) {
      final icon = value == true || value == 'PASS'
          ? '✅'
          : (value == false || value == 'FAIL' ? '❌' : '⚠️');
      buffer.writeln('   $icon $key: $value');
    });
    buffer.writeln();
    return buffer.toString();
  }
}

/// API Traffic Tracer
class ApiTrafficTracer {
  final http.Client _client = http.Client();
  final List<ApiTraceResult> _allResults = [];

  // ETag storage for 304 detection
  final Map<String, String> _etagCache = {};
  int _304LoopCount = 0;

  /// Get default headers for API calls
  Map<String, String> getDefaultHeaders({
    int? moduleId,
    List<int>? zoneIds,
    String? token,
    String? guestId,
  }) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-localization': 'ar',
      'zoneId': jsonEncode(zoneIds ?? TraceConfig.defaultZoneIds),
      'latitude': jsonEncode(TraceConfig.defaultLatitude),
      'longitude': jsonEncode(TraceConfig.defaultLongitude),
      if (moduleId != null) 'moduleId': '$moduleId',
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// Trace a GET request
  Future<ApiTraceResult> traceGet(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool useEtag = true,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final requestHeaders = headers ?? getDefaultHeaders();

    // Add ETag if available
    if (useEtag && _etagCache.containsKey(endpoint)) {
      requestHeaders['If-None-Match'] = _etagCache[endpoint]!;
    }

    final stopwatch = Stopwatch()..start();
    final timestamp = DateTime.now();

    try {
      final response = await _client.get(uri, headers: requestHeaders);
      stopwatch.stop();

      // Store ETag from response
      final etag = response.headers['etag'];
      if (etag != null && useEtag) {
        _etagCache[endpoint] = etag;
      }

      // Detect 304 loop
      String cacheStatus = 'MISS';
      if (response.statusCode == 304) {
        _304LoopCount++;
        if (_304LoopCount > 3) {
          cacheStatus = '304_LOOP';
        } else {
          cacheStatus = 'HIT';
        }
      } else if (response.statusCode == 200) {
        _304LoopCount = 0; // Reset loop counter
        cacheStatus = 'MISS';
      }

      // Parse response body
      Map<String, dynamic>? responseBody;
      try {
        if (response.body.isNotEmpty && response.statusCode != 304) {
          responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
        }
      } catch (_) {}

      final result = ApiTraceResult(
        endpoint: endpoint,
        method: 'GET',
        statusCode: response.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
        cacheStatus: cacheStatus,
        responseBody: responseBody,
        responseHeaders: response.headers,
        timestamp: timestamp,
        requestHeaders: requestHeaders,
        queryParams: queryParams,
      );

      _allResults.add(result);
      return result;
    } catch (e) {
      stopwatch.stop();

      final result = ApiTraceResult(
        endpoint: endpoint,
        method: 'GET',
        statusCode: 0,
        latencyMs: stopwatch.elapsedMilliseconds,
        cacheStatus: 'ERROR',
        errorMessage: e.toString(),
        timestamp: timestamp,
        requestHeaders: requestHeaders,
        queryParams: queryParams,
      );

      _allResults.add(result);
      return result;
    }
  }

  /// Trace a POST request
  Future<ApiTraceResult> tracePost(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${TraceConfig.baseUrl}$endpoint');
    final requestHeaders = headers ?? getDefaultHeaders();

    final stopwatch = Stopwatch()..start();
    final timestamp = DateTime.now();

    try {
      final response = await _client.post(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      stopwatch.stop();

      Map<String, dynamic>? responseBody;
      try {
        if (response.body.isNotEmpty) {
          responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
        }
      } catch (_) {}

      final result = ApiTraceResult(
        endpoint: endpoint,
        method: 'POST',
        statusCode: response.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
        cacheStatus: 'N/A',
        responseBody: responseBody,
        responseHeaders: response.headers,
        timestamp: timestamp,
        requestHeaders: requestHeaders,
      );

      _allResults.add(result);
      return result;
    } catch (e) {
      stopwatch.stop();

      final result = ApiTraceResult(
        endpoint: endpoint,
        method: 'POST',
        statusCode: 0,
        latencyMs: stopwatch.elapsedMilliseconds,
        cacheStatus: 'ERROR',
        errorMessage: e.toString(),
        timestamp: timestamp,
        requestHeaders: requestHeaders,
      );

      _allResults.add(result);
      return result;
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final baseUri = Uri.parse('${TraceConfig.baseUrl}$endpoint');
    if (queryParams == null || queryParams.isEmpty) {
      return baseUri;
    }
    return baseUri.replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
  }

  /// Get all traced results
  List<ApiTraceResult> get allResults => List.unmodifiable(_allResults);

  /// Clear all results
  void clearResults() {
    _allResults.clear();
    _etagCache.clear();
    _304LoopCount = 0;
  }

  /// Generate full session report
  String generateFullReport(List<ScreenTraceReport> screens) {
    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln(
        '╔═══════════════════════════════════════════════════════════════════╗');
    buffer.writeln(
        '║          API TRAFFIC TRACE - FULL SESSION REPORT                  ║');
    buffer.writeln(
        '║          Generated: ${DateTime.now().toIso8601String()}                ║');
    buffer.writeln(
        '╚═══════════════════════════════════════════════════════════════════╝');
    buffer.writeln();

    int totalCalls = 0;
    int totalLatency = 0;
    int totalErrors = 0;

    for (final screen in screens) {
      buffer.write(screen.toReport());
      totalCalls += screen.apiCalls.length;
      totalLatency += screen.totalLatencyMs;
      totalErrors += screen.errors;
    }

    buffer.writeln();
    buffer.writeln(
        '═══════════════════════════════════════════════════════════════════');
    buffer.writeln('📊 SESSION TOTALS');
    buffer.writeln(
        '═══════════════════════════════════════════════════════════════════');
    buffer.writeln('   Total API Calls: $totalCalls');
    buffer.writeln('   Total Latency: ${totalLatency}ms');
    buffer.writeln('   Total Errors: $totalErrors');
    buffer.writeln(
        '═══════════════════════════════════════════════════════════════════');

    return buffer.toString();
  }

  /// Export results to JSON
  Future<void> exportToJson(String filePath) async {
    final file = File(filePath);
    final json = jsonEncode({
      'generatedAt': DateTime.now().toIso8601String(),
      'results': _allResults.map((r) => r.toJson()).toList(),
    });
    await file.writeAsString(json);
    print('📁 Exported to: $filePath');
  }

  void dispose() {
    _client.close();
  }
}

/// Test Utilities
class TraceTestUtils {
  /// Get a guest ID for testing
  static Future<String?> getGuestId(ApiTrafficTracer tracer) async {
    final result = await tracer.tracePost('/api/v1/auth/guest/request');
    if (result.statusCode == 200 && result.responseBody != null) {
      return result.responseBody!['guest_id']?.toString();
    }
    return null;
  }

  /// Helper to print a divider
  static void printDivider() {
    print('─' * 70);
  }

  /// Helper to print a section header
  static void printSection(String title) {
    print('');
    print('┌${'─' * 68}┐');
    print('│ $title${' ' * (67 - title.length)}│');
    print('└${'─' * 68}┘');
  }
}
