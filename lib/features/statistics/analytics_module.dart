// Analytics Module - Main entry point
// This file initializes all analytics dependencies and provides easy access

import 'di/analytics_di.dart';
import 'config/analytics_config.dart';
import 'controllers/analytics_controller.dart';
import 'domain/repositories/analytics_repository.dart';

class AnalyticsModule {
  static bool _isInitialized = false;

  /// Initialize the analytics module
  /// Call this in your main.dart or app initialization
  static void initialize() {
    if (_isInitialized) {
      AnalyticsConfig.log('Analytics module already initialized');
      return;
    }

    try {
      AnalyticsConfig.log('Initializing analytics module...');
      initAnalyticsDependencies();
      _isInitialized = true;
      AnalyticsConfig.log('Analytics module initialized successfully');
    } catch (e) {
      AnalyticsConfig.log('Error initializing analytics module: $e');
      rethrow;
    }
  }

  /// Check if the module is initialized
  static bool get isInitialized => _isInitialized;

  /// Get analytics controller
  static AnalyticsController getController() {
    if (!_isInitialized) {
      throw Exception('Analytics module not initialized. Call AnalyticsModule.initialize() first.');
    }
    return getAnalyticsController();
  }

  /// Get analytics repository
  static AnalyticsRepository getRepository() {
    if (!_isInitialized) {
      throw Exception('Analytics module not initialized. Call AnalyticsModule.initialize() first.');
    }
    return getAnalyticsRepository();
  }

  /// Reset the module (for testing)
  static void reset() {
    _isInitialized = false;
    AnalyticsConfig.log('Analytics module reset');
  }
}
