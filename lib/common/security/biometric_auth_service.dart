/*
 * Biometric Authentication Service
 * 
 * This service provides secure biometric authentication using fingerprint
 * and face recognition with fallback mechanisms and security levels.
 * 
 * Features:
 * - Fingerprint authentication
 * - Face recognition
 * - PIN/Password fallback
 * - Security level management
 * - Biometric availability checking
 * - Secure authentication flow
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Biometric authentication state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  
  // Security levels
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';
  static const String _fallbackPinKey = 'fallback_pin';
  static const String _securityLevelKey = 'security_level';
  
  // Security level constants
  static const int _securityLevelLow = 1;      // PIN only
  static const int _securityLevelMax = 4;      // Biometric + PIN + Timeout + Location

  /// Initialize biometric authentication service
  Future<void> initialize() async {
    try {
      // Check if biometric authentication is available
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;
      
      if (_isBiometricAvailable) {
        // Get available biometric types
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
        
        // Check if device supports biometric authentication
        _isBiometricAvailable = _availableBiometrics.isNotEmpty;
        
        if (kDebugMode) {
          debugPrint('🔐 Biometric types available: $_availableBiometrics');
        }
      }
      
      // Load saved settings
      await _loadBiometricSettings();
      
      if (kDebugMode) {
        debugPrint('🔐 Biometric Auth Service initialized');
        debugPrint('🔐 Available: $_isBiometricAvailable');
        debugPrint('🔐 Enabled: $_isBiometricEnabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing biometric auth: $e');
      }
      _isBiometricAvailable = false;
    }
  }

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    if (!_isBiometricAvailable) return false;
    
    try {
      return await _localAuth.canCheckBiometrics && 
             await _localAuth.isDeviceSupported();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking biometric availability: $e');
      }
      return false;
    }
  }

  /// Check if biometric authentication is enabled by user
  Future<bool> isBiometricEnabled() async {
    return _isBiometricEnabled;
  }

  /// Get available biometric types
  List<BiometricType> getAvailableBiometrics() {
    return List.from(_availableBiometrics);
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric({
    required int securityLevel,
    String? fallbackPin,
  }) async {
    try {
      if (!await isBiometricAvailable()) {
        throw Exception('Biometric authentication not available on this device');
      }

      // Validate security level
      if (securityLevel < _securityLevelLow || securityLevel > _securityLevelMax) {
        throw Exception('Invalid security level');
      }

      // Save settings
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: 'true',
      );
      await _secureStorage.write(
        key: _securityLevelKey,
        value: securityLevel.toString(),
      );

      if (fallbackPin != null) {
        await _secureStorage.write(
          key: _fallbackPinKey,
          value: fallbackPin,
        );
      }

      _isBiometricEnabled = true;
      
      if (kDebugMode) {
        debugPrint('🔐 Biometric authentication enabled with security level: $securityLevel');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error enabling biometric: $e');
      }
      return false;
    }
  }

  /// Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _securityLevelKey);
      await _secureStorage.delete(key: _fallbackPinKey);
      await _secureStorage.delete(key: _biometricTypeKey);
      
      _isBiometricEnabled = false;
      
      if (kDebugMode) {
        debugPrint('🔐 Biometric authentication disabled');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disabling biometric: $e');
      }
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<BiometricAuthResult> authenticate({
    String? reason,
    String? fallbackTitle,
    String? cancelTitle,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool sensitiveTransaction = false,
  }) async {
    try {
      if (!_isBiometricEnabled) {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication not enabled',
          errorCode: 'not_enabled',
        );
      }

      if (!await isBiometricAvailable()) {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication not available',
          errorCode: 'not_available',
        );
      }

      // Configure authentication options
      final authOptions = AuthenticationOptions(
        stickyAuth: stickyAuth,
        biometricOnly: true,
        useErrorDialogs: useErrorDialogs,
        sensitiveTransaction: sensitiveTransaction,
      );

      // Attempt biometric authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason ?? 'Please authenticate to continue',
        options: authOptions,
      );

      if (authenticated) {
        if (kDebugMode) {
          debugPrint('🔐 Biometric authentication successful');
        }
        
        return BiometricAuthResult(
          success: true,
          biometricType: _getPrimaryBiometricType(),
        );
      } else {
        return BiometricAuthResult(
          success: false,
          error: 'Authentication cancelled or failed',
          errorCode: 'cancelled',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Biometric authentication error: $e');
      }
      
      return BiometricAuthResult(
        success: false,
        error: e.toString(),
        errorCode: 'error',
      );
    }
  }

  /// Authenticate with fallback to PIN
  Future<BiometricAuthResult> authenticateWithFallback({
    required String pin,
    String? reason,
  }) async {
    try {
      // First try biometric authentication
      final biometricResult = await authenticate(reason: reason);
      
      if (biometricResult.success) {
        return biometricResult;
      }

      // If biometric fails, check PIN
      final storedPin = await _secureStorage.read(key: _fallbackPinKey);
      
      if (storedPin == null) {
        return BiometricAuthResult(
          success: false,
          error: 'No fallback PIN configured',
          errorCode: 'no_fallback',
        );
      }

      if (pin == storedPin) {
        if (kDebugMode) {
          debugPrint('🔐 PIN authentication successful');
        }
        
        return BiometricAuthResult(
          success: true,
          biometricType: BiometricType.weak,
          usedFallback: true,
        );
      } else {
        return BiometricAuthResult(
          success: false,
          error: 'Invalid PIN',
          errorCode: 'invalid_pin',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Authentication with fallback error: $e');
      }
      
      return BiometricAuthResult(
        success: false,
        error: e.toString(),
        errorCode: 'error',
      );
    }
  }

  /// Get current security level
  Future<int> getSecurityLevel() async {
    try {
      final level = await _secureStorage.read(key: _securityLevelKey);
      return int.tryParse(level ?? '1') ?? _securityLevelLow;
    } catch (e) {
      return _securityLevelLow;
    }
  }

  /// Update security level
  Future<bool> updateSecurityLevel(int newLevel) async {
    try {
      if (newLevel < _securityLevelLow || newLevel > _securityLevelMax) {
        throw Exception('Invalid security level');
      }

      await _secureStorage.write(
        key: _securityLevelKey,
        value: newLevel.toString(),
      );

      if (kDebugMode) {
        debugPrint('🔐 Security level updated to: $newLevel');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating security level: $e');
      }
      return false;
    }
  }

  /// Get biometric authentication status
  Future<Map<String, dynamic>> getBiometricStatus() async {
    return {
      'isAvailable': await isBiometricAvailable(),
      'isEnabled': _isBiometricEnabled,
      'availableTypes': _availableBiometrics.map((e) => e.toString()).toList(),
      'securityLevel': await getSecurityLevel(),
      'hasFallbackPin': await _secureStorage.read(key: _fallbackPinKey) != null,
    };
  }

  /// Test biometric authentication
  Future<BiometricAuthResult> testBiometric() async {
    return await authenticate(
      reason: 'Testing biometric authentication',
      useErrorDialogs: false,
    );
  }

  /// Load saved biometric settings
  Future<void> _loadBiometricSettings() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      _isBiometricEnabled = enabled == 'true';
    } catch (e) {
      _isBiometricEnabled = false;
    }
  }

  /// Get primary biometric type
  BiometricType _getPrimaryBiometricType() {
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return BiometricType.iris;
    }
    return BiometricType.weak;
  }
}

/// Result of biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final BiometricType? biometricType;
  final bool usedFallback;

  BiometricAuthResult({
    required this.success,
    this.error,
    this.errorCode,
    this.biometricType,
    this.usedFallback = false,
  });

  @override
  String toString() {
    if (success) {
      return 'BiometricAuthResult(success: true, type: $biometricType, fallback: $usedFallback)';
    } else {
      return 'BiometricAuthResult(success: false, error: $error, code: $errorCode)';
    }
  }
}
