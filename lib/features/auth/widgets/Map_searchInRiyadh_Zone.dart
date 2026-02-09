// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeZonePolygons();
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
        _marker = Marker(
          markerId: const MarkerId('riyadh_marker'),
          position: newPosition,
          draggable: true,
          infoWindow: InfoWindow(title: query),
        );
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

  void _updatePosition(LatLng newPosition) {
    final storeRegController = Get.find<StoreRegistrationController>();
    final zones = storeRegController.zoneList ?? [];
    final containing = _findContainingZone(newPosition, zones);
    if (containing == null) {
      _showOutOfServiceDialog(); // Show the coming soon dialog
      return;
    }

    setState(() {
      _currentPosition = newPosition;
      _marker = Marker(
        markerId: const MarkerId('riyadh_marker'),
        position: newPosition,
        draggable: true,
      );
    });

    // Update controller and inZone
    _activeZoneId = containing.id;
    storeRegController.setLocation(_marker!.position,
        forStoreRegistration: true, zoneId: _activeZoneId);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? ''),
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
                      const SizedBox(height: 20),
                      // OK Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back(); // Close dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'ok'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 9,
              ),
              markers: _marker != null ? {_marker!} : {},
              polygons: _polygons,
              onTap: _updatePosition,
            ),
          );
        }),
      ],
    );
  }
}
