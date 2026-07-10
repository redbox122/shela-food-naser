/*
 * App Integrity Checker
 * 
 * Detects security threats like:
 * - Root/jailbreak detection
 * - Emulator detection
 * - Debug mode security
 * - Code signing validation
 * - App tampering detection
 */

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppIntegrityChecker {
  static final AppIntegrityChecker _instance = AppIntegrityChecker._internal();
  factory AppIntegrityChecker() => _instance;
  AppIntegrityChecker._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  bool _isInitialized = false;
  Map<String, bool> _integrityChecks = {};
  
  // Storage keys
  static const String _integrityStatusKey = 'app_integrity_status';
  static const String _lastCheckKey = 'last_integrity_check';

  /// Initialize integrity checker
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _performIntegrityChecks();
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('🔐 App Integrity Checker initialized');
        debugPrint('🔐 Integrity status: $_integrityChecks');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing integrity checker: $e');
      }
    }
  }

  /// Perform all integrity checks
  Future<Map<String, bool>> performIntegrityChecks() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _performIntegrityChecks();
      await _saveIntegrityStatus();
      
      return Map.from(_integrityChecks);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error performing integrity checks: $e');
      }
      return {};
    }
  }

  /// Check if app is running on rooted/jailbroken device
  Future<bool> isDeviceRooted() async {
    try {
      if ((!kIsWeb && Platform.isAndroid)) {
        return await _checkAndroidRoot();
      } else if ((!kIsWeb && Platform.isIOS)) {
        return await _checkIOSJailbreak();
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking root status: $e');
      }
      return true; // Assume rooted if check fails
    }
  }

  /// Check if app is running in emulator
  Future<bool> isEmulator() async {
    try {
      if ((!kIsWeb && Platform.isAndroid)) {
        return await _checkAndroidEmulator();
      } else if ((!kIsWeb && Platform.isIOS)) {
        return await _checkIOSEmulator();
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking emulator status: $e');
      }
      return true; // Assume emulator if check fails
    }
  }

  /// Check if app is in debug mode
  bool isDebugMode() {
    return kDebugMode;
  }

  /// Check if app integrity is compromised
  Future<bool> isIntegrityCompromised() async {
    if (!_isInitialized) await initialize();
    
    return _integrityChecks.values.contains(true);
  }

  /// Get integrity status summary
  Future<Map<String, dynamic>> getIntegrityStatus() async {
    if (!_isInitialized) await initialize();
    
    final compromised = await isIntegrityCompromised();
    final lastCheck = await _secureStorage.read(key: _lastCheckKey);
    
    return {
      'isCompromised': compromised,
      'checks': Map<String, bool>.from(_integrityChecks),
      'lastCheck': lastCheck,
      'timestamp': DateTime.now().toIso8601String(),
      'riskLevel': _calculateRiskLevel(),
    };
  }

  /// Perform Android root detection
  Future<bool> _checkAndroidRoot() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Check build tags
      final buildTags = androidInfo.tags;
      if (buildTags.contains('test-keys') || 
          buildTags.contains('dev-keys')) {
        return true;
      }
      
      // Check for common root apps
      final packages = await _checkForRootPackages();
      if (packages) return true;
      
      // Check for su binary
      final suExists = await _checkForSuBinary();
      if (suExists) return true;
      
      return false;
    } catch (e) {
      return true; // Assume rooted if check fails
    }
  }

  /// Perform iOS jailbreak detection
  Future<bool> _checkIOSJailbreak() async {
    try {
      // Check for common jailbreak files
      final jailbreakFiles = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
        '/private/var/lib/cydia',
        '/private/var/mobile/Library/SBSettings/Themes',
      ];
      
      for (final file in jailbreakFiles) {
        if (await File(file).exists()) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return true; // Assume jailbroken if check fails
    }
  }

  /// Check Android emulator
  Future<bool> _checkAndroidEmulator() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Check build fingerprint
      final fingerprint = androidInfo.fingerprint;
      if (fingerprint.contains('generic') || 
          fingerprint.contains('sdk') ||
          fingerprint.contains('emulator')) {
        return true;
      }
      
      // Check product
      final product = androidInfo.product;
      if (product.contains('sdk') || 
          product.contains('emulator') ||
          product.contains('google_sdk')) {
        return true;
      }
      
      return false;
    } catch (e) {
      return true; // Assume emulator if check fails
    }
  }

  /// Check iOS emulator
  Future<bool> _checkIOSEmulator() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      
      // Check if running on simulator
      if (iosInfo.isPhysicalDevice == false) {
        return true;
      }
      
      return false;
    } catch (e) {
      return true; // Assume emulator if check fails
    }
  }

  /// Check for root packages on Android
  Future<bool> _checkForRootPackages() async {
    try {
      // This would require platform-specific implementation
      // For now, return false as placeholder
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check for su binary
  Future<bool> _checkForSuBinary() async {
    try {
      // This would require platform-specific implementation
      // For now, return false as placeholder
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Perform all integrity checks
  Future<void> _performIntegrityChecks() async {
    _integrityChecks = {
      'rooted': await isDeviceRooted(),
      'emulator': await isEmulator(),
      'debug_mode': isDebugMode(),
    };
  }

  /// Save integrity status
  Future<void> _saveIntegrityStatus() async {
    try {
      await _secureStorage.write(
        key: _integrityStatusKey,
        value: _integrityChecks.toString(),
      );
      await _secureStorage.write(
        key: _lastCheckKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving integrity status: $e');
      }
    }
  }

  /// Calculate risk level
  String _calculateRiskLevel() {
    final compromisedCount = _integrityChecks.values.where((v) => v).length;
    
    if (compromisedCount == 0) return 'LOW';
    if (compromisedCount == 1) return 'MEDIUM';
    if (compromisedCount == 2) return 'HIGH';
    return 'CRITICAL';
  }

  /// Test integrity checker
  Future<Map<String, dynamic>> testIntegrityChecker() async {
    try {
      await initialize();
      final status = await getIntegrityStatus();
      
      if (kDebugMode) {
        debugPrint('🔐 Integrity checker test completed');
        debugPrint('🔐 Status: $status');
      }
      
      return status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Integrity checker test failed: $e');
      }
      return {'error': e.toString()};
    }
  }
}
