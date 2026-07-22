// ignore_for_file: constant_identifier_names

/// Environment Configuration for Indian Shella App
/// This file manages different environment configurations
///
/// To switch environments, change the currentEnvironment variable
///
/// Available environments:
/// - development: Local XAMPP server
/// - staging: Staging server
/// - production: Production server
library;

import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

enum Environment { development, staging, production, azure }

class EnvironmentConfig {
  // Change this to switch environments
  // ⚠️ TEMP: pointed at Azure (shellagroup) to test the هايبر شله rebuild.
  // Revert to Environment.production before any release build.
  static const Environment currentEnvironment = Environment.azure;

  // Environment-specific configurations
  static const Map<Environment, Map<String, String>> _configs = {
    Environment.development: {
      // Dev host is NOT hardcoded: override at build time with
      //   --dart-define=DEV_BASE_URL=http://<your-lan-ip>:8000
      // Default is the Android-emulator host loopback so nothing personal is in git.
      'baseUrl': String.fromEnvironment('DEV_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000'),
      'webHostedUrl': String.fromEnvironment('DEV_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000'),
      'description': 'Local Laravel Dev (override via --dart-define=DEV_BASE_URL)',
    },
    Environment.staging: {
      'baseUrl': 'https://staging.shelafood.com',
      'webHostedUrl': 'https://staging.shelafood.com',
      'description': 'Staging Server',
    },
    Environment.production: {
      'baseUrl': 'https://shellafood.com',
      'webHostedUrl': 'https://shellafood.com',
      'description': 'Production Server',
    },
    Environment.azure: {
      'baseUrl': 'https://shellagroup.uaenorth.cloudapp.azure.com',
      'webHostedUrl': 'https://shellagroup.uaenorth.cloudapp.azure.com',
      'description': 'Azure (shellagroup) — هايبر شله rebuild test',
    },
  };

  /// Get current base URL based on environment
  static String get baseUrl => _configs[currentEnvironment]!['baseUrl']!;

  /// Get current web hosted URL based on environment
  static String get webHostedUrl =>
      _configs[currentEnvironment]!['webHostedUrl']!;

  /// Get current environment description
  static String get description =>
      _configs[currentEnvironment]!['description']!;

  /// Check if current environment is development
  static bool get isDevelopment =>
      currentEnvironment == Environment.development;

  /// Check if current environment is staging
  static bool get isStaging => currentEnvironment == Environment.staging;

  /// Check if current environment is production
  static bool get isProduction => currentEnvironment == Environment.production;

  /// Get environment name as string
  static String get environmentName => currentEnvironment.name.toUpperCase();

  /// Master switch for TLS certificate pinning.
  ///
  /// OFF by default on purpose: with this flag false the app behaves exactly as
  /// before — plain HTTPS validated by the OS trust store, no cert assets are
  /// loaded and no custom SecurityContext is built.
  ///
  /// When true (mobile only — web is always skipped), every Dio client that
  /// talks to our own domain is pinned to the bundled GTS WE1 intermediate and
  /// GTS Root R4 CA certificates (see assets/certs/). Do NOT enable for
  /// production until it has been validated on a real test build, otherwise a
  /// wrong/expired pin would lock every user out of the app.
  static const bool enableCertificatePinning = false;

  /// Check if secure HTTP client should be used
  static bool get useSecureHttpClient =>
      currentEnvironment == Environment.production;

  /// Print current environment configuration
  static void printConfig() {
    if (kDebugMode) {
      appLogger.info('🌍 Environment: $environmentName');
      appLogger.info('🔗 Base URL: $baseUrl');
      appLogger.info('🌐 Web URL: $webHostedUrl');
      appLogger.info('📝 Description: $description');
    }
  }
}
