/*
 * Certificate Pinning Service
 * 
 * This file provides SSL certificate pinning and validation for the Indian Shella App.
 * It implements certificate pinning to prevent Man-in-the-Middle (MITM) attacks
 * and ensures secure communication with the dashboard API.
 * 
 * Features:
 * - SSL certificate pinning
 * - Certificate validation
 * - MITM attack prevention
 * - Secure API communication
 * - Certificate fingerprint validation
 */

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:sixam_mart/util/environment_config.dart';

/// Certificate Pinning Service for secure API communication
/// Prevents MITM attacks by validating SSL certificates
class CertificatePinningService {
  // Certificate fingerprints for pinning
  static const Map<String, List<String>> _certificateFingerprints = {
    // Production server certificates
    'production': [
      // Add your production server certificate fingerprints here
      // Example: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      // Example: 'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    ],
    // Development server certificates
    'development': [
      // Add your development server certificate fingerprints here
      // Example: 'sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=',
    ],
    // Staging server certificates
    'staging': [
      // Add your staging server certificate fingerprints here
      // Example: 'sha256/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=',
    ],
  };

  // Server environment (should be configurable)
  static String _currentEnvironment = 'production';

  // Certificate validation status
  static bool _isCertificateValid = false;
  static String? _lastValidationError;

  /// Initialize certificate pinning service
  /// [environment] - Server environment (production, staging, development)
  static Future<void> initialize({String environment = 'production'}) async {
    _currentEnvironment = environment;

    try {
      // Validate current environment
      if (!_certificateFingerprints.containsKey(_currentEnvironment)) {
        throw Exception('Invalid environment: $_currentEnvironment');
      }

      if (kDebugMode) {
        debugPrint(
            '🔒 Certificate Pinning Service initialized for $_currentEnvironment environment');
      }

      _isCertificateValid = true;
    } catch (e) {
      _isCertificateValid = false;
      _lastValidationError = e.toString();

      if (kDebugMode) {
        debugPrint('❌ Certificate Pinning Service initialization failed: $e');
      }
    }
  }

  /// Get current environment
  static String get currentEnvironment => _currentEnvironment;

  /// Check if certificate validation is active
  static bool get isCertificateValid => _isCertificateValid;

  /// Get last validation error
  static String? get lastValidationError => _lastValidationError;

  /// Validate certificate fingerprint
  /// [certificate] - SSL certificate to validate
  /// Returns true if certificate is valid
  static bool validateCertificateFingerprint(X509Certificate certificate) {
    try {
      final fingerprint = _calculateCertificateFingerprint(certificate);
      final allowedFingerprints =
          _certificateFingerprints[_currentEnvironment] ?? [];

      if (allowedFingerprints.isEmpty) {
        // Fail-closed when pinning is enabled: an empty list must never be
        // treated as "trust anything". Real enforcement is done via the bundled
        // CA SecurityContext (see CertificatePinning); this guard just makes
        // sure this legacy helper can't silently bypass pinning.
        if (EnvironmentConfig.enableCertificatePinning) {
          if (kDebugMode) {
            debugPrint(
                '❌ Certificate pinning ON but no fingerprints configured for $_currentEnvironment — rejecting (fail-closed)');
          }
          return false;
        }
        if (kDebugMode) {
          debugPrint(
              '⚠️ No certificate fingerprints configured for $_currentEnvironment environment');
          debugPrint(
              '⚠️ Certificate pinning is effectively DISABLED - add fingerprints before production release');
        }
        // Pinning flag is OFF — preserve legacy permissive behaviour for the
        // (unused) fingerprint path so nothing changes while the flag is off.
        return true; // Allow if no fingerprints configured
      }

      final isValid = allowedFingerprints.contains(fingerprint);

      if (kDebugMode) {
        debugPrint('🔒 Certificate validation: ${isValid ? 'VALID' : 'INVALID'}');
        debugPrint('🔒 Expected fingerprints: $allowedFingerprints');
        debugPrint('🔒 Actual fingerprint: $fingerprint');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Certificate validation error: $e');
      }
      return false;
    }
  }

  /// Calculate certificate fingerprint
  /// [certificate] - SSL certificate
  /// Returns SHA-256 fingerprint in base64 format
  static String _calculateCertificateFingerprint(X509Certificate certificate) {
    try {
      final bytes = certificate.der;
      final hash = sha256.convert(bytes);
      final fingerprint = base64.encode(hash.bytes);
      return 'sha256/$fingerprint';
    } catch (e) {
      throw Exception('Failed to calculate certificate fingerprint: $e');
    }
  }

  /// Configure Dio with security headers and timeouts
  /// [dio] - Dio instance to configure
  /// [baseUrl] - Base URL for API calls
  static void configureDioWithSecurity(Dio dio, String baseUrl) {
    try {
      // ⚠️ WEB FIX: على الويب، بعض الـ headers تسبب مشاكل CORS
      // نضيف فقط الـ headers الآمنة
      if (!kIsWeb) {
        // على الموبايل، نضيف كل الـ headers
        dio.options.headers['X-Requested-With'] = 'XMLHttpRequest';
        dio.options.headers['X-Frame-Options'] = 'DENY';
        dio.options.headers['X-XSS-Protection'] = '1; mode=block';
      }

      // الـ headers الآمنة على جميع المنصات
      dio.options.headers['X-Content-Type-Options'] = 'nosniff';

      // Configure timeouts
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.sendTimeout = const Duration(seconds: 30);

      if (kDebugMode) {
        debugPrint('🔒 Dio configured with security headers for $baseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to configure Dio with security: $e');
      }
    }
  }

  /// Validate server certificate for a specific host
  /// [host] - Host to validate
  /// [port] - Port number
  /// Returns true if certificate is valid
  static Future<bool> validateServerCertificate(String host, int port) async {
    try {
      final socket = await SecureSocket.connect(host, port);
      final certificate = socket.peerCertificate;

      if (certificate == null) {
        if (kDebugMode) {
          debugPrint('❌ No certificate received from $host:$port');
        }
        return false;
      }

      final isValid = validateCertificateFingerprint(certificate);
      await socket.close();

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to validate server certificate for $host:$port: $e');
      }
      return false;
    }
  }

