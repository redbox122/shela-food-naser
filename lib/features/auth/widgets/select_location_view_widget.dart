import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/widgets/pickup_zone_widget.dart';
import 'package:sixam_mart/features/auth/widgets/zone_selection_widget.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/auth/widgets/module_view_widget.dart';
import 'package:sixam_mart/features/location/widgets/location_search_dialog_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';

class SelectLocationViewWidget extends StatefulWidget {
  final bool fromView;
  final bool mapView;
  final bool zoneModuleView;
  final GoogleMapController? mapController;
  final TextEditingController? addressController;
  final FocusNode? addressFocus;
  final bool inDialog;
  const SelectLocationViewWidget({
    super.key,
    required this.fromView,
    this.mapController,
    this.mapView = false,
    this.zoneModuleView = false,
    this.addressController,
    this.addressFocus,
    this.inDialog = false,
  });

  @override
  State<SelectLocationViewWidget> createState() => _SelectLocationViewWidgetState();
}

class _SelectLocationViewWidgetState extends State<SelectLocationViewWidget> {
  late CameraPosition _cameraPosition;
  Set<Polygon> _polygons = {};
  GoogleMapController? _mapController;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cityController.dispose();
    _areaController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreRegistrationController>(builder: (storeRegController) {
      final isDesktop = ResponsiveHelper.isDesktop(context);
      final isRentalModule = _isRentalModule(storeRegController);
      final zoneList = _buildZoneDropdownList(storeRegController);

      return _buildMainContainer(
        context,
        isDesktop,
        isRentalModule,
        storeRegController,
        zoneList,
      );
    });
  }

  bool _isRentalModule(StoreRegistrationController controller) {
    return widget.fromView &&
        controller.moduleList != null &&
        controller.selectedModuleIndex != -1 &&
        controller.moduleList![controller.selectedModuleIndex!].moduleType == AppConstants.taxi;
  }

  List<DropdownItem<int>> _buildZoneDropdownList(StoreRegistrationController controller) {
    if (controller.zoneList == null || controller.zoneIds == null) return [];

    return List.generate(controller.zoneList!.length, (index) {
      return DropdownItem<int>(
        value: index,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(controller.zoneList![index].name ?? ''),
        ),
      );
    });
  }

  Widget _buildMainContainer(
    BuildContext context,
    bool isDesktop,
    bool isRentalModule,
    StoreRegistrationController storeRegController,
    List<DropdownItem<int>> zoneList,
  ) {
    return Container(
      decoration: _buildContainerDecoration(context, isDesktop),
      alignment: Alignment.center,
      height: widget.fromView ? null : context.height,
      padding: _getContainerPadding(isDesktop),
      child: SizedBox(
        width: Dimensions.webMaxWidth,
        child: Padding(
          padding: EdgeInsets.all(widget.fromView ? 0 : 0),
          child: SingleChildScrollView(
            child: isDesktop && widget.fromView
                ? _buildWebView(storeRegController, zoneList)
                : _buildMobileView(context, isDesktop, isRentalModule, storeRegController, zoneList),
          ),
        ),
      ),
    );
  }

  BoxDecoration? _buildContainerDecoration(BuildContext context, bool isDesktop) {
    return widget.fromView && !isDesktop
        ? BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          )
        : null;
  }

  EdgeInsets _getContainerPadding(bool isDesktop) {
    return widget.fromView && !isDesktop
        ? const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeDefault,
          )
        : EdgeInsets.zero;
  }

  Widget _buildWebView(StoreRegistrationController storeRegController, List<DropdownItem<int>> zoneList) {
    return Row(children: [
      (widget.fromView && widget.zoneModuleView) ? const SizedBox() : const SizedBox(width: Dimensions.paddingSizeLarge),
      (widget.fromView && widget.mapView)
          ? Expanded(
              child: Column(
                children: [
                  ZoneSelectionWidget(
                    storeRegController: storeRegController,
                    zoneList: zoneList,
                    callBack: () => _setPolygon(storeRegController.zoneList![storeRegController.selectedZoneIndex!]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  _buildMapView(storeRegController),
                ],
              ),
            )
          : const SizedBox(),
    ]);
  }

  Widget _buildMobileView(
    BuildContext context,
    bool isDesktop,
    bool isRentalModule,
    StoreRegistrationController storeRegController,
    List<DropdownItem<int>> zoneList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // حقل المدينة
        CustomTextField(
          titleText: 'city'.tr,
          labelText: 'enter_city'.tr,
          controller: _cityController,
          capitalization: TextCapitalization.words,
          required: true,
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // حقل المنطقة
        CustomTextField(
          titleText: 'area'.tr,
          labelText: 'enter_area'.tr,
          controller: _areaController,
          capitalization: TextCapitalization.words,
          required: true,
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // حقل اسم الشارع
        CustomTextField(
          titleText: 'street_name'.tr,
          labelText: 'enter_street_name'.tr,
          controller: _streetController,
          inputAction: TextInputAction.done,
          inputType: TextInputType.streetAddress,
          capitalization: TextCapitalization.words,
          required: true,
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // زر البحث في الخريطة
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomButton(
                buttonText: 'search_on_map'.tr,
                onPressed: _searchOnMap,
              ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        if (widget.fromView) ...[
          ZoneSelectionWidget(
            storeRegController: storeRegController,
            zoneList: zoneList,
            callBack: () => _setPolygon(storeRegController.zoneList![storeRegController.selectedZoneIndex!]),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),
          const ModuleViewWidget(),
          const SizedBox(height: Dimensions.paddingSizeExtremeLarge),
          if (isRentalModule) ...[
            const PickupZoneWidget(),
            const SizedBox(height: Dimensions.paddingSizeExtremeLarge),
          ],
        ],

        _buildMapView(storeRegController),

        if (!widget.fromView && !widget.inDialog) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          CustomButton(
            buttonText: 'set_location'.tr,
            onPressed: () => _handleSetLocation(),
          ),
        ],

        if (!storeRegController.inZone) _buildZoneWarning(),

        if (!isDesktop) SizedBox(height: !widget.fromView ? Dimensions.paddingSizeSmall : 0),
        SizedBox(height: widget.fromView ? Dimensions.paddingSizeExtremeLarge : 0),

        if (widget.fromView && !isDesktop) _buildAddressField(),
      ],
    );
  }

  Widget _buildZoneWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Row(children: [
        Text('* ', style: robotoBold.copyWith(color: Colors.red)),
        Text(
          'please_place_the_marker_inside_the_zone'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      ]),
    );
  }

  Widget _buildAddressField() {
    return CustomTextField(
      titleText: 'write_store_address'.tr,
      labelText: 'address'.tr,
      controller: widget.addressController,
      focusNode: widget.addressFocus,
      inputAction: TextInputAction.done,
      capitalization: TextCapitalization.sentences,
      maxLines: 3,
      showTitle: ResponsiveHelper.isDesktop(context),
      required: true,
      validator: (value) => ValidateCheck.validateEmptyText(value, 'store_address_field_is_required'.tr),
    );
  }

  Future<void> _searchOnMap() async {
    if (_cityController.text.isEmpty || _areaController.text.isEmpty || _streetController.text.isEmpty) {
      showCustomSnackBar('please_fill_all_fields'.tr);
      return;
    }

    setState(() => _isLoading = true);

    final String fullAddress = '${_cityController.text}, ${_areaController.text}, ${_streetController.text}';

    try {
      // هنا يجب استبدال هذا الجزء بطلب API حقيقي للجيو كودنج
      // هذا مثال فقط للتوضيح
      await Future.delayed(const Duration(seconds: 1)); // محاكاة لطلب الشبكة

      // استخدام الموقع الافتراضي للعرض التوضيحي
      // في التطبيق الحقيقي، استخدم إحداثيات العنوان الذي تم العثور عليه
      _cameraPosition = CameraPosition(
        target: LatLng(
          double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '0'),
          double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '0'),
        ),
        zoom: 16,
      );

      _mapController?.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));

      showCustomSnackBar('location_found'.tr);
    } catch (e) {
      showCustomSnackBar('failed_to_find_location'.tr);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMapView(StoreRegistrationController storeRegController) {
    if (storeRegController.zoneList?.isEmpty ?? true) return const SizedBox();

    final mapHeight = _calculateMapHeight(context);
    final mapWidth = widget.inDialog ? MediaQuery.of(context).size.width * 0.7 : MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        height: mapHeight,
        width: mapWidth,
        decoration: widget.fromView
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).primaryColor),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildGoogleMap(storeRegController),
              const Center(child: CustomAssetImageWidget(Images.markerStore, height: 40, width: 40)),
              _buildSearchButton(),
              if (widget.inDialog) _buildCloseButton(),
              if (widget.fromView) _buildFullScreenButton(storeRegController),
              _buildMyLocationButton(),
              if (!widget.fromView) _buildZoomControls(),
              if (!widget.fromView) _buildSetLocationButton(storeRegController),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateMapHeight(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return widget.fromView ? 190 : MediaQuery.of(context).size.height * 0.8;
    }
    return widget.fromView ? 150 : (context.height * 0.87);
  }

  Widget _buildGoogleMap(StoreRegistrationController storeRegController) {
    final defaultLocation = Get.find<SplashController>().configModel!.defaultLocation!;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          double.parse(defaultLocation.lat ?? '0'),
          double.parse(defaultLocation.lng ?? '0'),
        ),
        zoom: 16,
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
      zoomControlsEnabled: false,
      compassEnabled: false,
      indoorViewEnabled: true,
      mapToolbarEnabled: false,
      polygons: _polygons,
      onCameraIdle: () => _handleCameraIdle(storeRegController),
      onCameraMove: (position) => _cameraPosition = position,
      onMapCreated: (controller) => _handleMapCreated(controller, storeRegController),
      gestureRecognizers: _buildGestureRecognizers(),
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>> _buildGestureRecognizers() {
    return {
      Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
      Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
      Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
      Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
    };
  }

  Widget _buildSearchButton() {
    return Positioned(
      top: widget.fromView ? 10 : 20,
      left: widget.fromView ? 10 : 20,
      right: widget.fromView ? null : 20,
      child: InkWell(
        onTap: _handleSearchLocation,
        child: Container(
          height: widget.fromView ? 30 : 40,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            color: Theme.of(context).cardColor,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          padding: const EdgeInsets.only(left: 10),
          alignment: Alignment.centerLeft,
          child: Text('search'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 0,
      right: 0,
      child: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.clear),
      ),
    );
  }

  Widget _buildFullScreenButton(StoreRegistrationController storeRegController) {
    return Positioned(
      bottom: 50,
      right: 0,
      child: InkWell(
        onTap: () => _handleFullScreen(storeRegController),
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: Icon(Icons.fullscreen, color: Theme.of(context).primaryColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: widget.fromView ? 10 : 210,
      right: 0,
      child: InkWell(
        onTap: () => _checkPermission(() {
          Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
        }),
        child: Container(
          padding: EdgeInsets.all(widget.fromView ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall),
          margin: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.white),
          child: Icon(
            Icons.my_location_outlined,
            color: Theme.of(context).primaryColor,
            size: widget.fromView ? 20 : 25,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 100,
      right: 0,
      child: Container(
        margin: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _zoomIn,
              child: const Icon(Icons.add, size: 25),
            ),
            const Divider(),
            InkWell(
              onTap: _zoomOut,
              child: const Icon(Icons.remove, size: 25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetLocationButton(StoreRegistrationController storeRegController) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: ResponsiveHelper.isDesktop(context) ? 40 : 20,
      child: CustomButton(
        buttonText: storeRegController.inZone ? 'set_location'.tr : 'not_in_zone'.tr,
        onPressed: storeRegController.inZone ? _handleSetLocation : null,
      ),
    );
  }

  void _handleCameraIdle(StoreRegistrationController storeRegController) {
    storeRegController.setLocation(
      _cameraPosition.target,
      forStoreRegistration: true,
      zoneId: storeRegController.zoneList![storeRegController.selectedZoneIndex!].id,
    );

    if (!widget.fromView) {
      widget.mapController?.moveCamera(CameraUpdate.newCameraPosition(_cameraPosition));
    }
  }

  void _handleMapCreated(GoogleMapController controller, StoreRegistrationController storeRegController) {
    _mapController = controller;
    _setPolygon(storeRegController.zoneList![storeRegController.selectedZoneIndex!]);
  }

  Future<void> _handleSearchLocation() async {
    await Get.dialog(LocationSearchDialogWidget(mapController: _mapController));
    // Location is set via LocationController.setLocation, no need to handle position here
  }

  void _handleFullScreen(StoreRegistrationController storeRegController) {
    if (storeRegController.selectedZoneIndex == -1) {
      showCustomSnackBar('please_select_zone'.tr);
      return;
    }

    if (ResponsiveHelper.isDesktop(context)) {
      showGeneralDialog(
        context: context,
        pageBuilder: (_, __, ___) {
          return Center(
            child: SelectLocationViewWidget(
              fromView: false,
              mapController: _mapController,
              inDialog: true,
            ),
          );
        },
      );
    } else {
      Get.to(
        Scaffold(
          appBar: CustomAppBar(title: 'set_your_store_location'.tr),
          body: SelectLocationViewWidget(fromView: false, mapController: _mapController),
        ),
      );
    }
  }

  void _zoomIn() async {
    final currentZoomLevel = await _mapController?.getZoomLevel();
    if (currentZoomLevel != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _cameraPosition.target,
            zoom: currentZoomLevel + 1,
          ),
        ),
      );
    }
  }

  void _zoomOut() async {
    final currentZoomLevel = await _mapController?.getZoomLevel();
    if (currentZoomLevel != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _cameraPosition.target,
            zoom: currentZoomLevel - 1,
          ),
        ),
      );
    }
  }

  void _handleSetLocation() {
    try {
      widget.mapController?.moveCamera(CameraUpdate.newCameraPosition(_cameraPosition));
      Get.back();
    } catch (e) {
      if (widget.fromView) {
        showCustomSnackBar('please_setup_the_marker_in_your_required_location'.tr);
      } else {
        Get.back();
      }
    }
  }

  void _setPolygon(ZoneDataModel zoneModel) {
    if (zoneModel.formatedCoordinates == null) return;

    final zoneLatLongList = zoneModel.formatedCoordinates!.map((coordinate) => LatLng(coordinate.lat!, coordinate.lng!)).toList();

    _polygons = HashSet<Polygon>.from([
      Polygon(
        polygonId: PolygonId('${zoneModel.id!}'),
        points: zoneLatLongList,
        strokeWidth: 2,
        strokeColor: Get.theme.colorScheme.primary,
        fillColor: Get.theme.colorScheme.primary.withValues(alpha: .2),
      ),
    ]);

    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList(zoneLatLongList),
          Get.context != null && ResponsiveHelper.isDesktop(Get.context!) ? 30 : 100.5,
        ),
      );
    });

    setState(() {});
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;

    for (final latLng in list) {
      x0 = x0 == null ? latLng.latitude : (latLng.latitude < x0 ? latLng.latitude : x0);
      x1 = x1 == null ? latLng.latitude : (latLng.latitude > x1 ? latLng.latitude : x1);
      y0 = y0 == null ? latLng.longitude : (latLng.longitude < y0 ? latLng.longitude : y0);
      y1 = y1 == null ? latLng.longitude : (latLng.longitude > y1 ? latLng.longitude : y1);
    }

    return LatLngBounds(
      northeast: LatLng(x1 ?? 0, y1 ?? 0),
      southwest: LatLng(x0 ?? 0, y0 ?? 0),
    );
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialogWidget());
    } else {
      onTap();
    }
  }
}
