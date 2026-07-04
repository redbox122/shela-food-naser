// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/marker_helper.dart';
import 'package:sixam_mart/util/images.dart';

/// 🗺️ Live order-tracking map. Shows the store, the customer and (once the order
/// is on the way) the driver, with a route polyline between them. The driver
/// marker animates smoothly between location updates and the camera follows it.
///
/// It reads everything from [track] (the order being polled every few seconds);
/// each new [track] with a moved driver triggers a smooth marker animation and a
/// camera re-fit — so the map stays in sync with the order's state.
class LiveTrackingMap extends StatefulWidget {
  final OrderModel track;
  LiveTrackingMap({super.key, required this.track});

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  bool _mapReady = false;

  Set<Marker> _markers = HashSet<Marker>();
  final Set<Polyline> _polylines = HashSet<Polyline>();

  BitmapDescriptor? _storeIcon;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _customerIcon;

  // Smooth driver-marker animation between two consecutive locations.
  late final AnimationController _driverAnim;
  LatLng? _driverFrom;
  LatLng? _driverTo;
  LatLng? _driverShown;

  // Cache the last route we asked Google for, so we only re-query on real moves.
  String? _routeKey;

  bool get _onTheWay {
    final s = (widget.track.orderStatus ?? '').toLowerCase();
    return s == 'picked_up' || s == 'handover' || s == 'on_the_way';
  }

