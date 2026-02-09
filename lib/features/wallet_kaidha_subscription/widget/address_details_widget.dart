// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class AddressDetailsWidget extends StatelessWidget {
  final AddressModel address_model;
  const AddressDetailsWidget({super.key, required this.address_model});

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
              address_model.address != '' || address_model.address!.isNotEmpty
                  ? Row(
                      children: [
                        Text('العنوان :  ', style: robotoMedium),
                        Text(
                          address_model.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                        )
                      ],
                    )
                  : const SizedBox(height: Dimensions.paddingSizeSmall),
              address_model.house != '' || address_model.house!.isNotEmpty
                  ? Row(
                      children: [
                        Text('المنزل :  ', style: robotoMedium),
                        Text(
                          ' ${address_model.house}  ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                        )
                      ],
                    )
                  : const SizedBox(height: Dimensions.paddingSizeSmall),
              address_model.streetNumber != '' || address_model.streetNumber!.isNotEmpty
                  ? Row(
                      children: [
                        Text('الشارع :  ', style: robotoMedium),
                        Text(
                          ' ${address_model.streetNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                        )
                      ],
                    )
                  : const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              address_model.streetNumber != '' || address_model.streetNumber!.isNotEmpty
                  ? Row(
                      children: [
                        Text('الوصف :  ', style: robotoMedium),
                        Text(
                          '${address_model.floor} ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
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
