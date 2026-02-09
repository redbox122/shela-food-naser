import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/local/cache_response.dart';

final database = AppDatabase();

/// Database Helper with write queue to prevent concurrent write operations
/// that cause database locking warnings
class DbHelper {
  // Queue to serialize database writes and prevent concurrent access
  static final Queue<Future<void> Function()> _writeQueue =
      Queue<Future<void> Function()>();
  static bool _isProcessingQueue = false;

  /// Insert or update cache response with queued writes to prevent database locking
  /// ⚡ PERFORMANCE: Batches database operations to prevent concurrent write conflicts
  static Future<void> insertOrUpdate(
      {required String id, required CacheResponseCompanion data}) async {
    assert(id.isNotEmpty);
    // Add operation to queue
    final completer = Completer<void>();
    _writeQueue.add(() async {
      try {
        await database.upsertCacheResponse(data);
        completer.complete();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ DbHelper: Database operation failed: $e');
        }
        completer.completeError(e);
      }
    });

    // Process queue if not already processing
    _processQueue();

    return completer.future;
  }

  /// Process write queue sequentially to prevent database locking
  static Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_writeQueue.isNotEmpty) {
        final operation = _writeQueue.removeFirst();
        try {
          await operation();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ DbHelper: Queue operation failed: $e');
          }
        }
        // Small delay to prevent overwhelming the database
        await Future.delayed(const Duration(milliseconds: 10));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Clear the write queue (useful for testing or cleanup)
  static void clearQueue() {
    _writeQueue.clear();
  }

  /// ⚡ Delete all cache entries matching a prefix pattern
  /// Used to clear stale pagination cache when loading fresh data
  /// Example: clearCacheByPrefix('category_items_8_') clears all pages for category 8
  static Future<int> clearCacheByPrefix(String prefix) async {
    try {
      final count = await database.deleteCacheByPrefix(prefix);
      if (kDebugMode) {
        print(
            '🗑️ DbHelper: Cleared $count cache entries with prefix: $prefix');
      }
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ DbHelper: Failed to clear cache by prefix: $e');
      }
      return 0;
    }
  }
}