  @override
  void initState() {
    super.initState();
    _driverAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_onDriverTick);
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final bool isRestaurant = widget.track.moduleType == 'food';
    _storeIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
      width: isRestaurant ? 90 : 80,
      imagePath: isRestaurant ? Images.restaurantMarker : Images.markerStore,
    );
    _driverIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
      width: 70, imagePath: Images.deliveryManMarker);
    _customerIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
      width: 70, imagePath: Images.userMarker);
    if (mounted) _rebuild(initial: true);
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuild();
  }

  void _onDriverTick() {
    if (_driverFrom == null || _driverTo == null) return;
    final t = Curves.easeInOut.transform(_driverAnim.value);
    _driverShown = LatLng(
      lerpDouble(_driverFrom!.latitude, _driverTo!.latitude, t)!,
      lerpDouble(_driverFrom!.longitude, _driverTo!.longitude, t)!,
    );
    _composeMarkers();
    if (mounted) setState(() {});
    if (_onTheWay && _driverShown != null) {
      _controller?.moveCamera(CameraUpdate.newLatLng(_driverShown!));
    }
  }

  // ─── geometry helpers ──────────────────────────────────────────────────────

  LatLng? _parse(String? lat, String? lng) {
    final dLat = double.tryParse(lat ?? '');
    final dLng = double.tryParse(lng ?? '');
    if (dLat == null || dLng == null) return null;
    if (dLat == 0 && dLng == 0) return null;
    return LatLng(dLat, dLng);
  }

  LatLng? get _storeLatLng =>
      _parse(widget.track.store?.latitude, widget.track.store?.longitude);
  LatLng? get _customerLatLng => _parse(
      widget.track.deliveryAddress?.latitude,
      widget.track.deliveryAddress?.longitude);
  LatLng? get _driverLatLng =>
      _parse(widget.track.deliveryMan?.lat, widget.track.deliveryMan?.lng);

  /// Remaining driver→customer distance in km (null when not on the way / invalid
  /// coords / implausibly far — guards against the old 5714 km bug).
  double? get _remainingKm {
    if (!_onTheWay) return null;
    final d = _driverShown ?? _driverLatLng;
    final c = _customerLatLng;
    if (d == null || c == null) return null;
    const r = 6371.0;
    final dLat = (c.latitude - d.latitude) * math.pi / 180;
    final dLng = (c.longitude - d.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(d.latitude * math.pi / 180) *
            math.cos(c.latitude * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final km = r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    if (km <= 0 || km > 300) return null;
    return km;
  }

  // ─── rebuild on each track update ────────────────────────────────────────────

  void _rebuild({bool initial = false}) {
    final driver = _driverLatLng;
    if (driver != null) {
      if (_driverShown == null) {
        _driverShown = driver;
        _driverTo = driver;
      } else if (_driverTo == null ||
          driver.latitude != _driverTo!.latitude ||
          driver.longitude != _driverTo!.longitude) {
        // New driver location → animate from where we currently show it.
        _driverFrom = _driverShown;
        _driverTo = driver;
        _driverAnim
          ..reset()
          ..forward();
      }
    }
    _composeMarkers();
    _buildRoute();
    if (initial) _fitCamera();
    if (mounted) setState(() {});
  }

  void _composeMarkers() {
    final markers = HashSet<Marker>();
    final store = _storeLatLng;
    final customer = _customerLatLng;
    final driver = _driverShown;

    if (store != null && _storeIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('store'),
        position: store,
        icon: _storeIcon!,
        infoWindow: InfoWindow(
            title: widget.track.store?.name ?? 'store'.tr,
            snippet: widget.track.store?.address),
      ));
    }
    if (customer != null && _customerIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: customer,
        icon: _customerIcon!,
        infoWindow: InfoWindow(title: 'delivery_address'.tr),
      ));
    }
    if (driver != null && _driverIcon != null && _onTheWay) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: driver,
        icon: _driverIcon!,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
            title: 'delivery_man'.tr,
            snippet: widget.track.deliveryMan?.location),
      ));
    }
    _markers = markers;
  }

  /// Route line: driver→customer once on the way, otherwise store→customer.
  /// Tries the Google Directions API for a real road route and falls back to a
  /// straight line so the map always shows a connecting path.
  Future<void> _buildRoute() async {
    final customer = _customerLatLng;
    if (customer == null) return;
    final LatLng? origin = (_onTheWay && _driverTo != null)
        ? _driverTo
        : _storeLatLng;
    if (origin == null) return;

    final key =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}'
        '->${customer.latitude.toStringAsFixed(4)},${customer.longitude.toStringAsFixed(4)}';
    if (key == _routeKey) return;
    _routeKey = key;

    // Capture theme colour before any await (no BuildContext across async gaps).
    final Color routeColor = Theme.of(context).primaryColor;

    List<LatLng> points = <LatLng>[origin, customer];
    try {
      final road = await _fetchDirections(origin, customer);
      if (road.length >= 2) points = road;
    } catch (_) {/* keep straight-line fallback */}

    _polylines
      ..clear()
      ..add(Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: routeColor,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));
    if (mounted) setState(() {});
  }

  Future<List<LatLng>> _fetchDirections(LatLng origin, LatLng dest) async {
    const String apiKey = 'AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8';
    final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&mode=driving&key=$apiKey');
    final res = await http.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) return const [];
    final encoded = routes.first['overview_polyline']?['points'] as String?;
    if (encoded == null) return const [];
    return _decodePolyline(encoded);
  }

  // Standard Google encoded-polyline decoder.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _fitCamera() async {
    if (_controller == null) return;
    final pts = <LatLng>[
      if (_storeLatLng != null) _storeLatLng!,
      if (_customerLatLng != null) _customerLatLng!,
      if (_onTheWay && _driverShown != null) _driverShown!,
    ];
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _controller!.moveCamera(CameraUpdate.newLatLngZoom(pts.first, 15));
      return;
    }
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  @override
  void dispose() {
    _driverAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initial = _customerLatLng ??
        _storeLatLng ??
        const LatLng(24.7136, 46.6753); // Riyadh fallback
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initial, zoom: 14),
          markers: _markers,
          polylines: _polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (c) {
            _controller = c;
            _mapReady = true;
            _fitCamera();
          },
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer()),
          },
          style: Get.isDarkMode
              ? Get.find<ThemeController>().darkMap
              : Get.find<ThemeController>().lightMap,
        ),
        if (!_mapReady)
          Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
        // Remaining-distance bubble over the driver ("يبعد عنك X كم").
        if (_remainingKm != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 0,
            right: 0,
            child: Center(child: _DistanceBubble(km: _remainingKm!)),
          ),
        // Re-centre button.
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: Theme.of(context).primaryColor,
            onPressed: _fitCamera,
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}

/// Floating green pill showing how far the courier still is from the customer.
class _DistanceBubble extends StatelessWidget {
  final double km;
  const _DistanceBubble({required this.km});

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Get.locale?.languageCode == 'ar';
    final String dist = km < 1
        ? '${(km * 1000).round()} ${isArabic ? 'ord_meter'.tr : 'm'}'
        : '${km.toStringAsFixed(1)} ${isArabic ? 'ord_km'.tr : 'km'}';
    final String label =
        isArabic ? 'السائق يبعد عنك $dist' : 'Courier is $dist away';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delivery_dining, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
