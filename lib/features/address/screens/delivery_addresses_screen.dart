import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: "Delivery addresses" management screen.
///
/// Reached from the "edit addresses" action in the address-selection sheet.
/// Lists the saved addresses (v2). Each card has edit (opens the form prefilled)
/// and delete actions, plus an "add another address" button.
class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  @override
  void initState() {
    super.initState();
    if (AuthHelper.isLoggedIn()) {
      Get.find<AddressController>().getAddressListV2();
    }
  }

  void _confirmDelete(AddressModel address, int index) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'do_you_want_to_delete_the_address'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.6,
                  color: Color(0xFF121C19),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
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
                  onPressed: () {
                    Get.back();
                    Get.find<AddressController>()
                        .deleteAddressV2(address.id, index)
                        .then((response) {
                      showCustomSnackBar(response.message,
                          isError: !response.isSuccess);
                    });
                  },
                  child: Text(
                    'delete_the_address'.tr,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: Dimensions.fontSizeDefault,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
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
                  onPressed: () => Get.back(),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: Dimensions.fontSizeDefault,
                      height: 1.6,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'delivery_addresses'.tr,
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
      body: SafeArea(
        child: GetBuilder<AddressController>(builder: (controller) {
          final list = controller.addressList;
          if (list == null && controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final int? currentId =
              AddressHelper.getUserAddressFromSharedPref()?.id;
          final items = list ?? const <AddressModel>[];
          return RefreshIndicator(
            onRefresh: () => controller.getAddressListV2(),
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'no_saved_addresses'.tr,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(items.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeSmall),
                      child: _AddressTile(
                        address: items[i],
                        selected: items[i].id == currentId,
                        onDelete: () => _confirmDelete(items[i], i),
                        onEdit: () => Get.toNamed(
                          RouteHelper.getAddressDetailsRoute(),
                          arguments: {'addressId': items[i].id},
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    onPressed: () => Get.toNamed(
                        RouteHelper.getSelectLocationRoute(page: 'home')),
                    child: Text(
                      'add_another_address'.tr,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool selected;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        // Selected = active (green); others = disabled (grey).
        color: selected ? const Color(0xFFEBFEEB) : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: selected ? primary : const Color(0xFFEAEAEA),
        ),
      ),
      child: Row(
        children: [
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
                      fontSize: 18,
                      height: 1.83,
                    ),
                  ),
                if (address.address != null && address.address!.isNotEmpty)
                  Text(
                    address.address!,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
          // Edit → opens the form prefilled with this address (mockup step 6).
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Icon(Icons.edit_outlined, size: 20, color: primary),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          InkWell(
              onTap: onDelete,
              child: Image.asset(Images.trash_v2, width: 48, height: 48)),
        ],
      ),
    );
  }
}
