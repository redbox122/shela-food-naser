import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/features/location/widgets/serach_location_widget.dart';
import 'package:sixam_mart/features/location/widgets/zone_redirection_dialog.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'dart:async';
import 'dart:io';

class PickMapScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromAddAddress;
  final bool canRoute;
  final String? route;
  final GoogleMapController? googleMapController;
  final Function(AddressModel address)? onPicked;
  final bool fromLandingPage;
  // 🎯 PERFORMANCE FIX: Accept pre-loaded location to avoid duplicate GPS calls
  final LatLng? initialLocation;
  final AddressModel? preloadedAddress;
  const PickMapScreen({
    super.key,
    required this.fromSignUp,
    required this.fromAddAddress,
    required this.canRoute,
    required this.route,
    this.googleMapController,
    this.onPicked,
    this.fromLandingPage = false,
    this.initialLocation,
    this.preloadedAddress,
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  late LatLng _initialPosition;
  bool locationAlreadyAllow = false;
  
  // 🎯 PERFORMANCE FIX: Lazy load GoogleMap to prevent skipped frames
  // Don't build map immediately - wait for first frame to render
  bool _mapReady = false;
  // 🎯 LIFECYCLE FIX: Prevent re-initialization when returning from background
  bool _hasInitialized = false;
  // 🎯 PERFORMANCE: Debounce timer to reduce API calls when dragging pin
  Timer? _pinDebounceTimer;
  Timer? _connectivityProbeTimer;
  bool _isCheckingConnectivity = true;
  bool _showConnectivityError = false;
  bool _isSkippingLocationSelection = false;
  

  @override
  void initState() {
    super.initState();
    
    // 🎯 LIFECYCLE FIX: Skip initialization if already done
    if (_hasInitialized) {
      return;
    }
    _hasInitialized = true;

    if (widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
    }
    
    // 🔥 UX FIX: Entering map = user intention to choose location
    // No need to wait for button press - map entry itself is confirmation
    final locationController = Get.find<LocationController>();
    locationController.confirmLocation();
    debugPrint('✅ PickMapScreen: Location confirmed - user entered map (intention to choose location)');
    
    // 🔥 FIX: Load zones FIRST to ensure green polygons appear
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('🗺️ PickMapScreen: Loading zones first (forceRefresh=true to get formated_coordinates)...');
      await locationController.fetchZonePolygons(forceRefresh: true);
      debugPrint('✅ PickMapScreen: Zones loaded - ${locationController.zones.length} zones, ${locationController.zonePolygons.length} polygons');
    });

    // 🎯 PERFORMANCE FIX: Use pre-loaded location if available (from AccessLocation)
    // This prevents duplicate GPS calls and zone validation
    debugPrint('🗺️ PickMapScreen: initialLocation = ${widget.initialLocation}, preloadedAddress = ${widget.preloadedAddress}');
    if (widget.initialLocation != null) {
      _initialPosition = widget.initialLocation!;
      debugPrint(
          '🗺️ PickMapScreen: Using pre-loaded location: ${_initialPosition.latitude}, ${_initialPosition.longitude}');
    } else {
      // 🔥 DEFAULT PIN LOCATION: Use saved address first, then backend default
      final savedAddress = AddressHelper.getUserAddressFromSharedPref();
      if (savedAddress != null &&
          savedAddress.latitude != null &&
          savedAddress.longitude != null) {
        _initialPosition = LatLng(
          double.parse(savedAddress.latitude!),
          double.parse(savedAddress.longitude!),
        );
        debugPrint(
            '🗺️ PickMapScreen: Using saved address as default pin: ${_initialPosition.latitude}, ${_initialPosition.longitude}');
        debugPrint('   - Address: ${savedAddress.address}');
      } else {
        final defaultLocation =
            Get.find<SplashController>().configModel?.defaultLocation;
        if (defaultLocation != null &&
            defaultLocation.lat != null &&
            defaultLocation.lng != null) {
          _initialPosition = LatLng(
            double.parse(defaultLocation.lat!),
            double.parse(defaultLocation.lng!),
          );
          debugPrint(
              '🗺️ PickMapScreen: Using backend default location: ${_initialPosition.latitude}, ${_initialPosition.longitude}');
        } else {
          _initialPosition = const LatLng(0, 0);
          debugPrint(
              '🗺️ PickMapScreen: No saved/default location available, using (0,0)');
        }
      }
    }

    // 🎯 PERFORMANCE FIX: Defer map initialization to prevent skipped frames
    // First: Let first frame render (no map)
    // Then: Build map after frame is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startConnectivityProbe();
      // Delay map creation by 100ms to let first frame render smoothly
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _mapReady = true;
          });
        }
      });
      
      // 🔥 UI-ONLY FIX: PickMapScreen is UI-only - no GPS requests, no zone validation
      // All location/zone logic is handled by AccessLocationScreen before opening PickMap
      debugPrint('🗺️ PickMapScreen: UI-only mode - no GPS/zone validation');
      
      // 📍 DEFAULT PIN: Set initial pick position to default location
      // This places the pin on the map immediately when it opens
      // User can then move the map to change the location
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // Wait for map to be fully initialized
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) {
            final locationController = Get.find<LocationController>();
            // Set pick position to default location (saved address or West Riyadh center)
            // This ensures the pin appears immediately when map opens at the default location
            locationController.updatePickPositionFromLatLng(_initialPosition);
            debugPrint('📍 PickMapScreen: Default pin set at: ${_initialPosition.latitude}, ${_initialPosition.longitude}');
            debugPrint('   - User can move map to change location');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    // 🎯 PERFORMANCE: Cancel debounce timer
    _pinDebounceTimer?.cancel();
    _connectivityProbeTimer?.cancel();
    super.dispose();
  }

  void _startConnectivityProbe() {
    _connectivityProbeTimer?.cancel();
    setState(() {
      _isCheckingConnectivity = true;
      _showConnectivityError = false;
    });
    _connectivityProbeTimer = Timer(const Duration(seconds: 5), () {
      _resolveConnectivityState();
    });
  }

  Future<void> _resolveConnectivityState() async {
    if (!mounted) {
      return;
    }
    final bool hasConnection = await _hasActiveInternetConnection();
    if (hasConnection && Get.isRegistered<LocationController>()) {
      final LocationController locationController = Get.find<LocationController>();
      if (!locationController.loadingZones &&
          (locationController.zonePolygons.isEmpty ||
              !locationController.zonesLoaded)) {
        await locationController.fetchZonePolygons(forceRefresh: true);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isCheckingConnectivity = false;
      _showConnectivityError = !hasConnection;
    });
  }

  Future<bool> _hasActiveInternetConnection() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // 🔥 UI-ONLY FIX: Removed _getCurrentLocation() - PickMapScreen doesn't request GPS
  // GPS location should be provided via initialLocation parameter from AccessLocationScreen
  
  // 🔥 UI-ONLY FIX: Removed _checkAlreadyLocationEnable() - PickMapScreen doesn't check permissions
  // Permission checking is handled by AccessLocationScreen before opening PickMap

  /// First launch uses `onboarding` after guest login; cold start without intro uses `splash`.
  bool get _canSkipWithDefaultLocation =>
      widget.route == 'splash' || widget.route == 'onboarding';

  Future<void> _skipLocationAndContinueWithDefault() async {
    if (_isSkippingLocationSelection) {
      return;
    }
    setState(() {
      _isSkippingLocationSelection = true;
    });
    try {
      final SplashController splashController = Get.find<SplashController>();
      final String? configLat =
          splashController.configModel?.defaultLocation?.lat;
      final String? configLng =
          splashController.configModel?.defaultLocation?.lng;
      final double? parsedLat =
          configLat != null ? double.tryParse(configLat) : null;
      final double? parsedLng =
          configLng != null ? double.tryParse(configLng) : null;
      final bool hasValidConfigDefault = parsedLat != null &&
          parsedLng != null &&
          (parsedLat != 0 || parsedLng != 0);
      final double latitude = hasValidConfigDefault
          ? parsedLat
          : LocationController.DEFAULT_FALLBACK_LOCATION.latitude;
      final double longitude = hasValidConfigDefault
          ? parsedLng
          : LocationController.DEFAULT_FALLBACK_LOCATION.longitude;
      final String addressText = 'default_app_location_address'.tr;
      if (!mounted) {
        return;
      }
      final LocationController locationController =
          Get.find<LocationController>();
      final ZoneResponseModel zoneResponse = await locationController.getZone(
        latitude.toString(),
        longitude.toString(),
        false,
      );
      if (!mounted) {
        return;
      }
      final AddressModel defaultAddress = AddressModel(
        latitude: latitude.toString(),
        longitude: longitude.toString(),
        addressType: 'current',
        address: addressText,
        zoneId: 0,
        zoneIds: [],
        zoneData: [],
        areaIds: [],
      );
      if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
        defaultAddress.zoneId = zoneResponse.zoneIds.first;
        defaultAddress.zoneIds = List<int>.from(zoneResponse.zoneIds);
        defaultAddress.zoneData = zoneResponse.zoneData;
        defaultAddress.areaIds = List<int>.from(zoneResponse.areaIds);
        locationController.disableZoneChecks();
        locationController.saveAddressAndNavigate(
          context,
          defaultAddress,
          widget.fromSignUp,
          widget.route,
          widget.canRoute,
          ResponsiveHelper.isDesktop(context),
          skipZoneValidation: true,
        );
      } else {
        locationController.saveAddressAndNavigate(
          context,
          defaultAddress,
          widget.fromSignUp,
          widget.route,
          widget.canRoute,
          ResponsiveHelper.isDesktop(context),
          skipZoneValidation: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSkippingLocationSelection = false;
        });
      }
    }
  }

  Widget _buildSkipWithDefaultLocationButton(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final bool disabled = _isSkippingLocationSelection;
    return Opacity(
      opacity: disabled ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _skipLocationAndContinueWithDefault,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: primaryColor, width: 1.5),
              color: primaryColor.withValues(alpha: 0.07),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeDefault,
                horizontal: Dimensions.paddingSizeLarge,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (disabled)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: Dimensions.paddingSizeSmall,
                      ),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'not_now'.tr,
                          textAlign: TextAlign.center,
                          style: robotoBold.copyWith(
                            color: primaryColor,
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                        const SizedBox(
                          height: Dimensions.paddingSizeExtraSmall,
                        ),
                        Text(
                          'skip_use_app_default_location_hint'.tr,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showConnectivityError && !_isCheckingConnectivity) {
      return Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        body: ErrorStateView(
          titleKey: 'something_went_wrong',
          subtitleKey: 'no_internet_connection',
          onRetry: _startConnectivityProbe,
        ),
      );
    }
    return Scaffold(
      backgroundColor: ResponsiveHelper.isDesktop(context)
          ? Colors.transparent
          : Theme.of(context).cardColor,
      body: SafeArea(
          child: Center(
              child: Container(
        height: ResponsiveHelper.isDesktop(context) ? 600 : null,
        width:
            ResponsiveHelper.isDesktop(context) ? 700 : Dimensions.webMaxWidth,
        decoration: context.width > 700
            ? BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              )
            : null,
        child: ResponsiveHelper.isDesktop(context)
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeSmall,
                      horizontal: Dimensions.paddingSizeLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text('type_your_address_here_to_pick_form_map'.tr,
                          style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    GetBuilder<LocationController>(
                      builder: (locationController) {
                        return SearchLocationWidget(
                          mapController: _mapController,
                          pickedAddress: locationController.pickAddress,
                          isEnabled: null,
                          fromDialog: true,
                        );
                      },
                    ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      SizedBox(
                        height: 350,
                        child: Stack(children: [
                          // 🎯 PERFORMANCE FIX: Show loading until map is ready
                          if (!_mapReady)
                            const Center(child: CircularProgressIndicator())
                          else
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusDefault),
                            child: GetBuilder<LocationController>(
                              id: 'zones',
                              builder: (locationController) {
                                return GoogleMap(
                                  key: const ValueKey('pick_map_desktop'),
                              initialCameraPosition: CameraPosition(
                                target: widget.fromAddAddress
                                    ? LatLng(
                                        locationController.position.latitude,
                                        locationController.position.longitude)
                                    : _initialPosition,
                                zoom: 16,
                              ),
                              minMaxZoomPreference:
                                  const MinMaxZoomPreference(0, 16),
                              myLocationButtonEnabled: false,
                                  myLocationEnabled: false,
                                  // Draw any available polygons immediately.
                                  polygons: locationController.zonePolygons,
                              onMapCreated:
                                  (GoogleMapController mapController) async {
                                _mapController = mapController;
                                Get.find<LocationController>()
                                    .setMapController(mapController);
                                debugPrint('🗺️ PickMapScreen: Map created - UI-only mode');
                              },
                              scrollGesturesEnabled: !Get.isDialogOpen!,
                              zoomControlsEnabled: false,
                              onCameraMove: (CameraPosition cameraPosition) {
                                _cameraPosition = cameraPosition;
                                _pinDebounceTimer?.cancel();
                                _pinDebounceTimer = Timer(const Duration(milliseconds: 400), () {
                                  // Timer will trigger validation after user stops dragging
                                });
                              },
                              onCameraMoveStarted: () {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                      Get.find<LocationController>().disableButton();
                                });
                              },
                              onCameraIdle: () {
                                _pinDebounceTimer?.cancel();
                                if (_cameraPosition != null) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                                    final locationController = Get.find<LocationController>();
                                    
                                    // 🔥 CRITICAL LOOP PREVENTION: Skip validation during zone correction
                                    if (locationController.isZoneCorrectionInProgress) {
                                      debugPrint('⏸️ PickMapScreen: Zone correction in progress - skipping onCameraIdle validation');
                                      return;
                                    }
                                    
                                    await locationController.updatePickPositionFromLatLng(_cameraPosition!.target);
                                    if (!mounted) {
                                      return;
                                    }
                                    
                                    try {
                                      final zoneResponse = await locationController.getZone(
                                        _cameraPosition!.target.latitude.toString(),
                                        _cameraPosition!.target.longitude.toString(),
                                        false,
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      
                                      if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
                                        locationController.setInZone(true);
                                        locationController.enableButton();
                                        debugPrint('✅ PickMapScreen: Pin location validated by API - Zone IDs: ${zoneResponse.zoneIds}');
                                      } else {
                                        locationController.setInZone(false);
                                        locationController.disableButton();
                                        debugPrint('❌ PickMapScreen: Pin location rejected by API - outside service area');
                                        
                                        // 🎯 Premium UX: Show dialog asking user if they want redirection
                                        // 🔥 UX FIX: Dialog shows if API says outside zone, regardless of zonesLoaded
                                        // Dialog is a UX decision, not a technical requirement
                                        // API already confirmed: is_in_zone = false → we should inform user immediately
                                        // 🔥 CRITICAL LOOP PREVENTION: Dialog only shows if:
                                        // 1. Location is confirmed by user
                                        // 2. Zone correction NOT in progress
                                        // 3. Dialog NOT shown before (once per session)
                                        // Note: zonesLoaded is NOT required - API decision is authoritative
                                        if (locationController.isLocationConfirmed && 
                                            !locationController.isZoneCorrectionInProgress &&
                                            locationController.canShowZoneDialog) {
                                          locationController.markZoneDialogShown();
                                          
                                          if (!context.mounted) {
                                            return;
                                          }
                                          showZoneRedirectionDialog(
                                            context: context,
                                            onConfirm: () async {
                                              // 🔥 CRITICAL: Set correction flag BEFORE auto-move
                                              locationController.setZoneCorrectionInProgress(true);
                                              
                                              // User chose "Yes, redirect me"
                                              const LatLng defaultLocation = LocationController.DEFAULT_FALLBACK_LOCATION;
                                              if (_mapController != null && _cameraPosition != null) {
                                                debugPrint('📍 PickMapScreen: User confirmed - auto-moving to default fallback location: ${defaultLocation.latitude}, ${defaultLocation.longitude}');
                                                await _mapController!.animateCamera(
                                                  CameraUpdate.newLatLng(defaultLocation),
                                                );
                                                if (!mounted) {
                                                  return;
                                                }
                                                
                                                // Wait for camera to settle
                                                await Future.delayed(const Duration(milliseconds: 600));
                                                
                                                // Update camera position
                                                _cameraPosition = const CameraPosition(target: defaultLocation, zoom: 16);
                                                
                                                // Update pick position (this will trigger zone check, but correction flag prevents loop)
                                                await locationController.updatePickPositionFromLatLng(defaultLocation);
                                                if (!mounted) {
                                                  return;
                                                }
                                                
                                                // Wait a bit more before allowing validation again
                                                await Future.delayed(const Duration(milliseconds: 400));
                                                if (!mounted) {
                                                  return;
                                                }
                                                
                                                // 🔥 CRITICAL: Reset correction flag AFTER everything settles
                                                locationController.setZoneCorrectionInProgress(false);
                                                
                                                debugPrint('✅ PickMapScreen: Zone correction completed - validation re-enabled');
                                              }
                                            },
                                            onCancel: () {
                                              // User chose "No, go to home"
                                              debugPrint('⬅️ PickMapScreen: User chose to go home');
                                              Get.offAllNamed<void>(RouteHelper.getInitialRoute());
                                            },
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('❌ PickMapScreen: Error validating zone: $e');
                                      locationController.setInZone(false);
                                      locationController.disableButton();
                                    }
                                  });
                                }
                              },
                              style: Get.isDarkMode
                                  ? Get.find<ThemeController>().darkMap
                                  : Get.find<ThemeController>().lightMap,
                                );
                              },
                            ),
                          ),
                        GetBuilder<LocationController>(
                          builder: (locationController) {
                            return Center(
                              child: !locationController.loading
                                  ? Image.asset(Images.pickMarker,
                                      height: 50, width: 50)
                                  : const CircularProgressIndicator(),
                            );
                          },
                        ),
                          Positioned(
                            bottom: 30,
                            right: Dimensions.paddingSizeLarge,
                            child: FloatingActionButton(
                              // 🔥 FIX: Add unique heroTag to prevent "multiple heroes" error
                              heroTag: 'pick_map_confirm_fab_1',
                              mini: true,
                              backgroundColor: Theme.of(context).cardColor,
                              onPressed: () => Get.find<LocationController>()
                                  .checkPermission(() async {
                                final AddressModel currentLocation =
                                    await Get.find<LocationController>()
                                        .getCurrentLocation(false,
                                            mapController: _mapController,
                                            forceRefresh: true,
                                            skipZoneValidation: true);
                                if (currentLocation.latitude != null &&
                                    currentLocation.longitude != null) {
                                final newPos = LatLng(
                                      double.parse(currentLocation.latitude!),
                                      double.parse(currentLocation.longitude!),
                                    );
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLng(newPos),
                                );
                                }
                              }),
                              child: Icon(Icons.my_location,
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                      ],
                    ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    if (_canSkipWithDefaultLocation)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeSmall,
                        ),
                        child: _buildSkipWithDefaultLocationButton(context),
                      ),
                    GetBuilder<LocationController>(
                      builder: (locationController) {
                        return CustomButton(
                        isBold: false,
                        radius: Dimensions.radiusSmall,
                        buttonText: locationController.inZone
                            ? widget.fromAddAddress
                                ? 'pick_address'.tr
                                : 'pick_location'.tr
                            : 'service_not_available_in_this_area'.tr,
                        isLoading: locationController.isLoading,
                        onPressed: locationController.isLoading
                            ? () {}
                            : (locationController.buttonDisabled ||
                                    locationController.loading)
                                ? null
                                : () {
                                    _onPickAddressButtonPressed(
                                        locationController);
                                    },
                        );
                                  },
                      ),
                    ],
                  ),
                )
              : Stack(children: [
                  // 🎯 PERFORMANCE FIX: Show loading until map is ready
                  if (!_mapReady)
                    const Center(child: CircularProgressIndicator())
                  else
                  GetBuilder<LocationController>(
                    id: 'zones',
                    builder: (locationController) {
                      return GoogleMap(
                        key: const ValueKey('pick_map_mobile'),
                    initialCameraPosition: CameraPosition(
                      target: widget.fromAddAddress
                              ? LatLng(
                                  locationController.position.latitude,
                              locationController.position.longitude)
                          : _initialPosition,
                      zoom: 16,
                    ),
                    minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                    myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                        // Draw any available polygons immediately.
                        polygons: locationController.zonePolygons,
                    onMapCreated: (GoogleMapController mapController) async {
                      _mapController = mapController;
                      Get.find<LocationController>()
                          .setMapController(mapController);
                      debugPrint('🗺️ PickMapScreen: Map created - UI-only mode');
                    },
                    scrollGesturesEnabled: !Get.isDialogOpen!,
                    zoomControlsEnabled: false,
                    onCameraMove: (CameraPosition cameraPosition) {
                      // 🎯 PREMIUM UX: No validation during drag (performance + UX)
                      // Validation happens only in onCameraIdle (after user stops dragging)
                      _cameraPosition = cameraPosition;
                      _pinDebounceTimer?.cancel();
                      _pinDebounceTimer = Timer(const Duration(milliseconds: 400), () {
                        // Timer will trigger validation after user stops dragging
                      });
                    },
                    onCameraMoveStarted: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                            Get.find<LocationController>().disableButton();
                      });
                    },
                    onCameraIdle: () async {
                      _pinDebounceTimer?.cancel();
                      if (_cameraPosition != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          final locationController = Get.find<LocationController>();
                          
                          // 🔥 CRITICAL LOOP PREVENTION: Skip validation during zone correction
                          if (locationController.isZoneCorrectionInProgress) {
                            debugPrint('⏸️ PickMapScreen: Zone correction in progress - skipping onCameraIdle validation');
                            return;
                          }
                          
                          await locationController.updatePickPositionFromLatLng(_cameraPosition!.target);
                          if (!mounted) {
                            return;
                          }
                          
                              try {
                                final zoneResponse = await locationController.getZone(
                                  _cameraPosition!.target.latitude.toString(),
                                  _cameraPosition!.target.longitude.toString(),
                                  false,
                                );
                                if (!mounted) {
                                  return;
                                }
                                
                                if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
                                  locationController.setInZone(true);
                                  locationController.enableButton();
                              debugPrint('✅ PickMapScreen: Pin location validated by API - Zone IDs: ${zoneResponse.zoneIds}');
                            } else {
                              locationController.setInZone(false);
                              locationController.disableButton();
                              debugPrint('❌ PickMapScreen: Pin location rejected by API - outside service area');
                              
                              // 🎯 Premium UX: Show dialog asking user if they want redirection
                              // 🔥 UX FIX: Dialog shows if API says outside zone, regardless of zonesLoaded
                              // Dialog is a UX decision, not a technical requirement
                              // API already confirmed: is_in_zone = false → we should inform user immediately
                              // 🔥 UX FIX: Dialog shows every time user goes outside zone, with 10s cooldown
                              // This allows user to move freely and get notified when outside, but not spammed
                              // 🔥 CRITICAL LOOP PREVENTION: Dialog only shows if:
                              // 1. Location is confirmed by user
                              // 2. Zone correction NOT in progress
                              // 3. Cooldown period passed (10 seconds since last dialog)
                              // Note: zonesLoaded is NOT required - API decision is authoritative
                              if (locationController.isLocationConfirmed && 
                                  !locationController.isZoneCorrectionInProgress &&
                                  locationController.canShowZoneDialog) {
                                debugPrint('🟠 PickMapScreen: Showing zone redirection dialog - API confirmed outside zone');
                                locationController.markZoneDialogShown();
                                
                                  if (!context.mounted) {
                                    return;
                                  }
                                  showZoneRedirectionDialog(
                                    context: context,
                                  onConfirm: () async {
                                    // 🔥 CRITICAL: Set correction flag BEFORE auto-move
                                    locationController.setZoneCorrectionInProgress(true);
                                    
                                    // User chose "Yes, redirect me"
                                    const LatLng defaultLocation = LocationController.DEFAULT_FALLBACK_LOCATION;
                                    if (_mapController != null && _cameraPosition != null) {
                                      debugPrint('📍 PickMapScreen: User confirmed - auto-moving to default fallback location: ${defaultLocation.latitude}, ${defaultLocation.longitude}');
                                      await _mapController!.animateCamera(
                                        CameraUpdate.newLatLng(defaultLocation),
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      
                                      // Wait for camera to settle
                                      await Future.delayed(const Duration(milliseconds: 600));
                                      if (!mounted) {
                                        return;
                                      }
                                      
                                      // Update camera position
                                      _cameraPosition = const CameraPosition(target: defaultLocation, zoom: 16);
                                      
                                      // 🔥 UX FIX: Get address from geocoding first, then update position
                                      // This ensures we have a proper address before updating
                                      try {
                                        final address = await locationController.getAddressFromGeocode(defaultLocation);
                                        if (!mounted) {
                                          return;
                                        }
                                        debugPrint('📍 PickMapScreen: Got address from geocoding: $address');
                                        
                                        // Update pick position (this will trigger zone check, but correction flag prevents loop)
                                        await locationController.updatePickPositionFromLatLng(defaultLocation);
                                        if (!mounted) {
                                          return;
                                        }
                                        
                                        // If geocoding returned a valid address, use it
                                        // Otherwise, set a clear default address
                                        if (address.isEmpty || address == 'Unknown Location Found') {
                                          // Set a clear default address for the default location
                                          locationController.setPickAddress('الموقع الافتراضي - الرياض');
                                          debugPrint('📍 PickMapScreen: Using default address text for fallback location');
                                        } else {
                                          // Use the address from geocoding (it's valid)
                                          locationController.setPickAddress(address);
                                          debugPrint('📍 PickMapScreen: Using address from geocoding: $address');
                                        }
                                      } catch (e) {
                                        debugPrint('⚠️ PickMapScreen: Error getting address from geocoding: $e');
                                        // Set default address if geocoding fails
                                        locationController.setPickAddress('الموقع الافتراضي - الرياض');
                                        await locationController.updatePickPositionFromLatLng(defaultLocation);
                                        if (!mounted) {
                                          return;
                                        }
                                      }
                                      
                                      // Wait a bit more before allowing validation again
                                      await Future.delayed(const Duration(milliseconds: 400));
                                      if (!mounted) {
                                        return;
                                      }
                                      
                                      // 🔥 CRITICAL: Reset correction flag AFTER everything settles
                                      locationController.setZoneCorrectionInProgress(false);
                                      
                                      debugPrint('✅ PickMapScreen: Zone correction completed - validation re-enabled');
                                    }
                                  },
                                  onCancel: () {
                                    // User chose "No, go to home"
                                    debugPrint('⬅️ PickMapScreen: User chose to go home');
                                    Get.offAllNamed<void>(RouteHelper.getInitialRoute());
                                  },
                                );
                              } else {
                                // 🔍 Debug: Log why dialog didn't show
                                debugPrint('⏸️ PickMapScreen: Dialog not shown - guards:');
                                debugPrint('   → isLocationConfirmed: ${locationController.isLocationConfirmed}');
                                debugPrint('   → isZoneCorrectionInProgress: ${locationController.isZoneCorrectionInProgress}');
                                debugPrint('   → canShowZoneDialog: ${locationController.canShowZoneDialog}');
                              }
                            }
                          } catch (e) {
                            debugPrint('❌ PickMapScreen: Error validating zone: $e');
                            locationController.setInZone(false);
                            locationController.disableButton();
                          }
                        });
                      }
                    },
                    style: Get.isDarkMode
                        ? Get.find<ThemeController>().darkMap
                        : Get.find<ThemeController>().lightMap,
                      );
                    },
                  ),
                GetBuilder<LocationController>(
                  builder: (locationController) {
                    return Center(
                    child: !locationController.loading
                        ? Image.asset(Images.pickMarker, height: 50, width: 50)
                        : const CircularProgressIndicator(),
                    );
                  },
                  ),

                  // search ========================

                  Positioned(
                    top: Dimensions.paddingSizeLarge,
                    left: Dimensions.paddingSizeSmall,
                    right: Dimensions.paddingSizeSmall,
                    child: GetBuilder<LocationController>(
                        builder: (locationController) {
                      return SearchLocationWidget(
                        mapController: _mapController,
                        pickedAddress: locationController.pickAddress,
                        isEnabled: null,
                      );
                    }),
                  ),

                  // 🎯 UX: Zone selection helper message
                GetBuilder<LocationController>(
                  builder: (locationController) {
                    if (locationController.zonePolygons.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      top: Dimensions.paddingSizeLarge + 60,
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: Text(
                                'select_location_in_green_areas'.tr,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                    ),

                  //

                  Positioned(
                    bottom: 80,
                    right: Dimensions.paddingSizeLarge,
                    child: FloatingActionButton(
                      // 🔥 FIX: Add unique heroTag to prevent "multiple heroes" error
                      heroTag: 'pick_map_confirm_fab_2',
                      mini: true,
                      backgroundColor: Theme.of(context).cardColor,
                      onPressed: () => Get.find<LocationController>()
                          .checkPermission(() async {
                        final AddressModel currentLocation =
                            await Get.find<LocationController>()
                                .getCurrentLocation(false,
                                    mapController: _mapController,
                                    forceRefresh: true,
                                    skipZoneValidation: true);
                        if (currentLocation.latitude != null &&
                            currentLocation.longitude != null) {
                        final newPos = LatLng(
                              double.parse(currentLocation.latitude!),
                              double.parse(currentLocation.longitude!),
                            );
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(newPos),
                        );
                        }
                      }),
                      child: Icon(Icons.my_location,
                          color: Theme.of(context).primaryColor),
                    ),
                  ),

                  //

                  Positioned(
                    bottom: Dimensions.paddingSizeLarge,
                    left: Dimensions.paddingSizeLarge,
                    right: Dimensions.paddingSizeLarge,
                  child: GetBuilder<LocationController>(
                    builder: (locationController) {
                      return CustomButton(
                      buttonText: locationController.inZone
                          ? widget.fromAddAddress
                              ? 'pick_address'.tr
                              : 'pick_location'.tr
                          : 'service_not_available_in_this_area'.tr,
                      isLoading: locationController.isLoading,
                      onPressed: locationController.isLoading
                          ? () {}
                          : (locationController.buttonDisabled ||
                                  locationController.loading)
                              ? null
                              : () {
                                  _onPickAddressButtonPressed(
                                      locationController);
                                  },
                      );
                                },
                    ),
                  ),
                  if (_canSkipWithDefaultLocation)
                    Positioned(
                      bottom: Dimensions.paddingSizeLarge + 72,
                      left: Dimensions.paddingSizeLarge,
                      right: Dimensions.paddingSizeLarge,
                      child: _buildSkipWithDefaultLocationButton(context),
                    ),
              ]),
      ))),
    );
  }

  Future<void> _onPickAddressButtonPressed(
      LocationController locationController) async {
    // 🎯 POLYGONS ARE OPTIONAL (UX): Polygons are visual only - zone validation uses API
    // If zones exist but no polygons, it's okay - user can still proceed if API confirms location
    if (locationController.zones.isNotEmpty && locationController.zonePolygons.isEmpty) {
      debugPrint('⚠️ PickMapScreen: Zones exist but no polygons - polygons are optional (visual only)');
      debugPrint('   - Zones: ${locationController.zones.length}, Polygons: ${locationController.zonePolygons.length}');
      debugPrint('ℹ️ Zone validation uses API (get-zone-id) - not polygons');
      // Don't block - polygons are optional, API validation is what matters
    }

    if (locationController.pickPosition.latitude != 0 &&
        locationController.pickAddress!.isNotEmpty) {
      if (widget.onPicked != null) {
        // 🔒 MANDATORY: Always get zone data from API if available, even for onPicked callback
        final AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: 'others',
          address: locationController.pickAddress,
          contactPersonName:
              AddressHelper.getUserAddressFromSharedPref()?.contactPersonName,
          contactPersonNumber:
              AddressHelper.getUserAddressFromSharedPref()?.contactPersonNumber,
        );
        
        // Try to get zone data from API first (mandatory)
        try {
          final zoneResponse = await locationController.getZone(
              address.latitude!, address.longitude!, false);
          if (!context.mounted) {
            return;
          }
          
          if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
            // ✅ Use zone data from API if available
            address.zoneId = zoneResponse.zoneIds[0];
            address.zoneIds = zoneResponse.zoneIds;
            address.zoneData = zoneResponse.zoneData;
            address.areaIds = zoneResponse.areaIds;
            debugPrint(
                '✅ onPicked: Using zone IDs from API: ${address.zoneIds}');
          } else {
            // 🎯 UX: Show friendly message explaining limited coverage
            showCustomSnackBar(
                'we_cover_limited_areas_only'.tr,
                isError: true,
                showDuration: 4);
            debugPrint(
                '🛑 onPicked: Blocked - location outside service area');
            return;
          }
        } catch (e) {
          debugPrint('❌ onPicked: Error getting zone data from API: $e');
          // 🎯 UX: Show friendly message explaining limited coverage
          showCustomSnackBar(
              'we_cover_limited_areas_only'.tr,
              isError: true,
              showDuration: 4);
          return;
        }
        
        widget.onPicked!(address);
        Get.back();
      } else if (widget.fromAddAddress) {
        if (widget.googleMapController != null) {
          widget.googleMapController!
              .moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
                  target: LatLng(
                    locationController.pickPosition.latitude,
                    locationController.pickPosition.longitude,
                  ),
                  zoom: 16)));
          locationController.setAddAddressData();
        }
        Get.back();
      } else {
        final AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: 'others',
          address: locationController.pickAddress,
        );

        // Special handling for cart checkout flow - pass location directly to checkout
        if (widget.route == '/cart') {
          debugPrint(
              '🛒 PickMapScreen: Navigating directly to checkout with selected location');

          // Show loading indicator during zone validation
          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );

          // 🔒 ZONE VALIDATION: API is the only source of truth
          // If API fails, checkout is blocked
          bool zoneValidated = false;
          
          try {
            // 🔒 PRIORITY: Get zone data from API first
            final zoneResponse = await locationController.getZone(
                address.latitude!, address.longitude!, false);

            // Use zone data directly from API response if successful
            if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
              // ✅ API returned valid zone data - use it exactly as is
              address.zoneId = zoneResponse.zoneIds[0];
              address.zoneIds = zoneResponse.zoneIds;
              address.zoneData = zoneResponse.zoneData;
              address.areaIds = zoneResponse.areaIds;
              zoneValidated = true;
              
              debugPrint('✅ Zone validation (API): Success - using zone data from API');
              debugPrint('   - Zone IDs: ${address.zoneIds}');
              debugPrint('   - Zone Data count: ${zoneResponse.zoneData.length}');
              debugPrint('   - Area IDs: ${zoneResponse.areaIds}');
            } else {
              // API returned failure - block checkout
              zoneValidated = false;
              debugPrint('❌ Zone validation (API): Failed - API returned failure');
              debugPrint('   - Status Code: ${zoneResponse.statusCode}');
              debugPrint('   - isSuccess: ${zoneResponse.isSuccess}');
            }
          } catch (e) {
            // API call failed - block checkout
            zoneValidated = false;
            debugPrint('❌ Zone validation error: $e');
          }

          // Close loading dialog
          if (Get.isDialogOpen ?? false) {
            Get.back();
            await Future.delayed(const Duration(milliseconds: 100));
          }

         // GUARD: Block checkout if API validation failed
         if (!zoneValidated) {
           // Close any existing dialogs first to avoid stacking
           if (Get.isDialogOpen ?? false) {
             Get.back();
             await Future.delayed(const Duration(milliseconds: 100));
           }
           // 🎯 UX: Show friendly message explaining limited coverage
           showCustomSnackBar(
               'we_cover_limited_areas_only'.tr,
               isError: true,
               showDuration: 4);
           debugPrint('🛑 PickMapScreen: Blocked checkout - location outside service area');
           debugPrint('   - Selected location: ${address.latitude}, ${address.longitude}');
           debugPrint('   - Address: ${address.address}');
           return; // Stop here - don't navigate to checkout
         }

          // 🔒 CRITICAL FIX: Ensure cart data is preserved before navigation
          // LOCAL-FIRST APPROACH: Use getCartDataOnline which already implements local-first protection
          // The getCartDataOnline method in CartController:
          // 1. Loads from local storage first (Hive/SharedPreferences) - lines 643-676
          // 2. Preserves local cart if API returns empty - lines 934-960
          // 3. Only overwrites local cart if API has valid data
          final cartController = Get.find<CartController>();
          
          // Check if cart is empty before attempting reload
          if (cartController.cartList.isEmpty) {
            debugPrint('⚠️ PickMapScreen: Cart is empty - attempting to reload (local-first)');
            try {
              // getCartDataOnline() already implements LOCAL-FIRST protection:
              // - Loads from local storage first (Hive/SharedPreferences)
              // - Preserves local cart if API returns empty
              // - Only overwrites if API has valid data
              await cartController.getCartDataOnline();
              debugPrint('🔄 PickMapScreen: Reloaded cart (local-first) - ${cartController.cartList.length} items');
              
              // If still empty after local-first reload, this is a real empty cart
              if (cartController.cartList.isEmpty) {
                debugPrint('❌ PickMapScreen: Cart is truly empty - cannot proceed to checkout');
                showCustomSnackBar('please_add_items_to_cart_first'.tr, isError: true);
                return;
              }
            } catch (e) {
              debugPrint('❌ PickMapScreen: Error reloading cart: $e');
              showCustomSnackBar('error_loading_cart'.tr, isError: true);
              return;
            }
          } else {
            debugPrint('✅ PickMapScreen: Cart has ${cartController.cartList.length} items - proceeding to checkout');
          }

          // Only navigate to checkout if zone validation succeeded and cart is not empty
          Get.back(); // Close the pick-map screen
          // ✅ ARCHITECTURAL FIX: Pass cartList via arguments
          final storeId = cartController.cartList.isNotEmpty
              ? cartController.cartList.first.item?.storeId
              : null;
          if (storeId != null) {
            RouteHelper.navigateToCheckout(
              cartList: cartController.cartList,
              storeId: storeId,
            );
          } else {
            debugPrint('❌ Cannot navigate to checkout - storeId is null');
            showCustomSnackBar('Unable to proceed to checkout. Please try again.'.tr);
          }
          return;
        }

        // 🔒 MANDATORY: For non-cart routes, try to get zone data from API before proceeding
        // This ensures all addresses have proper zone information from API if available
        try {
          final zoneResponse = await locationController.getZone(
              address.latitude!, address.longitude!, false);
          
          if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
            // ✅ API confirmed location is in zone - save zone data
            address.zoneId = zoneResponse.zoneIds[0];
            address.zoneIds = zoneResponse.zoneIds;
            address.zoneData = zoneResponse.zoneData;
            address.areaIds = zoneResponse.areaIds;
            debugPrint(
                '✅ General flow: Using zone IDs from API: ${address.zoneIds}');
          } else {
            // ❌ API rejected location - block saving
            debugPrint('❌ General flow: API rejected location - blocking save');
            showCustomSnackBar(
              'we_cover_limited_areas_only'.tr,
              isError: true,
              showDuration: 4,
            );
            return; // Block save - no zone_id means invalid location
          }
        } catch (e) {
          debugPrint('❌ General flow: Error getting zone data from API: $e');
          // On error, block save to be safe
          showCustomSnackBar(
            'we_cover_limited_areas_only'.tr,
            isError: true,
            showDuration: 4,
          );
          return; // Block save - API error means we can't validate
        }

        if (!mounted) {
          return;
        }

        if (widget.fromLandingPage) {
          if (!AuthHelper.isGuestLoggedIn() && !AuthHelper.isLoggedIn()) {
            Get.find<AuthController>().guestLogin().then((response) {
              if (response.isSuccess) {
                if (!mounted) {
                  return;
                }
                Get.find<ProfileController>().setForceFullyUserEmpty();
                Get.back();
                locationController.saveAddressAndNavigate(
                  context,
                  address,
                  widget.fromSignUp,
                  widget.route,
                  widget.canRoute,
                  Get.context != null && ResponsiveHelper.isDesktop(Get.context!),
                );
              }
            });
          } else {
            Get.back();
            locationController.saveAddressAndNavigate(
              context,
              address,
              widget.fromSignUp,
              widget.route,
              widget.canRoute,
              ResponsiveHelper.isDesktop(context),
            );
          }
        } else {
          locationController.saveAddressAndNavigate(
            context,
            address,
            widget.fromSignUp,
            widget.route,
            widget.canRoute,
            ResponsiveHelper.isDesktop(context),
          );
        }
      }
    } else {
      showCustomSnackBar('pick_an_address'.tr);
    }
  }

  // 🔥 UI-ONLY FIX: Removed _locationCheck() - PickMapScreen doesn't check permissions
  // Permission checking is handled by AccessLocationScreen before opening PickMap
}
