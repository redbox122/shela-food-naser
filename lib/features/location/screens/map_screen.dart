import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/marker_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/widgets/address_details_widget.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:async';
import 'dart:io';

class MapScreen extends StatefulWidget {
  final AddressModel address;
  final bool fromStore;
  final bool isFood;
  final String storeName;
  const MapScreen(
      {super.key,
      required this.address,
      this.fromStore = false,
      this.isFood = false,
      required this.storeName});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late LatLng _latLng;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool isHovered = false;
  bool _isLoadingLocation = false;
  Timer? _connectivityProbeTimer;
  bool _isCheckingConnectivity = true;
  bool _showConnectivityError = false;

  @override
  void initState() {
    super.initState();

    // Start with saved address as fallback, but try to get actual GPS location
    _latLng = LatLng(double.parse(widget.address.latitude!),
        double.parse(widget.address.longitude!));

    // Try to get actual GPS location
    _getCurrentLocation();
    _startConnectivityProbe();
  }

  @override
  void dispose() {
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      debugPrint('🗺️ MapScreen: Getting actual GPS location...');
      final AddressModel currentLocation =
          await Get.find<LocationController>().getCurrentLocation(false);

      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        debugPrint(
            '🗺️ MapScreen: Got GPS location: ${currentLocation.latitude}, ${currentLocation.longitude}');
        setState(() {
          _latLng = LatLng(
            double.parse(currentLocation.latitude!),
            double.parse(currentLocation.longitude!),
          );
        });
      } else {
        debugPrint('🗺️ MapScreen: GPS location failed, using saved address');
      }
    } catch (e) {
      debugPrint('🗺️ MapScreen: Error getting GPS location: $e');
      // Keep using saved address as fallback
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void onEntered(bool isHovered) {
    // 🔥 FIX: Use Future.microtask to prevent setState during mouse tracking
    // This prevents "Failed assertion: '!_debugDuringDeviceUpdate'" error
    Future.microtask(() {
      if (mounted) {
    setState(() {
      this.isHovered = isHovered;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showConnectivityError && !_isCheckingConnectivity) {
      return Scaffold(
        appBar: CustomAppBar(
            title: widget.storeName != 'null' && widget.storeName.isNotEmpty
                ? widget.storeName
                : 'location'.tr),
        body: ErrorStateView(
          titleKey: 'something_went_wrong',
          subtitleKey: 'no_internet_connection',
          onRetry: _startConnectivityProbe,
        ),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(
          title: widget.storeName != 'null' && widget.storeName.isNotEmpty
              ? widget.storeName
              : 'location'.tr),
      body: SingleChildScrollView(
        physics: isHovered || !ResponsiveHelper.isDesktop(context)
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        child: FooterView(
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              height: ResponsiveHelper.isDesktop(context)
                  ? 600
                  : MediaQuery.of(context).size.height * 0.85,
              child: Stack(children: [
                MouseRegion(
                  onEnter: (event) {
                    // 🔥 FIX: Defer setState to prevent mouse_tracker assertion error
                    Future.microtask(() => onEntered(true));
                  },
                  onExit: (event) {
                    // 🔥 FIX: Defer setState to prevent mouse_tracker assertion error
                    Future.microtask(() => onEntered(false));
                  },
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _latLng, zoom: 16),
                    minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    indoorViewEnabled: true,
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _setMarker();
                    },
                    style: Get.isDarkMode
                        ? Get.find<ThemeController>().darkMap
                        : Get.find<ThemeController>().lightMap,
                  ),
                ),
                // Loading indicator while getting GPS location
                if (_isLoadingLocation)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Getting your current location...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: Dimensions.paddingSizeLarge,
                  right: Dimensions.paddingSizeLarge,
                  bottom: Dimensions.paddingSizeLarge,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => _checkPermission(() async {
                            setState(() {
                              _isLoadingLocation = true;
                            });
                            try {
                              final AddressModel address =
                                  await Get.find<LocationController>()
                                      .getCurrentLocation(false,
                                          mapController: _mapController);
                              setState(() {
                                _latLng = LatLng(
                                  double.parse(address.latitude!),
                                  double.parse(address.longitude!),
                                );
                              });
                              _setMarker(
                                  address: address, fromCurrentLocation: true);
                            } finally {
                              setState(() {
                                _isLoadingLocation = false;
                              });
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Theme.of(context).cardColor),
                            child: Icon(Icons.my_location_outlined,
                                color: Theme.of(context).primaryColor,
                                size: 25),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      InkWell(
                        onTap: () {
                          if (_mapController != null) {
                            _mapController!.animateCamera(
                                CameraUpdate.newCameraPosition(
                                    CameraPosition(target: _latLng, zoom: 17)));
                          }
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusSmall),
                            color: Theme.of(context).cardColor,
                            // boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), spreadRadius: 3, blurRadius: 10)],
                          ),
                          child: widget.fromStore
                              ? Row(children: [
                                  Expanded(
                                    child: Text(widget.address.address ?? '',
                                        style: robotoMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeDefault),
                                  InkWell(
                                    onTap: () async {
                                      final String url =
                                          'https://www.google.com/maps/dir/?api=1&destination=${widget.address.latitude}'
                                          ',${widget.address.longitude}&mode=d';
                                      if (await canLaunchUrlString(url)) {
                                        await launchUrlString(url,
                                            mode:
                                                LaunchMode.externalApplication);
                                      } else {
                                        showCustomSnackBar(
                                            'unable_to_launch_google_map'.tr);
                                      }
                                    },
                                    child: const Icon(Icons.directions),
                                  ),
                                ])
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(
                                        widget.address.addressType == 'home'
                                            ? Icons.home_outlined
                                            : widget.address.addressType ==
                                                    'office'
                                                ? Icons.work_outline
                                                : Icons.location_on,
                                        size: 30,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(
                                          width: Dimensions.paddingSizeSmall),
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                  widget
                                                      .address.addressType!.tr,
                                                  style: robotoRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    color: Theme.of(context)
                                                        .disabledColor,
                                                  )),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraSmall),
                                              AddressDetailsWidget(
                                                  addressDetails:
                                                      widget.address),
                                            ]),
                                      ),
                                    ]),
                                    const SizedBox(
                                        height: Dimensions.paddingSizeSmall),
                                    Text(
                                        '- ${widget.address.contactPersonName}',
                                        style: robotoMedium.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: Dimensions.fontSizeLarge,
                                        )),
                                    Text(
                                        '- ${widget.address.contactPersonNumber}',
                                        style: robotoRegular),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _setMarker(
      {AddressModel? address, bool fromCurrentLocation = false}) async {
    final BitmapDescriptor markerIcon =
        await MarkerHelper.convertAssetToBitmapDescriptor(
      width: widget.isFood ? 50 : 50,
      imagePath: widget.fromStore
          ? widget.isFood
              ? Images.restaurantMarker
              : Images.markerStore
          : Images.locationMarker,
    );

    final BitmapDescriptor myLocationMarkerIcon =
        await MarkerHelper.convertAssetToBitmapDescriptor(
      width: 50,
      imagePath: Images.userMarker,
    );

    _markers = <Marker>{};

    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('marker'),
        position: _latLng,
        icon: markerIcon,
      ));
    });

    if (address == null) {
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('id--1'),
          zIndexInt: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          position: LatLng(
            double.parse(
                AddressHelper.getUserAddressFromSharedPref()!.latitude!),
            double.parse(
                AddressHelper.getUserAddressFromSharedPref()!.longitude!),
          ),
          icon: myLocationMarkerIcon,
        ));
      });
    }

    /// Animate to coordinate
    LatLngBounds? bounds;
    if (_mapController != null) {
      if (address != null) {
        if (double.parse(address.latitude!) <
            double.parse(widget.address.latitude!)) {
          bounds = LatLngBounds(
            southwest: LatLng(double.parse(address.latitude!),
                double.parse(address.longitude!)),
            northeast: LatLng(double.parse(widget.address.latitude!),
                double.parse(widget.address.longitude!)),
          );
        } else {
          bounds = LatLngBounds(
            southwest: LatLng(double.parse(widget.address.latitude!),
                double.parse(widget.address.longitude!)),
            northeast: LatLng(double.parse(address.latitude!),
                double.parse(address.longitude!)),
          );
        }
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(
              double.parse(
                  AddressHelper.getUserAddressFromSharedPref()!.latitude!),
              double.parse(
                  AddressHelper.getUserAddressFromSharedPref()!.longitude!)),
          northeast: LatLng(double.parse(widget.address.latitude!),
              double.parse(widget.address.longitude!)),
        );
      }
    }

    final LatLng centerBounds = LatLng(
      (bounds!.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    if (fromCurrentLocation && address != null) {
      final LatLng currentLocation = LatLng(
        double.parse(address.latitude!),
        double.parse(address.longitude!),
      );
      _mapController!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: currentLocation, zoom: GetPlatform.isWeb ? 7 : 15)));
    }

    if (!fromCurrentLocation) {
      _mapController!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds, zoom: GetPlatform.isWeb ? 7 : 15)));
      if (!ResponsiveHelper.isWeb()) {
        zoomToFit(_mapController, bounds, centerBounds, padding: 3.5);
      }
    }

    ///current location marker set
    if (address != null) {
      _markers.add(Marker(
        markerId: const MarkerId('id--2'),
        zIndexInt: 2,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        position: LatLng(
          double.parse(address.latitude!),
          double.parse(address.longitude!),
        ),
        icon: myLocationMarkerIcon,
      ));
      setState(() {});
    }

    if (fromCurrentLocation) {
      setState(() {});
    }
  }

  Future<void> zoomToFit(GoogleMapController? controller, LatLngBounds? bounds,
      LatLng centerBounds,
      {double padding = 0.5}) async {
    bool keepZoomingOut = true;

    while (keepZoomingOut) {
      final LatLngBounds screenBounds = await controller!.getVisibleRegion();
      if (fits(bounds!, screenBounds)) {
        keepZoomingOut = false;
        final double zoomLevel = await controller.getZoomLevel() - padding;

        await controller
            .moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
        break;
      } else {
        // Zooming out by 0.1 zoom level per iteration
        final double zoomLevel = await controller.getZoomLevel() - 0.1;
        await controller
            .moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
      }
    }
  }

  bool fits(LatLngBounds fitBounds, LatLngBounds screenBounds) {
    final bool northEastLatitudeCheck =
        screenBounds.northeast.latitude >= fitBounds.northeast.latitude;
    final bool northEastLongitudeCheck =
        screenBounds.northeast.longitude >= fitBounds.northeast.longitude;

    final bool southWestLatitudeCheck =
        screenBounds.southwest.latitude <= fitBounds.southwest.latitude;
    final bool southWestLongitudeCheck =
        screenBounds.southwest.longitude <= fitBounds.southwest.longitude;

    return northEastLatitudeCheck &&
        northEastLongitudeCheck &&
        southWestLatitudeCheck &&
        southWestLongitudeCheck;
  }

  void _checkPermission(VoidCallback onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      Get.dialog<void>(const PermissionDialogWidget());
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog<void>(const PermissionDialogWidget());
    } else {
      onTap();
    }
  }
}
