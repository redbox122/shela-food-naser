/*
 * Role-Based Access Control (RBAC) Manager
 * 
 * This service provides comprehensive access control system with:
 * - User role definitions (admin, user, guest)
 * - Permission-based access control
 * - Feature-level security checks
 * - Audit logging for access attempts
 * - Dynamic permission management
 * - Security policy enforcement
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// User roles with different permission levels
enum UserRole {
  guest, // Limited access, no personal data
  user, // Standard user with full app access
  premium, // Premium user with enhanced features
  moderator, // Content moderation capabilities
  admin, // Full administrative access
  superAdmin, // System-level administrative access
}

/// Permission levels for different features
enum PermissionLevel {
  none, // No access
  read, // Read-only access
  write, // Read and write access
  delete, // Full CRUD access
  admin, // Administrative access
}

/// Feature categories for permission management
enum FeatureCategory {
  authentication, // Login, registration, profile
  shopping, // Browse, cart, orders
  payment, // Payment methods, transactions
  messaging, // Chat, notifications
  settings, // App settings, preferences
  admin, // Administrative functions
  analytics, // User analytics, reports
  system, // System-level operations
}

class RBACManager {
  static final RBACManager _instance = RBACManager._internal();
  factory RBACManager() => _instance;
  RBACManager._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Current user role and permissions
  UserRole _currentUserRole = UserRole.guest;
  Map<String, PermissionLevel> _userPermissions = {};

  // Role definitions and permissions
  static const Map<UserRole, Map<String, PermissionLevel>> _rolePermissions = {
    UserRole.guest: {
      'auth.login': PermissionLevel.read,
      'auth.register': PermissionLevel.write,
      'shopping.browse': PermissionLevel.read,
      'shopping.view_items': PermissionLevel.read,
      'shopping.view_stores': PermissionLevel.read,
      'settings.basic': PermissionLevel.read,
    },
    UserRole.user: {
      'auth.login': PermissionLevel.write,
      'auth.register': PermissionLevel.write,
      'auth.profile': PermissionLevel.write,
      'shopping.browse': PermissionLevel.read,
      'shopping.view_items': PermissionLevel.read,
      'shopping.view_stores': PermissionLevel.read,
      'shopping.cart': PermissionLevel.write,
      'shopping.orders': PermissionLevel.write,
      'payment.methods': PermissionLevel.write,
      'payment.transactions': PermissionLevel.read,
      'messaging.chat': PermissionLevel.write,
      'messaging.notifications': PermissionLevel.write,
      'settings.full': PermissionLevel.write,
      'analytics.personal': PermissionLevel.read,
    },
    UserRole.premium: {
      'auth.login': PermissionLevel.write,
      'auth.register': PermissionLevel.write,
      'auth.profile': PermissionLevel.write,
      'shopping.browse': PermissionLevel.read,
      'shopping.view_items': PermissionLevel.read,
      'shopping.view_stores': PermissionLevel.read,
      'shopping.cart': PermissionLevel.write,
      'shopping.orders': PermissionLevel.write,
      'shopping.premium_features': PermissionLevel.write,
      'payment.methods': PermissionLevel.write,
      'payment.transactions': PermissionLevel.read,
      'payment.premium_methods': PermissionLevel.write,
      'messaging.chat': PermissionLevel.write,
      'messaging.notifications': PermissionLevel.write,
      'messaging.priority_support': PermissionLevel.write,
      'settings.full': PermissionLevel.write,
      'settings.premium': PermissionLevel.write,
      'analytics.personal': PermissionLevel.read,
      'analytics.advanced': PermissionLevel.read,
    },
    UserRole.moderator: {
      'auth.login': PermissionLevel.write,
      'auth.register': PermissionLevel.write,
      'auth.profile': PermissionLevel.write,
      'shopping.browse': PermissionLevel.read,
      'shopping.view_items': PermissionLevel.read,
      'shopping.view_stores': PermissionLevel.read,
      'shopping.cart': PermissionLevel.write,
      'shopping.orders': PermissionLevel.write,
      'payment.methods': PermissionLevel.write,
      'payment.transactions': PermissionLevel.read,
      'messaging.chat': PermissionLevel.write,
      'messaging.notifications': PermissionLevel.write,
      'settings.full': PermissionLevel.write,
      'analytics.personal': PermissionLevel.read,
      'admin.content_moderation': PermissionLevel.write,
      'admin.report_review': PermissionLevel.write,
      'admin.user_reports': PermissionLevel.read,
    },
    UserRole.admin: {
      'auth.login': PermissionLevel.write,
      'auth.register': PermissionLevel.write,
      'auth.profile': PermissionLevel.write,
      'shopping.browse': PermissionLevel.read,
      'shopping.view_items': PermissionLevel.read,
      'shopping.view_stores': PermissionLevel.read,
      'shopping.cart': PermissionLevel.write,
      'shopping.orders': PermissionLevel.write,
      'payment.methods': PermissionLevel.write,
      'payment.transactions': PermissionLevel.read,
      'messaging.chat': PermissionLevel.write,
      'messaging.notifications': PermissionLevel.write,
      'settings.full': PermissionLevel.write,
      'analytics.personal': PermissionLevel.read,
      'admin.content_moderation': PermissionLevel.write,
      'admin.report_review': PermissionLevel.write,
      'admin.user_reports': PermissionLevel.read,
      'admin.user_management': PermissionLevel.write,
      'admin.store_management': PermissionLevel.write,
      'admin.order_management': PermissionLevel.write,
      'admin.payment_management': PermissionLevel.write,
      'admin.analytics': PermissionLevel.read,
      'admin.system_settings': PermissionLevel.write,
    },
    UserRole.superAdmin: {
      'auth.login': PermissionLevel.write,
      'auth.register': PermissionLevel.write,
      'auth.profile': PermissionLevel.write,
      'shopping.browse': PermissionLevel.read,
      'shopping.view_items': PermissionLevel.read,
      'shopping.view_stores': PermissionLevel.read,
      'shopping.cart': PermissionLevel.write,
      'shopping.orders': PermissionLevel.write,
      'payment.methods': PermissionLevel.write,
      'payment.transactions': PermissionLevel.read,
      'messaging.chat': PermissionLevel.write,
      'messaging.notifications': PermissionLevel.write,
      'settings.full': PermissionLevel.write,
      'analytics.personal': PermissionLevel.read,
      'admin.content_moderation': PermissionLevel.write,
      'admin.report_review': PermissionLevel.write,
      'admin.user_reports': PermissionLevel.read,
      'admin.user_management': PermissionLevel.write,
      'admin.store_management': PermissionLevel.write,
      'admin.order_management': PermissionLevel.write,
      'admin.payment_management': PermissionLevel.write,
      'admin.analytics': PermissionLevel.read,
      'admin.system_settings': PermissionLevel.write,
      'system.full_access': PermissionLevel.admin,
      'system.security': PermissionLevel.admin,
      'system.backup': PermissionLevel.admin,
      'system.restore': PermissionLevel.admin,
    },
  };

  // Storage keys
  static const String _userRoleKey = 'user_role';
  static const String _userPermissionsKey = 'user_permissions';
  static const String _auditLogKey = 'audit_log';
  static const String _lastAccessKey = 'last_access';

  /// Initialize RBAC manager
  Future<void> initialize() async {
    try {
      // Load user role and permissions
      await _loadUserRole();
      await _loadUserPermissions();

      if (kDebugMode) {
        debugPrint('🔐 RBAC Manager initialized');
        debugPrint('🔐 Current role: $_currentUserRole');
        debugPrint('🔐 Permissions loaded: ${_userPermissions.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing RBAC: $e');
      }
      // Set default guest role
      _currentUserRole = UserRole.guest;
      _userPermissions = _getDefaultPermissions(UserRole.guest);
    }
  }

  /// Set user role and update permissions
  Future<bool> setUserRole(UserRole role) async {
    try {
      _currentUserRole = role;
      _userPermissions = _getDefaultPermissions(role);

      // Save to secure storage
      await _secureStorage.write(
        key: _userRoleKey,
        value: role.toString(),
      );
      await _secureStorage.write(
        key: _userPermissionsKey,
        value: jsonEncode(_userPermissions),
      );

      // Log role change
      await _logAuditEvent(
        'role_changed',
        'User role changed to: ${role.toString()}',
        'info',
      );

      if (kDebugMode) {
        debugPrint('🔐 User role set to: $role');
        debugPrint('🔐 Permissions updated: ${_userPermissions.length}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting user role: $e');
      }
      return false;
    }
  }

  /// Get current user role
  UserRole getCurrentUserRole() {
    return _currentUserRole;
  }

  /// Check if user has permission for a specific feature
  bool hasPermission(String feature, PermissionLevel requiredLevel) {
    try {
      final userLevel = _userPermissions[feature];
      if (userLevel == null) return false;

      // Check permission hierarchy
      return _comparePermissionLevels(userLevel, requiredLevel) >= 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking permission: $e');
      }
      return false;
    }
  }

  /// Check if user can access a feature
  bool canAccess(String feature) {
    return hasPermission(feature, PermissionLevel.read);
  }

  /// Check if user can modify a feature
  bool canModify(String feature) {
    return hasPermission(feature, PermissionLevel.write);
  }

  /// Check if user can delete a feature
  bool canDelete(String feature) {
    return hasPermission(feature, PermissionLevel.delete);
  }

  /// Check if user has administrative access
  bool isAdmin() {
    return _currentUserRole == UserRole.admin ||
        _currentUserRole == UserRole.superAdmin;
  }

  /// Check if user is a guest
  bool isGuest() {
    return _currentUserRole == UserRole.guest;
  }

  /// Check if user is premium
  bool isPremium() {
    return _currentUserRole == UserRole.premium;
  }

  /// Get user permissions for a specific category
  Map<String, PermissionLevel> getPermissionsForCategory(
      FeatureCategory category) {
    final categoryPermissions = <String, PermissionLevel>{};

    _userPermissions.forEach((feature, level) {
      if (feature.startsWith(category.toString().toLowerCase())) {
        categoryPermissions[feature] = level;
      }
    });

    return categoryPermissions;
  }

  /// Grant additional permission to user
  Future<bool> grantPermission(String feature, PermissionLevel level) async {
    try {
      // Check if current role allows granting permissions
      if (!isAdmin()) {
        if (kDebugMode) {
          debugPrint('❌ Insufficient permissions to grant access');
        }
        return false;
      }

      _userPermissions[feature] = level;

      // Save updated permissions
      await _secureStorage.write(
        key: _userPermissionsKey,
        value: jsonEncode(_userPermissions),
      );

      // Log permission grant
      await _logAuditEvent(
        'permission_granted',
        'Permission granted: $feature -> ${level.toString()}',
        'info',
      );

      if (kDebugMode) {
        debugPrint('🔐 Permission granted: $feature -> $level');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error granting permission: $e');
      }
      return false;
    }
  }

  /// Revoke permission from user
  Future<bool> revokePermission(String feature) async {
    try {
      // Check if current role allows revoking permissions
      if (!isAdmin()) {
        if (kDebugMode) {
          debugPrint('❌ Insufficient permissions to revoke access');
        }
        return false;
      }

      _userPermissions.remove(feature);

      // Save updated permissions
      await _secureStorage.write(
        key: _userPermissionsKey,
        value: jsonEncode(_userPermissions),
      );

      // Log permission revocation
      await _logAuditEvent(
        'permission_revoked',
        'Permission revoked: $feature',
        'warning',
      );

      if (kDebugMode) {
        debugPrint('🔐 Permission revoked: $feature');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error revoking permission: $e');
      }
      return false;
    }
  }

  /// Get all user permissions
  Map<String, PermissionLevel> getAllPermissions() {
    return Map.from(_userPermissions);
  }

  /// Log access attempt for audit
  Future<void> logAccessAttempt(
      String feature, bool granted, String reason) async {
    await _logAuditEvent(
      'access_attempt',
      'Feature: $feature, Granted: $granted, Reason: $reason',
      granted ? 'info' : 'warning',
    );
  }

  /// Get audit log
  Future<List<Map<String, dynamic>>> getAuditLog({int limit = 100}) async {
    try {
      final logData = await _secureStorage.read(key: _auditLogKey);
      if (logData == null) return [];

      final decoded = jsonDecode(logData);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .take(limit)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting audit log: $e');
      }
      return [];
    }
  }

  /// Clear audit log
  Future<bool> clearAuditLog() async {
    try {
      if (!isAdmin()) return false;

      await _secureStorage.delete(key: _auditLogKey);

      if (kDebugMode) {
        debugPrint('🔐 Audit log cleared');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing audit log: $e');
      }
      return false;
    }
  }

  /// Get RBAC status and statistics
  Future<Map<String, dynamic>> getRBACStatus() async {
    final auditLog = await getAuditLog();
    final accessAttempts =
        auditLog.where((log) => log['event'] == 'access_attempt').length;
    final grantedAccess = auditLog
        .where((log) =>
            log['event'] == 'access_attempt' &&
            log['message']?.toString().contains('Granted: true') == true)
        .length;

    final deniedAccess = auditLog
        .where((log) =>
            log['event'] == 'access_attempt' &&
            log['message']?.toString().contains('Granted: false') == true)
        .length;

    return {
      'currentRole': _currentUserRole.toString(),
      'totalPermissions': _userPermissions.length,
      'accessAttempts': accessAttempts,
      'grantedAccess': grantedAccess,
      'deniedAccess': deniedAccess,
      'lastAccess': await _secureStorage.read(key: _lastAccessKey),
      'isAdmin': isAdmin(),
      'isGuest': isGuest(),
      'isPremium': isPremium(),
    };
  }

  /// Load user role from storage
  Future<void> _loadUserRole() async {
    try {
      final roleString = await _secureStorage.read(key: _userRoleKey);
      if (roleString != null) {
        _currentUserRole = UserRole.values.firstWhere(
          (role) => role.toString() == roleString,
          orElse: () => UserRole.guest,
        );
      }
    } catch (e) {
      _currentUserRole = UserRole.guest;
    }
  }

  /// Load user permissions from storage
  Future<void> _loadUserPermissions() async {
    try {
      final permissionsData =
          await _secureStorage.read(key: _userPermissionsKey);
      if (permissionsData != null) {
        final decoded = jsonDecode(permissionsData);

        if (decoded is Map) {
          final Map<String, dynamic> permissions =
              Map<String, dynamic>.from(decoded);

          _userPermissions = permissions.map(
            (key, value) => MapEntry(
              key,
              PermissionLevel.values.firstWhere(
                (level) => level.toString() == value,
                orElse: () => PermissionLevel.none,
              ),
            ),
          );
        } else {
          _userPermissions = _getDefaultPermissions(_currentUserRole);
        }
      } else {
        _userPermissions = _getDefaultPermissions(_currentUserRole);
      }
    } catch (e) {
      _userPermissions = _getDefaultPermissions(_currentUserRole);
    }
  }

  /// Get default permissions for a role
  Map<String, PermissionLevel> _getDefaultPermissions(UserRole role) {
    return Map.from(_rolePermissions[role] ?? {});
  }

  /// Compare permission levels
  int _comparePermissionLevels(PermissionLevel user, PermissionLevel required) {
    const levels = PermissionLevel.values;
    final userIndex = levels.indexOf(user);
    final requiredIndex = levels.indexOf(required);
    return userIndex.compareTo(requiredIndex);
  }

  /// Log audit event
  Future<void> _logAuditEvent(
      String event, String message, String level) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final auditEntry = {
        'timestamp': timestamp,
        'event': event,
        'message': message,
        'level': level,
        'userRole': _currentUserRole.toString(),
        'userId': await _getCurrentUserId(),
      };

      // Get existing log
      final existingLog = await _secureStorage.read(key: _auditLogKey);
      List<dynamic> auditLog = [];

      if (existingLog != null) {
        final decoded = jsonDecode(existingLog);
        if (decoded is List) {
          auditLog = decoded;
        }
      }

      // Add new entry
      auditLog.add(Map<String, dynamic>.from(auditEntry));

      // Keep only last 1000 entries
      if (auditLog.length > 1000) {
        auditLog = auditLog.take(1000).toList();
      }

      // Save updated log
      await _secureStorage.write(
        key: _auditLogKey,
        value: jsonEncode(auditLog),
      );

      // Update last access
      await _secureStorage.write(
        key: _lastAccessKey,
        value: timestamp,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error logging audit event: $e');
      }
    }
  }

  /// Get current user ID (placeholder - implement based on your auth system)
  Future<String> _getCurrentUserId() async {
    // This should be implemented based on your authentication system
    // For now, return a placeholder
    return 'user_${_currentUserRole.toString()}';
  }
}
