import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/address/widgets/address_confirmation_dialogue.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/screens/web_landing_page.dart';
import 'package:sixam_mart/features/location/widgets/zone_redirection_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/core/navigation/navigation_guards.dart';
import 'dart:async';

class AccessLocationScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;
  const AccessLocationScreen(
      {super.key,
      required this.fromSignUp,
      required this.fromHome,
      required this.route});

  @override
  State<AccessLocationScreen> createState() => _AccessLocationScreenState();
}

class _AccessLocationScreenState extends State<AccessLocationScreen> {
  String _selectedLocationType = 'current'; // 'current' or 'saved'
  AddressModel? _currentLocation;
  bool _isLoadingCurrentLocation = false;
  bool _isFetchingLocation = false; // 🔥 Guard to prevent duplicate calls
  LatLng? _currentPosition;
  // 🗺️ Map readiness variables
  bool _mapReady = false;
  CameraPosition? _cameraPosition;
  GoogleMapController? _mapController;
  // Zone validation is handled by backend via get-zone-id
  bool _isUpdatingPin = false;
  CameraPosition? _lastCameraPosition;
  // 🎯 PERFORMANCE: Debounce timer to reduce API calls when dragging pin
  Timer? _pinDebounceTimer;
  // 🔥 FIX 3: Guard to prevent auto-redirect loop
  bool _isAutoMoving = false;
  // 🔥 UX FIX: Removed _hasShownRedirectionDialog - using cooldown timer instead
  // Dialog can show every 10 seconds when user goes outside zone

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 AccessLocationScreen: Redirecting to PickMapScreen (simplified flow)');
    
