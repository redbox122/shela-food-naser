import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/location/domain/models/delivery_man_last_location.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/services/location_service_interface.dart';
import 'package:sixam_mart/features/location/widgets/module_dialog_widget.dart';
import 'package:sixam_mart/features/location/widgets/service_area_dialog_widget.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/core/cache/hive_cache_config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// 🎯 Zone Status Enum - Single source of truth for zone validation
enum ZoneStatus {
  inside,
  outside,
}

class LocationController extends GetxController implements GetxService {
  final LocationServiceInterface locationServiceInterface;

  LocationController({required this.locationServiceInterface});

  // 🔥 DEFAULT LOCATION: Fixed point for users without location or outside zones
  // This is the fallback location that users are redirected to when outside service area
  static const LatLng DEFAULT_FALLBACK_LOCATION = LatLng(
    24.581458227121935, // Default latitude
    46.60091131925583, // Default longitude
  );

  /// Create a Position from latitude/longitude with default placeholder values
  /// for fields not relevant to geocoding (altitude, heading, speed, etc.).
  static Position positionFromLatLng(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 1,
      heading: 1,
      speed: 1,
      speedAccuracy: 1,
      altitudeAccuracy: 1,
      headingAccuracy: 1,
    );
  }

//

  LocationDeliveryModel? _LocationDelivery_man_Model;
  LocationDeliveryModel get LocationDelivery_man_Model =>
      _LocationDelivery_man_Model!;

