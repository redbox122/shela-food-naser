import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/models/check_zone_model.dart';
import 'package:sixam_mart/features/address/domain/services/address_v2_api.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/out_of_zone_dialog.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: Full-screen map location picker (new address flow).
///
/// Flow (guest): Home "join us" banner → this screen → pick a point on the map
/// → "confirm address" → Address Details screen.
///
/// The button starts DISABLED ("enter the address") until the user moves the
/// map to a valid (in-zone) point; then it turns green ("confirm address").
///
/// Zone validation + reverse geocoding reuse [LocationController]; this screen
/// keeps its own lightweight selection state so it never interferes with the
/// legacy [PickMapScreen] used by checkout/sign-up flows.
class SelectLocationScreen extends StatefulWidget {
  /// Origin page tag (e.g. 'home'), forwarded to the next step if needed.
  final String? route;
  const SelectLocationScreen({super.key, this.route});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  // Bottom area reserved for the sheet/button so the map center (camera target)
  // and the pin both sit in the visible region above it.
  static const double _kBottomInset = 150;

  GoogleMapController? _mapController;
  late LatLng _initialPosition;

  bool _mapReady = false;

  // Selection state (local — does not touch other flows).
  LatLng? _pickedLatLng;
  String? _pickedAddress;
  bool _isInZone = false;
  CheckZoneModel? _checkZone;

  final AddressV2Api _addressApi = AddressV2Api();

  bool _isResolving = false; // check-zone in flight
  // Only enable after the user actually moves the map (matches the design:
  // pin is shown but button stays disabled until a deliberate pick).
  bool _hasUserMovedMap = false;
  // Show the out-of-zone dialog once per out-of-zone visit (reset on re-entry).
  bool _outOfZoneDialogShown = false;

  Timer? _idleDebounce;
  int _resolveToken = 0;

  LocationController get _location => Get.find<LocationController>();

