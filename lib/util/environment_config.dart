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

enum Environment { development, staging, production }

class EnvironmentConfig {
  // Change this to switch environments
  static const Environment currentEnvironment = Environment.production;

  // Environment-specific configurations
  static const Map<Environment, Map<String, String>> _configs = {
    Environment.development: {
      'baseUrl':
          'http://192.168.100.6:8000', // Updated: Using computer's local IP for Android Emulator
      'webHostedUrl':
          'http://192.168.100.6:8000', // Updated: Using computer's local IP for Android Emulator
      'description': 'Local Laravel Development Server (192.168.100.6:8000)',
    },
    Environment.staging: {
      'baseUrl': 'https://staging.shelafood.com',
      'webHostedUrl': 'https://staging.shelafood.com',
      'description': 'Staging Server',
    },
    Environment.production: {
      'baseUrl': 'https://shellagroup.uaenorth.cloudapp.azure.com',
      'webHostedUrl': 'https://shellagroup.uaenorth.cloudapp.azure.com',
      'description': 'Production Server',
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
