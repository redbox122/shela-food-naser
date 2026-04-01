import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/delivery_man_last_location.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository_interface.dart';
import 'package:sixam_mart/features/location/domain/services/location_service_interface.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/features/parcel/domain/models/place_details_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/home/screens/multi_module/multi_module_home_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class LocationService implements LocationServiceInterface {
  final LocationRepositoryInterface locationRepoInterface;
  LocationService({required this.locationRepoInterface});

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    return await locationRepoInterface.getAddressFromGeocode(latLng);
  }

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng,
      {bool handleError = false}) async {
    return await locationRepoInterface.getZone(lat, lng,
        handleError: handleError);
  }

  @override
  Future<List<ZoneDataModel>> getAllZones() async {
    return await locationRepoInterface.getAllZones();
  }

  @override
  Future<Position> getPosition(LatLng? defaultLatLng, LatLng configLatLng,
      {bool skipZoneValidation = false}) async {
    Position myPosition;
    try {
      debugPrint('🔍 LocationService: Getting current position...');

      // Add timeout to prevent hanging and force fresh location
      final Position newLocalData = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      )).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
              '⏰ LocationService: Timeout getting position, using default');
          throw Exception('Location request timed out');
        },
      );

      debugPrint(
          '🔍 LocationService: Position obtained: ${newLocalData.latitude}, ${newLocalData.longitude}');

      // Check if the detected location is within a reasonable range of the service area
      // If it's too far from the default location, use the default coordinates instead
      final double distance = Geolocator.distanceBetween(
              newLocalData.latitude,
              newLocalData.longitude,
              configLatLng.latitude,
              configLatLng.longitude) /
          1000; // Convert to kilometers

      debugPrint(
          '🔍 LocationService: Distance from service area: ${distance.toStringAsFixed(2)}km');

      // If skipZoneValidation is true, always use actual GPS location regardless of distance
      if (skipZoneValidation) {
        debugPrint(
            '✅ LocationService: Skipping zone validation - using actual GPS location (${distance.toStringAsFixed(2)}km from service area)');
        myPosition = newLocalData;
      }
      // If the distance is more than 1000km from the service area, use default coordinates
      else if (distance > 1000) {
        debugPrint(
            '⚠️ LocationService: Detected location is ${distance.toStringAsFixed(2)}km from service area, using default coordinates');
        myPosition = LocationController.positionFromLatLng(
          defaultLatLng != null
              ? defaultLatLng.latitude
              : configLatLng.latitude,
          defaultLatLng != null
              ? defaultLatLng.longitude
              : configLatLng.longitude,
        );
      } else {
        debugPrint(
            '✅ LocationService: Using actual GPS location (${distance.toStringAsFixed(2)}km from service area)');
        myPosition = newLocalData;
      }
    } catch (e) {
      debugPrint('❌ LocationService: Error getting position: $e');
      myPosition = LocationController.positionFromLatLng(
        defaultLatLng != null ? defaultLatLng.latitude : configLatLng.latitude,
        defaultLatLng != null
            ? defaultLatLng.longitude
            : configLatLng.longitude,
      );
    }
    debugPrint(
        '✅ LocationService: Returning position: ${myPosition.latitude}, ${myPosition.longitude}');
    return myPosition;
  }

  @override
  void handleMapAnimation(
      GoogleMapController? mapController, Position myPosition) {
    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(myPosition.latitude, myPosition.longitude),
            zoom: 17),
      ));
    }
  }

  @override
  Map<String, String> prepareHeader(List<int>? zoneIds) {
    final Map<String, String> header = {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.zoneId: zoneIds != null ? jsonEncode(zoneIds) : '',
    };
    return header;
  }

  @override
  void configureFirebaseMessaging(AddressModel address) {
    if (!GetPlatform.isWeb) {
      if (Get.find<SplashController>().configModel!.demo!) {
        FirebaseMessaging.instance.subscribeToTopic('demo_reset');
      } else {
        FirebaseMessaging.instance.unsubscribeFromTopic('demo_reset');
      }

      // Unsubscribe from old zones
      if (AddressHelper.getUserAddressFromSharedPref() != null) {
        final oldAddress = AddressHelper.getUserAddressFromSharedPref()!;
        if (oldAddress.zoneIds != null && oldAddress.zoneIds!.isNotEmpty) {
          for (final int zoneID in oldAddress.zoneIds!) {
            if (zoneID > 0) {
              // Only unsubscribe from valid zones
              FirebaseMessaging.instance
                  .unsubscribeFromTopic('zone_${zoneID}_customer');
            }
          }
        } else if (oldAddress.zoneId != null && oldAddress.zoneId! > 0) {
          // Only unsubscribe if zoneId is valid (not 0)
          FirebaseMessaging.instance
              .unsubscribeFromTopic('zone_${oldAddress.zoneId}_customer');
        }
      }

      // Subscribe to new zones (only if valid)
      if (address.zoneIds != null && address.zoneIds!.isNotEmpty) {
        for (final int zoneID in address.zoneIds!) {
          if (zoneID > 0) {
            // Only subscribe to valid zones
            FirebaseMessaging.instance
                .subscribeToTopic('zone_${zoneID}_customer');
          }
        }
      } else if (address.zoneId != null && address.zoneId! > 0) {
        // Only subscribe if zoneId is valid (not 0)
        FirebaseMessaging.instance
            .subscribeToTopic('zone_${address.zoneId}_customer');
      } else {
        // Location is outside zone - don't subscribe to any zone topics
        debugPrint(
            '📍 configureFirebaseMessaging: Location outside zone (zoneId=0), skipping zone topic subscription');
      }
    }
  }

  @override
  void handleRoute(bool fromSignUp, String? route, bool canRoute) {
    // Keep onboarding flow intact:
    // Welcome screens -> Pick Map -> MultiModuleHomeScreen.
    if (route == 'onboarding' || route == RouteHelper.onBoarding) {
      Get.offAll<dynamic>(
        () => const MultiModuleHomeScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 250),
      );
      return;
    }

    if (route != null && canRoute) {
      Get.offAllNamed(route);
    } else {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    }
  }

  @override
  Future<LatLng> getLatLng(String? id) async {
    LatLng latLng = const LatLng(0, 0);
    final Response? response = await locationRepoInterface.get(id) as Response?;
    if (response?.statusCode == 200) {
      final PlaceDetailsModel placeDetails =
          PlaceDetailsModel.fromJson(response?.body as Map<String, dynamic>);
      if (placeDetails.status == 'OK') {
        latLng = LatLng(placeDetails.result!.geometry!.location!.lat!,
            placeDetails.result!.geometry!.location!.lng!);
      }
    }
    return latLng;
  }

  @override
  Future<List<PredictionModel>> searchLocation(String text) async {
    List<PredictionModel> predictionList = [];
    final Response response = await locationRepoInterface.searchLocation(text);
    if (response.statusCode == 200 && response.body['status'] == 'OK') {
      predictionList = [];
      for (var prediction in (response.body['predictions'] as List)) {
        predictionList
            .add(PredictionModel.fromJson(prediction as Map<String, dynamic>));
      }
    } else {
      showCustomSnackBar(
          (response.body['error_message'] as String?) ?? response.bodyString);
    }
    return predictionList;
  }

  @override
  void checkLocationPermission(Function onTap) async {
    debugPrint('🔍 Checking location permission...');

    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled - opening settings');
      showCustomSnackBar('location_services_disabled'.tr);
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(milliseconds: 700));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services still disabled after settings');
        showCustomSnackBar('location_services_disabled'.tr);
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('🔍 Initial permission status: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('🔍 Permission denied, requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('🔍 Permission after request: $permission');
    }

    if (permission == LocationPermission.denied) {
      debugPrint('❌ Permission denied, showing settings dialog');
      Get.dialog(const PermissionDialogWidget());
    } else if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permission denied forever, showing dialog');
      Get.dialog(const PermissionDialogWidget());
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      debugPrint('✅ Permission granted, executing onTap callback');
      onTap();
    } else {
      debugPrint(
          '⚠️ Unknown permission status: $permission, executing onTap anyway');
      onTap();
    }
  }

  @override
  Future<void> authorizeNavigation(
    String page,
    List<AddressModel>? addressList,
    GoogleMapController? mapController, {
    bool offNamed = false,
    bool offAll = false,
  }) async {
    //

    if (addressList != null && addressList.isEmpty) {
      // 🔥 CRITICAL GUARD: Don't redirect before zones are loaded
      if (Get.isRegistered<LocationController>()) {
        final locationController = Get.find<LocationController>();

        // Check if zones are required but not loaded
        if (!locationController.zonesLoaded &&
            locationController.zones.isEmpty) {
          debugPrint(
              '⏸️ authorizeNavigation: Zones not loaded yet - allowing navigation');
          debugPrint('   → This is normal navigation (user has no addresses)');
          // Allow navigation - this is normal flow when user has no addresses
        }

        // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
        // If zones exist but no polygons, it's okay - user can still proceed if API confirms location
        if (locationController.zones.isNotEmpty &&
            locationController.zonePolygons.isEmpty) {
          debugPrint(
              '⚠️ Zones exist but no polygons - polygons are optional (visual only)');
          debugPrint(
              'ℹ️ Zone validation uses API (get-zone-id) - not polygons');
          // Don't block - polygons are optional, API validation is what matters
        }

        // 🔥 SIMPLIFIED FLOW: Navigate directly to PickMapScreen
        final String targetRoute = RouteHelper.getPickMapRoute(page, false);
        final String currentRoute = Get.currentRoute;

        if (currentRoute == targetRoute) {
          debugPrint(
              '⏸️ authorizeNavigation: Already on target route ($targetRoute) - skipping navigation');
          return;
        }

        // Normal navigation flow - direct to PickMapScreen
        if (offNamed) {
          Get.offNamed(targetRoute);
        } else if (offAll) {
          Get.offAllNamed(targetRoute);
        } else {
          Get.toNamed(targetRoute);
        }
        return;
      }

      if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
        showGeneralDialog(
            context: Get.context!,
            pageBuilder: (_, __, ___) {
              return SizedBox(
                height: 300,
                width: 300,
                child: PickMapScreen(
                    fromSignUp: (page == RouteHelper.signUp),
                    canRoute: false,
                    fromAddAddress: false,
                    route: null,
                    googleMapController: mapController),
              );
            });
      } else {
        debugPrint('\x1B[32m  /444444444  \x1B[0m');

        Get.toNamed(RouteHelper.getMy_LocationRoute(page, false));

        //
      }
    } else {
      if (offNamed) {
        debugPrint('\x1B[32m  /6666666  \x1B[0m');

        Get.offNamed(RouteHelper.getAccessLocationRoute(page));
      } else if (offAll) {
        debugPrint('\x1B[32m  /77777  \x1B[0m');

        Get.offAllNamed(RouteHelper.getAccessLocationRoute(page));
      } else {
        debugPrint('\x1B[32m  /88888888  \x1B[0m');

        Get.toNamed(RouteHelper.getAccessLocationRoute(page));
      }
    }
  }

  @override
  void defaultNavigation(String page, GoogleMapController? mapController) {
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
      Get.toNamed(RouteHelper.getPickMapRoute(page, false));
    }
  }

  //

  @override
  Future<LocationDeliveryModel> Location_Delivery_man(String orderID) async {
    return await locationRepoInterface.Location_Delivery_man(orderID);
  }
}