  /// Get certificate information
  /// [host] - Host to check
  /// [port] - Port number
  /// Returns certificate information map
  static Future<Map<String, dynamic>?> getCertificateInfo(
      String host, int port) async {
    try {
      final socket = await SecureSocket.connect(host, port);
      final certificate = socket.peerCertificate;

      if (certificate == null) {
        await socket.close();
        return null;
      }

      final info = {
        'subject': certificate.subject,
        'issuer': certificate.issuer,
        'validFrom': certificate.startValidity.toIso8601String(),
        'validTo': certificate.endValidity.toIso8601String(),
        'fingerprint': _calculateCertificateFingerprint(certificate),
      };

      await socket.close();
      return info;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get certificate info for $host:$port: $e');
      }
      return null;
    }
  }

  /// Update certificate fingerprints
  /// [environment] - Environment to update
  /// [fingerprints] - New certificate fingerprints
  static void updateCertificateFingerprints(
      String environment, List<String> fingerprints) {
    try {
      if (_certificateFingerprints.containsKey(environment)) {
        _certificateFingerprints[environment] = fingerprints;

        if (kDebugMode) {
          debugPrint(
              '🔒 Updated certificate fingerprints for $environment environment');
          debugPrint('🔒 New fingerprints: $fingerprints');
        }
      } else {
        throw Exception('Invalid environment: $environment');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update certificate fingerprints: $e');
      }
    }
  }

  /// Get security status
  /// Returns map with security metrics
  static Map<String, dynamic> getSecurityStatus() {
    return {
      'isInitialized': _isCertificateValid,
      'currentEnvironment': _currentEnvironment,
      'certificateValidation': _isCertificateValid,
      'lastValidationError': _lastValidationError,
      'configuredFingerprints':
          _certificateFingerprints[_currentEnvironment]?.length ?? 0,
      'totalEnvironments': _certificateFingerprints.length,
    };
  }

  /// Test certificate pinning
  /// [testUrl] - Test URL to validate
  /// Returns true if test passes
  static Future<bool> testCertificatePinning(String testUrl) async {
    try {
      final uri = Uri.parse(testUrl);
      final isValid = await validateServerCertificate(uri.host, uri.port);

      if (kDebugMode) {
        debugPrint(
            '🧪 Certificate pinning test for $testUrl: ${isValid ? 'PASSED' : 'FAILED'}');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Certificate pinning test failed: $e');
      }
      return false;
    }
  }
}
