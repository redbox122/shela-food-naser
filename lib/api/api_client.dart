import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/common/models/error_response.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/security/secure_token_storage.dart';
import 'package:sixam_mart/common/security/certificate_pinning_service.dart';
import 'package:sixam_mart/common/security/secure_http_client.dart';
import 'package:sixam_mart/common/security/certificate_pinning.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:sixam_mart/util/environment_config.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/utils/secure_log.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/etag_scope_key_builder.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';

bool _responseIndicatesAuthDeferred(Response<dynamic> response) {
  final dynamic raw = response.body;
  if (raw is! Map) {
    return false;
  }
  final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
  if (m['code']?.toString() == 'auth-001') {
    return true;
  }
  final String message = m['message']?.toString() ?? '';
  if (message == 'auth_deferred') {
    return true;
  }
  return false;
}

String _stringifyResponseBodyForLog(Response<dynamic> response) {
  try {
    final dynamic b = response.body ?? response.bodyString;
    if (b == null) {
      return '';
    }
    final String s = b is String ? b : jsonEncode(b);
    const int maxLen = kReleaseMode ? 80 : 400;
    if (s.length > maxLen) {
      return '${s.substring(0, maxLen)}…';
    }
    return s;
  } catch (_) {
    return '[unavailable]';
  }
}

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static final String noInternetMessage = 'connection_to_api_server_failed'.tr;
  final int timeoutInSeconds =
      30; // 🔧 FIX: Consistent 30-second timeout (matches secure_http_client.dart)

  String? token;
  late Map<String, String> _mainHeaders;

  // Secure HTTP client
  late final SecureHttpClient _secureHttpClient;
  bool _useSecureClient = false;

  // Fallback Dio client (replaces http package)
  late final dio_pkg.Dio _fallbackDio;

  // ETag storage for conditional requests
  static const String _etagPrefix = 'etag_';
  Completer<void>? _contextSyncCompleter;

  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    _fallbackDio = dio_pkg.Dio(dio_pkg.BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    // Pin the fallback client too (no-op while the flag is OFF). Without this,
    // a pinning failure on the secure client would silently downgrade here.
    CertificatePinning.apply(_fallbackDio);
    _initializeSecureServices();
    token = sharedPreferences.getString(AppConstants.token);
    AddressModel? addressModel;
    try {
      final rawAddress = sharedPreferences.getString(AppConstants.userAddress);
      if (rawAddress != null && rawAddress.isNotEmpty) {
        addressModel = AddressModel.fromJson(
            jsonDecode(rawAddress) as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ApiClient: $e');
    }
    // MOBILE-MODULE-ID FIX: Read saved moduleId on ALL platforms (not just web).
    // Without this, every cold start on Android/iOS fires API calls with
    // module-id=null until resolveInitialModule or _ensureApiHeadersUpdated runs.
    int? moduleID;
    if (sharedPreferences.containsKey(AppConstants.moduleId)) {
      try {
        moduleID = ModuleModel.fromJson(
                jsonDecode(sharedPreferences.getString(AppConstants.moduleId)!)
                    as Map<String, dynamic>)
            .id;
      } catch (e) {
        if (kDebugMode) debugPrint('ApiClient: $e');
      }
    }
    updateHeader(
        token,
        addressModel?.zoneIds,
        addressModel?.areaIds,
        sharedPreferences.getString(AppConstants.languageCode),
        moduleID,
        addressModel?.latitude,
        addressModel
            ?.longitude); // responseMode - will be set per-request in Phase 2
  }

  /// Initialize token from secure storage - ALWAYS check secure storage first
  /// Secure token takes priority over legacy SharedPreferences token
  /// This ensures hot restart uses the most up-to-date token
  Future<void> initializeTokenFromSecureStorage() async {
    try {
      // 🔧 FIX: ALWAYS check secure storage first (even if legacy token exists)
      // Secure token is the source of truth and may be more up-to-date after hot restart
      final secureToken = await SecureTokenStorage.getToken();
      if (kDebugMode) {
        debugPrint(
            '[AuthStartup] secure_token_exists=${secureToken != null && secureToken.isNotEmpty}');
      }
      if (secureToken != null && secureToken.isNotEmpty) {
        token = secureToken;

        if (kDebugMode) {
          debugPrint(
              '✅ ApiClient: Token loaded from secure storage (priority over legacy)');
          debugPrint(
              '[AuthStartup] token loaded into API client (source=secure_storage)');
        }

        // Update headers with the secure token
        AddressModel? addressModel;
        try {
          final rawAddress =
              sharedPreferences.getString(AppConstants.userAddress);
          if (rawAddress != null && rawAddress.isNotEmpty) {
            addressModel = AddressModel.fromJson(
                jsonDecode(rawAddress) as Map<String, dynamic>);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('ApiClient: $e');
        }
        // MOBILE-MODULE-ID FIX: Read saved moduleId on ALL platforms.
        int? moduleID;
        if (sharedPreferences.containsKey(AppConstants.moduleId)) {
          try {
            moduleID = ModuleModel.fromJson(jsonDecode(
                        sharedPreferences.getString(AppConstants.moduleId)!)
                    as Map<String, dynamic>)
                .id;
          } catch (e) {
            if (kDebugMode) debugPrint('ApiClient: $e');
          }
        }
        updateHeader(
            token,
            addressModel?.zoneIds,
            addressModel?.areaIds,
            sharedPreferences.getString(AppConstants.languageCode),
            moduleID,
            addressModel?.latitude,
            addressModel
                ?.longitude); // responseMode - will be set per-request in Phase 2
        return;
      }

      // Fallback to legacy token only if secure storage has no token
      final legacyToken = sharedPreferences.getString(AppConstants.token);
      if (legacyToken != null &&
          legacyToken.isNotEmpty &&
          (token == null || token!.isEmpty)) {
        token = legacyToken;
        if (kDebugMode) {
          debugPrint('⚠️ ApiClient: Using legacy token (secure storage empty)');
          debugPrint(
              '[AuthStartup] token loaded into API client (source=legacy_storage)');
        }
        // Update headers with legacy token
        AddressModel? addressModel;
        try {
          final rawAddress =
              sharedPreferences.getString(AppConstants.userAddress);
          if (rawAddress != null && rawAddress.isNotEmpty) {
            addressModel = AddressModel.fromJson(
                jsonDecode(rawAddress) as Map<String, dynamic>);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('ApiClient: $e');
        }
        // MOBILE-MODULE-ID FIX: Read saved moduleId on ALL platforms.
        int? moduleID;
        if (sharedPreferences.containsKey(AppConstants.moduleId)) {
          try {
            moduleID = ModuleModel.fromJson(jsonDecode(
                        sharedPreferences.getString(AppConstants.moduleId)!)
                    as Map<String, dynamic>)
                .id;
          } catch (e) {
            if (kDebugMode) debugPrint('ApiClient: $e');
          }
        }
        updateHeader(
            token,
            addressModel?.zoneIds,
            addressModel?.areaIds,
            sharedPreferences.getString(AppConstants.languageCode),
            moduleID,
            addressModel?.latitude,
            addressModel?.longitude);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading token from secure storage: $e');
      }
    }
  }

  /// Ensure headers are properly initialized for smooth operation
  void ensureHeadersAreValid() {
    // Get current address and zone information
    final AddressModel? addressModel =
        AddressHelper.getUserAddressFromSharedPref();

    // Update headers with current information
    updateHeader(
      token,
      addressModel?.zoneIds,
      addressModel?.areaIds,
      sharedPreferences.getString(AppConstants.languageCode),
      ModuleHelper.getModule()?.id,
      addressModel?.latitude,
      addressModel
          ?.longitude, // responseMode - will be set per-request in Phase 2
    );
  }

  /// Initialize secure services
  Future<void> _initializeSecureServices() async {
    // ⚠️ WEB FIX: تعطيل Secure Client على الويب
    // Certificate pinning لا يعمل على الويب، والـ headers تسبب مشاكل CORS
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Secure HTTP Client disabled on web platform (CORS and certificate pinning issues)');
      }
      _useSecureClient = false;
      return;
    }

    // Only initialize secure services for production environment
    if (!EnvironmentConfig.useSecureHttpClient) {
      return;
    }

    try {
      // Initialize secure token storage
      await SecureTokenStorage.initialize();

      // Initialize certificate pinning service
      await CertificatePinningService.initialize();

      // Initialize secure HTTP client
      _secureHttpClient = SecureHttpClient(
        baseUrl: appBaseUrl,
        defaultHeaders: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      _useSecureClient = true;
    } catch (e) {
      _useSecureClient = false;
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize secure services: $e');
      }
    }
  }

  /// Check if secure token is valid, fallback to legacy token if needed
  Future<bool> _isSecureTokenValid() async {
    // For local development, always use standard HTTP client
    if (!EnvironmentConfig.useSecureHttpClient) {
      return false;
    }

    try {
      if (!_useSecureClient) return false;

      // Check if secure token storage has a valid token
      final hasValidToken = await SecureTokenStorage.hasValidToken();
      if (hasValidToken) {
        return true;
      }

      // If no secure token, check if legacy token exists and is still valid
      if (token != null && token!.isNotEmpty) {
        return true; // Allow legacy token to be used
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Token validation failed: $e');
      }
      return false;
    }
  }

  Map<String, String> updateHeader(
      String? token,
      List<int>? zoneIDs,
      List<int>? operationIds,
      String? languageCode,
      int? moduleID,
      String? latitude,
      String? longitude,
      {bool setHeader = true,
      String? responseMode}) {
    final Map<String, String> header = {};
    String? resolvedModuleId;

    // Ensure we have valid zone IDs - no defaults (backend is source of truth)
    List<int> validZoneIDs = zoneIDs ?? <int>[];
    if (validZoneIDs.isEmpty) {
      final AddressModel? addressModel =
          AddressHelper.getUserAddressFromSharedPref();
      validZoneIDs = addressModel?.zoneIds ?? <int>[];
    }

    // Use coordinates if available, otherwise omit
    String? validLatitude = latitude;
    String? validLongitude = longitude;
    if (validLatitude == null || validLongitude == null) {
      final AddressModel? addressModel =
          AddressHelper.getUserAddressFromSharedPref();
      validLatitude = addressModel?.latitude;
      validLongitude = addressModel?.longitude;
    }

    if (moduleID != null ||
        sharedPreferences.getString(AppConstants.cacheModuleId) != null) {
      resolvedModuleId =
          '${moduleID ?? ModuleModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.cacheModuleId)!) as Map<String, dynamic>).id}';
      header.addAll({AppConstants.moduleId: resolvedModuleId});
    }

    header.addAll({
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.zoneId: jsonEncode(validZoneIDs),
      AppConstants.localizationKey:
          languageCode ?? AppConstants.languages[0].languageCode!,
    });
    if (validLatitude != null && validLongitude != null) {
      header.addAll({
        AppConstants.latitude: jsonEncode(validLatitude),
        AppConstants.longitude: jsonEncode(validLongitude),
      });
    }
    final String? sanitizedToken =
        (token == null || token.isEmpty || token == 'null') ? null : token;
    if (sanitizedToken != null && sanitizedToken.isNotEmpty) {
      header['Authorization'] = 'Bearer $sanitizedToken';
    } else {
      if (kDebugMode && AuthHelper.isLoggedIn()) {
        debugPrint(
            '⚠️ ApiClient: Authorization header missing while user is logged in');
      }
    }

    // Add X-Response-Mode header if responseMode is provided
    if (responseMode != null && responseMode.isNotEmpty) {
      header[AppConstants.responseModeHeader] = responseMode;
    }

    if (setHeader) {
      _addHeaderAliases(header, resolvedModuleId: resolvedModuleId);
      _mainHeaders = header;
    } else {
      _addHeaderAliases(header, resolvedModuleId: resolvedModuleId);
    }
    return header;
  }

  void _addHeaderAliases(Map<String, String> header,
      {String? resolvedModuleId}) {
    final String? moduleValue = resolvedModuleId ??
        header[AppConstants.moduleId] ??
        header['module-id'];
    if (_isValidHeaderValue(moduleValue)) {
      header[AppConstants.moduleId] = moduleValue!;
      header['module-id'] = moduleValue;
    }

    final String? zoneValue = header[AppConstants.zoneId] ?? header['zone-id'];
    if (_isValidZoneHeaderValue(zoneValue)) {
      header[AppConstants.zoneId] = zoneValue!;
      header['zone-id'] = zoneValue;
    }
  }

  Map<String, String> getHeader() => _mainHeaders;

  /// Merge custom headers with default headers and apply aliases.
  /// Custom headers override defaults, but defaults provide moduleId, zoneId, etc.
  Map<String, String> _prepareFinalHeaders(Map<String, String>? customHeaders) {
    final Map<String, String> finalHeaders =
        Map<String, String>.from(_mainHeaders);
    if (customHeaders != null) {
      finalHeaders.addAll(customHeaders);
    }
    _addHeaderAliases(finalHeaders);
    return finalHeaders;
  }

  void resetHeaders() {
    _mainHeaders = {};
  }

  /// Check if an API is a config/system API that doesn't require moduleId
  /// Config APIs: /api/v1/config, /api/v1/module, /api/v1/business-settings, etc.
  bool _isConfigApi(String uri) {
    final configPaths = [
      '/api/v1/config',
      '/api/v1/module',
      '/api/v1/business-settings',
      '/api/v1/auth/',
      '/api/v1/customer/update-zone',
      '/api/v1/guest-login',
      '/api/v1/app-init', // App-init doesn't require moduleId (returns all modules)
    ];
    return configPaths.any((path) => uri.contains(path));
  }

  /// Check if an API is a Home or Store feature API that REQUIRES moduleId
  /// Home/Store APIs: /api/v2/home-unified, /api/v1/stores, /api/v1/banners, /api/v1/categories, etc.
  bool _isHomeOrStoreApi(String uri) {
    final homeStorePaths = [
      '/api/v2/home-unified',
      '/api/v1/stores',
      '/api/v1/banners',
      '/api/v1/categories',
      '/api/v1/brands',
      '/api/v1/offers',
      '/api/v1/items',
      '/api/v1/popular-stores',
    ];
    return homeStorePaths.any((path) => uri.contains(path));
  }

  bool _isValidHeaderValue(String? value) {
    if (value == null) return false;
    final normalized = value.trim().toLowerCase();
    return normalized.isNotEmpty && normalized != 'null';
  }

  bool _isValidZoneHeaderValue(String? zoneHeaderValue) {
    if (!_isValidHeaderValue(zoneHeaderValue)) {
      return false;
    }

    final normalized = zoneHeaderValue!.trim();
    if (normalized == '[]') {
      return false;
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is List) {
        return decoded.isNotEmpty;
      }
    } catch (e) {
      // If backend/client sent non-JSON zone-id, keep old behavior and accept non-empty value.
      if (kDebugMode) {
        debugPrint('ApiClient: zone-id parse (non-JSON treated as valid): $e');
      }
    }
    return true;
  }

  /// Public guard: can be used by controllers before triggering Home/Store load.
  bool hasValidHomeHeaders({Map<String, String>? headers}) {
    final Map<String, String> effectiveHeaders = headers ?? _mainHeaders;
    return _isValidHeaderValue(effectiveHeaders[AppConstants.moduleId]) &&
        _isValidZoneHeaderValue(effectiveHeaders[AppConstants.zoneId]);
  }

  void _hydrateHomeHeadersFromAppContext(
      String uri, Map<String, String> headers) {
    if (!_isHomeOrStoreApi(uri)) return;

    if (!_isValidHeaderValue(headers[AppConstants.moduleId])) {
      int? moduleId;
      try {
        if (Get.isRegistered<SplashController>()) {
          final splashController = Get.find<SplashController>();
          moduleId = splashController.selectedModule.value?.id ??
              splashController.module?.id ??
              splashController.getDefaultModuleId();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('ApiClient: $e');
      }

      if (moduleId == null) {
        try {
          final cachedModuleId =
              sharedPreferences.getString(AppConstants.cacheModuleId);
          if (cachedModuleId != null) {
            final moduleModel = ModuleModel.fromJson(
                jsonDecode(cachedModuleId) as Map<String, dynamic>);
            moduleId = moduleModel.id;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('ApiClient: $e');
        }
      }

      if (moduleId != null) {
        headers[AppConstants.moduleId] = moduleId.toString();
      }
    }

    if (!_isValidZoneHeaderValue(headers[AppConstants.zoneId])) {
      try {
        final addressModel = AddressHelper.getUserAddressFromSharedPref();
        final zoneIds = addressModel?.zoneIds;
        if (zoneIds != null && zoneIds.isNotEmpty) {
          headers[AppConstants.zoneId] = jsonEncode(zoneIds);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('ApiClient: $e');
      }
    }
  }

  Future<void> _awaitContextSyncOnce(
      String uri, Map<String, String> headers) async {
    if (!_isHomeOrStoreApi(uri)) return;

    if (_contextSyncCompleter != null) {
      await _contextSyncCompleter!.future;
      return;
    }

    _contextSyncCompleter = Completer<void>();
    try {
      if (Get.isRegistered<SplashController>()) {
        try {
          await Get.find<SplashController>()
              .ensureModuleReady()
              .timeout(const Duration(seconds: 2));
        } catch (e) {
          if (kDebugMode) debugPrint('ApiClient: $e');
        }
      }

      // Give a small window for address/module writes racing from other controllers.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      _hydrateHomeHeadersFromAppContext(uri, headers);
    } finally {
      _contextSyncCompleter?.complete();
      _contextSyncCompleter = null;
    }
  }

  Future<Response<dynamic>?> _ensureHomeHeadersOrBlock(
      String uri, Map<String, String> headers,
      {required String method}) async {
    if (!_isHomeOrStoreApi(uri)) return null;
    bool syncAttempted = false;

    _hydrateHomeHeadersFromAppContext(uri, headers);
    if (hasValidHomeHeaders(headers: headers)) {
      return null;
    }

    syncAttempted = true;
    await _awaitContextSyncOnce(uri, headers);
    if (hasValidHomeHeaders(headers: headers)) {
      return null;
    }

    return _blockIfInvalidHomeHeaders(
      uri,
      headers,
      method: method,
      syncAttempted: syncAttempted,
    );
  }

  Response<dynamic>? _blockIfInvalidHomeHeaders(
      String uri, Map<String, String> headers,
      {required String method, required bool syncAttempted}) {
    if (!_isHomeOrStoreApi(uri)) return null;

    final String? moduleId = headers[AppConstants.moduleId];
    final String? zoneId = headers[AppConstants.zoneId];
    if (kDebugMode) {
      debugPrint(
          '[HeaderGuard] blocked | syncAttempted=$syncAttempted | module=$moduleId | zone=$zoneId | path=$uri');
    }
    appLogger.warning('ApiClient: $method $uri blocked - invalid home headers '
        '(module-id=$moduleId, zone-id=$zoneId)');

    return Response(
      statusCode: 428,
      statusText: 'home_headers_invalid',
      body: <String, dynamic>{
        'message': 'Home request blocked - missing module-id or zone-id',
        'code': 'home_headers_invalid',
        'module-id': moduleId,
        'zone-id': zoneId,
      },
    );
  }

  /// Check if an API is public (no auth required)
  bool _isPublicApi(String uri) {
    if (_isConfigApi(uri)) {
      return true;
    }
    if (uri.contains('/api/v1/customer/cart/list') &&
        uri.contains('guest_id=')) {
      return true;
    }
    final publicPaths = [
      '/api/v1/categories',
      '/api/v1/items',
      '/api/v1/stores',
      '/api/v1/banners',
      '/api/v1/offers',
      '/api/v1/brands',
      '/api/v1/campaigns',
      '/api/v1/popular-stores',
      '/api/v1/app-init',
      '/api/v1/guest-login',
      '/api/v1/auth/guest',
      '/api/v2/home-unified',
    ];
    return publicPaths.any((path) => uri.contains(path));
  }

  Future<Response<dynamic>> getData(String uri,
      {Map<String, dynamic>? query,
      Map<String, String>? headers,
      bool handleError = true,
      bool changeBaseUrl = false,
      Uri? newUri,
      bool useEtag = true,
      bool omitModuleId = false,
      dio_pkg.CancelToken? cancelToken,
      String? requestId}) async {
    try {
      final fullUri = changeBaseUrl ? newUri!.toString() : uri;
      final bool isCouponApplyUri = fullUri.contains('/api/v1/coupon/apply');
      final bool effectiveUseEtag = useEtag && !isCouponApplyUri;
      final String effectiveRequestId =
          requestId ?? 'req_${DateTime.now().millisecondsSinceEpoch}';

      // Detect /items/latest endpoint and debug modes
      final bool isItemsLatestEndpoint =
          uri.contains(AppConstants.storeItemUri);
      final bool itemsFallbackOnlyMode =
          AppConstants.debugItemsUseFallbackOnly && isItemsLatestEndpoint;
      final bool isPublicApi = _isPublicApi(uri);

      if (kDebugMode) {
        final String clientMode = itemsFallbackOnlyMode
            ? 'fallback-only'
            : (_useSecureClient ? 'secure+fallback' : 'fallback');
        appLogger.debug(
            '[ApiClient] GET START | requestId=$effectiveRequestId | uri=$fullUri | query=$query | itemsLatest=$isItemsLatestEndpoint | clientMode=$clientMode');
      }

      // ⚠️ CRITICAL: Merge custom headers with default headers to ensure moduleId is always included
      // Custom headers override defaults, but defaults provide moduleId, zoneId, etc.
      final Map<String, String> finalHeaders = _prepareFinalHeaders(headers);
      if (omitModuleId) {
        finalHeaders.remove(AppConstants.moduleId);
        finalHeaders.remove('moduleId');
      }
      if (!effectiveUseEtag) {
        // Signal SecureHttpClient to skip ETag for this request
        finalHeaders['X-Disable-ETag'] = 'true';
      }
      if (isCouponApplyUri) {
        finalHeaders['Cache-Control'] = 'no-cache';
        finalHeaders['Pragma'] = 'no-cache';
      }

      // Log API call start with full details (after headers are prepared)
      appLogger.logApiCallStart('GET', fullUri,
          query: query, headers: finalHeaders);

      // ⚡ TASK 2: Ensure module-id is ALWAYS sent for Home and Store feature requests
      // This is mandatory for backend's optimized filters
      if (_isHomeOrStoreApi(uri) &&
          !finalHeaders.containsKey(AppConstants.moduleId)) {
        // Try to get moduleId from current module
        try {
          int? moduleId;
          if (Get.isRegistered<SplashController>()) {
            final splashController = Get.find<SplashController>();
            moduleId = splashController.module?.id;
          }

          if (moduleId != null) {
            finalHeaders[AppConstants.moduleId] = moduleId.toString();
            if (kDebugMode) {
              appLogger.debug(
                  'API Client: Added moduleId=$moduleId to headers for Home/Store API: $uri');
            }
          } else {
            // Try to get from cache
            final cachedModuleId =
                sharedPreferences.getString(AppConstants.cacheModuleId);
            if (cachedModuleId != null) {
              final moduleModel = ModuleModel.fromJson(
                  jsonDecode(cachedModuleId) as Map<String, dynamic>);
              finalHeaders[AppConstants.moduleId] = moduleModel.id.toString();
              if (kDebugMode) {
                appLogger.debug(
                    'API Client: Added cached moduleId=${moduleModel.id} to headers for Home/Store API: $uri');
              }
            } else {
              if (kDebugMode) {
                appLogger.warning(
                    'API Client: moduleId missing for Home/Store API: $uri - backend may return wrong data!');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning(
                'API Client: Could not add moduleId for Home/Store API: $uri - Error: $e');
          }
        }
      }

      // ⚡ TASK 2: Ensure zone-id (array) is ALWAYS sent for Home and Store feature requests
      // zone-id is already sent as jsonEncode(array) which is correct format
      if (_isHomeOrStoreApi(uri) &&
          !finalHeaders.containsKey(AppConstants.zoneId)) {
        // Try to get zoneIds from current address
        try {
          final addressModel = AddressHelper.getUserAddressFromSharedPref();
          if (addressModel?.zoneIds != null &&
              addressModel!.zoneIds!.isNotEmpty) {
            finalHeaders[AppConstants.zoneId] =
                jsonEncode(addressModel.zoneIds);
            if (kDebugMode) {
              appLogger.debug(
                  'API Client: Added zoneId=${addressModel.zoneIds} to headers for Home/Store API: $uri');
            }
          } else {
            if (kDebugMode) {
              appLogger.warning(
                  'API Client: zoneId missing for Home/Store API: $uri - backend may return wrong data!');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            appLogger.warning(
                'API Client: Could not add zoneId for Home/Store API: $uri - Error: $e');
          }
        }
      }

      final blockedResponse =
          await _ensureHomeHeadersOrBlock(uri, finalHeaders, method: 'GET');
      if (blockedResponse != null) {
        return blockedResponse;
      }

      // Attach requestId to headers for tracing across layers & backend
      finalHeaders['X-Request-ID'] = effectiveRequestId;

      // Debug: Log moduleId in headers for data APIs
      if (kDebugMode && !_isConfigApi(uri)) {
        if (finalHeaders.containsKey(AppConstants.moduleId)) {
          appLogger.debug(
              'API Client: moduleId=${finalHeaders[AppConstants.moduleId]} included in headers for: $uri');
        } else {
          appLogger.warning(
              'moduleId header missing for API: $uri - This may cause API to return wrong data or fail!');
        }
      }

      final stopwatch = Stopwatch()..start();

      // 🔧 Optional: Per-endpoint timeout override for diagnostics (items/latest only)
      // This is intentionally very narrow-scoped to avoid impacting other APIs.
      const bool enableItemsLatestTimeoutDebug = true;

      // Use secure client if available. Public APIs do not require a token.
      // For /items/latest we can force fallback-only mode via debug flag.
      final bool canUseSecureClient = _useSecureClient &&
          !itemsFallbackOnlyMode &&
          (isPublicApi || await _isSecureTokenValid());

      // ⚡ TASK 4: ETag handling moved to SecureHttpClient interceptor
      // Only add ETag for fallback HTTP client (non-secure requests)
      // SecureHttpClient interceptor handles ETags for secure requests
      if (effectiveUseEtag &&
          !finalHeaders.containsKey('If-None-Match') &&
          !canUseSecureClient) {
        final storedEtag = await _getStoredEtag(uri, headers: finalHeaders);
        if (storedEtag != null) {
          finalHeaders['If-None-Match'] = storedEtag;
        }
      }

      if (canUseSecureClient) {
        try {
          if (kDebugMode && isItemsLatestEndpoint) {
            appLogger.debug(
                '[ApiClient] SECURE START | requestId=$effectiveRequestId | uri=$uri | timeouts=${_secureHttpClient.dio.options.connectTimeout}/${_secureHttpClient.dio.options.receiveTimeout}');
          }

          final Duration? secureReceiveTimeoutOverride =
              enableItemsLatestTimeoutDebug && isItemsLatestEndpoint
                  ? const Duration(seconds: 120)
                  : _secureHttpClient.dio.options.receiveTimeout;

          final response = await _secureHttpClient.dio.get<dynamic>(
            uri,
            queryParameters: query,
            options: dio_pkg.Options(
              headers: finalHeaders,
              receiveTimeout: secureReceiveTimeoutOverride,
              sendTimeout: _secureHttpClient.dio.options.sendTimeout,
              receiveDataWhenStatusError:
                  _secureHttpClient.dio.options.receiveDataWhenStatusError,
              followRedirects: _secureHttpClient.dio.options.followRedirects,
              validateStatus: _secureHttpClient.dio.options.validateStatus,
            ),
            cancelToken: cancelToken, // 🔧 FIX: Support request cancellation
          );

          stopwatch.stop();

          // ⚡ TASK 4: ETag storage moved to SecureHttpClient interceptor
          // This code is kept for backward compatibility but interceptor handles it
          // Only store if interceptor didn't (shouldn't happen, but safety check)
          if (effectiveUseEtag && response.statusCode == 200) {
            final etag = response.headers.value('etag') ??
                response.headers.value('ETag');
            if (etag != null) {
              // Interceptor already stored it, but double-check won't hurt
              await _storeEtag(uri, etag, headers: finalHeaders);
            }
          }

          // ⚡ ETAG SUPPORT: Handle 304 Not Modified
          if (response.statusCode == 304) {
            // Convert headers to Map<String, String>
            final headersMap = <String, String>{};
            response.headers.forEach((key, values) {
              if (values.isNotEmpty) {
                headersMap[key] = values.first;
              }
            });
            final localCacheResponse = Response<dynamic>(
              statusCode: 304,
              statusText: 'Not Modified',
              bodyString: '',
              headers: headersMap,
            );
            return localCacheResponse;
          }

          // Log API call success with full response details
          try {
            dynamic responseData;
            try {
              responseData = response.data;
            } catch (e) {
              responseData = response.toString();
            }
            appLogger.logApiCallSuccess(
                'GET', uri, response.statusCode ?? 0, stopwatch.elapsed,
                response: responseData);
          } catch (e) {
            appLogger.logApiCallSuccess(
                'GET', uri, response.statusCode ?? 0, stopwatch.elapsed);
          }

          if (kDebugMode) {
            appLogger.debug(
                '[ApiClient] SECURE SUCCESS | requestId=$effectiveRequestId | uri=$uri | status=${response.statusCode} | durationMs=${stopwatch.elapsed.inMilliseconds}');
          }

          final converted = _convertDioResponseToGetResponse(response, uri);

          if (kDebugMode) {
            appLogger.debug(
                '[ApiClient] RETURNING TO CALLER | requestId=$effectiveRequestId | uri=$uri | client=secure | status=${converted.statusCode} | durationMs=${stopwatch.elapsed.inMilliseconds}');
          }

          return converted;
        } catch (e) {
          stopwatch.stop();
          if (kDebugMode) {
            if (e is dio_pkg.DioException) {
              appLogger.error(
                  '[ApiClient] SECURE ERROR | requestId=$effectiveRequestId | uri=$uri | type=${e.type} | status=${e.response?.statusCode} | message=${e.message} | durationMs=${stopwatch.elapsed.inMilliseconds}');
            } else {
              appLogger.error(
                  '[ApiClient] SECURE ERROR | requestId=$effectiveRequestId | uri=$uri | error=$e | durationMs=${stopwatch.elapsed.inMilliseconds}');
            }
          }
          if (kDebugMode) {
            debugPrint(
                '❌ Secure client failed, falling back to standard HTTP: $e');
          }
          _useSecureClient = false;
        }
      }

      // Fallback to standard HTTP client
      // 🔧 FIX: Ensure Authorization header is included when secure client fails
      // Update headers with current token before fallback request
      if (token != null && token!.isNotEmpty) {
        finalHeaders['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          appLogger.debug(
              '[ApiClient] FALLBACK: Updated Authorization header with current token');
        }
      } else if (!isPublicApi) {
        if (kDebugMode) {
          appLogger.warning(
              '[ApiClient] FALLBACK: No token available - Authorization header missing');
        }
      }

      // ⚠️ WEB FIX: إزالة الـ headers التي تسبب مشاكل CORS على الويب
      if (kIsWeb) {
        // على الويب، نزيل الـ headers التي قد تسبب مشاكل CORS
        finalHeaders.remove('X-Requested-With');
        finalHeaders.remove('X-Frame-Options');
        finalHeaders.remove('Strict-Transport-Security');
        // نحتفظ فقط بالـ headers الأساسية
        if (!finalHeaders.containsKey('Content-Type')) {
          finalHeaders['Content-Type'] = 'application/json; charset=UTF-8';
        }
      }

      if (kDebugMode) {
        final String fallbackMode =
            itemsFallbackOnlyMode ? 'fallback-only' : 'fallback';
        final int previewTimeoutSeconds =
            enableItemsLatestTimeoutDebug && isItemsLatestEndpoint
                ? 120
                : timeoutInSeconds;
        appLogger.debug(
            '[ApiClient] FALLBACK START | requestId=$effectiveRequestId | uri=$fullUri | mode=$fallbackMode | timeout=${previewTimeoutSeconds}s | hasAuth=${finalHeaders.containsKey('Authorization')} | public=$isPublicApi | isWeb=$kIsWeb');
      }

      final int effectiveTimeoutSeconds =
          enableItemsLatestTimeoutDebug && isItemsLatestEndpoint
              ? 120
              : timeoutInSeconds;

      final dynamic dioGetResp = await _fallbackDio.get<dynamic>(
        changeBaseUrl ? newUri!.toString() : (appBaseUrl + uri),
        options: dio_pkg.Options(
          headers: finalHeaders,
          receiveTimeout: Duration(seconds: effectiveTimeoutSeconds),
          sendTimeout: Duration(seconds: effectiveTimeoutSeconds),
          validateStatus: (s) => s != null,
        ),
      );

      stopwatch.stop();

      // ⚡ ETAG SUPPORT: Extract and store ETag from response headers
      final Map<String, String> getFallbackHeaders = {};
      try {
        (dioGetResp.headers.map as Map).forEach((k, v) {
          getFallbackHeaders[k.toString()] =
              (v is List) ? v.join(',') : v.toString();
        });
      } catch (_) {}

      if (effectiveUseEtag && (dioGetResp.statusCode as int?) == 200) {
        final etag = getFallbackHeaders['etag'] ?? getFallbackHeaders['ETag'];
        if (etag != null) {
          await _storeEtag(uri, etag, headers: finalHeaders);
        }
      }

      // ⚡ ETAG SUPPORT: Handle 304 Not Modified
      if ((dioGetResp.statusCode as int?) == 304) {
        appLogger.logApiCallSuccess('GET', uri, 304, stopwatch.elapsed,
            response: 'Not Modified (cached)');
        final localCacheResponse = Response<dynamic>(
          statusCode: 304,
          statusText: 'Not Modified',
          bodyString: '',
          headers: getFallbackHeaders,
        );
        return localCacheResponse;
      }

      // Log API call success with full response details
      try {
        appLogger.logApiCallSuccess(
            'GET', uri, dioGetResp.statusCode as int, stopwatch.elapsed,
            response: dioGetResp.data);
      } catch (e) {
        appLogger.logApiCallSuccess('GET', uri,
            (dioGetResp.statusCode as int?) ?? 0, stopwatch.elapsed);
      }

      if (kDebugMode) {
        appLogger.debug(
            '[ApiClient] FALLBACK SUCCESS | requestId=$effectiveRequestId | uri=$uri | status=${dioGetResp.statusCode} | durationMs=${stopwatch.elapsed.inMilliseconds}');
      }

      final converted =
          _handleDioFallbackResponse(dioGetResp, uri, handleError);

      if (kDebugMode) {
        appLogger.debug(
            '[ApiClient] RETURNING TO CALLER | requestId=$effectiveRequestId | uri=$uri | client=fallback | status=${converted.statusCode} | durationMs=${stopwatch.elapsed.inMilliseconds}');
      }

      return converted;
    } catch (e) {
      final String fullUriOnError = changeBaseUrl ? newUri!.toString() : uri;
      appLogger.logApiCallError('GET', fullUriOnError, e.toString());

      if (kDebugMode) {
        appLogger.error(
            '[ApiClient] FALLBACK ERROR | requestId=${requestId ?? 'n/a'} | uri=$fullUriOnError | error=$e');

        // ⚠️ WEB FIX: معلومات إضافية للأخطاء على الويب
        if (kIsWeb) {
          appLogger.error(
              '[ApiClient] WEB ERROR DETAILS | This might be a CORS issue. Check:');
          appLogger.error('   1. Server CORS configuration');
          appLogger.error('   2. SSL Certificate validity');
          appLogger.error('   3. Base URL: $appBaseUrl');
          appLogger.error('   4. Full URI: $fullUriOnError');
        }
      }

      return Response(
        statusCode: 1,
        statusText: noInternetMessage,
      );
    }
  }

  /// Whether a thrown Dio error for [uri] is the benign place-order case where
  /// the backend returned a non-2xx (e.g. 403) but the body still carries a
  /// usable order id together with duplicate_prevented=true or a
  /// payment_pending/unpaid state. Such responses are recovered downstream
  /// (fallback client + createOrder()), so they should not be logged as errors.
  /// Returns false for genuine failures (no usable order id), so real errors
  /// are still logged.
  bool _isUsablePendingOrderDioError(String uri, Object error) {
    try {
      if (!uri.contains(AppConstants.placeOrderUri)) {
        return false;
      }
      if (error is! dio_pkg.DioException) {
        return false;
      }

      final dynamic rawBody = error.response?.data;
      Map<String, dynamic>? bodyMap;
      if (rawBody is Map<String, dynamic>) {
        bodyMap = rawBody;
      } else if (rawBody is String && rawBody.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          bodyMap = decoded;
        }
      }
      if (bodyMap == null) {
        return false;
      }

      final String orderId =
          (bodyMap['order_id'] ?? bodyMap['orderId'] ?? bodyMap['id'] ?? '')
              .toString()
              .trim();
      if (orderId.isEmpty) {
        return false;
      }

      final bool duplicatePrevented = bodyMap['duplicate_prevented'] == true;
      final String statusStr =
          (bodyMap['status'] ?? bodyMap['order_status'] ?? '')
              .toString()
              .toLowerCase();
      final String paymentStatusStr =
          (bodyMap['payment_status'] ?? '').toString().toLowerCase();
      final bool isPendingPayment =
          statusStr == 'payment_pending' || paymentStatusStr == 'unpaid';

      return duplicatePrevented || isPendingPayment;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> postData(String uri, dynamic body,
      {Map<String, String>? headers,
      int? timeout,
      bool handleError = true,
      dio_pkg.ValidateStatus? validateStatus,
      bool alreadyRetriedAuthRefresh = false,
      bool skipAuthDeferredRetry = false}) async {
    try {
      // ⚠️ CRITICAL: Merge custom headers with default headers to ensure moduleId is always included
      final Map<String, String> finalHeaders = _prepareFinalHeaders(headers);

      final blockedResponse =
          await _ensureHomeHeadersOrBlock(uri, finalHeaders, method: 'POST');
      if (blockedResponse != null) {
        return blockedResponse;
      }

      // Log API call start with full details
      appLogger.logApiCallStart('POST', uri, headers: finalHeaders);
      if (body != null) {
        appLogger.debug(
            'POST Body: ${body.toString().length > 500 ? "${body.toString().substring(0, 500)}..." : body.toString()}');
      }

      // Warn if moduleId is missing for data APIs
      if (kDebugMode &&
          !_isConfigApi(uri) &&
          !finalHeaders.containsKey(AppConstants.moduleId)) {
        appLogger.warning('moduleId header missing for API: $uri');
      }

      final stopwatch = Stopwatch()..start();

      // Use secure client if available and token is valid, otherwise fallback to standard HTTP
      if (_useSecureClient && await _isSecureTokenValid()) {
        try {
          final response = await _secureHttpClient.dio.post<dynamic>(
            uri,
            data: body,
            options: dio_pkg.Options(
              headers: finalHeaders,
              sendTimeout: Duration(seconds: timeout ?? timeoutInSeconds),
              validateStatus: validateStatus,
            ),
          );

          stopwatch.stop();

          // Log API call success with full response details
          try {
            dynamic responseData;
            try {
              responseData = response.data;
            } catch (e) {
              responseData = response.toString();
            }
            appLogger.logApiCallSuccess(
                'POST', uri, response.statusCode ?? 0, stopwatch.elapsed,
                response: responseData);
          } catch (e) {
            appLogger.logApiCallSuccess(
                'POST', uri, response.statusCode ?? 0, stopwatch.elapsed);
          }

          final Response<dynamic> converted =
              _convertDioResponseToGetResponse(response, uri);
          return await _finalizeAuthDeferredRetryForPost(
            uri: uri,
            body: body,
            headers: headers,
            timeout: timeout,
            handleError: handleError,
            validateStatus: validateStatus,
            alreadyRetriedAuthRefresh: alreadyRetriedAuthRefresh,
            skipAuthDeferredRetry: skipAuthDeferredRetry,
            initialResponse: converted,
          );
        } catch (e) {
          stopwatch.stop();
          // The secure client throws on non-2xx (e.g. the place-order 403 that
          // still carries a usable payment_pending/duplicate_prevented order).
          // That case is handled downstream by createOrder() via the fallback
          // client, so don't log it as an error here — only log genuine errors.
          if (!uri.contains('registration-activity') &&
              !_isUsablePendingOrderDioError(uri, e)) {
            appLogger.logApiCallError('POST', uri, e.toString(),
                duration: stopwatch.elapsed);
          }
          _useSecureClient = false;
        }
      }

      // Fallback to standard HTTP client (using Dio)
      final dynamic dioPostResp = await _fallbackDio.post<dynamic>(
        appBaseUrl + uri,
        data: jsonEncode(body),
        options: dio_pkg.Options(
          headers: finalHeaders,
          receiveTimeout: Duration(seconds: timeout ?? timeoutInSeconds),
          sendTimeout: Duration(seconds: timeout ?? timeoutInSeconds),
          validateStatus: (s) => s != null,
          contentType: 'application/json; charset=UTF-8',
        ),
      );

      stopwatch.stop();

      try {
        appLogger.logApiCallSuccess('POST', uri,
            (dioPostResp.statusCode as int?) ?? 0, stopwatch.elapsed,
            response: dioPostResp.data);
      } catch (e) {
        appLogger.logApiCallSuccess('POST', uri,
            (dioPostResp.statusCode as int?) ?? 0, stopwatch.elapsed);
      }

      final Response<dynamic> handled =
          _handleDioFallbackResponse(dioPostResp, uri, handleError);
      return await _finalizeAuthDeferredRetryForPost(
        uri: uri,
        body: body,
        headers: headers,
        timeout: timeout,
        handleError: handleError,
        validateStatus: validateStatus,
        alreadyRetriedAuthRefresh: alreadyRetriedAuthRefresh,
        skipAuthDeferredRetry: skipAuthDeferredRetry,
        initialResponse: handled,
      );
    } catch (e) {
      if (!uri.contains('registration-activity')) {
        appLogger.logApiCallError('POST', uri, e.toString());
      }
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response<dynamic>> postMultipartData(
      String uri, Map<String, String> body, List<MultipartBody> multipartBody,
      {Map<String, String>? headers, bool handleError = true}) async {
    try {
      // ⚠️ CRITICAL: Merge custom headers with default headers
      final Map<String, String> finalHeaders = _prepareFinalHeaders(headers);

      final blockedResponse = await _ensureHomeHeadersOrBlock(uri, finalHeaders,
          method: 'POST_MULTIPART');
      if (blockedResponse != null) {
        return blockedResponse;
      }

      // Use secure client if available, otherwise fallback to standard HTTP
      if (_useSecureClient) {
        try {
          // For multipart requests, fallback to standard HTTP client to avoid conflicts
          _useSecureClient = false;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ Secure client failed, falling back to standard HTTP: $e');
          }
          _useSecureClient = false;
        }
      }

      // Fallback to standard HTTP client (using Dio FormData)
      // 🔧 FIX: Ensure Authorization header is included when secure client fails
      if (token != null && token!.isNotEmpty) {
        finalHeaders['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          debugPrint(
              '[ApiClient] FALLBACK MULTIPART: Updated Authorization header with current token');
        }
      }

      final dioFormData = dio_pkg.FormData();
      for (final MultipartBody multipart in multipartBody) {
        if (multipart.file != null) {
          final Uint8List bytes = await multipart.file!.readAsBytes();
          dioFormData.files.add(MapEntry(
            multipart.key,
            dio_pkg.MultipartFile.fromBytes(
              bytes,
              filename: '${DateTime.now().millisecondsSinceEpoch}.png',
            ),
          ));
        }
      }
      body.forEach((s, i) {
        if (i.isNotEmpty) dioFormData.fields.add(MapEntry(s, i));
      });

      final dynamic dioMultipartResp = await _fallbackDio.post<dynamic>(
        appBaseUrl + uri,
        data: dioFormData,
        options: dio_pkg.Options(
          headers: finalHeaders,
          validateStatus: (s) => s != null,
        ),
      );
      return _handleDioFallbackResponse(dioMultipartResp, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  /// Post Multipart Data using Dio FormData (for prescription orders)
  /// This method sends FormData with files and fields using Dio
  /// ⚠️ NOTE: This is a new method specifically for FormData, different from the existing postMultipartData
  Future<Response<dynamic>> postFormData(
    String uri,
    dynamic formData, {
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    debugPrint('\x1B[35m🔥🔥🔥 apiClient.postFormData() CALLED 🔥🔥🔥\x1B[0m');
    debugPrint('\x1B[35m - URI: $uri\x1B[0m');
    debugPrint('\x1B[35m - formData type: ${formData.runtimeType}\x1B[0m');

    try {
      // ⚠️ CRITICAL: Merge custom headers with default headers
      final Map<String, dynamic> finalHeaders =
          Map<String, dynamic>.from(_mainHeaders);
      if (headers != null) {
        finalHeaders.addAll(headers);
      }

      // 🔥 مهم: إزالة Content-Type header للسماح لـ dio بضبطه تلقائياً
      final Map<String, String> guardHeaders =
          finalHeaders.map((key, value) => MapEntry(key, value.toString()));
      final blockedResponse = await _ensureHomeHeadersOrBlock(uri, guardHeaders,
          method: 'POST_FORM_DATA');
      if (blockedResponse != null) {
        return blockedResponse;
      }
      finalHeaders.addAll(guardHeaders);

      finalHeaders.remove('Content-Type');
      debugPrint('\x1B[35m - Content-Type removed (will be set by dio)\x1B[0m');

      // Convert to Map<String, String> for logging
      final Map<String, String> logHeaders =
          finalHeaders.map((key, value) => MapEntry(key, value.toString()));

      // Log API call start
      appLogger.logApiCallStart('POST (FormData)', uri, headers: logHeaders);

      // Try to get files/fields count for debug logging
      try {
        if (formData.runtimeType.toString().contains('FormData')) {
          // formData is already dynamic — access fields directly without redundant cast
          if (formData.files != null) {
            debugPrint(
                '\x1B[35m - FormData files count: ${formData.files.length}\x1B[0m');
          }
          if (formData.fields != null) {
            debugPrint(
                '\x1B[35m - FormData fields count: ${formData.fields.length}\x1B[0m');
          }
        }
      } catch (e) {
        debugPrint('\x1B[35m - Could not get FormData info: $e\x1B[0m');
      }

      final stopwatch = Stopwatch()..start();

      // Use secure client if available and token is valid
      if (_useSecureClient && await _isSecureTokenValid()) {
        try {
          if (kDebugMode) {
            debugPrint(
                '\x1B[35m🔥 Using Secure Client (Dio) for FormData\x1B[0m');
            debugPrint('\x1B[35m - URI: $uri\x1B[0m');
            debugPrint(
                '\x1B[35m - Headers (masked): ${SecureLog.maskHeadersDynamic(finalHeaders)}\x1B[0m');
            debugPrint(
                '\x1B[35m - Content-Type in headers: ${finalHeaders.containsKey('Content-Type')}\x1B[0m');
          }

          final response = await _secureHttpClient.dio.post<dynamic>(
            uri,
            data: formData,
            options: dio_pkg.Options(
              headers: finalHeaders,
              sendTimeout: Duration(seconds: timeoutInSeconds),
              validateStatus: (int? status) => status != null && status < 500,
            ),
          );

          if (kDebugMode) {
            debugPrint('\x1B[35m✅ Secure Client Response:\x1B[0m');
            debugPrint('\x1B[35m - Status: ${response.statusCode}\x1B[0m');
            debugPrint(
                '\x1B[35m - Response header keys: ${response.headers.map.keys.join(",")}\x1B[0m');
          }

          stopwatch.stop();
          appLogger.logApiCallSuccess('POST (FormData)', uri,
              response.statusCode ?? 0, stopwatch.elapsed);

          return _convertDioResponseToGetResponse(response, uri);
        } on dio_pkg.DioException catch (e) {
          stopwatch.stop();
          debugPrint(
              '\x1B[31m❌❌❌ dio_pkg.DioException in postFormData (Secure Client):\x1B[0m');
          debugPrint(
              '\x1B[31m - Status Code: ${e.response?.statusCode}\x1B[0m');
          debugPrint(
              '\x1B[31m - Status Message: ${e.response?.statusMessage}\x1B[0m');
          debugPrint('\x1B[31m - Response Data: ${e.response?.data}\x1B[0m');
          debugPrint(
              '\x1B[31m - Response Headers: ${e.response?.headers}\x1B[0m');
          if (e.response?.data is Map) {
            final errorData = e.response!.data as Map;
            if (errorData.containsKey('errors')) {
              debugPrint(
                  '\x1B[31m - Validation Errors: ${errorData['errors']}\x1B[0m');
            }
            if (errorData.containsKey('message')) {
              debugPrint(
                  '\x1B[31m - Error Message: ${errorData['message']}\x1B[0m');
            }
          }
          appLogger.logApiCallError('POST (FormData)', uri, e.toString(),
              duration: stopwatch.elapsed);
          _useSecureClient = false;
        } catch (e) {
          stopwatch.stop();
          debugPrint(
              '\x1B[31m❌❌❌ General Exception in postFormData (Secure Client):\x1B[0m');
          debugPrint('\x1B[31m - Error: $e\x1B[0m');
          appLogger.logApiCallError('POST (FormData)', uri, e.toString(),
              duration: stopwatch.elapsed);
          _useSecureClient = false;
        }
      }

      // Fallback: Create new Dio instance for multipart
      if (kDebugMode) {
        debugPrint('\x1B[35m🔥 Using Fallback Dio Client for FormData\x1B[0m');
        debugPrint('\x1B[35m - Base URL: $appBaseUrl\x1B[0m');
        debugPrint('\x1B[35m - URI: $uri\x1B[0m');
        debugPrint('\x1B[35m - Full URL: $appBaseUrl$uri\x1B[0m');
        debugPrint(
            '\x1B[35m - Headers (masked): ${SecureLog.maskHeadersDynamic(finalHeaders)}\x1B[0m');
        debugPrint(
            '\x1B[35m - Content-Type in headers: ${finalHeaders.containsKey('Content-Type')}\x1B[0m');
      }

      final dioClient = dio_pkg.Dio(dio_pkg.BaseOptions(
        baseUrl: appBaseUrl,
        connectTimeout: Duration(seconds: timeoutInSeconds),
        receiveTimeout: Duration(seconds: timeoutInSeconds),
        headers: finalHeaders,
      ));
      // Multipart fallback also targets our domain — pin it too.
      CertificatePinning.apply(dioClient);

      try {
        debugPrint('\x1B[35m🔥 Sending Dio POST request...\x1B[0m');
        final response = await dioClient.post<dynamic>(
          uri,
          data: formData,
          options: dio_pkg.Options(
            headers: finalHeaders,
            validateStatus: (int? status) => status != null && status < 500,
          ),
        );

        if (kDebugMode) {
          debugPrint('\x1B[35m✅ Dio Response received:\x1B[0m');
          debugPrint('\x1B[35m - Status: ${response.statusCode}\x1B[0m');
          try {
            final Map<String, String> rh = response.requestOptions.headers.map(
              (String k, dynamic v) => MapEntry(k, v.toString()),
            );
            debugPrint(
                '\x1B[35m - Request Headers (masked): ${SecureLog.maskHeaders(rh)}\x1B[0m');
          } catch (_) {}
          debugPrint(
              '\x1B[35m - Response header keys: ${response.headers.map.keys.join(",")}\x1B[0m');
        }

        stopwatch.stop();

        // Log response details
        debugPrint('\x1B[35m✅ postFormData Response:\x1B[0m');
        debugPrint('\x1B[35m - Status Code: ${response.statusCode}\x1B[0m');
        debugPrint(
            '\x1B[35m - Status Message: ${response.statusMessage}\x1B[0m');

        // If error response (422, 400, etc), log the body
        if (response.statusCode != null && response.statusCode! >= 400) {
          debugPrint('\x1B[31m❌ ERROR RESPONSE BODY:\x1B[0m');
          debugPrint('\x1B[31m${response.data}\x1B[0m');
          if (response.data is Map) {
            final errorData = response.data as Map;
            if (errorData.containsKey('errors')) {
              debugPrint(
                  '\x1B[31m - Validation Errors: ${errorData['errors']}\x1B[0m');
            }
            if (errorData.containsKey('message')) {
              debugPrint(
                  '\x1B[31m - Error Message: ${errorData['message']}\x1B[0m');
            }
          }
          // ✅ FIX: تسجيل كـ error وليس success
          appLogger.logApiCallError('POST (FormData)', uri,
              'Status ${response.statusCode}: ${response.data}',
              duration: stopwatch.elapsed);
        } else {
          appLogger.logApiCallSuccess('POST (FormData)', uri,
              response.statusCode ?? 0, stopwatch.elapsed);
        }

        // Convert DioResponse to GetResponse
        return Response(
          statusCode: response.statusCode ?? 0,
          statusText: response.statusMessage,
          body: response.data,
        );
      } on dio_pkg.DioException catch (e) {
        stopwatch.stop();
        debugPrint(
            '\x1B[31m❌❌❌ dio_pkg.DioException in postFormData (Fallback):\x1B[0m');
        debugPrint('\x1B[31m - Status Code: ${e.response?.statusCode}\x1B[0m');
        debugPrint(
            '\x1B[31m - Status Message: ${e.response?.statusMessage}\x1B[0m');
        debugPrint('\x1B[31m - Response Data: ${e.response?.data}\x1B[0m');
        debugPrint(
            '\x1B[31m - Response Headers: ${e.response?.headers}\x1B[0m');
        if (e.response?.data is Map) {
          final errorData = e.response!.data as Map;
          if (errorData.containsKey('errors')) {
            debugPrint(
                '\x1B[31m - Validation Errors: ${errorData['errors']}\x1B[0m');
          }
          if (errorData.containsKey('message')) {
            debugPrint(
                '\x1B[31m - Error Message: ${errorData['message']}\x1B[0m');
          }
        }
        if (!uri.contains('registration-activity')) {
          appLogger.logApiCallError('POST (FormData)', uri, e.toString());
        }
        // Return error response instead of generic error
        if (e.response != null) {
          return Response(
            statusCode: e.response!.statusCode ?? 0,
            statusText: e.response!.statusMessage,
            body: e.response!.data,
          );
        }
        return Response(statusCode: 1, statusText: noInternetMessage);
      } catch (e) {
        stopwatch.stop();
        debugPrint(
            '\x1B[31m❌❌❌ General Exception in postFormData (Fallback):\x1B[0m');
        debugPrint('\x1B[31m - Error: $e\x1B[0m');
        if (!uri.contains('registration-activity')) {
          appLogger.logApiCallError('POST (FormData)', uri, e.toString());
        }
        return Response(statusCode: 1, statusText: noInternetMessage);
      }
    } catch (e) {
      debugPrint('\x1B[31m❌❌❌ Outer Exception in postFormData:\x1B[0m');
      debugPrint('\x1B[31m - Error: $e\x1B[0m');
      if (!uri.contains('registration-activity')) {
        appLogger.logApiCallError('POST (FormData)', uri, e.toString());
      }
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response<dynamic>> putData(String uri, dynamic body,
      {Map<String, String>? headers, bool handleError = true}) async {
    try {
      // ⚠️ CRITICAL: Merge custom headers with default headers
      final Map<String, String> finalHeaders = _prepareFinalHeaders(headers);

      final blockedResponse =
          await _ensureHomeHeadersOrBlock(uri, finalHeaders, method: 'PUT');
      if (blockedResponse != null) {
        return blockedResponse;
      }

      // Log API call start
      appLogger.logApiCallStart('PUT', uri, headers: finalHeaders);
      if (body != null) {
        appLogger.debug(
            'PUT Body: ${body.toString().length > 500 ? "${body.toString().substring(0, 500)}..." : body.toString()}');
      }

      final stopwatch = Stopwatch()..start();

      // Use secure client if available, otherwise fallback to standard HTTP
      if (_useSecureClient) {
        try {
          final response = await _secureHttpClient.dio.put<dynamic>(
            uri,
            data: body,
            options: dio_pkg.Options(headers: finalHeaders),
          );

          stopwatch.stop();
          try {
            dynamic responseData;
            try {
              responseData = response.data;
            } catch (e) {
              responseData = response.toString();
            }
            appLogger.logApiCallSuccess(
                'PUT', uri, response.statusCode ?? 0, stopwatch.elapsed,
                response: responseData);
          } catch (e) {
            appLogger.logApiCallSuccess(
                'PUT', uri, response.statusCode ?? 0, stopwatch.elapsed);
          }

          return _convertDioResponseToGetResponse(response, uri);
        } catch (e) {
          stopwatch.stop();
          appLogger.logApiCallError('PUT', uri, e.toString(),
              duration: stopwatch.elapsed);
          if (kDebugMode) {
            debugPrint(
                '❌ Secure client failed, falling back to standard HTTP: $e');
          }
          _useSecureClient = false;
        }
      }

      // Fallback to standard HTTP client
      // 🔧 FIX: Ensure Authorization header is included when secure client fails
      if (token != null && token!.isNotEmpty) {
        finalHeaders['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          appLogger.debug(
              '[ApiClient] FALLBACK PUT: Updated Authorization header with current token');
        }
      }

      final dynamic dioPutResp = await _fallbackDio.put<dynamic>(
        appBaseUrl + uri,
        data: jsonEncode(body),
        options: dio_pkg.Options(
          headers: finalHeaders,
          receiveTimeout: Duration(seconds: timeoutInSeconds),
          sendTimeout: Duration(seconds: timeoutInSeconds),
          validateStatus: (s) => s != null,
          contentType: 'application/json; charset=UTF-8',
        ),
      );

      stopwatch.stop();
      try {
        appLogger.logApiCallSuccess(
            'PUT', uri, (dioPutResp.statusCode as int?) ?? 0, stopwatch.elapsed,
            response: dioPutResp.data);
      } catch (e) {
        appLogger.logApiCallSuccess('PUT', uri,
            (dioPutResp.statusCode as int?) ?? 0, stopwatch.elapsed);
      }

      return _handleDioFallbackResponse(dioPutResp, uri, handleError);
    } catch (e) {
      appLogger.logApiCallError('PUT', uri, e.toString());
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response<dynamic>> deleteData(String uri,
      {Map<String, String>? headers, bool handleError = true}) async {
    try {
      // ⚠️ CRITICAL: Merge custom headers with default headers
      final Map<String, String> finalHeaders = _prepareFinalHeaders(headers);

      final blockedResponse =
          await _ensureHomeHeadersOrBlock(uri, finalHeaders, method: 'DELETE');
      if (blockedResponse != null) {
        return blockedResponse;
      }

      // Log API call start
      appLogger.logApiCallStart('DELETE', uri, headers: finalHeaders);

      final stopwatch = Stopwatch()..start();

      // Use secure client if available, otherwise fallback to standard HTTP
      if (_useSecureClient) {
        try {
          final response = await _secureHttpClient.dio.delete<dynamic>(
            uri,
            options: dio_pkg.Options(headers: finalHeaders),
          );

          stopwatch.stop();
          try {
            dynamic responseData;
            try {
              responseData = response.data;
            } catch (e) {
              responseData = response.toString();
            }
            appLogger.logApiCallSuccess(
                'DELETE', uri, response.statusCode ?? 0, stopwatch.elapsed,
                response: responseData);
          } catch (e) {
            appLogger.logApiCallSuccess(
                'DELETE', uri, response.statusCode ?? 0, stopwatch.elapsed);
          }

          return _convertDioResponseToGetResponse(response, uri);
        } catch (e) {
          stopwatch.stop();
          appLogger.logApiCallError('DELETE', uri, e.toString(),
              duration: stopwatch.elapsed);
          if (kDebugMode) {
            debugPrint(
                '❌ Secure client failed, falling back to standard HTTP: $e');
          }
          _useSecureClient = false;
        }
      }

      // Fallback to standard HTTP client
      // 🔧 FIX: Ensure Authorization header is included when secure client fails
      if (token != null && token!.isNotEmpty) {
        finalHeaders['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          appLogger.debug(
              '[ApiClient] FALLBACK DELETE: Updated Authorization header with current token');
        }
      }

      final dynamic dioDeleteResp = await _fallbackDio.delete<dynamic>(
        appBaseUrl + uri,
        options: dio_pkg.Options(
          headers: finalHeaders,
          receiveTimeout: Duration(seconds: timeoutInSeconds),
          sendTimeout: Duration(seconds: timeoutInSeconds),
          validateStatus: (s) => s != null,
        ),
      );

      stopwatch.stop();
      try {
        appLogger.logApiCallSuccess('DELETE', uri,
            (dioDeleteResp.statusCode as int?) ?? 0, stopwatch.elapsed,
            response: dioDeleteResp.data);
      } catch (e) {
        appLogger.logApiCallSuccess('DELETE', uri,
            (dioDeleteResp.statusCode as int?) ?? 0, stopwatch.elapsed);
      }

      return _handleDioFallbackResponse(dioDeleteResp, uri, handleError);
    } catch (e) {
      appLogger.logApiCallError('DELETE', uri, e.toString());
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Response<dynamic> _convertDioResponseToGetResponse(
      dynamic dioResponse, String uri) {
    try {
      // -----------------------------
      // 1️⃣ Body
      // -----------------------------
      final dynamic responseBody = dioResponse.data;
      final String responseBodyString = responseBody?.toString() ?? '';

      // -----------------------------
      // 2️⃣ Headers
      // -----------------------------
      final Map<String, String> safeHeaders = <String, String>{};
      if (dioResponse.headers.map != null) {
        dioResponse.headers.map.forEach((String key, List<String> value) {
          safeHeaders[key.toString()] = (value as List).join(',');
        });
      }
      _updateServerTimeOffsetFromHeaders(safeHeaders);

      // -----------------------------
      // 3️⃣ URI
      // -----------------------------
      final Uri safeUri = dioResponse.requestOptions.uri is Uri
          ? dioResponse.requestOptions.uri as Uri
          : Uri.parse(dioResponse.requestOptions.uri.toString());

      // -----------------------------
      // 4️⃣ Status Code
      // -----------------------------
      final int? safeStatusCode = dioResponse.statusCode is int
          ? dioResponse.statusCode as int
          : int.tryParse(dioResponse.statusCode?.toString() ?? '');

      // -----------------------------
      // 5️⃣ Return GetX Response
      // -----------------------------
      return Response<dynamic>(
        body: responseBody, // استخدام responseBody مباشرة (نوع dynamic)
        bodyString: responseBodyString,
        statusCode: safeStatusCode,
        statusText: dioResponse.statusMessage?.toString(),
        headers: safeHeaders,
        request: Request(
          url: safeUri,
          method: dioResponse.requestOptions.method.toString(),
          headers:
              (dioResponse.requestOptions.headers as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key.toString(),
              value.toString(),
            ),
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error converting Dio response: $e');
      }
      return const Response<dynamic>(
        statusCode: 0,
        statusText: 'Response conversion failed',
      );
    }
  }

  void _updateServerTimeOffsetFromHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return;
    String? dateHeader;
    headers.forEach((key, value) {
      if (key.toLowerCase() == 'date') {
        dateHeader = value;
      }
    });
    if (dateHeader == null || dateHeader!.trim().isEmpty) return;

    DateTime? serverTimeUtc;
    try {
      serverTimeUtc = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
          .parseUtc(dateHeader!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiClient: RFC date parse failed, trying ISO: $e');
      }
      try {
        serverTimeUtc = DateTime.parse(dateHeader!).toUtc();
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('ApiClient: ISO date parse also failed: $e2');
        }
      }
    }

    if (serverTimeUtc == null) return;
    final int offsetMs = serverTimeUtc.millisecondsSinceEpoch -
        DateTime.now().toUtc().millisecondsSinceEpoch;
    sharedPreferences.setInt(AppConstants.serverTimeOffsetMs, offsetMs);
    DateConverter.updateServerTimeOffsetMs(offsetMs);
  }

  /// Get stored ETag for an endpoint
  /// ⚡ TASK 3: Migrated from SharedPreferences to Hive app_config box
  Future<String?> _getStoredEtag(String uri,
      {Map<String, String>? headers}) async {
    try {
      // ⚡ TASK 3: Use Hive app_config box for ETag storage
      final cacheService = HiveHomeCacheService();
      final scopedUri =
          EtagScopeKeyBuilder.buildScopedUri(uri, headers: headers);
      return await cacheService.getEtag(scopedUri);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ApiClient: Error getting stored ETag: $e');
      }
      return null;
    }
  }

  /// Store ETag for an endpoint
  /// ⚡ TASK 3: Migrated from SharedPreferences to Hive app_config box
  Future<void> _storeEtag(String uri, String etag,
      {Map<String, String>? headers}) async {
    try {
      // ⚡ TASK 3: Use Hive app_config box for ETag storage
      final cacheService = HiveHomeCacheService();
      final scopedUri =
          EtagScopeKeyBuilder.buildScopedUri(uri, headers: headers);
      await cacheService.saveEtag(scopedUri, etag);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ApiClient: Error storing ETag: $e');
      }
    }
  }

  /// Clear stored ETag for an endpoint (useful for force refresh)
  Future<void> clearEtag(String uri) async {
    try {
      final etagKey =
          '$_etagPrefix${uri.replaceAll('/', '_').replaceAll(':', '_')}';
      await sharedPreferences.remove(etagKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ApiClient: Error clearing ETag: $e');
      }
    }
  }

  /// Clear all stored ETags
  Future<void> clearAllEtags() async {
    try {
      final keys = sharedPreferences.getKeys();
      for (final key in keys) {
        if (key.startsWith(_etagPrefix)) {
          await sharedPreferences.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ApiClient: Error clearing all ETags: $e');
      }
    }
  }

  /// When the server returns HTTP 200 with `auth-001` / `auth_deferred`, refresh
  /// the FCM token once (without nested retry), then replay this POST once.
  Future<Response<dynamic>> _finalizeAuthDeferredRetryForPost({
    required String uri,
    required dynamic body,
    required Map<String, String>? headers,
    required int? timeout,
    required bool handleError,
    required dio_pkg.ValidateStatus? validateStatus,
    required bool alreadyRetriedAuthRefresh,
    required bool skipAuthDeferredRetry,
    required Response<dynamic> initialResponse,
  }) async {
    if (skipAuthDeferredRetry ||
        !_responseIndicatesAuthDeferred(initialResponse)) {
      return initialResponse;
    }
    if (alreadyRetriedAuthRefresh) {
      debugPrint(
        '[AuthRetry][RETRY_RESPONSE] status=${initialResponse.statusCode} body=${_stringifyResponseBodyForLog(initialResponse)}',
      );
      await ApiChecker.onAuthDeferredRetryExhausted(uri);
      return initialResponse;
    }
    debugPrint('[AuthRetry][START] path=$uri');
    await ApiChecker.refreshSessionAfterAuthDeferred(uri);
    if (!AuthHelper.isLoggedIn()) {
      debugPrint('[AuthRetry] abort retry — session cleared during refresh');
      return initialResponse;
    }
    debugPrint('[AuthRetry][REFRESH_SUCCESS]');
    debugPrint('[AuthRetry][RETRY_REQUEST] path=$uri');
    final Response<dynamic> retryResponse = await postData(
      uri,
      body,
      headers: headers,
      timeout: timeout,
      handleError: handleError,
      validateStatus: validateStatus,
      alreadyRetriedAuthRefresh: true,
      skipAuthDeferredRetry: false,
    );
    debugPrint(
      '[AuthRetry][RETRY_RESPONSE] status=${retryResponse.statusCode} body=${_stringifyResponseBodyForLog(retryResponse)}',
    );
    return retryResponse;
  }

  /// Convert a Dio fallback response into the GetX Response with full
  /// error-parsing and handleError logic.
  Response<dynamic> _handleDioFallbackResponse(
      dynamic dioResponse, String uri, bool handleError) {
    final int statusCode = (dioResponse.statusCode as int?) ?? 0;
    final dynamic rawBody = dioResponse.data;

    // Dio already parsed JSON; serialise back only if needed for bodyString
    final String bodyString = rawBody is String
        ? rawBody
        : (rawBody != null ? jsonEncode(rawBody) : '');

    // Extract headers into Map<String,String>
    final Map<String, String> headersMap = {};
    try {
      (dioResponse.headers.map as Map).forEach((k, v) {
        headersMap[k.toString()] = (v is List) ? v.join(',') : v.toString();
      });
    } catch (_) {}
    _updateServerTimeOffsetFromHeaders(headersMap);

    // Build request info from requestOptions
    String reqMethod = 'GET';
    Uri reqUrl = Uri.parse(uri);
    Map<String, String> reqHeaders = {};
    try {
      reqMethod = dioResponse.requestOptions.method?.toString() ?? 'GET';
      reqUrl = dioResponse.requestOptions.uri ?? Uri.parse(uri);
      (dioResponse.requestOptions.headers as Map)
          .forEach((k, v) => reqHeaders[k.toString()] = v.toString());
    } catch (_) {}

    Response<dynamic> response0 = Response<dynamic>(
      body: rawBody,
      bodyString: bodyString,
      request: Request(headers: reqHeaders, method: reqMethod, url: reqUrl),
      headers: headersMap,
      statusCode: statusCode,
      statusText: dioResponse.statusMessage?.toString() ?? 'Unknown',
    );

    // Clean and translate message text
    String cleanMessage(String? text) {
      if (text == null) return '';
      final String cleaned = text.replaceFirst('messages.', '').trim();
      return BackendMessageTranslator.translate(cleaned);
    }

    if (response0.statusCode != 200 &&
        response0.body != null &&
        response0.body is! String) {
      try {
        if (response0.body is Map<String, dynamic> &&
            response0.body.toString().startsWith('{errors: [{code:')) {
          final ErrorResponse errorResponse =
              ErrorResponse.fromJson(response0.body as Map<String, dynamic>);
          response0 = Response(
            statusCode: response0.statusCode,
            body: response0.body,
            statusText: cleanMessage(
              errorResponse.errors?.isNotEmpty == true
                  ? errorResponse.errors!.first.message
                  : 'Unknown error',
            ),
          );
        } else if (response0.body.toString().startsWith('{message')) {
          String messageText = '';
          if (response0.body is Map) {
            messageText = (response0.body as Map)['message']?.toString() ?? '';
          }
          response0 = Response(
            statusCode: response0.statusCode,
            body: response0.body,
            statusText: cleanMessage(messageText),
          );
        } else if (response0.body is Map) {
          final String errorMessage =
              extractErrorMessage(response0.body, response0.statusText);
          response0 = Response(
            statusCode: response0.statusCode,
            body: response0.body,
            statusText: cleanMessage(errorMessage),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error parsing error response: $e');
        }
        response0 = Response(
          statusCode: response0.statusCode,
          body: response0.body,
          statusText: 'Error parsing response',
        );
      }
    } else if (response0.statusCode != 200 && response0.body == null) {
      response0 = Response(statusCode: 0, statusText: noInternetMessage);
    }

    response0 = Response(
      statusCode: response0.statusCode,
      body: response0.body,
      statusText: cleanMessage(response0.statusText),
      bodyString: response0.bodyString,
      request: response0.request,
      headers: response0.headers,
    );

    if (handleError) {
      if (response0.statusCode == 200 || response0.statusCode == 201) {
        return response0;
      } else if (response0.statusCode == 429) {
        return response0;
      } else if (response0.statusCode == 405) {
        debugPrint('\x1B[32m     /////////////    \x1B[0m');
        return response0;
      } else {
        ApiChecker.checkApi(response0, uri: uri);
        return response0;
      }
    } else {
      return response0;
    }
  }

  /// Get security status
  Map<String, dynamic> getSecurityStatus() {
    return {
      'secureTokenStorage': SecureTokenStorage.getSecurityStatus(),
      'certificatePinning': CertificatePinningService.getSecurityStatus(),
      'secureHttpClient': _useSecureClient
          ? _secureHttpClient.getSecurityStatus()
          : {'isInitialized': false},
      'useSecureClient': _useSecureClient,
    };
  }

  /// Test security features
  Future<bool> testSecurityFeatures() async {
    try {
      // Test secure token storage
      final tokenTest = await SecureTokenStorage.hasValidToken();
      if (!tokenTest) {
        if (kDebugMode) {
          debugPrint('❌ Token storage test failed');
        }
        return false;
      }

      // Test certificate pinning
      final certTest =
          await CertificatePinningService.testCertificatePinning(appBaseUrl);
      if (!certTest) {
        if (kDebugMode) {
          debugPrint('❌ Certificate pinning test failed');
        }
        return false;
      }

      // Test secure HTTP client if available
      if (_useSecureClient) {
        final httpTest = await _secureHttpClient.testSecurityFeatures();
        if (!httpTest) {
          if (kDebugMode) {
            debugPrint('❌ Secure HTTP client test failed');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ API Client security test failed: $e');
      }
      return false;
    }
  }

  /// Safely extract error message from response
  String extractErrorMessage(dynamic responseBody, String? statusText) {
    try {
      if (responseBody == null) {
        return statusText ?? 'Unknown error';
      }

      if (responseBody is String) {
        return responseBody.isNotEmpty
            ? responseBody
            : (statusText ?? 'Unknown error');
      }

      if (responseBody is Map) {
        final Map<String, dynamic> bodyMap =
            Map<String, dynamic>.from(responseBody);

        // Try different error message fields
        final String? errorMessage = bodyMap['error_message']?.toString() ??
            bodyMap['error']?.toString() ??
            bodyMap['message']?.toString() ??
            bodyMap['detail']?.toString() ??
            bodyMap['description']?.toString();

        if (errorMessage != null && errorMessage.isNotEmpty) {
          return errorMessage;
        }
      }

      return statusText ?? 'Unknown error';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error extracting error message: $e');
      }
      return statusText ?? 'Unknown error';
    }
  }
}

class MultipartBody {
  String key;
  XFile? file;

  MultipartBody(this.key, this.file);
}