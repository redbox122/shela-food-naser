/*
 * Secure HTTP Client Service
 * 
 * This file provides a secure HTTP client implementation using Dio for the Indian Shella App.
 * It implements enhanced security features including request/response validation,
 * secure headers, and certificate validation.
 * 
 * Features:
 * - Dio HTTP client with enhanced security
 * - Request/response validation
 * - Secure header management
 * - Certificate validation
 * - Rate limiting and abuse prevention
 * - Request/response integrity checks
 */

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'certificate_pinning_service.dart';
import 'certificate_pinning.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/etag_scope_key_builder.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Secure HTTP Client Service using Dio
/// Provides enhanced security for API communication
class SecureHttpClient {
  late final Dio _dio;
  final String _baseUrl;
  final Map<String, dynamic> _defaultHeaders;

  // Security configuration
  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = 100;

  // Rate limiting
  final Map<String, List<DateTime>> _requestTimestamps = {};

  /// Initialize secure HTTP client
  /// [baseUrl] - Base URL for API calls
  /// [defaultHeaders] - Default headers to include in all requests
  SecureHttpClient({
    required String baseUrl,
    Map<String, dynamic>? defaultHeaders,
  })  : _baseUrl = baseUrl,
        _defaultHeaders = defaultHeaders ?? {} {
    _initializeDio();
  }

