import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/widgets/address_selection_sheet.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/features/checkout/widgets/guest_delivery_address.dart';

class DeliverySection extends StatelessWidget {
  final CheckoutController checkoutController;
  final List<AddressModel> address;
  final List<DropdownItem<int>> addressList;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  const DeliverySection({
    super.key,
    required this.checkoutController,
    required this.address,
    required this.addressList,
    required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController,
    required this.guestNumberNode,
    required this.guestEmailController,
    required this.guestEmailNode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    final bool takeAway = (checkoutController.orderType == 'take_away');
    final int selectedIndex = (checkoutController.addressIndex != null &&
            checkoutController.addressIndex! >= 0 &&
            checkoutController.addressIndex! < address.length)
        ? checkoutController.addressIndex!
        : 0;
    debugPrint(
      '📍 [DeliverySection] addresses=${address.length}, selectedIndex=$selectedIndex, selectedId=${address.isNotEmpty ? address[selectedIndex].id : null}, ids=${address.map((e) => e.id).toList()}',
    );
    return Column(children: [
      isGuestLoggedIn
          ? GuestDeliveryAddress(
              checkoutController: checkoutController,
              guestNumberNode: guestNumberNode,
              guestNameTextEditingController: guestNameTextEditingController,
              guestNumberTextEditingController:
                  guestNumberTextEditingController,
              guestEmailController: guestEmailController,
              guestEmailNode: guestEmailNode,
            )
          : !takeAway
              ? Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Theme.of(context).cardColor,
                    border: isDark
                        ? Border.all(color: const Color(0xFF334155), width: 1)
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // 🎨 NEW DESIGN: tappable "will arrive at" row + address
                        // line. Tapping opens the address bottom sheet (choose
                        // saved / add new / edit). The detailed street/house/
                        // floor fields were removed — the selected address
                        // already carries them.
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          // The new app's address sheet handles selection
                          // (zone, distance, active address) internally.
                          onTap: () => showAddressSelectionSheet(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  // "سيصلك على" → Headline (Bold 18, #121C19);
                                  // address name → Highlight green (Bold 16).
                                  child: Text.rich(
                                    TextSpan(children: [
                                      TextSpan(
                                        text: '${'will_arrive_at'.tr} ',
                                        style: tajawalBold.copyWith(
                                          fontSize: 18,
                                          height: 1.6,
                                          letterSpacing: 0,
                                          color: isDark ? Colors.white : const Color(0xFF121C19),
                                        ),
                                      ),
                                      if (address.isNotEmpty &&
                                          (address[selectedIndex].addressType ??
                                                  '')
                                              .isNotEmpty)
                                        TextSpan(
                                          text: address[selectedIndex]
                                              .addressType!,
                                          style: tajawalBold.copyWith(
                                            fontSize: 16,
                                            height: 1.6,
                                            letterSpacing: 0,
                                            color: const Color(0xFF30913F),
                                          ),
                                        ),
                                    ]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Theme.of(context).primaryColor),
                              ],
                            ),
                          ),
                        ),
                        if (address.isNotEmpty &&
                            (address[selectedIndex].address ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(Images.location_new,
                                    width: 16, height: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    address[selectedIndex].address!,
                                    textAlign: TextAlign.right,
                                    style: tajawalMedium.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 1.6,
                                      letterSpacing: 0,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                      ]),
                )
              : const SizedBox(),
    ]);
  }
}
