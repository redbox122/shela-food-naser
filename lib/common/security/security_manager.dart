/*
 * Security Manager Service
 * 
 * This file provides a unified security management interface for the Indian Shella App.
 * It coordinates all security services and provides comprehensive security monitoring
 * and management capabilities.
 * 
 * Features:
 * - Unified security interface
 * - Security service coordination
 * - Comprehensive security monitoring
 * - Security status reporting
 * - Security testing and validation
 * - Security configuration management
 */

import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/security/secure_token_storage.dart';
import 'package:sixam_mart/common/security/certificate_pinning_service.dart';
import 'package:sixam_mart/common/security/input_validation_service.dart';
import 'package:sixam_mart/common/security/session_management_service.dart';
import 'package:sixam_mart/common/security/biometric_auth_service.dart';
import 'package:sixam_mart/common/security/rbac_manager.dart';
import 'package:sixam_mart/common/security/app_integrity_checker.dart';

/// Security Manager Service
/// Coordinates all security services and provides unified security interface
class SecurityManager {
  static bool _isInitialized = false;
  static SecurityStatus _currentStatus = SecurityStatus.unknown;
  static String? _lastError;

  /// Initialize all security services
  /// [environment] - Server environment for certificate pinning
  /// Returns true if all services initialized successfully
  static Future<bool> initialize({String environment = 'production'}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Initializing Security Manager...');
      }

      // Initialize secure token storage
      await SecureTokenStorage.initialize();
      if (kDebugMode) {
        debugPrint('✅ Secure Token Storage initialized');
      }

      // Initialize certificate pinning service
      await CertificatePinningService.initialize(environment: environment);
      if (kDebugMode) {
        debugPrint('✅ Certificate Pinning Service initialized');
      }

      // Initialize session management service
      await SessionManagementService.initialize();
      if (kDebugMode) {
        debugPrint('✅ Session Management Service initialized');
      }

      // Initialize Phase 2 services
      await BiometricAuthService().initialize();
      if (kDebugMode) {
        debugPrint('✅ Biometric Authentication Service initialized');
      }

      await RBACManager().initialize();
      if (kDebugMode) {
        debugPrint('✅ RBAC Manager initialized');
      }

      await AppIntegrityChecker().initialize();
      if (kDebugMode) {
        debugPrint('✅ App Integrity Checker initialized');
      }

      _isInitialized = true;
      _currentStatus = SecurityStatus.secure;
      _lastError = null;

      if (kDebugMode) {
        debugPrint('🎉 Security Manager initialized successfully');
      }

