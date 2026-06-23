import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_v2_model.dart';
import 'package:sixam_mart/features/address/domain/models/check_zone_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Result of `POST /api/v2/address/add`.
class AddAddressV2Result {
  final bool success;
  final String? message;
  final int? addressId;
  const AddAddressV2Result(this.success, this.message, {this.addressId});
}

/// Thin wrapper around the new v2 address endpoints. Kept outside GetX DI so it
/// can be used directly from screens without extra plumbing; it borrows the
/// already-registered [ApiClient] (auth headers, retries, cert pinning).
class AddressV2Api {
  final ApiClient apiClient;
  AddressV2Api({ApiClient? apiClient})
      : apiClient = apiClient ?? Get.find<ApiClient>();

  /// Validates a map point and returns the parsed address parts.
  /// Returns null only on a transport-level failure (no parseable body).
  Future<CheckZoneModel?> checkZone(double latitude, double longitude) async {
    try {
      final Response response = await apiClient.postData(
        AppConstants.checkZoneV2Uri,
        {'latitude': latitude, 'longitude': longitude},
        handleError: false,
      );
      // Out-of-zone still returns a parseable body with success/in_zone=false.
      if (response.body is Map) {
        return CheckZoneModel.fromJson(
            Map<String, dynamic>.from(response.body as Map));
      }
    } catch (e) {
      debugPrint('⚠️ AddressV2Api.checkZone failed: $e');
    }
    return null;
  }

  /// Saves a new address. [body] must already contain the v2 fields
  /// (city, region, street_name, address_label, building_type, latitude, …).
  Future<AddAddressV2Result> add(Map<String, dynamic> body) async {
    try {
      final Response response = await apiClient.postData(
        AppConstants.addAddressV2Uri,
        body,
        handleError: false,
      );
      final dynamic data = response.body;
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        final addr = data['address'];
        return AddAddressV2Result(
          true,
          data['message']?.toString(),
          addressId: addr is Map && addr['id'] != null
              ? int.tryParse(addr['id'].toString())
              : null,
        );
      }
      final String? message =
          data is Map ? data['message']?.toString() : response.statusText;
      return AddAddressV2Result(false, message);
    } catch (e) {
      debugPrint('⚠️ AddressV2Api.add failed: $e');
      return const AddAddressV2Result(false, null);
    }
  }

  /// Updates an existing address (PUT — accepts the same fields as [add] and
  /// supports partial updates).
  Future<AddAddressV2Result> update(int id, Map<String, dynamic> body) async {
    try {
      final Response response = await apiClient.putData(
        '${AppConstants.updateAddressV2Uri}$id',
        body,
      );
      final dynamic data = response.body;
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        final addr = data['address'];
        return AddAddressV2Result(
          true,
          data['message']?.toString(),
          addressId: addr is Map && addr['id'] != null
              ? int.tryParse(addr['id'].toString())
              : null,
        );
      }
      final String? message =
          data is Map ? data['message']?.toString() : response.statusText;
      return AddAddressV2Result(false, message);
    } catch (e) {
      debugPrint('⚠️ AddressV2Api.update failed: $e');
      return const AddAddressV2Result(false, null);
    }
  }

  /// Fetches all saved addresses. Returns an empty list on failure.
  Future<List<AddressV2Model>> list() async {
    try {
      final Response response = await apiClient.getData(
        AppConstants.addressListV2Uri,
        useEtag: false,
      );
      final dynamic data = response.body;
      if (response.statusCode == 200 && data is Map && data['addresses'] is List) {
        return (data['addresses'] as List)
            .whereType<Map>()
            .map((e) => AddressV2Model.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ AddressV2Api.list failed: $e');
    }
    return <AddressV2Model>[];
  }

  /// Fetches the full details of a single address.
  Future<AddressV2Model?> details(int id) async {
    try {
      final Response response = await apiClient.getData(
        '${AppConstants.addressDetailsV2Uri}$id',
        useEtag: false,
      );
      if (response.statusCode == 200 && response.body is Map) {
        return AddressV2Model.fromJson(
            Map<String, dynamic>.from(response.body as Map));
      }
    } catch (e) {
      debugPrint('⚠️ AddressV2Api.details failed: $e');
    }
    return null;
  }

  /// Deletes an address by id.
  Future<AddAddressV2Result> delete(int id) async {
    try {
      final Response response = await apiClient.deleteData(
        '${AppConstants.deleteAddressV2Uri}$id',
        handleError: false,
      );
      final dynamic data = response.body;
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        return AddAddressV2Result(true, data['message']?.toString());
      }
      final String? message =
          data is Map ? data['message']?.toString() : response.statusText;
      return AddAddressV2Result(false, message);
    } catch (e) {
      debugPrint('⚠️ AddressV2Api.delete failed: $e');
      return const AddAddressV2Result(false, null);
    }
  }

  /// Builds the v2 add-address request body from the form + picked location.
  static Map<String, dynamic> buildAddBody({
    required String city,
    required String region,
    required String streetName,
    required String addressLabel,
    required double latitude,
    required double longitude,
    required String buildingType,
    String? buildingNumber,
    String? floorNumber,
    String? apartmentNumber,
    String? additionalInfo,
  }) {
    return {
      'city': city,
      'region': region,
      'street_name': streetName,
      'address_label': addressLabel,
      'latitude': latitude,
      'longitude': longitude,
      'building_type': buildingType,
      'building_number': buildingNumber ?? '',
      'floor_number': floorNumber ?? '',
      'apartment_number': apartmentNumber ?? '',
      'additional_info': additionalInfo ?? '',
    };
  }
}
