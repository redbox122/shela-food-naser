import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
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
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    final bool takeAway = (checkoutController.orderType == 'take_away');
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
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
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.05),
                          blurRadius: 10)
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('deliver_to'.tr, style: robotoMedium),
                              TextButton.icon(
                                onPressed: () async {
                                  final dynamic result = await Get.toNamed(
                                      RouteHelper.getAddAddressRoute(
                                          true,
                                          false,
                                          checkoutController.store!.zoneId));
                                  if (result is AddressModel) {
                                    checkoutController.getDistanceInKM(
                                      LatLng(double.parse(result.latitude!),
                                          double.parse(result.longitude!)),
                                      LatLng(
                                          double.parse(checkoutController
                                              .store!.latitude!),
                                          double.parse(checkoutController
                                              .store!.longitude!)),
                                    );
                                    final String? street = result.streetNumber;
                                    if (street != null &&
                                        street.trim().isNotEmpty) {
                                      checkoutController
                                          .streetNumberController.text = street;
                                    }
                                    final String? house = result.house;
                                    if (house != null &&
                                        house.trim().isNotEmpty) {
                                      checkoutController.houseController.text =
                                          house;
                                    }
                                    final String? floor = result.floor;
                                    if (floor != null &&
                                        floor.trim().isNotEmpty) {
                                      checkoutController.floorController.text =
                                          floor;
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: Text('add_new'.tr,
                                    style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall)),
                              ),
                            ]),
                        isDesktop
                            ? Stack(children: [
                                Container(
                                  constraints:
                                      const BoxConstraints(minHeight: 90),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault),
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.1),
                                  ),
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                      vertical:
                                          Dimensions.paddingSizeExtraSmall,
                                      horizontal:
                                          Dimensions.paddingSizeExtraSmall,
                                    ),
                                    child: AddressWidget(
                                      address: address[selectedIndex],
                                      fromAddress: false,
                                      fromCheckout: true,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: PopupMenuButton(
                                        position: PopupMenuPosition.under,
                                        icon: const Icon(
                                            Icons.keyboard_arrow_down),
                                        onSelected: (value) {},
                                        itemBuilder: (context) => List.generate(
                                            address.length,
                                            (index) => PopupMenuItem(
                                                  child: InkWell(
                                                    onTap: () {
                                                      checkoutController
                                                          .getDistanceInKM(
                                                        LatLng(
                                                          double.parse(
                                                              address[index]
                                                                  .latitude!),
                                                          double.parse(
                                                              address[index]
                                                                  .longitude!),
                                                        ),
                                                        LatLng(
                                                            double.parse(
                                                                checkoutController
                                                                    .store!
                                                                    .latitude!),
                                                            double.parse(
                                                                checkoutController
                                                                    .store!
                                                                    .longitude!)),
                                                      );
                                                      checkoutController
                                                          .setAddressIndex(
                                                              index);
                                                      final String? street =
                                                          address[index]
                                                              .streetNumber;
                                                      if (street != null &&
                                                          street
                                                              .trim()
                                                              .isNotEmpty) {
                                                        checkoutController
                                                            .streetNumberController
                                                            .text = street;
                                                      }
                                                      final String? house =
                                                          address[index].house;
                                                      if (house != null &&
                                                          house
                                                              .trim()
                                                              .isNotEmpty) {
                                                        checkoutController
                                                            .houseController
                                                            .text = house;
                                                      }
                                                      final String? floor =
                                                          address[index].floor;
                                                      if (floor != null &&
                                                          floor
                                                              .trim()
                                                              .isNotEmpty) {
                                                        checkoutController
                                                            .floorController
                                                            .text = floor;
                                                      }
                                                      Navigator.pop(context);
                                                    },
                                                    child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            height: 20,
                                                            width: 20,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(3),
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                  color: checkoutController
                                                                              .addressIndex ==
                                                                          index
                                                                      ? Theme.of(
                                                                              context)
                                                                          .primaryColor
                                                                      : Theme.of(
                                                                              context)
                                                                          .disabledColor),
                                                            ),
                                                            child: checkoutController
                                                                        .addressIndex ==
                                                                    index
                                                                ? Container(
                                                                    height: 15,
                                                                    width: 15,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: Theme.of(context)
                                                                            .primaryColor),
                                                                  )
                                                                : const SizedBox(),
                                                          ),
                                                          const SizedBox(
                                                              width: Dimensions
                                                                  .paddingSizeSmall),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                    address[index]
                                                                        .addressType!
                                                                        .tr,
                                                                    style: robotoMedium.copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeSmall)),
                                                                const SizedBox(
                                                                    height: Dimensions
                                                                        .paddingSizeExtraSmall),
                                                                Text(
                                                                  address[index]
                                                                      .address!,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: robotoRegular.copyWith(
                                                                      fontSize:
                                                                          Dimensions
                                                                              .fontSizeExtraSmall,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .disabledColor),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ]),
                                                  ),
                                                ))),
                                  ),
                                ),
                              ])
                            : Container(
                                constraints: BoxConstraints(
                                  minHeight: ResponsiveHelper.isDesktop(context)
                                      ? 100
                                      : 96,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.05),
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeSmall),
                                    child: CustomDropdown<int>(
                                      onChange: (int? value, int index) {
                                        checkoutController.getDistanceInKM(
                                          LatLng(
                                            double.parse(
                                                address[index].latitude!),
                                            double.parse(
                                                address[index].longitude!),
                                          ),
                                          LatLng(
                                            double.parse(checkoutController
                                                .store!.latitude!),
                                            double.parse(checkoutController
                                                .store!.longitude!),
                                          ),
                                        );
                                        checkoutController
                                            .setAddressIndex(index);

                                        final String? street =
                                            address[index].streetNumber;
                                        if (street != null &&
                                            street.trim().isNotEmpty) {
                                          checkoutController
                                              .streetNumberController
                                              .text = street;
                                        }
                                        final String? house =
                                            address[index].house;
                                        if (house != null &&
                                            house.trim().isNotEmpty) {
                                          checkoutController
                                              .houseController.text = house;
                                        }
                                        final String? floor =
                                            address[index].floor;
                                        if (floor != null &&
                                            floor.trim().isNotEmpty) {
                                          checkoutController
                                              .floorController.text = floor;
                                        }
                                      },
                                      dropdownButtonStyle: DropdownButtonStyle(
                                        height: 96,
                                        padding: const EdgeInsets.symmetric(
                                          vertical:
                                              Dimensions.paddingSizeExtraSmall,
                                          horizontal:
                                              Dimensions.paddingSizeExtraSmall,
                                        ),
                                        primaryColor: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color,
                                      ),
                                      dropdownStyle: DropdownStyle(
                                        elevation: 10,
                                        borderRadius: BorderRadius.circular(
                                            Dimensions.radiusDefault),
                                        padding: const EdgeInsets.all(
                                            Dimensions.paddingSizeExtraSmall),
                                      ),
                                      items: addressList,
                                      child: AddressWidget(
                                        address: address[selectedIndex],
                                        fromAddress: false,
                                        fromCheckout: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        !isDesktop
                            ? CustomTextField(
                                labelText: 'street_number'.tr,
                                titleText: 'write_street_number'.tr,
                                inputType: TextInputType.streetAddress,
                                focusNode: checkoutController.streetNode,
                                nextFocus: checkoutController.houseNode,
                                controller:
                                    checkoutController.streetNumberController,
                              )
                            : const SizedBox(),
                        SizedBox(
                            height:
                                !isDesktop ? Dimensions.paddingSizeLarge : 0),
                        Row(children: [
                          isDesktop
                              ? Expanded(
                                  child: CustomTextField(
                                    titleText: 'write_street_number'.tr,
                                    labelText: 'street_number'.tr,
                                    inputType: TextInputType.streetAddress,
                                    focusNode: checkoutController.streetNode,
                                    nextFocus: checkoutController.houseNode,
                                    controller: checkoutController
                                        .streetNumberController,
                                  ),
                                )
                              : const SizedBox(),
                          SizedBox(
                              width:
                                  isDesktop ? Dimensions.paddingSizeSmall : 0),

                          Expanded(
                            child: CustomTextField(
                              titleText: 'write_house_number'.tr,
                              labelText: 'house'.tr,
                              focusNode: checkoutController.houseNode,
                              nextFocus: checkoutController.floorNode,
                              controller: checkoutController.houseController,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Expanded(
                            child: CustomTextField(
                              titleText: 'write_floor_number'.tr,
                              labelText: 'floor'.tr,
                              focusNode: checkoutController.floorNode,
                              inputAction: TextInputAction.done,
                              controller: checkoutController.floorController,
                            ),
                          ),
                          //const SizedBox(height: Dimensions.paddingSizeLarge),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ]),
                )
              : const SizedBox(),
    ]);
  }
}
