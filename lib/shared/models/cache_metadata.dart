/// Cache metadata for tracking cache state
class CacheMetadata {
  final DateTime lastUpdated;
  final int itemCount;
  final int sizeInBytes;
  final String? dataType;
  final String version;
  final Map<String, dynamic> additionalData;

  const CacheMetadata({
    required this.lastUpdated,
    required this.itemCount,
    this.sizeInBytes = 0,
    this.dataType,
    this.version = '1.0',
    this.additionalData = const {},
  });

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      itemCount: json['itemCount'] as int,
      sizeInBytes: json['sizeInBytes'] as int? ?? 0,
      dataType: json['dataType'] as String?,
      version: json['version'] as String? ?? '1.0',
      additionalData: json['additionalData'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated.toIso8601String(),
      'itemCount': itemCount,
      'sizeInBytes': sizeInBytes,
      if (dataType != null) 'dataType': dataType,
      'version': version,
      'additionalData': additionalData,
    };
  }

  CacheMetadata copyWith({
    DateTime? lastUpdated,
    int? itemCount,
    int? sizeInBytes,
    String? dataType,
    String? version,
    Map<String, dynamic>? additionalData,
  }) {
    return CacheMetadata(
      lastUpdated: lastUpdated ?? this.lastUpdated,
      itemCount: itemCount ?? this.itemCount,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      dataType: dataType ?? this.dataType,
      version: version ?? this.version,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  bool isExpired({Duration maxAge = const Duration(hours: 6)}) {
    return DateTime.now().difference(lastUpdated) > maxAge;
  }

  @override
  String toString() {
    return 'CacheMetadata(lastUpdated: $lastUpdated, itemCount: $itemCount, '
        'sizeInBytes: $sizeInBytes, dataType: $dataType, version: $version, '
        'expired: ${isExpired()})';
  }
}

/// Cache status information
class CacheStatus {
  final DateTime? lastUpdated;
  final int itemCount;
  final bool isExpired;
  final Duration? age;

  const CacheStatus({
    this.lastUpdated,
    required this.itemCount,
    required this.isExpired,
    this.age,
  });

  bool get hasData => itemCount > 0;
  bool get isValid => hasData && !isExpired;

  @override
  String toString() {
    return 'CacheStatus(lastUpdated: $lastUpdated, itemCount: $itemCount, '
        'isExpired: $isExpired, age: $age)';
  }
}

