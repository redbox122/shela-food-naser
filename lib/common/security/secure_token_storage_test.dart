/*
 * Secure Token Storage Test File
 * 
 * This file provides basic testing functionality for the Secure Token Storage system.
 * It can be used to verify that the encryption and decryption are working correctly.
 * 
 * Note: This is for development/testing purposes only.
 */

import 'package:flutter/foundation.dart';
import 'secure_token_storage.dart';

/// Test class for Secure Token Storage functionality
class SecureTokenStorageTest {
  
  /// Run basic functionality tests
  static Future<void> runBasicTests() async {
    if (kDebugMode) {
      debugPrint('🧪 Starting Secure Token Storage Tests...');
    }
    
    try {
      // Test 1: Initialize the system
      await SecureTokenStorage.initialize();
      if (kDebugMode) {
        debugPrint('✅ Test 1 PASSED: Initialization successful');
      }
      
      // Test 2: Save a test token
      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final saveResult = await SecureTokenStorage.saveToken(testToken);
      
      if (saveResult) {
        if (kDebugMode) {
          debugPrint('✅ Test 2 PASSED: Token saved successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Test 2 FAILED: Token save failed');
        }
        return;
      }
      
      // Test 3: Retrieve the token
      final retrievedToken = await SecureTokenStorage.getToken();
      
      if (retrievedToken == testToken) {
        if (kDebugMode) {
          debugPrint('✅ Test 3 PASSED: Token retrieved and decrypted correctly');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Test 3 FAILED: Token retrieval failed');
          debugPrint('Expected: $testToken');
          debugPrint('Got: $retrievedToken');
        }
        return;
      }
      
      // Test 4: Check token validity
      final hasValidToken = await SecureTokenStorage.hasValidToken();
      
      if (hasValidToken) {
        if (kDebugMode) {
          debugPrint('✅ Test 4 PASSED: Token validation successful');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Test 4 FAILED: Token validation failed');
        }
        return;
      }
      
      // Test 5: Get security status
      final securityStatus = await SecureTokenStorage.getSecurityStatus();
      
      if (securityStatus['isInitialized'] == true && 
          securityStatus['hasToken'] == true) {
        if (kDebugMode) {
          debugPrint('✅ Test 5 PASSED: Security status check successful');
          debugPrint('🔐 Security Status: $securityStatus');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Test 5 FAILED: Security status check failed');
          debugPrint('Status: $securityStatus');
        }
        return;
      }
      
      // Test 6: Clear token
      final clearResult = await SecureTokenStorage.clearToken();
      
      if (clearResult) {
        if (kDebugMode) {
          debugPrint('✅ Test 6 PASSED: Token cleared successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Test 6 FAILED: Token clear failed');
        }
        return;
      }
      
      // Test 7: Verify token is cleared
      final tokenAfterClear = await SecureTokenStorage.getToken();
      
      if (tokenAfterClear == null) {
        if (kDebugMode) {
          debugPrint('✅ Test 7 PASSED: Token verification after clear successful');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Test 7 FAILED: Token still exists after clear');
          debugPrint('Token: $tokenAfterClear');
        }
        return;
      }
      
      if (kDebugMode) {
        debugPrint('🎉 ALL TESTS PASSED! Secure Token Storage is working correctly.');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Test FAILED with exception: $e');
      }
    }
  }
  
  /// Test token rotation functionality
  static Future<void> testTokenRotation() async {
    if (kDebugMode) {
      debugPrint('🔄 Testing Token Rotation...');
    }
    
    try {
      // Save initial token
      const initialToken = 'initial_test_token_123456789';
      await SecureTokenStorage.saveToken(initialToken);
      
      // Check if rotation is needed
      final shouldRotate = await SecureTokenStorage.shouldRotateToken();
      if (kDebugMode) {
        debugPrint('Should rotate token: $shouldRotate');
      }
      
      // Rotate token
      const newToken = 'new_test_token_987654321';
      final rotationResult = await SecureTokenStorage.rotateToken(newToken);
      
      if (rotationResult) {
        if (kDebugMode) {
          debugPrint('✅ Token rotation successful');
        }
        
        // Verify new token
        final retrievedToken = await SecureTokenStorage.getToken();
        if (retrievedToken == newToken) {
          if (kDebugMode) {
            debugPrint('✅ New token verified after rotation');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ New token verification failed after rotation');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Token rotation failed');
        }
      }
      
      // Clean up
      await SecureTokenStorage.clearToken();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Token rotation test failed: $e');
      }
    }
  }
  
  /// Test refresh token functionality
  static Future<void> testRefreshToken() async {
    if (kDebugMode) {
      debugPrint('🔄 Testing Refresh Token...');
    }
    
    try {
      // Save main token
      const mainToken = 'main_test_token_123456789';
      await SecureTokenStorage.saveToken(mainToken);
      
      // Save refresh token
      const refreshToken = 'refresh_test_token_987654321';
      final refreshSaveResult = await SecureTokenStorage.saveRefreshToken(refreshToken);
      
      if (refreshSaveResult) {
        if (kDebugMode) {
          debugPrint('✅ Refresh token saved successfully');
        }
        
        // Retrieve refresh token
        final retrievedRefreshToken = await SecureTokenStorage.getRefreshToken();
        if (retrievedRefreshToken == refreshToken) {
          if (kDebugMode) {
            debugPrint('✅ Refresh token retrieved successfully');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ Refresh token retrieval failed');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Refresh token save failed');
        }
      }
      
      // Clean up
      await SecureTokenStorage.clearToken();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Refresh token test failed: $e');
      }
    }
  }
  
  /// Run all tests
  static Future<void> runAllTests() async {
    if (kDebugMode) {
      debugPrint('🚀 Running All Secure Token Storage Tests...\n');
    }
    
    await runBasicTests();
    if (kDebugMode) {
      debugPrint('\n${'='*50}\n');
    }
    
    await testTokenRotation();
    if (kDebugMode) {
      debugPrint('\n${'='*50}\n');
    }
    
    await testRefreshToken();
    if (kDebugMode) {
      debugPrint('\n${'='*50}\n');
    }
    
    if (kDebugMode) {
      debugPrint('🎯 All test suites completed!');
    }
  }
}
