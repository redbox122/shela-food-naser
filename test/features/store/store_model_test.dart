import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

void main() {
  group('Store.fromJson Type-Stress Tests', () {
    test('should map moduleId from camelCase key when module_id is missing',
        () {
      final json = {
        'id': 1,
        'name': 'Test Store',
        'moduleId': 6,
      };

      final store = Store.fromJson(json);

      expect(store.moduleId, equals(6));
    });

    test(
        'should use is_open only and mirror it to isOpenNow compatibility field',
        () {
      final json = {
        'id': 1,
        'name': 'Test Store',
        'is_open': true,
      };

      final store = Store.fromJson(json);

      expect(store.isOpen, isTrue);
      expect(store.isOpenNow, isTrue);
    });

    test('should prioritize direct logo and cover_photo URLs from API', () {
      final json = {
        'id': 1,
        'name': 'Test Store',
        'logo': 'https://cdn.example.com/logo.png',
        'logo_full_url': 'https://old.example.com/logo.png',
        'cover_photo': 'https://cdn.example.com/cover.png',
        'cover_photo_full_url': 'https://old.example.com/cover.png',
      };

      final store = Store.fromJson(json);

      expect(store.logoFullUrl, equals('https://cdn.example.com/logo.png'));
      expect(
          store.coverPhotoFullUrl, equals('https://cdn.example.com/cover.png'));
    });

    test('should convert active: 1 (int) to true (bool)', () {
      // Arrange: Create JSON with active as int
      final json = {
        'id': 1,
        'name': 'Test Store',
        'active': 1, // int instead of bool
      };

      // Act: Parse JSON
      final store = Store.fromJson(json);

      // Assert: active should be true
      expect(store.active, isTrue);
    });

    test('should convert minimum_order: "15.00" (string) to 15.0 (double)', () {
      // Arrange: Create JSON with minimum_order as string
      final json = {
        'id': 1,
        'name': 'Test Store',
        'minimum_order': '15.00', // string instead of double
      };

      // Act: Parse JSON - should not throw
      final store = Store.fromJson(json);

      // Assert: minimumOrder should be 15.0 (double)
      expect(store.minimumOrder, equals(15.0));
      expect(store.minimumOrder, isA<double>());
    });

    test('should handle latitude: null without crashing', () {
      // Arrange: Create JSON with latitude as null
      final json = {
        'id': 1,
        'name': 'Test Store',
        'latitude': null, // null value
      };

      // Act & Assert: Should not throw exception
      final store = Store.fromJson(json);

      // Assert: latitude should be null or empty string
      expect(store.latitude, isNull);
    });

    test('should handle missing active field gracefully', () {
      // Arrange: Create JSON without active field
      final json = {
        'id': 1,
        'name': 'Test Store',
        // active field is missing
      };

      // Act & Assert: Should not throw exception
      final store = Store.fromJson(json);

      // Assert: active should default to false
      expect(store.active, isFalse);
    });

    test('should handle active as string "1" and convert to true', () {
      // Arrange: Create JSON with active as string "1"
      final json = {
        'id': 1,
        'name': 'Test Store',
        'active': '1', // string "1"
      };

      // Act: Parse JSON
      final store = Store.fromJson(json);

      // Assert: active should be true
      expect(store.active, isTrue);
    });

    test('should handle active as string "true" and convert to true', () {
      // Arrange: Create JSON with active as string "true"
      final json = {
        'id': 1,
        'name': 'Test Store',
        'active': 'true', // string "true"
      };

      // Act: Parse JSON
      final store = Store.fromJson(json);

      // Assert: active should be true
      expect(store.active, isTrue);
    });

    test('should handle minimum_order as invalid string and default to 0.0',
        () {
      // Arrange: Create JSON with invalid minimum_order string
      final json = {
        'id': 1,
        'name': 'Test Store',
        'minimum_order': 'invalid', // cannot parse to double
      };

      // Act: Parse JSON
      final store = Store.fromJson(json);

      // Assert: minimumOrder should default to 0.0 when parsing fails
      expect(store.minimumOrder, equals(0.0));
    });

    test('should handle minimum_order as double and keep as double', () {
      // Arrange: Create JSON with minimum_order as double
      final json = {
        'id': 1,
        'name': 'Test Store',
        'minimum_order': 20.5, // double
      };

      // Act: Parse JSON
      final store = Store.fromJson(json);

      // Assert: minimumOrder should be 20.5
      expect(store.minimumOrder, equals(20.5));
    });

    test('should handle latitude as double and convert to string', () {
      // Arrange: Create JSON with latitude as double
      final json = {
        'id': 1,
        'name': 'Test Store',
        'latitude': 25.2048, // double
      };

      // Act: Parse JSON
      final store = Store.fromJson(json);

      // Assert: latitude should be converted to string
      expect(store.latitude, equals('25.2048'));
      expect(store.latitude, isA<String>());
    });

    test('should handle longitude as null without crashing', () {
      // Arrange: Create JSON with longitude as null
      final json = {
        'id': 1,
        'name': 'Test Store',
        'longitude': null, // null value
      };

      // Act & Assert: Should not throw exception
      final store = Store.fromJson(json);

      // Assert: longitude should be null
      expect(store.longitude, isNull);
    });

    test('should handle empty string for minimum_order and default to 0.0', () {
      // Arrange: Create JSON with empty string for minimum_order
      final json = {
        'id': 1,
        'name': 'Test Store',
        'minimum_order': '', // empty string
      };

      // Act: Parse JSON
      final store = Store.fromJson(json);

      // Assert: minimumOrder should default to 0.0
      expect(store.minimumOrder, equals(0.0));
    });

    test('should handle all dirty data types together', () {
      // Arrange: Create JSON with multiple dirty data types
      final json = {
        'id': 1,
        'name': 'Test Store',
        'active': 1, // int
        'minimum_order': '25.50', // string
        'latitude': null, // null
        'longitude': 55.2708, // double
      };

      // Act & Assert: Should not throw exception
      final store = Store.fromJson(json);

      // Assert: All conversions should work correctly
      expect(store.active, isTrue);
      expect(store.minimumOrder, equals(25.5));
      expect(store.latitude, isNull);
      expect(store.longitude, equals('55.2708'));
    });
  });
}
