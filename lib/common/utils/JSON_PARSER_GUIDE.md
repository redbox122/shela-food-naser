# JSON Parser Utility Guide

This guide explains how to use the safe JSON parsing utility to fix null safety and type enforcement issues in Dart 3.

## Overview

The `JsonParser` utility provides type-safe methods to parse JSON data that may come in various formats (String, int, double, bool, null) and converts them safely to the expected types.

## Usage

### Extension Methods (Recommended)

Use extension methods on `Map<String, dynamic>` for cleaner code:

```dart
import 'package:sixam_mart/common/utils/json_parser.dart';

// In your fromJson method
factory MyModel.fromJson(Map<String, dynamic> json) {
  return MyModel(
    id: json.parseInt('id'),                    // int?
    name: json.parseString('name'),         // String?
    price: json.parseDouble('price'),        // double?
    isActive: json.parseBool('is_active'),   // bool
    createdAt: json.parseDateTime('created_at'), // DateTime?
  );
}
```

### Standalone Methods

Use standalone methods when you have a dynamic value:

```dart
import 'package:sixam_mart/common/utils/json_parser.dart';

final dynamic value = json['amount'];
final double? amount = JsonParser.parseDouble(value);
```

## Common Patterns and Fixes

### Pattern 1: Dynamic to String

**Before (Unsafe):**
```dart
name = json['name']?.toString();
```

**After (Safe):**
```dart
name = json.parseString('name');
```

### Pattern 2: Dynamic to int

**Before (Unsafe):**
```dart
id = json['id']?.toString();  // Wrong: id is int?, not String?
// or
id = int.parse(json['id'].toString());  // Crashes if null
```

**After (Safe):**
```dart
id = json.parseInt('id');
```

### Pattern 3: Dynamic to double

**Before (Unsafe):**
```dart
amount = json['amount'] != null
    ? double.tryParse(json['amount'].toString())
    : null;
// or
amount = json['amount']?.toDouble();  // Crashes if String
```

**After (Safe):**
```dart
amount = json.parseDouble('amount');
```

### Pattern 4: Dynamic to bool

**Before (Unsafe):**
```dart
isActive = json['is_active'] ?? false;  // Wrong if value is 0/1 or "true"/"false"
```

**After (Safe):**
```dart
isActive = json.parseBool('is_active');  // Handles 0/1, "true"/"false", etc.
```

### Pattern 5: FCM Notification Data

**Before (Unsafe):**
```dart
final orderId = int.parse(message.data['order_id']);  // Crashes if null or String
```

**After (Safe):**
```dart
final int? orderId = JsonParser.parseInt(message.data['order_id']);
if (orderId != null) {
  // Use orderId safely
}
```

### Pattern 6: Nested Maps

**Before (Unsafe):**
```dart
deliveryMan = json['delivery_man'] != null
    ? DeliveryMan.fromJson(json['delivery_man'])
    : null;
```

**After (Safe):**
```dart
final deliveryManMap = json.parseMap('delivery_man');
deliveryMan = deliveryManMap != null
    ? DeliveryMan.fromJson(deliveryManMap)
    : null;
```

### Pattern 7: Lists

**Before (Unsafe):**
```dart
if (json['items'] != null) {
  items = [];
  json['items'].forEach((v) {
    items!.add(Item.fromJson(v));
  });
}
```

**After (Safe):**
```dart
items = json.parseList<Item>('items', (v) => Item.fromJson(v as Map<String, dynamic>));
```

### Pattern 8: String Lists

**Before (Unsafe):**
```dart
if (json['tags'] != null) {
  tags = [];
  json['tags'].forEach((v) {
    if (v != null) {
      tags!.add(v.toString());
    }
  });
}
```

**After (Safe):**
```dart
tags = json.parseList<String>('tags', (v) => JsonParser.parseStringOrEmpty(v));
```

## Available Methods

### Extension Methods on Map<String, dynamic>

