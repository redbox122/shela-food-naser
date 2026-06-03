
import 'package:flutter/foundation.dart';
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
import 'package:dio/dio.dart' as dio_pkg;
import 'package:sixam_mart/common/security/certificate_pinning.dart';

/// Maps [checkDeliveryManRegistration] JSON to [StatusModel] (legacy UI).
StatusModel statusModelFromCheckRegistration(
    Map<String, dynamic>? root, String? phone) {
  if (root == null) {
    return StatusModel(
      success: false,
      message: null,
      name: null,
      phone: phone,
      email: null,
      status: null,
    );
  }
  final Map<String, dynamic>? dm = root['delivery_man'] is Map
      ? Map<String, dynamic>.from(root['delivery_man'] as Map)
      : null;
  final String applicationStatus =
      (dm?['application_status'] ?? '').toString().toLowerCase();
  final String statusRaw = (dm?['status'] ?? '').toString().toLowerCase();
  final String activeRaw = (dm?['active'] ?? '').toString().toLowerCase();
  String statusOut =
      applicationStatus.isNotEmpty ? applicationStatus : statusRaw;
  if (statusOut.isEmpty &&
      (activeRaw == '1' ||
          activeRaw == 'true' ||
          statusRaw == '1' ||
          statusRaw == 'active')) {
    statusOut = 'approved';
  }
  if (statusOut.isEmpty && root['is_registered'] == true) {
    statusOut = 'approved';
  }
  return StatusModel(
    success: true,
    message: null,
    name: dm?['name']?.toString(),
    phone: phone ?? dm?['phone']?.toString(),
    email: dm?['email']?.toString(),
    status: statusOut.isNotEmpty ? statusOut : null,
  );
}

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
      if (kDebugMode) {
        debugPrint('⚠️ لا يوجد توكن.');
      }
      return false;
    }

    final url = AppConstants.baseUrl + AppConstants.dmRegisterUri;
    final formData = dio_pkg.FormData();

    formData.fields.addAll([
      MapEntry('f_name', deliveryManBody.fName!),
      MapEntry('identity_type', deliveryManBody.identityType!),
      MapEntry('identity_number', deliveryManBody.identityNumber!),
      MapEntry('email', deliveryManBody.email!),
      MapEntry('phone', deliveryManBody.phone!),
      MapEntry('password', deliveryManBody.password!),
      MapEntry('zone_id', deliveryManBody.zoneId.toString()),
      MapEntry('vehicle_id', deliveryManBody.vehicleId.toString()),
      MapEntry('earning', deliveryManBody.earning.toString()),
    ]);

    for (final file in identityImages) {
      formData.files.add(MapEntry(
        'identity_image[]',
        await dio_pkg.MultipartFile.fromFile(file.path),
      ));
    }
    for (final file in vehicleLicenseImages) {
      formData.files.add(MapEntry(
        'driving_license_image[]',
        await dio_pkg.MultipartFile.fromFile(file.path),
      ));
    }
    for (final file in driverLicenseImages) {
      formData.files.add(MapEntry(
        'driver_license_image[]',
        await dio_pkg.MultipartFile.fromFile(file.path),
      ));
    }

    final dio = dio_pkg.Dio();
    CertificatePinning.apply(dio);
    final dioResponse = await dio.post<dynamic>(
      url,
      data: formData,
      options: dio_pkg.Options(
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${apiClient.token}',
        },
        validateStatus: (s) => s != null,
      ),
    );

    if (kDebugMode) {
      debugPrint('\x1B[32m     ${dioResponse.statusCode} \x1B[0m');
      debugPrint(
          '✅ Response Body (truncated): ${dioResponse.data.toString().length > 200 ? "${dioResponse.data.toString().substring(0, 200)}…" : dioResponse.data}');
    }

    if (dioResponse.statusCode == 200) {
      if (kDebugMode) {
        debugPrint('\x1B[32m ✅    ${dioResponse.statusMessage} \x1B[0m');
      }
      return true;
    } else {
      if (kDebugMode) {
        debugPrint('❌ Error: ${dioResponse.statusCode}');
      }
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
    if (kDebugMode) {
      debugPrint(
          '[PROFILE_STATUS][DELIVERY_SINGLE_ENDPOINT] ${AppConstants.customerDmCheckRegistrationUri}');
    }
    final Map<String, dynamic>? root =
        await checkDeliveryManRegistration(phone: phone);
    return statusModelFromCheckRegistration(root, phone);
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