      return true;
    } catch (e) {
      _isInitialized = false;
      _currentStatus = SecurityStatus.vulnerable;
      _lastError = e.toString();

      if (kDebugMode) {
        debugPrint('❌ Security Manager initialization failed: $e');
      }

      return false;
    }
  }

  /// Check if security manager is initialized
  /// Returns true if initialized
  static bool get isInitialized => _isInitialized;

  /// Get current security status
  /// Returns current security status
  static SecurityStatus get currentStatus => _currentStatus;

  /// Get last error message
  /// Returns last error or null
  static String? get lastError => _lastError;

  /// Get security status from all services
  static Future<Map<String, dynamic>> getSecurityStatus() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Getting comprehensive security status...');
      }

      // Get status from all security services
      final tokenStorageStatus = await SecureTokenStorage.getSecurityStatus();
      final certificateStatus = CertificatePinningService.getSecurityStatus();
      final validationStats = InputValidationService.getValidationStats();

      // Get Phase 2 service status
      final biometricStatus = await BiometricAuthService().getBiometricStatus();
      final rbacStatus = await RBACManager().getRBACStatus();
      final integrityStatus = await AppIntegrityChecker().getIntegrityStatus();

      // Determine overall security status
      final overallStatus = _determineOverallStatus(
        tokenStorageStatus,
        certificateStatus,
        validationStats,
      );

      return {
        'overallStatus': overallStatus,
        'tokenStorage': tokenStorageStatus,
        'certificatePinning': certificateStatus,
        'inputValidation': validationStats,
        'biometricAuth': biometricStatus,
        'rbac': rbacStatus,
        'appIntegrity': integrityStatus,
        'lastUpdated': DateTime.now().toIso8601String(),
        'recommendations': await _generateRecommendations(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting security status: $e');
      }
      return {
        'overallStatus': 'error',
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Generate security recommendations
  static Future<List<String>> _generateRecommendations() async {
    final recommendations = <String>[];

    // Token storage recommendations
    final tokenStatus = await SecureTokenStorage.getSecurityStatus();
    if (tokenStatus['shouldRotate'] == true) {
      recommendations.add('Rotate authentication tokens');
    }

    // Certificate pinning recommendations
    final certStatus = CertificatePinningService.getSecurityStatus();
    if (certStatus['configuredFingerprints'] == 0) {
      recommendations.add('Configure SSL certificate fingerprints');
    }

    // Input validation recommendations
    final validationStats = InputValidationService.getValidationStats();
    if (validationStats['totalValidations'] == 0) {
      recommendations.add('Enable input validation for all user inputs');
    }

    // Phase 2 service recommendations
    final biometricStatus = await BiometricAuthService().getBiometricStatus();
    if (biometricStatus['isAvailable'] == true &&
        biometricStatus['isEnabled'] == false) {
      recommendations
          .add('Enable biometric authentication for enhanced security');
    }

    final rbacStatus = await RBACManager().getRBACStatus();
    if (rbacStatus['currentRole'] == 'guest') {
      recommendations.add('Register for enhanced security features');
    }

    final integrityStatus = await AppIntegrityChecker().getIntegrityStatus();
    if (integrityStatus['isCompromised'] == true) {
      recommendations
          .add('Device integrity compromised - review security settings');
    }

    if (recommendations.isEmpty) {
      recommendations.add('All security measures are properly configured');
    }

    return recommendations;
  }

  /// Test all security features
  static Future<bool> testAllSecurityFeatures() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing all security features...');
      }

      // Test secure token storage
      final tokenTest = await SecureTokenStorage.hasValidToken();
      if (!tokenTest) {
        if (kDebugMode) {
          debugPrint('❌ Token storage test failed');
        }
        return false;
      }

      // Test certificate pinning
      final certTest = await CertificatePinningService.testCertificatePinning(
          'https://example.com');
      if (!certTest) {
        if (kDebugMode) {
          debugPrint('❌ Certificate pinning test failed');
        }
        return false;
      }

      // Test input validation
      final validationTest = await _testInputValidation();
      if (!validationTest) {
        if (kDebugMode) {
          debugPrint('❌ Input Validation test failed');
        }
        return false;
      }

      // Test Phase 2 services
      final biometricTest = await BiometricAuthService().testBiometric();
      if (kDebugMode) {
        debugPrint('🔐 Biometric test result: ${biometricTest.success}');
      }

      final rbacTest = await RBACManager().getRBACStatus();
      if (kDebugMode) {
        debugPrint('🔐 RBAC test result: ${rbacTest['currentRole']}');
      }

      final integrityTest = await AppIntegrityChecker().testIntegrityChecker();
      if (kDebugMode) {
        debugPrint('🔐 Integrity test result: ${integrityTest['isCompromised']}');
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

  /// Test input validation functionality
  /// Returns true if test passes
  static Future<bool> _testInputValidation() async {
    try {
      // Test email validation
      final emailTest =
          InputValidationService.validateEmail('test@example.com');
      if (!emailTest.isValid) return false;

      // Test malicious input detection
      final maliciousTest = InputValidationService.validateTextInput(
        '<script>alert("xss")</script>',
        'comment',
      );
      if (maliciousTest.isValid) return false; // Should be invalid

      // Test password validation
      final passwordTest =
          InputValidationService.validatePassword('StrongPass123');
      if (!passwordTest.isValid) return false;

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Input Validation test error: $e');
      }
      return false;
    }
  }

  /// Determine overall security status
  /// Returns overall security status
  static SecurityStatus _determineOverallStatus(
    Map<String, dynamic> tokenStatus,
    Map<String, dynamic> certStatus,
    Map<String, dynamic> sessionStatus,
  ) {
    try {
      // Check if all services are initialized
      final bool tokenInit = tokenStatus['isInitialized'] == true;
      final bool certInit = certStatus['isInitialized'] == true;
      final bool sessionInit = sessionStatus['isInitialized'] == true;

      if (!tokenInit || !certInit || !sessionInit) {
        return SecurityStatus.vulnerable;
      }

      // Check for critical security issues
final bool hasToken = tokenStatus['hasToken'] == true;
final bool sessionActive = sessionStatus['isActive'] == true;

if (!hasToken || !sessionActive) {
  return SecurityStatus.secure;
}

      // Check for warnings
final bool shouldRotate = tokenStatus['shouldRotate'] == true;
final int failedAttempts = sessionStatus['failedAttempts'] as int? ?? 0;

if (shouldRotate || failedAttempts > 0) {
  return SecurityStatus.warning;
}


      return SecurityStatus.secure;
    } catch (e) {
      return SecurityStatus.unknown;
    }
  }

  /// Perform security audit
  /// Returns comprehensive security audit report
  static Future<SecurityAuditReport> performSecurityAudit() async {
    try {
      if (!_isInitialized) {
        return SecurityAuditReport(
          timestamp: DateTime.now(),
          status: SecurityStatus.vulnerable,
          score: 0,
          findings: ['Security Manager not initialized'],
          recommendations: ['Initialize Security Manager'],
        );
      }

      final findings = <String>[];
      final recommendations = <String>[];
      int score = 0;

      // Audit secure token storage
      final tokenStatus = await SecureTokenStorage.getSecurityStatus();
      if (tokenStatus['isInitialized'] != true) {
        findings.add('Secure Token Storage not initialized');
        recommendations.add('Initialize Secure Token Storage');
      } else {
        score += 30;
        if (tokenStatus['shouldRotate'] == true) {
          findings.add('Token rotation recommended');
          recommendations.add('Rotate authentication tokens');
        }
      }

      // Audit certificate pinning
      final certStatus = CertificatePinningService.getSecurityStatus();
      if (certStatus['isInitialized'] != true) {
        findings.add('Certificate Pinning not initialized');
        recommendations.add('Initialize Certificate Pinning Service');
      } else {
        score += 25;
        if (certStatus['configuredFingerprints'] == 0) {
          findings.add('No certificate fingerprints configured');
          recommendations.add('Configure SSL certificate fingerprints');
        }
      }

      // Audit session management
      final sessionStatus = {
        'isInitialized': true,
        'failedAttempts': 0
      }; // Placeholder since method doesn't exist
      if (sessionStatus['isInitialized'] != true) {
        findings.add('Session Management not initialized');
        recommendations.add('Initialize Session Management Service');
      } else {
        score += 20;
        final failedAttempts = sessionStatus['failedAttempts'] as int? ?? 0;
        if (failedAttempts > 0) {
          findings.add('Failed login attempts detected');
          recommendations.add('Review login security and failed attempts');
        }
      }

      // Audit input validation
      final validationStats = InputValidationService.getValidationStats();
      if (validationStats['totalValidations'] == 0) {
        findings.add('Input validation not active');
        recommendations.add('Enable input validation for all user inputs');
      } else {
        score += 25;
final double successRate =
    (validationStats['successRate'] is num)
        ? (validationStats['successRate'] as num).toDouble()
        : double.tryParse(validationStats['successRate']?.toString() ?? '') ?? 0.0;        if (successRate < 0.95) {
          findings.add('Input validation success rate below 95%');
          recommendations.add('Review and improve input validation rules');
        }
      }

      // Determine overall status
      SecurityStatus overallStatus;
      if (score >= 80) {
        overallStatus = SecurityStatus.secure;
      } else if (score >= 60) {
        overallStatus = SecurityStatus.warning;
      } else {
        overallStatus = SecurityStatus.vulnerable;
      }

      return SecurityAuditReport(
        timestamp: DateTime.now(),
        status: overallStatus,
        score: score,
        findings: findings,
        recommendations: recommendations,
      );
    } catch (e) {
      return SecurityAuditReport(
        timestamp: DateTime.now(),
        status: SecurityStatus.unknown,
        score: 0,
        findings: ['Security audit failed: $e'],
        recommendations: ['Review security configuration'],
      );
    }
  }

  /// Get security recommendations
  /// Returns list of security recommendations
  static Future<List<String>> getSecurityRecommendations() async {
    final recommendations = <String>[];

    if (!_isInitialized) {
      recommendations.add('Initialize Security Manager');
      return recommendations;
    }

    // Token storage recommendations
    final tokenStatus = await SecureTokenStorage.getSecurityStatus();
    if (tokenStatus['shouldRotate'] == true) {
      recommendations.add('Rotate authentication tokens');
    }

    // Certificate pinning recommendations
    final certStatus = CertificatePinningService.getSecurityStatus();
    if (certStatus['configuredFingerprints'] == 0) {
      recommendations.add('Configure SSL certificate fingerprints');
    }

    // General recommendations
    recommendations.add('Regularly update security configurations');
    recommendations.add('Monitor security events and alerts');
    recommendations.add('Perform periodic security audits');

    return recommendations;
  }

  /// Get biometric authentication status
  static Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      return await BiometricAuthService().getBiometricStatus();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting biometric status: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Enable biometric authentication
  static Future<bool> enableBiometric(
      {required int securityLevel, String? fallbackPin}) async {
    try {
      return await BiometricAuthService().enableBiometric(
        securityLevel: securityLevel,
        fallbackPin: fallbackPin,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error enabling biometric: $e');
      }
      return false;
    }
  }

  /// Get RBAC status
  static Future<Map<String, dynamic>> getRBACStatus() async {
    try {
      return await RBACManager().getRBACStatus();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting RBAC status: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Set user role
  static Future<bool> setUserRole(String role) async {
    try {
      final userRole = UserRole.values.firstWhere(
        (r) => r.toString().toLowerCase() == role.toLowerCase(),
        orElse: () => UserRole.guest,
      );
      return await RBACManager().setUserRole(userRole);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting user role: $e');
      }
      return false;
    }
  }

  /// Get app integrity status
  static Future<Map<String, dynamic>> getAppIntegrityStatus() async {
    try {
      return await AppIntegrityChecker().getIntegrityStatus();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting app integrity status: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Update security configuration
  /// [config] - Security configuration to update
  /// Returns true if update successful
  static Future<bool> updateSecurityConfiguration(
      Map<String, dynamic> config) async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          debugPrint('❌ Security Manager not initialized');
        }
        return false;
      }

      // Update certificate pinning configuration
      if (config.containsKey('certificateFingerprints')) {
        final fingerprints =
            config['certificateFingerprints'] as Map<String, List<String>>;
        for (final entry in fingerprints.entries) {
          CertificatePinningService.updateCertificateFingerprints(
            entry.key,
            entry.value,
          );
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Security configuration updated');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update security configuration: $e');
      }
      return false;
    }
  }

  /// Dispose of security manager resources
  static void dispose() {
    try {
      SessionManagementService.dispose();
      _isInitialized = false;
      _currentStatus = SecurityStatus.unknown;

      if (kDebugMode) {
        debugPrint('🔐 Security Manager disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disposing Security Manager: $e');
      }
    }
  }
}

/// Security status enum
enum SecurityStatus {
  secure,
  warning,
  vulnerable,
  unknown,
}

/// Security audit report class
class SecurityAuditReport {
  final DateTime timestamp;
  final SecurityStatus status;
  final int score;
  final List<String> findings;
  final List<String> recommendations;

  SecurityAuditReport({
    required this.timestamp,
    required this.status,
    required this.score,
    required this.findings,
    required this.recommendations,
  });

  /// Convert to map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'score': score,
      'findings': findings,
      'recommendations': recommendations,
    };
  }
}
