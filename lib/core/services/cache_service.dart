import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/core/errors/failures.dart';

/// Cache entry metadata
class CacheEntry {
  final String key;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? etag;
  final int size;

  const CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    this.expiresAt,
    this.etag,
    required this.size,
  });

  /// Check if cache entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if cache entry is valid (not expired)
  bool get isValid => !isExpired;

  /// Age of cache entry in seconds
  int get ageInSeconds => DateTime.now().difference(createdAt).inSeconds;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'etag': etag,
      'size': size,
    };
  }

  /// Create from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      etag: json['etag'] as String?,
      size: json['size'] as int,
    );
  }

  @override
  String toString() {
    return 'CacheEntry(key: $key, size: $size, age: ${ageInSeconds}s, expired: $isExpired)';
  }
}

/// Cache configuration
class CacheConfig {
  final Duration defaultTtl;
  final int maxSizeBytes;
  final int maxEntries;
  final bool enableCompression;
  final bool enableEncryption;

  const CacheConfig({
    this.defaultTtl = const Duration(hours: 1),
    this.maxSizeBytes = 50 * 1024 * 1024, // 50MB
    this.maxEntries = 1000,
    this.enableCompression = true,
    this.enableEncryption = false,
  });
}

/// Local JSON cache service for API responses
/// Provides persistent caching with TTL, size management, and offline support
class CacheService {
  final CacheConfig _config;
  late final Directory _cacheDir;
  final Map<String, CacheEntry> _memoryCache = {};
  bool _initialized = false;

  // Cache statistics
  int _hitCount = 0;
  int _missCount = 0;
  int _totalSize = 0;

  CacheService({
    CacheConfig? config,
  }) : _config = config ?? const CacheConfig();

  /// Initialize cache service
  Future<Result<void>> initialize() async {
    try {
      if (_initialized) return const Result.success(null);

      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/cache');
      
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      // Load existing cache entries into memory
      await _loadCacheIndex();
      
      // Clean up expired entries
      await _cleanupExpiredEntries();
      
      _initialized = true;
      
      if (kDebugMode) {
        debugPrint('CacheService: Initialized with ${_memoryCache.length} entries');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CacheService: Initialization failed: $error');
      }
      return Result.failure(
        CacheFailure.corruptedData(),
      );
    }
  }

  /// Store data in cache
  Future<Result<void>> put(
    String key, 
    Map<String, dynamic> data, {
    Duration? ttl,
    String? etag,
  }) async {
    try {
      if (!_initialized) {
        final initResult = await initialize();
        if (initResult.isFailure) return initResult;
      }

      final now = DateTime.now();
      final expiresAt = ttl != null ? now.add(ttl) : now.add(_config.defaultTtl);
      final jsonString = jsonEncode(data);
      final size = utf8.encode(jsonString).length;

      // Check size limits
      if (size > _config.maxSizeBytes ~/ 10) {
        return Result.failure(
          CacheFailure.sizeLimitExceeded(),
        );
      }

      // Create cache entry
      final entry = CacheEntry(
        key: key,
        data: data,
        createdAt: now,
        expiresAt: expiresAt,
        etag: etag,
        size: size,
      );

      // Check if we need to make space
      await _ensureSpace(size);

      // Store to disk
      final file = File('${_cacheDir.path}/${_sanitizeKey(key)}.json');
      await file.writeAsString(jsonEncode(entry.toJson()));

      // Update memory cache
      _memoryCache[key] = entry;
      _totalSize += size;

      if (kDebugMode) {
        debugPrint('CacheService: Stored $key ($size bytes, expires: $expiresAt)');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CacheService: Failed to store $key: $error');
      }
      return Result.failure(
        CacheFailure.corruptedData(),
      );
    }
  }

