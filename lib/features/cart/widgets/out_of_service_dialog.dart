import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/utils/snackbar_safe.dart';

class OutOfServiceDialog extends StatefulWidget {
  const OutOfServiceDialog({super.key});

  @override
  State<OutOfServiceDialog> createState() => _OutOfServiceDialogState();
}

class _OutOfServiceDialogState extends State<OutOfServiceDialog> {
  AddressController? addressController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      addressController = Get.find<AddressController>();
      await addressController!.getAddressList();
      // 🔒 FIX: Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      // 🔒 FIX: Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectAddress(AddressModel address) async {
    try {
      Get.dialog(
        const CustomLoaderWidget(),
        barrierDismissible: false,
      );

      // Validate the address is in service zone
      final LocationController locationController = Get.find<LocationController>();
      final response = await locationController.getZone(
          address.latitude, address.longitude, false);

      if (response.isSuccess && response.zoneIds.isNotEmpty) {
        // Update address with proper zone data (same as _prepareZoneData)
        address.zoneId = response.zoneIds[0];
        address.zoneIds = [];
        address.zoneIds!.addAll(response.zoneIds);
        address.zoneData = [];
        address.zoneData!.addAll(response.zoneData);
        address.areaIds = [];
        address.areaIds!.addAll(response.areaIds);

        // DON'T save to SharedPreferences - this would change the whole app's location
        // Just pass the address directly to checkout

        // 🔥 BUG FIX: Use SnackbarSafe to safely close any open snackbars before navigation
        SnackbarSafe.closeAll();
        
        Get.back(); // Close loader
        Get.back(); // Close the out-of-service dialog

        // Add a small delay to ensure dialogs are fully closed before navigation
        await Future.delayed(const Duration(milliseconds: 100));

        // Debug logging for address being passed
        debugPrint('🛒 OutOfServiceDialog: Passing address to checkout:');
        debugPrint('   - Address: ${address.address}');
        debugPrint('   - Lat/Lng: ${address.latitude}, ${address.longitude}');
        debugPrint('   - Zone IDs: ${address.zoneIds}');

        // Store the address in a global variable before navigation
        Get.put(address, tag: 'passed_address');
        debugPrint('🛒 OutOfServiceDialog: Address stored in global variable');

        // ✅ ARCHITECTURAL FIX: Pass cartList via navigateToCheckout
        final cartController = Get.find<CartController>();
        final storeId = cartController.cartList.isNotEmpty
            ? cartController.cartList.first.item?.storeId
            : null;
        if (storeId != null) {
          RouteHelper.navigateToCheckout(
            cartList: cartController.cartList,
            storeId: storeId,
          );
          showCustomSnackBar('location_selected_successfully'.tr, isError: false);
        } else {
          debugPrint('❌ Cannot navigate to checkout - storeId is null');
          showCustomSnackBar('Unable to proceed to checkout. Please try again.'.tr);
        }
      } else {
        // 🔥 BUG FIX: Use SnackbarSafe to safely close any open snackbars before showing new one
        SnackbarSafe.closeAll();
        
        Get.back(); // Close loader
        // Address is still outside service zone
        showCustomSnackBar('selected_address_outside_service_area'.tr);
      }
    } catch (e) {
      // 🔥 BUG FIX: Use SnackbarSafe to safely close any open snackbars before showing new one
      SnackbarSafe.closeAll();
      
      Get.back(); // Close loader
      showCustomSnackBar('error_selecting_address'.tr);
      debugPrint('Error selecting address: $e');
    }
  }

  void _openMapPicker() {
    // 🔥 BUG FIX: Use SnackbarSafe to safely close any open snackbars before navigation
    SnackbarSafe.closeAll();
    
    Get.back(); // Close the out-of-service dialog
    
    // Use microtask to separate dialog dismissal from navigation (prevents race conditions)
    Future.microtask(() {
      if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
        showGeneralDialog(
          context: Get.context!,
          pageBuilder: (_, __, ___) {
            return const SizedBox(
              height: 300,
              width: 300,
              child: PickMapScreen(
                fromSignUp: false,
                canRoute: true,
                fromAddAddress: false,
                route: '/cart',
              ),
            );
          },
        );
      } else {
        Get.toNamed('/pick-map?page=/cart&route=true');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern Header with Gradient
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'out_of_our_service'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'سننضم إليك قريباً!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message

                    const SizedBox(height: 20),

                    Text(
                      'select_an_address'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Saved addresses list
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading addresses...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : addressController?.addressList?.isNotEmpty == true
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  itemCount:
                                      addressController!.addressList!.length,
                                  itemBuilder: (context, index) {
                                    final AddressModel address =
                                        addressController!.addressList![index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap: () => _selectAddress(address),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.location_on_rounded,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        address.address ??
                                                            'address_not_available'
                                                                .tr,
                                                        style: robotoMedium
                                                            .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if (address.addressType !=
                                                          null) ...[
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          address
                                                              .addressType!.tr,
                                                          style: robotoRegular
                                                              .copyWith(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 16,
                                                  color: Colors.grey[400],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          Icons.location_off_rounded,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'no_saved_addresses'.tr,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),

                    const SizedBox(height: 20),

                    // Choose from map button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _openMapPicker,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.map_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'choose_from_map'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