  /// Initialize Dio with security features
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _requestTimeout,
      receiveTimeout: _requestTimeout,
      sendTimeout: _requestTimeout,
      headers: _defaultHeaders,
      // ⚡ ETAG SUPPORT: Allow 304 status code as valid response
      validateStatus: (status) {
        return status != null &&
            (status >= 200 && status < 300 || status == 304);
      },
    ));

    // Configure security features
    CertificatePinningService.configureDioWithSecurity(_dio, _baseUrl);

    // Pin this client to our CA chain (no-op while the flag is OFF / on web).
    CertificatePinning.apply(_dio);

    // Add security interceptors
    _addSecurityInterceptors();

    if (kDebugMode) {
      debugPrint('🔒 Secure HTTP Client initialized for $_baseUrl');
    }
  }

  /// Add security interceptors to Dio
  void _addSecurityInterceptors() {
    // Request interceptor for validation and rate limiting
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final String requestId =
                (options.headers['X-Request-ID']?.toString() ??
                    _generateRequestId());
            final bool isItemsLatest =
                options.path.contains('/api/v1/items/latest');
            if (kDebugMode && isItemsLatest) {
              appLogger.debug(
                  '🔒 SECURE onRequest | requestId=$requestId | path=${options.path} | connectTimeout=${_dio.options.connectTimeout?.inSeconds}s | receiveTimeout=${_dio.options.receiveTimeout?.inSeconds}s');
            }

            // Check rate limiting
            if (!_checkRateLimit(options.path)) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Rate limit exceeded',
                  type: DioExceptionType.connectionTimeout,
                ),
              );
            }

            // Add security headers
            _addSecurityHeaders(options);

            // Validate request data
            if (!_validateRequestData(options)) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Invalid request data',
                  type: DioExceptionType.badResponse,
                ),
              );
            }

            // Add request integrity check
            _addRequestIntegrity(options);

            // ⚡ TASK 4: ETag Interceptor - Add If-None-Match header if missing
            await _addEtagHeader(options);

            handler.next(options);
          } catch (e) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Request validation failed: $e',
              ),
            );
          }
        },
        onResponse: (response, handler) async {
          try {
            final String requestId =
                (response.requestOptions.headers['X-Request-ID']?.toString() ??
                    _generateRequestId());
            final bool isItemsLatest =
                response.requestOptions.path.contains('/api/v1/items/latest');
            if (kDebugMode && isItemsLatest) {
              final backendTime =
                  response.headers.value('X-Items-Latest-Backend-Time') ??
                      response.headers.value('x-items-latest-backend-time');
              final cacheHeader =
                  response.headers.value('X-Items-Latest-Cache') ??
                      response.headers.value('x-items-latest-cache');
              final backendRequestId =
                  response.headers.value('X-Items-Latest-Request-Id') ??
                      response.headers.value('x-items-latest-request-id');
              appLogger.debug(
                  '🔒 SECURE onResponse | requestId=$requestId | path=${response.requestOptions.path} | status=${response.statusCode} | backendTime=${backendTime ?? 'n/a'} | cache=${cacheHeader ?? 'n/a'} | backendRequestId=${backendRequestId ?? 'n/a'}');
            }

            // Validate response integrity
            if (!_validateResponseIntegrity(response)) {
              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  error: 'Response integrity check failed',
                  type: DioExceptionType.badResponse,
                ),
              );
            }

            // ⚡ ZERO-LATENCY CDN: Handle 304 Not Modified immediately
            // Cloudflare will catch server's 304 and serve it in <20ms
            // We must use local Hive cache immediately for zero-lag transition
            if (response.statusCode == 304) {
              if (kDebugMode) {
                debugPrint(
                    '⚡ SecureHttpClient: 304 Not Modified received - Cloudflare served in <20ms');
                debugPrint('   - Path: ${response.requestOptions.path}');
                debugPrint(
                    '   - Using local Hive cache immediately for zero-lag transition');
              }

              // 304 response is valid - pass it through to ApiClient
              // ApiClient will handle loading from Hive cache
              handler.next(response);
              return;
            }

            // Validate response data (skip for 304 as it has no body)
            if (!_validateResponseData(response)) {
              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  error: 'Invalid response data',
                  type: DioExceptionType.badResponse,
                ),
              );
            }

            // ⚡ TASK 4: ETag Interceptor - Extract and store ETag from response
            await _handleEtagResponse(response);

            handler.next(response);
          } catch (e) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: 'Response validation failed: $e',
              ),
            );
          }
        },
        onError: (error, handler) async {
          try {
            final String requestId =
                (error.requestOptions.headers['X-Request-ID']?.toString() ??
                    _generateRequestId());
            final bool isItemsLatest =
                error.requestOptions.path.contains('/api/v1/items/latest');
            if (kDebugMode && isItemsLatest) {
              appLogger.error(
                  '🔒 SECURE onError | requestId=$requestId | path=${error.requestOptions.path} | type=${error.type} | status=${error.response?.statusCode} | message=${error.message}');
            }

            // Handle specific error types
            if (error.type == DioExceptionType.connectionTimeout) {
              // Retry logic for timeout errors
              if (_shouldRetry(error.requestOptions)) {
                return handler.resolve(await _retryRequest(error));
              }
            }

            // Downgrade the scary error log for the known place-order case:
            // the backend intentionally returns a non-2xx (e.g. 403) for a
            // payment_pending/unpaid digital order, but the body still carries a
            // usable order_id (often with duplicate_prevented=true). Dio's
            // validateStatus treats that as an exception, yet createOrder()
            // handles it as a valid pending order. So log it as info, not an
            // error — without hiding genuine failures that have no usable id.
            if (kDebugMode) {
              if (_isUsablePendingOrderError(error)) {
                debugPrint(
                    'ℹ️ place-order returned ${error.response?.statusCode} with a usable pending order_id — handled by createOrder(), not a failure');
              } else {
                debugPrint('❌ HTTP Error: ${error.message}');
                debugPrint('❌ Error Type: ${error.type}');
                debugPrint('❌ Status Code: ${error.response?.statusCode}');
              }
            }

            handler.next(error);
          } catch (e) {
            handler.next(error);
          }
        },
      ),
    );
  }

  /// Whether a Dio error is the benign "place-order returned a usable pending
  /// order" case that createOrder() handles successfully.
  ///
  /// True only when ALL of the following hold:
  ///  - the request targets POST /api/v1/customer/order/place,
  ///  - the response body is a map containing a non-empty order id, AND
  ///  - the body signals duplicate_prevented=true OR a payment_pending /
  ///    unpaid state.
  ///
  /// Returns false for any genuine failure (no usable order id), so real
  /// errors are still logged normally.
  bool _isUsablePendingOrderError(DioException error) {
    try {
      final RequestOptions options = error.requestOptions;
      if (options.method.toUpperCase() != 'POST') {
        return false;
      }
      if (!options.path.contains(AppConstants.placeOrderUri)) {
        return false;
      }

      final dynamic rawBody = error.response?.data;
      Map<String, dynamic>? body;
      if (rawBody is Map<String, dynamic>) {
        body = rawBody;
      } else if (rawBody is String && rawBody.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      }
      if (body == null) {
        return false;
      }

      final String orderId =
          (body['order_id'] ?? body['orderId'] ?? body['id'] ?? '')
              .toString()
              .trim();
      if (orderId.isEmpty) {
        return false;
      }

      final bool duplicatePrevented = body['duplicate_prevented'] == true;
      final String statusStr =
          (body['status'] ?? body['order_status'] ?? '')
              .toString()
              .toLowerCase();
      final String paymentStatusStr =
          (body['payment_status'] ?? '').toString().toLowerCase();
      final bool isPendingPayment =
          statusStr == 'payment_pending' || paymentStatusStr == 'unpaid';

      return duplicatePrevented || isPendingPayment;
    } catch (_) {
      // Any parsing issue → treat as a normal error and log it.
      return false;
    }
  }

  /// Check rate limiting for requests
  /// [path] - Request path
  /// Returns true if request is allowed
  bool _checkRateLimit(String path) {
    final now = DateTime.now();
    final windowStart = now.subtract(_rateLimitWindow);

    if (!_requestTimestamps.containsKey(path)) {
      _requestTimestamps[path] = [];
    }

    // Remove old timestamps
    _requestTimestamps[path]!
        .removeWhere((timestamp) => timestamp.isBefore(windowStart));

    // Check if limit exceeded
    if (_requestTimestamps[path]!.length >= _maxRequestsPerWindow) {
      if (kDebugMode) {
        debugPrint('⚠️ Rate limit exceeded for $path');
      }
      return false;
    }

    // Add current timestamp
    _requestTimestamps[path]!.add(now);
    return true;
  }

  /// Add security headers to request
  /// [options] - Request options
  void _addSecurityHeaders(RequestOptions options) {
    final headers = options.headers;

    // ⚠️ WEB FIX: بعض الـ headers تسبب مشاكل CORS على الويب
    // نضيف فقط الـ headers الآمنة التي لا تسبب مشاكل CORS
    if (!kIsWeb) {
      // على الموبايل، نضيف كل الـ headers
      headers['X-Requested-With'] = 'XMLHttpRequest';
      headers['X-Frame-Options'] = 'DENY';
      headers['X-XSS-Protection'] = '1; mode=block';
      headers['Strict-Transport-Security'] =
          'max-age=31536000; includeSubDomains';
    }

    // الـ headers الآمنة على جميع المنصات (لا تسبب مشاكل CORS)
    headers['X-Content-Type-Options'] = 'nosniff';

    // Custom security headers (آمنة على جميع المنصات)
    headers['X-App-Version'] = '3.1.8';
    if (kIsWeb) {
      headers['X-Platform'] = 'web';
    } else {
      headers['X-Platform'] = (!kIsWeb && Platform.isAndroid) ? 'android' : 'ios';
    }
    headers['X-Request-ID'] = _generateRequestId();
  }

  /// Validate request data
  /// [options] - Request options
  /// Returns true if data is valid
  bool _validateRequestData(RequestOptions options) {
    try {
      // Check for malicious content in headers
      for (final entry in options.headers.entries) {
        if (_containsMaliciousContent(entry.value.toString())) {
          if (kDebugMode) {
            debugPrint('❌ Malicious content detected in header: ${entry.key}');
          }
          return false;
        }
      }

      // Check for malicious content in data
      if (options.data != null) {
        if (_containsMaliciousContent(options.data.toString())) {
          if (kDebugMode) {
            debugPrint('❌ Malicious content detected in request data');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Request data validation failed: $e');
      }
      return false;
    }
  }

  /// Add request integrity check
  /// [options] - Request options
  void _addRequestIntegrity(RequestOptions options) {
    try {
      final data = options.data?.toString() ?? '';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Create integrity hash
      final integrity = _calculateIntegrity(data + timestamp);

      // Add integrity headers
      options.headers['X-Request-Timestamp'] = timestamp;
      options.headers['X-Request-Integrity'] = integrity;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to add request integrity: $e');
      }
    }
  }

  /// Validate response integrity
  /// [response] - Response object
  /// Returns true if integrity check passes
  bool _validateResponseIntegrity(Response response) {
    try {
      final headers = response.headers;
      final timestamp = headers.value('X-Response-Timestamp');
      final integrity = headers.value('X-Response-Integrity');

      if (timestamp == null || integrity == null) {
        // Skip validation if headers not present
        return true;
      }

      final data = response.data?.toString() ?? '';
      final expectedIntegrity = _calculateIntegrity(data + timestamp);

      return integrity == expectedIntegrity;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Response integrity validation failed: $e');
      }
      return false;
    }
  }

  /// Validate response data
  /// [response] - Response object
  /// Returns true if data is valid
  bool _validateResponseData(Response response) {
    try {
      // Check for malicious content in response
      if (response.data != null) {
        if (_containsMaliciousContent(response.data.toString())) {
          if (kDebugMode) {
            debugPrint('❌ Malicious content detected in response data');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Response data validation failed: $e');
      }
      return false;
    }
  }

  /// Check if content contains malicious patterns
  /// [content] - Content to check
  /// Returns true if malicious content detected
  bool _containsMaliciousContent(String content) {
    final maliciousPatterns = [
      '<script',
      'javascript:',
      'data:text/html',
      'vbscript:',
      'onload=',
      'onerror=',
      'onclick=',
      'eval(',
      'document.cookie',
      'window.location',
    ];

    final lowerContent = content.toLowerCase();
    return maliciousPatterns.any((pattern) => lowerContent.contains(pattern));
  }

  /// Calculate integrity hash
  /// [data] - Data to hash
  /// Returns SHA-256 hash in base64 format
  String _calculateIntegrity(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return base64.encode(hash.bytes);
  }

  /// Generate unique request ID
  /// Returns request ID string
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'req_${random}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Check if request should be retried
  /// [options] - Request options
  /// Returns true if retry should be attempted
  bool _shouldRetry(RequestOptions options) {
    final String noRetryHeader =
        options.headers['X-No-Retry']?.toString().toLowerCase() ?? 'false';
    if (noRetryHeader == 'true') {
      if (kDebugMode) {
        debugPrint(
            '⏭️ SecureHttpClient: retry disabled by header for ${options.path}');
      }
      return false;
    }

    final int retryCount = options.extra['retryCount'] is int
        ? options.extra['retryCount'] as int
        : 0;

    return retryCount < _maxRetries;
  }

  /// Retry failed request
  /// [e] - Original Dio exception
  /// Returns response from retry attempt
  Future<Response> _retryRequest(DioException e) async {
    final RequestOptions options = e.requestOptions;
    final int previousRetry = options.extra['retryCount'] is int
        ? options.extra['retryCount'] as int
        : 0;

    final int retryCount = previousRetry + 1;
    options.extra['retryCount'] = retryCount;

    if (kDebugMode) {
      debugPrint('?? Retrying request (attempt $retryCount): ${options.path}');
      debugPrint('   ? Error type: ${e.type}');
      debugPrint(
          '   ?? Timeout after: ${e.requestOptions.connectTimeout?.inMilliseconds}ms');
      debugPrint('   ?? Status code: ${e.response?.statusCode}');
      debugPrint('   ?? Message: ${e.message}');
    }

    // Wait before retry
    await Future<void>.delayed(Duration(seconds: retryCount));

    return _dio.fetch(options);
  }

  /// Get Dio instance
  Dio get dio => _dio;

  /// Get base URL
  String get baseUrl => _baseUrl;

  /// Get security status
  Map<String, dynamic> getSecurityStatus() {
    return {
      'baseUrl': _baseUrl,
      'isInitialized': true,
      'maxRetries': _maxRetries,
      'requestTimeout': _requestTimeout.inSeconds,
      'rateLimitWindow': _rateLimitWindow.inMinutes,
      'maxRequestsPerWindow': _maxRequestsPerWindow,
      'activeRequests': _requestTimestamps.values
          .fold(0, (sum, timestamps) => sum + timestamps.length),
    };
  }

  /// Test security features
  /// Returns true if all tests pass
  Future<bool> testSecurityFeatures() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing Security Features...');
      }

      // Test rate limiting
      final rateLimitTest = _testRateLimiting();
      if (!rateLimitTest) {
        if (kDebugMode) {
          debugPrint('❌ Rate limiting test failed');
        }
        return false;
      }

      // Test certificate validation
      final certTest = await _testCertificateValidation();
      if (!certTest) {
        if (kDebugMode) {
          debugPrint('❌ Certificate validation test failed');
        }
        return false;
      }

      if (kDebugMode) {
        debugPrint('✅ All security tests passed');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Security test failed: $e');
      }
      return false;
    }
  }

  /// Test rate limiting functionality
  /// Returns true if test passes
  bool _testRateLimiting() {
    try {
      const testPath = '/test_rate_limit';

      // Clear test data
      _requestTimestamps.remove(testPath);

      // Test normal requests
      for (int i = 0; i < _maxRequestsPerWindow; i++) {
        if (!_checkRateLimit(testPath)) {
          return false;
        }
      }

      // Test rate limit exceeded
      if (_checkRateLimit(testPath)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test certificate validation
  /// Returns true if test passes
  Future<bool> _testCertificateValidation() async {
    try {
      final uri = Uri.parse(_baseUrl);
      return await CertificatePinningService.validateServerCertificate(
          uri.host, uri.port);
    } catch (e) {
      return false;
    }
  }

  /// ⚡ TASK 4: Add ETag header to request if available
  /// Checks Hive app_config box for stored ETag and adds If-None-Match header
  Future<void> _addEtagHeader(RequestOptions options) async {
    try {
      // ETag conditional requests are only valid for safe read operations.
      // Never attach If-None-Match to mutations (POST/PUT/PATCH/DELETE).
      final method = options.method.toUpperCase();
      if (method != 'GET') {
        return;
      }

      // Coupon apply must never use conditional GET (304 + empty body breaks apply flow).
      if (_isCouponApplyRequest(options)) {
        return;
      }

      // Respect per-request ETag disable flag
      if (_isEtagDisabled(options.headers) || _isHtmlCmsPath(options.path)) {
        return;
      }
      // Check if If-None-Match header already exists (don't override)
      if (options.headers.containsKey('If-None-Match')) {
        return;
      }

      // Build URI for ETag lookup
      final uri = options.uri.toString();
      final scopedUri =
          EtagScopeKeyBuilder.buildScopedUri(uri, headers: options.headers);

      // Get ETag from Hive app_config box
      final cacheService = HiveHomeCacheService();
      final storedEtag = await cacheService.getEtag(scopedUri);

      if (storedEtag != null) {
        options.headers['If-None-Match'] = storedEtag;
        if (kDebugMode) {
          debugPrint(
              '📤 SecureHttpClient: Added If-None-Match header: ${storedEtag.safeSubstring(20)}');
        }
      }
    } catch (e) {
      // Silently fail - ETag is optional
      if (kDebugMode) {
        debugPrint('⚠️ SecureHttpClient: Error adding ETag header: $e');
      }
    }
  }

  /// ⚡ TASK 4: Handle ETag from response
  /// Extracts ETag from response headers and stores in Hive app_config box
  Future<void> _handleEtagResponse(Response response) async {
    try {
      // Persist ETags only for GET responses.
      final method = response.requestOptions.method.toUpperCase();
      if (method != 'GET') {
        return;
      }

      if (_isCouponApplyRequest(response.requestOptions)) {
        return;
      }

      // Respect per-request ETag disable flag
      if (_isEtagDisabled(response.requestOptions.headers) ||
          _isHtmlCmsPath(response.requestOptions.path)) {
        return;
      }
      // Only store ETag for 200 OK responses
      if (response.statusCode != 200) {
        return;
      }

      // Extract ETag from response headers
      final etag =
          response.headers.value('etag') ?? response.headers.value('ETag');

      if (etag != null) {
        // Build URI for ETag storage
        final uri = response.requestOptions.uri.toString();
        final scopedUri = EtagScopeKeyBuilder.buildScopedUri(uri,
            headers: response.requestOptions.headers);

        // Store ETag in Hive app_config box
        final cacheService = HiveHomeCacheService();
        await cacheService.saveEtag(scopedUri, etag);

        if (kDebugMode) {
          debugPrint(
              '💾 SecureHttpClient: Stored ETag for $scopedUri: ${etag.safeSubstring(20)}');
        }
      }
    } catch (e) {
      // Silently fail - ETag storage is optional
      if (kDebugMode) {
        debugPrint('⚠️ SecureHttpClient: Error handling ETag response: $e');
      }
    }
  }

  bool _isEtagDisabled(Map<String, dynamic> headers) {
    final value = headers['X-Disable-ETag'] ?? headers['x-disable-etag'];
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  bool _isHtmlCmsPath(String path) {
    return path.contains('/api/v1/about-us') ||
        path.contains('/api/v1/terms-and-conditions') ||
        path.contains('/api/v1/privacy-policy') ||
        path.contains('/api/v1/shipping-policy') ||
        path.contains('/api/v1/refund-policy') ||
        path.contains('/api/v1/cancellation-policy');
  }

  bool _isCouponApplyRequest(RequestOptions options) {
    final String path = options.uri.path;
    return path.contains('/api/v1/coupon/apply');
  }
}
