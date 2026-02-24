import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class AnalyticsConfig {
  // Configuration flags
  static const bool useMockData = false; // Backend is ready - use real APIs
  static const bool enableCaching = true;
  static const bool enableOfflineMode = true;
  static const bool enableDebugLogging = true;

  // Cache settings
  static const Duration cacheExpiration = Duration(minutes: 15);
  static const Duration insightsCacheExpiration = Duration(hours: 1);

  // API settings
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Pagination settings
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // Export settings
  static const List<String> supportedExportFormats = ['pdf', 'csv', 'json'];
  static const int maxExportDataDays = 365;

  // Chart settings
  static const int maxDataPoints = 100;
  static const Duration chartAnimationDuration = Duration(milliseconds: 500);

  // Debug settings
  static void log(String message) {
    if (enableDebugLogging) {
      if (kDebugMode) {
        appLogger.debug('[Analytics] $message');
      }
    }
  }

  // Feature flags
  static const bool enableProductDeepDive = true;
  static const bool enableInsights = true;
  static const bool enableExport = true;
  static const bool enableRealTimeUpdates = false; // For future implementation

  // Validation settings
  static const double minSpendingAmount = 0.01;
  static const double maxSpendingAmount = 999999.99;
  static const int minPurchaseCount = 1;
  static const int maxPurchaseCount = 9999;
}
