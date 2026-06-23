import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_v2_model.dart';
import 'package:sixam_mart/features/address/domain/models/check_zone_model.dart';
import 'package:sixam_mart/features/address/domain/services/address_v2_api.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// A selectable building-type option.
class _BuildingType {
  final String key; // localization key
  final String apiValue; // value sent to the API
  final String image;
  const _BuildingType(this.key, this.apiValue, this.image);
}

const List<_BuildingType> _buildingTypes = [
  _BuildingType('apartment', 'apartment', Images.apartment),
  _BuildingType('office_building', 'office', Images.office_building),
  _BuildingType('villa', 'villa', Images.villa),
];

/// 🎨 REDESIGN: "Delivery address details" form.
///
/// Reached after the user confirms a point on [SelectLocationScreen]. It
/// collects the human-readable address parts (city, district, street, building
/// type, etc.). The Save button stays disabled until all required (*) fields
/// are filled, then turns green.
///
/// The picked coordinates carry the location forward; [zone] (from the v2
/// check-zone call) pre-fills city / district / street.
///
/// When opened from the saved-addresses list, [addressId] is set: the screen
/// loads the full record via `details/{id}` and shows it read-only (there is no
/// update endpoint yet).
class AddressDetailsScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final CheckZoneModel? zone;
  final int? addressId;
  const AddressDetailsScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.zone,
    this.addressId,
  });

  @override
  State<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends State<AddressDetailsScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _buildingNoController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _apartmentNoController = TextEditingController();
  final TextEditingController _additionalController = TextEditingController();
  final TextEditingController _shortNameController = TextEditingController();

  int _buildingTypeIndex = 0;
  bool _buildingDropdownOpen = false;
  bool _saving = false;
  bool _loadingDetails = false;

  // In edit mode, the loaded coordinates are kept so the update body carries
  // the address location (the screen itself has no map).
  double? _editLat;
  double? _editLng;

  /// Editing an existing address (opened from the list) vs. adding a new one.
  bool get _isEditMode => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill the parts returned by the check-zone call.
    final addr = widget.zone?.address;
    if (addr != null) {
      _cityController.text = addr.city ?? '';
      _districtController.text = addr.region ?? '';
      _streetController.text = addr.streetName ?? '';
    }
    // Recompute the Save button state as the user types.
    for (final c in [
      _cityController,
      _districtController,
      _streetController,
      _shortNameController,
    ]) {
      c.addListener(() => setState(() {}));
    }

    if (_isEditMode) _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _loadingDetails = true);
    final AddressV2Model? d = await AddressV2Api().details(widget.addressId!);
    if (!mounted) return;
    if (d != null) {
      _editLat = d.latitude;
      _editLng = d.longitude;
      _cityController.text = d.city ?? '';
      _districtController.text = d.region ?? '';
      _streetController.text = d.streetName ?? '';
      _shortNameController.text = d.addressLabel ?? '';
      _buildingNoController.text = d.buildingNumber ?? '';
      _floorController.text = d.floorNumber ?? '';
      _apartmentNoController.text = d.apartmentNumber ?? '';
      _additionalController.text = d.additionalInfo ?? '';
      final int typeIndex =
          _buildingTypes.indexWhere((t) => t.apiValue == d.buildingType);
      if (typeIndex >= 0) _buildingTypeIndex = typeIndex;
    }
    setState(() => _loadingDetails = false);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _buildingNoController.dispose();
    _floorController.dispose();
    _apartmentNoController.dispose();
    _additionalController.dispose();
    _shortNameController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _cityController.text.trim().isNotEmpty &&
      _districtController.text.trim().isNotEmpty &&
      _streetController.text.trim().isNotEmpty &&
      _shortNameController.text.trim().isNotEmpty &&
      !_saving;

  Future<void> _onSave() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    // Villas have only a single number (mapped to building_number); the floor
    // and apartment columns aren't shown, so don't send stale values for them.
    final String type = _buildingTypes[_buildingTypeIndex].apiValue;
    final bool isVilla = type == 'villa';

    final body = AddressV2Api.buildAddBody(
      city: _cityController.text.trim(),
      region: _districtController.text.trim(),
      streetName: _streetController.text.trim(),
      addressLabel: _shortNameController.text.trim(),
      latitude: _isEditMode ? (_editLat ?? 0) : (widget.latitude ?? 0),
      longitude: _isEditMode ? (_editLng ?? 0) : (widget.longitude ?? 0),
      buildingType: type,
      buildingNumber: _buildingNoController.text.trim(),
      floorNumber: isVilla ? '' : _floorController.text.trim(),
      apartmentNumber: isVilla ? '' : _apartmentNoController.text.trim(),
      additionalInfo: _additionalController.text.trim(),
    );

    if (_isEditMode) {
      final result = await AddressV2Api().update(widget.addressId!, body);
      if (!mounted) return;
      setState(() => _saving = false);
      if (result.success) {
        // Refresh the underlying list so it shows the edit on return.
        if (Get.isRegistered<AddressController>()) {
          await Get.find<AddressController>().getAddressListV2();
        }
        showCustomSnackBar(result.message ?? 'address_updated_successfully'.tr,
            isError: false);
        Get.back(result: true);
      } else {
        showCustomSnackBar(result.message ?? 'something_went_wrong'.tr);
      }
      return;
    }

    final result = await AddressV2Api().add(body);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      // Set the just-saved address as the current location so the home screen
      // loads data for the right zone, then land on home.
      await _setAsCurrentAddress(result.addressId);
      showCustomSnackBar(result.message ?? 'new_address_added_successfully'.tr,
          isError: false);
      Get.offAllNamed(RouteHelper.getMainRoute('home'));
    } else {
      showCustomSnackBar(result.message ?? 'something_went_wrong'.tr);
    }
  }

  Future<void> _setAsCurrentAddress(int? id) async {
    final int? zoneId = widget.zone?.zoneId;
    final AddressModel address = AddressModel(
      id: id,
      latitude: widget.latitude?.toString(),
      longitude: widget.longitude?.toString(),
      addressType: _shortNameController.text.trim(),
      address: [
        _cityController.text.trim(),
        _districtController.text.trim(),
        _streetController.text.trim(),
      ].where((e) => e.isNotEmpty).join('، '),
      zoneId: zoneId,
      zoneIds: zoneId != null ? [zoneId] : [],
      areaIds: const [],
    );
    await AddressHelper.saveUserAddressInSharedPref(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        // Prevent the Material 3 surface-tint that greens the header on scroll.
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'delivery_address_details'.tr,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 1.6,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: _loadingDetails
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledField(
                            label: 'city'.tr,
                            required: true,
                            controller: _cityController,
                            hint: 'city_hint'.tr,
                          ),
                          _LabeledField(
                            label: 'district'.tr,
                            required: true,
                            controller: _districtController,
                            hint: 'district_hint'.tr,
                          ),
                          _LabeledField(
                            label: 'street_name'.tr,
                            required: true,
                            controller: _streetController,
                            hint: 'street_name_hint'.tr,
                          ),
                          _buildingTypeField(context),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          _numberFields(context),
                          _LabeledField(
                            label: 'additional_information'.tr,
                            controller: _additionalController,
                            hint: 'additional_information_hint'.tr,
                          ),
                          _LabeledField(
                            label: 'short_name_for_address'.tr,
                            required: true,
                            controller: _shortNameController,
                            hint: 'short_name_for_address_hint'.tr,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeLarge,
                      Dimensions.paddingSizeSmall,
                      Dimensions.paddingSizeLarge,
                      Dimensions.paddingSizeDefault,
                    ),
                    child: _SaveButton(
                      enabled: _canSave,
                      loading: _saving,
                      onPressed: _onSave,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Number fields shown below the building-type picker, varying by type:
  /// - apartment: building no. + floor + apartment no.
  /// - office:    building no. + floor + office no.
  /// - villa:     a single villa no.
  ///
  /// All map onto the three API columns (building_number / floor_number /
  /// apartment_number); see [_onSave] for how the values are assembled.
  Widget _numberFields(BuildContext context) {
    final String type = _buildingTypes[_buildingTypeIndex].apiValue;

    if (type == 'villa') {
      return Row(
        children: [
          Expanded(
            child: _LabeledField(
              label: 'villa_number'.tr,
              controller: _buildingNoController,
              keyboardType: TextInputType.number,
              compact: true,
            ),
          ),
          // Keep the single field at ~1/3 width to match the grid layout.
          const Spacer(flex: 2),
        ],
      );
    }

    // apartment & office share the building-number + floor columns; only the
    // third column's label differs.
    final String thirdLabel =
        type == 'office' ? 'office_number'.tr : 'apartment_number'.tr;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LabeledField(
            label: 'building_number'.tr,
            controller: _buildingNoController,
            keyboardType: TextInputType.number,
            compact: true,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: _LabeledField(
            label: 'floor_no'.tr,
            controller: _floorController,
            keyboardType: TextInputType.number,
            compact: true,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: _LabeledField(
            label: thirdLabel,
            controller: _apartmentNoController,
            keyboardType: TextInputType.number,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildingTypeField(BuildContext context) {
    final selected = _buildingTypes[_buildingTypeIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _FieldLabel(label: 'building_type'.tr, required: true),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          onTap: () =>
              setState(() => _buildingDropdownOpen = !_buildingDropdownOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            decoration: _fieldDecoration(context),
            child: Row(
              children: [
                Image.asset(selected.image,
                    width: 30,
                    height: 30,
                    errorBuilder: (_, __, ___) => Icon(Icons.apartment,
                        size: 20, color: Theme.of(context).primaryColor)),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(selected.key.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.6,
                              color: const Color(0xFF333333),
                            )),
                      ),
                    ],
                  ),
                ),
                Icon(_buildingDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        if (_buildingDropdownOpen)
          Container(
            margin:
                const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            decoration: _fieldDecoration(context),
            child: Column(
              children: List.generate(_buildingTypes.length, (i) {
                final t = _buildingTypes[i];
                return InkWell(
                  onTap: () => setState(() {
                    _buildingTypeIndex = i;
                    _buildingDropdownOpen = false;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeDefault,
                    ),
                    child: Row(
                      children: [
                        Image.asset(t.image,
                            width: 30,
                            height: 30,
                            errorBuilder: (_, __, ___) => Icon(Icons.apartment,
                                size: 20,
                                color: Theme.of(context).primaryColor)),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Flexible(
                          child: Text(t.key.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 1.6,
                                color: const Color(0xFF333333),
                              )),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

BoxDecoration _fieldDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
    );

/// Field label with an optional red asterisk for required fields.
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 1.6,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        children: required
            ? [
                // Raise the asterisk above the text baseline (superscript).
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                )
              ]
            : null,
      ),
    );
  }
}

/// Labeled grey text field used throughout the form.
class _LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool compact;
  const _LabeledField({
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.keyboardType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _FieldLabel(label: label, required: required),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlignVertical: TextAlignVertical.center,
          // Number fields: large bold value centered in the box.
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: compact
              ? const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.6,
                )
              : TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF121C19),
                ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF717885),
            ),
            filled: true,
            fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.08),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: compact
                  ? Dimensions.paddingSizeDefault
                  : Dimensions.paddingSizeDefault + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width Save button — grey/disabled until valid, then green.
class _SaveButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;
  const _SaveButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: enabled ? primary : const Color(0xFFE2E4E6),
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
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'save_label'.tr,
                    textAlign: TextAlign.center,
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
