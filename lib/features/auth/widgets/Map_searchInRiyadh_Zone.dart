// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';

class RiyadhMapSearch extends StatefulWidget {
  const RiyadhMapSearch({super.key});

  @override
  _RiyadhMapSearchState createState() => _RiyadhMapSearchState();
}

class _RiyadhMapSearchState extends State<RiyadhMapSearch> {
  final TextEditingController _searchController =
      TextEditingController(text: 'الرياض');
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(24.7136, 46.6753); // مركز الرياض
  Marker? _marker;
  Set<Polygon> _polygons = {};
  bool _isInsideZone = true;
  int? _activeZoneId;
  bool _isGpsLoading = false;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    _initializeZonePolygons();

    // ضع الدبوس داخل الزون مباشرةً
    final center = _getZoneCenter();
    if (center != null) _currentPosition = center;

    _marker = _buildMarker(_currentPosition);

    // حمّل الأيقونة الكبيرة بعد بناء الشجرة
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarkerIcon());
  }

  Marker _buildMarker(LatLng position, {String? label}) {
    return Marker(
      markerId: const MarkerId('riyadh_marker'),
      position: position,
      draggable: true,
      icon: _markerIcon,
      anchor: const Offset(0.5, 1.0),
      infoWindow:
          label != null ? InfoWindow(title: label) : InfoWindow.noText,
      onDragEnd: (newPos) => _updatePosition(newPos),
    );
  }

  Future<void> _loadMarkerIcon() async {
    const double w = 96;
    const double h = 128;
    const double r = 40.0;
    const double cx = w / 2;
    const double cy = r + 6;

    final color = Theme.of(context).primaryColor;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // ظل
    canvas.drawCircle(
      Offset(cx + 2, cy + 3),
      r,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // الدائرة الرئيسية
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

    // حلقة بيضاء داخلية
    canvas.drawCircle(
      Offset(cx, cy),
      r - 10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // ذيل الدبوس (مثلث)
    final tail = Path()
      ..moveTo(cx - 13, cy + r - 8)
      ..lineTo(cx + 13, cy + r - 8)
      ..lineTo(cx, h - 4)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);

    final img =
        await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    if (!mounted || data == null) return;
    setState(() {
      _markerIcon =
          BitmapDescriptor.fromBytes(data.buffer.asUint8List());
      _marker = _buildMarker(_currentPosition);
    });
  }

  void _initializeZonePolygons() {
    final storeRegController = Get.find<StoreRegistrationController>();
    final zones = storeRegController.zoneList;
    if (zones == null || zones.isEmpty) return;

    // Find the largest zone by area
    ZoneDataModel? largestZone;
    double maxArea = 0;

    for (final zone in zones) {
      if (zone.formatedCoordinates == null) continue;
      final points =
          zone.formatedCoordinates!.map((c) => LatLng(c.lat!, c.lng!)).toList();
      final area = _calculatePolygonArea(points);
      if (area > maxArea) {
        maxArea = area;
        largestZone = zone;
      }
    }

    if (largestZone != null) {
      final points = largestZone.formatedCoordinates!
          .map((c) => LatLng(c.lat!, c.lng!))
          .toList();
      _polygons = HashSet<Polygon>.from([
        Polygon(
          polygonId: PolygonId('${largestZone.id}'),
          points: points,
          strokeWidth: 2,
          strokeColor: Colors.green,
          fillColor: Colors.green.withValues(alpha: 0.20),
        ),
      ]);
    }
    setState(() {});
  }

  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0;

    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    return (area / 2).abs();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      final LatLng v1 = polygon[i];
      final LatLng v2 = polygon[(i + 1) % polygon.length];
      if (v1.longitude == v2.longitude) continue;
      if (point.longitude < min(v1.longitude, v2.longitude)) continue;
      if (point.longitude >= max(v1.longitude, v2.longitude)) continue;
      final double xIntersect = (point.longitude - v1.longitude) *
              (v2.latitude - v1.latitude) /
              (v2.longitude - v1.longitude) +
          v1.latitude;
      if (point.latitude <= xIntersect) intersectCount++;
    }
    return intersectCount % 2 == 1;
  }

  ZoneDataModel? _findContainingZone(LatLng point, List<ZoneDataModel> zones) {
    for (final z in zones) {
      if (z.formatedCoordinates == null) continue;
      final poly =
          z.formatedCoordinates!.map((c) => LatLng(c.lat!, c.lng!)).toList();
      if (_isPointInPolygon(point, poly)) return z;
    }
    return null;
  }

  Future<void> _searchInRiyadh(String query) async {
    if (query.isEmpty) {
      _showError('الرجاء إدخال عنوان للبحث');
      return;
    }

    try {
      final String searchQuery = '$query, الرياض';
      final List<Location> locations = await locationFromAddress(searchQuery);

      if (locations.isEmpty) {
        _showError('لم يتم العثور على الموقع');
        return;
      }

      final newPosition =
          LatLng(locations.first.latitude, locations.first.longitude);

      final storeRegController = Get.find<StoreRegistrationController>();
      final zones = storeRegController.zoneList ?? [];
      final containing = _findContainingZone(newPosition, zones);
      if (containing == null) {
        _showOutOfServiceDialog(); // Show the coming soon dialog
        return;
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 14),
      );

      setState(() {
        _currentPosition = newPosition;
        _marker = _buildMarker(newPosition, label: query);
        _isInsideZone = true;
        _activeZoneId = containing.id;
      });

      // Update controller with location + zone check to toggle inZone
      storeRegController.setLocation(newPosition,
          forStoreRegistration: true, zoneId: _activeZoneId);
    } catch (e) {
      _showError('حدث خطأ أثناء البحث');
      debugPrint('Search error: $e');
    }
  }

  Future<void> _updatePosition(LatLng newPosition) async {
    final storeRegController = Get.find<StoreRegistrationController>();
    final zones = storeRegController.zoneList ?? [];
    final containing = _findContainingZone(newPosition, zones);
    if (containing == null) {
      _showOutOfServiceDialog();
      return;
    }

    setState(() {
      _currentPosition = newPosition;
      _marker = _buildMarker(newPosition);
    });

    _activeZoneId = containing.id;
    await storeRegController.setLocation(
      newPosition,
      forStoreRegistration: true,
      zoneId: _activeZoneId,
    );

    // تحديث حقل العنوان تلقائياً من نتيجة reverse geocoding
    if (mounted && storeRegController.storeAddress != null) {
      setState(() {
        _searchController.text = storeRegController.storeAddress!;
      });
    }
  }

  LatLng? _getZoneCenter() {
    if (_polygons.isEmpty) return null;
    final points = _polygons.first.points;
    if (points.isEmpty) return null;
    final lat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final lng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lng);
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isGpsLoading) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showError('يجب السماح بالوصول للموقع');
      return;
    }

    setState(() => _isGpsLoading = true);
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newPosition = LatLng(position.latitude, position.longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 14),
      );
      await _updatePosition(newPosition);
    } catch (_) {
      _showError('فشل في الحصول على الموقع');
    } finally {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {
      _isInsideZone = false;
    });
  }

  void _showOutOfServiceDialog() {
    Get.dialog(
      Material(
        type: MaterialType.transparency,
        child: Dialog(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shella delivery image
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/image/shella.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color:
                                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.delivery_dining,
                              size: 80,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'location_is_outside_service_area'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Message
                      Text(
                        'location_outside_message'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'navigate_to_service_zone'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // زر لا
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                              child: Text(
                                'no'.tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // زر نعم
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                                final center = _getZoneCenter();
                                if (center != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(center, 11),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'yes'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          titleText: 'write_store_address'.tr,
          labelText: 'address'.tr,
          controller: _searchController,
          inputAction: TextInputAction.done,
          capitalization: TextCapitalization.sentences,
          required: true,
          validator: (value) => null,
        ),
        const SizedBox(height: 16),
        CustomButton(
          width: 150,
          buttonText: 'بحث',
          onPressed: () => _searchInRiyadh(_searchController.text),
        ),
        if (!_isInsideZone)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'الموقع خارج المنطقة المحددة',
              style: TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 22),
        GetBuilder<StoreRegistrationController>(builder: (storeRegController) {
          return Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 9,
                  ),
                  markers: _marker != null ? {_marker!} : {},
                  polygons: _polygons,
                  onTap: _updatePosition,
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _moveToCurrentLocation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              spreadRadius: 1),
                        ],
                      ),
                      child: _isGpsLoading
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.my_location,
                              color: Theme.of(context).primaryColor,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
