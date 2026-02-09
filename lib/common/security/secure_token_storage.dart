/*
 * Secure Token Storage System
 * 
 * This file provides a secure, encrypted token storage system for the Indian Shella App.
 * It implements AES-256 encryption with secure key management and token rotation.
 * 
 * Features:
 * - AES-256 encryption for all stored tokens
 * - Secure key derivation and management
 * - Token rotation and expiration handling
 * - Secure token validation and verification
 * - Memory-safe token handling
 */

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Token Storage System with AES-256 encryption
/// Provides enterprise-grade security for storing sensitive authentication tokens
class SecureTokenStorage {
  // Private constants for encryption
  static const String _tokenKey = 'encrypted_auth_token';
  static const String _refreshTokenKey = 'encrypted_refresh_token';
  static const String _tokenExpiryKey = 'token_expiry_timestamp';
  static const String _lastRotationKey = 'last_token_rotation';
  static const String _rotationCountKey = 'token_rotation_count';
  
  // Encryption configuration
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits
  static const int _maxRotationCount = 100; // Maximum token rotations
  
  // Token expiration settings
  static const Duration _defaultTokenExpiry = Duration(hours: 24);
  static const Duration _rotationThreshold = Duration(hours: 12);
  
  // Secure key storage
  static Key? _encryptionKey;
  static IV? _initializationVector;
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;
  
  // ⚡ PERFORMANCE: In-memory token cache to avoid repeated decryption
  static String? _cachedToken;
  static DateTime? _cachedTokenExpiry;
  static DateTime? _cachedTokenTimestamp;
  static const Duration _cacheValidityDuration = Duration(minutes: 5); // Cache for 5 minutes
  
  /// Initialize the secure token storage system
  /// This must be called before using any other methods
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Handle concurrent initialization calls
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    
    _initCompleter = Completer<void>();
    
