
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Centralized API call management system to prevent duplicate calls and optimize performance
/// Now with persistent disk caching for offline support and instant app startup
class ApiCallManager extends GetxService {
  static ApiCallManager get instance => Get.find<ApiCallManager>();

  // Track ongoing API calls to prevent duplicates
  final Map<String, Completer<dynamic>> _ongoingCalls = {};

  // Memory cache for API responses with TTL (fast, volatile)
  final Map<String, CacheEntry> _responseCache = {};

  // Disk cache for persistent storage (survives app restarts)
  final Map<String, DiskCacheEntry> _diskCache = {};
  SharedPreferences? _prefs;
  bool _diskCacheLoaded = false;

  // Request debouncing
  final Map<String, Timer> _debounceTimers = {};

  // API call statistics
  int _totalCalls = 0;
  int _duplicateCallsPrevented = 0;
  int _cacheHits = 0;
  int _diskCacheHits = 0;

  static const String _cacheVersion = 'v1';
  static const String _cacheKeyPrefix = 'api_cache_${_cacheVersion}_';

  @override
  void onInit() {
    super.onInit();
    _initDiskCache();
    if (kDebugMode) {
      debugPrint('🚀 ApiCallManager initialized with persistent caching');
    }
  }

  /// Initialize disk cache by loading from SharedPreferences
  Future<void> _initDiskCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadDiskCache();
      _diskCacheLoaded = true;
      if (kDebugMode) {
        debugPrint('💾 Disk cache loaded: ${_diskCache.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load disk cache: $e');
      }
    }
  }

  /// Execute API call with deduplication and caching (Memory → Disk → API)
  Future<T> executeCall<T>(
    String callId,
    Future<T> Function() apiCall, {
    Duration cacheDuration = const Duration(minutes: 5),
    Duration debounceDuration = const Duration(milliseconds: 300),
    bool enableCaching = true,
    bool enableDebouncing = true,
  }) async {
    _totalCalls++;

    // 1. Check memory cache first (fastest)
    if (enableCaching && _responseCache.containsKey(callId)) {
      final cacheEntry = _responseCache[callId]!;
      if (DateTime.now().isBefore(cacheEntry.expiresAt)) {
        _cacheHits++;
        if (kDebugMode) {
          debugPrint('📦 Memory cache hit: $callId');
        }
        return cacheEntry.data as T;
      } else {
        _responseCache.remove(callId);
      }
    }

    // 2. Check disk cache (persistent, survives app restart)
    if (enableCaching && _diskCacheLoaded && _diskCache.containsKey(callId)) {
      final diskEntry = _diskCache[callId]!;
      if (DateTime.now().isBefore(diskEntry.expiresAt)) {
        _diskCacheHits++;
        if (kDebugMode) {
          debugPrint('💾 Disk cache hit: $callId');
        }
        // Load disk cache into memory cache for faster subsequent access
        _responseCache[callId] = CacheEntry(
          data: diskEntry.data,
          expiresAt: diskEntry.expiresAt,
        );
        return diskEntry.data as T;
      } else {
        _diskCache.remove(callId);
        await _removeDiskCacheEntry(callId);
      }
    }

    // 3. Check if call is already ongoing
    if (_ongoingCalls.containsKey(callId)) {
      _duplicateCallsPrevented++;
      if (kDebugMode) {
        debugPrint('🚫 Preventing duplicate call: $callId');
      }
      return await _ongoingCalls[callId]!.future as T;
    }

    // 4. Debounce rapid successive calls
    if (enableDebouncing && _debounceTimers.containsKey(callId)) {
      _debounceTimers[callId]?.cancel();
    }

    if (enableDebouncing) {
      final completer = Completer<T>();
      _debounceTimers[callId] = Timer(debounceDuration, () async {
        try {
          final result = await _executeWithDeduplication(
              callId, apiCall, cacheDuration, enableCaching);
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      });
      return completer.future;
    } else {
      return await _executeWithDeduplication(
          callId, apiCall, cacheDuration, enableCaching);
    }
  }

  Future<T> _executeWithDeduplication<T>(
    String callId,
    Future<T> Function() apiCall,
    Duration cacheDuration,
    bool enableCaching,
  ) async {
    final completer = Completer<T>();
    _ongoingCalls[callId] = completer;

    try {
      if (kDebugMode) {
        debugPrint('🌐 Executing API call: $callId');
      }

      final result = await apiCall();

      if (enableCaching) {
        // Cache in memory for fast access
        _responseCache[callId] = CacheEntry(
          data: result,
          expiresAt: DateTime.now().add(cacheDuration),
        );

        // Cache to disk for persistence across app restarts
        await _saveToDiskCache(callId, result, cacheDuration);
      }

      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _ongoingCalls.remove(callId);
    }
  }

  /// Load all disk cache entries from SharedPreferences
  Future<void> _loadDiskCache() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (!key.startsWith(_cacheKeyPrefix)) continue;

      try {
        final jsonString = _prefs!.getString(key);
        if (jsonString == null) continue;

        final Map<String, dynamic> json =
            jsonDecode(jsonString) as Map<String, dynamic>;
        final callId = key.substring(_cacheKeyPrefix.length);

        _diskCache[callId] = DiskCacheEntry(
          data: json['data'],
          expiresAt: DateTime.parse(json['expiresAt'] as String),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️  Failed to load disk cache entry: $key');
        }
      }
    }
  }

  /// Save data to disk cache
  Future<void> _saveToDiskCache(
      String callId, dynamic data, Duration cacheDuration) async {
    if (_prefs == null) return;

    try {
      // #region agent log
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        try {
          final logFile =
              File(r'c:\Users\pc\Desktop\clone\app-test\.cursor\debug.log');
          logFile.writeAsStringSync(
              '${jsonEncode({
                    "location": "api_call_manager.dart:203",
                    "message": "_saveToDiskCache entry",
                    "data": {
                      "callId": callId,
                      "dataType": data.runtimeType.toString()
                    },
                    "timestamp": DateTime.now().millisecondsSinceEpoch,
                    "sessionId": "debug-session",
                    "runId": "run1",
                    "hypothesisId": "A"
                  })}\n',
              mode: FileMode.append);
        } catch (e) { if (kDebugMode) debugPrint('$e'); }
      }
      // #endregion

      final expiresAt = DateTime.now().add(cacheDuration);

      // Convert model objects to JSON if they have toJson() method
      dynamic dataToEncode = data;
      if (data != null &&
          data is! Map &&
          data is! List &&
          data is! String &&
          data is! int &&
          data is! double &&
          data is! bool) {
        // Try to call toJson() if available (for model objects)
        try {
          dataToEncode = (data as dynamic).toJson();
        } catch (e) {
          // If toJson() doesn't exist, jsonEncode will fail with a clear error
        }
      }

      final json = jsonEncode({
        'data': dataToEncode,
        'expiresAt': expiresAt.toIso8601String(),
      });

      await _prefs!.setString('$_cacheKeyPrefix$callId', json);

      _diskCache[callId] = DiskCacheEntry(
        data: data,
        expiresAt: expiresAt,
      );

      if (kDebugMode) {
        debugPrint('💾 Saved to disk cache: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save to disk cache: $callId - $e');
      }
    }
  }

  /// Remove specific disk cache entry
  Future<void> _removeDiskCacheEntry(String callId) async {
    if (_prefs == null) return;
    await _prefs!.remove('$_cacheKeyPrefix$callId');
  }

  /// Clear cache for specific call or all calls (both memory and disk)
  Future<void> clearCache([String? callId]) async {
    if (callId != null) {
      _responseCache.remove(callId);
      _diskCache.remove(callId);
      await _removeDiskCacheEntry(callId);
      if (kDebugMode) {
        debugPrint('🗑️ Cleared cache for: $callId');
      }
    } else {
      _responseCache.clear();
      _diskCache.clear();
      if (_prefs != null) {
        final keys = _prefs!
            .getKeys()
            .where((k) => k.startsWith(_cacheKeyPrefix))
            .toList();
        for (final key in keys) {
          await _prefs!.remove(key);
        }
      }
      if (kDebugMode) {
        debugPrint('🗑️ Cleared all cache (memory + disk)');
      }
    }
  }

  /// Cancel ongoing call
  void cancelCall(String callId) {
    _ongoingCalls[callId]?.completeError('Cancelled');
    _ongoingCalls.remove(callId);
    _debounceTimers[callId]?.cancel();
    _debounceTimers.remove(callId);
  }

  /// Get API call statistics
  Map<String, dynamic> getStatistics() {
    final totalCacheHits = _cacheHits + _diskCacheHits;
    return {
      'totalCalls': _totalCalls,
      'duplicateCallsPrevented': _duplicateCallsPrevented,
      'memoryCacheHits': _cacheHits,
      'diskCacheHits': _diskCacheHits,
      'totalCacheHits': totalCacheHits,
      'ongoingCalls': _ongoingCalls.length,
      'memoryCachedResponses': _responseCache.length,
      'diskCachedResponses': _diskCache.length,
      'cacheHitRate': _totalCalls > 0
          ? (totalCacheHits / _totalCalls * 100).toStringAsFixed(2)
          : '0',
    };
  }

  /// Generate unique call ID for API endpoint
  /// ⚡ PERFORMANCE: Normalizes cache-busting parameters to prevent duplicate calls
  static String generateCallId(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return endpoint;
    }

    // ⚡ PERFORMANCE: Remove cache-busting parameters that don't affect response
    // These are added by client but don't change what backend returns
    final normalizedParams = Map<String, dynamic>.from(params);
    normalizedParams.removeWhere((key, value) =>
            key.startsWith('_t') || // Timestamp
            key.startsWith('_r') || // Random
            key.startsWith('_cb') || // Cache buster
            key.startsWith('_nc') || // No cache
            key.startsWith('_uuid') || // UUID
            key.startsWith('_v') || // Version
            key.startsWith('_rand') // Random number
        );

    if (normalizedParams.isEmpty) {
      return endpoint;
    }

    // Sort parameters for consistent callId generation
    final sortedKeys = normalizedParams.keys.toList()..sort();
    final paramString =
        sortedKeys.map((key) => '$key=${normalizedParams[key]}').join('&');

    return '$endpoint?$paramString';
  }

  @override
  void onClose() {
    // Cancel all ongoing calls
    for (final completer in _ongoingCalls.values) {
      completer.completeError('Service disposed');
    }
    _ongoingCalls.clear();

    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    super.onClose();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  CacheEntry({required this.data, required this.expiresAt});
}

class DiskCacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  DiskCacheEntry({required this.data, required this.expiresAt});
}
