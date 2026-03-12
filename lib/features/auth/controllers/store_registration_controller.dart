import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/business/controllers/business_controller.dart';
import 'package:sixam_mart/features/business/domain/models/package_model.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/services/location_service_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/auth/domain/models/store_body_model.dart';
import 'package:sixam_mart/features/auth/domain/services/store_registration_service_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class StoreRegistrationController extends GetxController
    implements GetxService {
  final StoreRegistrationServiceInterface storeRegistrationServiceInterface;
  final LocationServiceInterface locationServiceInterface;

  StoreRegistrationController(
      {required this.locationServiceInterface,
      required this.storeRegistrationServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _storeStatus = 0.1;
  double get storeStatus => _storeStatus;

  XFile? _pickedLogo;
  XFile? get pickedLogo => _pickedLogo;

  XFile? _pickedCover;
  XFile? get pickedCover => _pickedCover;

  LatLng? _restaurantLocation;
  LatLng? get restaurantLocation => _restaurantLocation;

  List<int>? _zoneIds;
  List<int>? get zoneIds => _zoneIds;

  int? _selectedZoneIndex = 0;
  int? get selectedZoneIndex => _selectedZoneIndex;

  List<ZoneDataModel>? _zoneList;
  List<ZoneDataModel>? get zoneList => _zoneList;
  
  // ✅ BACKEND CONTRACT: Flag to track zone loading errors
  bool _hasZoneError = false;
  bool get hasZoneError => _hasZoneError;

  List<ModuleModel>? _moduleList;
  List<ModuleModel>? get moduleList => _moduleList;

  int? _selectedModuleIndex = -1;
  int? get selectedModuleIndex => _selectedModuleIndex;

  bool _showPassView = false;
  bool get showPassView => _showPassView;

  String? _storeAddress;
  String? get storeAddress => _storeAddress;

  String _storeMinTime = '--';
  String get storeMinTime => _storeMinTime;

  String _storeMaxTime = '--';
  String get storeMaxTime => _storeMaxTime;

  String _storeTimeUnit = 'minute';
  String get storeTimeUnit => _storeTimeUnit;

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

  bool _inZone = false;
  bool get inZone => _inZone;

  int _businessIndex = 0;
  int get businessIndex => _businessIndex;

  int _activeSubscriptionIndex = 0;
  int get activeSubscriptionIndex => _activeSubscriptionIndex;

  String _businessPlanStatus = 'business';
  String get businessPlanStatus => _businessPlanStatus;

  int _paymentIndex = 0;
  int get paymentIndex => _paymentIndex;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  PackageModel? _packageModel;
  PackageModel? get packageModel => _packageModel;

  String? _selectedPickupZone;
  String? get selectedPickupZone => _selectedPickupZone;

  int? _selectedPickupZoneId;
  int? get selectedPickupZoneId => _selectedPickupZoneId;

  final List<String> _pickupZoneList = [];
  List<String> get pickupZoneList => _pickupZoneList;

  final List<int> _pickupZoneIdList = [];
  List<int> get pickupZoneIdList => _pickupZoneIdList;

  //

  void setRestaurantLocation(LatLng location) {
    _restaurantLocation = location;
    update();
  }

//

  void setSelectedPickupZone(String? zone, int? zoneId) {
    if (zone != null && zoneId != null) {
      if (_pickupZoneList.contains(zone) ||
          _pickupZoneIdList.contains(zoneId)) {
        showCustomSnackBar('zone_already_added_please_select_another'.tr);
      } else {
        _selectedPickupZone = zone;
        _pickupZoneList.add(zone);
        _pickupZoneIdList.add(zoneId);
        update();
      }
    }
  }

  void removePickupZone(String zone, int zoneId) {
    _selectedPickupZone = null;
    _pickupZoneList.remove(zone);
    _pickupZoneIdList.remove(zoneId);
    update();
  }

  void clearPickupZone() {
    _selectedModuleIndex = -1;
    _selectedPickupZone = null;
    _pickupZoneList.clear();
    _pickupZoneIdList.clear();
  }

  void showHidePass({bool isUpdate = true}) {
    _showPassView = !_showPassView;
    if (isUpdate) {
      update();
    }
  }

  Future<void> setZoneIndex(int? index, {bool canUpdate = true}) async {
    _selectedZoneIndex = index;
    _moduleList = null;
    _selectedModuleIndex = -1;
    update();

    // Re-evaluate inZone when user changes zone while a location is already set.
    if (_selectedZoneIndex != null &&
        _selectedZoneIndex != -1 &&
        _restaurantLocation != null &&
        _zoneList != null &&
        _zoneList!.isNotEmpty) {
      final int? selectedZoneId = _zoneList![_selectedZoneIndex!].id;
      if (selectedZoneId != null) {
        final bool inSelectedZone = await storeRegistrationServiceInterface
            .checkInZone(
                _restaurantLocation!.latitude.toString(),
                _restaurantLocation!.longitude.toString(),
                selectedZoneId);

        // Fallback to zoneIds from zone API when check endpoint is inconsistent.
        _inZone =
            inSelectedZone || (_zoneIds?.contains(selectedZoneId) ?? false);
      }
    }

    if (canUpdate) {
      await getModules(zoneList![selectedZoneIndex!].id);
      update();
    }
  }

  void minTimeChange(String time) {
    _storeMinTime = time;
    update();
  }

  void maxTimeChange(String time) {
    _storeMaxTime = time;
    update();
  }

  void timeUnitChange(String unit) {
    _storeTimeUnit = unit;
    update();
  }

  void storeStatusChange(double value, {bool isUpdate = true}) {
    _storeStatus = value;
    if (isUpdate) {
      update();
    }
  }

  void selectModuleIndex(int? index, {bool canUpdate = true}) {
    _selectedModuleIndex = index;
    if (canUpdate) {
      update();
    }
  }

  void pickImage(bool isLogo, bool isRemove) async {
    if (isRemove) {
      _pickedLogo = null;
      _pickedCover = null;
    } else {
      if (isLogo) {
        _pickedLogo =
            await ImagePicker().pickImage(source: ImageSource.gallery);
      } else {
        _pickedCover =
            await ImagePicker().pickImage(source: ImageSource.gallery);
      }
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

  /// Clean up address by removing redundant parts like "الرياض" (Riyadh)
  String _cleanAddress(String address) {
    if (address.isEmpty) return address;

    // Remove redundant "الرياض" (Riyadh) from the end
    String cleanedAddress = address;

    // Remove "، الرياض" (comma + Riyadh) from the end
    if (cleanedAddress.endsWith('، الرياض')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 7);
    }

    // Remove "الرياض" (Riyadh) from the end
    if (cleanedAddress.endsWith('الرياض')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 5);
    }

    // Remove "، السعودية" (comma + Saudi Arabia) from the end
    if (cleanedAddress.endsWith('، السعودية')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 9);
    }

    // Remove "السعودية" (Saudi Arabia) from the end
    if (cleanedAddress.endsWith('السعودية')) {
      cleanedAddress = cleanedAddress.substring(0, cleanedAddress.length - 7);
    }

    // Clean up any trailing commas or spaces
    cleanedAddress = cleanedAddress.trim();
    if (cleanedAddress.endsWith(',')) {
      cleanedAddress =
          cleanedAddress.substring(0, cleanedAddress.length - 1).trim();
    }

    return cleanedAddress;
  }

  Future<void> getZoneList() async {
    _pickedLogo = null;
    _pickedCover = null;
    _selectedZoneIndex = 0;
    _restaurantLocation = null;
    _zoneIds = null;
    _hasZoneError = false;
    
    final List<ZoneDataModel>? zones =
        await storeRegistrationServiceInterface.getZoneList();
    
    // ✅ BACKEND CONTRACT: Guard against empty zone list (prevents RangeError)
    // This can happen if backend returns 304 Not Modified with empty cache
    if (zones == null || zones.isEmpty) {
      debugPrint('❌ getZoneList: Zone list is null or empty - backend must return zones');
      debugPrint('   This can happen if backend returns 304 Not Modified with empty cache');
      _hasZoneError = true;
      _zoneList = [];
      update();
      return;
    }
    
    _zoneList = [];
    _zoneList!.addAll(zones);
    
    // ✅ BACKEND CONTRACT: Guard before accessing zones[0]
    if (_zoneList!.isEmpty) {
      debugPrint('❌ getZoneList: Zone list is empty after adding - backend contract violation');
      _hasZoneError = true;
      update();
      return;
    }
    
    final defaultLocation =
        Get.find<SplashController>().configModel?.defaultLocation;
    final lat = double.tryParse(defaultLocation?.lat ?? '0') ?? 0;
    final lng = double.tryParse(defaultLocation?.lng ?? '0') ?? 0;
    await setLocation(
      LatLng(lat, lng),
      forStoreRegistration: true,
    );

    final int? selectedZoneId = (_selectedZoneIndex != null &&
            _selectedZoneIndex! >= 0 &&
            _selectedZoneIndex! < _zoneList!.length)
        ? _zoneList![_selectedZoneIndex!].id
        : _zoneList!.first.id;

    await getModules(selectedZoneId);
    update();
  }

  Future<void> setLocation(LatLng location,
      {bool forStoreRegistration = false, int? zoneId}) async {
    final ZoneResponseModel response = await locationServiceInterface.getZone(
        location.latitude.toString(), location.longitude.toString(),
        handleError: true);

    final String rawAddress = await Get.find<LocationController>()
        .getAddressFromGeocode(LatLng(location.latitude, location.longitude));

    // Clean up the address by removing redundant parts
    _storeAddress = _cleanAddress(rawAddress);
    if (response.isSuccess && response.zoneIds.isNotEmpty) {
      _restaurantLocation = location;
      _zoneIds = response.zoneIds;

      // Set inZone based on whether location is in any available zone
      _inZone = true;
      debugPrint(
          '🟢 StoreRegistration: Location is in zone, setting inZone = true');

      // If specific zoneId is provided, double-check with that zone
      if (zoneId != null) {
        final bool inSpecificZone =
            await storeRegistrationServiceInterface.checkInZone(
            location.latitude.toString(),
            location.longitude.toString(),
            zoneId);
        // Fallback to zoneIds from getZone response to avoid false negatives.
        _inZone = inSpecificZone || response.zoneIds.contains(zoneId);
        debugPrint(
            '🟢 StoreRegistration: Zone check for zoneId $zoneId returned: $_inZone');
      }

      // _selectedZoneIndex = storeRegistrationServiceInterface.prepareSelectedZoneIndex(_zoneIds, _zoneList);
      for (int index = 0; index < zoneList!.length; index++) {
        if (zoneIds!.contains(zoneList![index].id)) {
          _selectedZoneIndex = index;
          break;
        }
      }
    } else {
      _restaurantLocation = null;
      _zoneIds = null;
      _inZone = false;
      debugPrint(
          '🔴 StoreRegistration: Location is outside zone, setting inZone = false');
    }
    debugPrint('🔄 StoreRegistration: Final inZone value: $_inZone');
    update();
  }

  Future<void> getModules(int? zoneId) async {
    final List<ModuleModel>? modules =
        await storeRegistrationServiceInterface.getModules(zoneId);
    if (modules != null && modules.isNotEmpty) {
      _moduleList = [];
      _moduleList!.addAll(modules);

      final int firstNonParcelIndex =
          _moduleList!.indexWhere((module) => module.moduleType != 'parcel');
      _selectedModuleIndex = firstNonParcelIndex != -1 ? firstNonParcelIndex : 0;
      await getPackageList(
        isUpdate: false,
        moduleId: _moduleList![_selectedModuleIndex!].id,
      );
    } else {
      _moduleList = [];
      _selectedModuleIndex = -1;
    }
    update();
  }

  void resetStoreRegistration() {
    _pickedLogo = null;
    _pickedCover = null;
    _selectedModuleIndex = -1;
    _selectedModuleIndex = -1;
    _storeMinTime = '--';
    _storeMaxTime = '--';
    _storeTimeUnit = 'minute';
    update();
  }

  Future<void> registerStore(StoreBodyModel storeBody) async {
    _isLoading = true;
    update();
    final Response<dynamic> response =
        await storeRegistrationServiceInterface.registerStore(
            storeBody, _pickedLogo, _pickedCover);

    Map<String, dynamic>? bodyMap;
    final dynamic body = response.body;
    if (body is Map<String, dynamic>) {
      bodyMap = body;
    } else if (body is String && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          bodyMap = decoded;
        }
      } catch (_) {
        bodyMap = null;
      }
    }

    final bool hasErrors = bodyMap?['errors'] is List &&
        (bodyMap?['errors'] as List).isNotEmpty;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        !hasErrors) {
      Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(true);
      final int? storeId = bodyMap?['store_id'] as int?;
      final int? packageId = bodyMap?['package_id'] as int?;
      if (storeId == null) {
        debugPrint(
            'Store registration response missing store_id. body: ${response.body}');
      } else if (packageId == null) {
        Get.find<BusinessController>()
            .submitBusinessPlan(storeId: storeId, packageId: null);
      } else {
        Get.toNamed<String>(RouteHelper.getSubscriptionPaymentRoute(
          storeId: storeId,
          packageId: packageId,
        ));
      }
      // Get.offAllNamed(RouteHelper.getBusinessPlanRoute(storeId, packageId));
    }
    _isLoading = false;
    update();
  }

  void resetBusiness() {
    _businessIndex =
        Get.find<SplashController>().configModel!.commissionBusinessModel == 0
            ? 1
            : 0;
    _activeSubscriptionIndex = 0;
    _businessPlanStatus = 'business';
    // _isFirstTime = true;
    _paymentIndex =
        Get.find<SplashController>().configModel!.subscriptionFreeTrialStatus ??
                false
            ? 1
            : 0;
  }

  Future<void> getPackageList({bool isUpdate = true, int? moduleId}) async {
    _packageModel = await storeRegistrationServiceInterface.getPackageList(
        moduleId: moduleId);
    if (isUpdate) {
      update();
    }
  }

  void changeDigitalPaymentName(String? name, {bool canUpdate = true}) {
    _digitalPaymentName = name;
    if (canUpdate) {
      update();
    }
  }

  void setPaymentIndex(int index) {
    _paymentIndex = index;
    update();
  }

  void setBusiness(int business) {
    _activeSubscriptionIndex = 0;
    _businessIndex = business;
    update();
  }

  void setBusinessStatus(String status) {
    _businessPlanStatus = status;
    update();
  }

  void selectSubscriptionCard(int index) {
    _activeSubscriptionIndex = index;
    update();
  }
}
