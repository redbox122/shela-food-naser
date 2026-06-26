import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/services/address_v2_api.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

Future<void> showAddressSelectionSheet() async {
  // Pre-load saved addresses BEFORE opening so the sheet appears once already
  // populated (no empty-then-filled flicker). On first open we wait for the
  // list; afterwards we refresh silently in the background.
  if (AuthHelper.isLoggedIn() && Get.isRegistered<AddressController>()) {
    final controller = Get.find<AddressController>();
    if (controller.addressList == null) {
      await controller.getAddressListV2();
    } else {
      unawaited(controller.getAddressListV2());
    }
  }
  Get.bottomSheet(
    const _AddressSelectionSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _AddressSelectionSheet extends StatefulWidget {
  const _AddressSelectionSheet();

  @override
  State<_AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<_AddressSelectionSheet> {
  int? get _currentAddressId =>
      AddressHelper.getUserAddressFromSharedPref()?.id;

  Future<void> _selectAddress(AddressModel address) async {
    Get.back();
    final double? lat = double.tryParse(address.latitude ?? '');
    final double? lng = double.tryParse(address.longitude ?? '');
    int? zoneId;
    if (lat != null && lng != null) {
      final zone = await AddressV2Api().checkZone(lat, lng);
      zoneId = zone?.zoneId;
    }
    final AddressModel current = AddressModel(
      id: address.id,
      latitude: address.latitude,
      longitude: address.longitude,
      addressType: address.addressType,
      address: address.address,
      zoneId: zoneId,
      zoneIds: zoneId != null ? [zoneId] : [],
      areaIds: const [],
    );
    await AddressHelper.saveUserAddressInSharedPref(current);
    Get.offAllNamed(RouteHelper.getMainRoute('home'));
  }

  void _addNewAddress() {
    Get.back();
    Get.toNamed(RouteHelper.getSelectLocationRoute(page: 'home'));
  }

  void _editAddresses() {
    Get.back();
    Get.toNamed(RouteHelper.getDeliveryAddressesRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const SizedBox(width: 48), // balance the close icon
                Expanded(
                  child: Text(
                    'choose_the_address'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 1.6,
                      color: Color(0xFF121C19),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 35,
                    height: 35,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F5F8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Saved addresses (hidden for guests / no addresses)
            GetBuilder<AddressController>(builder: (controller) {
              final list = controller.addressList ?? const <AddressModel>[];
              if (list.isEmpty) return const SizedBox.shrink();
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: context.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                  itemBuilder: (_, i) => _AddressCard(
                    address: list[i],
                    selected: list[i].id == _currentAddressId,
                    onTap: () => _selectAddress(list[i]),
                  ),
                ),
              );
            }),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Add new address
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                onPressed: _addNewAddress,
                child: Text(
                  'add_new_address_label'.tr,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Edit addresses
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF6F6F6),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                onPressed: _editAddresses,
                child: Text(
                  'edit_addresses'.tr,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.6,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: const Color(0xffEBFEEB),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          // Shella green border highlights the selected address (per mockup).
          border: Border.all(
            color: selected ? const Color(0xFF30913F) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Text on the right (RTL start), radio on the left.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address.addressType != null &&
                      address.addressType!.isNotEmpty)
                    Text(
                      address.addressType!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.83,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  if (address.address != null && address.address!.isNotEmpty)
                    Text(
                      address.address!,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.83,
                        color: Color(0xFF121C19),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? const Color(0xFF30913F)
                  : Theme.of(context).disabledColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
