import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

import '../coupon_list_filters.dart';
import '../models/my_coupon_models.dart';
import 'coupon_repository_interface.dart';

String _couponLogBody(dynamic body) {
  try {
    if (body == null) {
      return '';
    }
    if (body is String) {
      return body;
    }
    return jsonEncode(body);
  } catch (_) {
    return body.toString();
  }
}

void _appendJsonStrings(dynamic node, StringBuffer buffer) {
  if (node == null) {
    return;
  }
  if (node is String) {
    buffer.write(' ');
    buffer.write(node);
    return;
  }
  if (node is num || node is bool) {
    buffer.write(' ');
    buffer.write(node.toString());
    return;
  }
  if (node is Map) {
    for (final Object? key in node.keys) {
      _appendJsonStrings(key, buffer);
    }
    for (final Object? value in node.values) {
      _appendJsonStrings(value, buffer);
    }
    return;
  }
  if (node is List) {
    for (final Object? element in node) {
      _appendJsonStrings(element, buffer);
    }
  }
}

String _normCouponField(dynamic value) {
  return value?.toString().trim().toLowerCase() ?? '';
}

String _truncateMyCouponsLog(String value, int maxChars) {
  if (value.length <= maxChars) {
    return value;
  }
  return '${value.substring(0, maxChars)}…(truncated len=${value.length})';
}

String _maskMyCouponsHeaders(Map<String, String> headers) {
  final Map<String, String> copy = Map<String, String>.from(headers);
  void maskAuth(String key) {
    if (!copy.containsKey(key)) {
      return;
    }
    final String v = copy[key] ?? '';
    copy[key] = v.length > 12 ? '${v.substring(0, 12)}…' : '(set)';
  }
  maskAuth('Authorization');
  maskAuth('authorization');
  return copy.toString();
}

List<dynamic>? _extractMyCouponsRawList(dynamic body) {
  if (body == null) {
    return null;
  }
  if (body is List) {
    return body;
  }
  if (body is String) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded;
      }
      if (decoded is Map) {
        return _listFromMapWrapper(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }
  if (body is Map) {
    return _listFromMapWrapper(Map<String, dynamic>.from(body));
  }
  return null;
}

List<dynamic>? _listFromMapWrapper(Map<String, dynamic> map) {
  final dynamic data = map['data'] ?? map['coupons'] ?? map['items'];
  if (data is List) {
    return data;
  }
  return null;
}

/// Maps backend JSON (code/message/errors) to a GetX translation key.
String _couponApplyErrorMessageKeyFromBody(Map<String, dynamic> body) {
  final StringBuffer buffer = StringBuffer();
  _appendJsonStrings(body, buffer);
  final String blob = buffer.toString().toLowerCase();
  const Set<String> alreadyUsedCodes = <String>{
    'already_used',
    'coupon_used',
    'used_coupon',
    'coupon_already_used',
  };
  final String topCode = _normCouponField(body['code']);
  final String topError = _normCouponField(body['error']);
  if (alreadyUsedCodes.contains(topCode) || alreadyUsedCodes.contains(topError)) {
    return 'coupon_error_already_used';
  }
  final dynamic errors = body['errors'];
  if (errors is Map) {
    for (final Object? key in errors.keys) {
      if (alreadyUsedCodes.contains(_normCouponField(key))) {
        return 'coupon_error_already_used';
      }
    }
    for (final Object? value in errors.values) {
      if (value is List) {
        for (final Object? item in value) {
          if (alreadyUsedCodes.contains(_normCouponField(item))) {
            return 'coupon_error_already_used';
          }
        }
      }
    }
  }
  if (blob.contains('already used') ||
      blob.contains('used before') ||
      blob.contains('previously used') ||
      blob.contains('was used') ||
      blob.contains('تم استخدام') ||
      blob.contains('استخدامه مسبق') ||
      blob.contains('مسبقًا') ||
      blob.contains('مسبقا') ||
      blob.contains('already_used') ||
      blob.contains('coupon_already_used') ||
      blob.contains('used_coupon')) {
    return 'coupon_error_already_used';
  }
  if (blob.contains('expired') ||
      blob.contains('expiration') ||
      blob.contains('انتهت صلاحية') ||
      blob.contains('منتهي الصلاحية') ||
      blob.contains('منتهية')) {
    return 'coupon_error_expired';
  }
  if (blob.contains('minimum') ||
      blob.contains('min_purchase') ||
      blob.contains('min purchase') ||
      blob.contains('below minimum') ||
      blob.contains('minimum purchase') ||
      blob.contains('minimum order') ||
      blob.contains('الحد الأدنى') ||
      blob.contains('اقل من الحد') ||
      blob.contains('أقل من الحد')) {
    return 'coupon_error_below_minimum';
  }
  if (blob.contains('invalid') ||
      blob.contains('not found') ||
      blob.contains('does not exist') ||
      blob.contains('غير صالح') ||
      blob.contains('غير موجود')) {
    return 'coupon_error_invalid_code';
  }
  return 'coupon_error_invalid_code';
}

