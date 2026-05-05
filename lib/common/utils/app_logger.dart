/*
 * App Logger Utility
 * 
 * This file provides comprehensive logging functionality for the application.
 * It includes log filtering, throttling, page-level logging, and API call tracking.
 * 
 * Features:
 * - Filter system-level logs (EGL_emulation, etc.)
 * - Throttle frequent logs
 * - Page lifecycle tracking
 * - API call logging with details
 * - Performance metrics
 */

import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/secure_log.dart';

/// Log levels for different types of messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
  api,
  page,
}

/// App Logger Singleton
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  // Log filtering configuration
  bool _enableLogging = kDebugMode;
  bool _filterEGLLogs = true;
  bool _enablePageLogging = true;
  bool _enableApiLogging = true;
  
  // Throttling for frequent logs
  final Map<String, DateTime> _lastLogTime = {};
  final Map<String, int> _logCounts = {};
  static const Duration _throttleInterval = Duration(seconds: 20);
  
  // Page tracking
  String? _currentPage;
  DateTime? _currentPageStartTime;
  final List<String> _currentPageApiCalls = [];
  
  // API call tracking
  final Map<String, List<Map<String, dynamic>>> _apiCallHistory = {};
  
  /// Initialize logger
  void initialize({
    bool enableLogging = true,
    bool filterEGLLogs = true,
    bool enablePageLogging = true,
    bool enableApiLogging = true,
  }) {
    _enableLogging = enableLogging && kDebugMode;
    _filterEGLLogs = filterEGLLogs;
    _enablePageLogging = enablePageLogging;
    _enableApiLogging = enableApiLogging;
  }
  
  /// Check if log should be throttled
  bool _shouldThrottle(String logKey) {
    if (_throttleInterval.inSeconds <= 0) return false;
    
    final now = DateTime.now();
    final lastTime = _lastLogTime[logKey];
    
    if (lastTime == null) {
      _lastLogTime[logKey] = now;
      _logCounts[logKey] = 1;
      return false;
    }
    
    final timeSinceLastLog = now.difference(lastTime);
    if (timeSinceLastLog >= _throttleInterval) {
      final count = _logCounts[logKey] ?? 0;
      if (count > 1) {
        _log(LogLevel.info, '[$logKey] Logged $count times in last ${_throttleInterval.inSeconds}s (throttled)', skipFilter: true);
      }
      _lastLogTime[logKey] = now;
      _logCounts[logKey] = 1;
      return false;
    }
    
    _logCounts[logKey] = (_logCounts[logKey] ?? 0) + 1;
    return true;
  }
  
  /// Filter system logs
  bool _shouldFilter(String message) {
    if (!_filterEGLLogs) return false;
    
    // Filter EGL_emulation logs
    if (message.contains('EGL_emulation') || 
        message.contains('app_time_stats')) {
      return true;
    }
    
    // Filter other system logs if needed
    if (message.contains('D/EGL_emulation') || 
        message.contains('I/EGL_emulation')) {
      return true;
    }
    
    // 🔧 TASK 4: Filter Google Maps SDK log spam
    // Trimming POINTS_LABELS spam from Google Maps SDK - it's drowning out performance metrics
    // Also filters Map initialization logs (m140.duh pattern)
    if (message.contains('I/m140.bcu') || 
        message.contains('POINTS_LABELS') ||
        message.contains('m140.bcu') ||
        message.contains('I/m140.duh') ||
        message.contains('m140.duh') ||
        (message.contains('m140') && message.contains('Map initialization'))) {
      return true;
    }
    
    return false;
  }
  
  /// Public method to check if message should be filtered (for debugPrint override)
  bool shouldFilterMessage(String message) {
    return _shouldFilter(message);
  }
  
  /// Public method to check if log should be throttled (for debugPrint override)
  bool shouldThrottleLog(String logKey) {
    return _shouldThrottle(logKey);
  }
  
  /// Internal log method
  void _log(LogLevel level, String message, {bool skipFilter = false}) {
    if (!_enableLogging) return;
    
    // Filter system logs unless explicitly skipped
    if (!skipFilter && _shouldFilter(message)) {
      // Check if we should throttle this log
      if (_shouldThrottle('EGL_emulation')) {
        return;
      }
    }
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final levelPrefix = _getLevelPrefix(level);
    final pagePrefix = _currentPage != null ? '[$_currentPage]' : '';
    
    final logMessage = '[$timestamp]$pagePrefix $levelPrefix $message';
    
    debugPrint(logMessage);
  }
  
  /// Get level prefix
  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 DEBUG';
      case LogLevel.info:
        return 'ℹ️ INFO';
      case LogLevel.warning:
        return '⚠️ WARN';
      case LogLevel.error:
        return '❌ ERROR';
      case LogLevel.api:
        return '🌐 API';
      case LogLevel.page:
        return '📱 PAGE';
    }
  }
  
  /// Log page entry
  void logPageEntry(String pageName) {
    if (!_enablePageLogging) return;
    
    // Log page exit if there was a previous page
    if (_currentPage != null && _currentPage != pageName) {
      logPageExit();
    }
    
    _currentPage = pageName;
    _currentPageStartTime = DateTime.now();
    _currentPageApiCalls.clear();
    
    _log(LogLevel.page, 'Entered page: $pageName');
  }
  
  /// Log page exit
  void logPageExit() {
    if (!_enablePageLogging || _currentPage == null) return;
    
    final duration = _currentPageStartTime != null
        ? DateTime.now().difference(_currentPageStartTime!)
        : Duration.zero;
    
    final apiCallCount = _currentPageApiCalls.length;
    
    _log(LogLevel.page, 
        'Exited page: $_currentPage | Duration: ${duration.inSeconds}s | API Calls: $apiCallCount');
    
    if (apiCallCount > 0 && _enableApiLogging) {
      _log(LogLevel.page, 'API calls made in $_currentPage:');
      for (var i = 0; i < _currentPageApiCalls.length; i++) {
        _log(LogLevel.page, '  ${i + 1}. ${_currentPageApiCalls[i]}');
      }
    }
    
    _currentPage = null;
    _currentPageStartTime = null;
    _currentPageApiCalls.clear();
  }
  
  /// Log API call start
  void logApiCallStart(String method, String uri, {Map<String, dynamic>? query, Map<String, String>? headers}) {
    if (!_enableApiLogging) return;
    
    final apiInfo = {
      'method': method,
      'uri': uri,
      'timestamp': DateTime.now().toIso8601String(),
      'query': query?.toString() ?? 'none',
    };
    
    // Track in current page
    if (_currentPage != null) {
      _currentPageApiCalls.add('$method $uri');
    }
    
    // Track in history
    if (!_apiCallHistory.containsKey(_currentPage ?? 'unknown')) {
      _apiCallHistory[_currentPage ?? 'unknown'] = [];
    }
    _apiCallHistory[_currentPage ?? 'unknown']!.add(apiInfo);
    
    final queryStr = query != null && query.isNotEmpty ? '?${query.toString()}' : '';
    if (kDebugMode && headers != null && headers.isNotEmpty) {
      debugPrint(
          '[SECURE_LOG][MASKED_HEADERS] ${SecureLog.maskHeaders(headers)}');
    }
    final headerInfo = headers != null && headers.isNotEmpty
        ? ' | Header keys: ${headers.keys.join(", ")}'
        : '';

    _log(LogLevel.api, '→ $method $uri$queryStr$headerInfo');
  }
  
  /// Log API call success
  void logApiCallSuccess(String method, String uri, int statusCode, Duration duration, {dynamic response}) {
    if (!_enableApiLogging) return;
    
    final responseSize = response != null 
        ? _getResponseSize(response)
        : 'unknown';
    
    _log(LogLevel.api, 
        '✓ $method $uri | Status: $statusCode | Time: ${duration.inMilliseconds}ms | Size: $responseSize');
    
    // Log full response details if available
    if (response != null) {
      try {
        String responsePreview = '';
        if (response is String) {
          responsePreview = response.length > 500 ? '${response.substring(0, 500)}...' : response;
        } else if (response is Map) {
          final jsonStr = response.toString();
          responsePreview = jsonStr.length > 500 ? '${jsonStr.substring(0, 500)}...' : jsonStr;
        } else if (response is List) {
          final listStr = response.toString();
          responsePreview = listStr.length > 500 ? '${listStr.substring(0, 500)}...' : listStr;
        }
        
        if (responsePreview.isNotEmpty) {
          _log(LogLevel.api, '  Response: $responsePreview');
        }
      } catch (e) {
        // Silently fail - don't break logging
      }
    }
  }
  
  /// Log API call with full request and response details
  void logApiCallFull(String method, String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    dynamic body,
    int? statusCode,
    Duration? duration,
    dynamic response,
    String? error,
  }) {
    if (!_enableApiLogging) return;
    
    final queryStr = query != null && query.isNotEmpty ? '?${query.toString()}' : '';
    if (kDebugMode && headers != null && headers.isNotEmpty) {
      debugPrint(
          '[SECURE_LOG][MASKED_HEADERS] ${SecureLog.maskHeaders(headers)}');
    }
    final headerInfo = headers != null && headers.isNotEmpty
        ? ' | Header keys: ${headers.keys.join(", ")}'
        : '';
    final bodyInfo = body != null ? ' | Body: ${body.toString().length > 200 ? "${body.toString().substring(0, 200)}..." : body.toString()}' : '';

    _log(LogLevel.api, '→ $method $uri$queryStr$headerInfo$bodyInfo');
    
    if (statusCode != null && duration != null) {
      final responseSize = response != null ? _getResponseSize(response) : 'unknown';
      _log(LogLevel.api, 
          '✓ $method $uri | Status: $statusCode | Time: ${duration.inMilliseconds}ms | Size: $responseSize');
      
      // Log response preview
      if (response != null) {
        try {
          String responsePreview = '';
          if (response is String) {
            responsePreview = response.length > 1000 ? '${response.substring(0, 1000)}...' : response;
          } else if (response is Map) {
            final jsonStr = response.toString();
            responsePreview = jsonStr.length > 1000 ? '${jsonStr.substring(0, 1000)}...' : jsonStr;
          } else if (response is List) {
            final listStr = response.toString();
            responsePreview = listStr.length > 1000 ? '${listStr.substring(0, 1000)}...' : listStr;
          }
          
          if (responsePreview.isNotEmpty) {
            _log(LogLevel.api, '  Response Preview: $responsePreview');
          }
        } catch (e) {
          // Silently fail
        }
      }
    }
    
    if (error != null) {
      _log(LogLevel.error, '✗ $method $uri | Error: $error');
    }
  }
  
  /// Log API call error
  void logApiCallError(String method, String uri, String error, {int? statusCode, Duration? duration}) {
    if (!_enableApiLogging) return;
    
    final statusStr = statusCode != null ? ' | Status: $statusCode' : '';
    final timeStr = duration != null ? ' | Time: ${duration.inMilliseconds}ms' : '';
    
    _log(LogLevel.error, 
        '✗ $method $uri$statusStr$timeStr | Error: $error');
  }
  
  /// Get response size estimate
  String _getResponseSize(dynamic response) {
    try {
      if (response is String) {
        return '${response.length}B';
      } else if (response is Map || response is List) {
        return '${response.toString().length}B';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// Log debug message
  void debug(String message) {
    _log(LogLevel.debug, message);
  }
  
  /// Log info message
  void info(String message) {
    _log(LogLevel.info, message);
  }
  
  /// Log warning message
  void warning(String message) {
    _log(LogLevel.warning, message);
  }
  
  /// Log error message
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message);
    if (error != null) {
      _log(LogLevel.error, 'Error details: $error');
    }
    if (stackTrace != null) {
      _log(LogLevel.error, 'Stack trace: $stackTrace');
    }
  }
  
  /// Get API call history for current page
  List<Map<String, dynamic>> getCurrentPageApiCalls() {
    return List.from(_currentPageApiCalls.map((call) => {'call': call}));
  }
  
  /// Get API call history for a specific page
  List<Map<String, dynamic>> getPageApiCalls(String pageName) {
    return List.from(_apiCallHistory[pageName] ?? []);
  }
  
  /// Clear API call history
  void clearApiCallHistory() {
    _apiCallHistory.clear();
    _currentPageApiCalls.clear();
  }
  
  /// Get current page name
  String? getCurrentPage() => _currentPage;
}

/// Global logger instance
final appLogger = AppLogger();