//

  Position _position = positionFromLatLng(0, 0);
  Position get position => _position;

  Position _pickPosition = positionFromLatLng(0, 0);
  Position get pickPosition => _pickPosition;

  bool _loading = false;
  bool get loading => _loading;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _address = '';
  String? get address => _address;

  String? _pickAddress = '';
  String? get pickAddress => _pickAddress;

  bool _inZone = false;
  bool get inZone => _inZone;

  // 🎯 Zone Status - Single source of truth
  ZoneStatus _zoneStatus = ZoneStatus.outside;
  ZoneStatus get zoneStatus => _zoneStatus;

  // 🎯 Guard to prevent redirect loops
  bool _isRedirecting = false;
  bool get isRedirecting => _isRedirecting;

  // 🔥 CRITICAL LOOP PREVENTION: Zone correction in progress flag
  // Prevents zone validation during auto-move correction to break the loop
  bool _isZoneCorrectionInProgress = false;
  bool get isZoneCorrectionInProgress => _isZoneCorrectionInProgress;

  // 🔥 UX FIX: Dialog cooldown timer - allows dialog every 10 seconds
  // User can move outside zone multiple times, dialog shows with 10s cooldown
  DateTime? _lastDialogShownTime;
  static const Duration _dialogCooldown = Duration(seconds: 10);

  bool get canShowZoneDialog {
    if (_lastDialogShownTime == null) return true;
    final now = DateTime.now();
    final timeSinceLastDialog = now.difference(_lastDialogShownTime!);
    return timeSinceLastDialog >= _dialogCooldown;
  }

  // 🎯 UX Flags: Track user location state for smart notifications
  bool _wasInsideZoneInitially = false;
  bool get wasInsideZoneInitially => _wasInsideZoneInitially;
  bool _hasUserConfirmedLocation = false;
  bool get hasUserConfirmedLocation => _hasUserConfirmedLocation;

  // 🔥 CRITICAL: Location confirmation flag - prevents premature zone validation
  // Zone validation should ONLY happen AFTER user explicitly confirms their location
  bool _isLocationConfirmed = false;
  bool get isLocationConfirmed => _isLocationConfirmed;

  // 🎯 Nearest allowed point (inside any zone)
  LatLng? _nearestAllowedPoint;
  LatLng? get nearestAllowedPoint => _nearestAllowedPoint;

  int _zoneID = 0;
  int get zoneID => _zoneID;

  bool _buttonDisabled = true;
  bool get buttonDisabled => _buttonDisabled;

  bool _showLocationSuggestion = true;
  bool get showLocationSuggestion => _showLocationSuggestion;

  bool _updateAddAddressData = true;
  bool _changeAddress = true;
  // ⚠️ DEPRECATED: skipZoneValidation flag - kept for backward compatibility
  // Zone validation is now mandatory and handled by backend API
  // This flag may still be used in some legacy code paths but should be removed in future
  bool _skipZoneValidation = false;
  bool _isInitialCameraIdle =
      true; // Track first camera idle to skip dialog on initial load

  int _addressTypeIndex = 0;
  int get addressTypeIndex => _addressTypeIndex;

  final List<String?> _addressTypeList = ['home', 'office', 'others'];
  List<String?> get addressTypeList => _addressTypeList;

  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  List<PredictionModel> _predictionList = [];
  List<PredictionModel> get predictionList => _predictionList;

  Set<Polygon> _zonePolygons = {};
  Set<Polygon> get zonePolygons => _zonePolygons;

  bool _loadingZones = false;
  bool get loadingZones => _loadingZones;

  List<ZoneDataModel> _zones = [];
  List<ZoneDataModel> get zones => _zones;

  // 🔥 UX FALLBACK: Allow proceed without zone polygon match if zones exist but have no coordinates
  // 🗑️ REMOVED: _allowProceedWithoutZones flag
  // Zones without coordinates (polygons) are invalid - backend data issue
  // Flutter must block proceed if zones exist but have no coordinates

  // 🔥 GUARD: Prevent opening PickMap multiple times
  bool _pickMapOpened = false;

  /// Reset PickMap guard (call when returning from PickMap or changing location)
  void resetPickMapGuard() {
    _pickMapOpened = false;
    debugPrint('🔄 PickMap guard reset');
  }

  // 🔥 OPTIMIZATION: Disable zone checks after location is confirmed
  // Once user confirms location, no need to keep checking zones
  bool _shouldCheckZone = true;
  bool get shouldCheckZone => _shouldCheckZone;

  /// Disable zone checks after location confirmation (call after saveAddressAndNavigate succeeds)
  void disableZoneChecks() {
    _shouldCheckZone = false;
    debugPrint('⏭️ Zone checks disabled after location confirmation');
  }

  /// Re-enable zone checks (call when location changes or user explicitly requests)
  void enableZoneChecks() {
    _shouldCheckZone = true;
    debugPrint('✅ Zone checks re-enabled');
  }

  // 🔥 OPTIMIZATION: Prevent multiple home reloads after location change
  bool _homeReloadTriggered = false;

  /// Trigger home reload once after location change
  void triggerHomeReloadOnce(BuildContext context) {
    if (_homeReloadTriggered) {
      debugPrint('⏭️ Home reload already triggered - skipping');
      return;
    }
    _homeReloadTriggered = true;
    debugPrint(
        '🔄 LocationController: Location changed - triggering home data reload (once)');
    try {
      HomeScreen.loadData(context, true);
    } catch (e) {
      debugPrint(
          '⚠️ Error loading home data (location may be outside zone): $e');
    }
  }

  /// Reset home reload flag (call when location changes significantly)
  void resetHomeReloadFlag() {
    _homeReloadTriggered = false;
    debugPrint('🔄 Home reload flag reset');
  }

  // Store largest zone polygon points for boundary checking
  List<LatLng>? _largestZonePoints;
  List<LatLng>? get largestZonePoints => _largestZonePoints;

  // Store center of largest zone for returning to default location
  LatLng? _largestZoneCenter;
  LatLng? get largestZoneCenter => _largestZoneCenter;

  // ⚡ OPTIMIZATION: Track last geocode call to prevent duplicate API calls
  LatLng? _lastGeocodeLatLng;
  DateTime? _lastGeocodeTime;
  static const Duration _geocodeCacheTTL =
      Duration(minutes: 15); // Cache geocode for 15 minutes
  String? _lastSavedZoneCacheKey;
  String? _lastSavedZonePayloadSignature;

  void hideSuggestedLocation() {
    _showLocationSuggestion = !_showLocationSuggestion;
  }

  void setAddressTypeIndex(int index, {bool isUpdate = true}) {
    _addressTypeIndex = index;
    if (isUpdate) {
      update();
    }
  }

  void disableButton() {
    _buttonDisabled = true;
    _inZone = true;
    Future.microtask(() => update());
  }

  void setAddAddressData() {
    _position = _pickPosition;
    _address = _pickAddress;
    _updateAddAddressData = false;
    Future.microtask(() => update());
  }

  void setUpdateAddress(AddressModel address) {
    _position = positionFromLatLng(
      double.parse(address.latitude!),
      double.parse(address.longitude!),
    );
    _address = address.address;
    _addressTypeIndex = _addressTypeList.indexOf(address.addressType);
  }

  void setPickData() {
    _pickPosition = _position;
    _pickAddress = _address;
    // 🔧 Reset initial camera idle flag when entering pick map screen
    resetInitialCameraIdle();
  }

  /// 🔥 UI-ONLY: Update pick position and address from LatLng (for PickMapScreen)
  /// This method is UI-only - no GPS requests, no zone validation, no navigation
  /// 🎯 PERFORMANCE: Only updates if position actually changed (prevents unnecessary rebuilds)
  Future<void> updatePickPositionFromLatLng(LatLng latLng) async {
    try {
      // 🎯 PERFORMANCE: Check if position actually changed (within 5m tolerance)
      final double latDiff = (_pickPosition.latitude - latLng.latitude).abs();
      final double lngDiff = (_pickPosition.longitude - latLng.longitude).abs();
      const double tolerance = 0.00005; // ~5 meters

      if (latDiff < tolerance &&
          lngDiff < tolerance &&
          _pickAddress != null &&
          _pickAddress!.isNotEmpty) {
        // Position hasn't changed significantly - skip update
        debugPrint(
            '⏭️ updatePickPositionFromLatLng: Position unchanged, skipping update');
        return;
      }

      // Update pick position directly
      _pickPosition = positionFromLatLng(
        latLng.latitude,
        latLng.longitude,
      );

      // Get address from geocode (UI display only - no zone check)
      _pickAddress =
          await locationServiceInterface.getAddressFromGeocode(latLng);

      // ✅ UI-ONLY RULE: Do NOT auto-redirect or show dialogs/snackbars here.
      // PickMapScreen is a selection UI; zone validation happens on confirm via API.
      _inZone = _pickAddress != null && _pickAddress!.isNotEmpty;
      _buttonDisabled = _pickAddress == null || _pickAddress!.isEmpty;
      Future.microtask(() => update());
    } catch (e) {
      debugPrint('⚠️ Error updating pick position: $e');
    }
  }

  /// Reset the initial camera idle flag - prevents dialog from showing on map initialization
  void resetInitialCameraIdle() {
    _isInitialCameraIdle = true;
  }

  void setMapController(GoogleMapController mapController) {
    _mapController = mapController;
    debugPrint('🗺️ Map controller set successfully');
  }

  void resetSkipZoneValidation() {
    _skipZoneValidation = false;
    debugPrint('📍 Reset skip zone validation flag');
  }

  void setSkipZoneValidation(bool value) {
    _skipZoneValidation = value;
    debugPrint('📍 Set skip zone validation flag to: $value');
  }

  bool get skipZoneValidation => _skipZoneValidation;

  /// Set zone ID directly (used for pre-emptive injection from Hive)
  void setZoneID(int zoneId) {
    _zoneID = zoneId;
    debugPrint('📍 Set zone ID to: $zoneId');
  }

  /// Set in-zone status directly (used for optimistic rendering)
  void setInZone(bool inZone) {
    _inZone = inZone;
    debugPrint('📍 Set in-zone status to: $inZone');
    Future.microtask(() => update());
  }

  /// Enable confirm button (when zone is validated by API)
  void enableButton() {
    _buttonDisabled = false;
    Future.microtask(() => update());
  }

  Future<AddressModel> getCurrentLocation(bool fromAddress,
      {GoogleMapController? mapController,
      LatLng? defaultLatLng,
      bool notify = true,
      bool skipZoneValidation = false,
      bool forceRefresh = false}) async {
    debugPrint(
        '📍 Starting getCurrentLocation - fromAddress: $fromAddress, forceRefresh: $forceRefresh');
    _loading = true;
    // ⚡ TASK 3: Wrap update() in microtask to avoid setState during build
    if (notify) {
      Future.microtask(() => update());
    }
    AddressModel addressModel;

    try {
      debugPrint('📍 Getting position from location service...');

      // Add additional safety checks
      if (Get.find<SplashController>().configModel?.defaultLocation == null) {
        throw Exception('Config model or default location is null');
      }

      final Position myPosition = await locationServiceInterface.getPosition(
          defaultLatLng,
          LatLng(
            double.tryParse(Get.find<SplashController>()
                        .configModel!
                        .defaultLocation!
                        .lat ??
                    '0') ??
                0.0,
            double.tryParse(Get.find<SplashController>()
                        .configModel!
                        .defaultLocation!
                        .lng ??
                    '0') ??
                0.0,
          ),
          skipZoneValidation: skipZoneValidation);
      debugPrint(
          '📍 Position obtained: ${myPosition.latitude}, ${myPosition.longitude}');

      fromAddress ? _position = myPosition : _pickPosition = myPosition;

      locationServiceInterface.handleMapAnimation(mapController, myPosition);

      // ⚡ OPTIMIZATION: Check if geocode is needed (prevent duplicate API calls)
      final currentLatLng = LatLng(myPosition.latitude, myPosition.longitude);
      String addressFromGeocode;

      if (!forceRefresh &&
          _lastGeocodeLatLng != null &&
          _lastGeocodeTime != null &&
          _address != null &&
          _address!.isNotEmpty) {
        // Check if coordinates are the same (within 50 meters)
        final distance = Geolocator.distanceBetween(
          _lastGeocodeLatLng!.latitude,
          _lastGeocodeLatLng!.longitude,
          currentLatLng.latitude,
          currentLatLng.longitude,
        );

        final cacheAge = DateTime.now().difference(_lastGeocodeTime!);

        if (distance < 50 && cacheAge < _geocodeCacheTTL) {
          // Use cached address - skip geocode API call
          addressFromGeocode = fromAddress ? _address! : _pickAddress!;
          debugPrint(
              '✅ Geocode cache HIT (distance: ${distance.toStringAsFixed(0)}m, age: ${cacheAge.inMinutes}min) - skipping API call');
        } else {
          // Coordinates changed or cache expired - call geocode
          debugPrint(
              '📍 Getting address from geocode (cache miss: distance=${distance.toStringAsFixed(0)}m, age=${cacheAge.inMinutes}min)...');
          addressFromGeocode = await getAddressFromGeocode(currentLatLng);
          _lastGeocodeLatLng = currentLatLng;
          _lastGeocodeTime = DateTime.now();
          debugPrint('📍 Address from geocode: $addressFromGeocode');
        }
      } else {
        // No cache - call geocode
        debugPrint('📍 Getting address from geocode...');
        addressFromGeocode = await getAddressFromGeocode(currentLatLng);
        _lastGeocodeLatLng = currentLatLng;
        _lastGeocodeTime = DateTime.now();
        debugPrint('📍 Address from geocode: $addressFromGeocode');
      }

      fromAddress
          ? _address = addressFromGeocode
          : _pickAddress = addressFromGeocode;

      if (skipZoneValidation) {
        debugPrint('📍 Skipping zone validation as requested');
        _buttonDisabled = false;

        addressModel = AddressModel(
          latitude: myPosition.latitude.toString(),
          longitude: myPosition.longitude.toString(),
          addressType: 'others',
          zoneId: 0, // Set to 0 when skipping zone validation
          zoneIds: [],
          address: addressFromGeocode,
          zoneData: [],
          areaIds: [],
        );
      } else {
        debugPrint('📍 Getting zone information...');
        final ZoneResponseModel responseModel = await getZone(
            myPosition.latitude.toString(),
            myPosition.longitude.toString(),
            true,
            handleError: true);
        debugPrint('📍 Zone response success: ${responseModel.isSuccess}');
        _buttonDisabled = !responseModel.isSuccess;

        addressModel = AddressModel(
          latitude: myPosition.latitude.toString(),
          longitude: myPosition.longitude.toString(),
          addressType: 'others',
          zoneId: responseModel.isSuccess ? responseModel.zoneIds[0] : 0,
          zoneIds: responseModel.zoneIds,
          address: addressFromGeocode,
          zoneData: responseModel.zoneData,
          areaIds: responseModel.areaIds,
        );
      }
      debugPrint('✅ getCurrentLocation completed successfully');
    } catch (e) {
      // If there's an error, create a fallback address model with default coordinates
      debugPrint('❌ Error in getCurrentLocation: $e');
      final defaultLat =
          Get.find<SplashController>().configModel?.defaultLocation?.lat ??
              '24.604301879077966';
      final defaultLng =
          Get.find<SplashController>().configModel?.defaultLocation?.lng ??
              '46.59593515098095';

      addressModel = AddressModel(
        latitude: defaultLat,
        longitude: defaultLng,
        addressType: 'others',
        zoneId: 0,
        zoneIds: [],
        address: 'Default Location',
        zoneData: [],
        areaIds: [],
      );
      _buttonDisabled = true;
      debugPrint('📍 Using fallback location: $defaultLat, $defaultLng');
    } finally {
      // ⚡ TASK 2: Safety net - ensure _loading is always reset, even if API fails
      _loading = false;
      // ⚡ TASK 3: Wrap update() in microtask to avoid setState during build
      Future.microtask(() => update());
    }
    return addressModel;
  }

  Future<String> getAddressFromGeocode(LatLng latLng) async {
    return await locationServiceInterface.getAddressFromGeocode(latLng);
  }

  /// Set pick address directly (used when we have a known address)
  void setPickAddress(String address) {
    _pickAddress = address;
    debugPrint('📍 LocationController: Pick address set to: $address');
    Future.microtask(() => update());
  }

  Future<ZoneResponseModel> getZone(String? lat, String? lng, bool markerLoad,
      {bool updateInAddress = false, bool handleError = false}) async {
    if (markerLoad) {
      _loading = true;
    } else {
      _isLoading = true;
    }
    // ⚡ TASK 3: Wrap update() in microtask to avoid setState during build
    if (!updateInAddress) {
      Future.microtask(() => update());
    }
    ZoneResponseModel responseModel;
    try {
      responseModel = await locationServiceInterface.getZone(lat, lng,
          handleError: handleError);
      _inZone = responseModel.isSuccess;
      _zoneID = responseModel.zoneIds.isNotEmpty ? responseModel.zoneIds[0] : 0;
      if (updateInAddress && responseModel.isSuccess) {
        // 🎯 FIX: Null-safe address access
        final AddressModel? address =
            AddressHelper.getUserAddressFromSharedPref();
        if (address != null) {
          address.zoneData = responseModel.zoneData;
          AddressHelper.saveUserAddressInSharedPref(address);
        } else {
          debugPrint(
              '⚠️ LocationController: No address found in SharedPreferences');
        }
      }

      // ⚡ TASK 1: Save zone data to Hive for instant loading on module switch
      if (responseModel.isSuccess && lat != null && lng != null) {
        try {
          final cacheKey = 'zone_${lat}_$lng';
          final payloadSignature = 'zoneIds:${responseModel.zoneIds.join(',')}|'
              'areaIds:${responseModel.areaIds.join(',')}|'
              'zoneCount:${responseModel.zoneData.length}|'
              'status:${responseModel.status ?? ''}';

          if (_lastSavedZoneCacheKey == cacheKey &&
              _lastSavedZonePayloadSignature == payloadSignature) {
            if (kDebugMode) {
              debugPrint(
                  '⏭️ LocationController: Duplicate zone cache payload skipped for key $cacheKey');
            }
          } else {
            final zoneDataJson = {
              'isSuccess': responseModel.isSuccess,
              'zoneIds': responseModel.zoneIds,
              'zoneData':
                  responseModel.zoneData.map((z) => z.toJson()).toList(),
              'areaIds': responseModel.areaIds,
              'message': responseModel.message,
              'statusCode': responseModel.status,
            };
            await HiveHomeCacheService().saveZoneData(cacheKey, zoneDataJson);
            _lastSavedZoneCacheKey = cacheKey;
            _lastSavedZonePayloadSignature = payloadSignature;
            if (kDebugMode) {
              debugPrint(
                  '💾 LocationController: Saved zone data to Hive for key $cacheKey');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ LocationController: Error saving zone data to Hive - $e');
          }
          // Don't throw - continue even if cache save fails
        }
      }
    } finally {
      // ⚡ TASK 2: Safety net - ensure loading flags are always reset
      if (markerLoad) {
        _loading = false;
      } else {
        _isLoading = false;
      }
      // ⚡ TASK 3: Wrap update() in microtask to avoid setState during build
      Future.microtask(() => update());
    }
    return responseModel;
  }

  Future<void> syncZoneData({bool shouldRedirect = true}) async {
    // Check if we should skip zone validation (when using current location)
    if (_skipZoneValidation) {
      debugPrint(
          '📍 syncZoneData: Skipping zone validation due to current location usage');
      return;
    }

    final AddressModel? savedAddress =
        AddressHelper.getUserAddressFromSharedPref();

    if (savedAddress == null) {
      // إذا لم يكن هناك عنوان محفوظ، قم بتوجيه المستخدم لاختيار العنوان
      if (shouldRedirect) {
        Get.toNamed(RouteHelper.getAccessLocationRoute(RouteHelper.splash));
      }
      return;
    }

    // Check if address was saved without zone validation (user explicitly chose current location)
    // If zoneId is 0 or zoneIds is empty, it means user saved address without zone validation
    // We should preserve these addresses even if zone API fails
    final bool wasSavedWithoutZoneValidation =
        (savedAddress.zoneId == 0 || savedAddress.zoneId == null) &&
            (savedAddress.zoneIds == null || savedAddress.zoneIds!.isEmpty);

    final ZoneResponseModel response = await getZone(
        savedAddress.latitude, savedAddress.longitude, false,
        updateInAddress: true);

    if (!response.isSuccess || response.zoneIds.isEmpty) {
      // If API failed, don't clear address (could be temporary network issue)
      if (!response.isSuccess) {
        debugPrint(
            '⚠️ syncZoneData: Zone API call failed - preserving address');
        return;
      }

      // If API succeeded but returned empty zones, only clear if address was previously validated
      // Don't clear addresses that were saved without zone validation by user choice
      if (!wasSavedWithoutZoneValidation) {
        debugPrint(
            '⚠️ syncZoneData: Zone validation returned empty zones for previously validated address - clearing');
        AddressHelper.clearAddressFromSharedPref();
        if (shouldRedirect) {
          Get.toNamed(RouteHelper.getAccessLocationRoute(RouteHelper.splash));
        }
      } else {
        debugPrint(
            '✅ syncZoneData: Preserving user-saved address (was saved without zone validation)');
      }
    } else {
      // Update address with zone data
      savedAddress.zoneId = response.zoneIds[0];
      savedAddress.zoneIds = [...response.zoneIds];
      savedAddress.zoneData = [...response.zoneData];
      savedAddress.areaIds = [...response.areaIds];

      await AddressHelper.saveUserAddressInSharedPref(savedAddress);
      debugPrint('✅ syncZoneData: Zone data updated successfully');
    }

    update();
  }

  void showServiceAreaDialog() {
    Get.dialog(
      const ServiceAreaDialogWidget(),
    );
  }

  void updatePosition(CameraPosition? position, bool fromAddress) async {
    if (_updateAddAddressData && position != null) {
      // Don't show loading state - polygon provides instant visual feedback
      debugPrint('\x1B[32m  /${position.target.latitude}  \x1B[0m');
      debugPrint('\x1B[32m  /${position.target.longitude}  \x1B[0m');

      // Skip zone validation if flag is set
      if (_skipZoneValidation) {
        debugPrint('📍 Skipping zone validation in updatePosition');
        _buttonDisabled = false;
        _changeAddress = true;
        Future.microtask(() => update());
        return;
      }

      // ⚡ TASK 3: Use API as ultimate truth for zone validation
      // First, do a quick polygon check for instant visual feedback
      bool polygonCheckInside = false;
      if (_largestZonePoints != null && _largestZonePoints!.isNotEmpty) {
        polygonCheckInside = isPointInsideZone(
            position.target.latitude, position.target.longitude);
      } else {
        // If no polygons available, we must use API check
        debugPrint('⚠️ No zone polygons available - using API validation only');
      }

      // ⚡ TASK 3: Always validate with API (get-zone-id) as ultimate truth
      // This ensures accuracy even if polygons are missing or outdated
      final ZoneResponseModel apiZoneResponse = await getZone(
          position.target.latitude.toString(),
          position.target.longitude.toString(),
          false); // Don't show loading spinner for this check

      final bool apiCheckInside =
          apiZoneResponse.isSuccess && apiZoneResponse.zoneIds.isNotEmpty;

      // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
      // If zones exist but no polygons, it's okay - user can still proceed if API confirms location
      if (_zones.isNotEmpty && _zonePolygons.isEmpty) {
        debugPrint(
            '⚠️ Zones exist (${_zones.length}) but no polygons - polygons are optional (visual only)');
        debugPrint('ℹ️ Zone validation uses API (get-zone-id) - not polygons');
        debugPrint('   - API check: ${apiCheckInside ? 'INSIDE' : 'OUTSIDE'}');
        // Don't block - polygons are optional, API validation is what matters
      }

      // 🔧 FIX: Trust polygon when available - if user sees green polygon, allow selection
      // Only show "outside" dialog if polygon says OUTSIDE (when polygon exists)
      // If no polygon, fall back to API check
      bool isOutside;
      if (_largestZonePoints != null && _largestZonePoints!.isNotEmpty) {
        // If we have polygon, trust polygon check (user sees green = INSIDE)
        isOutside = !polygonCheckInside;
        debugPrint(
            "📍 Using polygon check: ${polygonCheckInside ? 'INSIDE' : 'OUTSIDE'} (API: ${apiCheckInside ? 'INSIDE' : 'OUTSIDE'})");
      } else {
        // If no polygon, use API as fallback
        isOutside = !apiCheckInside;
        debugPrint(
            "📍 No polygon available - using API check: ${apiCheckInside ? 'INSIDE' : 'OUTSIDE'}");
      }

      // 🔥 CRITICAL FIX: Never show dialog or open PickMap if we're already inside PickMapScreen
      // PickMapScreen is a selection screen - it should NEVER reopen itself
      final bool isInsidePickMapScreen =
          Get.currentRoute.contains('pick-map') ||
              Get.currentRoute.contains('my-location');

      if (isInsidePickMapScreen) {
        debugPrint(
            '⏸️ Inside PickMapScreen - suppressing zone validation dialog');
        // Just update button state - don't show dialog or navigate
        if (!isOutside) {
          _buttonDisabled = false;
          _changeAddress = true;
          Future.microtask(() => update());
        }
        return;
      }

      // 🔧 CRITICAL FIX: Skip dialog on initial camera idle (map initialization)
      // Only show dialog when user actively moves map to outside location
      // AND never show dialog if PickMap is already opened
      final bool shouldShowDialog =
          isOutside && !_isInitialCameraIdle && !_pickMapOpened;

      // 🔧 Mark that initial camera idle has passed - future moves will trigger dialog
      // This must happen AFTER checking the flag, but BEFORE showing dialog
      if (_isInitialCameraIdle) {
        _isInitialCameraIdle = false;
        debugPrint(
            '📍 Initial camera idle complete - dialog will show on future outside moves');
      }

      if (shouldShowDialog) {
        debugPrint(
            '🚫 Location is outside service zone: ${position.target.latitude}, ${position.target.longitude}');
        debugPrint("   - API check: ${apiCheckInside ? 'INSIDE' : 'OUTSIDE'}");
        if (_largestZonePoints != null && _largestZonePoints!.isNotEmpty) {
          debugPrint(
              "   - Polygon check: ${polygonCheckInside ? 'INSIDE' : 'OUTSIDE'}");
        }

        // Show dialog with Shella delivery image
        Get.dialog(
          ServiceAreaDialogWidget(
            onConfirm: () async {
              Get.back(); // Close dialog
              await Future.delayed(const Duration(milliseconds: 300));
              moveToDefaultLocation(); // Move camera back to default
            },
          ),
        );

        _buttonDisabled = true;
        Future.microtask(() => update());
        return; // Don't proceed with location update
      }

      debugPrint('✅ Location is inside service zone (API validated)');

      if (fromAddress) {
        _position = positionFromLatLng(
          position.target.latitude,
          position.target.longitude,
        );
      } else {
        _pickPosition = positionFromLatLng(
          position.target.latitude,
          position.target.longitude,
        );
      }
      // ⚡ TASK 3: We already have API response from validation above
      // Use it instead of calling getZone again (optimization)
      final ZoneResponseModel responseModel = apiZoneResponse;
      _buttonDisabled = !responseModel.isSuccess;
      if (_changeAddress) {
        final String addressFromGeocode = await getAddressFromGeocode(
            LatLng(position.target.latitude, position.target.longitude));

        fromAddress
            ? _address = addressFromGeocode
            : _pickAddress = addressFromGeocode;
      } else {
        _changeAddress = true;
      }

      Future.microtask(() => update());
    } else {
      _updateAddAddressData = true;
    }
  }

  /// 🔥 CRITICAL: Mark location as confirmed when saving address from PickMapScreen
  void saveAddressAndNavigate(BuildContext context, AddressModel? address,
      bool fromSignUp, String? route, bool canRoute, bool isDesktop,
      {bool skipZoneValidation = false}) {
    // 🔥 CRITICAL: Mark location as confirmed when user saves address from PickMapScreen
    _isLocationConfirmed = true;
    debugPrint(
        '✅ LocationController: Location confirmed via saveAddressAndNavigate (from PickMapScreen)');

    if (skipZoneValidation) {
      debugPrint('📍 Skipping zone validation in saveAddressAndNavigate');
      // Skip zone validation and directly navigate
      autoNavigate(context, address!, fromSignUp, route, canRoute, isDesktop);
    } else {
      _prepareZoneData(
          context, address!, fromSignUp, route, canRoute, isDesktop);
    }
  }

  void _prepareZoneData(BuildContext context, AddressModel address,
      bool fromSignUp, String? route, bool canRoute, bool isDesktop) {
    getZone(address.latitude, address.longitude, false).then((response) async {
      if (!context.mounted) {
        return;
      }
      if (response.isSuccess && response.zoneIds.isNotEmpty) {
        // Only refresh cart if zone change affects cart items
        // This prevents unnecessary API calls on every location update
        final cartController = Get.find<CartController>();
        if (cartController.cartList.isNotEmpty) {
          debugPrint(
              '🔄 LocationController: Refreshing cart after zone change');
          cartController.getCartDataOnline();
        } else {
          debugPrint(
              '💾 LocationController: No cart items to refresh after zone change');
        }
        address.zoneId = response.zoneIds[0];
        address.zoneIds = [];
        address.zoneIds!.addAll(response.zoneIds);
        address.zoneData = [];
        address.zoneData!.addAll(response.zoneData);
        address.areaIds = [];
        address.areaIds!.addAll(response.areaIds);
        if (kDebugMode) {
          debugPrint('Zone IDs: ${address.zoneIds}');
        }
        // 🔥 OPTIMIZATION: Disable zone checks after successful location confirmation
        disableZoneChecks();
        autoNavigate(context, address, fromSignUp, route, canRoute, isDesktop);
      } else {
        // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
        // If zones exist but no polygons, it's okay - user can still proceed if API confirms location
        if (_zones.isNotEmpty && _zonePolygons.isEmpty) {
          debugPrint(
              '⚠️ Zones exist (${_zones.length}) but no polygons - polygons are optional (visual only)');
          debugPrint(
              'ℹ️ Zone validation uses API (get-zone-id) - not polygons');
          // Don't block - polygons are optional, API validation is what matters
        }

        // 🔥 CRITICAL GUARD: Respect Backend metadata before any redirect
        // Backend may tell us: "don't redirect yet, wait for zones to load"
        if (response.requiresZonesLoaded && !_zonesLoaded) {
          debugPrint(
              '⏸️ Backend metadata: requires_zones_loaded=true - skipping redirect');
          debugPrint(
              '   → Zones loaded: $_zonesLoaded, Zones count: ${_zones.length}');
          debugPrint('   → Waiting for zones to load before redirect');
          // Don't redirect - wait for zones to load
          disableZoneChecks();
          autoNavigate(
              context, address, fromSignUp, route, canRoute, isDesktop);
          return;
        }

        // 🔥 CRITICAL GUARD: Respect Backend metadata should_redirect flag
        if (!response.shouldRedirect) {
          debugPrint(
              '⏸️ Backend metadata: should_redirect=false - skipping redirect');
          debugPrint('   → Backend explicitly says: do not redirect');
          // Don't redirect - Backend says no
          disableZoneChecks();
          autoNavigate(
              context, address, fromSignUp, route, canRoute, isDesktop);
          return;
        }

        // 🔥 CRITICAL GUARD: Don't redirect before zones are loaded (even if metadata allows)
        if (!_zonesLoaded || _zones.isEmpty) {
          debugPrint('⏸️ Zones not loaded yet - skipping redirect');
          debugPrint(
              '   → Zones loaded: $_zonesLoaded, Zones count: ${_zones.length}');
          debugPrint('   → No redirect until zones are loaded');
          // Don't redirect - wait for zones
          disableZoneChecks();
          autoNavigate(
              context, address, fromSignUp, route, canRoute, isDesktop);
          return;
        }

        // 🔥 CRITICAL FIX: Only open PickMap if location is truly OUTSIDE zone
        // Don't open PickMap for API errors or technical issues
        // Only open PickMap if:
        // 1. API explicitly says OUTSIDE (404 = no zone found for this location)
        // 2. AND PickMap hasn't been opened already
        final bool shouldOpenPickMap =
            response.statusCode == 404 && !_pickMapOpened;

        if (shouldOpenPickMap) {
          debugPrint(
              '🚫 Location is outside service zone (404) - opening PickMap');
          _pickMapOpened = true;
          Get.toNamed(RouteHelper.getPickMapRoute(route, false));
        } else if (route == 'splash' && !_pickMapOpened) {
          // Special case: splash route always opens PickMap (first time setup)
          debugPrint(
              '📍 Splash route - opening PickMap for initial location selection');
          _pickMapOpened = true;
          Get.toNamed(RouteHelper.getPickMapRoute(route, false));
        } else if (_pickMapOpened) {
          debugPrint(
              '⏸️ PickMap already opened - skipping duplicate navigation');
        } else {
          debugPrint(
              '⚠️ Zone check failed but not opening PickMap (may be API error)');
          // Don't block user - allow proceed even if zone check failed
          // 🔥 OPTIMIZATION: Disable zone checks after location confirmation (even if zone check failed)
          disableZoneChecks();
          autoNavigate(
              context, address, fromSignUp, route, canRoute, isDesktop);
        }
      }
    });
  }

  void autoNavigate(BuildContext context, AddressModel? address,
      bool fromSignUp, String? route, bool canRoute, bool isDesktop) async {
    if (isDesktop &&
        Get.find<SplashController>().module ==
            null /* && Get.find<SplashController>().configModel!.module == null*/) {
      final List<int>? zoneIds = address!.zoneIds;
      final Map<String, String> header =
          locationServiceInterface.prepareHeader(zoneIds);
      await Get.find<SplashController>().getModules(headers: header);
      if (!context.mounted) {
        return;
      }
      if (Get.isDialogOpen!) {
        Get.back();
      }
      Get.dialog(ModuleDialogWidget(callback: () {
        _saveDataAndFirebaseConfig(
            context, address, fromSignUp, route, canRoute, isDesktop);
      }),
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.7));
    } else {
      _saveDataAndFirebaseConfig(
          context, address!, fromSignUp, route, canRoute, isDesktop);
    }
  }

  void _saveDataAndFirebaseConfig(BuildContext context, AddressModel address,
      bool fromSignUp, String? route, bool canRoute, bool isDesktop) async {
    try {
      locationServiceInterface.configureFirebaseMessaging(address);
    } catch (e) {
      debugPrint('⚠️ Error configuring Firebase messaging: $e');
      // Continue even if Firebase messaging fails
    }

    try {
      await _handleTaxiModuleCart(address);
    } catch (e) {
      debugPrint('⚠️ Error handling taxi module cart: $e');
      // Continue even if taxi cart handling fails
    }

    try {
      await AddressHelper.saveUserAddressInSharedPref(address);
    } catch (e) {
      debugPrint('⚠️ Error saving address: $e');
      // Continue even if saving address fails
    }
    if (!context.mounted) {
      return;
    }

    if (AuthHelper.isLoggedIn()) {
      try {
        if (Get.find<SplashController>().module != null) {
          await Get.find<FavouriteController>().getFavouriteList();
        } else {
          Get.find<SplashController>().getConfigData(
            context,
          );
        }
        Get.find<AuthController>().updateZone();
      } catch (e) {
        debugPrint('⚠️ Error updating user data: $e');
        // Continue even if user data update fails
      }
    }

    // ROOT-CAUSE FIX: Sync ApiClient headers with the newly saved address
    // BEFORE any home-data request fires. Without this, every API call that
    // follows (triggerHomeReloadOnce, reloadOnZoneChange, etc.) goes out with
    // zone-id=null and module-id=null, causing the backend to reject or
    // misroute the request → blank home screen on fresh install.
    if (Get.isRegistered<ApiClient>()) {
      try {
        final apiClient = Get.find<ApiClient>();
        final splashCtrl = Get.find<SplashController>();
        final int? selectedModuleId = splashCtrl.selectedModule.value?.id;
        final int? currentModuleId = splashCtrl.module?.id;
        final int? fallbackModuleId = splashCtrl.getDefaultModuleId();
        final int? resolvedModuleId =
            selectedModuleId ?? currentModuleId ?? fallbackModuleId;

        apiClient.updateHeader(
          apiClient.token,
          address.zoneIds, // real zone IDs from the chosen location
          address.areaIds, // real area IDs
          null, // keep current language
          resolvedModuleId, // force module-id sync before any home reload
          address.latitude,
          address.longitude,
        );

        final headers = apiClient.getHeader();
        if (kDebugMode) {
          debugPrint(
              '✅ LocationController: API headers synced after address save '
              '(zoneIds=${address.zoneIds}, moduleId=$resolvedModuleId)');
          debugPrint('[Diag] LocationController: Headers now => '
              'module-id=${headers[AppConstants.moduleId]}, '
              'zone-id=${headers[AppConstants.zoneId]}, '
              'latitude=${headers[AppConstants.latitude]}, '
              'longitude=${headers[AppConstants.longitude]}');
        }
      } catch (e) {
        debugPrint('⚠️ LocationController: Failed to sync API headers: $e');
      }
    }

    // 🔥 OPTIMIZATION: Trigger home reload once after location change (prevent multiple reloads)
    // This is critical for Food module to show nearest restaurants correctly
    if (!context.mounted) {
      return;
    }
    final BuildContext buildContext = context;
    triggerHomeReloadOnce(buildContext);

    // 🔧 FIX 2: Notify HomeController of zone change for reactive data loading
    if (Get.isRegistered<HomeController>()) {
      final zoneId = address.zoneId ?? 0;
      Get.find<HomeController>().reloadOnZoneChange(zoneId);
    }

    try {
      Get.find<CheckoutController>().clearPrevData();
    } catch (e) {
      debugPrint('⚠️ Error clearing checkout data: $e');
      // Continue even if clearing checkout data fails
    }

    if (Get.context != null &&
        ResponsiveHelper.isDesktop(Get.context!) &&
        AuthHelper.isLoggedIn() &&
        Get.find<SplashController>().module != null) {
      if (Get.find<ProfileController>().userInfoModel == null) {
        Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
        await Get.find<ProfileController>().getUserInfo();
        Get.back();
      }
      if (!Get.find<ProfileController>()
              .userInfoModel!
              .selectedModuleForInterest!
              .contains(Get.find<SplashController>().module!.id) &&
          (Get.find<SplashController>().module!.moduleType == 'food' ||
              Get.find<SplashController>().module!.moduleType == 'grocery' ||
              Get.find<SplashController>().module!.moduleType == 'ecommerce')) {
        await Get.toNamed(RouteHelper.getInterestRoute());
      } else {
        locationServiceInterface.handleRoute(fromSignUp, route, canRoute);
      }
    } else {
      locationServiceInterface.handleRoute(fromSignUp, route, canRoute);
    }

    // Don't reset the flag here - let it be reset after home screen loads
    // resetSkipZoneValidation();
  }

  Future<void> _handleTaxiModuleCart(AddressModel address) async {
    if (TaxiHelper.haveTaxiModule() &&
        address.zoneIds != null &&
        Get.find<TaxiCartController>().cartList.isNotEmpty) {
      final List<int> providerZones =
          Get.find<TaxiCartController>().cartList[0].provider!.pickupZoneId ??
              [];
      final List<int> zoneIds = address.zoneIds ?? [];

      if (!_hasIntersection(providerZones, zoneIds)) {
        showCustomSnackBar(
            'your_cart_has_been_cleared_as_the_selected_zone_does_not_support_the_previous_pickup_point'
                .tr,
            showDuration: 10);
        Get.find<TaxiCartController>().clearTaxiCart();
      }
    }
  }

  bool _hasIntersection(List<int> list1, List<int> list2) {
    return list1.toSet().intersection(list2.toSet()).isNotEmpty;
  }

  Future<AddressModel> setLocation(String? placeID, String? address,
      GoogleMapController? mapController) async {
    _loading = true;
    update();

    final LatLng latLng = await locationServiceInterface.getLatLng(placeID);

    _pickPosition = positionFromLatLng(
      latLng.latitude,
      latLng.longitude,
    );

    _pickAddress = address;
    _changeAddress = false;

    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 17)));
    }
    _loading = false;
    update();
    return AddressModel(
      latitude: _pickPosition.latitude.toString(),
      longitude: _pickPosition.longitude.toString(),
      addressType: 'others',
      address: _pickAddress,
    );
  }

  Future<List<PredictionModel>> searchLocation(
      BuildContext context, String text) async {
    if (text.isNotEmpty) {
      _predictionList = await locationServiceInterface.searchLocation(text);
    }
    return _predictionList;
  }

  void setPlaceMark(String address) {
    _address = address;
  }

  void checkPermission(Function onTap) async {
    locationServiceInterface.checkLocationPermission(onTap);
  }

  Future<bool> checkLocationActive() async {
    final bool isActiveLocation = await Geolocator.isLocationServiceEnabled();

    if (!isActiveLocation) {
      return false;
    }

    try {
      // الحصول على إحداثيات الموقع الافتراضي

      final splashController = Get.find<SplashController>();
      final defaultLat = double.tryParse(
              splashController.configModel?.defaultLocation?.lat ?? '0') ??
          0.0;
      final defaultLng = double.tryParse(
              splashController.configModel?.defaultLocation?.lng ?? '0') ??
          0.0;

      final Position myPosition = await locationServiceInterface.getPosition(
          null, LatLng(defaultLat, defaultLng));

      // التحقق من وجود عنوان المستخدم
      final userAddress = AddressHelper.getUserAddressFromSharedPref();

      if (userAddress?.latitude == null || userAddress?.longitude == null) {
        if (kDebugMode) {
          debugPrint('User address coordinates are null');
        }
        return false;
      }

      final double userLat = double.tryParse(userAddress!.latitude!) ?? 0.0;
      final double userLng = double.tryParse(userAddress.longitude!) ?? 0.0;

      final double distance = Geolocator.distanceBetween(
              userLat, userLng, myPosition.latitude, myPosition.longitude) /
          1000;

      if (kDebugMode) {
        debugPrint('Distance check: $distance');
      }

      return distance > 1;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in checkLocationActive: $e');
      }
      return false;
    }
  }

  Future<void> navigateToLocationScreen(BuildContext context, String page,
      {bool offNamed = false, bool offAll = false}) async {
    final bool fromSignup = page == RouteHelper.signUp;
    final bool fromHome = page == 'home';

    debugPrint(
        '🔍 navigateToLocationScreen called with page: $page, fromHome: $fromHome, isLoggedIn: ${AuthHelper.isLoggedIn()}');

    // 🔥 CRITICAL GUARD: Don't navigate if zones are required but not loaded
    if (Get.isRegistered<LocationController>()) {
      final locationController = Get.find<LocationController>();
      if (!locationController.zonesLoaded && locationController.zones.isEmpty) {
        debugPrint(
            '⏸️ navigateToLocationScreen: Zones not loaded yet - allowing navigation anyway');
        debugPrint('   → This is normal navigation (not zone-based redirect)');
        // Allow normal navigation (not zone-based redirect)
      }
    }

    if (!fromHome && AddressHelper.getUserAddressFromSharedPref() != null) {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      autoNavigate(
          context,
          AddressHelper.getUserAddressFromSharedPref(),
          fromSignup,
          null,
          false,
          Get.context != null && ResponsiveHelper.isDesktop(Get.context!));
    } else if (AuthHelper.isLoggedIn()) {
      // For logged in users, always show AccessLocationScreen first when coming from home
      // This allows users to see saved addresses, add new ones, or use current location
      if (fromHome) {
        debugPrint(
            '🔍 User is logged in and fromHome=true, navigating directly to PickMapScreen');
        if (offNamed) {
          Get.offNamed(RouteHelper.getPickMapRoute(page, false));
        } else if (offAll) {
          Get.offAllNamed(RouteHelper.getPickMapRoute(page, false));
        } else {
          Get.toNamed(RouteHelper.getPickMapRoute(page, false));
        }
      } else {
        debugPrint(
            '🔍 User is logged in but not fromHome, using original logic');
        // For non-home pages, use the original logic
        Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);

        await Get.find<AddressController>().getAddressList();

        Get.back();

        locationServiceInterface.authorizeNavigation(
          page,
          Get.find<AddressController>().addressList,
          mapController,
          offNamed: offNamed,
          offAll: offAll,
        );
      }
    } else {
      // For non-logged in users, navigate to access location screen first
      if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
        showGeneralDialog(
            context: Get.context!,
            pageBuilder: (_, __, ___) {
              return SizedBox(
                height: Get.context!.height * 0.75,
                width: 300,
                child: PickMapScreen(
                  fromSignUp: (page == RouteHelper.signUp),
                  canRoute: false,
                  fromAddAddress: false,
                  route: null,
                  googleMapController: mapController,
                ),
              );
            });
      } else {
        // Navigate directly to PickMapScreen (simplified flow)
        if (offNamed) {
          Get.offNamed(RouteHelper.getPickMapRoute(page, false));
        } else if (offAll) {
          Get.offAllNamed(RouteHelper.getPickMapRoute(page, false));
        } else {
          Get.toNamed(RouteHelper.getPickMapRoute(page, false));
        }
      }
    }
  }

  Future<void> setStoreAddressToUserAddress(LatLng storeAddress) async {
    final Position storePosition = positionFromLatLng(
      storeAddress.latitude,
      storeAddress.longitude,
    );
    final String addressFromGeocode = await getAddressFromGeocode(
        LatLng(storeAddress.latitude, storeAddress.longitude));
    final ZoneResponseModel responseModel = await getZone(
        storePosition.latitude.toString(),
        storePosition.longitude.toString(),
        true);
    _buttonDisabled = !responseModel.isSuccess;
    final AddressModel addressModel = AddressModel(
      latitude: storePosition.latitude.toString(),
      longitude: storePosition.longitude.toString(),
      addressType: 'others',
      zoneId: responseModel.isSuccess ? responseModel.zoneIds[0] : 0,
      zoneIds: responseModel.zoneIds,
      address: addressFromGeocode,
      zoneData: responseModel.zoneData,
      areaIds: responseModel.areaIds,
    );
    await AddressHelper.saveUserAddressInSharedPref(addressModel);

    await Get.find<SplashController>().getModules();
    final List<ModuleModel>? modules = Get.find<SplashController>().moduleList;
    for (final ModuleModel m in modules!) {
      if (m.id == Get.find<StoreController>().store!.moduleId) {
        Get.find<SplashController>().setModule(m);
      }
    }
  }

