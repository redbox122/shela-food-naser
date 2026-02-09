import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressWidget extends StatelessWidget {
  final AddressModel? address;
  final bool fromAddress;
  final bool fromCheckout;
  final Function? onRemovePressed;
  final Function? onEditPressed;
  final Function? onTap;
  final bool isSelected;
  final bool fromDashBoard;
  final bool showRadioButton;
  final String? radioGroupValue;
  final String? radioValue;
  final ValueChanged<String?>? onRadioChanged;
  const AddressWidget(
      {super.key,
      required this.address,
      required this.fromAddress,
      this.onRemovePressed,
      this.onEditPressed,
      this.onTap,
      this.fromCheckout = false,
      this.isSelected = false,
      this.fromDashBoard = false,
      this.showRadioButton = false,
      this.radioGroupValue,
      this.radioValue,
      this.onRadioChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: fromCheckout ? 0 : Dimensions.paddingSizeSmall),
      child: Container(
        decoration: fromDashBoard
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: isSelected ? 1 : 0),
              )
            : fromCheckout
                ? const BoxDecoration()
                : BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).cardColor,
                        width: isSelected ? 0.5 : 0),
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          blurRadius: 5,
                          spreadRadius: 1)
                    ],
                  ),
        child: CustomInkWell(
          onTap: onTap as void Function()?,
          radius: fromDashBoard
              ? Dimensions.radiusDefault
              : fromCheckout
                  ? 0
                  : Dimensions.radiusSmall,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context)
                ? Dimensions.paddingSizeDefault
                : Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                // Radio Button (if enabled)
                if (showRadioButton && onRadioChanged != null) ...[
                  // ignore: deprecated_member_use
                  Radio<String>(
                    value: radioValue ?? '',
                    // ignore: deprecated_member_use
                    groupValue: radioGroupValue,
                    // ignore: deprecated_member_use
                    onChanged: onRadioChanged!,
                    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).primaryColor;
                      }
                      return Theme.of(context).unselectedWidgetColor;
                    }),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                ],

                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(
                            address!.addressType == 'home'
                                ? Images.homeIcon
                                : address!.addressType == 'office'
                                    ? Images.workIcon
                                    : Images.otherIcon,
                            color: Theme.of(context).primaryColor,
                            height:
                                ResponsiveHelper.isDesktop(context) ? 25 : 20,
                            width:
                                ResponsiveHelper.isDesktop(context) ? 25 : 20,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            address!.addressType!.tr,
                            style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault),
                          ),
                        ]),
                        const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall),
                        Text(
                          AddressHelper()
                              .removeEnglishAndNumbers(address?.address ?? ''),
                          style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).disabledColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                ),

                // Edit and Delete Icons (always show when fromAddress is true)
                if (fromAddress) ...[
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Colors.blueGrey, size: 25),
                    onPressed: onEditPressed as void Function()?,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 25),
                    onPressed: onRemovePressed as void Function()?,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
