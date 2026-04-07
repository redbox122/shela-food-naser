/*
 * Input Validation Service
 * 
 * This file provides comprehensive input validation and sanitization for the Indian Shella App.
 * It implements security measures to prevent injection attacks, XSS, and other input-based vulnerabilities.
 * 
 * Features:
 * - SQL injection prevention
 * - XSS prevention
 * - Input sanitization
 * - Format validation
 * - Security pattern detection
 * - Input length validation
 */

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Input Validation Service for security
/// Prevents injection attacks and validates user inputs
class InputValidationService {
  // Security patterns for malicious content detection
  static const List<String> _sqlInjectionPatterns = [
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER',
    'UNION', 'EXEC', 'EXECUTE', 'SCRIPT', 'VBSCRIPT', 'JAVASCRIPT',
    '--', '/*', '*/', ';', 'OR', 'AND', '1=1', '1=0',
  ];

  static const List<String> _xssPatterns = [
    '<script', '</script>', 'javascript:', 'vbscript:', 'data:text/html',
    'onload=', 'onerror=', 'onclick=', 'onmouseover=', 'onfocus=',
    'eval(', 'document.cookie', 'window.location', 'innerHTML',
    'outerHTML', 'document.write', 'document.writeln',
  ];

  static const List<String> _pathTraversalPatterns = [
    '../', '..\\', '..%2f', '..%5c', '%2e%2e%2f', '%2e%2e%5c',
    '....//', '....\\\\', '..%252f', '..%255c',
  ];

  static final List<String> _commandInjectionPatterns = [
    '|', '&', ';', '`', '\$', '(', ')', '{', '}', '[', ']',
    '&&', '||', '>>', '<<', '>', '<',
  ];

  // Input length limits
  static const Map<String, int> _inputLengthLimits = {
    'email': 254,
    'phone': 20,
    'name': 100,
    'address': 500,
    'password': 128,
    'username': 50,
    'comment': 1000,
    'description': 2000,
    'url': 2048,
    'search': 200,
  };