// =====================================================================================================

  Future<void> get_Location_Delivery_man(String orderID) async {
    _LocationDelivery_man_Model = null;

    _LocationDelivery_man_Model =
        await locationServiceInterface.Location_Delivery_man(orderID);

    update();
  }

// =====================================================================================================
// Zone Polygon Methods for Visual Zone Display
// =====================================================================================================

  // 🎯 PERFORMANCE FIX: Track if zones are already loaded to prevent duplicate API calls
  bool _zonesLoaded = false;
  bool get zonesLoaded => _zonesLoaded;
  DateTime? _lastZonesLoadTime;

  /// Fetches all active zones and builds polygon overlays for map display
  /// 🔧 Zones MUST come from /api/v1/zone/list with formated_coordinates
  /// 🔧 DATA PRESERVATION: Keeps existing zones if API fails (404)
  /// 🎯 PERFORMANCE FIX: Prevents duplicate API calls within 5 seconds
  /// 🔥 RETRY FIX: Smart retry on 304 if cache missing coordinates
  Future<void> fetchZonePolygons(
      {bool forceRefresh = false, bool isRetry = false}) async {
    try {
      // 🔥 FIX: Clear cache if forceRefresh is true (to force fresh API call)
      if (forceRefresh) {
        debugPrint(
            '🔄 fetchZonePolygons: forceRefresh=true - clearing cache to force fresh API call');
        await clearZoneCache();
      }

      // 🎯 PERFORMANCE FIX: Skip if zones already loaded recently (within 5 seconds)
      if (!forceRefresh && _zonesLoaded && _zones.isNotEmpty) {
        final now = DateTime.now();
        if (_lastZonesLoadTime != null &&
            now.difference(_lastZonesLoadTime!).inSeconds < 5) {
          debugPrint(
              '⏭️ fetchZonePolygons: Skipping - zones loaded ${now.difference(_lastZonesLoadTime!).inSeconds}s ago');
          // Rebuild polygons from existing zones (lightweight operation)
          if (_zonePolygons.isEmpty && _zones.isNotEmpty) {
            _zonePolygons = await _buildZonePolygonsInIsolate(_zones);
            // 🎯 CRITICAL: Update only polygons (not entire map)
            update(['zones']);
          }
          return;
        }
      }

      _loadingZones = true;
      // 🎯 CRITICAL: Update only zones-related widgets (not entire map)
      update(['zones']);

      debugPrint('🗺️ Fetching zone polygons...');

      // 🔥 FIX: Zones MUST come from /api/v1/zone/list with formated_coordinates
      // ❌ app-init cache does NOT have formated_coordinates - skip it
      // ✅ Always call API to get zones with formated_coordinates
      debugPrint(
          '🗺️ Fetching zones from /api/v1/zone/list (required for formated_coordinates)');

      // ⚡ TASK 1: Always call API to get zones with formated_coordinates
      // ⚡ TASK 2: If API fails, preserve existing _zones (don't clear)
      List<ZoneDataModel> apiZones = [];
      try {
        apiZones = await locationServiceInterface.getAllZones();
        debugPrint('🗺️ API returned ${apiZones.length} zones');

        // 🔥 FIX 3: Verify zones have formated_coordinates
        final zonesWithCoords = apiZones
            .where((z) =>
                z.formatedCoordinates != null &&
                z.formatedCoordinates!.isNotEmpty)
            .toList();

        if (apiZones.isNotEmpty && zonesWithCoords.isEmpty) {
          debugPrint(
              '\x1B[33m  ⚠️ WARNING: API returned ${apiZones.length} zones but NONE have formated_coordinates  \x1B[0m');
          debugPrint(
              '   → This means backend is not returning formated_coordinates in response');
          debugPrint('   → Green polygons will NOT render');
        } else if (zonesWithCoords.isNotEmpty) {
          debugPrint(
              '\x1B[32m  ✅ API returned ${zonesWithCoords.length} zone(s) with formated_coordinates - polygons will render  \x1B[0m');
        }
      } catch (e) {
        debugPrint('❌ API call failed: $e');
        // ⚡ TASK 2: Don't clear existing zones - keep what we have
        if (_zones.isNotEmpty) {
          debugPrint(
              '✅ Preserving existing ${_zones.length} zones (API failed)');
          _loadingZones = false;
          // 🎯 CRITICAL: Update only zones-related widgets (not entire map)
          update(['zones']);
          return;
        }
      }

      // ⚡ TASK 2: Only update if API returned valid data
      if (apiZones.isNotEmpty) {
        _zones = apiZones;
        // 🎯 PERFORMANCE FIX: Build polygons in isolate to prevent blocking UI thread
        _zonePolygons = await _buildZonePolygonsInIsolate(_zones);

        // 🔥 CRITICAL FIX: zonesLoaded = true ONLY if we have polygons (visual zones)
        // If zones exist but no polygons, zonesLoaded stays false (no UI validation)
        final hasPolygons = _zonePolygons.isNotEmpty;
        _zonesLoaded = hasPolygons;
        _lastZonesLoadTime = DateTime.now();

        if (hasPolygons) {
          debugPrint(
              '🗺️ Built ${_zonePolygons.length} zone polygons from ${_zones.length} zones - zonesLoaded = true');
        } else {
          debugPrint(
              '⚠️ Zones exist (${_zones.length}) but NO polygons built - zonesLoaded = false (no UI validation)');
          debugPrint(
              '   → Backend must return formated_coordinates in /api/v1/zone/list response');
        }

        // 🔥 CRITICAL DIAGNOSTIC: Report coordinate status
        final zonesWithCoordinates = _zones
            .where((z) =>
                z.status == 1 &&
                z.formatedCoordinates != null &&
                z.formatedCoordinates!.isNotEmpty)
            .toList();

        if (zonesWithCoordinates.isEmpty) {
          debugPrint(
              '\x1B[33m  ⚠️ WARNING: ${_zones.length} zone(s) loaded but NONE have coordinates  \x1B[0m');
          debugPrint(
              '   → Backend must return formated_coordinates in /api/v1/zone/list response');
          debugPrint(
              '   → See: lib/features/location/documentation/ZONE_API_CONTRACT.md');
          debugPrint(
              '   → Zone validation will use API (get-zone-id) only - no local validation');
          debugPrint(
              '   → No redirects will occur until coordinates are available');
        } else {
          debugPrint(
              '\x1B[32m  ✅ ${zonesWithCoordinates.length} zone(s) have coordinates - local validation enabled  \x1B[0m');
        }

        // 🎯 CRITICAL: Update only polygons (not entire map)
        update(['zones']);

        // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
        // If zones exist but no polygons, it's okay - user can still proceed if API confirms location
        if (_zones.isNotEmpty && _zonePolygons.isEmpty) {
          debugPrint(
              '\x1B[33m  ⚠️ Zones exist (${_zones.length}) but no polygons built - zones have no coordinates  \x1B[0m');
          debugPrint(
              'ℹ️ Polygons are optional (visual only) - zone validation uses API (get-zone-id)');
          debugPrint(
              '   → Backend must return formated_coordinates in /api/v1/zone/list response');
          debugPrint(
              '   → See: lib/features/location/documentation/ZONE_API_CONTRACT.md');
          // 🔥 DEBUG: Print zone details to diagnose
          for (final zone in _zones) {
            final coordCount = zone.formatedCoordinates?.length ?? 0;
            final status = zone.status == 1 ? 'active' : 'inactive';
            if (coordCount == 0) {
              debugPrint(
                  '   ❌ Zone ${zone.id} (${zone.name ?? "unnamed"}): NO coordinates, status=$status');
            } else {
              debugPrint(
                  '   ✅ Zone ${zone.id} (${zone.name ?? "unnamed"}): $coordCount coordinates, status=$status');
            }
          }
        }
      } else {
        // ⚡ TASK 2: If API returned empty but we have existing zones, keep them
        if (_zones.isNotEmpty) {
          debugPrint(
              '⚠️ API returned empty, but preserving existing ${_zones.length} zones');
          // Rebuild polygons from existing zones (in isolate)
          _zonePolygons = await _buildZonePolygonsInIsolate(_zones);

          // 🔥 CRITICAL FIX: zonesLoaded = true ONLY if we have polygons
          final hasPolygons = _zonePolygons.isNotEmpty;
          _zonesLoaded = hasPolygons;

          // 🎯 CRITICAL: Update only polygons (not entire map)
          update(['zones']);

          // 🔥 RETRY FIX: If zones exist but no coordinates, and this is not a retry, try once more with forceRefresh
          final zonesWithCoordinates = _zones
              .where((z) =>
                  z.status == 1 &&
                  z.formatedCoordinates != null &&
                  z.formatedCoordinates!.isNotEmpty)
              .toList();

          if (zonesWithCoordinates.isEmpty && !isRetry) {
            debugPrint(
                '🔄 fetchZonePolygons: Zones exist but no coordinates - retrying once with forceRefresh=true');
            _loadingZones = false;
            update(['zones']);
            // Retry once with forceRefresh
            await Future.delayed(const Duration(milliseconds: 500));
            await fetchZonePolygons(forceRefresh: true, isRetry: true);
            return;
          }

          // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
          if (_zonePolygons.isEmpty) {
            debugPrint(
                '\x1B[33m  ⚠️ Preserved zones (${_zones.length}) but no polygons - polygons are optional (visual only)  \x1B[0m');
            debugPrint(
                'ℹ️ Zone validation uses API (get-zone-id) - not polygons');
            debugPrint(
                '   → Backend must return formated_coordinates in /api/v1/zone/list response');
            debugPrint(
                '   → See: lib/features/location/documentation/ZONE_API_CONTRACT.md');
          }
        } else {
          // 🔥 UX FALLBACK: If no zones but location is verified, allow proceed
          // This handles cases where:
          // - 304 Not Modified (server says use cache, but cache unavailable)
          // - Temporary API failures
          // - Zone data sync delays
          // User should be able to proceed if they have a verified location
          final hasVerifiedLocation =
              _position.latitude != 0.0 && _position.longitude != 0.0;

          if (hasVerifiedLocation) {
            debugPrint(
                '⚠️ No zones available but location verified (${_position.latitude}, ${_position.longitude})');
            debugPrint('   - Allowing proceed without zones (UX fallback)');
            debugPrint('   - Zone validation will be handled later if needed');
            // Don't block user - allow proceed without zones
            // Zone validation can happen later during checkout/order placement
            _zonePolygons = {};
          } else {
            debugPrint('⚠️ No zones available (API empty and no cached zones)');
            // Only clear if we truly have no zones AND no verified location
            _zonePolygons = {};
          }
        }
      }

      _loadingZones = false;
      // 🎯 CRITICAL: Update only zones-related widgets (not entire map)
      update(['zones']);
    } catch (e) {
      debugPrint('❌ Error fetching zone polygons: $e');
      _loadingZones = false;
      // ⚡ TASK 2: CRITICAL - Don't clear existing zones on error
      // Only clear if we truly have no zones
      if (_zones.isEmpty) {
        _zonePolygons = {};
        // 🔥 UX FALLBACK: If location is verified but no zones, allow proceed
        final hasVerifiedLocation =
            _position.latitude != 0.0 && _position.longitude != 0.0;
        if (hasVerifiedLocation) {
          debugPrint('⚠️ No zones available but location verified');
          debugPrint(
              '   - This is acceptable if backend truly has no zones configured');
          // Allow proceed only if truly no zones (not zones without coordinates)
        }
      } else {
        debugPrint(
            '✅ Preserving existing ${_zones.length} zones despite error');
        // Rebuild polygons from existing zones (in isolate)
        _zonePolygons = await _buildZonePolygonsInIsolate(_zones);

        // 🔥 CRITICAL FIX: zonesLoaded = true ONLY if we have polygons
        final hasPolygons = _zonePolygons.isNotEmpty;
        _zonesLoaded = hasPolygons;

        // 🎯 CRITICAL: Update only polygons (not entire map)
        update(['zones']);

        // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
        if (_zonePolygons.isEmpty && _zones.isNotEmpty) {
          debugPrint(
              '⚠️ Preserved zones (${_zones.length}) but no polygons after error recovery - polygons are optional (visual only)');
          debugPrint(
              'ℹ️ Zone validation uses API (get-zone-id) - not polygons');
        }
      }
      // 🎯 CRITICAL: Update only zones-related widgets (not entire map)
      update(['zones']);
    }
  }

  /// 🗑️ Clear zone cache from SharedPreferences (call once to clear old cached zones without polygons)
  Future<void> clearZoneCache() async {
    try {
      final box =
          await Hive.openLazyBox<String>(HiveCacheConfig.zoneCacheBoxName);
      await box.clear();
      await box.close();
      debugPrint('🗑️ Cleared zone cache from Hive');

      // Also clear SharedPreferences zone cache
      final prefs = Get.find<SharedPreferences>();
      await prefs.remove('cached_all_zones_data');
      await prefs.remove('cached_all_zones_timestamp');
      debugPrint('🗑️ Cleared zone cache from SharedPreferences');
    } catch (e) {
      debugPrint('⚠️ Error clearing zone cache: $e');
    }
  }

  /// 🎯 PERFORMANCE FIX: Build polygons in isolate to prevent blocking UI thread
  /// 🎯 Zone-agnostic: Builds individual zone polygons (supports 1 or 100 zones)
  Future<Set<Polygon>> _buildZonePolygonsInIsolate(
      List<ZoneDataModel> zonesList) async {
    try {
      // Prepare data for isolate (must be serializable)
      final zoneData = zonesList
          .map((zone) => {
                'id': zone.id,
                'status': zone.status,
                'name': zone.name,
                'coordinates': zone.formatedCoordinates
                    ?.map((c) => {
                          'lat': c.lat,
                          'lng': c.lng,
                        })
                    .toList(),
              })
          .toList();

      // Run polygon building in isolate
      final result = await compute(_buildPolygonsInIsolate, zoneData);
      final Map<String, dynamic> typedResult = result;

      // Convert result back to Polygon objects
      final Set<Polygon> polygons = {};

      // 🎯 Build individual zone polygons
      final zonePolygonsList = typedResult['zonePolygons'] as List<dynamic>?;
      if (zonePolygonsList != null) {
        for (final zonePoly in zonePolygonsList.cast<Map<String, dynamic>>()) {
          final zoneId = zonePoly['id'] as int;
          final pointsList = zonePoly['points'] as List<dynamic>;
          if (pointsList.length >= 3) {
            final points = pointsList
                .cast<Map<String, double>>()
                .map((p) => LatLng(p['lat']!, p['lng']!))
                .toList();

            polygons.add(
              Polygon(
                polygonId: PolygonId('zone_$zoneId'),
                points: points,
                strokeWidth: 3,
                strokeColor: Colors.green,
                fillColor: Colors.green.withValues(alpha: 0.15),
              ),
            );
          }
        }
      }

      // Also store convex hull for backward compatibility
      final hullPointsList = typedResult['hullPoints'] as List<dynamic>?;
      if (hullPointsList != null && hullPointsList.length >= 3) {
        final hullPoints = hullPointsList
            .cast<Map<String, double>>()
            .map((p) => LatLng(p['lat']!, p['lng']!))
            .toList();

        _largestZonePoints = hullPoints;

        // Calculate center from all zones
        final List<LatLng> allPoints = [];
        if (zonePolygonsList != null) {
          for (final zonePoly
              in zonePolygonsList.cast<Map<String, dynamic>>()) {
            final pointsList = zonePoly['points'] as List<dynamic>;
            allPoints.addAll(pointsList
                .cast<Map<String, double>>()
                .map((p) => LatLng(p['lat']!, p['lng']!)));
          }
        }

        if (allPoints.isNotEmpty) {
          final double centerLat =
              allPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
                  allPoints.length;
          final double centerLng =
              allPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
                  allPoints.length;
          _largestZoneCenter = LatLng(centerLat, centerLng);
        }
      }

      return polygons;
    } catch (e) {
      debugPrint('❌ Error building polygons in isolate: $e');
      // Fallback to main thread if isolate fails
      return buildZonePolygons(zonesList);
    }
  }

  /// Helper function for isolate (must be top-level or static)
  /// 🎯 Zone-agnostic: Returns all zone polygons (not just convex hull)
  static Map<String, dynamic> _buildPolygonsInIsolate(List<dynamic> zoneData) {
    final List<Map<String, dynamic>> zonePolygons = [];
    final List<Map<String, double>> allActivePoints = [];

    for (final zone in zoneData.cast<Map<String, dynamic>>()) {
      // 🔥 CRITICAL FIX: Check status AND coordinates exist AND not empty
      if (zone['status'] == 1 && zone['coordinates'] != null) {
        final coords = zone['coordinates'] as List<dynamic>;
        // ⚠️ Skip zones with empty coordinates
        if (coords.isEmpty) {
          continue;
        }

        final List<Map<String, double>> zonePoints = [];
        for (final coord in coords.cast<Map<String, dynamic>>()) {
          // Validate coordinate has valid lat/lng
          if (coord['lat'] != null && coord['lng'] != null) {
            final point = {
              'lat': coord['lat'] as double,
              'lng': coord['lng'] as double,
            };
            zonePoints.add(point);
            allActivePoints.add(point);
          }
        }

        // Add individual zone polygon if valid
        if (zonePoints.length >= 3) {
          zonePolygons.add({
            'id': zone['id'],
            'points': zonePoints,
          });
        }
      }
    }

    // Also compute convex hull for backward compatibility
    List<Map<String, double>> hullPoints = [];
    if (allActivePoints.length >= 3) {
      hullPoints = _computeConvexHullInIsolate(allActivePoints);
    }

    return {
      'zonePolygons': zonePolygons,
      'hullPoints': hullPoints,
    };
  }

  /// Compute convex hull in isolate (simplified version)
  static List<Map<String, double>> _computeConvexHullInIsolate(
      List<Map<String, double>> points) {
    if (points.length < 3) return points;

    // Sort points by x-coordinate, then by y-coordinate
    points.sort((a, b) {
      final xCompare = a['lng']!.compareTo(b['lng']!);
      if (xCompare != 0) return xCompare;
      return a['lat']!.compareTo(b['lat']!);
    });

    // Graham scan algorithm (simplified)
    final List<Map<String, double>> hull = [];

    for (final point in points) {
      while (hull.length >= 2 &&
          _crossProductInIsolate(
                hull[hull.length - 2],
                hull[hull.length - 1],
                point,
              ) <=
              0) {
        hull.removeLast();
      }
      hull.add(point);
    }

    final int lowerHullSize = hull.length;
    for (int i = points.length - 2; i >= 0; i--) {
      while (hull.length > lowerHullSize &&
          _crossProductInIsolate(
                hull[hull.length - 2],
                hull[hull.length - 1],
                points[i],
              ) <=
              0) {
        hull.removeLast();
      }
      hull.add(points[i]);
    }

    hull.removeLast(); // Remove duplicate point
    return hull;
  }

  static double _crossProductInIsolate(
    Map<String, double> o,
    Map<String, double> a,
    Map<String, double> b,
  ) {
    return (a['lng']! - o['lng']!) * (b['lat']! - o['lat']!) -
        (a['lat']! - o['lat']!) * (b['lng']! - o['lng']!);
  }

  /// Builds Google Maps Polygon objects from zone data (fallback to main thread)
  /// 🎯 Zone-agnostic: Draws each zone individually (supports 1 zone or 100 zones)
  /// 🎯 UX: Zones are drawn in green color to clearly indicate serviceable areas
  Set<Polygon> buildZonePolygons(List<ZoneDataModel> zonesList) {
    // 🔥 FIX 4: Guard to prevent rebuild if polygons already exist
    if (_zonePolygons.isNotEmpty && zonesList.length == _zones.length) {
      final bool allZonesMatch = zonesList.every(
          (zone) => _zones.any((existingZone) => existingZone.id == zone.id));
      if (allZonesMatch) {
        debugPrint(
            '⏭️ buildZonePolygons: Polygons already built for ${zonesList.length} zones - skipping rebuild');
        return _zonePolygons;
      }
    }

    final Set<Polygon> polygons = {};
    final List<LatLng> allActivePoints = [];
    int activeZoneCount = 0;

    // 🎯 Draw each zone individually (Zone-agnostic approach)
    for (final zone in zonesList) {
      // Skip inactive zones
      if (zone.status != 1) {
        debugPrint(
            '⚠️ Zone ${zone.id} (${zone.name}) is INACTIVE (status: ${zone.status}) - skipping');
        continue;
      }

      // 🔥 FIX 1: Confirm reading formated_coordinates
      if (zone.formatedCoordinates == null ||
          zone.formatedCoordinates!.isEmpty) {
        debugPrint(
            '❌ Zone ${zone.id} (${zone.name ?? "unnamed"}) has no formated_coordinates');
        debugPrint('   → Backend must return formated_coordinates array');
        continue;
      }

      // 🔥 FIX 2: Convert formated_coordinates to LatLng
      // Ensure lat and lng are doubles (not strings)
      final List<LatLng> points = zone.formatedCoordinates!
          .map((coord) {
            final lat = coord.lat ?? 0.0;
            final lng = coord.lng ?? 0.0;
            if (lat == 0.0 || lng == 0.0) {
              debugPrint(
                  '⚠️ Zone ${zone.id}: Invalid coordinate (lat: $lat, lng: $lng)');
            }
            return LatLng(lat, lng);
          })
          .where((point) => point.latitude != 0.0 && point.longitude != 0.0)
          .toList();

      if (points.length < 3) {
        debugPrint(
            '⚠️ Zone ${zone.id} has insufficient points: ${points.length}');
        continue;
      }

      // 🔥 FIX 3: Build Polygon with green color (premium styling)
      final polygon = Polygon(
        polygonId: PolygonId('zone_${zone.id}'),
        points: points,
        strokeWidth: 3,
        strokeColor: Colors.green.shade700, // 🟢 Premium green border
        fillColor: Colors.green
            .withValues(alpha: 0.12), // Light green fill (premium opacity)
        consumeTapEvents: false, // Allow map interactions through polygon
      );

      polygons.add(polygon);
      debugPrint(
          '✅ Built polygon for zone ${zone.id} (${zone.name ?? "unnamed"}) with ${points.length} points');

      allActivePoints.addAll(points);
      activeZoneCount++;
      debugPrint(
          '✅ Added polygon for zone ${zone.id} (${zone.name}) with ${points.length} points');
    }

    // 🎯 Also create convex hull for backward compatibility (used by isPointInsideZone)
    if (allActivePoints.length >= 3) {
      final List<LatLng> hullPoints = _computeConvexHull(allActivePoints);
      _largestZonePoints = hullPoints;

      // Calculate center of all zones
      final double centerLat =
          allActivePoints.map((p) => p.latitude).reduce((a, b) => a + b) /
              allActivePoints.length;
      final double centerLng =
          allActivePoints.map((p) => p.longitude).reduce((a, b) => a + b) /
              allActivePoints.length;
      _largestZoneCenter = LatLng(centerLat, centerLng);
      debugPrint('📍 Service area center calculated: $centerLat, $centerLng');
    } else {
      _largestZonePoints = null;
      _largestZoneCenter = null;
    }

    debugPrint(
        '✅ Created ${polygons.length} zone polygons covering $activeZoneCount active zones');
    return polygons;
  }

  /// Check if a point is inside the largest zone polygon using ray casting algorithm
  /// ⚠️ DEPRECATED: Use isInsideAnyZone() instead for multi-zone support
  bool isPointInsideZone(double lat, double lng) {
    if (_largestZonePoints == null || _largestZonePoints!.length < 3) {
      debugPrint('⚠️ No zone polygon available for boundary check');
      return true; // Allow if no polygon defined
    }

    bool inside = false;
    final List<LatLng> points = _largestZonePoints!;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      if ((points[i].longitude > lng) != (points[j].longitude > lng) &&
          (lat <
              (points[j].latitude - points[i].latitude) *
                      (lng - points[i].longitude) /
                      (points[j].longitude - points[i].longitude) +
                  points[i].latitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// 🎯 Check if a point is inside ANY zone (Zone-agnostic)
  /// Returns true if point is inside at least one active zone
  bool isInsideAnyZone(LatLng point) {
    // 🔥 CRITICAL FIX: Don't allow validation before zones are loaded
    // This prevents false positives and redirect loops
    if (_zones.isEmpty || !_zonesLoaded) {
      debugPrint('⚠️ Zones not loaded yet - skipping local polygon check');
      debugPrint(
          '   → Zones loaded: $_zonesLoaded, Zones count: ${_zones.length}');
      debugPrint(
          '   → Use API validation (get-zone-id) until zones are loaded');
      // Return false to force API validation (more reliable)
      return false;
    }

    // Check each active zone individually
    for (final zone in _zones) {
      if (zone.status != 1) continue; // Skip inactive zones

      if (zone.formatedCoordinates == null ||
          zone.formatedCoordinates!.isEmpty) {
        continue; // Skip zones without coordinates
      }

      final List<LatLng> polygonPoints = zone.formatedCoordinates!
          .map((c) => LatLng(c.lat ?? 0.0, c.lng ?? 0.0))
          .toList();

      if (polygonPoints.length < 3) continue; // Skip invalid polygons

      if (_pointInsidePolygon(point, polygonPoints)) {
        debugPrint('✅ Point is inside zone: ${zone.id} (${zone.name})');
        return true;
      }
    }

    debugPrint('❌ Point is outside all zones');
    return false;
  }

  /// Ray casting algorithm to check if point is inside polygon
  bool _pointInsidePolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final LatLng vi = polygon[i];
      final LatLng vj = polygon[j];

      if ((vi.longitude > point.longitude) !=
              (vj.longitude > point.longitude) &&
          (point.latitude <
              (vj.latitude - vi.latitude) *
                      (point.longitude - vi.longitude) /
                      (vj.longitude - vi.longitude) +
                  vi.latitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// 🎯 Find nearest allowed point (inside any zone)
  /// Returns the closest point inside any active zone from the given point
  /// 🔥 FIX: If outside all zones, returns DEFAULT_FALLBACK_LOCATION
  LatLng findNearestAllowedPoint(LatLng point) {
    // 🔥 CRITICAL FIX: Don't calculate nearest point before zones are loaded
    if (_zones.isEmpty || !_zonesLoaded) {
      debugPrint('⚠️ Zones not loaded yet - using default fallback location');
      debugPrint(
          '   → Returning DEFAULT_FALLBACK_LOCATION: ${DEFAULT_FALLBACK_LOCATION.latitude}, ${DEFAULT_FALLBACK_LOCATION.longitude}');
      return DEFAULT_FALLBACK_LOCATION; // Return default fallback location
    }

    // 🔥 CRITICAL: Check if any zone has coordinates
    final zonesWithCoordinates = _zones
        .where((z) =>
            z.status == 1 &&
            z.formatedCoordinates != null &&
            z.formatedCoordinates!.isNotEmpty)
        .toList();

    if (zonesWithCoordinates.isEmpty) {
      debugPrint(
          '⚠️ No zones with coordinates available - using default fallback location');
      debugPrint(
          '   → Backend must return formated_coordinates in /api/v1/zone/list');
      debugPrint(
          '   → Returning DEFAULT_FALLBACK_LOCATION: ${DEFAULT_FALLBACK_LOCATION.latitude}, ${DEFAULT_FALLBACK_LOCATION.longitude}');
      return DEFAULT_FALLBACK_LOCATION; // Return default fallback location
    }

    LatLng? nearest;
    double minDistance = double.infinity;

    // Check all active zones
    for (final zone in _zones) {
      if (zone.status != 1) continue; // Skip inactive zones

      if (zone.formatedCoordinates == null ||
          zone.formatedCoordinates!.isEmpty) {
        continue; // Skip zones without coordinates
      }

      final List<LatLng> polygonPoints = zone.formatedCoordinates!
          .map((c) => LatLng(c.lat ?? 0.0, c.lng ?? 0.0))
          .toList();

      if (polygonPoints.length < 3) continue; // Skip invalid polygons

      // If point is already inside this zone, return it
      if (_pointInsidePolygon(point, polygonPoints)) {
        debugPrint('✅ Point is already inside zone: ${zone.id}');
        return point;
      }

      // Find nearest point on polygon boundary
      for (int i = 0; i < polygonPoints.length; i++) {
        final LatLng p1 = polygonPoints[i];
        final LatLng p2 = polygonPoints[(i + 1) % polygonPoints.length];

        // Find closest point on line segment p1-p2
        final LatLng closestOnSegment = _closestPointOnSegment(point, p1, p2);
        final double distance = Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          closestOnSegment.latitude,
          closestOnSegment.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = closestOnSegment;
        }
      }
    }

    if (nearest == null) {
      // 🔥 FIX: If no nearest point found in zones, use DEFAULT_FALLBACK_LOCATION
      debugPrint(
          '⚠️ No nearest point found in zones - using DEFAULT_FALLBACK_LOCATION');
      debugPrint(
          '   → Returning DEFAULT_FALLBACK_LOCATION: ${DEFAULT_FALLBACK_LOCATION.latitude}, ${DEFAULT_FALLBACK_LOCATION.longitude}');
      return DEFAULT_FALLBACK_LOCATION;
    }

    // 🔥 FIX: If nearest point is too far (outside all zones), use DEFAULT_FALLBACK_LOCATION
    // Check if nearest point is actually inside any zone
    bool isNearestInsideAnyZone = false;
    for (final zone in zonesWithCoordinates) {
      final List<LatLng> polygonPoints = zone.formatedCoordinates!
          .map((c) => LatLng(c.lat ?? 0.0, c.lng ?? 0.0))
          .toList();
      if (_pointInsidePolygon(nearest, polygonPoints)) {
        isNearestInsideAnyZone = true;
        break;
      }
    }

    if (!isNearestInsideAnyZone) {
      debugPrint(
          '⚠️ Nearest point is outside all zones - using DEFAULT_FALLBACK_LOCATION');
      debugPrint(
          '   → Returning DEFAULT_FALLBACK_LOCATION: ${DEFAULT_FALLBACK_LOCATION.latitude}, ${DEFAULT_FALLBACK_LOCATION.longitude}');
      return DEFAULT_FALLBACK_LOCATION;
    }

    debugPrint(
        '📍 Nearest allowed point found: ${nearest.latitude}, ${nearest.longitude} (distance: ${minDistance.toStringAsFixed(0)}m)');
    return nearest;
  }

  /// Find closest point on line segment from point to segment
  LatLng _closestPointOnSegment(
      LatLng point, LatLng segmentStart, LatLng segmentEnd) {
    final double dx = segmentEnd.longitude - segmentStart.longitude;
    final double dy = segmentEnd.latitude - segmentStart.latitude;
    final double lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) return segmentStart; // Segment is a point

    final double t = ((point.longitude - segmentStart.longitude) * dx +
            (point.latitude - segmentStart.latitude) * dy) /
        lengthSquared;

    // Clamp t to [0, 1] to stay on segment
    final double clampedT = t.clamp(0.0, 1.0);

    return LatLng(
      segmentStart.latitude + clampedT * dy,
      segmentStart.longitude + clampedT * dx,
    );
  }

  /// 🎯 Validate zone status for a point and update state
  /// Returns ZoneStatus and updates _zoneStatus, _nearestAllowedPoint
  ///
  /// 🔥 CRITICAL: This method should NOT be called before zones are loaded
  /// Use API validation (get-zone-id) until zones are available
  ZoneStatus validateZone(LatLng point) {
    // 🔥 CRITICAL LOOP PREVENTION: Don't validate during zone correction
    if (_isZoneCorrectionInProgress) {
      debugPrint(
          '⏸️ validateZone: Zone correction in progress - skipping validation to prevent loop');
      return _zoneStatus; // Return current status, don't change
    }

    // 🔥 CRITICAL GUARD 1: Don't validate before user confirms location
    if (!_isLocationConfirmed) {
      debugPrint(
          '⏭️ validateZone: Location not confirmed by user yet - skipping validation');
      debugPrint(
          '   → Zone validation will happen after user confirms location');
      debugPrint(
          '   → This prevents premature notifications before user chooses location');
      // Return inside to prevent blocking user (but no validation should happen)
      _zoneStatus = ZoneStatus.inside;
      _inZone = true;
      _nearestAllowedPoint = null;
      return _zoneStatus;
    }

    // 🔥 CRITICAL GUARD 2: Don't validate before zones are loaded
    if (!_zonesLoaded || _zones.isEmpty) {
      debugPrint('⚠️ validateZone: Zones not loaded yet - skipping validation');
      debugPrint(
          '   → Zones loaded: $_zonesLoaded, Zones count: ${_zones.length}');
      debugPrint(
          '   → Use API validation (get-zone-id) until zones are loaded');
      debugPrint('   → No redirect should occur before zones are loaded');
      // Return inside to prevent blocking user (but no redirect should happen)
      _zoneStatus = ZoneStatus.inside;
      _inZone = true;
      _nearestAllowedPoint = null;
      return _zoneStatus;
    }

    // Check if any zone has coordinates for local validation
    final zonesWithCoordinates = _zones
        .where((z) =>
            z.status == 1 &&
            z.formatedCoordinates != null &&
            z.formatedCoordinates!.isNotEmpty)
        .toList();

    if (zonesWithCoordinates.isEmpty) {
      debugPrint(
          '⚠️ validateZone: Zones exist but no coordinates - using API validation only');
      debugPrint(
          '   → Backend must return formated_coordinates in /api/v1/zone/list');
      // Return inside to prevent blocking (but no redirect should happen)
      _zoneStatus = ZoneStatus.inside;
      _inZone = true;
      _nearestAllowedPoint = null;
      return _zoneStatus;
    }

    // ✅ Zones loaded and have coordinates - proceed with local validation
    final bool isInside = isInsideAnyZone(point);

    _zoneStatus = isInside ? ZoneStatus.inside : ZoneStatus.outside;
    _inZone = isInside; // Keep backward compatibility

    if (!isInside) {
      _nearestAllowedPoint = findNearestAllowedPoint(point);
    } else {
      _nearestAllowedPoint = null;
    }

    return _zoneStatus;
  }

  /// 🔥 CRITICAL: Mark location as confirmed by user (enables zone validation)
  /// Call this ONLY when:
  /// 1. User clicks "Use Current Location" button
  /// 2. User confirms location from PickMapScreen
  void confirmLocation() {
    _isLocationConfirmed = true;
    debugPrint(
        '✅ LocationController: Location confirmed by user - zone validation enabled');
  }

  /// 🔥 CRITICAL: Reset location confirmation (when user changes location)
  void resetLocationConfirmation() {
    _isLocationConfirmed = false;
    debugPrint('🔄 LocationController: Location confirmation reset');
  }

  /// 🎯 UX: Mark that user was inside zone initially (no need to notify)
  void markWasInsideZoneInitially() {
    _wasInsideZoneInitially = true;
    _hasUserConfirmedLocation = true;
    debugPrint(
        '✅ LocationController: User was inside zone initially - no notifications needed');
  }

  /// 🎯 UX: Mark that user has confirmed their location
  void markUserConfirmedLocation() {
    _hasUserConfirmedLocation = true;
  }

  /// 🎯 UX: Reset initial state flags (when location changes significantly)
  void resetInitialStateFlags() {
    _wasInsideZoneInitially = false;
    _hasUserConfirmedLocation = false;
    debugPrint('🔄 LocationController: Initial state flags reset');
  }

  /// Reset redirect guard (call after redirect completes)
  void resetRedirectGuard() {
    _isRedirecting = false;
    debugPrint('🔄 Redirect guard reset');
  }

  /// Set redirect guard (call before redirecting)
  void setRedirecting(bool redirecting) {
    _isRedirecting = redirecting;
    debugPrint('🔄 Redirect guard set to: $redirecting');
  }

  // 🔥 CRITICAL LOOP PREVENTION: Zone correction methods
  void setZoneCorrectionInProgress(bool inProgress) {
    _isZoneCorrectionInProgress = inProgress;
    debugPrint('🔐 Zone correction in progress: $inProgress');
  }

  void markZoneDialogShown() {
    _lastDialogShownTime = DateTime.now();
    debugPrint('🔐 Zone dialog shown - cooldown started (10 seconds)');
  }

  void resetZoneDialogFlag() {
    _lastDialogShownTime = null;
    debugPrint('🔄 Zone dialog cooldown reset');
  }

  /// Move camera back to default location (center of largest zone)
  Future<void> moveToDefaultLocation() async {
    debugPrint('🔙 Attempting to move to default location...');
    debugPrint('   - Map controller available: ${_mapController != null}');
    debugPrint('   - Zone center available: ${_largestZoneCenter != null}');

    if (_largestZoneCenter == null) {
      debugPrint('⚠️ Zone center not available, cannot move');
      return;
    }

    if (_mapController == null) {
      debugPrint('⚠️ Map controller not available, cannot animate camera');
      // Still try to update position without animation
      updatePosition(
        CameraPosition(target: _largestZoneCenter!, zoom: 14.0),
        false,
      );
      return;
    }

    try {
      debugPrint('🔙 Moving camera back to: $_largestZoneCenter');
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _largestZoneCenter!,
            zoom: 14.0,
          ),
        ),
      );
      debugPrint('✅ Camera moved successfully');

      // Update position after moving
      updatePosition(
        CameraPosition(target: _largestZoneCenter!, zoom: 14.0),
        false,
      );
    } catch (e) {
      debugPrint('❌ Error moving camera: $e');
    }
  }

  /// Clear zone polygons (useful for cleanup or refresh)
  void clearZonePolygons() {
    _zonePolygons = {};
    _zones = [];
    _largestZonePoints = null;
    _largestZoneCenter = null;
    update();
  }

  /// Computes convex hull using Graham Scan algorithm
  List<LatLng> _computeConvexHull(List<LatLng> points) {
    if (points.length < 3) return points;

    // Find the bottom-most point (or left most in case of tie)
    final LatLng pivot = points.reduce((a, b) {
      if (a.latitude < b.latitude) return a;
      if (a.latitude == b.latitude && a.longitude < b.longitude) return a;
      return b;
    });

    // Sort points by polar angle with respect to pivot
    final List<LatLng> sortedPoints = List.from(points);
    sortedPoints.remove(pivot);
    sortedPoints.sort((a, b) {
      final double angleA = _polarAngle(pivot, a);
      final double angleB = _polarAngle(pivot, b);
      if (angleA < angleB) return -1;
      if (angleA > angleB) return 1;
      // If angles are equal, sort by distance
      final double distA = _distance(pivot, a);
      final double distB = _distance(pivot, b);
      return distA.compareTo(distB);
    });

    if (sortedPoints.isEmpty) return [pivot];
    if (sortedPoints.length == 1) return [pivot, sortedPoints[0]];

    // Build convex hull using stack
    final List<LatLng> hull = [pivot, sortedPoints[0], sortedPoints[1]];

    for (int i = 2; i < sortedPoints.length; i++) {
      while (hull.length > 1 &&
          _crossProduct(hull[hull.length - 2], hull[hull.length - 1],
                  sortedPoints[i]) <=
              0) {
        hull.removeLast();
      }
      hull.add(sortedPoints[i]);
    }

    return hull;
  }

  /// Calculate polar angle between two points
  double _polarAngle(LatLng pivot, LatLng point) {
    return atan2(
        point.latitude - pivot.latitude, point.longitude - pivot.longitude);
  }

  /// Calculate cross product for three points
  double _crossProduct(LatLng o, LatLng a, LatLng b) {
    return (a.longitude - o.longitude) * (b.latitude - o.latitude) -
        (a.latitude - o.latitude) * (b.longitude - o.longitude);
  }

  /// Calculate distance between two points
  double _distance(LatLng a, LatLng b) {
    final double dx = a.longitude - b.longitude;
    final double dy = a.latitude - b.latitude;
    return sqrt(dx * dx + dy * dy);
  }

//
}
