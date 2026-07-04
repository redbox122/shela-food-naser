// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class DeliveryDetailsWidget extends StatelessWidget {
  final AddressModel address_model;
  const DeliveryDetailsWidget({super.key, required this.address_model});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          address_model.addressType == 'home'
              ? Images.homeIcon
              : address_model.addressType == 'office'
                  ? Images.workIcon
                  : Images.otherIcon,
          color: Theme.of(context).primaryColor,
          height: 28,
          width: 28,
        ),

        //

        SizedBox(
          width: Dimensions.fontSizeLarge,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //
              // address_model.address != "" || address_model.address!.isNotEmpty
              //     ? Row(
              //         children: [
              //           Text("العنوان :  ", style: robotoMedium),
              //           SizedBox(
              //             width: 300,
              //             child: Text(
              //               (address_model.address?.isNotEmpty ?? false)
              //                   ? AddressHelper().removeEnglishAndNumbers(address_model.address!)
              //                   : 'ord_no_address'.tr,
              //               maxLines: 3,
              //               overflow: TextOverflow.ellipsis,
              //               style: robotoRegular.copyWith(
              //                 color: Theme.of(context).hintColor,
              //               ),
              //             ),
              //           )
              //         ],
              //       )
              //     : const SizedBox(height: Dimensions.paddingSizeSmall),

              // Show house if available, otherwise show main address
              (address_model.house != null && address_model.house!.isNotEmpty)
                  ? Row(
                      children: [
                        Text('ord_home_label'.tr, style: robotoMedium),
                        Text(
                          ' ${address_model.house}  ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(
                              color: Theme.of(context).hintColor),
                        )
                      ],
                    )
                  : (address_model.address != null &&
                          address_model.address!.isNotEmpty)
                      ? Row(
                          children: [
                            Text('ord_address_label'.tr, style: robotoMedium),
                            Expanded(
                              child: Text(
                                ' ${address_model.address}  ',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: robotoRegular.copyWith(
                                    color: Theme.of(context).hintColor),
                              ),
                            )
                          ],
                        )
                      : const SizedBox(height: Dimensions.paddingSizeSmall),

              // Show street if available
              (address_model.streetNumber != null &&
                      address_model.streetNumber!.isNotEmpty)
                  ? Row(
                      children: [
                        Text('ord_street'.tr, style: robotoMedium),
                        Text(
                          ' ${address_model.streetNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(
                              color: Theme.of(context).hintColor),
                        )
                      ],
                    )
                  : const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              // Show floor/description if available
              (address_model.floor != null && address_model.floor!.isNotEmpty)
                  ? Row(
                      children: [
                        Text('ord_desc_label'.tr, style: robotoMedium),
                        Text(
                          '${address_model.floor} ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(
                              color: Theme.of(context).hintColor),
                        )
                      ],
                    )
                  : const SizedBox(),
              //
            ],
          ),
        ),
      ],
    );
  }
}
