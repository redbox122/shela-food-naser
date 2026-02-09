import 'package:logger/logger.dart';

/// Centralized Logger for the entire application
/// 
/// This logger provides:
/// - Pretty formatted output with colors and emojis
/// - Stack trace information
/// - Timestamp logging
/// - Configurable method count in stack traces
/// 
/// Usage:
/// ```dart
/// import 'package:sixam_mart/core/logger/app_logger.dart';
/// 
/// logger.i("App started");
/// logger.w("API response is slow");
/// logger.e("Error occurred", error, stackTrace);
/// ```
final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,        // Number of methods in stack trace
    errorMethodCount: 5,   // Number of methods when error occurs
    lineLength: 90,       // Line width
    colors: true,         // Enable colors
    printEmojis: true,    // 🚀 ❌ ⚠️
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Print timestamp with elapsed time
  ),
);
