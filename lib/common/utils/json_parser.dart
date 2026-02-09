/// Safe JSON parsing utility for handling dynamic API responses
/// 
/// This utility provides type-safe methods to parse JSON data that may come
/// in various formats (String, int, double, bool, null) and converts them
/// safely to the expected types.
library;

/// Extension methods for safe JSON parsing
extension SafeJsonParser on Map<String, dynamic> {
  /// Safely parse a String value from JSON
  /// 
  /// Handles cases where the value might be:
  /// - Already a String
  /// - A number (int/double) that needs conversion
  /// - null
  /// 
  /// Returns null if the value cannot be converted to String
  String? parseString(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  /// Safely parse a non-nullable String value from JSON
  /// 
  /// Returns empty string if value is null or cannot be converted
  String parseStringOrEmpty(String key) {
    return parseString(key) ?? '';
  }

  /// Safely parse an int value from JSON
  /// 
  /// Handles cases where the value might be:
  /// - Already an int
  /// - A String representation of a number
  /// - A double (truncated to int)
  /// - null
  /// 
  /// Returns null if the value cannot be converted to int
  int? parseInt(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  /// Safely parse a non-nullable int value from JSON
  /// 
  /// Returns 0 if value is null or cannot be converted
  int parseIntOrZero(String key) {
    return parseInt(key) ?? 0;
  }

  /// Safely parse a double value from JSON
  /// 
  /// Handles cases where the value might be:
  /// - Already a double
  /// - An int (converted to double)
  /// - A String representation of a number
  /// - null
  /// 
  /// Returns null if the value cannot be converted to double
  double? parseDouble(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return null;
  }

  /// Safely parse a non-nullable double value from JSON
  /// 
  /// Returns 0.0 if value is null or cannot be converted
  double parseDoubleOrZero(String key) {
    return parseDouble(key) ?? 0.0;
  }

  /// Safely parse a bool value from JSON
  /// 
  /// Handles cases where the value might be:
  /// - Already a bool
  /// - An int (0 = false, 1 = true, or any non-zero = true)
  /// - A String ("true"/"false", "1"/"0", "yes"/"no")
  /// - null (returns false)
  /// 
  /// Returns false if the value cannot be converted to bool
  bool parseBool(String key) {
    final value = this[key];
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == 'true' || trimmed == '1' || trimmed == 'yes') {
        return true;
      }
      if (trimmed == 'false' || trimmed == '0' || trimmed == 'no') {
        return false;
      }
    }
    return false;
  }

  /// Safely parse a Map<String, dynamic> value from JSON
  /// 
  /// Returns null if the value is not a Map
  Map<String, dynamic>? parseMap(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  /// Safely parse a List<T> value from JSON
  /// 
  /// Returns null if the value is not a List
  List<T>? parseList<T>(String key, T Function(dynamic) parser) {
    final value = this[key];
    if (value == null) return null;
    if (value is List) {
      try {
        return value.map((item) => parser(item)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Safely parse a List<Map<String, dynamic>> value from JSON
  /// 
  /// Returns empty list if the value is not a List
  List<Map<String, dynamic>> parseMapList(String key) {
    final value = this[key];
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    return [];
  }

  /// Safely parse a DateTime value from JSON
  /// 
  /// Handles ISO 8601 strings and Unix timestamps (int/double)
  /// Returns null if the value cannot be converted to DateTime
  DateTime? parseDateTime(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Assume milliseconds if > 1e10, otherwise seconds
      if (value > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      final timestamp = value.toInt();
      if (timestamp > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      // Try ISO 8601 format first
      try {
        return DateTime.parse(trimmed);
      } catch (_) {
        // Try Unix timestamp as string
        final timestamp = int.tryParse(trimmed);
        if (timestamp != null) {
          if (timestamp > 10000000000) {
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
    }
    return null;
  }

  /// Safely get a value and convert it to String for comparison
  /// 
  /// Useful for comparing dynamic values with strings
  String? getStringValue(String key) {
    final value = this[key];
    if (value == null) return null;
    return value.toString();
  }

  /// Check if a key exists and has a non-null, non-empty value
  bool hasValue(String key) {
    final value = this[key];
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}

/// Standalone utility class for JSON parsing
/// 
/// Use this when you don't have a Map<String, dynamic> to extend
class JsonParser {
  /// Safely parse a String value from dynamic
  static String? parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  /// Safely parse a non-nullable String value from dynamic
  static String parseStringOrEmpty(dynamic value) {
    return parseString(value) ?? '';
  }

  /// Safely parse an int value from dynamic
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  /// Safely parse a non-nullable int value from dynamic
  static int parseIntOrZero(dynamic value) {
    return parseInt(value) ?? 0;
  }

  /// Safely parse a double value from dynamic
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return null;
  }

  /// Safely parse a non-nullable double value from dynamic
  static double parseDoubleOrZero(dynamic value) {
    return parseDouble(value) ?? 0.0;
  }

  /// Safely parse a bool value from dynamic
  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == 'true' || trimmed == '1' || trimmed == 'yes') {
        return true;
      }
      if (trimmed == 'false' || trimmed == '0' || trimmed == 'no') {
        return false;
      }
    }
    return false;
  }

  /// Safely parse a Map<String, dynamic> value from dynamic
  static Map<String, dynamic>? parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  /// Safely parse a List<T> value from dynamic
  static List<T>? parseList<T>(
    dynamic value,
    T Function(dynamic) parser,
  ) {
    if (value == null) return null;
    if (value is List) {
      try {
        return value.map((item) => parser(item)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Safely parse a DateTime value from dynamic
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      final timestamp = value.toInt();
      if (timestamp > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        return DateTime.parse(trimmed);
      } catch (_) {
        final timestamp = int.tryParse(trimmed);
        if (timestamp != null) {
          if (timestamp > 10000000000) {
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
    }
    return null;
  }

  /// Convert dynamic value to String for comparison
  static String? toStringValue(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}