class CouponRepository implements CouponRepositoryInterface {
  CouponRepository({required this.apiClient});

  final ApiClient apiClient;

  /// Last failure from [applyCoupon] for UI (e.g. suppress "invalid" on 304 empty body).
  static String? applyCouponLastFailureReason;

  /// GetX key for [showCustomSnackBar] after apply failure (set with [applyCouponLastFailureReason]).
  static String? applyCouponLastMessageKey;

  static const Map<String, String> _couponApplyNoCacheHeaders = <String, String>{
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  @override
  Future getList({int? offset, bool couponList = false, bool taxiCouponList = false}) async {
    if (couponList) {
      return await _getCouponList();
    } else if (taxiCouponList) {
      return await _getTaxiCouponList();
    }
  }

  Future<List<CouponModel>?> _getCouponList() async {
    // 🟢 BUILD MARKER (unconditional): if this line does NOT print at runtime,
    // the device is running a STALE build — do a full clean rebuild + reinstall.
    debugPrint('[MyCoupons][RUNTIME_VERSION] LIST_ALL_CACHEBUST_2026_06_07_B');
    // ✅ FIX: MyCoupons must call /coupon/list/all — it returns global coupons
    // (e.g. customer_id=["all"] like TEST30M6). /coupon/list returned an empty []
    // for these because it only lists customer-assigned coupons.
    // ✅ CACHE-BUST: append ?_t=<ms> so no URL-level cache (CDN/proxy/local) can
    // ever serve a stale empty response for this endpoint.
    final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
    final String relativePath = '${AppConstants.couponListAllUri}?_t=$cacheBuster';
    final Map<String, String> headers = apiClient.getHeader();
    if (kDebugMode) {
      // 🔎 DIAGNOSTIC: exact endpoint + full URL + every relevant header.
      debugPrint('[MyCoupons][ENDPOINT] $relativePath');
      debugPrint('[MyCoupons][FULL_URL] ${apiClient.appBaseUrl}$relativePath');
      debugPrint('[MyCoupons][METHOD] GET (useEtag=false → no If-None-Match, no-cache, cacheBust=$cacheBuster)');
      debugPrint(
        '[MyCoupons][HDR] zoneId=${headers['zoneId'] ?? '(none)'} '
        'zone-id=${headers['zone-id'] ?? '(none)'}',
      );
      debugPrint(
        '[MyCoupons][HDR] moduleId=${headers['moduleId'] ?? '(none)'} '
        'module-id=${headers['module-id'] ?? '(none)'}',
      );
      debugPrint(
        '[MyCoupons][HDR] X-localization='
        '${headers['X-localization'] ?? headers['x-localization'] ?? '(none)'}',
      );
      final String auth =
          headers['Authorization'] ?? headers['authorization'] ?? '';
      debugPrint(
        '[MyCoupons][HDR] authorization='
        '${auth.isEmpty ? '(none)' : '${auth.length > 16 ? auth.substring(0, 16) : auth}…'}',
      );
      debugPrint(
        '[MyCoupons][HEADERS_ALL] ${_maskMyCouponsHeaders(headers)}',
      );
    }
    final Response response = await apiClient.getData(
      relativePath,
      useEtag: false, // bypass ETag/If-None-Match so we never serve a stale empty []
      headers: _couponApplyNoCacheHeaders,
    );
    final dynamic rawBody = response.body;
    final String rawType = rawBody == null
        ? 'null'
        : rawBody.runtimeType.toString();
    if (kDebugMode) {
      debugPrint('[MyCoupons][STATUS] ${response.statusCode}');
      debugPrint('[MyCoupons][RAW_TYPE] $rawType');
      debugPrint(
        '[MyCoupons][RAW_BODY] ${_truncateMyCouponsLog(_couponLogBody(rawBody), 4000)}',
      );
    }
    if (response.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('[MyCoupons][PARSED_COUNT] 0');
        debugPrint('[MyCoupons][FILTERED_COUNT] n/a');
        debugPrint(
          '[MyCoupons][EMPTY_REASON] http_status_${response.statusCode}',
        );
      }
      return null;
    }
    final List<dynamic>? rawList = _extractMyCouponsRawList(rawBody);
    if (rawList == null) {
      if (kDebugMode) {
        debugPrint('[MyCoupons][PARSED_COUNT] 0');
        debugPrint('[MyCoupons][FILTERED_COUNT] n/a');
        debugPrint(
          '[MyCoupons][EMPTY_REASON] body_not_decodable_list_or_known_wrapper',
        );
      }
      return <CouponModel>[];
    }
    final List<CouponModel> couponList = <CouponModel>[];
    int parseFailCount = 0;
    for (final dynamic element in rawList) {
      if (element is! Map) {
        parseFailCount++;
        continue;
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(element);
      try {
        final CouponModel coupon = CouponModel.fromJson(map);
        coupon.toolTip = JustTheController();
        couponList.add(coupon);
        if (kDebugMode) {
          final bool expired = couponIsExpiredByDate(coupon);
          debugPrint(
            '[MyCoupons][ITEM_STATE] code=${coupon.code ?? ''} isUsed=${coupon.isUsed} isExpired=$expired',
          );
        }
      } catch (e) {
        parseFailCount++;
        if (kDebugMode) {
          debugPrint('[MyCoupons][PARSE_ITEM_FAIL] e=$e');
        }
      }
    }
    if (kDebugMode) {
      debugPrint('[MyCoupons][PARSED_COUNT] ${couponList.length}');
      final int firstTabNotExpired = countNotExpiredByDateCoupons(couponList);
      final int usable = countUsableCoupons(couponList);
      final int usedNotExpired = countUsedNotExpiredCoupons(couponList);
      final int expiredByDate = countExpiredTabCoupons(couponList);
      debugPrint(
        '[MyCoupons][FILTERED_COUNT] first_tab_not_expired=$firstTabNotExpired '
        'usable=$usable used_not_expired=$usedNotExpired expired_by_date=$expiredByDate',
      );
      if (parseFailCount > 0) {
        debugPrint('[MyCoupons][PARSE_FAIL_COUNT] $parseFailCount');
      }
      if (couponList.isEmpty) {
        final String reason = rawList.isEmpty
            ? 'empty_array_from_api'
            : 'all_list_items_failed_parse_or_not_map';
        debugPrint('[MyCoupons][EMPTY_REASON] $reason');
      }
    }
    return couponList;
  }

  Future<List<CouponModel>?> _getTaxiCouponList() async {
    List<CouponModel>? taxiCouponList;
    final Response response = await apiClient.getData(AppConstants.taxiCouponUri);
    if (response.statusCode == 200) {
      taxiCouponList = [];
      for (var category in (response.body as List)) {
        taxiCouponList.add(CouponModel.fromJson(category as Map<String, dynamic>));
      }
    }
    return taxiCouponList;
  }

  String _buildCouponApplyRelativePath(String code, int? storeID) {
    final StringBuffer buffer = StringBuffer(AppConstants.couponApplyUri);
    buffer.write(Uri.encodeQueryComponent(code));
    if (storeID != null) {
      buffer.write('&store_id=$storeID');
    }
    return buffer.toString();
  }

  CouponModel? _parseCouponApplyBody(Response response) {
    if (response.statusCode != 200) {
      return null;
    }
    final dynamic body = response.body;
    if (body is! Map<String, dynamic>) {
      return null;
    }
    try {
      return CouponModel.fromJson(body);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Coupon][APPLY_FAIL] reason=parse_error e=$e');
      }
      return null;
    }
  }

  @override
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID) async {
    applyCouponLastFailureReason = null;
    applyCouponLastMessageKey = null;
    final String code = couponCode.trim();
    if (code.isEmpty) {
      applyCouponLastFailureReason = 'empty_code';
      applyCouponLastMessageKey = null;
      if (kDebugMode) {
        debugPrint('[Coupon][REQUEST] skipped: empty code after trim');
        debugPrint('[Coupon][APPLY_FAIL] reason=empty_code');
      }
      return null;
    }
    final String applyPath = _buildCouponApplyRelativePath(code, storeID);
    if (kDebugMode) {
      debugPrint('[Coupon][REQUEST] method=GET url=$applyPath');
      debugPrint('[Coupon][CACHE] etagDisabled=true forceRefresh=true');
    }
    Response response = await apiClient.getData(
      applyPath,
      handleError: false,
      useEtag: false,
      headers: _couponApplyNoCacheHeaders,
    );
    if (kDebugMode) {
      debugPrint(
        '[Coupon][RESPONSE] status=${response.statusCode} body=${_couponLogBody(response.body)}',
      );
    }
    CouponModel? model = _parseCouponApplyBody(response);
    if (model != null) {
      return model;
    }
    if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint(
          '[Coupon][304_RETRY] retryingWithCacheBypass=true url=$applyPath&_t=...',
        );
      }
      final String retryPath =
          '$applyPath&_t=${DateTime.now().millisecondsSinceEpoch}';
      if (kDebugMode) {
        debugPrint('[Coupon][304_RETRY] fullRetryUrl=$retryPath');
      }
      response = await apiClient.getData(
        retryPath,
        handleError: false,
        useEtag: false,
        headers: _couponApplyNoCacheHeaders,
      );
      if (kDebugMode) {
        debugPrint(
          '[Coupon][RESPONSE] status=${response.statusCode} body=${_couponLogBody(response.body)}',
        );
      }
      model = _parseCouponApplyBody(response);
      if (model != null) {
        return model;
      }
      applyCouponLastFailureReason = '304_empty_body_after_retry';
      applyCouponLastMessageKey = null;
      if (kDebugMode) {
        debugPrint('[Coupon][APPLY_FAIL] reason=304_empty_body_after_retry');
      }
      return null;
    }
    if (response.statusCode == 200) {
      applyCouponLastFailureReason = 'invalid_coupon_json_or_shape';
      final dynamic rawOk = response.body;
      if (rawOk is Map) {
        applyCouponLastMessageKey = _couponApplyErrorMessageKeyFromBody(
          Map<String, dynamic>.from(rawOk),
        );
      } else {
        applyCouponLastMessageKey = 'coupon_error_invalid_code';
      }
      if (kDebugMode) {
        debugPrint(
          '[Coupon][APPLY_FAIL] reason=$applyCouponLastFailureReason messageKey=$applyCouponLastMessageKey body=${_couponLogBody(response.body)}',
        );
      }
      return null;
    }
    final dynamic errorBody = response.body;
    if (errorBody is Map) {
      final Map<String, dynamic> errorMap =
          Map<String, dynamic>.from(errorBody);
      applyCouponLastFailureReason = 'http_${response.statusCode}_body';
      applyCouponLastMessageKey = _couponApplyErrorMessageKeyFromBody(errorMap);
      if (kDebugMode) {
        debugPrint(
          '[Coupon][APPLY_FAIL] reason=$applyCouponLastFailureReason messageKey=$applyCouponLastMessageKey body=${_couponLogBody(response.body)}',
        );
      }
      return null;
    }
    applyCouponLastFailureReason = 'http_${response.statusCode}';
    applyCouponLastMessageKey = 'coupon_error_invalid_code';
    if (kDebugMode) {
      debugPrint('[Coupon][APPLY_FAIL] reason=$applyCouponLastFailureReason');
    }
    return null;
  }

  @override
  Future<CouponModel?> applyTaxiCoupon(String couponCode, int? providerId) async {
    CouponModel? taxiCouponModel;
    final Response response = await apiClient.getData('${AppConstants.taxiCouponApplyUri}$couponCode&provider_id=$providerId');
    if (response.statusCode == 200) {
      taxiCouponModel = CouponModel.fromJson(response.body as Map<String, dynamic>);
    }
    return taxiCouponModel;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
