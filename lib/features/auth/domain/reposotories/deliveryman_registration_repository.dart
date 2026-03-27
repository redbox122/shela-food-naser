// ignore_for_file: unused_import, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/auth/domain/models/status_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_body.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_vehicles_model.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/deliveryman_registration_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import 'package:http/http.dart' as http;

class DeliverymanRegistrationRepository
    implements DeliverymanRegistrationRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  DeliverymanRegistrationRepository(
      {required this.sharedPreferences, required this.apiClient});

  //

  @override
  Future<bool> registerDeliveryMan(
    List<XFile> driverLicenseImages,
    List<XFile> vehicleLicenseImages,
    List<XFile> identityImages,
    DeliveryManBody deliveryManBody,
  ) async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      print('⚠️ لا يوجد توكن.');
      return false;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${apiClient.token}'
    };
    final uri = Uri.parse(AppConstants.baseUrl + AppConstants.dmRegisterUri);
    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll({
      'f_name': deliveryManBody.fName!,
      'identity_type': deliveryManBody.identityType!,
      'identity_number': deliveryManBody.identityNumber!,
      'email': deliveryManBody.email!,
      'phone': deliveryManBody.phone!,
      'password': deliveryManBody.password!,
      'zone_id': deliveryManBody.zoneId.toString(),
      'vehicle_id': deliveryManBody.vehicleId.toString(),
      'earning': deliveryManBody.earning.toString(),
    });

    // هوية
    for (final file in identityImages) {
      request.files.add(
          await http.MultipartFile.fromPath('identity_image[]', file.path));
    }

    // رخصة القيادة
    for (final file in vehicleLicenseImages) {
      request.files.add(await http.MultipartFile.fromPath(
          'driving_license_image[]', file.path));
    }

    // رخصة السائق
    for (final file in driverLicenseImages) {
      request.files.add(await http.MultipartFile.fromPath(
          'driver_license_image[]', file.path));
    }

    request.headers.addAll(headers);

    final http.StreamedResponse response = await request.send();

    //

    final body = await response.stream.bytesToString();

    debugPrint('\x1B[32m     ${response.statusCode} \x1B[0m');

    debugPrint('✅ Response Body:\n$body');

    if (response.statusCode == 200) {
      debugPrint('\x1B[32m ✅    ${response.reasonPhrase} \x1B[0m');

      return true;
    } else {
      print('❌ Error: ${response.statusCode}');
      return false;
    }
  }

  @override
  Future getList(
      {int? offset,
      int? zoneId,
      bool isZone = true,
      bool isVehicle = false}) async {
    if (isZone) {
      return await _getZoneList();
    } else if (isVehicle) {
      return await _getVehicleList();
    } else {
      return await _getModules(zoneId);
    }
  }

  Future<List<ZoneDataModel>?> _getZoneList() async {
    List<ZoneDataModel>? zoneList;
    final Response response = await apiClient.getData(AppConstants.zoneListUri, useEtag: false);

    if (response.statusCode == 200) {
      zoneList = [];
      
      // ✅ BACKEND CONTRACT: Handle both List and Map response formats
      if (response.body is List) {
        for (var zone in (response.body as List)) {
          zoneList.add(ZoneDataModel.fromJson(zone as Map<String, dynamic>));
        }
      } else if (response.body is Map<String, dynamic>) {
        // Handle new format: {success: true, zones: [...]}
        final responseMap = response.body as Map<String, dynamic>;
        final zonesData = responseMap['zones'];
        if (zonesData is List) {
          for (var zone in zonesData) {
            zoneList.add(ZoneDataModel.fromJson(zone as Map<String, dynamic>));
          }
        }
      }
      
      // ✅ BACKEND CONTRACT: Validate that we got zones
      if (zoneList.isEmpty) {
        debugPrint('❌ _getZoneList: Backend returned 200 but zones list is empty');
      }
    }
    return zoneList;
  }

  Future<List<ModuleModel>?> _getModules(int? zoneId) async {
    List<ModuleModel>? moduleList;
    final Response response = await apiClient.getData(
      '${AppConstants.moduleUri}?zone_id=$zoneId',
      useEtag: false,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        AppConstants.localizationKey:
            sharedPreferences.getString(AppConstants.languageCode) ??
                AppConstants.languages[0].languageCode!,
      },
    );
    if (response.statusCode == 200) {
      moduleList = [];
      if (response.body is List) {
        for (var storeCategory in (response.body as List)) {
          moduleList.add(ModuleModel.fromJson(storeCategory as Map<String, dynamic>));
        }
      }
    }
    return moduleList;
  }

  Future<List<DeliveryManVehicleModel>?> _getVehicleList() async {
    List<DeliveryManVehicleModel>? vehicles;
    final Response response = await apiClient.getData(AppConstants.vehiclesUri, useEtag: false);
    if (response.statusCode == 200) {
      vehicles = [];
      if (response.body is List) {
        for (var vehicle in (response.body as List)) {
          vehicles.add(DeliveryManVehicleModel.fromJson(vehicle as Map<String, dynamic>));
        }
      }
    }
    return vehicles;
  }

  @override
  Future<StatusModel> getStatus(String? phone) async {
    final Map<String, dynamic> data = {
      'phone': phone,
    };

    // Try known backend variants in order:
    // 1) current configured uri
    // 2) direct /delivery-man/status (without auth/customer prefix)
    // 3) customer-prefixed fallback
    final List<String> endpointCandidates = <String>[
      AppConstants.statusUri,
      '/api/v1/delivery-man/status',
      '/api/v1/customer/delivery-man/status',
    ].toSet().toList();

    Response? lastResponse;
    for (final uri in endpointCandidates) {
      debugPrint('[DM-REG] getStatus -> POST $uri body=$data');
      final Response response = await apiClient.postData(
        uri,
        data,
        handleError: false,
      );
      lastResponse = response;

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[DM-REG] getStatus <- ${response.statusCode} uri=$uri body=${response.body}');
        return StatusModel.fromJson(response.body as Map<String, dynamic>);
      }

      debugPrint('[DM-REG] getStatus miss uri=$uri status=${response.statusCode}');
    }

    debugPrint(
        '[DM-REG] getStatus failed status=${lastResponse?.statusCode} body=${lastResponse?.body}');
    return StatusModel(
      success: false,
      message:
          'status endpoint not found or failed (${lastResponse?.statusCode ?? 'unknown'})',
      name: null,
      phone: phone,
      email: null,
      status: null,
    );
  }

  @override
  Future<Map<String, dynamic>?> checkDeliveryManRegistration({
    String? phone,
    String? email,
    String? identityNumber,
  }) async {
    final Map<String, dynamic> payload = {};

    final normalizedPhone = phone?.trim();
    final normalizedEmail = email?.trim();
    final normalizedIdentityNumber = identityNumber?.trim();

    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      payload['phone'] = normalizedPhone;
    }
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      payload['email'] = normalizedEmail;
    }
    if (normalizedIdentityNumber != null && normalizedIdentityNumber.isNotEmpty) {
      payload['identity_number'] = normalizedIdentityNumber;
    }

    // Try auth:api endpoint first (uses Bearer token, can work with empty body)
    final Response customerResponse = await apiClient.postData(
      AppConstants.customerDmCheckRegistrationUri,
      payload.isEmpty ? <String, dynamic>{} : payload,
      handleError: false,
    );
    if (customerResponse.statusCode == 200 &&
        customerResponse.body is Map<String, dynamic>) {
      return customerResponse.body as Map<String, dynamic>;
    }

    // Fallback to public endpoint when identifiers are available
    if (payload.isNotEmpty) {
      final Response publicResponse = await apiClient.postData(
        AppConstants.dmCheckRegistrationUri,
        payload,
        handleError: false,
      );
      if (publicResponse.statusCode == 200 &&
          publicResponse.body is Map<String, dynamic>) {
        return publicResponse.body as Map<String, dynamic>;
      }
    }

    return null;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }
}