- `parseString(String key)` → `String?`
- `parseStringOrEmpty(String key)` → `String`
- `parseInt(String key)` → `int?`
- `parseIntOrZero(String key)` → `int`
- `parseDouble(String key)` → `double?`
- `parseDoubleOrZero(String key)` → `double`
- `parseBool(String key)` → `bool`
- `parseMap(String key)` → `Map<String, dynamic>?`
- `parseList<T>(String key, T Function(dynamic) parser)` → `List<T>?`
- `parseMapList(String key)` → `List<Map<String, dynamic>>`
- `parseDateTime(String key)` → `DateTime?`
- `getStringValue(String key)` → `String?` (for comparisons)
- `hasValue(String key)` → `bool`

### Standalone Methods on JsonParser

- `JsonParser.parseString(dynamic value)` → `String?`
- `JsonParser.parseStringOrEmpty(dynamic value)` → `String`
- `JsonParser.parseInt(dynamic value)` → `int?`
- `JsonParser.parseIntOrZero(dynamic value)` → `int`
- `JsonParser.parseDouble(dynamic value)` → `double?`
- `JsonParser.parseDoubleOrZero(dynamic value)` → `double`
- `JsonParser.parseBool(dynamic value)` → `bool`
- `JsonParser.parseMap(dynamic value)` → `Map<String, dynamic>?`
- `JsonParser.parseList<T>(dynamic value, T Function(dynamic) parser)` → `List<T>?`
- `JsonParser.parseDateTime(dynamic value)` → `DateTime?`
- `JsonParser.toStringValue(dynamic value)` → `String?`

## Type Handling

The parser handles these common backend inconsistencies:

1. **Numbers as Strings**: `"123"` → `123` (int) or `123.0` (double)
2. **Booleans as 0/1**: `0` → `false`, `1` → `true`
3. **Booleans as Strings**: `"true"` → `true`, `"false"` → `false`
4. **Mixed int/double**: `123` (int) → `123.0` (double)
5. **Null values**: Always returns `null` for nullable types, defaults for non-nullable

## Migration Checklist

When fixing a model file:

1. ✅ Import the utility: `import 'package:sixam_mart/common/utils/json_parser.dart';`
2. ✅ Replace `json['key']?.toString()` with `json.parseString('key')`
3. ✅ Replace `int.parse(json['key'].toString())` with `json.parseInt('key')`
4. ✅ Replace `double.tryParse(json['key'].toString())` with `json.parseDouble('key')`
5. ✅ Replace `json['key']?.toDouble()` with `json.parseDouble('key')`
6. ✅ Replace `json['key'] ?? false` (for bools) with `json.parseBool('key')`
7. ✅ Replace unsafe map/list parsing with `parseMap()` and `parseList()`
8. ✅ Remove excessive null checks and `!` operators
9. ✅ Test the model with various data formats

## Examples

### Complete Model Example

```dart
import 'package:sixam_mart/common/utils/json_parser.dart';

class ProductModel {
  final int? id;
  final String name;
  final double? price;
  final bool isActive;
  final DateTime? createdAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  ProductModel({
    this.id,
    required this.name,
    this.price,
    required this.isActive,
    this.createdAt,
    required this.tags,
    this.metadata,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json.parseInt('id'),
      name: json.parseStringOrEmpty('name'),
      price: json.parseDouble('price'),
      isActive: json.parseBool('is_active'),
      createdAt: json.parseDateTime('created_at'),
      tags: json.parseList<String>('tags', (v) => JsonParser.parseStringOrEmpty(v)) ?? [],
      metadata: json.parseMap('metadata'),
    );
  }
}
```

## Benefits

1. **Type Safety**: All conversions are type-safe and handle null values properly
2. **Consistency**: Same parsing logic across the entire codebase
3. **Error Prevention**: No more runtime crashes from invalid type conversions
4. **Maintainability**: Centralized parsing logic makes it easy to update behavior
5. **Backend Compatibility**: Handles inconsistent API data formats gracefully