    // 🔥 SIMPLIFIED FLOW: Redirect immediately to PickMapScreen
    // AccessLocationScreen is now just a redirect - no UI needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Get.offNamed<void>(
          RouteHelper.getPickMapRoute(widget.route, false),
        );
      }
    });
    // 🛡️ CRITICAL: Block auto-routing while user is selecting location
    NavigationGuards.isInAccessLocation = true;
    debugPrint('🛡️ NavigationGuard: AccessLocationScreen active - auto-routing blocked');
    
    if (AuthHelper.isLoggedIn()) {
      Get.find<AddressController>().getAddressList();
    }
    
    // 🔥 FIX 1: Load zones FIRST (before location) to ensure green polygons appear
    // 🔥 FIX: Force refresh on first load to bypass 304 cache and get formated_coordinates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('🗺️ AccessLocationScreen: Loading zones first (forceRefresh=true to get formated_coordinates)...');
      final locationController = Get.find<LocationController>();
      await locationController.fetchZonePolygons(forceRefresh: true);
      debugPrint('✅ AccessLocationScreen: Zones loaded - ${locationController.zones.length} zones, ${locationController.zonePolygons.length} polygons');
      
      // After zones are loaded, get current location
      debugPrint('🔍 AccessLocationScreen: Getting current location...');
      await _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    // 🛡️ CRITICAL: Unblock auto-routing when leaving AccessLocationScreen
    NavigationGuards.isInAccessLocation = false;
    debugPrint('🛡️ NavigationGuard: AccessLocationScreen disposed - auto-routing unblocked');
    
    // 🎯 PERFORMANCE: Cancel debounce timer
    _pinDebounceTimer?.cancel();
    
    // 🗺️ Clean up map controller
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> refreshCurrentLocation() async {
    await _getCurrentLocation(forceRefresh: true);
  }

  // Zone validation is handled by backend via get-zone-id

  Future<void> _onUserPickLocationOnMiniMap(
    LatLng newPosition, {
    bool shouldAnimateCamera = true,
  }) async {
    if (_isUpdatingPin) {
      return;
    }
    if (_currentPosition != null) {
      final double latDiff = (_currentPosition!.latitude - newPosition.latitude).abs();
      final double lngDiff = (_currentPosition!.longitude - newPosition.longitude).abs();
      const double maxDiff = 0.00005; // ~5m tolerance
      if (latDiff < maxDiff && lngDiff < maxDiff) {
        return;
      }
    }
    _isUpdatingPin = true;
    setState(() {
      _currentPosition = newPosition;
      _cameraPosition = CameraPosition(
        target: newPosition,
        zoom: 16,
      );
    });
    try {
      if (_mapController != null && shouldAnimateCamera) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(newPosition),
        );
      }
      final LocationController locationController = Get.find<LocationController>();
      final String address = await locationController.getAddressFromGeocode(newPosition);
      
      // 🔥 CRITICAL FIX: Don't validate zone until user confirms location
      // This prevents premature notifications when user is just moving the map
      if (!locationController.isLocationConfirmed) {
        debugPrint('⏭️ AccessLocationScreen: Skipping zone validation in _onUserPickLocationOnMiniMap - location not confirmed yet');
        debugPrint('   → User is just moving map - no validation needed');
        // Just update the address, no zone validation
      } else {
        // User confirmed location - now validate zone
        final ZoneResponseModel zoneResponse = await locationController.getZone(
          newPosition.latitude.toString(),
          newPosition.longitude.toString(),
          false,
        );

          if (!zoneResponse.isSuccess || zoneResponse.zoneIds.isEmpty) {
            // 🎯 UX: Show friendly message explaining limited coverage
            showCustomSnackBar(
              'we_cover_limited_areas_only'.tr,
              isError: true,
              showDuration: 4,
            );
            debugPrint(
                '❌ AccessLocationScreen: Zone validation failed for ${newPosition.latitude}, ${newPosition.longitude}');
            return;
          }
          setState(() {
            _currentLocation = AddressModel(
              latitude: newPosition.latitude.toString(),
              longitude: newPosition.longitude.toString(),
              address: address,
              addressType: 'current',
              zoneId: zoneResponse.zoneIds.first,
              zoneIds: zoneResponse.zoneIds,
              zoneData: zoneResponse.zoneData,
              areaIds: zoneResponse.areaIds,
            );
          });
        }
    } catch (e) {
      debugPrint('❌ AccessLocationScreen: Error updating picked location: $e');
    } finally {
      _isUpdatingPin = false;
    }
  }

  Future<void> _ensureCurrentLocationModelFromPosition(LatLng position) async {
    if (_currentLocation != null &&
        _currentLocation!.latitude != null &&
        _currentLocation!.longitude != null &&
        _currentLocation!.latitude!.isNotEmpty &&
        _currentLocation!.longitude!.isNotEmpty) {
      final double? existingLat = double.tryParse(_currentLocation!.latitude!);
      final double? existingLng = double.tryParse(_currentLocation!.longitude!);
      if (existingLat != null && existingLng != null) {
        // If the saved model coordinates don't match the current pin, rebuild model.
        final double latDiff = (existingLat - position.latitude).abs();
        final double lngDiff = (existingLng - position.longitude).abs();
        const double maxDiff = 0.0002; // ~20m tolerance
        if (latDiff < maxDiff && lngDiff < maxDiff) {
          return;
        }
      }
    }
    try {
      final LocationController locationController = Get.find<LocationController>();
      final String address = await locationController.getAddressFromGeocode(position);
      setState(() {
        _currentLocation = AddressModel(
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
          address: address,
          addressType: 'current',
          zoneId: 0,
          zoneIds: [],
          zoneData: [],
          areaIds: [],
        );
      });
    } catch (e) {
      debugPrint('❌ AccessLocationScreen: Failed to reverse geocode pin: $e');
    }
  }

  Future<void> _getCurrentLocation({bool forceRefresh = false}) async {
    // 🔥 CRITICAL FIX: Guard to prevent duplicate location fetches
    if (_isFetchingLocation && !forceRefresh) {
      debugPrint('⏸️ AccessLocationScreen: Location fetch already in progress - skipping');
      return;
    }
    
    debugPrint(
        '🔍 AccessLocationScreen: Starting _getCurrentLocation (forceRefresh: $forceRefresh)');
    
    _isFetchingLocation = true;
    // 🗺️ CRITICAL FIX: Reset map readiness when fetching new location
    _mapReady = false;
    _cameraPosition = null;
    // Reset map state on force refresh
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      final locationController = Get.find<LocationController>();

      if (forceRefresh) {
        // User explicitly clicked "Current Location" - get actual GPS location
        debugPrint(
            '🔍 AccessLocationScreen: Force refreshing actual GPS location');
        try {
          final AddressModel currentLocationModel =
              await locationController.getCurrentLocation(true);

          if (currentLocationModel.latitude != null &&
              currentLocationModel.longitude != null) {
            debugPrint(
                '🔍 AccessLocationScreen: Got actual GPS location: ${currentLocationModel.latitude}, ${currentLocationModel.longitude}');

            _currentLocation = currentLocationModel;
            _currentPosition = LatLng(
              double.parse(currentLocationModel.latitude!),
              double.parse(currentLocationModel.longitude!),
            );
          } else {
            throw Exception('GPS location returned null coordinates');
          }
        } catch (gpsError) {
          debugPrint('🔍 AccessLocationScreen: GPS location failed: $gpsError');
          // Fallback to location controller data, but check if it's valid
          final position = locationController.position;
          
          // Check if position is valid (not 0.0, 0.0)
          final bool isValidPosition = position.latitude != 0.0 || position.longitude != 0.0;
          
          if (isValidPosition) {
            final address = locationController.address ?? 'Current Location';
            debugPrint(
                '🔍 AccessLocationScreen: Using valid location controller position: ${position.latitude}, ${position.longitude}');
            _currentLocation = AddressModel(
              latitude: position.latitude.toString(),
              longitude: position.longitude.toString(),
              address: address,
              addressType: 'current',
              zoneId: 0,
              zoneIds: [],
              zoneData: [],
              areaIds: [],
            );
            _currentPosition = LatLng(position.latitude, position.longitude);
          } else {
            // Position is invalid (0.0, 0.0), use default location from config
            debugPrint(
                '🔍 AccessLocationScreen: Location controller position is invalid (0.0, 0.0), using default location');
            final splashController = Get.find<SplashController>();
            final defaultLat = double.tryParse(
                    splashController.configModel?.defaultLocation?.lat ?? '0') ??
                0.0;
            final defaultLng = double.tryParse(
                    splashController.configModel?.defaultLocation?.lng ?? '0') ??
                0.0;
            
            if (defaultLat != 0.0 && defaultLng != 0.0) {
              _currentLocation = AddressModel(
                latitude: defaultLat.toString(),
                longitude: defaultLng.toString(),
                address: 'Default Location',
                addressType: 'current',
                zoneId: 0,
                zoneIds: [],
                zoneData: [],
                areaIds: [],
              );
              _currentPosition = LatLng(defaultLat, defaultLng);
            } else {
              throw Exception('No valid location available');
            }
          }
        }
      } else {
        // 🔥 FIX 2: Initial load - prioritize GPS location FIRST (not saved address)
        debugPrint('🔍 AccessLocationScreen: Initial load - prioritizing GPS location');
        
        try {
          // Try GPS location first
          final AddressModel currentLocationModel =
              await locationController.getCurrentLocation(true);
          
          if (currentLocationModel.latitude != null &&
              currentLocationModel.longitude != null) {
            debugPrint('✅ AccessLocationScreen: Got GPS location: ${currentLocationModel.latitude}, ${currentLocationModel.longitude}');
            _currentLocation = currentLocationModel;
            _currentPosition = LatLng(
              double.parse(currentLocationModel.latitude!),
              double.parse(currentLocationModel.longitude!),
            );
          } else {
            throw Exception('GPS location returned null coordinates');
          }
        } catch (gpsError) {
          debugPrint('⚠️ AccessLocationScreen: GPS location failed: $gpsError, falling back to saved address');

          // Fallback 1: Try saved address
        final AddressModel? savedAddress =
            AddressHelper.getUserAddressFromSharedPref();
        if (savedAddress != null &&
            savedAddress.latitude != null &&
            savedAddress.longitude != null &&
            savedAddress.latitude!.isNotEmpty &&
            savedAddress.longitude!.isNotEmpty) {
          try {
            final double lat = double.parse(savedAddress.latitude!);
            final double lng = double.parse(savedAddress.longitude!);
              debugPrint('✅ AccessLocationScreen: Using saved address: $lat, $lng');
            _currentLocation = savedAddress;
            _currentPosition = LatLng(lat, lng);
          } catch (e) {
              debugPrint('⚠️ AccessLocationScreen: Error parsing saved address: $e');
            throw Exception('Invalid saved address coordinates');
          }
        } else {
            debugPrint('⚠️ AccessLocationScreen: No saved address, checking location controller data');
          
            // Fallback 2: Try location controller position
            final position = locationController.position;
          final bool isValidPosition = position.latitude != 0.0 || position.longitude != 0.0;
          
          if (isValidPosition) {
            final address = locationController.address ?? 'Current Location';
              debugPrint('✅ AccessLocationScreen: Using location controller position: ${position.latitude}, ${position.longitude}');
            _currentLocation = AddressModel(
              latitude: position.latitude.toString(),
              longitude: position.longitude.toString(),
              address: address,
              addressType: 'current',
              zoneId: 0,
              zoneIds: [],
              zoneData: [],
              areaIds: [],
            );
            _currentPosition = LatLng(position.latitude, position.longitude);
          } else {
              // Fallback 3: Use default location from config
              debugPrint('⚠️ AccessLocationScreen: Using default location from config');
              final splashController = Get.find<SplashController>();
              final defaultLat = double.tryParse(
                      splashController.configModel?.defaultLocation?.lat ?? '0') ??
                  0.0;
              final defaultLng = double.tryParse(
                      splashController.configModel?.defaultLocation?.lng ?? '0') ??
                  0.0;
              
              if (defaultLat != 0.0 && defaultLng != 0.0) {
                _currentLocation = AddressModel(
                  latitude: defaultLat.toString(),
                  longitude: defaultLng.toString(),
                  address: 'Default Location',
                  addressType: 'current',
                  zoneId: 0,
                  zoneIds: [],
                  zoneData: [],
                  areaIds: [],
                );
                _currentPosition = LatLng(defaultLat, defaultLng);
              } else {
                throw Exception('No valid location available');
              }
            }
          }
        }
      }

      debugPrint(
          '📍 AccessLocationScreen: Final position set to ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      debugPrint(
          '📍 Location verified: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // 🗺️ Set camera position directly to user's current location
      final LatLng targetPosition = _currentPosition!;
      _cameraPosition = CameraPosition(
        target: targetPosition,
        zoom: 16,
      );
      _mapReady = true;
      debugPrint('🗺️ Map ready: Camera position set to ${targetPosition.latitude}, ${targetPosition.longitude}');
      debugPrint('🚫 NO ROUTE CHANGES - Only camera position updated');

      // 🔥 UX FIX: Entering map = user intention to choose location
      // No need to wait for button press - map entry itself is confirmation
      if (!locationController.isLocationConfirmed) {
        locationController.confirmLocation();
        debugPrint('✅ AccessLocationScreen: Location confirmed - user entered map (intention to choose location)');
      }

      // 🔥 FIX: Zones already loaded in initState - skip duplicate fetch
      // await locationController.fetchZonePolygons(); // Already loaded in initState

      // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
      // If zones exist but no polygons, it's okay - user can still proceed if API confirms location
      if (locationController.zones.isNotEmpty && locationController.zonePolygons.isEmpty) {
        debugPrint('⚠️ AccessLocationScreen: Zones exist but no polygons - polygons are optional (visual only)');
        debugPrint('   - Zones: ${locationController.zones.length}, Polygons: ${locationController.zonePolygons.length}');
        debugPrint('ℹ️ Zone validation uses API (get-zone-id) - not polygons');
        // Don't block - polygons are optional, API validation is what matters
      }

      setState(() {
        _isLoadingCurrentLocation = false;
      });
      _isFetchingLocation = false;
    } catch (e) {
      debugPrint('❌ AccessLocationScreen: Error in _getCurrentLocation: $e');
      debugPrint('⚠️ AccessLocationScreen: GPS failed, trying fallback...');
      
      // 🔥 FIX: Try fallback locations before showing error
      bool fallbackSuccess = false;
      
      // Fallback 1: Use the first saved address
      try {
        final addressController = Get.find<AddressController>();
        if (addressController.addressList != null &&
            addressController.addressList!.isNotEmpty) {
          final firstAddress = addressController.addressList!.first;
          debugPrint(
              '✅ AccessLocationScreen: Using first saved address as fallback: ${firstAddress.latitude}, ${firstAddress.longitude}');
          _currentLocation = firstAddress;
          _currentPosition = LatLng(
            double.parse(firstAddress.latitude!),
            double.parse(firstAddress.longitude!),
          );
          fallbackSuccess = true;
        }
      } catch (fallbackError1) {
        debugPrint('⚠️ AccessLocationScreen: Fallback 1 failed: $fallbackError1');
      }
      
      // Fallback 2: Use default location (if fallback 1 failed)
      if (!fallbackSuccess) {
        try {
          debugPrint('✅ AccessLocationScreen: Using default location as fallback');
          _currentLocation = AddressModel(
            latitude: '24.56931995577657',
            longitude: '46.547983288764954',
            addressType: 'current',
            zoneId: 0,
            zoneIds: [],
            address: 'Default Location',
            zoneData: [],
            areaIds: [],
          );
          _currentPosition = const LatLng(24.56931995577657, 46.547983288764954);
          fallbackSuccess = true;
        } catch (fallbackError2) {
          debugPrint('❌ AccessLocationScreen: All fallbacks failed: $fallbackError2');
        }
      }

      // 🔥 UX FIX: Never show error dialog - always use fallback
      // Even if all fallbacks fail, we still set a default location
      // User can always choose location manually from map
      // Error dialogs are scary and break UX - location selection should never fail
      if (!fallbackSuccess || _currentPosition == null) {
        debugPrint('⚠️ AccessLocationScreen: All fallbacks failed - using hardcoded default location');
        // Use hardcoded default as last resort (should never happen, but just in case)
        _currentLocation = AddressModel(
          latitude: LocationController.DEFAULT_FALLBACK_LOCATION.latitude.toString(),
          longitude: LocationController.DEFAULT_FALLBACK_LOCATION.longitude.toString(),
          addressType: 'current',
          zoneId: 0,
          zoneIds: [],
          address: 'Default Location',
          zoneData: [],
          areaIds: [],
        );
        _currentPosition = LocationController.DEFAULT_FALLBACK_LOCATION;
        debugPrint('✅ AccessLocationScreen: Hardcoded default location set - map will open');
        debugPrint('   → User can choose location manually from map');
        debugPrint('   → No error shown - location selection never fails');
      } else {
        debugPrint('✅ AccessLocationScreen: Fallback location obtained - no error shown');
      }

      // Set camera position if we have a valid location
      if (_currentPosition != null) {
        _cameraPosition = CameraPosition(
          target: _currentPosition!,
          zoom: 16,
        );
        _mapReady = true;
        debugPrint('🗺️ Map ready (fallback): Camera position set to ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

        // Still try to fetch zones for fallback location
        try {
          final locationController = Get.find<LocationController>();
          await locationController.fetchZonePolygons();
        } catch (e) {
          debugPrint('❌ Error fetching zones: $e');
        }
      }

      setState(() {
        _isLoadingCurrentLocation = false;
      });
      _isFetchingLocation = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          CustomAppBar(title: 'set_location'.tr, backButton: widget.fromHome),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        height: context.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ResponsiveHelper.isDesktop(context)
                ? Images.addressCity
                : Images.city),
            alignment: ResponsiveHelper.isDesktop(context)
                ? Alignment.center
                : Alignment.bottomCenter,
            fit: BoxFit.fitWidth,
          ),
        ),
        child: GetBuilder<AddressController>(builder: (locationController) {
          final bool isLoggedIn = AuthHelper.isLoggedIn();
          return (ResponsiveHelper.isDesktop(context) &&
                  AddressHelper.getUserAddressFromSharedPref() == null)
              ? WebLandingPage(
                  fromSignUp: widget.fromSignUp,
                  fromHome: widget.fromHome,
                  route: widget.route,
                )
              : isLoggedIn
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await locationController.getAddressList();
                        await _getCurrentLocation();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            WebScreenTitleWidget(title: 'select_location'.tr),
                            Center(
                              child: FooterView(
                                minHeight: 0.45,
                                child: SizedBox(
                                  width: Dimensions.webMaxWidth,
                                  child: Column(
                                    children: [
                                      // Location Type Selection Radio Buttons
                                      _buildLocationTypeSelector(),
                                      const SizedBox(
                                          height: Dimensions.paddingSizeLarge),

                                      // Current Location Section with Mini Map
                                      if (_selectedLocationType ==
                                          'current') ...[
                                        _buildCurrentLocationSection(),
                                        const SizedBox(
                                            height:
                                                Dimensions.paddingSizeLarge),
                                      ],

                                      // Saved Locations Section
                                      if (_selectedLocationType == 'saved') ...[
                                        _buildSavedLocationsSection(
                                            locationController),
                                        const SizedBox(
                                            height:
                                                Dimensions.paddingSizeLarge),
                                      ],

                                      // Action Buttons
                                      _buildActionButtons(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: FooterView(
                          child: SizedBox(
                              width: 700,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(Images.deliveryLocation,
                                        height: 220),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeLarge),
                                    Text(
                                        'find_stores_and_items'
                                            .tr
                                            .toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: robotoMedium.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeExtraLarge)),
                                    Padding(
                                      padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeLarge),
                                      child: Text(
                                        'by_allowing_location_access'.tr,
                                        textAlign: TextAlign.center,
                                        style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context)
                                                .disabledColor),
                                      ),
                                    ),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeLarge),
                                    Padding(
                                      padding: ResponsiveHelper.isWeb()
                                          ? EdgeInsets.zero
                                          : const EdgeInsets.symmetric(
                                              horizontal:
                                                  Dimensions.paddingSizeLarge),
                                      child: BottomButton(
                                          fromSignUp: widget.fromSignUp,
                                          route: widget.route,
                                          preloadedLocation: _currentPosition,
                                          preloadedAddress: _currentLocation),
                                    ),
                                  ]))),
                    ));
        }),
      ),
    );
  }

  Widget _buildLocationTypeSelector() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text('current_location'.tr),
              // ignore: deprecated_member_use
              leading: Radio<String>(
                value: 'current',
                // ignore: deprecated_member_use
                groupValue: _selectedLocationType,
                // ignore: deprecated_member_use
                onChanged: (String? value) {
                  setState(() {
                    _selectedLocationType = value!;
                  });
                },
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).primaryColor;
                  }
                  return Theme.of(context).unselectedWidgetColor;
                }),
              ),
              onTap: () {
                setState(() {
                  _selectedLocationType = 'current';
                });
              },
            ),
          ),
          Expanded(
            child: ListTile(
              title: Text('saved_addresses'.tr),
              // ignore: deprecated_member_use
              leading: Radio<String>(
                value: 'saved',
                // ignore: deprecated_member_use
                groupValue: _selectedLocationType,
                // ignore: deprecated_member_use
                onChanged: (String? value) {
                  setState(() {
                    _selectedLocationType = value!;
                  });
                },
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).primaryColor;
                  }
                  return Theme.of(context).unselectedWidgetColor;
                }),
              ),
              onTap: () {
                setState(() {
                  _selectedLocationType = 'saved';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationSection() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, color: Theme.of(context).primaryColor),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'current_location'.tr,
                style:
                    robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Mini Map
          if (_cameraPosition == null)
            Container(
              height: 300, // Made bigger to match the map
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_currentPosition != null)
            Container(
              height: 300, // Made bigger as requested
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: GetBuilder<LocationController>(
                  id: 'zones',
                  builder: (locationController) {
                    return Stack(
                      children: [
                        GoogleMap(
                          key: ValueKey('access_location_map_${_currentPosition?.latitude}_${_currentPosition?.longitude}'),
                          initialCameraPosition: _cameraPosition!,
                          onMapCreated: (GoogleMapController controller) async {
                            _mapController = controller;
                            
                            debugPrint(
                                '🗺️ Map created with current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
                            
                            if (_cameraPosition != null) {
                              await controller.moveCamera(
                                CameraUpdate.newCameraPosition(_cameraPosition!),
                              );
                              debugPrint('🗺️ Camera moved to: ${_cameraPosition!.target.latitude}, ${_cameraPosition!.target.longitude}');
                            } else {
                              await controller.moveCamera(
                                CameraUpdate.newLatLngZoom(
                                  _currentPosition!,
                                  16,
                                ),
                              );
                              debugPrint('🗺️ Camera moved to current location (fallback)');
                            }
                            
                            debugPrint('🚫 NO ROUTE CHANGES - Map controller stored and camera moved');
                          },
                          onTap: (LatLng tappedPosition) async {
                            if (_mapController != null) {
                              await _mapController!.animateCamera(
                                CameraUpdate.newLatLng(tappedPosition),
                              );
                            } else {
                              await _onUserPickLocationOnMiniMap(
                                tappedPosition,
                                shouldAnimateCamera: false,
                              );
                            }
                          },
                          onCameraMove: (CameraPosition cameraPosition) {
                            _lastCameraPosition = cameraPosition;
                            _pinDebounceTimer?.cancel();
                            _pinDebounceTimer = Timer(const Duration(milliseconds: 400), () {
                              // Timer will trigger validation after user stops dragging
                            });
                          },
                          onCameraIdle: () async {
                            _pinDebounceTimer?.cancel();
                            if (_lastCameraPosition == null) {
                              return;
                            }
                            
                            final locationController = Get.find<LocationController>();
                            final LatLng currentPoint = _lastCameraPosition!.target;
                            
                            // 🔥 CRITICAL LOOP PREVENTION: Skip validation during zone correction
                            if (locationController.isZoneCorrectionInProgress) {
                              debugPrint('⏸️ AccessLocationScreen: Zone correction in progress - skipping onCameraIdle validation');
                              return;
                            }
                            
                            // 🔥 CRITICAL GUARD: Don't validate or redirect before zones are loaded
                            if (!locationController.zonesLoaded || locationController.zones.isEmpty) {
                              debugPrint('⏸️ AccessLocationScreen: Zones not loaded yet - skipping validation');
                              debugPrint('   → Zones loaded: ${locationController.zonesLoaded}, Zones count: ${locationController.zones.length}');
                              debugPrint('   → No validation or redirect until zones are loaded');
                              // Still update location (user can move map freely)
                            await _onUserPickLocationOnMiniMap(
                                currentPoint,
                              shouldAnimateCamera: false,
                            );
                              return;
                            }
                            
                            // Check if zones have coordinates (required for local validation)
                            final zonesWithCoordinates = locationController.zones.where((z) => 
                              z.status == 1 && 
                              z.formatedCoordinates != null && 
                              z.formatedCoordinates!.isNotEmpty
                            ).toList();
                            
                            if (zonesWithCoordinates.isEmpty) {
                              debugPrint('⏸️ AccessLocationScreen: Zones exist but no coordinates - skipping local validation');
                              debugPrint('   → Backend must return formated_coordinates in /api/v1/zone/list');
                              debugPrint('   → Use API validation (get-zone-id) for now');
                              // Still update location (user can move map freely)
                              await _onUserPickLocationOnMiniMap(
                                currentPoint,
                                shouldAnimateCamera: false,
                              );
                              return;
                            }
                            
                            // ✅ Zones loaded and have coordinates - proceed with validation
                            
                            // 🔥 CRITICAL GUARD: Only validate zone if user confirmed location
                            if (!locationController.isLocationConfirmed) {
                              debugPrint('⏭️ AccessLocationScreen: Skipping zone validation - location not confirmed yet');
                              debugPrint('   → User is just moving map - no validation needed');
                              return;
                            }
                            
                            // 🔥 FIX 3: Guard to prevent auto-redirect loop
                            if (_isAutoMoving) {
                              debugPrint('⏸️ AccessLocationScreen: Auto-move in progress - skipping validation');
                              return;
                            }
                            
                            // 🎯 Validate zone status (only after user confirmation)
                            final ZoneStatus status = locationController.validateZone(currentPoint);
                            
                            // 🟢 Case 1: Inside zone - no intervention needed
                            if (status == ZoneStatus.inside) {
                              // Mark as inside initially if first validation
                              if (!locationController.hasUserConfirmedLocation) {
                                locationController.markWasInsideZoneInitially();
                                debugPrint('✅ AccessLocationScreen: User inside zone initially - no notifications');
                              }
                              return; // No snackbar, no auto-move
                            }
                            
                            // 🟡 Case 2 & 3: Outside zone - show dialog with user choice (with 10s cooldown)
                            // 🔥 UX FIX: Dialog shows if API says outside zone, regardless of zonesLoaded
                            // Dialog is a UX decision, not a technical requirement
                            // API already confirmed: is_in_zone = false → we should inform user immediately
                            // 🔥 UX FIX: Dialog shows every time user goes outside zone, with 10s cooldown
                            // This allows user to move freely and get notified when outside, but not spammed
                            // 🔥 CRITICAL LOOP PREVENTION: Dialog only shows if:
                            // 1. Location is confirmed by user
                            // 2. Not already redirecting
                            // 3. Not already auto-moving
                            // 4. Zone correction NOT in progress
                            // 5. Cooldown period passed (10 seconds since last dialog)
                            // Note: zonesLoaded is NOT required - API decision is authoritative
                            if (status == ZoneStatus.outside && 
                                !locationController.isRedirecting && 
                                !_isAutoMoving && 
                                !locationController.isZoneCorrectionInProgress &&
                                locationController.canShowZoneDialog &&
                                locationController.isLocationConfirmed) {
                              locationController.setRedirecting(true);
                              locationController.markZoneDialogShown();
                              
                              // 🎯 Premium UX: Show dialog asking user if they want redirection
                              showZoneRedirectionDialog(
                                context: context,
                                onConfirm: () async {
                                  // 🔥 CRITICAL: Set correction flag BEFORE auto-move
                                  locationController.setZoneCorrectionInProgress(true);
                                  _isAutoMoving = true;
                                  
                                  // Auto-move camera to nearest allowed point
                                  final LatLng nearestPoint = locationController.nearestAllowedPoint ?? LocationController.DEFAULT_FALLBACK_LOCATION;
                                  if (_mapController != null && nearestPoint != currentPoint) {
                                    debugPrint('📍 AccessLocationScreen: User confirmed - auto-moving camera to nearest allowed point: ${nearestPoint.latitude}, ${nearestPoint.longitude}');
                                    await _mapController!.animateCamera(
                                      CameraUpdate.newLatLng(nearestPoint),
                                    );
                                    
                                    // Wait for camera to settle
                                    await Future.delayed(const Duration(milliseconds: 600));
                                    
                                    // Update position after camera move
                                    setState(() {
                                      _currentPosition = nearestPoint;
                                      _cameraPosition = CameraPosition(target: nearestPoint, zoom: 16);
                                    });
                                    
                                    // 🔥 UX FIX: Get address from geocoding first, then update location
                                    // This ensures we have a proper address before updating
                                    try {
                                      final locationController = Get.find<LocationController>();
                                      final address = await locationController.getAddressFromGeocode(nearestPoint);
                                      debugPrint('📍 AccessLocationScreen: Got address from geocoding: $address');
                                      
                                      // If geocoding returned a valid address, use it
                                      // Otherwise, set a clear default address
                                      if (address.isEmpty || address == 'Unknown Location Found') {
                                        // Set a clear default address
                                        locationController.setPickAddress('الموقع الافتراضي - الرياض');
                                        debugPrint('📍 AccessLocationScreen: Using default address text for fallback location');
                                      } else {
                                        // Use the address from geocoding (it's valid)
                                        locationController.setPickAddress(address);
                                        debugPrint('📍 AccessLocationScreen: Using address from geocoding: $address');
                                      }
                                    } catch (e) {
                                      debugPrint('⚠️ AccessLocationScreen: Error getting address from geocoding: $e');
                                      // Set default address if geocoding fails
                                      final locationController = Get.find<LocationController>();
                                      locationController.setPickAddress('الموقع الافتراضي - الرياض');
                                    }
                                    
                                    // Update location model after move (this will trigger zone check, but correction flag prevents loop)
                                    await _onUserPickLocationOnMiniMap(
                                      nearestPoint,
                                      shouldAnimateCamera: false,
                                    );
                                    
                                    // Wait a bit more before allowing validation again
                                    await Future.delayed(const Duration(milliseconds: 400));
                                    
                                    // 🔥 CRITICAL: Reset guards AFTER everything settles
                                    _isAutoMoving = false;
                                    locationController.setZoneCorrectionInProgress(false);
                                    locationController.resetRedirectGuard();
                                    
                                    debugPrint('✅ AccessLocationScreen: Zone correction completed - validation re-enabled');
                                  } else {
                                    // If no move needed, reset immediately
                                    _isAutoMoving = false;
                                    locationController.setZoneCorrectionInProgress(false);
                                    locationController.resetRedirectGuard();
                                  }
                                },
                                onCancel: () {
                                  // User chose "No, go to home"
                                  debugPrint('⬅️ AccessLocationScreen: User chose to go home');
                                  locationController.resetRedirectGuard();
                                  Get.offAllNamed<void>(RouteHelper.getInitialRoute());
                                },
                              );
                            } else if (status == ZoneStatus.inside) {
                              // Inside zone: Update location normally
                              await _onUserPickLocationOnMiniMap(
                                currentPoint,
                                shouldAnimateCamera: false,
                              );
                            }
                          },
                          markers: {
                            Marker(
                              markerId: const MarkerId('current_location'),
                              position: _currentPosition!,
                              infoWindow:
                                  InfoWindow(title: 'current_location'.tr),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen),
                            ),
                          },
                          // 🎯 CRITICAL: Use zonesLoaded to show polygons only after zones are loaded
                          polygons: locationController.zonesLoaded ? locationController.zonePolygons : {},
                          style: Get.isDarkMode
                              ? Get.find<ThemeController>().darkMap
                              : Get.find<ThemeController>().lightMap,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                          myLocationEnabled: false,
                          compassEnabled: false,
                        ),

                        // GPS/location loading overlay (never blocks the map)
                        if (_isLoadingCurrentLocation || !_mapReady)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .cardColor
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Zones loading overlay (never blocks the map)
                    GetBuilder<LocationController>(
                      id: 'zones',
                      builder: (locationController) {
                        if (!locationController.loadingZones) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: Colors.transparent,
                              color: Theme.of(context).primaryColor,
                            ),
                        );
                      },
                          ),

                        // Center pin overlay (move the map to move the pin)
                        Center(
                          child: IgnorePointer(
                            child: Image.asset(
                              Images.pickMarker,
                              height: 46,
                              width: 46,
                            ),
                          ),
                        ),

                        // My Location Button
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: FloatingActionButton(
                            // 🔥 FIX: Add unique heroTag to prevent "multiple heroes" error
                            heroTag: 'access_location_confirm_fab',
                            mini: true,
                            backgroundColor: Theme.of(context).cardColor,
                            onPressed: () {
                              if (_mapController != null && _currentPosition != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    _currentPosition!,
                                    16,
                                  ),
                                );
                              }
                            },
                            child: Icon(
                              Icons.my_location,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: 300, // Made bigger to match the map
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      'location_not_available'.tr,
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    TextButton.icon(
                      onPressed: () async {
                        await _getCurrentLocation();
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      label: Text(
                        'retry'.tr,
                        style: robotoMedium.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentLocation != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              _currentLocation!.address ?? 'address_not_available'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedLocationsSection(AddressController locationController) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'saved_addresses'.tr,
                style:
                    robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              // Add New Address Button
              FloatingActionButton.small(
                // 🔥 FIX: Add unique heroTag to prevent "multiple heroes" error
                heroTag: 'location_add_address_fab',
                onPressed: () => Get.toNamed<void>(
                    RouteHelper.getAddAddressRoute(false, false, 0)),
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (locationController.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (locationController.addressList != null)
            locationController.addressList!.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: locationController.addressList!.length,
                    itemBuilder: (context, index) {
                      return AddressWidget(
                        address: locationController.addressList![index],
                        fromAddress: true,
                        onTap: () {
                          Get.dialog<void>(
                            const CustomLoaderWidget(),
                            barrierDismissible: false,
                          );
                          final AddressModel address =
                              locationController.addressList![index];
                          Get.find<LocationController>().saveAddressAndNavigate(
                            context,
                            address,
                            widget.fromSignUp,
                            widget.route,
                            widget.route != null,
                            ResponsiveHelper.isDesktop(context),
                          );
                        },
                        onEditPressed: () {
                          Get.toNamed<void>(RouteHelper.getEditAddressRoute(
                            locationController.addressList![index],
                          ));
                        },
                        onRemovePressed: () {
                          if (Get.isSnackbarOpen) {
                            Get.back<void>();
                          }
                          Get.dialog<void>(
                            AddressConfirmDialogue(
                              icon: Images.locationConfirm,
                              title: 'are_you_sure'.tr,
                              description:
                                  'you_want_to_delete_this_location'.tr,
                              onYesPressed: () {
                                locationController
                                    .deleteUserAddressByID(
                                  locationController.addressList![index].id,
                                  index,
                                )
                                    .then((response) {
                                  Get.back<void>();
                                  if (mounted) {
                                    showCustomSnackBar(
                                      response.message,
                                      isError: !response.isSuccess,
                                    );
                                  }
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  )
                : NoDataScreen(
                    text: 'no_saved_address_found'.tr,
                    fromAddress: true,
                  )
          else
            NoDataScreen(
              text: 'no_saved_address_found'.tr,
              fromAddress: true,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Column(
        children: [
          // Use Current Location Button
          if (_selectedLocationType == 'current')
            CustomButton(
              buttonText: _currentLocation != null
                  ? 'use_current_location'.tr
                  : 'get_current_location'.tr,
              onPressed: () async {
                // ✅ Desired UX:
                // This button confirms the CURRENT PIN (map selection), not GPS.
                // GPS is only used to seed the initial position if we don't have any.
                if (_currentPosition == null) {
                  await _getCurrentLocation(forceRefresh: true);
                  return;
                }

                await _ensureCurrentLocationModelFromPosition(_currentPosition!);
                if (_currentLocation == null) {
                  return;
                }

                // 🔥 CRITICAL: Mark location as confirmed by user
                final locationController = Get.find<LocationController>();
                locationController.confirmLocation();
                debugPrint('✅ AccessLocationScreen: User confirmed location - zone validation enabled');

                // Now validate zone (after user confirmation)
                final zoneResponse = await locationController.getZone(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                  false,
                );
                if (!zoneResponse.isSuccess || zoneResponse.zoneIds.isEmpty) {
                  showCustomSnackBar(
                    'service_not_available_in_this_area'.tr,
                    isError: true,
                  );
                  return;
                }
                _currentLocation!.zoneId = zoneResponse.zoneIds.first;
                _currentLocation!.zoneIds = zoneResponse.zoneIds;
                _currentLocation!.zoneData = zoneResponse.zoneData;
                _currentLocation!.areaIds = zoneResponse.areaIds;

                Get.dialog<void>(
                  const CustomLoaderWidget(),
                  barrierDismissible: false,
                );
                Get.back<void>();
                if (mounted) {
                  Get.find<LocationController>().saveAddressAndNavigate(
                    context,
                    _currentLocation!,
                    widget.fromSignUp,
                    widget.route,
                    widget.route != null,
                    ResponsiveHelper.isDesktop(context),
                  );
                }
              },
              icon: Icons.my_location,
            ),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Choose from Map Button
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              minimumSize: const Size(double.infinity, 50),
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              // 🎯 PERFORMANCE FIX: Pass pre-loaded location to PickMapScreen
              // This prevents duplicate GPS calls and zone validation
              // Try to get location from state, then from LocationController as fallback
              LatLng? preloadedLocation = _currentPosition;
              AddressModel? preloadedAddress = _currentLocation;
              
              // If state doesn't have location, try to get from LocationController
              if (preloadedLocation == null) {
                final locationController = Get.find<LocationController>();
                final position = locationController.position;
                if (position.latitude != 0.0 || position.longitude != 0.0) {
                  preloadedLocation = LatLng(position.latitude, position.longitude);
                  // Try to get address from LocationController
                  final address = locationController.address;
                  if (address != null && address.isNotEmpty) {
                    preloadedAddress = AddressModel(
                      latitude: position.latitude.toString(),
                      longitude: position.longitude.toString(),
                      address: address,
                      addressType: 'current',
                    );
                  }
                  debugPrint('🔍 AccessLocationScreen: Using LocationController position: ${preloadedLocation.latitude}, ${preloadedLocation.longitude}');
                }
              }
              
              if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
                showGeneralDialog(
                  context: Get.context!,
                  pageBuilder: (_, __, ___) {
                    return SizedBox(
                      height: 300,
                      width: 300,
                      child: PickMapScreen(
                        fromSignUp: widget.fromSignUp,
                        canRoute: widget.route != null,
                        fromAddAddress: false,
                        route: widget.route ?? RouteHelper.accessLocation,
                        initialLocation: preloadedLocation,
                        preloadedAddress: preloadedAddress,
                      ),
                    );
                  },
                );
              } else {
                // 🎯 PERFORMANCE FIX: Pass pre-loaded data via arguments
                Get.toNamed<void>(
                  RouteHelper.getPickMapRoute(
                    widget.route ?? RouteHelper.accessLocation,
                    widget.route != null,
                  ),
                  arguments: PickMapScreen(
                    fromSignUp: widget.fromSignUp,
                    canRoute: widget.route != null,
                    fromAddAddress: false,
                    route: widget.route ?? RouteHelper.accessLocation,
                    initialLocation: preloadedLocation,
                    preloadedAddress: preloadedAddress,
                  ),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: Icon(
                    Icons.map,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'choose_from_map'.tr,
                  textAlign: TextAlign.center,
                  style: robotoBold.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomButton extends StatelessWidget {
  final bool fromSignUp;
  final String? route;
  // 🎯 PERFORMANCE FIX: Accept pre-loaded location to pass to PickMapScreen
  final LatLng? preloadedLocation;
  final AddressModel? preloadedAddress;
  const BottomButton({
      super.key,
      required this.fromSignUp,
      required this.route,
      this.preloadedLocation,
      this.preloadedAddress});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
            width: 700,
            child: Column(children: [
              CustomButton(
                buttonText: 'continue'.tr,
                onPressed: () async {
                  debugPrint('🔘 Current location button pressed');
                  // Capture context before async operations
                  final currentContext = context;
                  Get.find<LocationController>().checkPermission(() async {
                    debugPrint(
                        '🔘 Permission granted, getting current location...');
                    Get.dialog<void>(const CustomLoaderWidget(),
                        barrierDismissible: false);

                    // Force refresh the current location by calling getCurrentLocation directly
                    debugPrint('🔘 Force refreshing location...');

                    final AddressModel address = await Get.find<LocationController>()
                        .getCurrentLocation(true);
                    debugPrint(
                        '🔘 Current location obtained: ${address.latitude}, ${address.longitude}');

                    // 🔥 CRITICAL: Mark location as confirmed when user clicks "Use Current Location"
                    final locationController = Get.find<LocationController>();
                    locationController.confirmLocation();
                    debugPrint('✅ AccessLocationScreen: User confirmed location via "Use Current Location" button');

                    // Now validate zone (after user confirmation)
                    final ZoneResponseModel zoneResponse =
                        await locationController.getZone(
                      address.latitude,
                      address.longitude,
                      false,
                    );
                    if (!zoneResponse.isSuccess ||
                        zoneResponse.zoneIds.isEmpty) {
                      Get.back<void>();
                      showCustomSnackBar(
                        'service_not_available_in_this_area'.tr,
                        isError: true,
                      );
                      return;
                    }
                    address.zoneId = zoneResponse.zoneIds.first;
                    address.zoneIds = zoneResponse.zoneIds;
                    address.zoneData = zoneResponse.zoneData;
                    address.areaIds = zoneResponse.areaIds;
                    Get.back<void>();

                    // Save current location and proceed directly (same as logged-in users)
                    // Check if context is still mounted before using it
                    if (currentContext.mounted) {
                      Get.find<LocationController>().saveAddressAndNavigate(
                        currentContext,
                        address,
                        fromSignUp,
                        route,
                        route != null,
                        Get.context != null && ResponsiveHelper.isDesktop(Get.context!),
                      );
                    }
                  });
                },
                icon: Icons.my_location,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: Theme.of(context).primaryColor),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  minimumSize: const Size(Dimensions.webMaxWidth, 50),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  // 🎯 PERFORMANCE FIX: Use pre-loaded location passed to BottomButton
                  // If BottomButton doesn't have location, try to get from LocationController
                  LatLng? finalLocation = preloadedLocation;
                  AddressModel? finalAddress = preloadedAddress;
                  
                  if (finalLocation == null) {
                    final locationController = Get.find<LocationController>();
                    final position = locationController.position;
                    if (position.latitude != 0.0 || position.longitude != 0.0) {
                      finalLocation = LatLng(position.latitude, position.longitude);
                      // Try to get address from LocationController
                      final address = locationController.address;
                      if (address != null && address.isNotEmpty) {
                        finalAddress = AddressModel(
                          latitude: position.latitude.toString(),
                          longitude: position.longitude.toString(),
                          address: address,
                          addressType: 'current',
                        );
                      }
                      debugPrint('🔍 BottomButton: Using LocationController position: ${finalLocation.latitude}, ${finalLocation.longitude}');
                    }
                  }
                  
                  if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
                    showGeneralDialog(
                        context: Get.context!,
                        pageBuilder: (_, __, ___) {
                          return SizedBox(
                              height: 300,
                              width: 300,
                              child: PickMapScreen(
                                  fromSignUp: fromSignUp,
                                  canRoute: route != null,
                                  fromAddAddress: false,
                                  route: route ?? RouteHelper.accessLocation,
                                  initialLocation: finalLocation,
                                  preloadedAddress: finalAddress));
                        });
                  } else {
                    // 🎯 PERFORMANCE FIX: Pass pre-loaded data via arguments
                    Get.toNamed<void>(
                      RouteHelper.getPickMapRoute(
                        route ??
                            (fromSignUp
                                ? RouteHelper.signUp
                                : RouteHelper.accessLocation),
                        route != null,
                      ),
                      arguments: PickMapScreen(
                        fromSignUp: fromSignUp,
                        canRoute: route != null,
                        fromAddAddress: false,
                        route: route ?? RouteHelper.accessLocation,
                        initialLocation: finalLocation,
                        preloadedAddress: finalAddress,
                      ),
                    );
                  }
                },
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        right: Dimensions.paddingSizeExtraSmall),
                    child:
                        Icon(Icons.map, color: Theme.of(context).primaryColor),
                  ),
                  Text('set_from_map'.tr,
                      textAlign: TextAlign.center,
                      style: robotoBold.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeLarge,
                      )),
                ]),
              ),
            ])));
  }
}
