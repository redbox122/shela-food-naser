/*
 * Session Management Service
 * 
 * This file provides secure session management for the Indian Shella App.
 * It implements automatic session expiration, security monitoring, and
 * comprehensive session tracking for security purposes.
 * 
 * Features:
 * - Secure session management
 * - Automatic session expiration
 * - Security event logging
 * - Session monitoring
 * - Threat detection
 * - Security alerts
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'secure_token_storage.dart';
import 'package:sixam_mart/helper/string_extension.dart';

/// Session Management Service for security
/// Manages user sessions with security monitoring
class SessionManagementService {
  // Session configuration
  static const Duration _defaultSessionTimeout = Duration(hours: 24);
  static const Duration _inactiveSessionTimeout = Duration(hours: 2);
  static const Duration _securityCheckInterval = Duration(minutes: 5);
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  
  // Session state
  static DateTime? _sessionStartTime;
  static DateTime? _lastActivityTime;
  static String? _currentSessionId;
  static int _failedLoginAttempts = 0;
  static DateTime? _lockoutStartTime;
  static bool _isSessionActive = false;
  
  // Security monitoring
  static final List<SecurityEvent> _securityEvents = [];
  static final StreamController<SecurityAlert> _alertController = StreamController<SecurityAlert>.broadcast();
  
  // Timers
  static Timer? _sessionTimer;
  static Timer? _securityCheckTimer;
  
  /// Initialize session management service
  static Future<void> initialize() async {
    try {
      // Load existing session data
      await _loadSessionData();
      
      // Start security monitoring
      _startSecurityMonitoring();
      
      if (kDebugMode) {
        debugPrint('🔐 Session Management Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize Session Management Service: $e');
      }
    }
  }

  /// Start a new user session
  /// [userId] - User ID for the session
  /// [userRole] - User role for access control
  /// [sessionTimeout] - Custom session timeout
  /// Returns session ID if successful
  static Future<String?> startSession({
    required String userId,
    required String userRole,
    Duration? sessionTimeout,
  }) async {
    try {
      // Check if account is locked
      if (_isAccountLocked()) {
        _logSecurityEvent(
          SecurityEventType.loginBlocked,
          'Account locked due to multiple failed attempts',
          severity: SecuritySeverity.high,
        );
        return null;
      }

      // Generate session ID
      final sessionId = _generateSessionId(userId);
      
      // Set session state
      _currentSessionId = sessionId;
      _sessionStartTime = DateTime.now();
      _lastActivityTime = DateTime.now();
      _isSessionActive = true;
      
      // Save session data
      await _saveSessionData();
      
      // Start session timer
      _startSessionTimer(sessionTimeout ?? _defaultSessionTimeout);
      
      // Log session start
      _logSecurityEvent(
        SecurityEventType.sessionStarted,
        'User session started: $userId ($userRole)',
        metadata: {
          'userId': userId,
          'userRole': userRole,
          'sessionId': sessionId,
        },
      );
      
      if (kDebugMode) {
        debugPrint('🔐 Session started: $sessionId');
      }
      
      return sessionId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to start session: $e');
      }
      return null;
    }
  }

  /// End current session
  /// [reason] - Reason for session termination
  static Future<bool> endSession({String reason = 'User logout'}) async {
    try {
      if (!_isSessionActive) return true;
      
      // Clear session state
      _currentSessionId = null;
      _sessionStartTime = null;
      _lastActivityTime = null;
      _isSessionActive = false;
      
      // Stop timers
      _stopSessionTimer();
      
      // Clear secure tokens
      await SecureTokenStorage.clearToken();
      
      // Save session data
      await _saveSessionData();
      
      // Log session end
      _logSecurityEvent(
        SecurityEventType.sessionEnded,
        'User session ended: $reason',
        metadata: {'reason': reason},
      );
      
      if (kDebugMode) {
        debugPrint('🔐 Session ended: $reason');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to end session: $e');
      }
      return false;
    }
  }

  /// Update session activity
  /// Call this when user performs actions
  static Future<void> updateActivity() async {
    if (!_isSessionActive) return;
    
    _lastActivityTime = DateTime.now();
    await _saveSessionData();
    
    if (kDebugMode) {
      debugPrint('🔐 Session activity updated');
    }
  }

  /// Check if session is valid
  /// Returns true if session is active and not expired
  static bool isSessionValid() {
    if (!_isSessionActive || _currentSessionId == null) {
      return false;
    }
    
    // Check session timeout
    if (_sessionStartTime != null) {
      final sessionAge = DateTime.now().difference(_sessionStartTime!);
      if (sessionAge > _defaultSessionTimeout) {
        _handleSessionExpiration('Session timeout exceeded');
        return false;
      }
    }
    
    // Check inactivity timeout
    if (_lastActivityTime != null) {
      final inactivityAge = DateTime.now().difference(_lastActivityTime!);
      if (inactivityAge > _inactiveSessionTimeout) {
        _handleSessionExpiration('Inactivity timeout exceeded');
        return false;
      }
    }
    
    return true;
  }

  /// Get current session information
  /// Returns session info map
  static Map<String, dynamic> getSessionInfo() {
    return {
      'isActive': _isSessionActive,
      'sessionId': _currentSessionId,
      'sessionStartTime': _sessionStartTime?.toIso8601String(),
      'lastActivityTime': _lastActivityTime?.toIso8601String(),
      'sessionAge': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inMinutes 
          : 0,
      'inactivityAge': _lastActivityTime != null 
          ? DateTime.now().difference(_lastActivityTime!).inMinutes 
          : 0,
      'failedAttempts': _failedLoginAttempts,
      'isLocked': _isAccountLocked(),
    };
  }

  /// Record failed login attempt
  /// [userId] - User ID that failed to login
  /// [reason] - Reason for failure
  static Future<void> recordFailedLogin(String userId, String reason) async {
    _failedLoginAttempts++;
    
    // Check if account should be locked
    if (_failedLoginAttempts >= _maxFailedAttempts) {
      _lockoutStartTime = DateTime.now();
      
      _logSecurityEvent(
        SecurityEventType.accountLocked,
        'Account locked due to multiple failed login attempts',
        severity: SecuritySeverity.high,
        metadata: {
          'userId': userId,
          'failedAttempts': _failedLoginAttempts,
          'reason': reason,
        },
      );
      
      if (kDebugMode) {
        debugPrint('🔒 Account locked: $userId');
      }
    } else {
      _logSecurityEvent(
        SecurityEventType.loginFailed,
        'Failed login attempt: $reason',
        severity: SecuritySeverity.medium,
        metadata: {
          'userId': userId,
          'failedAttempts': _failedLoginAttempts,
          'reason': reason,
        },
      );
    }
    
    await _saveSessionData();
  }

  /// Reset failed login attempts
  /// Call this on successful login
  static Future<void> resetFailedAttempts() async {
    _failedLoginAttempts = 0;
    _lockoutStartTime = null;
    await _saveSessionData();
    
    if (kDebugMode) {
      debugPrint('🔐 Failed login attempts reset');
    }
  }

  /// Check if account is locked
  /// Returns true if account is currently locked
  static bool _isAccountLocked() {
    if (_lockoutStartTime == null) return false;
    
    final lockoutAge = DateTime.now().difference(_lockoutStartTime!);
    if (lockoutAge > _lockoutDuration) {
      // Lockout expired
      _lockoutStartTime = null;
      _failedLoginAttempts = 0;
      return false;
    }
    
    return true;
  }

  /// Handle session expiration
  /// [reason] - Reason for expiration
  static Future<void> _handleSessionExpiration(String reason) async {
    if (kDebugMode) {
      debugPrint('⏰ Session expired: $reason');
    }
    
    // Log security event
    _logSecurityEvent(
      SecurityEventType.sessionExpired,
      'Session expired: $reason',
      severity: SecuritySeverity.medium,
      metadata: {'reason': reason},
    );
    
    // End session
    await endSession(reason: reason);
    
    // Send security alert
    _sendSecurityAlert(
      SecurityAlertType.sessionExpired,
      'Your session has expired due to $reason. Please log in again.',
      SecuritySeverity.medium,
    );
  }

  /// Generate secure session ID
  /// [userId] - User ID to include in session ID
  /// Returns secure session ID
  static String _generateSessionId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode * 31 + userId.hashCode).toString();
    final combined = '$userId:$timestamp:$random';
    
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    
    return 'sess_${hash.toString().safeSubstring(16, ellipsis: '')}';
  }

  /// Start session timer
  /// [timeout] - Session timeout duration
  static void _startSessionTimer(Duration timeout) {
    _stopSessionTimer();
    
    _sessionTimer = Timer.periodic(timeout, (timer) {
      if (!_isSessionActive) {
        timer.cancel();
        return;
      }
      
      // Check session validity
      if (!isSessionValid()) {
        timer.cancel();
      }
    });
  }

  /// Stop session timer
  static void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Start security monitoring
  static void _startSecurityMonitoring() {
    _securityCheckTimer = Timer.periodic(_securityCheckInterval, (timer) {
      _performSecurityChecks();
    });
  }

  /// Perform periodic security checks
  static void _performSecurityChecks() {
    try {
      // Check session validity
      if (_isSessionActive && !isSessionValid()) {
        _handleSessionExpiration('Security check failed');
      }
      
      // Check for suspicious activity
      _detectSuspiciousActivity();
      
      // Clean up old security events
      _cleanupOldSecurityEvents();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Security check failed: $e');
      }
    }
  }

  /// Detect suspicious activity
  static void _detectSuspiciousActivity() {
    // Check for rapid failed login attempts
    if (_failedLoginAttempts > 3) {
      _logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        'Multiple failed login attempts detected',
        severity: SecuritySeverity.high,
        metadata: {'failedAttempts': _failedLoginAttempts},
      );
    }
    
    // Check for unusual session patterns
    if (_lastActivityTime != null) {
      final inactivityAge = DateTime.now().difference(_lastActivityTime!);
      if (inactivityAge > const Duration(hours: 1)) {
        _logSecurityEvent(
          SecurityEventType.suspiciousActivity,
          'Unusual inactivity pattern detected',
          severity: SecuritySeverity.medium,
          metadata: {'inactivityAge': inactivityAge.inMinutes},
        );
      }
    }
  }

  /// Log security event
  /// [type] - Type of security event
  /// [message] - Event message
  /// [severity] - Event severity
  /// [metadata] - Additional event data
  static void _logSecurityEvent(
    SecurityEventType type,
    String message, {
    SecuritySeverity severity = SecuritySeverity.info,
    Map<String, dynamic>? metadata,
  }) {
    final event = SecurityEvent(
      type: type,
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    _securityEvents.add(event);
    
    // Keep only last 1000 events
    if (_securityEvents.length > 1000) {
      _securityEvents.removeRange(0, _securityEvents.length - 1000);
    }
    
    if (kDebugMode) {
      debugPrint('🔐 Security Event [${severity.name.toUpperCase()}]: $message');
    }
  }

  /// Send security alert
  /// [type] - Alert type
  /// [message] - Alert message
  /// [severity] - Alert severity
  static void _sendSecurityAlert(
    SecurityAlertType type,
    String message,
    SecuritySeverity severity,
  ) {
    final alert = SecurityAlert(
      type: type,
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
    );
    
    _alertController.add(alert);
    
    if (kDebugMode) {
      debugPrint('🚨 Security Alert [${severity.name.toUpperCase()}]: $message');
    }
  }

  /// Get security events stream
  /// Returns stream of security alerts
  static Stream<SecurityAlert> get securityAlerts => _alertController.stream;

  /// Get recent security events
  /// [limit] - Maximum number of events to return
  /// Returns list of recent security events
  static List<SecurityEvent> getRecentSecurityEvents({int limit = 100}) {
    final events = List<SecurityEvent>.from(_securityEvents);
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return events.take(limit).toList();
  }

  /// Get security statistics
  /// Returns map with security metrics
  static Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentEvents = _securityEvents.where(
      (event) => event.timestamp.isAfter(last24Hours)
    ).toList();
    
    return {
      'totalEvents': _securityEvents.length,
      'eventsLast24Hours': recentEvents.length,
      'highSeverityEvents': _securityEvents.where(
        (e) => e.severity == SecuritySeverity.high
      ).length,
      'failedLoginAttempts': _failedLoginAttempts,
      'isAccountLocked': _isAccountLocked(),
      'sessionStatus': getSessionInfo(),
    };
  }

  /// Clean up old security events
  /// Removes events older than 30 days
  static void _cleanupOldSecurityEvents() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    _securityEvents.removeWhere((event) => event.timestamp.isBefore(cutoffDate));
  }

  /// Save session data to persistent storage
  static Future<void> _saveSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final sessionData = {
        'sessionStartTime': _sessionStartTime?.millisecondsSinceEpoch,
        'lastActivityTime': _lastActivityTime?.millisecondsSinceEpoch,
        'currentSessionId': _currentSessionId,
        'failedLoginAttempts': _failedLoginAttempts,
        'lockoutStartTime': _lockoutStartTime?.millisecondsSinceEpoch,
        'isSessionActive': _isSessionActive,
      };
      
      await prefs.setString('session_data', jsonEncode(sessionData));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save session data: $e');
      }
    }
  }

  /// Load session data from persistent storage
static Future<void> _loadSessionData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final sessionDataString = prefs.getString('session_data');

    if (sessionDataString == null) return;

    final decoded = jsonDecode(sessionDataString);
    if (decoded is! Map<String, dynamic>) return;

    final data = decoded;

    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    }

    bool asBool(dynamic v) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    String? asString(dynamic v) {
      return v?.toString();
    }

    DateTime? asDate(dynamic v) {
      final ms = asInt(v);
      return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    }

    _sessionStartTime = asDate(data['sessionStartTime']);
    _lastActivityTime = asDate(data['lastActivityTime']);
    _currentSessionId = asString(data['currentSessionId']);
    _failedLoginAttempts = asInt(data['failedLoginAttempts']) ?? 0;
    _lockoutStartTime = asDate(data['lockoutStartTime']);
    _isSessionActive = asBool(data['isSessionActive']);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Failed to load session data: $e');
    }
  }
}


  /// Dispose of service resources
  static void dispose() {
    _stopSessionTimer();
    _securityCheckTimer?.cancel();
    _alertController.close();
  }
}

/// Security event class
class SecurityEvent {
  final SecurityEventType type;
  final String message;
  final SecuritySeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  SecurityEvent({
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.metadata,
  });
}

/// Security alert class
class SecurityAlert {
  final SecurityAlertType type;
  final String message;
  final SecuritySeverity severity;
  final DateTime timestamp;

  SecurityAlert({
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

/// Security event types
enum SecurityEventType {
  sessionStarted,
  sessionEnded,
  sessionExpired,
  loginFailed,
  loginBlocked,
  accountLocked,
  suspiciousActivity,
  securityViolation,
}

/// Security alert types
enum SecurityAlertType {
  sessionExpired,
  suspiciousActivity,
  securityViolation,
  accountLocked,
  multipleFailedLogins,
}

/// Security severity levels
enum SecuritySeverity {
  info,
  low,
  medium,
  high,
  critical,
}
