import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class SecureTokenLoader {
  static bool _initialized = false;

  /// Initialize secure tokens from platform-specific sources
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Platform.isAndroid) {
        await _loadAndroidTokens();
      } else if (Platform.isIOS) {
        await _loadIOSTokens();
      }

      _initialized = true;
      if (kDebugMode) {
        appLogger.info('✅ Secure tokens loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('❌ Failed to load secure tokens: $e', e);
      }
      // Fallback to empty tokens (app will show error)
    }
  }

  /// Load tokens from Android BuildConfig via platform channel
  static Future<void> _loadAndroidTokens() async {
    try {
      const MethodChannel channel = MethodChannel('secure_tokens');

      final String liveToken = (await channel.invokeMethod('getLiveToken')) as String;
      final String testToken = (await channel.invokeMethod('getTestToken')) as String;

      AppConstants.initializeTokens(
        liveToken: liveToken.isNotEmpty ? liveToken : null,
        testToken: testToken.isNotEmpty ? testToken : null,
      );

      if (kDebugMode) {
        appLogger.info(
            '✅ Android tokens loaded: Live=${liveToken.isNotEmpty}, Test=${testToken.isNotEmpty}');
      }
    } catch (e) {
      // 🔧 FIX: Better error handling - check if it's TOKEN_NOT_FOUND (expected in debug builds)
      final errorString = e.toString();
      if (errorString.contains('TOKEN_NOT_FOUND')) {
        if (kDebugMode) {
          appLogger.warning('⚠️ SecureTokenLoader: TOKEN_NOT_FOUND - This is expected in debug builds without BuildConfig tokens');
          appLogger.debug('   - Payment tokens will use environment variables or be empty');
          appLogger.debug('   - This does not affect app functionality, only payment integration');
        }
      } else {
        if (kDebugMode) {
          appLogger.error('❌ Android token loading failed: $e', e);
        }
      }
      
      // Fallback to environment variables
      const String liveToken =
          String.fromEnvironment('MYFATOORAH_LIVE_TOKEN');
      const String testToken =
          String.fromEnvironment('MYFATOORAH_TEST_TOKEN');

      AppConstants.initializeTokens(
        liveToken: liveToken.isNotEmpty ? liveToken : null,
        testToken: testToken.isNotEmpty ? testToken : null,
      );
    }
  }

  /// Load tokens from iOS Info.plist or secure storage
  static Future<void> _loadIOSTokens() async {
    try {
      // iOS implementation would read from Info.plist or Keychain
      // For now, using environment variables as fallback
      const String liveToken =
          String.fromEnvironment('MYFATOORAH_LIVE_TOKEN');
      const String testToken =
          String.fromEnvironment('MYFATOORAH_TEST_TOKEN');

      AppConstants.initializeTokens(
        liveToken: liveToken.isNotEmpty ? liveToken : null,
        testToken: testToken.isNotEmpty ? testToken : null,
      );
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('❌ iOS token loading failed: $e', e);
      }
    }
  }

  /// Check if tokens are properly loaded
  static bool get isInitialized => _initialized;

  /// Get current token based on environment
  static String get currentToken {
    if (!_initialized) return '';

    return AppConstants.useMyFatoorahTestMode
        ? AppConstants.myFatoorahTestToken
        : AppConstants.myFatoorahLiveToken;
  }
}
