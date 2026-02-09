import 'package:equatable/equatable.dart';

/// Base class for all application failures
/// 
/// Provides unified error handling across the application
/// All specific failure types extend this base class
abstract class AppFailure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppFailure({
    required this.message,
    this.code,
    this.originalError,
  });
  
  @override
  List<Object?> get props => [message, code, originalError];
  
  @override
  String toString() => 'AppFailure(message: $message, code: $code)';
}

/// Server-side errors (5xx, API errors)
class ServerFailure extends AppFailure {
  final int? statusCode;
  
  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });
  
  @override
  List<Object?> get props => [super.props, statusCode];
  
  @override
  String toString() => 'ServerFailure(message: $message, statusCode: $statusCode)';
}

/// Network connectivity errors (timeout, no internet, socket errors)
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalError,
  });
  
  @override
  String toString() => 'NetworkFailure(message: $message)';
}

/// Cache-related errors (read/write failures, corruption)
class CacheFailure extends AppFailure {
  const CacheFailure({
    required super.message,
    super.code,
    super.originalError,
  });
  
  @override
  String toString() => 'CacheFailure(message: $message)';
}

/// Validation errors (input validation, business rules)
class ValidationFailure extends AppFailure {
  final Map<String, List<String>>? fieldErrors;
  
  const ValidationFailure({
    required super.message,
    super.code,
    super.originalError,
    this.fieldErrors,
  });
  
  @override
  List<Object?> get props => [super.props, fieldErrors];
  
  @override
  String toString() => 'ValidationFailure(message: $message, fieldErrors: $fieldErrors)';
}

/// Authentication/Authorization errors (401, 403)
class AuthFailure extends AppFailure {
  final int? statusCode;
  
  const AuthFailure({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });
  
  @override
  List<Object?> get props => [super.props, statusCode];
  
  @override
  String toString() => 'AuthFailure(message: $message, statusCode: $statusCode)';
}

/// Unknown/Unexpected errors
class UnknownFailure extends AppFailure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.originalError,
  });
  
  @override
  String toString() => 'UnknownFailure(message: $message)';
}

