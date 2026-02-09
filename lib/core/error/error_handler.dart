import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/core/error/app_failure.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

/// Centralized Error Handler Service
/// 
/// Provides unified error handling across the application:
/// - Converts exceptions to AppFailure types
/// - Provides user-friendly error messages
/// - Handles error logging
/// - Manages error display (snackbars, dialogs)
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Convert exception to AppFailure
  /// 
  /// Analyzes the exception type and converts it to appropriate AppFailure subclass
  AppFailure handleException(dynamic exception, {String? context}) {
    if (exception is AppFailure) {
      return exception;
    }
    
    final errorMessage = exception.toString();
    final contextPrefix = context != null ? '[$context] ' : '';
    
    // Network errors
    if (exception is SocketException) {
      return NetworkFailure(
        message: 'no_internet_connection'.tr,
        code: 'SOCKET_EXCEPTION',
        originalError: exception,
      );
    }
    
    if (exception is HttpException) {
      return NetworkFailure(
        message: 'network_error'.tr,
        code: 'HTTP_EXCEPTION',
        originalError: exception,
      );
    }
    
    if (errorMessage.contains('TimeoutException') || 
        errorMessage.contains('timeout') ||
        errorMessage.contains('SocketException')) {
      return NetworkFailure(
        message: 'request_timeout'.tr,
        code: 'TIMEOUT',
        originalError: exception,
      );
    }
    
    // Server errors (from API responses)
    if (errorMessage.contains('500') || 
        errorMessage.contains('Internal Server Error')) {
      return ServerFailure(
        message: 'server_error'.tr,
        statusCode: 500,
        code: 'SERVER_ERROR',
        originalError: exception,
      );
    }
    
    if (errorMessage.contains('401') || 
        errorMessage.contains('Unauthorized')) {
      return AuthFailure(
        message: 'unauthorized_access'.tr,
        statusCode: 401,
        code: 'UNAUTHORIZED',
        originalError: exception,
      );
    }
    
    if (errorMessage.contains('403') || 
        errorMessage.contains('Forbidden')) {
      return AuthFailure(
        message: 'access_forbidden'.tr,
        statusCode: 403,
        code: 'FORBIDDEN',
        originalError: exception,
      );
    }
    
    if (errorMessage.contains('404') || 
        errorMessage.contains('Not Found')) {
      return ServerFailure(
        message: 'resource_not_found'.tr,
        statusCode: 404,
        code: 'NOT_FOUND',
        originalError: exception,
      );
    }
    
    // Validation errors
    if (errorMessage.contains('422') || 
        errorMessage.contains('Unprocessable Entity') ||
        errorMessage.contains('validation')) {
      return ValidationFailure(
        message: 'validation_error'.tr,
        code: 'VALIDATION_ERROR',
        originalError: exception,
      );
    }
    
    // Unknown error
    return UnknownFailure(
      message: '${contextPrefix}something_went_wrong'.tr,
      code: 'UNKNOWN',
      originalError: exception,
    );
  }
  
  /// Handle error and show user-friendly message
  /// 
  /// Converts exception to AppFailure, logs it, and optionally shows snackbar
  AppFailure handleError(
    dynamic error, {
    String? context,
    bool showSnackbar = true,
    bool logError = true,
  }) {
    final failure = handleException(error, context: context);
    
    if (logError) {
      _logError(failure, context: context);
    }
    
    if (showSnackbar) {
      _showErrorSnackbar(failure);
    }
    
    return failure;
  }
  
  /// Log error for debugging
  void _logError(AppFailure failure, {String? context}) {
    final contextPrefix = context != null ? '[$context] ' : '';
    
    appLogger.error(
      '${contextPrefix}Error: ${failure.message}',
      failure.originalError,
      failure.originalError is Error 
          ? (failure.originalError as Error).stackTrace 
          : null,
    );
    
    if (kDebugMode) {
      debugPrint('❌ $contextPrefix${failure.toString()}');
      if (failure.originalError != null) {
        debugPrint('   Original error: ${failure.originalError}');
      }
    }
  }
  
  /// Show error snackbar to user
  void _showErrorSnackbar(AppFailure failure) {
    showCustomSnackBar(
      failure.message,
      isError: true,
    );
  }
  
  /// Get user-friendly error message from failure
  String getUserMessage(AppFailure failure) {
    return failure.message;
  }
  
  /// Check if error is network-related
  bool isNetworkError(AppFailure failure) {
    return failure is NetworkFailure;
  }
  
  /// Check if error is server-related
  bool isServerError(AppFailure failure) {
    return failure is ServerFailure;
  }
  
  /// Check if error is authentication-related
  bool isAuthError(AppFailure failure) {
    return failure is AuthFailure;
  }
  
  /// Check if error is validation-related
  bool isValidationError(AppFailure failure) {
    return failure is ValidationFailure;
  }
}