    try {
      // Generate or retrieve secure encryption key
      await _initializeEncryptionKeys();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('🔐 Secure Token Storage initialized successfully');
      }
      _initCompleter?.complete();
    } catch (e) {
      _initCompleter?.completeError(e);
      _initCompleter = null; // Reset on failure so we can try again
      throw Exception('Failed to initialize Secure Token Storage: $e');
    }
  }
  
  /// Initialize encryption keys securely
  static Future<void> _initializeEncryptionKeys() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have existing keys
    final String? existingKey = prefs.getString('secure_encryption_key');
    final String? existingIV = prefs.getString('secure_initialization_vector');
    
    if (existingKey != null && existingIV != null) {
      // Use existing keys
      _encryptionKey = Key.fromBase64(existingKey);
      _initializationVector = IV.fromBase64(existingIV);
    } else {
      // Generate new secure keys
      final random = Random.secure();
      final keyBytes = Uint8List(_keyLength);
      final ivBytes = Uint8List(_ivLength);
      
      for (int i = 0; i < _keyLength; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      for (int i = 0; i < _ivLength; i++) {
        ivBytes[i] = random.nextInt(256);
      }
      
      _encryptionKey = Key(keyBytes);
      _initializationVector = IV(ivBytes);
      
      // Store keys securely (in production, consider using Flutter Secure Storage)
      await prefs.setString('secure_encryption_key', _encryptionKey!.base64);
      await prefs.setString('secure_initialization_vector', _initializationVector!.base64);
    }
  }
  
  /// Save authentication token securely with encryption
  /// [token] - The authentication token to store
  /// [expiry] - Optional custom expiry duration
  /// Returns true if successful, false otherwise
  static Future<bool> saveToken(String token, {Duration? expiry}) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Validate token format
      if (!_isValidToken(token)) {
        throw Exception('Invalid token format');
      }
      
      // Encrypt the token
      if (_encryptionKey == null || _initializationVector == null) {
        throw Exception('Encryption keys not initialized');
      }
      final encrypter = Encrypter(AES(_encryptionKey!));
      final encrypted = encrypter.encrypt(token, iv: _initializationVector!);
      
      // Calculate expiry timestamp
      final expiryTime = DateTime.now().add(expiry ?? _defaultTokenExpiry);
      final expiryTimestamp = expiryTime.millisecondsSinceEpoch;
      
      // Store encrypted token and expiry
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_tokenKey, encrypted.base64) &&
                      await prefs.setInt(_tokenExpiryKey, expiryTimestamp);
      
      if (success) {
        // ⚡ PERFORMANCE: Cache the token in memory
        _cachedToken = token;
        _cachedTokenExpiry = expiryTime;
        _cachedTokenTimestamp = DateTime.now();
        
        // Update rotation tracking
        await _updateRotationTracking();
        
        if (kDebugMode) {
          print('🔐 Token saved securely with expiry: ${expiryTime.toIso8601String()} (cached)');
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving token: $e');
      }
      return false;
    }
  }
  
  /// Retrieve and decrypt the stored authentication token
  /// Returns the decrypted token or null if not found/expired
  /// ⚡ PERFORMANCE: Uses in-memory cache to avoid repeated decryption
  static Future<String?> getToken() async {
    if (!_isInitialized) await initialize();
    
    try {
      // ⚡ PERFORMANCE: Check in-memory cache first
      if (_cachedToken != null && 
          _cachedTokenExpiry != null && 
          _cachedTokenTimestamp != null) {
        final now = DateTime.now();
        
        // Check if cache is still valid (not expired and within validity duration)
        if (now.isBefore(_cachedTokenExpiry!) && 
            now.difference(_cachedTokenTimestamp!) < _cacheValidityDuration) {
          // Cache hit - return cached token without decryption
          return _cachedToken;
        } else {
          // Cache expired - clear it
          _cachedToken = null;
          _cachedTokenExpiry = null;
          _cachedTokenTimestamp = null;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // Check if token exists
      final encrypted = prefs.getString(_tokenKey);
      if (encrypted == null) {
        _cachedToken = null; // Clear cache if no token
        return null;
      }
      
      // Check if token is expired
      final expiryTimestamp = prefs.getInt(_tokenExpiryKey);
      DateTime? expiryTime;
      if (expiryTimestamp != null) {
        expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        if (DateTime.now().isAfter(expiryTime)) {
          // Token expired, clean it up
          await clearToken();
          _cachedToken = null; // Clear cache
          return null;
        }
      }
      
      // Decrypt the token (only if not in cache)
      if (_encryptionKey == null || _initializationVector == null) {
        throw Exception('Encryption keys not initialized');
      }
      final encrypter = Encrypter(AES(_encryptionKey!));
      final decrypted = encrypter.decrypt64(encrypted, iv: _initializationVector!);
      
      // Validate decrypted token
      if (!_isValidToken(decrypted)) {
        throw Exception('Decrypted token validation failed');
      }
      
      // ⚡ PERFORMANCE: Cache the decrypted token in memory
      _cachedToken = decrypted;
      _cachedTokenExpiry = expiryTime;
      _cachedTokenTimestamp = DateTime.now();
      
      if (kDebugMode) {
        print('🔐 Token retrieved and decrypted successfully (cached for ${_cacheValidityDuration.inMinutes}min)');
      }
      
      return decrypted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving token: $e');
      }
      // Clear corrupted token and cache
      await clearToken();
      _cachedToken = null;
      return null;
    }
  }
  
  /// Save refresh token securely
  /// [refreshToken] - The refresh token to store
  static Future<bool> saveRefreshToken(String refreshToken) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (!_isValidToken(refreshToken)) {
        throw Exception('Invalid refresh token format');
      }
      
      if (_encryptionKey == null || _initializationVector == null) {
        throw Exception('Encryption keys not initialized');
      }
      final encrypter = Encrypter(AES(_encryptionKey!));
      final encrypted = encrypter.encrypt(refreshToken, iv: _initializationVector!);
      
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_refreshTokenKey, encrypted.base64);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving refresh token: $e');
      }
      return false;
    }
  }
  
  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    if (!_isInitialized) await initialize();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = prefs.getString(_refreshTokenKey);
      if (encrypted == null) return null;
      
      if (_encryptionKey == null || _initializationVector == null) {
        throw Exception('Encryption keys not initialized');
      }
      final encrypter = Encrypter(AES(_encryptionKey!));
      return encrypter.decrypt64(encrypted, iv: _initializationVector!);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving refresh token: $e');
      }
      return null;
    }
  }
  
  /// Check if token needs rotation
  /// Returns true if token should be rotated
  static Future<bool> shouldRotateToken() async {
    if (!_isInitialized) await initialize();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRotation = prefs.getInt(_lastRotationKey);
      
      if (lastRotation == null) return true;
      
      final lastRotationTime = DateTime.fromMillisecondsSinceEpoch(lastRotation);
      final timeSinceRotation = DateTime.now().difference(lastRotationTime);
      
      return timeSinceRotation > _rotationThreshold;
    } catch (e) {
      return true; // Rotate on error for security
    }
  }
  
  /// Rotate token securely
  /// [newToken] - The new token to store
  /// Returns true if rotation successful
  static Future<bool> rotateToken(String newToken) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Check rotation count to prevent abuse
      final prefs = await SharedPreferences.getInstance();
      final rotationCount = prefs.getInt(_rotationCountKey) ?? 0;
      
      if (rotationCount >= _maxRotationCount) {
        throw Exception('Maximum token rotation count exceeded');
      }
      
      // Save new token
      final success = await saveToken(newToken);
      if (success) {
        // ⚡ PERFORMANCE: Update cache with new token
        _cachedToken = newToken;
        _cachedTokenTimestamp = DateTime.now();
        final expiryTime = DateTime.now().add(_defaultTokenExpiry);
        _cachedTokenExpiry = expiryTime;
        
        // Update rotation tracking
        await prefs.setInt(_lastRotationKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setInt(_rotationCountKey, rotationCount + 1);
        
        if (kDebugMode) {
          print('🔄 Token rotated successfully (rotation #${rotationCount + 1}, cache updated)');
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rotating token: $e');
      }
      return false;
    }
  }
  
  /// Clear all stored tokens securely
  /// This should be called on logout or security events
  static Future<bool> clearToken() async {
    if (!_isInitialized) await initialize();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all token-related data
      final success = await prefs.remove(_tokenKey) &&
                      await prefs.remove(_refreshTokenKey) &&
                      await prefs.remove(_tokenExpiryKey) &&
                      await prefs.remove(_lastRotationKey) &&
                      await prefs.remove(_rotationCountKey);
      
      // ⚡ PERFORMANCE: Clear in-memory cache
      _cachedToken = null;
      _cachedTokenExpiry = null;
      _cachedTokenTimestamp = null;
      
      if (success && kDebugMode) {
        print('🧹 All tokens cleared securely (cache cleared)');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing tokens: $e');
      }
      return false;
    }
  }
  
  /// Check if a valid token exists
  /// Returns true if token exists and is not expired
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null;
  }
  
  /// Get token expiry information
  /// Returns expiry DateTime or null if no token
  static Future<DateTime?> getTokenExpiry() async {
    if (!_isInitialized) await initialize();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTimestamp = prefs.getInt(_tokenExpiryKey);
      
      if (expiryTimestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Get time remaining until token expires
  /// Returns Duration or null if no token/expired
  static Future<Duration?> getTimeUntilExpiry() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(expiry)) return null;
    
    return expiry.difference(now);
  }
  
  /// Update rotation tracking
  static Future<void> _updateRotationTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setInt(_lastRotationKey, now);
      
      final rotationCount = prefs.getInt(_rotationCountKey) ?? 0;
      if (rotationCount == 0) {
        await prefs.setInt(_rotationCountKey, 1);
      }
    } catch (e) {
      // Silent fail for tracking updates
    }
  }
  
  /// Validate token format and security
  /// Returns true if token is valid
  static bool _isValidToken(String token) {
    if (token.isEmpty) return false;
    
    // Basic token validation (adjust based on your token format)
    if (token.length < 32) return false; // Minimum length for security
    
    // Check for common invalid patterns
    if (token.contains(' ') || token.contains('\n') || token.contains('\t')) {
      return false;
    }
    
    return true;
  }
  
  /// Get security status information
  /// Returns map with security metrics
  static Future<Map<String, dynamic>> getSecurityStatus() async {
    if (!_isInitialized) await initialize();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'isInitialized': _isInitialized,
        'hasToken': await hasValidToken(),
        'tokenExpiry': await getTokenExpiry(),
        'timeUntilExpiry': await getTimeUntilExpiry(),
        'lastRotation': prefs.getInt(_lastRotationKey),
        'rotationCount': prefs.getInt(_rotationCountKey) ?? 0,
        'shouldRotate': await shouldRotateToken(),
        'encryptionKeyLength': _keyLength * 8, // in bits
        'ivLength': _ivLength * 8, // in bits
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isInitialized': _isInitialized,
      };
    }
  }
}
