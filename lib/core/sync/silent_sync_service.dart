import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

/// Silent Sync Service
/// 
/// ⚡ BFF API v2: Implements version_hash based cache invalidation
/// 
/// How it works:
/// 1. Store `version_hash` locally when fetching store data
/// 2. Compare local hash with server hash periodically
/// 3. If hash changed → pricing data changed → invalidate cache
/// 4. Refresh store data in background without user interruption
/// 
/// When hash changes:
/// - minimum_order changed
/// - per_km_shipping_charge changed
/// - tax changed
/// - Any pricing field changed
/// 
/// When hash stays same:
/// - name changed (non-pricing)
/// - logo changed (non-pricing)
/// - description changed (non-pricing)
class SilentSyncService {
  static const String _hashPrefix = 'store_version_hash_';
  static const Duration _syncInterval = Duration(minutes: 5);
  
  static Timer? _syncTimer;
  static final Set<int> _cachedStoreIds = {};

  /// Start periodic sync for all cached stores
  static void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      syncAllStoreHashes();
    });
    
    if (kDebugMode) {
      debugPrint('🔄 SilentSyncService: Started periodic sync (every ${_syncInterval.inMinutes} minutes)');
    }
  }

  /// Stop periodic sync
  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    
    if (kDebugMode) {
      debugPrint('🛑 SilentSyncService: Stopped periodic sync');
    }
  }

  /// Save store version hash locally
  static Future<void> saveStoreHash(int storeId, String? versionHash) async {
    if (versionHash == null || versionHash.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_hashPrefix$storeId', versionHash);
      _cachedStoreIds.add(storeId);
      
      if (kDebugMode) {
        debugPrint('💾 SilentSyncService: Saved hash for store $storeId: ${versionHash.safeSubstring(10)}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SilentSyncService: Error saving hash: $e');
      }
    }
  }

  /// Get stored version hash for a store
  static Future<String?> getStoredHash(int storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_hashPrefix$storeId');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SilentSyncService: Error getting stored hash: $e');
      }
      return null;
    }
  }

  /// Delete stored hash for a store
  static Future<void> deleteStoreHash(int storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_hashPrefix$storeId');
      _cachedStoreIds.remove(storeId);
      
      if (kDebugMode) {
        debugPrint('🗑️ SilentSyncService: Deleted hash for store $storeId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SilentSyncService: Error deleting hash: $e');
      }
    }
  }

  /// Check if store pricing has changed by comparing hashes
  /// 
  /// Returns true if hash changed (pricing updated)
  /// Returns false if hash is same (no pricing changes)
  static Future<bool> hasStorePricingChanged(int storeId, String? currentHash) async {
    if (currentHash == null || currentHash.isEmpty) return false;
    
    final storedHash = await getStoredHash(storeId);
    if (storedHash == null) {
      // No stored hash - save current and return false (first time)
      await saveStoreHash(storeId, currentHash);
      return false;
    }
    
    final hasChanged = storedHash != currentHash;
    
    if (hasChanged && kDebugMode) {
      appLogger.warning('⚠️ SilentSyncService: Store $storeId pricing changed!');
      appLogger.debug('   Old hash: ${storedHash.safeSubstring(10)}');
      appLogger.debug('   New hash: ${currentHash.safeSubstring(10)}');
    }
    
    return hasChanged;
  }

  /// Sync all cached store hashes
  /// 
  /// Called periodically and on app foreground
  static Future<void> syncAllStoreHashes() async {
    if (_cachedStoreIds.isEmpty) {
      if (kDebugMode) {
        debugPrint('🔄 SilentSyncService: No cached stores to sync');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('🔄 SilentSyncService: Syncing ${_cachedStoreIds.length} store hashes...');
    }
    
    final changedStoreIds = <int>[];
    
    for (final storeId in _cachedStoreIds) {
      try {
        final currentHash = await fetchStoreHash(storeId);
        if (currentHash != null) {
          final hasChanged = await hasStorePricingChanged(storeId, currentHash);
          if (hasChanged) {
            changedStoreIds.add(storeId);
            // Update stored hash
            await saveStoreHash(storeId, currentHash);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ SilentSyncService: Error syncing store $storeId: $e');
        }
      }
    }
    
    if (changedStoreIds.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ SilentSyncService: ${changedStoreIds.length} stores have pricing changes');
      }
      // Notify listeners about pricing changes
      _notifyPricingChanges(changedStoreIds);
    } else {
      if (kDebugMode) {
        debugPrint('✅ SilentSyncService: All store prices are up to date');
      }
    }
  }

  /// Fetch current version hash from server
  /// 
  /// Note: This endpoint may not be available yet - falls back to store details
  static Future<String?> fetchStoreHash(int storeId) async {
    try {
      final apiClient = Get.find<ApiClient>();
      
      // Try lightweight hash endpoint first (future)
      // final response = await apiClient.getData(
      //   '/api/v2/stores/$storeId/hash',
      //   handleError: false,
      // );
      
      // Fallback: Get hash from store details
      final response = await apiClient.getData(
        '${AppConstants.storeDetailsUri}$storeId',
        handleError: false,
      );
      
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;
        if (data is Map<String, dynamic>) {
          return data['version_hash'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SilentSyncService: Error fetching hash for store $storeId: $e');
      }
      return null;
    }
  }

  /// Notify listeners about pricing changes
  static void _notifyPricingChanges(List<int> storeIds) {
    // This can be expanded to show inline banner, update UI, etc.
    if (kDebugMode) {
      debugPrint('📢 SilentSyncService: Pricing changed for stores: $storeIds');
    }
    
    // Note: Implement notification mechanism
    // - Show subtle inline banner on cart/checkout
    // - Refresh store data in background
    // - Update cart totals if affected
  }

  /// Validate store data before checkout
  /// 
  /// CRITICAL: Call this before payment to ensure prices are current
  static Future<bool> validateStoreForCheckout(Store store) async {
    if (store.id == null) return true;
    
    try {
      final currentHash = await fetchStoreHash(store.id!);
      if (currentHash == null) return true; // Can't validate, proceed
      
      final hasChanged = await hasStorePricingChanged(store.id!, currentHash);
      
      if (hasChanged) {
        if (kDebugMode) {
          debugPrint('⚠️ SilentSyncService: Store ${store.id} pricing changed before checkout!');
        }
        // Update stored hash
        await saveStoreHash(store.id!, currentHash);
        return false; // Pricing changed - caller should refresh
      }
      
      return true; // Pricing is current
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ SilentSyncService: Error validating store for checkout: $e');
      }
      return true; // Error - proceed anyway
    }
  }

  /// Clear all stored hashes
  static Future<void> clearAllHashes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_hashPrefix)) {
          await prefs.remove(key);
        }
      }
      
      _cachedStoreIds.clear();
      
      if (kDebugMode) {
        debugPrint('🗑️ SilentSyncService: Cleared all stored hashes');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SilentSyncService: Error clearing hashes: $e');
      }
    }
  }
}