  /// Get data from cache
  Future<Result<Map<String, dynamic>?>> get(String key) async {
    try {
      if (!_initialized) {
        final initResult = await initialize();
        if (initResult.isFailure) return Result.failure(initResult.failureOrNull!);
      }

      // Check memory cache first
      final entry = _memoryCache[key];
      if (entry == null) {
        _missCount++;
        return const Result.success(null);
      }

      // Check if expired
      if (entry.isExpired) {
        await _removeEntry(key);
        _missCount++;
        return Result.failure(CacheFailure.expired(key));
      }

      _hitCount++;
      
      if (kDebugMode) {
        debugPrint('CacheService: Cache hit for $key (age: ${entry.ageInSeconds}s)');
      }

      return Result.success(entry.data);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CacheService: Failed to get $key: $error');
      }
      _missCount++;
      return Result.failure(
        CacheFailure.corruptedData(),
      );
    }
  }

  /// Check if key exists in cache and is valid
  Future<bool> contains(String key) async {
    if (!_initialized) {
      final initResult = await initialize();
      if (initResult.isFailure) return false;
    }

    final entry = _memoryCache[key];
    return entry != null && entry.isValid;
  }

  /// Remove entry from cache
  Future<Result<void>> remove(String key) async {
    try {
      if (!_initialized) {
        final initResult = await initialize();
        if (initResult.isFailure) return initResult;
      }

      await _removeEntry(key);
      return const Result.success(null);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CacheService: Failed to remove $key: $error');
      }
      return Result.failure(
        CacheFailure.corruptedData(),
      );
    }
  }

  /// Clear all cache entries
  Future<Result<void>> clear() async {
    try {
      if (!_initialized) {
        final initResult = await initialize();
        if (initResult.isFailure) return initResult;
      }

      // Remove all files
      final files = await _cacheDir.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          await file.delete();
        }
      }

      // Clear memory cache
      _memoryCache.clear();
      _totalSize = 0;

      if (kDebugMode) {
        debugPrint('CacheService: Cleared all cache entries');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CacheService: Failed to clear cache: $error');
      }
      return Result.failure(
        CacheFailure.corruptedData(),
      );
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalRequests = _hitCount + _missCount;
    final hitRate = totalRequests > 0 ? _hitCount / totalRequests : 0.0;

    return {
      'entries': _memoryCache.length,
      'totalSize': _totalSize,
      'hitCount': _hitCount,
      'missCount': _missCount,
      'hitRate': hitRate,
      'maxSize': _config.maxSizeBytes,
      'maxEntries': _config.maxEntries,
    };
  }

  /// Load cache index from disk
  Future<void> _loadCacheIndex() async {
    try {
      final files = await _cacheDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            final entry = CacheEntry.fromJson(json);
            
            if (entry.isValid) {
              _memoryCache[entry.key] = entry;
              _totalSize += entry.size;
            } else {
              // Remove expired file
              await file.delete();
            }
          } catch (e) {
            // Remove corrupted file
            await file.delete();
            if (kDebugMode) {
              debugPrint('CacheService: Removed corrupted cache file: ${file.path}');
            }
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CacheService: Failed to load cache index: $error');
      }
    }
  }

  /// Clean up expired entries
  Future<void> _cleanupExpiredEntries() async {
    final expiredKeys = <String>[];
    
    for (final entry in _memoryCache.values) {
      if (entry.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await _removeEntry(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('CacheService: Cleaned up ${expiredKeys.length} expired entries');
    }
  }

  /// Ensure there's enough space for new entry
  Future<void> _ensureSpace(int newEntrySize) async {
    // Check total size limit
    while (_totalSize + newEntrySize > _config.maxSizeBytes) {
      await _evictOldestEntry();
    }

    // Check entry count limit
    while (_memoryCache.length >= _config.maxEntries) {
      await _evictOldestEntry();
    }
  }

  /// Evict oldest entry (LRU)
  Future<void> _evictOldestEntry() async {
    if (_memoryCache.isEmpty) return;

    // Find oldest entry
    CacheEntry? oldestEntry;
    String? oldestKey;

    for (final entry in _memoryCache.entries) {
      if (oldestEntry == null || entry.value.createdAt.isBefore(oldestEntry.createdAt)) {
        oldestEntry = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      await _removeEntry(oldestKey);
      if (kDebugMode) {
        debugPrint('CacheService: Evicted oldest entry: $oldestKey');
      }
    }
  }

  /// Remove entry from both memory and disk
  Future<void> _removeEntry(String key) async {
    final entry = _memoryCache[key];
    if (entry != null) {
      _totalSize -= entry.size;
      _memoryCache.remove(key);
    }

    final file = File('${_cacheDir.path}/${_sanitizeKey(key)}.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Sanitize key for filename
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w\-_.]'), '_');
  }

  /// Dispose resources
  void dispose() {
    _memoryCache.clear();
    _totalSize = 0;
    _initialized = false;
  }
}