  @override
  void initState() {
    super.initState();
    _initialPosition = _resolveInitialPosition();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show the map quickly — don't block on the network. Zone polygons are
      // fetched in the background and render (green) as soon as they arrive.
      unawaited(_location.fetchZonePolygons(forceRefresh: true));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _mapReady = true);
      });
    });
  }

  @override
  void dispose() {
    _idleDebounce?.cancel();
    super.dispose();
  }

  LatLng _resolveInitialPosition() {
    final saved = AddressHelper.getUserAddressFromSharedPref();
    if (saved?.latitude != null && saved?.longitude != null) {
      final lat = double.tryParse(saved!.latitude!);
      final lng = double.tryParse(saved.longitude!);
      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        return LatLng(lat, lng);
      }
    }
    final def = Get.find<SplashController>().configModel?.defaultLocation;
    final lat = double.tryParse(def?.lat ?? '');
    final lng = double.tryParse(def?.lng ?? '');
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      return LatLng(lat, lng);
    }
    return LocationController.DEFAULT_FALLBACK_LOCATION;
  }

  // ───────────────────────── map callbacks ─────────────────────────

  void _onCameraMoveStarted() {
    _hasUserMovedMap = true;
    _idleDebounce?.cancel();
    if (!_isResolving || _pickedAddress != null) {
      setState(() {
        _isResolving = true;
        _pickedAddress = null;
        _isInZone = false;
      });
    }
  }

  void _onCameraIdle(LatLng target) {
    if (!_hasUserMovedMap) return; // honor "enter the address" initial state
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 350), () {
      _resolvePoint(target);
    });
  }

  /// Validate the picked point via the v2 check-zone endpoint (it also returns
  /// the parsed address parts used to pre-fill the next screen).
  Future<void> _resolvePoint(LatLng target) async {
    final int token = ++_resolveToken;
    if (mounted) setState(() => _isResolving = true);

    CheckZoneModel? zone;
    try {
      zone = await _addressApi.checkZone(target.latitude, target.longitude);
    } catch (e) {
      debugPrint('⚠️ SelectLocationScreen: check-zone failed: $e');
    }

    // Drop stale results (user kept moving).
    if (!mounted || token != _resolveToken) return;

    final bool inZone = zone?.inZone == true;
    final String text = zone?.address?.displayText ?? '';
    setState(() {
      _pickedLatLng = target;
      _checkZone = zone;
      _pickedAddress = text.isNotEmpty ? text : null;
      _isInZone = inZone;
      _isResolving = false;
    });

    if (inZone) {
      _outOfZoneDialogShown = false;
    } else if (zone != null && !_outOfZoneDialogShown) {
      // The point is confirmed outside coverage → offer redirect.
      _showOutOfZoneDialog();
    }
  }

  void _showOutOfZoneDialog() {
    _outOfZoneDialogShown = true;
    showOutOfZoneDialog(
      onConfirm: () async {
        // Auto-move to the nearest serviceable point; the camera-idle handler
        // then re-validates it (and resets the dialog guard).
        _hasUserMovedMap = true;
        await _mapController?.animateCamera(
          CameraUpdate.newLatLng(LocationController.DEFAULT_FALLBACK_LOCATION),
        );
      },
      onCancel: () => Get.offAllNamed(RouteHelper.getMainRoute('home')),
    );
  }

  Future<void> _goToMyLocation() async {
    _location.checkPermission(() async {
      final AddressModel current = await _location.getCurrentLocation(
        false,
        mapController: _mapController,
        forceRefresh: true,
        skipZoneValidation: true,
      );
      if (!mounted) return;
      if (current.latitude != null && current.longitude != null) {
        final pos = LatLng(
          double.parse(current.latitude!),
          double.parse(current.longitude!),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
      }
    });
  }

  bool get _canConfirm =>
      _isInZone &&
      _pickedAddress != null &&
      _pickedLatLng != null &&
      !_isResolving;

  void _onConfirmPressed() {
    if (!_canConfirm) return;
    // Carry the picked location + parsed address parts into the details form.
    Get.toNamed(
      RouteHelper.getAddressDetailsRoute(),
      arguments: <String, dynamic>{
        'latitude': _pickedLatLng!.latitude,
        'longitude': _pickedLatLng!.longitude,
        'zone': _checkZone,
      },
    );
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map ----------------------------------------------------------
          if (!_mapReady)
            const Center(child: CircularProgressIndicator())
          else
            GetBuilder<LocationController>(
              id: 'zones',
              builder: (location) => GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _initialPosition, zoom: 16),
                minMaxZoomPreference: const MinMaxZoomPreference(0, 18),
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                // Reserve the bottom area so the camera target sits in the
                // VISIBLE map center (above the sheet), matching the pin.
                padding: const EdgeInsets.only(bottom: _kBottomInset),
                polygons: location.zonePolygons,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _location.setMapController(controller);
                },
                // Tapping a point moves the pin there → resolves it (check-zone
                // + address) via the camera-idle handler.
                onTap: (latLng) {
                  _hasUserMovedMap = true;
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(latLng),
                  );
                },
                onCameraMoveStarted: _onCameraMoveStarted,
                onCameraMove: (pos) => _pickedLatLng = pos.target,
                onCameraIdle: () {
                  if (_pickedLatLng != null) _onCameraIdle(_pickedLatLng!);
                },
                style: Get.isDarkMode
                    ? Get.find<ThemeController>().darkMap
                    : Get.find<ThemeController>().lightMap,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
              ),
            ),

          // Address label floating just above the pin (close to the point).
          if (_pickedAddress != null && _isInZone)
            Align(
              alignment: Alignment(0,
                  (-_kBottomInset / MediaQuery.of(context).size.height) - 0.10),
              child: _AddressChip(text: _pickedAddress!),
            ),

          // Pin — aligned to the visible map center (matches the camera target
          // after the bottom padding above).
          Align(
            alignment: Alignment(
                0, -_kBottomInset / MediaQuery.of(context).size.height),
            child: const _MapCenterPin(),
          ),

          // Top: back button only ---------------------------------------
          Positioned(
            top: MediaQuery.of(context).padding.top +
                Dimensions.paddingSizeSmall,
            left: Dimensions.paddingSizeDefault,
            right: Dimensions.paddingSizeDefault,
            child: Row(
              children: [
                _CircleIconButton(
                  image: Images.arrow_back_ios_new,
                  onTap: () => Get.back(),
                ),
                const Spacer(),
              ],
            ),
          ),

          // My-location button (bottom-left, above the sheet) -----------
          Positioned(
            left: Dimensions.paddingSizeDefault,
            bottom: _bottomSheetHeight + Dimensions.paddingSizeLarge,
            child: _CircleIconButton(
              image: Images.forward_v2,
              onTap: _goToMyLocation,
            ),
          ),

          // Bottom sheet -------------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(context),
          ),
        ],
      ),
    );
  }

  // Rough reserved height used to offset the my-location button.
  double get _bottomSheetHeight =>
      (_canConfirm || _pickedAddress != null) ? 185 : 96;

  Widget _buildBottomSheet(BuildContext context) {
    // Before a valid pick: just the button (no sheet). After: full sheet.
    final bool showAddressRow = _pickedAddress != null && _isInZone;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // No background bar before a valid pick — the button floats on the map.
        color:
            showAddressRow ? Theme.of(context).cardColor : Colors.transparent,
        borderRadius: showAddressRow
            ? const BorderRadius.vertical(
                top: Radius.circular(Dimensions.radiusExtraLarge),
              )
            : null,
        boxShadow: showAddressRow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showAddressRow) ...[
                _SelectedAddressRow(text: _pickedAddress!),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
              _ConfirmButton(
                enabled: _canConfirm,
                loading: _isResolving,
                label: _canConfirm
                    ? 'confirm_the_address'.tr
                    : 'enter_the_address'.tr,
                onPressed: _onConfirmPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Green location dot shown at the map center.
class _MapCenterPin extends StatelessWidget {
  const _MapCenterPin();

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    // A simple centered dot whose center IS the camera target, so the resolved
    // point matches exactly where the dot appears (no vertical offset).
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Small circular white button (back / my-location).
class _CircleIconButton extends StatelessWidget {
  final String image;
  final VoidCallback onTap;
  const _CircleIconButton({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Image.asset(image, width: 22, height: 22),
        ),
      ),
    );
  }
}

/// Green pill at the top showing the picked address (compact).
class _AddressChip extends StatelessWidget {
  final String text;
  const _AddressChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Address row shown inside the bottom sheet once a point is picked.
class _SelectedAddressRow extends StatelessWidget {
  final String text;
  const _SelectedAddressRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(
            color: Color(0xffEBFEEB),
            shape: BoxShape.circle,
          ),
          child: Image.asset(Images.location_v2, width: 35, height: 35),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width bottom button with enabled / disabled / loading states.
class _ConfirmButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback onPressed;
  const _ConfirmButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    // Solid light-grey fill so the disabled button stays clearly visible on
    // the map (no background bar behind it).
    const Color disabledColor = Color(0xFFE2E4E6);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: enabled ? primary : disabledColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          onTap: enabled && !loading ? onPressed : null,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: Dimensions.fontSizeDefault,
                      height: 1.6,
                      color: enabled ? Colors.white : const Color(0xFF545454),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
