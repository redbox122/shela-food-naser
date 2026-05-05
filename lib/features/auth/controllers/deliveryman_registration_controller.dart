// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/features/auth/domain/models/status_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_body.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_vehicles_model.dart';
import 'package:sixam_mart/features/auth/domain/services/deliveryman_registration_service_interface.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/deliveryman_registration_repository.dart';

class DeliverymanRegistrationController extends GetxController
    implements GetxService {
  final DeliverymanRegistrationServiceInterface
      deliverymanRegistrationServiceInterface;

  DeliverymanRegistrationController(
      {required this.deliverymanRegistrationServiceInterface});

  static const String _tag = '[DM-REG]';

  /// Prints a snapshot of all key state variables for debugging
  void printState(String caller) {
    debugPrint('$_tag ====== STATE DUMP from $caller ======');
    debugPrint('$_tag  isLoading=$_isLoading');
    debugPrint('$_tag  dmStatus=$_dmStatus');
    debugPrint('$_tag  dmTypeIndex=$_dmTypeIndex');
    debugPrint('$_tag  identityTypeIndex=$_identityTypeIndex');
    debugPrint('$_tag  selectedZoneIndex=$_selectedZoneIndex');
    debugPrint('$_tag  zoneList=${_zoneList?.length ?? 'null'} items');
    debugPrint('$_tag  zoneIds=$_zoneIds');
    debugPrint('$_tag  vehicleIndex=$_vehicleIndex');
    debugPrint('$_tag  vehicles=${_vehicles?.length ?? 'null'} items');
    debugPrint('$_tag  vehicleIds=$_vehicleIds');
    debugPrint('$_tag  moduleList=${_moduleList?.length ?? 'null'} items');
    debugPrint('$_tag  pickedImage=${_pickedImage?.path ?? 'null'}');
    debugPrint('$_tag  pickedIdentities=${_pickedIdentities.length} items');
    debugPrint('$_tag  driverLicenseImages=${driverLicenseImages.length} items');
    debugPrint('$_tag  vehicleLicenseImages=${vehicleLicenseImages.length} items');
    debugPrint('$_tag  identityImages=${identityImages.length} items');
    debugPrint('$_tag  acceptTerms=$_acceptTerms');
    debugPrint('$_tag ====== END STATE DUMP ======');
  }

  List<XFile> driverLicenseImages = [];
  List<XFile> vehicleLicenseImages = [];
  List<XFile> identityImages = [];

  // ========

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StatusModel? _status_model;
  StatusModel? get status_model => _status_model;

  bool _showPassView = false;
  bool get showPassView => _showPassView;

  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  List<XFile> _pickedIdentities = [];
  List<XFile> get pickedIdentities => _pickedIdentities;

  double _dmStatus = 0.4;
  double get dmStatus => _dmStatus;

  bool _lengthCheck = false;
  bool get lengthCheck => _lengthCheck;

  bool _numberCheck = false;
  bool get numberCheck => _numberCheck;

  bool _uppercaseCheck = false;
  bool get uppercaseCheck => _uppercaseCheck;

  bool _lowercaseCheck = false;
  bool get lowercaseCheck => _lowercaseCheck;

  bool _spatialCheck = false;
  bool get spatialCheck => _spatialCheck;

  final List<String> _identityTypeList = ['passport', 'driving_license'];
  List<String> get identityTypeList => _identityTypeList;

  int _identityTypeIndex = 0;
  int get identityTypeIndex => _identityTypeIndex;

  int _dmTypeIndex = 0;
  int get dmTypeIndex => _dmTypeIndex;

  List<ZoneDataModel>? _zoneList;
  List<ZoneDataModel>? get zoneList => _zoneList;

  int? _selectedZoneIndex = 0;
  int? get selectedZoneIndex => _selectedZoneIndex;

  List<int>? _zoneIds;
  List<int>? get zoneIds => _zoneIds;

  List<ModuleModel>? _moduleList;
  List<ModuleModel>? get moduleList => _moduleList;

  List<DeliveryManVehicleModel>? _vehicles;
  List<DeliveryManVehicleModel>? get vehicles => _vehicles;

  List<int?>? _vehicleIds;
  List<int?>? get vehicleIds => _vehicleIds;

  final List<String?> _dmTypeList = [
    'select_delivery_type',
    'freelancer',
    'salary_based'
  ];

  List<String?> get dmTypeList => _dmTypeList;

  int? _vehicleIndex = 0;
  int? get vehicleIndex => _vehicleIndex;

  bool _acceptTerms = true;
  bool get acceptTerms => _acceptTerms;

  // ===============================================================================

  Future<void> pickImage(String type) async {
    debugPrint('$_tag pickImage($type) called | driver=${driverLicenseImages.length}, vehicle=${vehicleLicenseImages.length}, identity=${identityImages.length}');
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        debugPrint('$_tag pickImage($type) => picked: ${image.path}');
        switch (type) {
          case 'driver':
            if (driverLicenseImages.length < 2) {
              driverLicenseImages.add(image);
            } else {
              debugPrint('$_tag pickImage(driver) => already has 2 images, skipped');
            }
            break;
          case 'vehicle':
            if (vehicleLicenseImages.length < 2) {
              vehicleLicenseImages.add(image);
            } else {
              debugPrint('$_tag pickImage(vehicle) => already has 2 images, skipped');
            }
            break;
          case 'identity':
            if (identityImages.length < 2) {
              identityImages.add(image);
            } else {
              debugPrint('$_tag pickImage(identity) => already has 2 images, skipped');
            }
            break;
        }
        debugPrint('$_tag pickImage($type) done | driver=${driverLicenseImages.length}, vehicle=${vehicleLicenseImages.length}, identity=${identityImages.length}');
        update();
      } else {
        debugPrint('$_tag pickImage($type) => user cancelled (null)');
      }
    } on PlatformException catch (e) {
      debugPrint('$_tag pickImage($type) PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('$_tag pickImage($type) unexpected error: $e');
    }
  }

  void removeImage(String type, int index) {
    debugPrint('$_tag removeImage($type, index=$index)');
    switch (type) {
      case 'driver':
        driverLicenseImages.removeAt(index);
        break;
      case 'vehicle':
        vehicleLicenseImages.removeAt(index);
        break;
      case 'identity':
        identityImages.removeAt(index);
        break;
    }
    debugPrint('$_tag removeImage done | driver=${driverLicenseImages.length}, vehicle=${vehicleLicenseImages.length}, identity=${identityImages.length}');
    update();
  }

  //

  // ===========================================================================

  void showHidePass({bool isUpdate = true}) {
    _showPassView = !_showPassView;
    debugPrint('$_tag showHidePass => showPassView=$_showPassView');
    if (isUpdate) {
      update();
    }
  }

  Future<void> setZoneIndex(int? index, {bool canUpdate = true}) async {
    debugPrint('$_tag setZoneIndex(index=$index) | old=$_selectedZoneIndex | zoneList=${_zoneList?.length ?? 'null'} items');
    _selectedZoneIndex = index;
    if (canUpdate) {
      final zoneName = (zoneList != null && selectedZoneIndex != null && selectedZoneIndex! >= 0 && selectedZoneIndex! < zoneList!.length)
          ? zoneList![selectedZoneIndex!].name
          : 'OUT_OF_BOUNDS';
      debugPrint('$_tag setZoneIndex => selected zone: $zoneName (id=${(zoneList != null && selectedZoneIndex != null && selectedZoneIndex! >= 0 && selectedZoneIndex! < zoneList!.length) ? zoneList![selectedZoneIndex!].id : 'N/A'})');
      await getModules(zoneList![selectedZoneIndex!].id);
      update();
    }
  }

  void setVehicleIndex(int? index, bool notify) {
    debugPrint('$_tag setVehicleIndex(index=$index) | old=$_vehicleIndex | vehicles=${_vehicles?.length ?? 'null'} items');
    _vehicleIndex = index;
    if (_vehicles != null && index != null && index >= 0 && index < _vehicles!.length) {
      debugPrint('$_tag setVehicleIndex => selected vehicle: ${_vehicles![index].type} (id=${_vehicles![index].id})');
    }
    if (notify) {
      update();
    }
  }

  void removeIdentityImage(int index) {
    debugPrint('$_tag removeIdentityImage(index=$index) | was ${_pickedIdentities.length} items');
    _pickedIdentities.removeAt(index);
    debugPrint('$_tag removeIdentityImage => now ${_pickedIdentities.length} items');
    update();
  }

  void pickDmImage(bool isLogo, bool isRemove) async {
    debugPrint('$_tag pickDmImage(isLogo=$isLogo, isRemove=$isRemove)');
    if (isRemove) {
      _pickedImage = null;
      _pickedIdentities = [];
      debugPrint('$_tag pickDmImage => cleared all images');
    } else {
      try {
        if (isLogo) {
          _pickedImage =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          debugPrint('$_tag pickDmImage(logo) => ${_pickedImage?.path ?? 'cancelled'}');
        } else {
          final XFile? xFile =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (xFile != null) {
            _pickedIdentities.add(xFile);
            debugPrint('$_tag pickDmImage(identity) => added ${xFile.path} | total=${_pickedIdentities.length}');
          } else {
            debugPrint('$_tag pickDmImage(identity) => user cancelled');
          }
        }
      } on PlatformException catch (e) {
        debugPrint('$_tag pickDmImage PlatformException: ${e.message}');
      } catch (e) {
        debugPrint('$_tag pickDmImage unexpected error: $e');
      }
      update();
    }
  }

  void removeDmImage() {
    debugPrint('$_tag removeDmImage => cleared profile image');
    _pickedImage = null;
    update();
  }

  void dmStatusChange(double value, {bool isUpdate = true}) {
    debugPrint('$_tag dmStatusChange($value) | old=$_dmStatus | step=${value == 0.4 ? "STEP 1 (personal info)" : "STEP 2 (documents)"}');
    _dmStatus = value;
    if (isUpdate) {
      update();
    }
  }

  void validPassCheck(String pass, {bool isUpdate = true}) {
    _lengthCheck = false;
    _numberCheck = false;
    _uppercaseCheck = false;
    _lowercaseCheck = false;
    _spatialCheck = false;

    if (pass.length > 7) {
      _lengthCheck = true;
    }
    // ignore: deprecated_member_use
    if (pass.contains(RegExp(r'[a-z]'))) {
      _lowercaseCheck = true;
    }
    // ignore: deprecated_member_use
    if (pass.contains(RegExp(r'[A-Z]'))) {
      _uppercaseCheck = true;
    }
    // ignore: deprecated_member_use
    if (pass.contains(RegExp(r'[ .!@#$&*~^%]'))) {
      _spatialCheck = true;
    }
    // ignore: deprecated_member_use
    if (pass.contains(RegExp(r'[\d+]'))) {
      _numberCheck = true;
    }
    if (isUpdate) {
      update();
    }
  }

  void setIdentityTypeIndex(String? identityType, bool notify) {
    debugPrint('$_tag setIdentityTypeIndex($identityType) | old=$_identityTypeIndex');
    int index0 = 0;
    for (int index = 0; index < _identityTypeList.length; index++) {
      if (_identityTypeList[index] == identityType) {
        index0 = index;
        break;
      }
    }
    _identityTypeIndex = index0;
    debugPrint('$_tag setIdentityTypeIndex => new=$_identityTypeIndex (${_identityTypeList[_identityTypeIndex]})');
    if (notify) {
      update();
    }
  }

  void setDMTypeIndex(int dmType, bool notify) {
    debugPrint('$_tag setDMTypeIndex($dmType) | old=$_dmTypeIndex | label=${dmType >= 0 && dmType < _dmTypeList.length ? _dmTypeList[dmType] : 'OUT_OF_BOUNDS'}');
    _dmTypeIndex = dmType;
    if (notify) {
      update();
    }
  }

  Future<void> getZoneList() async {
    debugPrint('$_tag getZoneList() START');
    _selectedZoneIndex = -1;
    _zoneIds = null;

    try {
      final List<ZoneDataModel>? zones =
          await deliverymanRegistrationServiceInterface.getZoneList();

      debugPrint('$_tag getZoneList() => API returned ${zones?.length ?? 'null'} zones');

      if (zones == null || zones.isEmpty) {
        debugPrint('$_tag getZoneList: Zone list is null or empty');
        _zoneList = [];
        update();
        return;
      }

      _zoneList = [];
      _zoneList!.addAll(zones);
      for (int i = 0; i < _zoneList!.length; i++) {
        debugPrint('$_tag   zone[$i]: id=${_zoneList![i].id}, name=${_zoneList![i].name}');
      }

      final defaultLocation = Get.find<SplashController>().configModel?.defaultLocation;
      debugPrint('$_tag getZoneList => defaultLocation: lat=${defaultLocation?.lat}, lng=${defaultLocation?.lng}');
      _setLocation(LatLng(
        double.tryParse(defaultLocation?.lat ?? '0') ?? 0,
        double.tryParse(defaultLocation?.lng ?? '0') ?? 0,
      ));
      await getModules(_zoneList!.first.id);
    } catch (e) {
      debugPrint('$_tag getZoneList ERROR: $e');
      _zoneList ??= [];
    }
    debugPrint('$_tag getZoneList() END | zoneList=${_zoneList?.length ?? 'null'}, selectedZoneIndex=$_selectedZoneIndex');
    update();
  }

  void _setLocation(LatLng location) async {
    debugPrint('$_tag _setLocation(lat=${location.latitude}, lng=${location.longitude})');
    final ZoneResponseModel response =
        await Get.find<LocationController>().getZone(
      location.latitude.toString(),
      location.longitude.toString(),
      false,
    );
    debugPrint('$_tag _setLocation => isSuccess=${response.isSuccess}, zoneIds=${response.zoneIds}');
    if (response.isSuccess && response.zoneIds.isNotEmpty) {
      _zoneIds = response.zoneIds;
      _selectedZoneIndex = deliverymanRegistrationServiceInterface
          .prepareSelectedZoneIndex(_zoneIds, _zoneList);
      debugPrint('$_tag _setLocation => selectedZoneIndex=$_selectedZoneIndex, zoneIds=$_zoneIds');
    } else {
      _zoneIds = null;
      debugPrint('$_tag _setLocation => no zone found, zoneIds=null');
    }
    update();
  }

  Future<void> getModules(int? zoneId) async {
    debugPrint('$_tag getModules(zoneId=$zoneId) START');
    final List<ModuleModel>? modules =
        await deliverymanRegistrationServiceInterface.getModules(zoneId);
    debugPrint('$_tag getModules => returned ${modules?.length ?? 'null'} modules');
    if (modules != null) {
      _moduleList = [];
      _moduleList!.addAll(modules);
    }
    update();
  }

  void toggleTerms() {
    _acceptTerms = !_acceptTerms;
    debugPrint('$_tag toggleTerms => acceptTerms=$_acceptTerms');
    update();
  }

  Future<void> getVehicleList() async {
    debugPrint('$_tag getVehicleList() START');
    try {
      final List<DeliveryManVehicleModel>? vehicleList =
          await deliverymanRegistrationServiceInterface.getVehicleList();
      debugPrint('$_tag getVehicleList() => API returned ${vehicleList?.length ?? 'null'} vehicles');
      if (vehicleList != null && vehicleList.isNotEmpty) {
        _vehicles = [];
        _vehicles!.addAll(vehicleList);
        _vehicleIds = deliverymanRegistrationServiceInterface
            .prepareVehicleIds(vehicleList);
        for (int i = 0; i < _vehicles!.length; i++) {
          debugPrint('$_tag   vehicle[$i]: id=${_vehicles![i].id}, type=${_vehicles![i].type}');
        }
        debugPrint('$_tag getVehicleList() => vehicleIds=$_vehicleIds');
      } else {
        debugPrint('$_tag getVehicleList: vehicle list is null or empty => setting empty lists');
        _vehicles = [];
        _vehicleIds = [];
      }
    } catch (e) {
      debugPrint('$_tag getVehicleList ERROR: $e');
      _vehicles ??= [];
      _vehicleIds ??= [];
    }
    debugPrint('$_tag getVehicleList() END | vehicles=${_vehicles?.length ?? 'null'}, vehicleIds=$_vehicleIds, vehicleIndex=$_vehicleIndex');
    update();
  }

  Future<void> registerDeliveryMan(
    List<XFile> driverLicenseImages,
    List<XFile> vehicleLicenseImages,
    List<XFile> identityImages,
    DeliveryManBody deliveryManBody,
  ) async {
    debugPrint('$_tag registerDeliveryMan() START');
    debugPrint('$_tag  fName=${deliveryManBody.fName}');
    debugPrint('$_tag  zoneId=${deliveryManBody.zoneId}');
    debugPrint('$_tag  vehicleId=${deliveryManBody.vehicleId}');
    debugPrint('$_tag  identityType=${deliveryManBody.identityType}');
    debugPrint('$_tag  identityNumber=${deliveryManBody.identityNumber}');
    debugPrint('$_tag  earning=${deliveryManBody.earning}');
    debugPrint('$_tag  driverLicenseImages=${driverLicenseImages.length}');
    debugPrint('$_tag  vehicleLicenseImages=${vehicleLicenseImages.length}');
    debugPrint('$_tag  identityImages=${identityImages.length}');
    _isLoading = true;
    update();

    try {
      await deliverymanRegistrationServiceInterface.registerDeliveryMan(
        driverLicenseImages,
        vehicleLicenseImages,
        identityImages,
        deliveryManBody,
      );
      debugPrint('$_tag registerDeliveryMan() => service call completed');
    } catch (e) {
      debugPrint('$_tag registerDeliveryMan ERROR: $e');
    } finally {
      _isLoading = false;
      debugPrint('$_tag registerDeliveryMan() END | isLoading=$_isLoading');
      update();
    }
  }

  void resetDeliveryRegistration() {
    debugPrint('$_tag resetDeliveryRegistration() => clearing all form data');
    _identityTypeIndex = 0;
    _dmTypeIndex = 0;
    _selectedZoneIndex = -1;
    _pickedImage = null;
    _pickedIdentities = [];

    driverLicenseImages = [];
    vehicleLicenseImages = [];
    identityImages = [];
    printState('resetDeliveryRegistration');
    update();
  }

  // get  Status   =================================================================

  /// Single endpoint: POST /api/v1/customer/delivery-man/check-registration
  Future<Map<String, dynamic>?> fetchDeliveryRegistrationForProfile({
    String? phone,
    String? email,
  }) async {
    if (kDebugMode) {
      debugPrint('[PROFILE_STATUS][DELIVERY_SINGLE_ENDPOINT]');
    }
    try {
      final Map<String, dynamic>? raw =
          await deliverymanRegistrationServiceInterface
              .checkDeliveryManRegistration(phone: phone, email: email);
      _status_model = statusModelFromCheckRegistration(raw, phone);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        update();
      });
      return raw;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_tag fetchDeliveryRegistrationForProfile ERROR: $e');
      }
      return null;
    }
  }

  Future<void> getStatus() async {
    if (kDebugMode) {
      debugPrint('$_tag getStatus() START');
    }
    final ProfileController profileController = Get.find<ProfileController>();
    String? phone = profileController.userInfoModel?.phone?.trim();
    String? email = profileController.userInfoModel?.email?.trim();

    if (phone == null || phone.isEmpty || phone.toLowerCase() == 'null') {
      if (kDebugMode) {
        debugPrint('$_tag getStatus => phone is null, fetching user info...');
      }
      await profileController.getUserInfo();
      phone = profileController.userInfoModel?.phone?.trim();
      email = profileController.userInfoModel?.email?.trim();
    }

    if (phone == null || phone.isEmpty || phone.toLowerCase() == 'null') {
      if (kDebugMode) {
        debugPrint('$_tag getStatus => phone is still null, aborting');
      }
      return;
    }

    await fetchDeliveryRegistrationForProfile(phone: phone, email: email);

    if (kDebugMode) {
      debugPrint(
          '$_tag getStatus => status_model phone=${_status_model?.phone ?? 'null'}');
    }
  }

  Future<Map<String, dynamic>?> checkDeliveryManRegistration({
    String? phone,
    String? email,
    String? identityNumber,
  }) async {
    debugPrint(
      '$_tag checkDeliveryManRegistration(phone=$phone, email=$email, identityNumber=$identityNumber)',
    );
    try {
      return await deliverymanRegistrationServiceInterface
          .checkDeliveryManRegistration(
        phone: phone,
        email: email,
        identityNumber: identityNumber,
      );
    } catch (e) {
      debugPrint('$_tag checkDeliveryManRegistration ERROR: $e');
      return null;
    }
  }

  //
}
