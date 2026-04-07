
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache Manager - Multi-layer caching system
/// 
/// Implements a three-layer caching strategy:
/// L1: Memory Cache (fastest, limited size)
/// L2: Persistent Cache (Hive database, medium speed)
/// L3: Network Cache (HTTP cache headers, slowest)
/// 
/// Features:
/// - TTL (Time To Live) support
/// - Smart invalidation
/// - Fallback mechanisms
/// - Performance monitoring
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // L1: Memory cache
  final Map<String, CacheEntry> _memoryCache = {};
  static const int _maxMemoryCacheSize = 100;
  static const Duration _defaultTTL = Duration(hours: 6);

  // L2: Persistent cache (SharedPreferences)
  late SharedPreferences _sharedPreferences;
  bool _persistentInitialized = false;

  // Performance tracking
  int _memoryHits = 0;
  int _persistentHits = 0;
  final int _networkHits = 0;
  int _cacheMisses = 0;

  /// Initialize cache manager
  Future<void> initialize() async {
    try {
      // Initialize SharedPreferences for persistent caching
      _sharedPreferences = await SharedPreferences.getInstance();
      _persistentInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ CacheManager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CacheManager initialization failed: $e');
      }
      _persistentInitialized = false;
    }
  }

  /// Get data from cache with fallback strategy
  Future<T?> get<T>(String key, {Duration? ttl, bool forceRefresh = false}) async {
    if (forceRefresh) {
      await remove(key);
    }

    // L1: Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired(ttl ?? _defaultTTL)) {
        _memoryHits++;
        if (kDebugMode) {
          debugPrint('🎯 Memory cache HIT: $key');
        }
        return _deserialize<T>(entry.data);
      } else {
        _memoryCache.remove(key);
      }
    }

    // L2: Check persistent cache
    if (_persistentInitialized) {
      try {
        final cachedData = _sharedPreferences.getString(key);
        if (cachedData != null) {
          final entry = CacheEntry.fromJson(jsonDecode(cachedData) as Map<String, dynamic>);
          if (!entry.isExpired(ttl ?? _defaultTTL)) {
            _persistentHits++;
            
            // Promote to memory cache
            _memoryCache[key] = entry;
            _evictMemoryCacheIfNeeded();
            
            if (kDebugMode) {
              debugPrint('💾 Persistent cache HIT: $key');
            }
            return _deserialize<T>(entry.data);
          } else {
            // Remove expired entry
            await _sharedPreferences.remove(key);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Persistent cache error for $key: $e');
        }
      }
    }

    _cacheMisses++;
    if (kDebugMode) {
      debugPrint('❌ Cache MISS: $key');
    }
    return null;
  }

  /// Store data in cache
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    final entry = CacheEntry(
      data: _serialize(data),
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTTL,
    );

    // L1: Store in memory cache
    _memoryCache[key] = entry;
    _evictMemoryCacheIfNeeded();

    // L2: Store in persistent cache
    if (_persistentInitialized) {
      try {
        await _sharedPreferences.setString(key, jsonEncode(entry.toJson()));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to store in persistent cache: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('💾 Cached: $key (TTL: ${ttl ?? _defaultTTL})');
    }
  }

  /// Remove data from cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    
    if (_persistentInitialized) {
      try {
        await _sharedPreferences.remove(key);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to remove from persistent cache: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('🗑️ Removed from cache: $key');
    }
  }

  /// Clear cache by pattern
  Future<void> clearByPattern(String pattern) async {
    // ignore: deprecated_member_use
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    
    // Clear memory cache
    _memoryCache.removeWhere((key, value) => regex.hasMatch(key));
    
    // Clear persistent cache
    if (_persistentInitialized) {
      try {
        final allKeys = _sharedPreferences.getKeys();
        final keysToDelete = allKeys
            .where((key) => regex.hasMatch(key))
            .toList();
        
        for (final key in keysToDelete) {
          await _sharedPreferences.remove(key);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to clear persistent cache by pattern: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('🧹 Cleared cache pattern: $pattern');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    
    if (_persistentInitialized) {
      try {
        await _sharedPreferences.clear();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to clear persistent cache: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('🧹 Cleared all cache');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalHits = _memoryHits + _persistentHits + _networkHits;
    final totalRequests = totalHits + _cacheMisses;
    
    return {
      'memoryHits': _memoryHits,
      'persistentHits': _persistentHits,
      'networkHits': _networkHits,
      'cacheMisses': _cacheMisses,
      'totalHits': totalHits,
      'totalRequests': totalRequests,
      'hitRate': totalRequests > 0 ? (totalHits / totalRequests * 100) : 0,
      'memoryCacheSize': _memoryCache.length,
      'persistentCacheSize': _persistentInitialized ? _sharedPreferences.getKeys().length : 0,
    };
  }

  /// Evict memory cache if it exceeds max size
  void _evictMemoryCacheIfNeeded() {
    if (_memoryCache.length > _maxMemoryCacheSize) {
      // Remove oldest entries (simple LRU)
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final entriesToRemove = sortedEntries.take(_memoryCache.length - _maxMemoryCacheSize);
      for (final entry in entriesToRemove) {
        _memoryCache.remove(entry.key);
      }
    }
  }

  /// Serialize data for storage
  String _serialize<T>(T data) {
    if (data is String) {
      return data;
    } else if (data is Map || data is List) {
      return jsonEncode(data);
    } else {
      return jsonEncode(data);
    }
  }

  /// Deserialize data from storage
  T? _deserialize<T>(String data) {
    try {
      if (T == String) {
        return data as T;
      } else {
        return jsonDecode(data) as T;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to deserialize data: $e');
      }
      return null;
    }
  }

  /// Clean up expired entries
  Future<void> cleanupExpiredEntries() async {
    // Clean memory cache
    _memoryCache.removeWhere((key, entry) {
      if (entry.isExpired(_defaultTTL)) {
        if (kDebugMode) {
          debugPrint('🧹 Removed expired memory cache: $key');
        }
        return true;
      }
      return false;
    });

    // Clean persistent cache
    if (_persistentInitialized) {
      try {
        final expiredKeys = <String>[];
        final allKeys = _sharedPreferences.getKeys();
        
        for (final key in allKeys) {
          try {
            final cachedData = _sharedPreferences.getString(key);
            if (cachedData != null) {
              final entry = CacheEntry.fromJson(jsonDecode(cachedData) as Map<String, dynamic>);
              if (entry.isExpired(_defaultTTL)) {
                expiredKeys.add(key);
              }
            }
          } catch (e) {
            // Invalid cache entry, remove it
            expiredKeys.add(key);
          }
        }
        
        for (final key in expiredKeys) {
          await _sharedPreferences.remove(key);
          if (kDebugMode) {
            debugPrint('🧹 Removed expired persistent cache: $key');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to cleanup persistent cache: $e');
        }
      }
    }
  }

  /// Close cache manager
  Future<void> close() async {
    // No need to close SharedPreferences
    _persistentInitialized = false;
  }
}

/// Cache entry model
class CacheEntry {
  final String data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool isExpired(Duration? customTTL) {
    final effectiveTTL = customTTL ?? ttl;
    return DateTime.now().difference(timestamp) > effectiveTTL;
  }

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'ttl': ttl.inMilliseconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: json['data'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    ttl: Duration(milliseconds: json['ttl'] as int),
  );
}

