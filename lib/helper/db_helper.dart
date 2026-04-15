import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based cache helper — replaces the previous drift/SQLite implementation.
/// Uses a simple Box<String> keyed by endpoint URL.
class DbHelper {
  static const String _boxName = 'api_cache';
  static Box<String>? _box;
  static final Queue<Future<void> Function()> _writeQueue = Queue();
  static bool _isProcessingQueue = false;

  /// Opens (or returns the already-open) Hive box.
  static Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Insert or update a cache entry. Writes are serialised through a queue
  /// to prevent concurrent write conflicts (same guarantee as before).
  static Future<void> insertOrUpdate({
    required String id,
    required String data,
  }) async {
    assert(id.isNotEmpty);
    final completer = Completer<void>();
    _writeQueue.add(() async {
      try {
        final box = await _getBox();
        await box.put(id, data);
        completer.complete();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ DbHelper: Write failed: $e');
        }
        completer.completeError(e);
      }
    });
    _processQueue();
    return completer.future;
  }

  /// Retrieve a cached response by endpoint id. Returns null on miss or error.
  static Future<String?> getCacheById(String id) async {
    try {
      final box = await _getBox();
      return box.get(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ DbHelper: Read failed: $e');
      }
      return null;
    }
  }

  /// Process the write queue sequentially.
  static Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    try {
      while (_writeQueue.isNotEmpty) {
        final op = _writeQueue.removeFirst();
        try {
          await op();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ DbHelper: Queue operation failed: $e');
          }
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Clear the write queue (useful for testing or cleanup).
  static void clearQueue() => _writeQueue.clear();

  /// Delete all cache entries whose key starts with [prefix].
  static Future<int> clearCacheByPrefix(String prefix) async {
    try {
      final box = await _getBox();
      final keysToDelete =
          box.keys.where((k) => k.toString().startsWith(prefix)).toList();
      await box.deleteAll(keysToDelete);
      if (kDebugMode) {
        debugPrint(
            '🗑️ DbHelper: Cleared ${keysToDelete.length} cache entries with prefix: $prefix');
      }
      return keysToDelete.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ DbHelper: Failed to clear cache by prefix: $e');
      }
      return 0;
    }
  }
}