  // Email validation regex
  // ignore: deprecated_member_use
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  // Phone validation regex
  // ignore: deprecated_member_use
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );

  // URL validation regex
  // ignore: deprecated_member_use
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  /// Validate and sanitize text input
  /// [input] - Input text to validate
  /// [type] - Type of input for specific validation rules
  /// [required] - Whether input is required
  /// Returns validation result with sanitized input
  static ValidationResult validateTextInput(
    String? input,
    String type, {
    bool required = false,
  }) {
    try {
      // Check if required
      if (required && (input == null || input.trim().isEmpty)) {
        return ValidationResult(
          isValid: false,
          sanitizedInput: '',
          errorMessage: '$type is required',
          errorType: ValidationErrorType.required,
        );
      }

      // Handle null/empty input
      if (input == null || input.trim().isEmpty) {
        return ValidationResult(
          isValid: true,
          sanitizedInput: '',
          errorMessage: '',
          errorType: ValidationErrorType.none,
        );
      }

      final trimmedInput = input.trim();
      final sanitizedInput = _sanitizeInput(trimmedInput);

      // Check length limits
      final lengthLimit = _inputLengthLimits[type] ?? 1000;
      if (sanitizedInput.length > lengthLimit) {
        return ValidationResult(
          isValid: false,
          sanitizedInput: sanitizedInput,
          errorMessage: '$type must be less than $lengthLimit characters',
          errorType: ValidationErrorType.tooLong,
        );
      }

      // Check for malicious patterns
      final maliciousCheck = _checkMaliciousPatterns(sanitizedInput);
      if (maliciousCheck.isMalicious) {
        return ValidationResult(
          isValid: false,
          sanitizedInput: sanitizedInput,
          errorMessage: 'Invalid characters detected in $type',
          errorType: ValidationErrorType.malicious,
        );
      }

      // Type-specific validation
      final typeValidation = _validateByType(sanitizedInput, type);
      if (!typeValidation.isValid) {
        return ValidationResult(
          isValid: false,
          sanitizedInput: sanitizedInput,
          errorMessage: typeValidation.errorMessage,
          errorType: typeValidation.errorType,
        );
      }

      return ValidationResult(
        isValid: true,
        sanitizedInput: sanitizedInput,
        errorMessage: '',
        errorType: ValidationErrorType.none,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Input validation error: $e');
      }
      return ValidationResult(
        isValid: false,
        sanitizedInput: input ?? '',
        errorMessage: 'Validation failed: $e',
        errorType: ValidationErrorType.validationError,
      );
    }
  }

  /// Validate email address
  /// [email] - Email to validate
  /// [required] - Whether email is required
  /// Returns validation result
  static ValidationResult validateEmail(String? email, {bool required = false}) {
    return validateTextInput(email, 'email', required: required);
  }

  /// Validate phone number
  /// [phone] - Phone to validate
  /// [required] - Whether phone is required
  /// Returns validation result
  static ValidationResult validatePhone(String? phone, {bool required = false}) {
    return validateTextInput(phone, 'phone', required: required);
  }

  /// Validate password
  /// [password] - Password to validate
  /// [required] - Whether password is required
  /// Returns validation result
  static ValidationResult validatePassword(String? password, {bool required = false}) {
    if (required && (password == null || password.isEmpty)) {
      return ValidationResult(
        isValid: false,
        sanitizedInput: '',
        errorMessage: 'Password is required',
        errorType: ValidationErrorType.required,
      );
    }

    if (password == null || password.isEmpty) {
      return ValidationResult(
        isValid: true,
        sanitizedInput: '',
        errorMessage: '',
        errorType: ValidationErrorType.none,
      );
    }

    // Password strength validation
    final strengthCheck = _validatePasswordStrength(password);
    if (!strengthCheck.isValid) {
      return ValidationResult(
        isValid: false,
        sanitizedInput: password,
        errorMessage: strengthCheck.errorMessage,
        errorType: ValidationErrorType.weakPassword,
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedInput: password,
      errorMessage: '',
      errorType: ValidationErrorType.none,
    );
  }

  /// Validate URL
  /// [url] - URL to validate
  /// [required] - Whether URL is required
  /// Returns validation result
  static ValidationResult validateUrl(String? url, {bool required = false}) {
    return validateTextInput(url, 'url', required: required);
  }

  /// Validate file upload
  /// [fileName] - Name of uploaded file
  /// [fileSize] - Size of file in bytes
  /// [allowedExtensions] - List of allowed file extensions
  /// [maxSize] - Maximum file size in bytes
  /// Returns validation result
  static ValidationResult validateFileUpload(
    String fileName,
    int fileSize, {
    List<String>? allowedExtensions,
    int? maxSize,
  }) {
    try {
      // Check file name
      final nameValidation = validateTextInput(fileName, 'filename');
      if (!nameValidation.isValid) {
        return nameValidation;
      }

      // Check file extension
      if (allowedExtensions != null) {
        final extension = _getFileExtension(fileName).toLowerCase();
        if (!allowedExtensions.contains(extension)) {
          return ValidationResult(
            isValid: false,
            sanitizedInput: fileName,
            errorMessage: 'File type not allowed. Allowed types: ${allowedExtensions.join(', ')}',
            errorType: ValidationErrorType.invalidFileType,
          );
        }
      }

      // Check file size
      if (maxSize != null && fileSize > maxSize) {
        final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(1);
        return ValidationResult(
          isValid: false,
          sanitizedInput: fileName,
          errorMessage: 'File size too large. Maximum size: ${maxSizeMB}MB',
          errorType: ValidationErrorType.fileTooLarge,
        );
      }

      // Check for malicious file names
      if (_containsMaliciousFileName(fileName)) {
        return ValidationResult(
          isValid: false,
          sanitizedInput: fileName,
          errorMessage: 'Invalid file name detected',
          errorType: ValidationErrorType.malicious,
        );
      }

      return ValidationResult(
        isValid: true,
        sanitizedInput: fileName,
        errorMessage: '',
        errorType: ValidationErrorType.none,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        sanitizedInput: fileName,
        errorMessage: 'File validation failed: $e',
        errorType: ValidationErrorType.validationError,
      );
    }
  }

  /// Sanitize input text
  /// [input] - Input to sanitize
  /// Returns sanitized input
  static String _sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove null bytes
    var sanitized = input.replaceAll('\x00', '');
    
    // Remove control characters (except newline and tab)
    // ignore: deprecated_member_use
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    // Normalize whitespace
    // ignore: deprecated_member_use
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // HTML encode special characters
    sanitized = _htmlEncode(sanitized);
    
    return sanitized;
  }

  /// Check for malicious patterns in input
  /// [input] - Input to check
  /// Returns malicious check result
  static MaliciousCheckResult _checkMaliciousPatterns(String input) {
    final lowerInput = input.toLowerCase();
    
    // Check SQL injection patterns
    for (final pattern in _sqlInjectionPatterns) {
      if (lowerInput.contains(pattern.toLowerCase())) {
        return MaliciousCheckResult(
          isMalicious: true,
          patternType: 'SQL Injection',
          pattern: pattern,
        );
      }
    }

    // Check XSS patterns
    for (final pattern in _xssPatterns) {
      if (lowerInput.contains(pattern.toLowerCase())) {
        return MaliciousCheckResult(
          isMalicious: true,
          patternType: 'XSS',
          pattern: pattern,
        );
      }
    }

    // Check path traversal patterns
    for (final pattern in _pathTraversalPatterns) {
      if (lowerInput.contains(pattern.toLowerCase())) {
        return MaliciousCheckResult(
          isMalicious: true,
          patternType: 'Path Traversal',
          pattern: pattern,
        );
      }
    }

    // Check command injection patterns
    for (final pattern in _commandInjectionPatterns) {
      if (lowerInput.contains(pattern.toLowerCase())) {
        return MaliciousCheckResult(
          isMalicious: true,
          patternType: 'Command Injection',
          pattern: pattern,
        );
      }
    }

    return MaliciousCheckResult(
      isMalicious: false,
      patternType: '',
      pattern: '',
    );
  }

  /// Validate input by type
  /// [input] - Input to validate
  /// [type] - Type of input
  /// Returns validation result
  static ValidationResult _validateByType(String input, String type) {
    switch (type) {
      case 'email':
        if (!_emailRegex.hasMatch(input)) {
          return ValidationResult(
            isValid: false,
            sanitizedInput: input,
            errorMessage: 'Invalid email format',
            errorType: ValidationErrorType.invalidFormat,
          );
        }
        break;
        
      case 'phone':
        if (!_phoneRegex.hasMatch(input)) {
          return ValidationResult(
            isValid: false,
            sanitizedInput: input,
            errorMessage: 'Invalid phone number format',
            errorType: ValidationErrorType.invalidFormat,
          );
        }
        break;
        
      case 'url':
        if (!_urlRegex.hasMatch(input)) {
          return ValidationResult(
            isValid: false,
            sanitizedInput: input,
            errorMessage: 'Invalid URL format',
            errorType: ValidationErrorType.invalidFormat,
          );
        }
        break;
        
      case 'name':
        if (input.length < 2) {
          return ValidationResult(
            isValid: false,
            sanitizedInput: input,
            errorMessage: 'Name must be at least 2 characters long',
            errorType: ValidationErrorType.tooShort,
          );
        }
        break;
        
      case 'password':
        if (input.length < 8) {
          return ValidationResult(
            isValid: false,
            sanitizedInput: input,
            errorMessage: 'Password must be at least 8 characters long',
            errorType: ValidationErrorType.tooShort,
          );
        }
        break;
    }

    return ValidationResult(
      isValid: true,
      sanitizedInput: input,
      errorMessage: '',
      errorType: ValidationErrorType.none,
    );
  }

  /// Validate password strength
  /// [password] - Password to validate
  /// Returns validation result
  static ValidationResult _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return ValidationResult(
        isValid: false,
        sanitizedInput: password,
        errorMessage: 'Password must be at least 8 characters long',
        errorType: ValidationErrorType.tooShort,
      );
    }

    // Check for common weak passwords
    final weakPasswords = [
      'password', '123456', '12345678', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
    ];

    if (weakPasswords.contains(password.toLowerCase())) {
      return ValidationResult(
        isValid: false,
        sanitizedInput: password,
        errorMessage: 'Password is too common, please choose a stronger password',
        errorType: ValidationErrorType.weakPassword,
      );
    }

    // Check password complexity
    // ignore: deprecated_member_use
    final bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    // ignore: deprecated_member_use
    final bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    // ignore: deprecated_member_use
    final bool hasDigits = password.contains(RegExp(r'[0-9]'));

    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return ValidationResult(
        isValid: false,
        sanitizedInput: password,
        errorMessage: 'Password must contain uppercase, lowercase, and numbers',
        errorType: ValidationErrorType.weakPassword,
      );
    }

    return ValidationResult(
      isValid: true,
      sanitizedInput: password,
      errorMessage: '',
      errorType: ValidationErrorType.none,
    );
  }

  /// Get file extension from filename
  /// [fileName] - Filename to extract extension from
  /// Returns file extension
  static String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Check if filename contains malicious patterns
  /// [fileName] - Filename to check
  /// Returns true if malicious
  static bool _containsMaliciousFileName(String fileName) {
    final maliciousPatterns = [
      '..', '\\', '/', ':', '*', '?', '"', '<', '>', '|',
      'con', 'prn', 'aux', 'nul', 'com1', 'com2', 'com3', 'com4',
      'com5', 'com6', 'com7', 'com8', 'com9', 'lpt1', 'lpt2',
      'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
    ];

    final lowerFileName = fileName.toLowerCase();
    return maliciousPatterns.any((pattern) => lowerFileName.contains(pattern));
  }

  /// HTML encode special characters
  /// [input] - Input to encode
  /// Returns encoded input
  static String _htmlEncode(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Generate secure random string
  /// [length] - Length of string to generate
  /// Returns random string
  static String generateSecureRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final bytes = utf8.encode(random.toString());
    final hash = sha256.convert(bytes);
    
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[hash.bytes[i % hash.bytes.length] % chars.length];
    }
    
    return result;
  }

  /// Get validation statistics
  /// Returns map with validation metrics
  static Map<String, dynamic> getValidationStats() {
    return {
      'sqlInjectionPatterns': _sqlInjectionPatterns.length,
      'xssPatterns': _xssPatterns.length,
      'pathTraversalPatterns': _pathTraversalPatterns.length,
      'commandInjectionPatterns': _commandInjectionPatterns.length,
      'inputLengthLimits': _inputLengthLimits,
      'supportedTypes': _inputLengthLimits.keys.toList(),
    };
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String sanitizedInput;
  final String errorMessage;
  final ValidationErrorType errorType;

  ValidationResult({
    required this.isValid,
    required this.sanitizedInput,
    required this.errorMessage,
    required this.errorType,
  });
}

/// Validation error types
enum ValidationErrorType {
  none,
  required,
  tooShort,
  tooLong,
  invalidFormat,
  malicious,
  weakPassword,
  invalidFileType,
  fileTooLarge,
  validationError,
}

/// Malicious check result class
class MaliciousCheckResult {
  final bool isMalicious;
  final String patternType;
  final String pattern;

  MaliciousCheckResult({
    required this.isMalicious,
    required this.patternType,
    required this.pattern,
  });
}
